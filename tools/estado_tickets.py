#!/usr/bin/env python3
"""tools/estado_tickets.py — o estado de um ticket vive no ficheiro dele, e so la.

O docs/backlog/README.md manda mudar o **Estado** "no proprio ficheiro e nesta
tabela, no mesmo commit" — e o tickets.json, que alimenta o painel e o site,
e um terceiro sitio. Tres copias do mesmo facto divergiram: a 26/09/2026 o
site contava 64 tickets feitos quando os ficheiros diziam mais, e o README
tinha a Fase 1 inteira "por fazer" depois de fechada.

A fonte e a linha `Estado` de cada docs/backlog/<id>.md. O tickets.json leva o
texto dela; a tabela do README tem de dizer a mesma coisa (feito, parcial ou
por fazer — a mesma regra do estadoDe() do tools/web/dados.mjs).

    python3 tools/estado_tickets.py            # confere (o check_claims chama isto)
    python3 tools/estado_tickets.py --write    # acerta o tickets.json e o README
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
BACKLOG = RAIZ / "docs/backlog"
JSON = BACKLOG / "tickets.json"
README = BACKLOG / "README.md"
# Uma linha da tabela: | [ID](ID.md) | ... | Estado |
LINHA = re.compile(r"^(\| \[([A-Z0-9-]+)\]\(\2\.md\) \|.*\| )([^|]+?)( \|\s*)$", re.M)


def estado_md(texto: str) -> str:
    """A linha `Estado` do bloco do ticket, com as de continuacao juntas."""
    linhas = texto.splitlines()
    for i, linha in enumerate(linhas):
        if linha.startswith("Estado "):
            partes = [linha[len("Estado"):].strip()]
            for seguinte in linhas[i + 1:]:
                if not seguinte.startswith(" " * 10) or not seguinte.strip():
                    break
                partes.append(seguinte.strip())
            return " ".join(partes)
    return ""


def categoria(estado: str) -> str:
    e = estado.strip().lower()
    return "feito" if e.startswith("feito") else "parcial" if e.startswith("parcial") else "falta"


def _fontes(raiz: Path) -> dict[str, str]:
    return {
        p.stem: estado_md(p.read_text(encoding="utf-8"))
        for p in sorted((raiz / "docs/backlog").glob("*.md"))
        if p.name != "README.md"
    }


def divergencias(raiz: Path = RAIZ) -> list[str]:
    fontes = _fontes(raiz)
    problemas = []
    tickets = json.loads((raiz / "docs/backlog/tickets.json").read_text(encoding="utf-8"))
    for tid, estado in fontes.items():
        if not estado:
            problemas.append(f"docs/backlog/{tid}.md: nao tem linha Estado")
            continue
        no_json = tickets.get(tid, {}).get("estado", "")
        if no_json != estado:
            problemas.append(
                f"docs/backlog/tickets.json: {tid} diz '{no_json[:40]}', o ficheiro diz"
                f" '{estado[:40]}' — corre tools/estado_tickets.py --write"
            )
    for m in LINHA.finditer((raiz / "docs/backlog/README.md").read_text(encoding="utf-8")):
        tid, celula = m.group(2), m.group(3)
        if tid in fontes and categoria(celula) != categoria(fontes[tid]):
            problemas.append(
                f"docs/backlog/README.md: {tid} diz '{celula.strip()}', o ficheiro diz"
                f" '{categoria(fontes[tid])}' — corre tools/estado_tickets.py --write"
            )
    return problemas


def escrever(raiz: Path = RAIZ) -> list[str]:
    fontes = _fontes(raiz)
    mudados = []
    caminho = raiz / "docs/backlog/tickets.json"
    tickets = json.loads(caminho.read_text(encoding="utf-8"))
    for tid, estado in fontes.items():
        if tid in tickets and estado and tickets[tid].get("estado") != estado:
            tickets[tid]["estado"] = estado
            mudados.append(tid)
    caminho.write_text(json.dumps(tickets, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")

    def celula(m: re.Match) -> str:
        tid, atual = m.group(2), m.group(3)
        if tid not in fontes or categoria(atual) == categoria(fontes[tid]):
            return m.group(0)
        mudados.append(f"README:{tid}")
        return m.group(1) + fontes[tid] + m.group(4)

    readme = raiz / "docs/backlog/README.md"
    readme.write_text(LINHA.sub(celula, readme.read_text(encoding="utf-8")), encoding="utf-8")
    return mudados


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--write", action="store_true", help="acerta o tickets.json e o README")
    args = parser.parse_args()
    if args.write:
        mudados = escrever()
        print(f"estado_tickets: {len(mudados)} acerto(s): {', '.join(mudados) or 'nenhum'}")
        return 0
    problemas = divergencias()
    for p in problemas:
        print(f"estado_tickets: {p}", file=sys.stderr)
    if not problemas:
        print("estado_tickets: tickets.json e README batem com os ficheiros")
    return 1 if problemas else 0


if __name__ == "__main__":
    raise SystemExit(main())
