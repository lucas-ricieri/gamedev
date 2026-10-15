extends SceneTree
var game
var player

func _initialize():
 call_deferred("verify")

func step(count: int = 1):
 for index in range(count):
  await physics_frame
  await process_frame

func press_key(code: int):
 var event=InputEventKey.new()
 event.physical_keycode=code; event.pressed=true
 Input.parse_input_event(event)
 await step()
 event=InputEventKey.new(); event.physical_keycode=code; event.pressed=false
 Input.parse_input_event(event)
 await step()

func fire_once():
 player.cooldown=0
 Input.action_press("fire")
 await step()
 Input.action_release("fire")

func target(pos: Vector2):
 var enemy=game.world.spawn_enemy("stalker",pos)
 enemy.set_physics_process(false); enemy.immunity=0; enemy.hp=1000; enemy.max_hp=1000
 return enemy

func clear_targets():
 for enemy in get_nodes_in_group("arena_enemies"):
  enemy.dead=true; enemy.queue_free()
 for bolt in get_nodes_in_group("bolts"): bolt.queue_free()
 await step(2)
 if DisplayServer.get_name()!="headless":
  game.last_device="mouse"
  Input.warp_mouse(player.get_viewport_transform()*Vector2(720,410))
  await step(2)
  assert(not game.pointer_on_hud(),"Scaled lower arena must accept mouse attacks")
  Input.warp_mouse(player.get_viewport_transform()*Vector2(480,500))
  await step(2)
  assert(game.pointer_on_hud(),"Slot buttons cannot trigger combat")
  Input.warp_mouse(player.get_viewport_transform()*Vector2(700,270))
  await step(2)
  game.last_device="pad"

func capture(name: String):
 if DisplayServer.get_name()!="headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://output/cacador-spritesheet/"+name+".png")

func verify():
 game=preload("res://scripts/main.gd").new()
 root.add_child(game)
 player=game.player
 game.last_device="pad"
 game.world.director_enabled=false
 for id in game.stats.WEAPONS: game.stats.weapons[id].crit=0.0
 await step(2)
 var actions=InputMap.get_actions()
 for id in ["slot_1","slot_2","slot_3","slot_4","interact","fire","roll"]:
  assert(id in actions)
 # Real keyboard input must select the fixed slots.
 for index in range(1,5):
  await press_key(KEY_1+index-1)
  assert(game.selected_slot==index)
  assert(player.rig.weapon==(["sword","bow","dagger",""][index-1]))
  for id in ["sword","bow","dagger"]:
   assert(player.rig.backs[id].visible==(id!=game.weapon_id()))
 game.select_slot(1); player.aim=Vector2.RIGHT
 var front=target(player.position+Vector2(60,-8))
 var rear=target(player.position+Vector2(-65,0))
 await step(2)
 await fire_once()
 assert(front.hp==1000, "No damage during windup")
 await step(25)
 assert(is_equal_approx(front.hp,974.0), "Sword damage once per target")
 assert(rear.hp==1000)
 assert(get_nodes_in_group("bolts").is_empty())
 await capture("arena-sword")
 await clear_targets()
 game.select_slot(2)
 var ranged=target(player.position+Vector2(180,-8))
 await step(2)
 await fire_once()
 assert(get_nodes_in_group("bolts").is_empty(), "Bowstring release must precede arrow launch")
 await step(35)
 assert(is_equal_approx(ranged.hp,980.0))
 assert(get_nodes_in_group("landed_arrows").size()>0, "Arrow persists after impact")
 await capture("arena-bow")
 await clear_targets()
 game.select_slot(3); game.stats.weapons.dagger.crit=1.0
 var close=target(player.position+Vector2(35,-8))
 var distant=target(player.position+Vector2(120,0))
 await step(2)
 await fire_once(); await step(18)
 assert(is_equal_approx(close.hp,972.0), "Dagger uses its own damage and critical multiplier")
 assert(distant.hp==1000)
 assert(game.stats.attack_interval("dagger")<game.stats.attack_interval("sword"))
 await capture("arena-dagger")
 game.stats.weapons.dagger.crit=0.25
 await clear_targets()
 # Explicit pickup and replacement: exactly one held item.
 game.world.pickups.clear()
 game.world.add_pickup(player.position+Vector2(10,0),"grenade")
 game.world.add_pickup(player.position+Vector2(25,0),"trap")
 await press_key(KEY_E)
 assert(game.carried=="grenade")
 await press_key(KEY_E)
 assert(game.carried=="trap")
 assert(game.world.pickups.any(func(drop): return drop.kind=="grenade" and not drop.taken))
 game.select_slot(4)
 var captive=target(player.position+Vector2(25,0))
 await step(2)
 await fire_once()
 assert(game.carried=="")
 await step(35)
 assert(captive.stun_time>0)
 assert(is_equal_approx(captive.hp,952.0))
 await step(25)
 assert(is_equal_approx(captive.hp,952.0), "Trap cannot deal repeated damage")
 await clear_targets()
 game.carried="grenade"
 var blast=target(game.world.clamp_point(player.position+Vector2.RIGHT*230))
 await step(2)
 assert(game.use_special())
 assert(game.carried=="")
 await step(60)
 assert(is_equal_approx(blast.hp,920.0))
 await capture("arena-grenade")
 await clear_targets()
 game.carried="potion"; game.health=game.stats.base.vitality
 assert(not game.use_special() and game.carried=="potion")
 game.health=10
 assert(game.use_special() and game.carried=="")
 assert(is_equal_approx(game.health,66.0))
 # Vigor controls maximum stamina; roll keeps its explicit cost.
 player.stamina=game.stats.base.vigor
 player.roll_cooldown=0
 Input.action_press("roll"); await step(); Input.action_release("roll")
 assert(player.stamina>=70 and player.stamina<72)
 player.roll_time=0
 await step(2)
 # Wave completion gives exactly five choices and requires two unique picks.
 game.complete_wave()
 assert(game.state=="upgrade" and game.offers.size()==5)
 var before=game.stats.serialize()
 game.confirm_upgrades()
 assert(game.wave==1, "Cannot advance with no upgrades")
 game.toggle_choice(0); game.toggle_choice(0)
 assert(game.choices.is_empty())
 game.toggle_choice(0)
 game.confirm_upgrades()
 assert(game.wave==1, "Cannot advance with one upgrade")
 game.toggle_choice(1); game.toggle_choice(2)
 assert(game.choices==[0,1], "Third choice is refused")
 assert(not game.confirm_button.disabled)
 var selected_offers=[game.offers[0].duplicate(true),game.offers[1].duplicate(true)]
 await capture("arena-upgrades-selected")
 # A JSON round trip preserves the upgrade screen and selected choices.
 game.checkpoint=JSON.parse_string(JSON.stringify(game.checkpoint))
 game.continue_run()
 player=game.player
 assert(game.state=="upgrade" and game.choices==[0,1] and game.wave==1)
 game.confirm_upgrades()
 assert(game.wave==2 and game.state=="playing")
 assert(is_equal_approx(game.stats.base.strength,float(before.base.strength)+4))
 assert(is_equal_approx(game.stats.base.vitality,float(before.base.vitality)+25))
 assert(game.world.total==18)
 for offer in selected_offers:
  var extra=offer.extra
  var old_item=before.weapons[extra.target] if before.weapons.has(extra.target) else before.specials[extra.target]
  var new_item=game.stats.weapons[extra.target] if game.stats.weapons.has(extra.target) else game.stats.specials[extra.target]
  var expected=float(old_item[extra.key])+float(extra.amount)
  if extra.key=="crit": expected=minf(0.75,expected)
  if extra.key=="arrows": expected=minf(5,expected)
  if extra.key=="heal": expected=minf(0.8,expected)
  assert(is_equal_approx(float(new_item[extra.key]),expected),"Specific item bonus must be applied")
 var after=game.stats.serialize()
 game.confirm_upgrades()
 assert(game.stats.serialize()==after, "Upgrades cannot be applied twice")
 game.world.director_enabled=false
 # The other base choices must affect real cooldown, movement and dodge fuel.
 var old_interval=game.stats.attack_interval("bow")
 var old_speed=game.stats.base.agility
 game.complete_wave(); game.toggle_choice(2); game.toggle_choice(3); game.confirm_upgrades()
 assert(game.stats.attack_interval("bow")<old_interval)
 Input.action_press("move_right"); await step(2)
 assert(player.velocity.length()>old_speed)
 Input.action_release("move_right"); await step()
 game.complete_wave(); game.toggle_choice(4); game.toggle_choice(0); game.confirm_upgrades()
 assert(game.stats.base.vigor==120 and game.stats.regen==28)
 assert(player.stamina==120)
 for index in range(4):
  player.roll_cooldown=0; player.roll_time=0
  Input.action_press("roll"); await step(); Input.action_release("roll")
  player.roll_time=0
  await step()
 assert(player.stamina<10 and player.stamina>=0, "Larger vigor reserve allows four dodges")
 game.world.director_enabled=false
 # Later waves have stronger enemies and are not bounded by six levels.
 game.wave=1
 var early=game.world.spawn_enemy("stalker",Vector2(90,120))
 var early_hp=early.hp; var early_speed=early.speed; var early_damage=early.contact_damage
 early.dead=true; early.queue_free(); await step(2)
 game.wave=50; game.world.begin_wave()
 var late=game.world.spawn_enemy("stalker",Vector2(90,120))
 assert(late.hp>early_hp and late.speed>early_speed and late.contact_damage>early_damage)
 assert(game.world.total==210)
 game.world.pending=1
 assert(game.world.choose_kind()=="boss")
 late.dead=true; late.queue_free(); await step(2)
 # No victory cap, and the director schedules timed spawn warnings.
 game.wave=51; game.world.begin_wave()
 game.world.director_enabled=true; game.world.spawn_timer=0
 await step(2)
 assert(game.world.pending==213 and game.world.telegraphs.size()==1)
 assert(game.world.alive()==0)
 await step(60)
 assert(game.world.alive()>=1)
 print("ARENA_VERIFIED: keys 1-4, carried equipment, 3 combat styles, persistent arrows, single consumable/swap/use, grenade/trap/potion, vigor, exact 2-of-5 upgrades, specific bonuses, JSON resume, scaling at wave 50+, timed spawning")
 game.quit_game()
