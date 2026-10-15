# Correspondência com os documentos da disciplina

Os PDFs fornecidos foram tratados como fontes de requisitos. O usuário aprovou adaptar o Maze Shooter para um caçador, preservando seu núcleo e acrescentando chefes e IA. Não foram interpretados como autorização para publicar em uma conta externa ou preencher nomes de alunos sem informação.

## Requisitos e evidências

| Requisito | Implementação / evidência | Situação |
|---|---|---|
| Godot 2D, Compatibility | `project.godot`, viewport 960×540, 16:9 | Implementado |
| Início, gameplay e final | Splash, título, campanha, game over, vitória | Implementado |
| Pelo menos 5 fases finitas | 6 layouts em `scripts/level_data.gd` | Implementado |
| Pelo menos 12 elementos, contagem flexível | 4 mecânicas + 5 itens + 5 inimigos + 6 elementos de cenário = 20 | Implementado |
| Progressão de conteúdo e valores | Inimigos, perigos, amuletos, layouts, paletas e chefes progressivos | Implementado |
| Teclado, mouse e joystick | Ações de gameplay e foco nos menus | Implementado; controle físico pendente |
| Arte própria | SVG original e desenho de cenário pelo jogo; assistência declarada | Implementado; validar autoria acadêmica com a disciplina |
| Som e música | 6 loops e 9 efeitos WAV sintetizados | Implementado |
| Logo UTFPR | Splash usa arquivo institucional oficial | Implementado |
| Título, data e autores | Título e outubro/2026; crédito genérico da equipe | Nome completo / funções pendentes |
| Instruções, créditos, fase concluída | Menus próprios; preparação entre fases | Implementado |
| Transições | Fade de 0,22 s na entrada e saída | Implementado |
| Web e PC | Windows x86_64 e HTML5/WASM; presets e ZIPs | Gerados |
| Meta Web 30/60 FPS | Compatibility, cap de 60 FPS, limites de IA/projéteis | Benchmark em equipamento-alvo pendente |
| Visibilidade / otimização | VisibleOnScreenNotifier2D e repouso por distância; navegação espaçada | Implementado |
| itch.io, descrição e controles | Kit local, screenshots e GIF de 4 s | Kit pronto; publicação pendente |
| GDD em apresentação | PPTX editável de 24 slides e PDF equivalente | Gerados |

**Origem:** Projeto_disciplina_2026_1.0.pdf, especialmente páginas 8–14 e 17–19; mini-gdd_2026_1.0.pdf, páginas 2–17. Os prazos por semanas do material são diretrizes da disciplina; não foi informada uma data de entrega.

## Elementos contados

- Mecânicas: mover, mirar, atirar, esquivar.
- Itens: relíquia vital, chave, cadência, força, leque.
- Inimigos: perseguidor, atirador, bruto, tecelã, chefe.
- Cenário: parede, portão, baú, ninho, área lenta, área de dano.

O ninho é contado uma única vez, como gerador de cenário. Os seis chefes compartilham a mesma classe, mas variam padrão, paleta, PV e velocidade.

## Núcleo do mini GDD preservado

Movimentação e mira independentes; tiro; vitalidade/score que cai com o tempo; relíquias; chaves; portas; baús de loot definido; três power-ups combináveis; geradores ativados por sala; perseguidor; atirador radial; área de lentidão; área de dano; seis fases e fluxo completo de telas.

## Adaptações aprovadas

Tema do caçador, narrativa de ruínas, esquiva com vigor, tecelã e bruto, chefe em toda fase, preparo permanente entre fases, checkpoint e mapa. Valores numéricos e layouts estão documentados no GDD e correspondem aos scripts, sem exigir cópia literal dos índices de tamanho do exemplo.
