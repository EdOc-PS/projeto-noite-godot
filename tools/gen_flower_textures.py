"""Gera os PNGs das florzinhas do campo (estilo BotW: tufos de flores em tons
pastel). A câmera é isométrica (de cima), então as flores ficam numa carta
DEITADA, viradas pra cima: flowers_<tipo>.png são as cabeças vistas de cima.
Os tipos com caule ganham flowers_<tipo>_stem.png (só caules, cartas cruzadas
em pé até a altura HEAD). Shader: shaders/nature/flower_card.gdshader. Regras: .docs/plans/10-vegetacao.md.

Uso: python tools/gen_flower_textures.py
Saída: assets/textures/vegetation/flowers/flowers_<tipo>.png (+ _stem.png)
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
    "white": ((1.0, 1.0, 0.96), (1.0, 1.0, 1.0), "daisy", 16, (4, 6), (0.84, 0.92)),    # branca, colada no chão (caule escondido), muitas
    "blue": ((0.56, 0.68, 0.96), (0.98, 0.9, 0.55), "daisy", 16, (4, 7), (0.12, 0.4)),       # azul, com caule
    "pink": ((0.98, 0.66, 0.78), (0.98, 0.9, 0.55), "daisy", 17, (4, 6), (0.06, 0.35)),        # rosa, com caule
    "red": ((0.94, 0.52, 0.5), (0.86, 0.42, 0.42), "spike", 16, (4, 6), (0.04, 0.3)),       # vermelho pastel em espiga reta
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


HEAD = 0.72  # altura das flores (fração da carta) nos tipos com caule; tem que bater com flower_field.gd
TOP_SHAPE = {"spike": "ball"}  # espiga vista de cima vira bolinha


def _pack(acc):
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


def make_top(kind, seed):
    """Flores vistas DE CIMA (carta deitada): cabeças espalhadas num disco."""
    petal, center, shape, radius, count, _ = KINDS[kind]
    shape = TOP_SHAPE.get(shape, shape)
    rng = random.Random(seed)
    S = N * SS
    heads = []
    for _ in range(rng.randint(*count)):
        for _try in range(40):
            d = S * (0.4 if kind == "white" else 0.33) * math.sqrt(rng.random()); a = rng.uniform(0, math.tau)
            x, y = S / 2 + math.cos(a) * d, S / 2 + math.sin(a) * d
            r = radius * SS * 1.3 * rng.uniform(0.8, 1.15)
            if all(math.hypot(x - hx, y - hy) > (r + hr) * (1.25 if kind == "white" else 0.8) for hx, hy, hr, _, _ in heads):
                break
        # branca: mesmo branco do raminho, com Shaded (40% das flores num tom mais escuro)
        shade = (rng.uniform(0.8, 0.88) if rng.random() < 0.4 else 1.0) if kind == "white" else rng.uniform(0.9, 1.05)
        heads.append((x, y, r, rng.uniform(0, math.tau), shade))
    acc = [0.0] * (N * N * 4)
    for y in range(S):
        for x in range(S):
            for (hx, hy, r, rot, shade) in heads:
                dx, dy = x - hx, y - hy
                if abs(dx) > r * 2 or abs(dy) > r * 2:
                    continue
                c, sn = math.cos(rot), math.sin(rot)
                hit = flower_hit(dx * c - dy * sn, dx * sn + dy * c, r, shape)
                if hit:
                    col = center if hit == 2 else petal
                    k = shade * (1.0 if dy < 0 else 0.92)  # metade de baixo um pouco mais escura
                    i = ((y // SS) * N + (x // SS)) * 4
                    acc[i] += col[0] * k; acc[i + 1] += col[1] * k; acc[i + 2] += col[2] * k; acc[i + 3] += 1.0
                    break
    return _pack(acc)


def make_stems(kind, seed):
    """Só os caules (carta em pé), do chão até HEAD, onde a carta deitada das flores fica."""
    rng = random.Random(seed)
    S = N * SS
    n = rng.randint(*KINDS[kind][4])
    top_y = S * (1.0 - HEAD)
    stems = []
    for i in range(n):
        bx = S * (0.25 + 0.5 * (i + rng.random() * 0.8) / n)
        tx = bx + rng.uniform(-0.1, 0.1) * S
        mx = (bx + tx) / 2 + rng.uniform(-0.05, 0.05) * S
        stems.append((bx, S - 1, mx, (S + top_y) / 2, tx, top_y))
    w = 1.6 * SS
    acc = [0.0] * (N * N * 4)
    for y in range(int(top_y) - 2, S):
        for x in range(S):
            for (bx, by, mx, my, tx, ty) in stems:
                if seg_dist(x, y, bx, by, mx, my) < w or seg_dist(x, y, mx, my, tx, ty) < w:
                    col = STEM if x < (bx + tx) / 2 else STEM_DARK
                    i = ((y // SS) * N + (x // SS)) * 4
                    acc[i] += col[0]; acc[i + 1] += col[1]; acc[i + 2] += col[2]; acc[i + 3] += 1.0
                    break
    return _pack(acc)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for j, kind in enumerate(KINDS):
        path = os.path.join(OUT, f"flowers_{kind}.png")
        write_png(path, N, N, make_top(kind, 100 + j))
        print("ok:", path)
        if kind != "white":  # a branca é rente ao chão: sem caule
            path = os.path.join(OUT, f"flowers_{kind}_stem.png")
            write_png(path, N, N, make_stems(kind, 200 + j))
            print("ok:", path)
