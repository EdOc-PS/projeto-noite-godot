# NightProject

## Visão Geral

Jogo 3D isométrico com estética **Stylized Toy Aesthetic / Diorama 3D**, inspirado visualmente em *The Legend of Zelda: Link's Awakening* (remake Nintendo Switch).

Loop de jogo dividido em duas partes:

- **Dia (Cidade)**: mapa fixo, desenhado à mão, onde o jogador explora e realiza atividades que fortalecem o personagem (progressão, itens, upgrades) para as runs noturnas.
- **Noite (Dungeons)**: o personagem é transportado para um mundo separado com dungeons proceduralmente montadas — estilo **Zelda misturado com Hades**.

## Motor e Linguagem

- **Engine**: Godot 4
- **Linguagem**: GDScript (não usar C#)

## Direção de Arte

- **Modelagem**: Stylized Low-Poly / Mid-Poly — modelos simplificados, sem detalhamento hiper-realista
- **Material**: Plastic/Vinyl PBR — roughness baixo, metallic baixo, brilho sutil tipo vinil/miniatura de resina (via `StandardMaterial3D`)
- **Personagens**: proporção Chibi / Super Deformed
- **Câmera**: isométrica, projeção **Orthogonal** (Camera3D), ângulo aproximado de 30–45°
- **Iluminação**: preferencialmente baked (LightmapGI) para a cidade estática; SDFGI se houver necessidade de tempo real
- **Água**: shader estilizado simples (vertex displacement + cor por profundidade), não realista

## Sistemas Principais

### 1. Cidade (Dia)
- Cena fixa (`.tscn`), não procedural
- Câmera isométrica seguindo o personagem (offset fixo + lerp para suavizar)
- NPCs e atividades de progressão
- Cutscenes via `AnimationPlayer` (possivelmente `Tween` para transições simples)

### 2. Dungeons (Noite) — estilo Hades
- **Não é geração de terreno via noise/algoritmo** — é um sistema de **salas pré-desenhadas montadas em sequência aleatória**
- Conjunto de cenas de sala (`.tscn`): combate, tesouro, boss, etc.
- Um "Dungeon Generator" (script) escolhe e instancia as salas dinamicamente formando um grafo/sequência aleatória a cada run
- Manter a mesma estética curada (vinil/low-poly) em cada sala

### 3. Transição Dia/Noite
- Troca de cena + persistência de estado do jogador (vida, itens, progresso)
- Gerenciar via Autoload/Singleton (ex: `GameState.gd`)

## Escopo Inicial (primeira entrega)

Começar simples:
1. Mapa da cidade (cena fixa, isométrica)
2. Câmera isométrica com seguimento do personagem
3. Movimentação básica do personagem (CharacterBody3D)

Sistemas de dungeon, progressão e cutscenes vêm em etapas posteriores.

## Notas Técnicas

- Formato de importação de modelos recomendado: glTF (`.glb`)
- `FastNoiseLite` fica reservado para uso futuro caso variação orgânica seja necessária (não é o caso do escopo inicial)
- `MultiMeshInstance3D` útil para props repetidos em massa (árvores, pedras) se necessário futuramente

## Assets — Fonte

Kits gratuitos de terceiros, formato glTF, organizados em `assets/models/`:

- **Cidade**: KayKit — City Builder Bits (Kay Lousberg) — prédios, ruas, carros, mobiliário urbano
- **Calm Place** (campo/área tranquila fora da cidade): Tiny Treats (Isa Lousberg), packs:
  - Homely House
  - Pleasant Picnic
  - Pretty Park
  - Fun Playground
- **Calm Place** (natureza/floresta): KayKit — Forest Nature Pack (Kay Lousberg) — árvores, arbustos e rochas low-poly
- **Calm Place** (folhagem de chão): Tiny Treats — House Plants (Isa Lousberg) — usado apenas pelas folhas soltas (monstera, sansevieria, zzplant) espalhadas no chão

Ver [ARQUITETURA.md](ARQUITETURA.md) para a organização de pastas desses assets.

Créditos e licenças completos: [CREDITOS.md](CREDITOS.md).
