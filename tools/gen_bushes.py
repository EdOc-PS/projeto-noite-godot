"""Gera os arbustos de teste (assets/models/bushes/), pra comparar lado a lado:
bush_blob.gltf — feito do zero: montinho de bolas low-poly fundidas (pé largo,
                 topo arredondado), cada bola com leve "amassado" pra não ficar
                 perfeita. Shader da grama (degradê pela altura, borda, vento).
bush_card.gltf — montado com o PNG (assets/textures/vegetation/bushes/bush_card.png):
                 3 cartas em pé cruzadas no centro (estrela), textura com alfa.
O terceiro (Bush_Common, Quaternius Stylized Nature) é copiado do pacote.
Uso: python tools/gen_bushes.py
"""
import math, os, random, sys

sys.path.insert(0, os.path.dirname(__file__))
from gen_grass_tufts import write_gltf  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "models", "bushes")


def icosphere(sub):
    t = (1 + 5 ** 0.5) / 2
    v = [(-1, t, 0), (1, t, 0), (-1, -t, 0), (1, -t, 0), (0, -1, t), (0, 1, t), (0, -1, -t), (0, 1, -t),
         (t, 0, -1), (t, 0, 1), (-t, 0, -1), (-t, 0, 1)]
    v = [tuple(c / math.sqrt(sum(x * x for x in p)) for c in p) for p in v]
    f = [(0, 11, 5), (0, 5, 1), (0, 1, 7), (0, 7, 10), (0, 10, 11), (1, 5, 9), (5, 11, 4), (11, 10, 2), (10, 7, 6), (7, 1, 8),
         (3, 9, 4), (3, 4, 2), (3, 2, 6), (3, 6, 8), (3, 8, 9), (4, 9, 5), (2, 4, 11), (6, 2, 10), (8, 6, 7), (9, 8, 1)]
    for _ in range(sub):
        cache, nf = {}, []
        def mid(a, b):
            k = (min(a, b), max(a, b))
            if k not in cache:
                p = tuple((v[a][i] + v[b][i]) / 2 for i in range(3))
                l = math.sqrt(sum(x * x for x in p))
                v.append(tuple(x / l for x in p)); cache[k] = len(v) - 1
            return cache[k]
        for a, b, c in f:
            ab, bc, ca = mid(a, b), mid(b, c), mid(c, a)
            nf += [(a, ab, ca), (b, bc, ab), (c, ca, bc), (ab, bc, ca)]
        f = nf
    return v, f


def bush_blob(seed=7):
    rnd = random.Random(seed)
    v, f = icosphere(2)
    # (x, y, z, raio): corpo central, anel de bolas em volta (pé largo), topo
    blobs = [(0.0, 0.36, 0.0, 0.4)]
    for i in range(6):
        a = i * math.tau / 6 + rnd.uniform(-0.3, 0.3)
        blobs.append((math.cos(a) * 0.33, 0.24 + rnd.uniform(-0.04, 0.05), math.sin(a) * 0.33, rnd.uniform(0.25, 0.32)))
    for i in range(3):
        a = i * math.tau / 3 + rnd.uniform(-0.4, 0.4)
        blobs.append((math.cos(a) * 0.14, 0.58 + rnd.uniform(-0.03, 0.04), math.sin(a) * 0.14, rnd.uniform(0.22, 0.27)))
    pos, nor, uv, col, edge = [], [], [], [], []
    for bx, by, bz, r in blobs:
        bump = [1.0 + rnd.uniform(-0.06, 0.06) for _ in v]
        shade = rnd.uniform(0.86, 1.0)
        for tri in f:
            for i in tri:  # anti-horário visto de fora (igual às lâminas da grama)
                n = v[i]
                p = (bx + n[0] * r * bump[i], max(by + n[1] * r * bump[i], -0.05), bz + n[2] * r * bump[i])
                pos.append(p); nor.append(n); uv.append((0.5, 0.5))
                col.append((shade, shade, shade, 1.0)); edge.append((0.0, 0.0))
    return pos, nor, uv, col, edge


def bush_card(width=1.15, height=1.15):
    pos, nor, uv, col, edge = [], [], [], [], []
    for k in range(3):
        a = k * math.pi / 3
        d = (math.cos(a) * width / 2, math.sin(a) * width / 2)
        q = [((-d[0], -0.05, -d[1]), (0, 1)), ((d[0], -0.05, d[1]), (1, 1)), ((d[0], height, d[1]), (1, 0)), ((-d[0], height, -d[1]), (0, 0))]
        for i in (0, 1, 2, 0, 2, 3):
            pos.append(q[i][0]); nor.append((0.0, 1.0, 0.0)); uv.append(q[i][1])
            col.append((1.0, 1.0, 1.0, 1.0)); edge.append((0.0, 0.0))
    return pos, nor, uv, col, edge


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for name, data in (("bush_blob", bush_blob()), ("bush_card", bush_card())):
        path = os.path.join(OUT, name + ".gltf")
        write_gltf(path, name, *data)
        print("ok:", os.path.abspath(path))
