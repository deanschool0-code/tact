"""Draws Tact's first-pass app icon: a lime speech bubble whose tail is a checkmark, on ink. 1024x1024, no alpha."""
import sys
from PIL import Image, ImageDraw

S = 1024
ink, lime = (13, 15, 20), (200, 242, 90)
img = Image.new("RGB", (S, S), ink)
d = ImageDraw.Draw(img)
# bubble
d.rounded_rectangle((170, 200, 854, 700), radius=190, fill=lime)
# tail
d.polygon([(300, 640), (250, 860), (470, 690)], fill=lime)
# checkmark in ink
d.line([(350, 455), (470, 570), (690, 340)], fill=ink, width=78, joint="curve")
for x, y in [(350, 455), (690, 340)]:
    d.ellipse((x - 39, y - 39, x + 39, y + 39), fill=ink)
out = sys.argv[1] if len(sys.argv) > 1 else "icon-1024.png"
img.save(out)
print("wrote", out)
