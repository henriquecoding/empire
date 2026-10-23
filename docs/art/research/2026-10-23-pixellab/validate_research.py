#!/usr/bin/env python3
"""Check the research package. Does not evaluate images or run a model."""

from __future__ import annotations

import argparse
import ast
import copy
import json
import re
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def check_links() -> int:
    count = 0
    for path in ROOT.rglob("*.md"):
        text = re.sub(r"```.*?```", "", path.read_text(encoding="utf-8"), flags=re.S)
        for target in re.findall(r"\]\(([^)]+)\)", text):
            if target.startswith(("https://", "http://", "#", "mailto:")):
                continue
            local = target.split("#", 1)[0]
            require((path.parent / local).is_file(), f"Missing link in {path.name}: {local}")
            count += 1
    return count


def check_references(provenance: dict) -> int:
    report = (ROOT / "RELATORIO-MESTRE.md").read_text(encoding="utf-8")
    body, bibliography = report.split("## 25. Referências primárias centrais", 1)
    defined = set(re.findall(r"^\| (P\d+) \|", bibliography, flags=re.M))
    used = set(re.findall(r"\bP\d+\b", body))
    require(used <= defined, f"Undefined references: {used - defined}")
    recorded = {item["id"] for item in provenance["central_references"]}
    require(defined == recorded, "Bibliography and provenance disagree")
    for source in provenance["collected_public_sources"]:
        require(source["url"].startswith("https://"), "Non-HTTPS source")
        require(source["http_status"] == 200, "Unacknowledged failed collection")
        require(bool(re.fullmatch(r"[a-f0-9]{64}", source["sha256"])), "Invalid source hash")
        require(source["bytes"] > 0, "Empty source body")
    urls = [item["url"] for item in provenance["collected_public_sources"]]
    require(len(urls) == len(set(urls)), "Duplicate collected URL")
    return len(defined)


def check_plan(plan: dict) -> dict:
    require(plan["status"] == "planned_not_executed", "Unexpected benchmark status")
    require(plan["results"] is None, "This research package must not invent results")
    require(plan["paid_api_calls"] == 0, "Unexpected paid generation claim")
    briefs = plan["static"]["briefs"]
    require(len({x["id"] for x in briefs}) == len(briefs), "Duplicate brief ID")
    configs = plan["configurations"]
    require(len({x["id"] for x in configs}) == len(configs), "Duplicate configuration ID")
    static_per = len(briefs) * len(plan["sizes"]) * len(plan["seeds"])
    animation = plan["animation"]
    clips_per = len(animation["characters"]) * len(animation["actions"])
    clips_per *= len(plan["sizes"]) * len(animation["seeds"])
    total_static, total_clips = static_per * len(configs), clips_per * len(configs)
    report = (ROOT / "RELATORIO-MESTRE.md").read_text(encoding="utf-8")
    require(f"{total_static} saídas estáticas" in report, "Static count in report drifted")
    require(f"{clips_per} clips por configuração" in report, "Clip count in report drifted")
    require(f"{total_clips} nas três" in report, "Total clip count in report drifted")
    return {"static_per_configuration": static_per, "static_total": total_static,
            "clips_per_configuration": clips_per, "clips_total": total_clips}


def check_fixture(schema: dict, fixture: dict) -> dict:
    require(set(schema["required"]) <= set(fixture), "Fixture lacks required top-level fields")
    require(set(fixture) <= set(schema["properties"]), "Unexpected fixture fields")
    require(fixture["fixture"] is True, "Example must be identified as synthetic")
    require(fixture["authoring_mode"] == "synthetic_metadata_fixture", "Misleading example")
    require(not fixture["provenance"]["training_allowed"], "Fixture has no training data")
    require(all(x == "not_reviewed" for x in fixture["review"].values()), "Invented approval")
    frames = fixture["frames"]
    indices = {f["index"] for f in frames}
    require(indices == set(range(len(frames))), "Non-contiguous or duplicate frame indices")
    for frame in frames:
        require(frame["file"] is None and frame["sha256"] is None, "Fixture invents a raster")
        require(frame["duration_ms"] > 0, "Invalid frame duration")
        require(len(frame["pivot"]) == 2 and len(frame["origin"]) == 2, "Invalid point")
    for clip in fixture["clips"]:
        require(set(clip["frame_indices"]) <= indices, "Clip references absent frame")
        for event in clip["events"]:
            require(event["frame_index"] in clip["frame_indices"], "Event outside clip")
            require(event["presentation_only"] is True, "Event must not drive gameplay")
    try:
        from jsonschema import Draft202012Validator
    except ImportError:
        formal = "not_run_jsonschema_unavailable; fixture invariants checked separately"
    else:
        Draft202012Validator.check_schema(schema)
        validator = Draft202012Validator(schema)
        validator.validate(fixture)
        invalid = copy.deepcopy(fixture)
        invalid["frames"][0]["duration_ms"] = 0
        require(not validator.is_valid(invalid), "Schema accepts zero duration")
        invalid = copy.deepcopy(fixture)
        invalid["fixture"] = False
        require(not validator.is_valid(invalid), "Schema accepts synthetic production asset")
        invalid = copy.deepcopy(fixture)
        invalid["frames"][0]["file"] = "../outside.png"
        require(not validator.is_valid(invalid), "Schema accepts parent traversal")
        invalid = copy.deepcopy(fixture)
        invalid["clips"][0]["events"] = [
            {"frame_index": 0, "name": "example", "presentation_only": False}
        ]
        require(not validator.is_valid(invalid), "Schema accepts gameplay event")
        formal = "passed_draft2020_12"
    return {"fixture_invariants": "passed", "formal_json_schema": formal,
            "example_duration_ms": sum(f["duration_ms"] for f in frames)}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write-report", action="store_true")
    args = parser.parse_args()
    documents = {str(p.relative_to(ROOT)): json.loads(p.read_text(encoding="utf-8"))
                 for p in ROOT.rglob("*.json") if p.name != "verificacao.json"}
    for script in ROOT.glob("*.py"):
        source = script.read_text(encoding="utf-8")
        ast.parse(source, filename=str(script))
        require(len(source.splitlines()) <= 250, f"Script exceeds 250 lines: {script}")
    result = {
        "checked_at_utc": datetime.now(timezone.utc).isoformat(),
        "scope": "research_package_integrity_only",
        "command": "python3 docs/art/research/2026-10-23-pixellab/validate_research.py",
        "json_documents_parsed": len(documents),
        "local_links_checked": check_links(),
        "central_references_checked": check_references(documents["proveniencia.json"]),
        "planned_counts": check_plan(documents["benchmark-plan.json"]),
        "contract": check_fixture(documents["asset-contract.schema.json"],
                                  documents["examples/asset-fixture.json"]),
        "python_syntax_and_line_limits": "passed",
        "generation_executed": False,
        "training_executed": False,
        "visual_quality_benchmark_executed": False,
    }
    rendered = json.dumps(result, ensure_ascii=False, indent=2) + "\n"
    if args.write_report:
        (ROOT / "verificacao.json").write_text(rendered, encoding="utf-8")
    print(rendered, end="")


if __name__ == "__main__":
    main()
