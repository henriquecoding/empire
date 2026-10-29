"""As convencoes do Empire num .aseprite e os comandos `aseprite`, `ase` e `exportar` (FORJA-13)."""
import json
import unittest
from pathlib import Path

from PIL import Image

from tools.forja import aseprite, cli, mcp_server
from tools.forja import ase
from tools.forja.ase import empire
from tools.forja.ase.describe import diff
from tools.forja.ase.model import Layer
from tools.forja.ase import cena as scene_ase
from tools.forja.tests import scene_fixtures as fx
from tools.forja.tests.ase_cases import _box, body, cena
from tools.forja.tests.helpers import tempdir

FIX = Path(__file__).resolve().parent / "ase_fixtures"
ROOT = Path(__file__).resolve().parents[3]


def codes(report: dict, severity: str | None = None) -> list[str]:
    return [f["code"] for f in report["findings"] if severity in (None, f["severity"])]


class ConvencoesTest(unittest.TestCase):
    def test_slot_variante_e_ordem_z(self):
        self.assertEqual([empire.slot(n) for n in ("weapon_bow_l1", "face", "Body", "plant", "head_hood")],
                         ["weapon", "face", None, None, "head"])
        self.assertEqual(empire.layer_user("weapon_bow_l1").properties[""], {"slot": "weapon", "variant": "bow_l1"})
        names = ["overlay", "weapon_bow_l1", "body", "shadow", "face_hurt", "storage_quiver", "head_hood"]
        self.assertEqual(sorted(names, key=empire.z_order),
                         ["shadow", "body", "storage_quiver", "head_hood", "face_hurt", "weapon_bow_l1", "overlay"])

    def test_tropa_do_dono_le_se_como_a_tabela_da_biblia(self):
        rep = empire.check(ase.read(FIX / "troop.aseprite"))
        self.assertTrue(rep["ok"])
        self.assertEqual(rep["exported"], ["body", "face", "shield", "sword", "equipments"])  # o Knight e de trabalho
        roles = {la["name"]: (la["role"], la["slot"]) for la in rep["layers"]}
        self.assertEqual(roles["Equipments"], ("legacy", "storage"))
        self.assertEqual(roles["Knight"][0], "work")
        self.assertIn("tag_name", codes(rep, "warn"))  # `Idle` com maiuscula
        self.assertEqual(codes(rep, "error"), [])

    def test_o_pivot_dos_v15_e_o_ground_pivot(self):
        rep = empire.check(ase.read(FIX / "rose-7.aseprite"))
        self.assertEqual(rep["pivot"]["slice"], "ground_pivot")
        self.assertNotIn("pivot_slice", codes(rep))

    def test_o_que_impede_a_exportacao(self):
        img = _box((8, 8), [1, 1, 4, 4], (200, 0, 0, 255))
        twin = ase.build((8, 8), [("body", [img]), ("body", [img])])
        self.assertIn("duplicate_layer", codes(empire.check(twin), "error"))
        self.assertFalse(empire.check(twin)["ok"])
        self.assertIn("canvas", codes(empire.check(ase.read(FIX / "troop.aseprite"), "troop_64"), "error"))

    def test_avisos_de_camada_e_tag(self):
        img = _box((8, 8), [1, 1, 4, 4], (200, 0, 0, 255))
        s = ase.build((8, 8), [(Layer("body"), [img, img]), (Layer("weapon_x", flags=2), [img, img]),
                               (Layer("glow", blend=2), [img, None])])
        s.tags = [ase.Tag("Walk", 0, 0)]
        rep = empire.check(s)
        self.assertTrue({"slot_hidden", "layer_name", "layer_blend", "tag_name", "untagged_frames"}
                        <= set(codes(rep, "warn")), rep["findings"])
        self.assertEqual(rep["exported"], ["body", "glow"])

    def test_corpo_montado_pela_forja(self):
        s = body()
        self.assertEqual([la.name for la in s.layers], ["References", "shadow", "body", "face_normal", "weapon_bow_l1"])
        self.assertTrue(s.layers[0].has("reference"))
        self.assertEqual([(t.name, t.repeat) for t in s.tags], [("idle", 0), ("die", 1)])
        self.assertTrue(all(s.cels[(1, f)].link == 0 for f in range(1, s.frames)))  # a sombra: uma cel, ligada
        self.assertEqual(s.slices[0].keys[0].pivot, (32, 56))
        rep = empire.check(s, "character_s1")
        self.assertTrue(rep["ok"])
        self.assertEqual(codes(rep, "warn"), [])

    def test_camadas_desiguais_recusadas(self):
        img = _box((8, 8), [1, 1, 4, 4], (200, 0, 0, 255))
        with self.assertRaises(ValueError):
            aseprite.assemble((8, 8), {"body": [img, img, img], "face": [img, img]})


class CenaTest(unittest.TestCase):
    def resolved(self) -> dict:
        from tools.forja import scene
        return scene.resolve(scene.load(fx.write(tempdir(), fx.contract())))

    def test_o_contrato_vai_e_volta_pelo_ficheiro(self):
        back = ase.read(ase.write(cena()))
        seen = scene_ase.read(back)
        self.assertEqual(seen["states"], ["done", "damaged"])
        self.assertEqual(seen["openings"]["porta"], {"box_px": fx.DOOR, "kind": "door", "treatment": "interior"})
        self.assertEqual(seen["pivot"], [64, 127])
        self.assertEqual(scene_ase.drift(self.resolved(), seen), [])
        zone = next(s for s in back.slices if s.name == "state_damaged_0")
        self.assertEqual([k.frame for k in zone.keys], [1])  # a zona so existe no quadro do estado
        self.assertEqual(empire.check(back)["asset"], "scene")

    def test_um_vao_mexido_no_aseprite_aparece_e_nao_reescreve(self):
        s = cena()
        door = next(x for x in s.slices if x.name == "opening_porta")
        door.keys[0].w = 20  # o autor estreitou a porta no Aseprite
        res = self.resolved()
        drift = scene_ase.drift(res, scene_ase.read(ase.read(ase.write(s))))
        self.assertEqual(drift, ["vao porta: contrato [48, 44, 80, 128], ficheiro [48, 44, 68, 128]"])
        self.assertEqual(res["openings"][0]["box_px"], fx.DOOR)

    def test_estado_base_obrigatorio(self):
        with self.assertRaises(ValueError):
            scene_ase.write(self.resolved(), {"damaged": fx.house()})


class ComandosTest(unittest.TestCase):
    def frames(self, d: Path, prefix: str, n: int, color) -> list[str]:
        out = []
        for f in range(n):
            p = d / f"{prefix}_{f}.png"
            _box((64, 64), [20 + f, 20, 40, 56], color).save(p)
            out.append(str(p))
        return out

    def test_aseprite_com_slots_referencia_e_contrato(self):
        d = tempdir()
        main = self.frames(d, "corpo", 6, (150, 100, 60, 255))
        self.frames(d, "arco", 6, (90, 60, 30, 255))
        _box((64, 64), [0, 0, 63, 63], (255, 0, 255, 255)).save(d / "ref.png")
        res = cli.run(["aseprite", *main, "-o", str(d / "corpo.aseprite"), "--tags", "idle", "--kind", "character_s1",
                       "--slot", f"weapon_bow_l1={d}/arco_*.png", "--reference", str(d / "ref.png")])
        self.assertTrue(res["ok"], res)
        self.assertEqual(res["verify"]["layer_equal"], {"body": True, "weapon_bow_l1": True})
        self.assertIsNone(res["verify"]["pixel_equal"])
        s = ase.read(d / "corpo.aseprite")
        self.assertEqual(s.slices[0].keys[0].pivot, (32, 56))  # o pivot do contrato
        self.assertEqual(s.user.properties[""]["kind"].value, "character_s1")  # lido de volta, com o tipo

    def test_nunca_escreve_em_art(self):
        d = tempdir()
        main = self.frames(d, "corpo", 1, (150, 100, 60, 255))
        with self.assertRaises(ValueError):
            cli.run(["aseprite", *main, "-o", str(ROOT / "art/source/x.aseprite")])
        with self.assertRaises(ValueError):
            cli.run(["exportar", str(FIX / "troop.aseprite"), "-o", str(ROOT / "art/export/x")])

    def test_ase_so_le(self):
        res = cli.run(["ase", str(FIX / "forja_rgba.aseprite")])
        self.assertTrue(res["ok"])
        self.assertEqual(res["aseprite"]["layers"][1]["cels"], 4)
        self.assertEqual(res["check"]["schema"], "forja.ase_check/1")
        self.assertEqual(mcp_server.annotations("ase")["readOnlyHint"], True)
        self.assertIn("forja_exportar", {t["name"] for t in mcp_server.tools()})

    def test_exportar_igual_ao_script(self):
        d = tempdir()
        res = cli.run(["exportar", str(FIX / "troop.aseprite"), "-o", str(d)])
        self.assertEqual(sorted(Path(f["png"]).stem for f in res["files"]),
                         json.loads((FIX / "casos.json").read_text(encoding="utf-8"))["script"]["troop.aseprite"])
        for f in res["files"]:
            stem = Path(f["png"]).stem
            mine, theirs = (json.loads(Path(p).read_text(encoding="utf-8")) for p in (f["json"], FIX / "export" /
                                                                                       f"{stem}.json"))
            for doc in (mine, theirs):
                doc["meta"].pop("app")
                doc["meta"].pop("version")
            self.assertEqual(diff(mine, theirs), [])
            self.assertEqual(Image.open(f["png"]).convert("RGBA").tobytes(),
                             Image.open(FIX / "export" / f"{stem}.png").convert("RGBA").tobytes())

    def test_estrutura_escreve_e_ase_confere_a_cena(self):
        d = tempdir()
        contract = fx.write(d, fx.contract())
        fx.house().save(d / "casa.png")
        rep = cli.run(["estrutura", str(d / "casa.png"), "--scene", str(contract), "--state",
                       f"damaged={d / 'casa.png'}", "--aseprite", str(d / "casa.aseprite")])
        self.assertTrue(Path(rep["aseprite"]).exists())
        res = cli.run(["ase", rep["aseprite"], "--scene", str(contract)])
        self.assertEqual(res["scene"]["drift"], [])
        self.assertTrue(res["ok"])

    def test_exportar_composto_como_o_diagnostico(self):
        d = tempdir()
        res = cli.run(["exportar", str(FIX / "troop.aseprite"), "-o", str(d), "--composite"])
        self.assertEqual(len(res["files"]), 1)
        data = json.loads(Path(res["files"][0]["json"]).read_text(encoding="utf-8"))
        theirs = json.loads((FIX / "troop_sheet.json").read_text(encoding="utf-8"))
        for doc in (data, theirs):
            doc["meta"].pop("app")
            doc["meta"].pop("version")
        self.assertEqual(diff(data, theirs), [".meta.image: 'troop.png' contra 'troop_sheet.png'"])  # so o nome


if __name__ == "__main__":
    unittest.main()
