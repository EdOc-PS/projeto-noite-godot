# Estilo visual: brinquedo de vinil

Referência: [PROJETO-NOITE.md](../PROJETO-NOITE.md) · Efeitos de toda cena: [10-pos-processamento.md](10-pos-processamento.md) · Dia e noite: [06-clima.md](06-clima.md)

**Referência principal: The Legend of Zelda: Link's Awakening (Switch, 2019).** O mundo parece uma maquete de brinquedos de plástico/vinil: cores vivas e limpas, superfícies com brilho suave, bordas desfocadas de miniatura.

## A palavra é "vivo"

- Verde vivo, cores de brinquedo, luz clara e quente de dia.
- **Nunca lavado** (claridade/névoa demais), **nunca estourado** (glow demais), **nunca azulado de dia**.
- Saturar por igual não resolve: satura tudo, e laranja/pele ficam agressivos. O "vivo" vem da soma das técnicas abaixo.

## As técnicas do visual

| # | Técnica | O que faz | Status |
|---|---|---|---|
| 1 | **Tilt-shift** | bordas desfocadas em elipse, cara de maquete | ✅ toda cena (`scenes/effects/tilt_shift.tscn`) |
| 2 | **Material plástico** | brilho especular suave + verniz: o "vinil" | ✅ toda cena (`PlasticApplier`) |
| 3 | **Color grading (LUT)** | remapeia as cores da tela: verdes e céu vivos, laranja/pele contidos, sombras coloridas em vez de cinza | ✅ cidade (`ColorGrade`) · ⏳ outside, inside_house |
| 4 | **Rim light / fresnel** | borda clara sutil nos objetos e personagens, destaca do fundo | ✅ toda cena (no `PlasticApplier`) |
| 5 | **Reflexos** | o ambiente refletido no plástico: é o que faz o brilho de vinil aparecer | ✅ toda cena (`ReflectionProbe` + SSR) |
| 6 | **Sombras macias** | borda da sombra esfumada (PCSS), como no Zelda | ✅ toda cena (`SoftShadows`) |

### 2. Material plástico

`scripts/environment/plastic_applier.gd`: um node na raiz da cena que, ao iniciar, troca os materiais dos glTF por cópias "plásticas". Os kits vêm foscos (roughness alta), que é o oposto do vinil.

| Parâmetro | Padrão | Efeito |
|---|---|---|
| `roughness` | 0,3 | brilho especular suave (menor = mais brilhante; abaixo de ~0,3 vira cerâmica/vidro) |
| `specular` | 0,7 | força do reflexo |
| `clearcoat` | 0,6 | camada de verniz por cima, como brinquedo envernizado |
| `clearcoat_roughness` | 0,3 | verniz levemente borrado |

- Ignora materiais com emissão (vidro aceso, lanternas) e com `glass`/`glow`/`light` no nome.
- Materiais iguais compartilham uma cópia só (não pesa).

### 5. Reflexos

Sem nada pra refletir, o plástico fica "meio brilhante" e sem vida. Toda cena tem:

- **`ReflectionProbe`** na raiz, cobrindo a área jogável (cidade 76×24×92, outside 40×14×40, inside_house 26×9×22 com `interior` e `box_projection`). Atualiza uma vez (`update_mode` padrão).
- **SSR** (reflexo em tela) no `Environment`: `ssr_enabled`, 64 passos, `fade_in` 0,15, `fade_out` 2,0, `depth_tolerance` 0,2.

### 6. Sombras macias

`scripts/environment/soft_shadows.gd` (node `SoftShadows`): ao iniciar, dá tamanho às luzes e a Godot faz sombra suave (PCSS).

| Parâmetro | Padrão | Efeito |
|---|---|---|
| `sun_angular_distance` | 2° | sol/lua: maior = borda mais esfumada |
| `lamp_size` | 0,15 m | Omni/Spot com sombra (lâmpadas, postes, fogo) |

### 3. Color grading (LUT)

`scripts/environment/color_grade.gd` (node `ColorGrade`): gera ao iniciar uma LUT 3D (32³) por código e põe em `Environment.adjustment_color_correction`. Sem arquivo de imagem pra manter: os ajustes são exports.

| Parâmetro | Padrão | Efeito |
|---|---|---|
| `vibrance` | 0,5 | satura mais o que está apagado, quase não mexe no que já é vivo |
| `green_boost` | 0,4 | verdes mais vivos (grama, árvores) |
| `sky_boost` | 0,15 | azul-céu mais vivo |
| `shadow_tint` / `highlight_tint` | azul leve / quente leve | sombras frias, luzes quentes (sombra colorida em vez de cinza) |
| `s_curve` | 0,15 | contraste suave |

Com a LUT, a **saturação global desce** (dia 1,2; tarde 1,3; noite 1,15) pra não somar demais. Quem satura "do jeito certo" agora é a LUT.

### 4. Rim light

No próprio `PlasticApplier`: `rim_enabled` nos materiais plásticos, `rim` 0,3 e `rim_tint` 0,6 (borda clara puxando pra cor do objeto, não branca).

## O que filtro não resolve (texturas e modelos): fora do escopo

**Decisão: não vamos fazer texturas pintadas à mão nem trocar assets.** Fica registrado como referência do que separa o visual do Link's Awakening.

O Link's Awakening é vivo principalmente por causa dos **assets**, não só do pós-processamento:

- **Texturas pintadas à mão**: a grama tem manchas de verde claro/escuro, a terra tem bordas irregulares, as pedras têm faixas de luz pintadas. Os kits da cidade são de **cor chapada** (uma cor por material), então nenhum filtro cria essa variação.
- **Modelos arredondados**: bordas chanfradas e "gordinhas" pegam o brilho especular (é o que faz o vinil aparecer). Low-poly de quinas retas quase não mostra o brilho.
- **Chão com variação**: manchas de terra, flores, tufos de grama espalhados quebram o chão liso.

Caminhos pra chegar mais perto: (1) shader de chão com ruído de cor (manchas de grama/terra), (2) gradiente vertical nos materiais (base mais escura, topo mais claro, como AO pintado), (3) props de detalhe (flores, tufos). Os filtros (1–4 acima) só potencializam isso.

## Regra

**Padrão do jogo inteiro:** toda cena jogável tem `PlasticApplier`, `SoftShadows`, `ReflectionProbe` e SSR no `Environment`, além do tilt-shift. O `ColorGrade` (LUT) por enquanto só na cidade (outside/inside_house já estão no ponto à noite) + o checklist de [10-pos-processamento.md](10-pos-processamento.md).
