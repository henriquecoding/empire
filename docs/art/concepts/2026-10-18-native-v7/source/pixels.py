"""Integer-grid authoring. No source images, resampling or quantization are used."""
from collections import OrderedDict
from PIL import Image, ImageDraw, ImageChops, ImageColor

PALETTE = {
    "ink": "#14151c", "skin": "#f4b57c", "skin_hi": "#ffdda3", "skin_sh": "#c77d55",
    "brown_skin": "#a96b43", "brown_hi": "#d39b62", "brown_sh": "#704334",
    "cream": "#ead7a2", "cream_hi": "#fff0c4", "cream_sh": "#baa476",
    "wine": "#8b243d", "wine_hi": "#b83d4a", "wine_sh": "#541e32",
    "navy": "#273a64", "navy_hi": "#405782", "navy_sh": "#17253e",
    "steel": "#8792a6", "steel_hi": "#d4d9dc", "steel_sh": "#515e77",
    "iron": "#364052", "iron_hi": "#5d6d82", "iron_sh": "#202533",
    "gold": "#dfa438", "gold_hi": "#ffe29a", "gold_sh": "#95602d",
    "leather": "#8d542a", "leather_hi": "#b67a3a", "leather_sh": "#57331f",
    "green": "#65714c", "green_hi": "#9baf75", "green_sh": "#3d513d",
    "hair": "#a34024", "hair_hi": "#d26335", "hair_sh": "#652c23",
    "blackhair": "#24201f", "blackhair_hi": "#3c302c", "blackhair_sh": "#15151b",
    "pants": "#34353c", "pants_hi": "#51515a", "white": "#fff4dc",
    "orange": "#d17126", "orange_hi": "#f2ab43", "pink": "#cf6593",
    "pink_hi": "#f3b1c7", "lavender": "#9585bd", "lavender_hi": "#cebee8",
    "leaf": "#568457", "leaf_hi": "#91ae65", "leaf_sh": "#304e44",
}


class Sprite:
    def __init__(self, name, label, size, pivot, head):
        self.name, self.label, self.size = name, label, size
        self.pivot, self.head = pivot, head
        self.layers = OrderedDict()
        self.operations = []
        self.current = None
        self.draw = None
        self.face_spec = None

    def layer(self, name):
        self.current = name
        if name not in self.layers:
            self.layers[name] = Image.new("RGBA", (self.size, self.size))
        self.draw = ImageDraw.Draw(self.layers[name])

    def p(self, color, *xy):
        assert len(xy) % 2 == 0 and all(isinstance(v, int) for v in xy)
        points = list(zip(xy[::2], xy[1::2]))
        self.draw.polygon(points, fill=PALETTE[color])
        self.operations.append([self.current, "polygon", color, list(xy)])

    def r(self, color, x, y, w, h):
        assert all(isinstance(v, int) for v in (x, y, w, h))
        self.draw.rectangle((x, y, x+w-1, y+h-1), fill=PALETTE[color])
        self.operations.append([self.current, "rect", color, [x, y, w, h]])

    def l(self, color, *xy):
        assert len(xy) % 2 == 0 and all(isinstance(v, int) for v in xy)
        self.draw.line(list(zip(xy[::2], xy[1::2])), fill=PALETTE[color], width=1)
        self.operations.append([self.current, "line", color, list(xy)])

    def flat(self):
        result = Image.new("RGBA", (self.size, self.size))
        for layer in self.layers.values():
            result.alpha_composite(layer)
        return result


STATES = ("calma", "foco", "medo", "golpe", "ferido", "vitoria")


def original_face(s, state="calma"):
    """Face anatomy stays in the body budget; no enlarged portrait is authored."""
    x, y, mouth_x, mouth_y, kind = s.face_spec
    base = s.flat()
    skin_colors = {ImageColor.getrgb(PALETTE[k]) for k in ("brown_skin", "brown_hi", "brown_sh") if kind == "nia"}
    if kind != "nia":
        skin_colors = {ImageColor.getrgb(PALETTE[k]) for k in ("skin", "skin_hi", "skin_sh")}
    skin_mask = Image.new("L", base.size)
    skin_mask.putdata([255 if px[:3] in skin_colors and px[3] else 0 for px in base.get_flattened_data()])
    mouth_width = {"king":8, "squire":3, "nia":5, "bard":3, "archer":4, "intendant":3, "dancer":3}[kind]
    s.layer("face")
    if state == "calma":
        s.r("white", x, y, 3, 3)
        s.r("ink", x+2, y, 1, 2)
        s.l("ink", x-1, y-1, x+3, y-1)
        if kind in ("king", "nia"):
            s.p("ink", mouth_x, mouth_y, mouth_x+mouth_width-1, mouth_y-1, mouth_x+mouth_width, mouth_y+2, mouth_x+2, mouth_y+3)
            s.l("white", mouth_x+1, mouth_y, mouth_x+mouth_width-2, mouth_y)
            if kind == "king":
                s.l("white", mouth_x+2, mouth_y+1, mouth_x+mouth_width-2, mouth_y+1)
                s.l("hair_sh", x-1, y-3, x+2, y-4)
        elif kind == "bard":
            s.r("ink", mouth_x, mouth_y, 3, 4)
            s.r("white", mouth_x, mouth_y, 2, 1)
        elif kind == "squire":
            s.r("ink", mouth_x, mouth_y, 3, 2)
            s.r("white", mouth_x+1, mouth_y, 1, 1)
        else:
            s.l("ink", mouth_x, mouth_y+1, mouth_x+3, mouth_y+1, mouth_x+4, mouth_y)
    elif state == "foco":
        s.r("white", x, y+1, 3, 2)
        s.r("ink", x+2, y+1, 1, 2)
        s.l("ink", x-1, y-(1 if kind == "squire" else 2), x+3, y)
        if kind == "bard":
            s.r("skin", x-1, y-2, 5, 2)
            s.l("ink", x-1, y, x+3, y)
            s.r("ink", mouth_x+1, mouth_y, 2, 3)
        else:
            s.l("ink", mouth_x, mouth_y+1, mouth_x+mouth_width-1, mouth_y+1)
    elif state == "medo":
        s.r("white", x, y if kind == "squire" else y-1, 3, 4)
        s.r("ink", x+2, y, 1, 2)
        brow_y = y-(1 if kind == "squire" else 2)
        s.l("ink", x-1, brow_y, x+1, brow_y-1, x+3, brow_y)
        if kind in ("king", "archer", "nia"):
            s.r("ink", mouth_x, mouth_y, mouth_width, 3)
            s.r("white", mouth_x+1, mouth_y, mouth_width-2, 1)
        else:
            s.r("ink", mouth_x+1, mouth_y, 3, 3)
    elif state == "golpe":
        s.l("ink", x-1, y-1, x+2, y+1, x-1, y+2)
        s.l("ink", x-1, y-(1 if kind == "squire" else 2), x+3, y-1)
        if kind == "intendant":
            s.l("ink", mouth_x, mouth_y+2, mouth_x+3, mouth_y+2)
        else:
            s.r("ink", mouth_x, mouth_y, mouth_width, 3)
            s.r("white", mouth_x+1, mouth_y+1, max(1,mouth_width-2), 1)
    elif state == "ferido":
        s.r("white", x, y+1, 3, 2)
        s.r("ink", x+2, y+1, 1, 2)
        s.l("ink", x-1, y, x+3, y)
        s.l("ink", mouth_x, mouth_y+2, mouth_x+1, mouth_y+1, mouth_x+mouth_width-1, mouth_y+1)
    else:
        s.l("ink", x-1, y+1, x, y, x+2, y, x+3, y+1)
        width, height = {"king":(8,5), "squire":(4,3), "nia":(5,3), "bard":(5,5), "archer":(4,2), "intendant":(4,2), "dancer":(4,3)}[kind]
        s.p("ink", mouth_x,mouth_y, mouth_x+width-1,mouth_y-1, mouth_x+width-1,mouth_y+height-1, mouth_x+1,mouth_y+height-1)
        s.r("white", mouth_x+1, mouth_y, width-2, min(2,height-1))
    facial_layer = s.layers["face"]
    facial_layer.putalpha(ImageChops.multiply(facial_layer.getchannel("A"), skin_mask))
    if kind == "intendant":
        s.layer("permanent_moustache")
        s.p("hair_sh", mouth_x-2, mouth_y-2, mouth_x+1, mouth_y-3, mouth_x+3, mouth_y-2, mouth_x+6, mouth_y-3, mouth_x+8, mouth_y-1, mouth_x+7, mouth_y+2, mouth_x+4, mouth_y+1, mouth_x+2, mouth_y+1, mouth_x, mouth_y+2, mouth_x-2, mouth_y+1)
        s.l("hair", mouth_x-1, mouth_y-1, mouth_x+1, mouth_y-2)
        s.l("hair", mouth_x+4, mouth_y-1, mouth_x+6, mouth_y-2)


def face(s, state="calma"):
    from faces import paint
    paint(s,state,PALETTE,original_face)
