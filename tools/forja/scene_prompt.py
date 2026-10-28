"""O pedido de uma cena ou construcao: do `forja.scene/1` a um prompt que o gerador cumpre (FORJA-11).

O compilador dos personagens fala de rosto, roupa e pose, e de uma camara de perfil virada para um lado. Uma casa
nao tem nada disso: tem projecao (elevacao lateral, a fachada paralela ao plano da imagem), uma linha de chao, vaos
medidos pelos atores reais e sinais de identidade arquitetonica (relatorio de 28/10, §9, §18 e §28). Cada linha diz a
origem, como no `constraints.py`; nenhuma e uma preferencia escondida do compilador.

A regua vai tambem como imagem (`ruler_guide`): as silhuetas verdadeiras do ator mais alto e do mais baixo, na
escala do pedido, de pe na linha do chao, e a altura que a porta pede. Um gerador segue melhor uma figura do que uma
frase sobre medidas; o texto diz-lhe que nao as desenhe.
"""
from __future__ import annotations

from PIL import Image, ImageDraw

from . import constraints, contracts, matte, prompts, regua
from .palette import Palette

ROLE_TEXT = {"palette": prompts.ROLES["palette"],
             "ruler": "the SCALE RULER at the exact output size: silhouettes of the real game characters standing on "
                      "the walk line and the doorway height they need; do NOT draw these figures, marks or lines"}


LOOKS = {"interior": "a dark interior", "lit": "a lit interior, brighter than the wall", "transparent": "see-through"}
GROUNDS = {
    "terrain_strip": "Ground: the TOP edge is the walk line (a walkable lip in the top rows); below it the cut face of "
                     "the soil runs down to the bottom edge; nothing above the lip.",
    "plane": "Ground: the band rests on the bottom edge of the image (its own horizon); it is a flat silhouette band, "
             "with no walk line and no characters' scale details.",
}


def _ground(res: dict) -> dict:
    asset = res["asset"].replace("_", " ")
    kind = res["asset"] if res["asset"] == "terrain_strip" else "plane" if res["anchor"]["mode"] == "base_left" else ""
    text = GROUNDS.get(kind) or (f"Ground: the {asset} rests on a flat walk line along the bottom edge of the image "
                                 "(the bottom row of logical pixels is the ground contact); it neither floats nor "
                                 "sinks; do not paint a cast shadow on the ground (the game adds the contact shadow).")
    return _rule("ground", text, "asset_bible §1 (sombra de contacto); scene:anchor")


def _rule(ident: str, text: str, origin: str) -> dict:
    return {"id": ident, "text": text, "origin": origin}


def role_text(role: str) -> str:
    if role in ROLE_TEXT:
        return ROLE_TEXT[role]
    r = regua.data()["roles"][role]
    return f"the {r['en']} ({role}): use it for {r['carries']}; do NOT copy {r['forbids']}"


def geometry(res: dict, target: str) -> dict:
    cw, ch = res["cells"]
    k = prompts.pick_scale(cw, ch, target)
    return {"canvas": [cw, ch], "layout": [1, 1], "frames": 1, "logical": [cw, ch], "content": [0, 0, cw, ch],
            "scale": k, "size": [cw * k, ch * k], "exact": target == "gpt-image"}


def _scale_lines(res: dict, offset: tuple[int, int] = (0, 0)) -> list[dict]:
    step, rul = res["step"], res["ruler"]
    door = regua.metric(res["metrics"], "door_clear_height")
    width = regua.metric(res["metrics"], "door_clear_width")
    tall, short = rul["tallest"], rul["shortest"]
    out = [_rule("scale", f"Scale: one logical pixel is {step}x{step} screen pixels in the game. The tallest character "
                 f"is {tall['height'] / step:.1f} logical pixels tall and the smallest {short['height'] / step:.1f}; "
                 "the architecture is sized for them, never the characters for the building.",
                 f"regua: {tall['id']} e {short['id']} ({regua.data()['actors']['manifest']})")]
    doors = [o for o in res["openings"] if o["kind"] in ("door", "gate", "arch", "bay")]
    for o in res["openings"]:
        x0, y0, x1, y1 = (v + offset[i % 2] for i, v in enumerate(o["cells"]))
        look = LOOKS[o.get("treatment", "interior")]
        sill = "its sill on the ground line" if o["kind"] != "window" else "above the ground"
        out.append(_rule(f"opening:{o['id']}", f"{o['kind'].capitalize()} '{o['id']}': a clear opening at logical "
                         f"pixels x {x0}-{x1 - 1}, y {y0}-{y1 - 1} ({look}, {sill}); nothing crosses it.",
                         "scene:openings"))
    if not doors and res["spec"].get("openings"):
        out.append(_rule("door", f"Doorway: a clear opening {door['cells'][0]}-{door['cells'][1]} logical pixels tall "
                         f"and {width['cells'][0]}-{width['cells'][1]} wide, sill on the ground line.",
                         f"regua: {door['origin']}"))
    return out


def _identity(res: dict) -> list[dict]:
    d = regua.data()
    out = []
    if res["signals"]:
        out.append(_rule("identity", "Identity (must read clearly at 1x): "
                         + "; ".join(d["signals"][s] for s in res["signals"]) + ".", "scene:signals"))
    for m in res["materials"]:
        spec = d["materials"][m]
        out.append(_rule(f"material:{m}", f"Material {m.replace('_', ' ')}: {spec['motifs']}; concentrate detail at "
                         f"{spec['focus']}.", "scenery.json:materials (relatorio de 28/10, §11)"))
    if res["materials"]:
        out.append(_rule("detail", "Detail has hierarchy: large calm surfaces, detail concentrated where things are "
                         "joined, used or lit; no uniform noise texture, no random dark specks.",
                         "relatorio de 28/10, §4 e §7"))
    fam = d["families"].get(res["scene"].get("people", ""))
    if fam:
        out.append(_rule("people", f"People and place: {fam['nature']}; architecture of {fam['architecture']}.",
                         "scenery.json:families (proposta, relatorio §16)"))
    return out


def rules(res: dict, palette: Palette | None, swatch: int | None, listed: int = 24,
          offset: tuple[int, int] = (0, 0)) -> list[dict]:
    c = contracts.get(res["kind"])
    out = [_rule("projection", "Projection: orthographic side elevation, the view of a side-scrolling game: the facade "
                 "is parallel to the picture plane; no perspective, no vanishing point, no top-down, isometric or "
                 "three-quarter view. Roofs, ledges and platforms may show a thin top face for thickness.",
                 f"scene:{res['projection']} (relatorio de 28/10, §9)"),
           _ground(res)]
    out += _scale_lines(res, offset) + _identity(res)
    if res["asset"] in ("building", "wall_segment"):
        roof = regua.data()["roof"]
        out.append(_rule("roof", roof["en"], roof["origin"]))
    if c.outline_px:
        width = max(1, c.outline_px // c.cluster)
        out.append(_rule("outline", f"Outline: a {width}-logical-pixel pure black (#000000) outline on the outer "
                         "silhouette; inside, separate surfaces by value and colored edges, not black lines.",
                         f"contract:{c.kind} ({c.outline_px} px de ecra = {width} pixel logico)"))
    elif c.outline_px == 0:
        out.append(constraints.outline(c))
    out.append(_rule("shading", "Shading: light from the top-left; a light plane and a shadow plane per material, a "
                     "dark accent only at contacts and joints; no gradients, no dithering.", "asset_bible §1"))
    out.append(constraints.colors(palette, c, listed, swatch, True))
    if "x" in res["repeat"]:
        out.append(_rule("repeat", "Tiling: the left edge continues seamlessly into the right edge (it repeats "
                         "horizontally); the silhouette has the same height at both edges.", "scene:repeat"))
    light = (res["scene"].get("brief") or {}).get("light")
    if light:
        out.append(_rule("light", f"Light: {light}; warm light only where a source exists, as stepped color clusters; "
                         "no glow halo, no bloom.", "scene:brief"))
    return out


def build(res: dict, target: str = "gpt-image", attached: list[str] | None = None, geo: dict | None = None,
          palette: Palette | None = None, listed: int = 24) -> dict:
    """O prompt e o `expect` de uma cena resolvida (`scene.resolve`). `attached`: os papeis das imagens que VAO
    anexadas, por ordem (os da cena, `ruler`, `palette`)."""
    if target not in prompts.TARGETS:
        raise ValueError(f"alvo desconhecido: {target}")
    geo = geo or geometry(res, target)
    attached = attached or []
    number = {r: attached.index(r) + 1 for r in attached}
    lw, lh = geo["logical"]
    x0, y0, x1, y1 = geo["content"]
    k = geo["scale"]
    block = f"ONE crisp solid {k}x{k} square block" if geo["exact"] else (
        f"ONE crisp solid square block of one fixed size (about {round(k)}x{round(k)} image pixels)")
    found = rules(res, palette, number.get("palette"), listed, (x0, y0))
    spec, brief = res["spec"], res["scene"].get("brief") or {}
    lines = ['Create a pixel-art game asset for "Empire", a 2D side-view kingdom builder.',
             f"Subject: {res['scene']['subject']}.", f"Asset type: {spec['en']}."]
    if brief.get("story"):
        lines.append(f"Who built it and how it is used: {brief['story']}.")
    lines.append(f"Pixel grid: the image is an exact grid of {lw}x{lh} logical pixels; every logical pixel is {block} "
                 "aligned to the image edges. No sub-pixel detail, no anti-aliasing, no blur, no gradients, no soft "
                 "brushes, no texture noise.")
    lines += [r["text"] for r in found]
    if attached:
        lines.append("Attached images, in order: " + "; ".join(f"image {i}: {role_text(r)}"
                                                                for i, r in enumerate(attached, 1)) + ".")
    background = backdrop(res, target, palette)
    asset = res["asset"].replace("_", " ")
    lines.append(f"Background: fully transparent around the {asset}; no sky, no backdrop, no checkerboard."
                 if background in ("transparent", "keep") else
                 f"Background: one perfectly flat solid {background} color (chroma key) everywhere around the {asset}; "
                 f"never use {background} inside it; no shadow, floor, gradient or vignette.")
    if (x0, y0, x1, y1) != (0, 0, lw, lh):
        lines.append(f"Margins: draw only inside logical pixels x {x0}-{x1 - 1}, y {y0}-{y1 - 1}; the walk line is "
                     f"row {y1 - 1}; everything outside that box is empty background.")
    lines.append("Avoid: characters, animals, text or lettered signs, UI, frames, perspective or isometric projection, "
                 "photorealism, 3D render, painterly brushwork, blur, glow, watermark.")
    expect = {"kind": res["kind"], "cells": [lw, lh], "content": [x0, y0, x1, y1], "scale": k,
              "scale_exact": geo["exact"], "grid": "requested", "layout": [1, 1], "frames": 1, "tags": None,
              "background": background, "size": geo["size"], "cluster": res["step"], "attached": attached,
              "mode": "scene", "scene": res["id"], "forge_args": res["forge_args"], "placement": "origin"}
    advice = None if k >= 8 else (f"cada pixel logico tera so {k:g} px na imagem: divida a cena em objetos ou planos "
                                  "e peca cada um no seu tamanho")
    return {"prompt": "\n".join(lines), "size": f"{geo['size'][0]}x{geo['size'][1]}", "expect": expect,
            "advice": advice, "pixellab": pixellab_params(res), "target": target,
            "conflicts": prompts.camera_conflicts(res["scene"]["subject"], "right", "elevation"), "mode": "scene",
            "constraints": [{"id": "pixel_grid", "origin": "request"}] + [{k: r[k] for k in ("id", "origin")}
                                                                       for r in found], "implicit": []}


def backdrop(res: dict, target: str, palette: Palette | None = None) -> str:
    """O fundo pedido e o que o `forge` faz com ele: so o gpt-image (e o PixelLab) devolvem alfa; os outros pintam uma
    cor-chave liso, que sai em todo o lado. Uma peca que toca as bordas por desenho (faixa de terreno, muro, planos)
    nao passa pela detecao do fundo pela borda, que tomaria a terra pelo fundo: `keep` so binariza o alfa."""
    if target in ("gpt-image", "pixellab"):
        return "keep" if res["repeat"] else "transparent"
    return matte.best_key(palette.colors if palette else [])


def pixellab_params(res: dict) -> dict:
    c = contracts.get(res["kind"])
    outline = {None: None, 0: "lineless"}.get(c.outline_px, "single color black outline")
    return {"description": f"{res['scene']['subject']}, {res['spec']['en']}",
            "image_size": {"width": res["cells"][0], "height": res["cells"][1]}, "outline": outline,
            "shading": "basic shading", "detail": "highly detailed", "view": "side", "no_background": True}


def ruler_guide(res: dict, expect: dict, root=None) -> Image.Image:
    """A regua em imagem, no tamanho exato do pedido: chao, altura da porta e as silhuetas reais dos atores."""
    w, h = expect["size"]
    sx, sy = w / expect["cells"][0], h / expect["cells"][1]
    x0, _, x1, y1 = expect["content"]
    zoom = sx / res["step"]
    img = Image.new("RGBA", (w, h), (232, 232, 228, 255))
    draw = ImageDraw.Draw(img)
    ground = round(y1 * sy) - 1
    left, right = round(x0 * sx), round(x1 * sx)
    draw.line([(left, ground), (right, ground)], fill=(120, 120, 116, 255), width=max(1, round(sx / 2)))
    door = regua.metric(res["metrics"], "door_clear_height")["cells"][0] * sy
    draw.line([(left, round(ground - door)), (right, round(ground - door))], fill=(170, 170, 166, 255), width=1)
    for o in res["openings"]:
        bx0, by0, bx1, by1 = o["cells"]
        box = [round((x0 + bx0) * sx), round((y1 - res["cells"][1] + by0) * sy),
               round((x0 + bx1) * sx) - 1, round((y1 - res["cells"][1] + by1) * sy) - 1]
        draw.rectangle(box, outline=(150, 150, 146, 255), width=max(1, round(sx / 3)))
    x = left + round(sx * 2)
    for actor in (res["ruler"]["tallest"], res["ruler"]["shortest"]):
        sprite, (px, py), _ = regua.frame(actor["id"], root=root)
        mask = sprite.getchannel("A").point(lambda v: 255 if v else 0)
        size = (max(1, round(sprite.width * zoom)), max(1, round(sprite.height * zoom)))
        mask = mask.resize(size, Image.Resampling.NEAREST)
        top = round(ground - (py + 1) * zoom) + 1
        img.paste((96, 96, 92, 255), (x - round((px + actor["body_bounds"][0]) * zoom), top), mask)
        x += round(actor["width"] * zoom) + round(sx * 4)
    return img
