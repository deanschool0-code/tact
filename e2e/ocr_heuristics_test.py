"""Mirror of OCRService.side/groupIntoBubbles/isNoise (Swift) to sanity-check the heuristics on a synthetic
iMessage-style screenshot. Boxes are Vision-style: normalised, origin bottom-left. Keep in sync with Swift."""
import re

NOISE = [r"^\d{1,2}[:.]\d{2}(\s?[AaPp]\.?[Mm]\.?)?$", r"^(today|yesterday|hoy|ayer)\b.*",
         r"^(delivered|read|seen|sent|visto|entregado|leído)(\s.*)?$",
         r"^(imessage|text message|message|mensaje|type a message|send a message|escribe un mensaje|aa)$"]


def box(x0, y0, x1, y1):
    return dict(minX=x0, minY=y0, maxX=x1, maxY=y1, midX=(x0 + x1) / 2, w=x1 - x0, h=y1 - y0)


def noise(t, b):
    if len(t.strip()) <= 1 or b["minY"] > 0.955 or b["maxY"] < 0.035: return True
    if abs(b["midX"] - 0.5) < 0.06 and b["w"] < 0.5: return True
    return any(re.match(p, t, re.I) for p in NOISE)


def side(b):
    if b["minX"] > 0.28: return "me"
    if b["maxX"] < 0.72: return "them"
    return "me" if b["midX"] > 0.5 else "them"


def group(pieces):
    out, last = [], None
    for t, b in sorted(pieces, key=lambda p: -p[1]["maxY"]):
        s = side(b)
        if out and last and out[-1][0] == s and (last["minY"] - b["maxY"]) < max(b["h"], last["h"]) * 0.9:
            out[-1][1] += " " + t; last = b; continue
        out.append([s, t]); last = b
    return out


shot = [("9:41", box(0.05, 0.965, 0.15, 0.985)),               # status bar
        ("Sofía", box(0.44, 0.90, 0.56, 0.93)),                 # centred header
        ("Today 8:02 PM", box(0.38, 0.84, 0.62, 0.86)),         # centred date
        ("just got back from a hike", box(0.06, 0.78, 0.55, 0.81)),
        ("at el morado", box(0.06, 0.75, 0.30, 0.78)),          # 2nd line of same bubble
        ("no way, how was it", box(0.58, 0.68, 0.94, 0.71)),
        ("Delivered", box(0.80, 0.65, 0.94, 0.665)),
        ("freezing but the glacier was unreal", box(0.06, 0.58, 0.70, 0.61)),
        ("iMessage", box(0.12, 0.02, 0.30, 0.05))]
got = group([p for p in shot if not noise(*p)])
want = [["them", "just got back from a hike at el morado"], ["me", "no way, how was it"],
        ["them", "freezing but the glacier was unreal"]]
assert got == want, got
print("OCR heuristics OK:", got)
