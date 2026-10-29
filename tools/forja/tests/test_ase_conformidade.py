"""A conformidade da Forja com o Aseprite 1.3.18.6 (FORJA-14), repetida sem o Aseprite.

Os ficheiros de `ase_fixtures/` sairam do Aseprite real (`conformidade.py` da pesquisa de 29/10): sprites que ele
criou pelo Lua, tres fontes do dono copiadas de `art/source/`, os quadros que exportou, o que o Lua dele viu em cada
ficheiro, os que a Forja escreveu e ele regravou, as folhas + JSON da CLI e o que o `tools/export_aseprite.sh`
escreveu por camada (`export/`). O teste confere que a Forja continua a ler, renderizar, escrever e exportar como ele.
"""
import json
import unittest
from pathlib import Path

from PIL import Image

from tools.forja import ase
from tools.forja.ase import blend, empire
from tools.forja.ase.describe import describe, diff
from tools.forja.ase.export import sheet
from tools.forja.tests.ase_cases import CASES

FIX = Path(__file__).resolve().parent / "ase_fixtures"
MANIFEST = json.loads((FIX / "casos.json").read_text(encoding="utf-8"))


def pixels(img: Image.Image) -> bytes:
    return img.convert("RGBA").tobytes()


class ConformidadeTest(unittest.TestCase):
    def test_cobre_os_casos(self):
        self.assertTrue(MANIFEST["aseprite"].startswith("Aseprite 1.3.18.6"))
        origins = [c["origin"] for c in MANIFEST["cases"].values()]
        forja = {n for n, c in MANIFEST["cases"].items() if c["origin"] == "forja"}
        self.assertEqual(forja, {f"{n}.aseprite" for n in CASES})
        self.assertGreaterEqual(origins.count("aseprite"), 5)
        self.assertGreaterEqual(origins.count("empire"), 3)
        self.assertIn("troop.aseprite", MANIFEST["script"])  # o ficheiro com que o script pedia para ser testado

    def test_le_o_que_o_aseprite_ve(self):
        for name, case in MANIFEST["cases"].items():
            with self.subTest(name):
                seen = describe(ase.read(FIX / name))
                seen.pop("bytes_per_pixel")
                self.assertEqual(diff(seen, json.loads((FIX / case["dump"]).read_text(encoding="utf-8"))), [])

    def test_renderiza_como_o_aseprite(self):
        for name, case in MANIFEST["cases"].items():
            sprite = ase.read(FIX / name)
            self.assertEqual(len(case["frames"]), sprite.frames)
            for i, png in enumerate(case["frames"]):  # um quadro com fundo opaco o Aseprite grava em RGB
                with self.subTest(f"{name} quadro {i}"):
                    self.assertEqual(pixels(ase.render(sprite, i, native=True)), pixels(Image.open(FIX / png)))

    def test_escreve_os_mesmos_bytes_que_o_aseprite_abriu(self):
        for name, make in CASES.items():
            with self.subTest(name):
                self.assertEqual(ase.write(make()), (FIX / f"{name}.aseprite").read_bytes())

    def test_o_aseprite_regrava_sem_perder_nada(self):
        for name, case in MANIFEST["cases"].items():
            if "resaved" in case:
                with self.subTest(name):
                    mine, back = ase.read(FIX / name), ase.read(FIX / case["resaved"])
                    self.assertEqual(diff(describe(back, full=True), describe(mine, full=True)), [])
                    for i in range(mine.frames):
                        self.assertEqual(ase.render(back, i, native=True).tobytes(),
                                         ase.render(mine, i, native=True).tobytes(), f"quadro {i}")

    def test_ida_e_volta_byte_a_byte(self):
        for name in MANIFEST["cases"]:
            with self.subTest(name):
                once = ase.write(ase.read(FIX / name))
                self.assertEqual(ase.write(ase.read(once)), once)
                self.assertEqual(diff(describe(ase.read(once)), describe(ase.read(FIX / name))), [])

    def test_folha_e_json_como_a_cli(self):
        for s in MANIFEST["sheets"]:
            with self.subTest(s["label"]):
                src = s["source"].removesuffix(".aseprite")
                img, data = sheet(ase.read(FIX / s["source"]), src, f"{s['label']}.png", **s["options"])
                theirs = json.loads((FIX / f"{s['label']}.json").read_text(encoding="utf-8"))
                for doc in (data, theirs):
                    doc["meta"].pop("app")
                    doc["meta"].pop("version")
                self.assertEqual(diff(data, theirs), [])
                ref = Image.open(FIX / f"{s['label']}.png")
                self.assertEqual(img.mode, ref.mode)
                self.assertEqual(pixels(img), pixels(ref))

    def test_exporta_por_camada_como_o_script(self):
        for name, stems in MANIFEST["script"].items():
            with self.subTest(name):
                mine = empire.export_layers(ase.read(FIX / name), name.removesuffix(".aseprite"))
                self.assertEqual(sorted(s for s, _, _ in mine), stems)
                for stem, img, data in mine:
                    theirs = json.loads((FIX / "export" / f"{stem}.json").read_text(encoding="utf-8"))
                    for doc in (data, theirs):
                        doc["meta"].pop("app")
                        doc["meta"].pop("version")
                    self.assertEqual(diff(data, theirs), [], stem)
                    self.assertEqual(pixels(img), pixels(Image.open(FIX / "export" / f"{stem}.png")), stem)


class FormatoTest(unittest.TestCase):
    def test_a_paleta_encolhe_quando_o_chunk_o_diz(self):
        img = Image.new("P", (2, 2), 1)
        pal = [(0, 0, 0, 255, None), (255, 0, 0, 255, None), (0, 255, 0, 255, None), (0, 0, 255, 255, None)]
        s = ase.build((2, 2), [("a", [img, img])], [100, 100], depth=8, palette=pal)
        s.palettes[1] = pal[:2]  # o decoder do Aseprite faz resize para o tamanho declarado
        back = ase.read(ase.write(s))
        self.assertEqual([len(back.palette(f)) for f in range(2)], [4, 2])


class MisturaTest(unittest.TestCase):
    def test_aritmetica_de_8_bits_do_aseprite(self):
        self.assertEqual([blend.mul(a, b) for a, b in [(255, 255), (128, 128), (0, 200), (200, 1)]], [255, 64, 0, 1])
        self.assertEqual(blend.div(128, 255), 128)
        self.assertEqual(blend.normal((10, 20, 30, 0), (200, 100, 50, 255), 128), (200, 100, 50, 128))
        self.assertEqual(blend.normal((10, 20, 30, 255), (200, 100, 50, 0), 255), (10, 20, 30, 255))

    def test_cinzento_segue_as_excecoes_do_aseprite(self):
        b, s = (100, 255), (200, 255)
        self.assertEqual(blend.blend("hue", b, s, 255), blend.blend("normal", b, s, 255))
        self.assertEqual(blend.blend("addition", b, s, 255), blend.blend("exclusion", b, s, 255))
        self.assertEqual(len(blend.MODES), 19)


if __name__ == "__main__":
    unittest.main()
