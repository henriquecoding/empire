"""Estudo, ensaios e pilotos no mesmo registo CLI/MCP."""
from __future__ import annotations

import json
from pathlib import Path

from . import action_export, ase, proof_io, rehearsal, rehearsal_review, study, study_pilots
from .cli import command
from .cmd_ase import outside_art


def _read(path):
    return json.loads(Path(path).read_text(encoding="utf-8")) if path else None


def do_study(args) -> dict:
    return {"ok": True, **study.load(), "context": study.context(), "implementation": "docs/art/PENUSBMIC_WORKFLOW.md"}


def do_rehearsal(args) -> dict:
    return rehearsal.create(args.file, outside_art(args.out), args.kind, args.effect_layer or [], args.trim,
                            args.character, _read(args.recipe), _read(args.face_states))


def do_review(args) -> dict:
    path = Path(args.manifest)
    manifest = _read(path)
    if manifest.get("schema") == study_pilots.SCHEMA:
        return study_pilots.review(path, _read(args.review))
    technical = action_export.verify(path)
    if not technical["ok"]:
        return {**technical, "status": "blocked"}
    if not rehearsal.verify_replay(manifest):
        return {"ok": False, "status": "blocked", "blocking": ["receita ou eventos alterados"], "release_ready": False}
    sprite = ase.read(proof_io.resolve(path.parent, manifest["source"]))
    actor, final, _, _ = action_export.prepare(sprite, manifest["kind"], manifest["effect_layers"])
    return {**rehearsal_review.check(manifest, _read(args.review), actor, final), "export": technical}


def do_compare(args) -> dict:
    return rehearsal.compare(args.before, args.after)


def do_variations(args) -> dict:
    return study_pilots.variations(args.images, args.kind, outside_art(args.out), args.function, args.character, args.refs)


def do_scene(args) -> dict:
    return study_pilots.scene_pilot(args.spec, outside_art(args.out))


def register(sub) -> None:
    command(sub, "estudo", "Estudo Penusbmic: fontes, propostas e implementacao, sem rede", do_study)
    p = command(sub, "ensaio", "Aseprite -> acoes exatas, ator sem VFX, previa e ficha de revisao", do_rehearsal)
    p.add_argument("file")
    p.add_argument("-o", "--out", required=True)
    p.add_argument("--kind", required=True)
    p.add_argument("--character", help="id/alias do elenco: liga a autoridade e as restricoes partilhadas")
    p.add_argument("--effect-layer", action="append", help="camada de VFX a desligar na prova do corpo (repetivel)")
    p.add_argument("--trim", action="store_true", help="recortar armazenamento e provar a reconstrucao do canvas")
    p.add_argument("--recipe", help="forja.replay/1: repetir as mesmas entradas, estados e camara")
    p.add_argument("--face-states", help="estados/orientacoes autorizados, ligados a personagem e autoridade")
    p = command(sub, "ensaio-rever", "Conferir ficheiros e evidencia visual; pendente devolve falha", do_review)
    p.add_argument("manifest")
    p.add_argument("--review", required=True)
    p = command(sub, "ensaio-comparar", "Antes/depois com a mesma receita e escala", do_compare)
    p.add_argument("before")
    p.add_argument("after")
    p = command(sub, "variantes", "Comparar alternativas nativas de designs em aberto", do_variations)
    p.add_argument("images", nargs="+")
    p.add_argument("--kind", required=True)
    p.add_argument("--function", required=True)
    p.add_argument("--character", help="designs do elenco sao recusados: preservar/reparar")
    p.add_argument("--refs", help="registo das referencias, incluindo rejeicoes")
    p.add_argument("-o", "--out", required=True)
    p = command(sub, "cena-piloto", "Massas, tres planos, ator, acessos e dia/noite antes de expandir", do_scene)
    p.add_argument("spec", help="forja.scene_pilot/1, caminhos relativos ao JSON")
    p.add_argument("-o", "--out", required=True)
