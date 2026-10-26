"""Gera as malhas das flores pro pincel do Terrain3D (assets/models/flowers/):
flower_head_low.gltf  — carta DEITADA das flores rente ao chão (branca), y = 0,03
flower_head_high.gltf — carta deitada no topo dos caules, y = 0,72 (HEAD)
flower_stems.gltf     — duas cartas cruzadas em pé (caules), base em y = 0
Cada tipo de flor usa a carta de cabeça + (se tiver caule) a de caules, com os
materiais assets/materials/flowers/*.tres (textura do tipo nos shaders
flower_card / flower_stem). Normal pra cima; UV.y = 1 embaixo.
Uso: python tools/gen_flower_meshes.py
"""
import math, os, sys

sys.path.insert(0, os.path.dirname(__file__))
from gen_grass_tufts import write_gltf  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "models", "flowers")
HEAD = 0.72      # igual ao HEAD do gen_flower_textures.py
GROUND = 0.03
TOP_SIZE = 0.8


def quads(qs, uvs):
    pos, nor, uv, col, edge = [], [], [], [], []
    for q in qs:
        for i in (0, 1, 2, 0, 2, 3):
            pos.append(q[i]); nor.append((0.0, 1.0, 0.0)); uv.append(uvs[i])
            col.append((1.0, 1.0, 1.0, 1.0)); edge.append((0.0, 0.0))
    return pos, nor, uv, col, edge


def flat(y):
    h = TOP_SIZE / 2
    return quads([[(-h, y, -h), (h, y, -h), (h, y, h), (-h, y, h)]], [(0, 0), (1, 0), (1, 1), (0, 1)])


def cross():
    qs = []
    for ang in (0.0, math.pi / 2):
        dx = (math.cos(ang) * 0.5, 0.0, math.sin(ang) * 0.5)
        qs.append([(-dx[0], 0.0, -dx[2]), (dx[0], 0.0, dx[2]), (dx[0], 1.0, dx[2]), (-dx[0], 1.0, dx[2])])
    return quads(qs, [(0, 1), (1, 1), (1, 0), (0, 0)])


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for name, data in (("flower_head_low", flat(GROUND)), ("flower_head_high", flat(HEAD)), ("flower_stems", cross())):
        path = os.path.join(OUT, name + ".gltf")
        write_gltf(path, name, *data)
        print("ok:", os.path.abspath(path))
