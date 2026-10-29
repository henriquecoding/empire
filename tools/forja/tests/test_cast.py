"""O elenco escolhido pelo dono chega ao pedido com a sua autoridade e funcao."""
import json
import tempfile
import unittest
from pathlib import Path

from tools.forja import cli, mcp_server, production


class CastTest(unittest.TestCase):
    def test_list_keeps_design_decisions_separate_from_native_master_approval(self):
        result = cli.run(['elenco'])
        self.assertTrue(result['ok'])
        self.assertFalse(result['network'])
        ids = {row['id'] for row in result['characters']}
        self.assertTrue({'corsair_empress', 'miner_emperor', 'alchemist_emperor',
                         'alchemist_squire', 'cook', 'diplomat_08', 'farmer',
                         'root_berserker', 'spearman'} <= ids)
        self.assertTrue(all(not row['native_master_approved'] for row in result['characters']))
        self.assertNotIn('turnip_person', ids)

    def test_alchemy_assistant_plan_has_correct_crop_function_and_size(self):
        with tempfile.TemporaryDirectory() as folder:
            result = cli.run(['elenco', '--character', 'escudeiro_alquimista', '-o', folder,
                              '--palette', 'none'])
            self.assertTrue(result['ok'], result)
            plan = json.loads(Path(result['plan']).read_text())
            self.assertEqual(plan['kind'], 'royal_64')
            self.assertEqual(plan['production']['role'], 'squire')
            self.assertEqual(plan['mode'], 'adapt_concept')
            self.assertEqual(plan['cast']['function_scope'], 'visual_proposal_not_runtime')
            self.assertIn('offers the next prepared potion', plan['prompt'])
            self.assertIn('same absolute world size', plan['prompt'])
            self.assertIn('no tongs', plan['prompt'])
            self.assertIn('no shield', plan['prompt'])
            self.assertEqual(plan['fidelity']['character'], 'alchemist_squire')
            self.assertEqual([a['role'] for a in plan['attachments']], ['identity'])
            self.assertFalse(result['network'])

    def test_alchemist_preserves_east_asian_identity_and_original_long_nose(self):
        with tempfile.TemporaryDirectory() as folder:
            result = cli.run(['elenco', '--character', 'alchemist_emperor', '-o', folder,
                              '--palette', 'none'])
            plan = json.loads(Path(result['plan']).read_text())
            self.assertEqual(plan['kind'], 'royal_80')
            self.assertIn('East Asian', plan['prompt'])
            self.assertIn('long projecting nose', plan['prompt'])
            self.assertEqual(plan['fidelity']['target_canvas'], [80, 80])

    def test_existing_plan_and_prompt_commands_resolve_catalogue_aliases(self):
        with tempfile.TemporaryDirectory() as folder:
            for command in ('plan', 'prompt'):
                result = cli.run([command, 'imperador alquimista', '--character', 'alquimista',
                                  '--palette', 'none', '-o', str(Path(folder) / command)])
                self.assertTrue(result['ok'], result)
                output = Path(result['plan']).read_text() if command == 'plan' else result['prompt']
                self.assertIn('long projecting nose', output)

    def test_every_catalogued_identity_produces_a_valid_plan(self):
        from tools.forja import cast
        data = cast.load()
        with tempfile.TemporaryDirectory() as folder:
            for entry in data['characters']:
                result = cli.run(['elenco', '--character', entry['id'], '--palette', 'none',
                                  '-o', str(Path(folder) / entry['id'])])
                self.assertTrue(result['ok'], (entry['id'], result))

    def test_unknown_character_and_missing_output_do_not_guess(self):
        with self.assertRaisesRegex(ValueError, 'personagem'):
            cli.run(['elenco', '--character', 'not_a_character', '-o', 'unused'])
        with self.assertRaisesRegex(ValueError, 'out'):
            cli.run(['elenco', '--character', 'cook'])

    def test_superseded_shield_squire_is_refused_before_generation(self):
        from tools.forja import cast
        data = cast.load()
        contract = cast.authority(data, cast.character(data, 'alchemist_squire'))
        old = Path(contract['base']) / contract['characters'][0]['rejected_candidates'][0]['file']
        with tempfile.TemporaryDirectory() as folder:
            result = cli.run(['plan', 'escudeiro alquimista', '--character', 'alchemist_squire',
                              '--reference', str(old), '--palette', 'none', '-o', folder])
            self.assertFalse(result['ok'])
            self.assertIn('rejeitado', ' '.join(result['errors']))
            self.assertFalse(result['network'])

    def test_mcp_exposes_catalogue_listing_without_requiring_a_character(self):
        tool = next(t for t in mcp_server.tools() if t['name'] == 'forja_elenco')
        self.assertNotIn('character', tool['inputSchema']['required'])
        result = mcp_server.call('forja_elenco', {})
        self.assertFalse(result.get('isError', False), result)

    def test_female_roles_infer_the_same_grid_as_their_male_counterparts(self):
        for subject, kind in [('imperatriz corsaria', 'royal_80'), ('corsair empress', 'royal_80'),
                              ('escudeira da lanterna', 'royal_64'), ('escudeiro', 'royal_64')]:
            self.assertEqual(production.resolve(subject, None)['kind'], kind, subject)

    def test_catalogue_does_not_silently_accept_a_changed_authority(self):
        from tools.forja import cast
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'cast.json'
            data = json.loads(cast.DEFAULT.read_text())
            data['characters'][0]['contract'] = 'missing.json'
            path.write_text(json.dumps(data))
            with self.assertRaises(ValueError):
                cast.load(path)
