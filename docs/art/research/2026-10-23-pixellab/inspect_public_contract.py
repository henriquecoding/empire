#!/usr/bin/env python3
"""Inspect public OpenAPI metadata. Only GET; never submits a generation."""

from __future__ import annotations

import argparse
import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path
from urllib.request import Request, urlopen

URL = "https://api.pixellab.ai/v2/openapi.json"
MAX_BYTES = 8 * 1024 * 1024
METHODS = {"get", "post", "put", "patch", "delete", "head", "options", "trace"}
SELECTED = (
    "/create-image-pixen",
    "/generate-image-v2",
    "/animate-with-text-v3",
    "/animate-with-skeleton-v3",
    "/inpaint-v3",
    "/estimate-skeleton",
    "/animate-pixminimax",
)
FACETS = (
    "type", "enum", "minimum", "maximum", "multipleOf", "minItems", "maxItems",
    "minLength", "maxLength", "pattern", "default", "required",
)


def compact(schema: dict, document: dict, depth: int = 0) -> dict:
    """Return structural constraints, excluding documentation bodies."""
    if depth > 8:
        return {"truncated_at_depth": depth}
    result = {}
    if "$ref" in schema:
        ref = schema["$ref"]
        result["schema_ref"] = ref
        if not ref.startswith("#/"):
            result["external_ref_not_resolved"] = True
            return result
        target = document
        for part in ref[2:].split("/"):
            target = target[part.replace("~1", "/").replace("~0", "~")]
        result.update(compact(target, document, depth + 1))
    result.update({key: schema[key] for key in FACETS if key in schema})
    for key in ("anyOf", "oneOf", "allOf"):
        if key in schema:
            result[key] = [compact(item, document, depth + 1) for item in schema[key]]
    if "properties" in schema:
        result["properties"] = {
            name: compact(value, document, depth + 1)
            for name, value in schema["properties"].items()
        }
    if isinstance(schema.get("items"), dict):
        result["items"] = compact(schema["items"], document, depth + 1)
    return result


def inspect(raw: bytes) -> dict:
    document = json.loads(raw)
    paths = document["paths"]
    selected = {}
    for path in SELECTED:
        if path not in paths:
            selected[path] = {"present": False}
            continue
        operations = {}
        for method, operation in paths[path].items():
            if method not in METHODS:
                continue
            body = operation.get("requestBody", {}).get("content", {})
            schema = body.get("application/json", {}).get("schema", {})
            operations[method] = {
                "response_codes": sorted(operation.get("responses", {})),
                "request_constraints": compact(schema, document),
            }
        selected[path] = {"present": True, "operations": operations}
    return {
        "observed_at_utc": datetime.now(timezone.utc).isoformat(),
        "source_url": URL,
        "sha256": hashlib.sha256(raw).hexdigest(),
        "bytes": len(raw),
        "openapi": document.get("openapi"),
        "info_version": document.get("info", {}).get("version"),
        "path_count": len(paths),
        "operation_count": sum(m in METHODS for item in paths.values() for m in item),
        "schema_count": len(document.get("components", {}).get("schemas", {})),
        "limitations": [
            "Structural inspection only; no authenticated request was made.",
            "Prose-only constraints and actual server behavior are not validated.",
            "A matching schema does not establish quality or compatibility of an SDK.",
        ],
        "selected_paths": selected,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, help="Read a local OpenAPI copy instead of GET")
    parser.add_argument("--output", type=Path, help="Write report here instead of stdout")
    args = parser.parse_args()
    if args.input:
        if args.input.stat().st_size > MAX_BYTES:
            raise SystemExit("Input exceeds the inspection size limit")
        raw = args.input.read_bytes()
    else:
        request = Request(URL, headers={"User-Agent": "Empire-public-contract-research/1"})
        with urlopen(request, timeout=45) as response:
            raw = response.read(MAX_BYTES + 1)
    if len(raw) > MAX_BYTES:
        raise SystemExit("Response exceeds the inspection size limit")
    rendered = json.dumps(inspect(raw), ensure_ascii=False, indent=2) + "\n"
    if args.output:
        args.output.write_text(rendered, encoding="utf-8")
    else:
        print(rendered, end="")


if __name__ == "__main__":
    main()
