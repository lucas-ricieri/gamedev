# Créditos e proveniência

## Projeto acadêmico

Caçador — Arena das Ruínas, versão 2.0, outubro de 2026. A campanha 1.0 permanece nos arquivos históricos do projeto.

Responsável acadêmico: nome completo e funções ainda não informados pelo usuário. Não foi atribuída autoria individual fictícia.

Ideia da adaptação para um caçador: usuário. Implementação, documentação, sprites e síntese de áudio: desenvolvimento com assistência do Codex. Não foram utilizados packs de sprites, música ou efeitos de terceiros.

## Base didática

Mini GDD Maze Shooter e Projeto de Disciplina 2026, disponibilizados pelo usuário. Professor identificado nos documentos: Marcos Silvano Almeida, UTFPR Campo Mourão.

Referências citadas no mini GDD: Gauntlet, Alien Breed, SturmFront e Dragon Heart. Nenhum asset desses jogos foi copiado.

## Terceiros

- Godot Engine 4.7.2: MIT. [Licença oficial](https://godotengine.org/license/). Texto em `licenses/GODOT_LICENSE.txt`.
- Marca UTFPR: [portal institucional de identidade visual](https://www.utfpr.edu.br/comunicacao/design/marca-da-utfpr/). Arquivo horizontal colorido oficial, preservado em `assets/art/utfpr.png`.
- blentz/godot-mcp: AGPL-3.0, ferramenta de desenvolvimento e ponte do editor. Licença em `addons/godot_mcp/LICENSE.txt`; addon excluído dos exports de jogo.

SVGs e WAVs originais permanecem editáveis no projeto. Não se atribui a marca institucional nem componentes de terceiros à equipe do jogo.

O personagem jogável e o retrato do menu usam `assets/art/hunter-spritesheet.png`: desenho de referência fornecido pelo usuário (`caçador-sprite.jpeg`) e spritesheet de 80 frames gerado com a ferramenta image_gen. O recorte, alinhamento e seleção das cinco animações nas quatro direções ficam em `scripts/hunter_animations.gd` e `scripts/player.gd`.

O material `hunter_palette.gdshader` uniformiza as cores do personagem em todos os frames. `assets/art/hunter-sword.png` foi preparada com a ferramenta integrada image_gen a partir da imagem de espada fornecida pelo usuário; o prompt está em `docs/sword-image-prompt.txt`. O efeito sonoro `swing.wav` foi sintetizado para este projeto e pode ser recriado por `tools/create_sword_sfx.py`. O arco vetorial e a flecha SVG continuam sendo usados na arena.

A arena v2 equipa espada, arco e adaga: montagem no corpo e rastros em `scripts/weapon_rig.gd`. A adaga em `assets/art/hunter-dagger.png` foi preparada pela ferramenta integrada image_gen a partir da referência fornecida pelo usuário; o prompt está em `docs/dagger-image-prompt.txt`. Os ícones de arco, granada, armadilha e poção são vetoriais feitos para o projeto. O laço de ondas, os cinco atributos, bônus específicos de itens e as escolhas de duas melhorias foram implementados com assistência do Codex, conforme o pedido do usuário. As referências de gênero Isaac/Diablo não forneceram assets copiados.
