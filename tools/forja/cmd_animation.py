"""Animação nativa: plano sem rede, geração retomável e portão da sequência exata."""
from __future__ import annotations

import json
from pathlib import Path

from . import animation_files, animation_plan, animation_run, cast, durable, fidelity, lineage, refs
from . import sequence, sequence_review
from .backends.pixellab_animation import MODELS
from .cli import command


def _json(path: str | None) -> dict | None:
    return json.loads(Path(path).read_text(encoding="utf-8")) if path else None


def _contract(args, character: str | None = None):
    ident = args.character or character
    if args.fidelity:
        contract = fidelity.load(args.fidelity)
    else:
        catalog = cast.load(args.catalog)
        entry = cast.character(catalog, ident)
        ident = entry["id"]
        contract = cast.authority(catalog, entry)
    return contract, fidelity.character(contract, ident)


def do_plan(args) -> dict:
    contract, ch = _contract(args)
    plan = animation_plan.make(args.first, contract, ch["id"], args.tag, model=args.model,
        frame_count=args.frames, action=args.action, description=args.description, direction=args.direction,
        seed=args.seed, last_path=args.last, skeleton=_json(args.skeleton),
        register=refs.load(args.refs) if args.refs else None,
        source_lineage=lineage.load(args.lineage) if args.lineage else None, native_root=args.native_root,
        resolutions=lineage.load_resolutions(args.source_resolutions), drift_threshold=args.drift_threshold,
        last_lineage=lineage.load(args.last_lineage) if args.last_lineage else None,
        last_native_root=args.last_native_root, last_resolutions=lineage.load_resolutions(args.last_source_resolutions))
    path = plan.write(args.out)
    return {"ok": plan.ok, "network": False, "plan": str(path), "errors": plan.data["errors"],
            "request": plan.data["request"], "animation_plan": plan.data["animation_plan"],
            "ready_for_review": False, "release_ready": False}


def do_generate(args) -> dict:
    return animation_run.run(args.plan, args.out, max_calls=args.max_calls, max_usd=args.max_usd,
                             resume=args.resume, deadline=args.deadline)


def do_review(args) -> dict:
    clip = sequence.load(args.sequence)
    contract, ch = _contract(args, clip.data.get("character"))
    if args.template_out:
        durable.write_text(animation_files.destination(args.template_out),
                           json.dumps(sequence_review.template(clip, ch), indent=1, ensure_ascii=False) + "\n")
    if args.proof_out:
        from . import sequence_proof
        sequence_proof.write(clip, contract, ch, args.proof_out)
    result = sequence_review.check(clip, ch, _json(args.review), _json(args.approvals), _json(args.loss_resolutions))
    return {"ok": bool(args.template_out or args.proof_out) or result["ready_for_review"], **result}


def do_delivery(args) -> dict:
    clip = sequence.load(args.sequence)
    _, ch = _contract(args, clip.data.get("character"))
    result = sequence_review.check(clip, ch, _json(args.review), _json(args.approvals), _json(args.loss_resolutions))
    return {"ok": result["release_ready"] if args.release else result["ready_for_review"], **result}


def do_patch(args) -> dict:
    from . import animation_patch
    clip = sequence.load(args.sequence)
    _, ch = _contract(args, clip.data.get("character"))
    return animation_patch.apply(clip, _json(args.patch), ch, args.out)


def _identity(p) -> None:
    p.add_argument("--character", help="id/alias do elenco ou personagem no contrato de fidelidade")
    p.add_argument("--fidelity", help="contrato forja.fidelity/1; sem ele, consultar o elenco")
    p.add_argument("--catalog", default=str(cast.DEFAULT))


def _review(p) -> None:
    p.add_argument("sequence", help="animation.forja.json do animar, ou JSON do sheet com cadeia")
    _identity(p)
    p.add_argument("--review", help="revisao forja.animation_review/1 preenchida olhando a sequencia exata")
    p.add_argument("--approvals", help="registo forja.animation_approvals/1 escrito pelo dono")
    p.add_argument("--loss-resolutions", help="forja.animation_loss_resolutions/1: prova de cada perda por quadro")


def register(sub) -> None:
    p = command(sub, "anim-plan", "Plano nativo PixelLab sem rede: mestre exato, poses, contagem e autoridade",
                do_plan)
    p.add_argument("first", help="PNG do mestre nativo (64/80 conforme o personagem); nunca se reduz")
    _identity(p)
    p.add_argument("--tag", required=True, help="acao; contagem e cadencia pela Animation Bible")
    p.add_argument("--model", default="text-v3", choices=tuple(MODELS))
    p.add_argument("--frames", type=int, help="contagem explicita de estudo; nao redefine o runtime")
    p.add_argument("--action", help="texto da acao; por omissao inclui continuidade e articulacao")
    p.add_argument("--description", help="skeleton-v3: aparencia do personagem, nao a pose")
    p.add_argument("--direction", default="east", choices=("east", "west"),
                   help="skeleton-v3: campo direction; text-v3: incluido na acao por omissao (acao explicita prevalece)")
    p.add_argument("--last", help="text-v3: pose final nativa, na mesma tela")
    p.add_argument("--last-lineage", help="cadeia individual da pose final")
    p.add_argument("--last-native-root", action="store_true", help="a pose final e uma origem desenhada nativa")
    p.add_argument("--last-source-resolutions", help="resolucoes de perdas da pose final")
    p.add_argument("--skeleton", help="forja.skeleton_animation/1: pose inicial e 18 pontos por quadro observados")
    p.add_argument("--refs", help="registo das referencias, incluido o estado real do mestre")
    lineage.cli_args(p)
    p.add_argument("--source-resolutions", help="forja.loss_resolutions/1 do mestre inicial")
    p.add_argument("--seed", type=int, default=0)
    p.add_argument("--drift-threshold", type=float, help="controlo do fornecedor; nao equivale ao deflicker local")
    p.add_argument("-o", "--out", required=True)
    p = command(sub, "animar", "Executar ou retomar um plano nativo; um POST pago por job e pasta", do_generate)
    p.add_argument("plan", help="plan.json do anim-plan; imagem e regras conferidas de novo antes da rede")
    p.add_argument("-o", "--out", required=True)
    p.add_argument("--max-calls", type=int, default=1)
    p.add_argument("--max-usd", type=float)
    p.add_argument("--resume", help="id do job original; nunca reenvia POST ambiguo")
    p.add_argument("--deadline", type=float, default=900)
    p = command(sub, "animacao", "Rever a sequencia exata por quadro e acao; criar ficha pendente e prova visual",
                do_review)
    _review(p)
    p.add_argument("--template-out")
    p.add_argument("--proof-out", help="HTML com conceito e sequencia a 1x/ampliada, fundos e leitor por acao")
    p = command(sub, "entrega-anim", "Portao de animacao: regras, origem, runtime e evidencia por quadro/acao",
                do_delivery)
    _review(p)
    p.add_argument("--release", action="store_true", help="exigir tambem aprovacao do dono desta sequencia exata")
    p = command(sub, "anim-patch", "Reparar pixels de quadros por mascara; conservar origem, tempos e outros quadros",
                do_patch)
    p.add_argument("sequence")
    p.add_argument("patch", help="forja.animation_patch/1: hash da sequencia e patches de cada quadro")
    _identity(p)
    p.add_argument("-o", "--out", required=True, help="pasta nova para conservar o original e a sua cadeia")
