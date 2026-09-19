"""Reproducible export of Henrique's sources; no resampling or recolouring."""
import argparse
import hashlib
import json
import tempfile
from pathlib import Path

from PIL import Image
from aseprite_source import composite, read

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'art/source/originals'
OUT = ROOT / 'art/export/enramados'
REVIEW_STATUS = {
    'knight': 'near_complete_reference',
    'cook': 'near_complete_reference',
    'vagrant': 'derived_temporary',
    'monarch': 'redesign_required',
}
BODY_LAYERS = {'knight': 1, 'vagrant': 1, 'monarch': 63, 'cook': 43}


def export(destination):
    destination.mkdir(parents=True, exist_ok=True)
    sources = {name: read(SOURCE / f'{name}.aseprite') for name in ('troop', 'archer', 'concept')}
    # Explicit layer selections are an art contract, not a guess based on names.
    # Bounds and feet are in the original editor canvas. Shield order is retained.
    pieces = {
        'knight': ('troop', [1, 2, 3, 4, 5], (77, 75, 126, 129), (95, 128)),
        'vagrant': ('troop', [1, 2], (77, 75, 126, 129), (95, 128)),
        'monarch': ('concept', [63, 64], (2558, 225, 2618, 319), (2593, 318)),
        'cook': ('concept', [43, 44, 45, 46], (1296, 446, 1344, 514), (1311, 512)),
        'far_keep': ('concept', [11, 12], (2230, 103, 2976, 514), (2600, 514)),
        'oak': ('concept', [6], (2311, 0, 2944, 584), (2627, 584)),
        'tree_castle': ('concept', [6, 8, 11, 12, 13], (2230, 0, 2976, 514), (2600, 514)),
        'workshop': ('concept', [17, 19, 20], (104, 358, 212, 514), (158, 514)),
        'training_house': ('concept', [11, 12], (1180, 358, 1280, 514), (1230, 514)),
        'gate': ('concept', [11, 12], (3200, 236, 3338, 514), (3269, 514)),
        'storehouse': ('concept', [26], (1872, 518, 1987, 640), (1929, 640)),
    }
    manifest = {'version': 2, 'assets': {}, 'sources': {},
                'review_authority': 'Author clarification 2026-09-19; docs/art/REFERENCE_AUTHORITY.md'}
    for name, source in sources.items():
        manifest['sources'][name] = {'sha256': hashlib.sha256((SOURCE / f'{name}.aseprite').read_bytes()).hexdigest(),
                                     'layers': source['layers']}
        if name == 'archer':
            manifest['sources'][name].update(review_status='rejected_concept', runtime_allowed=False)
    for name, (src, layers, bounds, foot) in pieces.items():
        source = sources[src]
        width, height = bounds[2] - bounds[0], bounds[3] - bounds[1]
        sheet = Image.new('RGBA', (width * len(source['frames']), height))
        for frame in range(len(source['frames'])):
            sheet.alpha_composite(composite(source, frame, layers, bounds), (frame * width, 0))
        sheet.save(destination / f'{name}.png')
        manifest['assets'][name] = dict(source=src, layers=layers, source_bounds=bounds,
            size=[width, height], foot=[foot[0] - bounds[0], foot[1] - bounds[1]],
            durations_ms=source['durations'], tags=source['tags'], texture=f'{name}.png',
            review_status=REVIEW_STATUS.get(name, 'author_base_needs_refinement'))
        if name in BODY_LAYERS:
            x, y, body = source['frames'][0][BODY_LAYERS[name]]
            manifest['assets'][name]['body_bounds'] = [x - foot[0], y - foot[1], *body.size]
    atlas = Image.new('RGBA', (1024, 128))
    offset = 0
    for name in ('knight', 'vagrant', 'monarch', 'cook'):
        sheet = Image.open(destination / f'{name}.png')
        atlas.alpha_composite(sheet, (offset, 0))
        manifest['assets'][name]['atlas_origin'] = [offset, 0]
        offset += sheet.width
    atlas.save(destination / 'actors.png')
    (destination / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=OUT)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    if args.check:
        with tempfile.TemporaryDirectory() as directory:
            export(Path(directory))
            expected = {p.name for p in Path(directory).iterdir()}
            obsolete = {p.name for p in args.output.glob('*.png')} - expected
            if obsolete:
                raise SystemExit(f'Obsolete runtime exports: {sorted(obsolete)}')
            for generated in Path(directory).iterdir():
                checked_in = args.output / generated.name
                if not checked_in.exists() or checked_in.read_bytes() != generated.read_bytes():
                    raise SystemExit(f'Outdated export: {checked_in}')
        print('Original sources and exports match byte for byte')
    else:
        export(args.output)
