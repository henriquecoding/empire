"""Verify review artifacts and their provenance without claiming runtime coverage."""
import hashlib
import json
import re
from pathlib import Path
from PIL import Image
from hud_study_pixels import PALETTES, Pixels, ROOT

OUT = ROOT / "tools/web/site/estudos/hud"


def contrast(a: str, b: str) -> float:
    def luminance(color: str) -> float:
        rgb = [int(color[i:i+2],16)/255 for i in (1,3,5)]
        linear = [v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4 for v in rgb]
        return sum(v*w for v,w in zip(linear,[.2126,.7152,.0722]))
    light,dark = sorted([luminance(a),luminance(b)],reverse=True)
    return (light+.05)/(dark+.05)


def main() -> None:
    manifest=json.loads((OUT/"manifest.json").read_text())
    report={"scope":"artifact checks only; no Godot interaction or physical-device certification", "images":[],"contrast":{},"sources":[]}
    for path,expected in manifest["backgrounds"].items():
        assert hashlib.sha256((ROOT/path).read_bytes()).hexdigest()==expected,path
    for name,entry in manifest["outputs"].items():
        path=OUT/name
        with Image.open(path) as image:
            image.load()
            assert list(image.size)==entry["size"],name
        assert hashlib.sha256(path.read_bytes()).hexdigest()==entry["sha256"],name
        report["images"].append(name)
    for theme,palette in PALETTES.items():
        measured={}
        for role in ["text","muted","gold","green","red","blue"]:
            value=contrast(palette[role],palette["field"])
            assert value>=4.5,(theme,role,value)
            measured[role]=round(value,2)
        p=Pixels(theme,(32,32));p.panel((0,0,32,32));p.icon(8,8,"coin")
        assert set(p.image.getchannel("A").tobytes())<={0,255}
        expanded=p.image.resize((64,64),Image.Resampling.NEAREST)
        for x in range(32):
            for y in range(32):
                expected=p.image.getpixel((x,y))
                assert all(expanded.getpixel((2*x+dx,2*y+dy))==expected for dx in (0,1) for dy in (0,1))
        report["contrast"][theme]=measured
    for page in OUT.glob("*.html"):
        for target in re.findall(r'(?:href|src)="([^"]+)"',page.read_text()):
            if not target.startswith(("https:","#")):
                assert (page.parent/target).exists(),target
    research=ROOT/"docs/ux/HUD-PIXEL-2026-10-18.md"
    body=research.read_text()
    for target in re.findall(r'\]\(([^)]+)\)',body):
        if not target.startswith(("https:","http:","#")):
            assert (research.parent/target).exists(),target
    for sid,title,url in re.findall(r'\| (S\d+) \| \[([^\]]+)\]\((https://[^)]+)\)',body):
        report["sources"].append({"id":sid,"title":title,"url":url,"consulted":"2026-10-18"})
    assert len({s["id"] for s in report["sources"]})==len(report["sources"])
    assert len(report["sources"])>=20
    target=ROOT/"docs/ux/HUD-PIXEL-2026-10-18-validation.json"
    target.write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n")
    print(f"OK: {len(report['images'])} PNGs; {len(report['sources'])} source records; provenance, links, contrast and integer expansion")


if __name__ == "__main__":
    main()
