# Plano 05 — Câmera

Referência: [PROJETO-NOITE.md](../PROJETO-NOITE.md) · Referência de jogo: **Death's Door** (Acid Nerve, 2021) · Interações: [04-interacoes.md](04-interacoes.md)

Objetivo: definir como a câmera se comporta no jogo inteiro: padrão no gameplay, variação por área e **planos de cena** (close no rosto em conversas e momentos especiais), no estilo do Death's Door.

## Princípios

- **Fixa no gameplay**: o jogador nunca gira a câmera. "Cima" no controle é sempre "cima" na tela.
- **Diagonal (isométrica) por padrão**: câmera girada ~45° e inclinada ~45°, vendo o cenário pela quina, como nas referências (Tiny Treats, Death's Door na vila). O movimento do jogador é relativo à câmera (`player.gd` gira o input pelo giro da câmera).
- **Ortogonal**: visual de maquete/diorama (combina com o tilt-shift).
- **Jogador centralizado** no gameplay; a câmera segue com suavidade (sem tremer em movimentos bruscos).
- **Cada lugar escolhe o melhor enquadramento**: lugar aberto → mais de cima; lugar fechado → mais baixo, mostrando paredes e fachadas.
- **Fora do gameplay, a câmera é livre**: em conversas e momentos de história ela pode aproximar, mudar de ângulo e de lado, como um diretor de cinema. Ao terminar, volta suave pro gameplay.
- **Nunca corte seco** no gameplay: toda mudança é uma transição suave (0,5–1 s). Corte seco só dentro de cena (ex.: alternar entre close do jogador e do NPC).

## Ângulos (inclinação)

Medidos em prints do Death's Door: sala dos corvos ~45° (de frente), vila/loja ~50° (girada ~38°).

| Lugar | Inclinação | Giro | Zoom | Por quê |
|---|---|---|---|---|
| **Padrão** | 60° | 0° | normal | Meio-termo entre isométrica e top-down |
| **Área aberta** (Calm Place, praças) | **45°** ✅ no Calm Place | **-17°** ✅ (porta da casa, levemente pela direita) | um pouco aberto | O chão é o destaque: flores, sombra das nuvens, caminhos |
| **Fachadas e entradas** (porta da casa, lojas) | 50–55° | 0° | um pouco fechado | Mostra a frente do prédio e a porta |
| **Interiores e salas** | **35°** | **20°** (frente-direita) | próximo (`size` 7), segue o jogador | Diorama do cômodo; paredes do lado da câmera cortadas |
| **Combate (dungeon)** | 65° | 0° | travado na sala | Ler ataques e inimigos no chão |
| **Cena / conversa** | livre | livre | close | Ver abaixo |

Evitar: top-down puro (90°: casa vira telhado, personagem vira cabeça) e giro no gameplay.

## 1. Câmera de gameplay — ✅ base feita

`scripts/camera/isometric_camera.gd` no `CameraRig`:

- Segue o jogador (`follow_speed`), centralizado na altura `pivot_height`.
- `pitch_degrees`: inclinação · `yaw_degrees`: giro fixo da cena (Calm Place: 45° / -17°, porta da casa vista um pouco pela direita).
- Zoom ortogonal abre perto de um foco (`focus_path`, hoje a casa): `size_near_player` 6 → `size_near_focus` 10.

## 2. Zonas de câmera — a fazer

Como o Death's Door faz por área: uma **`CameraZone`** (`Area3D`) muda o enquadramento quando o jogador entra.

- Parâmetros: `pitch`, `size` (zoom), `mode` (`FOLLOW` segue o jogador · `LOCKED` enquadramento fixo da sala · `BOUNDED` segue mas não passa das bordas da zona), `blend_time`, `priority` (zonas sobrepostas: vence a maior).
- Sem zona: volta pro padrão da cena.
- Substitui o zoom da casa de hoje: no Calm Place, zona aberta a 70° no gramado e zona da casa a 55° perto da porta.
- **Limites do mapa**: zona `BOUNDED` cobrindo o cenário inteiro, pra câmera não mostrar o "fora do mapa".

## 3. Planos de cena (conversa e momentos especiais) — a fazer

No Death's Door, quando um NPC fala ou algo importante acontece, a câmera **sai do gameplay**: aproxima bem, às vezes no rosto, muda de ângulo e até de lado, e alterna entre quem fala. Queremos o mesmo.

**Quando usar:**

| Momento | Plano |
|---|---|
| NPC começa a falar | Câmera aproxima e enquadra os dois (plano de conversa) |
| Fala com emoção / ênfase | **Close no rosto** de quem fala, de um ângulo mais baixo e de lado |
| Alternância de falas | Corte entre o close do jogador e o do NPC |
| Personagem reage (emote, susto, alegria) | Close rápido no personagem + emote |
| Chegada num lugar importante / revelação de chefe | Plano aberto que passeia pela cena e volta pro jogador |
| Fim da cena | Volta suave pro enquadramento de gameplay |

**Como montar (proposta):**

- **`CameraShot`**: um `Marker3D` posicionado à mão no cenário ou no NPC (ex.: `Npc/Shots/CloseUp`, `Npc/Shots/TwoShot`). Guarda posição, rotação (ângulo livre, inclusive giro) e `size` (zoom; close = `size` bem pequeno, ~1,5–2).
- **`CameraDirector`** (autoload): tira a câmera do modo gameplay e anda entre shots: `play_shot(shot, blend)`, `cut_to(shot)`, `return_to_gameplay(blend)`. Pausa o movimento do jogador durante a cena.
- **Close no rosto com ortogonal**: aproximar = diminuir o `size`. Se o close ficar "chapado", a cena pode trocar a câmera pra **perspectiva** com FOV fechado (~20–30°) só durante a conversa; volta pra ortogonal no fim (decidir testando).
- **Enquadramento**: regra dos terços; quem fala um pouco fora do centro, olhando pro lado aberto da tela. Fundo levemente desfocado (aumentar o tilt-shift durante a cena).
- O diálogo (plano 03, item 6) chama o `CameraDirector`: cada fala pode indicar o shot (`shot: "npc_close"`).

## Etapas

1. ✅ Câmera de gameplay com inclinação e zoom de foco.
2. ✅ Calm Place diagonal: 45° de inclinação, -17° de giro (frente da casa, um pouco pela direita) (70° de cima foi testado e descartado: "de cima demais").
3. `CameraZone` + transição suave; trocar o zoom da casa por zonas.
4. Limites do mapa (`BOUNDED`).
5. `CameraDirector` + `CameraShot` (planos de cena), testado com um NPC de exemplo.
6. Integrar com o sistema de diálogo e emotes.

## Interior da casa (`home/inside_house`) — ✅

- **Planta em L** (safe house, 18 × 10 m + extensão de 8 × 4 m): **esquerda** cozinha em L e jantar (na extensão da frente); **fundo** a porta pro outro mundo, à esquerda do centro (provisória, vai virar algo mais especial); **direita** a **ferraria medieval** (mesmo piso de madeira e mesmas paredes da casa toda; o clima de dungeon vem dos móveis do KayKit Dungeon: mesa de venda/upgrade sobre um tapete vermelho medieval `rug_medieval_red`, bigorna, amolador, armas encostadas na parede, prateleiras `shelves`, estandarte, tochas acesas, baú de ouro encostado na parede do fundo, barris e caixotes) e a sala com lareira. Cozinha com bancadas `countertop_straight_B` e armários altos `wall_cabinet_straight` na parede. Recorte vazio na frente-direita; a entrada é um **mini corredor** (x 1–3, z 3–5) saindo da parede da frente, com o spawn `Entrance` dentro dele. Quinas fechadas com pilares na cor do topo da parede.
- **Organização dos nós**: `Room/` agrupado por área — `Structure` (piso, paredes, pilares, corredor), `Kitchen`, `Dining`, `Living` (inclui a lareira), `Store` (ferraria/loja: mesa, armas centralizadas na parede do fundo sob o estandarte, tochas dos dois lados, prateleiras `ForgeShelvesLeft/Right` com objetos), `GameplayDoor`, `Entrance`. Luz pertence ao objeto que a emite (`TorchLeft/TorchLight`, `LampStanding/LampLight`, luminárias de teto na área delas); em `Lights/` só a luz geral (`RoomLight`). **Colisão também pertence ao asset**: cada móvel tem um filho `Collision` (`StaticBody3D`) com `Shape`; armas agrupadas em `Store/WeaponRack`. Piso e paredes ficam em `Structure/Collision`.
- **Câmera**: `pitch_degrees` 35°, `yaw_degrees` 20° (frente-direita), `size` **7** (mais perto do personagem), **segue o jogador**.
- **Paredes do lado da câmera cortadas** (cutaway, escala 0,3 na altura): direita e frentes. Fundo e esquerda inteiras.
- Fora do cômodo: fundo escuro + natureza em silhueta (padrão de todo interior, ver 10-pos-processamento.md).

## Visão de interação frontal (padrão do jogo) — ✅

Ao **segurar `interact`** em pontos de "uso" (balcão de loja, fogão, e no futuro bancadas, baús, mapas…), a câmera **sai de cima do jogador e vai suave pra uma visão de frente do objeto**, com zoom. O personagem some e para de andar. Sai com `interact` de novo, `ui_cancel` ou mexendo o analógico; a câmera volta suave pro jogador.

- Script: `scripts/world/focus_view.gd` (node com `prompt_path`, `shot_path`, `shot_size`, `blend_time`; sinais `opened`/`closed` pra abrir a UI da loja/cozinha).
- **Sempre a mesma câmera ortogonal** se movendo, girando e mudando o zoom. Testado trocar pra uma câmera em perspectiva (primeira pessoa de verdade) e descartado: piscava e distorcia na troca.
- Enquadramento: um `Marker3D` (em `Shots/`) recuado no eixo do olhar, virado pro objeto. Visão **de frente, na altura dos olhos** (quase 90° com o objeto, só -10° de inclinação), como uma pessoa olhando pro móvel: balcão `CounterShot` (`size` 3,2), fogão `StoveShot` (`size` 2,6). O marcador fica entre o jogador e o objeto, na frente das luminárias de teto (com câmera ortogonal, o que fica atrás dela não aparece).
