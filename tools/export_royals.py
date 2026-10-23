#!/usr/bin/env python3
"""Import the owner's V15 delivery without redrawing, trimming or retiming its frames."""
import argparse
import hashlib
import io
import json
from pathlib import Path
from zipfile import ZipFile
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'art/export/royals'
SOURCE = ROOT / 'art/source/royals_v15'
PREFIX = 'res://art/export/royals/'
PROFILES = dict(rei='royal_king', escudeiro='royal_squire', nia='royal_nia',
                bardo='royal_bard', arqueiro='royal_archer', intendente='royal_quiver',
                sombra='royal_shadow', dancarina='royal_dancer')
ALIASES = dict(arqueiro={'attack': 'shoot'}, escudeiro={'attack': 'block'},
               bardo={'work': 'play'}, intendente={'work': 'deliver'})


def digest(payload):
    return hashlib.sha256(payload).hexdigest()


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n')


def import_package(path):
    OUT.mkdir(parents=True, exist_ok=True)
    SOURCE.mkdir(parents=True, exist_ok=True)
    manifest = {'version': 15, 'package_sha256': digest(path.read_bytes()), 'assets': {},
                'files': {}, 'source': 'EMPIRE-ANIMACOES-64-80-V15(1).zip'}
    with ZipFile(path) as archive:
        top = 'EMPIRE-ANIMACOES-V15/'
        def read(name):
            return archive.read(top + name)
        def copy(name, target):
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(read(name))
        for name in ['manifest.json', 'LEIA-ME.md', 'verificacao.json']:
            copy(name, SOURCE / name)
        for who, profile in PROFILES.items():
            base = f'personagens/{who}/'
            meta = json.loads(read(base + 'animacoes.json'))
            copy(base + who + '.aseprite', SOURCE / (who + '.aseprite'))
            copy(base + 'animacoes.json', SOURCE / (who + '.json'))
            payload = read(base + 'atlas.png')
            target = OUT / (who + '.png')
            target.write_bytes(payload)
            image = Image.open(io.BytesIO(payload)).convert('RGBA')
            mask = Image.new('RGBA', image.size, 'white')
            mask.putalpha(image.getchannel('A'))
            mask.save(OUT / (who + '_mask.png'))
            frames = [None] * meta['frameCount']
            tags, events, loops, mirrors = {}, {}, {}, {}
            for action in meta['animations']:
                indices = [f['atlasIndex'] for f in action['frames']]
                tags[action['name']] = {'from_frame': indices[0], 'to_frame': indices[-1]}
                loops[action['name']] = action['loop']
                events[action['name']] = action.get('events', [])
                for f in action['frames']:
                    rect = f['rect']
                    crop = image.crop((rect['x'], rect['y'], rect['x']+rect['w'], rect['y']+rect['h']))
                    if digest(crop.tobytes()) != f['rgbaSha256']:
                        raise ValueError(f'Frame pixels differ: {who}/{action["name"]}/{f["index"]}')
                    frames[f['atlasIndex']] = {'origin': [rect['x'], rect['y']],
                                              'duration': f['durationMs'], 'pivot': action['pivot']}
                if action['direction'] == 'right':
                    tags[action['action']] = tags[action['name']]
                    loops[action['action']] = action['loop']
                    events[action['action']] = action.get('events', [])
                    left = next(a for a in meta['animations'] if a['name'] == action['action']+'_left')
                    for r, l in zip(action['frames'], left['frames']):
                        mirrors[str(r['atlasIndex'])] = l['atlasIndex']
            if any(f is None for f in frames):
                raise ValueError(f'Missing timeline entries: {who}')
            for alias, actual in ALIASES.get(who, {}).items():
                tags[alias], loops[alias], events[alias] = tags[actual], loops[actual], events[actual]
            tags['flee'], loops['flee'] = tags['walk'], True
            first = meta['animations'][0]
            f = first['frames'][0]['rect']
            occupied = image.crop((f['x'],f['y'],f['x']+f['w'],f['y']+f['h'])).getbbox()
            pivot = first['pivot']
            manifest['assets'][profile] = {
                'root': PREFIX, 'texture': who+'.png', 'atlas_texture': who+'.png',
                'mask_texture': who+'_mask.png', 'atlas_origin': [0,0],
                'size': [meta['width'], meta['height']], 'foot': pivot,
                'body_bounds': [occupied[0]-pivot[0], occupied[1]-pivot[1],
                                occupied[2]-occupied[0], occupied[3]-occupied[1]],
                'frame_origins': [f['origin'] for f in frames],
                'frame_pivots': [f['pivot'] for f in frames],
                'durations_ms': [f['duration'] for f in frames],
                'tags': tags, 'loops': loops, 'events': events, 'mirrors': mirrors,
                'authored_animation': True, 'source_character': who,
                'rgba_sha256': digest(image.tobytes())}
        copy('efeitos/jardim-padrao.json', OUT / 'garden.json')
        plants = json.loads(read('efeitos/plantas/plantas.json'))
        for variant in plants['variants']:
            copy('efeitos/plantas/'+variant['id']+'/atlas.png', OUT/'plants'/(variant['id']+'.png'))
            copy('efeitos/plantas/'+variant['id']+'/'+variant['id']+'.aseprite',
                 SOURCE/'plants'/(variant['id']+'.aseprite'))
        write_json(OUT/'plants.json', plants)
        # Retain source timelines for the composed effect as well as editable sources.
        for name in ['flores.aseprite', 'sombra-cura-composta.aseprite', 'sombra-cura-composta.json']:
            copy('efeitos/'+name, SOURCE/name)
    for file in sorted(OUT.rglob('*')):
        if file.is_file() and file.name != 'manifest.json' and '.import' not in file.name:
            manifest['files'][str(file.relative_to(OUT))] = digest(file.read_bytes())
    write_json(OUT/'manifest.json', manifest)
    print(f'V15: {len(manifest["assets"])} characters, '+
          f'{sum(len(a["durations_ms"]) for a in manifest["assets"].values())} timeline entries imported')


def check():
    manifest = json.loads((OUT/'manifest.json').read_text())
    assert manifest['version'] == 15 and len(manifest['assets']) == len(PROFILES)
    attributes = (ROOT/'.gitattributes').read_text()
    assert 'art/export/royals/**/*.png -filter -diff -merge binary' in attributes
    assert 'art/source/royals_v15/**/*.aseprite -filter -diff -merge binary' in attributes
    for name, checksum in manifest['files'].items():
        assert digest((OUT/name).read_bytes()) == checksum, name
    for profile, item in manifest['assets'].items():
        image = Image.open(OUT/item['texture']).convert('RGBA')
        assert digest(image.tobytes()) == item['rgba_sha256'], profile
        assert len(item['frame_origins']) == len(item['durations_ms']) == len(item['frame_pivots'])
        assert set(image.getchannel('A').get_flattened_data()).issubset({0,255}), profile
        for i, (x,y) in enumerate(item['frame_origins']):
            assert x+item['size'][0] <= image.width and y+item['size'][1] <= image.height
            assert item['durations_ms'][i] > 0
        assert 'art/export/royals/*.json' in (ROOT/'export_presets.cfg').read_text()
    print('V15: source pixels, checksums, pivots, timings and export filters verified')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('package', nargs='?', type=Path)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    if args.check:
        check()
    elif args.package:
        import_package(args.package)
    else:
        parser.error('Provide the V15 ZIP, or --check')
