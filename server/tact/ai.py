"""Model providers. Official APIs only, with Dean's own keys."""
import hashlib

import requests

from . import prompts


class AIError(Exception):
    pass


def _clip(s, n):
    return str(s or "").strip()[:n]


def _items(raw, n):
    out = []
    if not isinstance(raw, list):
        return out
    for r in raw:
        if isinstance(r, str):
            r = {"text": r, "why": ""}
        if isinstance(r, dict) and _clip(r.get("text"), 600):
            out.append({"text": _clip(r.get("text"), 600), "why": _clip(r.get("why"), 120)})
    return out[:n]


def _strs(raw, n=6):
    if not isinstance(raw, list):
        return []
    return [_clip(x, 140) for x in (raw or []) if isinstance(x, str) and x.strip()][:n]


def _score(v):
    try:
        return max(0, min(100, int(round(float(v)))))
    except (TypeError, ValueError):
        return 50


def normalise(kind: str, data: dict) -> dict:
    """Coerce model output into the exact shape the app expects."""
    if kind in ("reply", "opener"):
        return {"read": _clip(data.get("read"), 240), "boundary": bool(data.get("boundary")),
                "replies": _items(data.get("replies"), 4)}
    if kind == "lines":
        return {"replies": _items(data.get("replies"), 6)}
    if kind == "tweak":
        return {"replies": _items(data.get("replies"), 2)}
    if kind == "vibe":
        return {"interest": _score(data.get("interest")), "summary": _clip(data.get("summary"), 400),
                "green_flags": _strs(data.get("green_flags")), "red_flags": _strs(data.get("red_flags")),
                "next_move": _clip(data.get("next_move"), 240), "boundary": bool(data.get("boundary"))}
    if kind == "bio":
        return {"score": _score(data.get("score")), "summary": _clip(data.get("summary"), 300),
                "strengths": _strs(data.get("strengths")), "fixes": _strs(data.get("fixes")),
                "rewrites": _items(data.get("rewrites"), 3)}
    raise AIError(f"unknown kind {kind}")


class Provider:
    def complete(self, system: str, messages: list, max_tokens: int = 900) -> str:
        raise NotImplementedError

    def generate(self, kind: str, payload: dict) -> dict:
        system, user = prompts.build(kind, payload)
        last_err = None
        for _ in range(2):  # one retry on malformed JSON
            raw = self.complete(system, [{"role": "user", "content": user}])
            try:
                result = normalise(kind, prompts.parse_json(raw))
            except (ValueError, TypeError) as e:
                last_err = e
                continue
            key = "rewrites" if kind == "bio" else "replies"
            if kind == "vibe" or result.get(key) or result.get("boundary"):
                return result
            last_err = AIError("empty result")
        raise AIError(f"model returned unusable output: {last_err}")

    def coach(self, messages: list, context) -> str:
        msgs = prompts.coach_messages(messages, context)
        if not msgs:
            raise AIError("empty conversation")
        return self.complete(prompts.COACH_SYSTEM, msgs, max_tokens=500).strip()


class AnthropicProvider(Provider):
    def __init__(self, api_key: str, model: str):
        if not api_key:
            raise AIError("ANTHROPIC_API_KEY is not set")
        import anthropic
        self.client = anthropic.Anthropic(api_key=api_key, timeout=40, max_retries=2)
        self.model = model

    def complete(self, system, messages, max_tokens=900):
        try:
            msg = self.client.messages.create(model=self.model, max_tokens=max_tokens,
                                              system=system, messages=messages)
        except Exception as e:  # network, auth, overload
            raise AIError(f"anthropic error: {type(e).__name__}") from e
        return "".join(b.text for b in msg.content if getattr(b, "type", "") == "text")


class OpenAICompatProvider(Provider):
    """Any OpenAI-compatible /chat/completions endpoint (Ollama, LM gateways, OpenAI itself)."""

    def __init__(self, base_url: str, api_key: str, model: str):
        self.url = base_url.rstrip("/") + "/chat/completions"
        self.key, self.model = api_key, model

    def complete(self, system, messages, max_tokens=900):
        headers = {"Content-Type": "application/json"}
        if self.key:
            headers["Authorization"] = f"Bearer {self.key}"
        body = {"model": self.model, "max_tokens": max_tokens, "temperature": 0.9,
                "messages": [{"role": "system", "content": system}] + messages}
        try:
            r = requests.post(self.url, json=body, headers=headers, timeout=60)
            r.raise_for_status()
            return r.json()["choices"][0]["message"]["content"]
        except Exception as e:
            raise AIError(f"openai_compat error: {type(e).__name__}") from e


class MockProvider(Provider):
    """Deterministic fake for tests and for building the app without a key."""

    def complete(self, system, messages, max_tokens=900):
        return "mock coach: keep it light, ask about something they mentioned, and suggest a plan."

    def generate(self, kind, payload):
        seed = hashlib.sha1(repr(sorted(payload.items())).encode()).hexdigest()[:4]
        r = lambda t, w="": {"text": f"{t}", "why": w}
        if kind in ("reply", "opener"):
            return {"read": "They're engaged and asking questions back — good sign.", "boundary": False,
                    "replies": [r("wait you actually went? how was it", "Asks about their thing"),
                                r("ok that's elite taste, respect", "Quick, warm validation"),
                                r("you're making me want to try it this weekend", "Opens a plan"),
                                r(f"ranking that a solid 9/10 ({seed})", "Playful callback")]}
        if kind == "lines":
            return {"replies": [r(f"line {i+1} about {payload.get('text') or 'you'}", "Playful") for i in range(6)]}
        if kind == "tweak":
            return {"replies": [r("shorter take"), r("another take")]}
        if kind == "vibe":
            return {"interest": 72, "summary": "They reply fast and ask questions back. Momentum is good.",
                    "green_flags": ["Asks questions back", "Long replies"], "red_flags": ["Hasn't suggested meeting"],
                    "next_move": "Suggest a specific plan this week.", "boundary": False}
        if kind == "bio":
            return {"score": 58, "summary": "Clear but gives people nothing to reply to.",
                    "strengths": ["Short", "Honest"], "fixes": ["Add a hook", "Cut the list of adjectives"],
                    "rewrites": [r("rewrite one", "Has a question hook"), r("rewrite two"), r("rewrite three")]}
        raise AIError(f"unknown kind {kind}")


def make_provider(cfg) -> Provider:
    if cfg.provider == "anthropic":
        return AnthropicProvider(cfg.anthropic_api_key, cfg.anthropic_model)
    if cfg.provider == "openai_compat":
        return OpenAICompatProvider(cfg.openai_base_url, cfg.openai_api_key, cfg.openai_model)
    return MockProvider()
