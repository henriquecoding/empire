#!/usr/bin/env python3
"""Conferir o envio de 26/10 (FORJA-04, PR #123): o pacote, o catalogo dos 200 videos e as alegacoes.

Tres verificacoes, todas repetiveis:

1. `--checkout`: o MANIFESTO-SHA256.json do pacote contra os ficheiros do ramo
   (os dois Markdown estao fora de pacote/, com outro nome e os mesmos bytes).
2. `--catalog`: cada video do catalogo existe no YouTube, e do canal PixelLab e tem
   o titulo registado. Usa o oEmbed publico (sem chave): so confirma existencia,
   autor e titulo atual; nao diz nada sobre as legendas.
3. `--spec`: as alegacoes do relatorio de 25/10 sobre o /reduce-colors e o
   drift_threshold, contra a especificacao OpenAPI recolhida.

    python3 -I conferir_envio.py --checkout <ramo> --catalog <catalogo.json> --spec <openapi.json> \
        --output conferencia-forja-04.json
"""

from __future__ import annotations

import argparse
import hashlib
import json
import time
import unicodedata
import urllib.parse
from collections import Counter
from pathlib import Path
from urllib.error import HTTPError
from urllib.request import Request, urlopen

PACKAGE = Path("docs/art/research/2026-10-25-forja-pixels-cores")
RENAMED = {"Relatorio-Forja-Pixels-Cores-Claude-2026-10-25.md": "RELATORIO.md",
           "Dossie-PixelLab-200-Videos-2026-10-25.md": "DOSSIE-PIXELLAB-200-VIDEOS.md"}


def manifest(checkout: Path) -> dict:
    base = checkout / PACKAGE
    expected = json.loads((base / "pacote/MANIFESTO-SHA256.json").read_text(encoding="utf-8"))
    rows = []
    for name, digest in expected.items():
        path = base / RENAMED[name] if name in RENAMED else base / "pacote" / name
        found = hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file() else None
        rows.append({"file": name, "ok": found == digest})
    return {"files": len(rows), "matching": sum(r["ok"] for r in rows), "rows": rows}


def norm(text: str) -> str:
    return unicodedata.normalize("NFKC", text).strip().casefold()


def oembed(catalog: Path, pause: float) -> dict:
    items = json.loads(catalog.read_text(encoding="utf-8"))
    rows = []
    for item in items:
        watch = f"https://www.youtube.com/watch?v={item['video_id']}"
        url = "https://www.youtube.com/oembed?format=json&url=" + urllib.parse.quote(watch)
        row = {"video_id": item["video_id"]}
        try:
            with urlopen(Request(url, headers={"User-Agent": "Mozilla/5.0"}), timeout=20) as response:
                data = json.load(response)
            row.update(status=200, author=data.get("author_name"),
                       title_match=norm(data.get("title", "")) == norm(item["titulo"]))
            if not row["title_match"]:
                row.update(title_now=data.get("title"), title_catalog=item["titulo"])
        except HTTPError as error:
            row.update(status=error.code)
        rows.append(row)
        time.sleep(pause)
    return {"items": len(rows), "status": dict(Counter(str(r["status"]) for r in rows)),
            "authors": dict(Counter(r.get("author") for r in rows)),
            "titles_matching": sum(bool(r.get("title_match")) for r in rows),
            "differences": [r for r in rows if r.get("status") != 200 or not r.get("title_match")]}


def spec_claims(spec: Path) -> dict:
    raw = spec.read_bytes()
    doc = json.loads(raw)
    schemas = doc["components"]["schemas"]
    reduce_op = doc["paths"]["/reduce-colors"]["post"]
    reduce = schemas["ReduceColorsRequest"]["properties"]
    drift = schemas["AnimateWithTextV3Request"]["properties"]["drift_threshold"]["description"]
    claims = {
        "reduce_colors_total_512x512": "512x512 worth of pixels" in reduce_op["description"],
        "num_colors_and_palette_image_exclusive": "Mutually exclusive" in reduce["num_colors"]["description"],
        "dithering_2x2_4x4_8x8": reduce["dithering"]["enum"] == ["none", "2x2", "4x4", "8x8"],
        "drift_threshold_compares_with_first_frame": "from the first frame" in drift,
        "drift_threshold_zero_corrects_every_frame": "0 corrects every frame" in drift,
    }
    return {"spec_sha256": hashlib.sha256(raw).hexdigest(), "claims": claims, "all_true": all(claims.values())}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--checkout", type=Path, required=True)
    parser.add_argument("--catalog", type=Path, required=True)
    parser.add_argument("--spec", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--pause", type=float, default=0.15)
    args = parser.parse_args()
    report = {"manifest": manifest(args.checkout), "catalog_oembed": oembed(args.catalog, args.pause),
              "spec_claims": spec_claims(args.spec),
              "limits": ["O oEmbed confirma que o video existe, o autor e o titulo de hoje; nao confere legendas.",
                         "A conferencia nao repete a leitura dos videos nem julga a arte."]}
    args.output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"manifest": f"{report['manifest']['matching']}/{report['manifest']['files']}",
                      "videos": report["catalog_oembed"]["status"],
                      "titles": report["catalog_oembed"]["titles_matching"],
                      "spec_claims": report["spec_claims"]["all_true"]}))


if __name__ == "__main__":
    main()
