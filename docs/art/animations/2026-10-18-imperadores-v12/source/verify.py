#!/usr/bin/env python3
"""Independent, standard-library PNG/ASE reader: compare every exported pixel."""
import binascii
import hashlib
import json
from pathlib import Path
import struct
import sys
import zlib


def u16(data, p=0):
    return struct.unpack_from('<H', data, p)[0]


def u32(data, p=0):
    return struct.unpack_from('<I', data, p)[0]


def string(data, p):
    n = u16(data, p)
    return data[p+2:p+2+n].decode('utf-8'), p+2+n


def read_png(file):
    data = Path(file).read_bytes()
    assert data[:8] == b'\x89PNG\r\n\x1a\n'
    p, packed, width, height = 8, bytearray(), 0, 0
    while p < len(data):
        n = struct.unpack_from('>I', data, p)[0]
        kind, chunk = data[p+4:p+8], data[p+8:p+8+n]
        assert binascii.crc32(kind+chunk) & 0xffffffff == struct.unpack_from('>I', data, p+8+n)[0]
        if kind == b'IHDR':
            width, height = struct.unpack_from('>II', chunk)
            assert chunk[8:13] == bytes([8, 6, 0, 0, 0])
        if kind == b'IDAT':
            packed.extend(chunk)
        p += n+12
    raw = zlib.decompress(packed)
    stride = width*4+1
    assert len(raw) == height*stride
    assert all(raw[y*stride] == 0 for y in range(height))
    pixels = b''.join(raw[y*stride+1:(y+1)*stride] for y in range(height))
    assert set(pixels[3::4]) <= {0, 255}
    return width, height, pixels


def region(pixels, width, x, y, w, h):
    return b''.join(pixels[((y+j)*width+x)*4:((y+j)*width+x+w)*4] for j in range(h))


def read_ase(file):
    data = Path(file).read_bytes()
    assert len(data) == u32(data) and u16(data, 4) == 0xa5e0
    n, w, h, depth = [u16(data, x) for x in (6, 8, 10, 12)]
    assert depth == 32
    pos, frames, layers, tags, durations, pivot = 128, [], [], [], [], None
    for _ in range(n):
        size = u32(data, pos)
        assert u16(data, pos+4) == 0xf1fa
        count = u32(data, pos+12) or u16(data, pos+6)
        durations.append(u16(data, pos+8))
        p, cels = pos+16, {}
        for _ in range(count):
            length, kind = u32(data, p), u16(data, p+4)
            q = data[p+6:p+length]
            if kind == 0x2004:
                assert u16(q) & 1 and q[12] == 255
                layers.append(string(q, 16)[0])
            elif kind == 0x2005:
                li = u16(q)
                assert struct.unpack_from('<hh', q, 2) == (0, 0)
                assert q[6] == 255 and u16(q, 7) == 2
                assert u16(q, 16) == w and u16(q, 18) == h
                cel = zlib.decompress(q[20:])
                assert len(cel) == w*h*4 and set(cel[3::4]) <= {0, 255}
                cels[li] = cel
            elif kind == 0x2018:
                t = 10
                for _ in range(u16(q)):
                    first, last, loop = u16(q, t), u16(q, t+2), u16(q, t+5) == 0
                    name, t = string(q, t+17)
                    tags.append({'name': name, 'from': first, 'to': last, 'loop': loop})
            elif kind == 0x2022:
                _, k = string(q, 12)
                pivot = list(struct.unpack_from('<ii', q, k+20))
            p += length
        assert p == pos+size
        pixels = bytearray(w*h*4)
        for li in sorted(cels):
            cel = cels[li]
            for j in range(0, len(cel), 4):
                if cel[j+3]:
                    pixels[j:j+4] = cel[j:j+4]
        frames.append(bytes(pixels))
        pos += size
    assert pos == len(data)
    return w, h, frames, tags, durations, pivot


def verify(root):
    manifest = json.loads((root/'manifest.json').read_text())
    report = {'status': 'passed', 'native_sizes': True, 'binary_alpha': True,
              'ase_png_json_pixel_match': True, 'exact_left_mirroring': True,
              'fixed_pivots': True, 'characters': [], 'limitations': [
                  'Validação estrutural e comparação de pixels; não é aprovação artística.',
                  'Aseprite e Godot não disponíveis para abrir os arquivos nesta execução.']}
    for c in manifest['characters']:
        folder = root/'personagens'/c['id']
        meta = json.loads((folder/'animacoes.json').read_text())
        w, h, rgba = read_png(folder/'atlas.png')
        aw, ah, frames, tags, ms, pivot = read_ase(folder/(c['id']+'.aseprite'))
        s = c['size']
        assert aw == ah == s and s in (64, 80) and pivot == [s//2, s-2]
        assert w == s*8 and h == s*len(meta['animations']) and len(tags) == len(meta['animations'])
        unique = set()
        for a, tag in zip(meta['animations'], tags):
            pw, ph, prgba = read_png(folder/a['sheet'])
            assert pw == len(a['frames'])*s and ph == s and tag['name'] == a['name']
            assert tag['from'] == a['frames'][0]['aseFrame'] and tag['to'] == a['frames'][-1]['aseFrame']
            assert tag['loop'] == a['loop']
            for f in a['frames']:
                r = f['rect']
                p = region(rgba, w, r['x'], r['y'], s, s)
                assert p == frames[f['aseFrame']] == region(prgba, pw, f['index']*s, 0, s, s)
                assert hashlib.sha256(p).hexdigest() == f['rgbaSha256']
                assert ms[f['aseFrame']] == f['durationMs'] and f['pivot'] == pivot
                assert any(p[3::4])
                if a['direction'] == 'left':
                    right = next(b for b in meta['animations'] if b['name'] == a['action']+'_right')
                    orig = frames[right['frames'][f['index']]['aseFrame']]
                    mirrored = b''.join(orig[(y*s+x)*4:(y*s+x+1)*4] for y in range(s) for x in reversed(range(s)))
                    assert p == mirrored
                unique.add(p)
        report['characters'].append({'id': c['id'], 'size': s, 'frames': len(frames), 'tags': len(tags), 'distinct_full_frames_including_mirrors': len(unique), 'cleaned_isolated_pixels': meta['cleanup']['isolatedPixelsRemovedAcrossAllFrames']})
    ew, eh, ep = read_png(root/'efeitos'/'sombra-flores.png')
    fw, fh, ff, ft, fm, fp = read_ase(root/'efeitos'/'sombra-flores.aseprite')
    assert (fw, fh, fp) == (160, 32, [80, 31]) and (ew, eh) == (160*len(ff), 32)
    assert all(region(ep, ew, i*160, 0, 160, 32) == f for i, f in enumerate(ff))
    report['effect_frames'] = len(ff)
    report['total_character_frames'] = sum(c['frames'] for c in report['characters'])
    (root/'verificacao.json').write_text(json.dumps(report, indent=2, ensure_ascii=False)+'\n')
    print(json.dumps(report, ensure_ascii=False))


if __name__ == '__main__':
    verify(Path(sys.argv[1]))
