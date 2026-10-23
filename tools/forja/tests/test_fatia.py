"""Fatia vertical com arte real do projeto (V15, so leitura): revisao, exportacao e ida e volta exatas."""
import hashlib
import json
import os
import re
import shutil
import subprocess
import unittest
from pathlib import Path

from PIL import Image

from tools.forja import anim, aseprite, contracts, godot, review, royals
from tools.forja.tests.helpers import tempdir

WHO = (("dancarina", "royal_64"), ("sombra", "royal_80"))


class V15RoundTripTest(unittest.TestCase):
    def test_package_matches_the_royal_contracts(self):
        for who, kind in WHO:
            pkg = royals.load(who)
            c = contracts.get(kind)
            self.assertEqual((pkg["kind"], tuple(pkg["size"]), tuple(pkg["pivot"])), (kind, c.canvas, c.pivot), who)
            self.assertEqual([hashlib.sha256(f.tobytes()).hexdigest() for f in pkg["frames"]], pkg["rgba_sha256"])

    def test_forja_export_reconstructs_every_frame(self):
        for who, _ in WHO:
            pkg = royals.load(who)
            d = tempdir()
            files = anim.export(pkg["frames"], d, who, pkg["durations"], pkg["tags"], tuple(pkg["pivot"]),
                                previews=False)
            data = json.loads(Path(files["json"]).read_text(encoding="utf-8"))
            with Image.open(files["sheet"]) as im:
                strip = im.convert("RGBA")
            for frame, entry, ms in zip(pkg["frames"], data["frames"], pkg["durations"]):
                r = entry["frame"]
                self.assertEqual(strip.crop((r["x"], r["y"], r["x"] + r["w"], r["y"] + r["h"])).tobytes(),
                                 frame.tobytes())
                self.assertEqual(entry["duration"], ms)
            self.assertEqual([(t["name"], t["from"], t["to"]) for t in data["meta"]["frameTags"]],
                             [t[:3] for t in pkg["tags"]])
            path = aseprite.from_frames(d / f"{who}.aseprite", pkg["frames"], durations=pkg["durations"],
                                        tags=pkg["tags"], pivot=tuple(pkg["pivot"]))
            check = aseprite.verify(path, pkg["frames"])
            self.assertTrue(check["pixel_equal"], who)
            self.assertEqual(check["durations"], pkg["durations"])

    def test_review_reads_declared_repeats_as_declared(self):
        for who, _ in WHO:
            pkg = royals.load(who)
            res = review.motion(pkg["frames"], pkg["tags"], pkg["holds"], "preserve")
            checks = res["motion_checks"]
            self.assertEqual([c for c in checks if c["check"] == "hidden_duplicate"], [], who)
            self.assertTrue(all(c["status"] == "ok" for c in checks if c["check"] == "hold"), who)
            self.assertEqual(res["blocking"], [], who)
            unique = len({f.tobytes() for f in pkg["frames"]})
            self.assertEqual(len(pkg["frames"]) - len(pkg["holds"]), unique, who)

    @unittest.skipUnless(os.environ.get("GODOT") or shutil.which("godot"), "sem o motor: GODOT ou godot no PATH")
    def test_spriteframes_keep_order_and_timing_in_godot(self):
        engine = os.environ.get("GODOT") or shutil.which("godot")
        pkg = royals.load("dancarina")
        d = tempdir()
        strip, rects = anim.strip(pkg["frames"])
        strip.save(d / "d.png")
        base = 1000 / 10
        godot.write(d / "d.tres", godot.sprite_frames("res://d.png", rects, pkg["durations"], pkg["tags"], 10,
                                                      {t: pkg["loops"].get(t, True) for t, *_ in pkg["tags"]}))
        (d / "check.gd").write_text(godot.CHECK_SCRIPT)
        (d / "project.godot").write_text('config_version=5\n\n[application]\nconfig/name="forja"\n')
        subprocess.run([engine, "--headless", "--path", str(d), "--import"], capture_output=True, timeout=180)
        out = subprocess.run([engine, "--headless", "--path", str(d), "-s", "check.gd", "--", "res://d.tres"],
                             capture_output=True, text=True, timeout=120)
        line = next(x for x in out.stdout.splitlines() if x.startswith("FORJA_OK"))
        anims = {a[0]: a for a in json.loads(line.split("spriteframes", 1)[1])}
        for name, first, last, _ in pkg["tags"]:
            seq = anims[name][4]
            self.assertEqual([round(x) for x, _ in seq], [rects[i][0] for i in range(first, last + 1)], name)
            self.assertEqual([round(ms * base) for _, ms in seq], pkg["durations"][first:last + 1], name)
            self.assertEqual(anims[name][3], pkg["loops"][name], name)
        self.assertTrue(re.search(r"FORJA_OK", out.stdout))
