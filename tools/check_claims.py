#!/usr/bin/env python3
"""tools/check_claims.py — o portao das afirmacoes.

O AGENTS.md tem uma regra que ate agora nada defendia: "nao escrevas a mao um
numero que a ferramenta conta". O README, o RETOMADA.md e o validation.json
estao cheios deles — 27 tabelas, 202 recursos, 43 testes, 591 campos propostos.
Todos verdadeiros hoje. O problema nao e hoje: e o dia em que alguem acrescenta
uma tabela e a prosa continua a dizer 27, porque ninguem reconta a mao.

A disciplina e a mesma que ferramentas/src/03-paineis.js impoe ao painel de
estado — nenhum numero chega ao ecra sem proveniencia. Aqui a proveniencia e
esta: cada numero de validation.json e de prosa e recontado da arvore a cada
push, e uma divergencia chumba. Nao ha um segundo ficheiro de medicoes, porque
um segundo sitio para o mesmo numero e exactamente o defeito que isto apanha.

    python3 tools/check_claims.py            # reconta e confere (o CI faz isto)
    python3 tools/check_claims.py --write    # corrige os campos contaveis do validation.json
"""

from __future__ import annotations

import argparse
import csv
import json
import re
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import estado_tickets  # noqa: E402

RAIZ = Path(__file__).resolve().parent.parent
VALIDACAO = RAIZ / "docs/recovery/validation.json"


def _glob(padrao: str, excluir: tuple[str, ...] = ()) -> list[Path]:
    return sorted(p for p in RAIZ.glob(padrao) if not any(e in p.name for e in excluir))


def _csvs() -> list[Path]:
    return _glob("data/source/*.csv", excluir=("_tables.csv",))


def _valores_conferidos_do_dossie() -> int:
    """Corre o check_dossie_vs_csv e le o numero que ele proprio conta."""
    r = subprocess.run(
        [sys.executable, "tools/check_dossie_vs_csv.py", "docs/dossie.html"],
        capture_output=True,
        text=True,
        cwd=RAIZ,
    )
    if r.returncode != 0:
        raise SystemExit(f"check_dossie_vs_csv chumbou:\n{r.stdout}{r.stderr}")
    achado = re.search(r"(\d+)\s+valores conferidos", r.stdout)
    if achado is None:
        raise SystemExit(f"check_dossie_vs_csv nao disse quantos conferiu:\n{r.stdout}")
    return int(achado.group(1))


def _sinais_do_catalogo() -> int:
    """Os sinais da tabela do §46 — a lista fechada que o EventBus tem de espelhar."""
    texto = (RAIZ / "docs/design/46-o-catalogo-completo.md").read_text(encoding="utf-8")
    nomes = [
        celula
        for linha in texto.splitlines()
        if linha.startswith("|")
        for celula in [linha.split("|")[1].strip()]
        if re.fullmatch(r"[a-z][a-z0-9_]+", celula)
    ]
    return len(nomes)


def _propostos() -> tuple[int, int]:
    """Campos marcados em _proposed, e quantos deles sao de fases 0 a 2."""
    total = fases_0_2 = 0
    for caminho in _csvs():
        with caminho.open(encoding="utf-8") as f:
            for linha in csv.DictReader(f):
                campos = [c for c in (linha.get("_proposed") or "").split("|") if c.strip()]
                total += len(campos)
                if (linha.get("_phase") or "").strip() in {"0", "1", "2"}:
                    fases_0_2 += len(campos)
    return total, fases_0_2


def _sinais_declarados() -> int:
    """Os `signal` do EventBus. O event_bus_test confere nome a nome com o motor
    a correr; isto e a mesma conferencia em contagem, no portao rapido."""
    fonte = RAIZ / "src/core/event_bus.gd"
    if not fonte.exists():
        return 0
    return len(re.findall(r"^signal\s+[a-z]", fonte.read_text(encoding="utf-8"), re.M))


def medir() -> dict[str, int]:
    """Tudo o que uma ferramenta pode contar em vez de alguem afirmar."""
    i18n = list(csv.reader((RAIZ / "data/i18n/strings.csv").open(encoding="utf-8")))
    testes = "\n".join(p.read_text(encoding="utf-8") for p in _glob("tests/**/*.gd"))
    propostos, propostos_0_2 = _propostos()
    return {
        "event_bus_signals": _sinais_declarados(),
        "csv_tables": len(_csvs()),
        "original_csv_unchanged": len(_csvs()),
        "generated_resources": len([p for p in RAIZ.glob("data/**/*.tres") if "source" not in p.parts]),
        "adrs": len(_glob("docs/adr/*.md", excluir=("0000-template",))),
        "tickets": len(_glob("docs/backlog/*.md", excluir=("README.md",))),
        "spec_sections": len(_glob("docs/design/*.md", excluir=("INDEX.md",))),
        "i18n_keys": len(i18n) - 1,
        "gdunit_discovered": len(re.findall(r"^func test_[a-z0-9_]+", testes, re.M)),
        "gdunit_skipped": len(re.findall(r"do_skip := true", testes)),
        "catalog_signals": _sinais_do_catalogo(),
        "numeric_comparisons": _valores_conferidos_do_dossie(),
        "proposed_fields": propostos,
        "proposed_phase_0_to_2": propostos_0_2,
    }


# Os campos de validation.json que sao contagens da arvore. Os restantes —
# engine, date, base, o que foi ou nao testado — sao testemunho de uma corrida,
# nao contagens, e por isso nao entram aqui: esta ferramenta nao os inventa.
CONTAVEIS_NO_VALIDATION = (
    "csv_tables",
    "original_csv_unchanged",
    "generated_resources",
    "adrs",
    "spec_sections",
    "i18n_keys",
    "gdunit_discovered",
    "gdunit_skipped",
    "numeric_comparisons",
    "proposed_fields",
    "proposed_phase_0_to_2",
    "catalog_signals",
    "event_bus_signals",
)

# Cada linha e uma afirmacao em prosa e a medicao que a tem de sustentar. O
# padrao apanha UM numero; se o texto mudar de forma, o padrao deixa de casar e
# isso tambem chumba — uma afirmacao que se perdeu e tao ma como uma errada.
AFIRMACOES: tuple[tuple[str, str, str], ...] = (
    ("README.md", r"(\d+) testes \(", "gdunit_discovered"),
    ("README.md", r"\((\d+) saltados", "gdunit_skipped"),
    ("README.md", r"\*\*(\d+) tabelas\*\*", "csv_tables"),
    ("README.md", r"tabelas\*\* e (\d+) recursos", "generated_resources"),
    ("README.md", r"confere \*\*(\d+) n[uú]meros\*\*", "numeric_comparisons"),
    ("docs/recovery/RETOMADA.md", r"(\d+) tabelas, \d+ recursos gerados", "csv_tables"),
    ("docs/recovery/RETOMADA.md", r"\d+ tabelas, (\d+) recursos gerados", "generated_resources"),
    ("docs/recovery/RETOMADA.md", r"confere (\d+)\s*\n?\s*n[uú]meros do dossi", "numeric_comparisons"),
    ("docs/recovery/RETOMADA.md", r"(\d+) casos, \d+ a passar", "gdunit_discovered"),
    ("docs/recovery/RETOMADA.md", r"\d+ casos, \d+ a passar, (\d+) saltados", "gdunit_skipped"),
    ("docs/recovery/RETOMADA.md", r"(\d+) ficheiros, gerado por", "spec_sections"),
    ("docs/recovery/RETOMADA.md", r"`docs/adr/` \| (\d+) decis", "adrs"),
    ("docs/recovery/RETOMADA.md", r"\| (\d+) tickets, um ficheiro cada", "tickets"),
    ("docs/recovery/RETOMADA.md", r"(\d+) chaves PT-PT e EN", "i18n_keys"),
)


def conferir(medido: dict[str, int]) -> list[str]:
    problemas: list[str] = []

    validacao = json.loads(VALIDACAO.read_text(encoding="utf-8"))
    for chave in CONTAVEIS_NO_VALIDATION:
        if validacao.get(chave) != medido[chave]:
            problemas.append(
                f"docs/recovery/validation.json: '{chave}' diz {validacao.get(chave)},"
                f" a contagem da {medido[chave]} — corre com --write"
            )

    # §46 e uma lista fechada: o que o EventBus declara e o que a tabela tem.
    # O event_bus_test confere nome a nome; aqui chumba tambem sem abrir o motor.
    if medido["event_bus_signals"] != medido["catalog_signals"]:
        problemas.append(
            f"src/core/event_bus.gd: declara {medido['event_bus_signals']} sinais,"
            f" a tabela da §46 tem {medido['catalog_signals']}"
        )

    for ficheiro, padrao, chave in AFIRMACOES:
        texto = (RAIZ / ficheiro).read_text(encoding="utf-8")
        achado = re.search(padrao, texto)
        if achado is None:
            problemas.append(f"{ficheiro}: a afirmacao sobre '{chave}' desapareceu ({padrao})")
        elif int(achado.group(1)) != medido[chave]:
            problemas.append(
                f"{ficheiro}: diz {achado.group(1)} para '{chave}', a contagem da {medido[chave]}"
            )

    # O tickets.json alimenta o painel de estado; um ticket novo em docs/backlog/
    # que nao entre la desaparece do plano sem dar erro.
    tickets = json.loads((RAIZ / "docs/backlog/tickets.json").read_text(encoding="utf-8"))
    if len(tickets) != medido["tickets"]:
        problemas.append(
            f"docs/backlog/tickets.json: tem {len(tickets)} entradas,"
            f" docs/backlog/ tem {medido['tickets']} tickets"
        )
    for ficheiro in _glob("docs/backlog/*.md", excluir=("README.md",)):
        if ficheiro.stem not in tickets:
            problemas.append(f"docs/backlog/tickets.json: falta o {ficheiro.stem}")

    # O estado de cada ticket vive no ficheiro dele; o tickets.json e a tabela
    # do README tem de dizer o mesmo (tools/estado_tickets.py).
    problemas.extend(estado_tickets.divergencias(RAIZ))
    return problemas


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true", help="corrige os contaveis do validation.json")
    args = parser.parse_args()

    medido = medir()

    if args.write:
        validacao = json.loads(VALIDACAO.read_text(encoding="utf-8"))
        mudados = [c for c in CONTAVEIS_NO_VALIDATION if validacao.get(c) != medido[c]]
        validacao.update({c: medido[c] for c in CONTAVEIS_NO_VALIDATION})
        VALIDACAO.write_text(json.dumps(validacao, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
        print(f"check_claims: validation.json atualizado, {len(mudados)} campo(s) mudaram: {mudados}")
        acertos = estado_tickets.escrever(RAIZ)
        print(f"check_claims: estado dos tickets, {len(acertos)} acerto(s): {acertos}")
        return 0

    problemas = conferir(medido)
    if problemas:
        print("check_claims: afirmacoes que a contagem nao sustenta\n")
        for p in problemas:
            print(f"  {p}")
        return 1
    print(
        f"check_claims: {len(AFIRMACOES)} afirmacoes em prosa,"
        f" {len(CONTAVEIS_NO_VALIDATION)} campos de validation.json e o tickets.json"
        f" conferidos contra {len(medido)} contagens — 0 divergencias"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
