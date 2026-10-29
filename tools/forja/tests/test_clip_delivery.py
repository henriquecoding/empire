"""Entrega portavel, transicoes e comparacao de custo sem aprovacao automatica."""
import copy
import json
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

from PIL import Image

from tools.forja import ase, choreography, cli, clip_export, godot, motion_review, pose, pose_library
from tools.forja.backends import sha
from tools.forja.tests.choreography_fixtures import clip


class ClipDeliveryTests(unittest.TestCase):
    @unittest.skipUnless(os.environ.get('GODOT') or shutil.which('godot'), 'sem o motor: GODOT ou godot no PATH')
    def test_exported_clip_opens_with_exact_timing_and_loop_in_godot(self):
        engine = os.environ.get('GODOT') or shutil.which('godot')
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            data = clip(root)
            data['frames'][0]['duration_ms'] = 200
            data['frames'][1]['duration_ms'] = 50
            data['frames'][2]['duration_ms'] = 50
            raw = (root / 'identity.png').read_bytes()
            out = root / 'out'
            clip_export.package(data, [raw] * 5, root, out)
            (out / 'project.godot').write_text('config_version=5\n[application]\nconfig/name="forja"\n')
            (out / 'check.gd').write_text(godot.CHECK_SCRIPT)
            subprocess.run([engine, '--headless', '--path', str(out), '--import'], capture_output=True, timeout=180)
            result = subprocess.run([engine, '--headless', '--path', str(out), '-s', 'check.gd', '--', 'res://attack.tres'],
                                    capture_output=True, text=True, timeout=120)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            line = next(line for line in result.stdout.splitlines() if line.startswith('FORJA_OK spriteframes'))
            animation = json.loads(line.split('spriteframes', 1)[1])[0]
            self.assertEqual(animation[:4], ['attack', 5, 10, False])
            self.assertEqual(animation[4], [[0, 2], [80, .5], [160, .5], [240, 1], [320, 1]])

    def test_package_survives_source_removal_and_preserves_frames(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            data = clip(root)
            raw = (root / 'identity.png').read_bytes()
            out = root / 'out'
            result = clip_export.package(data, [raw] * 5, root, out)
            (root / 'identity.png').unlink()
            saved = json.loads((out / 'clip.json').read_text())
            self.assertEqual(choreography.validate(saved, out)['errors'], [])
            self.assertEqual(len(list((out / 'frames').glob('*.png'))), 5)
            sprite = ase.read(out / 'attack.aseprite')
            self.assertEqual(sprite.durations, [100] * 5)
            for i in range(5):
                self.assertEqual(ase.render(sprite, i).getpixel((40, 40)), (20, 30, 40, 255))
            self.assertIn('"loop": false', (out / 'attack.tres').read_text())
            self.assertEqual(result['approval'], 'pending')
            review = json.loads((out / 'review.json').read_text())
            self.assertEqual(review['frames'][0]['sha256'], sha(raw))
            self.assertFalse(review['review']['raster_contract_ok'])
            self.assertTrue(any(f['code'] == 'raster_contract' for f in review['review']['findings']))

    def test_bad_json_reports_errors_without_crashing(self):
        with tempfile.TemporaryDirectory() as tmp:
            data = clip(Path(tmp))
            data['id'] = 123
            data['action'] = []
            self.assertTrue(choreography.validate(data, Path(tmp))['errors'])
            data = clip(Path(tmp))
            data['reference']['pose'] = []
            self.assertTrue(choreography.validate(data, Path(tmp))['errors'])
            data['frames'][0]['pose']['contacts'] = [{'point': [], 'target': 'grip'}]
            self.assertTrue(pose.validate(data['frames'][0]['pose']))

    def test_dry_run_needs_no_key_and_rejects_incompatible_route(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / 'clip.json').write_text(json.dumps(clip(root)))
            report = cli.run(['animar', str(root / 'clip.json')])
            self.assertFalse(report['network'])
            self.assertEqual(report['request']['expected_frames'], 5)
            with self.assertRaisesRegex(ValueError, 'pares'):
                cli.run(['animar', str(root / 'clip.json'), '--method', 'text-v3'])

    def test_transition_distinguishes_declared_and_unknown(self):
        with tempfile.TemporaryDirectory() as tmp:
            first = clip(Path(tmp))
            second = copy.deepcopy(first)
            second['frames'][0]['pose']['points']['RIGHT LEG'][0] += 5
            report = motion_review.transition(first, second)
            self.assertEqual(report['points']['RIGHT LEG']['status'], 'review')
            second['frames'][0]['pose']['inferred'] = ['RIGHT LEG']
            report = motion_review.transition(first, second)
            self.assertEqual(report['points']['RIGHT LEG']['status'], 'pending')

    def test_recipes_have_distinct_editable_phases_and_remain_studies(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            clip(root)
            for action in pose_library.PHASES:
                data = pose_library.create(root / 'identity.png', 'royal_80', action, 'mannequin')
                self.assertEqual(choreography.validate(data, root)['errors'], [])
                self.assertGreater(len({json.dumps(f['pose']['points']) for f in data['frames']}), 1)
                self.assertTrue(data['study'])

    def test_fixed_regions_detect_pixel_changes_without_freezing_motion(self):
        with tempfile.TemporaryDirectory() as tmp:
            data = clip(Path(tmp))
            for f in data['frames']:
                f['pose']['regions'] = {'badge': {'box_px': [35, 30, 40, 35], 'behavior': 'fixed'}}
            images = [Image.new('RGBA', (80, 80)) for _ in range(5)]
            images[1].putpixel((36, 31), (255, 0, 0, 255))
            images[2].putpixel((4, 4), (255, 0, 0, 255))
            changed = [f['frame'] for f in motion_review.analyze(data, images)['findings']
                       if f['code'] == 'region_changed']
            self.assertEqual(changed, [1])
