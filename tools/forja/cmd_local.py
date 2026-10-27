"""Subcomandos da edicao local e do encerramento (FORJA-06): `inpaint`, `verify` e `refs`.

Solucao de 27/10, §3 e §9. A edicao local parte do mestre registado: uma versao rejeitada ou o conceito sao recusados
antes de qualquer pedido pago, e o estado do mestre vai no resultado. Depois da composicao, `verify` repete a prova
contra o mestre so a ler (um acabamento global posterior pode desfazer a garantia) e diz se a entrega fecha: `ok` diz
que nada falhou no que se mediu; `deliverable` pede as quatro condicoes, a aprovacao do dono incluida. `refs` mostra
o registo de autoridade e acrescenta estados — nunca uma aprovacao.
"""
from __future__ import annotations

import json
from datetime import date
from pathlib import Path

from . import compose, contracts, jobs, lint, masks, palette as palmod, refs, verdicts
from .cli import box, command, out_path
from .cmd_ai import _spend
from .imageops import open_rgba


def _master(args, native) -> tuple[dict | None, dict]:
    """A imagem a editar, contra o registo: um mestre aprovado ou uma adaptacao em revisao."""
    reg = refs.load(args.refs) if args.refs else None
    rec = refs.record(reg, native)
    if reg and rec["state"] == refs.UNRECORDED:
        raise ValueError("a imagem a editar nao esta no registo (forja refs --add): sem estado, nao ha mestre")
    if rec["state"] == "rejected":
        raise ValueError(f"{rec['id']} foi rejeitada: editar por zonas congelaria a descaracterizacao; recupere o "
                         "desenho a partir do conceito antes de o proteger")
    if rec["state"] == "concept":
        raise ValueError(f"{rec['id']} e o conceito, fora da grade: a edicao local parte de um sprite nativo")
    return reg, rec


def do_inpaint(args) -> dict:
    from . import inpaint
    native = open_rgba(args.image)
    reg, master = _master(args, native)
    pal = palmod.load(args.palette) if args.palette else None
    images = [Path(r).read_bytes() for r in args.reference or []]
    region = masks.select(native, {"mask": args.mask}) if args.mask else None
    protect = frozenset().union(*[masks.box(b, native.size) for b in args.protect or []])
    out = out_path(args.out, Path(args.image).with_name(Path(args.image).stem + "_edit.png"))
    budget = jobs.Budget.open(out.parent, args.max_calls, args.max_usd)
    result, info = inpaint.run(native, args.box, args.change, pal, images, model=args.model, folder=out.parent,
                               budget=budget, region=region, method=args.method, protect=protect)
    if result is None:
        return {**info, "master": master}
    result.save(out)
    delivery = verdicts.closure(verdicts.summary(verdicts.initial()), refs.approval(reg, result), preservation=info)
    return {"ok": info["ok"], "out": str(out), **info, "master": master, "delivery": delivery,
            "next": "forja lint e forja verify contra o mestre (so leitura); a aprovacao e do dono, no registo"}


def _read(path: str | None) -> dict | None:
    return json.loads(Path(path).read_text(encoding="utf-8")) if path else None


def _preservation(master, candidate, args) -> dict | None:
    zone = (masks.select(master, {"mask": args.mask}) if args.mask else
            masks.box(args.box, master.size) if args.box else None)
    if zone is None:
        return None
    protect = frozenset().union(*[masks.box(b, master.size) for b in args.protect or []])
    proof = compose.verify(master, candidate, zone, protect)
    inside = len(masks.changed(master, candidate)) - proof["outside_changed"]
    return {**proof, "changed_inside": inside, "editable_box": masks.bbox(zone)}


def do_verify(args) -> dict:
    master, candidate = open_rgba(args.master), open_rgba(args.image)
    if master.size != candidate.size:
        raise ValueError(f"o candidato tem {candidate.size}, o mestre {master.size}: nao se compara esticando")
    reg = refs.load(args.refs) if args.refs else None
    preservation = _preservation(master, candidate, args)
    v, raster = verdicts.initial(), None
    if args.kind:
        c = contracts.get(args.kind)
        raster = lint.check(candidate, c, palmod.load(args.palette or palmod.ROOT / c.palette), frame=bool(c.canvas))
        verdicts.put(v, "raster_contract", "pass" if raster["ok"] else "fail",
                     [f["message"] for f in raster["findings"] if f["severity"] == "error"])
    for axis, status in ((_read(args.equip) or {}).get("summary") or {}).items():
        if axis in ("equipment_geometry", "functional_pose", "color_coherence") and status in verdicts.STATES:
            verdicts.put(v, axis, status, [args.equip])
    material = (_read(args.cores) or {}).get("material")
    approval = refs.approval(reg, candidate)
    summary = verdicts.summary(v)
    close = verdicts.closure(summary, approval, material, preservation)
    broken = bool(preservation) and not (preservation["outside_identical"] and preservation["protected_identical"])
    return {"ok": not broken and not verdicts.blocking(v), "deliverable": close["deliverable"],
            "preservation": preservation, "lint": raster and {k: raster[k] for k in ("ok", "errors", "warnings")},
            "material": material, "approval": approval, "master": refs.record(reg, master),
            "candidate": refs.record(reg, candidate), "verdicts": summary, "closure": close, "read_only": True,
            "note": close["note"]}


def do_refs(args) -> dict:
    if args.add:
        reg = refs.add(args.register, args.add, args.state, args.id or Path(args.add).stem, args.by, args.origin,
                       args.derived_from, args.date or date.today().isoformat())
    else:
        reg = refs.load(args.register)
    return {"ok": True, "register": str(args.register), "entries": reg["entries"],
            "note": "approved e uma linha do dono, escrita a mao; a Forja acrescenta estados, nunca uma aprovacao"}


def register(sub) -> None:
    p = command(sub, "inpaint", "Mudar so uma caixa ou mascara do sprite com o gpt-image; fora dela, pixels identicos",
                do_inpaint)
    p.add_argument("image")
    p.add_argument("--box", type=box)
    p.add_argument("--mask", help="PNG do tamanho do sprite: a zona a editar sao os pixels opacos, ou os claros se a "
                   "mascara nao tem transparencia (em vez de --box)")
    p.add_argument("--method", default="replace", choices=("add", "replace", "remove"),
                   help="add so acrescenta; replace manda na zona, transparencia incluida; remove tira o que la estava")
    p.add_argument("--protect", type=box, action="append", help="caixa que nao pode mudar (repetivel)")
    p.add_argument("--refs", help="registo forja.refs/1: a imagem tem de estar nele (mestre ou adaptacao em revisao; "
                   "rejeitada e conceito sao recusados antes do pedido)")
    p.add_argument("--change", required=True, help="o que mudar dentro da caixa")
    p.add_argument("--palette")
    p.add_argument("--reference", nargs="*")
    p.add_argument("--model")
    p.add_argument("-o", "--out")
    _spend(p, 1)
    p = command(sub, "verify", "Reconferir um candidato contra o mestre, so a ler: preservacao fora da zona, contrato, "
                "material e aprovacao registada; diz se a entrega fecha", do_verify)
    p.add_argument("image", help="o candidato")
    p.add_argument("--master", required=True, help="o mestre de onde a edicao partiu")
    p.add_argument("--box", type=box, help="a zona autorizada (ou --mask)")
    p.add_argument("--mask", help="PNG da zona autorizada, na convencao das mascaras da Forja")
    p.add_argument("--protect", type=box, action="append", help="caixa que nao pode ter mudado (repetivel)")
    p.add_argument("--refs", help="registo forja.refs/1: o estado do mestre e a aprovacao do candidato")
    p.add_argument("--kind", choices=contracts.kinds(), help="conferir o contrato raster")
    p.add_argument("--palette", help="paleta do lint (por omissao a do contrato)")
    p.add_argument("--cores", help="o JSON do forja cores com plano: o estado do material")
    p.add_argument("--equip", help="o JSON do forja equip: os vereditos do equipamento")
    p = command(sub, "refs", "O registo de autoridade das referencias (conceito, em revisao, aprovado, rejeitado): "
                "mostrar, conferir os hashes e acrescentar um estado (nunca approved)", do_refs)
    p.add_argument("register", help="o registo forja.refs/1 (criado se nao existe)")
    p.add_argument("--add", help="imagem a registar")
    p.add_argument("--state", default="adaptation_in_review", choices=refs.STATES)
    p.add_argument("--id", help="identificador (por omissao o nome do ficheiro)")
    p.add_argument("--by", help="quem regista (num rejected: quem decidiu)")
    p.add_argument("--origin", help="de onde veio: conceito, gerador, mao")
    p.add_argument("--derived-from", help="o id de onde esta deriva")
    p.add_argument("--date", help="AAAA-MM-DD (por omissao hoje)")
