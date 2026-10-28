"""Provas sem rede de escala, ocupacao, leitura nativa, defeitos conhecidos e conversao estruturada."""
from __future__ import annotations

import json
import sys
import tempfile
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT))
from tools.forja import equipment, fidelity, geometry, pipeline, plan, production  # noqa: E402
from tools.forja.tests import equip_fixtures as fixture  # noqa: E402

BASE = Path(__file__).resolve().parent


def run() -> dict:
    contract = fidelity.load(BASE / 'fidelidade.json')
    result = {'network_calls': 0, 'paid_calls': 0, 'approval': 'pending', 'checks': {}}
    checks = result['checks']
    troop = plan.make('pixellab', 'ordinary troop archer')
    checks['troop_native_64'] = troop.ok and troop.data['kind'] == 'troop_64' and troop.data['expect']['size'] == [64, 64]
    wrong = plan.make('openai', 'arqueiro de tropa', 'royal_80')
    checks['troop_80_refused'] = not wrong.ok and any('role_conflict' in e for e in wrong.data['errors'])
    result['troop_policy'] = {'kind': troop.data['kind'], 'size': troop.data['expect']['size'],
                              'wrong_kind_errors': wrong.data['errors']}
    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        source = Image.new('RGBA', (101, 100))
        source.paste((51, 61, 71, 255), (2, 2, 99, 98))
        source.save(tmp / 'oversized.png')
        r = pipeline.forge(tmp / 'oversized.png', tmp / 'forge', pipeline.Options(kind='royal_80', scale=1,
            palette='none', noise=0, cleanup='conservative', outline='keep'), report_html=False)
        result['occupied_extent'] = r['snap']['occupancy']
        result['occupied_extent']['target_canvas'] = [80, 80]
        checks['transparent_margins_do_not_make_97x96_fit'] = r['snap']['native_size'] == [97, 96] and not r['delivery']['usable_sprite']
        with Image.open(r['files']['uncut_png']) as uncut:
            checks['uncut_diagnostic_preserved'] = uncut.size == (97, 96)
        native = Image.new('RGBA', (64, 64))
        for y in range(4, 62):
            for x in range(3, 61):
                native.putpixel((x, y), ((x * 29) % 256, (y * 37) % 256, (x * y) % 256, 255))
        got, snap = pipeline.snap(native, pipeline.Options(scale=1, palette='none'))
        checks['native_1x_rgba_identical'] = got.tobytes() == native.crop((3, 4, 61, 62)).tobytes()
        result['native_read'] = {'input': [64, 64], 'useful': list(got.size), 'grid': snap['grid']['origin']}
        Image.new('RGBA', (320, 280), (51, 61, 71, 255)).save(tmp / 'concept.png')
        conversion = plan.make('pixellab', 'ordinary troop archer', model='image-to-pixelart',
                              references=[('concept', str(tmp / 'concept.png'))])
        request = conversion.call().descriptor
        result['conversion_request'] = request
        checks['native_output_structured_not_text'] = conversion.ok and request['params']['output_size'] == {'width': 64, 'height': 64}
        framed = conversion.data['source_frame']
        checks['source_not_locally_resized'] = framed['source_size'] == [320, 280] and not framed['resampled']
        checks['source_framed_to_output_aspect'] = request['params']['image_size'] == {'width': 320, 'height': 320}
    ch = fidelity.character(contract, 'arqueiro_tropa')
    prompt = plan.make('openai', 'arqueiro de tropa', fidelity=contract, character='arqueiro_tropa')
    checks['authorized_defect_exceptions_sent'] = prompt.ok and all(i['instruction'] in prompt.data['prompt'] for i in ch['reference_issues'])
    checks['known_repairs_need_new_image_evidence'] = production.repairs_state(ch, 'not-a-reviewed-candidate')['status'] == 'pending'
    blocked = plan.make('pixellab', 'arqueiro de tropa', fidelity=contract, character='arqueiro_tropa', model='image-to-pixelart')
    checks['conversion_cannot_silently_copy_known_defect'] = not blocked.ok and any('repair instructions' in e for e in blocked.data['errors'])
    image = fixture.bow('valid')
    obs = equipment.observe(image, fixture.bow_observation(image))
    good = geometry.review(fixture.bow_manifest(), obs)
    obs['regions']['bow.limb'] = frozenset((x + 8, y) for x, y in obs['regions']['bow.limb'])
    bad = geometry.review(fixture.bow_manifest(), obs)
    checks['normal_curved_bow_still_passes'] = good['summary']['equipment_geometry'] == 'pass'
    checks['string_attached_to_empty_space_fails'] = any(c['check'] == 'bow_nocks' and c['status'] == 'fail' for c in bad['checks'])
    result['bow_negative_control'] = [c for c in bad['checks'] if c['check'] == 'bow_nocks']
    result['ok'] = all(checks.values())
    return result


if __name__ == '__main__':
    data = run()
    (BASE / 'prova.json').write_text(json.dumps(data, indent=1, ensure_ascii=False) + '\n', encoding='utf-8')
    print(json.dumps({'ok': data['ok'], 'checks': data['checks']}, ensure_ascii=False))
    raise SystemExit(0 if data['ok'] else 1)
