"""`forja jobs`: ver, retomar (so consulta, nunca outro POST) e cancelar os pedidos de uma pasta."""
from __future__ import annotations

from pathlib import Path

from . import backends, jobs
from .cli import command


def do_jobs(args) -> dict:
    wanted = args.show or args.resume or args.cancel
    if not wanted:
        return {"ok": True, "jobs": jobs.listing(args.folder)}
    job = jobs.load(Path(args.folder) / "jobs" / f"{wanted}.json")
    if args.cancel:
        return {"ok": True, **jobs.cancel(job, backends.canceller(job.data["service"]))}
    if args.resume:
        try:
            jobs.execute(job, None, poll=backends.poller(job.data["service"]), deadline=args.deadline)
        except jobs.JobError as err:
            return {"ok": False, "state": job.state, "error": str(err), "job": str(job.path)}
    return {"ok": job.state == "completed", "job": job.data}


def register(sub) -> None:
    p = command(sub, "jobs", "Pedidos pagos de uma pasta: listar, ver, retomar (so consulta) ou cancelar", do_jobs)
    p.add_argument("folder", help="a pasta -o de generate/auto")
    p.add_argument("--show", metavar="ID")
    p.add_argument("--resume", metavar="ID", help="consultar o job remoto ou devolver o resultado guardado")
    p.add_argument("--cancel", metavar="ID", help="pedir ao fornecedor para parar (se ele o permite)")
    p.add_argument("--deadline", type=float, default=900.0, help="prazo da retomada, em segundos")
