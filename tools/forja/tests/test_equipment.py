"""FORJA-03: o contrato raster nao ve a arma; a geometria do equipamento ve, quando ha observacao."""
import unittest
from pathlib import Path

from tools.forja import cli, contracts, equipment, geometry, lint, palette as palmod, verdicts
from tools.forja.tests import equip_fixtures as F
from tools.forja.tests.helpers import tempdir

ROYAL = contracts.get("royal_80")
PALETTE = palmod.load(palmod.ROOT / ROYAL.palette)


def judge(kind: str, case: str) -> dict:
    img = F.sword(case) if kind == "sword" else F.bow(case)
    obs = (F.sword_observation if kind == "sword" else F.bow_observation)(img)
    manifest = F.sword_manifest() if kind == "sword" else F.bow_manifest()
    return geometry.review(manifest, equipment.observe(img, obs), lint.check(img, ROYAL, PALETTE)["ok"])


def failed(result: dict) -> set[tuple[str, str | None]]:
    return {(c["check"], c["part"]) for c in result["checks"] if c["status"] == "fail"}


class RasterIsBlindTest(unittest.TestCase):
    def test_the_report_fixtures_all_pass_the_raster_lint(self):
        for case in ("reference", "forked", "two_guards", "none"):
            report = lint.check(F.sword(case), ROYAL, PALETTE)
            self.assertEqual(report["errors"], 0, case)


class SwordTest(unittest.TestCase):
    def test_reference_and_hidden_grip_pass(self):
        for case in ("reference", "grip_hidden"):
            r = judge("sword", case)
            self.assertEqual(r["summary"]["equipment_geometry"], "pass", case)
            self.assertEqual(r["summary"]["functional_pose"], "pass", case)
            self.assertEqual(r["summary"]["raster_contract"], "pass", case)

    def test_forked_blade_is_caught(self):
        r = judge("sword", "forked")
        self.assertIn(("blade_axis", "blade"), failed(r))
        self.assertEqual(r["blocking"], ["equipment_geometry"])

    def test_two_guards_are_caught_and_guard_plus_pommel_is_not_duplication(self):
        self.assertIn(("part_count", "guard"), failed(judge("sword", "two_guards")))
        self.assertIn(("guard_seat", "guard"), failed(judge("sword", "two_guards")))
        self.assertNotIn(("part_count", "pommel"), failed(judge("sword", "reference")))

    def test_missing_weapon_fails_and_the_hidden_grip_stays_inconclusive(self):
        r = judge("sword", "none")
        self.assertIn(("item_present", None), failed(r))
        grip = next(c for c in r["checks"] if c["check"] == "part_count" and c["part"] == "grip")
        self.assertEqual(grip["status"], "inconclusive")
        self.assertEqual(r["summary"]["equipment_geometry"], "fail")

    def test_a_raster_diagonal_staircase_is_not_a_bent_blade(self):
        steep = {(10 + i // 3, 40 - i) for i in range(24)}
        steep |= {(x + 1, y) for x, y in steep}
        diagonal = {(10 + i, 40 - i) for i in range(16)} | {(11 + i, 40 - i) for i in range(16)}
        for region, tip in ((steep, (17, 17)), (diagonal, (25, 25))):
            lines = geometry.scan(region, (10, 40), tip)
            self.assertTrue(all(len(runs) == 1 for _, _, runs in lines))
        forked = diagonal | {(20 - i, 30 - i) for i in range(1, 5)}
        self.assertTrue(any(len(runs) > 1 for _, _, runs in geometry.scan(forked, (10, 40), (25, 25))))


class BowTest(unittest.TestCase):
    def test_curved_bow_with_the_string_behind_the_arm_passes(self):
        r = judge("bow", "valid")
        self.assertEqual(r["summary"]["equipment_geometry"], "pass")
        self.assertEqual(r["summary"]["functional_pose"], "pass")

    def test_wide_double_short_and_wavy_strings_fail(self):
        for case in ("wide", "double", "short", "wavy"):
            self.assertIn(("string_line", "string"), failed(judge("bow", case)), case)

    def test_a_drawn_string_is_not_judged_as_straight(self):
        img = F.bow("valid")
        manifest = F.bow_manifest()
        manifest["items"][0]["state"] = "draw"
        r = geometry.review(manifest, equipment.observe(img, F.bow_observation(img)))
        line = next(c for c in r["checks"] if c["check"] == "string_line")
        self.assertEqual(line["status"], "not_evaluated")
        self.assertNotEqual(r["summary"]["equipment_geometry"], "pass")


class ObservationTest(unittest.TestCase):
    def test_observation_is_bound_to_its_image(self):
        obs = F.sword_observation(F.sword("reference"))
        with self.assertRaisesRegex(ValueError, "outra imagem"):
            equipment.observe(F.sword("forked"), obs)

    def test_missing_regions_are_not_evaluated_never_pass(self):
        img = F.sword("reference")
        obs = F.sword_observation(img)
        obs["regions"] = {}
        r = geometry.review(F.sword_manifest(), equipment.observe(img, obs))
        self.assertEqual(r["summary"]["equipment_geometry"], "not_evaluated")
        self.assertEqual(r["summary"]["functional_pose"], "not_evaluated")

    def test_uncertain_region_cannot_pass(self):
        img = F.sword("reference")
        obs = F.sword_observation(img)
        obs["regions"]["sword.blade"]["uncertainty"] = "alta"
        r = geometry.review(F.sword_manifest(), equipment.observe(img, obs))
        self.assertEqual(r["summary"]["equipment_geometry"], "inconclusive")

    def test_manifest_rejects_gameplay_data_and_unknown_parts(self):
        m = F.bow_manifest()
        m["items"][0]["parts"]["arrow"] = {}
        m["items"][0]["ammo"] = 12
        m["items"].append(dict(m["items"][0]))
        errors = " ".join(equipment.validate(m))
        for needle in ("ammo", "arrow", "id repetido"):
            self.assertIn(needle, errors)


class ArcherProofTest(unittest.TestCase):
    """A prova do FORJA-03 (docs/art/research/2026-10-24-forja-armas): os numeros que o README cita."""

    def test_the_delivered_string_fails_and_the_redrawn_one_passes(self):
        base = Path(__file__).resolve().parents[3] / "docs/art/research/2026-10-24-forja-armas/arqueiro"
        args = [str(base / "arqueiro-recuperado.png"), "--manifest", str(base / "manifesto.json"),
                "--observation", str(base / "observacao.json"), "--kind", "royal_80", "-o", str(tempdir())]
        before = cli.run(["equip", *args])
        self.assertEqual(before["problems"], ["bow_main: largura 2 px em 22 linhas (maximo 1; ex.: [18, 19, 20]); "
                                              "afasta-se 1.55 px da reta entre as pontas"])
        fixed = cli.run(["line", *args, "--item", "bow_main"])
        r = fixed["repair"]
        self.assertEqual((r["line_pixels"], r["kept"], r["drawn"], r["cleared"], r["inferred"]),
                         (56, 51, 5, 26, [[60, 43]]))
        self.assertEqual(fixed["compose"], {"ok": True, "outside_identical": True, "protected_identical": True,
                                            "changed_pixels": 32})
        self.assertEqual(fixed["after"]["equipment_geometry"], "pass")
        self.assertEqual(fixed["after"]["artistic_approval"], "pending")


class VerdictsTest(unittest.TestCase):
    def test_not_evaluated_never_becomes_pass_and_nothing_is_averaged(self):
        self.assertEqual(verdicts.combine(["pass", "not_evaluated"]), "inconclusive")
        self.assertEqual(verdicts.combine(["pass"] * 9 + ["fail"]), "fail")
        self.assertEqual(verdicts.combine([]), "not_evaluated")
        self.assertEqual(verdicts.combine(["not_applicable"]), "not_applicable")

    def test_the_tool_cannot_approve_art_or_integration(self):
        v = verdicts.initial()
        with self.assertRaises(ValueError):
            verdicts.put(v, "artistic_approval", "pass")
        with self.assertRaises(ValueError):
            verdicts.put(v, "runtime_integration", "pass")
        self.assertEqual(verdicts.summary(v)["identity_consistency"], "not_evaluated")
        self.assertEqual(verdicts.summary(verdicts.initial(6))["temporal_consistency"], "not_evaluated")


if __name__ == "__main__":
    unittest.main()
