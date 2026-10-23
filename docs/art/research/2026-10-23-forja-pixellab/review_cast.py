#!/usr/bin/env python3
"""Read the existing V15 sources and record motion diagnostics without editing art."""
from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT))
from tools import aseprite_source
from tools.forja import quality

CAST = ("escudeiro", "nia", "rei", "arqueiro", "sombra", "bardo", "intendente", "dancarina")


def run() -> dict:
    results = []
    for name in CAST:
        path = ROOT / "art/source/royals_v15" / f"{name}.aseprite"
        before = hashlib.sha256(path.read_bytes()).hexdigest()
        src = aseprite_source.read(path)
        frames = [aseprite_source.composite(src, i, range(len(src["layers"]))) for i in range(len(src["frames"]))]
        directions = ("forward", "reverse", "pingpong", "pingpong_reverse")
        tags = [(name, t["from_frame"], t["to_frame"], directions[t["direction"]]) for name, t in src["tags"].items()]
        review = quality.review(frames, tags)
        after = hashlib.sha256(path.read_bytes()).hexdigest()
        if before != after:
            raise RuntimeError("source changed during read-only review")
        results.append({"asset": name, "source": str(path.relative_to(ROOT)), "sha256": before,
                        "canvas": src["size"], "frame_count": len(frames), "source_unchanged": True,
                        "review": review})
    return {"scope": "existing_V15_motion_diagnostics_only", "generation_executed": False,
            "artistic_approval": False, "assets": results}


if __name__ == "__main__":
    print(json.dumps(run(), ensure_ascii=False, indent=1))
