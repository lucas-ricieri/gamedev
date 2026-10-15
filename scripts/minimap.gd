extends Control
var game
func _ready(): mouse_filter = Control.MOUSE_FILTER_IGNORE
func _process(_delta): queue_redraw()
func _draw():
	if not is_instance_valid(game.world) or not is_instance_valid(game.player): return
	var data = game.world.data
	var scale_factor = minf(size.x/data.size.x,size.y/data.size.y)
	draw_rect(Rect2(Vector2.ZERO,size),Color("14232a"))
	for cell in game.world.floor_cells:
		draw_rect(Rect2(Vector2(cell)*scale_factor,Vector2.ONE*scale_factor),Color("637c77"))
	for obj in game.world.objects:
		if not obj.opened: draw_circle(obj.pos/64*scale_factor,2,Color("ddc581"))
	for door in game.world.doors:
		if not door.open: draw_rect(Rect2(door.rect.position/64*scale_factor,door.rect.size/64*scale_factor),Color("e4a767"))
	draw_circle(game.world.portal/64*scale_factor,3,Color("b799ca"))
	draw_circle(game.player.position/64*scale_factor,3,Color("fff0b8"))
