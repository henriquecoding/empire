"""Native raster primitives for the review study; never imported by the game."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
FONT = ROOT / "src/ui/fonts/silkscreen.ttf"
PALETTES = {
    "oficina": dict(ink="#191b20", field="#292722", edge="#78543c", light="#b18a57", gold="#eac578", text="#fff0d2", muted="#cfbb98", green="#a7d7ac", red="#f3a191", blue="#b0d4dc", cloth="#3a5246"),
    "vigilia": dict(ink="#121b23", field="#202b32", edge="#62787e", light="#a2b2ae", gold="#eac578", text="#fff0d2", muted="#c2c9bf", green="#a7d7ac", red="#f3a191", blue="#b0d4dc", cloth="#29483f"),
}


class Pixels:
    def __init__(self, theme: str, size: tuple[int, int] = (640, 360)) -> None:
        self.image = Image.new("RGBA", size)
        self.d = ImageDraw.Draw(self.image)
        self.d.fontmode = "1"
        self.p = PALETTES[theme]
        self.theme = theme

    def text(self, xy: tuple[int, int], s: str, size: int = 10, color: str = "text", center: bool = False) -> None:
        font = ImageFont.truetype(str(FONT), size)
        x, y = xy
        width = self.d.textlength(s, font=font)
        if center:
            x -= int(width // 2)
        self.d.text((x, y), s, font=font, fill=self.p.get(color, color), anchor="lt")

    def panel(self, box: tuple[int, int, int, int], paper: bool = False, focus: bool = False) -> None:
        x, y, w, h = box
        def cut(inset: int, color: str) -> None:
            a, b, c, e = x + inset, y + inset, x + w - 1 - inset, y + h - 1 - inset
            self.d.polygon([(a+3,b),(c-3,b),(c,b+3),(c,e-3),(c-3,e),(a+3,e),(a,e-3),(a,b+3)], fill=color)
        cut(0, self.p["ink"])
        cut(1, self.p["gold"] if focus else self.p["edge"])
        cut(2, self.p["light"])
        cut(3, "#e5d2a6" if paper else self.p["field"])
        self.d.line((x+5,y+h-4,x+w-6,y+h-4), fill=self.p["ink"])
        if self.theme == "oficina":
            for sx in range(x+10, x+w-9, 12):
                self.d.line((sx,y+4,sx+2,y+4),fill=self.p["light"])
            for yy, xx, length in [(y+2,x+12,12),(y+h-3,x+w-32,14)]:
                self.d.line((xx,yy,xx+length,yy),fill=self.p["gold"])
        else:
            for sx, sy in [(x+4,y+4),(x+w-6,y+4),(x+4,y+h-6),(x+w-6,y+h-6)]:
                self.d.rectangle((sx,sy,sx+1,sy+1),fill=self.p["light"])
                self.d.point((sx,sy),fill=self.p["text"])

    def rule(self, x: int, y: int, w: int) -> None:
        self.d.line((x,y,x+w,y),fill=self.p["edge"])
        self.d.rectangle((x+w//2-1,y-1,x+w//2+1,y+1),fill=self.p["gold"])

    def icon(self, x: int, y: int, kind: str, color: str = "gold") -> None:
        c, hi, dark = self.p.get(color,color), self.p["text"], self.p["ink"]
        def r(a: int,b: int,w: int,h: int,fill: str = c) -> None:
            self.d.rectangle((x+a,y+b,x+a+w-1,y+b+h-1),fill=fill)
        def line(points: list[tuple[int,int]], fill: str = c, width: int = 1) -> None:
            self.d.line([(x+a,y+b) for a,b in points],fill=fill,width=width)
        if kind == "coin":
            self.d.polygon([(x+5,y+1),(x+10,y+1),(x+13,y+4),(x+13,y+11),(x+10,y+14),(x+5,y+14),(x+2,y+11),(x+2,y+4)],fill=dark)
            self.d.polygon([(x+5,y+2),(x+10,y+2),(x+12,y+5),(x+12,y+10),(x+10,y+12),(x+5,y+12),(x+3,y+10),(x+3,y+5)],fill=c)
            line([(5,3),(9,3),(10,4)],hi);r(6,5,3,5,self.p["edge"]);r(7,5,1,4,hi)
        elif kind == "crown":
            self.d.polygon([(x+2,y+4),(x+5,y+7),(x+8,y+2),(x+11,y+7),(x+14,y+4),(x+12,y+12),(x+4,y+12)],fill=c)
            r(4,13,9,2);r(5,9,1,2,hi);r(8,8,1,2,hi);r(11,9,1,2,hi)
        elif kind == "sword":
            line([(4,12),(13,3)],dark,5);line([(5,11),(13,3)],c,3);line([(6,10),(13,3)],hi)
            line([(2,9),(7,14)],self.p["gold"],2);line([(2,14),(5,11)],self.p["edge"],2)
        elif kind == "moon":
            self.d.ellipse((x+1,y+1,x+14,y+14),fill=c)
            self.d.ellipse((x+6,y-1,x+17,y+10),fill=self.p["field"])
            r(12,2,1,3,hi);r(11,3,3,1,hi)
        elif kind == "sun":
            self.d.ellipse((x+4,y+4,x+11,y+11),fill=c)
            for a,b,w,h in [(7,0,2,3),(7,13,2,3),(0,7,3,2),(13,7,3,2),(2,2,2,2),(12,12,2,2),(2,12,2,2),(12,2,2,2)]:
                r(a,b,w,h)
        elif kind == "shield":
            self.d.polygon([(x+2,y+2),(x+13,y+2),(x+13,y+9),(x+8,y+15),(x+2,y+9)],fill=c)
            self.d.polygon([(x+4,y+4),(x+11,y+4),(x+11,y+8),(x+8,y+12),(x+4,y+8)],fill=self.p["cloth"])
            r(7,4,2,8,hi)
        elif kind == "bell":
            r(6,1,4,2);r(4,4,8,7);r(2,11,12,2);r(7,14,2,1,hi);r(5,5,1,4,hi)
        elif kind == "scroll":
            r(3,2,10,12);r(2,1,10,2,hi);r(4,5,6,1,dark);r(4,8,6,1,dark);r(4,11,4,1,dark)
        elif kind == "pause":
            r(4,3,3,10);r(10,3,3,10)
        elif kind == "hand":
            r(7,1,2,8);r(4,4,2,6);r(10,4,2,6);r(2,7,2,4);r(4,8,8,6);r(6,13,5,2);r(7,2,1,6,hi)
        elif kind == "boot":
            r(4,2,6,8);r(5,9,9,4);r(3,13,11,2);r(5,3,2,6,hi)
        elif kind == "lock":
            r(4,1,8,2);r(3,3,2,5);r(11,3,2,5);r(2,7,12,8);r(7,10,2,3,dark)
        elif kind == "check":
            line([(2,8),(6,12),(14,3)],c,2)
        elif kind == "cross":
            line([(3,3),(12,12)],c,2);line([(12,3),(3,12)],c,2)
        elif kind == "arrow":
            line([(2,7),(14,7)],c,2);line([(10,3),(14,7),(10,11)],c,2)
        else:
            raise ValueError(kind)

    def button(self, box: tuple[int,int,int,int], label: str, kind: str | None = None, focus: bool = False, disabled: bool = False) -> None:
        x,y,w,h = box
        self.panel(box,focus=focus)
        color = "muted" if disabled else "text"
        if kind:
            self.icon(x+8,y+(h-16)//2,kind,color)
            self.text((x+30,y+(h-7)//2),label,color=color)
        else:
            self.text((x+w//2,y+(h-7)//2),label,color=color,center=True)

    def gauge(self, x: int, y: int, w: int, ratio: float, color: str = "gold") -> None:
        self.d.rectangle((x,y,x+w-1,y+3),fill=self.p["ink"])
        self.d.rectangle((x+1,y+1,x+max(1,int((w-2)*ratio)),y+2),fill=self.p[color])

    def composite(self, background: Image.Image) -> Image.Image:
        layer = self.image.resize((self.image.width*2,self.image.height*2),Image.Resampling.NEAREST)
        return Image.alpha_composite(background.convert("RGBA"),layer).convert("RGB")
