"""Linha de comandos da Forja. Cada subcomando devolve um dict e imprime-o em JSON.

O mesmo registo serve o servidor MCP: os esquemas das ferramentas saem dos
argumentos daqui, para o agente e o terminal verem exatamente a mesma coisa.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Callable

from . import __version__

Handler = Callable[[argparse.Namespace], dict]
REGISTRY: dict[str, tuple[argparse.ArgumentParser, Handler]] = {}


def pair(text: str) -> tuple[int, int]:
    a, _, b = text.lower().replace(",", "x").partition("x")
    return int(a), int(b)


def box(text: str) -> tuple[int, int, int, int]:
    parts = [int(v) for v in text.replace(" ", "").split(",")]
    if len(parts) != 4:
        raise argparse.ArgumentTypeError("caixa: x0,y0,x1,y1")
    return parts[0], parts[1], parts[2], parts[3]


def out_path(path: str | None, default: Path) -> Path:
    p = Path(path) if path else default
    p.parent.mkdir(parents=True, exist_ok=True)
    return p


def command(sub, name: str, help_text: str, handler: Handler) -> argparse.ArgumentParser:
    parser = sub.add_parser(name, help=help_text, description=help_text)
    parser.set_defaults(handler=handler, command=name)
    REGISTRY[name] = (parser, handler)
    return parser


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="python3 -m tools.forja",
        description="Forja: pixel art verdadeira a partir de qualquer gerador de imagens, "
                    "nos contratos do Empire. Guia: docs/art/FORJA.md")
    parser.add_argument("--version", action="version", version=f"forja {__version__}")
    sub = parser.add_subparsers(dest="command", required=True)
    from . import cmd_ai, cmd_cores, cmd_equip, cmd_image, cmd_make
    for module in (cmd_image, cmd_make, cmd_ai, cmd_equip, cmd_cores):
        module.register(sub)
    return parser


def run(argv: list[str]) -> dict:
    args = build_parser().parse_args(argv)
    return args.handler(args)


def main(argv: list[str] | None = None) -> int:
    argv = sys.argv[1:] if argv is None else argv
    try:
        result = run(argv)
    except (FileNotFoundError, ValueError, KeyError, RuntimeError) as err:
        print(json.dumps({"ok": False, "error": str(err)}, ensure_ascii=False))
        return 2
    if result.get("_raw") is not None:
        print(result["_raw"])
        return 0 if result.get("ok", True) else 1
    print(json.dumps(result, indent=1, ensure_ascii=False))
    return 0 if result.get("ok", True) else 1
