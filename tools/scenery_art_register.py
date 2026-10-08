"""The layered scenery of 2026-10-08 in the runtime inventory (ADR 0081)."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / 'art/export/scenery/manifest.json'
ORDER = ['sky', 'clouds', 'far', 'mid', 'near', 'under', 'terrain', 'water', 'foreground', 'landmark']


def scenery_table():
    manifest = json.loads(MANIFEST.read_text(encoding='utf-8'))
    rows = ['', '## Cenarios em camadas — entrega de 08/10/2026', '',
            'Os ZIPs do dono, lidos por `tools/export_scenery.py` (hashes de cada pacote conferidos '
            'com o `catalogo.json`); o export e as mesmas camadas recortadas ao alfa, sem reamostrar. '
            'Mapa e regras: ADR 0081. Chamada em runtime: `SceneryArt`, `SceneryPlane` (fundo, em '
            'parallax) e `SceneryStrip` (chao e terra, no mundo).', '',
            '| Cena | Tipo | Bioma ou fronteira | Quadro | Camadas |',
            '|---|---|---|---|---|']
    for scene_id, scene in manifest['scenes'].items():
        where = scene.get('biome') or f"{scene['from']} → {scene['to']}"
        layers = ', '.join(name for name in ORDER if name in scene['layers'])
        rows.append(f"| `{scene_id}` ({scene['title']}) | {scene['kind']} | `{where}` "
                    f"| {scene['canvas'][0]} x {scene['canvas'][1]} | {layers} |")
    proposals = ', '.join(f"{p['title']} (`{p['id']}`)" for p in manifest['proposals'])
    rows += ['', f'Propostas por colocar no mundo, fora do export: {proposals} (Q-259). Edificios, '
             'escadas, atividades de baixo e atores de referencia ficam nos pacotes: o que se '
             'constroi e onde ha passagem decide-o a simulacao.', '']
    return rows
