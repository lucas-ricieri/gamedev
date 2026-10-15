extends CharacterBody2D
var game
var kind = "stalker"
var hp = 40.0
var max_hp = 40.0
var speed = 100.0
var cooldown = 1.5
var path_cooldown = 0.0
var waypoint = Vector2.ZERO
var room_index = 0
var active = true
var hurt_flash = 0.0
var tell = 0.0
var charge_time = 0.0
var charge_dir = Vector2.ZERO
var art: Sprite2D
var visible_notifier: VisibleOnScreenNotifier2D
var attack_target = Vector2.ZERO
var age = 0.0

func _ready():
	collision_layer = 4
	collision_mask = 1
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 25 if kind == "boss" else (22 if kind == "nest" else 14)
	shape.shape = circle
	add_child(shape)
	art = Sprite2D.new()
	art.texture = load("res://assets/art/boss_%d.svg"%(game.level+1)) if kind=="boss" else load("res://assets/art/%s.svg" % kind)
	art.scale = Vector2.ONE*(3.7 if kind == "boss" else (2.2 if kind in ["nest","brute"] else 1.65))
	art.position.y = -12
	add_child(art)
	visible_notifier = VisibleOnScreenNotifier2D.new()
	visible_notifier.rect = Rect2(-90,-90,180,180)
	add_child(visible_notifier)
	if kind == "boss":
		hp = 320+game.level*100
		speed = 80+game.level*8
		game.boss = self
	elif kind == "nest":
		hp = 120
		speed = 0
		active = false
		cooldown = 1.0
	elif kind == "archer":
		hp = [200,200,200,200,300,400][game.level]
		speed = 32 if game.level < 4 else 64
	elif kind == "brute":
		hp = 160
		speed = 65
	elif kind == "weaver":
		hp = 60
		speed = 115
	else:
		hp = 40
		speed = [72,96,96,120,120,144][game.level]
	max_hp = hp
	queue_redraw()

func _physics_process(delta):
	if game.state != "playing" or not is_instance_valid(game.player): return
	age += delta
	hurt_flash = maxf(0,hurt_flash-delta)
	art.modulate = Color(2,1.5,1.5) if hurt_flash > 0 else Color.WHITE
	var target = game.player.global_position
	var distance = global_position.distance_to(target)
	if kind == "nest":
		active = game.world.visited.has(room_index)
		if active and distance < 900:
			cooldown -= delta
			if cooldown <= 0:
				cooldown = float(game.world.data.rate)
				if game.world.enemy_count() < 38:
					var kinds = game.world.data.enemies
					game.world.spawn_enemy(kinds[(game.level+int(age))%kinds.size()],global_position+Vector2(55,0),room_index)
		queue_redraw()
		return
	if not active:
		active = game.world.visited.has(room_index)
		if not active: return
	# Distância + notifier mantêm a IA fora da câmera em repouso.
	if distance > 850 and not visible_notifier.is_on_screen(): return
	if kind == "boss":
		boss_update(delta,target,distance)
		return
	cooldown -= delta
	path_cooldown -= delta
	if tell > 0:
		tell -= delta
		velocity = Vector2.ZERO
		if tell <= 0:
			if kind == "brute":
				if distance < 90: game.player.hurt(45)
				game.float_text(global_position,"IMPACTO",Color("dca478"))
			else:
				for i in range(3): game.shoot(global_position,(attack_target-global_position).normalized().rotated((i-1)*.3),22,false)
		queue_redraw()
		return
	var desired = target
	if kind == "archer" and distance < 200: desired = global_position+(global_position-target).normalized()*100
	if path_cooldown <= 0:
		path_cooldown = .38+randf()*.12
		waypoint = game.world.next_point(global_position,desired)
	velocity = (waypoint-global_position).normalized()*speed if global_position.distance_to(waypoint)>8 else Vector2.ZERO
	if kind == "archer" and distance > 170 and distance < 400: velocity = Vector2.ZERO
	move_and_slide()
	art.flip_h = velocity.x < 0
	art.position.y = -12+sin(age*8)*2
	if cooldown <= 0:
		if kind == "archer" and distance < 500 and game.world.can_see(global_position,target):
			var count = [4,4,4,6,8,10][game.level]
			for i in range(count): game.shoot(global_position,Vector2.RIGHT.rotated(TAU*i/count+(target-global_position).angle()),20,false)
			cooldown = 2.3
		elif kind == "weaver" and distance < 340:
			tell = .65
			attack_target = target
			cooldown = 2.6
		elif kind == "brute" and distance < 95:
			tell = .7
			cooldown = 2
	if distance < 30:
		game.player.hurt(20 if kind == "stalker" else 30)
	queue_redraw()

func boss_update(delta: float,target: Vector2,distance: float):
	cooldown -= delta*(1.5 if hp < max_hp*.5 else 1.0)
	if charge_time > 0:
		charge_time -= delta
		velocity = charge_dir*410
		move_and_slide()
	elif tell > 0:
		tell -= delta
		if tell <= 0:
			if game.level in [0,5]:
				charge_dir = (attack_target-global_position).normalized()
				charge_time = .7
			if game.level > 0:
				var count = 6+game.level*2
				for i in range(count):
					var angle = TAU*i/count+age*.3
					if game.level==1: angle = (attack_target-global_position).angle()+(i-count*.5)*.16
					if game.level==3: angle = PI*i/count+age*.6
					game.shoot(global_position,Vector2.RIGHT.rotated(angle),26,false)
				if game.level in [1,2,5] and game.world.enemy_count()<32:
					for v in [Vector2(70,70),Vector2(-70,70)]: game.world.spawn_enemy("stalker" if game.level==1 else "weaver",global_position+v,room_index)
				if game.level >= 3: game.world.add_hazard(attack_target,"damage",55,3.0)
	else:
		velocity = (target-global_position).normalized()*speed if distance > 150 else Vector2.ZERO
		move_and_slide()
		if cooldown <= 0:
			cooldown = 2.8 if game.level==0 else 2.2
			tell = .85
			attack_target = target
	if distance < 50: game.player.hurt(45)
	art.flip_h = target.x < global_position.x
	queue_redraw()

func hurt(amount: float):
	if not active and kind != "nest": return
	hp -= amount
	hurt_flash = .12
	game.float_text(global_position,str(int(amount)),Color("f4d69d"))
	if hp <= 0:
		game.kills += 1
		game.vitality += 12 if kind != "boss" else 140
		if kind == "nest": game.vitality += 30
		if kind == "boss":
			game.world.boss_dead = true
			game.sound.play_sfx("clear")
			game.toast("Chefe derrotado! Atravesse o portal dourado.")
		elif game.kills%5 == 0:
			game.world.add_pickup(global_position,"vitality")
		queue_free()
	queue_redraw()

func _draw():
	if hp < max_hp:
		draw_rect(Rect2(-20,-43,40,4),Color("241f2b"))
		draw_rect(Rect2(-20,-43,40*maxf(0,hp/max_hp),4),Color("cf8c77"))
	if tell > 0:
		draw_arc(Vector2.ZERO,72 if kind=="boss" else 55,0,TAU,32,Color("ee9f78"),3)
		if kind == "boss" and game.level == 0: draw_line(Vector2.ZERO,(attack_target-global_position).normalized()*250,Color(1,.55,.4,.5),7)
	if kind=="nest" and active: draw_arc(Vector2.ZERO,35,age,age+PI,20,Color("d4ba7a"),2)
