"""Tiny .env loader so there's one less dependency. Existing env vars win."""
import os


def load_env(path: str) -> None:
    if not os.path.exists(path):
        return
    with open(path) as fh:
        for line in fh:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            v = v.strip()
            if v[:1] in ('"', "'"):
                v = v[1:].split(v[0], 1)[0]
            else:
                v = "" if v.startswith("#") else v.split(" #", 1)[0].split("\t#", 1)[0].strip()
            os.environ.setdefault(k.strip(), v)
