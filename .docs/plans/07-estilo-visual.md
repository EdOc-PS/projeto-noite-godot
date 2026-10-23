# Estilo visual: cartoon estilizado, pincelado

Referência: [PROJETO-NOITE.md](../PROJETO-NOITE.md) · Filtros e efeitos de toda cena: [06-pos-processamento.md](06-pos-processamento.md) · Dia, noite e vento: [05-clima.md](05-clima.md)

## Direção

**Cartoon estilizado (stylized), com cara de pintura: pincelada/aquarela.** Não é realista. Visual próprio, com inspirações pontuais.

- Técnica: pincelado "pintado", no estilo de **Dishonored**, mas com textura **viva, clara e pincelada** (em vez de escura e suja), no espírito do **Breath of the Wild**.
- Cores vivas e claras, nada preto, sombras coloridas, formas simples e legíveis.

## Dois mundos, dois conjuntos de assets

| Parte | Assets | Observação |
|---|---|---|
| **Cidade (dia)** | pacotes do autor **Kenney** (assets pequenos) | pouca gameplay de combate; cenário de exploração |
| **Mundo de gameplay (noite)** | **a definir** | o jogador dorme e entra em outro mundo; a visão muda junto com os assets |

Quando os pacotes do Kenney chegarem: curadoria (só o que importa entra no projeto, o resto fica em `projeto-noite_sources/`) e registro em [CREDITOS.md](../CREDITOS.md).

**Regra de coerência:** os dois conjuntos são diferentes, então o que os une é o **estilo aplicado por cima** (paleta, pincelada, silhueta, tilt-shift, contorno, luz). Assim a troca entre cidade e mundo de gameplay muda o cenário sem estranheza para o jogador.

## Elementos do estilo

- **Silhueta** do personagem/objetos atrás de paredes (`shaders/silhouette/`, `scripts/visuals/silhouette_applier.gd`).
- **Vento** global ([05-clima.md](05-clima.md), `scripts/weather/wind.gd`).
- **Efeito de lente em volta da tela** (tilt-shift, `shaders/post_process/tilt_shift.gdshader`, `scenes/vfx/tilt_shift.tscn`).
- **Interações e inputs:** mouse, cursores, ícones de controle, prompt de interação, transição de cena ([03-interacoes.md](03-interacoes.md), [02-ui.md](02-ui.md), [08-transicoes.md](08-transicoes.md)).
- **Câmera** ([04-camera.md](04-camera.md)).

## A fazer

- Receber os assets do Kenney e fazer a curadoria.
- Escolher a arte do mundo de gameplay (noite).
- Definir paleta oficial, pincelada (shader/pós-processamento), contorno e cel shading.
- Criar o clima (paleta, saturação, ciclo dia/noite).
- Criar o personagem e as cenas (cidade, mundo de gameplay).
