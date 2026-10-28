"""Medir margens sem as confundir com a figura e converter com tamanho nativo estruturado."""
import base64
import io
import json
import os
import unittest
from unittest import mock

from PIL import Image

from tools.forja import auto, cli, equipment, jobs, pipeline, plan
from tools.forja.backends import pixellab_convert
from tools.forja.tests import audit_fixtures as fx
from tools.forja.tests.helpers import tempdir
from tools.forja.tests.test_backends import ENV, Fake, png


class OccupancyTest(unittest.TestCase):
    def test_native_one_to_one_preserves_every_visible_pixel_before_finishing(self):
        image = Image.new('RGBA', (64, 64))
        for y in range(4, 62):
            for x in range(3, 61):
                image.putpixel((x, y), ((x * 29) % 256, (y * 37) % 256, (x * y) % 256, 255))
        native, _ = pipeline.snap(image, pipeline.Options(scale=1, palette='none'))
        self.assertEqual(native.tobytes(), image.crop((3, 4, 61, 62)).tobytes())

    def test_transparent_outer_rows_are_measured_before_the_tight_crop(self):
        image = Image.new('RGBA', (100, 100))
        image.paste((50, 60, 70, 255), (10, 20, 90, 90))
        native, snap = pipeline.snap(image, pipeline.Options(scale=1, palette='none'))
        self.assertEqual(native.size, (80, 70))
        o = snap['occupancy']
        self.assertEqual(o['opaque_bbox'], [10, 20, 90, 90])
        self.assertEqual(o['clear_margins'], {'left': 10, 'top': 20, 'right': 10, 'bottom': 10})
        self.assertEqual(o['useful_size'], [80, 70])

    def test_low_alpha_residue_does_not_count_as_useful_extent(self):
        image = Image.new('RGBA', (100, 100))
        image.paste((50, 60, 70, 255), (10, 20, 90, 90))
        image.putpixel((0, 0), (1, 1, 1, 1))
        _, snap = pipeline.snap(image, pipeline.Options(scale=1, palette='none'))
        self.assertEqual(snap['occupancy']['opaque_bbox'], [10, 20, 90, 90])

    def test_clipped_output_has_an_uncut_diagnostic_not_a_silent_loss(self):
        d = tempdir()
        image = Image.new('RGBA', (97, 96), (50, 60, 70, 255))
        image.save(d / 'king.png')
        r = pipeline.forge(d / 'king.png', d / 'o', pipeline.Options(kind='royal_80', scale=1,
            palette='none', bg='#FF00FF', noise=0, cleanup='conservative', outline='keep'), report_html=False)
        self.assertFalse(r['delivery']['usable_sprite'])
        self.assertTrue(r['finish']['fit']['clipped_pixels'])
        with Image.open(r['files']['uncut_png']) as uncut:
            self.assertEqual(uncut.size, (97, 96))
        self.assertFalse(r['snap']['occupancy']['fits_canvas'])

    def test_conflicting_face_pins_cannot_return_ok_from_forge_cli(self):
        d = tempdir()
        image = fx.marked('dente')
        image.save(d / 'input.png')
        pins = [{'id': name, 'cell': [8, 8], 'color': color, 'status': 'authorized',
                 'source_annotation': 'test'} for name, color in [('tooth', '#FAF0D7'), ('lid', '#0A080C')]]
        (d / 'signals.json').write_text(json.dumps({'schema': 'forja.signals/1',
            'image_sha256': equipment.image_sha(image), 'pins': pins}))
        r = cli.run(['forge', str(d / 'input.png'), '-o', str(d / 'o'), '--scale', '16', '--bg', '#FF00FF',
            '--palette', 'none', '--no-fit', '--noise', '0', '--signals', str(d / 'signals.json')])
        self.assertEqual(r['signals']['status'], 'blocked')
        self.assertFalse(r['ok'])


class NativeConversionTest(unittest.TestCase):
    def test_large_concept_has_a_native_64_conversion_plan_without_local_resize(self):
        d = tempdir()
        Image.new('RGBA', (320, 280), (80, 40, 30, 255)).save(d / 'concept.png')
        p = plan.make('pixellab', 'ordinary troop archer', references=[('concept', str(d / 'concept.png'))],
                      model='image-to-pixelart')
        self.assertTrue(p.ok, p.data['errors'])
        call = p.call()
        self.assertEqual(call.descriptor['params']['output_size'], {'width': 64, 'height': 64})
        self.assertEqual(call.descriptor['params']['image_size'], {'width': 320, 'height': 320})
        self.assertEqual(p.data['source_frame']['offset'], [0, 40])
        self.assertTrue(call.descriptor['params']['fixer'])
        self.assertEqual(p.data['expect']['size'], [64, 64])
        self.assertEqual(p.data['expect']['grid'], 'native')

    def test_conversion_requires_one_source_and_refuses_style_only(self):
        p = plan.make('pixellab', 'king', 'royal_80', model='image-to-pixelart')
        self.assertFalse(p.ok)
        self.assertIn('exactly one source', ' '.join(p.data['errors']))

    def test_actual_request_has_only_supported_fields_and_no_source_resizing(self):
        d = tempdir()
        Image.new('RGB', (320, 280), (70, 90, 30)).save(d / 'concept.jpg')
        p = plan.make('pixellab', 'troop archer', references=[('concept', str(d / 'concept.jpg'))],
                      model='image-to-pixelart', init_strength=150)
        with mock.patch.dict(os.environ, ENV):
            request = p.call().request()
        body = json.loads(request.body)
        self.assertEqual(set(body), {'image', 'image_size', 'output_size', 'fixer', 'init_image_strength'})
        self.assertEqual(body['init_image_strength'], 150)
        data = base64.b64decode(body['image']['base64'])
        self.assertTrue(data.startswith(b'\x89PNG'))
        self.assertEqual(body['image_size'], {'width': 320, 'height': 320})
        with Image.open(io.BytesIO(data)) as sent, Image.open(d / 'concept.jpg') as given:
            self.assertEqual(sent.convert('RGB').crop((0, 40, 320, 320)).tobytes(), given.convert('RGB').tobytes())
        self.assertNotIn('base64', json.dumps(p.call().descriptor))

    def test_a_wrong_native_response_is_blocked_and_not_paid_for_again(self):
        d = tempdir()
        Image.new('RGBA', (320, 280), (90, 40, 20, 255)).save(d / 'source.png')
        p = plan.make('pixellab', 'troop archer', references=[('concept', str(d / 'source.png'))],
                      model='image-to-pixelart')
        fake = Fake((200, {'image': {'base64': base64.b64encode(png(size=(65, 64))).decode()}}))
        with mock.patch.dict(os.environ, ENV):
            r = auto.run(p, d / 'run', 3, jobs.Budget.open(d / 'run', 3), palette='none', transport=fake)
        self.assertFalse(r['ok'])
        self.assertEqual(len(fake.requests), 1)
        self.assertIn('identical paid request is not repeated', r['stopped'])

    def test_source_is_framed_not_resampled_to_the_output_aspect_and_useful_box(self):
        image = Image.new('RGB', (510, 478), (90, 90, 90))
        image.paste((200, 30, 40), (100, 50, 400, 478))
        framed, info = pixellab_convert.frame(image, (80, 80), (2, 2, 78, 79))
        self.assertEqual(framed.width, framed.height)
        self.assertFalse(info['resampled'])
        ox, oy = info['offset']
        self.assertEqual(framed.convert('RGB').crop((ox, oy, ox + 510, oy + 478)).tobytes(), image.tobytes())
        k = info['output_px_per_source_px']
        self.assertLessEqual(510 * k, 76.001)
        self.assertLessEqual(round((oy + 478) * k), 79)
        self.assertEqual(info['fill'], '#5A5A5AFF')

    def test_conversion_size_and_strength_are_checked_before_a_job(self):
        d = tempdir()
        Image.new('RGBA', (320, 280)).save(d / 'source.png')
        p = plan.make('pixellab', 'troop archer', references=[('concept', str(d / 'source.png'))],
                      model='image-to-pixelart', init_strength=1000)
        self.assertFalse(p.ok)
        with self.assertRaises(ValueError):
            p.call()


if __name__ == '__main__':
    unittest.main()
