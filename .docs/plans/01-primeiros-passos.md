# Plano 01 — Primeiros Passos

Referência: [.docs/INIT-PROJETO-NOITE.md](../INIT-PROJETO-NOITE.md)

Objetivo: sair do zero até ter um personagem andando numa cena de cidade fixa, com câmera isométrica seguindo, na engine Godot 4 / GDScript.

## Escopo

1. Estrutura de pastas do projeto
2. Cena da cidade (bloco de teste, sem arte final)
3. Câmera isométrica (Camera3D ortogonal, ângulo 30–45°, seguindo o personagem)
4. Personagem básico (CharacterBody3D) com movimentação (input 2D → movimento no plano XZ)

Fora de escopo aqui: dungeons, NPCs, progressão, cutscenes, arte final, iluminação baked.

## 1. Estrutura de pastas

```
projeto-noite/
├── .docs/
│   ├── INIT-PROJETO-NOITE.md
│   └── plans/
├── project.godot
├── scenes/
│   ├── city/
│   │   └── city.tscn
│   ├── player/
│   │   └── player.tscn
│   └── main.tscn          # cena inicial que carrega city + player
├── scripts/
│   ├── player/
│   │   └── player.gd
│   └── camera/
│       └── isometric_camera.gd
├── assets/
│   ├── models/
│   └── textures/
└── autoload/
    └── game_state.gd       # placeholder para persistência dia/noite (futuro)
```

## 2. Cena da cidade (placeholder)

- `scenes/city/city.tscn`: `Node3D` raiz
  - Chão: `MeshInstance3D` (PlaneMesh) + `StaticBody3D`/`CollisionShape3D`
  - Alguns blocos (`CSGBox3D` ou `MeshInstance3D` com `BoxMesh`) só para ter obstáculos e testar colisão
  - Sem lightmap ainda — usar `WorldEnvironment` com luz ambiente simples + `DirectionalLight3D` básica

## 3. Câmera isométrica

- `scripts/camera/isometric_camera.gd` anexado a um `Camera3D` dentro de um `Node3D` "rig"
- `Camera3D.projection = ORTHOGONAL`, `size` ajustável (ex.: 10)
- Rotação fixa: rotacionar o rig em Y (~45°) e a câmera em X (~-30 a -35°) para o ângulo isométrico
- Seguimento: rig com posição = `player.global_position + offset`, suavizado com `lerp`/`move_toward` no `_process`ou `_physics_process`
- Offset fixo (constante), sem rotação livre de câmera (estilo Zelda/diorama)

## 4. Personagem básico

- `scenes/player/player.tscn`: `CharacterBody3D`
  - `CollisionShape3D` (capsule)
  - `MeshInstance3D` placeholder (capsule ou box)
- `scripts/player/player.gd`:
  - Ler input (`Input.get_vector` com ações ui_left/right/up/down ou ações customizadas `move_*`)
  - Converter input 2D em direção no plano XZ (considerando a orientação isométrica, não a orientação world pura)
  - Aplicar `velocity` e `move_and_slide()`
  - Sem gravidade complexa por enquanto (chão plano); pode manter `gravity` simples do template padrão do Godot

## 5. Integração

- `scenes/main.tscn`: instancia `city.tscn` + `player.tscn` + camera rig
- Definir `main.tscn` como cena principal (`project.godot` → Run/Main Scene)
- Configurar Input Map (`move_left`, `move_right`, `move_up`, `move_down`) no `project.godot`

## Critério de conclusão

- Abrir o projeto no Godot, rodar a cena principal
- Personagem se move em 4/8 direções coerente com a visão isométrica
- Câmera acompanha suavemente sem clipping estranho
- Colide com os blocos de teste do chão da cidade

## Próximos planos (não incluídos aqui)

- Sistema de salas para dungeons (Noite)
- Transição Dia/Noite + `GameState` autoload real
- NPCs e progressão na cidade
