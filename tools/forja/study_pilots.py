"""Provas pequenas de variantes e cenario; exportar a prancha nao escolhe nem aprova arte."""
from __future__ import annotations

import html
import json
from pathlib import Path

from PIL import Image

from . import cast, contracts, owner_rules, proof_io, refs, scene, study
from .equipment import image_sha
from .imageops import open_rgba
from .review_evidence import Review, box, pending, text

SCHEMA = "forja.study_pilot/1"
VARIATION_CHECKS = ("silhouette", "proportions", "facial_acting", "function", "native_readability")
SCENE_CHECKS = ("masses_before_detail", "actor_scale", "door_or_bank", "lower_access", "three_planes",
                "day_night_contrast", "seams", "material_junctions", "biome_groups", "procedural_cleanup")


def _finish(out: Path, data: dict, files: list[str], views: list[str], checks: list[str]) -> dict:
    data.update(schema=SCHEMA, study=study.context(), release_ready=False, runtime_integration="not_evaluated")
    manifest = proof_io.seal(data, out, files)
    doc = {"schema": "forja.pilot_review/1", "manifest_sha256": manifest["manifest_sha256"],
           "observer": {"author": "", "method": "", "date": ""},
           "views": {"native_1x": False, "integer_zoom": None},
           "checks": {k: pending() for k in checks}}
    proof_io.save(out / "review.template.json", doc)
    figures = "".join('<figure><figcaption>' + html.escape(name) +
                      '</figcaption><img src="' + name + '" alt="' + html.escape(name) + '"></figure>' for name in views)
    (out / "index.html").write_text('<!doctype html><html lang="pt"><meta charset="utf-8">'
        '<meta name="viewport" content="width=device-width,initial-scale=1"><title>Forja · Prova de estudo</title>'
        '<style>body{font:16px system-ui;background:#24201b;color:#eee;padding:24px}main{overflow:auto}'
        'img{image-rendering:pixelated;max-width:none}figure{margin:20px 0}a{color:#f0c578}'
        '</style><h1>Prova de estudo · revisão pendente</h1><label>Ampliação <select id="zoom">'
        '<option>1</option><option>2</option><option>4</option></select>×</label><p>Comece a 1×. '
        'Sem aprovação artística ou teste de runtime.</p><main>' + figures +
        '</main><a href="review.template.json" download>Ficha de revisão</a><script>'
        'document.getElementById("zoom").onchange=e=>document.querySelectorAll("img").forEach(i=>'
        '{i.style.width=(i.naturalWidth*Number(e.target.value))+"px"});</script></html>', encoding="utf-8")
    return {"ok": True, "manifest": str(out / "manifest.json"), "preview": str(out / "index.html"),
            "review_template": str(out / "review.template.json"), "release_ready": False, "review": "pending"}


def variations(paths, kind: str, out, function: str, character=None, register=None) -> dict:
    if character:
        entry = cast.character(cast.load(), character)
        raise ValueError(entry["id"] + ": design escolhido; usar preservacao/reparo, nao substituir por variantes")
    if not text(function) or len(paths) < 2:
        raise ValueError("variantes: funcao explicita e pelo menos duas alternativas")
    c = contracts.get(kind)
    images = [open_rgba(p) for p in paths]
    if not c.canvas or any(list(im.size) != list(c.canvas) for im in images):
        raise ValueError("variantes precisam da mesma grade nativa contratada")
    reg = refs.load(register) if register else None
    for im in images:
        if owner_rules.rejected(image_sha(im)) or refs.record(reg, im)["state"] == "rejected":
            raise ValueError("variante rejeitada nao entra como alternativa de autoridade")
    if len({image_sha(im) for im in images}) != len(images):
        raise ValueError("variantes identicas: comparar alternativas distintas")
    out = Path(out)
    out.mkdir(parents=True, exist_ok=True)
    files, items = [], []
    for i, im in enumerate(images):
        name = f"candidate-{i:03d}.png"
        if any(Path(p).resolve() == (out / name).resolve() for p in paths):
            raise ValueError("saida deve ser separada das fontes")
        im.save(out / name)
        files.append(name)
        items.append({"id": str(i), "file": name, "pixels_sha256": image_sha(im), "decision": "unapproved"})
    checks = [str(i) + ":" + key for i in range(len(items)) for key in VARIATION_CHECKS]
    return _finish(out, {"type": "variations", "kind": kind, "canvas": list(c.canvas), "function": function,
                         "candidates": items, "required_checks": checks}, files, files, checks)


def scene_pilot(spec_path, out) -> dict:
    spec_path, out = Path(spec_path), Path(out)
    if out.resolve() == spec_path.parent.resolve() or out.resolve() in spec_path.resolve().parents:
        raise ValueError("o piloto usa uma pasta separada das fontes")
    spec = json.loads(spec_path.read_text(encoding="utf-8"))
    if spec.get("schema") != "forja.scene_pilot/1":
        raise ValueError("piloto de cenario: schema invalido")
    base = spec_path.parent
    inputs = [spec[n] for n in ("contract", "masses", "night", "actor", "night_foreground")] + list(spec["planes"].values())
    if any(out.resolve() in (base / name).resolve().parents for name in inputs):
        raise ValueError("o piloto nao pode escrever sobre as suas fontes")
    res = scene.resolve(scene.load(base / spec["contract"]))
    size = res["extent_px"]
    names = ("background", "midground", "foreground")
    planes = {n: open_rgba(base / spec["planes"][n]) for n in names}
    masses, night, actor, night_front = [open_rgba(base / spec[n]) for n in ("masses", "night", "actor", "night_foreground")]
    if any(list(im.size) != size for im in [masses, night, night_front, *planes.values()]):
        raise ValueError("planos, massas e noite precisam da extensao nativa do contrato")
    c = contracts.get(spec["actor_kind"])
    if list(actor.size) != list(c.canvas or []):
        raise ValueError("ator fora da grade contratada")
    at = spec.get("actor_at")
    if not isinstance(at, list) or len(at) != 2 or any(type(v) is not int for v in at) or not (
            0 <= at[0] <= size[0] - actor.width and 0 <= at[1] <= size[1] - actor.height):
        raise ValueError("ator deve caber inteiro, sem escala, no piloto")
    if not box(spec.get("lower_access"), size) or any(not box(b, size) for b in spec.get("procedural_regions", [])):
        raise ValueError("acesso inferior ou regioes procedurais invalidos")
    if not spec.get("biome_groups") or any(not text(g) for g in spec["biome_groups"]):
        raise ValueError("declarar agrupamentos caracteristicos do bioma")
    out.mkdir(parents=True, exist_ok=True)
    reg = refs.load(base / spec["reference_register"]) if spec.get("reference_register") else None
    actor_state = refs.record(reg, actor)["state"]
    if actor_state == "rejected" or owner_rules.rejected(image_sha(actor)):
        raise ValueError("ator rejeitado nao pode servir de regua")
    day = Image.new("RGBA", tuple(size))
    for n in names[:2]:
        day.alpha_composite(planes[n])
    files = []
    products = {"masses": masses, "day": Image.alpha_composite(day, planes["foreground"]),
                "night": Image.alpha_composite(night, night_front), "actor": actor, **planes,
                "night-background": night, "night-foreground": night_front}
    for label, background, front in (("day-with-actor", day, planes["foreground"]), ("night-with-actor", night, night_front)):
        shown = background.copy()
        shown.alpha_composite(actor, tuple(at))
        shown.alpha_composite(front)
        products[label] = shown
    for name, im in products.items():
        im.save(out / (name + ".png"))
        files.append(name + ".png")
    proof_io.save(out / "scene-contract.json", {k: v for k, v in res["scene"].items() if not k.startswith("_")})
    files.append("scene-contract.json")
    checks = list(SCENE_CHECKS)
    return _finish(out, {"type": "scene", "canvas": size, "scene_id": res["id"], "actor_state": actor_state,
        "actor_at": at, "actor_kind": spec["actor_kind"], "lower_access": spec["lower_access"],
        "procedural_regions": spec.get("procedural_regions", []), "biome_groups": spec["biome_groups"],
        "required_checks": checks}, files, ["masses.png", "day-with-actor.png", "night-with-actor.png"], checks)


def review(path, doc: dict) -> dict:
    manifest, errors = proof_io.check(path, SCHEMA)
    r = Review()
    r.blocking.extend(errors)
    r.require(doc.get("schema") == "forja.pilot_review/1" and
              doc.get("manifest_sha256") == manifest["manifest_sha256"], "revisao de outro piloto", True)
    r.require(manifest["study"]["revision"] == study.context()["revision"], "estudo desatualizado", True)
    r.observer(doc)
    views = doc.get("views") or {}
    r.require(views.get("native_1x") is True and type(views.get("integer_zoom")) is int and
              views["integer_zoom"] >= 2, "rever a 1x e ampliacao inteira")
    for key in manifest["required_checks"]:
        r.evidence((doc.get("checks") or {}).get(key), key)
    if manifest["type"] == "scene":
        r.require(manifest["actor_state"] == "approved", "ator de escala sem aprovacao no registo")
    return r.result()
