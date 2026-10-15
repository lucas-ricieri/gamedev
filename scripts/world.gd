extends Node2D
var game
var data: Dictionary
var floor_cells: Dictionary = {}
var visited: Dictionary = {}
var objects: Array[Dictionary] = []
var hazards: Array[Dictionary] = []
var doors: Array[Dictionary] = []
var nav = AStarGrid2D.new()
var boss_dead = false
var actors: Node2D
var last_room = -1
var hazard_tick = 0.0
var portal = Vector2.ZERO
var time = 0.0

func _ready():
	data = HuntLevels.LEVELS[game.level]
	actors = Node2D.new()
	actors.y_sort_enabled = true
	add_child(actors)
	for room in data.rooms:
		for x in range(room.position.x,room.end.x):
			for y in range(room.position.y,room.end.y): floor_cells[Vector2i(x,y)] = true
	for link in data.links:
		var a = Vector2i(data.rooms[link[0]].get_center())
		var b = Vector2i(data.rooms[link[1]].get_center())
		for x in range(mini(a.x,b.x),maxi(a.x,b.x)+1):
			floor_cells[Vector2i(x,a.y)] = true
			floor_cells[Vector2i(x,a.y+1)] = true
		for y in range(mini(a.y,b.y),maxi(a.y,b.y)+1):
			floor_cells[Vector2i(b.x,y)] = true
			floor_cells[Vector2i(b.x+1,y)] = true
	nav.region = Rect2i(Vector2i.ZERO,data.size)
	nav.cell_size = Vector2(64,64)
	nav.offset = Vector2(32,32)
	nav.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	nav.update()
	for x in range(data.size.x):
		for y in range(data.size.y):
			var cell = Vector2i(x,y)
			if not floor_cells.has(cell):
				nav.set_point_solid(cell,true)
				var edge = false
				for offset in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
					if floor_cells.has(cell+offset): edge = true
				if edge: add_wall(Rect2(Vector2(cell)*64,Vector2(64,64)))
	var gated_link = data.links[data.gate]
	var ra: Rect2i = data.rooms[gated_link[0]]
	var rb: Rect2i = data.rooms[gated_link[1]]
	var ca = Vector2i(ra.get_center())
	var cb = Vector2i(rb.get_center())
	var gate_rect: Rect2
	if absi(ca.x-cb.x) >= absi(ca.y-cb.y):
		var gx = int((ra.end.x+rb.position.x)*.5) if ca.x<cb.x else int((rb.end.x+ra.position.x)*.5)
		gate_rect = Rect2(gx*64,ca.y*64,64,128)
	else:
		var gy = int((ra.end.y+rb.position.y)*.5) if ca.y<cb.y else int((rb.end.y+ra.position.y)*.5)
		gate_rect = Rect2(cb.x*64,gy*64,128,64)
	var body = add_wall(gate_rect)
	doors.append({"rect":gate_rect,"body":body,"open":false})
	for x in range(int(gate_rect.position.x/64),int(gate_rect.end.x/64)):
		for y in range(int(gate_rect.position.y/64),int(gate_rect.end.y/64)): nav.set_point_solid(Vector2i(x,y),true)
	for i in range(data.rooms.size()):
		var room: Rect2i = data.rooms[i]
		var origin = Vector2(room.position)*64
		if i == 0:
			add_chest(origin+Vector2(145,135),"key")
			add_chest(origin+Vector2(400,360),"vitality")
		elif i < data.rooms.size()-1 or (game.level==4 and i==4):
			add_chest(origin+Vector2(100,110),"rapid" if game.level>0 else "vitality")
			if game.level >= 2: add_chest(origin+Vector2(400,100),"damage")
			if game.level >= 4: add_chest(origin+Vector2(110,380),"spread")
			spawn_enemy("nest",origin+Vector2(350,340),i)
		for n in range(2+game.level):
			if i == 0 and n > 1: break
			if i == data.rooms.size()-1: break
			var kinds = data.enemies
			var e = spawn_enemy(kinds[n%kinds.size()],origin+Vector2(230+(n%3)*70,190+int(n/3)*90),i)
			e.active = i == 0
		if i > 0:
			for n in range(data.hazards.size()): add_hazard(origin+Vector2(220+n*170,260),data.hazards[n],65)
	var final_room: Rect2i = data.rooms[data.rooms.size()-1]
	# A fase 5 tem um ramo opcional; o chefe fica na sala 3.
	var boss_room = 3 if game.level == 4 else data.rooms.size()-1
	final_room = data.rooms[boss_room]
	var chief = spawn_enemy("boss",Vector2(final_room.get_center())*64,boss_room)
	chief.active = false
	portal = Vector2(final_room.end)*64-Vector2(90,90)
	game.player = preload("res://scripts/player.gd").new()
	game.player.game = game
	game.player.position = Vector2(data.rooms[0].position)*64+Vector2(130,280)
	actors.add_child(game.player)
	game.player.camera.limit_left = 0
	game.player.camera.limit_top = 0
	game.player.camera.limit_right = data.size.x*64
	game.player.camera.limit_bottom = data.size.y*64
	visited[0] = true
	queue_redraw()

func add_wall(rect: Rect2):
	var body = StaticBody2D.new()
	body.position = rect.get_center()
	body.collision_layer = 1
	body.collision_mask = 0
	var c = CollisionShape2D.new()
	var s = RectangleShape2D.new()
	s.size = rect.size
	c.shape = s
	body.add_child(c)
	add_child(body)
	return body

func spawn_enemy(kind: String,pos: Vector2,room: int):
	var e = preload("res://scripts/enemy.gd").new()
	e.game = game
	e.kind = kind
	e.room_index = room
	e.position = pos
	actors.add_child(e)
	return e

func enemy_count(): return actors.get_child_count()-1

func add_chest(pos: Vector2,loot: String):
	objects.append({"pos":pos,"type":"chest","loot":loot,"opened":false})

func add_pickup(pos: Vector2,type: String):
	objects.append({"pos":pos,"type":type,"opened":false})

func add_hazard(pos: Vector2,type: String,radius: float,life: float = -1):
	hazards.append({"pos":pos,"type":type,"radius":radius,"life":life})

func next_point(from: Vector2,to: Vector2) -> Vector2:
	var a = Vector2i(from/64)
	var b = Vector2i(to/64)
	if not nav.is_in_boundsv(a) or not nav.is_in_boundsv(b): return from
	if nav.is_point_solid(a) or nav.is_point_solid(b): return from
	var path = nav.get_point_path(a,b)
	return path[1] if path.size()>1 else to

func can_see(from: Vector2,to: Vector2) -> bool:
	return get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(from,to,1)).is_empty()

func _physics_process(delta):
	if game.state != "playing" or not is_instance_valid(game.player): return
	time += delta
	hazard_tick -= delta
	var p = game.player.global_position
	game.player.slow = 1.0
	for i in range(data.rooms.size()):
		var rect = Rect2(Vector2(data.rooms[i].position)*64,Vector2(data.rooms[i].size)*64)
		if rect.has_point(p):
			if not visited.has(i):
				visited[i] = true
				if is_instance_valid(game.boss) and game.boss.room_index==i:
					game.boss.active = true
					game.sound.play_sfx("boss")
					game.toast(data.boss+" • prepare-se!")
			last_room = i
	for obj in objects:
		if not obj.opened and p.distance_to(obj.pos) < 48:
			obj.opened = true
			game.collect(obj.loot if obj.type=="chest" else obj.type)
	for door in doors:
		if not door.open and p.distance_to(door.rect.get_center()) < 115 and game.keys > 0:
			door.open = true
			game.keys -= 1
			door.body.queue_free()
			for x in range(int(door.rect.position.x/64),int(door.rect.end.x/64)):
				for y in range(int(door.rect.position.y/64),int(door.rect.end.y/64)): nav.set_point_solid(Vector2i(x,y),false)
			game.sound.play_sfx("door")
			game.toast("Portão aberto. Uma chave consumida.")
	for h in hazards:
		if h.life > 0: h.life -= delta
		if p.distance_to(h.pos) < h.radius:
			if h.type == "slow": game.player.slow = .52
			elif hazard_tick <= 0: game.player.hurt(18)
	hazards = hazards.filter(func(h): return h.life == -1 or h.life > 0)
	if hazard_tick <= 0: hazard_tick = .8
	if boss_dead and p.distance_to(portal) < 48: game.clear_level()
	queue_redraw()

func _draw():
	if data.is_empty(): return
	draw_rect(Rect2(Vector2.ZERO,Vector2(data.size)*64),Color(data.wall))
	var tint = Color(data.color)
	for cell in floor_cells:
		var pos = Vector2(cell)*64
		var variant = (cell.x*17+cell.y*31)%7
		draw_rect(Rect2(pos,Vector2(64,64)),Color(data.floor).lightened(variant*.007))
		draw_line(pos+Vector2(1,62),pos+Vector2(62,62),Color(0,0,0,.11),2)
		if variant < 3:
			draw_rect(Rect2(pos+Vector2(11+variant*12,15),Vector2(5,3)),tint.darkened(.45))
		for v in [Vector2i.UP,Vector2i.LEFT,Vector2i.RIGHT,Vector2i.DOWN]:
			if not floor_cells.has(cell+v):
				var w = pos+Vector2(v)*64
				draw_rect(Rect2(w+Vector2(3,3),Vector2(58,58)),tint.darkened(.42))
				draw_rect(Rect2(w+Vector2(3,3),Vector2(58,8)),tint.darkened(.12))
				draw_rect(Rect2(w+Vector2(3,53),Vector2(58,8)),Color(0,0,0,.3))
	for h in hazards:
		var c = Color("bd7461") if h.type=="damage" else Color("718c86")
		draw_circle(h.pos,h.radius,c.darkened(.4))
		draw_arc(h.pos,h.radius-5,time*.3,time*.3+TAU-.2,28,c,2)
		for i in range(7):
			var v = h.pos+Vector2.RIGHT.rotated(i*2.4)*h.radius*.65
			draw_rect(Rect2(v,Vector2(5,9)),c)
	for obj in objects:
		if obj.type=="chest":
			draw_texture_rect(preload("res://assets/art/chest.svg"),Rect2(obj.pos-Vector2(27,32),Vector2(54,54)),false,Color(.5,.5,.5) if obj.opened else Color.WHITE)
			if obj.opened: draw_rect(Rect2(obj.pos+Vector2(-12,-16),Vector2(24,7)),Color("202a2d"))
		elif not obj.opened:
			draw_texture_rect(preload("res://assets/art/relic.svg"),Rect2(obj.pos-Vector2(20,24+sin(time*3)*4),Vector2(40,40)),false)
	for door in doors:
		if not door.open:
			draw_rect(door.rect,Color("654c3f"))
			for x in range(int(door.rect.position.x)+5,int(door.rect.end.x),16): draw_line(Vector2(x,door.rect.position.y),Vector2(x,door.rect.end.y),Color("b49361"),4)
			draw_texture_rect(preload("res://assets/art/key.svg"),Rect2(door.rect.get_center()-Vector2(24,24),Vector2(48,48)),false)
	var pc = Color("efcc83") if boss_dead else Color("6e6679")
	draw_circle(portal,38,pc.darkened(.6))
	draw_arc(portal,34+sin(time*3)*3,0,TAU,32,pc,4)
	draw_arc(portal,22,-time,time+PI,20,pc,2)
