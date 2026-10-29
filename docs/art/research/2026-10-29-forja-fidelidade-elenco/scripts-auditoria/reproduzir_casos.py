"""Reproducao minima usando apenas este pacote e uma copia local da Forja."""
import argparse
import copy
import hashlib
import json
import sys
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--repo', type=Path, required=True)
args = parser.parse_args()
sys.path.insert(0, str(args.repo.resolve()))
from PIL import Image
from tools.forja import gridcheck, pipeline, production

base = Path(__file__).resolve().parents[1]
evidence = base / 'evidencias'
source = Image.open(evidence/'casos/mercenary-source.png').convert('RGBA')
grid, sampled = gridcheck.measure(source)
native, snap = pipeline.snap(source, pipeline.Options(palette='none',noise=0,outline='keep',bg='keep'),grid,sampled)
teeth = {(38,23),(39,23),(38,24),(39,24)}
gone = [e for e in snap['loss']['erased'] if tuple(e['cell']) in teeth]
contract = json.loads((evidence/'casos/alchemist_squire/contract.json').read_text())
character = contract['characters'][0]
changed = copy.deepcopy(character)
changed['shared_prop_constraints'][0]['native_shared_dimensions'] = [99,3]
before, after = production.validate(character), production.validate(changed)
hashes = json.loads((evidence/'codigo-conferido.json').read_text())
matches = []
for row in hashes:
    if not row['path'].startswith('tools/forja/'):
        continue
    current = args.repo/row['path']
    matches.append(current.is_file() and hashlib.sha256(current.read_bytes()).hexdigest() == row['sha256'])
result = dict(code_matches_audited_snapshot=all(matches),
              grid=list(grid.size), purity=snap['sample']['purity'],
              erased=snap['loss']['erased_cells'], erased_tooth_cells=[e['cell'] for e in gone],
              original_validation=before, mutated_shared_dimensions_validation=after,
              scope='O teste minimo de contrato executa production.validate; a auditoria completa tambem executou fidelity.validate.',
              warning='Diagnostico do comportamento defeituoso original, nao suite de aceite de uma correcao.')
print(json.dumps(result,ensure_ascii=False,indent=2))
if all(matches):
    assert len(gone) == 4
    assert snap['sample']['purity'] == 0.97
    assert before == after == []
else:
    print('A Forja mudou: compare os novos resultados com o snapshot; o defeito pode ter sido corrigido.')
