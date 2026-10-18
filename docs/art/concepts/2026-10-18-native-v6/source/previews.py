"""Presentation uses only the exported native PNGs, enlarged by whole numbers."""
import base64
import json
from PIL import Image, ImageDraw, ImageFont
from pixels import STATES

PAPER = "#f0eee7"
TEXT = "#25333d"
MUTED = "#65727b"
PLOT = "#66717e"
GOLD = "#b18747"


def font(size,bold=False):
    try:
        return ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans"+("-Bold" if bold else "")+".ttf",size)
    except OSError:
        return ImageFont.load_default(size=size)


def paste(canvas, image, x, y, zoom=1):
    im = image.convert("RGBA")
    if zoom != 1:
        im = im.resize((im.width*zoom,im.height*zoom),Image.Resampling.NEAREST)
    canvas.paste(im,(x,y),im)


def pair(root,manifest,left,right,index,title,note):
    entries = {c["id"]:c for c in manifest["characters"]}
    a,b = entries[left],entries[right]
    out = Image.new("RGB",(1200,1000),PAPER)
    d = ImageDraw.Draw(out)
    d.text((48,32),f"0{index} / {title}",font=font(31,True),fill=TEXT)
    d.text((50,82),note,font=font(17),fill=MUTED)
    d.rectangle((48,125,795,485),fill=PLOT)
    for entry,cx in ((a,254),(b,610)):
        image = Image.open(root/"sprites"/(entry["id"]+".png"))
        x = cx-entry["pivot"][0]*4
        y = 462-entry["pivot"][1]*4
        paste(out,image,x,y,4)
    d.line((72,462,770,462),fill="#465462",width=1)
    d.text((70,141),"4× / mesmo pixel, mesma linha de apoio",font=font(13),fill="#e6e6de")
    d.text((832,133),"AUTORIA NATIVA",font=font(15,True),fill=TEXT)
    for j,e in enumerate((a,b)):
        y = 168+j*72
        d.text((832,y),e["label"],font=font(17,True),fill=TEXT)
        d.text((832,y+25),f'{e["canvas"][0]} × {e["canvas"][1]} px · {e["opaque_colors"]} cores',font=font(15),fill=MUTED)
    d.text((832,327),"1× / tamanho real",font=font(14),fill=MUTED)
    d.rectangle((830,355,1152,472),fill="#d4d5cc")
    for e,x in ((a,883),(b,1040)):
        paste(out,Image.open(root/"sprites"/(e["id"]+".png")),x,459-e["pivot"][1])
    for row,e in enumerate((a,b)):
        y = 526+row*205
        d.text((50,y),e["label"].upper()+" / recorte do corpo",font=font(15,True),fill=TEXT)
        if len(e["states"]) == 1:
            d.text((50,y+52),"Visor fechado: a expressão pertence à postura.",font=font(19),fill=MUTED)
            seated = Image.open(root/"sprites"/"sombra_sentado.png")
            paste(out,seated,565,y+25,2)
        else:
            for col,st in enumerate(STATES):
                x = 50+col*184
                d.rectangle((x,y+34,x+172,y+176),fill="#d3d5cf")
                crop = Image.open(root/"heads"/(e["id"]+"_"+st+".png"))
                paste(out,crop,x+(172-crop.width*4)//2,y+38+(132-crop.height*4)//2,4)
                d.text((x,y+183),st.upper(),font=font(12),fill=MUTED)
    d.line((48,959,1152,959),fill="#c3c7c0")
    d.text((50,971),"EMPIRE / V6 · conceito para revisão · PNGs 1× + fontes por camadas",font=font(13),fill=MUTED)
    out.save(root/"previews"/(f"0{index}-"+left+"-"+right+".png"))


def overview(root,manifest):
    entries = {e["id"]:e for e in manifest["characters"]}
    out = Image.new("RGB",(1440,940),PAPER)
    d = ImageDraw.Draw(out)
    d.text((48,30),"EMPIRE / CONCEITOS NATIVOS",font=font(32,True),fill=TEXT)
    d.text((50,80),"64×64: Nia e companhias  ·  80×80: Rei, Arqueiro e Sombra  ·  ampliação comum 4×",font=font(19),fill=MUTED)
    for row,names in enumerate((("rei","nia","arqueiro","sombra"),("escudeiro","bardo","intendente","dancarina"))):
        y = 131+row*380
        for col,name in enumerate(names):
            e = entries[name]
            x = 44+col*344
            d.rectangle((x,y,x+325,y+325),fill=PLOT)
            paste(out,Image.open(root/"sprites"/(name+".png")),x+163-e["pivot"][0]*4,y+304-e["pivot"][1]*4,4)
            d.text((x,y+337),e["label"],font=font(17,True),fill=TEXT)
            d.text((x+253,y+340),f'{e["canvas"][0]}×{e["canvas"][1]}',font=font(12),fill=MUTED)
    d.text((48,917),"O pixel é igual para todos. Pranchas e rostos usam os mesmos PNGs nativos.",font=font(14),fill=MUTED)
    out.save(root/"previews"/"00-elenco-nativo.png")


def flora_board(root):
    out = Image.new("RGB",(1200,720),PAPER)
    d = ImageDraw.Draw(out)
    d.text((48,30),"05 / SOMBRA & FLORAÇÃO",font=font(32,True),fill=TEXT)
    d.text((50,81),"Peso no chão. O mesmo corpo sentado; a vegetação cresce em camadas próprias.",font=font(18),fill=MUTED)
    for index,stage in enumerate((None,0,1,2)):
        canvas = Image.new("RGBA",(144,80),PLOT)
        body = Image.open(root/"sprites"/"sombra_sentado.png").convert("RGBA")
        if stage is not None:
            canvas.alpha_composite(Image.open(root/"fx"/("flora_back_"+str(stage)+".png")).convert("RGBA"),(8,53))
        canvas.alpha_composite(body,(32,0))
        if stage is not None:
            canvas.alpha_composite(Image.open(root/"fx"/("flora_front_"+str(stage)+".png")).convert("RGBA"),(8,53))
        x = 42+(index%2)*565
        y = 134+(index//2)*272
        paste(out,canvas,x,y,3)
        d.text((x,y+244),("SENTAR","BROTAR","CRIAR BOTÕES","FLORIR")[index],font=font(15,True),fill=TEXT)
    d.text((50,692),"Estudos estáticos de repouso e crescimento; a descida e o levantar continuam por animar.",font=font(14),fill=MUTED)
    out.save(root/"previews"/"05-sombra-floracao.png")


def html_gallery(root,manifest):
    images = {}
    for e in manifest["characters"]:
        images[e["id"]] = {st:"data:image/png;base64,"+base64.b64encode((root/"expressions"/(e["id"]+"_"+st+".png")).read_bytes()).decode() for st in e["states"]}
    data = json.dumps(dict(manifest=manifest,images=images),ensure_ascii=False)
    template = (root/"source"/"gallery-template.html").read_text()
    (root/"inspecao.html").write_text(template.replace("__SPRITE_DATA__",data))


def all_previews(root,manifest):
    overview(root,manifest)
    pair(root,manifest,"rei","escudeiro",1,"REI & ESCUDEIRO","Volume da barriga, apoio do escudo e expressões dentro da cabeça real.")
    pair(root,manifest,"nia","bardo",2,"NIA & BARDO","Duas machadinhas, caracóis e prontidão; gesto musical e boca de canto.")
    pair(root,manifest,"arqueiro","intendente",3,"ARQUEIRO & INTENDENTE","Perfil comprido, arco contínuo e bigode permanente nas seis expressões.")
    pair(root,manifest,"sombra","dancarina",4,"SOMBRA & DANÇARINA","Ferro escuro e visor vazio; contraste de peso com o gesto da escudeira.")
    flora_board(root)
    html_gallery(root,manifest)
