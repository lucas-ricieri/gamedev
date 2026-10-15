extends Node2D
var game
var kind = "grenade"
var origin = Vector2.ZERO
var target = Vector2.ZERO
var age = 0.0
var triggered = false
var damage = 80.0
var radius = 105.0
var duration = 4.0

func _ready():
 add_to_group("special_effects")
 position = origin

func trigger():
 if triggered: return
 triggered = true
 age = 0
 for enemy in get_tree().get_nodes_in_group("arena_enemies"):
  if enemy.dead or enemy.global_position.distance_to(global_position) > radius+12: continue
  if not game.world.can_see(global_position,enemy.global_position): continue
  if kind == "trap": enemy.stun_time = maxf(enemy.stun_time,duration)
  enemy.hurt(damage)
 game.sound.play_sfx("hit")

func _physics_process(delta):
 if game.state != "playing": return
 age += delta
 if triggered:
  if age > 0.45: queue_free()
 elif kind == "grenade":
  position = origin.lerp(target,minf(1.0,age/0.65))
  if age >= 0.85: trigger()
 elif age > 0.35:
  for enemy in get_tree().get_nodes_in_group("arena_enemies"):
   if not enemy.dead and enemy.global_position.distance_to(position) < radius:
    trigger()
    break
  if age > 18: queue_free()
 queue_redraw()

func _draw():
 if triggered:
  var alpha = maxf(0.0,1.0-age/0.45)
  var tint = Color("efb66b") if kind=="grenade" else Color("9ed8dd")
  draw_circle(Vector2.ZERO,radius,Color(tint,alpha*0.25))
  draw_arc(Vector2.ZERO,radius*(0.5+age),0,TAU,48,Color(tint,alpha),4)
 else:
  var offset = Vector2(0,-sin(minf(1.0,age/0.65)*PI)*28) if kind=="grenade" else Vector2.ZERO
  draw_texture_rect(game.icon(kind),Rect2(offset-Vector2(15,15),Vector2(30,30)),false)
  if kind == "trap": draw_arc(Vector2.ZERO,radius,0,TAU,32,Color(0.6,0.8,0.82,0.22),1)
