"""Fecho explícito de perdas de cada quadro; a prova vincula-se à sequência e aos pixels atuais."""
from __future__ import annotations

from . import lineage, owner_rules
from .equipment import image_sha

SCHEMA = "forja.animation_loss_resolutions/1"


def check(clip, doc: dict | None = None) -> dict:
    blocked, pending = [], []
    if doc is not None and (not isinstance(doc, dict) or doc.get("schema") != SCHEMA or
                           doc.get("sequence_sha256") != clip.sha):
        return {"blocked": ["resolucoes de outra sequencia ou schema invalido"], "pending": []}
    rows = (doc or {}).get("resolutions", [])
    if not isinstance(rows, list) or any(not isinstance(r, dict) for r in rows):
        return {"blocked": ["resolucoes por quadro invalidas"], "pending": []}
    found = set()

    def visit(node, identity=True):
        for rec in node.get("frames", []):
            i = rec["frame"]
            for index, loss in enumerate(rec.get("losses", [])):
                key = (node.get("output_sha256"), i, index)
                found.add(key)
                matches = [r for r in rows if (r.get("chain_output_sha256"), r.get("frame"), r.get("loss")) == key]
                reason = "resolucao unica com evidencia em falta"
                if len(matches) == 1:
                    r = matches[0]
                    documented = all(isinstance(r.get(k), str) and r[k].strip() for k in ("by", "date", "evidence"))
                    if documented and r.get("status") == "excepted" and \
                            r.get("authorized_by") == owner_rules.load()["owner"]:
                        continue
                    if documented and r.get("status") == "repaired" and identity and 0 <= i < len(clip.frames):
                        try:
                            reason = lineage._proof(r, loss, clip.frames[i], image_sha(clip.frames[i]))
                        except (ValueError, TypeError, IndexError):
                            reason = "prova de pixels invalida"
                        if reason is None:
                            continue
                pending.append(f"cadeia {str(key[0])[:12]}, quadro {i}, perda {index}: {reason}")
        if isinstance(node.get("parent"), dict):
            visit(node["parent"], identity and node.get("origin") == "pixel_patch")

    visit(clip.data["lineage"])
    if any((r.get("chain_output_sha256"), r.get("frame"), r.get("loss")) not in found for r in rows):
        blocked.append("resolucao de perda inexistente nesta cadeia")
    return {"blocked": blocked, "pending": pending}
