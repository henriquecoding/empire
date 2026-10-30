"""Plano de poses anterior ao pedido. Marca apenas chaves ja fixadas nas bibles, nunca inventa eventos."""
from __future__ import annotations

from . import contracts, timeline

SOURCE = "docs/art/ANIMATION_BIBLE.md §2; docs/art/CHARACTER_ANIMATION_WORKFLOW.md"
KEYS = {"walk": {"contact": [0, 4]}, "carry": {"contact": [0, 4]},
        "run": {"contact": [0, 3]}, "attack": {"anticipation": [0, 1], "action": [2], "recovery": [3, 4]},
        "shoot": {"release": [2]}, "die": {"fall": [2], "body_on_ground": [6]},
        "hit": {"reaction": [0], "recover": [1]}, "work": {"action": [2]}, "build": {"action": [2]},
        "smith": {"action": [2]}, "cast": {"action": [3]}, "interact": {"action": [2]},
        "harvest": {"action": [3]}, "cook": {"action": [3]}, "dig": {"action": [2, 5]}}


def plan(tags, canvas, pivot):
    timeline.declarations(tags)
    out, start = [], 0
    for name, count in tags or []:
        spec = contracts.tag(name) or {}
        canonical = count == spec.get("frames")
        out.append({"name": name, "from": start, "to": start + count - 1,
                    "fps": spec.get("fps", 10), "loop": spec.get("loop", True),
                    "canonical_count": canonical, "keyframes": {
                        k: [start + i for i in indices] for k, indices in KEYS.get(name, {}).items()
                    } if canonical else {}, "source": SOURCE})
        start += count
    return {"schema": "forja.animation_plan/1", "canvas": list(canvas),
            "pivot": list(pivot) if pivot else None, "frame_indices": "zero_based",
            "tags": out, "approval": "pending", "source": SOURCE}


def instructions(plan):
    if not plan["tags"]:
        return []
    lines = ["Before detailing, block out the key poses below on the final native grid. Draw articulated "
             "inbetweens: shoulder, elbow, wrist and hand stay connected; hips, knees and feet transfer weight. "
             "Do not manufacture action by rotating or translating one rigid cutout.",
             "Keep the concept's head volume, facial acting, hands, weapon and prop shape in every pose. "
             "Plan occlusion and grip together: a hand that passes in front of the body must still connect to "
             "its arm, and equipment must not duplicate, bend, switch hands or disappear.",
             "Review each action and its entry/exit transition separately. Keep the canvas origin and ground "
             "line fixed; do not recenter crouches or airborne poses. An intentional hold is timing, not a new pose."]
    for tag in plan["tags"]:
        if tag["keyframes"]:
            keys = "; ".join(k + " in cells " + ",".join(str(i + 1) for i in indices)
                             for k, indices in tag["keyframes"].items())
            lines.append(f"Pose plan '{tag['name']}': {keys}. Draw the passage between those keys, not copies.")
        if not tag["canonical_count"]:
            lines.append(f"'{tag['name']}' uses an explicit study count; it does not redefine the runtime contract.")
    return lines
