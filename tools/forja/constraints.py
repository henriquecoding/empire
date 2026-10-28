"""As restricoes do prompt, cada uma com a sua origem (FORJA-07; auditoria de 27/10, §3.2 e §16.1).

O compilador acrescentava «two tones per material», «a short palette (about 12-24 colors)» e o perfil estrito a todo
o pedido, mesmo quando o contrato nao fixa cores (`royal_80` e `royal_64` tem `max_colors: null`). Num pedido de
adaptacao fiel isso e uma simplificacao imposta antes de se saber o que tem de sobreviver: as mangas, a capa, o
metal e as expressoes do conceito dependem de planos e de diferencas pequenas bem postas.

Por isso cada linha diz de onde vem: `contract:<kind>` (o contrato do Empire), `palette:<nome>` (a paleta pedida),
`explicit_request` (uma decisao dita no pedido: --max-colors, --tones), `fidelity:<personagem>/<pose>` (as
invariantes do contrato de fidelidade), `concept` (o conceito anexado) e `compiler_default` (uma preferencia do
compilador, dos prompts V15). Os modos fieis (`adapt_concept`, `edit_approved_master`) nao recebem nenhuma
`compiler_default` de forma, sombra ou cor; o modo `stylized` (o de antes) continua igual e diz que sao preferencias.
"""
from __future__ import annotations

from . import contracts
from .palette import Palette

MODES = ("stylized", "adapt_concept", "edit_approved_master", "recover_grid")
FAITHFUL = ("adapt_concept", "edit_approved_master")
DEFAULT = "compiler_default"


def _rule(ident: str, text: str, origin: str) -> dict:
    return {"id": ident, "text": text, "origin": origin}


def outline(c: contracts.Contract) -> dict:
    if c.outline_px is None:
        return _rule("outline", "Outline: outline only where it helps readability.", DEFAULT)
    if c.outline_px == 0:
        return _rule("outline", "Outline: NO outline at all; shapes are separated by value only.",
                     f"contract:{c.kind}")
    width = max(1, c.outline_px // c.cluster)  # o contrato diz px de ecra; o pedido fala em pixels logicos (FORJA-09)
    return _rule("outline", f"Outline: a {width}-logical-pixel pure black (#000000) outline around the whole "
                 "silhouette and on key internal details.", f"contract:{c.kind}")


def colors(pal: Palette | None, c: contracts.Contract, listed: int, swatch: int | None, faithful: bool,
           max_colors: int | None = None) -> dict:
    """A cor: o teto vem do contrato ou de um pedido explicito; so o modo estilizado poe o 12-24 por omissao."""
    if max_colors:
        limit, origin = f"at most {max_colors} colors in total", "explicit_request"
    elif c.max_colors:
        limit, origin = f"at most {c.max_colors} colors in total", f"contract:{c.kind}"
    elif faithful:
        limit, origin = ("no numeric color cap (the contract sets none): keep every material of the concept art "
                         "distinct, with the light and shadow planes it needs"), f"contract:{c.kind} (max_colors null)"
    else:
        limit, origin = "a short palette (about 12-24 colors)", DEFAULT
    if pal is None or not len(pal):
        return _rule("colors", f"Colors: flat colors only, {limit}.", origin)
    where = f"palette:{pal.name or 'pedida'}"
    if len(pal) <= listed:
        return _rule("colors", f"Colors: use ONLY these colors: {', '.join(pal.hexes())}; {limit}.",
                     f"{where}; {origin}")
    if swatch:
        return _rule("colors", f"Colors: use ONLY colors from attached image {swatch} (the palette swatch, {len(pal)} "
                     f"colors); {limit}.", f"{where}; {origin}")
    return _rule("colors", f"Colors: flat colors only, {limit}.", origin)


def shading(c: contracts.Contract, faithful: bool, tones: int | None = None) -> dict:
    dither = "" if c.dither else ", no dithering"
    if tones:
        return _rule("shading", f"Shading: {tones} tones per material, big readable flat clusters{dither}.",
                     "explicit_request")
    if faithful:
        return _rule("shading", "Shading: keep the light direction, light planes, folds and material contrasts of the "
                     f"concept art, redrawn as flat clusters on the grid{dither}.", "concept")
    return _rule("shading", "Shading: two tones per material (light and shadow), light from the top-left, big "
                 f"readable flat clusters{dither}.", DEFAULT)


def camera(c: contracts.Contract, facing: str, faithful: bool) -> dict:
    if faithful:
        return _rule("camera", f"Camera: side view facing {facing.upper()}, the same view, pose and gesture as the "
                     "concept art (chest, sleeves and hands organized as it shows them).",
                     f"contract:{c.kind} (side view); concept")
    return _rule("camera", f"Camera: strict side view (profile), facing {facing.upper()}, like a 2D platformer "
                 "sprite.", DEFAULT)


def fidelity(invariants: list[str] | None, where: str | None) -> list[dict]:
    """As linhas que so o modo fiel tem: os sinais pequenos e as invariantes do personagem."""
    out = [_rule("small_features", "Small features: eyes, brows, nose, mouth or teeth and highlights are whole "
                 "logical pixels placed as in the concept art; reserve room for them and do not erase them to "
                 "simplify (one pixel for a pupil does not mean one pixel for the whole eye).",
                 "fidelity: auditoria de 27/10, §8 (etapa C)")]
    if invariants:
        out.append(_rule("invariants", "Must match the concept for this pose (owner's invariants): "
                         + "; ".join(invariants) + ".", f"fidelity:{where}"))
    return out


def rules(c: contracts.Contract, pal: Palette | None, facing: str, mode: str, listed: int, swatch: int | None,
          invariants: list[str] | None = None, where: str | None = None, max_colors: int | None = None,
          tones: int | None = None) -> list[dict]:
    if mode not in MODES:
        raise ValueError(f"modo desconhecido: {mode} (use {', '.join(MODES)})")
    faithful = mode in FAITHFUL
    out = [camera(c, facing, faithful), outline(c), shading(c, faithful, tones),
           colors(pal, c, listed, swatch, faithful, max_colors)]
    return out + (fidelity(invariants, where) if faithful else [])


def implicit(found: list[dict]) -> list[str]:
    """As restricoes que so o compilador quis (o modo fiel nao as tem)."""
    return [r["id"] for r in found if r["origin"] == DEFAULT]
