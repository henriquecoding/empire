"""PixelLab: skeleton-v3 e text-v3. So os quadros ordenados da resposta, sem anexos repetidos."""
from __future__ import annotations

import io

from PIL import Image

from . import Call, Result, digest, http, image_refs, pixellab_api
from .. import contracts, pose

METHODS = ('skeleton-v3', 'text-v3')


def call(reference: bytes, clip: dict, method: str = 'skeleton-v3', seed: int = 0) -> Call:
    if method not in METHODS:
        raise ValueError('rota de animacao desconhecida')
    if type(seed) is not int or seed < 0:
        raise ValueError('seed: inteiro nao negativo')
    with Image.open(io.BytesIO(reference)) as image:
        size = image.size
    count = len(clip['frames'])
    if min(size) < 1 or max(size) > 256 or size != contracts.get(clip['kind']).canvas:
        raise ValueError('animacao: tela nativa do contrato, ate 256x256')
    body = {'first_frame': {'type': 'base64', 'base64': http.b64(reference), 'format': 'png'},
            'action': clip['action'], 'seed': seed, 'no_background': True}
    if method == 'skeleton-v3':
        if not 3 <= count <= 15:
            raise ValueError('skeleton-v3: de 3 a 15 quadros')
        body.update(description=clip['description'], view=clip['reference']['pose']['view'],
                    direction='east' if clip['reference']['pose']['facing'] == 'right' else 'west',
                    first_frame_keypoints=pose.keypoints(clip['reference']['pose']),
                    keypoints=[pose.keypoints(f['pose']) for f in clip['frames']], template_id='mannequin')
    else:
        if not 4 <= count <= 16 or count % 2 or size[0] * size[1] * count > 524288:
            raise ValueError('text-v3: 4-16 quadros pares; limite de 524288 pixels')
        body.update(frame_count=count, enhance_prompt=False)
    operation = 'animate-with-' + method
    endpoint = pixellab_api.BASE + '/' + operation
    descriptor = {'endpoint': endpoint, 'spec_sha256': pixellab_api.SPEC_SHA256,
                  'params': {k: v for k, v in body.items() if k != 'first_frame'},
                  'images': image_refs([('identity', reference)]), 'clip_sha256': digest(clip),
                  'expected_frames': count, 'expected_size': list(size),
                  'reference_returned': False if method == 'skeleton-v3' else 'provider_defined',
                  'coordinate_mapping': 'pixel/(side-1)', 'review': 'pending'}
    return Call('pixellab', operation,
                lambda: http.json_request('POST', endpoint, body, pixellab_api._headers()),
                pixellab_api.parse, descriptor, pixellab_api.REFUSED)


def parse_job(data: dict) -> Result:
    if data.get('status') != 'completed':
        return pixellab_api.parse_job(data)
    last = data.get('last_response') or {}
    images = last.get('images')
    if not isinstance(images, list):
        return Result(state='failed', detail={'status': 'invalid', 'error': 'images deve ser lista ordenada'})
    frames = []
    for index, value in enumerate(images):
        try:
            decoded = http.find_images(value)
        except (ValueError, TypeError):
            return Result(state='failed', detail={'status': 'invalid', 'error': f'quadro {index}: base64 invalido'})
        if len(decoded) != 1:
            return Result(state='failed', detail={'status': 'invalid', 'error': f'quadro {index} ausente/ambiguo'})
        frames.extend(decoded)
    usd = pixellab_api._usd(last)
    return Result(frames, usage_usd=usd if usd is not None else pixellab_api._usd(data),
                  detail={'status': 'completed', 'frame_order': 'last_response.images'})


def poll_call(job_id: str) -> Call:
    call = pixellab_api.poll_call(job_id)
    call.parse = parse_job
    return call
