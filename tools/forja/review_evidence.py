"""Evidencia declarada por observador: falha bloqueia, desconhecido fica pendente."""
from __future__ import annotations


def text(value) -> bool:
    return isinstance(value, str) and bool(value.strip())


def box(value, size) -> bool:
    return isinstance(value, list) and len(value) == 4 and all(type(v) is int for v in value) and (
        0 <= value[0] < value[2] <= size[0] and 0 <= value[1] < value[3] <= size[1])


def pending() -> dict:
    return {"status": "pending", "evidence": ""}


class Review:
    def __init__(self):
        self.blocking, self.pending = [], []

    def require(self, condition, label: str, blocking: bool = False) -> None:
        if not condition:
            (self.blocking if blocking else self.pending).append(label)

    def evidence(self, item, label: str) -> bool:
        if not isinstance(item, dict):
            self.pending.append(label + ": falta evidencia")
            return False
        status = item.get("status")
        if status == "fail":
            self.blocking.append(label + ": defeito observado")
            return False
        if status not in ("pass", "pending", "inconclusive"):
            self.blocking.append(label + ": estado invalido")
            return False
        if status != "pass" or not text(item.get("evidence")):
            self.pending.append(label + ": falta revisao")
            return False
        return True

    def observer(self, doc: dict) -> None:
        observer = doc.get("observer") or {}
        self.require(isinstance(observer, dict) and all(text(observer.get(k)) for k in ("author", "method", "date")),
                     "observador, metodo e data obrigatorios")

    def result(self) -> dict:
        return {"ok": not self.blocking and not self.pending,
                "status": "blocked" if self.blocking else "pending" if self.pending else "pass",
                "blocking": self.blocking, "pending": self.pending, "release_ready": False,
                "owner_approval": "not_granted", "runtime_integration": "not_evaluated",
                "scope": "declared_visual_evidence_only"}
