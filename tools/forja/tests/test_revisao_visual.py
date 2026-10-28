"""P0 (FORJA-10): a revisao visual de uma imagem exata, com controlos positivos e negativos.

Transporte simulado: as revisoes sao escritas pelos testes como um observador as escreveria. Isto prova o contrato
(hash, tela, estados, classe, bloqueio e incerteza) e a ligacao ao equip e a identidade; a qualidade real de uma
visao so se avalia olhando imagens reais, e nenhum teste aqui inventa uma taxa de acerto.
"""
import json
import unittest

from PIL import Image

from tools.forja import cli, equipment, fidelity, geometry, pixel_patch, review_state, visual_review as vr
from tools.forja.tests import equip_fixtures as ef
from tools.forja.tests.helpers import tempdir

CONTRACT = 'docs/art/research/2026-10-28-forja-escala-e-referencia/fidelidade.json'
INVARIANTS = ['capuz verde', 'expressao contida']
WHO = {'author': 'teste', 'model': None, 'method': 'revisao escrita pelo teste', 'date': '2026-10-28'}


def archer(**extra) -> dict:
    return {'id': 'arq', 'pose': 'p', 'role': 'troop', 'required_invariants': INVARIANTS,
            'reference_issues': [{'id': 'fragment', 'disposition': 'repair'}], **extra}


def review(image, phase='candidate', **extra) -> dict:
    base = {'schema': vr.SCHEMA, 'phase': phase, 'image': {'sha256': equipment.image_sha(image),
            'size': list(image.size)}, 'subject': {'character': 'arq', 'declared_role': 'troop'}, 'observer': WHO,
            'regions': {'bow.limb': {'box': [56, 18, 70, 62], 'state': 'observed', 'colors': [ef.WOOD]},
                        'bow.string': {'box': [52, 18, 60, 62], 'state': 'observed', 'colors': [ef.STRING]},
                        'bow.grip': {'box': [60, 34, 70, 47], 'state': 'observed', 'colors': [ef.WOOD]},
                        'hand': {'box': [62, 37, 69, 44], 'state': 'observed', 'colors': [ef.SKIN]},
                        'arm': {'box': [42, 38, 62, 43], 'state': 'observed', 'colors': [ef.SKIN, '#000000']}},
            'anchors': {'bow.nock_top': {'point': [57, 21], 'state': 'observed'},
                        'bow.nock_bottom': {'point': [57, 59], 'state': 'observed'}},
            'findings': [], 'invariant_checks': [{'invariant': i, 'status': 'preserved', 'evidence': 'visto a 8x'}
                                                 for i in INVARIANTS]}
    if phase == 'candidate':
        base['repair_claims'] = [{'issue': 'fragment', 'status': 'fixed', 'certainty': 'certain',
                                  'box': [50, 40, 60, 50], 'evidence': 'sem segmento cinzento entre as maos'}]
    return {**base, **extra}


def finding(**over) -> dict:
    return {'id': 'f1', 'category': 'equipment_defect', 'box': [55, 18, 60, 24], 'state': 'observed',
            'certainty': 'certain', 'evidence': 'a corda acaba no ar, longe da madeira', 'description': 'corda solta',
            'action': 'repair', **over}


def detached() -> Image.Image:
    image = ef.bow('valid')
    patch = {'schema': pixel_patch.SCHEMA, 'base': {'pixels_sha256': equipment.image_sha(image), 'canvas': [80, 80]},
             'mask': [[50, 15, 80, 66]], 'author': 'teste', 'date': '2026-10-28', 'reason': 'controlo: madeira longe',
             'operations': [{'op': 'move', 'box': [58, 18, 70, 36], 'select': [ef.WOOD], 'to': [8, 0]}]}
    return pixel_patch.apply(image, patch)[0]


class ControlTest(unittest.TestCase):
    def test_valid_curved_bow_passes_and_feeds_a_passing_equipment_observation(self):
        image = ef.bow('valid')
        rev = review(image)
        self.assertEqual(vr.state(rev, image, archer())['status'], 'pass')
        obs = equipment.observe(image, vr.observation(rev))
        result = geometry.review(ef.bow_manifest(), obs)
        self.assertFalse(result['blocking'])
        self.assertEqual([c['status'] for c in result['checks'] if c['check'] == 'bow_nocks'], ['pass'])

    def test_string_detached_from_the_wood_blocks_and_geometry_agrees(self):
        image = detached()
        rev = review(image, findings=[finding()])
        st = vr.state(rev, image, archer())
        self.assertEqual(st['status'], 'blocked')
        result = geometry.review(ef.bow_manifest(), equipment.observe(image, vr.observation(rev)))
        self.assertEqual([c['status'] for c in result['checks'] if c['check'] == 'bow_nocks'], ['fail'])

    def test_part_hidden_by_the_sleeve_is_inconclusive_and_cannot_be_called_missing(self):
        image = ef.bow('valid')
        rev = review(image)
        rev['regions']['bow.grip'] = {'box': [60, 34, 70, 47], 'state': 'occluded', 'occluded_by': 'hand'}
        obs = vr.observation(rev)
        self.assertNotIn('bow.grip', obs['regions'])
        result = geometry.review(ef.bow_manifest(), equipment.observe(image, obs))
        self.assertNotIn('pass', [c['status'] for c in result['checks'] if c['check'] == 'bow_nocks'])
        rev['findings'] = [finding(category='missing_part', box=[62, 36, 66, 40], description='sem pega')]
        self.assertTrue(any('parte tapada nao e parte ausente' in e for e in vr.validate(rev, image, archer())))

    def test_unassigned_fragment_needs_an_owner_decision_then_proof_on_the_new_image(self):
        image = ef.bow('valid')
        frag = finding(id='frag', category='unidentified_fragment', description='segmento cinzento sem funcao')
        ref = review(image, 'reference', findings=[frag])
        ref.pop('repair_claims', None)
        self.assertEqual(vr.state(ref, image, archer())['status'], 'blocked')
        ref['findings'] = [{**frag, 'reference_issue': 'fragment'}]
        self.assertEqual(vr.state(ref, image, archer())['status'], 'pass')
        still = review(image, repair_claims=[{'issue': 'fragment', 'status': 'still_present', 'box': [50, 40, 60, 50],
                                              'evidence': 'o segmento continua'}])
        self.assertEqual(vr.state(still, image, archer())['status'], 'blocked')
        self.assertEqual(vr.issue_reviews(still)[0]['status'], 'fail')
        self.assertEqual(vr.issue_reviews(review(image))[0]['status'], 'pass')

    def test_archer_with_swapped_clothing_or_expression_is_blocked_despite_a_complete_identity_review(self):
        image = ef.bow('valid')
        rev = review(image, invariant_checks=[{'invariant': 'capuz verde', 'status': 'changed',
                                               'evidence': 'tunica verde comprida, sem capuz'},
                                              {'invariant': 'expressao contida', 'status': 'changed',
                                               'evidence': 'sorriso largo'}])
        ch = archer(identity_reviews=[{'pixels_sha256': equipment.image_sha(image), 'status': 'pass',
                                       'reviewed_by': 'x', 'date': 'd',
                                       'observations': {a: 'ok' for a in review_state.ASPECTS}}])
        self.assertEqual(review_state.identity(ch, image, None, rev)['status'], 'blocked')

    def test_correct_face_with_a_one_pixel_pupil_is_kept_not_flagged_as_noise(self):
        image = ef.bow('valid')
        rev = review(image, findings=[finding(id='pupil', category='detail_preserved', box=[38, 24, 39, 25],
                                              description='pupila de um pixel', evidence='ponto escuro no olho',
                                              action='keep')])
        rev['regions']['pupil'] = {'box': [38, 24, 39, 25], 'state': 'observed'}
        self.assertEqual(vr.state(rev, image, archer())['status'], 'pass')
        ch = archer(identity_reviews=[{'pixels_sha256': equipment.image_sha(image), 'status': 'pass',
                                       'reviewed_by': 'x', 'date': 'd',
                                       'observations': {a: 'ok' for a in review_state.ASPECTS}}])
        self.assertEqual(review_state.identity(ch, image, None, rev)['status'], 'pass')

    def test_inferred_region_or_anchor_never_becomes_a_geometric_pass(self):
        image = ef.bow('valid')
        rev = review(image)
        rev['regions']['bow.grip'] = {'box': [60, 34, 70, 47], 'state': 'inferred', 'colors': [ef.WOOD]}
        obs = vr.observation(rev)
        self.assertEqual(obs['regions']['bow.grip']['uncertainty'], 'alta')
        nocks = [c for c in geometry.review(ef.bow_manifest(), equipment.observe(image, obs))['checks']
                 if c['check'] == 'bow_nocks']
        self.assertEqual(nocks[0]['status'], 'inconclusive')
        rev = review(image)
        rev['anchors']['bow.nock_bottom']['state'] = 'inferred'
        obs = vr.observation(rev)
        self.assertNotIn('bow.nock_bottom', obs['anchors'])
        nocks = [c for c in geometry.review(ef.bow_manifest(), equipment.observe(image, obs))['checks']
                 if c['check'] == 'bow_nocks']
        self.assertEqual(nocks[0]['status'], 'not_evaluated')

    def test_a_reference_phase_review_is_not_evidence_for_the_candidate(self):
        image = ef.bow('valid')
        ref = review(image, 'reference', invariant_checks=[{'invariant': 'capuz verde', 'status': 'changed',
                                                            'evidence': 'sem capuz'}])
        ch = archer(identity_reviews=[{'pixels_sha256': equipment.image_sha(image), 'status': 'pass',
                                       'reviewed_by': 'x', 'date': 'd',
                                       'observations': {a: 'ok' for a in review_state.ASPECTS}}])
        self.assertEqual(review_state.identity(ch, image, None, ref)['status'], 'blocked')

    def test_uncertainty_stays_visible_and_never_becomes_pass(self):
        image = ef.bow('valid')
        rev = review(image, findings=[finding(certainty='uncertain')])
        st = vr.state(rev, image, archer())
        self.assertEqual(st['status'], 'pending')
        self.assertTrue(st['uncertain'])
        rev = review(image, repair_claims=[{'issue': 'fragment', 'status': 'fixed', 'certainty': 'probable',
                                            'box': [50, 40, 60, 50], 'evidence': 'parece limpo'}])
        self.assertEqual(vr.state(rev, image, archer())['status'], 'pending')


class ContractTest(unittest.TestCase):
    def test_invalid_json_other_image_and_coordinates_outside_the_canvas_are_refused(self):
        d = tempdir()
        (d / 'bad.json').write_text('{"schema": ', encoding='utf-8')
        with self.assertRaisesRegex(ValueError, 'JSON invalido'):
            vr.load(d / 'bad.json')
        image = ef.bow('valid')
        other = image.copy()
        other.putpixel((0, 0), (1, 2, 3, 255))
        self.assertTrue(any('outra imagem' in e for e in vr.validate(review(image), other)))
        rev = review(image, findings=[finding(box=[70, 70, 90, 90])])
        rev['regions']['hand']['box'] = [-1, 0, 4, 4]
        rev['anchors']['bow.nock_top']['point'] = [80, 3]
        errors = ' '.join(vr.validate(rev, image))
        self.assertIn('regiao hand', errors)
        self.assertIn('ancora bow.nock_top', errors)
        self.assertIn('achado f1', errors)

    def test_observer_cannot_change_the_declared_class_or_claim_a_repair_on_the_reference(self):
        image = ef.bow('valid')
        rev = review(image)
        rev['subject']['declared_role'] = 'royal_archer'
        self.assertTrue(any('class_override' in e for e in vr.validate(rev, image, archer())))
        ref = review(image, 'reference')
        ref['repair_claims'] = review(image)['repair_claims']
        self.assertTrue(any('so na fase candidate' in e for e in vr.validate(ref, image, archer())))

    def test_the_request_carries_the_reference_review_or_says_it_is_pending(self):
        contract = fidelity.load(CONTRACT)
        ch = fidelity.character(contract, 'arqueiro_tropa')
        crop = fidelity._pixels(fidelity.crop_png(contract, ch))
        prep = fidelity.prepare(contract, 'arqueiro_tropa', None, None, [])
        self.assertTrue(any('observacao visual da referencia' in n for n in prep['notes']) or
                        any('referencia, problema conhecido' in n for n in prep['notes']))
        d = tempdir()
        rev = {'schema': vr.SCHEMA, 'phase': 'reference', 'image': {'sha256': equipment.image_sha(crop),
               'size': list(crop.size)}, 'subject': {'character': 'arqueiro_tropa', 'declared_role': 'troop'},
               'observer': WHO, 'regions': {}, 'anchors': {}, 'invariant_checks': [],
               'findings': [finding(id='novo', box=[10, 10, 20, 20], description='defeito sem decisao')]}
        (d / 'ref.json').write_text(json.dumps(rev), encoding='utf-8')
        ch['visual_review'] = {'reference': str(d / 'ref.json')}
        out = vr.for_reference(contract['base'], ch, crop)
        self.assertTrue(out['errors'])
        rev['findings'][0]['reference_issue'] = 'bow_unidentified_fragment'
        (d / 'ref.json').write_text(json.dumps(rev), encoding='utf-8')
        out = vr.for_reference(contract['base'], ch, crop)
        self.assertEqual(out['errors'], [])
        self.assertTrue(any('bow_unidentified_fragment' in n for n in out['notes']))

    def test_cli_writes_a_template_marks_and_an_observation_for_equip(self):
        d = tempdir()
        image = ef.bow('valid')
        image.save(d / 'bow.png')
        r = cli.run(['visual', str(d / 'bow.png'), '--template-out', str(d / 't.json'), '--phase', 'candidate'])
        self.assertEqual(json.loads((d / 't.json').read_text())['image']['sha256'], equipment.image_sha(image))
        (d / 'r.json').write_text(json.dumps(review(image)), encoding='utf-8')
        r = cli.run(['visual', str(d / 'bow.png'), '--review', str(d / 'r.json'), '--marks-out', str(d / 'm.png'),
                     '--observation-out', str(d / 'o.json')])
        self.assertTrue(r['ok'])
        self.assertEqual(r['files']['preview'], str(d / 'm.png'))
        with Image.open(d / 'm.png') as marked:
            self.assertEqual(marked.size, (640, 640))
        equipment.observe(image, json.loads((d / 'o.json').read_text()))


if __name__ == '__main__':
    unittest.main()
