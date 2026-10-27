"""O contrato de equipamento em tres registos: intencao, observacao e veredito (FORJA-03).

- Intencao (o manifesto): cada objeto com identificador, familia, slot, estado de uso, partes e
  quantidades, contactos com o corpo, oclusao e material. Descreve apresentacao: nao cria mecanicas,
  capacidades de inventario nem eventos (esses vivem em data/source e na Animation Bible).
- Observacao: regioes e ancoras localizadas NUMA imagem (o hash dela), com autor, metodo, data e
  incerteza. Um JSON a dizer que ha uma lamina nao prova que a imagem tem uma; uma regiao marcada
  tambem pode estar errada, e por isso a observacao diz quem a fez e como.
- Veredito: a geometria (geometry.py) compara as duas. Sem observacao nao ha veredito, ha `not_evaluated`.

As familias dizem que regras valem para cada objeto: a lamina reta nao se aplica a um sabre, a curva da
madeira do arco e intencional, e a corda so e reta nos estados em que nao esta puxada. `joins` diz por
onde uma parte continua (os dois bracos do arco encontram-se na empunhadura); `occluders`, no manifesto,
diz que regioes tapam ou cruzam a parte nesta pose.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path

from PIL import Image

from . import masks

STRAIGHT = ("stowed", "carried", "rest", "nock")
FAMILIES = {
    "sword_straight": {"parts": {"blade": 1, "guard": 1, "grip": 1, "pommel": 1}, "behavior": "rigid",
                       "axis": "blade", "anchors": ("base", "tip"),
                       "states": ("stowed", "carried", "held", "ready", "strike", "recovery")},
    "bow_simple": {"parts": {"limb": 1, "string": 1, "grip": 1}, "behavior": "flexible",
                   "line": "string", "anchors": ("nock_top", "nock_bottom"), "joins": {"limb": ("grip",)},
                   "states": ("stowed", "carried", "rest", "nock", "draw", "release", "recovery")},
    "shield": {"parts": {"face": 1, "rim": 1, "grip": 1}, "behavior": "rigid",
               "states": ("carried", "held", "block")},
    "storage": {"parts": {"container": 1, "strap": 1}, "behavior": "cloth", "states": ("worn", "carried")},
}
SLOTS = ("weapon", "shield", "storage", "head", "face")
REFERENCE_STATUS = ("aprovada", "estudo", "rejeitada")
UNCERTAINTY = ("baixa", "media", "alta")
GAMEPLAY = ("capacity", "holds", "damage", "ammo", "arrows", "torches", "price", "range", "cooldown")
SCHEMA, OBS_SCHEMA = "forja.equipment/1", "forja.observation/1"


def load(path: str | Path) -> dict:
    return json.loads(Path(path).read_text(encoding="utf-8"))


def _gameplay(obj, where: str) -> list[str]:
    out = []
    if isinstance(obj, dict):
        for key, value in obj.items():
            if key in GAMEPLAY:
                out.append(f"{where}.{key}: dado de jogo (vive em data/source), nao de apresentacao")
            out += _gameplay(value, f"{where}.{key}")
    elif isinstance(obj, list):
        for i, value in enumerate(obj):
            out += _gameplay(value, f"{where}[{i}]")
    return out


def validate(manifest: dict) -> list[str]:
    """Os erros do manifesto (lista vazia: valido). Nada aqui olha para a imagem."""
    errors = [] if manifest.get("schema") == SCHEMA else [f"schema: esperado {SCHEMA}"]
    errors += _gameplay(manifest, "manifesto")
    ids = [i.get("id") for i in manifest.get("items", [])]
    if not ids:
        errors.append("manifesto sem items")
    for dup in sorted({i for i in ids if ids.count(i) > 1}):
        errors.append(f"id repetido: {dup} (cada objeto tem um identificador proprio)")
    for item in manifest.get("items", []):
        name, fam = item.get("id"), FAMILIES.get(item.get("family"))
        if not name:
            errors.append("item sem id")
            continue
        if fam is None:
            errors.append(f"{name}: familia desconhecida {item.get('family')!r} (ha {', '.join(FAMILIES)})")
            continue
        if item.get("slot") not in SLOTS:
            errors.append(f"{name}: slot {item.get('slot')!r} fora da ASSET_BIBLE §2 ({', '.join(SLOTS)})")
        if item.get("state") not in fam["states"]:
            errors.append(f"{name}: estado {item.get('state')!r} nao e de {item['family']} ({', '.join(fam['states'])})")
        for part in item.get("parts", {}):
            if part not in fam["parts"]:
                errors.append(f"{name}: parte {part!r} nao existe em {item['family']}")
        for c in item.get("contacts", []):
            if c.get("part") not in fam["parts"] or not c.get("body"):
                errors.append(f"{name}: contacto {c} precisa de uma parte da familia e de uma regiao do corpo")
        ref = item.get("reference")
        if ref and ref.get("status") not in REFERENCE_STATUS:
            errors.append(f"{name}: referencia com estado {ref.get('status')!r} (use {', '.join(REFERENCE_STATUS)})")
    return errors


def items(manifest: dict) -> list[dict]:
    """Os objetos com as partes da familia completas: contagem, opcional, oculta, oclusores, largura."""
    out = []
    for item in manifest["items"]:
        fam = FAMILIES[item["family"]]
        parts = {}
        for part, count in fam["parts"].items():
            given = item.get("parts", {}).get(part, {})
            joins = [f"{item['id']}.{p}" for p in fam.get("joins", {}).get(part, ())]
            parts[part] = {"count": given.get("count", count), "optional": bool(given.get("optional")),
                           "hidden": bool(given.get("hidden")), "occluders": list(given.get("occluders", [])),
                           "joins": joins,
                           "max_width": given.get("max_width", 1 if part == fam.get("line") else None)}
        out.append({**item, "required": item.get("required", True), "parts": parts, "behavior": fam["behavior"],
                    "anchors": fam.get("anchors", ()), "axis": fam.get("axis"), "line": fam.get("line"),
                    "tolerance": item.get("tolerance", 1.0), "contacts": item.get("contacts", [])})
    return out


def image_sha(image: Image.Image) -> str:
    """O hash dos pixels (RGBA, tamanho incluido): a observacao vale para esta imagem e nao para outra.

    Um pixel de alfa 0 conta como (0, 0, 0, 0): a cor escondida no transparente nao se ve, e um editor que re-grava o
    PNG zera-a ou guarda-a a vontade dele. Antes, o mestre aprovado re-gravado sem mudar um pixel visivel deixava de
    estar no registo (auditoria de 27/10, B08). Uma imagem sem cor escondida tem o mesmo hash que tinha."""
    rgba = image.convert("RGBA")
    alpha = rgba.getchannel("A")
    if alpha.getextrema()[0] == 0:
        clean = Image.new("RGBA", rgba.size, (0, 0, 0, 0))
        clean.paste(rgba, (0, 0), alpha.point(lambda a: 255 if a else 0))
        rgba = clean
    return hashlib.sha256(f"{rgba.width}x{rgba.height}:".encode() + rgba.tobytes()).hexdigest()


def observe(image: Image.Image, obs: dict, base: Path | None = None) -> dict:
    """As regioes e ancoras de uma observacao, resolvidas sobre a imagem que ela diz ter visto."""
    if obs.get("schema") != OBS_SCHEMA:
        raise ValueError(f"observacao: schema esperado {OBS_SCHEMA}")
    who = obs.get("observer") or {}
    missing = [k for k in ("author", "method", "date") if not who.get(k)]
    if missing:
        raise ValueError(f"observacao sem {', '.join(missing)}: quem viu, como e quando")
    sha = image_sha(image)
    if obs.get("image_sha256") != sha:
        raise ValueError(f"a observacao e de outra imagem (hash {str(obs.get('image_sha256'))[:12]}..., esta "
                         f"{sha[:12]}...): observe de novo depois de cada mudanca")
    regions, uncertain = {}, set()
    for name, spec in obs.get("regions", {}).items():
        if spec.get("uncertainty", "baixa") not in UNCERTAINTY:
            raise ValueError(f"{name}: incerteza {spec.get('uncertainty')!r} (use {', '.join(UNCERTAINTY)})")
        regions[name] = masks.select(image, spec, base)
        if spec.get("uncertainty") == "alta":
            uncertain.add(name)
    anchors = {}
    for name, point in obs.get("anchors", {}).items():
        x, y = (int(v) for v in point)
        if not (0 <= x < image.width and 0 <= y < image.height):
            raise ValueError(f"ancora {name} {point} fora da imagem {image.size}")
        anchors[name] = (x, y)
    return {"regions": regions, "uncertain": uncertain, "anchors": anchors, "observer": who, "image_sha256": sha}


def observation(image: Image.Image, regions: dict, anchors: dict, author: str, method: str, date: str,
                **extra) -> dict:
    """Uma observacao nova para esta imagem (o hash entra sozinho)."""
    return {"schema": OBS_SCHEMA, "image_sha256": image_sha(image),
            "observer": {"author": author, "method": method, "date": date, **extra},
            "regions": regions, "anchors": {k: list(v) for k, v in anchors.items()}}
