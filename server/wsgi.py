"""Entry point: gunicorn wsgi:app  (or python wsgi.py for local dev)."""
import os

from dotenv_lite import load_env

load_env(os.path.join(os.path.dirname(__file__), ".env"))

from tact.app import create_app  # noqa: E402

app = create_app()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", "5580")))
