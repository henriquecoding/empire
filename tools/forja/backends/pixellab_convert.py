"""Conversao com output_size nativo; contrato publico de 28/10, sem redimensionamento local ou POST de prova."""
from __future__ import annotations

import io

from PIL import Image

from . import Call, http, image_refs
from . import pixellab_api as api
from ..imageops import from_bytes, png_bytes

MODEL = 'image-to-pixelart'


def source_size(source: bytes) -> tuple[int, int]:
    with Image.open(io.BytesIO(source)) as image:
        return image.size


def check(source: bytes, width: int, height: int, strength: int = 200) -> list[str]:
    iw, ih = source_size(source)
    errors = []
    if not (16 <= iw <= 2048 and 16 <= ih <= 2048):
        errors.append(f'conversion input {iw}x{ih}: cada lado tem de estar entre 16 e 2048')
    if not (16 <= width <= 512 and 16 <= height <= 512):
        errors.append(f'conversion output {width}x{height}: cada lado tem de estar entre 16 e 512')
    if type(strength) is not int or not 0 <= strength <= 999:
        errors.append('conversion init_image_strength: inteiro de 0 a 999')
    return errors


def call(source: bytes, width: int, height: int, strength: int = 200, seed: int | None = None) -> Call:
    errors = check(source, width, height, strength)
    if errors:
        raise ValueError('; '.join(errors))
    iw, ih = source_size(source)
    params = {'image_size': {'width': iw, 'height': ih}, 'output_size': {'width': width, 'height': height},
              'fixer': True, 'init_image_strength': strength}
    if seed is not None:
        if type(seed) is not int or seed < 0:
            raise ValueError('conversion seed: inteiro nao negativo')
        params['seed'] = seed
    body = {**params, 'image': {'type': 'base64', 'base64': http.b64(source), 'format': 'png'}}
    url = f'{api.BASE}/{MODEL}'
    descriptor = {'endpoint': url, 'model': MODEL, 'spec_sha256': api.SPEC_SHA256, 'params': params,
                  'images': image_refs([('conversion_source', source)])}
    return Call('pixellab', MODEL, lambda: http.json_request('POST', url, body, api._headers()),
                api.parse, descriptor, api.REFUSED)


def prepare(d: dict, contract, references, init_strength, seed) -> list[tuple[str, bytes]]:
    sources = [(role, data) for role, data in references if role not in ('style', 'palette', 'layout')]
    if len(sources) != 1:
        d['errors'].append('image-to-pixelart requires exactly one source concept or identity image')
        return []
    if any(role in ('style', 'palette', 'layout') for role, _ in references):
        d['errors'].append('image-to-pixelart does not accept style or layout reference images')
    if not contract.canvas or d['frames'] != 1:
        d['errors'].append('image-to-pixelart requires one static native canvas')
        return []
    if d['fidelity_prompt'].get('reference_repairs'):
        d['errors'].append('image-to-pixelart cannot receive text repair instructions: repair the known reference '
                           'defect in a verified local edit before conversion; it must not be copied silently')
    if any(k in d['fidelity_prompt'] for k in ('max_colors', 'tones')):
        d['errors'].append('image-to-pixelart has no color-count or tone-count field; not sent silently')
    source = png_bytes(from_bytes(sources[0][1]))  # orientacao/cor conferidas; PNG, sem redimensionar
    w, h = contract.canvas
    strength = 200 if init_strength is None else init_strength
    d['errors'] += check(source, w, h, strength)
    if seed is not None and (type(seed) is not int or seed < 0):
        d['errors'].append('conversion seed: inteiro nao negativo')
    d['request'] = {'endpoint': f'{api.BASE}/{MODEL}', 'width': w, 'height': h,
                    'params': {'strength': strength, 'seed': seed}, 'spec_sha256': api.SPEC_SHA256}
    d['expect'] = {'kind': d['kind'], 'cells': [w, h], 'content': [0, 0, w, h], 'scale': 1,
                   'scale_exact': True, 'grid': 'native', 'layout': [1, 1], 'frames': 1, 'tags': None,
                   'background': 'transparent', 'size': [w, h], 'cluster': 1, 'attached': ['conversion_source'],
                   'role': d['production']['role'],
                   'target_useful_bbox': d['fidelity_prompt'].get('target_useful_bbox')}
    d['prompt'] = 'Faithful image conversion; no text description is accepted or transmitted by this endpoint.'
    d['authoring'] = 'model_conversion_to_native_requested_size'
    d['notes'].append('fixer=true; output_size is a structured request, not a size written only in the prompt. '
                      'Dimensions, background, equipment and identity still require review; no local resize.')
    return [('conversion_source', source)]
