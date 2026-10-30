"""Plano nativo: mestre exato, autoridade atual, poses e pedido validado antes da rede."""
from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path

from . import animation_files, choreography, contracts, durable, face, fidelity, lineage, lint, owner_rules, palette, refs
from .backends import digest, sha
from .backends import pixellab_animation as api
from .equipment import image_sha

SCHEMA = "forja.native_animation_plan/1"


def source_errors(ch: dict, image, parent: dict | None, native_root: bool, resolutions: list) -> list[str]:
    if parent:
        if parent.get("schema") != lineage.SCHEMA or parent.get("output_sha256") != image_sha(image):
            return ["a cadeia da referencia nao corresponde a este mestre individual"]
        if lineage.delivery(True, parent)["diagnostic_only"]:
            return ["mestre reduzido: redesenhar na grade nativa antes de animar"]
        required = [r for r in ch.get("critical_regions", []) if r.get("required", True)]
        boxes = {r["id"]: r["target_box"] for r in required if r.get("target_box")} | face.boxes(ch.get("face_sheet"))
        closed = lineage.closure(parent, image, boxes, resolutions,
                                 [r["id"] for r in required if not r.get("target_box")])
        if closed["status"] != "pass":
            return ["perdas da referencia pendentes: resolver o mestre antes de animar", *closed["reasons"]]
    elif not native_root:
        return ["origem do mestre ausente: conservar --lineage ou declarar --native-root"]
    return []


@dataclass
class AnimationPlan:
    data: dict
    first: bytes
    last: bytes | None
    skeleton: dict | None

    @property
    def ok(self) -> bool:
        return not self.data["errors"]

    def call(self):
        d = self.data
        if not self.ok:
            raise ValueError("; ".join(d["errors"]))
        return api.call(self.first, d["action"], d["frame_count"], d["model"], last_frame=self.last,
                        skeleton=self.skeleton, description=d["description"], direction=d["direction"],
                        seed=d["seed"], drift_threshold=d["drift_threshold"])

    def write(self, folder: str | Path) -> Path:
        out = animation_files.destination(folder)
        out.mkdir(parents=True, exist_ok=True)
        (out / "first.png").write_bytes(self.first)
        if self.last is not None:
            (out / "last.png").write_bytes(self.last)
        if self.skeleton is not None:
            durable.write_text(out / "skeleton.json", json.dumps(self.skeleton, indent=1, allow_nan=False) + "\n")
        return durable.write_text(out / "plan.json", json.dumps(self.data, ensure_ascii=False, indent=1) + "\n")


def make(first_path: str | Path, contract: dict, character: str, tag: str, *, model: str = "text-v3",
         frame_count: int | None = None, action: str | None = None, description: str | None = None,
         direction: str = "east", seed: int = 0, drift_threshold: float | None = None,
         last_path: str | Path | None = None, skeleton: dict | None = None, register: dict | None = None,
         source_lineage: dict | None = None, native_root: bool = False, resolutions: list | None = None,
         last_lineage: dict | None = None, last_native_root: bool = False,
         last_resolutions: list | None = None) -> AnimationPlan:
    ch = fidelity.character(contract, character)
    c = contracts.get(ch["kind"])
    first = Path(first_path).read_bytes()
    image = api._image(first)
    last = Path(last_path).read_bytes() if last_path else None
    spec = contracts.tag(tag) or {}
    count = frame_count if frame_count is not None else spec.get("frames")
    errors = []
    if list(image.size) != ch["target_canvas"]:
        errors.append(f"tela da referencia {list(image.size)} difere de {ch['target_canvas']}; nao se reduz")
    if type(count) is not int or count < 1:
        errors.append("acao sem contagem conhecida: declarar --frames como estudo")
        count = 0
    errors += source_errors(ch, image, source_lineage, native_root, resolutions or [])
    rejected = owner_rules.rejected(image_sha(image)) or fidelity.rejected(ch, image)
    if rejected:
        errors.append("referencia rejeitada pelo dono: nao pode ser animada como identidade")
    _, reference, ref_error = refs.resolve("identity", first, register)
    if ref_error:
        errors.append(ref_error)
    master_lint = lint.check(image, c, palette.load(palette.ROOT / c.palette))
    if not master_lint["ok"]:
        errors.append("mestre fora do contrato raster: corrigir antes de animar")
    last_source = None
    if last is not None:
        end = api._image(last)
        errors += ["pose final: " + e for e in source_errors(ch, end, last_lineage,
                                                          last_native_root, last_resolutions or [])]
        _, end_ref, end_error = refs.resolve("identity", last, register)
        if end_error or owner_rules.rejected(image_sha(end)) or fidelity.rejected(ch, end):
            errors.append("pose final: referencia rejeitada ou em conflito")
        if not lint.check(end, c, palette.load(palette.ROOT / c.palette))["ok"]:
            errors.append("pose final fora do contrato raster")
        last_source = {"pixels_sha256": image_sha(end), "reference": end_ref, "lineage": last_lineage,
                       "native_root": last_native_root, "resolutions": last_resolutions or []}
    consulted = owner_rules.context({"character": ch["id"], "crop_pixels_sha256": ch["_authority_crop_sha256"],
                                     "authority_sha256": contract["authority"]["sha256"]})
    motion = choreography.plan([(tag, count)], image.size, c.pivot) if count else None
    text = action or (f"{tag} in place, facing {direction}. Keep the same face, head volume, clothing, hands and equipment. "
                      "Articulate shoulders, elbows, wrists, hips, knees and feet; preserve grip and occlusion. "
                      "Keep the native canvas, ground line and body scale. Draw true inbetweens, not rigid cutouts.")
    if action is None and motion and model == "text-v3":
        text += " Zero-based key poses: " + json.dumps(motion["tags"][0]["keyframes"], separators=(",", ":"))
        text += ". Review articulation, grip, weight and the loop seam or final held pose."
    if model == "skeleton-v3":
        text = action or tag
    d = {"schema": SCHEMA, "fidelity_file": str(Path(contract["path"]).resolve()), "character": ch,
         "tag": tag, "model": model, "frame_count": count, "canvas": list(image.size), "pivot": list(c.pivot),
         "action": text, "description": description, "direction": direction, "seed": seed,
         "drift_threshold": drift_threshold, "has_last": last is not None, "has_skeleton": skeleton is not None,
         "source_pixels_sha256": image_sha(image), "source_bytes_sha256": sha(first),
         "last_bytes_sha256": sha(last) if last else None, "reference": reference,
         "register_file": (register or {}).get("path"), "owner_rules": consulted, "animation_plan": motion,
         "source_lineage": source_lineage, "native_root": native_root, "source_resolutions": resolutions or [],
         "last_source": last_source,
         "master_lint": master_lint, "errors": errors, "request": None, "release_ready": False}
    try:
        request = api.call(first, text, count, model, last_frame=last, skeleton=skeleton, description=description,
                           direction=direction, seed=seed, drift_threshold=drift_threshold)
        d.update(request=request.descriptor, request_sha256=digest(request.descriptor))
    except ValueError as err:
        errors.append(str(err))
    return AnimationPlan(d, first, last, skeleton)


def load(path: str | Path) -> AnimationPlan:
    path = Path(path)
    d = json.loads(path.read_text(encoding="utf-8"))
    if d.get("schema") != SCHEMA or d.get("errors"):
        raise ValueError("plano de animacao invalido: recompilar com forja anim-plan")
    contract = fidelity.load(d["fidelity_file"])
    end = d.get("last_source") or {}
    p = make(path.parent / "first.png", contract, d["character"]["id"], d["tag"], model=d["model"],
        frame_count=d["frame_count"], action=d["action"], description=d["description"], direction=d["direction"],
        seed=d["seed"], drift_threshold=d.get("drift_threshold"),
        last_path=path.parent / "last.png" if d["has_last"] else None,
        skeleton=json.loads((path.parent / "skeleton.json").read_text()) if d["has_skeleton"] else None,
        register=refs.load(d["register_file"]) if d.get("register_file") else None,
        source_lineage=d.get("source_lineage"), native_root=d["native_root"], resolutions=d["source_resolutions"],
        last_lineage=end.get("lineage"), last_native_root=end.get("native_root", False),
        last_resolutions=end.get("resolutions"))
    if not p.ok:
        raise ValueError("; ".join(p.data["errors"]))
    if d != p.data:
        raise ValueError("plano, referencia, autoridade ou regras mudaram: recompilar antes de enviar")
    return p
