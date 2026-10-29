import copy
import json
import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from PIL import Image

from tools.forja import choreography, motion_review, pose
from tools.forja.backends import http, pixellab_animation
from tools.forja.tests.choreography_fixtures import clip
from tools.forja.tests.test_backends import Fake, ENV


class ChoreographyTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.folder = Path(self.temp.name)
        self.clip = clip(self.folder)

    def test_native_canvas_and_odd_frame_count(self):
        self.assertEqual(choreography.validate(self.clip, self.folder)['errors'], [])
        data = (self.folder / 'identity.png').read_bytes()
        call = pixellab_animation.call(data, self.clip)
        with patch.dict(os.environ, ENV):
            body = json.loads(call.request().body)
        self.assertEqual(len(body['keypoints']), 5)
        self.assertEqual(len(body['first_frame_keypoints']), 18)
        self.assertEqual(body['view'], 'side')
        self.assertEqual(body['direction'], 'east')
        self.assertNotIn('depth', body['keypoints'][0][0])
        self.assertAlmostEqual(body['keypoints'][0][0]['x'], 40 / 79)
        self.assertNotIn('base64', json.dumps(call.descriptor))

    def test_contract_count_loop_duration_and_reference_are_enforced(self):
        for field, value in [('loop', True), ('frames', self.clip['frames'][:4])]:
            bad = copy.deepcopy(self.clip)
            bad[field] = value
            self.assertTrue(choreography.validate(bad, self.folder)['errors'])
        self.clip['frames'][0]['duration_ms'] = 0
        self.assertTrue(choreography.validate(self.clip, self.folder)['errors'])
        self.clip = clip(self.folder)
        Image.new('RGBA', (80, 80), 'red').save(self.folder / 'identity.png')
        self.assertTrue(choreography.validate(self.clip, self.folder)['errors'])

    def test_missing_duplicate_or_nonfinite_joints_fail_before_network(self):
        for value in ([-1, 2], [float('nan'), 1], [True, 1], [80, 2]):
            p = copy.deepcopy(self.clip['frames'][0]['pose'])
            p['points']['NOSE'] = value
            self.assertTrue(pose.validate(p))
        del self.clip['frames'][0]['pose']['points']['NECK']
        self.assertTrue(choreography.validate(self.clip, self.folder)['errors'])

    def test_text_rejects_odd_counts_and_keeps_exact_even_counts(self):
        ref = (self.folder / 'identity.png').read_bytes()
        with self.assertRaises(ValueError):
            pixellab_animation.call(ref, self.clip, 'text-v3')
        c = clip(self.folder, 'walk', 8)
        with patch.dict(os.environ, ENV):
            body = json.loads(pixellab_animation.call(ref, c, 'text-v3').request().body)
        self.assertEqual(body['frame_count'], 8)
        self.assertFalse(body['enhance_prompt'])

    def test_support_in_world_detects_slide_not_fixed_pivot(self):
        c = self.clip
        c['frames'][1]['root_px'] = [4, 0]
        report = motion_review.analyze(c)
        self.assertTrue(any(x['code'] == 'support_slide' for x in report['findings']))
        c['frames'][1]['pose']['points']['RIGHT LEG'][0] -= 4
        report = motion_review.analyze(c)
        self.assertFalse(any(x['code'] == 'support_slide' for x in report['findings']))
        self.assertEqual(report['approval'], 'pending')

    def test_unknown_contact_is_pending_not_passed(self):
        self.clip['frames'][0]['pose']['contacts'] = [
            {'point': 'RIGHT ARM', 'target': 'grip', 'tolerance_px': 1}]
        self.clip['frames'][0]['pose']['occluded'] = ['RIGHT ARM']
        r = motion_review.analyze(self.clip)
        self.assertTrue(any(x['status'] == 'pending' for x in r['findings']))

    @patch.dict(os.environ, ENV)
    def test_poll_uses_only_ordered_images_without_echoed_reference(self):
        ref = (self.folder / 'identity.png').read_bytes()
        image = {'type': 'base64', 'base64': http.b64(ref)}
        fake = Fake((200, {'background_job_id': 'test-id'}),
                    (200, {'status': 'completed', 'last_response':
                           {'images': [image] * 5, 'first_frame': image}}))
        result = choreography.generate(self.clip, self.folder, self.folder / 'out', transport=fake,
                                       sleep=lambda _: None)
        self.assertEqual(len(result['images']), 5)
        self.assertEqual(len(fake.requests), 2)
        again = choreography.generate(self.clip, self.folder, self.folder / 'out', transport=fake)
        self.assertEqual(again['job']['id'], result['job']['id'])
        self.assertEqual(len(fake.requests), 2)

    @patch.dict(os.environ, ENV)
    def test_bad_return_is_retained_but_never_exported_or_repaid(self):
        image = {'base64': http.b64((self.folder / 'identity.png').read_bytes())}
        fake = Fake((200, {'background_job_id': 'bad'}),
                    (200, {'status': 'completed', 'last_response': {'images': [image] * 4}}))
        for _ in range(2):
            with self.assertRaisesRegex(ValueError, 'quadros'):
                choreography.generate(self.clip, self.folder, self.folder / 'out', transport=fake,
                                       sleep=lambda _: None)
        self.assertEqual(len(fake.requests), 2)

    @patch.dict(os.environ, ENV)
    def test_ambiguous_post_is_not_repeated(self):
        fake = Fake(TimeoutError('unknown'))
        for _ in range(2):
            with self.assertRaises(RuntimeError):
                choreography.generate(self.clip, self.folder, self.folder / 'out', transport=fake)
        self.assertEqual(len(fake.requests), 1)
