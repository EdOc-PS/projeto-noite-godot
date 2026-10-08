# Plano 04 — Interações do cenário

Referência: [PROJETO-NOITE.md](../PROJETO-NOITE.md) · Prompt de interação: [03-ui.md](03-ui.md) · Passagens: [TRANSICOES.md](../TRANSICOES.md)

Catálogo de coisas que o jogador pode fazer no **Calm Place** (casa do personagem, noite). Serve de cardápio: escolher, implementar e marcar o status.

## Regras de toda interação

- **Mesmo prompt pra tudo**: `InteractionPrompt` (ícone genérico de longe, tecla/botão de perto). **Segurar** `interact` pra confirmar, nunca um toque.
- **Feedback em 3 camadas**: algo acontece no mundo (animação/objeto) + no personagem (pose/emote) + (depois) som.
- **Curta e reversível**: interação de cenário não prende o jogador; mexer o analógico cancela poses (sentar, deitar).
- **Sem texto longo**: o Calm Place é tranquilo; preferir emote e animação a caixas de diálogo. Texto só quando for história (cartas, bilhetes).
- **Um sistema por tipo**: cada interação nova reaproveita um dos tipos abaixo antes de criar código novo.

## Tipos (sistemas reutilizáveis)

| Tipo | O que faz | Exemplos | Base técnica |
|---|---|---|---|
| **Passagem** | Troca de cenário | Porta da casa, portão pra cidade, cama → noite | ✅ `scene_exit.gd` + `SceneTransition` |
| **Pose** | Personagem vai até um ponto e fica numa pose até mexer | Sentar no banco, deitar na grama, olhar o céu | `Marker3D` de pose + animação do personagem |
| **Reação do objeto** | O objeto anima/responde | Caixa de correio abre, flor fecha e reabre, pássaro voa | `AnimationPlayer`/`Tween` no objeto |
| **Coleta** | Pega algo e some do mundo | Maçã, uva, pedrinha brilhante | `GameState` (inventário) + objeto some |
| **Leitura** | Mostra um texto curto | Carta na caixa de correio, placa | Balão/painel de UI (plano 03, diálogo) |
| **Emote** | Só um balão em cima do personagem | Cheirar flor (❤), olhar a lua (✨) | `assets/ui/emotes/` (plano 03) |

## Cardápio do Calm Place

### Prioridade 1 (sistemas base)

| Interação | Tipo | Onde | Resultado |
|---|---|---|---|
| Entrar/sair da casa | Passagem | Porta | ✅ feito |
| **Sentar no banco** | Pose | `bench` | Senta, câmera aproxima um pouco, vagalumes do poste ao lado ficam mais ativos. Levanta ao mexer. |
| **Abrir a caixa de correio** | Reação + Leitura | `mailbox` | Tampa abre; às vezes tem carta (bilhete curto: dica, história, convite pra cidade). |
| **Cheirar as flores** | Emote + Reação | flores bioluminescentes | Emote ❤, a flor brilha mais forte por um instante. |

### Prioridade 2 (vida e coleta)

| Interação | Tipo | Onde | Resultado |
|---|---|---|---|
| Pegar maçã / uva | Coleta | piquenique, árvores com fruta | Fruta vai pro inventário (cura ou presente pra NPC na cidade). |
| Espantar o pássaro | Reação | `bird` | Pássaro voa e pousa em outro lugar. |
| Pular nos tocos | Reação (andar) | `stepping_stumps` | Pequeno pulinho automático entre tocos; toco afunda e volta. |
| Mexer no arbusto | Reação + Coleta (rara) | arbustos grandes | Arbusto chacoalha, solta folhas; às vezes cai um item ou um vagalume. |
| Chutar a lata de lixo | Reação | `trashcan` | Lata balança e faz barulho (piada visual). |

### Prioridade 3 (atmosfera e história)

| Interação | Tipo | Onde | Resultado |
|---|---|---|---|
| Deitar na grama e olhar o céu | Pose | gramado aberto | Câmera sobe olhando o céu (único momento em que as nuvens 3D aparecem). |
| Pegar o pacote na porta | Coleta + Leitura | `package` | Item da história (ex.: primeiro equipamento pra noite). |
| Calçar as botas | Reação | `boots` | Desbloqueia corrida ou som de passo diferente. |
| Pegar vagalume | Coleta | perto do poste | Vagalume vai num pote; vira luz que segue o jogador na dungeon. |
| **Dormir na cama** | Passagem (pesada) | dentro da casa | Sequência de "cair no sono" → mundo da noite (ver [CARREGAMENTO.md](../CARREGAMENTO.md)). |

## O que precisa existir antes

1. **Personagem com animações** (parado, andar, sentar, pegar, interagir). Sem isso, poses e coletas não leem bem.
2. **`GameState`** (autoload previsto no ARQUITETURA.md) pra coleta e pra lembrar o que já foi feito (carta lida, fruta pega).
3. **Emotes** (plano 03, item 3).
4. **Painel de leitura curto** (plano 03, diálogo).

## Status

| Interação | Status |
|---|---|
| Entrar/sair da casa | ✅ |
| Demais | ⏳ não iniciadas |
