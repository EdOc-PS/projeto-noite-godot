"""Gera scenes/city/city.tscn: ruas da cidade (rascunho pra trabalhar o clima).
Kit KayKit City Builder Bits (tile de 2 m, escalado 4x pra ficar na proporção
do personagem). Rua principal no eixo Z cruzando uma rua lateral no X, prédios
dos dois lados virados pra rua, postes com luz, carros, hidrantes e bancos.
Céu, névoa e lua iguais ao outside (noite); colisão de prédios e bordas.
Rodar: python tools/gen_city.py  (sobrescreve a cena)
"""
import math, os, random

OUT = os.path.join(os.path.dirname(__file__), "..", "scenes", "city", "city.tscn")
S = 4.0  # escala do kit
R90 = math.pi / 2
rnd = random.Random(3)
ext = {}
nodes = []


def res(path):
    rid = os.path.splitext(os.path.basename(path))[0]
    ext[rid] = path
    return rid


def T(x, y, z, ang=0.0, s=1.0):
    c, sn = math.cos(ang), math.sin(ang)
    return "Transform3D(%g, 0, %g, 0, %g, 0, %g, 0, %g, %g, %g, %g)" % (c * s, sn * s, s, -sn * s, c * s, x, y, z)


def inst(name, parent, model, x, z, ang=0.0):
    rid = res("res://assets/models/city/%s.gltf" % model)
    nodes.append('[node name="%s" parent="%s" instance=ExtResource("%s")]\ntransform = %s' % (name, parent, rid, T(x, 0, z, ang)))


nodes.append('[node name="City" type="Node3D" parent="."]\ntransform = Transform3D(%g, 0, 0, 0, %g, 0, 0, 0, %g, 0, 0, 0)' % (S, S, S))
for g in ("Roads", "Buildings", "Props"):
    nodes.append('[node name="%s" type="Node3D" parent="City"]' % g)

# ruas: principal no Z (road_straight já corre no Z), lateral no X (girada)
i = 0
for z in range(-10, 11, 2):
    m = "road_junction" if z == 0 else ("road_straight_crossing" if z in (-6, 6) else "road_straight")
    inst("Road_%d" % i, "City/Roads", m, 0, z); i += 1
for x in (-8, -6, -4, -2, 2, 4, 6, 8):
    inst("Road_%d" % i, "City/Roads", "road_straight", x, 0, R90); i += 1

# prédios virados pra rua (frente do modelo em +Z)
HEIGHT = {"A": 1.65, "B": 1.65, "C": 2.98, "D": 2.97, "E": 2.35, "F": 2.35, "G": 2.98, "H": 3.05}
occ, boxes, b = set(), [], 0
def bld(x, z, ang):
    global b
    letter = rnd.choice("ABCDEFGH")
    inst("Building_%d" % b, "City/Buildings", "building_" + letter, x, z, ang); b += 1
    h = HEIGHT[letter]
    boxes.append((x * S, h * S / 2, z * S, 2 * S * 0.92, h * S, 2 * S * 0.92)); occ.add((x, z))
for z in range(-10, 11, 2):
    if z != 0:
        bld(2, z, -R90); bld(-2, z, R90)
for x in (4, 6, 8, -4, -6, -8):
    bld(x, -2, 0.0); bld(x, 2, math.pi)

# calçada (base) no resto, fechando o quarteirão
k = 0
for x in range(-10, 11, 2):
    for z in range(-12, 13, 2):
        if x == 0 or (z == 0 and abs(x) <= 8) or (x, z) in occ:
            continue
        inst("Base_%d" % k, "City/Roads", "base", x, z); k += 1

# postes (luz é filha do poste, na ponta do braço), carros, hidrantes, bancos
lights = []
for j, z in enumerate((-9, -5, -1, 3, 7)):
    for side in (-1, 1):
        name = "Streetlight_%d_%s" % (j, "L" if side < 0 else "R")
        inst(name, "City/Props", "streetlight", side * 0.85, z, R90 if side < 0 else -R90)
        lights.append(name)
cars = ["car_sedan", "car_taxi", "car_hatchback", "car_stationwagon", "car_police"]
for j, (x, z, a) in enumerate([(0.5, -7, 0), (-0.5, 4.3, math.pi), (0.5, 8.5, 0), (-0.5, -3.5, math.pi), (5, 0.5, R90)]):
    inst("Car_%d" % j, "City/Props", cars[j % len(cars)], x, z, a)
for j, (x, z) in enumerate([(0.85, -3), (-0.85, 5), (3, 0.85), (-5, -0.85)]):
    inst("Hydrant_%d" % j, "City/Props", "firehydrant", x, z)
for j, (x, z) in enumerate([(0.85, 1.6), (-0.85, -6.5), (6.5, -0.85)]):
    inst("Bench_%d" % j, "City/Props", "bench", x, z, -R90 if x > 0 else R90)
ext["lantern_pulse"] = "res://scripts/environment/lantern_pulse.gd"
for name in lights:
    nodes.append('[node name="Light" type="OmniLight3D" parent="City/Props/%s"]\n'
                 'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -0.2, 0.9, 0)\n'
                 'light_color = Color(1, 0.62, 0.25, 1)\nlight_energy = 2.0\nomni_range = 2.2\n'
                 'script = ExtResource("lantern_pulse")\nbase_energy = 2.0\nflicker_amount = 0.15\npulse_amount = 0.25' % name)

# colisão: chão, prédios e bordas invisíveis
subs = ['[sub_resource type="BoxShape3D" id="GroundShape"]\nsize = Vector3(%g, 1, %g)' % (22 * S, 26 * S)]
col = ['[node name="Collision" type="StaticBody3D" parent="."]',
       '[node name="Ground" type="CollisionShape3D" parent="Collision"]\ntransform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, -0.5, 0)\nshape = SubResource("GroundShape")']
for n, (x, y, z, sx, sy, sz) in enumerate(boxes):
    subs.append('[sub_resource type="BoxShape3D" id="B%d"]\nsize = Vector3(%g, %g, %g)' % (n, sx, sy, sz))
    col.append('[node name="Building_%d" type="CollisionShape3D" parent="Collision"]\ntransform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %g, %g, %g)\nshape = SubResource("B%d")' % (n, x, y, z, n))
for n, (x, z, sx, sz) in enumerate([(0, -11 * S, 4 * S, 1), (0, 11 * S, 4 * S, 1), (-9 * S, 0, 1, 4 * S), (9 * S, 0, 1, 4 * S)]):
    subs.append('[sub_resource type="BoxShape3D" id="Bound%d"]\nsize = Vector3(%g, 6, %g)' % (n, sx, sz))
    col.append('[node name="Bound_%d" type="CollisionShape3D" parent="Collision"]\ntransform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %g, 3, %g)\nshape = SubResource("Bound%d")' % (n, x, z, n))

head = ["[gd_scene format=3]", ""]
for rid, p in ext.items():
    head.append('[ext_resource type="%s" path="%s" id="%s"]' % ("Script" if p.endswith(".gd") else "PackedScene", p, rid))
for t, p, rid in [("PackedScene", "res://scenes/player/player.tscn", "player"),
                  ("Script", "res://scripts/camera/isometric_camera.gd", "camera_script"),
                  ("PackedScene", "res://scenes/effects/tilt_shift.tscn", "tilt_shift"),
                  ("PackedScene", "res://scenes/ui/interaction_prompt.tscn", "interaction_prompt"),
                  ("Script", "res://scripts/world/scene_exit.gd", "scene_exit"),
                  ("Texture2D", "res://assets/skyboxes/space/skybox-space-nebula.png", "sky_tex")]:
    head.append('[ext_resource type="%s" path="%s" id="%s"]' % (t, p, rid))

ENV = """[sub_resource type="PanoramaSkyMaterial" id="NightSkyMaterial"]
panorama = ExtResource("sky_tex")
energy_multiplier = 0.6

[sub_resource type="Sky" id="NightSky"]
sky_material = SubResource("NightSkyMaterial")

[sub_resource type="Environment" id="Env"]
background_mode = 2
sky = SubResource("NightSky")
ambient_light_source = 3
ambient_light_color = Color(0.4, 0.44, 0.65, 1)
ambient_light_energy = 0.45
tonemap_mode = 4
ssao_enabled = true
ssao_radius = 2.0
ssao_intensity = 2.0
glow_enabled = true
glow_intensity = 0.6
glow_blend_mode = 2
fog_enabled = true
fog_light_color = Color(0.106, 0.137, 0.251, 1)
fog_density = 0.008
fog_height = 1.2
fog_height_density = 0.45
adjustment_enabled = true
adjustment_contrast = 1.12
adjustment_saturation = 1.3"""

TAIL = """[node name="WorldEnvironment" type="WorldEnvironment" parent="."]
environment = SubResource("Env")

[node name="Moon" type="DirectionalLight3D" parent="."]
transform = Transform3D(0.8, -0.35, 0.48, 0, 0.8, 0.6, -0.6, -0.48, 0.64, 0, 8, 0)
light_color = Color(0.62352943, 0.7058824, 1, 1)
light_energy = 0.8
shadow_enabled = true
shadow_opacity = 0.9
shadow_blur = 1.0
directional_shadow_max_distance = 45.0

[node name="Arrival" type="Marker3D" parent="." groups=["spawn_point"]]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 30)

[node name="ReturnPrompt" parent="." instance=ExtResource("interaction_prompt")]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.2, 34)
action_radius = 1.5

[node name="ReturnExit" type="Node" parent="."]
script = ExtResource("scene_exit")
prompt_path = NodePath("../ReturnPrompt")
target_scene = "res://scenes/calm_place/inside_house/inside_house.tscn"
spawn_id = &"GameplayDoorArrival"

[node name="Player" parent="." instance=ExtResource("player")]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 30)

[node name="CameraRig" type="Node3D" parent="."]
script = ExtResource("camera_script")
target_path = NodePath("../Player")
camera_distance = 40.0
pitch_degrees = 45.0
yaw_degrees = -17.0
size_near_player = 9.0

[node name="Camera3D" type="Camera3D" parent="CameraRig"]
projection = 1
current = true
size = 9.0
far = 200.0

[node name="TiltShift" parent="." instance=ExtResource("tilt_shift")]"""

txt = "\n".join(head) + "\n\n" + "\n\n".join(subs) + "\n\n" + ENV + "\n\n" + '[node name="CityStreets" type="Node3D"]' \
    + "\n\n" + "\n\n".join(nodes) + "\n\n" + "\n\n".join(col) + "\n\n" + TAIL + "\n"
os.makedirs(os.path.dirname(OUT), exist_ok=True)
open(OUT, "w", encoding="utf-8").write(txt)
print("ok: %d prédios, %d calçadas" % (b, k))
