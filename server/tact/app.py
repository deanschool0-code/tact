"""Tact API. Holds the AI key so it never ships inside the iPhone app."""
import hmac
import logging
import re
import time
from collections import defaultdict, deque

from flask import Flask, g, jsonify, request

from .ai import AIError, make_provider
from .config import Config
from .db import DB
from .entitlements import EntitlementError, Verifier

KINDS = {"reply", "opener", "lines", "vibe", "bio", "tweak"}
DEVICE_RE = re.compile(r"^[A-Za-z0-9-]{16,64}$")
MAX_MESSAGES, MAX_CHARS = 60, 6000

log = logging.getLogger("tact")


class RateLimiter:
    def __init__(self, per_minute: int):
        self.per_minute, self.hits = per_minute, defaultdict(deque)

    def allow(self, key: str) -> bool:
        now, q = time.monotonic(), self.hits[key]
        while q and now - q[0] > 60:
            q.popleft()
        if len(q) >= self.per_minute:
            return False
        q.append(now)
        return True


def _err(status, code, message):
    return jsonify({"error": code, "message": message}), status


def _clean_transcript(raw):
    if raw is None:
        return []
    if not isinstance(raw, list):
        raise ValueError("transcript must be a list")
    out = []
    for m in raw[-MAX_MESSAGES:]:
        if not isinstance(m, dict):
            raise ValueError("transcript items must be objects")
        who = "me" if m.get("from") == "me" else "them"
        text = str(m.get("text", ""))[:800]
        if text.strip():
            out.append({"from": who, "text": text})
    return out


def _str(body, key, n):
    v = body.get(key)
    if v is None:
        return ""
    if not isinstance(v, str):
        raise ValueError(f"{key} must be a string")
    return v[:n]


def create_app(cfg: Config | None = None, provider=None, verifier=None) -> Flask:
    cfg = cfg or Config()
    app = Flask(__name__)
    db = DB(cfg.db_path)
    ai = provider or make_provider(cfg)
    ver = verifier or Verifier(cfg)
    device_limiter, ip_limiter = RateLimiter(cfg.rate_per_minute), RateLimiter(cfg.rate_per_minute * 3)

    @app.before_request
    def gate():
        if request.path == "/health":
            return None
        if cfg.client_token:
            sent = request.headers.get("X-Client-Token", "")
            if not hmac.compare_digest(sent, cfg.client_token):
                return _err(401, "unauthorized", "Bad client token.")
        device = request.headers.get("X-Device-ID", "")
        if not DEVICE_RE.match(device):
            return _err(400, "bad_device", "Missing or invalid X-Device-ID header.")
        ip = request.headers.get("X-Forwarded-For", request.remote_addr or "?").split(",")[0].strip()
        if not device_limiter.allow(device) or not ip_limiter.allow(ip):
            return _err(429, "rate_limited", "Slow down a little and try again in a minute.")
        g.device = device
        return None

    def quota():
        pro = db.is_pro(g.device)
        used = db.used_today(g.device)
        return {"pro": pro, "used": used, "limit": cfg.free_daily,
                "remaining": None if pro else max(cfg.free_daily - used, 0)}

    def charge():
        """Use one free generation unless Pro. Returns (ok, refund_fn)."""
        if db.is_pro(g.device):
            return True, lambda: None
        if db.try_consume(g.device, cfg.free_daily):
            return True, lambda: db.refund(g.device)
        return False, None

    @app.get("/health")
    def health():
        return {"ok": True, "provider": cfg.provider}

    @app.get("/v1/quota")
    def get_quota():
        return quota()

    @app.post("/v1/generate")
    def generate():
        body = request.get_json(silent=True)
        if not isinstance(body, dict):
            return _err(400, "bad_json", "Body must be a JSON object.")
        kind = body.get("kind")
        if kind not in KINDS:
            return _err(400, "bad_kind", f"kind must be one of {sorted(KINDS)}")
        try:
            payload = {
                "transcript": _clean_transcript(body.get("transcript")),
                "text": _str(body, "text", MAX_CHARS),
                "tone": _str(body, "tone", 20), "goal": _str(body, "goal", 20),
                "style": _str(body, "style", 20), "extra": _str(body, "extra", 300),
                "tweak": _str(body, "tweak", 20), "base": _str(body, "base", 600),
                "voice": [str(v)[:200] for v in (body.get("voice") or [])[:8] if isinstance(v, str)],
            }
        except ValueError as e:
            return _err(400, "bad_input", str(e))
        needs_chat = kind in ("reply", "vibe")
        if needs_chat and not payload["transcript"] and not payload["text"].strip():
            return _err(400, "empty", "Add the conversation first.")
        if kind in ("opener", "bio") and not payload["text"].strip():
            return _err(400, "empty", "Add some text first.")
        if kind == "tweak" and not payload["base"].strip():
            return _err(400, "empty", "Nothing to tweak.")
        if sum(len(m["text"]) for m in payload["transcript"]) > MAX_CHARS * 2:
            return _err(413, "too_long", "That chat is very long. Crop to the last part.")

        ok, refund = charge()
        if not ok:
            return _err(402, "limit_reached", "That's your free replies for today.")
        try:
            result = ai.generate(kind, payload)
        except AIError as e:
            refund()
            log.warning("generate failed: %s", e)  # never log the payload
            return _err(502, "ai_failed", "That didn't land. Try again?")
        return {"kind": kind, "result": result, "quota": quota()}

    @app.post("/v1/coach")
    def coach():
        body = request.get_json(silent=True)
        if not isinstance(body, dict) or not isinstance(body.get("messages"), list):
            return _err(400, "bad_json", "messages must be a list.")
        try:
            context = _clean_transcript(body.get("context"))
        except ValueError as e:
            return _err(400, "bad_input", str(e))
        msgs = [m for m in body["messages"] if isinstance(m, dict)][-20:]
        if not msgs:
            return _err(400, "empty", "Ask something first.")
        ok, refund = charge()
        if not ok:
            return _err(402, "limit_reached", "That's your free questions for today.")
        try:
            reply = ai.coach(msgs, context or None)
        except AIError as e:
            refund()
            log.warning("coach failed: %s", e)
            return _err(502, "ai_failed", "Coach is stuck. Try again?")
        return {"reply": reply, "quota": quota()}

    @app.post("/v1/entitlement")
    def entitlement():
        body = request.get_json(silent=True) or {}
        jws = body.get("jws")
        if not isinstance(jws, str) or len(jws) > 20000 or jws.count(".") != 2:
            return _err(400, "bad_jws", "jws must be a signed transaction.")
        try:
            t = ver.verify(jws)
        except EntitlementError as e:
            return _err(400, "unverified", str(e))
        db.save_entitlement(t["original_transaction_id"], g.device, t["product_id"], t["expires_at"], t["environment"])
        return {"pro": db.is_pro(g.device), "expires_at": t["expires_at"], "quota": quota()}

    @app.post("/v1/data/delete")
    def delete_data():
        return {"deleted": db.delete_device(g.device)}

    return app
