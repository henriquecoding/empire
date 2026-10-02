"""Read the temporary manifest for the runtime art inventory."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / 'art/export/temporary/manifest.json'


def temporary_assets():
    return json.loads(MANIFEST.read_text())['assets'] if MANIFEST.exists() else {}


def temporary_table():
    assets = temporary_assets()
    if not assets:
        return []
    rows = ['', '## Assets gratuitos temporarios', '',
        'Proxies para gameplay, autorizados pelo dono (ADR 0042). Fontes preservadas em '
        '`art/source/temporary/`; licencas, autores e alteracoes em '
        '`art/export/temporary/CREDITS.txt`. Nao sao arte definitiva nem aprovacao dos originais.', '',
        '| Perfil | Frame exportado | Escala inteira | Tags |',
        '|---|---|---:|---|']
    for name, item in sorted(assets.items()):
        actions = ', '.join(f'`{tag}`' for tag in item['tags']) or '—'
        rows.append(f"| `{name}` | {item['size'][0]}x{item['size'][1]} "
                    f"| {item['integer_scale']} | {actions} |")
    rows.extend(['', 'Atores: OriginalArt/UnitArtBatch. Criaturas: CreatureSkins/BandView. '
                 'Cenario e props: TemporaryScenery/EnramadosLayer/RootCellars/BuildView.', ''])
    return rows
