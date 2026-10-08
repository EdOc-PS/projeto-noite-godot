# Arquitetura do Projeto

Referência de visão geral: [PROJETO-NOITE.md](PROJETO-NOITE.md)

Este documento descreve a organização de pastas do repositório e as convenções usadas para manter o projeto navegável conforme cresce. Detalhes de implementação de features específicas ficam nos planos em `.docs/plans/`.

## Estrutura de pastas

```
projeto-noite/
├── .docs/
│   ├── PROJETO-NOITE.md      # visão geral, direção de arte, sistemas
│   ├── ARQUITETURA.md        # este arquivo
│   ├── TRANSICOES.md         # regra de transição de cenário (iris wipe)
│   ├── CARREGAMENTO.md       # boas práticas pra esconder loading
│   ├── INTERACOES.md         # catálogo de interações do cenário
│   └── plans/                # planos de implementação por etapa
├── project.godot
├── scenes/
│   ├── city/                 # cena fixa da cidade (dia)
│   ├── calm_place/           # área tranquila, um cenário por subpasta
│   │   ├── outside/           # outside.tscn (cenário jogável: ambiente + player + câmera)
│   │   │                      #   + outside_environment.tscn (só o ambiente)
│   │   └── inside_house/      # inside_house.tscn (fundo preto + player + botão de volta)
│   ├── dungeon/              # salas e sistema de dungeon (noite)
│   ├── player/                # cena do personagem
│   ├── ui/                    # elementos de UI reutilizáveis (ex.: interaction_prompt.tscn)
├── scripts/
│   ├── player/
│   ├── camera/
│   ├── dungeon/
│   ├── world/                 # lógica de mundo (ex.: scene_exit.gd, saída de cenário)
│   └── ui/
├── assets/
│   ├── models/                # modelos 3D, um subdiretório por kit/conjunto
│   │   ├── city/               # kit da cidade
│   │   └── calm_place/         # kits da área tranquila fora da cidade
│   │       ├── homely_house/
│   │       ├── pleasant_picnic/
│   │       ├── pretty_park/
│   │       ├── fun_playground/
│   │       ├── forest_nature/
│   │       └── house_plants/
│   ├── skyboxes/              # panoramas equiretangulares (2:1) pra PanoramaSkyMaterial
│   │   ├── basic/              # dia, manhã, noite, alien, espaço
│   │   └── space/              # nebulosa, galáxia, faixa, escuro, dia
│   └── ui/
│       ├── input_prompts/     # ícones de botão: generic/, keyboard/, xbox/
│       ├── cursors/           # cursores (Basic Default)
│       └── emotes/            # balões de emote (Vector Style 1)
├── shaders/                   # .gdshader (vento, névoa, rim light, tilt-shift)
└── autoload/
    ├── scene_transition.gd    # SceneTransition: troca de cenário com iris wipe (ver TRANSICOES.md)
    ├── input_device.gd        # InputDevice: teclado ou controle em uso (troca ícones da UI)
    └── game_state.gd          # (futuro) singleton de persistência de estado (dia/noite)
```

## Convenção de assets (`assets/`)

Assets são kits de terceiros baixados prontos (não feitos internamente). O primeiro nível de `assets/` separa por **tipo**: `models/` (3D), `skyboxes/` (céus), `ui/` (interface). Novos tipos (ex.: `audio/`, `fonts/`) seguem o mesmo padrão. Créditos e licenças de cada pacote ficam em [CREDITOS.md](CREDITOS.md).

Kits de modelos chegam com múltiplos formatos de exportação (fbx, fbx para Unity, obj, gltf) — só o **glTF** é usado no Godot 4.

### Pacotes originais ficam fora do projeto

O pacote completo baixado (licença, FBX/OBJ, previews, links, ícones não usados) fica em **`E:\Estudos\Desenvolvimento de Games\Jogo - 3D\projeto-noite_sources\`**, espelhando a estrutura de `assets/` (ex.: `projeto-noite_sources/models/calm_place/forest_nature/`). Lá tem um `LEIA-ME.md` com a mesma regra.

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
- `<categoria>` agrupa por contexto de uso no jogo (ex.: `city`, `calm_place`), não pelo nome comercial do kit. Categoria com um kit só → arquivos direto nela; com vários → uma subpasta por kit.
- `snake_case`, sem espaços nem caracteres especiais, descrevendo o **conteúdo** (`skyboxes/space`, `ui/cursors`), não o autor/marca — autor e versão ficam no CREDITOS.md.

Ver [PROJETO-NOITE.md](PROJETO-NOITE.md#assets--fonte) para a origem de cada kit.

## Autoloads (Singletons)

- `InputDevice` (`autoload/input_device.gd`): detecta se o jogador está no teclado/mouse ou no controle (último input) e emite `device_changed`; usado pela UI pra mostrar os ícones certos.
- `SceneTransition` (`autoload/scene_transition.gd`): única forma de trocar de cenário — `SceneTransition.change_scene(path)`. Faz o iris wipe e abre a íris ao iniciar o jogo. Regras em [TRANSICOES.md](TRANSICOES.md).
- `GameState` (`autoload/game_state.gd`, ainda não criado): estado do jogador que persiste entre a troca de cena Dia ↔ Noite (vida, itens, progresso). Único autoload previsto no escopo inicial; novos autoloads devem ser justificados aqui quando adicionados.

## Convenções gerais

- Uma cena (`.tscn`) por responsabilidade; scripts (`.gd`) vivem em `scripts/` espelhando a árvore de `scenes/` quando fizer sentido.
- Nomes de arquivo em `snake_case`, nomes de classes/nodes em `PascalCase`.
- **Cenários em árvore**: `scenes/<área>/<cenário>/<cenário>.tscn` (ex.: `calm_place/outside/outside.tscn`). Cada cenário jogável é uma cena completa (ambiente + player + câmera) carregável sozinha. Cena inicial atual: `calm_place/outside/outside.tscn`.
- Nenhuma geração procedural de terreno — dungeons são salas pré-desenhadas montadas em sequência (ver PROJETO-NOITE.md).
