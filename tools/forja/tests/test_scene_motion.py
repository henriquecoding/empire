import copy
import tempfile
import unittest
from pathlib import Path

from PIL import Image

from tools.forja import scene, scene_motion
from tools.forja.backends import sha
from tools.forja.tests.scene_fixtures import contract, house


class SceneMotionTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.folder = Path(self.temp.name)
        self.scene = contract()
        frames = []
        for i in range(2):
            image = Image.new('RGBA', (16, 16))
            image.putpixel((4 + i, 4), (240, 120, 40, 255))
            file = self.folder / f'{i}.png'
            image.save(file)
            frames.append({'file': file.name, 'sha256': sha(file.read_bytes()),
                           'duration_ms': 100, 'anchor_px': [8, 14]})
        self.scene['components'] = [{'id': 'flame', 'role': 'effect', 'region_px': [96, 0, 112, 16],
                                     'anchor_px': [104, 14], 'layer': 1, 'loop': True, 'frames': frames}]

    def test_composition_keeps_structure_outside_component(self):
        self.assertEqual(scene.validate(self.scene, self.folder)['errors'], [])
        frames, durations = scene_motion.compose(self.scene, house(), self.folder)
        self.assertEqual(durations, [100, 100])
        for im in frames:
            self.assertEqual(im.crop((0, 16, 128, 128)).tobytes(), house().crop((0, 16, 128, 128)).tobytes())
        self.assertNotEqual(frames[0].tobytes(), frames[1].tobytes())

    def test_moved_anchor_changed_hash_and_outside_regions_are_refused(self):
        for field, value in [('anchor_px', [1, 1]), ('sha256', 'bad')]:
            data = copy.deepcopy(self.scene)
            data['components'][0]['frames'][1][field] = value
            self.assertTrue(scene.validate(data, self.folder)['errors'])
        self.scene['components'][0]['region_px'] = [120, 0, 136, 16]
        self.assertTrue(scene.validate(self.scene, self.folder)['errors'])

    def test_mutation_outside_mask_is_reported(self):
        candidate = house()
        candidate.putpixel((20, 50), (1, 2, 3, 255))
        report = scene_motion.review(self.scene, house(), [candidate])
        self.assertEqual(report['outside_changes'], [1])
        self.assertFalse(report['ok'])
        self.assertEqual(report['approval'], 'pending')

    def test_relations_distinguish_unobserved_from_gap(self):
        self.scene['interactions'] = [{'id': 'hammer', 'point_px': [30, 50], 'target_px': [30, 60],
                                       'tolerance_px': 1, 'observed': False}]
        report = scene_motion.review(self.scene, house(), [house()])
        self.assertEqual(report['interactions'][0]['status'], 'pending')
        self.scene['interactions'][0]['observed'] = True
        report = scene_motion.review(self.scene, house(), [house()])
        self.assertEqual(report['interactions'][0]['status'], 'review')
