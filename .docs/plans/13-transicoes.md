# Transições de cenário

Referência: [ARQUITETURA.md](../ARQUITETURA.md) · [PROJETO-NOITE.md](../PROJETO-NOITE.md) · Boas práticas de loading: [14-carregamento.md](14-carregamento.md)

## Regra

**Toda troca de cenário do jogo usa o mesmo efeito: wipe de bolhas RADIAL.** Bolhas pretas de tamanhos variados vêm da borda da tela pro centro, num círculo, crescem e se fundem até fechar no meio (shader do pacote [Godot Modular Transitions](https://binbun3d.itch.io/godot-modular-transitions), Binbun3D). Histórico: iris wipe (círculo) → triângulos roxos na diagonal → bolhas pelas laterais → bolhas radiais (atual).

- **Saindo**: as bolhas cobrem a tela da borda pro centro, em círculo (`close_time` 0,6 s).
- **Entrando**: a cena nova começa coberta e as bolhas recuam do centro pra borda (`open_time` 0,6 s).
- **Ao iniciar o jogo**: a primeira cena também começa coberta e descobre.
- Nunca usar `get_tree().change_scene_to_*` direto: sempre `SceneTransition.change_scene(path)`.

## Dois tipos de troca

Como os jogos modernos fazem: dentro do mesmo contexto a troca é quase instantânea, e só uma mudança grande de mundo ganha tela de loading.

| Tipo | Quando | Como |
|---|---|---|
| **Leve** (padrão) | Mesmo contexto: outside ↔ inside house, cômodos, quarto ↔ sala | Só o wipe. A cena de destino começa a carregar em segundo plano quando o jogador chega perto da passagem, então quando o wipe fecha ela já está pronta. Cenas visitadas ficam em cache: voltar é instantâneo. |
| **Pesada** (a fazer) | Troca de mundo/contexto: casa → cidade, dormir → mundo da noite/dungeon | Wipe fecha → **tela de loading** (com progresso) → wipe abre. Usa o mesmo carregamento em segundo plano. |

Regra: se a troca leve começar a ficar com tela preta perceptível (cena grande demais), ela vira pesada.

## Implementação

| Peça | Arquivo | Função |
|---|---|---|
| Autoload `SceneTransition` | `scripts/core/scene_transition.gd` | `CanvasLayer` (layer 100) com um `ColorRect` de tela cheia. `change_scene(path)` cobre a tela, troca a cena e descobre de novo. |
| Shader | `shaders/ui/transition_wipe.gdshader` | Shader enviado pelo usuário. `factor` 0 = livre, 1 = coberto; `gradient_texture` decide a ordem (degradê **radial**: borda preta → centro branco, gerado por código em `_radial_gradient`); `shape_texture` é a forma (ruído celular → bolhas de tamanhos variados, gerado por código); `shape_tiling` 5; `width` 0,5; cor `base_color` preta. Trocar o efeito = trocar essas duas texturas. |
| Saída de cenário | `scripts/world/scene_exit.gd` | Node que escuta o `interacted` de um `InteractionPrompt` (`prompt_path`) e chama `SceneTransition.change_scene(target_scene)`. |

- **Ajustes** (exports do autoload): `color`, `tiling`, `width`, `close_time`, `open_time`, `hold_black`.
- **Durante a transição**: a árvore fica pausada enquanto a tela é coberta (o jogador não anda) e o mouse fica bloqueado. O autoload roda com `PROCESS_MODE_ALWAYS`.
- **Carregamento em segundo plano**: `SceneTransition.preload_scene(path)` usa `ResourceLoader.load_threaded_request` (outra thread, o jogo não trava). O `scene_exit` chama isso quando o prompt emite `player_near` (jogador entrou no `show_radius`). Se ainda não terminou quando o wipe fecha, a tela segura coberta até terminar e nunca abre pela metade.
- **Cache**: toda cena carregada (e a cena inicial) fica guardada em `_cache`, então voltar pra ela não lê o disco de novo. Quando tiver muitas cenas, limpar o cache na troca pesada.
- **Tempos** (exports do autoload): `close_time` 0,7 s · `hold_black` 0,15 s · `open_time` 0,8 s.

## Como adicionar uma passagem

1. No cenário de origem, instancie um `InteractionPrompt` no ponto da passagem (ex.: a porta). Segurar `interact` confirma, que é o padrão de toda ação.
2. Adicione um `Node` com `scene_exit.gd`, aponte `prompt_path` pro prompt e `target_scene` pro `.tscn` de destino.
3. (Opcional) No destino, crie um `Marker3D` no grupo `spawn_point` e ponha o nome dele em `spawn_id` do `scene_exit`. O jogador nasce nessa posição/rotação (`player.gd` lê `SceneTransition.spawn_id` no `_ready`). Sem `spawn_id`, fica onde a cena posiciona.

## Passagens atuais

| De | Prompt | Para | Chega em |
|---|---|---|---|
| `home/outside` | porta da casa (`house/DoorPrompt`) | `home/inside_house` | `Entrance` |
| `home/inside_house` | entrada do salão (`DoorPrompt`) | `home/outside` | `house/HouseDoor` (na frente da porta, de costas pra ela) |
| `levels/test_area` (**cena inicial**) | porta do fundo (`DoorPrompt`) | `home/outside` | `house/HouseDoor` |
| `home/inside_house` | porta do fundo (`GameplayDoorPrompt`) | — (desligada: `target_scene` vazio; a cidade está guardada) | — |

`inside_house`: casa-loja de quem ajuda o personagem (um cômodo, ver [05-camera.md](05-camera.md) pro enquadramento).

## Pendências

- Som de transição.
