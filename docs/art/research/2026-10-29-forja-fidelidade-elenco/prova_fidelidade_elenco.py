#!/usr/bin/env python3
"""A prova do FORJA-15: a auditoria de fidelidade de 29/10 refeita como benchmark do elenco, com a Forja deste ramo.

A auditoria (`AUDITORIA.md`) mostrou que as dimensoes certas e os pixels protegidos nao conservaram a pocao nem a
personalidade. Aqui os mesmos casos viram regressao, com as imagens reais do pacote e mutacoes controladas:
1. cadeia (P0-01, caso C e D): a fonte arquivada da mercenaria perde os quatro dentes com pureza 0,970; a perda e
   critica e vai para a cadeia com os votos; reexportar a base nativa da zero perdas nessa etapa e o fecho continua
   bloqueado; sem a etapa anterior, a cadeia que comeca numa base nativa fica pendente;
2. frasco (P0-02, caso A): os dois frascos v3 tem o mesmo envelope 13x20 e isso nao prova o molde (pendente); a medida
   99x3 da mutacao da auditoria e recusada; no molde de teste, o bojo afinado no mesmo envelope falha, o ambar e o
   espelho declarado passam e um modelo proposto nunca da `pass`;
3. rosto (P0-03, caso B): a pupila mudada de lado e o sorriso torto trocado por uma linha bloqueiam; os pinos tirados
   do candidato nao preenchem a fidelidade;
4. elenco (P2-01): por personagem, a ficha facial (intencao, marcos, caixas no conceito, relacoes), a restricao
   partilhada e a autoridade (o recorte do conceito, nunca o candidato, e o gabarito). Nao ha mestre nativo aprovado:
   o benchmark tem zero exemplos bons revistos ate o dono aprovar um.
Sem rede, sem geracao, sem aprovacao. Grava `prova.json`; falha se um criterio nao se cumprir.

    python3 docs/art/research/2026-10-29-forja-fidelidade-elenco/prova_fidelidade_elenco.py
"""
from __future__ import annotations

import copy
import json
import sys
import tempfile
from pathlib import Path

from PIL import Image

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
sys.path.insert(0, str(ROOT))
from tools.forja import cast, equipment, face, fidelity, geometry, lineage, pipeline, prop_shape, props  # noqa: E402
from tools.forja import refs, review_state  # noqa: E402
from tools.forja.equipment import image_sha  # noqa: E402
from tools.forja.tests import fidelity_fixtures as ff  # noqa: E402

EVIDENCE = HERE / "evidencias"
TEETH = [[38, 23], [39, 23], [38, 24], [39, 24]]
REGION = {"schema": "forja.signals/1", "pins": [],
          "regions": [{"id": "dentes", "required": True, "purpose": "dentes", "source_box": [745, 451, 784, 490]}]}
CH = {"id": "mercenary", "pose": "idle", "pixel_pins": [], "critical_regions": [], "face_sheet": None}
checks: list[dict] = []


def check(label: str, ok: bool, **detail) -> None:
    assert ok, (label, detail)
    checks.append({"check": label, "status": "pass", **detail})


def forge(src, out, name, **kw) -> dict:
    opts = pipeline.Options(palette="none", noise=0, outline="keep", bg="keep", fit=False, **kw)
    return pipeline.forge(src, out, opts, name=name, report_html=False)


def cadeia(tmp: Path) -> dict:
    first = forge(EVIDENCE / "casos/mercenary-source.png", tmp / "a", "merc", signals=REGION)
    teeth = [o for o in first["lineage"]["occurrences"] if o["cell"] in TEETH]
    check("dentes_apagados_com_pureza_0970", first["snap"]["sample"]["purity"] == 0.97 and len(teeth) == 4,
          purity=first["snap"]["sample"]["purity"], erased=first["snap"]["loss"]["erased_cells"])
    check("dentes_criticos_com_votos", all(o["critical"] and len(o["votes"]) >= 2 for o in teeth),
          votes=[[v["color"] for v in o["votes"]] for o in teeth])
    second = forge(tmp / "a/merc.png", tmp / "b", "merc2", lineage=first["lineage"])
    final = Image.open(second["files"]["png"]).convert("RGBA")
    close = review_state.review(CH, final, None, second["lint"], second)["release"]
    check("reexportar_nao_encerra", second["snap"]["loss"]["erased_cells"] == 0 and close["status"] == "blocked"
          and len(close["open_critical"]) == 4, open=[o["id"] for o in close["open_critical"]])
    lone = forge(tmp / "a/merc.png", tmp / "c", "merc3")
    alone = review_state.review(CH, final, None, lone["lint"], lone)["release"]
    check("base_nativa_sem_cadeia_fica_pendente", lone["lineage"]["root"]["kind"] == "native_input" and
          any("base ja nativa" in r for r in alone["reasons"]))
    check("forge_nao_chama_entrega", not first["delivery"]["release_ready"] and not second["delivery"]["release_ready"]
          and "usable_sprite" not in second["delivery"], labels=[first["delivery"]["label"], second["delivery"]["label"]])
    return {"first_stage": {"purity": first["snap"]["sample"]["purity"], "erased": first["snap"]["loss"]["erased_cells"],
                            "critical": sum(o["critical"] for o in first["lineage"]["occurrences"])},
            "second_stage": {"erased": 0, "carried": second["lineage"]["stages"][-1]["carried"],
                             "closure": close["status"]}}


def frascos() -> dict:
    sides = []
    for who in ("alchemist_emperor", "alchemist_squire"):
        mask = json.loads((EVIDENCE / "casos" / who / "flask-mask.json").read_text(encoding="utf-8"))
        with Image.open(EVIDENCE / "casos" / who / "final.png") as im:
            check(f"mascara_do_png_v3_{who}", image_sha(im) == mask["image_pixels_sha256"])
        item = equipment.items({"items": [{"id": "alchemy_standard_flask", "family": "flask", "slot": "weapon",
                                           "state": "held"}]})[0]
        obs = {"regions": {"alchemy_standard_flask.body": frozenset(map(tuple, mask["pixels"]))}}
        sides.append({"character": who, "measure": prop_shape.measure(item, obs), "shape": None})
    contract = fidelity.load(ROOT / "docs/art/concepts/2026-10-29-elenco/contracts/alchemist_squire.json")
    rule = contract["characters"][0]["shared_prop_constraints"][0]
    pair = props.pair(rule, *sides)
    check("v3_mesmo_envelope_nao_prova_o_molde", pair["status"] == "pending" and
          pair["envelopes"]["alchemist_squire"] == [13, 20] == pair["envelopes"]["alchemist_emperor"])
    bad = copy.deepcopy(contract)
    bad["characters"][0]["shared_prop_constraints"][0]["native_shared_dimensions"] = [99, 3]
    errors = fidelity.validate(bad, Path(contract["base"]))
    check("mutacao_99x3_recusada", any("nao cabe" in e for e in errors), errors=errors)
    shapes = {}
    for label, rows, mirror, allowed, status in (("molde", ff.FLASK, False, (), "approved"),
                                                 ("bojo_fino_gargalo_longo", ff.THIN, False, (), "approved"),
                                                 ("espelho_declarado", ff.SPOUT, True, ("orientation",), "approved"),
                                                 ("espelho_nao_declarado", ff.SPOUT, True, (), "approved"),
                                                 ("modelo_proposto", ff.FLASK, False, (), "proposed")):
        img, regions = ff.scene(rows, mirror=mirror, glass=ff.LIQUID)
        man = ff.manifest(allowed=allowed, status=status, rows=ff.SPOUT if rows is ff.SPOUT else None)
        got = [c for c in geometry.evaluate(man, ff.observe(img, regions)) if c["check"] == "prop_shape"][0]
        shapes[label] = got["status"]
    check("forma_do_frasco", shapes == {"molde": "pass", "bojo_fino_gargalo_longo": "fail", "espelho_declarado": "pass",
                                        "espelho_nao_declarado": "fail", "modelo_proposto": "inconclusive"},
          shapes=shapes)
    return {"v3_pair": {k: pair[k] for k in ("status", "envelopes", "declared")}, "shapes": shapes}


def rostos() -> dict:
    out = {}
    for label, image in (("conceito", ff.face_image()), ("pupila_movida", ff.face_image(pupil="right")),
                         ("linha_neutra", ff.face_image(mouth="neutral"))):
        got = face.check(ff.sheet(), image)
        out[label] = {"status": got["status"], "failed": [r["id"] for r in got["relations"] if r["status"] == "fail"]}
    check("rosto_t05_t06", out["conceito"]["status"] == "pass" and out["pupila_movida"]["failed"] == ["gaze"] and
          out["linha_neutra"]["failed"] == ["smile"], faces=out)
    pins = [{"id": f"p{x}", "target_pixel": [x, 18], "color": "#962832", "status": "authorized"} for x in range(6, 13)]
    ch = {"id": "x", "pose": "p", "pixel_pins": pins, "critical_regions": [], "face_sheet": None}
    kept = review_state.review(ch, ff.face_image(mouth="neutral"))["states"]["declared_feature_preservation"]
    check("pinos_do_candidato_nao_provam", kept["status"] == "pending" and
          kept["candidate_protection"]["status"] == "pass")
    return out


def elenco() -> list[dict]:
    data = cast.load()
    register = refs.load(Path(data["base"]) / data["reference_register"])
    check("nenhum_mestre_aprovado_no_registo", all(e["state"] != "approved" for e in register["entries"]))
    rows = []
    for entry in data["characters"]:
        contract = cast.authority(data, entry)
        ch = fidelity.character(contract, entry["id"], entry.get("pose"))
        sheet = ch.get("face_sheet") or {}
        marks = sheet.get("landmarks", [])
        crop = fidelity.authority_crop(contract, ch)
        state = face.check(sheet, Image.new("RGBA", tuple(ch["target_canvas"])))
        rows.append({"character": entry["id"], "face_sheet": sheet.get("status"), "landmarks": len(marks),
                     "landmarks_in_concept": sum(1 for m in marks if m.get("authority_box")),
                     "relations": len(sheet.get("relations", [])),
                     "reserved_in_native_grid": sum(1 for m in marks if m.get("target_box")),
                     "face_check": state["status"], "shared_props": [c["id"] for c in ch.get("shared_prop_constraints")
                                                                    or []],
                     "authority_crop_pixels_sha256": image_sha(crop)})
    check("elenco_completo_com_ficha", len(rows) == 15 and all(r["face_sheet"] and r["landmarks"] for r in rows))
    check("ficha_pendente_nao_passa", all(r["face_check"] != "pass" for r in rows))
    check("par_dos_alquimistas_anotado", all(r["landmarks_in_concept"] >= 6 and r["relations"] >= 2 for r in rows
                                             if r["character"].startswith("alchemist")))
    return rows


def main() -> None:
    with tempfile.TemporaryDirectory(prefix="forja-prova-15-") as tmp:
        chain = cadeia(Path(tmp))
    result = {"schema": "empire.forja_prova/1", "ticket": "FORJA-15", "audit": "AUDITORIA.md (29/10/2026)",
              "chain": chain, "flask": frascos(), "faces": rostos(), "cast": elenco(),
              "reviewed_good_examples": 0,
              "limits": ["nenhum mestre nativo aprovado: sem exemplos bons revistos no benchmark",
                         "o molde do frasco e as caixas nativas dos marcos estao por desenhar e aprovar (Q-304, Q-305)",
                         "fixtures sinteticas isolam a medida; nao sao o frasco nem o rosto de nenhum personagem"],
              "checks": checks}
    (HERE / "prova.json").write_text(json.dumps(result, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps({"checks": len(checks), "status": "pass"}))


if __name__ == "__main__":
    main()
