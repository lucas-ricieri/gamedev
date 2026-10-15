# Caçador — Arena das Ruínas

Versão 2.0. Roguelike de ação em uma arena única, com ondas sem limite de nível, inimigos que chegam ao longo do tempo, três armas permanentes e um consumível carregado. A direção de arte mantém o caçador e sua paleta; as armas são partes visíveis do equipamento, com rastros de movimento nas suas cores.

## Jogar

- Windows: execute `output/builds/windows/game-by-chat/CacadorDasRuinas.exe` ou extraia `output/Cacador_das_Ruinas_Windows.zip`.
- Projeto: importe `project.godot` no Godot 4.7.2, Compatibility, e pressione F5.
- Web: sirva `output/builds/web` por HTTP. Exemplo: `python -m http.server 8000 --directory output/builds/web`.
- Documentação atual das regras: este README e `docs/ARENA_RULES.md`. Os PDFs e slides da versão 1.0 descrevem a campanha anterior.

## Controles

| Ação | Teclado / mouse | Controle |
|---|---|---|
| Movimento | WASD / setas | Analógico esquerdo |
| Direção do ataque | Mouse | Analógico direito |
| Atacar / usar consumível selecionado | Clique esquerdo | LT / RT |
| Espada / arco / adaga / consumível | 1 / 2 / 3 / 4; também pelos botões do HUD | LB / RB alternam slots |
| Recolher ou trocar consumível próximo | E | X |
| Esquiva | Espaço | A |
| Atributos e detalhes dos itens | Tab | Y |
| Pausa | Esc | Start |

Os slots 1–3 permanecem fixos: espada, arco e adaga. O slot 4 contém no máximo uma granada, armadilha ou poção. E troca o item carregado pelo drop próximo e devolve o anterior ao chão. Selecionar 4 não usa o item: o clique/gatilho o consome. Uma poção com vida cheia é preservada.

## Arena e ondas

A arena não tem labirinto, portões, chaves ou portal de saída. Cada onda agenda `10 + 4 × onda` inimigos, com aviso visual de 0,9 s antes de cada entrada. Novos inimigos continuam aparecendo enquanto os anteriores são combatidos. A simultaneidade tem limite para manter a cena legível e o custo de IA estável; a quantidade total e o nível não têm limite de seis fases.

O intervalo entre entradas diminui com o nível. A vida inimiga segue `vida inicial × (0,86 + 0,14 × onda^1,35)`; o dano de contato cresce 10% do valor inicial por onda. A velocidade cresce até 225 px/s. Arqueiros entram a partir da onda 2, tecelãs a partir da 3 e brutos a partir da 4; a cada cinco ondas surge uma elite. A pressão também aumenta com projéteis e inimigos simultâneos. Fragmentos de cura e consumíveis podem cair após abates.

Ao eliminar todos os inimigos e esgotar todas as entradas da onda, o jogo pausa e mostra cinco cartões: força, vitalidade, destreza, agilidade e vigor. É obrigatório selecionar exatamente dois cartões distintos e confirmar. Cada cartão oferece um aumento do atributo e um bônus específico de arma ou consumível. O bônus é sorteado de forma reproduzível por caçada/onda, e os cartões selecionados podem ser trocados antes de confirmar.

Não há perda de vida passiva pelo tempo. A vida é perdida em combate. Ao concluir a onda, recupera-se 12% da vida máxima. A morte encerra a caçada; uma nova tentativa retorna à onda 1 com atributos iniciais.

## Atributos

| Atributo | Inicial | Aumento por escolha |
|---|---|---|
| Força | 20 dano base | +4 |
| Vitalidade | 140 vida máxima | +25 de máximo e cura 25 |
| Destreza | ×1,00 velocidade de ataque | +0,10 no multiplicador |
| Agilidade | 210 px/s | +14 px/s |
| Vigor | 100, regeneração 26/s | +20 de máximo e +2/s |

A esquiva custa 30 de vigor, dura 0,23 s e concede 0,32 s de proteção. Aumentar vigor aumenta a reserva disponível para esquivas; não aumenta seu custo. O intervalo de ataque é o intervalo próprio da arma dividido pela destreza, com mínimo de 0,08 s. Tab apresenta os valores efetivos de cada arma e consumível.

## Armas e consumíveis

| Item | Dano inicial | Ritmo / alcance | Característica |
|---|---|---|---|
| Espada | Força ×1,30 = 26 | 0,52 s / 76 | Corte de 140°, uma aplicação por alvo e por golpe |
| Arco | Força ×1,00 = 20 | 0,62 s / 740 | Flecha a 620 px/s; lançamento na soltura da corda |
| Adaga | Força ×0,70 = 14 | 0,25 s / 48 | Corte de 80°, 25% crítico ×2 |
| Granada | Força ×4 = 80 | Raio 105 | Arremesso na direção da mira, explosão após 0,85 s |
| Armadilha | Força ×2,40 = 48 | Raio 65 / 4 s | Imobiliza e causa dano uma vez ao disparar |
| Poção | 40% da vida máxima | Uso imediato | Não é gasta com vida cheia |

Espada começa com 5% de crítico ×1,7; arco com 8% ×1,7. Bônus específicos modificam multiplicador de dano, alcance, velocidade ou quantidade de flechas, crítico da adaga, raio/dano de granadas, duração/dano de armadilhas e cura de poções. Flechas extras têm limite de cinco, críticos de 75% e cura de poção de 80%.

Paredes bloqueiam golpes e projéteis. Trocar o slot ou esquivar interrompe um ataque em preparação. Flechas lançadas permanecem após impacto/limite de alcance, sem dano repetido; são limpas no início da próxima onda. Os drops de uma onda permanecem durante a seguinte, com no máximo 64 drops no chão.

## Arte e implementação

O caçador usa `assets/art/hunter-spritesheet.png` e `hunter_palette.gdshader`, com as cores aprovadas: `#165E36`, `#094123`, `#E38268`, `#BF0202`, `#010201`. A arma selecionada fica na mão; as outras permanecem visíveis no equipamento. Espada usa um rastro azul aço, adaga usa branco/ciano e arco usa os tons quentes de madeira/corda.

Espada e adaga foram preparadas com a ferramenta integrada image_gen a partir das referências do usuário, em `assets/art/hunter-sword.png` e `assets/art/hunter-dagger.png`. Os prompts estão em `docs/sword-image-prompt.txt` e `docs/dagger-image-prompt.txt`. Os PNGs permanecem como fonte; o motor faz rotação, poses, montagem no corpo e rastro, sem alterar as cores do caçador.

| Script | Papel |
|---|---|
| `main.gd` | Slots, HUD, menus, 2 de 5 melhorias, checkpoint e encerramento |
| `run_stats.gd` | Atributos, valores por item, bônus e serialização |
| `arena_world.gd` | Arena, entradas temporizadas, drops e encerramento da onda |
| `arena_enemy.gd` | Tipos de inimigo, escalonamento e combate |
| `player.gd` | Movimento, esquiva, ataques, crítico e troca de arma |
| `weapon_rig.gd` | Equipamento visível e borrões nas cores das armas |
| `hunter_animations.gd` | Frames alinhados e material comum do caçador |
| `projectile.gd` | Flechas e ataques à distância dos inimigos |
| `special_effect.gd` | Granada e armadilha |
| `sound.gd` | Música e efeitos |

Os scripts da campanha anterior e suas artes foram preservados; a cena principal agora usa os scripts de arena. Não rode os geradores procedurais para recriar os PNGs: eles só recriam os SVGs e WAVs antigos. O efeito de corte possui gerador em `tools/create_sword_sfx.py`.

## Checkpoint e exportação

`user://hunt_arena_v2.json` salva os atributos, bônus, onda, arma selecionada, consumível e estado das escolhas. Continuar uma onda em combate a reinicia a partir do início; continuar no intervalo restaura os cartões e escolhas pendentes sem aplicar bônus duas vezes. O save da campanha v1 não é sobrescrito. Ao morrer, o checkpoint da caçada é limpo.

Os presets Windows Desktop e Web são os mesmos, com templates 4.7.2 em `.tools/export-templates`. Os exports usam Compatibility; Web não usa threads. Para exportar:

```powershell
godot --headless --path . --export-release "Windows Desktop" "output/builds/windows/game-by-chat/CacadorDasRuinas.exe"
godot --headless --path . --export-release "Web" "output/builds/web/index.html"
```

Não publique `.tools` nem `.godot`. A publicação externa não é parte desta alteração.

## Verificação

`tools/verify_arena.gd` executa as verificações de slots por teclas reais, três armas, flechas persistentes, troca e uso de consumíveis, efeitos das cinco melhorias, bônus por item, restauração de escolhas após JSON, ondas 50/51 e avisos temporizados de entrada. Em modo com janela também verifica coordenadas do mouse após o redimensionamento da tela e produz capturas para conferir o HUD e a arte.

```powershell
godot --headless --path . --script tools/verify_arena.gd --quit-after 1200 -- --capture-level 1
```

O modo de captura/verificação não sobrescreve o save do jogador. A confirmação é a linha `ARENA_VERIFIED`; erros de script e asserções também precisam ser conferidos no log.
