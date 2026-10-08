#!/usr/bin/env python3
"""Export the layered scenery packages of 08/10/2026 into the game (ADR 0081).

The owner's delivery comes as three batch ZIPs, each with one ZIP per scene in
`pacotes/` and a `catalogo.json` with the SHA-256 of every scene ZIP. This tool
reads them in place (zip inside zip), checks every hash, and writes only what the
game draws: each aligned layer of `18_aligned`, cropped to its alpha bounds and,
when the art was authored in repeated blocks (the skies are 2x4), stored at its
native block size. Nothing is resampled: the export is the same pixels.

Kingdoms keep sky, clouds, far, mid, near, under, terrain, water and foreground.
Transitions keep their world-space ground (under, terrain, water, foreground) and
the threshold landmark, cut from the props layer where the composer placed it.
Buildings, props with stairs, under activities and actor references stay out: the
simulation decides what is built and where a passage is. The three special
scenes are proposals still waiting for a place in the world (Q-259).

    python3 tools/export_scenery.py LOTE.zip [LOTE.zip ...]
    python3 tools/export_scenery.py --check     # o export contra o manifesto, sem os ZIPs

Exporting also needs numpy (only here, never in the game nor in CI); the check needs Pillow only.
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
OUTPUT = ROOT / 'art/export/scenery'
PREFIX = 'res://art/export/scenery/'
KINGDOM_LAYERS = ['sky', 'clouds', 'far', 'mid', 'near', 'under', 'terrain', 'water', 'foreground']
TRANSITION_LAYERS = ['under', 'terrain', 'water', 'foreground']
LANDMARK = '07_props/threshold_landmark.png'
BLOCKS = [8, 4, 2]
GROUPS = {'kingdoms': 'kingdom', 'transitions': 'transition'}


def save_png(image, path):
    buffer = io.BytesIO()
    image.save(buffer, format='PNG', optimize=True)
    payload = buffer.getvalue()
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


def block(pixels, axis):
    """The largest repeat factor along an axis: every row (or column) of a block equal."""
    import numpy
    size = pixels.shape[axis]
    for factor in BLOCKS:
        if size % factor:
            continue
        first = numpy.take(pixels, range(0, size, factor), axis=axis)
        if numpy.array_equal(numpy.repeat(first, factor, axis=axis), pixels):
            return factor
    return 1


def reduced(image):
    """The layer at its authored block size, cropped to the alpha bounds, in canvas px."""
    import numpy
    pixels = numpy.asarray(image.convert('RGBA'))
    fx, fy = block(pixels, 1), block(pixels, 0)
    small = Image.fromarray(pixels[::fy, ::fx].copy(), 'RGBA')
    bounds = small.getchannel('A').getbbox()
    if bounds is None:
        return None
    rect = [bounds[0] * fx, bounds[1] * fy, (bounds[2] - bounds[0]) * fx, (bounds[3] - bounds[1]) * fy]
    return small.crop(bounds), rect, [fx, fy]


def located(layer, piece):
    """Where the composer pasted `piece` inside `layer`: the offset whose pixels match."""
    import numpy
    big = numpy.asarray(layer.convert('RGBA')).astype(numpy.int16)
    small = numpy.asarray(piece.convert('RGBA')).astype(numpy.int16)
    solid = small[:, :, 3] >= 128
    ys, xs = numpy.nonzero(solid)
    if ys.size == 0:
        raise ValueError('Landmark without opaque pixels')
    anchor = small[ys[0], xs[0]]
    for y, x in zip(*numpy.nonzero(numpy.all(big == anchor, axis=2))):
        top, left = y - ys[0], x - xs[0]
        if top < 0 or left < 0 or top + small.shape[0] > big.shape[0] or left + small.shape[1] > big.shape[1]:
            continue
        window = big[top:top + small.shape[0], left:left + small.shape[1]]
        if numpy.array_equal(window[solid], small[solid]):
            return int(left), int(top)
    raise ValueError('Landmark not found in the props layer')


def member(archive, path):
    """The entry at `path`, below the one folder that a scene ZIP (or a batch) may have."""
    names = [n for n in archive.namelist() if n == path or n.split('/', 1)[-1] == path]
    if len(names) != 1:
        raise ValueError(f'Expected one {path}, found {names}')
    return names[0]


def read_json(archive, suffix):
    return json.loads(archive.read(member(archive, suffix)))


def image(archive, suffix):
    return Image.open(io.BytesIO(archive.read(member(archive, suffix))))


def export_layer(name, picture, folder, written):
    result = reduced(picture)
    if result is None:
        return None
    small, rect, scale = result
    path = OUTPUT / folder / (name + '.png')
    payload = save_png(small, path)
    written.add(path)
    return dict(file=PREFIX + folder + '/' + name + '.png', rect=rect, scale=scale,
                sha256=hashlib.sha256(payload).hexdigest())


def export_scene(entry, archive, written):
    kind = GROUPS[entry['group']]
    routes = read_json(archive, 'routes.json')
    stack = {layer['id']: layer['file'] for layer in read_json(archive, 'layers.json')['layers']}
    scene = dict(kind=kind, title=entry['title'], package=entry['zip'], package_sha256=entry['sha256'],
                 canvas=entry['canvas'], layers={})
    folder = routes['id']
    (OUTPUT / folder).mkdir(parents=True, exist_ok=True)
    wanted = KINGDOM_LAYERS if kind == 'kingdom' else TRANSITION_LAYERS
    for name in wanted:
        if name not in stack:
            continue
        exported = export_layer(name, image(archive, stack[name]), folder, written)
        if exported is not None:
            scene['layers'][name] = exported
    if kind == 'kingdom':
        scene['biome'] = routes['id']
    else:
        meta = read_json(archive, '13_sources/previous_metadata/composition.json')
        scene.update({'from': meta['from'], 'to': meta['to'], 'threshold_x': meta['threshold_x']})
        piece = image(archive, LANDMARK)
        left, top = located(image(archive, stack['props']), piece)
        holder = Image.new('RGBA', tuple(entry['canvas']))
        holder.alpha_composite(piece.convert('RGBA'), (left, top))
        scene['layers']['landmark'] = export_layer('landmark', holder, folder, written)
    return folder, scene


def batches(paths):
    for path in paths:
        outer = zipfile.ZipFile(path)
        catalog = json.loads(outer.read(member(outer, 'catalogo.json')))
        digest = hashlib.sha256(Path(path).read_bytes()).hexdigest()
        yield Path(path).name, digest, outer, catalog


def check():
    """Every exported PNG is the one the manifest names: same hash, same size, nothing extra."""
    manifest = json.loads((OUTPUT / 'manifest.json').read_text(encoding='utf-8'))
    named = set()
    for scene_id, scene in manifest['scenes'].items():
        for name, layer in scene['layers'].items():
            path = ROOT / layer['file'].removeprefix('res://')
            named.add(path)
            payload = path.read_bytes()
            if hashlib.sha256(payload).hexdigest() != layer['sha256']:
                raise ValueError(f'{scene_id}/{name}: SHA-256 differs from the manifest')
            width, height = Image.open(io.BytesIO(payload)).size
            x, y, w, h = layer['rect']
            if [width * layer['scale'][0], height * layer['scale'][1]] != [w, h]:
                raise ValueError(f'{scene_id}/{name}: size differs from rect / scale')
            if x < 0 or y < 0 or x + w > scene['canvas'][0] or y + h > scene['canvas'][1]:
                raise ValueError(f'{scene_id}/{name}: rect outside the canvas')
    extra = sorted(str(p.relative_to(ROOT)) for p in OUTPUT.rglob('*.png') if p not in named)
    if extra:
        raise ValueError(f'PNG without a manifest entry: {extra}')
    print(f'scenery: {len(manifest["scenes"])} scenes, {len(named)} layers match the manifest')
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('batches', nargs='*', help='the batch ZIPs of the delivery')
    parser.add_argument('--check', action='store_true', help='verify the export against the manifest')
    args = parser.parse_args()
    if args.check:
        return check()
    if not args.batches:
        parser.error('the batch ZIPs are required to export')
    manifest = dict(schema=1, generated_by='tools/export_scenery.py', surface_y=517, under_y=618.5,
                    batches=[], scenes={}, proposals=[])
    written = set()
    for name, digest, outer, catalog in batches(args.batches):
        manifest['batches'].append(dict(file=name, sha256=digest))
        for entry in catalog:
            payload = outer.read('pacotes/' + entry['zip'])
            if hashlib.sha256(payload).hexdigest() != entry['sha256']:
                raise ValueError(f'SHA-256 differs from catalogo.json: {entry["zip"]}')
            if entry['group'] not in GROUPS:
                manifest['proposals'].append(dict(id=entry['id'], title=entry['title'], package=entry['zip']))
                continue
            folder, scene = export_scene(entry, zipfile.ZipFile(io.BytesIO(payload)), written)
            manifest['scenes'][folder] = scene
            print(f'{folder:22} {scene["kind"]:10} {len(scene["layers"])} layers')
    manifest['scenes'] = dict(sorted(manifest['scenes'].items()))
    text = json.dumps(manifest, indent=1, ensure_ascii=False) + '\n'
    (OUTPUT / 'manifest.json').write_text(text, encoding='utf-8')
    stale = [p for p in OUTPUT.rglob('*.png') if p not in written]
    for path in stale:
        print(f'stale export removed: {path.relative_to(ROOT)}')
        path.unlink()
    print(f'{len(manifest["scenes"])} scenes, {len(written)} PNG')
    return 0


if __name__ == '__main__':
    sys.exit(main())
