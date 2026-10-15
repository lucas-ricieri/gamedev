# Caçador das Ruínas — GDD 1.0

10 de outubro de 2026. Adaptação para caçador aprovada pelo usuário.

## 1. Caçador das Ruínas

- Aventura de ação top down / twin-stick shooter.
- Um caçador atravessa seis ruínas para devolver a aurora à floresta.
- Godot 4.7.2 • Windows e Web • um jogador

**Detalhes e fontes:** Adaptação aprovada pelo usuário em 10/10/2026. Mini GDD Maze Shooter é a base didática; não é um documento de um jogo de caçador pronto. Identificação acadêmica depende do nome completo a ser informado pelo responsável.

## 2. Uma caçada contra o tempo

- Premissa: uma maldição desperta criaturas nas antigas ruínas. O caçador precisa destruir seus seis guardiões.
- Objetivo principal: derrotar o chefe de cada fase e alcançar o portal. A sexta vitória encerra a campanha.
- Objetivos de apoio: abrir baús, buscar chaves, destruir ninhos e administrar vitalidade e vigor.
- Público: jogadores de ação 2D que gostam de esquiva, exploração curta e progressão clara.
- Escopo: campanha finita; mapas fixos; dificuldade progressiva; sem multiplayer.

**Detalhes e fontes:** Conceito, plataforma e estrutura derivam do mini-gdd_2026_1.0.pdf, pp. 2–5, e do pedido de adaptação do usuário. A narrativa e os chefes são novos.

## 3. Explorar, caçar, recuperar, avançar

- Explore a sala e encontre a chave.
- Mire enquanto se move; role para evitar impactos.
- Colete loot e interrompa os ninhos geradores.
- Abra o portão, enfrente o chefe e entre no portal.

**Detalhes e fontes:** Captura real do projeto em Godot, fase 1. Objetos são coletados ao encostar. O portal fica inativo até a morte do chefe. A vitalidade une sobrevivência e recurso de progressão.

## 4. Mira e movimento independentes

- Movimento: oito direções no teclado e 360° no analógico; velocidade base de 200 px/s.
- Mira: posição do mouse ou analógico direito. O caçador conserva a última direção da mira no controle.
- Disparo: projétil a 720 px/s, 20 de dano base, intervalo de 0,32 s; paredes bloqueiam tiros.
- Esquiva: 0,23 s a 480 px/s; 0,32 s de invulnerabilidade; custa 30 de vigor; recarga de 0,9 s.
- Vigor: máximo 100, regeneração de 25/s. Dano recebido dá 0,7 s de proteção.

**Detalhes e fontes:** Fonte da implementação: scripts/player.gd e scripts/projectile.gd. Valores são parâmetros iniciais de balanceamento; assistência do Codex na implementação.

## 5. Teclado, mouse e controle

| Ação | Teclado / mouse | Controle |
| --- | --- | --- |
| Mover | WASD ou setas | Analógico esquerdo |
| Mirar | Mouse | Analógico direito |
| Atirar | Clique esquerdo | LT ou RT |
| Esquivar | Espaço | A |
| Mapa | Tab | Y |
| Pausar / voltar | Esc | Start / B |
| Menus | Setas + Enter / mouse | Direcional / analógico + A |

**Detalhes e fontes:** Mapeamento em scripts/main.gd; menus utilizam foco nativo do Godot. Implementado para gamepad padrão. Validação com controle físico ainda depende de um dispositivo conectado.

## 6. A vitalidade sustenta a caçada

- A campanha começa com 600 de vitalidade. Ela cai 1,5 por segundo durante o gameplay.
- Relíquia vital: +90. Inimigo comum: +12. Ninho destruído: +42 no total. Chefe: +140.
- Completar uma fase concede mais +120. Entre fases, escolha +4 de dano, +12 px/s ou +100 de vitalidade.
- Contato causa 20–45 de dano conforme o inimigo. Áreas perigosas aplicam 18 a cada janela de 0,8 s.
- A chave é obtida num baú da sala inicial e consumida por um portão. Loot não ocupa inventário.
- Ao perder, retome o checkpoint do início da fase com pelo menos 400 de vitalidade.

**Detalhes e fontes:** scripts/main.gd: collect, clear_level, restore_run; scripts/enemy.gd: hurt; scripts/world.gd: hazard_tick. A vitalidade pode ultrapassar 900; a barra representa uma faixa visual e o número mostra o valor exato.

## 7. Três efeitos que se combinam

| Amuleto | Regra | Entrada |
| --- | --- | --- |
| Cadência | Intervalo de tiro: 0,13 s | Fase 2 |
| Força | Dano: 60 + melhoria permanente | Fase 3 |
| Leque | 3 tiros: ângulos −0,23 / 0 / +0,23 rad | Fase 5 |
| Duração | 16 s; nova coleta renova o tempo | Todas as coletas |
| Combinação | Cadência + força + leque simultâneos | Fases 5 e 6 |

**Detalhes e fontes:** Base: mini GDD, pp. 9–10 e 16. Ajustes: duração explícita e valores em px/s; força multiplica o dano base por três antes do bônus permanente.

## 8. Baús, portões, ninhos e áreas

- Baú: loot definido por instância, aberto automaticamente a menos de 48 px; não volta a fechar.
- Portão: obstáculo sólido de duas células; uma chave o abre por aproximação. A navegação é atualizada.
- Ninho: 120 PV. É ativado quando o caçador entra na sala; gera criaturas em intervalos de 5,0 a 3,5 s.
- Lama / gelo: multiplica a velocidade por 0,52. Brasas / espinhos: dano periódico; esquiva permite atravessar.
- Portal: marca a saída da arena. Só avança depois da derrota do chefe.
- Mapa: mostra corredores, baús, portão, jogador e portal; Y ou Tab amplia a visão.

**Detalhes e fontes:** Fontes: scripts/world.gd e scripts/minimap.gd; mini GDD, pp. 11–13. Limite de atores usado pelo gerador: 38. Colisões e raycasts usam camadas distintas.

## 9. Percepção, navegação e ataque

- Ativação: criaturas aguardam a entrada na sala; ninhos começam a gerar após essa visita.
- Navegação: AStarGrid2D sobre pisos transitáveis, recalculado a cada 0,38–0,50 s.
- Perseguidor: aproximação direta via caminho e dano de contato. Mais rápido nas fases finais.
- Atirador: aproximação, distância de combate e recuo; linha de visão antes do disparo radial.
- Bruto: aproximação lenta e impacto anunciado por um círculo. Tecelã: prepara três projéteis em leque.
- Chefes: preparação, execução e recuperação. Abaixo de 50% de PV, a recarga acelera em 50%.

**Detalhes e fontes:** A IA é baseada em regras e estados simples; não utiliza modelo de linguagem nem serviço online. scripts/enemy.gd. Distância e VisibleOnScreenNotifier2D reduzem trabalho fora da câmera.

## 10. Funções distintas em combate

| Entidade | PV | Movimento / ameaça |
| --- | --- | --- |
| Perseguidor | 40 | 72 / 96 / 96 / 120 / 120 / 144 px/s |
| Atirador | 200 / 200 / 300 / 400* | 32 ou 64 px/s; 4 / 6 / 8 / 10 tiros* |
| Bruto | 160 | 65 px/s; impacto de 45 após 0,7 s |
| Tecelã | 60 | 115 px/s; 3 tiros de 22 após 0,65 s |
| Ninho | 120 | Imóvel; gera inimigos da fase |
| Chefe | 320 + 100 × índice | 80 + 8 × índice px/s; índice de 0 a 5 |

* Valores do atirador nas fases 3, 4, 5 e 6.

**Detalhes e fontes:** Valores da implementação em scripts/enemy.gd. Classes de obstáculos adicionais: parede, portão, área lenta e área de dano.

## 11. Seis guardiões das ruínas

- Javali Ancestral: avisa a direção e investe por 0,7 s. A parede interrompe o avanço.
- Matriarca do Brejo: leque direcionado e invocação de perseguidores.
- Guardião das Galerias: anel de projéteis e invocação de tecelãs.
- Cervo de Inverno: arco giratório de tiros e área de dano na posição marcada.
- Colosso da Forja: anel completo e áreas de dano temporárias; arena com brasas e lama.
- Rei sem Aurora: combina investida, anel, invocação de tecelãs e área de dano.

**Detalhes e fontes:** Todos avisam ataques durante 0,85 s. Dano por contato: 45; projétil de chefe: 26. Áreas criadas por chefes duram 3 s. scripts/enemy.gd: boss_update.

## 12. Aprender e enfrentar o terreno

- 1 • Clareira: caminho curto, perseguidor, relíquias e portão. Chefe introduz a investida.
- 2 • Pântano: rota com curva, tecelãs, lama e ninhos. Surge o amuleto da cadência.
- A chave sempre aparece antes do portão obrigatório.
- O primeiro baú vital ensina a recuperar o recurso que diminui com o tempo.

**Detalhes e fontes:** Captura real da arena da fase 2. Fase 1: 42×16 células, 3 salas. Fase 2: 42×28, 4 salas. Mapas em scripts/level_data.gd.

## 13. Galerias do Eco

- Atiradores entram na campanha com 200 PV e quatro projéteis radiais.
- Áreas de dano exigem escolher a rota de aproximação.
- O amuleto da força permite enfrentar alvos mais resistentes.
- Chefe: anel de tiros e tecelãs; use os intervalos de preparação para atacar.

**Detalhes e fontes:** Captura real da fase 3. Mapa 42×28 células, 4 salas. O portão bloqueia o corredor vertical para a arena. Força é 60 de dano base antes das melhorias.

## 14. Santuário da Geada

- Brutos entram na campanha. O golpe anunciado pune a aproximação sem vigor.
- Gelo e áreas de dano combinam lentidão com pressão de projéteis.
- Atiradores passam a seis tiros por ataque.
- Chefe: arco de tiros em rotação e área temporária na posição marcada.

**Detalhes e fontes:** Captura real da fase 4. Mapa 42×28 células, 4 salas, rota vertical e horizontal. Paleta azul e cinza muda a leitura do ambiente.

## 15. Forja das Cinzas

- Ramo opcional com loot recompensa a exploração antes do chefe.
- Todos os inimigos comuns aparecem; atirador com 300 PV e oito tiros.
- Leque entra na campanha e pode combinar com cadência e força.
- Chefe: anel de tiros, áreas temporárias e terreno misto na arena.

**Detalhes e fontes:** Captura real da fase 5. 42×28 células, 5 salas, chefe na sala 3 e sala 4 como ramo opcional. O número da sala é índice zero no código.

## 16. Cidadela do Eclipse

- Rota longa com mudanças de direção e encontros com todo o bestiário.
- Atirador com 400 PV e dez tiros; perseguidor a 144 px/s.
- Rei sem Aurora combina os padrões anteriores e entra em fúria abaixo de 50% de PV.
- Derrote o último guardião e atravesse o portal para ver o encerramento.

**Detalhes e fontes:** Captura real da fase 6. 42×29 células, 5 salas. Chefe com 820 PV, 120 px/s, projéteis de 26, investida e invocações.

## 17. O desafio ganha novas camadas

| Fase | Salas | Ameaça nova | Amuletos | Chefe PV |
| --- | --- | --- | --- | --- |
| 1 | 3 | Perseguidor / portão | — | 320 |
| 2 | 4 | Tecelã / lama | Cadência | 420 |
| 3 | 4 | Atirador / dano | + Força | 520 |
| 4 | 4 | Bruto / terreno misto | Cadência + força | 620 |
| 5 | 5 | Ramo de exploração | + Leque | 720 |
| 6 | 5 | Combinação final | Todos | 820 |

Ninhos: intervalo 5,0 / 4,8 / 4,5 / 4,0 / 3,8 / 3,5 s.

**Detalhes e fontes:** O índice é zero no código. O mini GDD p.16 orienta introdução progressiva; tamanhos e padrões foram adaptados com aprovação do usuário. Esta tabela descreve a implementação atual.

## 18. Informação durante o combate

- HUD: fase, vitalidade numérica, chaves e caçadas; barras de vitalidade e vigor.
- Mapa no canto superior; trilha de objetivo chave → portão → chefe → portal.
- Nome e barra do chefe aparecem somente quando a arena é ativada.
- Mensagens de loot, temporizadores dos amuletos, números de dano e alertas circulares.

**Detalhes e fontes:** Captura real da tela de instruções. Formato 16:9, resolução lógica 960×540, janela 1280×720. Rótulos textuais acompanham as cores de estados.

## 19. Início, campanha e fim

- Splash UTFPR → título → nova caçada ou continuar.
- Menus: instruções, som, créditos e saída; foco navegável com teclado e controle.
- Gameplay → chefe → portal → fase concluída → preparo → próxima fase.
- Vitalidade zero → game over → repetir fase ou menu. Fase 6 → vitória → créditos / reinício.

**Detalhes e fontes:** Captura real da tela final; números zerados porque é uma captura isolada da tela, não um registro de campanha concluída. Fades de 0,22 s para entrada e saída. Pausa suspende a simulação e a perda de vitalidade.

## 20. Assets originais e editáveis

- Visual: pixel art top down; sprites SVG de 32×32 com grade de 2 px, ampliados com filtro nearest.
- Seis paletas de ambiente e guardiões; pisos, paredes, projéteis e perigos desenhados pelo jogo.
- Áudio: seis loops de 16 s e nove efeitos sintetizados em WAV mono, 22.050 Hz.
- Feedback: som para tiro, dano, loot, portão, esquiva, chefe, vitória, derrota e menu.
- Fontes: assets/art e assets/audio. Geração reproduzível em .tools/create_assets.py.
- Referências didáticas: Gauntlet, Alien Breed, SturmFront e Dragon Heart, citadas no mini GDD.

**Detalhes e fontes:** Não foram usados packs externos de sprites ou música. Marca UTFPR é exceção institucional: https://www.utfpr.edu.br/comunicacao/design/marca-da-utfpr/ . Arte e áudio procedurais criados com assistência do Codex; confirmar aceitação dessa forma de autoria na disciplina.

## 21. Godot 2D, PC e navegador

- Motor: Godot 4.7.2 com renderizador Compatibility. Limite de execução: 60 FPS; desempenho real depende do dispositivo.
- Arquitetura: main coordena telas e progresso; world monta mapas; player, enemy e projectile cuidam do combate.
- Navegação: AStarGrid2D; colisões separadas para paredes, jogador e inimigos. Raycasts impedem tiros de atravessar paredes.
- Otimização: limite de projéteis, limite do gerador, atualização de caminhos espaçada e descanso de IA distante.
- Persistência: checkpoint por fase em user://; opção continuar e reinício da fase.
- Exports: Windows x86_64 com PCK embutido; Web sem threads ou extensões. Servir Web via HTTP.

**Detalhes e fontes:** Presets em export_presets.cfg. Meta de 60 FPS não equivale a benchmark. Export sem threads não depende de SharedArrayBuffer; a opção deve ser reavaliada se threads forem habilitadas.

## 22. 20 elementos de gameplay

- 4 mecânicas: mover, mirar, atirar e esquivar.
- 5 itens: relíquia vital, chave, cadência, força e leque.
- 5 inimigos: perseguidor, atirador, bruto, tecelã e chefe.
- 6 elementos de cenário: parede, portão, baú, ninho, área lenta e área de dano.
- Campanha de 6 fases, telas de início e fim, áudio, créditos, instruções, transições e builds PC / Web.
- A disciplina aceita contagem flexível de pelo menos 12 elementos; esta adaptação mantém o núcleo do mini GDD e o amplia.

**Detalhes e fontes:** Fonte: Projeto_disciplina_2026_1.0.pdf, pp. 8–14 (requisitos de export, fases, elementos e telas). Contagem soma 4+5+5+6=20. Ninho conta como cenário gerador e não é contado novamente como inimigo.

## 23. Autoria e rastreabilidade

- Responsável acadêmico: identificação solicitada ao usuário; completar antes da entrega institucional.
- Adaptação do conceito e escolhas de escopo: proposta do usuário, com aprovação da direção caçador.
- Implementação, sprites, áudio e documentação: desenvolvidos com assistência do Codex.
- Base didática: mini-gdd_2026_1.0.pdf e Projeto_disciplina_2026_1.0.pdf, fornecidos pelo usuário.
- Professor identificado no material: Marcos Silvano Almeida • UTFPR, Campo Mourão.
- Godot: MIT. Ferramenta MCP: blentz/godot-mcp, AGPL-3.0. Marca UTFPR: fonte institucional.

**Detalhes e fontes:** As instruções dos PDFs foram tratadas como especificações para o projeto, não como autorização para publicar em conta externa ou afirmar autoria individual dos alunos. Nomes completos e divisão real de funções ainda não foram informados.

## 24. Projeto e material para publicação

- Projeto editável: project.godot, scripts, cena principal, sprites SVG, áudio e presets de export.
- GDD: apresentação editável, PDF de leitura e fonte estruturada com regras e progressão.
- Pacotes: Windows em ZIP; Web em ZIP com index.html na raiz; screenshots e GIF real de gameplay.
- Kit itch.io: descrição, controles, objetivos, créditos e instruções de upload preparados localmente.
- Antes da entrega acadêmica: informar nomes / funções, avaliar balanceamento e jogar com um controle físico.
- Publicação no itch.io e comprovação de FPS em dispositivos-alvo permanecem etapas da entrega institucional.

**Detalhes e fontes:** A publicação externa não foi solicitada diretamente pelo usuário. Itens pendentes são declarados para evitar afirmar validação física ou autoria não realizada. Builds e documentação devem acompanhar a versão dos scripts.
