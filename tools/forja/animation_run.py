"""Executar ou retomar um plano nativo. A pasta liga-se a um único job antes do POST pago."""
from __future__ import annotations

import json
from pathlib import Path

from . import animation_files, animation_pack, animation_plan, backends, durable, jobs
from .backends import digest, sha
from .backends import pixellab_animation


def run(plan_file: str | Path, folder: str | Path, *, max_calls: int = 1, max_usd: float | None = None,
        resume: str | None = None, transport=None, **kw) -> dict:
    path, out = Path(plan_file), animation_files.destination(folder)
    plan = animation_plan.load(path)
    call = plan.call()
    plan_sha = sha(path.read_bytes())
    with durable.locked(out / "animation.lock"):
        index_file = out / "native-animation.json"
        index = json.loads(index_file.read_text()) if index_file.exists() else None
        if index is None and not resume and out.exists() and any(
                p.name != "animation.lock.lock" for p in out.iterdir()):
            raise ValueError("pasta sem indice do job original: conservar os ficheiros e escolher uma pasta nova")
        if index and index.get("plan_sha256") != plan_sha:
            raise ValueError("esta pasta pertence a outro plano; conservar a origem e escolher uma pasta nova")
        if resume and (len(resume) != 16 or any(c not in "0123456789abcdef" for c in resume)):
            raise ValueError("id de job invalido")
        if index and resume and index["job_id"] != resume:
            raise ValueError("retomada de outro job: a pasta ja esta ligada ao pedido original")
        budget = jobs.Budget.open(out, max_calls, max_usd)
        if index or resume:
            job = jobs.load(out / "jobs" / f"{resume or index['job_id']}.json")
            if job.data.get("request_sha256") != digest(call.descriptor) or job.data.get("plan_sha256") != plan_sha:
                raise ValueError("o job nao pertence a este plano e referencia")
        else:
            budget.check(call.estimate_usd)
            job = jobs.create(call, out, extra={"plan_sha256": plan_sha, "owner_rules": plan.data["owner_rules"]})
        durable.write_text(index_file, json.dumps({"plan_sha256": plan_sha, "job_id": job.id}) + "\n")
        try:
            images = jobs.execute(job, call, transport, poll=pixellab_animation.poll_call, budget=budget, **kw)
        except (jobs.JobError, jobs.BudgetExceeded, backends.http.MissingKey) as err:
            return {"ok": False, "job": str(job.path), "state": job.state, "error": str(err),
                    "budget": budget.as_dict(), "ready_for_review": False, "release_ready": False}
        result = animation_pack.package(plan, job, images, out)
        result.update(state=job.state, budget=budget.as_dict())
        durable.write_text(out / "result.json", json.dumps(result, ensure_ascii=False, indent=1) + "\n")
        return result
