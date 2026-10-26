"""Gera os PNGs das florzinhas do campo (estilo BotW: tufos de flores em tons
pastel, com caules de alturas diferentes, misturados na grama). Cada imagem é
um tufo; o shader shaders/nature/flower_card.gdshader desenha em cartas
cruzadas. Regras: .docs/plans/10-vegetacao.md.

Uso: python tools/gen_flower_textures.py
Saída: assets/textures/vegetation/flowers/flowers_<tipo>.png
"""
import math, os, random, struct, zlib

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "textures", "vegetation", "flowers")
N = 256      # tamanho final
SS = 2       # supersampling (borda lisa)

STEM = (0.5, 0.68, 0.15)      # caule no verde da grama
STEM_DARK = (0.36, 0.53, 0.08)

# tipo: (cor das pétalas, cor do miolo, formato, raio da flor em px, n de flores,
#        altura do topo das flores na imagem (0 = topo, 1 = base))
KINDS = {
    "white": ((0.97, 0.97, 0.93), (0.95, 0.88, 0.55), "daisy", 9, (7, 11), (0.55, 0.8)),     # branca baixinha, quase rente ao chão, muitas
    "blue": ((0.56, 0.68, 0.96), (0.98, 0.9, 0.55), "daisy", 12, (4, 7), (0.2, 0.45)),       # azul, com caule
    "pink": ((0.98, 0.66, 0.78), (0.98, 0.9, 0.55), "daisy", 13, (4, 6), (0.1, 0.4)),        # rosa, com caule
    "red": ((0.94, 0.52, 0.5), (0.86, 0.42, 0.42), "spike", 13, (4, 6), (0.04, 0.35)),       # vermelho pastel em espiga reta
}


def write_png(path, w, h, rgba):
    raw = b"".join(b"\x00" + bytes(rgba[y * w * 4:(y + 1) * w * 4]) for y in range(h))
    def chunk(t, d):
        c = struct.pack(">I", len(d)) + t + d
        return c + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff)
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")
    with open(path, "wb") as f:
        f.write(png)


def seg_dist(px, py, ax, ay, bx, by):
    dx, dy = bx - ax, by - ay
    t = max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy + 1e-9)))
    return math.hypot(px - (ax + dx * t), py - (ay + dy * t))


def flower_hit(dx, dy, r, shape):
    """0 = fora, 1 = pétala, 2 = miolo."""
    d = math.hypot(dx, dy)
    a = math.atan2(dy, dx)
    if d < r * 0.32 and shape not in ("puff", "spike", "ball"):
        return 2
    if shape == "spike":       # espiga comprida (tipo trigo): grãos empilhados
        e = (dx / (r * 0.42)) ** 2 + ((dy - r * 0.9) / (r * 1.9)) ** 2
        bump = 0.85 + 0.15 * math.cos(dy * 0.9)
        return (2 if (int((dy + 100) / (r * 0.35)) % 2 == 0 and abs(dx) < r * 0.12) else 1) if e < bump else 0
    if shape == "ball":        # bolinha rechonchuda
        return 1 if d < r * (0.92 + 0.08 * math.cos(a * 7)) else 0
    if shape == "puff":        # bolinha com borda franjada
        return 1 if d < r * (0.85 + 0.15 * math.cos(a * 12)) else 0
    if shape == "daisy":       # 8 pétalas compridas
        return 1 if d < r * (0.45 + 0.55 * abs(math.cos(a * 4)) ** 0.6) else 0
    if shape == "star":        # 5 pontas
        return 1 if d < r * (0.42 + 0.58 * (0.5 + 0.5 * math.cos(a * 5)) ** 1.6) else 0
    return 1 if d < r * (0.75 + 0.25 * abs(math.cos(a * 2.5))) else 0  # round: 5 pétalas largas


def make(kind, seed):
    petal, center, shape, radius, count, height = KINDS[kind]
    rng = random.Random(seed)
    S = N * SS
    n = rng.randint(*count)
    # caules: base embaixo, alturas diferentes, leve curva
    stems = []
    for i in range(n):
        bx = S * (0.2 + 0.6 * (i + rng.random() * 0.8) / n)
        top_y = S * rng.uniform(*height)  # flor só no topo; altura por tipo
        tx = bx + rng.uniform(-0.08, 0.08) * S
        mx = (bx + tx) / 2 + rng.uniform(-0.05, 0.05) * S
        r = radius * SS * rng.uniform(0.8, 1.15)
        stems.append((bx, S - 1, mx, (S + top_y) / 2, tx, top_y, r, rng.uniform(0.9, 1.05)))
    w = 1.6 * SS
    acc = [0.0] * (N * N * 4)
    for y in range(S):
        for x in range(S):
            col = None
            for (bx, by, mx, my, tx, ty, r, shade) in stems:
                hit = flower_hit(x - tx, y - ty, r, shape)
                if hit:
                    c = center if hit == 2 else petal
                    # pétala mais clara em cima, mais escura embaixo (dois tons)
                    k = shade * (1.0 if y < ty else 0.9)
                    col = (c[0] * k, c[1] * k, c[2] * k)
                    break
                if seg_dist(x, y, bx, by, mx, my) < w or seg_dist(x, y, mx, my, tx, ty) < w:
                    col = STEM if x < (bx + tx) / 2 else STEM_DARK
            if col is None:
                continue
            i = ((y // SS) * N + (x // SS)) * 4
            acc[i] += col[0]; acc[i + 1] += col[1]; acc[i + 2] += col[2]; acc[i + 3] += 1.0
    out = bytearray(N * N * 4)
    k = SS * SS
    for i in range(0, len(acc), 4):
        a = acc[i + 3]
        if a > 0:
            out[i] = int(min(acc[i] / a, 1.0) * 255)
            out[i + 1] = int(min(acc[i + 1] / a, 1.0) * 255)
            out[i + 2] = int(min(acc[i + 2] / a, 1.0) * 255)
        out[i + 3] = int(a / k * 255)
    return out


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for j, kind in enumerate(KINDS):
        path = os.path.join(OUT, f"flowers_{kind}.png")
        write_png(path, N, N, make(kind, 100 + j))
        print("ok:", path)
