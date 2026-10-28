# Draws Media/Refresh.tga: a clockwise circular arrow, white on transparent.
import math, sys
from PIL import Image, ImageDraw
S = 1024; c = S / 2; r = S * 0.30; w = S * 0.14   # 64 px tile shown at 14 px: ~2 px stroke
img = Image.new("L", (S, S), 0); d = ImageDraw.Draw(img)
start, end = -15, 285   # PIL degrees, clockwise from 3 o'clock; gap at the top right
d.arc([c - r - w/2, c - r - w/2, c + r + w/2, c + r + w/2], start, end, fill=255, width=int(w))
# round cap at the tail
a = math.radians(start); tx, ty = c + r*math.cos(a), c + r*math.sin(a)
d.ellipse([tx - w/2, ty - w/2, tx + w/2, ty + w/2], fill=255)
# arrowhead at the end, pointing clockwise into the gap
a = math.radians(end); px, py = c + r*math.cos(a), c + r*math.sin(a)
dx, dy = -math.sin(a), math.cos(a)          # tangent, clockwise
nx, ny = math.cos(a), math.sin(a)           # radial
h = w * 2.0; b = w * 1.15
tip = (px + dx*h, py + dy*h)
d.polygon([tip, (px + nx*b, py + ny*b), (px - nx*b, py - ny*b)], fill=255)
alpha = img.resize((64, 64), Image.LANCZOS)
out = Image.new("RGBA", (64, 64), (255, 255, 255, 0)); out.putalpha(alpha)
out.save(sys.argv[1])
prev = Image.new("RGBA", (64, 64), (20, 20, 20, 255)); prev.alpha_composite(out)
prev.resize((14, 14), Image.LANCZOS).resize((140, 140), Image.NEAREST).save(sys.argv[2])
prev.resize((256, 256), Image.LANCZOS).save(sys.argv[3])
