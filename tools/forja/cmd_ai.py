"""Subcomandos com gerador: prompt, plan, generate, auto (ciclo fechado); e prova e mcp. O inpaint esta em cmd_local."""
from __future__ import annotations

import json
from pathlib import Path

from . import auto, backends, constraints, contracts, fidelity, guides, jobs, palette as palmod, plan as plan_mod
from . import production, prompts, refs, sheetforge
from .cli import command

BACKENDS = plan_mod.BACKENDS
LABELS = {"identity": "o mestre aprovado", "identity_review": "a adaptacao em revisao",
          "identity_unrecorded": "a referencia (aprovacao nao registada)", "concept": "o conceito de autoridade"}


def _palette(args, kind: str) -> palmod.Palette | None:
    if args.palette == "none" or (kind == "free" and not args.palette):
        return None
    return palmod.load(args.palette or palmod.ROOT / contracts.get(kind).palette)


def _reference(args) -> bool | str:
    """O papel da referencia que o agente vai anexar. So o registo do dono diz `approved` (FORJA-06)."""
    if args.reference_file:
        if not args.refs:
            raise ValueError("--reference-file pede --refs: o estado da referencia vem do registo")
        role, _, error = refs.resolve("identity", Path(args.reference_file).read_bytes(), refs.load(args.refs))
        if error:
            raise ValueError(error)
        return role
    if args.reference_state == "approved":
        raise ValueError("aprovado so pelo registo do dono: --refs registo.json --reference-file imagem.png")
    if not args.reference and args.reference_state == refs.UNRECORDED:
        return False
    return refs.PROMPT_ROLE[args.reference_state]


def _decisions(args) -> dict:
    """Cores e tons so entram por decisao dita no pedido (FORJA-07): a origem fica `explicit_request`."""
    return {k: v for k, v in (("max_colors", getattr(args, "max_colors", None)),
                              ("tones", getattr(args, "tones", None))) if v}


def _fidelity(args, given: list) -> dict:
    contract = fidelity.load(args.fidelity) if getattr(args, "fidelity", None) else None
    return fidelity.prepare(contract, getattr(args, "character", None), getattr(args, "pose", None),
                            getattr(args, "mode", None), given)


def do_prompt(args) -> dict:
    """Sem gerador ligado: o prompt, o expect.json e as guias, na ordem em que se anexam."""
    tags = sheetforge.parse_tags(args.tags)
    role = _reference(args)
    given = [("identity", args.reference_file, Path(args.reference_file).read_bytes())] if args.reference_file else []
    prep = _fidelity(args, given)
    selected = production.resolve(args.subject, args.kind, prep["record"])
    kind = selected["kind"]
    pal = _palette(args, kind)
    prep["errors"] += selected["errors"]
    if prep["errors"]:
        return {"ok": False, "errors": prep["errors"], "mode": prep["mode"]}
    attached = [r for r, _, _ in prep["attach"]] + prompts.default_attached(role, pal)
    res = prompts.build(args.subject, kind, tags, args.facing, role or bool(prep["attach"]), pal, args.target,
                        args.background, attached=attached, mode=prep["mode"],
                        fidelity={**(prep["prompt"] or {}), **_decisions(args), "role": selected["role"]})
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    for r, _, data in prep["attach"]:
        (out / "attach_concept_authority.png").write_bytes(data)
    (out / "prompt.txt").write_text(res["prompt"] + "\n", encoding="utf-8")
    (out / "expect.json").write_text(json.dumps(res["expect"], indent=1) + "\n", encoding="utf-8")
    (out / "pixellab.json").write_text(json.dumps(res["pixellab"], indent=1) + "\n", encoding="utf-8")
    c = contracts.get(kind)
    files = guides.write(out, res["expect"], pal, c.pivot[1] // c.cluster if c.pivot else None)
    files.update({"concept": str(out / "attach_concept_authority.png")} if prep["attach"] else {})
    attach = [files[r] if r in files else LABELS[r] for r in res["expect"]["attached"]]
    return {"ok": not res["conflicts"], "conflicts": res["conflicts"], "prompt": res["prompt"], "size": res["size"],
            "mode": res["mode"], "constraints": res["constraints"], "implicit": res["implicit"],
            "fidelity": prep["record"], "notes": prep["notes"],
            "expect": res["expect"], "advice": res["advice"], "attach": attach,
            "files": {"prompt": str(out / "prompt.txt"), "expect": str(out / "expect.json"),
                      "pixellab": str(out / "pixellab.json"), **files},
            "next": f"gere a imagem ({res['size']}) com o prompt, anexando por esta ordem: {attach or 'nada'} "
                    "(o molde guide_layout.png e opcional: o prompt nao o promete). Depois: python3 -m tools.forja "
                    f"{'sheet' if res['expect']['frames'] > 1 else 'forge'} <imagem> --expect "
                    f"{out / 'expect.json'} -o <pasta>"}


def _plan(args) -> plan_mod.Plan:
    opt = lambda name, default=None: getattr(args, name, default)  # noqa: E731 (chamadores antigos da API)
    given = ([("identity", r) for r in args.reference or []] + [("concept", r) for r in opt("concept") or []]
             + [("style", r) for r in opt("style_reference") or []])
    return plan_mod.make(args.backend, args.subject, args.kind, sheetforge.parse_tags(args.tags), args.facing,
                         given, _palette(args, args.kind or "character_s2"), args.model, opt("guides", "auto"), "auto",
                         opt("init_strength"), opt("seed"), opt("image_size"),
                         refs.load(opt("refs")) if opt("refs") else None, opt("mode"),
                         fidelity.load(opt("fidelity")) if opt("fidelity") else None, opt("character"), opt("pose"),
                         _decisions(args))


def do_plan(args) -> dict:
    """O plano validado e escrito, sem rede: o que se pediria, a quem, com que imagens e porque."""
    p = _plan(args)
    path = p.write(Path(args.out) / "plan")
    return {"ok": p.ok, "plan": str(path), "errors": p.data["errors"], "notes": p.data["notes"],
            "request": p.data["request"], "attachments": p.data["attachments"], "expect": p.data["expect"],
            "advice": p.data["advice"], "network": False}


def _direct_call(args, prompt: str, refs: list[bytes]):
    """`forja generate`: um pedido cru, validado pelo adaptador antes de sair."""
    if args.backend == "openai":
        from .backends import openai_images
        size = args.size or "1024x1024"
        if refs:
            return openai_images.edit_call(prompt, refs, None, size, args.model, n=args.n,
                                           roles=["identity"] * len(refs))
        return openai_images.generate_call(prompt, size, args.model, n=args.n)
    if args.backend == "gemini":
        from .backends import gemini_images
        if args.size:
            raise ValueError("o Gemini nao recebe pixels: use --aspect e --image-size (a saida e medida no retorno)")
        return gemini_images.call(prompt, [("identity", r) for r in refs], args.model, args.aspect,
                                  args.image_size or "1K")
    from .backends import pixellab_api
    w, h = (int(v) for v in (args.size or "64x64").lower().split("x"))
    return pixellab_api.call(prompt, w, h, args.model or "pixflux", no_background=True,
                             init_image=refs[0] if refs else None)


def do_generate(args) -> dict:
    prompt = args.prompt or Path(args.prompt_file).read_text(encoding="utf-8")
    refs = [Path(r).read_bytes() for r in args.reference or []]
    call = _direct_call(args, prompt, refs)
    out = Path(args.out)
    budget = jobs.Budget.open(out, args.max_calls, args.max_usd)
    job = jobs.create(call, out, extra={"backend": args.backend, "references": args.reference or []})
    try:
        jobs.execute(job, call, poll=backends.poller(call.service), budget=budget)
    except (jobs.JobError, jobs.BudgetExceeded, backends.http.MissingKey) as err:
        return {"ok": False, "error": str(err), "job": str(job.path), "state": job.state, "budget": budget.as_dict()}
    return {"ok": True, "files": [o["file"] for o in job.data["outputs"]], "job": str(job.path),
            "received": [o["size"] for o in job.data["outputs"]], "cost": job.data["cost"],
            "budget": budget.as_dict()}


def do_auto(args, transport=None, **kw) -> dict:
    """Ciclo fechado: plano -> gerar (job duravel) -> forjar -> rever -> prompt corretivo -> ..."""
    p = _plan(args)
    out = Path(args.out)
    if not p.ok:
        return {"ok": False, "errors": p.data["errors"], "plan": str(p.write(out / "plan")), "network": False}
    budget = jobs.Budget.open(out, getattr(args, "max_calls", None) or args.attempts, getattr(args, "max_usd", None))
    return auto.run(p, out, args.attempts, budget, args.palette, transport, **kw)


def do_prova(args) -> dict:
    from . import prova
    if args.bench:
        return prova.bench(args.bench)
    return prova.run(Path(args.out) if args.out else None)


def do_mcp(args) -> dict:
    from . import mcp_server
    mcp_server.serve()
    return {"_raw": ""}


def _planned(p) -> None:
    p.add_argument("subject")
    p.add_argument("-o", "--out", required=True)
    p.add_argument("--backend", default="openai", choices=BACKENDS)
    p.add_argument("--kind", choices=contracts.kinds())
    p.add_argument("--tags")
    p.add_argument("--facing", default="right", choices=("right", "left"))
    p.add_argument("--reference", nargs="*", help="referencia de identidade; o estado (aprovado, em revisao) vem "
                   "de --refs")
    p.add_argument("--concept", nargs="*", help="conceito de autoridade (fora da grade): o rosto e as proporcoes a "
                   "recuperar")
    p.add_argument("--refs", help="registo forja.refs/1: o estado de cada referencia, pelo hash dos pixels")
    p.add_argument("--style-reference", nargs="*", help="referencia de estilo (so onde o modelo a aceita)")
    p.add_argument("--palette")
    p.add_argument("--model")
    p.add_argument("--guides", default="auto", choices=plan_mod.GUIDES,
                   help="que guias anexar; auto = a amostra da paleta quando ela nao cabe no texto")
    p.add_argument("--image-size", help="Gemini: 1K, 2K ou 4K (por omissao a menor com >= 8 px por pixel)")
    p.add_argument("--init-strength", type=int, help="PixelLab: forca da imagem inicial (1-999, maior preserva)")
    p.add_argument("--seed", type=int, help="PixelLab: seed")
    _faithful(p)


def _faithful(p) -> None:
    p.add_argument("--mode", choices=constraints.MODES, help="stylized (o de antes), adapt_concept (fiel ao recorte "
                   "de autoridade), edit_approved_master; por omissao adapt_concept com --fidelity ou um conceito")
    p.add_argument("--fidelity", help="contrato forja.fidelity/1: a autoridade, as invariantes e os rejeitados")
    p.add_argument("--character", help="o personagem no contrato de fidelidade")
    p.add_argument("--pose", help="a pose no contrato de fidelidade")
    p.add_argument("--max-colors", type=int, help="teto de cores decidido no pedido (origem explicit_request)")
    p.add_argument("--tones", type=int, help="tons por material decididos no pedido (origem explicit_request)")


def _spend(p, default_calls: int | None) -> None:
    p.add_argument("--max-calls", type=int, default=default_calls, help="teto de chamadas pagas nesta pasta")
    p.add_argument("--max-usd", type=float, help="teto em dolares, contra o custo dito pelo fornecedor")


def register(sub) -> None:
    p = command(sub, "prompt", "Compilar o pedido para o gerador: prompt, tamanho, guias e expect.json", do_prompt)
    p.add_argument("subject", help="o que desenhar, em poucas palavras (ingles ou portugues)")
    p.add_argument("-o", "--out", required=True)
    p.add_argument("--kind", choices=contracts.kinds())
    p.add_argument("--tags", help="animacao: 'walk' ou 'idle,walk' ou 'attack:5'")
    p.add_argument("--facing", default="right", choices=("right", "left"))
    p.add_argument("--reference", action="store_true", help="vai anexar uma referencia de identidade")
    p.add_argument("--reference-state", default=refs.UNRECORDED, choices=(refs.UNRECORDED, "concept",
                   "adaptation_in_review", "approved"), help="o estado dela; approved so com --refs e --reference-file")
    p.add_argument("--refs", help="registo forja.refs/1 (com --reference-file: o estado sai dele)")
    p.add_argument("--reference-file", help="a imagem que vai anexada, conferida no registo")
    p.add_argument("--target", default="gpt-image", choices=prompts.TARGETS)
    p.add_argument("--background", default="auto", choices=("auto", "transparent", "key"))
    p.add_argument("--palette")
    _faithful(p)
    p = command(sub, "plan", "Planear um pedido para um gerador, validado e sem rede: tamanho, imagens e limites",
                do_plan)
    _planned(p)
    p = command(sub, "generate", "Pedir a imagem a um gerador (OPENAI_API_KEY, GEMINI_API_KEY ou PIXELLAB_API_KEY), "
                "com job duravel e teto de gasto", do_generate)
    p.add_argument("--backend", default="openai", choices=BACKENDS)
    p.add_argument("--prompt")
    p.add_argument("--prompt-file")
    p.add_argument("--reference", nargs="*", help="design aprovado (PixelLab: vai como init_image)")
    p.add_argument("--model")
    p.add_argument("--size", help="openai e pixellab: LxA em pixels")
    p.add_argument("--aspect", default="1:1", help="Gemini: proporcao suportada (ex.: 16:9)")
    p.add_argument("--image-size", help="Gemini: 1K, 2K ou 4K")
    p.add_argument("--n", type=int, default=1)
    p.add_argument("-o", "--out", required=True)
    _spend(p, 1)
    p = command(sub, "auto", "Ciclo fechado com um gerador: planear, pedir, forjar, rever e corrigir o prompt", do_auto)
    _planned(p)
    p.add_argument("--attempts", type=int, default=3)
    _spend(p, None)
    p = command(sub, "prova", "A prova da Forja: pixel art falsa fabricada, recuperada e conferida", do_prova)
    p.add_argument("-o", "--out", help="pasta para guardar as imagens da prova")
    p.add_argument("--bench", type=int, help="em vez da prova: bancada pesada com N casos sorteados (lenta)")
    command(sub, "mcp", "Servidor MCP (stdio) com todas as ferramentas, para Codex, Claude Code e outros", do_mcp)
    from .cmd_jobs import register as register_jobs
    register_jobs(sub)
