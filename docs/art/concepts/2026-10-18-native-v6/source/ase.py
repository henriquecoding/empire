"""Small RGBA Aseprite writer following the official chunk specification."""
import struct
import zlib


def chunk(kind, payload):
    return struct.pack("<IH", len(payload)+6, kind)+payload


def string(value):
    raw = value.encode("utf8")
    return struct.pack("<H",len(raw))+raw


def write(path, frames, names, size):
    layers = list(frames[0].layers)
    assert all(list(f.layers) == layers for f in frames)
    contents = []
    for n,s in enumerate(frames):
        chunks = []
        if n == 0:
            for name in layers:
                chunks.append(chunk(0x2004, struct.pack("<6HB3x",3,0,0,0,0,0,255)+string(name)))
            tags = struct.pack("<H8x",len(names))
            for i,name in enumerate(names):
                tags += struct.pack("<HHBH6x3BB",i,i,0,1,210,155,57,0)+string(name)
            chunks.append(chunk(0x2018,tags))
            slices = struct.pack("<III",1,2,0)+string("ground_pivot")
            slices += struct.pack("<IiiIIii",0,0,0,*size,*s.pivot)
            chunks.append(chunk(0x2022,slices))
        for i,layer in enumerate(s.layers.values()):
            layer = layer.crop((0,0,*size))
            if layer.getbbox():
                payload = struct.pack("<HhhBHh5xHH",i,0,0,255,2,0,*size)
                chunks.append(chunk(0x2005,payload+zlib.compress(layer.tobytes(),9)))
        body = b"".join(chunks)
        contents.append(struct.pack("<IHHH2xI",16+len(body),0xF1FA,len(chunks),100,len(chunks))+body)
    body = b"".join(contents)
    header = bytearray(128)
    struct.pack_into("<I5HIHII",header,0,128+len(body),0xA5E0,len(frames),*size,32,1,100,0,0)
    struct.pack_into("<HBBhhHH",header,32,0,1,1,0,0,1,1)
    path.write_bytes(header+body)
