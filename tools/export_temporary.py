"""Export the free gameplay proxies without changing Henrique's originals."""
import argparse
import hashlib
import json
import re
import tempfile
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'art/source/temporary'
OUT = ROOT / 'art/export/temporary'
RESOURCE_ROOT = 'res://art/export/temporary/'
ACTIONS = {'Idle': 'idle', 'Run': 'walk', 'Walk': 'walk', 'Flight': 'walk',
           'Attack': 'attack', 'Take Hit': 'hit', 'Get Hit': 'hit', 'Death': 'die'}


def numbered(path):
    return int(re.search(r'(\d+)\.png$', path.name).group(1))


def individual(folder):
    actions = {}
    for path in sorted(folder.iterdir()):
        if path.is_dir() and path.name in ACTIONS:
            actions[ACTIONS[path.name]] = [Image.open(p).convert('RGBA')
                for p in sorted(path.glob('*.png'), key=numbered)]
    return actions


def strips(folder, width):
    actions = {}
    for name, action in ACTIONS.items():
        path = folder / f'{name}.png'
        if path.exists():
            sheet = Image.open(path).convert('RGBA')
            actions[action] = [sheet.crop((x, 0, x + width, sheet.height))
                               for x in range(0, sheet.width, width)]
    if 'idle' not in actions:
        actions['idle'] = actions['walk']
    return actions


def export(destination):
    destination.mkdir(parents=True, exist_ok=True)
    assets, images = {}, {}

    def animated(name, actions, foot, scale):
        frames, durations, tags = [], [], {}
        for tag in ['idle', 'walk', 'attack', 'hit', 'die']:
            if tag not in actions:
                continue
            start = len(frames)
            frames.extend(actions[tag])
            durations.extend([150 if tag == 'idle' else 100] * len(actions[tag]))
            tags[tag] = {'from_frame': start, 'to_frame': len(frames) - 1}
        bounds = [frame.getbbox() for frame in frames if frame.getbbox()]
        crop = (min(b[0] for b in bounds), min(b[1] for b in bounds),
                max(b[2] for b in bounds), max(b[3] for b in bounds))
        width, height = (crop[2] - crop[0]) * scale, (crop[3] - crop[1]) * scale
        columns = min(len(frames), 4096 // width)
        rows = (len(frames) + columns - 1) // columns
        sheet = Image.new('RGBA', (width * columns, height * rows))
        origins = []
        for i, frame in enumerate(frames):
            resized = frame.crop(crop).resize((width, height), Image.Resampling.NEAREST)
            origin = (i % columns * width, i // columns * height)
            origins.append(list(origin))
            sheet.alpha_composite(resized, origin)
        body = actions['idle'][0].getbbox()
        assets[name] = {'texture': f'{name}.png', 'root': RESOURCE_ROOT,
            'size': [width, height], 'foot': [(foot[0] - crop[0]) * scale,
                                             (foot[1] - crop[1]) * scale],
            'body_bounds': [(body[0] - foot[0]) * scale, (body[1] - foot[1]) * scale,
                            (body[2] - body[0]) * scale, (body[3] - body[1]) * scale],
            'durations_ms': durations, 'tags': tags, 'integer_scale': scale,
            'frame_origins': origins,
            'review_status': 'free_temporary_gameplay_proxy'}
        images[name] = sheet

    archer = strips(SOURCE / 'luizmelo/Huntress', 100)
    spear = individual(SOURCE / 'angav_spearman')
    animated('temp_archer', archer, (50, 67), 1)
    animated('temp_archer_hero', archer, (50, 67), 2)
    animated('temp_spearman', spear, (16, 32), 3)
    for name, folder, scale, foot in [
        ('temp_crawler', 'Goblin', 1, (75, 101)),
        ('temp_winged', 'Flying eye', 1, (75, 92)),
        ('temp_brute', 'Mushroom', 2, (75, 101)),
        ('temp_burrower', 'Skeleton', 1, (75, 101)),
    ]:
        animated(name, strips(SOURCE / 'luizmelo' / folder, 150), foot, scale)

    atlas = Image.new('RGBA', (4096, 1024))
    y = 0
    for name, sheet in images.items():
        assert sheet.width <= atlas.width and y + sheet.height <= atlas.height
        atlas.alpha_composite(sheet, (0, y))
        assets[name]['atlas_origin'] = [0, y]
        assets[name]['atlas_texture'] = 'actors.png'
        y += sheet.height
        sheet.save(destination / f'{name}.png')
    atlas.save(destination / 'actors.png')
    mask = Image.new('RGBA', atlas.size, 'white')
    mask.putalpha(atlas.getchannel('A'))
    mask.save(destination / 'actors_mask.png')

    def still(name, image, scale=1):
        image = image.convert('RGBA')
        image = image.resize((image.width * scale, image.height * scale), Image.Resampling.NEAREST)
        image.save(destination / f'{name}.png')
        assets[name] = {'texture': f'{name}.png', 'root': RESOURCE_ROOT,
            'size': list(image.size), 'foot': [image.width // 2, image.height],
            'body_bounds': [-image.width // 2, -image.height, image.width, image.height],
            'durations_ms': [100], 'tags': {}, 'integer_scale': scale,
            'review_status': 'free_temporary_gameplay_proxy'}

    still('temp_forest_back', Image.open(SOURCE / 'forest_back.png'), 2)
    still('temp_forest_middle', Image.open(SOURCE / 'forest_middle.png'), 2)
    still('temp_soil', Image.open(SOURCE / 'cave_brown.png').crop((80, 64, 96, 80)), 2)
    still('temp_cave', Image.open(SOURCE / 'cave_gray.png').crop((80, 64, 96, 80)), 2)
    props = Image.open(SOURCE / 'props.png')
    for name, x, y in [('crate', 6, 1), ('wood', 7, 0), ('stone', 8, 0),
                       ('lever', 4, 3), ('flag', 12, 5), ('plant', 4, 6),
                       ('mushroom', 8, 6), ('sign', 4, 4), ('fence', 5, 5)]:
        still(f'temp_{name}', props.crop((x * 18, y * 18, (x + 1) * 18, (y + 1) * 18)), 2)
    sources = {str(p.relative_to(SOURCE)): hashlib.sha256(p.read_bytes()).hexdigest()
               for p in sorted(SOURCE.rglob('*.png'))}
    manifest = {'version': 1, 'temporary': True, 'assets': assets, 'sources': sources,
                'credits': 'res://art/export/temporary/CREDITS.txt'}
    (destination / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=OUT)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    if args.check:
        with tempfile.TemporaryDirectory() as directory:
            export(Path(directory))
            for generated in Path(directory).iterdir():
                target = args.output / generated.name
                if not target.exists() or target.read_bytes() != generated.read_bytes():
                    raise SystemExit(f'Outdated temporary export: {target}')
        print('Temporary exports match their free sources')
    else:
        export(args.output)
