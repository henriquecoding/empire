#!/usr/bin/env python3
"""Export the animated 64x64 animals and creatures of 14/10/2026 into the game (ADR 0083).

The owner's delivery comes as two ZIPs: EMPIRE-ANIMAIS-ANIMADOS-64x64 (12 species,
six actions each, `metadata/manifest.json` and `metadata/checksums.sha256`) and
EMPIRE-CRIATURAS-ANIMADAS-64x64 (eight creatures of the Rot, `catalogo.json` and
`SHA256SUMS.txt`). This tool reads them in place, checks every file it uses against
the package's own checksums and writes only what the game draws:

  - the right-facing sheet, byte for byte (the game mirrors it for the left);
  - a white mask of the same frames (the hit flash, the night silhouette);
  - for the creatures, the glow: the lightest colour of their shared palette (the
    eyes and the teeth), the only thing of them that is seen in the dark (ADR 0048).

The manifest has the shape OriginalArt reads (size, foot, frame_origins,
durations_ms, tags), so the poses, the strike timeline and the death of the
existing drawers work on the new art unchanged. Species and creatures with no
place in the game yet stay in the packages (Q-263).

    python3 tools/export_animated.py ANIMAIS.zip CRIATURAS.zip
    python3 tools/export_animated.py --check     # o export contra o manifesto, sem os ZIPs
"""
import argparse
import hashlib
import io
import json
import os
import sys
import zipfile
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / 'art/export/animated'
PREFIX = 'res://art/export/animated/'
CELL = 64

# The package name -> the id the game knows (creatures.csv, wildlife.csv, mounts.csv, buildings.csv).
CREATURES = {
    'rastejante': 'beast_crawler',
    'alado': 'beast_winged',
    'bruto': 'beast_brute',
    'cavador': 'beast_burrower',
    'ariete': 'beast_slime_ram',
    'consumidora': 'beast_devourer',
    'zelador': 'beast_tender',
}
ANIMALS = {
    'coelho': 'animal_rabbit',
    'raposa': 'animal_fox',
    'cervo_castanho': 'animal_deer',
    'cervo_branco': 'animal_white_stag',
    'javali': 'animal_boar',
    'cavalo': 'animal_draft_horse',
    'galinha': 'animal_hen',
    'galo': 'animal_rooster',
    'vaca': 'animal_cow',
}
# Animal actions also answer to their category: the feeding of each species has its own
# name (graze, root, groom, peck, nibble...), and the drawers ask for "feed".
CATEGORY_ALIASES = ('feed', 'special', 'down')


def save_png(image, path):
    buffer = io.BytesIO()
    image.save(buffer, format='PNG', optimize=True)
    return write_bytes(buffer.getvalue(), path)


def write_bytes(payload, path):
    Image.open(io.BytesIO(payload)).verify()
    temporary = path.with_suffix('.png.tmp')
    with temporary.open('wb') as handle:
        handle.write(payload)
        handle.flush()
        os.fsync(handle.fileno())
    temporary.replace(path)
    if path.stat().st_size != len(payload):
        raise ValueError(f'Incomplete PNG write: {path}')
    return payload


class Package:
    """One delivery ZIP, with the checksums it brings for its own files."""

    def __init__(self, path, sums):
        self.path = Path(path)
        self.archive = zipfile.ZipFile(path)
        names = self.archive.namelist()
        self.top = names[0].split('/', 1)[0] + '/'
        self.sha256 = hashlib.sha256(self.path.read_bytes()).hexdigest()
        self.sums = {}
        for line in self.read(sums, checked=False).decode('utf-8').splitlines():
            if line.strip():
                digest, name = line.split(maxsplit=1)
                self.sums[name.strip()] = digest

    def read(self, name, checked=True):
        payload = self.archive.read(self.top + name)
        if checked:
            expected = self.sums.get(name)
            if expected is None:
                raise ValueError(f'{self.path.name}: {name} is not in the package checksums')
            if hashlib.sha256(payload).hexdigest() != expected:
                raise ValueError(f'{self.path.name}: SHA-256 of {name} differs from the package')
        return payload

    def json(self, name):
        return json.loads(self.read(name))


def mask(sheet, keep):
    """White where `keep(rgba)` holds, transparent elsewhere: the same frames, one colour."""
    data = sheet.convert('RGBA').tobytes()
    pixels = (tuple(data[i:i + 4]) for i in range(0, len(data), 4))
    out = bytes(b for p in pixels for b in ((255, 255, 255, 255) if keep(p) else (0, 0, 0, 0)))
    return Image.frombytes('RGBA', sheet.size, out)


def body_bounds(sheet, origins, foot, first, last):
    """The union of the opaque pixels of frames first..last, relative to the foot."""
    box = None
    for index in range(first, last + 1):
        x, y = origins[index]
        bounds = sheet.crop((x, y, x + CELL, y + CELL)).getchannel('A').getbbox()
        if bounds is None:
            raise ValueError(f'empty frame {index}')
        box = bounds if box is None else (
            min(box[0], bounds[0]), min(box[1], bounds[1]), max(box[2], bounds[2]), max(box[3], bounds[3]))
    return [box[0] - foot[0], box[1] - foot[1], box[2] - box[0], box[3] - box[1]]


def lightest(palette_text):
    colours = []
    for line in palette_text.splitlines():
        parts = line.split()
        if len(parts) >= 3 and all(p.isdigit() for p in parts[:3]):
            colours.append(tuple(int(p) for p in parts[:3]))
    return max(colours, key=lambda c: 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2])


def export_sheet(asset_id, payload, entry, glow, written):
    sheet = Image.open(io.BytesIO(payload)).convert('RGBA')
    files = {}
    path = OUTPUT / (asset_id + '.png')
    write_bytes(payload, path)
    written.add(path)
    files['texture'] = hashlib.sha256(payload).hexdigest()
    path = OUTPUT / (asset_id + '_mask.png')
    files['mask_texture'] = hashlib.sha256(save_png(mask(sheet, lambda p: p[3] > 0), path)).hexdigest()
    written.add(path)
    if glow is not None:
        path = OUTPUT / (asset_id + '_glow.png')
        image = mask(sheet, lambda p: p[3] > 0 and p[:3] == glow)
        files['eyes_texture'] = hashlib.sha256(save_png(image, path)).hexdigest()
        written.add(path)
    idle = entry['tags']['idle']
    entry['body_bounds'] = body_bounds(sheet, entry['frame_origins'], entry['foot'],
                                       idle['from_frame'], idle['to_frame'])
    entry['sheet_size'] = list(sheet.size)
    entry.update(root=PREFIX, texture=asset_id + '.png', atlas_texture=asset_id + '.png',
                 mask_texture=asset_id + '_mask.png', atlas_origin=[0, 0], size=[CELL, CELL])
    if glow is not None:
        entry['eyes_texture'] = asset_id + '_glow.png'
    entry['sha256'] = files
    return entry


def creatures(package, written):
    catalog = package.json('catalogo.json')
    glow = lightest(package.read('palette/empire_criaturas_32.gpl').decode('utf-8'))
    assets, left = {}, []
    for item in catalog['items']:
        name = item['id']
        if name not in CREATURES:
            left.append(dict(source=name, title=item['title'], kind='creature'))
            continue
        durations, tags = [0] * item['frame_count'], {}
        for animation in item['animations']:
            for k, ms in enumerate(animation['duration_ms']):
                durations[animation['start'] + k] = ms
            tags[animation['id']] = dict(from_frame=animation['start'], to_frame=animation['end'],
                                         loop=animation['loop'])
        for alias in item.get('aliases', []):
            source = tags[alias['source']]
            tags[alias['id']] = dict(source, alias_of=alias['source'], speed=alias.get('speed_scale', 1.0),
                                     loop=alias.get('loop', source['loop']))
        columns = catalog['columns']
        origins = [[(i % columns) * CELL, (i // columns) * CELL] for i in range(item['frame_count'])]
        entry = dict(kind='creature', source=name, title=item['title'], hostile=item['hostile'],
                     foot=list(catalog['support']), frame_origins=origins, durations_ms=durations, tags=tags)
        asset_id = CREATURES[name]
        assets[asset_id] = export_sheet(asset_id, package.read(item['sheet']), entry, glow, written)
    return assets, left


def animals(package, written):
    manifest = package.json('metadata/manifest.json')
    assets, left = {}, []
    for item in manifest['animals']:
        name = item['id']
        if name not in ANIMALS:
            left.append(dict(source=name, title=item['label'], kind='animal'))
            continue
        frames = sorted(item['frames'], key=lambda f: f['index'])
        origins = [[f['rect']['x'], f['rect']['y']] for f in frames]
        durations = [f['duration'] for f in frames]
        tags = {}
        for animation in item['animations']:
            tag = dict(from_frame=animation['frames'][0], to_frame=animation['frames'][-1], loop=animation['loop'])
            if animation['frames'] != list(range(tag['from_frame'], tag['to_frame'] + 1)):
                raise ValueError(f'{name}/{animation["name"]}: frames are not contiguous')
            tags[animation['name']] = tag
            if animation['category'] in CATEGORY_ALIASES:
                tags[animation['category']] = dict(tag, alias_of=animation['name'])
        entry = dict(kind='animal', source=name, title=item['label'], foot=list(manifest['pivot']),
                     frame_origins=origins, durations_ms=durations, tags=tags,
                     lifts=[f['lift'] for f in frames])
        asset_id = ANIMALS[name]
        assets[asset_id] = export_sheet(asset_id, package.read(item['sheet']), entry, None, written)
    return assets, left


def check():
    """Every PNG is the one the manifest names, every frame is inside its sheet, nothing extra."""
    manifest = json.loads((OUTPUT / 'manifest.json').read_text(encoding='utf-8'))
    named = set()
    for asset_id, entry in manifest['assets'].items():
        for field, digest in entry['sha256'].items():
            path = OUTPUT / entry[field]
            named.add(path)
            payload = path.read_bytes()
            if hashlib.sha256(payload).hexdigest() != digest:
                raise ValueError(f'{asset_id}/{field}: SHA-256 differs from the manifest')
            if list(Image.open(io.BytesIO(payload)).size) != entry['sheet_size']:
                raise ValueError(f'{asset_id}/{field}: size differs from the sheet')
        width, height = entry['sheet_size']
        for x, y in entry['frame_origins']:
            if x < 0 or y < 0 or x + CELL > width or y + CELL > height:
                raise ValueError(f'{asset_id}: frame outside the sheet')
        if len(entry['durations_ms']) != len(entry['frame_origins']):
            raise ValueError(f'{asset_id}: one duration per frame')
        for name, tag in entry['tags'].items():
            if not 0 <= tag['from_frame'] <= tag['to_frame'] < len(entry['frame_origins']):
                raise ValueError(f'{asset_id}/{name}: tag outside the frames')
    extra = sorted(str(p.relative_to(ROOT)) for p in OUTPUT.glob('*.png') if p not in named)
    if extra:
        raise ValueError(f'PNG without a manifest entry: {extra}')
    print(f'animated: {len(manifest["assets"])} assets, {len(named)} PNG match the manifest')
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('packages', nargs='*', help='the two ZIPs of the delivery')
    parser.add_argument('--check', action='store_true', help='verify the export against the manifest')
    args = parser.parse_args()
    if args.check:
        return check()
    if len(args.packages) != 2:
        parser.error('the animals ZIP and the creatures ZIP are required to export')
    OUTPUT.mkdir(parents=True, exist_ok=True)
    manifest = dict(schema=1, generated_by='tools/export_animated.py', cell=[CELL, CELL], packages=[],
                    assets={}, left_in_package=[])
    written = set()
    for path in args.packages:
        names = zipfile.ZipFile(path).namelist()
        if any(n.endswith('/catalogo.json') and n.count('/') == 1 for n in names):
            package = Package(path, 'SHA256SUMS.txt')
            assets, left = creatures(package, written)
        else:
            package = Package(path, 'metadata/checksums.sha256')
            assets, left = animals(package, written)
        manifest['packages'].append(dict(file=package.path.name, sha256=package.sha256))
        manifest['assets'].update(assets)
        manifest['left_in_package'] += left
    missing = sorted((set(CREATURES.values()) | set(ANIMALS.values())) - set(manifest['assets']))
    if missing:
        raise ValueError(f'Not found in the packages: {missing}')
    manifest['assets'] = dict(sorted(manifest['assets'].items()))
    text = json.dumps(manifest, indent=1, ensure_ascii=False) + '\n'
    (OUTPUT / 'manifest.json').write_text(text, encoding='utf-8')
    for stale in [p for p in OUTPUT.glob('*.png') if p not in written]:
        print(f'stale export removed: {stale.relative_to(ROOT)}')
        stale.unlink()
    for asset_id, entry in manifest['assets'].items():
        print(f'{asset_id:22} {entry["source"]:16} {len(entry["frame_origins"]):3} frames {len(entry["tags"]):2} tags')
    print(f'{len(manifest["assets"])} assets, {len(written)} PNG; '
          f'left in the packages: {", ".join(x["source"] for x in manifest["left_in_package"])}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
