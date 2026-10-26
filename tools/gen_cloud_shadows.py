"""Gera assets/textures/effects/cloud_shadows.png: manchas de sombra de nuvem
macias, em alpha, num padrão que repete (3x3 tiles idênticos). O Decal desliza
um período e volta sem emenda visível. Rodar: python tools/gen_cloud_shadows.py
"""
import os, random
from PIL import Image, ImageDraw, ImageFilter

T = 256           # pixels por período (o Decal usa 1 período = 40 m)
SEED = 11
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "textures", "effects", "cloud_shadows.png")

rnd = random.Random(SEED)
# 2 nuvens por período, bem separadas
centers = [(0.28 * T, 0.30 * T), (0.75 * T, 0.72 * T)]
clouds = []
for cx, cy in centers:
    n = rnd.randint(6, 9)
    length = rnd.uniform(70, 100)
    blobs = []
    for i in range(n):
        t = i / (n - 1) - 0.5
        r = (1 - abs(t) * 1.2) * rnd.uniform(20, 28) + 8
        blobs.append((cx + t * length + rnd.uniform(-6, 6), cy + rnd.uniform(-10, 10), r))
    clouds.append(blobs)

big = Image.new("L", (T * 3, T * 3), 0)
d = ImageDraw.Draw(big)
for ox in range(-1, 4):
    for oy in range(-1, 4):
        for blobs in clouds:
            for x, y, r in blobs:
                x += ox * T; y += oy * T
                d.ellipse((x - r * 1.2, y - r * 0.85, x + r * 1.2, y + r * 0.85), fill=255)
big = big.filter(ImageFilter.GaussianBlur(10))
tile = big.crop((T, T, 2 * T, 2 * T))
alpha = Image.new("L", (T * 3, T * 3))
for i in range(3):
    for j in range(3):
        alpha.paste(tile, (i * T, j * T))
white = Image.new("L", alpha.size, 255)  # cor vem do modulate do Decal
os.makedirs(os.path.dirname(OUT), exist_ok=True)
Image.merge("RGBA", (white, white, white, alpha)).save(OUT)
print("ok", OUT)
