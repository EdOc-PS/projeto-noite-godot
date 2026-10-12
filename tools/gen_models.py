"""Gera os modelos feitos no projeto em assets/models/custom/, no padrão dos kits
Tiny Treats: low poly arredondado (icosferas com normais suaves), cor vinda da
atlas do Tiny Treats (gradiente vertical: claro em cima), roughness 0.5 /
metallic 0, glTF.

  smoke/smoke_puff.gltf         fumaça da chaminé (~0,8 m)
  clouds/cloud_a..d.gltf        nuvens grandes (8–14 m), base achatada,
                                formas inspiradas no pacote Low Poly Clouds
  props/fireplace.gltf          lareira de pedra/tijolo com cantos arredondados
                                (caixas arredondadas, cores da atlas)
  props/floor_stone_blend*.gltf placas de pedra em degradê por cima do piso de
                                madeira: transição madeira -> piso de pedra
  props/rug_medieval_red.gltf   tapete vermelho medieval (mesmas cores do
                                estandarte do KayKit Dungeon: vermelho + dourado)
  grass/grass_tuft_A/B.gltf     tufos de grama densa (folhas finas e juntas),
                                menores que as gramas dos kits; balançam com
                                o vento e amassam com o jogador (WindApplier)

Rodar: python tools/gen_models.py
"""
import json, math, struct, os, random

ROOT = os.path.join(os.path.dirname(__file__), "..", "assets", "models", "custom")
TEX = "../../tiny_treats/homely_house/tiny_treats_texture_1.png"
TEX_FALLBACK = "../../calm_place/homely_house/tiny_treats_texture_1.png"
ATLAS = 1024
COL_U = 448            # coluna branco-frio da atlas (célula x 384–511)
V_TOP, V_BOT = 8, 200  # claro em cima, mais escuro embaixo


def icosphere(subdiv):
    t = (1 + 5 ** 0.5) / 2
    v = [(-1, t, 0), (1, t, 0), (-1, -t, 0), (1, -t, 0), (0, -1, t), (0, 1, t),
         (0, -1, -t), (0, 1, -t), (t, 0, -1), (t, 0, 1), (-t, 0, -1), (-t, 0, 1)]
    v = [tuple(c / math.sqrt(sum(x * x for x in p)) for c in p) for p in v]
    f = [(0,11,5),(0,5,1),(0,1,7),(0,7,10),(0,10,11),(1,5,9),(5,11,4),(11,10,2),(10,7,6),(7,1,8),
         (3,9,4),(3,4,2),(3,2,6),(3,6,8),(3,8,9),(4,9,5),(2,4,11),(6,2,10),(8,6,7),(9,8,1)]
    for _ in range(subdiv):
        cache, nf = {}, []
        def mid(a, b):
            k = (min(a, b), max(a, b))
            if k not in cache:
                p = [(v[a][i] + v[b][i]) / 2 for i in range(3)]
                l = math.sqrt(sum(x * x for x in p))
                v.append(tuple(x / l for x in p)); cache[k] = len(v) - 1
            return cache[k]
        for a, b, c in f:
            ab, bc, ca = mid(a, b), mid(b, c), mid(c, a)
            nf += [(a, ab, ca), (b, bc, ab), (c, ca, bc), (ab, bc, ca)]
        f = nf
    return v, f


def write_gltf(path, name, blobs, subdiv, squash_bottom=0.0):
    """blobs: [((cx,cy,cz), raio)]. squash_bottom: achata a parte de baixo (0..1)."""
    sv, sf = icosphere(subdiv)
    pos, nor, idx = [], [], []
    for (cx, cy, cz), r in blobs:
        base = len(pos)
        for x, y, z in sv:
            yy = y * (1 - squash_bottom) if y < 0 else y
            pos.append((cx + x * r, max(cy + yy * r, 0.0), cz + z * r))
            nor.append((x, y, z))
        idx += [i + base for tri in sf for i in tri]

    ymin = min(p[1] for p in pos); ymax = max(p[1] for p in pos)
    uv = [((COL_U + 0.5) / ATLAS, (V_BOT + (V_TOP - V_BOT) * (p[1] - ymin) / (ymax - ymin)) / ATLAS) for p in pos]

    big = len(pos) > 65535
    blob = b"".join(struct.pack("<3f", *p) for p in pos)
    o_nor = len(blob); blob += b"".join(struct.pack("<3f", *n) for n in nor)
    o_uv = len(blob); blob += b"".join(struct.pack("<2f", *u) for u in uv)
    o_idx = len(blob); blob += b"".join(struct.pack("<I" if big else "<H", i) for i in idx)
    while len(blob) % 4: blob += b"\0"

    out_dir = os.path.dirname(path)
    tex = TEX if os.path.exists(os.path.join(out_dir, TEX)) else TEX_FALLBACK
    mn = [min(p[i] for p in pos) for i in range(3)]; mx = [max(p[i] for p in pos) for i in range(3)]
    n = len(pos)
    gltf = {
        "asset": {"version": "2.0", "generator": "projeto-noite tools/gen_models.py"},
        "scene": 0, "scenes": [{"name": "Scene", "nodes": [0]}],
        "nodes": [{"name": name, "mesh": 0}],
        "meshes": [{"name": name, "primitives": [{"attributes": {"POSITION": 0, "NORMAL": 1, "TEXCOORD_0": 2}, "indices": 3, "material": 0}]}],
        "materials": [{"name": "tiny_treats_1", "pbrMetallicRoughness": {"baseColorTexture": {"index": 0}, "metallicFactor": 0, "roughnessFactor": 0.5}}],
        "textures": [{"sampler": 0, "source": 0}],
        "samplers": [{"magFilter": 9729, "minFilter": 9987}],
        "images": [{"uri": tex}],
        "buffers": [{"uri": name + ".bin", "byteLength": len(blob)}],
        "bufferViews": [
            {"buffer": 0, "byteOffset": 0, "byteLength": o_nor, "target": 34962},
            {"buffer": 0, "byteOffset": o_nor, "byteLength": o_uv - o_nor, "target": 34962},
            {"buffer": 0, "byteOffset": o_uv, "byteLength": o_idx - o_uv, "target": 34962},
            {"buffer": 0, "byteOffset": o_idx, "byteLength": len(idx) * (4 if big else 2), "target": 34963},
        ],
        "accessors": [
            {"bufferView": 0, "componentType": 5126, "count": n, "type": "VEC3", "min": mn, "max": mx},
            {"bufferView": 1, "componentType": 5126, "count": n, "type": "VEC3"},
            {"bufferView": 2, "componentType": 5126, "count": n, "type": "VEC2"},
            {"bufferView": 3, "componentType": 5125 if big else 5123, "count": len(idx), "type": "SCALAR"},
        ],
    }
    os.makedirs(out_dir, exist_ok=True)
    open(os.path.join(out_dir, name + ".bin"), "wb").write(blob)
    json.dump(gltf, open(path, "w"), indent=1)
    print(f"{name}: {n} vértices, {len(idx)//3} triângulos, {mx[0]-mn[0]:.1f} x {mx[1]-mn[1]:.1f} x {mx[2]-mn[2]:.1f} m")


def cloud(seed, length, dome, side_count):
    """Nuvem grande no estilo do pacote: base larga e achatada, cúpula maior no
    meio (ou deslocada) e bolinhas menores nas pontas."""
    rnd = random.Random(seed)
    blobs = []
    # base: fileira de bolas ao longo do comprimento
    for i in range(side_count):
        t = i / (side_count - 1) - 0.5
        r = (1.0 - abs(t) * 1.1) * length * 0.2 + rnd.uniform(-0.2, 0.3)
        blobs.append(((t * length, r * 0.55, rnd.uniform(-0.6, 0.6)), max(r, 0.9)))
    # profundidade: segunda fileira atrás
    for i in range(side_count - 1):
        t = (i + 0.5) / (side_count - 1) - 0.5
        r = (1.0 - abs(t) * 1.2) * length * 0.16 + rnd.uniform(-0.2, 0.2)
        blobs.append(((t * length * 0.9, r * 0.5, rnd.uniform(1.0, 1.8) * rnd.choice((-1, 1))), max(r, 0.8)))
    # cúpula(s)
    for dx, dr in dome:
        r = length * dr
        blobs.append(((dx * length, r * 0.95, rnd.uniform(-0.4, 0.4)), r))
    return blobs


# --- caixas arredondadas (props): mesmo acabamento "vinil" dos kits ---------
# Cada parte é uma caixa com cantos arredondados (raio r), com a cor de uma
# célula da atlas do Tiny Treats e gradiente vertical (claro em cima).
# Células (x central da coluna na atlas 1024): 320 pedra cinza, 448 pedra clara,
# 704 tijolo, 832 madeira escura, 960 madeira clara, 64 fuligem.

def rounded_box(center, half, r, n=6, flat_top=False):
    """Vértices/normais/triângulos de uma caixa arredondada (grade n x n por face).
    flat_top: topo reto, sem arredondar (ex.: chaminé que continua subindo)."""
    pos, nor, tri = [], [], []
    inner = [max(h - r, 0.0) for h in half]
    faces = [(0, 1, 2, 1), (0, 1, 2, -1), (1, 2, 0, 1), (1, 2, 0, -1), (2, 0, 1, 1), (2, 0, 1, -1)]
    for a, b, c, sgn in faces:
        base = len(pos)
        for i in range(n + 1):
            for j in range(n + 1):
                q = [0.0, 0.0, 0.0]
                q[c] = sgn * half[c]
                q[a] = (i / n * 2 - 1) * half[a]
                q[b] = (j / n * 2 - 1) * half[b]
                top = [inner[0], half[1] if flat_top else inner[1], inner[2]]
                cl = [max(-inner[k], min(top[k], q[k])) for k in range(3)]
                d = [q[k] - cl[k] for k in range(3)]
                l = math.sqrt(sum(x * x for x in d))
                if l < 1e-9:  # dentro do topo reto: o ponto já está na superfície
                    nn = [0.0, 0.0, 0.0]; nn[c] = float(sgn)
                    pos.append(tuple(center[k] + q[k] for k in range(3)))
                else:
                    nn = [x / l for x in d]
                    pos.append(tuple(center[k] + cl[k] + nn[k] * r for k in range(3)))
                nor.append(tuple(nn))
        for i in range(n):
            for j in range(n):
                v0 = base + i * (n + 1) + j; v1 = v0 + 1; v2 = v0 + n + 1; v3 = v2 + 1
                tri += [(v0, v2, v1), (v1, v2, v3)]  # orientação corrigida em write_parts
    return pos, nor, tri


def write_parts(path, name, parts):
    """parts: [(centro, meia-dimensão, raio, coluna_atlas[, topo_reto])] -> um glTF só."""
    pos, nor, uv, idx = [], [], [], []
    for part in parts:
        center, half, r, col = part[:4]
        p, nn, t = rounded_box(center, half, r, flat_top=len(part) > 4 and part[4])
        y0 = center[1] - half[1]; y1 = center[1] + half[1]
        base = len(pos)
        for v in p:
            k = (v[1] - y0) / (y1 - y0) if y1 > y0 else 1.0
            uv.append(((col + 0.5) / ATLAS, (V_BOT + (V_TOP - V_BOT) * k) / ATLAS))
        pos += p; nor += nn
        # garante a face pra fora: compara a normal do triângulo com a do vértice
        for a, b, c in t:
            A, B, C = p[a], p[b], p[c]
            fn = ((B[1]-A[1])*(C[2]-A[2])-(B[2]-A[2])*(C[1]-A[1]), (B[2]-A[2])*(C[0]-A[0])-(B[0]-A[0])*(C[2]-A[2]), (B[0]-A[0])*(C[1]-A[1])-(B[1]-A[1])*(C[0]-A[0]))
            if sum(fn[i] * nn[a][i] for i in range(3)) < 0:
                b, c = c, b
            idx += [base + a, base + b, base + c]
    blob = b"".join(struct.pack("<3f", *v) for v in pos)
    o_nor = len(blob); blob += b"".join(struct.pack("<3f", *v) for v in nor)
    o_uv = len(blob); blob += b"".join(struct.pack("<2f", *v) for v in uv)
    o_idx = len(blob); blob += b"".join(struct.pack("<I", i) for i in idx)
    out_dir = os.path.dirname(path)
    tex = TEX if os.path.exists(os.path.join(out_dir, TEX)) else TEX_FALLBACK
    mn = [min(v[i] for v in pos) for i in range(3)]; mx = [max(v[i] for v in pos) for i in range(3)]
    n = len(pos)
    gltf = {
        "asset": {"version": "2.0", "generator": "projeto-noite tools/gen_models.py"},
        "scene": 0, "scenes": [{"name": "Scene", "nodes": [0]}],
        "nodes": [{"name": name, "mesh": 0}],
        "meshes": [{"name": name, "primitives": [{"attributes": {"POSITION": 0, "NORMAL": 1, "TEXCOORD_0": 2}, "indices": 3, "material": 0}]}],
        "materials": [{"name": "tiny_treats_1", "pbrMetallicRoughness": {"baseColorTexture": {"index": 0}, "metallicFactor": 0, "roughnessFactor": 0.5}}],
        "textures": [{"sampler": 0, "source": 0}],
        "samplers": [{"magFilter": 9729, "minFilter": 9987}],
        "images": [{"uri": tex}],
        "buffers": [{"uri": name + ".bin", "byteLength": len(blob)}],
        "bufferViews": [
            {"buffer": 0, "byteOffset": 0, "byteLength": o_nor, "target": 34962},
            {"buffer": 0, "byteOffset": o_nor, "byteLength": o_uv - o_nor, "target": 34962},
            {"buffer": 0, "byteOffset": o_uv, "byteLength": o_idx - o_uv, "target": 34962},
            {"buffer": 0, "byteOffset": o_idx, "byteLength": len(idx) * 4, "target": 34963},
        ],
        "accessors": [
            {"bufferView": 0, "componentType": 5126, "count": n, "type": "VEC3", "min": mn, "max": mx},
            {"bufferView": 1, "componentType": 5126, "count": n, "type": "VEC3"},
            {"bufferView": 2, "componentType": 5126, "count": n, "type": "VEC2"},
            {"bufferView": 3, "componentType": 5125, "count": len(idx), "type": "SCALAR"},
        ],
    }
    os.makedirs(out_dir, exist_ok=True)
    open(os.path.join(out_dir, name + ".bin"), "wb").write(blob)
    json.dump(gltf, open(path, "w"), indent=1)
    print(f"{name}: {n} vértices, {len(idx)//3} triângulos, {mx[0]-mn[0]:.1f} x {mx[1]-mn[1]:.1f} x {mx[2]-mn[2]:.1f} m")


STONE, STONE_LIGHT, BRICK, WOOD_DARK, WOOD, SOOT = 320, 448, 704, 832, 960, 64

FIREPLACE = [  # (centro, meia-dimensão, raio, cor) — frente em +Z, base no chão
    ((0.0, 0.12, 0.15), (1.45, 0.12, 0.75), 0.08, STONE),        # base (soleira)
    ((-0.9, 1.0, 0.0), (0.32, 0.82, 0.45), 0.14, STONE_LIGHT),   # pilar esquerdo
    ((0.9, 1.0, 0.0), (0.32, 0.82, 0.45), 0.14, STONE_LIGHT),    # pilar direito
    ((0.0, 1.95, 0.0), (1.25, 0.22, 0.46), 0.14, STONE_LIGHT),   # viga de pedra
    ((0.0, 2.27, 0.06), (1.5, 0.09, 0.56), 0.07, WOOD),          # prateleira de madeira
    ((0.0, 3.18, -0.12), (0.9, 0.82, 0.36), 0.14, BRICK, True),  # chaminé de tijolo: sobe até o teto (4 m), topo reto
    ((0.0, 0.95, -0.38), (0.62, 0.75, 0.06), 0.03, SOOT),        # fundo com fuligem
    ((0.0, 0.95, -0.44), (0.62, 0.75, 0.02), 0.02, STONE),       # costas de pedra (de trás não aparece a fuligem)
    ((0.0, 0.33, 0.02), (0.45, 0.1, 0.1), 0.09, WOOD_DARK),      # tora de baixo
    ((0.1, 0.48, 0.12), (0.38, 0.09, 0.09), 0.08, WOOD_DARK),    # tora de cima
]


# --- tufos de grama densa -----------------------------------------------------
# Folhas finas afinando na ponta, agrupadas num tufo. Cor da coluna verde da
# atlas (x≈192, linhas 270–470: claro na ponta, escuro na base). Cada folha tem
# os dois lados (o shader de vento descarta faces de trás).

GRASS_COL, GRASS_V_TOP, GRASS_V_BOT = 192, 270, 470


def grass_tuft(path, name, seed, blades, radius, h_min, h_max):
    rnd = random.Random(seed)
    pos, nor, uv, idx = [], [], [], []
    for _ in range(blades):
        a = rnd.uniform(0, math.tau); d = radius * math.sqrt(rnd.random())
        bx, bz = math.cos(a) * d, math.sin(a) * d
        h = rnd.uniform(h_min, h_max); w = rnd.uniform(0.025, 0.04)
        yaw = rnd.uniform(0, math.tau)
        lean = rnd.uniform(0.05, 0.18)  # inclina pra fora do centro do tufo
        lx, lz = (math.cos(a) * lean, math.sin(a) * lean) if d > 1e-6 else (0.0, 0.0)
        side = (math.cos(yaw), math.sin(yaw))
        # base (2), meio (2), ponta (1)
        pts = [(-w, 0.0), (w, 0.0), (-w * 0.6, 0.55), (w * 0.6, 0.55), (0.0, 1.0)]
        verts = []
        for sx, t in pts:
            verts.append((bx + side[0] * sx + lx * t * t, h * t, bz + side[1] * sx + lz * t * t))
        tris = [(0, 1, 2), (1, 3, 2), (2, 3, 4)]
        for face in (1, -1):
            base = len(pos)
            for (vx, vy, vz), (_, t) in zip(verts, pts):
                pos.append((vx, vy, vz))
                # normal quase pra cima: sombreamento suave de grama estilizada
                n = (-side[1] * 0.35 * face, 0.9, side[0] * 0.35 * face)
                l = math.sqrt(sum(c * c for c in n)); nor.append(tuple(c / l for c in n))
                uv.append(((GRASS_COL + 0.5) / ATLAS, (GRASS_V_BOT + (GRASS_V_TOP - GRASS_V_BOT) * t) / ATLAS))
            for a_, b_, c_ in tris:
                idx += [base + a_, base + b_, base + c_] if face == 1 else [base + a_, base + c_, base + b_]
    _save_mesh(path, name, pos, nor, uv, idx)


def _save_mesh(path, name, pos, nor, uv, idx, tex=None):
    blob = b"".join(struct.pack("<3f", *v) for v in pos)
    o_nor = len(blob); blob += b"".join(struct.pack("<3f", *v) for v in nor)
    o_uv = len(blob); blob += b"".join(struct.pack("<2f", *v) for v in uv)
    o_idx = len(blob); blob += b"".join(struct.pack("<I", i) for i in idx)
    out_dir = os.path.dirname(path)
    if tex is None:
        tex = TEX if os.path.exists(os.path.join(out_dir, TEX)) else TEX_FALLBACK
    mn = [min(v[i] for v in pos) for i in range(3)]; mx = [max(v[i] for v in pos) for i in range(3)]
    n = len(pos)
    gltf = {
        "asset": {"version": "2.0", "generator": "projeto-noite tools/gen_models.py"},
        "scene": 0, "scenes": [{"name": "Scene", "nodes": [0]}],
        "nodes": [{"name": name, "mesh": 0}],
        "meshes": [{"name": name, "primitives": [{"attributes": {"POSITION": 0, "NORMAL": 1, "TEXCOORD_0": 2}, "indices": 3, "material": 0}]}],
        "materials": [{"name": "atlas", "pbrMetallicRoughness": {"baseColorTexture": {"index": 0}, "metallicFactor": 0, "roughnessFactor": 0.5}}],
        "textures": [{"sampler": 0, "source": 0}],
        "samplers": [{"magFilter": 9729, "minFilter": 9987}],
        "images": [{"uri": tex}],
        "buffers": [{"uri": name + ".bin", "byteLength": len(blob)}],
        "bufferViews": [
            {"buffer": 0, "byteOffset": 0, "byteLength": o_nor, "target": 34962},
            {"buffer": 0, "byteOffset": o_nor, "byteLength": o_uv - o_nor, "target": 34962},
            {"buffer": 0, "byteOffset": o_uv, "byteLength": o_idx - o_uv, "target": 34962},
            {"buffer": 0, "byteOffset": o_idx, "byteLength": len(idx) * 4, "target": 34963},
        ],
        "accessors": [
            {"bufferView": 0, "componentType": 5126, "count": n, "type": "VEC3", "min": mn, "max": mx},
            {"bufferView": 1, "componentType": 5126, "count": n, "type": "VEC3"},
            {"bufferView": 2, "componentType": 5126, "count": n, "type": "VEC2"},
            {"bufferView": 3, "componentType": 5125, "count": len(idx), "type": "SCALAR"},
        ],
    }
    os.makedirs(out_dir, exist_ok=True)
    open(os.path.join(out_dir, name + ".bin"), "wb").write(blob)
    json.dump(gltf, open(path, "w"), indent=1)
    print(f"{name}: {n} vértices, {len(idx)//3} triângulos, {mx[0]-mn[0]:.2f} x {mx[1]-mn[1]:.2f} x {mx[2]-mn[2]:.2f} m")


# --- transição madeira -> pedra ------------------------------------------------
# Placas de pedra achatadas (caixas arredondadas finas) espalhadas por cima do
# piso de madeira, com densidade em degradê: cheio no lado -Z (encosta no piso de
# pedra) e sumindo até o lado +Z (só madeira). Cor da pedra do KayKit Dungeon
# (coluna x=642 da dungeon_texture, linhas 102 claro -> 162 escuro).

DUNGEON_TEX = "../../dungeon/dungeon_texture.png"
STONE_COL, STONE_V_TOP, STONE_V_BOT = 642, 102, 162


def stone_blend(path, name, seed, corner=False):
    """Tile 2x2 m. corner=True: degradê na diagonal (pedra no canto -X/-Z)."""
    rnd = random.Random(seed)
    pos, nor, uv, idx = [], [], [], []
    placed = []
    for _ in range(4000):
        x = rnd.uniform(-1.0, 1.0); z = rnd.uniform(-1.0, 1.0)
        t = ((z + 1) / 2) if not corner else min(1.0, ((x + 1) / 2 + (z + 1) / 2) / 1.4)
        if rnd.random() > (1 - t) ** 2.2:          # 1 no lado da pedra, 0 no da madeira
            continue
        w = rnd.uniform(0.09, 0.18) * (1.25 - 0.6 * t); d = w * rnd.uniform(0.65, 1.0)
        # dentro do tile, mas pode encostar/passar um pouco no lado da pedra (lá o piso de pedra cobre)
        x = max((-1.05 if corner else -1 + w), min(1 - w, x)); z = max(-1.05, min(1 - w, z))
        if any(math.hypot(x - a, z - b) < (w + r) * 0.92 for a, b, r in placed):
            continue
        placed.append((x, z, w))
        h = rnd.uniform(0.022, 0.03)
        p, nn, tris = rounded_box((0.0, 0.0, 0.0), (w, h, d), min(0.03, h * 0.95))
        ang = rnd.uniform(-0.3, 0.3); c, sn = math.cos(ang), math.sin(ang)  # quase alinhadas, como pedras assentadas
        shade = rnd.uniform(0.0, 0.35)              # variação de tom entre placas
        base = len(pos)
        for (vx, vy, vz), (nx, ny, nz) in zip(p, nn):
            pos.append((x + vx * c - vz * sn, vy + h, z + vx * sn + vz * c))
            nor.append((nx * c - nz * sn, ny, nx * sn + nz * c))
            k = shade + (1 - shade) * (1 - (vy + h) / (2 * h))
            uv.append(((STONE_COL + 0.5) / ATLAS, (STONE_V_TOP + (STONE_V_BOT - STONE_V_TOP) * k) / ATLAS))
        for a, b, c_ in tris:
            A, B, C = pos[base + a], pos[base + b], pos[base + c_]
            fn = ((B[1]-A[1])*(C[2]-A[2])-(B[2]-A[2])*(C[1]-A[1]), (B[2]-A[2])*(C[0]-A[0])-(B[0]-A[0])*(C[2]-A[2]), (B[0]-A[0])*(C[1]-A[1])-(B[1]-A[1])*(C[0]-A[0]))
            if sum(fn[i] * nor[base + a][i] for i in range(3)) < 0:
                b, c_ = c_, b
            idx += [base + a, base + b, base + c_]
    _save_mesh(path, name, pos, nor, uv, idx, DUNGEON_TEX)


# --- tapete medieval vermelho ----------------------------------------------------
# Peças achatadas (caixas arredondadas finas) empilhadas: base vermelha, faixa
# dourada, miolo vermelho, losango dourado no centro e franjas nas pontas. Cores
# da dungeon_texture (as do estandarte): vermelho x=448, dourado x=704.
# Peça: (centro, meia-dimensão, cor_x, linha_v, ângulo_y). Tamanho 5 x 3 m.

RED, GOLD = 448, 704
RUG = [
    ((0.0, 0.0, 0.0), (2.5, 0.012, 1.5), RED, 740, 0.0),        # base (vermelho escuro)
    ((0.0, 0.012, 0.0), (2.32, 0.012, 1.32), GOLD, 600, 0.0),   # faixa dourada
    ((0.0, 0.024, 0.0), (2.2, 0.012, 1.2), RED, 650, 0.0),      # miolo vermelho
    ((0.0, 0.036, 0.0), (0.62, 0.012, 0.62), GOLD, 600, math.pi / 4),  # losango dourado
    ((0.0, 0.048, 0.0), (0.44, 0.012, 0.44), RED, 740, math.pi / 4),   # losango interno
    ((0.0, 0.06, 0.0), (0.14, 0.012, 0.14), GOLD, 580, math.pi / 4),   # miolo do emblema
    ((-1.75, 0.036, 0.0), (0.16, 0.012, 0.16), GOLD, 600, math.pi / 4),  # losangos laterais
    ((1.75, 0.036, 0.0), (0.16, 0.012, 0.16), GOLD, 600, math.pi / 4),
] + [  # franjas douradas nas pontas curtas
    ((sx * 2.58, 0.0, z * 0.25), (0.08, 0.008, 0.07), GOLD, 680, 0.0)
    for sx in (-1, 1) for z in range(-5, 6)
]


def rug(path, name, parts):
    pos, nor, uv, idx = [], [], [], []
    for (cx, cy, cz), half, col, v, ang in parts:
        p, nn, tris = rounded_box((0.0, 0.0, 0.0), half, min(0.03, half[1] * 0.95))
        c, sn = math.cos(ang), math.sin(ang)
        base = len(pos)
        for (vx, vy, vz), (nx, ny, nz) in zip(p, nn):
            pos.append((cx + vx * c - vz * sn, cy + vy + half[1], cz + vx * sn + vz * c))
            nor.append((nx * c - nz * sn, ny, nx * sn + nz * c))
            uv.append(((col + 0.5) / ATLAS, (v + 0.5) / ATLAS))
        for a, b, c_ in tris:
            A, B, C = pos[base + a], pos[base + b], pos[base + c_]
            fn = ((B[1]-A[1])*(C[2]-A[2])-(B[2]-A[2])*(C[1]-A[1]), (B[2]-A[2])*(C[0]-A[0])-(B[0]-A[0])*(C[2]-A[2]), (B[0]-A[0])*(C[1]-A[1])-(B[1]-A[1])*(C[0]-A[0]))
            if sum(fn[i] * nor[base + a][i] for i in range(3)) < 0:
                b, c_ = c_, b
            idx += [base + a, base + b, base + c_]
    _save_mesh(path, name, pos, nor, uv, idx, DUNGEON_TEX)


if __name__ == "__main__":
    write_gltf(os.path.join(ROOT, "smoke", "smoke_puff.gltf"), "smoke_puff", [
        ((0.00, 0.26, 0.00), 0.26),
        ((-0.22, 0.18, 0.06), 0.18),
        ((0.22, 0.17, -0.04), 0.19),
        ((0.04, 0.42, 0.03), 0.17),
        ((-0.05, 0.16, -0.20), 0.15),
    ], subdiv=1)
    # nuvens: (seed, comprimento, cúpulas [(posição x relativa, raio relativo)], bolas na base)
    shapes = {
        "cloud_a": (1, 12.0, [(0.0, 0.2)], 6),                 # cúpula central
        "cloud_b": (2, 14.0, [(0.18, 0.21), (-0.2, 0.13)], 7), # cúpula deslocada + menor
        "cloud_c": (3, 8.0, [(-0.05, 0.24)], 4),               # pequena e alta
        "cloud_d": (4, 13.0, [(-0.12, 0.17), (0.15, 0.15)], 6),# dois montes
    }
    for name, (seed, length, dome, n) in shapes.items():
        write_gltf(os.path.join(ROOT, "clouds", name + ".gltf"), name,
                   cloud(seed, length, dome, n), subdiv=2, squash_bottom=0.6)
    write_parts(os.path.join(ROOT, "props", "fireplace.gltf"), "fireplace", FIREPLACE)
    grass_tuft(os.path.join(ROOT, "grass", "grass_tuft_A.gltf"), "grass_tuft_A", 21, 30, 0.16, 0.24, 0.4)
    grass_tuft(os.path.join(ROOT, "grass", "grass_tuft_B.gltf"), "grass_tuft_B", 22, 20, 0.12, 0.2, 0.32)
    stone_blend(os.path.join(ROOT, "props", "floor_stone_blend.gltf"), "floor_stone_blend", 31)
    stone_blend(os.path.join(ROOT, "props", "floor_stone_blend_corner.gltf"), "floor_stone_blend_corner", 32, corner=True)
    rug(os.path.join(ROOT, "props", "rug_medieval_red.gltf"), "rug_medieval_red", RUG)
