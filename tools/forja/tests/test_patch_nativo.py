"""P1 (FORJA-10): o patch nativo edita so na mascara, por operacoes explicitas, e prova que o resto ficou igual."""
import json
import unittest

from PIL import Image

from tools.forja import cli, equipment, pixel_patch as pp
from tools.forja.tests import equip_fixtures as ef
from tools.forja.tests.helpers import tempdir

RED, BLUE = '#C0302A', '#2A4C8C'


def base() -> Image.Image:
    image = Image.new('RGBA', (16, 16))
    for y in range(4, 12):
        for x in range(4, 12):
            image.putpixel((x, y), (200, 180, 140, 255))
    image.putpixel((7, 6), (10, 8, 12, 255))  # a pupila: um pixel isolado com funcao
    image.putpixel((14, 1), (250, 240, 215, 255))  # um brilho solto fora de tudo
    return image


def patch(image, *ops, **extra) -> dict:
    return {'schema': pp.SCHEMA, 'base': {'pixels_sha256': equipment.image_sha(image), 'canvas': list(image.size)},
            'mask': [[4, 8, 12, 12]], 'protected': [{'id': 'eye', 'box': [6, 5, 9, 8]}],
            'author': 'teste', 'date': '2026-10-28', 'reason': 'boca', 'operations': list(ops), **extra}


class PatchTest(unittest.TestCase):
    def test_paint_inside_the_mask_keeps_every_outside_byte_and_reports_both_hashes(self):
        image = base()
        out, rep = pp.apply(image, patch(image, {'op': 'paint', 'pixels': [[6, 9, RED], [7, 9, RED]]}))
        self.assertEqual(rep['changed_pixels'], 2)
        self.assertEqual(rep['changed_bbox'], [6, 9, 8, 10])
        self.assertEqual(rep['base_pixels_sha256'], equipment.image_sha(image))
        self.assertEqual(rep['result_pixels_sha256'], equipment.image_sha(out))
        for y in range(16):
            for x in range(16):
                if not (4 <= x < 12 and 8 <= y < 12):
                    self.assertEqual(out.getpixel((x, y)), image.getpixel((x, y)))
        self.assertEqual(out.getpixel((7, 6)), (10, 8, 12, 255))
        self.assertEqual(out.getpixel((14, 1)), (250, 240, 215, 255))

    def test_refusals_outside_mask_canvas_protected_and_other_image(self):
        image = base()
        for op, text in (({'op': 'paint', 'pixels': [[2, 2, RED]]}, 'fora da mascara'),
                         ({'op': 'paint', 'pixels': [[20, 9, RED]]}, 'fora da tela'),
                         ({'op': 'paint', 'pixels': [[7, 9, '#C0302A80']]}, 'alfa intermedio')):
            with self.assertRaisesRegex(ValueError, text):
                pp.apply(image, patch(image, op))
        locked = patch(image, {'op': 'paint', 'pixels': [[7, 8, RED]]})
        locked['protected'] = [{'id': 'mouth_corner', 'box': [7, 8, 8, 9]}]
        with self.assertRaisesRegex(ValueError, 'protegido'):
            pp.apply(image, locked)
        other = image.copy()
        other.putpixel((0, 0), (1, 1, 1, 255))
        with self.assertRaisesRegex(ValueError, 'outra imagem'):
            pp.apply(other, patch(image, {'op': 'paint', 'pixels': [[6, 9, RED]]}))
        wrong = patch(image, {'op': 'paint', 'pixels': [[6, 9, RED]]})
        wrong['base']['canvas'] = [64, 64]
        with self.assertRaisesRegex(ValueError, 'tela'):
            pp.apply(image, wrong)
        pinned = patch(image, {'op': 'paint', 'pixels': [[6, 9, RED]]}, pins=[{'id': 'pupil', 'xy': [7, 6],
                                                                                  'rgba': '#FFFFFF'}])
        with self.assertRaisesRegex(ValueError, 'pino pupil'):
            pp.apply(image, pinned)

    def test_base_with_soft_alpha_and_colors_outside_the_palette_are_refused(self):
        soft = base()
        soft.putpixel((1, 1), (9, 9, 9, 128))
        with self.assertRaisesRegex(ValueError, 'alfa intermedio'):
            pp.apply(soft, patch(soft, {'op': 'paint', 'pixels': [[6, 9, RED]]}))
        image = base()
        with self.assertRaisesRegex(ValueError, 'fora da paleta'):
            pp.apply(image, patch(image, {'op': 'paint', 'pixels': [[6, 9, RED]]}), [(200, 180, 140)])
        _, rep = pp.apply(image, patch(image, {'op': 'paint', 'pixels': [[6, 9, RED]]}, allow_new_colors=True),
                          [(200, 180, 140)])
        self.assertEqual(rep['new_colors'], [RED])

    def test_region_rows_with_a_legend_and_keep(self):
        image = base()
        op = {'op': 'region', 'box': [5, 9, 10, 10], 'rows': ['.rrr.'], 'legend': {'.': 'keep', 'r': RED}}
        out, rep = pp.apply(image, patch(image, op))
        self.assertEqual(rep['changed_pixels'], 3)
        self.assertEqual(out.getpixel((5, 9)), image.getpixel((5, 9)))
        with self.assertRaisesRegex(ValueError, 'linhas'):
            pp.apply(image, patch(image, {**op, 'rows': ['.rr.']}))
        with self.assertRaisesRegex(ValueError, 'sem legenda'):
            pp.apply(image, patch(image, {**op, 'rows': ['.rxr.']}))

    def test_move_a_cluster_with_a_validated_destination(self):
        image = base()
        image.putpixel((6, 10), (42, 76, 140, 255))
        p = patch(image, {'op': 'move', 'box': [5, 9, 8, 11], 'select': [BLUE], 'to': [2, 0],
                          'fill': '#C8B48C'})
        out, rep = pp.apply(image, p)
        self.assertEqual(out.getpixel((8, 10)), (42, 76, 140, 255))
        self.assertEqual(out.getpixel((6, 10)), (200, 180, 140, 255))
        p['operations'][0]['to'] = [8, 0]
        with self.assertRaisesRegex(ValueError, 'fora da mascara|fora da tela'):
            pp.apply(image, p)

    def test_no_operation_removes_isolated_pixels_or_resamples(self):
        image = base()
        out, rep = pp.apply(image, patch(image, {'op': 'paint', 'pixels': [[6, 9, RED]]}))
        self.assertFalse(rep['singletons_removed_automatically'] or rep['resampled'] or rep['blurred'])
        self.assertEqual(out.getpixel((14, 1)), (250, 240, 215, 255))
        self.assertEqual(out.size, image.size)


class PatchCliTest(unittest.TestCase):
    def test_cli_writes_png_diff_report_and_invalidates_the_old_observation(self):
        d = tempdir()
        image = ef.bow('valid')
        image.save(d / 'bow.png')
        (d / 'man.json').write_text(json.dumps(ef.bow_manifest()))
        (d / 'obs.json').write_text(json.dumps(ef.bow_observation(image)))
        p = {'schema': pp.SCHEMA, 'base': {'pixels_sha256': equipment.image_sha(image), 'canvas': [80, 80]},
             'mask': [[50, 15, 80, 66]], 'author': 't', 'date': '2026-10-28', 'reason': 'corda',
             'operations': [{'op': 'paint', 'pixels': [[57, 40, ef.STRING]]}]}
        (d / 'p.json').write_text(json.dumps(p))
        r = cli.run(['patch', str(d / 'bow.png'), str(d / 'p.json'), '-o', str(d / 'o'), '--kind', 'royal_80',
                     '--manifest', str(d / 'man.json'), '--observation', str(d / 'obs.json')])
        self.assertEqual(r['report']['equipment']['status'], 'not_evaluated')
        self.assertIn('lint', r['report'])
        for key in ('png', 'preview', 'diff', 'json'):
            self.assertTrue((d / 'o' / r['files'][key].split('/')[-1]).is_file())
        with Image.open(r['files']['diff']) as dif:
            self.assertEqual(dif.size, (80 * 8 * 3 + 32, 640))

    def test_cli_refuses_to_write_in_art(self):
        d = tempdir()
        image = base()
        image.save(d / 'b.png')
        (d / 'p.json').write_text(json.dumps(patch(image, {'op': 'paint', 'pixels': [[6, 9, RED]]})))
        with self.assertRaisesRegex(ValueError, 'art/'):
            cli.run(['patch', str(d / 'b.png'), str(d / 'p.json'), '-o', 'art/forja-teste'])


if __name__ == '__main__':
    unittest.main()
