"""O contrato de uma cena (forja.scene/1) dentro do .aseprite (FORJA-13; o passo 2 que o FORJA-12 deixou).

Um quadro e uma tag por estado desenhado (ASSET_BIBLE §3: num edificio, tags = estados); a slice `pivot` no ponto
que o forge pousa (o centro da base), com a ancora e o chao nos dados; uma slice por vao (`opening_<id>`, com o tipo
e o tratamento), por regiao de sinal (`signal_<nome>`) e por zona de mudanca (`state_<estado>_<n>`, que so existe no
quadro desse estado); e o contrato resumido nos dados do sprite. `read` devolve o que o ficheiro diz e `drift` o
que difere do contrato: se o autor mexer num vao no Aseprite, a diferenca aparece — nunca se reescreve o contrato.
"""
from __future__ import annotations

from PIL import Image

from .build import sprite as build_sprite
from .describe import plain
from .model import Slice, SliceKey, Sprite, Tag, Typed, UserData

COLORS = {"opening": (0, 160, 255, 255), "signal": (255, 200, 0, 255), "state": (255, 60, 60, 255)}


def _box(box: list[int]) -> tuple[int, int, int, int]:
    """[x0, y0, x1, y1) do contrato -> x, y, largura, altura da slice."""
    return box[0], box[1], box[2] - box[0], box[3] - box[1]


def _slice(name: str, frame: int, box: list[int], kind: str, props: dict, last: int | None = None) -> Slice:
    keys = [SliceKey(frame, *_box(box))]
    if last is not None and frame < last:
        keys.append(SliceKey(frame + 1, 0, 0, 0, 0))  # a zona acaba com o quadro do estado
    return Slice(name, keys, UserData(color=COLORS[kind], properties={"": props}))


def write(res: dict, images: dict[str, Image.Image]) -> Sprite:
    """A peca e os seus estados desenhados (`images[estado]`, o primeiro e o do contrato) com o contrato em slices."""
    states = [s for s in res["states"] if s in images]
    if not states or states[0] != res["states"][0]:
        raise ValueError(f"falta a imagem do estado base {res['states'][0]!r}")
    w, h = res["extent_px"]
    if any(img.size != (w, h) for img in images.values()):
        raise ValueError(f"cada estado tem a extensao do contrato, {w}x{h}")
    sprite = build_sprite((w, h), [(res["asset"], [images[s] for s in states])], [100] * len(states))
    sprite.grid = (0, 0, res["step"], res["step"])
    sprite.tags = [Tag(s, i, i) for i, s in enumerate(states)]
    last = len(states) - 1
    anchor = res["anchor"]
    sprite.slices = [Slice("pivot", [SliceKey(0, 0, 0, w, h, None, (w // 2, h - 1))],
                           UserData(properties={"": {"anchor": anchor["mode"], "ground": anchor["ground"],
                                                     "anchor_local": Typed(0x0E, tuple(anchor["local_px"]))}}))]
    for o in res["openings"]:
        sprite.slices.append(_slice(f"opening_{o['id']}", 0, o["box_px"], "opening",
                                    {"kind": o["kind"], "treatment": o.get("treatment", "")}))
    for name, box in sorted(res["signal_regions"].items()):
        sprite.slices.append(_slice(f"signal_{name}", 0, box, "signal", {"signal": name}))
    for state, boxes in sorted(res["state_changes"].items()):
        if state in states:
            for n, box in enumerate(boxes):
                sprite.slices.append(_slice(f"state_{state}_{n}", states.index(state), box, "state",
                                            {"state": state}, last))
    sprite.user = UserData(properties={"": {
        "schema": "forja.scene/1", "id": res["id"], "asset": res["asset"], "kind": res["kind"], "step": res["step"],
        "states": list(res["states"]), "signals": list(res["signals"]), "materials": list(res["materials"])}})
    return sprite


def _props(s: Slice) -> dict:
    return plain(s.user.properties.get("", {}))


def _boxes(s: Slice, frames: int) -> list[list[int] | None]:
    """A caixa da slice em cada quadro: uma chave vale do seu quadro ate a seguinte; antes da primeira, ou com
    largura 0, a slice nao existe nesse quadro."""
    out, cur = [], None
    for f in range(frames):
        for k in s.keys:
            if k.frame == f:
                cur = [k.x, k.y, k.x + k.w, k.y + k.h] if k.w and k.h else None
        out.append(cur)
    return out


def read(sprite: Sprite) -> dict:
    """O contrato como o ficheiro o diz agora: estados, pivot, vaos, regioes de sinal e zonas de mudanca. Um vao ou
    um sinal que muda de caixa noutro quadro traz `frames` com as caixas desse quadro; uma zona traz os quadros
    onde existe."""
    out: dict = {"states": [t.name for t in sprite.tags], "openings": {}, "signal_regions": {}, "signal_frames": {},
                 "state_changes": {}, "state_frames": {}}
    for s in sprite.slices:
        boxes = _boxes(s, sprite.frames)
        box = next((b for b in boxes if b), None)
        other = {f: b for f, b in enumerate(boxes) if b != box}
        k = s.keys[0]
        if s.name == "pivot" and k.pivot:
            out["pivot"] = [k.x + k.pivot[0], k.y + k.pivot[1]]
        elif s.name.startswith("opening_"):
            out["openings"][s.name[len("opening_"):]] = {"box_px": box, **_props(s), **({"frames": other} if other
                                                                                           else {})}
        elif s.name.startswith("signal_"):
            out["signal_regions"][s.name[len("signal_"):]] = box
            if other:
                out["signal_frames"][s.name[len("signal_"):]] = other
        elif s.name.startswith("state_"):
            state = _props(s).get("state")
            out["state_changes"].setdefault(state, []).append(box)
            out["state_frames"].setdefault(state, []).append([f for f, b in enumerate(boxes) if b])
    return out


def drift(res: dict, seen: dict) -> list[str]:
    """O que o ficheiro diz diferente do contrato (vazio: o ficheiro e o contrato concordam)."""
    out = []
    want = {o["id"]: o["box_px"] for o in res["openings"]}
    got = {k: v["box_px"] for k, v in seen["openings"].items()}
    for oid in sorted(set(want) | set(got)):
        if want.get(oid) != got.get(oid):
            out.append(f"vao {oid}: contrato {want.get(oid)}, ficheiro {got.get(oid)}")
        for f, box in sorted(seen["openings"].get(oid, {}).get("frames", {}).items()):
            out.append(f"vao {oid} no quadro {f}: contrato {want.get(oid)}, ficheiro {box}")
    for name in sorted(set(res["signal_regions"]) | set(seen["signal_regions"])):
        if res["signal_regions"].get(name) != seen["signal_regions"].get(name):
            out.append(f"sinal {name}: contrato {res['signal_regions'].get(name)}, ficheiro "
                       f"{seen['signal_regions'].get(name)}")
        for f, box in sorted(seen.get("signal_frames", {}).get(name, {}).items()):
            out.append(f"sinal {name} no quadro {f}: contrato {res['signal_regions'].get(name)}, ficheiro {box}")
    for state, spans in sorted(seen.get("state_frames", {}).items()):
        frame = seen["states"].index(state) if state in seen["states"] else None
        for span in spans:
            if span != [frame]:
                out.append(f"zona do estado {state}: nos quadros {span}, o estado e o quadro {frame}")
    for state in sorted(set(res["state_changes"]) & set(seen["states"]) | set(seen["state_changes"])):
        if res["state_changes"].get(state) != seen["state_changes"].get(state):
            out.append(f"estado {state}: contrato {res['state_changes'].get(state)}, ficheiro "
                       f"{seen['state_changes'].get(state)}")
    extra = [s for s in seen["states"] if s not in res["states"]]
    if extra:
        out.append(f"estados fora do contrato: {extra}")
    w, h = res["extent_px"]
    if seen.get("pivot") not in (None, [w // 2, h - 1]):
        out.append(f"pivot {seen['pivot']}, o forge pousa em {[w // 2, h - 1]}")
    return out
