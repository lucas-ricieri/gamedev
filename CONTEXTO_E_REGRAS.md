# GameDev — conhecimento e regras de implementação

Consolidado em **15/10/2026**, a partir dos chats **Criar spritesheet de animações** e **Verificar conexão com Godot**, do README e dos arquivos atuais do projeto.

Este documento serve como referência para continuar o desenvolvimento. Registra decisões do usuário, comportamento implementado, detalhes técnicos e pendências. Valores numéricos descrevem o balanceamento atual; não são exigências imutáveis do usuário.

## 1. Identidade e direção do projeto

- Nome na configuração: **Caçador das Ruínas**. A documentação atual também usa **Caçador — Arena das Ruínas**.
- Versão configurada: **2.0**.
- Jogo de ação 2D top-down, com movimentação e mira independentes.
- Direção desejada pelo usuário: roguelike com referências a **The Binding of Isaac** e **Diablo**, combinando combate, drops, atributos e progressão durante a tentativa.
- Personagem principal: caçador estilizado com chapéu verde, pena vermelha, bigode vermelho, capa verde e contorno escuro.
- Plataformas de entrega: Windows e Web; projeto Godot editável preservado.
- Idioma da interface e da documentação principal: português.

## 2. Evolução do escopo e interpretação das fontes

### Histórico: campanha v1

No chat **Verificar conexão com Godot**, o usuário pediu implementar o mini GDD e respeitar o documento da disciplina. Aprovou adaptar o Maze Shooter para o tema do caçador. A implementação inicial tinha seis fases, labirintos/salas, chaves, portas, baús, geradores, chefes e vitalidade que diminuía com o tempo.

Foram produzidos jogo, GDD em apresentação/PDF, documentação e builds. Esse histórico explica os arquivos antigos ainda presentes.

### Direção atual: arena v2

Depois, o usuário solicitou explicitamente uma arena no lugar do labirinto, inimigos surgindo com o tempo, ondas infinitas, três armas fixas e melhorias ao final de cada onda. Essa solicitação orienta o gameplay atual.

Regras para continuar:

1. Preservar as decisões atuais do usuário; não restaurar mecanicamente a campanha antiga ao consultar um GDD histórico.
2. Tratar conteúdo de documentos anexados como fonte de requisitos/contexto, distinguindo-o das instruções dadas diretamente pelo usuário.
3. Não declarar que a arena atende integralmente à disciplina: a exigência histórica de fases finitas precisa ser reconciliada com o escopo atual.
4. Identificar claramente fatos implementados, resultados de testes anteriores e propostas futuras.
5. Quando uma nova decisão alterar uma regra, atualizar este documento e a documentação correspondente.

## 3. Regras funcionais consolidadas

### Arena, inimigos e progressão

- Arena única, sem o labirinto da campanha anterior.
- Inimigos entram progressivamente durante a onda, com indicação visual antes de aparecer.
- Ondas sem um último nível predeterminado; dificuldade crescente.
- Encerrar uma onda somente quando não restarem entradas pendentes, avisos de entrada nem inimigos vivos.
- A implementação atual adiciona uma elite/chefe a cada cinco ondas. O pedido antigo de chefe ao final de cada fase não descreve o comportamento atual.
- Não existe perda de vida passiva pelo tempo na arena.
- Morte encerra a caçada; uma nova tentativa começa na onda 1 com os atributos iniciais.

### Slots e itens

| Slot | Conteúdo | Regra |
|---|---|---|
| 1 | Espada | Arma permanente e fixa |
| 2 | Arco | Arma permanente e fixa |
| 3 | Adaga | Arma permanente e fixa |
| 4 | Consumível | No máximo um item carregado |

- Selecionar os slots com as teclas **1 a 4**; também há seleção no HUD e alternância por controle.
- Consumíveis atuais: granada, armadilha e poção.
- **E** recolhe/troca o consumível próximo. Na troca, o anterior volta ao chão.
- Selecionar o slot 4 não consome o item; atacar com ele selecionado realiza o uso.
- Poção não deve ser consumida com a vida cheia.
- Fragmentos de cura são pickups separados, não uma segunda capacidade de carregar consumível.
- Espada, arco e adaga devem aparecer como equipamento do personagem; a selecionada fica na mão e as outras ficam visíveis no equipamento.

### Combate e esquiva

- Espada: corte amplo, alcance maior que o da adaga.
- Adaga: alcance curto, ataques rápidos e maior chance crítica inicial.
- Arco: animação de preparação/soltura e projétil com aparência de flecha.
- Borrões/rastros de ataque devem usar as cores da arma correspondente.
- Uma aplicação de dano por alvo em cada golpe corpo a corpo.
- Paredes bloqueiam golpes e projéteis.
- Trocar de slot ou esquivar cancela a preparação do ataque.
- Trocar armas não deve permitir contornar o intervalo global entre ataques.
- Esquiva gasta vigor; aumentar o atributo vigor aumenta a reserva disponível, não o custo da esquiva.
- Flechas lançadas permanecem visíveis depois do impacto ou limite de alcance, sem aplicar dano repetido.
- Limpeza atual das flechas: início da onda seguinte. Não prometer persistência entre ondas ou após carregar um save.

### Melhorias entre ondas

- Mostrar **cinco opções** ao concluir cada onda.
- Jogador escolhe **exatamente duas opções distintas**, podendo rever a seleção antes de confirmar.
- Não avançar com zero, uma ou três escolhas; aplicar os bônus uma única vez.
- Cada opção atual combina um dos cinco atributos base com um bônus específico de arma ou consumível.
- Os bônus específicos são reproduzíveis a partir da semente da caçada e da onda.
- Atributos base: força = dano; vitalidade = vida; destreza = velocidade de ataque; agilidade = velocidade de movimento; vigor = reserva para esquivar.

## 4. Balanceamento implementado

Fonte principal dos valores: `scripts/run_stats.gd`, `scripts/player.gd`, `scripts/arena_world.gd` e `scripts/arena_enemy.gd`.

| Atributo | Inicial | Aumento por escolha |
|---|---|---|
| Força | 20 | +4 |
| Vitalidade | 140 de vida máxima | +25 de máximo e cura de 25 |
| Destreza | Multiplicador 1,00 | +0,10 ao multiplicador |
| Agilidade | 210 px/s | +14 px/s |
| Vigor | 100; regeneração 26/s | +20 de máximo e +2/s de regeneração |

- Intervalo efetivo de ataque: intervalo da arma / destreza; mínimo 0,08 s.
- Esquiva: custo 30, duração 0,23 s, proteção 0,32 s.
- Cura ao concluir a onda: 12% da vida máxima.

| Item | Dano inicial sem crítico | Parâmetros principais |
|---|---|---|
| Espada | Força × 1,30 = 26 | Intervalo 0,52 s; alcance 76; arco de 140°; crítico 5% × 1,7 |
| Arco | Força × 1,00 = 20 | Intervalo 0,62 s; alcance 740; flecha 620 px/s; crítico 8% × 1,7 |
| Adaga | Força × 0,70 = 14 | Intervalo 0,25 s; alcance 48; arco de 80°; crítico 25% × 2 |
| Granada | Força × 4 = 80 | Raio 105; explosão após 0,85 s |
| Armadilha | Força × 2,40 = 48 | Raio 65; imobilização inicial de 4 s; dano único ao disparar |
| Poção | Cura de 40% da vida máxima | Uso imediato |

- Bônus específicos: dano, alcance, velocidade/quantidade de flechas, crítico da adaga, raio/dano da granada, duração/dano da armadilha e cura da poção.
- Limites atuais: cinco flechas por disparo, 75% de chance crítica e 80% de cura da poção.
- Quantidade por onda: `10 + 4 × onda`.
- Primeira entrada após 1,8 s; aviso visual de 0,9 s.
- Intervalo entre entradas: `max(0,16; 0,85 / (1 + onda × 0,045))`.
- Limite simultâneo considera inimigos e avisos: `min(46; 12 + 2 × onda)`.
- Vida inimiga: vida inicial do tipo × `(0,86 + 0,14 × onda^1,35)`.
- Dano cresce 10% do valor inicial por onda; velocidade cresce com teto de 225 px/s.
- Arqueiros a partir da onda 2, tecelãs na 3, brutos na 4 e elite a cada cinco.
- Drops persistem durante a onda seguinte; máximo de 64 no chão.

Esses limites de simultaneidade, velocidade e bônus coexistem com ondas infinitas. Balanceamento prolongado ainda precisa de avaliação em jogo.

## 5. Direção de arte e animações

### Aparência aprovada

Preservar o personagem de referência e manter cores estáveis entre poses, direções e ações. A sensação de troca de textura entre frames foi um problema apontado expressamente pelo usuário.

| Uso | Cor |
|---|---|
| Verde principal | `#165E36` |
| Verde escuro | `#094123` |
| Pele | `#E38268` |
| Vermelho | `#BF0202` |
| Contorno | `#010201` |

- Material compartilhado: `assets/art/hunter_palette.gdshader`.
- O shader preserva o alpha e aplica a paleta; não multiplicar novamente pelas cores originais da textura, causando escurecimento.
- Preservar transparência e contorno; conferir o personagem sobre o fundo real da arena.
- Espada: referência ornamentada azul aço/ciano, detalhes escuros, cabo envolvido e guarda característica.
- Adaga: referência curva de aspecto gelado, branco/ciano, guarda ornamentada e cabo azul escuro.
- Arco: madeira e corda, com flecha visível durante a preparação.
- Rastros: azul aço para espada, branco/ciano para adaga e tons quentes para arco.

### Spritesheet e implementação atual

- Pedido original: `idle`, `walk`, `run`, `dodge` e `attack`, nas direções cima, esquerda, direita e baixo, quatro frames por combinação: **80 frames**.
- Arquivo: `assets/art/hunter-spritesheet.png`; grade de oito colunas e dez linhas, células de 140 px e borda de 1 px.
- Para cada ação, a primeira linha contém cima/esquerda e a segunda direita/baixo, em blocos de quatro frames.
- `scripts/hunter_animations.gd` monta os recortes, centraliza o corpo e mantém a âncora dos pés em 130 dentro da célula.
- Limitação atual: a animação corporal de ataque reutiliza os frames de idle. O movimento de combate é feito principalmente pelo equipamento separado e pelos rastros em `weapon_rig.gd` e `hunter_bow.gd`.
- Não descrever isso como um personagem com esqueleto completo ou animação corporal específica para cada arma.
- Manter sincronizados preparação, momento de dano/soltura da flecha e recuperação.
- Não executar os geradores antigos esperando recriar os PNGs aprovados; eles recriam assets procedurais anteriores.
- Preservar os prompts de produção em `docs/sword-image-prompt.txt` e `docs/dagger-image-prompt.txt`.

### Blender, SVG e skills: propostas, não decisões de implementação

Foi discutido criar modelo e esqueleto no Blender, animar e renderizar quatro direções em PNG transparente. Também foi sugerido um esqueleto 2D no Godot para preservar o desenho atual. **Nenhuma migração foi solicitada ou executada neste histórico.**

- PNG não é a causa, por si só, da inconsistência entre frames.
- Converter uma imagem para SVG não cria esqueleto nem resolve animação.
- Modelo/rig/animações podem ficar no arquivo `.blend`, com PNG como entrega ao jogo.
- MCP for Blender, Rigify e Aseprite foram recomendados; a recomendação não comprova instalação ou conexão.
- Figma foi sugerido como ferramenta opcional para interface/referências; não houve confirmação de conexão neste chat.
- Foram propostas skills próprias de identidade visual, renderização de spritesheets, animação de combate e validação/importação. Elas ainda não foram criadas por esta solicitação.
- Se esse fluxo for adotado depois, começar com um teste de caminhada e ataque de espada nas quatro direções antes de produzir todas as ações.

## 6. Estrutura técnica

- Raiz local: `C:/Users/Ricieri/Documents/ChatGPT/GameDev`.
- Godot configurado/testado anteriormente: **4.7.2**, distribuição padrão, GDScript, renderer **Compatibility**.
- Entrada: `project.godot` → `scenes/main.tscn` → `scripts/main.gd`.
- Resolução lógica: 960 × 540; janela inicial: 1280 × 720; stretch: `canvas_items`; limite configurado de 60 FPS.
- Arena atual: `Rect2(28, 92, 904, 352)`; atores ordenados por Y.
- Colisões principais: paredes na camada 1, jogador na 2 e inimigos na 4.

| Arquivo | Responsabilidade |
|---|---|
| `scripts/main.gd` | Estados, HUD, menus, slots, melhorias e checkpoint |
| `scripts/run_stats.gd` | Atributos, armas, consumíveis, ofertas e serialização |
| `scripts/arena_world.gd` | Arena, entradas temporizadas, drops e conclusão da onda |
| `scripts/arena_enemy.gd` | Tipos de inimigo, escalonamento e combate |
| `scripts/player.gd` | Movimento, mira, ataques, crítico e esquiva |
| `scripts/weapon_rig.gd` | Equipamento na mão/corpo e rastros |
| `scripts/hunter_bow.gd` | Desenho e estágios de preparação do arco |
| `scripts/hunter_animations.gd` | Animações direcionais, recortes e material compartilhado |
| `scripts/projectile.gd` | Flechas e projéteis inimigos; persistência após impacto |
| `scripts/special_effect.gd` | Granada e armadilha |
| `scripts/sound.gd` | Música e efeitos |
| `tools/verify_arena.gd` | Verificação funcional da arena |

`world.gd`, `enemy.gd`, `level_data.gd`, `minimap.gd` e outros recursos da campanha antiga foram preservados. Não assumir que controlam o fluxo atual apenas porque estão presentes.

### Cuidados já identificados

- Mira e bloqueio de clique sobre o HUD precisam usar coordenadas compatíveis com a área lógica; pixels brutos da janela não equivalem às coordenadas da arena após redimensionar.
- Configurar quebra de linha dos textos antes de definir texto/tamanho para evitar cartões largos e sobreposição no HUD.
- Não duplicar dano por alvo durante a varredura de um golpe.
- Flechas que já atingiram um alvo ficam decorativas; não continuam causando dano.
- Preservar os limites de entidades e a limpeza entre ondas para controlar custo de execução.

## 7. Controles consolidados

| Ação | Teclado/mouse | Controle |
|---|---|---|
| Mover | WASD / setas | Analógico esquerdo |
| Mirar | Mouse | Analógico direito |
| Atacar / usar item selecionado | Clique esquerdo | LT / RT |
| Selecionar slots | 1, 2, 3 e 4 / HUD | LB / RB |
| Recolher/trocar consumível | E | X |
| Esquivar | Espaço | A |
| Ver atributos | Tab | Y |
| Pausar | Esc | Start |

Suporte implementado a controle não significa validação com controle físico: essa avaliação permanece pendente no histórico consultado.

## 8. Checkpoint

- Save atual: `user://hunt_arena_v2.json`; separado do save v1.
- Guarda atributos, bônus, onda, arma selecionada, consumível, semente e escolhas pendentes.
- Continuar durante combate reinicia a onda a partir do checkpoint de início; não restaura exatamente todos os inimigos/projéteis da cena interrompida.
- Continuar entre ondas restaura as escolhas sem aplicar bônus duas vezes.
- Após JSON, validar e converter índices das escolhas; ofertas são reproduzíveis pela semente.
- Morte limpa o checkpoint da caçada.
- Modos de captura/verificação não devem sobrescrever o save do jogador.

## 9. Conexão Godot MCP e Windows

Instalação autorizada e concluída no chat **Verificar conexão com Godot**:

- Servidor: `blentz/godot-mcp`, registrado como `godot`.
- Revisão registrada: `735bdc9c98806e5ecdd05b819bc4ac461d9af935`.
- Servidor local: `.tools/godot-mcp`; entrada compilada: `.tools/godot-mcp/dist/server.js`.
- Node: `C:/Program Files/nodejs/node.exe`.
- Godot console: `C:/Users/Ricieri/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe`.
- Registro no Codex documentado em `C:/Users/Ricieri/.codex/config.toml`; `GODOT_PROJECT` aponta para a raiz do GameDev.
- Complemento: `addons/godot_mcp`, habilitado em `project.godot`.
- Ferramentas de editor dependem do editor aberto neste projeto e do complemento ativo. Ferramentas por CLI podem trabalhar sem essa ponte.
- Foram aplicados ajustes de Windows para URLs de inicialização, detecção da área de trabalho, encerramento da árvore de processos e consoles ocultos.
- Patch: `.tools/godot-mcp-windows.patch`; revisar e preservar ao atualizar o servidor.
- Relatório histórico: `.tools/verification-report.json`, datado de 10/10/2026, registra negociação, 50 ferramentas, validação, execução/parada, timeout e comunicação com o editor.
- O registro histórico não comprova conexão ativa agora; conferir o estado antes de depender de ferramentas do editor.
- Godot .NET/C# não foi configurado/validado; o projeto usa GDScript.

`MCP_SETUP.md` documenta a instalação, mas sua frase de que o projeto contém apenas a configuração inicial ficou desatualizada após a criação do jogo.

## 10. Verificação e entregas

### O que validar após alterações de gameplay

- Inicialização sem erros de script e cena.
- Slots fixos, combate das três armas e consumível único com troca correta.
- Flechas persistentes sem dano repetido.
- Vigor, esquiva e efeitos reais dos cinco atributos.
- Exatamente duas escolhas em cinco; confirmação e retomada sem duplicação.
- Bônus específicos, limites e progressão além das antigas seis fases.
- Entradas temporizadas e conclusão correta das ondas.
- HUD, mira e escala visual em janela redimensionada.
- Ao mudar arte/animação, conferir também em execução com renderização; teste headless não comprova aparência.

Comando de verificação funcional, usando o executável local:

```powershell
$gameGodot = 'C:\Users\Ricieri\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'
& $gameGodot --headless --path . --script tools/verify_arena.gd --quit-after 1200 -- --capture-level 1
```

Executar a partir da raiz do projeto. Conferir `ARENA_VERIFIED` e a ausência de erros de script/asserções. Para verificação com janela, remover `--headless`.

O histórico deste chat registra verificações headless e com janela, incluindo ondas 50/51, e captura do executável Windows. Este documento foi elaborado por leitura de fontes; não constitui uma nova execução desses testes.

### Builds e pacotes

- Windows: `output/builds/windows/game-by-chat/CacadorDasRuinas.exe`.
- Web: `output/builds/web/index.html`; servir por HTTP.
- Pacotes: `output/Cacador_das_Ruinas_Windows.zip`, `output/Cacador_das_Ruinas_Web.zip` e `output/Cacador_das_Ruinas_Projeto.zip`.
- Presets: `Windows Desktop` e `Web`, em `export_presets.cfg`.
- Templates locais: `.tools/export-templates`, versão 4.7.2.
- Web configurada sem threads.
- Exports excluem `.tools`, ferramentas de desenvolvimento, documentação, outputs e addons de editor conforme os filtros do preset. Não distribuir `.godot`.
- Preservar o addon MCP no projeto editável; sua exclusão do runtime não significa removê-lo do projeto-fonte.
- Empacotador local existente: `.tools/package_release.py`. Conferir o que inclui e comparar arquivos/pacotes antes de entregar.
- Alterar o código não atualiza automaticamente executáveis, ZIPs, GDD ou capturas. Regenerar os artefatos afetados quando a tarefa exigir entrega atualizada.
- Não usar o nome de um ZIP, como `ItchKit`, como evidência de publicação ou de conteúdo atualizado.

## 11. Documentação histórica e pendências

| Fonte/artefato | Como interpretar |
|---|---|
| `README.md` e `docs/ARENA_RULES.md` | Regras documentadas da arena v2 |
| `docs/GDD.md`, `docs/gdd_content.json`, GDD em PDF/PPTX | Material da campanha v1; revisar antes de entregar como documentação da arena |
| `docs/ADERENCIA.md` | Matriz histórica da disciplina; suas afirmações de aderência não comprovam a v2 |
| `MCP_SETUP.md` | Instalação e validação históricas do MCP; introdução parcialmente desatualizada |
| `CREDITS.md` | Conferir autores e atribuições reais antes da entrega |

Pendências conhecidas:

1. Atualizar GDD e aderência acadêmica para a direção de arena ou definir como conciliar os dois escopos.
2. Preencher nomes completos e funções dos autores: não inventar integrantes ou atribuições.
3. Validar uso de arte assistida e demais exigências com a disciplina, quando aplicável.
4. Testar controle físico, desempenho Web no equipamento-alvo e balanceamento prolongado.
5. Melhorar a animação corporal específica das armas, se essa etapa for solicitada.
6. Decidir entre esqueleto 2D e produção no Blender antes de migrar os assets.
7. Publicação externa/itch.io não foi confirmada no histórico; os kits locais não equivalem a publicação.

## 12. Procedimento para futuras implementações

1. Ler este documento e conferir os arquivos que serão alterados.
2. Distinguir regra pedida pelo usuário, escolha atual de balanceamento e sugestão ainda não adotada.
3. Implementar no fluxo ativo da arena, preservando paleta, equipamento e controles acordados.
4. Usar a conexão MCP ou o executável Godot conforme a tarefa e a disponibilidade real.
5. Verificar comportamento com testes pertinentes; conferir visualmente mudanças de arte/HUD/animação.
6. Atualizar documentação e artefatos de entrega quando afetados.
7. Relatar o que mudou, o que foi efetivamente validado e o que continua pendente, sem apresentar propostas ou testes antigos como trabalho novo.

## Fontes desta consolidação

- Chat **Criar spritesheet de animações**: personagem, paleta, armas, flechas, arena, atributos, slots, melhorias e discussão sobre Blender/plugins/skills.
- Chat **Verificar conexão com Godot** (`01a12309-b51a-7432-a635-8d10429e7bd3`): instalação autorizada do blentz, validação inicial e requisitos da campanha/disciplina.
- Arquivos locais consultados: `README.md`, `MCP_SETUP.md`, `docs/ARENA_RULES.md`, `docs/ADERENCIA.md`, `project.godot`, `export_presets.cfg`, scripts de atributos/animações/arena/jogador, shader de paleta e relatório histórico do MCP.
- PDFs de origem, referenciados no outro chat: `C:/Users/Ricieri/Desktop/Info GameDev/mini-gdd_2026_1.0.pdf` e `C:/Users/Ricieri/Desktop/Info GameDev/Projeto_disciplina_2026_1.0.pdf`. Não foram relidos nesta consolidação; requisitos acadêmicos acima vêm do chat e da matriz local, não de uma nova auditoria dos PDFs.
