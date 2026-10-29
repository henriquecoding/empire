"""Componentes e interacoes do forja.scene/1: a arquitetura fica, o movimento e local."""
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image

from . import pose
from .backends import sha

ROLES = ('structure', 'material', 'decoration', 'effect')


def validate(data: dict, base: Path) -> list[str]:
    size, errors = data.get('extent_px'), []
    if not isinstance(size, list) or len(size) != 2 or any(type(v) is not int or v < 1 for v in size):
        return ['extent_px: duas dimensoes inteiras positivas']
    components = data.get('components', [])
    if not isinstance(components, list):
        return ['components: esperado lista']
    ids = set()
    for component in components:
        if not isinstance(component, dict):
            errors.append('component: esperado objeto')
            continue
        ident = component.get('id')
        if not isinstance(ident, str) or not ident or ident in ids:
            errors.append('component id em falta/repetido')
            continue
        ids.add(ident)
        region = component.get('region_px')
        if not pose.box(region, size):
            errors.append(f'{ident}: region_px fora da cena')
            continue
        if component.get('role') not in ROLES or type(component.get('layer')) is not int:
            errors.append(f'{ident}: role e layer inteiro obrigatorios')
        if not pose.point(component.get('anchor_px'), size):
            errors.append(f'{ident}: anchor_px fora da cena')
            continue
        frames = component.get('frames', [])
        if not isinstance(frames, list):
            errors.append(f'{ident}: frames deve ser lista')
            continue
        if frames and type(component.get('loop')) is not bool:
            errors.append(f'{ident}: declarar loop')
        for i, frame in enumerate(frames):
            if not isinstance(frame, dict):
                errors.append(f'{ident}/{i}: esperado objeto')
                continue
            if type(frame.get('duration_ms')) is not int or not 1 <= frame['duration_ms'] <= 65535:
                errors.append(f'{ident}/{i}: duration_ms invalida')
            local = frame.get('anchor_px')
            crop_size = (region[2] - region[0], region[3] - region[1])
            if not pose.point(local, crop_size) or [local[j] + region[j] for j in (0, 1)] != component['anchor_px']:
                errors.append(f'{ident}/{i}: ancora deslocada')
            try:
                path = base / frame.get('file', '')
                if sha(path.read_bytes()) != frame.get('sha256'):
                    errors.append(f'{ident}/{i}: hash alterado')
                with Image.open(path) as im:
                    if im.size != crop_size:
                        errors.append(f'{ident}/{i}: imagem deve medir {crop_size}')
            except (OSError, ValueError, TypeError) as err:
                errors.append(f'{ident}/{i}: {err}')
    interactions = data.get('interactions', [])
    if not isinstance(interactions, list):
        return errors + ['interactions: esperado lista']
    for entry in interactions:
        if not isinstance(entry, dict):
            errors.append('interaction: esperado objeto')
            continue
        if not all(pose.point(entry.get(k), size) for k in ('point_px', 'target_px')):
            errors.append('interaction: ponto e alvo dentro da cena')
        if type(entry.get('observed')) is not bool:
            errors.append('interaction: declarar observed, sem presumir observacao')
        tolerance = entry.get('tolerance_px', 1)
        if not pose.number(tolerance) or tolerance < 0:
            errors.append('interaction: tolerance_px invalida')
    return errors


def rules(data: dict) -> list[dict]:
    return [{'id': 'component:' + c['id'], 'origin': 'scene:components',
             'text': f"Component {c['id']} ({c['role']}), region {c['region_px']} screen pixels, "
                     f"anchor {c['anchor_px']}, layer {c['layer']} back-to-front. "
                     'Keep the structure outside this region unchanged; author motion separately.'}
            for c in data.get('components', [])]


def review(data: dict, master: Image.Image, candidates: list[Image.Image]) -> dict:
    mask = Image.new('1', master.size)
    from PIL import ImageDraw
    draw = ImageDraw.Draw(mask)
    for c in data.get('components', []):
        if c.get('frames'):
            x0, y0, x1, y1 = c['region_px']
            draw.rectangle((x0, y0, x1 - 1, y1 - 1), fill=1)
    protected = list(mask.get_flattened_data())
    original = list(master.convert('RGBA').get_flattened_data())
    changes = []
    for candidate in candidates:
        if candidate.size != master.size:
            raise ValueError('tela da cena mudou')
        changes.append(sum(a != b and not allowed for a, b, allowed in
                           zip(original, candidate.convert('RGBA').get_flattened_data(), protected)))
    interactions = []
    for entry in data.get('interactions', []):
        distance = math.dist(entry['point_px'], entry['target_px'])
        status = ('pending' if not entry['observed'] else
                  'review' if distance > entry.get('tolerance_px', 1) else 'measured')
        interactions.append({'id': entry.get('id'), 'status': status, 'distance_px': round(distance, 3)})
    return {'schema': 'forja.scene-motion-review/1', 'ok': not any(changes), 'outside_changes': changes,
            'interactions': interactions, 'approval': 'pending',
            'notes': ['Mascara preservada nao aprova a leitura da cena; conferir atores, oclusao e luz no motor.']}


def compose(data: dict, master: Image.Image, base: Path, duration_ms: int | None = None) -> tuple[list, list]:
    errors = validate(data, base)
    if errors:
        raise ValueError('; '.join(errors))
    if list(master.size) != data['extent_px']:
        raise ValueError('base deve ter a extensao da cena em pixels de ecra')
    components = sorted((c for c in data.get('components', []) if c.get('frames')), key=lambda c: c['layer'])
    if not components:
        raise ValueError('nenhum componente com quadros')
    totals = [sum(f['duration_ms'] for f in c['frames']) for c in components]
    if duration_ms is None:
        duration_ms = math.lcm(*totals) if all(c['loop'] for c in components) else max(totals)
    if type(duration_ms) is not int or not 1 <= duration_ms <= 60000:
        raise ValueError('duracao da montagem deve ser 1-60000 ms; declare --duration-ms para ciclos longos')
    times = {0, duration_ms}
    for c, total in zip(components, totals):
        for start in range(0, duration_ms, total) if c['loop'] else [0]:
            t = start
            for f in c['frames']:
                t += f['duration_ms']
                if t < duration_ms:
                    times.add(t)
    times = sorted(times)
    if len(times) > 601 or master.width * master.height * 4 * len(times) > 256 * 1024 * 1024:
        raise ValueError('montagem excede 600 quadros ou 256 MiB; reduza a duracao, nao a grade')
    loaded = {}
    for c in components:
        for f in c['frames']:
            with Image.open(base / f['file']) as im:
                loaded[f['file']] = im.convert('RGBA')
    images = []
    for t in times[:-1]:
        canvas = master.convert('RGBA').copy()
        for c, total in zip(components, totals):
            elapsed = t % total if c['loop'] else min(t, total - 1)
            for frame in c['frames']:
                if elapsed < frame['duration_ms']:
                    canvas.alpha_composite(loaded[frame['file']], tuple(c['region_px'][:2]))
                    break
                elapsed -= frame['duration_ms']
        images.append(canvas)
    return images, [b - a for a, b in zip(times, times[1:])]
