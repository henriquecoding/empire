"""Prova para observar, nunca uma declaração automática de fidelidade ou aprovação."""
from __future__ import annotations

import html
from pathlib import Path

from . import anim, animation_files, fidelity, report


def write(clip, contract: dict, ch: dict, destination: str | Path) -> Path:
    path = animation_files.destination(destination)
    path.parent.mkdir(parents=True, exist_ok=True)
    source = fidelity.authority_crop(contract, ch)
    data = {**clip.data, "metrics": clip.data.get("metrics") or anim.metrics(clip.frames)}
    report.animation(path, clip.frames, clip.data["durations"], data)
    authority = ("<h2>Conceito de autoridade</h2><p>Conceito escolhido, fora da grade; comparar identidade, "
                 "roupa, expressao, maos e equipamento em cada pose.</p>" +
                 f'<img alt="conceito" style="max-width:400px;max-height:400px" src="{report.data_uri(source)}">')
    views = "<h2>Quadros nativos em fundos claro/escuro</h2><div style=\"display:flex;gap:24px;align-items:start\"><div>" + "".join(
        f"<h3>{html.escape(ch['id'])} · quadro {i}</h3>" + report._views(frame, 4)
        for i, frame in enumerate(clip.frames))
    views += '</div><aside style="position:sticky;top:8px;max-width:400px">' + authority + "</aside></div>"
    text = path.read_text(encoding="utf-8").replace("<h2>Animacao</h2>", authority + "<h2>Animacao</h2>")
    path.write_text(text.replace("<h2>Tira</h2>", views + "<h2>Tira</h2>"), encoding="utf-8")
    return path
