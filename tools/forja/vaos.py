"""Os vaos de uma cena forjada contra a regua (FORJA-11, FORJA-12): o que o ator usa tem de ficar aberto.

Um vao mede-se na parte livre ligada a soleira (a porta) ou na maior parte livre (a janela): livre e mais escuro do
que a parede a volta (`interior`), mais claro (`lit`) ou vazado (`transparent`). A altura conta filas (a caixa de
`masks.bbox` tem o maximo exclusivo). A largura e a da metade de baixo do vao, onde passa o corpo: um arco pode
estreitar no topo sem fechar a passagem, uma fenda de 2 px nao a abre (auditoria de 28/10, A1 e A7).

A luminosidade e um indicio, nao a funcao: uma regiao escura pode ser uma porta, uma viga ou uma fenda. Por isso o
vao so se mede na caixa que o contrato declara. A largura de passagem exige-se a porta, ao portao e ao arco; a baia
de trabalho (o interior mobilado a vista) chega a soleira mas nao e passagem: a largura reporta-se (Q-301). As
medidas sao a proposta da regua (Q-295): cada verificacao diz `rule_status`, e quem as aprova e o dono.
"""
from __future__ import annotations

from PIL import Image

from . import color, masks, regua

DOORS = ("door", "gate", "arch", "bay")  # chegam a soleira e tem a altura de uma porta
PASSAGES = ("door", "gate", "arch")  # e passa-se por elas: a largura exige-se; a baia de trabalho so a reporta


def check(axis: str, name: str, status: str, detail: str, **evidence) -> dict:
    return {"axis": axis, "check": name, "status": status, "detail": detail, "evidence": evidence}


def shift(img: Image.Image, res: dict) -> tuple[int, int]:
    """Do referencial da extensao para o da imagem, pela ancora."""
    w, h = res["extent_px"]
    dx = img.width // 2 - w // 2 if res["anchor"]["mode"] == "base_center" else 0
    return dx, 0 if res["anchor"]["mode"] == "top_left" else img.height - h


def place(box: list[int], offset: tuple[int, int]) -> list[int]:
    return [box[0] + offset[0], box[1] + offset[1], box[2] + offset[0], box[3] + offset[1]]


def _ring_light(img: Image.Image, box: list[int]) -> float | None:
    x0, y0, x1, y1 = box
    px = img.load()
    ring = [px[x, y] for x in range(max(0, x0 - 2), min(img.width, x1 + 2))
            for y in range(max(0, y0 - 2), min(img.height, y1))
            if not (x0 <= x < x1 and y0 <= y < y1) and px[x, y][3] >= 128]
    lights = sorted(color.oklab(p[:3])[0] for p in ring)
    return lights[len(lights) // 2] if lights else None


def _clear(img: Image.Image, o: dict, box: list[int]) -> frozenset | None:
    """Os pixels livres da caixa, ou None se nao ha parede a volta para comparar."""
    x0, y0, x1, y1 = box
    px = img.load()
    if o.get("treatment", "interior") == "transparent":
        return frozenset((x, y) for x in range(x0, x1) for y in range(y0, y1) if px[x, y][3] < 128)
    wall = _ring_light(img, box)
    if wall is None:
        return None
    sign = -1 if o.get("treatment", "interior") == "lit" else 1  # aceso: mais claro do que a parede
    return frozenset((x, y) for x in range(x0, x1) for y in range(y0, y1)  # o vazio fora do edificio nao e vao
                     if px[x, y][3] >= 128 and sign * (color.oklab(px[x, y][:3])[0] - wall) <= -0.12)


def width(part: frozenset) -> int:
    """A largura util: as filas da metade de baixo do vao (onde passa o corpo), no percentil 10 — uma fila de um
    puxador ou de um degrau nao decide a porta inteira; uma fenda continua a ser uma fenda."""
    rows: dict[int, int] = {}
    for _, y in part:
        rows[y] = rows.get(y, 0) + 1
    top, bottom = min(rows), max(rows)
    low = sorted(n for y, n in rows.items() if y >= (top + bottom + 1) // 2)
    return low[len(low) // 10]


def opening(img: Image.Image, o: dict, offset, found: list[dict]) -> dict:
    x0, y0, x1, y1 = box = place(o["box_px"], offset)
    name = f"opening:{o['id']}"
    if x0 < 0 or y0 < 0 or x1 > img.width or y1 > img.height:
        return check("structure", name, "fail", f"o vao {o['id']} cai fora da imagem ({box})", box=box)
    clear = _clear(img, o, box)
    if clear is None:
        return check("structure", name, "inconclusive", f"{o['id']}: sem parede a volta para comparar", box=box)
    parts = masks.components(clear)
    sill = [c for c in parts if any(y == y1 - 1 for _, y in c)]
    door = o["kind"] in DOORS
    part = max(sill or parts or [frozenset()], key=len)
    if not part:
        return check("structure", name, "fail", f"{o['id']}: nenhum vao legivel na caixa (fechado ou da cor da "
                     "parede)", box=box)
    bx = masks.bbox(part)
    height, wide = bx[3] - bx[1], width(part)
    tall = regua.metric(found, "public_door_height" if o["kind"] in ("gate", "arch") else
                        "door_clear_height" if door else "window_height")
    need, need_w = tall["px"][0], regua.metric(found, "door_clear_width")["px"][0] if o["kind"] in PASSAGES else None
    reasons = (["nao chega a soleira"] if door and not sill and not o.get("raised") else []) + \
        ([f"vao legivel de {height} px, a regua pede {need}"] if height < need else []) + \
        ([f"largura util de {wide} px, a regua pede {need_w}"] if need_w and wide < need_w else [])
    rule = f" (perfil {'proposto' if tall['status'] == 'proposal' else tall['status']}, {tall['decision']})"
    detail = f"{o['id']}: " + ("; ".join(reasons) + rule if reasons else
                               f"vao legivel de {height}x{wide} px" + (" ate a soleira" if door else ""))
    return check("structure", name, "fail" if reasons else "pass", detail, box=box, clear_height=height,
                 clear_width=wide, required=need, required_width=need_w, clear_pixels=len(part),
                 rule_status=tall["status"], decision=tall["decision"])
