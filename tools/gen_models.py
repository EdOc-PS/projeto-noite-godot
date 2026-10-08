"""Gera os modelos feitos no projeto em assets/models/custom/, no padrão dos kits
Tiny Treats: low poly arredondado (icosferas com normais suaves), cor vinda da
atlas do Tiny Treats (gradiente vertical: claro em cima), roughness 0.5 /
metallic 0, glTF.

  smoke/smoke_puff.gltf         fumaça da chaminé (~0,8 m)
  clouds/cloud_a..d.gltf        nuvens grandes (8–14 m), base achatada,
                                formas inspiradas no pacote Low Poly Clouds

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
