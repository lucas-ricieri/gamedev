extends Node
const Stats = preload("res://scripts/run_stats.gd")
const SAVE = "user://hunt_arena_v2.json"
var stats = Stats.new()
var state = "title"
var wave = 1
var health = 140.0
var kills = 0
var elapsed = 0.0
var run_seed = 0
var selected_slot = 1
var carried = ""
var world
var player
var sound
var last_device = "mouse"
var checkpoint: Dictionary = {}
var offers: Array = []
var choices: Array = []
var layer: CanvasLayer
var ui: Control
var health_bar: ProgressBar
var stamina_bar: ProgressBar
var wave_text: Label
var weapon_text: Label
var attributes_text: Label
var pickup_text: Label
var notice: Label
var notice_time = 0.0
var slot_buttons: Array = []
var slot_labels: Array = []
var offer_buttons: Array = []
var choice_badges: Array = []
var choice_text: Label
var confirm_button: Button
var quitting = false
var icon_cache: Dictionary = {}
var capture_mode = false

func _ready():
 process_mode = Node.PROCESS_MODE_ALWAYS
 get_tree().auto_accept_quit = false
 setup_inputs()
 load_save()
 sound = preload("res://scripts/sound.gd").new()
 add_child(sound)
 layer = CanvasLayer.new()
 add_child(layer)
 ui = Control.new()
 ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 layer.add_child(ui)
 var args = OS.get_cmdline_user_args()
 capture_mode = "--capture-level" in args or "--capture-screen" in args
 if "--capture-level" in args:
  reset_run()
  wave = maxi(1,int(args[args.find("--capture-level")+1]))
  start_arena()
  if "--capture-out" in args:
   await get_tree().create_timer(4.5).timeout
   await RenderingServer.frame_post_draw
   get_viewport().get_texture().get_image().save_png(args[args.find("--capture-out")+1])
   quit_game()
 elif "--capture-screen" in args:
  var screen = args[args.find("--capture-screen")+1]
  if screen == "instructions": show_instructions()
  elif screen == "upgrades":
   reset_run(); start_arena(); complete_wave()
  elif screen == "stats":
   reset_run(); start_arena(); show_stats()
  else: show_title()
  await get_tree().create_timer(0.4).timeout
  await RenderingServer.frame_post_draw
  get_viewport().get_texture().get_image().save_png(args[args.find("--capture-out")+1])
  quit_game()
 else:
  show_title()

func setup_inputs():
 var mapping = {"move_left":[KEY_A,KEY_LEFT],"move_right":[KEY_D,KEY_RIGHT],"move_up":[KEY_W,KEY_UP],"move_down":[KEY_S,KEY_DOWN],"roll":[KEY_SPACE],"interact":[KEY_E],"stats":[KEY_TAB],"pause":[KEY_ESCAPE],"slot_1":[KEY_1],"slot_2":[KEY_2],"slot_3":[KEY_3],"slot_4":[KEY_4]}
 for action in mapping:
  if not InputMap.has_action(action): InputMap.add_action(action,0.18)
  for key in mapping[action]:
   var event = InputEventKey.new()
   event.physical_keycode = key
   InputMap.action_add_event(action,event)
 for pair in [["move_left",JOY_AXIS_LEFT_X,-1.0],["move_right",JOY_AXIS_LEFT_X,1.0],["move_up",JOY_AXIS_LEFT_Y,-1.0],["move_down",JOY_AXIS_LEFT_Y,1.0]]:
  var event = InputEventJoypadMotion.new()
  event.axis = pair[1]; event.axis_value = pair[2]
  InputMap.action_add_event(pair[0],event)
 for pair in [["roll",JOY_BUTTON_A],["interact",JOY_BUTTON_X],["stats",JOY_BUTTON_Y],["pause",JOY_BUTTON_START],["previous_slot",JOY_BUTTON_LEFT_SHOULDER],["next_slot",JOY_BUTTON_RIGHT_SHOULDER]]:
  if not InputMap.has_action(pair[0]): InputMap.add_action(pair[0])
  var event = InputEventJoypadButton.new()
  event.button_index = pair[1]
  InputMap.action_add_event(pair[0],event)
 if not InputMap.has_action("fire"): InputMap.add_action("fire")
 var mouse = InputEventMouseButton.new()
 mouse.button_index = MOUSE_BUTTON_LEFT
 InputMap.action_add_event("fire",mouse)
 for axis in [JOY_AXIS_TRIGGER_LEFT,JOY_AXIS_TRIGGER_RIGHT]:
  var event = InputEventJoypadMotion.new()
  event.axis = axis; event.axis_value = 1.0
  InputMap.action_add_event("fire",event)

func _input(event):
 if event is InputEventMouseMotion or event is InputEventMouseButton: last_device = "mouse"
 elif event is InputEventJoypadMotion and absf(event.axis_value)>0.25: last_device = "pad"
 elif event is InputEventJoypadButton: last_device = "pad"
 if event.is_action_pressed("pause"):
  if state == "playing": show_pause()
  elif state in ["paused","stats"]: resume()
  elif state in ["instructions","credits","settings"]: show_title()
 if event.is_action_pressed("stats"):
  if state == "playing": show_stats()
  elif state == "stats": resume()
 if state == "playing":
  for index in range(1,5):
   if event.is_action_pressed("slot_%d" % index): select_slot(index)
  if event.is_action_pressed("previous_slot"): select_slot(posmod(selected_slot-2,4)+1)
  if event.is_action_pressed("next_slot"): select_slot(selected_slot%4+1)
  if event.is_action_pressed("interact"): world.pickup_nearest()

func select_slot(index: int):
 if state != "playing" or index < 1 or index > 4: return
 if selected_slot != index:
  selected_slot = index
  player.cancel_attack()
  sound.play_sfx("click")
  player.refresh_equipment()
  refresh_hud()

func weapon_id() -> String:
 return Stats.WEAPONS[selected_slot-1] if selected_slot <= 3 else ""

func pointer_on_hud() -> bool:
 # Canvas coordinates account for the 960x540 game being displayed in a
 # larger window; raw viewport pixels would block the lower arena.
 return last_device == "mouse" and not world.BOUNDS.has_point(player.get_global_mouse_position())

func _process(delta):
 if state != "playing": return
 elapsed += delta
 notice_time = maxf(0.0,notice_time-delta)
 if health <= 0:
  game_over()
  return
 refresh_hud()

func icon(id: String) -> Texture2D:
 if icon_cache.has(id): return icon_cache[id]
 var path = {"sword":"hunter-sword.png","dagger":"hunter-dagger.png","bow":"bow.svg","grenade":"grenade.svg","trap":"trap.svg","potion":"potion.svg"}.get(id,"potion.svg")
 var texture = load("res://assets/art/"+path)
 if id in ["sword","dagger"]:
  var atlas = AtlasTexture.new()
  atlas.atlas = texture
  atlas.region = texture.get_image().get_used_rect()
  texture = atlas
 icon_cache[id] = texture
 return texture

func wipe_ui():
 for child in ui.get_children():
  ui.remove_child(child)
  child.queue_free()
 slot_buttons.clear(); slot_labels.clear(); offer_buttons.clear(); choice_badges.clear()

func text_at(value: String, pos: Vector2, size: int = 20, color: Color = Color("ece4cb"), width: float = 880) -> Label:
 var label = Label.new()
 label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 label.add_theme_font_size_override("font_size",size)
 label.add_theme_color_override("font_color",color)
 label.text = value; label.position = pos; label.size = Vector2(width,40)
 ui.add_child(label)
 return label

func style(color: Color, border: Color = Color("657f74")) -> StyleBoxFlat:
 var box = StyleBoxFlat.new()
 box.bg_color = color; box.border_color = border
 box.set_border_width_all(2); box.set_corner_radius_all(5)
 return box

func button(value: String, pos: Vector2, callback: Callable, width: float = 290, height: float = 44) -> Button:
 var control = Button.new()
 control.text = value; control.position = pos; control.size = Vector2(width,height)
 control.add_theme_font_size_override("font_size",18)
 control.add_theme_stylebox_override("normal",style(Color("29474b")))
 control.add_theme_stylebox_override("hover",style(Color("3e6259"),Color("eed297")))
 control.add_theme_stylebox_override("focus",style(Color("3e6259"),Color("eed297")))
 control.pressed.connect(callback)
 ui.add_child(control)
 return control

func background():
 var rect = ColorRect.new()
 rect.color = Color("15272f")
 rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 ui.add_child(rect)
 for index in range(13):
  var stripe = ColorRect.new()
  stripe.color = Color("1c333b"); stripe.position = Vector2(index*95-200,0)
  stripe.size = Vector2(12,700); stripe.rotation = -0.4
  stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
  ui.add_child(stripe)

func show_title():
 get_tree().paused = false
 state = "title"
 if is_instance_valid(world): world.hide()
 wipe_ui(); background()
 sound.song(0)
 text_at("CAÇADOR",Vector2(52,50),60,Color("efd29c"))
 text_at("ARENA DAS RUÍNAS",Vector2(55,128),35)
 text_at("Três armas. Uma arena. Ondas sem fim.",Vector2(58,187),19,Color("9ab4a4"))
 var hero = TextureRect.new()
 hero.texture = preload("res://scripts/hunter_animations.gd").create_frames().get_frame_texture("idle_down",0)
 hero.material = preload("res://scripts/hunter_animations.gd").create_material()
 hero.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
 hero.position = Vector2(695,105); hero.size = Vector2(170,170)
 hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 ui.add_child(hero)
 for index in range(3):
  var image = TextureRect.new()
  image.texture = icon(Stats.WEAPONS[index]); image.position = Vector2(653+index*70,292)
  image.size = Vector2(64,44); image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  ui.add_child(image)
 button("Nova caçada",Vector2(58,252),func(): reset_run(); start_arena()).grab_focus()
 if not checkpoint.is_empty():
  button("Continuar • onda %d" % int(checkpoint.get("wave",1)),Vector2(58,308),continue_run)
 button("Como jogar",Vector2(371,252),show_instructions,240)
 button("Som e opções",Vector2(371,308),show_settings,240)
 button("Créditos",Vector2(371,364),show_credits,240)
 button("Sair",Vector2(58,420),quit_game)
 text_at("1 Espada   2 Arco   3 Adaga   4 Consumível",Vector2(647,360),15,Color("d8d1b9"),278)
 text_at("Cada onda vencida: escolha 2 de 5 melhorias.",Vector2(58,492),16,Color("95aa9d"))

func show_instructions():
 state = "instructions"; wipe_ui(); background()
 text_at("GUIA DA ARENA",Vector2(44,28),34,Color("efd29c"))
 text_at("MOVIMENTO E COMBATE\nWASD / setas: mover • mouse: mirar\nClique / LT ou RT: atacar ou usar slot 4\n1 Espada • corte amplo de perto\n2 Arco • flechas à distância\n3 Adaga • rápida, curta e crítica\n4 Consumível • um item por vez\nEspaço / A: esquiva • custa 30 vigor\nE / X: recolher ou trocar consumível\nTab / Y: atributos • Esc / Start: pausa\nLB / RB: alternar slots no controle",Vector2(44,98),18,Color("ece4cb"),430)
 text_at("SOBREVIVA ÀS ONDAS\nAvisos vermelhos indicam novas entradas.\nElimine todos os inimigos para avançar.\nNovos tipos e elites nas ondas seguintes.\nCada onda aumenta vida, dano e pressão.\n\nEVOLUÇÃO\nEscolha exatamente 2 de 5 atributos.\nCada escolha inclui um bônus de item.\nGranada: explosão • armadilha: aprisiona\nPoção: cura • fragmentos: cura ao tocar\nAo morrer, a caçada recomeça da onda 1.",Vector2(498,98),18,Color("bfd0bc"),424)
 button("Voltar",Vector2(44,475),show_title).grab_focus()

func show_credits():
 state = "credits"; wipe_ui(); background()
 text_at("CRÉDITOS",Vector2(44,35),34,Color("efd29c"))
 text_at("Conceito e referências de personagem e armas: usuário.\nImplementação, animação, arte técnica e áudio: assistência do Codex.\n\nGodot 4.7.2 • licença MIT\nSpritesheet, espada e adaga: image_gen a partir das referências.\nPaleta fixa do caçador • armas visíveis e rastros em suas cores.\nDemais sprites SVG e áudio sintetizados para o projeto.\n\nArena com ondas infinitas, três armas e um consumível.\nInspiração de gênero: roguelike de ação e progressão por atributos.\nEquipe acadêmica e divisão de funções: ainda a preencher.",Vector2(44,103),20,Color("ece4cb"),870)
 button("Voltar",Vector2(44,475),show_title).grab_focus()

func show_settings():
 state = "settings"; wipe_ui(); background()
 text_at("SOM E OPÇÕES",Vector2(44,50),34)
 var slider = HSlider.new()
 slider.position = Vector2(44,190); slider.size = Vector2(500,40)
 slider.min_value=0; slider.max_value=1; slider.step=0.05; slider.value=sound.volume
 slider.value_changed.connect(sound.set_volume); ui.add_child(slider)
 text_at("Volume geral",Vector2(44,125),22)
 button("Tela cheia / janela",Vector2(44,280),func(): DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN),330)
 button("Voltar",Vector2(44,420),show_title)

func reset_run():
 stats = Stats.new(); wave=1; health=stats.base.vitality; kills=0; elapsed=0
 run_seed = randi(); selected_slot=1; carried=""; choices.clear(); offers.clear()

func start_arena(spawn_wave: bool = true):
 get_tree().paused = false
 if is_instance_valid(world):
  remove_child(world); world.queue_free()
 state = "playing"
 world = preload("res://scripts/arena_world.gd").new()
 world.game = self; world.process_mode = Node.PROCESS_MODE_PAUSABLE
 add_child(world)
 wipe_ui(); make_hud()
 sound.song((wave-1)%6)
 if spawn_wave:
  world.begin_wave()
  store_checkpoint("playing")
  toast("ONDA %d • prepare-se!" % wave,2.0)

func make_bar(pos: Vector2, width: float, color: Color) -> ProgressBar:
 var bar = ProgressBar.new()
 bar.show_percentage=false
 bar.add_theme_stylebox_override("background",style(Color("101a20"),Color("101a20")))
 bar.add_theme_stylebox_override("fill",style(color,color))
 bar.position=pos; bar.size=Vector2(width,11)
 ui.add_child(bar); return bar

func make_hud():
 var bg = ColorRect.new()
 bg.color=Color(0.04,0.08,0.10,0.94); bg.size=Vector2(960,84)
 bg.mouse_filter=Control.MOUSE_FILTER_IGNORE; ui.add_child(bg)
 wave_text = text_at("",Vector2(26,10),18,Color("efd29c"),400)
 health_bar = make_bar(Vector2(26,46),185,Color("95b796"))
 stamina_bar = make_bar(Vector2(238,46),139,Color("d6bd7f"))
 weapon_text = text_at("",Vector2(430,12),16,Color("e9e2cb"),451)
 attributes_text = text_at("",Vector2(26,64),12,Color("b7c7b7"),850)
 button("Ⅱ",Vector2(904,16),show_pause,36,37)
 for index in range(4):
  var x = 36+index*223
  var slot = index+1
  slot_buttons.append(button("",Vector2(x,465),func(): select_slot(slot),215,61))
  slot_labels.append(text_at("",Vector2(x+61,474),15,Color("ece4cb"),146))
 pickup_text = text_at("",Vector2(28,427),14,Color("efd29c"),880)
 notice = text_at("",Vector2(280,393),17,Color("efe2bc"),460)
 refresh_hud()

func refresh_hud():
 if not is_instance_valid(health_bar) or not is_instance_valid(player): return
 health_bar.max_value=stats.base.vitality; health_bar.value=maxf(0,health)
 stamina_bar.max_value=stats.base.vigor; stamina_bar.value=player.stamina
 wave_text.text="ONDA %d  •  ATIVOS %d  •  RESTAM %d" % [wave,world.alive(),world.pending+world.telegraphs.size()+world.alive()]
 attributes_text.text="VIDA %d/%d    VIGOR %d/%d    FOR %d   DES ×%.2f   AGI %d    TAB: atributos" % [maxi(0,int(health)),int(stats.base.vitality),int(player.stamina),int(stats.base.vigor),int(stats.base.strength),stats.base.dexterity,int(stats.base.agility)]
 var id=weapon_id()
 if id != "":
  weapon_text.text="%s  •  %.0f dano  •  %.2f ataques/s\n%.0f alcance  •  %.0f%% crítico" % [Stats.NAMES[id],stats.damage(id),1.0/stats.attack_interval(id),stats.weapons[id].range,stats.weapons[id].crit*100]
 else:
  weapon_text.text="CONSUMÍVEL  •  "+(Stats.NAMES.get(carried,"Slot vazio"))+"\nE: recolher ou trocar • clique: usar"
 for index in range(slot_buttons.size()):
  var current_id=Stats.WEAPONS[index] if index<3 else carried
  slot_buttons[index].add_theme_stylebox_override("normal",style(Color("405b47") if selected_slot==index+1 else Color("1c3037"),Color("efd29c") if selected_slot==index+1 else Color("52695f")))
  var image=slot_buttons[index].get_node_or_null("Icon")
  if image == null:
   image=TextureRect.new(); image.name="Icon"; image.position=Vector2(8,8); image.size=Vector2(47,45)
   image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
   image.mouse_filter=Control.MOUSE_FILTER_IGNORE; slot_buttons[index].add_child(image)
  image.texture=icon(current_id) if current_id!="" else null
  image.pivot_offset=Vector2(23.5,22.5)
  image.rotation=-0.65 if current_id in ["sword","dagger"] else 0.0
  slot_labels[index].text="%d · %s\n%s" % [index+1,Stats.NAMES.get(current_id,"VAZIO").to_upper(),"Clique: usar" if index==3 and current_id!="" else ("E: recolher" if index==3 else ("EQUIPADA" if selected_slot==index+1 else "Tecla %d" % (index+1)))]
 if world.nearest >= 0 and world.nearest < world.pickups.size():
  pickup_text.text="E / X: "+("trocar por " if carried!="" else "recolher ")+Stats.NAMES[world.pickups[world.nearest].kind]
 else: pickup_text.text="1–4: slots   •   E: recolher   •   Espaço: esquiva   •   Tab: atributos"
 notice.text="" if notice_time<=0 else notice.text

func toast(value: String, duration: float = 2.0):
 notice_time=duration
 if is_instance_valid(notice): notice.text=value

func enemy_defeated(enemy):
 kills += 1
 var roll = randf()
 if enemy.kind=="boss":
  world.add_pickup(world.clamp_point(enemy.position+Vector2(-20,0)),"heart")
  world.add_pickup(world.clamp_point(enemy.position+Vector2(20,0)),["grenade","trap","potion"].pick_random())
 elif roll<0.28:
  world.add_pickup(world.clamp_point(enemy.position),"heart")
 elif roll<0.48:
  world.add_pickup(world.clamp_point(enemy.position),["grenade","trap","potion"].pick_random())

func shoot(pos: Vector2,direction: Vector2,amount: float,friendly: bool, speed: float = 0.0, reach: float = 740.0):
 if get_tree().get_nodes_in_group("bolts").size()>=140: return
 var projectile=preload("res://scripts/projectile.gd").new()
 projectile.game=self; projectile.position=pos; projectile.direction=direction; projectile.damage=amount; projectile.friendly=friendly
 projectile.speed=speed if speed>0 else (620.0 if friendly else minf(430,230+wave*4))
 projectile.life=reach/projectile.speed if friendly else 4.5
 projectile.add_to_group("bolts"); world.add_child(projectile)

func use_special() -> bool:
 if carried=="": return false
 if carried=="potion":
  if health>=stats.base.vitality:
   toast("Vida cheia • poção preservada"); return false
  health=minf(stats.base.vitality,health+stats.base.vitality*stats.specials.potion.heal)
  sound.play_sfx("loot")
 else:
  var effect=preload("res://scripts/special_effect.gd").new()
  effect.game=self; effect.kind=carried; effect.origin=player.position
  effect.target=world.clamp_point(player.position+player.aim*230)
  if carried=="grenade":
   effect.damage=stats.base.strength*stats.specials.grenade.damage; effect.radius=stats.specials.grenade.radius
  else:
   effect.damage=stats.base.strength*stats.specials.trap.damage; effect.radius=stats.specials.trap.radius; effect.duration=stats.specials.trap.duration
  world.add_child(effect)
  sound.play_sfx("roll")
 carried=""
 return true

func float_text(pos: Vector2,value: String,color: Color):
 if not is_instance_valid(world): return
 var label=Label.new()
 label.text=value; label.position=pos-Vector2(10,40); label.z_index=20
 label.add_theme_font_size_override("font_size",13); label.add_theme_color_override("font_color",color)
 world.add_child(label)
 var tween=label.create_tween().set_parallel(true)
 tween.tween_property(label,"position",label.position-Vector2(0,22),0.55)
 tween.tween_property(label,"modulate:a",0.0,0.55)
 tween.chain().tween_callback(label.queue_free)

func complete_wave():
 if state!="playing": return
 state="upgrade"; get_tree().paused=true
 player.cancel_attack()
 health=minf(stats.base.vitality,health+stats.base.vitality*0.12)
 offers=stats.offers(run_seed,wave); choices=[]
 store_checkpoint("upgrade")
 sound.play_sfx("clear")
 show_upgrades()

func show_upgrades():
 state="upgrade"; get_tree().paused=true
 wipe_ui(); background()
 text_at("ONDA %d CONCLUÍDA" % wave,Vector2(44,35),34,Color("efd29c"))
 text_at("Escolha exatamente 2 atributos. Cada cartão inclui um bônus para arma ou consumível.",Vector2(44,92),17,Color("b9ccb9"),870)
 choice_text=text_at("",Vector2(44,127),17,Color("efd29c"))
 for index in range(offers.size()):
  var x=44+index*178
  var card_index=index
  offer_buttons.append(button("",Vector2(x,168),func(): toggle_choice(card_index),166,254))
  var offer=offers[index]
  text_at(Stats.LABELS[offer.attribute],Vector2(x+12,186),17,Color("efd29c"),143)
  text_at(Stats.DESCRIPTIONS[offer.attribute],Vector2(x+12,232),16,Color("ece4cb"),143)
  text_at("BÔNUS DO ITEM\n"+offer.extra.text,Vector2(x+12,310),14,Color("b6d1ca"),143)
  var badge=text_at("",Vector2(x+12,400),12,Color("efd29c"),143)
  badge.size.y=18
  choice_badges.append(badge)
 confirm_button=button("Aplicar e iniciar onda %d" % (wave+1),Vector2(590,462),confirm_upgrades,327,45)
 button("Salvar e sair ao menu",Vector2(44,462),func(): store_checkpoint("upgrade"); show_title(),270,45)
 refresh_choices()
 offer_buttons[0].grab_focus()

func toggle_choice(index: int):
 if state!="upgrade" or index<0 or index>=offers.size(): return
 if index in choices: choices.erase(index)
 elif choices.size()<2: choices.append(index)
 refresh_choices()
 store_checkpoint("upgrade")

func refresh_choices():
 if not is_instance_valid(choice_text): return
 choice_text.text="Selecionadas: %d / 2 • você pode desmarcar um cartão para trocar a escolha." % choices.size()
 for index in range(offer_buttons.size()):
  offer_buttons[index].add_theme_stylebox_override("normal",style(Color("49644b") if index in choices else Color("213b40"),Color("efd29c") if index in choices else Color("52695f")))
  choice_badges[index].text="SELECIONADO" if index in choices else ""
 confirm_button.disabled=choices.size()!=2

func confirm_upgrades():
 if state!="upgrade" or choices.size()!=2: return
 for index in choices:
  var offer=offers[index]
  stats.apply_offer(offer)
  if offer.attribute=="vitality": health=minf(stats.base.vitality,health+25)
 wave += 1
 choices.clear(); offers.clear()
 get_tree().paused=false
 state="playing"
 wipe_ui(); make_hud()
 player.stamina=stats.base.vigor
 world.begin_wave()
 sound.song((wave-1)%6)
 store_checkpoint("playing")
 toast("ONDA %d • inimigos mais fortes" % wave,2.0)

func show_pause():
 if state!="playing": return
 state="paused"; get_tree().paused=true
 wipe_ui(); background()
 text_at("CAÇADA PAUSADA",Vector2(44,55),36,Color("efd29c"))
 text_at("Onda %d • %d inimigos abatidos\nContinuar pelo menu recomeça a onda a partir do checkpoint." % [wave,kills],Vector2(44,130),20)
 button("Retomar",Vector2(44,244),resume).grab_focus()
 button("Atributos e itens",Vector2(44,303),show_stats)
 button("Salvar e sair ao menu",Vector2(44,362),show_title)

func show_stats():
 state="stats"; get_tree().paused=true
 wipe_ui(); background()
 text_at("ATRIBUTOS E EQUIPAMENTO",Vector2(44,28),30,Color("efd29c"))
 text_at("FORÇA  %.0f dano base\nVITALIDADE  %.0f vida máxima\nDESTREZA  ×%.2f ataque\nAGILIDADE  %.0f movimento\nVIGOR  %.0f máximo / %.0f por segundo\nEsquiva: custo 30 • proteção 0,32 s" % [stats.base.strength,stats.base.vitality,stats.base.dexterity,stats.base.agility,stats.base.vigor,stats.regen],Vector2(44,98),18,Color("ece4cb"),340)
 var lines=""
 for id in Stats.WEAPONS:
  var w=stats.weapons[id]
  lines+="%s: %.0f dano • %.2f ataques/s\nAlcance %.0f • crítico %.0f%% ×%.1f\n" % [Stats.NAMES[id],stats.damage(id),1.0/stats.attack_interval(id),w.range,w.crit*100,w.crit_mult]
  if id=="bow": lines+="%d flecha(s) • velocidade %.0f\n" % [int(w.arrows),w.speed]
 text_at(lines,Vector2(411,98),17,Color("c5ded5"),490)
 text_at("ESPECIAIS\nGranada: %.0f dano / %.0f raio • Armadilha: %.0f dano / %.1f s\nPoção: %.0f%% da vida máxima • capacidade: um consumível" % [stats.base.strength*stats.specials.grenade.damage,stats.specials.grenade.radius,stats.base.strength*stats.specials.trap.damage,stats.specials.trap.duration,stats.specials.potion.heal*100],Vector2(44,347),17,Color("dccb9d"),870)
 button("Voltar à arena • Tab / Esc",Vector2(44,475),resume,335).grab_focus()

func resume():
 state="playing"; get_tree().paused=false
 wipe_ui(); make_hud()

func game_over():
 if state!="playing": return
 state="over"; get_tree().paused=true
 checkpoint={}; save_run()
 sound.play_sfx("death")
 wipe_ui(); background()
 text_at("A CAÇADA TERMINOU",Vector2(44,68),38,Color("e7ac8c"))
 text_at("Onda %d • %d inimigos abatidos • %d min %02d s\nUma nova tentativa começa com os atributos iniciais." % [wave,kills,int(elapsed/60),int(elapsed)%60],Vector2(44,166),22)
 button("Nova caçada",Vector2(44,290),func(): reset_run(); start_arena(),340).grab_focus()
 button("Menu principal",Vector2(44,352),show_title,340)

func store_checkpoint(phase: String):
 checkpoint={"version":2,"phase":phase,"wave":wave,"health":health,"kills":kills,"elapsed":elapsed,"seed":run_seed,"slot":selected_slot,"carried":carried,"stats":stats.serialize(),"offers":offers.duplicate(true),"choices":choices.duplicate()}
 save_run()

func save_run():
 if capture_mode: return
 var file=FileAccess.open(SAVE,FileAccess.WRITE)
 if file: file.store_string(JSON.stringify(checkpoint))

func load_save():
 if not FileAccess.file_exists(SAVE): return
 var value=JSON.parse_string(FileAccess.get_file_as_string(SAVE))
 if value is Dictionary and value.get("version",0)==2 and int(value.get("wave",0))>=1 and value.get("stats") is Dictionary:
  checkpoint=value

func continue_run():
 if checkpoint.is_empty(): return
 stats=Stats.new(); stats.restore(checkpoint.stats)
 wave=maxi(1,int(checkpoint.wave)); health=clampf(float(checkpoint.health),1.0,stats.base.vitality)
 kills=int(checkpoint.kills); elapsed=float(checkpoint.elapsed); run_seed=int(checkpoint.seed)
 selected_slot=clampi(int(checkpoint.get("slot",1)),1,4)
 carried=checkpoint.get("carried","")
 if not carried in ["","grenade","trap","potion"]: carried=""
 var phase=checkpoint.get("phase","playing")
 offers=stats.offers(run_seed,wave)
 choices=[]
 for value in checkpoint.get("choices",[]):
  var index=int(value)
  if index>=0 and index<5 and not index in choices and choices.size()<2: choices.append(index)
 start_arena(phase!="upgrade")
 if phase=="upgrade":
  if offers.size()!=5: offers=stats.offers(run_seed,wave); choices=[]
  show_upgrades()

func _notification(what):
 if what==NOTIFICATION_WM_CLOSE_REQUEST: quit_game()

func quit_game():
 if quitting: return
 quitting=true
 state="quitting"
 get_tree().paused=true
 if is_instance_valid(sound): sound.release_audio()
 await get_tree().create_timer(0.15).timeout
 get_tree().quit()
