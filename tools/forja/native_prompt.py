"""O mesmo pedido nativo completo no plano e no pixellab.json do compilador, sem a grade ampliada."""
from __future__ import annotations

from . import constraints, production


def build(subject: str, contract, palette, facing: str, mode: str, fid: dict) -> dict:
    rules = constraints.rules(contract, palette, facing, mode, 24, None, fid.get('invariants'),
                              fid.get('where'), fid.get('max_colors'), fid.get('tones'))
    rules += production.rules(fid)
    w, h = (v // contract.cluster for v in contract.canvas)  # o mesmo tamanho que o pedido manda (image_size)
    scale = (f' (the game shows each pixel as a {contract.cluster}x{contract.cluster} block, '
             f'{contract.canvas[0]}x{contract.canvas[1]} on screen)' if contract.cluster > 1 else '')
    text = (f'{subject}. Asset type: {contract.en}. Native canvas: {w}x{h} actual pixels{scale}; every feature uses '
            'whole pixels.\n' + '\n'.join(r['text'] for r in rules))
    return {'prompt': text, 'constraints': [{'id': r['id'], 'origin': r['origin']} for r in rules],
            'implicit': constraints.implicit(rules)}
