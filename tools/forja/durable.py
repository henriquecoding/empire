"""Escrever um registo que sobrevive a uma queda, e ler-mudar-escrever sem dois processos se pisarem (auditoria de 27/10).

O job escreve-se ANTES do POST (jobs.py) para que um pedido pago nunca fique sem rasto. A troca atomica (tmp +
os.replace) garante que nunca fica meio ficheiro; sem `fsync` o conteudo pode ainda estar so na cache do sistema
quando a maquina cai, e o ficheiro trocado volta vazio ou antigo. Aqui: escrever, `fsync` do ficheiro, trocar e
`fsync` da pasta (POSIX), o padrao do atomicwrites. No Windows a pasta nao se sincroniza assim; o `os.replace` e
atomico na mesma.

O teto de gasto (`budget.json`) era lido uma vez ao abrir e escrito da memoria: dois `forja generate` na mesma pasta
liam ambos "0 chamadas" e faziam dois POSTs com um teto de um. `locked` da um lock exclusivo num ficheiro ao lado
(`fcntl.flock` em POSIX, `msvcrt.locking` no Windows), e quem conta relê o ficheiro dentro dele.
"""
from __future__ import annotations

import contextlib
import os
import time
from pathlib import Path


def write_text(path: str | Path, text: str) -> Path:
    """Troca atomica e duravel: o ficheiro fica o antigo inteiro ou o novo inteiro, ja no disco."""
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(f".{path.name}.{os.getpid()}.tmp")
    with open(tmp, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(text)
        fh.flush()
        os.fsync(fh.fileno())
    os.replace(tmp, path)
    _sync_dir(path.parent)
    return path


def _sync_dir(folder: Path) -> None:
    if os.name != "posix":
        return
    fd = os.open(folder, os.O_RDONLY)
    try:
        os.fsync(fd)
    except OSError:  # alguns sistemas de ficheiros nao sincronizam pastas; o replace ja foi feito
        pass
    finally:
        os.close(fd)


@contextlib.contextmanager
def locked(path: str | Path, timeout: float = 30.0):
    """Lock exclusivo em `<path>.lock`, entre processos. Espera ate `timeout` e depois falha com TimeoutError."""
    lock = Path(f"{path}.lock")
    lock.parent.mkdir(parents=True, exist_ok=True)
    with open(lock, "a+b") as fh:
        _acquire(fh, time.monotonic() + timeout)
        try:
            yield
        finally:
            _release(fh)


def _acquire(fh, deadline: float) -> None:
    delay = 0.01
    while True:
        try:
            if os.name == "nt":
                import msvcrt
                fh.seek(0)
                msvcrt.locking(fh.fileno(), msvcrt.LK_NBLCK, 1)
            else:
                import fcntl
                fcntl.flock(fh.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
            return
        except OSError:
            if time.monotonic() >= deadline:
                raise TimeoutError(f"outro processo prende {fh.name}; tente de novo quando ele acabar") from None
            time.sleep(delay)
            delay = min(0.2, delay * 2)


def _release(fh) -> None:
    if os.name == "nt":
        import msvcrt
        fh.seek(0)
        msvcrt.locking(fh.fileno(), msvcrt.LK_UNLCK, 1)
    else:
        import fcntl
        fcntl.flock(fh.fileno(), fcntl.LOCK_UN)
