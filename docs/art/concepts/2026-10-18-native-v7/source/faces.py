"""Facial acting authored at body resolution; each anatomy has its own marks."""
from PIL import Image, ImageColor, ImageChops


def eye(s, x, y, w=3, h=3, pupil=1):
    s.r("white", x, y, w, h)
    s.r("ink", x+w-1, y+pupil, 1, max(1, min(2, h-pupil)))


def king(s, st):
    if st == "calma":
        eye(s,48,18,4,3)
        s.l("ink",47,17,52,17)
        s.p("hair_sh",46,15,49,13,52,14,52,15,47,17)
        s.p("ink",46,24,49,25,56,24,58,23,58,27,55,29,49,28,48,26)
        s.p("white",48,25,51,26,56,25,57,25,56,27,51,27,49,26)
        s.l("skin_sh",53,30,56,30,58,28)
    elif st == "foco":
        eye(s,48,19,4,2,0)
        s.p("hair_sh",46,15,48,15,52,17,52,18,48,17)
        s.l("ink",47,18,52,18)
        s.l("ink",48,26,55,26,56,27)
    elif st == "medo":
        eye(s,48,16,4,5,2)
        s.l("hair_sh",47,14,50,13,52,14)
        s.p("ink",46,25,48,23,53,24,57,26,57,29,54,27,49,26,47,28)
        s.l("white",48,24,52,25,55,26)
    elif st == "golpe":
        s.l("ink",47,17,50,19,47,21)
        s.l("hair_sh",47,15,51,16)
        s.p("ink",48,24,55,24,57,26,57,29,51,29,49,27)
        s.p("white",50,25,54,25,55,27,51,27)
    elif st == "ferido":
        eye(s,48,20,4,2,0)
        s.l("ink",47,19,52,19)
        s.l("hair_sh",47,16,51,15)
        s.l("ink",49,28,51,26,56,27)
        s.l("skin_sh",48,23,51,24)
    else:
        s.l("ink",47,19,48,17,51,17,52,18)
        s.l("hair_sh",46,14,49,12,52,13)
        s.p("ink",46,23,50,25,57,23,59,24,58,29,54,31,50,30,48,27)
        s.p("white",48,25,51,26,57,24,57,27,53,28,50,27)


def squire(s, st):
    if st == "calma":
        eye(s,39,23,3,4,1)
        s.l("ink",38,22,40,21,42,22)
        s.r("ink",39,29,3,2)
        s.r("white",40,29,1,1)
    elif st == "foco":
        eye(s,39,24,3,2,0)
        s.l("ink",38,22,42,23)
        s.l("ink",39,30,42,30)
    elif st == "medo":
        eye(s,38,22,4,5,1)
        s.r("ink",39,28,4,4)
        s.r("white",40,28,2,1)
    elif st == "golpe":
        s.l("ink",38,23,40,25,38,26)
        s.r("ink",39,29,4,3)
        s.r("white",40,30,2,1)
    elif st == "ferido":
        eye(s,39,25,3,2,0)
        s.l("ink",38,24,42,24)
        s.l("ink",39,31,40,30,42,30)
    else:
        s.l("ink",38,24,39,23,41,23,42,24)
        s.p("ink",38,29,43,28,42,31,40,32)
        s.l("white",39,29,42,29)


def nia(s, st):
    if st == "calma":
        eye(s,38,19,3,2,0)
        s.l("blackhair",37,18,40,17,41,18)
        s.l("ink",37,25,39,26,42,25)
        s.r("white",40,25,2,1)
    elif st == "foco":
        eye(s,38,20,3,2,0)
        s.p("blackhair",37,17,41,19,41,20,37,18)
        s.l("ink",38,25,42,25)
    elif st == "medo":
        eye(s,38,18,3,4,1)
        s.l("blackhair",37,16,40,15,41,16)
        s.p("ink",38,24,42,24,42,27,40,27,39,26)
        s.r("white",39,24,2,1)
    elif st == "golpe":
        s.l("ink",37,19,40,20,38,22)
        s.l("blackhair",37,17,41,18)
        s.p("ink",37,25,41,24,42,26,41,27,38,27)
        s.l("white",38,25,40,25)
    elif st == "ferido":
        eye(s,38,21,3,2,0)
        s.l("ink",37,20,41,20)
        s.l("blackhair",37,18,40,17)
        s.l("ink",38,27,40,26,42,27)
    else:
        eye(s,38,19,3,2,0)
        s.l("blackhair",37,16,40,15,41,16)
        s.p("ink",37,24,40,25,43,23,42,27,39,28)
        s.l("white",38,25,41,25)


def archer(s, st):
    if st == "calma":
        eye(s,43,24,4,2,0)
        s.l("hair_sh",42,22,46,22)
        s.l("ink",42,32,46,32,47,31)
    elif st == "foco":
        s.r("white",44,25,3,1)
        s.r("ink",46,25,1,2)
        s.l("ink",42,23,47,24)
        s.l("ink",43,33,47,33)
    elif st == "medo":
        eye(s,43,22,4,5,1)
        s.l("hair_sh",42,21,44,20,46,21)
        s.p("ink",42,31,47,31,47,34,44,35,42,33)
        s.r("white",43,31,3,1)
    elif st == "golpe":
        s.l("ink",42,24,45,25,43,27)
        s.l("hair_sh",42,22,46,23)
        s.p("ink",42,32,46,31,47,33,46,35,43,34)
        s.l("white",43,32,45,32)
    elif st == "ferido":
        eye(s,43,26,4,2,0)
        s.l("ink",42,25,47,25)
        s.l("ink",43,34,45,33,47,33)
    else:
        eye(s,43,24,4,2,0)
        s.l("hair_sh",42,21,46,20)
        s.p("ink",42,31,45,32,48,30,47,34,44,34)
        s.l("white",43,32,46,32)


def intendant(s, st):
    if st == "calma":
        eye(s,36,25,4,2,0)
        s.p("hair_sh",35,23,37,22,40,23,40,24,35,24)
        s.l("ink",35,35,38,35,39,34)
    elif st == "foco":
        eye(s,36,26,4,1,0)
        s.p("hair_sh",35,23,40,25,40,26,35,24)
        s.l("ink",35,35,39,35)
    elif st == "medo":
        eye(s,36,24,4,4,1)
        s.l("hair_sh",35,22,38,21,40,22)
        s.r("ink",35,34,4,2)
        s.r("white",36,34,2,1)
    elif st == "golpe":
        s.l("ink",35,25,38,26,35,28)
        s.l("hair_sh",35,23,40,24)
        s.r("ink",35,34,5,2)
        s.r("white",36,35,2,1)
    elif st == "ferido":
        eye(s,36,27,4,1,0)
        s.l("ink",35,26,40,26)
        s.l("hair_sh",35,23,39,22)
        s.l("ink",35,36,37,35,39,35)
    else:
        eye(s,36,25,4,2,0)
        s.l("hair_sh",35,22,38,21,40,22)
        s.p("ink",34,34,39,34,38,36,36,37)
        s.r("white",35,34,3,1)


def bard(s, st):
    if st in ("calma", "vitoria"):
        if st == "calma":
            eye(s,36,22,3,2,0)
            s.l("ink",35,21,39,21)
        else:
            s.l("ink",35,23,36,21,38,21,39,22)
        s.p("ink",36,26,39,26,40,27,39,29,37,30,36,28)
        s.r("white",37,26,2,1)
        s.r("skin_sh",37,29,1,1)
    elif st == "foco":
        s.l("ink",35,23,39,23)
        s.l("hair_sh",35,21,38,20)
        s.r("ink",37,27,2,3)
    elif st == "medo":
        eye(s,36,21,3,4,1)
        s.l("hair_sh",35,19,38,18,39,19)
        s.r("ink",36,27,4,4)
        s.r("white",37,27,2,1)
    elif st == "golpe":
        s.l("ink",35,22,38,24,35,25)
        s.p("ink",36,28,39,27,40,29,37,30)
        s.r("white",37,28,2,1)
    else:
        eye(s,36,24,3,1,0)
        s.l("ink",35,23,39,23)
        s.l("ink",36,30,38,29,40,30)


def paint(s, state, palette, dancer_fallback):
    from finishes import materials
    materials(s)
    if s.name == "dancarina":
        dancer_fallback(s,state)
        return
    base = s.flat()
    names = ("brown_skin","brown_hi","brown_sh") if s.name == "nia" else ("skin","skin_hi","skin_sh")
    colors = {ImageColor.getrgb(palette[k]) for k in names}
    mask = Image.new("L",base.size)
    mask.putdata([255 if p[:3] in colors and p[3] else 0 for p in base.get_flattened_data()])
    s.layer("face")
    {"rei":king,"escudeiro":squire,"nia":nia,"arqueiro":archer,"intendente":intendant,"bardo":bard}[s.name](s,state)
    s.layers["face"].putalpha(ImageChops.multiply(s.layers["face"].getchannel("A"),mask))
    if s.name == "intendente":
        s.layer("permanent_moustache")
        s.p("hair_sh",33,31,35,30,38,31,40,30,43,31,43,33,41,34,38,33,36,34,33,33)
        s.l("hair",34,31,36,31,37,32)
        s.l("hair",39,31,41,31,42,32)
