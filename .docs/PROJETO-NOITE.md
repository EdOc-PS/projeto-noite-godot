# NightProject

## Visão Geral

Jogo 3D de câmera de cima com estética **cartoon estilizada, pincelada** (visual próprio; inspirado no pincelado de Dishonored e no Breath of the Wild, vivo e claro). Detalhes em [plans/11-estilo-visual.md](plans/11-estilo-visual.md).

Loop de jogo dividido em duas partes:

- **Dia (Cidade)**: mapa fixo, desenhado à mão, onde o jogador explora e realiza atividades que fortalecem o personagem (progressão, itens, upgrades) para as runs noturnas. Pouca gameplay de combate; usa os assets pequenos do **Kenney**.
- **Noite (Dungeons / mundo de gameplay)**: o jogador dorme e é transportado para um mundo separado com dungeons proceduralmente montadas — estilo **Zelda misturado com Hades**. Terá **assets e visão próprios** (ainda a definir); o estilo aplicado por cima une os dois mundos pra não causar estranheza.

## Motor e Linguagem

- **Engine**: Godot 4
- **Linguagem**: GDScript (não usar C#)

## Direção de Arte

- **Estilo**: cartoon estilizado (não realista), pincelado/aquarela, cores vivas e claras ([plans/11-estilo-visual.md](plans/11-estilo-visual.md))
- **Personagens**: proporção Chibi / Super Deformed (a confirmar com o novo personagem)
- **Câmera**: isométrica, projeção **Orthogonal** (Camera3D), ângulo aproximado de 30–45°
- **Elementos**: silhueta atrás de paredes, vento, efeito de lente (tilt-shift) em volta da tela, interações/inputs/mouse
- **A definir**: clima (paleta, saturação, ciclo), cel shading/contorno, pincelada
- **Iluminação**: a definir junto com o clima novo

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
- Mesma estética estilizada em cada sala

### 3. Transição Dia/Noite
- Troca de cena + persistência de estado do jogador (vida, itens, progresso)
- Gerenciar via Autoload/Singleton (ex: `GameState.gd`)

## Escopo Inicial (primeira entrega)

1. Receber e organizar os assets do Kenney
2. Mapa da cidade (cena fixa, isométrica)
3. Câmera isométrica com seguimento do personagem
4. Movimentação básica do personagem (CharacterBody3D)

Sistemas de dungeon, progressão e cutscenes vêm em etapas posteriores.

## Notas Técnicas

- Formato de importação de modelos recomendado: glTF (`.glb`)
- `MultiMeshInstance3D` útil para props repetidos em massa se necessário

## Assets — Fonte

Hoje o projeto só tem `assets/ui/` (Kenney, CC0).

Próximos: assets do **Kenney** para a cidade (a enviar) e uma arte a definir para o mundo de gameplay.

Ver [ARQUITETURA.md](ARQUITETURA.md) para a organização de pastas.

Créditos e licenças completos: [CREDITOS.md](CREDITOS.md).
