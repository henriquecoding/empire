#!/usr/bin/env python3
"""Conferir o pacote de 26/10 sem rede: JSON, ligacoes, coerencia com a Forja e numeros citados.

Nao mede imagens nem chama o PixelLab. Falha (codigo 1) na primeira incoerencia:
um JSON que nao abre, uma ligacao local partida, um script com mais de 250
linhas, um resultado de sonda inventado, o adaptador da Forja com outro hash de
especificacao que nao o do contrato gravado, uma divergencia de conformidade, um
caminho local ou um endereco de email nos ficheiros, ou um numero citado na prosa
que nao e o que os JSON dizem.

    python3 -I verificar.py [--write]
"""

from __future__ import annotations

import argparse
import ast
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(f"verificar: {message}")


def load(name: str) -> dict:
    return json.loads((HERE / name).read_text(encoding="utf-8"))


def links() -> int:
    count = 0
    for path in HERE.glob("*.md"):
        text = re.sub(r"```.*?```", "", path.read_text(encoding="utf-8"), flags=re.S)
        for target in re.findall(r"\]\(([^)\s]+)\)", text):
            if target.startswith(("https://", "http://", "#", "mailto:")) or target == "verificacao.json":
                continue
            local = (path.parent / target.split("#", 1)[0]).resolve()
            require(local.exists(), f"ligacao partida em {path.name}: {target}")
            count += 1
    return count


def scripts() -> int:
    for path in HERE.glob("*.py"):
        source = path.read_text(encoding="utf-8")
        ast.parse(source)
        require(len(source.splitlines()) <= 250, f"{path.name} passa das 250 linhas")
    return len(list(HERE.glob("*.py")))


def hygiene() -> None:
    for path in [*HERE.glob("*.md"), *HERE.glob("*.json")]:
        text = path.read_text(encoding="utf-8")
        require("/tmp/" not in text and "/home/" not in text, f"caminho local em {path.name}")
        require(not re.search(r"[\w.+-]+@[A-Za-z][\w-]*\.[A-Za-z]{2,}", text), f"endereco de email em {path.name}")


def probes() -> dict:
    plan = load("sondas.json")
    require(plan["status"] == "planned_not_executed" and plan["results"] is None, "sondas com resultados")
    require(plan["paid_api_calls"] == 0, "sondas declaram chamadas pagas")
    ids = [p["id"] for p in plan["probes"]]
    require(len(ids) == len(set(ids)), "id de sonda repetido")
    calls = sum(p["calls"] for p in plan["probes"])
    usd = sum(p["calls"] * p["unit_usd"] for p in plan["probes"])
    return {"probes": len(ids), "calls": calls, "usd": round(usd, 2)}


def contract() -> dict:
    sys.path.insert(0, str(ROOT))
    from tools.forja.backends import pixellab_api  # noqa: E402
    now, before = load("contrato-2026-10-26.json"), load("conformidade-forja-antes.json")
    require(now["forja_conformance"]["mismatches"] == [], "a Forja diverge do contrato gravado")
    require(pixellab_api.SPEC_SHA256 == now["sha256"], "o adaptador da Forja regista outro hash de especificacao")
    require(before["spec_sha256"] == now["sha256"], "o antes e o depois nao falam da mesma especificacao")
    return {"operations": now["counts"]["operations"], "paths": now["counts"]["paths"],
            "schemas": now["counts"]["schemas"], "checked": now["forja_conformance"]["checked"],
            "mismatches_before": len(before["mismatches"])}


def provenance() -> dict:
    data = load("proveniencia.json")
    urls = [s["url"] for s in data["sources"]]
    require(len(urls) == len(set(urls)), "URL repetido na proveniencia")
    for source in data["sources"]:
        require(source["url"].startswith("https://"), f"fonte sem HTTPS: {source['url']}")
        require(re.fullmatch(r"[0-9a-f]{64}", source["sha256"]) is not None, "hash invalido")
    ok = sum(s["http_status"] == 200 for s in data["sources"])
    return {"sources": len(urls), "http_200": ok, **data["drift_since_previous"]["counts"]}


def cited(numbers: dict) -> int:
    """Os numeros que a prosa cita tem de ser os dos JSON."""
    text = "\n".join(p.read_text(encoding="utf-8") for p in HERE.glob("*.md"))
    forensic = load("forense-imagens.json")["summary"]
    expected = [
        f"{numbers['contract']['operations']} operações",
        f"{numbers['contract']['mismatches_before']} divergências",
        f"{numbers['contract']['checked']} verificações",
        f"{forensic['estimate_wrong_on_outputs']} de {forensic['model_outputs']}",
        f"{forensic['checked_wrong_on_outputs']} de {forensic['model_outputs']}",
        f"{numbers['probes']['calls']} chamadas",
        f"{numbers['provenance']['sources']} respostas",
    ]
    for phrase in expected:
        require(phrase in text, f"a prosa nao cita '{phrase}' (o numero mudou?)")
    return len(expected)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--write", action="store_true", help="Gravar verificacao.json")
    args = parser.parse_args()
    for path in HERE.glob("*.json"):
        json.loads(path.read_text(encoding="utf-8"))
    numbers = {"links": links(), "scripts": scripts(), "probes": probes(), "contract": contract(),
               "provenance": provenance()}
    hygiene()
    numbers["cited_numbers"] = cited(numbers)
    report = {"checked_at_utc": datetime.now(timezone.utc).isoformat(timespec="seconds"),
              "command": "python3 -I docs/art/research/2026-10-26-pixellab-engenharia-reversa/verificar.py",
              **numbers, "generation_executed": False, "paid_api_calls": 0}
    if args.write:
        (HERE / "verificacao.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n",
                                               encoding="utf-8")
    print(json.dumps(report, ensure_ascii=False))


if __name__ == "__main__":
    main()
