# Arquitetura do Projeto

Referência de visão geral: [PROJETO-NOITE.md](PROJETO-NOITE.md)

Este documento descreve a organização de pastas do repositório e as convenções usadas para manter o projeto navegável conforme cresce. Detalhes de implementação de features específicas ficam nos planos em `.docs/plans/`.

## Estrutura de pastas

```
projeto-noite/
├── .docs/
│   ├── PROJETO-NOITE.md      # visão geral, direção de arte, sistemas
│   ├── ARQUITETURA.md        # este arquivo
│   └── plans/                # planos de implementação por etapa
├── project.godot
├── scenes/
│   ├── city/                 # cena fixa da cidade (dia)
│   ├── dungeon/              # salas e sistema de dungeon (noite)
│   ├── player/                # cena do personagem
│   └── main.tscn             # cena inicial
├── scripts/
│   ├── player/
│   ├── camera/
│   ├── dungeon/
│   └── ui/
├── assets/
│   └── models/                # todos os modelos 3D, um subdiretório por kit/conjunto
│       ├── city/               # kit da cidade
│       └── calm_place/         # kit da área tranquila fora da cidade
│           ├── homely_house/
│           ├── pleasant_picnic/
│           ├── pretty_park/
│           ├── fun_playground/
│           ├── forest_nature/
│           └── house_plants/
└── autoload/
    └── game_state.gd          # singleton de persistência de estado (dia/noite)
```

## Convenção de assets (`assets/models/`)

Assets são kits de terceiros baixados prontos (não modelados internamente). Cada kit chega com múltiplos formatos de exportação (fbx, fbx para Unity, obj, gltf) — só o **glTF** é usado no Godot 4.

Regra de organização, por kit:

```
assets/models/<categoria>/<nome_do_kit>/
├── *.gltf, *.bin, texturas .png     # arquivos usados de fato pelo Godot, na raiz da pasta do kit
└── _source/                          # material original arquivado, não usado em runtime
    ├── fbx/
    ├── fbx_unity/
    ├── obj/
    ├── textures/ (se vier separado do gltf)
    └── License.txt, sample.png, etc.
```

- `<categoria>` agrupa por contexto de uso no jogo (ex.: `city`, `calm_place`), não pelo nome comercial do kit.
- Quando uma categoria tem só um kit, os arquivos ficam direto em `assets/models/<categoria>/`.
- Quando uma categoria combina vários kits (ex.: `calm_place`), cada kit vira uma subpasta com seu próprio nome.
- `_source/` nunca é referenciado por cenas do Godot — existe só para manter o material original (licença, outros formatos) caso seja preciso reexportar ou trocar de engine.

Ver [PROJETO-NOITE.md](PROJETO-NOITE.md#assets--fonte) para a origem de cada kit.

## Autoloads (Singletons)

- `GameState` (`autoload/game_state.gd`): estado do jogador que persiste entre a troca de cena Dia ↔ Noite (vida, itens, progresso). Único autoload previsto no escopo inicial; novos autoloads devem ser justificados aqui quando adicionados.

## Convenções gerais

- Uma cena (`.tscn`) por responsabilidade; scripts (`.gd`) vivem em `scripts/` espelhando a árvore de `scenes/` quando fizer sentido.
- Nomes de arquivo em `snake_case`, nomes de classes/nodes em `PascalCase`.
- Nenhuma geração procedural de terreno — dungeons são salas pré-desenhadas montadas em sequência (ver PROJETO-NOITE.md).
