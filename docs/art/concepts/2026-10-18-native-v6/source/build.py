"""Run from any folder: python3 source/build.py. Rebuilds the native concept pack."""
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageColor
from pixels import PALETTE, STATES
from royals import king, nia, archer
from companions import squire, intendant, bard, dancer
from shadow import shadow, flowers
from ase import write

ROOT = Path(__file__).resolve().parent.parent
MODELS = (king, squire, nia, bard, archer, intendant, shadow, dancer)
RGB = [ImageColor.getrgb(h) for h in PALETTE.values()]
COLOR_INDEX = {rgb:i+1 for i,rgb in enumerate(RGB)}


def save(image, path):
    """Exact color-index assignment. No palette approximation or resampling."""
    image = image.convert("RGBA")
    out = Image.new("P", image.size)
    table = [(0,0,0)]+RGB
    out.putpalette([v for rgb in table for v in rgb]+[0]*(768-3*len(table)))
    out.putdata([COLOR_INDEX[p[:3]] if p[3] else 0 for p in image.get_flattened_data()])
    out.info["transparency"] = 0
    path.parent.mkdir(parents=True,exist_ok=True)
    out.save(path, transparency=0, optimize=False)


def build():
    for folder in ("sprites", "expressions", "heads", "diagnostics", "aseprite", "fx", "previews"):
        (ROOT/folder).mkdir(exist_ok=True)
    entries = []
    operations = {}
    for model in MODELS:
        s = model()
        states = STATES if s.face_spec else ("calma",)
        frames = [model(st) for st in states]
        image = s.flat()
        save(image,ROOT/"sprites"/(s.name+".png"))
        used = sorted({p[:3] for p in image.get_flattened_data() if p[3]})
        bbox = image.getbbox()
        entry = dict(id=s.name,label=s.label,canvas=[s.size,s.size],pivot=list(s.pivot),
                     bounds=list(bbox),useful_width=bbox[2]-bbox[0],useful_height=bbox[3]-bbox[1],
                     head_crop=list(s.head),head_size=[s.head[2]-s.head[0],s.head[3]-s.head[1]],
                     opaque_colors=len(used),states=list(states),pixel_pitch=1,
                     source="aseprite/"+s.name+".aseprite",status="concept_for_author_review")
        entries.append(entry)
        operations[s.name] = dict(normal=s.operations,expressions={})
        for st,frame in zip(states,frames):
            body = frame.flat()
            save(body,ROOT/"expressions"/(s.name+"_"+st+".png"))
            save(body.crop(s.head),ROOT/"heads"/(s.name+"_"+st+".png"))
            operations[s.name]["expressions"][st] = [op for op in frame.operations if op[0] in ("face","permanent_moustache")]
        write(ROOT/"aseprite"/(s.name+".aseprite"),frames,states,(s.size,s.size))
        mask = Image.new("RGBA",image.size)
        mask.putdata([(0,0,0,255) if p[3] else (0,0,0,0) for p in image.get_flattened_data()])
        mask.save(ROOT/"diagnostics"/(s.name+"_silhouette.png"))
        gray = image.convert("L").convert("RGBA")
        gray.putalpha(image.getchannel("A"))
        gray.save(ROOT/"diagnostics"/(s.name+"_values.png"))
    seated = shadow(seated=True)
    save(seated.flat(),ROOT/"sprites"/"sombra_sentado.png")
    write(ROOT/"aseprite"/"sombra_sentado.aseprite",[seated],["sentado"],(80,80))
    operations["sombra_sentado"] = dict(normal=seated.operations)
    effects = []
    for stage in range(3):
        b,f = flowers(stage)
        for s in (b,f):
            image = s.flat().crop((0,0,128,24))
            path = "fx/"+s.name+"_"+str(stage)+".png"
            save(image,ROOT/path)
            effects.append(dict(path=path,canvas=[128,24],pivot=[64,23],stage=stage,
                                layer="back" if s is b else "front"))
    write(ROOT/"aseprite"/"flora_back.aseprite",[flowers(i)[0] for i in range(3)],
          ["brotos","botoes","flores"],(128,24))
    write(ROOT/"aseprite"/"flora_front.aseprite",[flowers(i)[1] for i in range(3)],
          ["brotos","botoes","flores"],(128,24))
    manifest = dict(version=6,authored_at="2026-10-18",status="concepts_not_runtime_assets",
                    method="integer_authored_clusters_no_image_resampling",palette=PALETTE,
                    source_base="8915b8b06db97d51e1163a64910a00769b63503e",characters=entries,
                    seated=dict(path="sprites/sombra_sentado.png",canvas=[80,80],pivot=[40,76]),
                    effects=effects,animation_cycles_delivered=False,runtime_integration=False)
    (ROOT/"manifest.json").write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+"\n")
    (ROOT/"source"/"integer-clusters.json").write_text(json.dumps(operations,ensure_ascii=False,separators=(",",":"))+"\n")
    (ROOT/"source"/"palette.json").write_text(json.dumps(PALETTE,indent=2)+"\n")
    from previews import all_previews
    all_previews(ROOT,manifest)
    return manifest


if __name__ == "__main__":
    manifest = build()
    from verify import verify
    verify(ROOT,manifest)
    paths = sorted(p for p in ROOT.rglob("*") if p.is_file() and p.suffix not in (".pyc",) and p.name != "CHECKSUMS.sha256")
    (ROOT/"CHECKSUMS.sha256").write_text("".join(hashlib.sha256(p.read_bytes()).hexdigest()+"  "+p.relative_to(ROOT).as_posix()+"\n" for p in paths))
    print("8 native character concepts; 42 facial variants; 1 seated pose; 6 flora layers. Integrity verified.")
