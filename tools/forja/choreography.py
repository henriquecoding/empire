"""Sequencias com contrato e identidade explicitos; gerar, retomar e conferir antes de exportar."""
from __future__ import annotations

import io
import json
import re
from pathlib import Path

from PIL import Image

from . import contracts, durable, jobs, pose, refs
from .backends import digest, sha

SCHEMA = 'forja.clip/1'


def load(path: str | Path) -> dict:
    return json.loads(Path(path).read_text(encoding='utf-8'))


def validate(data: dict, base: Path, register: dict | None = None) -> dict:
    errors, warnings = [], []
    if not isinstance(data, dict) or data.get('schema') != SCHEMA:
        return {'errors': [f'schema: esperado {SCHEMA}'], 'warnings': []}
    if not isinstance(data.get('id'), str) or not re.fullmatch(r'[a-zA-Z0-9_-]+', data['id']):
        errors.append('id: letras, numeros, _ ou -')
    try:
        contract = contracts.get(data.get('kind'))
    except (KeyError, TypeError):
        return {'errors': errors + ['kind desconhecido'], 'warnings': []}
    action = contracts.tag(data['action']) if isinstance(data.get('action'), str) else {}
    frames = data.get('frames')
    if not isinstance(action, dict) or 'frames' not in action:
        errors.append('action: tag inexistente no contrato do Empire')
    if not isinstance(frames, list) or not frames:
        return {'errors': errors + ['frames: lista nao vazia obrigatoria'], 'warnings': []}
    if action and isinstance(action, dict):
        if len(frames) != action['frames']:
            errors.append(f"quadros: {len(frames)}, contrato exige {action['frames']}")
        if type(data.get('loop')) is not bool or data['loop'] != action['loop']:
            errors.append('loop difere do contrato da acao')
    ref = data.get('reference')
    if not isinstance(ref, dict):
        return {'errors': errors + ['reference obrigatoria'], 'warnings': []}
    rp = ref.get('pose', {})
    errors += ['reference: ' + e for e in pose.validate(rp)]
    for i, frame in enumerate(frames):
        if not isinstance(frame, dict):
            errors.append(f'quadro {i}: esperado objeto')
            continue
        p = frame.get('pose', {})
        errors += [f'quadro {i}: {e}' for e in pose.validate(p)]
        if isinstance(p, dict):
            if p.get('kind') != data.get('kind'):
                errors.append(f'quadro {i}: kind diferente do clip')
            if isinstance(rp, dict) and any(p.get(k) != rp.get(k) for k in ('facing', 'view')):
                errors.append(f'quadro {i}: camera/direcao diferente da referencia')
            if p.get('inferred') or p.get('occluded'):
                warnings.append(f'quadro {i}: pontos inferidos/ocultos exigem revisao')
        if type(frame.get('duration_ms')) is not int or not 0 < frame['duration_ms'] <= 65535:
            errors.append(f'quadro {i}: duration_ms inteiro de 1 a 65535')
        if not pose.point(frame.get('root_px')):
            errors.append(f'quadro {i}: root_px explicito [x,y] para medir apoio no mundo')
    if isinstance(rp, dict) and rp.get('kind') != data.get('kind'):
        errors.append('reference pose: kind diferente do clip')
    durations = [f.get('duration_ms') for f in frames if isinstance(f, dict)]
    if action and isinstance(action, dict) and len(durations) == len(frames) and all(pose.number(v) for v in durations):
        expected = action['frames'] * 1000 / action['fps']
        if abs(sum(durations) - expected) > 1:
            errors.append(f'duracao total difere dos {expected:g} ms do contrato')
    authority = None
    try:
        path = base / ref.get('file', '')
        raw = path.read_bytes()
        if sha(raw) != ref.get('sha256'):
            errors.append('reference: hash alterado; reveja a imagem exata')
        with Image.open(io.BytesIO(raw)) as im:
            if im.format != 'PNG':
                errors.append('reference: esperado PNG nativo')
            if im.size != contract.canvas:
                errors.append(f'reference: tela {im.size} difere de {contract.canvas}')
            if not im.convert('RGBA').getchannel('A').getbbox():
                errors.append('reference: imagem vazia')
        _, authority, error = refs.resolve('identity', raw, register)
        if error:
            errors.append(error)
    except (OSError, ValueError, TypeError) as err:
        errors.append(f'reference: {err}')
    if not isinstance(data.get('description'), str) or not data['description'].strip():
        errors.append('description: aparencia da identidade obrigatoria')
    return {'errors': errors, 'warnings': warnings, 'authority': authority}


def require(data: dict, base: Path, register: dict | None = None) -> dict:
    report = validate(data, base, register)
    if report['errors']:
        raise ValueError('; '.join(report['errors']))
    return report


def returned(data: dict, images: list[bytes]) -> list[Image.Image]:
    if len(images) != len(data['frames']):
        raise ValueError(f"quadros recebidos {len(images)}; esperados {len(data['frames'])}; nada foi exportado")
    expected = contracts.get(data['kind']).canvas
    frames = []
    for i, raw in enumerate(images):
        with Image.open(io.BytesIO(raw)) as image:
            if image.format != 'PNG':
                raise ValueError(f'quadro {i}: esperado PNG')
            if image.size != expected:
                raise ValueError(f'quadro {i}: tela {image.size}; esperada {expected}')
            image.load()
            frames.append(image.convert('RGBA'))
    return frames


def generate(data: dict, base: Path, folder: Path, method: str = 'skeleton-v3',
             register: dict | None = None, max_calls: int = 1, max_usd: float | None = None,
             seed: int = 0, transport=None, **kw) -> dict:
    from .backends import pixellab_animation
    report = require(data, base, register)
    if type(max_calls) is not int or max_calls <= 0:
        raise ValueError('max_calls: inteiro positivo')
    if max_usd is not None and (not pose.number(max_usd) or max_usd <= 0):
        raise ValueError('max_usd: numero positivo')
    call = pixellab_animation.call((base / data['reference']['file']).read_bytes(), data, method, seed)
    intent = folder / 'animation-request.json'
    # A pasta e uma intencao local unica. Retomar/reexecutar consulta o mesmo job.
    with durable.locked(intent):
        if intent.exists():
            record = load(intent)
            if record['request_sha256'] != digest(call.descriptor):
                raise ValueError('pasta pertence a outro pedido; use nova pasta para outra intencao')
            job = jobs.load(folder / 'jobs' / (record['job_id'] + '.json'))
        else:
            job = jobs.create(call, folder, {'clip': data, 'review': 'pending'})
            durable.write_text(intent, json.dumps({'job_id': job.id, 'request_sha256': digest(call.descriptor)}))
        budget = jobs.Budget.saved(folder) or jobs.Budget.open(folder, max_calls, max_usd)
        images = jobs.execute(job, call, transport, poll=pixellab_animation.poll_call, budget=budget, **kw)
        returned(data, images)
        return {'images': images, 'job': job.data, 'authority': report['authority'],
                'warnings': report['warnings'], 'approval': 'pending'}
