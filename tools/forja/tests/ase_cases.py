"""Os sprites que a Forja escreve para a prova de conformidade com o Aseprite (FORJA-14).

Cobrem o que o gerador em Lua nao alcanca: camada de referencia com limites precisos, grupo colapsado, movimento
bloqueado, UUID de camadas, slices com varias chaves (e uma escondida), os dezanove tipos de propriedade e um mapa de
extensao, paleta com nomes e alfa que muda a meio da animacao, dados por peca de um tileset. Determinísticos: o mesmo
codigo da os mesmos bytes, e o teste confere-os contra os ficheiros que o Aseprite abriu.
"""
from __future__ import annotations

import struct

from PIL import Image, ImageDraw

from tools.forja import ase
from tools.forja.ase.model import Layer, Slice, SliceKey, Tag, Tileset, Typed, UserData

ALL_TYPES = {"b": Typed(0x01, True), "i8": Typed(0x02, -7), "u8": Typed(0x03, 200), "i16": Typed(0x04, -3000),
             "u16": Typed(0x05, 60000), "i32": Typed(0x06, -70000), "u32": Typed(0x07, 4000000000),
             "i64": Typed(0x08, -5000000000), "u64": Typed(0x09, 9000000000), "fixed": Typed(0x0A, 1.5),
             "float": Typed(0x0B, 0.25), "double": Typed(0x0C, 2.125), "text": Typed(0x0D, "arco"),
             "point": Typed(0x0E, (40, 78)), "size": Typed(0x0F, (80, 80)), "rect": Typed(0x10, (2, 3, 76, 77)),
             "mixed": Typed(0x11, [Typed(0x06, 1), Typed(0x0D, "dois"), Typed(0x01, False)]),
             "same": Typed(0x11, [Typed(0x05, 3), Typed(0x05, 4)]),
             "map": Typed(0x12, {"slot": Typed(0x0D, "weapon"), "deep": Typed(0x12, {"n": Typed(0x06, 2)})}),
             "uuid": Typed(0x13, bytes(range(16)))}


def _box(size, rect, color) -> Image.Image:
    img = Image.new("RGBA", size)
    ImageDraw.Draw(img).rectangle(rect, fill=color)
    return img


def rgba() -> ase.Sprite:
    size = (40, 30)
    ground = Image.new("RGBA", size, (52, 60, 70, 255))
    body = [_box(size, [12 + f, 8, 25 + f, 27], (180, 90 + 20 * f, 60, 255)) for f in range(4)]
    bow = _box(size, [6, 14, 30, 16], (120, 80, 40, 210))
    glow = _box(size, [26, 2, 33, 9], (250, 220, 120, 140))
    ref = _box(size, [0, 0, 39, 29], (255, 0, 255, 255))
    layers = [(Layer("Background", flags=1 | 2 | 8), [ground] * 4),
              (Layer("body", flags=3 | 16, user=UserData("corpo", (0, 255, 0, 255), {"": {"slot": "body"}})),
               [body[0], body[0], body[2], body[3]]),
              (Layer("equip", "group", flags=3 | 32), []),
              (Layer("weapon_bow_l1", level=1, flags=3 | 4, blend=1, opacity=200), [bow, bow, None, bow]),
              (Layer("fx", "group", level=1), []),
              (Layer("overlay", level=2, blend=2, opacity=160), [glow, None, glow, None]),
              (Layer("References", flags=1 | 64), [ref, None, None, None]),
              (Layer("hidden", flags=2), [glow] * 4)]
    s = ase.build(size, layers, [100, 140, 80, 220])
    s.flags |= 4
    for i, layer in enumerate(s.layers):
        layer.uuid = struct.pack("<4I", 0xF0124A00 + i, i, 7, 9)
    s.cels[(3, 0)].z, s.cels[(3, 0)].opacity = -2, 180
    s.cels[(5, 2)].z = 1
    s.cels[(6, 0)].extra = (1, 0.5, 0.25, 40.0, 30.0)
    s.cels[(1, 0)].user = UserData("pose", (10, 20, 30, 255), {"": {"key": True}})
    s.tags = [Tag("idle", 0, 3, 0, 0, user=UserData(color=(255, 0, 0, 255))),
              Tag("walk", 0, 1, 1, 2, user=UserData("passo", (0, 128, 255, 255), {"": {"loop": True}})),
              Tag("attack", 1, 3, 2, 3, user=UserData(color=(0, 255, 0, 255))),
              Tag("die", 3, 3, 3, 1, user=UserData())]
    s.slices = [Slice("pivot", [SliceKey(0, 0, 0, 40, 30, None, (20, 28)), SliceKey(2, 0, 0, 40, 30, None, (21, 28))],
                      UserData(properties={"": {"kind": "pivot"}})),
                Slice("socket_hand", [SliceKey(0, 4, 4, 20, 12, (2, 2, 16, 8)),
                                      SliceKey(1, 6, 4, 20, 12, (2, 2, 16, 8)),
                                      SliceKey(3, 0, 0, 0, 0, (0, 0, 0, 0))], UserData("mao", (0, 0, 255, 255)))]
    s.external_files = [(1, 2, "forja/empire")]
    s.user = UserData("forja", None, {"": dict(ALL_TYPES), "forja/empire": {"contract": "royal_80"}})
    return s


def gray() -> ase.Sprite:
    size = (12, 8)
    base = Image.new("LA", size, (90, 255))
    top = Image.new("LA", size)
    ImageDraw.Draw(top).rectangle([2, 1, 9, 6], fill=(200, 150))
    return ase.build(size, [("base", [base]), (Layer("light", blend=2, opacity=180), [top]),
                            (Layer("add", blend=16), [top])], depth=16)


def indexed() -> ase.Sprite:
    size = (10, 10)
    pal = [(i * 25, 255 - i * 25, 90, 255 if i != 6 else 100, f"c{i}" if i % 2 else None) for i in range(10)]
    a = Image.new("P", size, 3)
    a.putpalette([v for c in pal for v in c[:3]])
    ImageDraw.Draw(a).rectangle([1, 1, 7, 6], fill=6)
    ImageDraw.Draw(a).point([(8, 8)], fill=9)
    b = a.copy()
    ImageDraw.Draw(b).rectangle([2, 2, 4, 4], fill=1)
    s = ase.build(size, [("sprite", [a, b])], [100, 100], depth=8, palette=pal, transparent=3)
    s.palettes[1] = [c if i != 1 else (255, 255, 0, 255, "troca") for i, c in enumerate(pal)]
    return s


def tilemap() -> ase.Sprite:
    tw = th = 4
    tiles = [Image.new("RGBA", (tw, th))] + [Image.new("RGBA", (tw, th), (70 * k, 30 * k, 200 - 50 * k, 255))
                                             for k in (1, 2, 3)]
    for k, t in enumerate(tiles[1:], 1):
        t.putpixel((0, 0), (255, 255, 255, 255))
        t.putpixel((k, 3), (0, 0, 0, 255))
    sheet = Image.new("RGBA", (tw, th * 4))
    for k, t in enumerate(tiles):
        sheet.paste(t, (0, k * th))
    s = ase.Sprite(16, 12, durations=[100, 100])
    s.tilesets = [Tileset(0, "terrain", tw, th, 4, pixels=sheet.tobytes(), user=UserData("terreno"),
                          tile_users=[UserData(), UserData("relva"), UserData(properties={"": {"wang": 5}}),
                                      UserData(color=(9, 9, 9, 255))])]
    s.layers = [Layer("surface", "tilemap", tileset=0)]
    flags = (0, 0x80000000, 0x40000000, 0x20000000)
    for frame in range(2):
        cells = [((x + y + frame) % 4) | flags[(x + 2 * y) % 4] for y in range(3) for x in range(4)]
        s.cels[(0, frame)] = ase.Cel(0, 0, width=4, height=3, pixels=struct.pack(f"<{len(cells)}I", *cells),
                                     tilemap={"bits": 32, "id": 0x1FFFFFFF, "xflip": 0x80000000,
                                              "yflip": 0x40000000, "dflip": 0x20000000})
    return s


def body() -> ase.Sprite:
    """Um corpo como a Forja o entrega (`aseprite.assemble`): slots dados fora da ordem Z, a sombra num so quadro,
    a camada de referencia, as tags do ANIMATION_BIBLE (o `die` toca uma vez), o pivot e o contrato nos dados."""
    from tools.forja import aseprite
    size, n = (64, 64), 13
    frames = [_box(size, [24, 20 + (f % 3), 39, 56], (150, 110 - 5 * f, 70, 255)) for f in range(n)]
    face = [_box(size, [28, 24 + (f % 3), 35, 28 + (f % 3)], (230, 200, 160, 255)) for f in range(n)]
    bow = [_box(size, [16, 36, 47, 38], (110, 70, 30, 255)) if f < 6 else None for f in range(n)]
    shadow = [_box(size, [22, 55, 41, 57], (0, 0, 0, 90))]
    ref = _box(size, [0, 0, 63, 63], (255, 0, 255, 255))
    return aseprite.assemble(size, {"weapon_bow_l1": bow, "face_normal": face, "body": frames, "shadow": shadow},
                             [100] * 6 + [140] * 7, [("idle", 0, 5, "forward"), ("die", 6, 12, "forward")],
                             pivot=(32, 56), reference=ref, kind="character_s1")


def wang() -> ase.Sprite:
    """Um terreno como a Forja o entrega (`tileset --aseprite`): as 16 pecas Wang depois da vazia e o mapa de
    exemplo numa camada tilemap."""
    from tools.forja import aseprite, tiles
    lower, upper, rim = (Image.new("RGBA", (16, 16), c) for c in ((58, 95, 42, 255), (138, 106, 58, 255),
                                                                   (111, 160, 74, 255)))
    sheet, _ = tiles.wang16(16, lower, upper, rim=rim, rim_width=2, rim_side="top", rag=0.35, seed=0, cluster=2)
    return aseprite.tilemap(sheet, 16, tiles.demo_indices(), "terrain")


def cena() -> ase.Sprite:
    """Uma construcao como a Forja a entrega (`estrutura --aseprite`): a casa e o estado danificado, com o vao, o
    sinal, a zona de mudanca e o pivot em slices."""
    import tempfile
    from pathlib import Path

    from tools.forja import scene
    from tools.forja.ase import cena as scene_ase
    from tools.forja.tests import scene_fixtures as fx
    res = scene.resolve(scene.load(fx.write(Path(tempfile.mkdtemp(prefix="forja-cena-")), fx.contract())))
    done = fx.house()
    damaged = done.copy()
    ImageDraw.Draw(damaged).rectangle([20, 10, 41, 21], fill=(0, 0, 0, 0))
    return scene_ase.write(res, {"done": done, "damaged": damaged})


CASES = {"forja_rgba": rgba, "forja_gray": gray, "forja_indexed": indexed, "forja_tilemap": tilemap,
         "forja_body": body, "forja_wang": wang, "forja_cena": cena}
