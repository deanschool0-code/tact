"""End-to-end smoke test against a running Tact server, walking flows F01-F07 like the app does.
Usage: python3 e2e/smoke.py http://localhost:5580"""
import sys
import uuid

import requests

BASE = (sys.argv[1] if len(sys.argv) > 1 else "http://localhost:5580").rstrip("/")
H = {"X-Device-ID": str(uuid.uuid4())}
CHAT = [{"from": "them", "text": "just got back from a hike at el morado"},
        {"from": "me", "text": "no way, how was it"},
        {"from": "them", "text": "freezing but the glacier was unreal 🥶"}]
ok = fail = 0


def check(case, cond, detail=""):
    global ok, fail
    print(("PASS " if cond else "FAIL ") + case + (f"  ({detail})" if detail and not cond else ""))
    ok, fail = ok + cond, fail + (not cond)


r = requests.get(f"{BASE}/health", timeout=10)
check("health", r.ok and r.json()["ok"])
q = requests.get(f"{BASE}/v1/quota", headers=H).json()
check("quota fresh device", q["used"] == 0 and q["remaining"] == q["limit"], q)

r = requests.post(f"{BASE}/v1/generate", headers=H, json={"kind": "reply", "transcript": CHAT, "tone": "funny",
                                                          "goal": "ask_out", "voice": ["lol ok", "nah fr"]}, timeout=90)
res = r.json().get("result", {})
check("F01-H1 reply from chat", r.ok and 1 <= len(res.get("replies", [])) <= 4, r.text[:200])
check("F01-H1 reply has read line", isinstance(res.get("read"), str))

base = res["replies"][0]["text"] if res.get("replies") else "hey"
r = requests.post(f"{BASE}/v1/generate", headers=H, json={"kind": "tweak", "tweak": "shorter", "base": base, "transcript": CHAT}, timeout=90)
check("F01-H2 tweak shorter", r.ok and len(r.json()["result"]["replies"]) >= 1, r.text[:200])

r = requests.post(f"{BASE}/v1/generate", headers=H, json={"kind": "opener", "text": "Sunday: climbing then empanadas. Looking for a concert buddy."}, timeout=90)
if r.status_code == 402:
    check("F07-N1 free limit reached returns 402", r.json()["error"] == "limit_reached")
else:
    check("F02-H1 opener", r.ok, r.text[:200])

H2 = {"X-Device-ID": str(uuid.uuid4())}
r = requests.post(f"{BASE}/v1/generate", headers=H2, json={"kind": "vibe", "transcript": CHAT}, timeout=90)
v = r.json().get("result", {})
check("F04-H1 vibe check", r.ok and 0 <= v.get("interest", -1) <= 100, r.text[:200])
r = requests.post(f"{BASE}/v1/generate", headers=H2, json={"kind": "lines", "text": "Sofía"}, timeout=90)
check("F03-H1 pickup lines", r.ok and len(r.json()["result"]["replies"]) >= 1, r.text[:200])
r = requests.post(f"{BASE}/v1/coach", headers=H2, json={"messages": [{"role": "user", "text": "how do i ask her out?"}]}, timeout=90)
check("F06-H1 coach", r.ok and len(r.json()["reply"]) > 0, r.text[:200])
r = requests.post(f"{BASE}/v1/generate", headers=H2, json={"kind": "bio", "text": "gym, travel, tacos"}, timeout=90)
check("F05 bio when out of free uses -> 402", r.status_code == 402, r.text[:200])

H3 = {"X-Device-ID": str(uuid.uuid4())}
r = requests.post(f"{BASE}/v1/generate", headers=H3, json={"kind": "reply", "transcript": [{"from": "them", "text": "x" * 800}] * 60}, timeout=30)
check("F01-E very long chat rejected cleanly", r.status_code == 413, r.status_code)
r = requests.post(f"{BASE}/v1/generate", headers=H3, json={"kind": "reply", "transcript": []})
check("F01-E empty chat -> 400", r.status_code == 400)
r = requests.post(f"{BASE}/v1/generate", headers={"X-Device-ID": "bad"}, json={"kind": "lines"})
check("bad device id -> 400", r.status_code == 400)
r = requests.post(f"{BASE}/v1/data/delete", headers=H)
check("delete my data", r.ok)
print(f"\n{ok} passed, {fail} failed")
sys.exit(1 if fail else 0)
