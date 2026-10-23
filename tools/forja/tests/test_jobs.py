"""F01 e F09: pedidos pagos persistidos, sem POST repetido, com prazo, cancelamento e retomada."""
import json
import os
import unittest
from unittest import mock

from tools.forja import jobs
from tools.forja.backends import pixellab_api
from tools.forja.tests.helpers import tempdir
from tools.forja.tests.test_backends import B64, ENV, Fake, png


class Clock:
    """Relogio falso: `sleep` avanca o tempo, nada espera de verdade."""

    def __init__(self):
        self.t = 0.0
        self.slept = []

    def __call__(self):
        return self.t

    def sleep(self, s):
        self.slept.append(s)
        self.t += s


def call():
    return pixellab_api.call("comic knight", 64, 64, no_background=True)


def run(job, fake, clock, **kw):
    return jobs.execute(job, call(), fake, poll=pixellab_api.poll_call, sleep=clock.sleep, clock=clock,
                        rand=lambda: 0.5, **kw)


DONE = (200, {"status": "completed", "last_response": {"image": {"type": "base64", "base64": B64}}})
WORKING = (200, {"status": "processing", "last_response": {"queue_position": 2, "estimated_wait_seconds": 6}})


@mock.patch.dict(os.environ, ENV)
class SubmissionTest(unittest.TestCase):
    def test_lost_response_is_not_resubmitted(self):
        d, clock = tempdir(), Clock()
        job = jobs.create(call(), d)
        fake = Fake(TimeoutError("accepted, answer lost"))
        with self.assertRaises(jobs.Ambiguous):
            run(job, fake, clock)
        self.assertEqual(job.state, "submission_unknown")
        again = jobs.load(job.path)
        second = Fake((200, {"image": {"type": "base64", "base64": B64}}))
        with self.assertRaises(jobs.Ambiguous):
            run(again, second, clock)
        self.assertEqual((len(fake.requests), len(second.requests)), (1, 0))
        images = run(again, second, clock, force_resubmit=True)
        self.assertEqual(images, [png()])
        self.assertEqual(len(again.data["attempts"]), 2)

    def test_written_before_post_and_without_secrets(self):
        d, clock = tempdir(), Clock()
        job = jobs.create(call(), d)
        seen = {}

        def transport(req):
            seen["state"] = json.loads(job.path.read_text())["state"]
            return Fake((200, {"image": {"type": "base64", "base64": B64}}))(req)

        run(job, transport, clock)
        self.assertEqual(seen["state"], "submitting")
        text = job.path.read_text()
        self.assertNotIn("p-test", text)
        self.assertNotIn(B64[:40], text)
        record = json.loads(text)
        self.assertEqual(record["outputs"][0]["size"], [4, 4])
        self.assertEqual(record["attempts"][0]["exchanges"][0]["method"], "POST")

    def test_rejected_post_can_be_sent_again(self):
        d, clock = tempdir(), Clock()
        job = jobs.create(call(), d)
        with self.assertRaisesRegex(jobs.JobError, "30s"):
            run(job, Fake((429, {"detail": "slow"}, {"Retry-After": "30"})), clock)
        self.assertEqual(job.state, "rejected")
        self.assertEqual(run(job, Fake((200, {"image": {"type": "base64", "base64": B64}})), clock), [png()])

    def test_budget_stops_before_the_post(self):
        d, clock = tempdir(), Clock()
        budget = jobs.Budget.open(d, max_calls=1, max_usd=1.0)
        run(jobs.create(call(), d), Fake((200, {"image": {"type": "base64", "base64": B64},
                                               "usage": {"type": "usd", "usd": 0.01}})), clock, budget=budget)
        fake = Fake()
        with self.assertRaises(jobs.BudgetExceeded):
            run(jobs.create(call(), d), fake, clock, budget=jobs.Budget.open(d, 1, 1.0))
        self.assertEqual(fake.requests, [])
        saved = json.loads((d / "budget.json").read_text())
        self.assertEqual((saved["calls"], saved["usd"]), (1, 0.01))

    def test_unknown_cost_is_said(self):
        d, clock = tempdir(), Clock()
        budget = jobs.Budget.open(d, 3)
        run(jobs.create(call(), d), Fake((200, {"image": {"type": "base64", "base64": B64}})), clock, budget=budget)
        self.assertEqual(budget.unknown_cost_calls, 1)
        self.assertIn("note", budget.as_dict())


@mock.patch.dict(os.environ, ENV)
class PollingTest(unittest.TestCase):
    def submitted(self):
        return (200, {"background_job_id": "remote-1"})

    def test_stuck_job_stops_at_deadline(self):
        d, clock = tempdir(), Clock()
        job = jobs.create(call(), d)
        fake = Fake(self.submitted(), *[WORKING] * 500)
        with self.assertRaises(jobs.Timeout):
            run(job, fake, clock, deadline=60, every=5, max_every=30)
        self.assertEqual(job.state, "timed_out")
        self.assertEqual(job.data["remote_id"], "remote-1")
        self.assertLessEqual(clock.t, 60)
        self.assertLess(len(fake.requests), 20)
        self.assertEqual(job.data["progress"]["queue_position"], 2)

    def test_poll_limit(self):
        clock = Clock()
        job = jobs.create(call())
        fake = Fake(self.submitted(), *[WORKING] * 50)
        with self.assertRaises(jobs.Timeout):
            run(job, fake, clock, deadline=10_000, max_polls=3)
        self.assertEqual([r.method for r in fake.requests], ["POST", "GET", "GET", "GET"])

    def test_remote_failure(self):
        job = jobs.create(call())
        with self.assertRaisesRegex(jobs.JobError, "falhou"):
            run(job, Fake(self.submitted(), (200, {"status": "failed", "last_response": {"error": "gpu"}})), Clock())
        self.assertEqual(job.state, "failed")

    def test_completed_without_images_is_an_error(self):
        job = jobs.create(call())
        with self.assertRaisesRegex(jobs.JobError, "nao trouxe imagens"):
            run(job, Fake(self.submitted(), (200, {"status": "completed", "last_response": {}})), Clock())
        self.assertEqual((job.state, job.data["error"][:12]), ("failed", "empty_result"))

    def test_unknown_remote_state_keeps_the_job_resumable(self):
        job = jobs.create(call())
        with self.assertRaisesRegex(jobs.JobError, "desconhecido"):
            run(job, Fake(self.submitted(), (200, {"status": "paused_by_provider"})), Clock())
        self.assertEqual((job.state, job.data["remote_id"]), ("submitted", "remote-1"))

    def test_resume_after_restart_only_polls(self):
        d, clock = tempdir(), Clock()
        job = jobs.create(call(), d)
        with self.assertRaises(jobs.Timeout):
            run(job, Fake(self.submitted(), *[WORKING] * 100), clock, deadline=20)
        restarted = jobs.load(job.path)
        fake = Fake(WORKING, DONE)
        images = jobs.execute(restarted, None, fake, poll=pixellab_api.poll_call, sleep=clock.sleep, clock=clock)
        self.assertEqual(images, [png()])
        self.assertEqual([r.method for r in fake.requests], ["GET", "GET"])
        self.assertEqual(jobs.execute(jobs.load(job.path), None, Fake()), [png()])

    def test_cancel(self):
        d, clock = tempdir(), Clock()
        job = jobs.create(call(), d)
        with self.assertRaises(jobs.Timeout):
            run(job, Fake(self.submitted(), WORKING), clock, max_polls=1)
        fake = Fake((200, {"cancelled": True}))
        res = jobs.cancel(job, pixellab_api.cancel_call, fake)
        self.assertTrue(res["cancelled"])
        self.assertEqual(fake.requests[0].method, "DELETE")
        self.assertEqual(job.state, "cancelled")
        self.assertIn("pode ser cobrado", job.data["history"][-1]["note"])

    def test_cancel_after_completion_reconciles(self):
        clock = Clock()
        job = jobs.create(call())
        with self.assertRaises(jobs.Timeout):
            run(job, Fake(self.submitted(), WORKING), clock, max_polls=1)
        res = jobs.cancel(job, pixellab_api.cancel_call, Fake((400, {"detail": "already completed"})))
        self.assertFalse(res["cancelled"])
        self.assertEqual(job.state, "submitted")

    def test_cancel_without_remote_job(self):
        job = jobs.create(call())
        self.assertTrue(jobs.cancel(job, None)["cancelled"])
        self.assertEqual(job.state, "cancelled")
