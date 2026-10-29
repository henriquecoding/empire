"""O documento Aseprite em memoria: tudo o que a especificacao 1.3 descreve, sem perder nada na ida e volta.

Os pixels guardam-se crus, no modo de cor do sprite (RGBA 4 bytes, Grayscale 2, Indexed 1), como no ficheiro: a
Forja nao converte em silencio. As cels ficam por (camada, quadro); uma cel ligada guarda o quadro com que partilha a
imagem. As propriedades dos dados de utilizador guardam o tipo do formato (`Typed`) quando vem de um ficheiro, para a
reescrita sair igual; quem escreve pode dar valores Python simples.
"""
from __future__ import annotations

from dataclasses import dataclass, field

LAYER_KINDS = ("image", "group", "tilemap")
LAYER_FLAGS = {"visible": 1, "editable": 2, "lock_movement": 4, "background": 8, "prefer_linked": 16,
               "collapsed": 32, "reference": 64}
DIRECTIONS = ("forward", "reverse", "pingpong", "pingpong_reverse")
DEPTHS = {32: "rgba", 16: "grayscale", 8: "indexed"}
BYTES = {32: 4, 16: 2, 8: 1}
TILE_ID, TILE_XFLIP, TILE_YFLIP, TILE_DFLIP = 0x1FFFFFFF, 0x80000000, 0x40000000, 0x20000000


@dataclass(frozen=True)
class Typed:
    """Um valor de propriedade com o tipo do formato (0x0001 bool ... 0x0013 uuid)."""
    kind: int
    value: object


@dataclass
class UserData:
    text: str | None = None
    color: tuple[int, int, int, int] | None = None
    properties: dict[str, dict] = field(default_factory=dict)  # "" = do utilizador; senao o id da extensao

    def empty(self) -> bool:
        return self.text is None and self.color is None and not any(self.properties.values())


@dataclass
class Layer:
    name: str
    kind: str = "image"
    level: int = 0
    flags: int = 3
    blend: int = 0
    opacity: int = 255
    tileset: int | None = None
    uuid: bytes | None = None
    user: UserData = field(default_factory=UserData)

    def has(self, flag: str) -> bool:
        return bool(self.flags & LAYER_FLAGS[flag])


@dataclass
class Cel:
    x: int = 0
    y: int = 0
    opacity: int = 255
    z: int = 0
    width: int = 0
    height: int = 0
    pixels: bytes = b""  # cru, no modo do sprite; num tilemap, um DWORD por peca
    link: int | None = None
    tilemap: dict | None = None  # {"bits", "id", "xflip", "yflip", "dflip"} numa cel de tilemap
    extra: tuple | None = None  # (flags, x, y, w, h) em virgula fixa 16.16 convertida para float
    user: UserData = field(default_factory=UserData)


@dataclass
class Tag:
    name: str
    first: int
    last: int
    direction: int = 0
    repeat: int = 0
    user: UserData = field(default_factory=UserData)  # a cor da tag e user.color


@dataclass
class SliceKey:
    frame: int
    x: int
    y: int
    w: int
    h: int
    center: tuple[int, int, int, int] | None = None
    pivot: tuple[int, int] | None = None


@dataclass
class Slice:
    name: str
    keys: list[SliceKey]
    user: UserData = field(default_factory=UserData)


@dataclass
class Tileset:
    id: int
    name: str
    tile_w: int
    tile_h: int
    count: int
    flags: int = 6  # peças dentro do ficheiro; o id 0 e a peça vazia
    base_index: int = 1
    pixels: bytes = b""  # tile_w x (tile_h * count), no modo do sprite
    external: tuple[int, int] | None = None
    user: UserData | None = None
    tile_users: list[UserData] = field(default_factory=list)


@dataclass
class Sprite:
    width: int
    height: int
    depth: int = 32
    flags: int = 1
    speed: int = 100
    transparent: int = 0
    pixel_ratio: tuple[int, int] = (1, 1)
    grid: tuple[int, int, int, int] = (0, 0, 16, 16)
    layers: list[Layer] = field(default_factory=list)
    durations: list[int] = field(default_factory=list)
    cels: dict[tuple[int, int], Cel] = field(default_factory=dict)
    tags: list[Tag] = field(default_factory=list)
    slices: list[Slice] = field(default_factory=list)
    palettes: dict[int, list[tuple]] = field(default_factory=dict)  # quadro -> [(r, g, b, a, nome|None)]
    tilesets: list[Tileset] = field(default_factory=list)
    user: UserData = field(default_factory=UserData)
    color_profile: dict | None = field(default_factory=lambda: {"type": 1, "flags": 0, "gamma": 0.0, "icc": b""})
    external_files: list[tuple[int, int, str]] = field(default_factory=list)  # (id, tipo, nome)

    @property
    def frames(self) -> int:
        return len(self.durations)

    @property
    def mode(self) -> str:
        return DEPTHS[self.depth]

    def palette(self, frame: int = 0) -> list[tuple]:
        """A paleta em vigor num quadro (a ultima mudanca ate ele)."""
        keys = [k for k in self.palettes if k <= frame]
        return self.palettes[max(keys)] if keys else []

    def parents(self) -> list[int | None]:
        """O indice do grupo de cada camada (NOTE.1: o nivel diz a relacao com a camada anterior)."""
        out: list[int | None] = []
        stack: list[int] = []
        for i, layer in enumerate(self.layers):
            del stack[layer.level:]
            out.append(stack[-1] if stack else None)
            if layer.kind == "group":
                stack.append(i)
        return out
