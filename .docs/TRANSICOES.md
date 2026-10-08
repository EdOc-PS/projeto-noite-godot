# Transições de cenário

Referência: [ARQUITETURA.md](ARQUITETURA.md) · [PROJETO-NOITE.md](PROJETO-NOITE.md) · Boas práticas de loading: [CARREGAMENTO.md](CARREGAMENTO.md)

## Regra

**Toda troca de cenário do jogo usa o mesmo efeito: iris wipe** (o "fechamento em círculo" dos desenhos antigos de Looney Tunes; no Star Wars o mesmo recurso aparece como *circle wipe*).

- **Saindo (iris in)**: um círculo preto fecha a tela até o jogador. Para um instante em volta dele (`focus_radius`) e só então fecha de vez.
- **Entrando (iris out)**: a cena nova começa preta e o círculo abre a partir do jogador.
- **Ao iniciar o jogo**: a primeira cena também abre com iris out.
- Nunca usar `get_tree().change_scene_to_*` direto: sempre `SceneTransition.change_scene(path)`.

## Dois tipos de troca

Como os jogos modernos fazem: dentro do mesmo contexto a troca é quase instantânea, e só uma mudança grande de mundo ganha tela de loading.

| Tipo | Quando | Como |
|---|---|---|
| **Leve** (padrão) | Mesmo contexto: outside ↔ inside house, cômodos, quarto ↔ sala | Só o iris wipe. A cena de destino começa a carregar em segundo plano quando o jogador chega perto da passagem, então quando a íris fecha ela já está pronta. Cenas visitadas ficam em cache: voltar é instantâneo. |
| **Pesada** (a fazer) | Troca de mundo/contexto: casa → cidade, dormir → mundo da noite/dungeon | Iris wipe fecha → **tela de loading** (com progresso) → iris wipe abre. Usa o mesmo carregamento em segundo plano. |

Regra: se a troca leve começar a ficar com tela preta perceptível (cena grande demais), ela vira pesada.

## Implementação

| Peça | Arquivo | Função |
|---|---|---|
| Autoload `SceneTransition` | `autoload/scene_transition.gd` | `CanvasLayer` (layer 100) com um `ColorRect` de tela cheia. `change_scene(path)` fecha a íris, troca a cena e abre de novo. |
| Shader | `shaders/iris_wipe.gdshader` | Pinta de preto tudo fora de um círculo (`center`, `radius` em pixels). |
| Saída de cenário | `scripts/world/scene_exit.gd` | Node que escuta o `interacted` de um `InteractionPrompt` (`prompt_path`) e chama `SceneTransition.change_scene(target_scene)`. |

- **Centro da íris**: o node do grupo `player` projetado na tela pela câmera ativa. Se a cena não tiver jogador ou câmera, usa o centro da tela.
- **Durante a transição**: a árvore fica pausada enquanto a íris fecha (o jogador não anda) e o mouse fica bloqueado. O autoload roda com `PROCESS_MODE_ALWAYS`.
- **Carregamento em segundo plano**: `SceneTransition.preload_scene(path)` usa `ResourceLoader.load_threaded_request` (outra thread, o jogo não trava). O `scene_exit` chama isso quando o prompt emite `player_near` (jogador entrou no `show_radius`). Se ainda não terminou quando a íris fecha, a tela segura preta até terminar e nunca abre pela metade.
- **Cache**: toda cena carregada (e a cena inicial) fica guardada em `_cache`, então voltar pra ela não lê o disco de novo. Quando tiver muitas cenas, limpar o cache na troca pesada.
- **Tempos** (exports do autoload): `close_time` 0,7 s · `hold_black` 0,15 s · `open_time` 0,8 s.

## Como adicionar uma passagem

1. No cenário de origem, instancie um `InteractionPrompt` no ponto da passagem (ex.: a porta). Segurar `interact` confirma, que é o padrão de toda ação.
2. Adicione um `Node` com `scene_exit.gd`, aponte `prompt_path` pro prompt e `target_scene` pro `.tscn` de destino.
3. (Opcional) No destino, crie um `Marker3D` no grupo `spawn_point` e ponha o nome dele em `spawn_id` do `scene_exit`. O jogador nasce nessa posição/rotação (`player.gd` lê `SceneTransition.spawn_id` no `_ready`). Sem `spawn_id`, fica onde a cena posiciona.

## Passagens atuais

| De | Prompt | Para | Chega em |
|---|---|---|---|
| `calm_place/outside` | porta da casa (`house/DoorPrompt`) | `calm_place/inside_house` | `Entrance` |
| `calm_place/inside_house` | botão flutuante (`DoorPrompt`) | `calm_place/outside` | `house/HouseDoor` (na frente da porta, de costas pra ela) |

`inside_house` por enquanto é só fundo preto com o jogador iluminado, chão invisível e o botão de saída.

## Pendências

- Som de transição.
