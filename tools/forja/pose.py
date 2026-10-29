"""Pose nativa: coordenadas da tela, anatomia, apoios e oclusao separados (FORJA-16)."""
from __future__ import annotations

import math

from PIL import Image, ImageDraw

from . import contracts

SCHEMA = 'forja.pose/1'
JOINTS = ('NOSE', 'NECK', 'RIGHT SHOULDER', 'RIGHT ELBOW', 'RIGHT ARM', 'LEFT SHOULDER',
          'LEFT ELBOW', 'LEFT ARM', 'RIGHT HIP', 'RIGHT KNEE', 'RIGHT LEG', 'LEFT HIP',
          'LEFT KNEE', 'LEFT LEG', 'RIGHT EYE', 'LEFT EYE', 'RIGHT EAR', 'LEFT EAR')
BONES = ((0, 1), (1, 2), (2, 3), (3, 4), (1, 5), (5, 6), (6, 7), (1, 8), (8, 9),
         (9, 10), (1, 11), (11, 12), (12, 13), (0, 14), (14, 16), (0, 15), (15, 17))
BEHAVIORS = ('fixed', 'transported', 'articulated', 'deformable', 'effect')


def number(value: object) -> bool:
    return type(value) in (int, float) and math.isfinite(value)


def point(value: object, size: tuple | None = None) -> bool:
    return (isinstance(value, list) and len(value) == 2 and all(number(v) for v in value)
            and (size is None or all(0 <= v < s for v, s in zip(value, size))))


def box(value: object, size: tuple) -> bool:
    return (isinstance(value, list) and len(value) == 4 and all(type(v) is int for v in value)
            and 0 <= value[0] < value[2] <= size[0] and 0 <= value[1] < value[3] <= size[1])


def validate(data: dict) -> list[str]:
    if not isinstance(data, dict):
        return ['pose: esperado objeto']
    errors = [] if data.get('schema') == SCHEMA else [f'pose schema: esperado {SCHEMA}']
    try:
        c = contracts.get(data.get('kind'))
    except (KeyError, TypeError):
        return errors + ['pose kind desconhecido']
    if not c.canvas:
        return errors + ['pose exige contrato com tela fixa']
    if data.get('view') != 'side' or data.get('facing') not in ('left', 'right'):
        errors.append('pose: view side e facing left/right obrigatorios')
    points = data.get('points')
    if not isinstance(points, dict) or set(points) != set(JOINTS):
        return errors + ['pose points: exatamente as 18 articulacoes nomeadas']
    for name, value in points.items():
        if not point(value, c.canvas):
            errors.append(f'{name}: coordenada finita dentro de {c.canvas}')
    sockets = data.get('sockets', {})
    if not isinstance(sockets, dict):
        return errors + ['sockets: esperado objeto']
    if set(sockets) & set(points):
        errors.append('sockets nao substituem articulacoes')
    for name, value in sockets.items():
        if not point(value, c.canvas):
            errors.append(f'socket {name}: coordenada invalida')
    names = set(points) | set(sockets)
    for field in ('supports', 'occluded', 'inferred'):
        seq = data.get(field, [])
        if not isinstance(seq, list) or any(not isinstance(v, str) or v not in names for v in seq):
            errors.append(f'{field}: pontos desconhecidos')
        elif len(set(seq)) != len(seq):
            errors.append(f'{field}: pontos repetidos')
    order = data.get('parts_order', [])
    if (not isinstance(order, list) or any(not isinstance(p, str) or not p for p in order)
            or len(set(order)) != len(order)):
        errors.append('parts_order: lista de partes unicas, de tras para a frente')
    contacts = data.get('contacts', [])
    if not isinstance(contacts, list):
        return errors + ['contacts: esperado lista']
    for contact in contacts:
        if not isinstance(contact, dict):
            errors.append('contact: esperado objeto')
            continue
        if any(not isinstance(contact.get(k), str) or contact[k] not in names for k in ('point', 'target')):
            errors.append('contact: point e target devem nomear articulacoes/sockets')
        tolerance = contact.get('tolerance_px', 1)
        if not number(tolerance) or tolerance < 0:
            errors.append('contact tolerance_px: numero nao negativo')
    regions = data.get('regions', {})
    if not isinstance(regions, dict):
        return errors + ['regions: esperado objeto']
    for name, region in regions.items():
        if not isinstance(region, dict) or not box(region.get('box_px'), c.canvas):
            errors.append(f'region {name}: caixa invalida')
        elif region.get('behavior') not in BEHAVIORS:
            errors.append(f'region {name}: behavior desconhecido')
    return errors


def keypoints(data: dict) -> list[dict]:
    errors = validate(data)
    if errors:
        raise ValueError('; '.join(errors))
    w, h = contracts.get(data['kind']).canvas
    # Coordenadas de centros de pixels: extremos 0 e lado-1 mapeados para 0 e 1.
    return [{'label': name, 'x': data['points'][name][0] / (w - 1),
             'y': data['points'][name][1] / (h - 1)} for name in JOINTS]


def render(data: dict) -> Image.Image:
    errors = validate(data)
    if errors:
        raise ValueError('; '.join(errors))
    c = contracts.get(data['kind'])
    image = Image.new('RGBA', c.canvas)
    draw = ImageDraw.Draw(image)
    for a, b in BONES:
        draw.line([tuple(data['points'][JOINTS[a]]), tuple(data['points'][JOINTS[b]])],
                  fill=(56, 190, 220, 255))
    for name, xy in data['points'].items():
        color = (250, 184, 77, 255) if name in data.get('occluded', []) else (245, 245, 235, 255)
        draw.point(tuple(xy), fill=color)
    for name in data.get('supports', []):
        x, y = {**data['points'], **data.get('sockets', {})}[name]
        draw.line((x - 2, y, x + 2, y), fill=(85, 220, 120, 255))
    return image
