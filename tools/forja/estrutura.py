"""A revisao estrutural de uma cena forjada contra o seu contrato (`forja.scene/1`, FORJA-09).

O lint confere o raster (tela, alfa, paleta, contorno, cluster). Nao sabe se a casa flutua, se a porta fechou na
quantizacao, se o sinal que a identifica sumiu, se a faixa de terreno repete sem degrau ou se o estado `damaged`
mudou a fachada inteira. Cada verificacao diz o que mediu; o que nao se mediu fica `not_evaluated`, nunca `pass`, e
os eixos nao se somam (relatorio de 28/10, §26: uma nota global nao compensa uma porta bloqueada).

As caixas do contrato estao no referencial da extensao. Uma imagem com o tamanho da extensao (o `forge` com a tela e o
pivot da cena) le-se diretamente; noutro tamanho, alinha-se pela ancora: o centro da base com o centro da base.
"""
from __future__ import annotations

from PIL import Image

from . import color, contracts, lint, masks, regua
from .imageops import opaque_bbox

AXES = ("raster_contract", "structure", "identity_signals", "continuity", "states", "artistic_approval",
        "runtime_integration")


def check(axis: str, name: str, status: str, detail: str, **evidence) -> dict:
    return {"axis": axis, "check": name, "status": status, "detail": detail, "evidence": evidence}


def _shift(img: Image.Image, res: dict) -> tuple[int, int]:
    """Do referencial da extensao para o da imagem, pela ancora."""
    w, h = res["extent_px"]
    dx = img.width // 2 - w // 2 if res["anchor"]["mode"] == "base_center" else 0
    return dx, img.height - h


def _place(box: list[int], shift: tuple[int, int]) -> list[int]:
    return [box[0] + shift[0], box[1] + shift[1], box[2] + shift[0], box[3] + shift[1]]


def _frame(img: Image.Image, res: dict) -> list[dict]:
    out, step = [], res["step"]
    w, h = res["extent_px"]
    same = img.size == (w, h)
    out.append(check("structure", "extent", "pass" if same else "fail",
                     f"{img.width}x{img.height} px" + ("" if same else f"; o contrato pede {w}x{h} (alinhado pela "
                                                                         "ancora)"), size=list(img.size)))
    off = [v for v in img.size if v % step]
    out.append(check("structure", "lattice", "fail" if off else "pass",
                     f"lados multiplos de {step} px" if not off else f"lado(s) {off} fora da grade de {step} px",
                     phase=res["lattice"]["phase"]))
    box = opaque_bbox(img)
    if box is None:
        return out + [check("structure", "base_contact", "fail", "imagem vazia")]
    if res["anchor"]["ground"] != "surface":
        out.append(check("structure", "base_contact", "not_evaluated", f"ancora {res['anchor']['ground']}: "
                         "sem linha de chao a conferir"))
        return out
    float_px = img.height - box[3]
    alpha = img.getchannel("A").load()
    row = [x for x in range(box[0], box[2]) if alpha[x, img.height - 1] >= 128]
    fill = round((box[2] - box[0]) / max(1, w), 2)
    status = "fail" if float_px else "pass"
    detail = (f"a base flutua {float_px} px acima do chao" if float_px else
              f"pousa no chao em {len(row)} de {box[2] - box[0]} colunas")
    out.append(check("structure", "base_contact", status, detail, float_px=float_px, contact_columns=len(row),
                     width_fill=fill))
    if fill < 0.75:
        out.append(check("structure", "fill", "inconclusive", f"o desenho ocupa {fill:.0%} da largura pedida: o "
                         "gerador desenhou mais pequeno? (rever a escala na montagem)", width_fill=fill))
    return out


def _ring_light(img: Image.Image, box: list[int]) -> float | None:
    x0, y0, x1, y1 = box
    px = img.load()
    ring = [px[x, y] for x in range(max(0, x0 - 2), min(img.width, x1 + 2))
            for y in range(max(0, y0 - 2), min(img.height, y1))
            if not (x0 <= x < x1 and y0 <= y < y1) and px[x, y][3] >= 128]
    lights = sorted(color.oklab(p[:3])[0] for p in ring)
    return lights[len(lights) // 2] if lights else None


def _opening(img: Image.Image, o: dict, shift, found: list[dict]) -> dict:
    x0, y0, x1, y1 = box = _place(o["box_px"], shift)
    name = f"opening:{o['id']}"
    if x0 < 0 or y0 < 0 or x1 > img.width or y1 > img.height:
        return check("structure", name, "fail", f"o vao {o['id']} cai fora da imagem ({box})", box=box)
    px = img.load()
    if o.get("treatment", "interior") == "transparent":
        clear = {(x, y) for x in range(x0, x1) for y in range(y0, y1) if px[x, y][3] < 128}
    else:
        wall = _ring_light(img, box)
        if wall is None:
            return check("structure", name, "inconclusive", f"{o['id']}: sem parede a volta para comparar", box=box)
        sign = -1 if o.get("treatment", "interior") == "lit" else 1  # aceso: mais claro do que a parede
        clear = {(x, y) for x in range(x0, x1) for y in range(y0, y1)  # o vazio fora do edificio nao e um vao
                 if px[x, y][3] >= 128 and sign * (color.oklab(px[x, y][:3])[0] - wall) <= -0.12}
    sill = [c for c in masks.components(frozenset(clear)) if any(y == y1 - 1 for _, y in c)]
    door = o["kind"] in ("door", "gate", "arch", "bay")
    part = max(sill or masks.components(frozenset(clear)) or [frozenset()], key=len)
    if not part:
        return check("structure", name, "fail", f"{o['id']}: nenhum vao legivel na caixa (fechado ou da cor da "
                     "parede)", box=box)
    bx = masks.bbox(part)
    height = bx[3] - bx[1] + 1
    metric = "public_door_height" if o["kind"] in ("gate", "arch") else "door_clear_height" if door else "window_height"
    need = regua.metric(found, metric)["px"][0]
    reasons = (["nao chega a soleira"] if door and not sill and not o.get("raised") else []) + \
        ([f"vao legivel de {height} px, a regua pede {need}"] if height < need else [])
    detail = f"{o['id']}: " + ("; ".join(reasons) if reasons else f"vao legivel de {height} px" +
                               (" ate a soleira" if door else ""))
    return check("structure", name, "fail" if reasons else "pass", detail, box=box, clear_height=height,
                 required=need, clear_pixels=len(part))


def _signals(img: Image.Image, res: dict, shift, master: Image.Image | None) -> list[dict]:
    out = []
    regions = res["signal_regions"]
    for sid in res["signals"]:
        if sid not in regions:
            out.append(check("identity_signals", sid, "not_evaluated", f"{sid}: sem regiao marcada no contrato"))
            continue
        x0, y0, x1, y1 = box = _place(regions[sid], shift)
        crop = img.crop(tuple(box))
        cover = sum(crop.getchannel("A").histogram()[128:]) / max(1, crop.width * crop.height)
        if cover < 0.25:
            out.append(check("identity_signals", sid, "fail", f"{sid}: a regiao ficou quase vazia ({cover:.0%})",
                             box=box, coverage=round(cover, 2)))
            continue
        if master is None:
            out.append(check("identity_signals", sid, "inconclusive", f"{sid}: presente ({cover:.0%}); sem mestre, "
                             "a forma revê-se a olho", box=box, coverage=round(cover, 2)))
            continue
        ref = master.crop(tuple(_place(regions[sid], _shift(master, res))))
        a, b = crop.tobytes(), ref.tobytes()
        changed = sum(a[i:i + 4] != b[i:i + 4] for i in range(0, len(a), 4))
        out.append(check("identity_signals", sid, "pass" if not changed else "fail",
                         f"{sid}: igual ao mestre" if not changed else f"{sid}: {changed} px diferentes do mestre",
                         box=box, changed=changed))
    return out


def _profile(img: Image.Image, x: int) -> list[bool]:
    a = img.getchannel("A").load()
    return [a[x, y] >= 128 for y in range(img.height)]


def joint(left: Image.Image, right: Image.Image) -> dict:
    """A juncao de dois modulos lado a lado: o degrau na emenda contra o maior degrau entre colunas interiores."""
    if left.height != right.height:
        return {"ok": False, "jump": None, "interior": None, "detail": f"alturas {left.height} e {right.height}"}
    jump = sum(a != b for a, b in zip(_profile(left, left.width - 1), _profile(right, 0)))
    inner = max([sum(a != b for a, b in zip(_profile(im, x), _profile(im, x + 1)))
                 for im in (left, right) for x in range(im.width - 1)] or [0])
    return {"ok": jump <= inner, "jump": jump, "interior": inner,
            "detail": f"degrau de {jump} px na emenda; o maior entre colunas interiores e {inner}"}


def _continuity(img: Image.Image, res: dict, neighbors: dict) -> list[dict]:
    out = []
    if "x" in res["repeat"]:
        j = joint(img, img)
        out.append(check("continuity", "repeat_x", "pass" if j["ok"] else "fail", "repete em x: " + j["detail"],
                         jump=j["jump"], interior=j["interior"]))
    for side, other in neighbors.items():
        j = joint(img, other) if side == "right" else joint(other, img)
        out.append(check("continuity", f"connector_{side}", "pass" if j["ok"] else "fail",
                         f"com o vizinho da {'direita' if side == 'right' else 'esquerda'}: " + j["detail"],
                         jump=j["jump"], interior=j["interior"]))
    if not out and res["connectors"]:
        out.append(check("continuity", "connectors", "not_evaluated", "modulo com conectores: de os vizinhos"))
    return out


def _states(base: Image.Image, res: dict, states: dict) -> list[dict]:
    out = []
    for name, img in states.items():
        if img.size != base.size:
            out.append(check("states", name, "fail", f"{name}: {img.size}, a base e {base.size} (a origem muda)"))
            continue
        allowed = frozenset().union(*[masks.box(tuple(_place(b, _shift(img, res))))
                                      for b in res["state_changes"].get(name, [])])
        a, b = base.load(), img.load()
        outside = [(x, y) for y in range(img.height) for x in range(img.width)
                   if a[x, y] != b[x, y] and (x, y) not in allowed]
        out.append(check("states", name, "fail" if outside else "pass",
                         f"{name}: {len(outside)} px mudados fora das zonas declaradas" if outside else
                         f"{name}: so mudou dentro das zonas declaradas", outside=len(outside),
                         where=[list(p) for p in outside[:8]]))
    return out


def summarize(checks: list[dict], raster_ok: bool | None) -> dict:
    v = {axis: "not_evaluated" for axis in AXES}
    v["artistic_approval"] = "pending"
    if raster_ok is not None:
        v["raster_contract"] = "pass" if raster_ok else "fail"
    for axis in AXES[1:5]:
        found = [c["status"] for c in checks if c["axis"] == axis]
        if found:
            v[axis] = next((s for s in ("fail", "inconclusive", "not_evaluated") if s in found), "pass")
    return v


def review(img: Image.Image, res: dict, master: Image.Image | None = None, neighbors: dict | None = None,
           states: dict | None = None, palette=None) -> dict:
    img = img.convert("RGBA")
    master = master.convert("RGBA") if master is not None else None
    states = {k: v.convert("RGBA") for k, v in (states or {}).items()}
    shift = _shift(img, res)
    raster = lint.check(img, contracts.get(res["kind"]), palette, frame=False)
    checks = _frame(img, res) + [_opening(img, o, shift, res["metrics"]) for o in res["openings"]]
    checks += _signals(img, res, shift, master) + _continuity(img, res, neighbors or {})
    checks += _states(img, res, states)
    v = summarize(checks, raster["ok"])
    w, h = img.size
    world_edge = res["lattice"]["anchors"].get("surface_y", {}).get("edge")
    placement = {"anchor_local_px": [w // 2 if res["anchor"]["mode"] == "base_center" else 0, h],
                 "anchor_world_y_edge": world_edge, "top_world_y": world_edge - h if world_edge else None,
                 "rule": "world = anchor_world - anchor_local + pixel_local"}
    return {"verdicts": v, "blocking": [a for a, s in v.items() if s == "fail"], "checks": checks,
            "raster": {k: raster[k] for k in ("ok", "errors", "warnings", "prompt_feedback")},
            "placement": placement, "scene": res["id"]}
