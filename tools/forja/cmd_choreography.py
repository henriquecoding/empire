"""Coreografia acessivel pela CLI e MCP; um plano nunca faz uma chamada paga."""
from __future__ import annotations

import json
from pathlib import Path

from PIL import Image

from . import anim, cast, choreography, clip_export, motion_review, pose, pose_library, refs, scene, scene_motion
from .backends import pixellab_animation
from .cli import command
from .cmd_ase import outside_art


def _clip(args) -> tuple[dict, Path, dict | None]:
    path = Path(args.clip)
    reg = refs.load(args.refs) if getattr(args, 'refs', None) else None
    data = choreography.load(path)
    choreography.require(data, path.parent, reg)
    return data, path.parent, reg


def _write(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')


def do_poses(args) -> dict:
    if not args.reference:
        return {'ok': True, 'network': False, 'recipes': pose_library.PHASES,
                'note': 'Roteiros de estudo; ajustar articulacoes a referencia e desenhar as fases.'}
    if not args.out or not args.action or not args.description:
        raise ValueError('poses --reference exige --action, --description e --out')
    kind = args.kind
    if args.character:
        entry = cast.character(cast.load(), args.character)
        if kind and kind != entry['kind']:
            raise ValueError('kind contradiz o elenco')
        kind = entry['kind']
    if not kind:
        raise ValueError('diga --kind ou --character do elenco')
    data = pose_library.create(Path(args.reference), kind, args.action, args.description, args.facing)
    choreography.require(data, Path('.'))
    path = outside_art(args.out)
    _write(path, data)
    return {'ok': True, 'clip': str(path), 'network': False, 'notes': data['notes']}


def do_choreography(args) -> dict:
    data, base, reg = _clip(args)
    report = choreography.validate(data, base, reg)
    motion = motion_review.analyze(data)
    files = {}
    if args.out:
        folder = outside_art(args.out)
        folder.mkdir(parents=True, exist_ok=True)
        guides, _ = anim.strip([pose.render(f['pose']) for f in data['frames']])
        guides.save(folder / 'poses.png')
        _write(folder / 'choreography.json', {'validation': report, 'motion': motion})
        files = {'sheet': str(folder / 'poses.png'), 'report': str(folder / 'choreography.json')}
    return {'ok': True, 'network': False, 'validation': report, 'motion': motion, 'files': files}


def do_animate(args) -> dict:
    data, base, reg = _clip(args)
    call = pixellab_animation.call((base / data['reference']['file']).read_bytes(), data, args.method, args.seed)
    if not args.send:
        return {'ok': True, 'network': False, 'request': call.descriptor,
                'review': choreography.validate(data, base, reg),
                'next': 'Rever as poses; --send envia com teto e job persistente na pasta --out.'}
    if not args.out:
        raise ValueError('animar --send exige --out para persistir o job e o teto')
    folder = outside_art(args.out)
    result = choreography.generate(data, base, folder, args.method, reg, args.max_calls, args.max_usd,
                                   args.seed, deadline=args.deadline)
    exported = clip_export.package(data, result['images'], base, folder / 'review',
                                  {'method': args.method, 'job_id': result['job']['id'],
                                   'cost': result['job']['cost'], 'request_sha256': result['job']['request_sha256']}, reg)
    return {**exported, 'job': result['job'], 'network': True}


def do_review(args) -> dict:
    data, base, reg = _clip(args)
    if not args.frame:
        raise ValueError('rever-clip exige --frame repetido na ordem da timeline')
    return clip_export.package(data, [Path(p).read_bytes() for p in args.frame], base, outside_art(args.out), register=reg)


def do_scene_motion(args) -> dict:
    sc = scene.load(args.scene)
    scene.resolve(sc)
    with Image.open(args.image) as image:
        master = image.convert('RGBA')
    frames, durations = scene_motion.compose(sc, master, Path(sc['_base']), args.duration_ms)
    folder = outside_art(args.out)
    folder.mkdir(parents=True, exist_ok=True)
    files = anim.export(frames, folder, 'scene', durations, previews=False)
    report = scene_motion.review(sc, master, frames)
    from .backends import digest, sha
    from .imageops import png_bytes
    loops = all(c.get('loop', False) and sum(durations) % sum(f['duration_ms'] for f in c['frames']) == 0
                for c in sc['components'] if c.get('frames'))
    data = {'schema': 'forja.review-package/1', 'id': sc['id'], 'canvas': list(master.size),
            'commit': clip_export.commit(), 'reference': clip_export.uri(master),
            'loop': loops, 'approval': 'pending', 'source': {'method': 'scene-components',
                'scene_sha256': digest({k: v for k, v in sc.items() if not k.startswith('_')}),
                'base_sha256': sha(Path(args.image).read_bytes())}, 'review': report,
            'frames': [{'image': clip_export.uri(f), 'duration_ms': ms, 'sha256': sha(png_bytes(f))}
                       for f, ms in zip(frames, durations)]}
    clip_export.write_review(data, folder)
    return {'ok': report['ok'], 'files': {**files, 'review': str(folder / 'review.json')}, 'review': report}


def register(sub) -> None:
    p = command(sub, 'poses', 'Roteiros de poses editaveis: fases e tempos do Empire; sem rede', do_poses)
    p.add_argument('--reference')
    p.add_argument('--kind')
    p.add_argument('--character', help='id/alias do elenco; resolve escala, nao aprova o sprite de entrada')
    p.add_argument('--action', choices=tuple(pose_library.PHASES))
    p.add_argument('--description', help='aparencia do personagem, em ingles')
    p.add_argument('--facing', choices=('left', 'right'), default='right')
    p.add_argument('-o', '--out')
    for name, description, handler in (
        ('coreografia', 'Conferir poses, tempos, apoios, contactos e gerar guias; sem rede', do_choreography),
        ('animar', 'Plano de animacao; --send envia UMA intencao paga e retoma-a sem repetir', do_animate),
        ('rever-clip', 'Rever PNGs ordenados e exportar Aseprite, SpriteFrames e bancada visual', do_review)):
        p = command(sub, name, description, handler)
        p.add_argument('clip', help='ficheiro forja.clip/1')
        p.add_argument('--refs', help='registo de autoridade forja.refs/1')
        p.add_argument('-o', '--out', required=name == 'rever-clip')
        if name == 'animar':
            p.add_argument('--method', choices=pixellab_animation.METHODS, default='skeleton-v3')
            p.add_argument('--send', action='store_true', help='autoriza a chamada paga; sem isto e so plano')
            p.add_argument('--seed', type=int, default=0)
            p.add_argument('--max-calls', type=int, default=1)
            p.add_argument('--max-usd', type=float)
            p.add_argument('--deadline', type=float, default=900.0)
        if name == 'rever-clip':
            p.add_argument('--frame', action='append', help='PNG de cada quadro, pela ordem; repetivel')
    p = command(sub, 'cena-movimento', 'Compor componentes locais e provar preservacao da estrutura', do_scene_motion)
    p.add_argument('scene')
    p.add_argument('--image', required=True, help='base limpa da cena em pixels de ecra')
    p.add_argument('--duration-ms', type=int)
    p.add_argument('-o', '--out', required=True)
