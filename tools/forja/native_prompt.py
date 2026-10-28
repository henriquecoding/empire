"""O mesmo pedido nativo completo no plano e no pixellab.json do compilador, sem a grade ampliada."""
from __future__ import annotations

from . import constraints, production


def build(subject: str, contract, palette, facing: str, mode: str, fid: dict) -> dict:
    rules = constraints.rules(contract, palette, facing, mode, 24, None, fid.get('invariants'),
                              fid.get('where'), fid.get('max_colors'), fid.get('tones'))
    rules += production.rules(fid)
    text = (f'{subject}. Asset type: {contract.en}. Native canvas: '
            f'{contract.canvas[0]}x{contract.canvas[1]} actual pixels; every feature uses whole pixels.\n'
            + '\n'.join(r['text'] for r in rules))
    return {'prompt': text, 'constraints': [{'id': r['id'], 'origin': r['origin']} for r in rules],
            'implicit': constraints.implicit(rules)}
