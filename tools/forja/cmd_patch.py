"""`forja patch`: aplicar um `forja.pixel_patch/1` a um PNG nativo e voltar a avaliar (FORJA-10, P1).

Grava o PNG editado, a ampliacao, o antes/depois/diferenca e o relatorio com os dois hashes. Depois de qualquer
mudanca, a observacao da imagem anterior deixa de valer: com `--manifest --observation` so ha veredito de
equipamento se a observacao ja for da imagem nova; com `--kind` volta o lint do contrato; com `--fidelity
--character`, os quatro estados. Nunca grava em art/.
"""
from __future__ import annotations

import json
from pathlib import Path

from . import contracts, equipment, fidelity, geometry, lineage, lint, palette as palmod, pixel_patch
from . import review_state
from .cli import command
from .imageops import open_rgba, upscale

ART = Path(__file__).resolve().parents[2] / "art"


def _palette(args):
    if args.palette == "none":
        return None
    if args.palette:
        return palmod.load(args.palette)
    return palmod.load(palmod.ROOT / contracts.get(args.kind).palette) if args.kind else None


def _equipment(args, image, sha: str) -> dict | None:
    if not (args.manifest and args.observation):
        return None
    raw = equipment.load(args.observation)
    if raw.get("image_sha256") != sha:
        return {"status": "not_evaluated", "detail": "a observacao e de outra imagem (a anterior ao patch): observe "
                "de novo a imagem nova (forja visual, forja equip) antes de qualquer veredito de equipamento"}
    obs = equipment.observe(image, raw, Path(args.observation).parent)
    result = geometry.review(equipment.load(args.manifest), obs)
    return {"status": "blocked" if result["blocking"] else "evaluated", "summary": result["summary"],
            "blocking": result["blocking"]}


def do_patch(args) -> dict:
    out = Path(args.out).resolve()
    if out == ART or ART in out.parents:
        raise ValueError("nunca escrever em art/ sem pedido do dono: use build/forja/")
    base = open_rgba(args.base)
    pal = _palette(args)
    result, report = pixel_patch.apply(base, pixel_patch.load(args.patch), pal.colors if pal else None)
    out.mkdir(parents=True, exist_ok=True)
    stem = args.name or Path(args.base).stem + "_patch"
    files = {"png": out / f"{stem}.png", "preview": out / f"{stem}@{args.zoom}x.png",
             "diff": out / f"{stem}_diff.png", "json": out / f"{stem}.json"}
    result.save(files["png"])
    upscale(result, args.zoom).save(files["preview"])
    pixel_patch.diff(base, result, args.zoom).save(files["diff"])
    report["observation_of_base_still_valid"] = False
    if args.kind:
        c = contracts.get(args.kind)
        raster = lint.check(result, c, pal, frame=bool(c.canvas))
        report["lint"] = {"ok": raster["ok"],
                          "errors": [f["message"] for f in raster["findings"] if f["severity"] == "error"]}
    lin = None
    if args.lineage:  # FORJA-15: a etapa entra na cadeia; o que cai na mascara fica marcado, nao resolvido
        data = pixel_patch.load(args.patch)
        lin = report["lineage"] = lineage.patch(lineage.load(args.lineage), report, data.get("mask") or [])
    if args.fidelity:
        ch = fidelity.character(fidelity.load(args.fidelity), args.character, args.pose)
        rev = review_state.review(ch, result, None, None if not args.kind else raster, {"lineage": lin} if lin else None)
        report["review"] = {"summary": rev["summary"], "blocked": rev["blocked"], "deliverable": rev["deliverable"],
                            "release": rev["release"]["status"], "label": rev["label"]}
    report["equipment"] = _equipment(args, result, report["result_pixels_sha256"])
    files["json"].write_text(json.dumps({**report, "base": args.base, "patch": args.patch,
                                         "files": {k: str(v) for k, v in files.items()}}, indent=1,
                                        ensure_ascii=False) + "\n", encoding="utf-8")
    return {"ok": True, "report": report, "files": {k: str(v) for k, v in files.items()},
            "note": "o patch nao aprova a arte: rever a 1x e ampliado, em fundo claro e escuro, ao lado da referencia"}


def register(sub) -> None:
    p = command(sub, "patch", "Editar pixels nativos por operacoes explicitas (pintar, regiao, mover agrupamento) "
                "numa mascara autorizada, com protegidos, hashes antes/depois e diferenca; sem blur nem reamostragem",
                do_patch)
    p.add_argument("base", help="o PNG nativo (a tela final)")
    p.add_argument("patch", help="o forja.pixel_patch/1")
    p.add_argument("-o", "--out", required=True, help="pasta de saida (build/forja/...; nunca art/)")
    p.add_argument("--name", help="nome dos ficheiros de saida")
    p.add_argument("--kind", choices=contracts.kinds(), help="contrato do runtime para voltar a passar o lint")
    p.add_argument("--palette", help="paleta das cores pintadas (por omissao a do --kind; 'none' sem paleta)")
    p.add_argument("--fidelity", help="contrato forja.fidelity/1 para os quatro estados da imagem nova")
    p.add_argument("--character", help="o personagem no contrato")
    p.add_argument("--pose", help="a pose")
    p.add_argument("--manifest", help="manifesto forja.equipment/1")
    p.add_argument("--observation", help="observacao forja.observation/1 (so conta se for da imagem nova)")
    p.add_argument("--zoom", type=int, default=8, help="ampliacao inteira das previas")
    p.add_argument("--lineage", help="o JSON do forge (ou cadeia) da base: o relatorio leva a cadeia com esta etapa")
