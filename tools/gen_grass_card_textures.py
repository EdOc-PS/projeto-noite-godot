"""Gera o atlas dos tufos de grama BILLBOARD (carta que sempre vira pra câmera).
Saída: assets/textures/vegetation/grass/grass_clumps.png (1024 × 512, 2 células):
  célula 0 — tufo cheio: 15–18 lâminas em leque, pé junto, pontas abertas
  célula 1 — tufo de borda: 4–5 lâminas mais curtas e espaçadas
Lâminas BRANCAS (a cor vem toda do shader: pé = cor do chão, ponta clara), com
um cinza leve no pé só pra separar as lâminas. Alfa = máscara de borda suave.
Uso: python tools/gen_grass_card_textures.py
"""
import math, os, random, struct, zlib

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "textures", "vegetation", "grass")
W, H, CELL = 1024, 512, 512


def blade(rnd, x0, hmin, hmax, spread):
    h = rnd.uniform(hmin, hmax) * H
    w = rnd.uniform(14, 24)
    # pé perto do centro da célula, ponta abre pra fora (leque) com curva
    lean = (x0 - spread[0]) * spread[1] + rnd.uniform(-25, 25)
    def edges(s):
        c = x0 + lean * s ** 1.6
        hw = w * (1.0 - s) ** 0.8
        return c - hw, c + hw
    return h, edges


def render():
    acc = [[0.0, 0.0] for _ in range(W * H)]  # (cobertura, cinza·cobertura)
    # célula: (lâminas, altura mín/máx, largura do pé, quanto abre, seed)
    for cell, (count, hmin, hmax, base, opens, seed) in enumerate((((15, 18), 0.5, 0.95, 0.6, 0.9, 3), ((4, 5), 0.35, 0.7, 0.55, 0.6, 9))):
        rnd = random.Random(seed)
        n = rnd.randint(*count)
        mid = cell * CELL + CELL * 0.5
        for i in range(n):
            x0 = mid + CELL * base * ((i + rnd.uniform(0.2, 0.8)) / n - 0.5)
            h, edges = blade(rnd, x0, hmin, hmax, (mid, opens))
            for py in range(H):
                s = (H - 1 - py) / h  # 0 no pé, 1 na ponta
                if s > 1.0:
                    continue
                a, b = edges(s)
                gray = 0.8 + 0.2 * min(s * 3.0, 1.0)  # cinza só no pezinho
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
    path = os.path.join(OUT, "grass_clumps.png")
    write_png(path, render())
    print("ok:", os.path.abspath(path))
