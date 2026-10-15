extends Node2D

const ARROW = preload("res://assets/art/arrow.svg")
const INK = Color("080c08")
const WOOD = Color("915037")
const STRING = Color("bbb6a0")
var stage = -1

func set_stage(value: int):
	if stage != value:
		stage = value
		queue_redraw()

func muzzle() -> Vector2:
	return to_global(Vector2(13, 0))

func _draw():
	# Local +X is the firing direction; rotate the complete bow with the aim.
	var limbs = PackedVector2Array()
	for index in range(17):
		var t = float(index) / 16.0
		var y = lerpf(-17.0, 17.0, t)
		limbs.append(Vector2(-2.0 + 11.0 * sin(t * PI), y))
	draw_polyline(limbs, INK, 7.0, true)
	draw_polyline(limbs, WOOD, 4.5, true)
	var pull = 12.0 if stage == 1 else (3.0 if stage == 0 else 0.0)
	var nock = Vector2(-2.0 - pull, 0)
	var string_points = PackedVector2Array([limbs[0], nock, limbs[16]])
	draw_polyline(string_points, INK, 2.8, true)
	draw_polyline(string_points, STRING, 1.0, true)
	draw_line(Vector2(9, -4), Vector2(9, 4), INK, 6.0, true)
	# The nocked arrow disappears exactly at the release (third frame).
	if stage != 2:
		draw_texture_rect(ARROW, Rect2(nock.x, -4.5, 30, 9), false)
	draw_circle(Vector2(9, 0), 3.0, INK, true, -1.0, true)
	if stage == 0 or stage == 1:
		draw_circle(nock, 2.6, INK, true, -1.0, true)
