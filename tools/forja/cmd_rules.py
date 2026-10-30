"""Consultar as regras do dono e conferir a entrega antes de a apresentar."""
from __future__ import annotations

import argparse
import json
from pathlib import Path

from . import cast, cmd_lote, owner_rules
from .cli import command, out_path


def do_rules(args) -> dict:
    result = {"ok": True, **owner_rules.load(), "consultation": owner_rules.context(), "network": False,
              "next": "ler as regras e autoridade; compilar pedido; rever pixels; forja entrega antes de apresentar"}
    if args.character:
        data = cast.load(args.catalog)
        entry = cast.character(data, args.character)
        result["character"] = cast.describe(data, entry)
    if args.out:
        out_path(args.out, Path(args.out)).write_text(json.dumps(result, ensure_ascii=False, indent=1) + "\n",
                                                     encoding="utf-8")
    return result


def do_delivery(args) -> dict:
    selected = set(args.character or [])
    if selected:
        data = cast.load(args.catalog)
        selected = {cast.character(data, c)["id"] for c in selected}
    result = cmd_lote.do_batch(argparse.Namespace(**{**vars(args), "out": None}), selected or None)
    result["count"] = len(result["entries"])
    result["ready_for_review"] = sum(r.get("ready_for_review", False) for r in result["entries"])
    result["ok"] = result["count"] > 0 and result["ready_for_review"] == result["count"]
    result["scope"] = "selected_pilot" if selected else "full_cast"
    result["release_ready"] = sum(r.get("deliverable", False) for r in result["entries"])
    result["deliverable"] = result["release_ready"]
    result["labels"] = {label: sum(r["label"] == label for r in result["entries"])
                        for label in ("release", "study", "blocked", "no_candidate")}
    result["note"] = "so apresentar como candidato revisto com ready_for_review; mestre exige a aprovacao separada"
    if args.out:
        out_path(args.out, Path(args.out)).write_text(json.dumps(result, ensure_ascii=False, indent=1) + "\n",
                                                     encoding="utf-8")
    return result


def register(sub) -> None:
    p = command(sub, "regras", "Regras obrigatorias de Henrique e fontes: consultar antes de produzir e entregar",
                do_rules)
    p.add_argument("--character")
    p.add_argument("--catalog", default=str(cast.DEFAULT))
    p.add_argument("-o", "--out")
    p = command(sub, "entrega", "Portao de entrega: falha com candidato ausente, reduzido ou sem revisao das regras",
                do_delivery)
    p.add_argument("folder")
    p.add_argument("--previous")
    p.add_argument("--catalog", default=str(cast.DEFAULT))
    p.add_argument("--character", action="append", help="limitar explicitamente a um piloto; omitir exige o elenco")
    p.add_argument("-o", "--out")
