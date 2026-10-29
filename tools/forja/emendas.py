"""As emendas e os estados de uma cena forjada (FORJA-11, FORJA-12).

Uma emenda tem criterios que nao se somam (auditoria de 28/10, A3): o perfil do alfa (o degrau da silhueta) e a cor
(a diferenca OKLab entre as colunas que se tocam). Cada um compara-se com o interior das proprias pecas — o percentil
90 dos saltos entre colunas vizinhas, para uma descontinuidade forte la dentro nao esconder a emenda, mais uma folga:
uma celula no alfa, 0,02 OKLab na cor (`color.delta`: «0.02 mal se ve»). Uma peca que repete consigo tem de emendar
sem costura; entre vizinhos diferentes a cor pode mudar de proposito (outro material) e fica para rever.

Um estado prova duas coisas (A4): nada mudou fora das zonas que o contrato declara, e alguma coisa mudou dentro delas.
Mudar nao prova o significado — ruido tambem muda pixels —, por isso a mudanca fica `inconclusive` ate se ver.
"""
from __future__ import annotations

from PIL import Image

from . import color, masks
from .vaos import check, place, shift

COLOUR_TOLERANCE = 0.02


def _profile(img: Image.Image, x: int) -> list[bool]:
    a = img.getchannel("A").load()
    return [a[x, y] >= 128 for y in range(img.height)]


def _colour(a: Image.Image, xa: int, b: Image.Image, xb: int, lab: dict) -> float | None:
    """A diferenca media de cor entre duas colunas, nas filas em que as duas sao opacas."""
    pa, pb = a.load(), b.load()
    for p in {pa[xa, y][:3] for y in range(a.height)} | {pb[xb, y][:3] for y in range(b.height)}:
        if p not in lab:
            lab[p] = color.oklab(p)
    ds = [color.dist2(lab[pa[xa, y][:3]], lab[pb[xb, y][:3]]) ** 0.5 for y in range(min(a.height, b.height))
          if pa[xa, y][3] >= 128 and pb[xb, y][3] >= 128]
    return sum(ds) / len(ds) if ds else None


def _p90(values: list[float]) -> float:
    values = sorted(values)
    return values[int(len(values) * 0.9)] if values else 0.0


def joint(left: Image.Image, right: Image.Image, cell: int = 2) -> dict:
    """A juncao de dois modulos lado a lado: o alfa e a cor da emenda contra o interior das pecas."""
    if left.height != right.height:  # os mesmos campos de sempre: quem le o resultado nao tem de saber o caso
        return {"ok": False, "jump": None, "interior": None, "colour_seam": None, "colour_limit": None,
                "criteria": {"alpha": False, "colour": None}, "detail": f"alturas {left.height} e {right.height}"}
    jump = sum(a != b for a, b in zip(_profile(left, left.width - 1), _profile(right, 0)))
    steps = [sum(a != b for a, b in zip(_profile(im, x), _profile(im, x + 1)))
             for im in (left, right) for x in range(im.width - 1)]
    inner = max(_p90(steps), cell)
    lab: dict = {}
    seam = _colour(left, left.width - 1, right, 0, lab)
    shades = [d for im in (left, right) for x in range(im.width - 1)
              if (d := _colour(im, x, im, x + 1, lab)) is not None]
    limit = _p90(shades) + COLOUR_TOLERANCE
    criteria = {"alpha": jump <= inner, "colour": seam is None or seam <= limit}
    seam_text = "sem filas opacas dos dois lados" if seam is None else f"cor {seam:.3f} OKLab (limite {limit:.3f})"
    return {"ok": all(criteria.values()), "jump": jump, "interior": inner, "colour_seam": seam and round(seam, 4),
            "colour_limit": round(limit, 4), "criteria": criteria,
            "detail": f"degrau de {jump} px na emenda (limite {inner}); {seam_text}"}


def continuity(img: Image.Image, res: dict, neighbors: dict) -> list[dict]:
    out, cell = [], res["step"]
    if "x" in res["repeat"]:
        j = joint(img, img, cell)
        out.append(check("continuity", "repeat_x", "pass" if j["ok"] else "fail", "repete em x: " + j["detail"],
                         **{k: j[k] for k in ("jump", "interior", "colour_seam", "colour_limit", "criteria")}))
    for side, other in neighbors.items():
        j = joint(img, other, cell) if side == "right" else joint(other, img, cell)
        status = "pass" if j["ok"] else "fail" if not j["criteria"]["alpha"] else "inconclusive"
        extra = "" if status != "inconclusive" else "; a cor muda na emenda: material intencional? rever"
        out.append(check("continuity", f"connector_{side}", status, f"com o vizinho da "
                         f"{'direita' if side == 'right' else 'esquerda'}: " + j["detail"] + extra,
                         **{k: j[k] for k in ("jump", "interior", "colour_seam", "colour_limit", "criteria")}))
    if not out and res["connectors"]:
        out.append(check("continuity", "connectors", "not_evaluated", "modulo com conectores: de os vizinhos"))
    return out


def states(base: Image.Image, res: dict, given: dict) -> list[dict]:
    """Cada estado ou condicao declarada contra a base (`done`, ou o primeiro estado): a que nao veio fica por avaliar,
    para o eixo nao passar com metade das variantes; a que veio igual a base chumba."""
    first = "done" if "done" in res["states"] else res["states"][0]
    out = [check("states", n, "not_evaluated", f"{n}: declarado no contrato, sem imagem para conferir")
           for n in res["states"] + res["conditions"] if n != first and n not in given]
    for name, img in given.items():
        if img.size != base.size:
            out.append(check("states", name, "fail", f"{name}: {img.size}, a base e {base.size} (a origem muda)"))
            continue
        zones = res["state_changes"].get(name, [])
        allowed = frozenset().union(*[masks.box(tuple(place(b, shift(img, res))), img.size) for b in zones])
        a, b = base.load(), img.load()
        moved = [(x, y) for y in range(img.height) for x in range(img.width) if a[x, y] != b[x, y]]
        outside = [p for p in moved if p not in allowed]
        inside = len(moved) - len(outside)
        out.append(check("states", name, "fail" if outside else "pass",
                         f"{name}: {len(outside)} px mudados fora das zonas declaradas" if outside else
                         f"{name}: nada mudou fora das zonas declaradas", outside=len(outside),
                         where=[list(p) for p in outside[:8]]))
        why = (f"{name}: mudou {inside} px nas zonas; o que o estado comunica reve-se a olho" if inside else
               f"{name}: nada mudou nas zonas declaradas — o estado nao se distingue da base" if zones else
               f"{name}: o contrato nao diz onde o estado muda (state_changes)")
        out.append(check("states", f"{name}:change", "inconclusive" if inside else "fail", why, changed=inside,
                         zones=len(zones)))
    return out
