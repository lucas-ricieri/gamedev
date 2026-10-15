extends Node2D
const SWORD = preload("res://assets/art/hunter-sword.png")
const DAGGER = preload("res://assets/art/hunter-dagger.png")
var game
var weapon = "sword"
var progress = -1.0
var sweep = deg_to_rad(140)
var reach = 76.0
var pivot: Node2D
var sword: Sprite2D
var dagger: Sprite2D
var bow: Node2D
var backs: Dictionary = {}
var carried_layer: Node2D

func _ready():
 pivot = Node2D.new(); add_child(pivot)
 sword = make_blade(SWORD,Vector2(0.215,0.5),64)
 dagger = make_blade(DAGGER,Vector2(0.23,0.42),40)
 bow = preload("res://scripts/hunter_bow.gd").new()
 add_child(bow)
 equip("sword")

func make_blade(texture: Texture2D, grip: Vector2, length: float) -> Sprite2D:
 var sprite=Sprite2D.new()
 sprite.texture=texture; sprite.centered=false
 sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
 var ratio=length/texture.get_image().get_used_rect().size.x
 sprite.scale=Vector2.ONE*ratio
 sprite.position=-texture.get_size()*grip*ratio
 pivot.add_child(sprite)
 return sprite

func add_carried(layer: Node2D):
 carried_layer=layer
 for id in ["sword","bow","dagger"]:
  var sprite=Sprite2D.new()
  sprite.texture=game.icon(id)
  sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
  var length=38.0 if id=="sword" else (29.0 if id=="bow" else 25.0)
  sprite.scale=Vector2.ONE*length/maxf(sprite.texture.get_width(),sprite.texture.get_height())
  sprite.position={"sword":Vector2(-20,-13),"bow":Vector2(15,-13),"dagger":Vector2(-17,4)}[id]
  sprite.rotation={"sword":-1.1,"bow":-0.35,"dagger":0.65}[id]
  layer.add_child(sprite); backs[id]=sprite
 equip(weapon)

func equip(id: String):
 weapon=id
 if is_instance_valid(sword): sword.visible=id=="sword"
 if is_instance_valid(dagger): dagger.visible=id=="dagger"
 if is_instance_valid(bow): bow.visible=id=="bow"
 for name in backs: backs[name].visible=name!=id
 queue_redraw()

static func angle_at(time: float, arc: float) -> float:
 if time<0: return -0.45
 if time<0.25: return lerpf(-0.45,-arc*0.5,time*4)
 if time<0.5: return -arc*0.5
 if time<0.75: return lerpf(-arc*0.5,arc*0.5,(time-0.5)*4)
 return lerpf(arc*0.5,-0.45,(time-0.75)*4)

func set_pose(time: float, arc: float, distance: float):
 progress=time; sweep=arc; reach=distance
 if weapon in ["sword","dagger"]:
  pivot.rotation=angle_at(time,arc)
  pivot.scale=Vector2.ONE*distance/(76.0 if weapon=="sword" else 48.0)
 elif weapon=="bow":
  bow.set_stage(mini(3,int(time*4)) if time>=0 else -1)
 queue_redraw()

func _draw():
 if weapon=="":
  if game.carried!="":
   draw_texture_rect(game.icon(game.carried),Rect2(-10,-12,23,23),false)
  return
 if progress>=0.5 and progress<0.9:
  var alpha=0.55 if progress<0.75 else 0.55*(0.9-progress)/0.15
  if weapon=="bow":
   # Warm blur follows the bowstring and arrow release.
   draw_line(Vector2(-14,0),Vector2(36,0),Color(0.86,0.67,0.40,alpha),8,true)
   draw_line(Vector2(-8,0),Vector2(38,0),Color(0.96,0.87,0.67,alpha),2,true)
  else:
   var finish=angle_at(minf(progress,0.75),sweep)
   var tint=Color("9ed9ec") if weapon=="sword" else Color("d3f7fa")
   var radius=maxf(15,reach-27)
   draw_arc(Vector2.ZERO,radius,-sweep*0.5,finish,32,Color(tint,alpha),8 if weapon=="sword" else 5,true)
   draw_arc(Vector2.ZERO,radius+3,-sweep*0.5,finish,32,Color(0.9,1.0,1.0,alpha),2,true)
 draw_circle(Vector2.ZERO,2.8,Color("010201"),true,-1,true)
