"""Generated runtime inventory for the art direction confirmed on 2026-10-05."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / 'art/export/renewal/manifest.json'


def renewal_assets():
    return json.loads(MANIFEST.read_text())['assets']


def renewal_table():
    rows = ['', '## Renovacao visual — direcao confirmada em 05/10/2026', '',
            'Fontes integrais: `art/source/renewal/`. Export deterministico: '
            '`tools/export_renewal.py`. Referencias, aprovacoes e limites: '
            '`docs/art/ART_DIRECTION_2026-10-05.md` (ADR 0072).', '',
            '| Perfil | Tamanho do frame | Frames | Accoes |',
            '|---|---|---:|---|']
    for name, item in sorted(renewal_assets().items()):
        tags = ', '.join(item['tags'])
        rows.append(f"| `{name}` | {item['size'][0]} x {item['size'][1]} "
                    f"| {len(item['durations_ms'])} | {tags} |")
    rows += ['', 'Os ataques, golpes recebidos e quedas usam poses do combate. '
             'Caminhadas com quatro frames; nao se declaram ciclos de ataque completos. '
             'Edificios conservam estados de pagamento, construcao, reparacao e ruina. '
             'Todas as especies da Podridao usam sprites desta familia e olhos emissivos.', '']
    return rows
