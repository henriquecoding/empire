"""Os tipos primitivos do formato (little-endian) e o bloco de dados de utilizador com as propriedades (0x2020).

As propriedades seguem a tabela da especificacao: 0x0001 bool a 0x0013 uuid, vetores (0x0011, mistos ou de um tipo)
e mapas aninhados (0x0012, ate 128 niveis). Ler devolve `Typed`; escrever aceita `Typed` ou um valor Python, do qual
infere o tipo (bool, int32/int64, double, string, vetor, mapa).
"""
from __future__ import annotations

import struct

from .model import Typed, UserData

FIXED = 65536.0
SIMPLE = {0x01: "<B", 0x02: "<b", 0x03: "<B", 0x04: "<h", 0x05: "<H", 0x06: "<i", 0x07: "<I", 0x08: "<q",
          0x09: "<Q", 0x0A: "<i", 0x0B: "<f", 0x0C: "<d"}


class Reader:
    def __init__(self, data: bytes, pos: int = 0):
        self.data, self.pos = data, pos

    def take(self, fmt: str):
        values = struct.unpack_from(fmt, self.data, self.pos)
        self.pos += struct.calcsize(fmt)
        return values if len(values) > 1 else values[0]

    def raw(self, n: int) -> bytes:
        out = self.data[self.pos:self.pos + n]
        self.pos += n
        return out

    def string(self) -> str:
        return self.raw(self.take("<H")).decode("utf-8")


def string(text: str) -> bytes:
    raw = text.encode("utf-8")
    return struct.pack("<H", len(raw)) + raw


def _value(r: Reader, kind: int, depth: int):
    if kind in SIMPLE:
        v = r.take(SIMPLE[kind])
        return bool(v) if kind == 0x01 else v / FIXED if kind == 0x0A else v
    if kind == 0x0D:
        return r.string()
    if kind in (0x0E, 0x0F):
        return r.take("<ii")
    if kind == 0x10:
        return r.take("<iiii")
    if kind == 0x11:
        n, same = r.take("<IH")
        out = []
        for _ in range(n):
            k = r.take("<H") if same == 0 else same
            out.append(Typed(k, _value(r, k, depth + 1)))
        return out
    if kind == 0x12:
        if depth > 128:
            raise ValueError("propriedades com mais de 128 niveis")
        return _map(r, depth + 1)
    if kind == 0x13:
        return r.raw(16)
    raise ValueError(f"tipo de propriedade desconhecido: {kind:#06x}")


def _map(r: Reader, depth: int = 0) -> dict:
    out = {}
    for _ in range(r.take("<I")):
        name = r.string()
        kind = r.take("<H")
        out[name] = Typed(kind, _value(r, kind, depth))
    return out


def read_user(r: Reader, ext: dict[int, str]) -> UserData:
    flags = r.take("<I")
    user = UserData()
    if flags & 1:
        user.text = r.string()
    if flags & 2:
        user.color = r.take("<4B")
    if flags & 4:
        r.take("<I")  # o tamanho de todos os mapas
        for _ in range(r.take("<I")):
            key = r.take("<I")
            user.properties[ext.get(key, "") if key else ""] = _map(r)
    return user


def _infer(value) -> Typed:
    if isinstance(value, Typed):
        return value
    if isinstance(value, bool):
        return Typed(0x01, value)
    if isinstance(value, int):
        return Typed(0x06 if -2 ** 31 <= value < 2 ** 31 else 0x08, value)
    if isinstance(value, float):
        return Typed(0x0C, value)
    if isinstance(value, str):
        return Typed(0x0D, value)
    if isinstance(value, (list, tuple)):
        return Typed(0x11, [_infer(v) for v in value])
    if isinstance(value, dict):
        return Typed(0x12, {k: _infer(v) for k, v in value.items()})
    raise TypeError(f"propriedade sem tipo no formato: {value!r}")


def _pack(t: Typed) -> bytes:
    k, v = t.kind, t.value
    if k in SIMPLE:
        return struct.pack(SIMPLE[k], round(v * FIXED) if k == 0x0A else int(v) if k == 0x01 else v)
    if k == 0x0D:
        return string(v)
    if k in (0x0E, 0x0F):
        return struct.pack("<ii", *v)
    if k == 0x10:
        return struct.pack("<iiii", *v)
    if k == 0x11:
        items = [_infer(x) for x in v]
        same = items[0].kind if items and all(i.kind == items[0].kind for i in items) else 0
        body = b"".join((b"" if same else struct.pack("<H", i.kind)) + _pack(i) for i in items)
        return struct.pack("<IH", len(items), same) + body
    if k == 0x12:
        return pack_map(v)
    if k == 0x13:
        return bytes(v)
    raise ValueError(f"tipo de propriedade desconhecido: {k:#06x}")


def pack_map(props: dict) -> bytes:
    out = struct.pack("<I", len(props))
    for name, value in props.items():
        t = _infer(value)
        out += string(name) + struct.pack("<H", t.kind) + _pack(t)
    return out


def pack_user(user: UserData, ext_ids: dict[str, int]) -> bytes:
    maps = {k: v for k, v in user.properties.items() if v}
    text, color = bool(user.text), bool(user.color and user.color[3])  # como o Aseprite: vazio e alfa 0 nao vao
    out = struct.pack("<I", (1 if text else 0) | (2 if color else 0) | (4 if maps else 0))
    if text:
        out += string(user.text)
    if color:
        out += struct.pack("<4B", *user.color)
    if maps:
        body = b"".join(struct.pack("<I", ext_ids[k] if k else 0) + pack_map(v) for k, v in maps.items())
        out += struct.pack("<II", 8 + len(body), len(maps)) + body
    return out
