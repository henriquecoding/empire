"""The animated animals and creatures of 2026-10-14 in the runtime inventory (ADR 0083)."""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / 'art/export/animated/manifest.json'
SOURCE = ROOT / 'src/world/animated_art.gd'


def _block(text, const):
    match = re.search(rf'^const {const} := \{{(.*?)^\}}', text, re.S | re.M)
    return match.group(1) if match else ''


def _users():
    """Who draws each exported id, read from the maps of AnimatedArt."""
    text = SOURCE.read_text(encoding='utf-8')
    users = {}
    for form, asset in re.findall(r'Silhouette\.Form\.(\w+): &"(\w+)"', _block(text, 'CREATURES')):
        users.setdefault(asset, []).append(f'criatura `{form}` (`CreatureView`, `AnimatedBeasts`)')
    for game_id, asset in re.findall(r'&"(\w+)": &"(\w+)"', _block(text, 'WILDLIFE')):
        users.setdefault(asset, []).append(f'caca `{game_id}` (`HuntView`, `HuntPoses`)')
    for game_id, asset in re.findall(r'&"(\w+)": &"(\w+)"', _block(text, 'MOUNTS')):
        users.setdefault(asset, []).append(f'montaria `{game_id}` (`MountView`)')
    for building, assets in re.findall(r'&"(\w+)": \[([^\]]*)\]', _block(text, 'FARM')):
        for asset in sorted(set(re.findall(r'&"(\w+)"', assets))):
            users.setdefault(asset, []).append(f'obra `{building}` (`FarmAnimals`)')
    users.setdefault('beast_tender', []).append('a voz da Podridao (`OfferView`)')
    return users


def animated_table():
    manifest = json.loads(MANIFEST.read_text(encoding='utf-8'))
    users = _users()
    rows = ['', '## Animais e criaturas animados — entrega de 14/10/2026', '',
            'Os dois ZIPs do dono, lidos por `tools/export_animated.py` (cada ficheiro conferido com as '
            'somas do proprio pacote); a folha da direita e a mesma, byte a byte, e o export junta-lhe a '
            'mascara branca e, nas criaturas, o que brilha no escuro. Regras: ADR 0083. Quadros de 64 x 64, '
            'as criaturas a escala inteira mais perto do porte do `Bestiary`; os animais a escala do porte que '
            'o dono lhes deu (os pequenos um pouco abaixo das tropas, as montarias das tropas um pouco acima, '
            'as dos imperadores acima do rei; `AnimatedArt.ESCALA`, Q-264).', '',
            '| Export | Pacote | Quadros | Accoes | Quem o desenha |',
            '|---|---|---|---|---|']
    for asset_id, entry in manifest['assets'].items():
        actions = ', '.join(name for name, tag in entry['tags'].items() if 'alias_of' not in tag)
        who = '; '.join(users.get(asset_id, ['sem chamada em runtime']))
        rows.append(f"| `{asset_id}` | {entry['title']} (`{entry['source']}`) "
                    f"| {len(entry['frame_origins'])} | {actions} | {who} |")
    left = ', '.join(f"{x['title']} (`{x['source']}`)" for x in manifest['left_in_package'])
    rows += ['', f'Ficam nos pacotes, sem lugar no jogo ainda: {left} (Q-263).', '']
    return rows
