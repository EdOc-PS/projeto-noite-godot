# Carregamento — como esconder loading

Referência: [TRANSICOES.md](TRANSICOES.md) (efeito e API de troca) · [ARQUITETURA.md](ARQUITETURA.md)

Objetivo: o jogador **nunca deve ver uma tela de loading parada** se der pra evitar. Quando não der, o loading tem que parecer parte do jogo.

## Princípios

1. **Carregar antes de precisar.** O momento certo de carregar é quando o jogador *pode* ir pra um lugar, não quando ele já foi. Proximidade de uma passagem = começar a carregar.
2. **Nunca carregar na thread principal durante o jogo.** Tudo via `SceneTransition.preload_scene()` (`ResourceLoader.load_threaded_request`). `load()` e `change_scene_to_file()` direto são proibidos no gameplay.
3. **Esconder o tempo que sobrar atrás de algo que o jogador quer ver.** Uma animação, uma ação do personagem ou um momento de história. Tela preta parada é o último recurso.
4. **Cenas leves dentro do mesmo contexto.** Se uma troca leve começar a demorar, o problema é o tamanho da cena: quebrar a cena, não colocar loading.
5. **A transição nunca abre pela metade.** Se o carregamento atrasar, segura no estado "fechado" (preto ou animação em loop) até terminar.

## Orçamento de tempo

| Troca | Exemplo | Tempo visível máximo | Como esconder |
|---|---|---|---|
| Leve | outside ↔ inside house, cômodos | ~1,5 s (só a íris) | pré-carregar por proximidade + íris |
| Média | casa → cidade | ~3 s | íris + **ação do personagem** (abrir portão, sair andando) |
| Pesada | dormir → mundo da noite / dungeon | o necessário | **sequência de transição jogável/animada** no lugar de tela de loading |

## Técnicas (o que os jogos fazem)

| Técnica | Como funciona | Onde usar aqui |
|---|---|---|
| **Pré-carregar por proximidade** | Começa a carregar quando o jogador entra na área da passagem. | ✅ Já feito: `scene_exit` + `player_near` do `InteractionPrompt`. |
| **Segurar pra confirmar** | O tempo de segurar o botão já é tempo de carregamento. | ✅ Já feito: 0,5 s do hold. |
| **Transição de tela** (íris, fade) | Esconde a troca em si. | ✅ Iris wipe em toda troca. |
| **Animação de passagem** | Personagem abre a porta, sobe a escada, atravessa o portão; a câmera acompanha e a troca acontece no meio. | Porta da casa (futuro), saída pra cidade. |
| **Corredor/aperto** ("squeeze") | Trecho estreito e lento (passar entre arbustos, escada, ponte) enquanto a próxima área carrega. | Caminho calm place → cidade. |
| **Sequência no lugar do loading** | Sono, sonho, queda, tela com o personagem caindo no escuro. O jogador vê algo bonito e pode até mexer. | **Dormir → mundo da noite**: sequência de "cair no sono" em loop enquanto carrega. |
| **Streaming por pedaços** | Mundo dividido em pedaços carregados/descarregados conforme o jogador anda, sem troca de cena. | Cidade, se ficar grande (dividir em bairros). |
| **Cache de cenas** | Cenas já visitadas ficam na memória; voltar é instantâneo. | ✅ Já feito em `SceneTransition._cache`. |
| **Dicas/arte no loading** | Quando a tela é inevitável, mostrar arte, dica ou o personagem animado, nunca barra parada. | Fallback da troca pesada. |

## Travadas que não são carregamento

O carregamento em segundo plano não resolve tudo. Esses também causam "engasgo" na troca:

- **Compilação de shader**: na primeira vez que um material aparece, ele é compilado.
  - Abrir a cena atrás da tela fechada e esperar 1–2 frames antes de abrir (✅ já feito).
  - Reusar materiais e shaders. Poucos shaders diferentes = pouca compilação.
  - Se travar mesmo assim: cena de "aquecimento" que mostra os materiais novos atrás da tela preta.
- **`_ready()` pesado**: scripts que fazem muito trabalho ao entrar na cena (gerar coisas, buscar nós em loop). Mover pra antes (pré-calcular) ou dividir em vários frames.
- **Física e partículas**: muitos corpos ou `GPUParticles3D` nascendo juntos. Ligar partículas depois que a íris abre ou usar `preprocess`.
- **Instanciar cena gigante**: mesmo carregada, instanciar milhares de nós custa. Usar `MultiMeshInstance3D` pra vegetação repetida (grama, flores, arbustos).

## Manter as cenas leves

- **Texturas**: importar com compressão VRAM (padrão do Godot pra 3D) e no tamanho que aparece na tela. Kits de terceiros às vezes vêm com 2K/4K à toa.
- **Modelos**: um glTF por objeto, reusado com instâncias. Nada de duplicar o arquivo.
- **Vegetação repetida**: `MultiMeshInstance3D` em vez de centenas de nós.
- **Luzes**: poucas `OmniLight3D` com sombra; o resto sem sombra.
- **Interiores separados**: o interior de cada casa é sua própria cena (como `inside_house`), nunca escondido dentro do exterior.

## Checklist pra cada passagem nova

- [ ] Troca por `scene_exit` / `SceneTransition.change_scene()`, nunca `change_scene_to_file`.
- [ ] Pré-carregamento começa antes da confirmação (proximidade).
- [ ] Classificada como leve, média ou pesada, e escondida com a técnica da tabela.
- [ ] Testada saindo e voltando: a íris nunca abre com a cena incompleta, e nada trava ao abrir.
- [ ] Se travar: ver primeiro "Travadas que não são carregamento".

## Plano por contexto

| Passagem | Tipo | Esconder com |
|---|---|---|
| calm place outside ↔ inside house | Leve | ✅ pré-carregar + íris |
| quarto ↔ resto da casa | Leve | pré-carregar + íris |
| casa → cidade | Média | animação de sair pela porta/portão + íris; se crescer, corredor de transição |
| dormir → mundo da noite | Pesada | sequência de "cair no sono" em loop enquanto carrega, depois íris abre no mundo novo |
| sala → sala da dungeon | Leve | salas pré-carregadas uma à frente (a próxima sala carrega enquanto o jogador está na atual) |
