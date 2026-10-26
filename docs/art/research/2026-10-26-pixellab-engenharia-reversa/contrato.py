#!/usr/bin/env python3
"""A impressao digital do contrato publico do PixelLab, a deriva e a conformidade da Forja.

Le a especificacao OpenAPI publica (GET sem chave, ou uma copia local com
`--input`) e grava so estrutura, nunca o corpo: o hash dos bytes e do JSON
canonico, um hash por operacao do esquema do pedido, os limites que a Forja usa
e os sinais que a especificacao da sobre a pilha (FastAPI, nomes de modulos).
Com `--previous` compara com uma impressao anterior e lista o que entrou, saiu
ou mudou. A seccao `forja_conformance` confere `tools/forja/backends/pixellab_api`
contra os limites lidos: o que a Forja aceitaria e a API recusaria, e o inverso.

    python3 -I contrato.py --output contrato-2026-10-26.json
    python3 -I contrato.py --input copia.json --previous contrato-2026-10-26.json --output novo.json
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from urllib.request import Request, urlopen

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
URL = "https://api.pixellab.ai/v2/openapi.json"
METHODS = ("get", "post", "put", "patch", "delete")
FACETS = ("type", "enum", "const", "minimum", "maximum", "exclusiveMinimum", "multipleOf", "minItems",
          "maxItems", "minLength", "maxLength", "default", "required", "deprecated", "additionalProperties")
IMAGE_MODELS = ("pixflux", "pixen", "bitforge")
ENUM_SCHEMAS = {"outline": "Outline", "shading": "Shading", "detail": "Detail", "view": "CameraView",
                "direction": "Direction"}


def canon(value) -> str:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


def resolve(schema: dict, doc: dict, depth: int = 0):
    """O esquema sem $ref nem textos: so tipos, limites, enums e campos."""
    if depth > 12 or not isinstance(schema, dict):
        return schema
    if "$ref" in schema:
        target = doc
        for part in schema["$ref"][2:].split("/"):
            target = target[part]
        return resolve(target, doc, depth + 1)
    out = {k: schema[k] for k in FACETS if k in schema}
    for key in ("anyOf", "oneOf", "allOf"):
        if key in schema:
            out[key] = [resolve(item, doc, depth + 1) for item in schema[key]]
    if "properties" in schema:
        out["properties"] = {k: resolve(v, doc, depth + 1) for k, v in schema["properties"].items()}
    if isinstance(schema.get("items"), dict):
        out["items"] = resolve(schema["items"], doc, depth + 1)
    return out


def request_schema(op: dict) -> dict:
    content = op.get("requestBody", {}).get("content", {})
    return content.get("application/json", {}).get("schema", {}) or next(iter(content.values()), {}).get("schema", {})


def operations(doc: dict) -> dict:
    ops = {}
    for path, item in sorted(doc["paths"].items()):
        for method in METHODS:
            if method not in item:
                continue
            op = item[method]
            body = resolve(request_schema(op), doc)
            ops[f"{method.upper()} {path}"] = {
                "operation_id": op.get("operationId"),
                "tags": op.get("tags", []),
                "deprecated": bool(op.get("deprecated")),
                "responses": sorted(op.get("responses", {})),
                "request_sha256": hashlib.sha256(canon(body).encode()).hexdigest()[:16],
                "description_sha256": hashlib.sha256((op.get("description") or "").encode()).hexdigest()[:16],
            }
    return ops


def stack_signals(doc: dict, ops: dict) -> dict:
    """O que a especificacao revela da pilha, sem pedir nada ao servidor."""
    schemas = doc.get("components", {}).get("schemas", {})
    default_ids = [k for k, v in ops.items() if (v["operation_id"] or "").endswith("_" + k.split()[0].lower())]
    modules = sorted({"/".join(n.split("__")[:-1]) for n in schemas if n.startswith("app__")})
    return {
        "fastapi_validation_schemas": all(n in schemas for n in ("HTTPValidationError", "ValidationError")),
        "operation_ids_with_fastapi_default_suffix": len(default_ids),
        "operation_ids_explicit": sorted(v["operation_id"] for k, v in ops.items() if k not in default_ids),
        "module_paths_from_schema_names": modules,
        "info_version": doc.get("info", {}).get("version"),
        "servers": doc.get("servers"),
    }


def number_range(prop: dict) -> dict | None:
    for option in [prop, *prop.get("anyOf", [])]:
        if option.get("type") in ("integer", "number") and ("minimum" in option or "maximum" in option):
            return {k: option[k] for k in ("minimum", "maximum") if k in option} | (
                {"default": prop["default"]} if "default" in prop else {})
    return None


def image_facts(doc: dict, model: str) -> dict:
    op = doc["paths"][f"/create-image-{model}"]["post"]
    raw = request_schema(op)
    if "$ref" in raw:
        raw = doc["components"]["schemas"][raw["$ref"].rsplit("/", 1)[-1]]
    props = resolve(raw, doc)["properties"]
    size = props["image_size"]["properties"]
    text = (op.get("description") or "") + " " + json.dumps(doc["components"]["schemas"]).split(
        f'"app__endpoints__external__v2__create_image_{model}__ImageSize"', 1)[-1][:900]
    area = re.findall(r"(?:maximum|max) area (\d+)x(\d+)", text, flags=re.I)
    minimum = re.findall(r"minimum area (\d+)x(\d+)", text, flags=re.I)
    transparent = re.search(r"Up to ([\d,]+) px of area", raw["properties"].get("no_background", {}).get(
        "description", ""))
    return {
        "axis": {k: {f: size[k].get(f) for f in ("minimum", "maximum", "multipleOf")} for k in ("width", "height")},
        "max_area": int(area[0][0]) * int(area[0][1]) if area else None,
        "min_area": int(minimum[0][0]) * int(minimum[0][1]) if minimum else None,
        "square_below": 32 if re.search(r"square when either side is below 32", text) else None,
        "transparent_max_area": int(transparent.group(1).replace(",", "")) if transparent else None,
        "fields": sorted(props),
        "ranges": {k: r for k, v in props.items() if (r := number_range(v))},
    }


def conformance(doc: dict, facts: dict) -> dict:
    sys.path.insert(0, str(ROOT))
    from tools.forja.backends import pixellab_api as forja  # noqa: E402
    problems, checked = [], 0
    for model in IMAGE_MODELS:
        caps, f = forja.CAPS[model], facts[model]
        pairs = [("max_area", caps.get("max_area"), f["max_area"]), ("min_area", caps.get("min_area"), f["min_area"]),
                 ("min_side", caps.get("min_side", 1), f["axis"]["width"]["minimum"]),
                 ("max_side", caps.get("max_side"), f["axis"]["width"]["maximum"]),
                 ("multiple", caps.get("multiple"), f["axis"]["width"]["multipleOf"]),
                 ("square_below", caps.get("square_below"), f["square_below"]),
                 ("transparent_max_area", caps.get("transparent_max_area"), f["transparent_max_area"])]
        for name, mine, theirs in pairs:
            checked += 1
            if theirs is not None and mine != theirs:
                problems.append({"model": model, "limit": name, "forja": mine, "spec": theirs})
        for name in caps["fields"] + caps["images"]:
            checked += 1
            if name not in f["fields"]:
                problems.append({"model": model, "field": name, "issue": "a Forja envia e a especificacao nao tem"})
        for name, spec_range in f["ranges"].items():
            if name not in caps["fields"]:
                continue
            checked += 1
            mine = getattr(forja, "RANGES", {}).get(name)
            if mine is None or (mine[0], mine[1]) != (spec_range.get("minimum"), spec_range.get("maximum")):
                problems.append({"model": model, "range": name, "forja": mine, "spec": spec_range})
    schemas = doc["components"]["schemas"]
    for field, schema in ENUM_SCHEMAS.items():
        checked += 1
        if tuple(schemas[schema]["enum"]) != tuple(forja.ENUMS[field]):
            problems.append({"enum": field, "forja": list(forja.ENUMS[field]), "spec": schemas[schema]["enum"]})
    return {"forja_spec_sha256": forja.SPEC_SHA256, "checked": checked, "mismatches": problems}


def diff(now: dict, before: dict) -> dict:
    a, b = before["operations"], now["operations"]
    return {
        "previous_sha256": before["sha256"],
        "added": sorted(set(b) - set(a)),
        "removed": sorted(set(a) - set(b)),
        "request_changed": sorted(k for k in set(a) & set(b) if a[k]["request_sha256"] != b[k]["request_sha256"]),
        "description_changed": sorted(k for k in set(a) & set(b)
                                      if a[k]["description_sha256"] != b[k]["description_sha256"]),
        "facts_changed": sorted(m for m in now["image_facts"] if now["image_facts"][m] != before["image_facts"].get(m)),
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--input", type=Path, help="Copia local da especificacao (sem rede)")
    parser.add_argument("--previous", type=Path, help="Impressao anterior para comparar")
    parser.add_argument("--output", type=Path, help="Onde gravar (por omissao, stdout)")
    args = parser.parse_args()
    if args.input:
        raw = args.input.read_bytes()
    else:
        with urlopen(Request(URL, headers={"User-Agent": "Empire-public-research/2"}), timeout=45) as response:
            raw = response.read(8 * 1024 * 1024)
    doc = json.loads(raw)
    ops = operations(doc)
    facts = {m: image_facts(doc, m) for m in IMAGE_MODELS}
    report = {
        "observed_at_utc": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "source": URL,
        "read_from": "copia local (--input)" if args.input else "GET",
        "sha256": hashlib.sha256(raw).hexdigest(),
        "canonical_sha256": hashlib.sha256(canon(doc).encode()).hexdigest(),
        "bytes": len(raw),
        "openapi": doc.get("openapi"),
        "counts": {"paths": len(doc["paths"]), "operations": len(ops),
                   "schemas": len(doc.get("components", {}).get("schemas", {})),
                   "deprecated": sum(v["deprecated"] for v in ops.values())},
        "stack_signals": stack_signals(doc, ops),
        "image_facts": facts,
        "forja_conformance": conformance(doc, facts),
        "operations": ops,
        "limits": ["Estrutura e textos publicos; o comportamento real do servidor nao foi exercido.",
                   "Limites so em prosa podem escapar ao extrator; ver image_facts antes de confiar."],
    }
    if args.previous:
        report["diff"] = diff(report, json.loads(args.previous.read_text(encoding="utf-8")))
    text = json.dumps(report, ensure_ascii=False, indent=2) + "\n"
    if args.output:
        args.output.write_text(text, encoding="utf-8")
        print(json.dumps({"sha256": report["sha256"][:16], **report["counts"],
                          "forja_mismatches": len(report["forja_conformance"]["mismatches"])}))
    else:
        print(text, end="")


if __name__ == "__main__":
    main()
