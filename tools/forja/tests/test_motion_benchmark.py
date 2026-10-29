"""Comparacao so de observacoes presas a arquivos, sem custo ou aceitacao inventados."""
import json
import tempfile
import unittest
from pathlib import Path

from tools.forja import clip_export, motion_benchmark
from tools.forja.backends import sha
from tools.forja.tests.choreography_fixtures import clip


class BenchmarkTests(unittest.TestCase):
    def record(self, root: Path, cost: float | None) -> dict:
        data = clip(root)
        raw = (root / 'identity.png').read_bytes()
        clip_export.package(data, [raw] * 5, root, root / 'export',
                            {'method': 'skeleton-v3', 'cost': {'usd': cost}})
        path = root / 'export/review.json'
        return {'package': str(path), 'sha256': sha(path.read_bytes()), 'task': 'king-attack',
                'decision': 'accepted', 'reviewer': 'test reviewer', 'correction_minutes': 3,
                'extra_cost_usd': 0}

    def test_unknown_cost_does_not_become_zero(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            entry = self.record(root, None)
            report = motion_benchmark.summarize({'schema': 'forja.benchmark/1', 'runs': [entry]}, root)
            row = report['groups'][0]
            self.assertEqual(row['accepted'], 1)
            self.assertIsNone(row['usd_per_accepted'])
            self.assertEqual(row['unknown_cost_runs'], 1)
            self.assertEqual(report['approval'], 'pending')

    def test_cost_includes_rejected_attempts(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            good = self.record(root, 2)
            other = root / 'other'
            other.mkdir()
            bad = self.record(other, 3)
            bad['decision'] = 'rejected'
            report = motion_benchmark.summarize({'schema': 'forja.benchmark/1', 'runs': [good, bad]}, root)
            self.assertEqual(report['groups'][0]['usd_per_accepted'], 5)

    def test_changed_package_and_duplicate_attempt_refused(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            entry = self.record(root, 1)
            with self.assertRaisesRegex(ValueError, 'repetido'):
                motion_benchmark.summarize({'schema': 'forja.benchmark/1', 'runs': [entry, entry]}, root)
            Path(entry['package']).write_text('{}')
            with self.assertRaisesRegex(ValueError, 'hash'):
                motion_benchmark.summarize({'schema': 'forja.benchmark/1', 'runs': [entry]}, root)
