"""PixelLab v2: animar um PNG nativo com texto ou esqueletos observados, sem adaptar contagens.

Contrato público lido em 30/10/2026: /v2/openapi.json, hash SPEC_SHA256. O modo texto pede contagem par;
o esqueleto permite attack 5/die 7. Quem envia e retoma é jobs.py; nenhum POST é repetido aqui.
"""
from __future__ import annotations

import io
import json
import math

from PIL import Image

from . import Call, Result, http, image_refs, pixellab_api as api
from ..equipment import image_sha

SPEC_SHA256 = "e7bdfc6e50fc4fdeea424cf92841b5509e01e8acf8975e7dae44bcab34730e4a"
MODELS = {"text-v3": "animate-with-text-v3", "skeleton-v3": "animate-with-skeleton-v3"}
TEMPLATES = ("mannequin", "bear", "cat", "dog", "horse", "lion")
JOINTS = ("NOSE", "NECK", "RIGHT SHOULDER", "RIGHT ELBOW", "RIGHT ARM", "LEFT SHOULDER", "LEFT ELBOW",
          "LEFT ARM", "RIGHT HIP", "RIGHT KNEE", "RIGHT LEG", "LEFT HIP", "LEFT KNEE", "LEFT LEG",
          "RIGHT EYE", "LEFT EYE", "RIGHT EAR", "LEFT EAR")


def _number(value: object, low: float, high: float = float("inf")) -> bool:
    return type(value) in (int, float) and math.isfinite(value) and low <= value <= high


def _image(data: bytes) -> Image.Image:
    with Image.open(io.BytesIO(data)) as source:
        if source.format != "PNG" or min(source.size) < 1 or max(source.size) > 256:
            raise ValueError("referencia: PNG nativo com lados de 1..256; nao se redimensiona")
        return source.convert("RGBA")


def _pose(pose: list) -> None:
    if not isinstance(pose, list) or len(pose) != len(JOINTS) or any(not isinstance(p, dict) for p in pose):
        raise ValueError("esqueleto: cada pose precisa dos 18 pontos observados")
    labels = [p.get("label") for p in pose]
    if sorted(labels, key=str) != sorted(JOINTS):
        raise ValueError("esqueleto: pontos ausentes, duplicados ou desconhecidos")
    for p in pose:
        if set(p) - {"label", "x", "y", "z_index", "depth"}:
            raise ValueError("esqueleto: campos de ponto desconhecidos")
        if not _number(p.get("x"), 0, 1) or not _number(p.get("y"), 0, 1):
            raise ValueError("esqueleto: x/y finitos, normalizados de 0 a 1")
        if type(p.get("z_index", 0)) is not int:
            raise ValueError("esqueleto: z_index inteiro")
        if p.get("depth") is not None and not _number(p["depth"], 0, 255):
            raise ValueError("esqueleto: depth finito de 0 a 255, ou omitido")


def validate_skeleton(data: dict, first: Image.Image, count: int) -> dict:
    if not isinstance(data, dict) or data.get("schema") != "forja.skeleton_animation/1":
        raise ValueError("esqueleto: esperado forja.skeleton_animation/1")
    if data.get("first_frame_pixels_sha256") != image_sha(first):
        raise ValueError("esqueleto: a pose inicial foi observada noutra referencia")
    seen = data.get("observer") or {}
    if not isinstance(seen, dict) or any(not isinstance(seen.get(k), str) or not seen[k].strip()
                                        for k in ("author", "method", "date")):
        raise ValueError("esqueleto: identificar quem observou a pose inicial, como e quando")
    poses = data.get("keypoints")
    if not isinstance(poses, list) or len(poses) != count:
        raise ValueError("esqueleto: uma pose completa por quadro pedido; sem interpolacao inventada")
    _pose(data.get("first_frame_keypoints"))
    for pose in poses:
        _pose(pose)
    template = data.get("template_id", "mannequin")
    if template not in TEMPLATES:
        raise ValueError("esqueleto: template_id desconhecido")
    return {"first_frame_keypoints": data["first_frame_keypoints"], "keypoints": poses, "template_id": template}


def call(first_frame: bytes, action: str, frames: int, model: str = "text-v3", *, last_frame: bytes | None = None,
         skeleton: dict | None = None, description: str | None = None, direction: str = "east",
         seed: int = 0, drift_threshold: float | None = None) -> Call:
    if model not in MODELS:
        raise ValueError(f"modelo de animacao desconhecido: {model!r}")
    first = _image(first_frame)
    if type(seed) is not int or seed < 0:
        raise ValueError("seed: inteiro nao negativo")
    if not isinstance(action, str) or not action.strip() or len(action) > 1000:
        raise ValueError("action: texto de 1..1000 caracteres")
    if type(frames) is not int:
        raise ValueError("frame_count: inteiro")
    body = {"first_frame": {"type": "base64", "format": "png", "base64": http.b64(first_frame)},
            "action": action, "seed": seed, "no_background": True}
    images = [("first_frame", first_frame)]
    if model == "text-v3":
        if frames < 4 or frames > 16 or frames % 2 or first.width * first.height * frames > 524288:
            raise ValueError("text-v3: 4..16 quadros pares e area total <= 524288; para attack 5/die 7 use "
                             "skeleton-v3 com poses observadas, sem truncar nem duplicar quadros")
        if skeleton is not None:
            raise ValueError("text-v3 nao recebe esqueletos")
        body.update(frame_count=frames, enhance_prompt=False)
        if last_frame is not None:
            if _image(last_frame).size != first.size:
                raise ValueError("last_frame precisa da mesma tela da referencia inicial")
            body["last_frame"] = {"type": "base64", "format": "png", "base64": http.b64(last_frame)}
            images.append(("last_frame", last_frame))
        if drift_threshold is not None:
            if not _number(drift_threshold, 0):
                raise ValueError("drift_threshold: numero finito nao negativo")
            body["drift_threshold"] = drift_threshold
    else:
        if not 3 <= frames <= 15 or last_frame is not None or drift_threshold is not None:
            raise ValueError("skeleton-v3: 3..15 poses; nao recebe last_frame nem drift_threshold")
        if not isinstance(description, str) or not description.strip() or direction not in api.DIRECTIONS:
            raise ValueError("skeleton-v3 pede descricao da aparencia e direcao valida")
        body.update(validate_skeleton(skeleton, first, frames), description=description, direction=direction,
                    view="side")
    body = json.loads(json.dumps(body, allow_nan=False))
    endpoint = f"{api.BASE}/{MODELS[model]}"
    descriptor = {"endpoint": endpoint, "model": model, "spec_sha256": SPEC_SHA256,
                  "expected_frames": frames, "canvas": list(first.size),
                  "params": {k: v for k, v in body.items() if k not in ("first_frame", "last_frame")},
                  "images": image_refs(images)}
    return Call("pixellab", MODELS[model], lambda: http.json_request("POST", endpoint, body, api._headers()),
                parse, descriptor, api.REFUSED)


def _completed(data: dict) -> Result:
    images = data.get("images")
    if not isinstance(images, list):
        return Result(state="failed", detail={"error": "resposta de animacao sem lista images"})
    result = []
    for index, image in enumerate(images):
        found = http.find_images(image)
        if len(found) != 1:
            return Result(state="failed", detail={"error": f"quadro {index}: imagem base64 unica em falta"})
        result.append(found[0])
    return Result(result, usage_usd=api._usd(data), detail={"frames": len(result)})


def parse(data: dict) -> Result:
    remote = data.get("background_job_id")
    return Result(remote_id=remote, state="processing") if remote else _completed(data)


def parse_job(data: dict) -> Result:
    if data.get("status") == "completed":
        return _completed(data.get("last_response") or {})
    return api.parse_job(data)


def poll_call(job_id: str) -> Call:
    url = f"{api.BASE}/background-jobs/{job_id}"
    return Call("pixellab", "animation-job", lambda: http.json_request("GET", url, None, api._headers()),
                parse_job, {"endpoint": url})
