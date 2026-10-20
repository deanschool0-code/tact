import json
import os
import sys
import uuid

import pytest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from tact import prompts  # noqa: E402
from tact.ai import AIError, MockProvider, Provider, normalise  # noqa: E402
from tact.app import create_app  # noqa: E402
from tact.config import Config  # noqa: E402
from tact.entitlements import EntitlementError  # noqa: E402

CHAT = [{"from": "them", "text": "just got back from a hike at el morado"},
        {"from": "me", "text": "no way, how was it"},
        {"from": "them", "text": "freezing but the glacier was unreal"}]


class FakeVerifier:
    def verify(self, jws):
        if jws == "a.b.bad":
            raise EntitlementError("could not verify")
        return {"original_transaction_id": "1000", "product_id": "tact.pro.monthly",
                "expires_at": "2999-01-01T00:00:00+00:00", "environment": "Xcode"}


class FlakyProvider(Provider):
    def __init__(self):
        self.calls = 0

    def complete(self, system, messages, max_tokens=900):
        self.calls += 1
        if self.calls == 1:
            return "sorry, here you go"  # no JSON -> retry
        return 'Sure! ```json\n{"read": "ok", "replies": [{"text": "hi {there}", "why": "x"}]}\n```'


class BrokenProvider(Provider):
    def complete(self, system, messages, max_tokens=900):
        raise AIError("down")


def make(tmp_path, provider=None, **cfg):
    opts = {"db_path": str(tmp_path / "t.db"), "provider": "mock", "free_daily": 3, "rate_per_minute": 100, "client_token": ""}
    c = Config(**{**opts, **cfg})
    return create_app(c, provider=provider or MockProvider(), verifier=FakeVerifier()).test_client()


def H(dev=None):
    return {"X-Device-ID": dev or str(uuid.uuid4())}


def test_health_needs_no_device(tmp_path):
    assert make(tmp_path).get("/health").json["ok"] is True


def test_device_header_required(tmp_path):
    r = make(tmp_path).post("/v1/generate", json={"kind": "reply", "transcript": CHAT})
    assert r.status_code == 400 and r.json["error"] == "bad_device"


def test_reply_happy_path(tmp_path):
    c, h = make(tmp_path), H()
    r = c.post("/v1/generate", json={"kind": "reply", "transcript": CHAT, "tone": "funny"}, headers=h)
    assert r.status_code == 200
    assert len(r.json["result"]["replies"]) == 4
    assert r.json["quota"]["remaining"] == 2


def test_free_limit_then_402_and_other_device_unaffected(tmp_path):
    c, h = make(tmp_path), H()
    for _ in range(3):
        assert c.post("/v1/generate", json={"kind": "lines", "text": "Sofi"}, headers=h).status_code == 200
    r = c.post("/v1/generate", json={"kind": "lines", "text": "Sofi"}, headers=h)
    assert r.status_code == 402 and r.json["error"] == "limit_reached"
    assert c.post("/v1/generate", json={"kind": "lines"}, headers=H()).status_code == 200


def test_ai_failure_refunds_quota(tmp_path):
    c, h = make(tmp_path, provider=BrokenProvider()), H()
    assert c.post("/v1/generate", json={"kind": "reply", "transcript": CHAT}, headers=h).status_code == 502
    assert c.get("/v1/quota", headers=h).json["used"] == 0


def test_retry_and_fenced_json(tmp_path):
    p = FlakyProvider()
    c = make(tmp_path, provider=p)
    r = c.post("/v1/generate", json={"kind": "reply", "transcript": CHAT}, headers=H())
    assert r.status_code == 200 and p.calls == 2
    assert r.json["result"]["replies"][0]["text"] == "hi {there}"


@pytest.mark.parametrize("body,code", [
    ({"kind": "nope"}, "bad_kind"),
    ({"kind": "reply"}, "empty"),
    ({"kind": "opener", "text": "   "}, "empty"),
    ({"kind": "tweak"}, "empty"),
    ({"kind": "reply", "transcript": "not a list"}, "bad_input"),
    ({"kind": "reply", "transcript": CHAT, "tone": 5}, "bad_input"),
])
def test_validation(tmp_path, body, code):
    r = make(tmp_path).post("/v1/generate", json=body, headers=H())
    assert r.status_code == 400 and r.json["error"] == code


def test_bad_json_body(tmp_path):
    r = make(tmp_path).post("/v1/generate", data="x", headers={**H(), "Content-Type": "application/json"})
    assert r.status_code == 400


def test_all_kinds_shape(tmp_path):
    c, h = make(tmp_path, free_daily=99), H()
    bodies = {
        "reply": {"transcript": CHAT}, "opener": {"text": "loves dogs and climbing"},
        "lines": {"text": "coffee"}, "vibe": {"transcript": CHAT},
        "bio": {"text": "gym, travel, tacos"}, "tweak": {"base": "hey", "tweak": "funnier"},
    }
    for kind, b in bodies.items():
        r = c.post("/v1/generate", json={"kind": kind, **b}, headers=h)
        assert r.status_code == 200, kind
    v = c.post("/v1/generate", json={"kind": "vibe", "transcript": CHAT}, headers=h).json["result"]
    assert 0 <= v["interest"] <= 100 and isinstance(v["green_flags"], list)


def test_coach(tmp_path):
    c, h = make(tmp_path), H()
    r = c.post("/v1/coach", json={"messages": [{"role": "user", "text": "how do i ask her out"}], "context": CHAT}, headers=h)
    assert r.status_code == 200 and r.json["reply"]
    assert c.post("/v1/coach", json={"messages": []}, headers=h).status_code == 400


def test_entitlement_makes_pro_unlimited(tmp_path):
    c, h = make(tmp_path, free_daily=1), H()
    assert c.post("/v1/entitlement", json={"jws": "a.b.bad"}, headers=h).status_code == 400
    r = c.post("/v1/entitlement", json={"jws": "a.b.c"}, headers=h)
    assert r.status_code == 200 and r.json["pro"] is True
    for _ in range(5):
        assert c.post("/v1/generate", json={"kind": "lines"}, headers=h).status_code == 200
    assert c.get("/v1/quota", headers=h).json["remaining"] is None


def test_delete_data(tmp_path):
    c, h = make(tmp_path), H()
    c.post("/v1/generate", json={"kind": "lines"}, headers=h)
    assert c.post("/v1/data/delete", headers=h).json["deleted"] >= 1
    assert c.get("/v1/quota", headers=h).json["used"] == 0


def test_rate_limit(tmp_path):
    c = make(tmp_path)
    c2 = create_app(Config(db_path=str(tmp_path / "r.db"), provider="mock", rate_per_minute=2, client_token=""),
                    provider=MockProvider(), verifier=FakeVerifier()).test_client()
    h = H()
    codes = [c2.get("/v1/quota", headers=h).status_code for _ in range(3)]
    assert codes == [200, 200, 429]


def test_client_token(tmp_path):
    c = create_app(Config(db_path=str(tmp_path / "c.db"), provider="mock", client_token="s3cret"),
                   provider=MockProvider(), verifier=FakeVerifier()).test_client()
    assert c.get("/v1/quota", headers=H()).status_code == 401
    assert c.get("/v1/quota", headers={**H(), "X-Client-Token": "s3cret"}).status_code == 200


# --- prompt + parsing unit tests ---

def test_prompt_contains_rules_and_voice():
    sys_p, user = prompts.build("reply", {"transcript": CHAT, "tone": "funny", "voice": ["lol ok", "nah ur wrong"]})
    assert "boundary" in sys_p and "under 18" in sys_p
    assert "THEM: freezing" in user and "lol ok" in user and "4 different" in user


def test_parse_json_variants():
    assert prompts.parse_json('{"a": 1}') == {"a": 1}
    assert prompts.parse_json('blah {"a": "}"} trailing') == {"a": "}"}
    with pytest.raises(ValueError):
        prompts.parse_json("no json")


def test_normalise_coerces_bad_shapes():
    out = normalise("vibe", {"interest": "130", "green_flags": "x"})
    assert out["interest"] == 100 and out["green_flags"] == []
    out = normalise("reply", {"replies": ["plain string", {"text": ""}, {"text": "ok", "why": "y"}]})
    assert [r["text"] for r in out["replies"]] == ["plain string", "ok"]


def test_coach_messages_alternate():
    msgs = prompts.coach_messages([{"role": "assistant", "text": "hi"}, {"role": "user", "text": "a"},
                                   {"role": "user", "text": "b"}], None)
    assert msgs == [{"role": "user", "content": "a\nb"}]
