"""A corda pode ser reta e estar presa no vazio: conferir tambem as duas pontas na madeira."""
from __future__ import annotations

from . import masks


def check(item: dict, obs: dict) -> dict:
    iid = item['id']
    names = [f'{iid}.{p}' for p in ('limb', 'grip')]
    limb, grip = (obs['regions'].get(n) for n in names)
    tips = [obs['anchors'].get(f'{iid}.{name}') for name in item['anchors']]
    result = {'axis': 'equipment_geometry', 'check': 'bow_nocks', 'item': iid, 'part': 'limb',
              'status': 'not_evaluated', 'detail': f'{iid}: faltam pontas, madeira ou empunhadura observadas',
              'evidence': {}}
    if any(p is None for p in tips) or limb is None or grip is None:
        return result
    a, b = tips
    wood = limb | grip
    loose = [name for name, point in zip(item['anchors'], tips)
             if (masks.distance(wood, {point}) or 0) > 1 or not wood]
    reasons = ([f'corda sem contacto com a madeira em {", ".join(loose)}'] if loose else [])
    if a == b:
        reasons.append('as duas pontas do arco coincidem')
    if grip and a != b:
        center = tuple(sum(p[axis] for p in grip) / len(grip) for axis in (0, 1))
        dx, dy = b[0] - a[0], b[1] - a[1]
        t = ((center[0] - a[0]) * dx + (center[1] - a[1]) * dy) / (dx * dx + dy * dy)
        if not 0 < t < 1:
            reasons.append('empunhadura nao esta entre as duas pontas')
        result['evidence']['grip_projection'] = round(t, 3)
    elif not grip:
        result.update(status='inconclusive', detail=f'{iid}: empunhadura nao observada, possivelmente tapada')
        return result
    result.update(status='fail' if reasons else 'pass',
                  detail=f'{iid}: ' + ('; '.join(reasons) if reasons else 'duas pontas ligadas a madeira e pega entre elas'))
    result['evidence'].update(loose=loose, tips=[list(a), list(b)])
    if result['status'] == 'pass' and any(n in obs['uncertain'] for n in names):
        result.update(status='inconclusive', detail=result['detail'] + ' (observacao incerta)')
    return result
