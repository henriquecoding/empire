#!/usr/bin/env python3
"""Recolher, por GET publico, as paginas que a pesquisa cita, e medir a deriva.

So faz GET a paginas publicas, com uma pausa entre pedidos; nunca envia uma
geracao, nunca usa chave e nao segue nada que exija sessao. Os corpos ficam
numa pasta fora do repositorio (`--out`): nao se redistribuem. O que se grava
no repositorio e a proveniencia: estado HTTP, bytes, o SHA-256 dos bytes e o
SHA-256 do texto normalizado.

Porque dois hashes: o HTML do site e gerado pelo Next.js e leva um `buildId` e
nomes de ficheiros que mudam a cada publicacao. O hash dos bytes muda mesmo sem
nenhuma palavra nova; o hash do texto (sem scripts, estilos nem etiquetas, e
com o espaco comprimido) so muda quando o conteudo muda. Para JSON, o texto
normalizado e o JSON canonico (chaves ordenadas), que ignora a formatacao.

    python3 -I coleta.py --out /tmp/x --previous ../2026-10-23-pixellab/proveniencia.json \
        --output proveniencia.json
"""

from __future__ import annotations

import argparse
import hashlib
import html
import json
import re
import time
from datetime import datetime, timezone
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

HERE = Path(__file__).resolve().parent
AGENT = "Empire-public-research/2 (+https://github.com/henriquecoding/empire)"
MAX_BYTES = 8 * 1024 * 1024
NEW = (
    "https://www.pixellab.ai/robots.txt",
    "https://www.pixellab.ai/sitemap.xml",
    "https://www.pixellab.ai/llms.txt",
    "https://www.pixellab.ai/llms-full.txt",
    "https://www.pixellab.ai/privacypolicy",
    "https://www.pixellab.ai/refundpolicy",
    "https://www.pixellab.ai/enterprise",
    "https://www.pixellab.ai/ai-game-builder",
    "https://www.pixellab.ai/image-to-pixel-art",
    "https://www.pixellab.ai/pixel-art-vfx-generator",
    "https://www.pixellab.ai/docs/options/dithering",
    "https://www.pixellab.ai/docs/options/outline",
    "https://www.pixellab.ai/docs/options/shading",
    "https://www.pixellab.ai/docs/options/details",
    "https://api.pixellab.ai/v2/openapi.json",
    "https://api.pixellab.ai/mcp/docs",
    "https://pypi.org/pypi/pixellab/json",
    "https://registry.npmjs.org/@pixellab-code%2fpixellab",
    "https://huggingface.co/api/models?author=pixelparty&full=true",
    "https://ai.google.dev/gemini-api/docs/image-generation?hl=en",
)


def normalized(body: bytes, content_type: str) -> bytes:
    """O texto que conta: JSON canonico, ou o HTML sem scripts, estilos nem etiquetas."""
    text = body.decode("utf-8", "replace")
    if "json" in content_type:
        try:
            return json.dumps(json.loads(text), sort_keys=True, separators=(",", ":")).encode()
        except ValueError:
            pass
    if "html" in content_type:
        text = re.sub(r"<(script|style|noscript)\b.*?</\1>", " ", text, flags=re.S | re.I)
        text = html.unescape(re.sub(r"<[^>]+>", " ", text))
    return re.sub(r"\s+", " ", text).strip().encode()


def fetch(url: str) -> tuple[int, bytes, str, dict]:
    request = Request(url, headers={"User-Agent": AGENT, "Accept": "*/*"})
    try:
        with urlopen(request, timeout=45) as response:
            body = response.read(MAX_BYTES + 1)
            headers = {k.lower(): v for k, v in response.headers.items()}
            return response.status, body[:MAX_BYTES], headers.get("content-type", ""), headers
    except HTTPError as error:
        return error.code, error.read()[:MAX_BYTES], error.headers.get("content-type", ""), {}
    except URLError as error:
        return 0, str(error.reason).encode(), "", {}


def safe_name(url: str) -> str:
    return re.sub(r"[^A-Za-z0-9._-]+", "_", url.split("://", 1)[1])[:150]


def collect(urls: list[str], out: Path, pause: float) -> list[dict]:
    out.mkdir(parents=True, exist_ok=True)
    records = []
    for url in urls:
        status, body, content_type, headers = fetch(url)
        (out / safe_name(url)).write_bytes(body)
        title = re.search(rb"<title>([^<]{0,200})</title>", body)
        records.append({
            "url": url,
            "http_status": status,
            "bytes": len(body),
            "content_type": content_type.split(";")[0],
            "sha256": hashlib.sha256(body).hexdigest(),
            "text_sha256": hashlib.sha256(normalized(body, content_type)).hexdigest(),
            "title": html.unescape(title.group(1).decode("utf-8", "replace")).strip() if title else None,
            "server": headers.get("server"),
        })
        time.sleep(pause)
    return records


def drift(records: list[dict], previous: dict) -> dict:
    """Comparar com a coleta anterior: so os bytes, que e o que ela guardou."""
    before = {s["url"]: s for s in previous.get("collected_public_sources", [])}
    rows = {"same_bytes": [], "changed_bytes": [], "gone": [], "new": []}
    for record in records:
        old = before.get(record["url"])
        if old is None:
            rows["new"].append(record["url"])
        elif record["http_status"] != 200:
            rows["gone"].append(record["url"])
        elif old["sha256"] == record["sha256"]:
            rows["same_bytes"].append(record["url"])
        else:
            rows["changed_bytes"].append(record["url"])
    openapi = previous.get("openapi", {})
    now = next((r for r in records if r["url"] == openapi.get("url")), None)
    return {
        "previous_research_date": previous.get("research_date"),
        "counts": {k: len(v) for k, v in rows.items()},
        "lists": rows,
        "openapi_bytes_changed": bool(now and now["sha256"] != openapi.get("sha256")),
        "note": "Bytes de HTML mudam a cada publicacao do site (buildId do Next.js); "
                "so o text_sha256 desta coleta serve de base para a proxima comparacao de conteudo.",
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--out", type=Path, required=True, help="Pasta fora do repositorio para os corpos")
    parser.add_argument("--previous", type=Path, default=HERE.parent / "2026-10-23-pixellab/proveniencia.json")
    parser.add_argument("--output", type=Path, default=HERE / "proveniencia.json")
    parser.add_argument("--pause", type=float, default=0.5, help="Segundos entre pedidos")
    args = parser.parse_args()
    previous = json.loads(args.previous.read_text(encoding="utf-8"))
    urls = [s["url"] for s in previous["collected_public_sources"]]
    urls += [u for u in NEW if u not in urls]
    records = collect(urls, args.out, args.pause)
    report = {
        "schema_version": 1,
        "collected_at_utc": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "method": "GET publico, sem chave nem sessao; corpos fora do repositorio",
        "user_agent": AGENT,
        "sources": records,
        "drift_since_previous": drift(records, previous),
    }
    args.output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"sources": len(records), **report["drift_since_previous"]["counts"]}))


if __name__ == "__main__":
    main()
