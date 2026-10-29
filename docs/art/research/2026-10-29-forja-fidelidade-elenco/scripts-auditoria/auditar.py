"""Auditoria de leitura; nao altera sprites nem codigo da Forja."""
from __future__ import annotations
import argparse
import copy
import hashlib
import json
import shutil
import sys
from pathlib import Path


def read(path):
    return json.loads(path.read_text())


def write(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n")


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def audit(package, repo, out):
    sys.path.insert(0, str(repo))
    from PIL import Image
    from tools.forja import fidelity, gridcheck, pipeline
    from tools.forja.equipment import image_sha
    out.mkdir(parents=True, exist_ok=True)
    cases = out / "casos"
    cases.mkdir(exist_ok=True)
    rows = []
    for p in sorted((package / "Forja").iterdir()):
        if not p.is_dir() or not (p / "contract.json").exists():
            continue
        cid = p.name
        contract = read(p / "contract.json")
        ch = contract["characters"][0]
        forge = read(p / (cid + ".json"))
        st = read(p / "fidelity-state.json")
        previous = "edit-snap.json" if (p / "edit-snap.json").exists() else "recovery-snap.json"
        prior = read(p / previous)
        final = Image.open(package / "Sprites" / (cid + ".png")).convert("RGBA")
        old = Image.open(package.parent / "EMPIRE-Sprites-15-v2" / "Sprites" / (cid + ".png")).convert("RGBA")
        row = dict(character=cid, canvas=list(final.size), pixels_sha256=image_sha(final),
                   unchanged_from_v2=final.tobytes() == old.tobytes(),
                   prior_recovery=dict(file=previous, purity=prior["sample"].get("purity"),
                                       erased_cells=prior["loss"]["erased_cells"]),
                   final_recovery=dict(erased_cells=forge["snap"]["loss"]["erased_cells"],
                                       source=forge["provenance"]["input"]),
                   summary=st["summary"], deliverable=st["deliverable"],
                   legacy_delivery=forge["delivery"],
                   face_box=ch["critical_regions"][0]["target_box"])
        rows.append(row)
    flask = read(package / "flask-comparison.json")
    sets, bottles = [], []
    for b in flask["characters"]:
        x0, y0, x1, y1 = b["bbox"]
        points = {(x-x0, y-y0) for x, y in b["pixels"]}
        sets.append(points)
        bottles.append(dict(character=b["character"], size=b["size"], visible_pixels=len(points),
                            row_widths=[sum(y == j for x, y in points) for j in range(y1-y0)],
                            identical_to_v2=b["flask_pixels_identical_to_v2"]))
    mirrored = {(12-x, y) for x, y in sets[1]}
    flask_result = dict(bottles=bottles, same_envelope=bottles[0]["size"] == bottles[1]["size"],
                        visible_mask_iou=len(sets[0] & sets[1]) / len(sets[0] | sets[1]),
                        visible_mask_mirrored_iou=len(sets[0] & mirrored) / len(sets[0] | mirrored),
                        caveat="Mascaras visiveis, com oclusoes diferentes; IoU nao prova defeito artistico.")
    p = package / "Forja" / "alchemist_squire" / "contract.json"
    original = read(p)
    changed = copy.deepcopy(original)
    changed["characters"][0]["shared_prop_constraints"][0]["native_shared_dimensions"] = [99, 3]
    before = fidelity.validate(original, p.parent)
    after = fidelity.validate(changed, p.parent)
    assert before == after == []
    constraint = dict(original_errors=before, mutated_errors=after, mutation=[99, 3],
                      result="Mudar apenas shared_prop_constraints nao muda a validacao atual.")
    source = package / "Forja" / "mercenary" / "expression-edit-source.png"
    image = Image.open(source).convert("RGBA")
    grid, sampled = gridcheck.measure(image)
    native, snap = pipeline.snap(image, pipeline.Options(palette="none", noise=0, outline="keep", bg="keep"),
                                 grid, sampled)
    teeth = [[38, 23], [39, 23], [38, 24], [39, 24]]
    hits = [e for e in snap["loss"]["erased"] if e["cell"] in teeth]
    assert len(hits) == 4
    assert snap["sample"]["purity"] == 0.97
    native.save(cases / "mercenary-recovered.png")
    shutil.copy2(source, cases / "mercenary-source.png")
    write(cases / "mercenary-snap.json", snap)
    write(cases / "mercenary-grid.json", grid.as_dict())
    write(cases / "mercenary-teeth.json", dict(teeth=teeth, erased=hits,
          already_repaired_in_v3=True, demonstrates="Perda na etapa original; nao afirmar que os quatro continuam ausentes no PNG v3."))
    for cid in ("alchemist_emperor", "alchemist_squire", "miner_squire", "mercenary"):
        folder = cases / cid
        folder.mkdir(exist_ok=True)
        src = package / "Forja" / cid
        for name in ("contract.json", "fidelity-state.json", cid+".json", "flask-mask.json", "source-preservation.json"):
            if (src / name).exists():
                shutil.copy2(src / name, folder / name)
        shutil.copy2(package / "Sprites" / (cid+".png"), folder / "final.png")
    write(out / "elenco.json", rows)
    write(out / "frascos.json", flask_result)
    write(out / "teste-restricao-compartilhada.json", constraint)
    summary = dict(schema="empire.forja_audit/1", date="2026-10-29", examined=len(rows),
        runtime_pass=sum(r["summary"]["runtime"] == "pass" for r in rows),
        signals_pass=sum(r["summary"]["declared_feature_preservation"] == "pass" for r in rows),
        deliverable=sum(r["deliverable"] for r in rows),
        unchanged=sum(r["unchanged_from_v2"] for r in rows),
        final_zero_loss=sum(r["final_recovery"]["erased_cells"] == 0 for r in rows),
        original_mercenary_purity=snap["sample"]["purity"],
        original_mercenary_erased=snap["loss"]["erased_cells"],
        reproduced_erased_teeth=len(hits),
        shared_constraint_mutation_ignored=before == after,
        interpretation="Passes tecnicos nao aprovam a arte; o feedback atual rejeita a qualidade do lote.",
        game_and_aseprite_app_tested=False)
    write(out / "resumo.json", summary)
    code = []
    for name in ("resample.py", "loss.py", "signals.py", "limits.py", "pipeline.py", "review_state.py",
                 "production.py", "equipment.py", "provenance.py", "visual_review.py", "fidelity.py"):
        p = repo / "tools" / "forja" / name
        code.append(dict(path="tools/forja/"+name, sha256=sha(p), lines=len(p.read_text().splitlines())))
        shutil.copy2(p, out.parent / "fontes" / name)
    for name in ('patch_cast_v2.py', 'export_personality_v3.py', 'select_personality_v3.py'):
        p = package.parent / name
        code.append(dict(path=name, sha256=sha(p), lines=len(p.read_text().splitlines())))
        shutil.copy2(p, out.parent / 'fontes' / name)
    write(out / "codigo-conferido.json", code)
    assert len(rows) == 15 and summary["runtime_pass"] == 15 and summary["deliverable"] == 0
    print(json.dumps(summary, ensure_ascii=False))


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--package", type=Path, required=True)
    parser.add_argument("--repo", type=Path, required=True)
    parser.add_argument("--out", type=Path, default=Path(__file__).resolve().parents[1] / "evidencias")
    args = parser.parse_args()
    audit(args.package.resolve(), args.repo.resolve(), args.out.resolve())
