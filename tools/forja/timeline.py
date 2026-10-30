"""Integridade da timeline e ordem real de reproducao; nenhum quadro fica sem tempo ou tag."""
from __future__ import annotations

from PIL import Image

from . import contracts
from .godot import DIRECTIONS, order


def visible(frame: Image.Image) -> Image.Image:
    rgba = frame.convert("RGBA")
    out = Image.new("RGBA", rgba.size)
    out.paste(rgba, (0, 0), rgba.getchannel("A").point(lambda a: 255 if a else 0))
    return out


def validate(frames, durations, tags, columns=None) -> None:
    if not frames or len({f.size for f in frames}) != 1:
        raise ValueError("animacao precisa de quadros nao vazios na mesma tela")
    if columns is not None and (type(columns) is not int or columns < 1):
        raise ValueError("columns: inteiro positivo")
    if len(durations) != len(frames) or any(type(d) is not int or not 1 <= d <= 65535 for d in durations):
        raise ValueError("um tempo inteiro de 1..65535 ms por quadro, sem omissoes")
    if not tags:
        raise ValueError("timeline sem tags")
    covered, names = set(), set()
    for name, first, last, direction in tags:
        if not isinstance(name, str) or not name.strip() or name in names:
            raise ValueError("nome de tag vazio ou repetido")
        if type(first) is not int or type(last) is not int or not 0 <= first <= last < len(frames):
            raise ValueError(f"tag {name}: intervalo fora dos quadros")
        if direction not in DIRECTIONS:
            raise ValueError(f"tag {name}: direcao invalida {direction!r}")
        covered.update(range(first, last + 1))
        names.add(name)
    if covered != set(range(len(frames))):
        raise ValueError("quadros sem tag: declare toda a timeline")


def declarations(tags) -> None:
    names = set()
    for name, count in tags or []:
        if not name or name in names or type(count) is not int or count < 1:
            raise ValueError("tags: nomes unicos e contagens positivas")
        names.add(name)


def build(tags, count, strict=False):
    declarations(tags)
    if count < 1:
        raise ValueError("timeline sem quadros")
    if not tags:
        return [("anim", 0, count - 1, "forward")], [round(1000 / contracts.load_data()["fps"])] * count
    expected = sum(n for _, n in tags)
    if strict and expected != count:
        raise ValueError(f"tags pedem {expected} quadros, mas existem {count}; nao se trunca a timeline")
    out, durations, start = [], [], 0
    for name, n in tags:
        if start >= count:
            break
        last = min(count, start + n) - 1
        out.append((name, start, last, "forward"))
        durations += [round(1000 / (contracts.tag(name) or {}).get("fps", 10))] * (last - start + 1)
        start = last + 1
    if start < count:
        suffix = "unassigned"
        while suffix in {t[0] for t in out}:
            suffix += "_"
        out.append((suffix, start, count - 1, "forward"))
        durations += [100] * (count - start)
    return out, durations


def playback(tags, loops=None):
    return [{"name": name, "indices": order(first, last, direction),
             "loop": loops if isinstance(loops, bool) else (loops or {}).get(
                 name, (contracts.tag(name.removesuffix("_left").removesuffix("_right")) or {}).get("loop", True))}
            for name, first, last, direction in tags]


def holds(items, count):
    seen = set()
    for h in items or []:
        at, ms = h.get("frame"), h.get("ms")
        if type(at) is not int or not 0 <= at < count or at in seen or not h.get("reason"):
            raise ValueError("hold: quadro unico dentro da timeline e razao obrigatoria")
        if ms is not None and (type(ms) is not int or not 1 <= ms <= 65535):
            raise ValueError("hold: tempo entre 1 e 65535 ms")
        if "same_as" in h and (type(h["same_as"]) is not int or not 0 <= h["same_as"] < at):
            raise ValueError("hold: same_as precisa de apontar a um quadro anterior")
        seen.add(at)
