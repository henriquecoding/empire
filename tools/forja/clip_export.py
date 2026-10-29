"""Pacote de revisao: timeline, Aseprite em camadas, SpriteFrames e proveniencia exata."""
from __future__ import annotations

import base64
import copy
import json
import shutil
import subprocess
from pathlib import Path

from PIL import Image

from . import anim, ase, choreography, contracts, godot, lint, motion_review, palette, pose
from .backends import digest, sha
from .imageops import png_bytes

ROOT = Path(__file__).resolve().parents[2]
VIEWER = ROOT / 'tools/web/site/forja'


def commit() -> str | None:
    result = subprocess.run(['git', 'rev-parse', 'HEAD'], cwd=ROOT, capture_output=True, text=True, check=False)
    return result.stdout.strip() if result.returncode == 0 else None


def uri(image: Image.Image) -> str:
    return 'data:image/png;base64,' + base64.b64encode(png_bytes(image)).decode('ascii')


def package(clip: dict, images: list[bytes], base: Path, folder: Path, source: dict | None = None,
            register: dict | None = None) -> dict:
    validation = choreography.require(clip, base, register)
    frames = choreography.returned(clip, images)
    reference_raw = (base / clip['reference']['file']).read_bytes()
    original_hash = digest(clip)
    clip = copy.deepcopy(clip)
    clip['reference']['file'] = 'identity.png'
    c = contracts.get(clip['kind'])
    folder.mkdir(parents=True, exist_ok=True)
    (folder / 'identity.png').write_bytes(reference_raw)
    (folder / 'frames').mkdir(exist_ok=True)
    for i, raw in enumerate(images):
        (folder / 'frames' / f'{i:03d}.png').write_bytes(raw)
    name, durations = clip['id'], [f['duration_ms'] for f in clip['frames']]
    tags = [(clip['action'], 0, len(frames) - 1, 'forward')]
    files = anim.export(frames, folder, name, durations, tags, c.pivot, previews=False)
    sheet, rects = anim.strip(frames)
    godot.write(folder / (name + '.tres'), godot.sprite_frames('res://' + name + '.png', rects, durations,
                tags, fps=contracts.tag(clip['action'])['fps'], loops={clip['action']: clip['loop']}))
    guides = [pose.render(f['pose']) for f in clip['frames']]
    sprite = ase.build(c.canvas, [('body', frames), (ase.Layer('pose-guides', flags=66), guides)], durations)
    sprite.tags = [ase.Tag(clip['action'], 0, len(frames) - 1, repeat=0 if clip['loop'] else 1)]
    sprite.user = ase.UserData(text=json.dumps({'clip_sha256': digest(clip), 'loop': clip['loop'],
                                               'approval': 'pending', 'source': source or {'method': 'import'}}))
    sprite.slices = [ase.Slice('pivot', [ase.SliceKey(0, 0, 0, *c.canvas, pivot=c.pivot)])]
    sockets = sorted({n for f in clip['frames'] for n in f['pose'].get('sockets', {})})
    for socket in sockets:
        keys = [ase.SliceKey(i, round(xy[0]), round(xy[1]), 1, 1) for i, f in enumerate(clip['frames'])
                if (xy := f['pose'].get('sockets', {}).get(socket)) is not None]
        sprite.slices.append(ase.Slice(socket, keys))
    ase.write(sprite, folder / (name + '.aseprite'))
    review = motion_review.analyze(clip, frames)
    pal = palette.load(palette.ROOT / c.palette) if c.palette else None
    review['raster_contracts'] = [lint.check(frame, c, pal, frame=False) for frame in frames]
    review['raster_contract_ok'] = all(r['ok'] for r in review['raster_contracts'])
    # Nao exigir um pivot de pe num salto/queda. Tela, tempos e raiz pertencem ao clip.
    for i, raster in enumerate(review['raster_contracts']):
        for finding in raster['findings']:
            if finding['severity'] == 'error':
                review['findings'].append({'frame': i, 'code': 'raster_contract', 'status': 'review',
                                           'message': finding['message'], 'rule': finding['rule']})
    data = {'schema': 'forja.review-package/1', 'id': name, 'commit': commit(), 'clip_sha256': digest(clip),
            'input_clip_sha256': original_hash, 'clip': clip, 'canvas': list(c.canvas),
            'pivot': list(c.pivot), 'loop': clip['loop'],
            'approval': 'pending', 'authority': validation['authority'], 'source': source or {'method': 'import'},
            'reference': 'data:image/png;base64,' + base64.b64encode(reference_raw).decode('ascii'),
            'frames': [{'image': 'data:image/png;base64,' + base64.b64encode(raw).decode('ascii'), 'sha256': sha(raw),
                         'duration_ms': duration, 'pose': frame['pose'], 'phase': frame.get('phase', '')}
                        for im, raw, duration, frame in zip(frames, images, durations, clip['frames'])],
            'review': review}
    (folder / 'clip.json').write_text(json.dumps(clip, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
    write_review(data, folder)
    files.update(aseprite=str(folder / (name + '.aseprite')), godot=str(folder / (name + '.tres')),
                 review=str(folder / 'review.json'), viewer=str(folder / 'index.html'))
    return {'ok': True, 'raster_contract_ok': review['raster_contract_ok'], 'files': files, 'review': review,
            'approval': 'pending', 'package_sha256': data['package_sha256']}


def write_review(data: dict, folder: Path) -> None:
    data['package_sha256'] = digest(data)
    (folder / 'review.json').write_text(json.dumps(data, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
    for file in ('index.html', 'viewer.js', 'viewer.css', 'review-model.js', 'renderer.js'):
        shutil.copyfile(VIEWER / file, folder / file)
