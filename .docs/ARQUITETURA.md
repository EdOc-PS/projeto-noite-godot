# Arquitetura do Projeto

Referência de visão geral: [PROJETO-NOITE.md](PROJETO-NOITE.md)

Este documento descreve a organização de pastas do repositório e as convenções usadas para manter o projeto navegável conforme cresce. Detalhes de implementação de features específicas ficam nos planos em `.docs/plans/`.

## Estrutura de pastas

```
projeto-noite/
├── .docs/
│   ├── PROJETO-NOITE.md      # visão geral, direção de arte, sistemas
│   ├── ARQUITETURA.md        # este arquivo
│   ├── CREDITOS.md           # créditos e licenças dos assets
│   └── plans/                # documentos numerados: NN-nome-minusculo.md
│       ├── 01..06, 10, 13, 14-*.md  # planos por etapa/sistema
│       └── 07-estilo-visual.md      # estilo: cartoon estilizado, pincelado
├── project.godot
├── addons/                    # plugins do editor, só o que o projeto usa
│   └── terrain_3d/            #   Terrain3D 1.0.2 (relevo esculpível); só binários de Windows
├── scenes/                    # cenas, por tipo (áreas jogáveis serão recriadas)
│   ├── characters/            #   player/ (e NPCs/inimigos no futuro)
│   ├── vfx/                   #   efeitos reutilizáveis (tilt-shift)
│   └── ui/                    #   elementos de UI reutilizáveis (interaction_prompt)
├── scripts/                   # código, por sistema
│   ├── core/                  #   autoloads: SceneTransition, InputDevice, CursorManager
│   ├── player/
│   ├── camera/
│   ├── world/                 #   saída de cenário, foco de câmera, interação
│   ├── weather/               #   CLIMA (a refazer): weather_cycle, wind, rain, puddles, sun_rays...
│   ├── visuals/               #   estilo aplicado na cena: silhouette, soft_shadows, color_grade...
│   ├── vegetation/            #   wind_applier (vento nas plantas)
│   └── ui/
├── assets/                    # arquivos de terceiros, por tipo e depois por categoria
│   └── ui/                    #   input_prompts/, cursors/, emotes/  (cidade do Kenney entra em models/)
├── shaders/                   # .gdshader, uma pasta por tipo:
│   ├── silhouette/            #   silhueta atrás de paredes
│   ├── post_process/          #   efeitos de tela (tilt_shift)
│   └── ui/                    #   interface (ui_icon_glow)
└── (fora do projeto) ../../Jogo - 3D/projeto-noite_sources/   # pacotes originais (assets/, addons/)
```

Pastas que ainda não existem (`assets/models/`, `assets/textures/vegetation/`, `shaders/weather/`, `shaders/nature/`, `tools/`...) são criadas de novo quando houver conteúdo, seguindo as convenções abaixo.

## Convenção de assets (`assets/`)

Assets são kits de terceiros baixados prontos (não feitos internamente). O primeiro nível de `assets/` separa por **tipo**: `models/` (3D), `skyboxes/` (céus), `ui/` (interface). Novos tipos (ex.: `audio/`, `fonts/`) seguem o mesmo padrão. Créditos e licenças de cada pacote ficam em [CREDITOS.md](CREDITOS.md).

Kits de modelos chegam com múltiplos formatos de exportação (fbx, fbx para Unity, obj, gltf) — só o **glTF** é usado no Godot 4.

### Pacotes originais ficam fora do projeto

O pacote completo baixado (licença, FBX/OBJ, previews, links, ícones não usados) fica em **`E:\Estudos\Desenvolvimento de Games\Jogo - 3D\projeto-noite_sources\`**, espelhando a estrutura de `assets/` (ex.: `projeto-noite_sources/models/...`; os pacotes antigos ainda estão na estrutura de antes, `calm_place/...`). Lá tem um `LEIA-ME.md` com a mesma regra.

Dentro do projeto só entra o que o Godot usa:

```
assets/<tipo>/<categoria>/<nome_do_kit>/
└── *.gltf, *.bin, texturas .png / imagens usadas
```

### Regra para novos assets

1. Descompactar o pacote em `projeto-noite_sources/<tipo>/<categoria>/<nome>/`.
2. Copiar pro projeto, no mesmo caminho dentro de `assets/`, **só o que vai ser usado**: modelos em glTF (+ `.bin` + texturas); imagens/UI só os arquivos que alguma cena usa, não o pacote inteiro.
3. Registrar em [CREDITOS.md](CREDITOS.md) (nome, versão, autor, pasta, licença).

### Nomes de pasta

- `<tipo>`: `models/`, `skyboxes/`, `ui/` (novos tipos, ex.: `audio/`, `fonts/`, seguem o padrão).
- `<categoria>` agrupa por contexto de uso no jogo (ex.: `nature`, `home`, `park`, `city`), não pelo nome comercial do kit. Categoria com um kit só → arquivos direto nela; com vários → uma subpasta por kit.
- `snake_case`, sem espaços nem caracteres especiais, descrevendo o **conteúdo** (`skyboxes/space`, `ui/cursors`), não o autor/marca — autor e versão ficam no CREDITOS.md.

Ver [PROJETO-NOITE.md](PROJETO-NOITE.md#assets--fonte) para a origem de cada kit.

## Plugins (`addons/`)

Só entra em `addons/` a pasta do plugin, sem demo, exemplos nem binários de plataformas que o jogo não usa. O pacote completo fica em `projeto-noite_sources/addons/<plugin>_<versão>/`.

- **Terrain3D** (1.0.2, Tokisan Games, MIT): relevo esculpível (lagos, caminhos levemente afundados, ondulações) com colisão. Binários mantidos: Windows. Para exportar para outra plataforma, copiar o binário correspondente de `projeto-noite_sources/addons/terrain_3d_v1.0.2/addons/terrain_3d/bin/`.

## Autoloads (Singletons)

- `InputDevice` (`scripts/core/input_device.gd`): detecta se o jogador está no teclado/mouse ou no controle (último input) e emite `device_changed`; usado pela UI pra mostrar os ícones certos.
- `FpsCounter` (`scripts/ui/fps_counter.gd`): contador de FPS no canto inferior esquerdo, em todas as cenas; F3 mostra/esconde.
- `SceneTransition` (`scripts/core/scene_transition.gd`): única forma de trocar de cenário — `SceneTransition.change_scene(path)`. Faz o wipe de bolhas e descobre a tela ao iniciar o jogo. Regras em [08-transicoes.md](plans/08-transicoes.md).
- `GameState` (`scripts/core/game_state.gd`, ainda não criado): estado do jogador que persiste entre a troca de cena Dia ↔ Noite (vida, itens, progresso). Único autoload previsto no escopo inicial; novos autoloads devem ser justificados aqui quando adicionados.

## Convenções gerais

- Uma cena (`.tscn`) por responsabilidade; scripts (`.gd`) vivem em `scripts/` espelhando a árvore de `scenes/` quando fizer sentido.
- Nomes de arquivo em `snake_case`, nomes de classes/nodes em `PascalCase`.
- **Cenários em árvore**: `scenes/levels/<área>/<cenário>/<cenário>.tscn` (ex.: `levels/city/city.tscn`). Cada cenário jogável é uma cena completa (ambiente + player + câmera) carregável sozinha. Hoje não há cenário nem cena inicial (`run/main_scene` removida): serão recriados com os assets novos.
- **Nós em ordem alfabética.** Os filhos de cada nó ficam em ordem alfabética na árvore da cena . Facilita achar as coisas.
- **Nós agrupados por tipo.** Objetos repetidos ficam sob um nó pai do tipo: todos os arbustos em `Bushes`, árvores em `Trees`, pedrinhas em `Pebbles`, folhas em `Leaves`, grama no seu `GrassField` etc. (ex.: `Nature/Trees/Tree_0`). Nada de dezenas de objetos soltos na raiz da cena ou misturados no mesmo pai.
- **Colisão e luz são filhas do objeto.** Todo objeto com colisão ou que emite luz carrega o próprio `StaticBody3D`/`CollisionShape3D` e a própria `OmniLight3D`/`SpotLight3D` como filhos (ex.: `Props/Barrel_0/Collision/Shape`), nunca num `Collision` central solto. Mover/apagar o objeto leva a colisão e a luz junto. **Exceção:** barreiras invisíveis (sem objeto visual), que ficam num node próprio (`InvisibleBarrier`).
- **Organização por domínio (clima):** tudo que é do sistema de clima fica junto, por tipo de arquivo, na pasta `weather/` de cada um: `scripts/weather/` (lógica), `shaders/weather/` (shaders), e quando existirem `scenes/weather/` (cenas reutilizáveis, ex.: chuva pronta) e `assets/textures/weather/` (texturas de gota, poça, nuvem). Um sistema novo (ex.: combate) segue o mesmo padrão: `scripts/combat/`, `scenes/combat/`... É o padrão de projetos Godot profissionais: primeiro por tipo de recurso (`scenes/`, `scripts/`, `shaders/`, `assets/`), depois por sistema/domínio.
- **Shader novo vai na pasta do tipo** (ver árvore acima); se não couber em nenhuma, criar uma pasta nova de tipo, nunca solto na raiz de `shaders/`.
- Nenhuma geração procedural de terreno — dungeons são salas pré-desenhadas montadas em sequência (ver PROJETO-NOITE.md).
