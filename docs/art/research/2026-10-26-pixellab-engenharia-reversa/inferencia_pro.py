#!/usr/bin/env python3
"""Inferir a tela interna das ferramentas "Pro" do PixelLab a partir de numeros publicos.

Tres fontes publicas, todas lidas da pasta que o coleta.py preenche (`--corpus`):

1. a tabela "Output Counts by Size" e os tetos por proporcao do
   `/generate-image-v2` na especificacao OpenAPI;
2. os escaloes de preco "Up to NxN" das ferramentas Pro na pagina da API;
3. as tabelas de resolucao por proporcao dos modelos de imagem do Gemini.

O resultado e uma inferencia com teste, nao um facto: diz que numeros coincidem
e quais nao. Nao chama nenhum modelo e nao prova que fornecedor o PixelLab usa.

    python3 -I inferencia_pro.py --corpus /tmp/x --output inferencia-pro.json
"""

from __future__ import annotations

import argparse
import hashlib
import html
import json
import re
from pathlib import Path

CANVAS = 1024
FILES = {
    "openapi": "api.pixellab.ai_v2_openapi.json",
    "catalog": "www.pixellab.ai_pixellab-api",
    "gemini": "ai.google.dev_gemini-api_docs_image-generation_hl_en",
}


def read(corpus: Path, key: str) -> tuple[bytes, str]:
    raw = (corpus / FILES[key]).read_bytes()
    return raw, hashlib.sha256(raw).hexdigest()


def text_of(raw: bytes) -> str:
    text = re.sub(r"<(script|style)\b.*?</\1>", " ", raw.decode("utf-8", "replace"), flags=re.S | re.I)
    return re.sub(r"\s+", " ", html.unescape(re.sub(r"<[^>]+>", " ", text)))


def output_counts(doc: dict) -> list[dict]:
    """As linhas "Up to 32px: 64 images (8x8 grid)" do generate-image-v2."""
    desc = doc["paths"]["/generate-image-v2"]["post"]["description"]
    rows, low = [], 1
    for m in re.finditer(r"- (?:Up to (\d+)|(\d+)-(\d+)|(\d+)|Above (\d+))px: (\d+) images", desc):
        up, a, b, single, above, n = m.groups()
        if above:
            rows.append({"min": int(above) + 1, "max": None, "images": int(n), "grid": 1})
            continue
        lo, hi = (low, int(up)) if up else ((int(a), int(b)) if a else (int(single), int(single)))
        k = round(int(n) ** 0.5)
        rows.append({"min": lo, "max": hi, "images": int(n), "grid": k, "logical_canvas": k * hi,
                     "device_px_at": {str(u): k * hi * u for u in (4, 3, 2)},
                     "largest_scale_fitting_1024": max((u for u in (4, 3, 2, 1) if k * hi * u <= CANVAS), default=None)})
        low = hi + 1
    return rows


def aspect_caps(doc: dict) -> dict:
    desc = doc["paths"]["/generate-image-v2"]["post"]["description"]
    schema = doc["components"]["schemas"]["app__endpoints__external__v2__generate_image_v2__ImageSize"]["properties"]
    named = {f"{w}x{h}": label for w, h, label in re.findall(r"(\d+)x(\d+) for ([\w:]+)", desc)}
    return {"named": named, "max_width": schema["width"]["maximum"], "max_height": schema["height"]["maximum"]}


def price_tiers(catalog: str) -> dict:
    """Os escaloes "Up to NxN : $X" de cada ferramenta Pro, pela ordem da pagina."""
    tiers = {}
    pro = catalog.split("Pro Tools", 1)[-1].split("Pro Flash", 1)[0]
    for block in re.split(r"POST /v2/ ", pro)[1:]:
        name = block.split()[0]
        found = re.findall(r"[Uu]p to (\d+)\s*[x×]\s*\d+ : \$([\d.]+)", block)
        if found:
            tiers[name] = [{"side": int(s), "usd": float(p)} for s, p in found]
    return tiers


def gemini_tables(page: str) -> dict:
    """As tabelas "Aspect ratio | resolution" de cada modelo, a 1K."""
    tables = {}
    for m in re.finditer(r'<h3 id="([^"]+)"', page):
        segment = page[m.end():].split("<h3", 1)[0]
        rows = re.findall(r"<td[^>]*>\s*(?:<strong>)?\s*(\d+:\d+)\s*(?:</strong>)?\s*</td>(.*?)</tr>",
                          segment, flags=re.S)
        if not rows:
            continue
        table = {}
        for ratio, rest in rows:
            sizes = [(int(w), int(h)) for w, h in re.findall(r"(\d+)x(\d+)", rest)]
            if sizes:
                table[ratio] = list(min(sizes, key=lambda s: abs(s[0] * s[1] - CANVAS * CANVAS)))
        if table:
            tables[m.group(1)] = table
    return tables


def coincidence(caps: dict, tables: dict) -> dict:
    """Que tabelas, divididas por 2, dao os tetos publicados do Pro."""
    wanted = {tuple(int(v) for v in k.split("x")) for k in caps["named"]}
    out = {}
    for model, table in tables.items():
        halves = {r: (w // 2, h // 2) for r, (w, h) in table.items()}
        widest, tallest = max(w for w, _ in halves.values()), max(h for _, h in halves.values())
        out[model] = {
            "ratios": sorted(table),
            "named_caps_found": sorted(f"{w}x{h}" for w, h in wanted if (w, h) in halves.values()),
            "max_half_width": widest,
            "max_half_height": tallest,
            "all_named_match": wanted <= set(halves.values()),
            "max_width_match": widest == caps["max_width"],
            "max_height_match": tallest == caps["max_height"],
        }
    return out


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--corpus", type=Path, required=True, help="Pasta que o coleta.py preencheu")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    (spec, spec_sha), (cat, cat_sha), (gem, gem_sha) = (read(args.corpus, k) for k in ("openapi", "catalog", "gemini"))
    doc = json.loads(spec)
    rows = output_counts(doc)
    caps = aspect_caps(doc)
    tiers = price_tiers(text_of(cat))
    tables = gemini_tables(gem.decode("utf-8", "replace"))
    base = [t["side"] for t in tiers.get("generate-image-v2", [])]
    report = {
        "sources_sha256": {"openapi": spec_sha, "catalog_html": cat_sha, "gemini_html": gem_sha},
        "output_counts": rows,
        "logical_canvas_by_grid": sorted({r.get("logical_canvas") for r in rows if r.get("logical_canvas")}),
        "price_tiers": tiers,
        "price_tiers_as_fraction_of_image_tiers": {
            name: [round(t["side"] / b, 3) for t, b in zip(ts, base)] for name, ts in tiers.items() if base},
        "image_tiers_times_scale": [{"side": s, "x": CANVAS / s} for s in base],
        "aspect_caps": caps,
        "gemini_1k_halved": coincidence(caps, tables),
        "reading": [
            "Escaloes de preco 256/341/512 = 1024/4, 1024/3, 1024/2: uma tela de ~1024 px a escala inteira.",
            "k*s_max fica entre 245 e 256 para grelhas 3x3 a 8x8, e 340 para 2x2 e para o caso 85 px (4x4).",
            "Nenhuma regra unica de margem reproduz todas as linhas: a formula exata fica em aberto.",
            "Coincidencia de tabela de resolucao e indicio, nao prova de fornecedor.",
        ],
    }
    text = json.dumps(report, ensure_ascii=False, indent=2) + "\n"
    if args.output:
        args.output.write_text(text, encoding="utf-8")
        match = [m for m, v in report["gemini_1k_halved"].items()
                 if v["all_named_match"] and v["max_width_match"] and v["max_height_match"]]
        print(json.dumps({"rows": len(rows), "tiers": len(tiers), "gemini_tables": len(tables), "match": match}))
    else:
        print(text, end="")


if __name__ == "__main__":
    main()
