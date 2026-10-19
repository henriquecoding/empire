"""Runtime inventory of the owner's V15 character delivery."""
import json
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]


def royal_assets():
    return json.loads((ROOT/'art/export/royals/manifest.json').read_text())['assets']


def royal_table():
    rows = ['', '## Elenco V15 — pedido de integração de 19/10/2026', '',
            'Fonte editável: `art/source/royals_v15/`. Importação fiel: `tools/export_royals.py`.',
            'Os seis membros das duplas iniciais são usados no seletor e no mundo. '
            'O Cavaleiro Enterrado usa a aparência do Sombra; a Bailarina e a sequência '
            'de floração estão disponíveis na galeria dentro do jogo. '
            'Não há quarto par de gameplay definido (CV-04).', '',
            '| Perfil | Tela | Entradas (incluindo espelhos) | Ações |',
            '|---|---|---:|---|']
    for name, item in sorted(royal_assets().items()):
        actions = ', '.join(tag[:-6] for tag in item['tags'] if tag.endswith('_right'))
        rows.append(f"| `{name}` | {item['size'][0]} × {item['size'][1]} | "
                    f"{len(item['durations_ms'])} | {actions} |")
    return rows + ['', 'Pivôs por direção, tempos variáveis e marcadores preservados. '
                   'Os marcadores não aplicam dano, cura, moedas ou projéteis; a simulação mantém essa autoridade.', '']
