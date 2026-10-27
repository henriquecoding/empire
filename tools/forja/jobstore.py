"""O registo duravel dos jobs e o teto de gasto (a parte sem rede de `jobs.py`).

Um job e um ficheiro JSON escrito com troca atomica e `fsync` (durable.py): se o processo
ou a maquina morrem a meio, fica o estado anterior inteiro, nunca meio ficheiro nem um
vazio. O orcamento fica em `<pasta>/budget.json` e soma entre corridas, para uma retomada
nao o esquecer; cada conta relê-o com um lock, para dois processos na mesma pasta nao
passarem o teto (auditoria de 27/10, B03).
"""
from __future__ import annotations

import contextlib
import datetime
import json
import uuid
from dataclasses import dataclass
from pathlib import Path

from . import durable
from .backends import Call, digest, sha

FINAL = ("completed", "failed", "cancelled")


class JobError(RuntimeError):
    def __init__(self, job: "Job", message: str):
        super().__init__(f"job {job.id} ({job.state}): {message}")
        self.job = job


class Ambiguous(JobError):
    """O POST pode ter sido aceite: nao se reenvia sem decisao explicita."""


class Timeout(JobError):
    """O prazo acabou com o job remoto vivo: retomar consulta, nao volta a pedir."""


class BudgetExceeded(RuntimeError):
    pass


def now() -> str:
    return datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%fZ")


@dataclass
class Job:
    data: dict
    path: Path | None = None

    @property
    def id(self) -> str:
        return self.data["id"]

    @property
    def state(self) -> str:
        return self.data["state"]

    def save(self) -> None:
        self.data["updated_utc"] = now()
        if self.path is None:
            return
        durable.write_text(self.path, json.dumps(self.data, indent=1, ensure_ascii=False) + "\n")

    def mark(self, state: str, note: str | None = None, **fields) -> None:
        self.data.update(fields)
        self.data["state"] = state
        self.data["history"].append({"state": state, "at": now(), **({"note": note} if note else {})})
        self.save()


def create(call: Call, folder: str | Path | None = None, extra: dict | None = None) -> Job:
    """O job no disco (estado planned) antes de qualquer rede. Sem pasta, fica so em memoria."""
    job_id = uuid.uuid4().hex[:16]
    data = {"schema": 1, "id": job_id, "service": call.service, "operation": call.operation,
            "descriptor": call.descriptor, "request_sha256": digest(call.descriptor), "state": "planned",
            "remote_id": None, "attempts": [], "polls": 0, "history": [], "progress": None,
            "cost": {"usd": None, "status": "unknown"}, "outputs": [], "error": None,
            "created_utc": now(), **(extra or {})}
    job = Job(data, Path(folder) / "jobs" / f"{job_id}.json" if folder else None)
    job.mark("planned")
    return job


def load(path: str | Path) -> Job:
    p = Path(path)
    return Job(json.loads(p.read_text(encoding="utf-8")), p)


def listing(folder: str | Path) -> list[dict]:
    return [{"file": str(p), "id": d["id"], "state": d["state"], "service": d["service"],
             "operation": d["operation"], "remote_id": d["remote_id"], "attempts": len(d["attempts"]),
             "outputs": len(d["outputs"]), "cost": d["cost"], "created_utc": d["created_utc"]}
            for p in sorted((Path(folder) / "jobs").glob("*.json"))
            for d in [json.loads(p.read_text(encoding="utf-8"))]]


@dataclass
class Budget:
    """Teto de um ensaio: chamadas pagas e dolares ditos pelo fornecedor. Fica em <pasta>/budget.json."""

    max_calls: int
    max_usd: float | None = None
    calls: int = 0
    usd: float = 0.0
    unknown_cost_calls: int = 0
    path: Path | None = None

    @classmethod
    def open(cls, folder: str | Path | None, max_calls: int, max_usd: float | None = None) -> "Budget":
        b = cls(max_calls, max_usd, path=Path(folder) / "budget.json" if folder else None)
        b._reload()
        return b

    @classmethod
    def saved(cls, folder: str | Path) -> "Budget | None":
        """O teto ja gravado na pasta, para uma retomada somar nele o custo que o fornecedor disser (A04)."""
        path = Path(folder) / "budget.json"
        if not path.exists():
            return None
        data = json.loads(path.read_text(encoding="utf-8"))
        return cls.open(folder, data["max_calls"], data.get("max_usd"))

    def _reload(self) -> None:
        if self.path and self.path.exists():
            saved = json.loads(self.path.read_text(encoding="utf-8"))
            self.calls, self.usd, self.unknown_cost_calls = saved["calls"], saved["usd"], saved["unknown_cost_calls"]

    def _guard(self):
        return durable.locked(self.path) if self.path else _nothing()

    def _refuse(self, estimate: float | None) -> None:
        if self.calls >= self.max_calls:
            raise BudgetExceeded(f"teto de {self.max_calls} chamadas pagas atingido ({self.calls} feitas)")
        if self.max_usd is not None and (self.usd >= self.max_usd
                                         or (estimate is not None and self.usd + estimate > self.max_usd)):
            raise BudgetExceeded(f"teto de US${self.max_usd:g} atingido (US${self.usd:g} conhecidos)")

    def check(self, estimate: float | None) -> None:
        """So confere, com o que esta no disco agora; quem vai gastar usa `reserve`."""
        with self._guard():
            self._reload()
            self._refuse(estimate)

    def reserve(self, estimate: float | None = None) -> None:
        """Conferir e contar a chamada num so passo, com o lock: entre os dois nenhum outro processo gasta."""
        with self._guard():
            self._reload()
            self._refuse(estimate)
            self.calls += 1
            self.save()

    def settle(self, usd: float | None) -> None:
        with self._guard():
            self._reload()
            if usd is None:
                self.unknown_cost_calls += 1
            else:
                self.usd += usd
            self.save()

    def as_dict(self) -> dict:
        out = {"max_calls": self.max_calls, "max_usd": self.max_usd, "calls": self.calls, "usd": round(self.usd, 6),
               "unknown_cost_calls": self.unknown_cost_calls}
        if self.unknown_cost_calls:
            out["note"] = (f"{self.unknown_cost_calls} chamada(s) sem custo dito pelo fornecedor: o gasto real "
                           "pode ser maior que `usd`; o teto que vale sempre e `max_calls`")
        return out

    def save(self) -> None:
        if self.path:
            durable.write_text(self.path, json.dumps(self.as_dict(), indent=1) + "\n")


@contextlib.contextmanager
def _nothing():
    yield


def stored(job: Job) -> list[bytes]:
    """As imagens de um job concluido, conferidas pelo hash (sem rede)."""
    images = []
    for o in job.data["outputs"]:
        data = Path(o["file"]).read_bytes() if o.get("file") else b""
        if sha(data) != o["sha256"]:
            raise JobError(job, f"saida {o['index']} em falta ou alterada ({o.get('file')})")
        images.append(data)
    return images
