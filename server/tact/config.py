"""All settings come from environment variables. See .env.example."""
import os


def _bool(name: str, default: bool = False) -> bool:
    return os.environ.get(name, str(default)).strip().lower() in ("1", "true", "yes", "on")


def _int(name: str, default: int) -> int:
    raw = (os.environ.get(name) or "").strip()
    try:
        return int(raw) if raw else default
    except ValueError:
        return default


class Config:
    def __init__(self, **overrides):
        e = os.environ.get
        self.provider = (e("AI_PROVIDER") or "mock")  # anthropic | openai_compat | mock
        self.anthropic_api_key = e("ANTHROPIC_API_KEY", "")
        self.anthropic_model = (e("ANTHROPIC_MODEL") or "claude-sonnet-4-5")
        self.openai_base_url = (e("OPENAI_BASE_URL") or "http://localhost:11434/v1")
        self.openai_api_key = e("OPENAI_API_KEY", "")
        self.openai_model = (e("OPENAI_MODEL") or "llama3.1")
        self.db_path = e("DB_PATH") or os.path.join(os.path.dirname(__file__), "..", "tact.db")
        self.free_daily = _int("FREE_DAILY", 3)
        self.rate_per_minute = _int("RATE_PER_MINUTE", 30)
        self.bundle_id = (e("APP_BUNDLE_ID") or "com.deancarson.tact")
        self.app_apple_id = _int("APP_APPLE_ID", 0) or None
        self.certs_dir = e("APPLE_CERTS_DIR") or os.path.join(os.path.dirname(__file__), "..", "certs")
        self.allow_xcode_transactions = _bool("ALLOW_XCODE_TRANSACTIONS")
        self.client_token = e("CLIENT_TOKEN", "")  # optional shared header, a speed bump only
        for k, v in overrides.items():
            setattr(self, k, v)
