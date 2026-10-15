extends CharacterBody2D
var game
var kind = "stalker"
var hp = 30.0
var max_hp = 30.0
var speed = 90.0
var contact_damage = 12.0
var cooldown = 1.2
var tell = 0.0
var stun_time = 0.0
var immunity = 0.55
var age = 0.0
var hurt_flash = 0.0
var dead = false
var attack_target = Vector2.ZERO
var art: Sprite2D

func _ready():
 add_to_group("arena_enemies")
 collision_layer = 4
 collision_mask = 1
 var collision = CollisionShape2D.new()
 var circle = CircleShape2D.new()
 circle.radius = 23 if kind == "boss" else (18 if kind == "brute" else 12)
 collision.shape = circle
 add_child(collision)
 art = Sprite2D.new()
 art.texture = load("res://assets/art/boss_%d.svg" % (floori(game.wave/5.0)%6+1)) if kind == "boss" else load("res://assets/art/"+kind+".svg")
 art.scale = Vector2.ONE * (2.8 if kind=="boss" else (1.5 if kind=="brute" else 1.15))
 art.position.y = -8
 add_child(art)
 var base_hp = {"stalker":30.0,"archer":38.0,"weaver":34.0,"brute":85.0,"boss":280.0}[kind]
 hp = base_hp * (0.86 + 0.14 * pow(float(game.wave),1.35))
 max_hp = hp
 speed = minf(225.0, {"stalker":88.0,"archer":67.0,"weaver":112.0,"brute":58.0,"boss":72.0}[kind]+game.wave*3.0)
 contact_damage = (19.0 if kind in ["brute","boss"] else 12.0) * (1.0+(game.wave-1)*0.10)
 cooldown = randf_range(1.0,2.0)
 queue_redraw()

func _physics_process(delta):
 if dead or game.state != "playing": return
 age += delta
 immunity = maxf(0.0,immunity-delta)
 hurt_flash = maxf(0.0,hurt_flash-delta)
 art.modulate = Color(1.5,1.2,1.2) if hurt_flash > 0 else Color.WHITE
 stun_time = maxf(0.0,stun_time-delta)
 if stun_time > 0:
  velocity = Vector2.ZERO
  queue_redraw()
  return
 var target = game.player.global_position
 var to_player = target-global_position
 var distance = to_player.length()
 cooldown -= delta
 if tell > 0:
  tell -= delta
  velocity = Vector2.ZERO
  if tell <= 0: release_attack(target,distance)
 else:
  var direction = to_player.normalized()
  if kind == "archer":
   if distance < 170: direction = -direction
   elif distance < 300: direction = Vector2.ZERO
  velocity = direction * speed
  # A small separation force keeps a swarm readable without expensive paths.
  for other in get_tree().get_nodes_in_group("arena_enemies"):
   if other == self or other.dead: continue
   var apart = global_position-other.global_position
   if apart.length_squared() > 0 and apart.length_squared() < 700:
    velocity += apart.normalized()*24.0
  move_and_slide()
  if cooldown <= 0:
   if kind == "archer":
    attack_target = target
    tell = 0.4
    cooldown = maxf(0.8,2.2/(1.0+game.wave*0.025))
   elif kind == "weaver":
    attack_target = target
    tell = 0.6
    cooldown = 2.3
   elif kind == "brute" and distance < 85:
    tell = 0.65
    cooldown = 1.8
   elif kind == "boss":
    attack_target = target
    tell = 0.75
    cooldown = maxf(1.0,2.4/(1.0+game.wave*0.015))
 if immunity <= 0 and distance < (35 if kind=="boss" else 24):
  game.player.hurt(contact_damage)
 art.flip_h = to_player.x < 0
 art.position.y = -8+sin(age*7)*1.0
 queue_redraw()

func release_attack(target: Vector2, distance: float):
 if kind == "brute":
  if distance < 72: game.player.hurt(contact_damage*1.6)
  game.float_text(global_position,"IMPACTO",Color("dc9276"))
 elif kind == "boss":
  var count = mini(18,6+floori(game.wave/3.0))
  for index in range(count):
   game.shoot(global_position,Vector2.RIGHT.rotated(TAU*index/count+age*0.3),contact_damage,false)
 else:
  var count = mini(5,1+floori(game.wave/8.0)) if kind=="archer" else 3
  var direction = (attack_target-global_position).normalized()
  for index in range(count):
   game.shoot(global_position,direction.rotated((index-(count-1)*0.5)*0.16),contact_damage,false)

func hurt(amount: float):
 if dead or immunity > 0: return
 hp -= amount
 hurt_flash = 0.12
 game.float_text(global_position,str(roundi(amount)),Color("f4d69d"))
 if hp <= 0:
  dead = true
  collision_layer = 0
  game.enemy_defeated(self)
  queue_free()
 queue_redraw()

func _draw():
 if hp < max_hp:
  draw_rect(Rect2(-18,-31,36,3),Color("231c27"))
  draw_rect(Rect2(-18,-31,36*maxf(0,hp/max_hp),3),Color("d27c72"))
 if tell > 0:
  draw_arc(Vector2.ZERO,62 if kind=="brute" else 28,0,TAU,32,Color("ee9f78"),2)
 if stun_time > 0:
  draw_arc(Vector2.ZERO,21,0,TAU,24,Color("9ed8dd"),2)
 if immunity > 0: draw_arc(Vector2.ZERO,23,0,TAU,24,Color("da7474"),1)
