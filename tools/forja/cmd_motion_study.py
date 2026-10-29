"""Transicoes e comparacao de tentativas locais, pela mesma CLI/MCP."""
from __future__ import annotations

from pathlib import Path

from . import choreography, motion_benchmark, motion_review, refs
from .cli import command
from .cmd_ase import outside_art
from .cmd_choreography import _write


def do_transition(args) -> dict:
    before_path, after_path = Path(args.before), Path(args.after)
    before, after = choreography.load(before_path), choreography.load(after_path)
    reg = refs.load(args.refs) if args.refs else None
    choreography.require(before, before_path.parent, reg)
    choreography.require(after, after_path.parent, reg)
    report = motion_review.transition(before, after, [args.offset_x, args.offset_y], args.tolerance,
                                      args.from_frame, args.to_frame)
    if args.out:
        _write(outside_art(args.out), report)
    return {'ok': True, 'network': False, 'review': report}


def do_compare(args) -> dict:
    path = Path(args.manifest)
    report = motion_benchmark.summarize(choreography.load(path), path.parent)
    if args.out:
        _write(outside_art(args.out), report)
    return {'ok': True, **report}


def register(sub) -> None:
    p = command(sub, 'transicao', 'Medir extremos entre acoes ou interrupcoes, sem aprovar movimento', do_transition)
    p.add_argument('before')
    p.add_argument('after')
    p.add_argument('--refs')
    p.add_argument('--from-frame', type=int, default=-1)
    p.add_argument('--to-frame', type=int, default=0)
    p.add_argument('--offset-x', type=float, default=0)
    p.add_argument('--offset-y', type=float, default=0)
    p.add_argument('--tolerance', type=float, default=1)
    p.add_argument('-o', '--out')
    p = command(sub, 'comparar-clips', 'Custo e aceitacao por tarefa/metodo; desconhecido nao e zero', do_compare)
    p.add_argument('manifest')
    p.add_argument('-o', '--out')
