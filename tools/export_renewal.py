#!/usr/bin/env python3
"""Pack the approved image-generated artwork into deterministic game atlases.

This is asset preparation only: crop, nearest-neighbour resize, feet alignment,
binary alpha, atlas/mask generation. Source illustrations remain intact.
"""
import argparse
import io
import os
import hashlib
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'art/source/renewal'
OUTPUT = ROOT / 'art/export/renewal'
PREFIX = 'res://art/export/renewal/'
ACTORS = [
    ('rot_large', [0, 359, 754, 1254], [0, 323, 635, 950, 1254],
     [('royal_ram', 90), ('royal_devourer', 176), ('royal_tender', 136)]),
    ('crew', [0, 334, 641, 944, 1254], [0, 337, 642, 958, 1254],
     [('royal_bard', 68), ('royal_quiver', 48), ('royal_smith', 58), ('royal_knight', 62)]),
    ('royals', [0, 319, 649, 1003, 1254], [0, 329, 634, 948, 1254],
     [('royal_king', 78), ('royal_nia', 68), ('royal_archer', 74), ('royal_squire', 48)]),
    ('citizens', [0, 314, 621, 934, 1254], [0, 313, 627, 940, 1254],
     [('royal_citizen', 50), ('royal_bowman', 54), ('royal_spearman', 62), ('royal_cook', 60)]),
    ('rot', [0, 291, 616, 923, 1254], [0, 314, 626, 938, 1254],
     [('royal_crawler', 54), ('royal_winged', 74), ('royal_brute', 112), ('royal_burrower', 62)]),
]
BUILDINGS = [
    ('royal_cart', 126), ('royal_training', 164), ('royal_forge', 160),
    ('royal_kitchen', 176), ('royal_granary', 144), ('royal_hall', 184),
    ('royal_keep', 264), ('royal_oak', 308),
]


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


def opened(name):
    return Image.open(SOURCE / (name + '.png')).convert('RGBA')


def cut(image, rectangle):
    piece = image.crop(rectangle)
    alpha = piece.getchannel('A').point(lambda value: 255 if value >= 128 else 0)
    piece.putalpha(alpha)
    bounds = alpha.getbbox()
    if bounds is None:
        raise ValueError(f'Empty cell: {rectangle}')
    return piece.crop(bounds)


def sized(image, height):
    width = max(1, round(image.width * height / image.height))
    return image.resize((width, height), Image.Resampling.NEAREST)


def descriptor(name, width, height, count=1):
    return dict(root=PREFIX, texture=name + '.png', size=[width, height],
                foot=[width // 2, height - 4], body_bounds=[-width // 2, -height + 4, width, height - 4],
                durations_ms=[160] * count, tags={'idle': {'from_frame': 0, 'to_frame': 0}},
                review_status='direction_confirmed_2026_10_05',
                source='art/source/renewal', frame_origins=[[i * width, 0] for i in range(count)])


def export(directory):
    directory.mkdir(parents=True, exist_ok=True)
    assets = {}
    packed = []
    cell = 192
    for filename, rows, columns, profiles in ACTORS:
        source = opened(filename)
        for row, (name, target) in enumerate(profiles):
            frames = [cut(source, (columns[c], rows[row], columns[c + 1], rows[row + 1]))
                      for c in range(4)]
            # One scale per row preserves proportions; feet stay fixed across poses.
            scale = target / max(frame.height for frame in frames)
            strip = Image.new('RGBA', (cell * 4, cell))
            bounds = None
            for column, frame in enumerate(frames):
                frame = frame.resize((round(frame.width * scale), round(frame.height * scale)),
                                     Image.Resampling.NEAREST)
                # Downsampling can drop the last opaque pixel: align the reduced foot.
                frame = frame.crop(frame.getchannel('A').getbbox())
                x = column * cell + (cell - frame.width) // 2
                strip.alpha_composite(frame, (x, cell - 8 - frame.height))
                if column == 0:
                    bounds = [(cell - frame.width) // 2 - cell // 2, -frame.height,
                              frame.width, frame.height]
            save_png(strip, directory / (name + '.png'))
            item = descriptor(name, cell, cell, 4)
            item['foot'] = [cell // 2, cell - 8]
            item['body_bounds'] = bounds
            item['tags']['walk'] = {'from_frame': 0, 'to_frame': 3}
            item['tags']['flee'] = {'from_frame': 0, 'to_frame': 3}
            # Attack/hurt/fall use the existing combat pose system, not fake action tags.
            item['atlas_texture'] = 'actors.png'
            item['mask_texture'] = 'actors_mask.png'
            item['eyes_texture'] = 'actors_eyes.png'
            item['atlas_origin'] = [0, len(packed) * cell]
            assets[name] = item
            packed.append(strip)
    atlas = Image.new('RGBA', (cell * 4, cell * len(packed)))
    for index, strip in enumerate(packed):
        atlas.alpha_composite(strip, (0, index * cell))
    save_png(atlas, directory / 'actors.png')
    mask = Image.new('RGBA', atlas.size, 'white')
    mask.putalpha(atlas.getchannel('A'))
    save_png(mask, directory / 'actors_mask.png')
    # Emission map: keep only amber eye pixels in the rot rows, at identical UVs.
    eyes = Image.new('RGBA', atlas.size)
    for index, name in enumerate(assets):
        if name not in {'royal_ram', 'royal_devourer', 'royal_tender', 'royal_crawler',
                        'royal_winged', 'royal_brute', 'royal_burrower'}:
            continue
        strip = packed[index]
        for y in range(cell):
            for x in range(cell * 4):
                r, g, b, a = strip.getpixel((x, y))
                if a and r > 185 and g > 115 and b < 80:
                    eyes.putpixel((x, y + index * cell), (r, g, b, a))
    save_png(eyes, directory / 'actors_eyes.png')
    source = opened('settlement')
    columns = [0, 440, 896, 1337, 1774]
    rows = [0, 435, 887]
    for index, (name, height) in enumerate(BUILDINGS):
        row, column = divmod(index, 4)
        piece = cut(source, (columns[column], rows[row], columns[column + 1], rows[row + 1]))
        # Author scenery on a 2px grid, in contrast with the 1px actors.
        piece = sized(piece, height // 2)
        piece = piece.resize((piece.width * 2, piece.height * 2), Image.Resampling.NEAREST)
        output = Image.new('RGBA', (piece.width + 8, piece.height + 8))
        output.alpha_composite(piece, (4, 4))
        save_png(output, directory / (name + '.png'))
        assets[name] = descriptor(name, output.width, output.height)
    source = opened('village')
    details = [
        ('royal_encampment', (0, 0, 443, 477), 92),
        ('royal_hamlet', (443, 0, 881, 477), 124),
        ('royal_village', (881, 0, 1316, 477), 182),
        ('royal_walled', (1316, 0, 1774, 477), 212),
        ('royal_tree_castle', (0, 477, 595, 887), 340),
        ('royal_pine', (595, 477, 883, 887), 188),
        ('royal_bush', (883, 477, 1315, 887), 42),
        ('royal_meadow', (1315, 477, 1774, 887), 20),
    ]
    for name, rect, height in details:
        piece = sized(cut(source, rect), height // 2)
        piece = piece.resize((piece.width * 2, piece.height * 2), Image.Resampling.NEAREST)
        output = Image.new('RGBA', (piece.width + 8, piece.height + 8))
        output.alpha_composite(piece, (4, 4))
        save_png(output, directory / (name + '.png'))
        assets[name] = descriptor(name, output.width, output.height)
    source = opened('trees')
    names = ['oak', 'willow', 'coast_pine', 'roots']
    columns = [0, 454, 892, 1341, 1774]
    for row in range(2):
        for column, kind in enumerate(names):
            name = 'royal_tree_' + kind + ('_bare' if row else '')
            piece = sized(cut(source, (columns[column], row * 447,
                                      columns[column + 1], 447 if row == 0 else 887)), 88)
            piece = piece.resize((piece.width * 2, 176), Image.Resampling.NEAREST)
            output = Image.new('RGBA', (piece.width + 8, piece.height + 8))
            output.alpha_composite(piece, (4, 4))
            save_png(output, directory / (name + '.png'))
            assets[name] = descriptor(name, output.width, output.height)
    landscape = opened('valley').convert('RGB').resize((768, 256), Image.Resampling.NEAREST)
    save_png(landscape.resize((1536, 512), Image.Resampling.NEAREST), directory / 'valley.png')
    for who in ['king', 'nia', 'archer']:
        portrait = opened('portrait_' + who)
        if who == 'nia':
            portrait = portrait.crop((0, 0, 1000, portrait.height))
        portrait = cut(portrait, (0, 0, portrait.width, portrait.height))
        save_png(sized(portrait, 360), directory / ('portrait_' + who + '.png'))
    sources = {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(SOURCE.glob('*.png'))}
    (directory / 'manifest.json').write_text(json.dumps(dict(version=1, sources=sources, assets=assets),
                                                       ensure_ascii=False, indent=2) + '\n')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    if args.check:
        import tempfile
        with tempfile.TemporaryDirectory() as temporary:
            expected = Path(temporary)
            export(expected)
            for path in expected.iterdir():
                actual = OUTPUT / path.name
                if not actual.exists() or actual.read_bytes() != path.read_bytes():
                    raise SystemExit(f'Regenerate {actual.relative_to(ROOT)}')
        print('renewal: source hashes, atlas, masks and exports verified')
    else:
        export(OUTPUT)
        print('renewal: exported to art/export/renewal')


if __name__ == '__main__':
    main()
