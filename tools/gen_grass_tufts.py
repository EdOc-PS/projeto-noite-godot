"""Gera a grama (glTF) usada pelo pincel do Terrain3D, um modelo de cada:
assets/models/grass/grass_tuft.gltf  — tufo de lâminas-cilindro, ponta pontuda de bico arredondado
assets/models/grass/grass_tuft_2d.gltf — tufo de lâminas CHATAS (2D, do jogo antigo: mais leve)
assets/models/grass/grass_star.gltf — tufo ESTRELA: cartas em pé cruzadas no centro, cada uma um pente de lâminas
assets/models/grass/grass_sprig.gltf — raminho de folhinhas brancas (sprite_0093 do Kenney em 3D)
Tom por lâmina na cor do vértice (o "Shaded"). UV.y = 1 na base e 0 na ponta
(cor e vento: shaders/nature/grass_body.gdshaderinc).
Rodar: python tools/gen_grass_tufts.py
"""
import base64
import json
import math
import os
import random
import struct

OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "models", "grass")
ARC = 6  # segmentos do semicírculo da ponta

TUFTS = {
    # nome: (seed, lâminas, raio, altura das lâminas (m), meia-largura)
    "grass_tuft": (21, (14, 18), 0.24, (0.32, 0.52), (0.03, 0.05)),
}
# Cada lâmina do tufo é um CILINDRO (tubo que afina um pouco) com a ponta
# pontuda de bico arredondado, curvando pra fora.
CYL_SIDES = 6      # lados do tubo (mais lados = mais redondo, mais pesado)
CYL_RINGS = 4      # anéis ao longo da altura
CYL_RADIUS = 0.75  # raio do tubo no pé, em fração da meia-largura da lâmina (fino)
CYL_BLADES = 0.5   # fração das lâminas do tufo de fita (lâmina gorda: menos lâminas)
CYL_GAP = 0.07     # distância mínima entre os pés das lâminas (m): não ficam coladas
CYL_TAPER = 0.12   # quanto o tubo afina até em cima
CYL_TIP = 4.5      # altura da ponta em raios (bem pontuda; 1 = meia esfera)
# Shaded (como os sprites Shaded do Kenney): umas lâminas na cor cheia, outras
# na MESMA cor mais escura. 40% das lâminas escuras, com tom 0,68–0,78.
DARK_CHANCE = 0.4
DARK_SHADE = (0.68, 0.78)


def tuft_cyl(seed, blades, radius, height, width):
    """Mesmo sorteio do tufo de fita (posição, altura, inclinação, shaded),
    mas cada lâmina vira um tubo com ponta arredondada."""
    rnd = random.Random(seed)
    pos, nor, uv, col, edge = [], [], [], [], []

    def add(p, n, t, shade):
        l = math.sqrt(sum(c * c for c in n)) or 1.0
        pos.append(p); nor.append(tuple(c / l for c in n)); uv.append((0.5, 1.0 - min(t, 1.0)))
        col.append((shade, shade, shade, 1.0)); edge.append((0.0, 0.0))

    feet = []
    for _ in range(max(3, round(rnd.randint(*blades) * CYL_BLADES))):
        for _try in range(40):  # sorteia o pé longe das outras lâminas
            a = rnd.uniform(0, math.tau)
            d = radius * math.sqrt(rnd.random())
            bx, bz = math.cos(a) * d, math.sin(a) * d
            if all(math.hypot(bx - fx, bz - fz) >= CYL_GAP for fx, fz in feet):
                break
        feet.append((bx, bz))
        h = rnd.uniform(*height)
        w = rnd.uniform(*width)
        rnd.uniform(0, math.tau)  # (yaw do tufo de fita: mantém o sorteio parecido)
        lean = rnd.uniform(0.06, 0.16) if d > 1e-6 else 0.0
        lx, lz = math.cos(a) * lean, math.sin(a) * lean
        shade = rnd.uniform(*DARK_SHADE) if rnd.random() < DARK_CHANCE else 1.0
        r0 = w * CYL_RADIUS
        rt = r0 * (1.0 - CYL_TAPER)  # raio no topo do tubo
        cap = rt * CYL_TIP           # altura da ponta
        body = h - cap  # o tubo sobe até aqui; o resto é a ponta

        def center(y):
            t = y / h
            return (bx + lx * t * t, y, bz + lz * t * t)

        def ring(y, r):
            c = center(y)
            return [((c[0] + math.cos(k * math.tau / CYL_SIDES) * r, c[1], c[2] + math.sin(k * math.tau / CYL_SIDES) * r),
                     (math.cos(k * math.tau / CYL_SIDES), 0.0, math.sin(k * math.tau / CYL_SIDES))) for k in range(CYL_SIDES)]

        rings = []
        for j in range(CYL_RINGS + 1):
            y = body * j / CYL_RINGS
            rings.append((ring(y, r0 * (1.0 - CYL_TAPER * j / CYL_RINGS)), y))
        # ponta: pontuda, mas com o bico arredondado (ogiva). O raio cai devagar
        # no começo e fecha num bico redondinho, não numa agulha.
        for j in range(1, 6):
            t = j / 5
            y = body + cap * t
            rr = rt * (1.0 - t) ** 0.9  # cone levemente cheio: ponta fina
            slope = cap / max(rt, 1e-4)
            rg = [(p, (n[0], 0.4 + 0.6 * t, n[2])) for p, n in ring(y, max(rr, rt * 0.03))]
            rings.append((rg, y))
        for (r_a, ya), (r_b, yb) in zip(rings, rings[1:]):
            for k in range(CYL_SIDES):
                k2 = (k + 1) % CYL_SIDES
                quad = [r_a[k], r_a[k2], r_b[k2], r_b[k]]
                ys = [ya, ya, yb, yb]
                for tri in ((0, 2, 1), (0, 3, 2)):
                    for i in tri:
                        add(quad[i][0], quad[i][1], ys[i] / h, shade)
    return pos, nor, uv, col, edge


# Tufo 2D (como o grass_tuft do jogo antigo, tools/gen_models.py): cada lâmina
# é uma folha chata de 5 pontos (base, meio, ponta pontuda), dos dois lados,
# inclinando pra fora do centro. Bem mais leve que o tufo de cilindros.
TUFTS_2D = {
    # nome: (seed, lâminas, raio, altura (m), meia-largura)
    "grass_tuft_2d": (21, 26, 0.14, (0.34, 0.58), (0.03, 0.045)),
}
# Lâmina da referência (grama em pé, tipo foto do campo lima): chata, larga no
# pé, afina devagar até a ponta pontuda, quase em pé com uma curvinha suave
# pra um lado (não deita). 5 alturas por lâmina pra curva ficar lisa.
BLADE_T = (0.0, 0.3, 0.55, 0.8, 1.0)
BLADE_W = (1.0, 0.9, 0.7, 0.4, 0.0)


def tuft_flat(seed, blades, radius, height, width):
    rnd = random.Random(seed)
    pos, nor, uv, col, edge = [], [], [], [], []
    for _ in range(blades):
        a = rnd.uniform(0, math.tau); d = radius * math.sqrt(rnd.random())
        bx, bz = math.cos(a) * d, math.sin(a) * d
        h = rnd.uniform(*height); w = rnd.uniform(*width)
        yaw = rnd.uniform(0, math.tau)
        side = (math.cos(yaw), math.sin(yaw))
        # curva pra frente da lâmina (perpendicular à largura), pouca: fica em pé
        bend = rnd.uniform(0.04, 0.14) * h * rnd.choice((-1, 1))
        fx, fz = -side[1], side[0]
        out = rnd.uniform(0.0, 0.05) if d > 1e-6 else 0.0  # abre só um pouco pra fora
        ox, oz = math.cos(a) * out, math.sin(a) * out
        shade = rnd.uniform(0.85, 1.0)
        rows = []
        for t, wf in zip(BLADE_T, BLADE_W):
            cx = bx + fx * bend * t * t + ox * t
            cz = bz + fz * bend * t * t + oz * t
            hw = w * wf
            rows.append(((cx - side[0] * hw, h * t, cz - side[1] * hw), (cx + side[0] * hw, h * t, cz + side[1] * hw), t))
        for face in (1, -1):
            n = (fx * 0.4 * face, 0.9, fz * 0.4 * face)
            l = math.sqrt(sum(c * c for c in n)); n = tuple(c / l for c in n)
            for (l0, r0, t0), (l1, r1, t1) in zip(rows, rows[1:]):
                q = [(l0, t0), (r0, t0), (r1, t1), (l1, t1)]
                tris = [(0, 1, 2), (0, 2, 3)] if t1 < 1.0 else [(0, 1, 2)]
                for tri in tris:
                    for i in (tri if face == 1 else (tri[0], tri[2], tri[1])):
                        pos.append(q[i][0]); nor.append(n); uv.append((0.5, 1.0 - q[i][1]))
                        col.append((shade, shade, shade, 1.0)); edge.append((0.0, 0.0))
    return pos, nor, uv, col, edge


# Tufo ESTRELA (referência de jogo isométrico): 4 cartas em pé cruzando no
# centro (vistas de cima formam uma estrela de 8 pontas), cada carta é um
# "pente" de lâminas finas lado a lado, mais altas no meio e mais baixas nas
# pontas da carta. De qualquer ângulo da câmera sempre tem carta de frente:
# volume com poucos triângulos, bom pra visão isométrica.
STAR = {
    # nome: (seed, cartas, lâminas por carta, meia-largura da carta (m), altura (m))
    "grass_star": (31, 4, 16, 0.22, (0.26, 0.42)),
}


def tuft_star(seed, cards, blades, half, height):
    rnd = random.Random(seed)
    pos, nor, uv, col, edge = [], [], [], [], []
    top = height[1] * 1.1  # altura de referência do degradê (UV.y)
    for c in range(cards):
        ang = math.pi * c / cards + rnd.uniform(-0.12, 0.12)
        side = (math.cos(ang), math.sin(ang))
        fx, fz = -side[1], side[0]
        for b in range(blades):
            u = -1.0 + 2.0 * (b + rnd.uniform(0.2, 0.8)) / blades  # -1..1 ao longo da carta
            x0 = u * half
            # mais alta no meio da carta, baixa nas pontas (silhueta de leque)
            h = rnd.uniform(*height) * (1.0 - 0.45 * u * u)
            w = rnd.uniform(0.018, 0.03)
            lean = u * rnd.uniform(0.05, 0.12) + rnd.uniform(-0.03, 0.03)  # abre em leque
            bend = rnd.uniform(-0.03, 0.03)  # curvinha pra fora do plano
            shade = rnd.uniform(0.88, 1.0)
            pts = [(x0 - w, 0.0, 0.0), (x0 + w, 0.0, 0.0), (x0 - w * 0.5 + lean * 0.6, 0.6, bend * 0.36), (x0 + w * 0.5 + lean * 0.6, 0.6, bend * 0.36), (x0 + lean, 1.0, bend)]
            verts = [(side[0] * px + fx * pz, h * t, side[1] * px + fz * pz) for px, t, pz in pts]
            for face in (1, -1):
                n = (fx * 0.45 * face, 0.9, fz * 0.45 * face)
                l = math.sqrt(sum(k * k for k in n)); n = tuple(k / l for k in n)
                for tri in ((0, 1, 2), (1, 3, 2), (2, 3, 4)):
                    for i in (tri if face == 1 else (tri[0], tri[2], tri[1])):
                        pos.append(verts[i]); nor.append(n); uv.append((0.5, 1.0 - verts[i][1] / top))
                        col.append((shade, shade, shade, 1.0)); edge.append((0.0, 0.0))
    return pos, nor, uv, col, edge


# Raminho 3D (o sprite_0093 do Kenney refeito em geometria): caule fino em tubo,
# galhos diagonais saindo dele, cada um terminando numa folha em gota (elipsoide),
# e folhinhas menores ao longo dos galhos. Meshes 3 e 4 do pincel.
SPRIGS_3D = {
    # nome: (seed, altura (m))
    "grass_sprig": (51, 0.45),
}


def _norm(v):
    l = math.sqrt(sum(c * c for c in v)) or 1.0
    return tuple(c / l for c in v)


def _frame(axis):
    """Dois vetores perpendiculares ao eixo."""
    ax = _norm(axis)
    ref = (0.0, 0.0, 1.0) if abs(ax[1]) > 0.9 else (0.0, 1.0, 0.0)
    u = _norm((ax[1] * ref[2] - ax[2] * ref[1], ax[2] * ref[0] - ax[0] * ref[2], ax[0] * ref[1] - ax[1] * ref[0]))
    v = (ax[1] * u[2] - ax[2] * u[1], ax[2] * u[0] - ax[0] * u[2], ax[0] * u[1] - ax[1] * u[0])
    return ax, u, v


def _tube(out, a, b, r0, r1, height, sides=6):
    pos, nor, uv, col, edge = out
    ax, u, v = _frame(tuple(b[i] - a[i] for i in range(3)))
    def ringp(c, r, k):
        ang = math.tau * k / sides
        n = tuple(u[i] * math.cos(ang) + v[i] * math.sin(ang) for i in range(3))
        return tuple(c[i] + n[i] * r for i in range(3)), n
    for k in range(sides):
        q = [ringp(a, r0, k), ringp(a, r0, k + 1), ringp(b, r1, k + 1), ringp(b, r1, k)]
        for tri in ((0, 2, 1), (0, 3, 2)):
            for i in tri:
                p, n = q[i]
                pos.append(p); nor.append(n); uv.append((0.5, 1.0 - min(p[1] / height, 1.0)))
                col.append((1.0, 1.0, 1.0, 1.0)); edge.append((0.0, 0.0))


def _leaf(out, base, axis, length, radius, height, sides=8, rings=6):
    """Folha em gota: elipsoide ao longo do eixo, mais larga perto da ponta."""
    pos, nor, uv, col, edge = out
    ax, u, v = _frame(axis)
    def pt(j, k):
        t = j / rings                     # 0 no pé, 1 na ponta
        prof = math.sin(math.pi * t) * (0.55 + 0.45 * t)  # gota: cresce e fecha redondo
        ang = math.tau * k / sides
        dirn = tuple(u[i] * math.cos(ang) + v[i] * math.sin(ang) for i in range(3))
        p = tuple(base[i] + ax[i] * length * t + dirn[i] * radius * prof for i in range(3))
        n = _norm(tuple(dirn[i] * prof + ax[i] * (t - 0.5) for i in range(3)))
        return p, n
    for j in range(rings):
        for k in range(sides):
            q = [pt(j, k), pt(j, k + 1), pt(j + 1, k + 1), pt(j + 1, k)]
            for tri in ((0, 2, 1), (0, 3, 2)):
                for i in tri:
                    p, n = q[i]
                    pos.append(p); nor.append(n); uv.append((0.5, 1.0 - min(p[1] / height, 1.0)))
                    col.append((1.0, 1.0, 1.0, 1.0)); edge.append((0.0, 0.0))


def sprig_3d(seed, height):
    rnd = random.Random(seed)
    out = ([], [], [], [], [])
    yaw = rnd.uniform(0, math.tau)
    stem_r = 0.008
    top = (0.0, height * 0.88, 0.0)
    _tube(out, (0.0, 0.0, 0.0), top, stem_r, stem_r * 0.8, height)
    _leaf(out, top, (0.0, 1.0, 0.0), height * 0.18, height * 0.06, height)
    # galhos começam baixo (pouco caule pelado no pé), 6 em espiral
    for j, t in enumerate((0.14, 0.27, 0.4, 0.53, 0.66, 0.78)):
        side = 1 if j % 2 == 0 else -1
        # galhos em espiral em volta do caule (ângulo de ouro): frente, trás e lados
        ang = yaw + j * math.radians(137.5) + rnd.uniform(-0.3, 0.3)
        out_dir = (math.cos(ang), 0.0, math.sin(ang))
        tilt = rnd.uniform(0.9, 1.3)  # galho sobe na diagonal
        bdir = _norm((out_dir[0], tilt, out_dir[2]))
        start = (0.0, height * t, 0.0)
        blen = height * rnd.uniform(0.18, 0.28) * (1.0 - 0.3 * t)
        end = tuple(start[i] + bdir[i] * blen for i in range(3))
        _tube(out, start, end, stem_r * 0.7, stem_r * 0.55, height)
        _leaf(out, end, bdir, height * 0.17, height * 0.055, height)
        # folhinha menor no meio do galho, pro lado
        mid = tuple(start[i] + bdir[i] * blen * 0.5 for i in range(3))
        sdir = _norm((bdir[0] - out_dir[2] * side, bdir[1] * 0.4, bdir[2] + out_dir[0] * side))
        _leaf(out, mid, sdir, height * 0.1, height * 0.038, height)
    return out


def write_gltf(path, name, pos, nor, uv, col, edge):
    blobs = [
        b"".join(struct.pack("<3f", *p) for p in pos),
        b"".join(struct.pack("<3f", *n) for n in nor),
        b"".join(struct.pack("<2f", *u) for u in uv),
        b"".join(struct.pack("<4f", *c) for c in col),
        b"".join(struct.pack("<2f", *e) for e in edge),
    ]
    data = b"".join(blobs)
    views, off = [], 0
    for b in blobs:
        views.append({"buffer": 0, "byteOffset": off, "byteLength": len(b), "target": 34962})
        off += len(b)
    n = len(pos)
    mins = [min(p[i] for p in pos) for i in range(3)]
    maxs = [max(p[i] for p in pos) for i in range(3)]
    gltf = {
        "asset": {"version": "2.0", "generator": "tools/gen_grass_tufts.py"},
        "scene": 0,
        "scenes": [{"nodes": [0]}],
        "nodes": [{"name": name, "mesh": 0}],
        "meshes": [{"name": name, "primitives": [{"attributes": {"POSITION": 0, "NORMAL": 1, "TEXCOORD_0": 2, "COLOR_0": 3, "TEXCOORD_1": 4}, "mode": 4}]}],
        "buffers": [{"byteLength": len(data), "uri": "data:application/octet-stream;base64," + base64.b64encode(data).decode()}],
        "bufferViews": views,
        "accessors": [
            {"bufferView": 0, "componentType": 5126, "count": n, "type": "VEC3", "min": mins, "max": maxs},
            {"bufferView": 1, "componentType": 5126, "count": n, "type": "VEC3"},
            {"bufferView": 2, "componentType": 5126, "count": n, "type": "VEC2"},
            {"bufferView": 3, "componentType": 5126, "count": n, "type": "VEC4"},
            {"bufferView": 4, "componentType": 5126, "count": n, "type": "VEC2"},
        ],
    }
    with open(path, "w", encoding="utf-8") as f:
        json.dump(gltf, f)


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    for name, (seed, blades, radius, height, width) in TUFTS.items():
        path = os.path.join(OUT_DIR, name + ".gltf")
        write_gltf(path, name, *tuft_cyl(seed, blades, radius, height, width))
        print(os.path.abspath(path))
    for name, args in TUFTS_2D.items():
        path = os.path.join(OUT_DIR, name + ".gltf")
        write_gltf(path, name, *tuft_flat(*args))
        print(os.path.abspath(path))
    for name, args in STAR.items():
        path = os.path.join(OUT_DIR, name + ".gltf")
        write_gltf(path, name, *tuft_star(*args))
        print(os.path.abspath(path))
    for name, (seed, height) in SPRIGS_3D.items():
        path = os.path.join(OUT_DIR, name + ".gltf")
        write_gltf(path, name, *sprig_3d(seed, height))
        print(os.path.abspath(path))


if __name__ == "__main__":
    main()
