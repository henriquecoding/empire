"""FORJA-03: reparo com mascara, composicao declarada, corda refeita e contorno que respeita linhas finas."""
import io
import unittest

from PIL import Image

from tools.forja import compose, inpaint, masks, outline, pipeline, repair
from tools.forja.imageops import CLEAR
from tools.forja.tests.helpers import tempdir

RED, BLUE, CREAM, BLACK = (200, 40, 40, 255), (40, 40, 200, 255), (229, 211, 149, 255), (0, 0, 0, 255)


def board(size=(20, 20)) -> Image.Image:
    img = Image.new("RGBA", size, CLEAR)
    img.paste(RED, (2, 2, 8, 8))
    img.paste(BLUE, (12, 2, 18, 8))
    return img


class MaskTest(unittest.TestCase):
    def test_conventions_round_trip_and_differ(self):
        region = masks.box((3, 4, 7, 9)) | {(15, 15)}
        for convention in masks.CONVENTIONS:
            with Image.open(io.BytesIO(masks.to_png((20, 20), region, convention, k=4))) as im:
                self.assertEqual(masks.from_png(im, convention, k=4), region, convention)
        with Image.open(io.BytesIO(masks.to_png((20, 20), region, "pixellab"))) as im:
            self.assertEqual(im.convert("L").getpixel((3, 4)), 255)
            self.assertEqual(im.convert("L").getpixel((0, 0)), 0)
        with self.assertRaises(ValueError):
            masks.to_png((4, 4), region, "midjourney")

    def test_selector_by_box_colours_and_exclusion(self):
        img = board()
        red = masks.select(img, {"box": [0, 0, 20, 20], "colors": ["#C82828"]})
        self.assertEqual(len(red), 36)
        rest = masks.select(img, {"box": [0, 0, 20, 20], "exclude": {"box": [0, 0, 10, 20]}})
        self.assertEqual(masks.bbox(rest), [12, 2, 18, 8])
        with self.assertRaises(ValueError):
            masks.select(img, {"pixels": [[25, 1]]})

    def test_components_through_an_occluder(self):
        string = {(5, y) for y in range(0, 20) if not 8 <= y < 11}
        arm = masks.box((0, 8, 12, 11))
        self.assertEqual(len(masks.components(string)), 2)
        self.assertEqual(len(masks.components(string, arm)), 1)


class ComposeTest(unittest.TestCase):
    def test_add_keeps_the_old_object_and_replace_does_not(self):
        native = board()
        old = masks.select(native, {"box": [0, 0, 10, 10], "colors": ["#C82828"]})
        candidate = native.copy()
        candidate.paste(CLEAR, (2, 2, 8, 8))
        candidate.paste(BLUE, (3, 3, 5, 9))
        zone = masks.box((0, 0, 10, 10))
        added, info = compose.compose(native, candidate, zone, "add", old=old)
        self.assertEqual(added.getpixel((7, 7)), RED)
        self.assertEqual(info["findings"][0]["code"], "overlay_keeps_old")
        self.assertFalse(info["ok"])
        replaced, info = compose.compose(native, candidate, zone, "replace", old=old)
        self.assertEqual(replaced.getpixel((7, 7)), CLEAR)
        self.assertTrue(info["ok"] and info["outside_identical"])

    def test_remove_must_take_every_old_pixel_and_masks_must_cover_the_object(self):
        native = board()
        old = masks.select(native, {"box": [0, 0, 10, 10], "colors": ["#C82828"]})
        _, info = compose.compose(native, native.copy(), masks.box((0, 0, 10, 10)), "remove", old=old)
        self.assertIn("removed_object_remains", [f["code"] for f in info["findings"]])
        empty = native.copy()
        empty.paste(CLEAR, (0, 0, 10, 10))
        _, info = compose.compose(native, empty, masks.box((0, 0, 5, 10)), "replace", old=old, joints=[(9, 9)])
        codes = [f["code"] for f in info["findings"]]
        self.assertIn("old_outside_mask", codes)
        self.assertIn("joint_outside_mask", codes)

    def test_protected_regions_refuse_overlap_and_are_verified_after_finishing(self):
        native = board()
        with self.assertRaisesRegex(ValueError, "protegidos"):
            compose.compose(native, native, masks.box((0, 0, 10, 10)), protect=masks.box((6, 6, 14, 14)))
        candidate = native.copy()
        candidate.putpixel((4, 4), BLUE)
        out, info = compose.compose(native, candidate, {(4, 4)}, protect=masks.box((11, 1, 19, 9)))
        self.assertTrue(info["ok"])
        finished = outline.add(out)
        proof = compose.verify(native, finished, {(4, 4)}, masks.box((11, 1, 19, 9)))
        self.assertFalse(proof["outside_identical"])
        self.assertFalse(proof["protected_identical"])

    def test_inpaint_merge_takes_an_arbitrary_mask_and_a_method(self):
        native = board()
        image, mask, k, _, key = inpaint.prepare(native, None, region={(4, 4), (5, 5)})
        with Image.open(io.BytesIO(mask)) as im:
            self.assertEqual(masks.from_png(im, "openai", k), {(4, 4), (5, 5)})
        with Image.open(io.BytesIO(image)) as im:
            echo = im.convert("RGBA")
        out, info = inpaint.merge(native, echo, k, None, key=key, region={(4, 4), (5, 5)}, method="add")
        self.assertEqual(out.tobytes(), native.tobytes())
        self.assertEqual(info["method"], "add")
        self.assertTrue(info["outside_identical"])


class StringRepairTest(unittest.TestCase):
    def setUp(self):
        self.img = Image.new("RGBA", (24, 40), CLEAR)
        self.img.paste(RED, (2, 18, 14, 22))
        for y in range(2, 38):
            x = 9 if y < 18 else 8
            self.img.putpixel((x, y), CREAM)
            if 6 <= y < 12 or y == 20:
                self.img.putpixel((x + 1, y), CREAM)
        self.line = masks.select(self.img, {"box": [0, 0, 24, 40], "colors": ["#E5D395"]})
        self.arm = masks.select(self.img, {"box": [0, 0, 24, 40], "colors": ["#C82828"]})

    def test_the_line_ends_one_pixel_wide_and_never_paints_over_the_arm(self):
        candidate, zone, info = repair.straighten(self.img, self.line, (9, 2), (8, 37), keep=self.arm)
        out, proof = compose.compose(self.img, candidate, zone, "replace", protect=self.arm - zone,
                                     old=self.line, joints=[(9, 2), (8, 37)])
        self.assertTrue(proof["ok"], proof)
        new = masks.select(out, {"box": [0, 0, 24, 40], "colors": ["#E5D395"]})
        rows = {}
        for x, y in new:
            rows[y] = rows.get(y, 0) + 1
        self.assertEqual(max(rows.values()), 1)
        self.assertEqual(info["inferred"], [[9, 20]])
        self.assertEqual(out.getpixel((9, 20)), RED)
        self.assertTrue(all(out.getpixel(p) == RED for p in self.arm - {(8, 18), (8, 19), (8, 20), (8, 21)}))


class ThinLineOutlineTest(unittest.TestCase):
    """As duas sondas do relatorio: o contorno global engrossa a corda e fecha o vazio; protegido, nao."""

    def probe(self) -> Image.Image:
        img = Image.new("RGBA", (16, 16), CLEAR)
        for y in range(2, 14):
            img.putpixel((4, y), CREAM)
            img.putpixel((8, y), CREAM)
            img.putpixel((11, y), CREAM)
        return img

    def test_global_outline_thickens_and_closes_unless_kept(self):
        img = self.probe()
        plain = outline.add(img)
        self.assertEqual(sum(plain.getpixel((x, 7))[3] > 0 for x in range(2, 7)), 3)
        self.assertTrue(all(plain.getpixel((x, 7))[3] for x in (9, 10)))
        keep = masks.box((0, 0, 16, 16))
        self.assertEqual(outline.add(img, keep=keep).tobytes(), img.tobytes())

    def test_pipeline_bare_box_keeps_the_string_thin_and_exempt(self):
        body = Image.new("RGBA", (30, 30), CLEAR)
        body.paste((65, 110, 78, 255), (4, 6, 14, 28))
        for y in range(4, 28):
            body.putpixel((20, y), CREAM)
        src = tempdir() / "corda.png"
        body.resize((240, 240), Image.Resampling.NEAREST).save(src)
        res = {}
        for bare in (None, [(15, 0, 18, 25)]):
            opts = pipeline.Options(kind="character_s2", scale=8.0, palette="none", bare=bare, fit=False)
            r = pipeline.forge(src, tempdir(), opts, report_html=False)
            self.assertEqual(bool(r["finish"].get("outline_bare")), bool(bare))
            final = Image.open(r["files"]["png"]).convert("RGBA")
            res[bool(bare)] = sum(final.getpixel((x, 12))[3] > 0 for x in range(final.width - 6, final.width))
        self.assertEqual(res[False], 3)
        self.assertEqual(res[True], 1)


if __name__ == "__main__":
    unittest.main()
