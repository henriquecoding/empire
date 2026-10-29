"""Roteiros editaveis de estudo; nunca poses aprovadas de um personagem."""
from __future__ import annotations

import copy
from pathlib import Path

from . import contracts, pose, pose_recipes
from .backends import sha

PHASES = {
    'idle': ('rest', 'inhale', 'inhale', 'hold', 'exhale', 'rest'),
    'walk': ('contact', 'down', 'passing', 'up', 'contact', 'down', 'passing', 'up'),
    'attack': ('guard', 'anticipation', 'action', 'follow-through', 'recover'),
    'die': ('hit', 'lose-support', 'fall', 'lower', 'settle', 'rest', 'rest'),
}
STANDING = ((.56, .22), (.50, .34), (.46, .35), (.42, .49), (.46, .61),
            (.55, .35), (.59, .49), (.65, .59), (.47, .60), (.43, .77), (.40, .97),
            (.54, .60), (.58, .77), (.62, .97), (.55, .20), (.58, .20), (.49, .22), (.52, .22))


def create(reference: Path, kind: str, action: str, description: str, facing: str = 'right') -> dict:
    if action not in PHASES:
        raise ValueError('receitas: ' + ', '.join(PHASES))
    c, timing = contracts.get(kind), contracts.tag(action)
    if not c.canvas:
        raise ValueError('receita exige tela fixa')
    w, h = c.canvas
    points = {name: [round(x * (w - 1)), round(y * (h - 1))] for name, (x, y) in zip(pose.JOINTS, STANDING)}
    if facing == 'left':
        points = {k: [w - 1 - xy[0], xy[1]] for k, xy in points.items()}
    standing = {'schema': pose.SCHEMA, 'id': 'reference-to-adjust', 'kind': kind, 'view': 'side',
                'facing': facing, 'points': points, 'supports': [], 'contacts': [], 'parts_order': [],
                'sockets': {}, 'regions': {}, 'inferred': list(pose.JOINTS), 'occluded': []}
    frames = []
    for i, phase in enumerate(PHASES[action]):
        p = copy.deepcopy(standing)
        p['id'] = f'{action}-{i:02d}-{phase}'
        geometry = pose_recipes.points(STANDING, action, i)
        p['points'] = {name: [round((1 - x if facing == 'left' else x) * (w - 1)), round(y * (h - 1))]
                       for name, (x, y) in zip(pose.JOINTS, geometry)}
        frames.append({'pose': p, 'duration_ms': round(1000 / timing['fps']), 'root_px': [0, 0], 'phase': phase})
    return {'schema': 'forja.clip/1', 'id': action, 'kind': kind, 'action': action,
            'description': description, 'loop': timing['loop'], 'frames': frames,
            'reference': {'file': str(reference.resolve()), 'sha256': sha(reference.read_bytes()), 'pose': standing},
            'study': True, 'notes': ['Ajustar a pose da referencia aos pixels e editar cada fase antes de gerar.',
                                     'Pontos inferidos; nao sao poses aprovadas nem evidencia de movimento.']}
