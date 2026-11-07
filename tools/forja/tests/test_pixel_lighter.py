"""Luz por pixel, sem alterar os quadros nativos nem a timeline do Aseprite."""
import unittest
from pathlib import Path

from PIL import Image, ImageDraw

from tools.forja import ase, aseprite, cli, mcp_server
from tools.forja.ase.build import cel
from tools.forja.tests.helpers import tempdir


def actor():
    img = Image.new("RGBA", (64, 64))
    draw = ImageDraw.Draw(img)
    draw.rectangle((16, 12, 47, 59), fill="#221b18")
    draw.rectangle((17, 13, 25, 58), fill="#bc895b")
    draw.rectangle((26, 13, 46, 58), fill="#765643")
    draw.point((40, 25), fill="#17120e")
    return img


class PixelLighterTest(unittest.TestCase):
    def test_luz_mantem_alpha_e_reage_de_lados_opostos(self):
        from tools.forja import pixel_lighter as light

        img = actor()
        before = img.tobytes()
        normal, mask = light.generate(img)
        self.assertEqual(img.tobytes(), before)
        for result in (normal, mask):
            self.assertEqual(result.size, (64, 64))
            self.assertEqual(result.getchannel("A").tobytes(), img.getchannel("A").tobytes())
        self.assertLess(mask.getpixel((40, 25))[0], mask.getpixel((23, 25))[0])
        self.assertEqual(normal.getpixel((16, 25)), normal.getpixel((17, 25)))
        self.assertEqual(normal.getpixel((40, 25)), normal.getpixel((41, 25)))
        self.assertNotEqual(normal.getpixel((23, 25)), (128, 128, 255, 255))
        left = light.preview(img, normal, mask, (-10, 32))
        right = light.preview(img, normal, mask, (74, 32))
        self.assertGreater(left.getpixel((23, 25))[0], right.getpixel((23, 25))[0])
        self.assertEqual(left.getchannel("A").tobytes(), img.getchannel("A").tobytes())

    def test_aseprite_preserva_as_camadas_pivo_tags_e_quadro_vazio(self):
        folder = tempdir()
        img = actor()
        empty = Image.new("RGBA", img.size)
        source = aseprite.assemble(img.size, {"body": [img, empty], "weapon_bow": [empty, empty]},
                                  [74, 156], [("idle", 0, 1, "reverse")], pivot=(32, 60))
        path = aseprite.save(source, folder / "actor.aseprite")
        original = path.read_bytes()
        source = ase.read(path)
        result = cli.run(["luz", str(path), "--kind", "troop_64", "-o", str(folder / "study")])
        self.assertEqual(path.read_bytes(), original)
        self.assertTrue(result["ok"])
        self.assertEqual(result["frames"], 2)
        output = ase.read(result["files"]["aseprite"])
        self.assertEqual(output.layers[:2], source.layers)
        self.assertEqual(output.durations, source.durations)
        self.assertEqual(output.tags, source.tags)
        self.assertEqual(output.slices, source.slices)
        self.assertEqual(ase.render(output, 0).tobytes(), img.tobytes())
        self.assertIsNone(ase.render(output, 1).getbbox())
        self.assertEqual([layer.name for layer in output.layers[2:]], ["forja_normal", "forja_light_mask"])
        self.assertTrue(all(layer.has("editable") and not layer.has("visible") for layer in output.layers[2:]))
        with Image.open(result["files"]["surface"]) as surface:
            self.assertEqual(surface.getpixel((0, 0)), (128, 128, 255))
        self.assertTrue(any(tool["name"] == "forja_luz" for tool in mcp_server.tools()))

    def test_edicao_da_mascara_reexporta_os_pixels_sem_recorrer_ao_algoritmo(self):
        folder = tempdir()
        path = folder / "actor.png"
        actor().save(path)
        result = cli.run(["luz", str(path), "-o", str(folder / "first")])
        src = ase.read(result["files"]["aseprite"])
        key = (2, 0)
        mask = ase.render(src, 0, {2})
        mask.putpixel((23, 25), (0, 0, 0, 255))
        src.cels[key] = cel(mask)
        edit = aseprite.save(src, folder / "edit.aseprite")
        result = cli.run(["luz", str(edit), "--mapas-editados", "-o", str(folder / "second")])
        with Image.open(result["files"]["mask"]) as img:
            self.assertEqual(img.getpixel((23, 25)), (0, 0, 0, 255))
        with Image.open(result["files"]["surface"]) as img:
            self.assertEqual(img.getpixel((23, 25))[2], 0)
        mask.putpixel((23, 25), (0, 0, 0, 0))
        src.cels[key] = cel(mask)
        aseprite.save(src, edit)
        with self.assertRaisesRegex(ValueError, "alfa"):
            cli.run(["luz", str(edit), "--mapas-editados", "-o", str(folder / "third")])

    def test_fonte_indexada_gera_uma_companheira_rgb_com_os_mesmos_quadros(self):
        folder = tempdir()
        path = Path(__file__).with_name("ase_fixtures") / "forja_indexed.aseprite"
        src = ase.read(path)
        result = cli.run(["luz", str(path), "-o", str(folder)])
        out = ase.read(result["files"]["aseprite"])
        self.assertEqual(result["source_depth"], 8)
        self.assertFalse(result["source_layers_preserved"])
        self.assertEqual(out.depth, 32)
        self.assertEqual(out.durations, src.durations)
        self.assertEqual(out.tags, src.tags)
        for i in range(src.frames):
            self.assertEqual(ase.render(out, i).tobytes(), ase.render(src, i).tobytes())

    def test_os_atlas_do_jogo_correspondem_aos_originais(self):
        from tools import bake_royal_lighting

        self.assertTrue(bake_royal_lighting.check())
