"""Medidas declaradas de apoio/contacto e provas raster; nunca aprovacao artistica automatica."""
from __future__ import annotations

import math

from PIL import Image

from . import anim, pose


def positions(p: dict) -> dict:
    return {**p['points'], **p.get('sockets', {})}


def analyze(clip: dict, images: list[Image.Image] | None = None, support_tolerance: float = 1.0) -> dict:
    if not pose.number(support_tolerance) or support_tolerance < 0:
        raise ValueError('tolerancia de apoio deve ser finita e nao negativa')
    findings, trajectories, previous = [], {}, {}
    for i, frame in enumerate(clip['frames']):
        p, root = frame['pose'], frame['root_px']
        points = positions(p)
        uncertain = set(p.get('occluded', []) + p.get('inferred', []))
        current = {}
        for name, xy in points.items():
            trajectories.setdefault(name, []).append(xy)
        for name in p.get('supports', []):
            xy = [points[name][j] + root[j] for j in (0, 1)]
            if name in uncertain:
                findings.append({'frame': i, 'code': 'support_unknown', 'point': name, 'status': 'pending'})
            else:
                current[name] = previous.get(name, xy)
                drift = math.dist(xy, current[name])
                if drift > support_tolerance:
                    findings.append({'frame': i, 'code': 'support_slide', 'point': name,
                                     'pixels': round(drift, 3), 'status': 'review'})
        previous = current
        for contact in p.get('contacts', []):
            a, b = contact['point'], contact['target']
            if a in uncertain or b in uncertain:
                findings.append({'frame': i, 'code': 'contact_unknown', 'point': a, 'status': 'pending'})
            else:
                distance = math.dist(points[a], points[b])
                if distance > contact.get('tolerance_px', 1):
                    findings.append({'frame': i, 'code': 'contact_gap', 'point': a, 'target': b,
                                     'pixels': round(distance, 3), 'status': 'review'})
    if images:
        if len(images) != len(clip['frames']):
            raise ValueError('quantidade de imagens difere do clip')
        for name, region in clip['frames'][0]['pose'].get('regions', {}).items():
            if region['behavior'] not in ('fixed', 'transported'):
                continue
            master = images[0].crop(region['box_px'])
            for i, image in enumerate(images[1:], 1):
                candidate = clip['frames'][i]['pose'].get('regions', {}).get(name)
                if candidate is None or candidate.get('behavior') != region['behavior']:
                    findings.append({'frame': i, 'code': 'region_unknown', 'region': name, 'status': 'pending'})
                    continue
                actual = image.crop(candidate['box_px'])
                equal = actual.size == master.size and actual.tobytes() == master.tobytes()
                moved = region['behavior'] == 'fixed' and candidate['box_px'] != region['box_px']
                if not equal or moved:
                    findings.append({'frame': i, 'code': 'region_changed', 'region': name, 'status': 'review'})
    return {'schema': 'forja.motion-review/1', 'basis': 'declared_points_plus_optional_rasters',
            'approval': 'pending', 'findings': findings, 'trajectories': trajectories,
            'support_tolerance_px': support_tolerance, 'loop': clip['loop'],
            'metrics': anim.metrics(images, loop=clip['loop']) if images else None,
            'notes': ['Pontos declarados nao provam que o raster os segue; conferir sobreposicao a 1x.',
                      'Apoio mede root_px + ponto local. A transicao de loop precisa da raiz do ciclo seguinte.']}


def transition(before: dict, after: dict, offset: list | None = None, tolerance: float = 1.0,
               from_frame: int = -1, to_frame: int = 0) -> dict:
    """Compara extremos declarados, incluindo interrupcoes; offset e a mudanca da raiz entre clips."""
    offset = [0, 0] if offset is None else offset
    if not pose.point(offset) or not pose.number(tolerance) or tolerance < 0:
        raise ValueError('offset/tolerancia invalidos')
    if before['kind'] != after['kind']:
        raise ValueError('transicao exige o mesmo contrato de personagem')
    try:
        a, b = before['frames'][from_frame], after['frames'][to_frame]
    except IndexError as err:
        raise ValueError('quadro da transicao fora da sequencia') from err
    pa, pb = a['pose'], b['pose']
    unknown = set(pa.get('inferred', []) + pa.get('occluded', []) + pb.get('inferred', []) + pb.get('occluded', []))
    points = {}
    for name in positions(pa).keys() & positions(pb).keys():
        start = [positions(pa)[name][j] + a['root_px'][j] for j in (0, 1)]
        end = [positions(pb)[name][j] + b['root_px'][j] + offset[j] for j in (0, 1)]
        distance = math.dist(start, end)
        points[name] = {'distance_px': round(distance, 3), 'status': 'pending' if name in unknown
                        else 'review' if distance > tolerance else 'measured'}
    return {'schema': 'forja.transition-review/1', 'approval': 'pending', 'points': points,
            'offset_px': offset, 'from_frame': from_frame, 'to_frame': to_frame,
            'direction_changed': pa['facing'] != pb['facing'], 'tolerance_px': tolerance,
            'note': 'Distancia declarada e triagem; conferir raster, equipamento e interrupcao no motor.'}
