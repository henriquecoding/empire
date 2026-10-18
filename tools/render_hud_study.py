"""Render review compositions on a native integer grid, without changing runtime."""
import hashlib
import json
import io
import os
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
from hud_study_pixels import Pixels, PALETTES, ROOT, FONT

OUT = ROOT / "tools/web/site/estudos/hud"
DAY = ROOT / "docs/art/scenery_native_previews/enramados_base_underground.png"
NIGHT = ROOT / "tools/web/site/img/dia-noite.webp"
UNDER = ROOT / "docs/art/scenery_native_previews/campaign_underground.png"


def save_image(im: Image.Image, path: Path) -> None:
    buffer = io.BytesIO()
    im.save(buffer, format="PNG", optimize=True)
    data = buffer.getvalue()
    Image.open(io.BytesIO(data)).load()
    temporary = path.with_suffix(".tmp")
    with temporary.open("wb") as handle:
        handle.write(data)
        handle.flush()
        os.fsync(handle.fileno())
    temporary.replace(path)


def header(p: Pixels, night: bool = False, compact: bool = False) -> None:
    p.panel((12,12,116,38))
    p.icon(21,22,"coin")
    p.text((45,19),"6 / 33",16,"gold")
    p.text((45,37),"MOEDAS/MAX.",10,"muted")
    x = 140 if compact else 244
    p.panel((x,12,146,38))
    p.icon(x+9,21,"moon" if night else "sun")
    p.text((x+32,19),"DIA 3 - " + ("NOITE" if night else "MANHÃ"),10)
    p.text((x+32,32),"PRIMAVERA",10,"muted")
    p.gauge(x+32,43,102,.6)
    width = p.image.width
    p.panel((width-72,12,28,30));p.icon(width-66,18,"scroll")
    p.panel((width-40,12,28,30));p.icon(width-34,18,"pause")


def combat(p: Pixels, recovery: bool = False, unavailable: bool = False) -> None:
    x=p.image.width-168
    p.panel((x,64,156,62))
    p.text((x+10,72),"MONARCA",10,"muted")
    p.button((x+6,87,70,32),"F", "sword")
    p.button((x+80,87,70,32),"R", "bell",disabled=unavailable)
    p.gauge(x+9,113,62,.55 if recovery else 1,"blue" if recovery else "green")
    p.gauge(x+83,113,62,0 if unavailable else 1)
    p.text((x+119,72),"2,4 S" if recovery else "PRONTO",10,"blue" if recovery else "green",True)
    if unavailable:
        p.panel((x,132,156,26));p.icon(x+7,137,"lock","muted")
        p.text((x+29,141),"MOEDAS EM FALTA",10,"muted")


def hud(theme: str, mode: str) -> Image.Image:
    p=Pixels(theme)
    bg=Image.open(NIGHT if mode=="noite" else UNDER if mode=="subsolo" else DAY)
    header(p,night=mode=="noite")
    combat(p,recovery=mode=="subsolo",unavailable=mode=="noite")
    if mode=="dia":
        p.panel((220,64,200,37))
        p.text((320,72),"OFICINA DO REINO",10,center=True)
        p.text((320,86),"[E] VER CONDIÇÕES",10,"gold",True)
    if mode=="noite":
        p.panel((244,58,146,27));p.icon(252,63,"shield","red")
        p.text((275,68),"VIGIA NOTURNA",10,"red")
    if mode=="subsolo":
        p.panel((244,58,146,27));p.icon(252,63,"arrow","blue")
        p.text((275,68),"SUBSOLO",10,"blue")
    return p.composite(bg)


def menu(theme: str, sheet: bool = False) -> Image.Image:
    p=Pixels(theme)
    # Integer alpha veil is an explicit modal layer, not blurred game artwork.
    p.image.paste((18,23,27,165),(0,0,640,360))
    if not sheet:
        p.panel((174,42,292,278))
        p.d.rectangle((184,51,456,83),fill=p.p["cloth"])
        p.icon(197,58,"crown");p.text((320,59),"REINO EM PAUSA",12,center=True)
        p.text((320,92),"O TEMPO ESTÁ PARADO",10,"muted",True)
        p.rule(194,109,252)
        rows=[("CONTINUAR","arrow"),("ESTADO DO REINO","scroll"),("OPÇÕES","shield"),("ECRÃ INTEIRO","sun"),("VOLTAR AO INÍCIO","crown")]
        for i,(label,icon) in enumerate(rows):
            p.button((194,120+i*32,252,28),label,icon,focus=i==0)
        p.text((320,295),"[ESC] VOLTAR",10,"muted",True)
    else:
        p.panel((380,56,248,272))
        p.text((395,71),"FUNDAR NESTE LOCAL",12)
        p.text((395,91),"FICHA DO SÍTIO",10,"muted")
        p.rule(394,108,219)
        rows=[("check","SEDE CABE AQUI","green"),("coin","FUNDAR NÃO GASTA MOEDAS","gold"),("check","CLAREIRA: VER O QUE FICA","text"),("scroll","FONTES E ALCANCES REAIS","text")]
        for i,(icon,label,color) in enumerate(rows):
            yy=122+i*29;p.icon(394,yy,icon,color);p.text((416,yy+4),label,10,color)
        p.text((395,246),"ABRIR A FICHA NÃO FUNDA.",10,"muted")
        p.text((395,260),"CONFIRMAR REVALIDA O LOCAL.",10,"muted")
        p.button((394,281,104,30),"VOLTAR",focus=True)
        p.button((504,281,110,30),"FUNDAR")
    return p.composite(Image.open(UNDER if sheet else DAY))


def touch(theme: str) -> Image.Image:
    # Crop existing pixels; do not resample a 1280-wide screenshot fractionally.
    bg=Image.open(DAY).crop((218,330,1062,720))
    p=Pixels(theme,(422,195))
    header(p,compact=True)
    p.panel((138,58,148,28));p.text((212,68),"TOQUE: CONDIÇÕES",10,center=True)
    for x,y,kind,label in [(22,134,"arrow","ANDAR"),(90,144,"boot","CORRER"),(294,144,"coin","MOEDA"),(328,110,"hand","AÇÃO"),(362,144,"sword","ATAQUE"),(362,76,"bell","VIGÍLIA")]:
        p.panel((x,y,26,26));p.icon(x+5,y+5,kind)
        p.text((x+13,y+30),label,10,"text",True)
    p.panel((18,97,46,24));p.text((41,105),"FIXAR",10,center=True)
    p.d.ellipse((14,126,67,179),fill=p.p["ink"],outline=p.p["edge"],width=2)
    p.panel((29,141,24,24));p.icon(33,145,"arrow")
    p.text((41,182),"ANDAR",10,center=True)
    return p.composite(bg)


def states(theme: str) -> Image.Image:
    p=Pixels(theme,(640,176))
    p.image.paste(p.p["ink"],(0,0,640,176))
    p.text((16,14),"GRAMÁTICA DE ESTADOS",12)
    labels=["NORMAL","FOCO","PREMIDO","RECARGA","BLOQUEADO","SEM MOEDAS"]
    for i,label in enumerate(labels):
        x=16+i*103
        p.button((x,44,92,44),"R","bell",focus=i==1,disabled=i in (4,5))
        if i==2:
            p.d.rectangle((x+4,48,x+87,82),fill=p.p["cloth"]);p.icon(x+12,59,"bell");p.text((x+44,64),"R")
        if i==3:p.gauge(x+7,79,78,.5,"blue")
        if i==4:p.icon(x+66,58,"lock","muted")
        if i==5:p.icon(x+66,58,"cross","red")
        p.text((x+46,96),label,10,"muted",True)
        if i==3:p.text((x+46,112),"2,4 S",10,"blue",True)
    p.rule(16,134,606)
    for i,k in enumerate(["coin","crown","sun","moon","sword","shield","bell","hand","boot","lock","scroll","arrow"]):
        p.icon(24+i*38,147,k)
    p.text((490,152),"ÍCONES 16 X 16",10,"muted")
    return p.image.convert("RGB").resize((1280,352),Image.Resampling.NEAREST)


def main() -> None:
    OUT.mkdir(parents=True,exist_ok=True)
    manifest={"status":"propostas para aprovacao; composicoes, nao capturas de implementacao", "base_commit":"0c351775e2c569e83fc746ca339202753cd203ae", "ui_grid":[640,360],"ui_scale":2,"font":"src/ui/fonts/silkscreen.ttf (OFL)","backgrounds":{},"outputs":{}}
    for src in [DAY,NIGHT,UNDER]:
        manifest["backgrounds"][str(src.relative_to(ROOT))]=hashlib.sha256(src.read_bytes()).hexdigest()
    for theme in PALETTES:
        for mode in ["dia","noite","subsolo"]:
            save_image(hud(theme,mode),OUT/f"{theme}-{mode}.png")
        save_image(menu(theme),OUT/f"{theme}-pausa.png")
        save_image(menu(theme,True),OUT/f"{theme}-fundacao.png")
        save_image(touch(theme),OUT/f"{theme}-toque.png")
        save_image(states(theme),OUT/f"{theme}-estados.png")
    # Two full-resolution screens and their state strips: nothing is shrunk to fit a board.
    board=Image.new("RGB",(1280,2256),"#10181e")
    d=ImageDraw.Draw(board);d.fontmode="1"
    font=ImageFont.truetype(str(FONT),24)
    for theme,y,title in [("oficina",0,"01  OFICINA DO REINO"),("vigilia",1128,"03  VIGÍLIA DA FRONTEIRA")]:
        d.text((24,y+17),title,font=font,fill="#fff0d2")
        board.paste(Image.open(OUT/f"{theme}-dia.png"),(0,y+56))
        board.paste(Image.open(OUT/f"{theme}-estados.png"),(0,y+776))
    save_image(board,OUT/"comparacao.png")
    for path in sorted(OUT.glob("*.png")):
        im=Image.open(path)
        manifest["outputs"][path.name]={"size":list(im.size),"sha256":hashlib.sha256(path.read_bytes()).hexdigest()}
    (OUT/"manifest.json").write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+"\n")
    print(f"Rendered {len(manifest['outputs'])} review images in {OUT}")


if __name__ == "__main__":
    main()
