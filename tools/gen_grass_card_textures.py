"""Gera o atlas de lâminas pras cartas de grama (tufos em estrela, vista isométrica).
Saída: assets/textures/vegetation/grass/grass_blades.png (1024 × 512, 2 células de 512):
  célula 0 — 5–7 lâminas compridas e curvas, pé largo e ponta fina (referência 1)
  célula 1 — 2–3 lâminas retas com a ponta cortada torta (referência 2)
Cinza: escuro no pé, branco na ponta (o shader grass_body pinta o degradê e usa
o cinza só pra sombrear). Alfa = máscara, com borda suave (cobertura por pixel).
Uso: python tools/gen_grass_card_textures.py
"""
import math, os, random, struct, zlib

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "textures", "vegetation", "grass")
W, H, CELL = 1024, 512, 512


def blade_curved(rnd, x0):
    h = rnd.uniform(0.45, 0.95) * H
    w = rnd.uniform(16, 26)
    curve = rnd.uniform(-40, 40)
    def edges(s):
        c = x0 + curve * s * s
        hw = w * (1.0 - s) ** 0.75
        return c - hw, c + hw
    return h, edges


def blade_cut(rnd, x0):
    h = rnd.uniform(0.4, 0.75) * H
    w = rnd.uniform(18, 28)
    lean = rnd.uniform(-60, 60)
    cut = rnd.uniform(0.55, 0.8)       # onde o lado de dentro começa a cortar
    side = rnd.choice((-1, 1))
    def edges(s):
        c = x0 + lean * s
        hw = w * (1.0 - 0.45 * s)
        a, b = c - hw, c + hw
        if s > cut:  # um lado vai reto até o topo, o outro corta na diagonal
            k = (s - cut) / (1.0 - cut)
            if side > 0:
                b = b + (a + 2 - b) * k
            else:
                a = a + (b - 2 - a) * k
        return a, b
    return h, edges


def render():
    acc = [[0.0, 0.0] for _ in range(W * H)]  # (cobertura, cinza·cobertura)
    for cell, (maker, count, seed) in enumerate(((blade_curved, (5, 7), 3), (blade_cut, (2, 3), 9))):
        rnd = random.Random(seed)
        n = rnd.randint(*count)
        for i in range(n):
            x0 = cell * CELL + CELL * (0.12 + 0.76 * (i + rnd.uniform(0.2, 0.8)) / n)
            h, edges = maker(rnd, x0)
            for py in range(H):
                s = (H - 1 - py) / h  # 0 no pé, 1 na ponta
                if s > 1.0:
                    continue
                a, b = edges(s)
                gray = 0.62 + 0.38 * s
                for px in range(max(int(a), cell * CELL), min(int(b) + 1, (cell + 1) * CELL)):
                    cov = max(0.0, min(px + 1, b) - max(px, a))
                    if cov <= 0:
                        continue
                    p = acc[py * W + px]
                    add = min(cov, 1.0 - p[0])
                    p[0] += add; p[1] += gray * add
    out = bytearray()
    for py in range(H):
        out.append(0)
        for px in range(W):
            c, g = acc[py * W + px]
            v = int((g / c if c > 0 else 1.0) * 255)
            out += bytes((v, v, v, int(min(c, 1.0) * 255)))
    return bytes(out)


def write_png(path, raw):
    def chunk(t, d):
        c = struct.pack(">I", len(d)) + t + d
        return c + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff)
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", W, H, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")
    open(path, "wb").write(png)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, "grass_blades.png")
    write_png(path, render())
    print("ok:", os.path.abspath(path))
