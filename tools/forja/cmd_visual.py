"""`forja visual`: a revisao visual de uma imagem exata, antes do pedido e depois do retorno (FORJA-10, P0).

Sem `--review`: grava o esqueleto (`--template-out`) com o hash, o tamanho, a classe e as invariantes do dono, para
quem olha preencher. Com `--review`: valida contra a imagem (e o contrato, com `--fidelity --character`), diz o
estado (pass, pending, blocked ou invalid), grava a imagem marcada (`--marks-out`, caixas numeradas para conferir
onde cada coisa foi apontada) e a observacao do forja equip (`--observation-out`), e devolve os
`reference_issue_reviews` que os reparos declarados dao. So le a revisao; nunca a escreve nem a corrige.
"""
from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw

from . import fidelity, visual_review as vr
from .cli import command, out_path
from .equipment import image_sha
from .imageops import on_background, open_rgba, upscale


def template(image: Image.Image, phase: str, ch: dict | None = None) -> dict:
    """O esqueleto a preencher por quem olha: hash, tamanho, classe e invariantes do dono, problemas conhecidos."""
    ch = ch or {}
    return {"schema": vr.SCHEMA, "phase": phase, "image": {"sha256": image_sha(image), "size": list(image.size)},
            "subject": {"character": ch.get("id"), "pose": ch.get("pose"), "declared_role": ch.get("role"),
                        "target_canvas": ch.get("target_canvas"), "authority_crop_xyxy": ch.get("authority_crop_xyxy")},
            "observer": {"author": None, "model": None, "method": None, "date": None},
            "expected_equipment": ch.get("expected_equipment", []), "regions": {}, "anchors": {}, "findings": [],
            "invariant_checks": [{"invariant": i, "status": "uncertain", "evidence": ""}
                                 for i in ch.get("required_invariants", [])],
            "repair_claims": [{"issue": i["id"], "status": "uncertain", "box": None, "evidence": ""}
                              for i in ch.get("reference_issues", []) if phase == "candidate"]}


def marks(image: Image.Image, rev: dict, scale: int = 8) -> Image.Image:
    """A imagem ampliada com as caixas numeradas, para quem reve conferir onde cada coisa foi marcada."""
    big = on_background(upscale(image, scale), (128, 128, 128)).convert("RGB")
    draw = ImageDraw.Draw(big)
    hue = {"observed": (40, 200, 90), "inferred": (240, 200, 40), "occluded": (150, 150, 150)}
    items = [(n, r["box"], hue.get(r.get("state"), (255, 255, 255))) for n, r in rev.get("regions", {}).items()]
    items += [(f["id"], f["box"], (230, 40, 40)) for f in rev.get("findings", [])]
    items += [(c["issue"], c["box"], (60, 140, 255)) for c in rev.get("repair_claims", []) if c.get("box")]
    for i, (name, b, rgb) in enumerate(items, 1):
        x0, y0, x1, y1 = (v * scale for v in b)
        draw.rectangle((x0, y0, x1 - 1, y1 - 1), outline=rgb, width=2)
        draw.text((x0 + 3, y0 + 2), f"{i} {name}", fill=rgb)
    for a in rev.get("anchors", {}).values():
        x, y = (v * scale + scale // 2 for v in a["point"])
        draw.line((x - scale, y, x + scale, y), fill=(255, 0, 255), width=2)
        draw.line((x, y - scale, x, y + scale), fill=(255, 0, 255), width=2)
    return big


def do_visual(args) -> dict:
    image = open_rgba(args.image)
    ch = None
    if args.fidelity:
        if not args.character:
            raise ValueError("--fidelity pede --character")
        ch = fidelity.character(fidelity.load(args.fidelity), args.character, args.pose)
    if not args.review:
        if not args.template_out:
            raise ValueError("sem --review, diga onde gravar o esqueleto com --template-out")
        path = out_path(args.template_out, Path(args.template_out))
        path.write_text(json.dumps(template(image, args.phase, ch), indent=1, ensure_ascii=False) + "\n",
                        encoding="utf-8")
        return {"ok": True, "template": str(path), "image_sha256": image_sha(image),
                "note": "preencher olhando a imagem a 1x e ampliada; o que nao se viu fica uncertain"}
    rev = vr.load(args.review)
    st = vr.state(rev, image, ch)
    result = {"ok": st["status"] in ("pass", "pending"), "state": st}
    if st["status"] == "invalid":
        return result
    result["reference_issue_reviews"] = vr.issue_reviews(rev)
    if args.marks_out:
        path = out_path(args.marks_out, Path(args.marks_out))
        marks(image, rev, args.scale).save(path)
        result["files"] = {"preview": str(path)}  # o cliente MCP mostra-a ao agente
    if args.observation_out:
        path = out_path(args.observation_out, Path(args.observation_out))
        path.write_text(json.dumps(vr.observation(rev), indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
        result["observation"] = str(path)
    return result


def register(sub) -> None:
    p = command(sub, "visual", "Revisao visual de uma imagem exata (referencia ou candidato): validar contra o hash, "
                "a tela e a classe do dono, estado com o incerto visivel, imagem marcada e observacao do equip",
                do_visual)
    p.add_argument("image", help="a imagem revista (o recorte de autoridade na fase reference)")
    p.add_argument("--review", help="a revisao forja.visual_review/1 preenchida")
    p.add_argument("--phase", default="candidate", choices=vr.PHASES, help="so para o esqueleto")
    p.add_argument("--fidelity", help="contrato forja.fidelity/1: classe, invariantes e problemas da referencia")
    p.add_argument("--character", help="o personagem no contrato")
    p.add_argument("--pose", help="a pose (se o personagem tem mais de uma)")
    p.add_argument("--template-out", help="gravar o esqueleto a preencher (sem --review)")
    p.add_argument("--marks-out", help="PNG ampliado com as caixas e ancoras numeradas")
    p.add_argument("--observation-out", help="gravar a observacao forja.observation/1 para o forja equip")
    p.add_argument("--scale", type=int, default=8, help="ampliacao inteira da imagem marcada")
