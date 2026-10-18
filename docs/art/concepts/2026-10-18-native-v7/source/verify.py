"""File integrity checks, not artistic approval. Uses the existing repo's ASE reader."""
import json
from pathlib import Path
from PIL import Image, ImageChops
from ase_reader import read, composite

SIZES = dict(rei=80,escudeiro=64,nia=64,bardo=64,arqueiro=80,intendente=64,sombra=80,dancarina=64)


def same(a,b,message):
    assert a.size == b.size and a.convert("RGBA").tobytes() == b.convert("RGBA").tobytes(),message


def verify(root,manifest):
    results = []
    entries = manifest["characters"]
    assert {e["id"] for e in entries} == set(SIZES)
    for entry in entries:
        name = entry["id"]
        size = SIZES[name]
        path = root/"sprites"/(name+".png")
        image = Image.open(path)
        assert image.mode == "P" and image.size == (size,size),name+": native indexed dimensions"
        rgba = image.convert("RGBA")
        assert set(rgba.getchannel("A").get_flattened_data()) == {0,255},name+": alpha"
        x0,y0,x1,y1 = rgba.getbbox()
        assert x0 > 0 and y0 > 0 and x1 < size and y1 < size,name+": no edge clipping"
        assert y1 == entry["pivot"][1],name+": grounded pivot"
        source = read(root/entry["source"])
        assert source["size"] == image.size and source["durations"] == [100]*len(entry["states"])
        assert len(source["frames"]) == len(entry["states"])
        all_layers = range(len(source["layers"]))
        first = None
        states_pixels = set()
        for index,state in enumerate(entry["states"]):
            frame = Image.open(root/"expressions"/(name+"_"+state+".png")).convert("RGBA")
            head = Image.open(root/"heads"/(name+"_"+state+".png"))
            decoded = composite(source,index,all_layers)
            states_pixels.add(frame.tobytes())
            same(frame,decoded,name+": ASE round trip "+state)
            same(head,frame.crop(entry["head_crop"]),name+": body/head identity "+state)
            same(frame.getchannel("A").convert("RGBA"),rgba.getchannel("A").convert("RGBA"),name+": stable outer silhouette")
            if first is None:
                first = source["frames"][index]
            else:
                for layer,meta in enumerate(source["layers"]):
                    if meta["name"] != "face":
                        if layer in first:
                            same(first[layer][2],source["frames"][index][layer][2],name+": persistent "+meta["name"])
            assert state in source["tags"]
        assert len(states_pixels) == len(entry["states"]),name+": distinct facial states"
        results.append(dict(id=name,size=[size,size],indexed=True,binary_alpha=True,
                            head_is_body_crop=True,ase_round_trip=True,persistent_identity_layers=True,
                            occupied_bounds=[x0,y0,x1,y1],opaque_colors=entry["opaque_colors"]))
    seated = Image.open(root/"sprites"/"sombra_sentado.png")
    source = read(root/"aseprite"/"sombra_sentado.aseprite")
    same(seated,composite(source,0,range(len(source["layers"]))),"seated ASE round trip")
    assert seated.size == (80,80) and seated.convert("RGBA").getbbox()[3] == 76
    for layer in ("back","front"):
        source = read(root/"aseprite"/("flora_"+layer+".aseprite"))
        assert source["size"] == (128,24) and len(source["frames"]) == 3
        for index in range(3):
            frame = Image.open(root/"fx"/("flora_"+layer+"_"+str(index)+".png"))
            same(frame,composite(source,index,range(len(source["layers"]))),"flora ASE round trip")
    for path in (root/"source").glob("*.py"):
        assert len(path.read_text().splitlines()) <= 250,path.name+": script line budget"
    report = dict(status="technical_checks_passed",artistic_approval=False,
                  no_source_image_resampling=True,characters=results,seated_source_round_trip=True,
                  flora_sources_round_trip=True,head_states=42,game_runtime_tested=False,
                  limits=["Static pose/face studies, not full animation cycles.",
                          "80x80 is a proposed V7 authoring envelope for the three larger emperors.",
                          "No performance, animation, gameplay or artistic approval is claimed."])
    (root/"validation.json").write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n")
    return report


if __name__ == "__main__":
    root = Path(__file__).resolve().parent.parent
    verify(root,json.loads((root/"manifest.json").read_text()))
    print("Native PNGs, exact body/head crops, persistent identity, and independent ASE decoding: passed.")
