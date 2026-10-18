"""The closed helmet acts through posture. Flora is authored on separate grids."""
from pixels import Sprite


def head(s, x, y):
    s.layer("helmet")
    s.p("ink", x,y, x+9,y-2, x+14,y+2, x+13,y+14, x+8,y+20, x+2,y+16, x-1,y+8)
    s.p("iron", x+1,y+1, x+9,y, x+12,y+3, x+11,y+13, x+8,y+17, x+3,y+14, x+1,y+8)
    s.p("iron_hi", x+2,y+2, x+8,y+1, x+10,y+3, x+7,y+5, x+2,y+4)
    s.p("ink", x+1,y+5, x+6,y+7, x+12,y+5, x+11,y+8, x+9,y+9, x+8,y+17, x+7,y+15, x+6,y+9, x+2,y+8)
    s.l("iron", x+2,y+4, x+6,y+5, x+11,y+4)
    s.layer("crown")
    s.p("ink", x+1,y, x-1,y-7, x+2,y-6, x+4,y-3, x+7,y-10, x+9,y-9, x+10,y-3, x+14,y-6, x+13,y+1, x+7,y+3)
    s.p("gold_sh", x+2,y, x+1,y-5, x+4,y-2, x+7,y-8, x+8,y-8, x+9,y-1, x+12,y-4, x+12,y, x+7,y+1)
    s.l("cream_sh", x+7,y-6, x+8,y-1)


def shadow(state="calma", seated=False):
    s = Sprite("sombra_sentado" if seated else "sombra", "Imperador sombrio", 80, (40,76), (37,2,55,33) if not seated else (37,22,55,53))
    s.layer("cape_back")
    if seated:
        s.p("ink", 26,37, 50,35, 61,45, 67,68, 71,74, 8,75, 12,69, 18,47)
        s.p("wine_sh", 27,39, 49,37, 59,46, 65,69, 68,73, 12,73, 15,68, 20,47)
        s.p("wine", 25,42, 29,41, 24,57, 22,67, 17,71, 15,71, 19,54)
    else:
        s.p("ink", 25,20, 44,17, 57,24, 63,43, 65,64, 72,72, 71,75, 7,75, 12,70, 15,49, 17,32)
        s.p("wine_sh", 26,22, 44,19, 55,25, 61,44, 63,66, 69,72, 67,73, 10,73, 14,68, 17,49, 19,32)
        s.p("wine", 25,25, 32,24, 24,44, 23,64, 17,70, 12,72, 17,65, 19,45)
        s.l("wine", 55,35, 57,54, 61,69, 65,72)
    s.layer("legs")
    if seated:
        s.p("ink", 26,55, 36,54, 43,63, 51,55, 61,57, 67,69, 65,74, 52,75, 43,72, 34,75, 19,74, 17,68, 20,60)
        s.p("iron_sh", 26,57, 34,56, 40,63, 36,69, 32,72, 22,72, 19,68, 22,61)
        s.p("iron", 25,58, 30,56, 35,58, 37,61, 30,64, 21,64)
        s.l("iron_hi", 23,61, 27,58, 31,58)
        s.p("iron_sh", 52,58, 59,59, 65,69, 63,72, 54,73, 46,70, 46,64)
        s.p("iron", 52,59, 57,59, 60,63, 53,65, 47,64)
        s.p("ink", 21,65, 30,64, 35,69, 35,75, 20,75, 17,71)
        s.p("iron", 22,66, 28,66, 33,70, 33,73, 21,73, 19,70)
        s.p("iron_sh", 24,69, 29,68, 32,71, 32,73, 22,73)
        s.l("iron_hi", 21,68, 23,67, 27,67)
        s.p("ink", 53,66, 60,65, 66,69, 67,75, 51,75, 49,71)
        s.p("iron", 54,67, 59,67, 64,70, 65,73, 53,73, 51,70)
        s.p("iron_sh", 57,69, 60,69, 63,71, 64,73, 54,73)
        s.l("iron_hi", 53,69, 55,68, 58,68)
    else:
        s.p("ink", 31,48, 54,48, 58,55, 57,66, 63,72, 63,75, 46,75, 44,66, 42,58, 38,65, 36,74, 22,75, 24,67, 27,59)
        s.p("iron_sh", 32,50, 42,52, 39,59, 35,65, 34,71, 26,71, 27,65, 29,59)
        s.p("iron", 30,58, 34,53, 39,54, 36,59, 29,64)
        s.l("iron_hi", 30,59, 34,55, 37,55)
        s.p("iron_sh", 45,51, 53,50, 56,56, 54,65, 57,71, 48,71, 47,65)
        s.p("iron", 46,55, 51,53, 54,57, 52,62, 47,62)
        s.l("iron_hi", 47,56, 50,55, 52,57)
        s.p("ink", 25,68, 34,68, 37,72, 37,75, 21,75, 22,72)
        s.p("iron", 26,69, 32,69, 35,73, 23,73)
        s.p("iron_sh", 29,71, 33,71, 35,73, 26,73)
        s.p("ink", 47,68, 55,68, 56,71, 63,72, 65,75, 45,75)
        s.p("iron", 48,69, 54,69, 55,72, 62,73, 47,73)
        s.l("iron_hi", 49,70, 53,70)
    dy = 20 if seated else 0
    s.layer("breastplate")
    dy = 18 if seated else 0
    s.p("ink", 32,25+dy, 47,24+dy, 55,32+dy, 52,44+dy, 56,51+dy, 46,56+dy, 35,54+dy, 30,48+dy, 33,39+dy)
    s.p("iron_sh", 34,27+dy, 46,26+dy, 53,33+dy, 50,44+dy, 53,50+dy, 46,53+dy, 36,52+dy, 32,48+dy, 35,39+dy)
    s.p("iron", 34,28+dy, 40,27+dy, 41,34+dy, 37,41+dy, 34,39+dy)
    s.l("iron_hi", 35,29+dy, 39,28+dy)
    s.p("wine_sh", 39,34+dy, 47,33+dy, 48,44+dy, 50,52+dy, 44,55+dy, 39,51+dy)
    s.p("wine", 40,35+dy, 43,36+dy, 43,48+dy, 46,52+dy, 43,52+dy, 40,49+dy)
    s.l("gold_sh", 44,39+dy, 44,46+dy)
    s.l("gold_sh", 42,41+dy, 46,41+dy)
    s.layer("shoulders")
    dy = 20 if seated else 0
    s.p("ink", 19,22+dy, 27,16+dy, 35,18+dy, 40,27+dy, 33,34+dy, 19,33+dy, 14,30+dy)
    s.p("iron", 20,23+dy, 28,18+dy, 34,20+dy, 38,27+dy, 32,32+dy, 20,31+dy, 17,29+dy)
    s.p("iron_sh", 30,20+dy, 34,21+dy, 37,27+dy, 32,31+dy, 29,29+dy)
    s.l("iron_hi", 19,27+dy, 22,23+dy, 28,19+dy, 31,20+dy)
    s.l("gold_sh", 18,30+dy, 25,30+dy, 32,33+dy)
    s.p("ink", 51,23+dy, 58,24+dy, 65,31+dy, 64,38+dy, 57,39+dy, 51,33+dy)
    s.p("iron", 53,25+dy, 58,26+dy, 63,32+dy, 62,36+dy, 58,37+dy, 53,32+dy)
    s.l("iron_hi", 55,26+dy, 58,27+dy, 61,31+dy)
    s.layer("arms")
    if seated:
        s.p("ink", 20,51, 27,50, 31,55, 30,62, 23,65, 18,61, 17,57)
        s.p("iron", 21,52, 26,52, 29,56, 28,61, 23,63, 20,60, 19,57)
        s.p("ink", 53,55, 60,56, 64,61, 61,66, 54,65, 51,61)
        s.p("iron", 54,57, 59,58, 62,61, 60,64, 55,63, 53,60)
        s.l("iron_sh", 22,59, 23,62)
        s.l("iron_sh", 25,58, 26,61)
        s.l("iron_sh", 56,60, 56,63)
        s.l("iron_sh", 59,60, 59,64)
    else:
        s.p("ink", 20,32, 29,33, 30,40, 27,44, 30,49, 27,54, 20,54, 16,50, 17,43, 15,39)
        s.p("iron_sh", 21,34, 27,35, 28,39, 25,44, 27,49, 25,52, 21,52, 18,49, 19,43, 17,39)
        s.p("iron", 20,35, 24,35, 23,40, 19,43, 18,39)
        s.l("iron_hi", 19,36, 22,35)
        s.l("gold_sh", 19,44, 25,44)
        s.l("iron", 20,47, 20,50)
        s.l("iron", 23,47, 23,51)
        s.p("ink", 57,37, 64,36, 67,43, 65,47, 68,51, 65,57, 58,56, 55,52, 56,46, 54,43)
        s.p("iron_sh", 58,39, 63,38, 65,43, 63,47, 66,51, 64,55, 59,54, 57,51, 58,46, 56,43)
        s.l("iron", 59,40, 62,39, 63,43, 61,45)
        s.l("gold_sh", 58,47, 63,47)
        s.l("iron", 60,51, 60,54)
        s.l("iron", 63,51, 63,54)
    head(s, 39, 12+dy)
    from finishes import armor
    armor(s,seated)
    return s


def flowers(stage=2):
    """Five authored masses with gaps at the emperor's boots, never a seat."""
    back, front = Sprite("flora_back", "Flora traseira", 128, (64,23), None), Sprite("flora_front", "Flora frontal", 128, (64,23), None)
    for s in (back,front):
        for layer in ("low_masses", "foliage", "flowers"):
            s.layer(layer)
    stems = [(9,16),(14,11),(19,14),(24,7),(28,12),(34,16),(41,10),(46,14),(82,12),(87,7),(93,13),(99,9),(105,15),(112,11),(118,16)]
    if stage:
        back.layer("low_masses")
        back.p("leaf_sh", 4,22, 5,19, 9,20, 12,16, 16,18, 20,16, 22,12, 25,16, 30,16, 32,19, 36,18, 40,20, 43,16, 48,19, 49,22)
        back.p("leaf_sh", 77,22, 80,18, 84,19, 87,14, 90,17, 94,17, 96,19, 100,16, 104,18, 108,17, 112,15, 116,18, 120,19, 123,22)
        back.p("leaf", 5,22, 9,20, 12,20, 15,18, 19,20, 23,18, 27,19, 32,20, 34,22)
        back.p("leaf", 79,22, 83,20, 87,19, 90,21, 95,20, 100,21, 104,19, 108,21, 113,19, 120,21, 122,22)
    for i, (x,y) in enumerate(stems):
        s = back if i % 3 else front
        s.layer("foliage")
        top = 19 if stage == 0 else (y+3 if stage == 1 else y)
        s.l("leaf_sh", x,22, x,top)
        s.p("leaf", x,21, x-4,18, x-4,16, x-1,17, x+1,21, x+3,17, x+5,16, x+5,18, x+2,21)
        s.l("leaf_hi", x-3,17, x-1,19)
        if stage:
            s.layer("flowers")
            a,b = ("pink", "pink_hi") if i % 5 in (0,1) else (("lavender", "lavender_hi") if i % 5 == 2 else ("cream", "cream_hi"))
            if stage == 1:
                s.r(a,x-1,top,2,2)
            else:
                if i % 5 == 2:
                    s.p(a, x-2,top-1, x-1,top-2, x+1,top-2, x+2,top, x+1,top+2, x-2,top+1)
                    s.r(b,x-1,top-1,2,1)
                    s.r(a,x+2,top+3,2,2)
                elif i % 5 in (0,1):
                    s.p(a, x-2,top-2, x,top-1, x+2,top-2, x+3,top, x+1,top+2, x-1,top+2, x-3,top)
                    s.l(b,x-2,top-1,x,top)
                else:
                    s.p(a, x-1,top-2, x+1,top-2, x+1,top-1, x+3,top-1, x+3,top+1, x+1,top+1, x+1,top+3, x-1,top+3, x-1,top+1, x-3,top+1, x-3,top-1, x-1,top-1)
                    s.l(b,x-1,top-1,x+1,top-1)
                s.r("gold",x,top,1,1)
    return back, front
