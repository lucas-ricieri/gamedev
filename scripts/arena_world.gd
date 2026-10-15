extends Node2D

const BOUNDS = Rect2(28, 92, 904, 352)
var game
var actors: Node2D
var rng = RandomNumberGenerator.new()
var pending = 0
var total = 0
var spawned = 0
var spawn_timer = 0.0
var spawn_interval = 0.8
var telegraphs: Array = []
var pickups: Array = []
var time = 0.0
var director_enabled = true
var nearest = -1
var wave_finished = false

func _ready():
 actors = Node2D.new()
 actors.y_sort_enabled = true
 add_child(actors)
 add_wall(Rect2(0,64,960,28))
 add_wall(Rect2(0,444,960,28))
 add_wall(Rect2(0,92,28,352))
 add_wall(Rect2(932,92,28,352))
 game.player = preload("res://scripts/player.gd").new()
 game.player.game = game
 game.player.position = BOUNDS.get_center()
 actors.add_child(game.player)
 if game.wave == 1:
  add_pickup(BOUNDS.get_center()+Vector2(-75,70),"grenade")
  add_pickup(BOUNDS.get_center()+Vector2(0,70),"trap")
  add_pickup(BOUNDS.get_center()+Vector2(75,70),"potion")

func add_wall(rect: Rect2):
 var body = StaticBody2D.new()
 body.position = rect.get_center()
 body.collision_layer = 1
 body.collision_mask = 0
 var collision = CollisionShape2D.new()
 var shape = RectangleShape2D.new()
 shape.size = rect.size
 collision.shape = shape
 body.add_child(collision)
 add_child(body)
 return body

func begin_wave():
 rng.seed = game.run_seed + game.wave * 71
 total = 10 + game.wave * 4
 pending = total
 spawned = 0
 spawn_timer = 1.8
 spawn_interval = maxf(0.16, 0.85 / (1.0 + game.wave * 0.045))
 telegraphs.clear()
 pickups=pickups.filter(func(drop): return drop.get("wave",game.wave)>=game.wave-1 and not drop.taken)
 wave_finished = false
 for arrow in get_tree().get_nodes_in_group("landed_arrows"): arrow.queue_free()
 for bolt in get_tree().get_nodes_in_group("bolts"): bolt.queue_free()
 queue_redraw()

func alive() -> int:
 var count = 0
 for enemy in get_tree().get_nodes_in_group("arena_enemies"):
  if not enemy.dead: count += 1
 return count

func spawn_point() -> Vector2:
 var rect = BOUNDS.grow(-28)
 var pos = rect.position
 for attempt in range(12):
  match rng.randi_range(0,3):
   0: pos = Vector2(rng.randf_range(rect.position.x,rect.end.x),rect.position.y)
   1: pos = Vector2(rng.randf_range(rect.position.x,rect.end.x),rect.end.y)
   2: pos = Vector2(rect.position.x,rng.randf_range(rect.position.y,rect.end.y))
   3: pos = Vector2(rect.end.x,rng.randf_range(rect.position.y,rect.end.y))
  if pos.distance_to(game.player.position) >= 160: break
 return pos

func choose_kind() -> String:
 if game.wave % 5 == 0 and pending == 1: return "boss"
 var kinds = ["stalker","stalker","stalker"]
 if game.wave >= 2: kinds.append("archer")
 if game.wave >= 3: kinds.append("weaver")
 if game.wave >= 4: kinds.append("brute")
 return kinds[rng.randi_range(0,kinds.size()-1)]

func spawn_enemy(kind: String, pos: Vector2):
 var enemy = preload("res://scripts/arena_enemy.gd").new()
 enemy.game = game
 enemy.kind = kind
 enemy.position = pos
 actors.add_child(enemy)
 return enemy

func add_pickup(pos: Vector2, kind: String):
 pickups.append({"pos":pos,"kind":kind,"taken":false,"wave":game.wave})
 if pickups.size()>64: pickups.pop_front()
 queue_redraw()

func can_see(from: Vector2, to: Vector2) -> bool:
 return get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(from,to,1)).is_empty()

func clamp_point(pos: Vector2, margin: float = 20.0) -> Vector2:
 var rect = BOUNDS.grow(-margin)
 return Vector2(clampf(pos.x,rect.position.x,rect.end.x),clampf(pos.y,rect.position.y,rect.end.y))

func pickup_nearest() -> bool:
 find_nearest()
 if nearest < 0: return false
 var drop = pickups[nearest]
 var previous = game.carried
 game.carried = drop.kind
 drop.taken = true
 if previous != "":
  add_pickup(clamp_point(game.player.position+Vector2(35,0)),previous)
 game.toast("Slot 4: " + game.stats.NAMES[game.carried],2.0)
 game.sound.play_sfx("loot")
 return true

func find_nearest():
 nearest = -1
 var distance = 46.0
 for index in range(pickups.size()):
  var drop = pickups[index]
  if drop.taken or drop.kind == "heart": continue
  var current = game.player.position.distance_to(drop.pos)
  if current < distance:
   nearest = index
   distance = current

func _physics_process(delta):
 if game.state != "playing": return
 time += delta
 if director_enabled:
  spawn_timer -= delta
  if pending > 0 and spawn_timer <= 0 and alive()+telegraphs.size() < mini(46,12+game.wave*2):
   telegraphs.append({"pos":spawn_point(),"kind":choose_kind(),"time":0.9})
   pending -= 1
   spawn_timer = spawn_interval
  for cue in telegraphs:
   cue.time -= delta
   if cue.time <= 0:
    spawn_enemy(cue.kind,cue.pos)
    spawned += 1
  telegraphs = telegraphs.filter(func(cue): return cue.time > 0)
 for drop in pickups:
  if not drop.taken and drop.kind == "heart" and game.player.position.distance_to(drop.pos) < 28:
   if game.health < game.stats.base.vitality:
    game.health = minf(game.stats.base.vitality,game.health+14.0)
    drop.taken = true
    game.sound.play_sfx("loot")
 pickups = pickups.filter(func(drop): return not drop.taken)
 find_nearest()
 if director_enabled and pending == 0 and telegraphs.is_empty() and alive() == 0 and not wave_finished:
  wave_finished = true
  game.complete_wave()
 queue_redraw()

func _draw():
 draw_rect(Rect2(0,0,960,540),Color("101c22"))
 draw_rect(BOUNDS,Color("293e37"))
 for x in range(28,932,48):
  for y in range(92,444,44):
   var variant = (x*17+y*31)%5
   draw_rect(Rect2(x+1,y+1,46,42),Color("293e37").lightened(variant*0.009))
 draw_rect(BOUNDS.grow(6),Color("71816d"),false,4.0)
 draw_circle(BOUNDS.get_center(),94,Color(0.2,0.3,0.25,0.3))
 draw_arc(BOUNDS.get_center(),94,0,TAU,64,Color(0.6,0.7,0.55,0.12),2)
 for cue in telegraphs:
  var radius = 14.0 + (1.0-cue.time/0.9)*12.0
  var tint = Color("f2a36d") if cue.kind == "boss" else Color("da7474")
  draw_circle(cue.pos,24,Color(tint,0.15))
  draw_arc(cue.pos,radius,0,TAU,24,tint,2)
  draw_line(cue.pos-Vector2(6,0),cue.pos+Vector2(6,0),tint,2)
 for drop in pickups:
  var offset = Vector2(0,-2+sin(time*3)*2)
  if drop.kind == "heart":
   draw_circle(drop.pos+offset,8,Color("e07872"))
   draw_line(drop.pos+offset-Vector2(4,0),drop.pos+offset+Vector2(4,0),Color("fff0da"),2)
   draw_line(drop.pos+offset-Vector2(0,4),drop.pos+offset+Vector2(0,4),Color("fff0da"),2)
  else:
   draw_circle(drop.pos,18,Color(0,0,0,0.25))
   draw_texture_rect(game.icon(drop.kind),Rect2(drop.pos+offset-Vector2(16,16),Vector2(32,32)),false)
 if nearest >= 0 and nearest < pickups.size():
  draw_arc(pickups[nearest].pos,22,0,TAU,24,Color("efd29c"),2)
