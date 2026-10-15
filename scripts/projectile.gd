extends Node2D
const ARROW = preload("res://assets/art/arrow.svg")
const ARROW_TIP = 15.0
var direction = Vector2.RIGHT
var speed = 600.0
var damage = 20.0
var friendly = true
var life = 1.5
var game
var color = Color("f4d6a0")
var settled = false
var arrow_sprite: Sprite2D
var launch_origin = Vector2.ZERO
var launch_traced = false

func _ready():
	rotation = direction.angle()
	if friendly:
		launch_origin = game.player.global_position + Vector2(0, -8) if is_instance_valid(game.player) else global_position
		arrow_sprite = Sprite2D.new()
		arrow_sprite.texture = ARROW
		arrow_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		arrow_sprite.scale = Vector2(0.75,0.75)
		add_child(arrow_sprite)
	queue_redraw()

func _physics_process(delta):
	if settled or game.state != "playing": return
	var next = global_position + direction*speed*delta
	var tip = direction * ARROW_TIP if friendly else Vector2.ZERO
	var ray_start = launch_origin if friendly and not launch_traced else global_position + tip
	var query = PhysicsRayQueryParameters2D.create(ray_start,next + tip,5 if friendly else 3)
	query.hit_from_inside = true
	launch_traced = true
	query.collide_with_areas = false
	var hit = get_world_2d().direct_space_state.intersect_ray(query)
	if hit:
		global_position = hit.position - tip
		if friendly:
			settle()
		if hit.collider.has_method("hurt"): hit.collider.hurt(damage)
		if not friendly: queue_free()
		return
	else:
		global_position = next
	life -= delta
	if life <= 0:
		if friendly: settle()
		else: queue_free()

func settle():
	if settled: return
	settled = true
	speed = 0.0
	remove_from_group("bolts")
	add_to_group("landed_arrows")
	set_physics_process(false)
	# Keep arrows in the level even when the struck enemy is destroyed.
	# They no longer deal damage or count toward the active projectile cap.
	z_index = 0

func _draw():
	if friendly: return
	draw_rect(Rect2(-12,-3,19,6),color)
	draw_rect(Rect2(-3,-1,10,2),Color("fff2cf"))
