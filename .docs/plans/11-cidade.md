# Plano 11 — Cidade

Referência: [07-estilo-visual.md](07-estilo-visual.md) (estilo Kenney) · Pós-processamento: [06-pos-processamento.md](06-pos-processamento.md)

A cidade é montada **à mão** (sem Terrain3D), com os kits de cidade do Kenney (CC0). Aqui **todos** os assets dos kits ficam no projeto (não vale a regra de guardar fora o que não está em uso).

## Pastas

| Pasta | Conteúdo |
|---|---|
| `assets/models/city/commercial/` | City Kit (Commercial) 2.1 — prédios comerciais, arranha-céus, detalhes (toldos etc.) |
| `assets/models/city/industrial/` | City Kit (Industrial) 2.0 — fábricas, galpões, chaminés, tanques |
| `assets/models/city/suburban/` | City Kit (Suburban) 2.0 — casas (`building-type-*`), cercas, caminhos, árvores, garagem |
| `assets/models/city/roads/` | City Kit (Roads) — ruas (`road-*`), pontes, placas, postes, semáforos, cones, lixeira, pisos (`tile-*`) |
| `scenes/levels/city/` | a cena da cidade (`city.tscn`, a fazer) |

Em cada kit: os `.glb` direto na pasta (eles procuram a textura em `Textures/colormap.png`, então **não mover os .glb pra subpastas**), a paleta em `Textures/colormap.png`, as variações de cor (outras paletas, mesmo UV) em `Textures/variations/` e o `License.txt`.

Os formatos repetidos (FBX, OBJ), os previews e as páginas do pacote ficam fora do projeto, em `projeto-noite_sources/city/<kit>/` (o Godot importaria cada modelo 3 vezes).

## Regras

- Paleta e luz: as do estilo Kenney (06-pos-processamento.md, "ESTILO KENNEY").
- Trocar a cor de um kit inteiro: usar uma `variations/variation-*.png` no lugar do `colormap.png` (mesmo UV).
- Montagem: grade dos kits (ruas e prédios encaixam em módulos); nós agrupados por tipo (Roads, Buildings, Props...) com filhos em ordem alfabética.
