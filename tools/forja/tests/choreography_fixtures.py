"""Corpos de teste: pontos e pixels sinteticos, sem autoridade artistica."""
import hashlib

from PIL import Image


LABELS = ('NOSE', 'NECK', 'RIGHT SHOULDER', 'RIGHT ELBOW', 'RIGHT ARM', 'LEFT SHOULDER',
          'LEFT ELBOW', 'LEFT ARM', 'RIGHT HIP', 'RIGHT KNEE', 'RIGHT LEG', 'LEFT HIP',
          'LEFT KNEE', 'LEFT LEG', 'RIGHT EYE', 'LEFT EYE', 'RIGHT EAR', 'LEFT EAR')


def pose(kind='royal_80') -> dict:
    side = 80 if kind == 'royal_80' else 64
    return {'schema': 'forja.pose/1', 'id': 'standing', 'kind': kind, 'view': 'side',
            'facing': 'right', 'points': {k: [side // 2, side - 2] for k in LABELS},
            'supports': ['RIGHT LEG'], 'sockets': {'grip': [side // 2, side - 2]},
            'parts_order': ['body', 'weapon'], 'contacts': [], 'regions': {}}


def clip(folder, action='attack', count=5, kind='royal_80') -> dict:
    side = 80 if kind == 'royal_80' else 64
    path = folder / 'identity.png'
    Image.new('RGBA', (side, side), (20, 30, 40, 255)).save(path)
    return {'schema': 'forja.clip/1', 'id': action, 'kind': kind, 'action': action,
            'description': 'test mannequin', 'loop': action in ('idle', 'walk'),
            'reference': {'file': path.name, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
                          'pose': pose(kind)},
            'frames': [{'pose': pose(kind), 'duration_ms': 100, 'root_px': [0, 0]}
                       for _ in range(count)]}
