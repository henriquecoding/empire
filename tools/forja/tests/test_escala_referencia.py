"""Regressoes da entrega de 28/10: tropa, autoridade com defeito e refinamento."""
import copy
import json
import unittest

from tools.forja import cli, equipment, fidelity, geometry, limits, plan, prompts, review_state
from tools.forja.tests import audit_fixtures as fx, equip_fixtures as ef
from tools.forja.tests.helpers import framed, tempdir


def contract():
    data = copy.deepcopy(fidelity.load(fx.AUDIT / 'fidelidade.json'))
    ch = fidelity.character(data, 'arqueiro')
    ch.update(role='troop', kind='troop_64', target_canvas=[64, 64], target_useful_bbox=[2, 2, 62, 63])
    return data, ch


def issue(disposition='repair'):
    return {'id': 'bow_artifact', 'scope': 'equipment', 'authority_box': [1290, 455, 1360, 520],
            'description': 'Unidentified grey protrusion and ambiguous bow string attachment.',
            'disposition': disposition, 'instruction': 'Remove the unidentified grey protrusion and connect the string to both nocks.',
            'authorized_by': 'Henrique', 'date': '2026-10-28'}


class RoleTest(unittest.TestCase):
    def test_plain_troop_subject_selects_native_64_without_a_royal_preset(self):
        p = plan.make('pixellab', 'ordinary troop archer')
        self.assertTrue(p.ok, p.data['errors'])
        self.assertEqual((p.data['kind'], p.data['request']['width'], p.data['request']['height']),
                         ('troop_64', 64, 64))

    def test_an_explicit_80_frame_cannot_override_a_troop_role(self):
        p = plan.make('openai', 'arqueiro de tropa', 'royal_80')
        self.assertFalse(p.ok)
        self.assertIn('role_conflict', ' '.join(p.data['errors']))

    def test_royal_archer_remains_distinct(self):
        p = plan.make('pixellab', 'royal archer')
        self.assertTrue(p.ok, p.data['errors'])
        self.assertEqual((p.data['kind'], p.data['request']['width']), ('royal_80', 80))

    def test_negated_roles_and_comparison_labels_do_not_choose_the_frame(self):
        for text, kind in [('royal archer, not a troop', 'royal_80'),
                           ('troop archer, different from the royal archer', 'troop_64')]:
            p = plan.make('pixellab', text)
            self.assertTrue(p.ok, p.data['errors'])
            self.assertEqual(p.data['kind'], kind)

    def test_king_and_squire_are_also_decided_before_the_generator(self):
        for subject, kind, size in [('rei', 'royal_80', 80), ('escudeiro', 'royal_64', 64)]:
            p = plan.make('pixellab', subject)
            self.assertTrue(p.ok, p.data['errors'])
            self.assertEqual((p.data['kind'], p.data['request']['width']), (kind, size))

    def test_the_authority_contract_decides_kind_and_useful_budget(self):
        data, ch = contract()
        p = plan.make('openai', 'archer', fidelity=data, character='arqueiro')
        self.assertTrue(p.ok, p.data['errors'])
        self.assertEqual(p.data['kind'], 'troop_64')
        self.assertEqual(p.data['expect']['target_useful_bbox'], ch['target_useful_bbox'])
        self.assertIn('x=2..61', p.data['prompt'])

    def test_fidelity_and_requested_kind_cannot_silently_disagree(self):
        data, _ = contract()
        p = plan.make('openai', 'archer', 'royal_80', fidelity=data, character='arqueiro')
        self.assertFalse(p.ok)
        self.assertIn('kind_conflict', ' '.join(p.data['errors']))

    def test_prompt_cli_also_discerns_troop_in_portuguese(self):
        p = cli.run(['prompt', 'arqueiro tropa', '--palette', 'none', '-o', str(tempdir())])
        self.assertTrue(p['ok'], p)
        self.assertEqual(p['expect']['kind'], 'troop_64')
        self.assertEqual(p['expect']['cells'], [64, 64])


class ReferenceRepairTest(unittest.TestCase):
    def test_known_unresolved_defect_stops_the_request_before_network(self):
        data, ch = contract()
        ch['reference_issues'] = [issue('unresolved')]
        p = plan.make('openai', 'archer', 'troop_64', fidelity=data, character='arqueiro')
        self.assertFalse(p.ok)
        self.assertIn('reference_issue_unresolved', ' '.join(p.data['errors']))

    def test_authorized_exception_is_present_in_the_faithful_prompt(self):
        data, ch = contract()
        ch['reference_issues'] = [issue()]
        p = plan.make('openai', 'archer', 'troop_64', fidelity=data, character='arqueiro')
        self.assertTrue(p.ok, p.data['errors'])
        self.assertIn(issue()['instruction'], p.data['prompt'])
        self.assertIn('only the listed defects', p.data['prompt'])
        self.assertEqual(p.data['attachments'][0]['prompt_role'], 'concept')

    def test_identity_cannot_pass_without_evidence_of_the_repair(self):
        candidate = framed(5, (64, 64), (32, 62))
        ch = {'rejected_candidates': [], 'reference_issues': [issue()], 'identity_reviews': [{
            'pixels_sha256': equipment.image_sha(candidate), 'status': 'pass', 'reviewed_by': 'Codex',
            'date': '2026-10-28', 'observations': {a: 'compared with authority' for a in review_state.ASPECTS}}]}
        self.assertEqual(review_state.identity(ch, candidate, None)['status'], 'pending')
        ch['reference_issue_reviews'] = [{'id': 'bow_artifact', 'pixels_sha256': equipment.image_sha(candidate),
            'status': 'pass', 'reviewed_by': 'Codex', 'date': '2026-10-28', 'observation': 'Both nocks connected; no grey artifact.'}]
        self.assertEqual(review_state.identity(ch, candidate, None)['status'], 'pass')
        changed = candidate.copy()
        changed.putpixel((0, 0), (1, 2, 3, 255))
        self.assertEqual(review_state.identity(ch, changed, None)['status'], 'pending')

    def test_a_string_attached_to_free_space_does_not_pass_bow_geometry(self):
        image = ef.bow('valid')
        obs = equipment.observe(image, ef.bow_observation(image))
        obs['regions']['bow.limb'] = frozenset((x + 8, y) for x, y in obs['regions']['bow.limb'])
        result = geometry.review(ef.bow_manifest(), obs)
        nocks = [c for c in result['checks'] if c['check'] == 'bow_nocks']
        self.assertEqual(len(nocks), 1)
        self.assertEqual(nocks[0]['status'], 'fail')

    def test_refinement_feedback_preserves_face_structure_without_an_implicit_pixel_cap(self):
        f = limits.below_grid({'cells': 10, 'share': 0.2, 'largest': 10}, [1, 1, 4, 5])
        self.assertNotIn('1-2 pixel marks', f['prompt_hint'])
        self.assertIn('expression', f['prompt_hint'])

    def test_native_json_and_native_plan_keep_fidelity_without_forced_basic_shading(self):
        d = tempdir()
        framed(5, (64, 64), (32, 62)).save(d / 'concept.png')
        p = plan.make('pixellab', 'troop archer', references=[('concept', str(d / 'concept.png'))])
        self.assertTrue(p.ok, p.data['errors'])
        self.assertNotIn('shading', p.data['request']['params'])
        self.assertNotIn('detail', p.data['request']['params'])
        generated = prompts.build('troop archer', 'troop_64', mode='adapt_concept',
            fidelity={'invariants': ['cream tunic and restrained expression']})['pixellab']
        self.assertIn('cream tunic and restrained expression', generated['description'])
        self.assertIn('Native canvas: 64x64', generated['description'])
        self.assertNotIn('shading', generated)


if __name__ == '__main__':
    unittest.main()
