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
    return rows + native_table() + owner_table()


def native_table():
    path = ROOT / 'art/export/scenery_native/manifest.json'
    if not path.exists():
        return []
    data = json.loads(path.read_text(encoding='utf-8'))
    rows = ['', '## Producao nativa — 16/10/2026 (ADR 0084)', '',
            'Os planos naturais abaixo substituem os planos homonimos da entrega anterior '
            'pela chamada NativeSceneryCatalog.patch_legacy em SceneryArt. '
            'O terreno da campanha continua associado aos sitios e passagens da simulacao. '
            'A galeria tools/native_scenery_review.tscn monta as camadas funcionais '
            'e as construcoes fora do parallax.', '',
            '| Familia | Uso | Camadas nativas | Fonte editavel |',
            '|---|---|---|---|']
    for name, item in data['families'].items():
        usage = ('campanha: planos naturais; prefab completo' if item.get('campaign_layers')
                 else 'prefab completo; colocacao de campanha por decidir')
        layers = ', '.join(item['layers'])
        rows.append(f"| {item['name']} ({name}) | {usage} | {layers} "
                    f"| art/export/scenery_native/{name}/layers.ora |")
    rows += ['', f"Catalogo: {len(data['families'])} familias, {len(data['variants'])} cenas. "
             'Módulos de 64 px, PNGs recortados ao alfa, export nearest de 2/4 px, '
             'paleta limitada sem dithering. Validacao executada: '
             'docs/art/scenery_native_validation.json; guia: docs/art/NATIVE_SCENERY.md.', '']
    return rows


def owner_table():
    path = ROOT / 'art/export/scenery_owner/manifest.json'
    if not path.exists():
        return []
    data = json.loads(path.read_text(encoding='utf-8'))
    uso = {}
    for biome, k in data['kingdoms'].items():
        uso[k['base']] = f"reino `{biome}`"
        for v in k['variants']:
            quando = v.get('season') or ', '.join(v.get('phases', []))
            uso[v['view']] = f"variante de `{biome}` ({quando})"
    for biome, site in data['sites'].items():
        uso[site['base']] = f"sitio de agua de `{biome}`"
        for v in site['variants']:
            quando = v.get('season') or ', '.join(v.get('phases', []))
            uso[v['view']] = f"variante do sitio de `{biome}` ({quando})"
    for scene, t in data['transitions'].items():
        uso[t['view']] = f"transicao `{scene}` ({t['from']} → {t['to']})"
    rows = ['', '## As composicoes do dono — 15 e 16/10/2026 (ADR 0086)', '',
            'As pinturas dos dois ZIPs, separadas em planos por `tools/owner_scenery/` e exportadas por '
            '`tools/export_owner_scenery.py` (cada origem conferida contra o ZIP). Substituem os planos e o '
            'chao dos reinos pela chamada OwnerScenery.patch em SceneryArt; as variantes trocam-se pela hora e '
            'pela estacao (OwnerScenery.weights) e os sitios ficam na agua do territorio (OwnerSites).', '',
            '| Vista | Uso | Origem | Camadas |', '|---|---|---|---|']
    for view, item in data['views'].items():
        layers = ', '.join(name for name in ORDER if name in item['layers'])
        rows.append(f"| `{view}` | {uso.get(view, '—')} | `{item['src']}` | {layers} |")
    rows.append('')
    return rows
