extends Node2D

const TEXTURE = preload("res://assets/art/hunter-sword.png")
const GRIP = Vector2(0.215, 0.5)
const REST_ANGLE = -0.45
var progress = -1.0
var sweep = deg_to_rad(140.0)
var blade: Sprite2D

func _ready():
	var image = TEXTURE.get_image()
	var bounds = image.get_used_rect()
	var weapon_scale = 64.0 / bounds.size.x
	blade = Sprite2D.new()
	blade.name = "Blade"
	blade.texture = TEXTURE
	blade.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	blade.centered = false
	blade.scale = Vector2.ONE * weapon_scale
	blade.position = -Vector2(TEXTURE.get_size()) * GRIP * weapon_scale
	# Pivot the blade around the wrapped grip, rather than the image center.
	var pivot = Node2D.new()
	pivot.name = "GripPivot"
	add_child(pivot)
	pivot.add_child(blade)
	set_pose(-1.0, sweep)

static func angle_at(time: float, arc: float) -> float:
	if time < 0:
		return REST_ANGLE
	if time < 0.25:
		return lerpf(REST_ANGLE, -arc * 0.5, time * 4.0)
	if time < 0.5:
		return -arc * 0.5 - sin((time - 0.25) * 4.0 * PI) * 0.12
	if time < 0.75:
		return lerpf(-arc * 0.5, arc * 0.5, (time - 0.5) * 4.0)
	return lerpf(arc * 0.5, REST_ANGLE, (time - 0.75) * 4.0)

func set_pose(time: float, arc: float):
	progress = time
	sweep = arc
	if is_instance_valid(blade):
		blade.get_parent().rotation = angle_at(progress, sweep)
	queue_redraw()

func _draw():
	if progress >= 0.5 and progress < 0.9:
		var finish = angle_at(minf(progress, 0.75), sweep)
		var opacity = 0.5 if progress < 0.75 else 0.5 * (0.9 - progress) / 0.15
		draw_arc(Vector2.ZERO, 44.0, -sweep * 0.5, finish, 28, Color(0.65, 0.93, 1.0, opacity), 3.0, true)
		draw_arc(Vector2.ZERO, 48.0, -sweep * 0.5, finish, 28, Color(0.88, 0.98, 1.0, opacity), 1.5, true)
	draw_circle(Vector2.ZERO, 3.0, Color("010201"), true, -1.0, true)
