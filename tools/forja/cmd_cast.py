"""Listar o elenco e preparar um pedido fiel sem adivinhar a referencia, o papel ou a escala."""
from __future__ import annotations

from pathlib import Path

from . import cast, contracts, palette as palmod, plan, refs, sheetforge
from .cli import command


def do_cast(args) -> dict:
    data = cast.load(args.catalog)
    if not args.character:
        return {'ok': True, 'catalog': data['path'], 'network': False,
                'characters': [cast.describe(data, e) for e in data['characters']]}
    entry = cast.character(data, args.character)
    if not args.out:
        raise ValueError('elenco --character pede --out para gravar o plano e a referencia anexada')
    contract = cast.authority(data, entry)
    palette = None if args.palette == 'none' else palmod.load(
        args.palette or palmod.ROOT / contracts.get(entry['kind']).palette)
    register = refs.load(Path(data['base']) / data['reference_register'])
    p = plan.make(args.backend, entry['subject'], entry['kind'], sheetforge.parse_tags(args.tags),
                  args.facing, palette=palette, model=args.model, guides_mode=args.guides,
                  size=args.image_size, register=register, mode='adapt_concept', fidelity=contract,
                  character=entry['id'], pose=entry['pose'])
    p.data['cast'] = cast.describe(data, entry)
    p.data['notes'].append('Design escolhido pelo dono; o resultado gerado continua uma adaptacao em revisao. '
                           'Isto nao aprova um sprite nativo, uma animacao ou uma integracao no jogo.')
    output = p.write(Path(args.out) / 'plan')
    return {'ok': p.ok, 'character': entry['id'], 'contract': contract['path'], 'plan': str(output),
            'errors': p.data['errors'], 'notes': p.data['notes'], 'network': False,
            'attachments': p.data['attachments'], 'expect': p.data['expect']}


def register(sub) -> None:
    p = command(sub, 'elenco', 'Conceitos escolhidos pelo dono: listar ou preparar um pedido com a identidade, '
                'funcao, dupla e escala certas; sem rede nem aprovacao de sprites', do_cast)
    p.add_argument('--character', help='id ou alias exato; omitir para listar o elenco')
    p.add_argument('--catalog', default=str(cast.DEFAULT), help='catalogo forja.cast/1')
    p.add_argument('-o', '--out', help='pasta para o plano, o prompt e as imagens anexadas')
    p.add_argument('--backend', default='openai', choices=plan.BACKENDS)
    p.add_argument('--palette', help='paleta do projeto por omissao; none para um estudo sem paleta imposta')
    p.add_argument('--model')
    p.add_argument('--tags', help='tags ja existentes na Forja; sem tags prepara a pose estatica')
    p.add_argument('--facing', default='right', choices=('right', 'left'))
    p.add_argument('--guides', default='auto', choices=plan.GUIDES)
    p.add_argument('--image-size', help='resolucao do Gemini; nao altera a tela nativa do personagem')
