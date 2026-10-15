extends CharacterBody2D
const Animations = preload("res://scripts/hunter_animations.gd")
const Rig = preload("res://scripts/weapon_rig.gd")
var game
var aim=Vector2.RIGHT
var cooldown=0.0
var attack_time=0.0
var attack_duration=0.25
var attack_direction=Vector2.RIGHT
var attack_weapon="sword"
var attack_damage=20.0
var attack_sweep=deg_to_rad(140)
var attack_reach=76.0
var attack_crit=false
var projectile_speed=620.0
var projectile_count=1
var bow_released=false
var hit_targets: Dictionary={}
var roll_time=0.0
var roll_cooldown=0.0
var roll_direction=Vector2.RIGHT
var immune=0.0
var stamina=100.0
var slow=1.0
var facing="down"
var art: AnimatedSprite2D
var rig: Node2D
var carried_layer: Node2D
var blade_shape: CapsuleShape2D

func _ready():
 collision_layer=2; collision_mask=1
 var collision=CollisionShape2D.new()
 var shape=CircleShape2D.new(); shape.radius=12
 collision.shape=shape; add_child(collision)
 carried_layer=Node2D.new(); carried_layer.name="CarriedWeapons"; add_child(carried_layer)
 art=AnimatedSprite2D.new(); art.name="HunterSprite"
 art.sprite_frames=Animations.create_frames(); art.material=Animations.create_material()
 art.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
 art.scale=Vector2.ONE*0.36; art.position.y=-9
 add_child(art); art.play("idle_down")
 rig=Rig.new(); rig.name="Equipment"; rig.game=game; add_child(rig)
 rig.add_carried(carried_layer)
 blade_shape=CapsuleShape2D.new(); blade_shape.radius=9; blade_shape.height=60
 stamina=game.stats.base.vigor
 refresh_equipment()

func refresh_equipment():
 rig.equip(game.weapon_id())
 update_equipment()

func cancel_attack():
 attack_time=0.0; bow_released=true; hit_targets.clear()
 if is_instance_valid(art): art.play("idle_"+facing)
 if is_instance_valid(rig): rig.set_pose(-1,attack_sweep,attack_reach)

func _physics_process(delta):
 if game.state!="playing": return
 cooldown=maxf(0,cooldown-delta)
 roll_cooldown=maxf(0,roll_cooldown-delta)
 immune=maxf(0,immune-delta)
 stamina=minf(game.stats.base.vigor,stamina+game.stats.regen*delta)
 var move=Input.get_vector("move_left","move_right","move_up","move_down")
 var stick=Vector2.ZERO
 for id in Input.get_connected_joypads():
  stick=Vector2(Input.get_joy_axis(id,JOY_AXIS_RIGHT_X),Input.get_joy_axis(id,JOY_AXIS_RIGHT_Y))
  if stick.length()>0.22: break
 if stick.length()>0.22: aim=stick.normalized()
 elif game.last_device=="mouse":
  var direction=get_global_mouse_position()-global_position
  if direction.length()>3: aim=direction.normalized()
 if Input.is_action_just_pressed("roll") and roll_cooldown<=0 and stamina>=30:
  roll_direction=move.normalized() if move.length()>0.1 else aim
  roll_time=0.23; roll_cooldown=0.8; immune=0.32; stamina-=30
  cancel_attack(); game.sound.play_sfx("roll")
 var dodging=roll_time>0
 if dodging:
  roll_time=maxf(0,roll_time-delta)
  velocity=roll_direction*460
 else: velocity=move*game.stats.base.agility*slow
 move_and_slide()
 advance_attack(delta,dodging)
 if Input.is_action_pressed("fire") and cooldown<=0 and not dodging and not game.pointer_on_hud():
  if game.selected_slot==4:
   cooldown=0.5
   if game.use_special():
    facing=Animations.facing(aim)
    art.play("attack_"+facing,1.0); art.set_frame_and_progress(0,0)
  else: begin_attack()
 update_animation(dodging)
 update_equipment()
 art.modulate=Color(1,1,1,0.5) if immune>0 and int(immune*18)%2==0 else Color.WHITE
 rig.modulate=art.modulate; carried_layer.modulate=art.modulate
 queue_redraw()

func begin_attack():
 attack_weapon=game.weapon_id()
 if attack_weapon=="": return
 var data=game.stats.weapons[attack_weapon]
 cooldown=game.stats.attack_interval(attack_weapon)
 attack_duration=maxf(0.08,minf(0.34,cooldown*0.70))
 attack_time=attack_duration; attack_direction=aim
 attack_damage=game.stats.damage(attack_weapon)
 attack_sweep=deg_to_rad(data.get("sweep",140.0)); attack_reach=data.range
 projectile_speed=data.get("speed",620.0); projectile_count=int(data.get("arrows",1))
 hit_targets.clear(); bow_released=false
 facing=Animations.facing(aim)
 art.play("attack_"+facing,0.25/attack_duration); art.set_frame_and_progress(0,0)
 game.sound.play_sfx("swing" if attack_weapon!="bow" else "roll")

func advance_attack(delta: float,dodging: bool):
 if attack_time<=0: return
 var previous=1.0-attack_time/attack_duration
 attack_time=maxf(0,attack_time-delta)
 var progress=1.0-attack_time/attack_duration
 if dodging: return
 if attack_weapon=="bow":
  if not bow_released and progress>=0.5:
   bow_released=true
   var roll=game.stats.roll_damage("bow")
   var origin=global_position+attack_direction*31+Vector2(0,-8)
   for index in range(projectile_count):
    var angle=(index-(projectile_count-1)*0.5)*0.10
    game.shoot(origin,attack_direction.rotated(angle),roll.amount,true,projectile_speed,attack_reach)
   game.sound.play_sfx("shot")
 elif previous<0.75 and progress>=0.5:
  var first=Rig.angle_at(maxf(previous,0.5),attack_sweep)
  var last=Rig.angle_at(minf(progress,0.75),attack_sweep)
  var samples=maxi(1,ceili(absf(last-first)/deg_to_rad(12)))
  for index in range(samples+1):
   apply_melee(attack_direction.angle()+lerpf(first,last,float(index)/samples))

func apply_melee(angle: float):
 blade_shape.height=maxf(18,attack_reach-16)
 var grip=global_position+attack_direction*15+Vector2(0,-8)
 var direction=Vector2.RIGHT.rotated(angle)
 var query=PhysicsShapeQueryParameters2D.new()
 query.shape=blade_shape; query.collision_mask=4; query.collide_with_areas=false
 query.transform=Transform2D(angle+PI*0.5,grip+direction*(blade_shape.height*0.5-2))
 var space=get_world_2d().direct_space_state
 for hit in space.intersect_shape(query,64):
  var target=hit.collider
  if not target.has_method("hurt") or hit_targets.has(target.get_instance_id()): continue
  if not game.world.can_see(global_position,target.global_position): continue
  hit_targets[target.get_instance_id()]=true
  var data=game.stats.weapons[attack_weapon]
  var critical=randf()<float(data.crit)
  target.hurt(attack_damage*(data.crit_mult if critical else 1.0))
  if critical: game.float_text(target.global_position-Vector2(0,12),"CRÍTICO",Color("baf2e6"))

func update_equipment():
 var direction=attack_direction if attack_time>0 else aim
 rig.position=direction*15+Vector2(0,-8); rig.rotation=direction.angle()
 rig.visible=roll_time<=0
 var progress=1.0-attack_time/attack_duration if attack_time>0 else -1.0
 rig.set_pose(progress,attack_sweep,attack_reach)

func update_animation(dodging: bool):
 var action="idle"
 if dodging:
  action="dodge"; facing=Animations.facing(roll_direction)
 elif attack_time>0: return
 elif velocity.length()>1:
  action="run" if velocity.length()>=game.stats.base.agility*0.9 else "walk"
  facing=Animations.facing(velocity)
 var animation=StringName(action+"_"+facing)
 if art.animation!=animation: art.play(animation)

func hurt(amount: float):
 if immune>0 or game.state!="playing": return
 immune=0.65; game.health-=amount
 game.sound.play_sfx("hit")
 game.float_text(global_position,"−%d" % roundi(amount),Color("ef8b79"))

func _draw():
 draw_rect(Rect2(-14,9,28,6),Color(0,0,0,0.25))
 draw_arc(aim*44+Vector2(0,-5),4,0,TAU,16,Color("eee5c4"),1)
