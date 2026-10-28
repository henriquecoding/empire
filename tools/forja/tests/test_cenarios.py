"""Cenarios e construcoes (FORJA-09): a regua, o contrato de cena, o pedido e o plano por gerador."""
import json
import re
import shutil
import unittest
from pathlib import Path

from PIL import Image

from tools.forja import constraints, contracts, matte, palette as palmod, prompts, refs, regua, scene, scene_plan
from tools.forja import scene_prompt
from tools.forja.equipment import image_sha
from tools.forja.tests import scene_fixtures as fx
from tools.forja.tests.helpers import tempdir

ROOT = Path(__file__).resolve().parents[3]


class ReguaTest(unittest.TestCase):
    def test_the_ruler_is_read_from_the_cast_manifest(self):
        manifest = json.loads((ROOT / "art/export/royals/manifest.json").read_text(encoding="utf-8"))["assets"]
        rul = regua.ruler()
        tallest = max(regua.data()["actors"]["ruler"], key=lambda a: manifest[a]["body_bounds"][3])
        self.assertEqual(rul["tallest"]["id"], tallest)
        self.assertEqual(rul["tallest"]["height"], manifest[tallest]["body_bounds"][3])
        self.assertNotIn("royal_dancer", [a["id"] for a in rul["actors"]])
        self.assertLessEqual(rul["shortest"]["height"], rul["tallest"]["height"])

    def test_the_world_is_read_from_the_game_files(self):
        owner = json.loads((ROOT / "art/export/scenery_owner/manifest.json").read_text(encoding="utf-8"))
        project = (ROOT / "project.godot").read_text(encoding="utf-8")
        wld = regua.world()
        self.assertEqual((wld["surface_y"], wld["under_y"]), (owner["surface_y"], owner["under_y"]))
        self.assertEqual(wld["viewport"][0], int(re.search(r"viewport_width=(\d+)", project).group(1)))
        self.assertEqual(wld["notes"], [])

    def test_the_lattice_follows_the_owner_art_and_names_what_is_off_it(self):
        lat = regua.lattice(2, regua.world())
        self.assertEqual(lat["phase_source"], "medida na arte do dono")
        self.assertTrue(lat["art"]["consistent"])
        self.assertTrue(lat["anchors"]["surface_y"]["cell_edge"])
        if lat["off_lattice"]:
            self.assertIn("Q-293", lat["decision"])
        no_art = regua.lattice(2, {**regua.world(), "art_phase": {}})
        self.assertTrue(no_art["anchors"]["surface_y"]["cell_edge"])

    def test_metrics_round_inside_the_grid_and_clear_the_tallest_actor(self):
        rul = regua.ruler()
        found = regua.metrics(rul, 2)
        for m in found:
            self.assertEqual([v % 2 for v in m["px"]], [0, 0], m["id"])
            self.assertEqual(m["cells"], [v // 2 for v in m["px"]])
            self.assertLessEqual(m["px"][0], m["px"][1])
            self.assertTrue(m["origin"])
        self.assertGreater(regua.metric(found, "door_clear_height")["px"][0], rul["tallest"]["height"])

    def test_a_checkout_without_lfs_falls_back_to_the_body_box(self):
        root = tempdir()
        src = ROOT / "art/export/royals/manifest.json"
        (root / "art/export/royals").mkdir(parents=True)
        shutil.copy(src, root / "art/export/royals/manifest.json")
        (root / "art/export/royals/rei.png").write_text("version https://git-lfs.github.com/spec/v1\n")
        img, pivot, source = regua.frame("royal_king", root=root)
        self.assertIn("body_bounds", source)
        box = img.getchannel("A").getbbox()
        self.assertEqual(box[3] - box[1], regua.actors()[0]["height"])


class SceneTest(unittest.TestCase):
    def setUp(self):
        self.dir = tempdir()

    def errors(self, **over) -> list[str]:
        return scene.validate(fx.contract(**over), self.dir)["errors"]

    def test_a_valid_house_resolves_to_cells_anchor_and_forge_arguments(self):
        res = scene.resolve(scene.load(fx.write(self.dir, fx.contract())))
        self.assertEqual((res["kind"], res["step"], res["cells"]), ("building", 2, [64, 64]))
        self.assertEqual(res["anchor"]["local_px"], [64, 128])
        self.assertEqual(res["forge_args"], ["--kind", "building", "--canvas", "128x128", "--pivot", "64,127"])
        self.assertEqual(res["openings"][0]["cells"], [26, 22, 38, 64])

    def test_the_extent_is_explicit_and_on_the_grid(self):
        self.assertTrue(any("extent_px" in e for e in self.errors(extent_px=None)))
        self.assertTrue(any("grade" in e for e in self.errors(extent_px=[127, 128])))
        self.assertTrue(any("multipla de 32" in w for w in scene.validate(fx.contract(extent_px=[130, 128]),
                                                                           self.dir)["warnings"]))

    def test_doors_are_measured_against_the_tallest_actor_and_sit_on_the_ground(self):
        short = [{"id": "porta", "kind": "door", "box_px": [52, 80, 76, 128]}]
        self.assertTrue(any("pede pelo menos" in e for e in self.errors(openings=short)))
        gate = [{"id": "portao", "kind": "gate", "box_px": [40, 44, 88, 128]}]
        self.assertTrue(any("porta publica" in e for e in self.errors(openings=gate)))
        floating = [{"id": "porta", "kind": "door", "box_px": [52, 20, 76, 110]}]
        self.assertTrue(any("soleira" in e for e in self.errors(openings=floating)))
        self.assertFalse(self.errors(openings=[{**floating[0], "raised": True}]))
        self.assertTrue(any("tipo" in e for e in self.errors(openings=[{"id": "x", "kind": "hole",
                                                                         "box_px": [0, 0, 2, 2]}])))

    def test_vocabulary_states_and_references_are_checked(self):
        self.assertTrue(any("signals" in e for e in self.errors(signals=["face"])))
        self.assertTrue(any("materials" in e for e in self.errors(materials=["plastic"])))
        self.assertTrue(any("states" in e for e in self.errors(states=["burning"])))
        self.assertTrue(any("signal_regions" in e for e in self.errors(signal_regions={"supports": [0, 0, 2, 2]})))
        self.assertTrue(any("state_changes" in e for e in self.errors(state_changes={"burnt": [[0, 0, 2, 2]]})))
        self.assertTrue(any("state_changes" in e for e in self.errors(state_changes={"damaged": [[0, 0, 999, 2]]})))
        self.assertTrue(any("papel" in e for e in self.errors(references=[{"role": "identity", "file": "x.png"}])))
        fx.house().save(self.dir / "ref.png")
        ok = {"role": "asset_concept", "file": "ref.png", "pixels_sha256": image_sha(fx.house())}
        self.assertFalse(self.errors(references=[ok]))
        self.assertTrue(any("mudaram" in e for e in self.errors(references=[{**ok, "pixels_sha256": "0" * 64}])))
        self.assertTrue(any("recorte" in e for e in self.errors(references=[{**ok, "crop": [0, 0, 999, 9]}])))


class PromptTest(unittest.TestCase):
    def setUp(self):
        self.res = scene.resolve(scene.load(fx.write(tempdir(), fx.contract())))

    def test_no_square_canvas_is_invented_for_a_building(self):
        with self.assertRaises(ValueError):
            prompts.geometry("building", None, "gpt-image")
        self.assertEqual(prompts.geometry("building", None, "gpt-image", (64, 48))["canvas"], [64, 48])
        self.assertEqual(prompts.geometry("royal_80", None, "gpt-image")["canvas"], [80, 80])

    def test_a_facade_is_the_world_side_view_but_isometric_and_perspective_are_not(self):
        text = "the front facade of a smithy, front view"
        self.assertTrue(prompts.camera_conflicts(text, "right"))
        self.assertEqual(prompts.camera_conflicts(text, "right", "elevation"), [])
        self.assertTrue(prompts.camera_conflicts("an isometric smithy", "right", "elevation"))
        self.assertTrue(prompts.camera_conflicts("a smithy in perspective", "right", "elevation"))

    def test_the_outline_is_said_in_logical_pixels(self):
        self.assertIn("1-logical-pixel", constraints.outline(contracts.get("building"))["text"])
        self.assertIn("1-logical-pixel", constraints.outline(contracts.get("royal_80"))["text"])

    def test_the_scene_prompt_speaks_architecture_with_origins(self):
        built = scene_prompt.build(self.res, "gpt-image", ["asset_concept", "ruler", "palette"])
        text = built["prompt"]
        self.assertIn("orthographic side elevation", text)
        self.assertNotIn("profile", text)
        self.assertIn("x 26-37, y 22-63", text)
        tall = self.res["ruler"]["tallest"]["height"] / 2
        self.assertIn(f"{tall:.1f} logical pixels tall", text)
        self.assertIn("do NOT copy its resolution", text)
        self.assertIn("do NOT draw these figures", text)
        self.assertEqual(built["expect"]["cells"], [64, 64])
        self.assertEqual(built["conflicts"], [])
        self.assertTrue(all(c["origin"] for c in built["constraints"]))
        self.assertNotIn("compiler_default", [c["origin"] for c in built["constraints"]])

    def test_a_terrain_strip_walks_on_its_top_edge_and_a_lit_window_is_lit(self):
        strip = scene.resolve(scene.load(fx.write(tempdir(), fx.contract(
            asset="terrain_strip", extent_px=[64, 32], openings=[], signals=[], signal_regions={}, states=["done"],
            state_changes={}, materials=["soil"]))))
        self.assertIn("TOP edge is the walk line", scene_prompt.build(strip, "gpt-image")["prompt"])
        lit = fx.contract(openings=[fx.contract()["openings"][0],
                                    {"id": "janela", "kind": "window", "box_px": [16, 60, 40, 88], "treatment": "lit"}])
        text = scene_prompt.build(scene.resolve(scene.load(fx.write(tempdir(), lit))), "gpt-image")["prompt"]
        self.assertIn("a lit interior", text)

    def test_the_ruler_guide_has_the_request_size_and_the_actors(self):
        built = scene_prompt.build(self.res, "gpt-image")
        img = scene_prompt.ruler_guide(self.res, built["expect"])
        self.assertEqual(list(img.size), built["expect"]["size"])
        dark = img.getcolors(1 << 16)
        dark = sum(n for n, c in dark if c[:3] == (96, 96, 92))
        self.assertGreater(dark, 0)


class ScenePlanTest(unittest.TestCase):
    def setUp(self):
        self.dir = tempdir()
        fx.house().save(self.dir / "ref.png")
        self.path = fx.write(self.dir, fx.contract(references=[{"role": "asset_concept", "file": "ref.png"}]))

    def test_partition_covers_with_overlap(self):
        self.assertEqual(scene_plan.partition(640, 352, 64), [[0, 352], [288, 640]])
        self.assertEqual(scene_plan.partition(300, 400, 32), [[0, 300]])
        parts = scene_plan.partition(1280, 400, 32, 2)
        self.assertEqual((parts[0][0], parts[-1][1]), (0, 1280))
        self.assertTrue(all(b - a <= 400 for a, b in parts))
        self.assertTrue(all(parts[i][1] - parts[i + 1][0] >= 32 for i in range(len(parts) - 1)))

    def test_openai_and_gemini_plans_attach_the_ruler_and_keep_margins(self):
        pal = palmod.load(palmod.ROOT / contracts.get("building").palette)
        p = scene_plan.make("openai", self.path, pal)
        self.assertTrue(p.ok, p.data["errors"])
        self.assertEqual([a["prompt_role"] for a in p.data["attachments"]], ["asset_concept", "ruler", "palette"])
        self.assertEqual(p.data["expect"]["canvas_px"], [128, 128])
        g = scene_plan.make("gemini", fx.write(self.dir, fx.contract(extent_px=[256, 128]), "larga.json"))
        x0, y0, x1, y1 = g.data["expect"]["content"]
        if (x0, y0) != (0, 0):
            self.assertIn("Margins:", g.data["prompt"])

    def test_pixellab_draws_cells_and_refuses_a_panorama_with_a_partition(self):
        p = scene_plan.make("pixellab", self.path, palmod.load(palmod.ROOT / contracts.get("building").palette))
        self.assertTrue(p.ok, p.data["errors"])
        self.assertEqual([a["prompt_role"] for a in p.data["attachments"]], ["color_image"])
        self.assertEqual((p.data["request"]["width"], p.data["request"]["height"]), (64, 64))
        wide = fx.contract(extent_px=[1280, 256], openings=[], signal_regions={})
        big = scene_plan.make("pixellab", fx.write(self.dir, wide, "panorama.json"))
        self.assertFalse(big.ok)
        self.assertTrue(any("particao" in n for n in big.data["notes"]))

    def test_a_rejected_reference_does_not_enter(self):
        reg = refs.add(self.dir / "registo.json", self.dir / "ref.png", "rejected", "casa_v1", by="dono",
                       date="2026-10-28")
        p = scene_plan.make("openai", self.path, register=refs.load(reg["path"]))
        self.assertFalse(p.ok)
        self.assertNotIn("asset_concept", [a["prompt_role"] for a in p.data["attachments"]])


class OpaquePlaneTest(unittest.TestCase):
    def test_keep_leaves_an_opaque_plane_whole(self):
        img = Image.new("RGBA", (16, 8), (143, 160, 170, 255))
        img.paste((74, 59, 42, 255), (0, 5, 16, 8))
        out, info = matte.remove(img, "keep")
        self.assertEqual(out.tobytes(), img.tobytes())
        self.assertEqual(info["mode"], "none")
        flooded, _ = matte.remove(img)
        self.assertNotEqual(flooded.tobytes(), img.tobytes())


if __name__ == "__main__":
    unittest.main()
