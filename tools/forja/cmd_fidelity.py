"""`forja fidelity`: o contrato de fidelidade, o recorte de autoridade e a revisao em quatro estados (FORJA-07).

Sem candidato: confere o contrato (o hash da autoridade, os recortes, os rejeitados) e diz o que esta pendente por
personagem. Com `--crop-out`: grava o recorte de autoridade da pose, para anexar e comparar. Com `--candidate`: o
lint no contrato da pose, os sinais declarados (com o JSON do forge, tambem a perda medida), a identidade e a
aprovacao, cada um com a sua evidencia, e `--sheet` grava o conceito e o candidato lado a lado. So le e grava em
pastas de saida: nunca escreve uma revisao de identidade nem uma aprovacao.
"""
from __future__ import annotations

import json
from pathlib import Path

from . import contracts, fidelity, lineage, lint, palette as palmod, refs, review_state, visual_review
from .cli import command, out_path
from .equipment import image_sha
from .imageops import open_rgba


def _pending(ch: dict) -> list[str]:
    out = [f"regiao {r['id']}: sem caixa no destino" for r in ch.get("critical_regions", []) if not r.get("target_box")]
    out += [] if ch.get("target_useful_bbox") else ["caixa util no destino por planear"]
    out += [] if ch.get("replacement_candidate") else ["sem candidato de substituicao"]
    return out


def do_fidelity(args) -> dict:
    contract = fidelity.load(args.contract)
    if not args.character:
        rows = [{"character": c["id"], "pose": c["pose"], "kind": c["kind"], "crop": c["authority_crop_xyxy"],
                 "rejected_candidates": len(c.get("rejected_candidates", [])), "pending": _pending(c)}
                for c in contract["characters"]]
        return {"ok": True, "contract": args.contract, "authority": contract["authority"], "characters": rows}
    ch = fidelity.character(contract, args.character, args.pose)
    result: dict = {"ok": True, "character": ch["id"], "pose": ch["pose"], "kind": ch["kind"],
                    "invariants": ch.get("required_invariants"), "pending": _pending(ch)}
    if args.crop_out:
        path = out_path(str(Path(args.crop_out) / f"{ch['id']}-{ch['pose']}-autoridade.png"), Path("."))
        crop = fidelity.authority_crop(contract, ch)
        crop.save(path)
        result["authority_crop"] = {"file": str(path), "pixels_sha256": image_sha(crop),
                                    "box": ch["authority_crop_xyxy"], "authority_sha256": contract["authority"]["sha256"],
                                    "note": "recortar nao faz do recorte um mestre nativo"}
    if args.candidate:
        candidate = open_rgba(args.candidate)
        c = contracts.get(ch["kind"])
        raster = lint.check(candidate, c, palmod.load(args.palette or palmod.ROOT / c.palette), frame=bool(c.canvas))
        forge = json.loads(Path(args.forge_json).read_text(encoding="utf-8")) if args.forge_json else None
        visual = visual_review.load(args.visual_review) if args.visual_review else None
        rev = review_state.review(ch, candidate, refs.load(args.refs) if args.refs else None, raster, forge, visual,
                                  lineage.load_resolutions(args.resolutions))
        result.update(review=rev, ok=not rev["blocked"], deliverable=rev["deliverable"], label=rev["label"])
        if args.sheet:
            path = out_path(args.sheet, Path(args.sheet))
            review_state.sheet(contract, ch, candidate).save(path)
            result["sheet"] = str(path)
    return result


def register(sub) -> None:
    p = command(sub, "fidelity", "Contrato de fidelidade: conferir a autoridade, gravar o recorte de uma pose e rever "
                "um candidato em quatro estados (runtime, sinais, identidade, mestre), so a ler", do_fidelity)
    p.add_argument("contract", help="o contrato forja.fidelity/1")
    p.add_argument("--character", help="o personagem")
    p.add_argument("--pose", help="a pose (se o personagem tem mais de uma)")
    p.add_argument("--crop-out", help="pasta onde gravar o recorte de autoridade da pose")
    p.add_argument("--candidate", help="o PNG candidato a rever contra a pose")
    p.add_argument("--forge-json", help="o JSON do forge desse candidato: a perda medida nas regioes e os pinos")
    p.add_argument("--refs", help="registo forja.refs/1: rejeitada ou aprovada pelo dono, para esta imagem exata")
    p.add_argument("--palette", help="paleta do runtime (por omissao a do contrato da pose)")
    p.add_argument("--sheet", help="PNG com o conceito e o candidato lado a lado (1x e ampliado por inteiro)")
    p.add_argument("--resolutions", help="forja.loss_resolutions/1: reparo provado nesta imagem, excecao autorizada "
                   "ou revisao inconclusiva, uma por ocorrencia herdada (FORJA-15)")
    p.add_argument("--visual-review", help="revisao forja.visual_review/1 deste candidato (forja visual): bloqueia "
                   "com um defeito certo, deixa pendente o incerto e da os reference_issue_reviews dos reparos")
