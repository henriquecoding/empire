"""Recursos de texto do Godot 4 a partir do que a Forja produz.

- TileSet com um conjunto de terrenos em "Match Corners" para a folha Wang 16.
- SpriteFrames com uma animacao por tag, a partir da tira e das duracoes.

Os dois sao .tres de formato 3 e apontam a textura por caminho res://. O teste
`tools/forja/tests/test_godot.py` abre-os no motor fixado em .godot-version
quando ele esta no PATH (ou em GODOT); sem motor, o teste diz que saltou e porque.
"""
from __future__ import annotations

from pathlib import Path

from .tiles import corners

PEERING = {"NW": "top_left_corner", "NE": "top_right_corner",
           "SW": "bottom_left_corner", "SE": "bottom_right_corner"}


def _color(rgb: tuple[int, int, int]) -> str:
    return "Color(%.4g, %.4g, %.4g, 1)" % tuple(c / 255 for c in rgb)


def tileset(texture: str, size: int, names: tuple[str, str] = ("lower", "upper"),
            colors: tuple[tuple[int, int, int], tuple[int, int, int]] = ((90, 70, 50), (110, 160, 70)),
            columns: int = 4) -> str:
    """O texto do .tres. `texture` e o caminho res:// da folha 4x4."""
    lines = ['[gd_resource type="TileSet" format=3]', "",
             f'[ext_resource type="Texture2D" path="{texture}" id="1_sheet"]', "",
             '[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_wang"]',
             'texture = ExtResource("1_sheet")', f"texture_region_size = Vector2i({size}, {size})"]
    for index in range(16):
        c = corners(index)
        key = f"{index % columns}:{index // columns}/0"
        center = 1 if sum(c.values()) >= 2 else 0
        lines += [f"{key} = 0", f"{key}/terrain_set = 0", f"{key}/terrain = {center}"]
        lines += [f"{key}/terrains_peering_bit/{PEERING[k]} = {c[k]}" for k in ("NW", "NE", "SW", "SE")]
    lines += ["", "[resource]", f"tile_size = Vector2i({size}, {size})", "terrain_set_0/mode = 1"]
    for i, (name, rgb) in enumerate(zip(names, colors)):
        lines += [f'terrain_set_0/terrain_{i}/name = "{name}"', f"terrain_set_0/terrain_{i}/color = {_color(rgb)}"]
    lines.append('sources/0 = SubResource("TileSetAtlasSource_wang")')
    return "\n".join(lines) + "\n"


def sprite_frames(texture: str, rects: list[tuple[int, int, int, int]], durations: list[int],
                  tags: list[tuple[str, int, int, str]], fps: float = 10.0,
                  loops: dict[str, bool] | None = None) -> str:
    """O texto do .tres. As duracoes em ms viram multiplicadores do `speed` (fps)."""
    loops = loops or {}
    lines = ['[gd_resource type="SpriteFrames" format=3]', "",
             f'[ext_resource type="Texture2D" path="{texture}" id="1_strip"]', ""]
    for i, (x, y, w, h) in enumerate(rects):
        lines += [f'[sub_resource type="AtlasTexture" id="AtlasTexture_{i}"]', 'atlas = ExtResource("1_strip")',
                  f"region = Rect2({x}, {y}, {w}, {h})", ""]
    base = 1000.0 / fps
    anims = []
    for name, first, last, direction in tags:
        order = frame_order(first, last, direction)
        if first < 0 or last >= len(rects) or len(durations) != len(rects) or any(d <= 0 for d in durations):
            raise ValueError("quadros ou duracoes invalidos")
        frames = ",\n".join('{\n"duration": %s,\n"texture": SubResource("AtlasTexture_%d")\n}'
                            % (_num(durations[i] / base), i) for i in order)
        anims.append('{\n"frames": [%s],\n"loop": %s,\n"name": &"%s",\n"speed": %s\n}'
                     % (frames, "true" if loops.get(name, True) else "false", name, _num(fps)))
    lines += ["[resource]", "animations = [%s]" % ", ".join(anims)]
    return "\n".join(lines) + "\n"


def frame_order(first: int, last: int, direction: str) -> list[int]:
    if first > last or direction not in ("forward", "reverse", "pingpong", "pingpong_reverse"):
        raise ValueError("intervalo ou direcao de animacao invalida")
    order = list(range(first, last + 1))
    if direction in ("reverse", "pingpong_reverse"):
        order.reverse()
    return order + order[-2:0:-1] if direction.startswith("pingpong") else order


def _num(v: float) -> str:
    return f"{v:.4g}" if v != int(v) else f"{int(v)}.0"


def write(path: str | Path, text: str) -> Path:
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")
    return path


CHECK_SCRIPT = '''extends SceneTree


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var res: Resource = ResourceLoader.load(args[0])
	if res == null:
		print("FORJA_FAIL load")
		quit(1)
		return
	if res is TileSet:
		var ts: TileSet = res as TileSet
		var src: TileSetAtlasSource = ts.get_source(0) as TileSetAtlasSource
		var bits: Array = []
		for i in range(src.get_tiles_count()):
			var coords: Vector2i = src.get_tile_id(i)
			var data: TileData = src.get_tile_data(coords, 0)
			bits.append([coords.x, coords.y, data.terrain_set, data.terrain,
				data.get_terrain_peering_bit(TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER),
				data.get_terrain_peering_bit(TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER),
				data.get_terrain_peering_bit(TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER),
				data.get_terrain_peering_bit(TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER)])
		print("FORJA_OK tileset %s" % JSON.stringify({"tiles": src.get_tiles_count(),
			"mode": ts.get_terrain_set_mode(0), "terrains": ts.get_terrains_count(0), "bits": bits}))
	elif res is SpriteFrames:
		var sf: SpriteFrames = res as SpriteFrames
		var counts: Array = []
		for n: StringName in sf.get_animation_names():
			counts.append([String(n), sf.get_frame_count(n), sf.get_animation_speed(n), sf.get_animation_loop(n)])
			var frames: Array = []
			for i in range(sf.get_frame_count(n)):
				var tex: AtlasTexture = sf.get_frame_texture(n, i) as AtlasTexture
				frames.append([tex.region.position.x, sf.get_frame_duration(n, i)])
			print("FORJA_ORDER %s %s" % [n, JSON.stringify(frames)])
		print("FORJA_OK spriteframes %s" % JSON.stringify(counts))
	quit(0)
'''
