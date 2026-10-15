extends RefCounted

const SHEET = preload("res://assets/art/hunter-spritesheet.png")
const ACTIONS = ["idle", "walk", "run", "dodge", "attack"]
const DIRECTIONS = ["up", "left", "right", "down"]
const FRAME_RATES = [5.0, 8.0, 12.0, 4.0 / 0.23, 16.0]
const CELL_SIZE = 140
const BORDER = 1
static var cached_frames: SpriteFrames
static var cached_material: ShaderMaterial

static func create_frames() -> SpriteFrames:
	if cached_frames != null:
		return cached_frames
	var frames = SpriteFrames.new()
	frames.remove_animation("default")
	var image = SHEET.get_image()
	for action_index in range(ACTIONS.size()):
		for direction_index in range(DIRECTIONS.size()):
			var animation = StringName(ACTIONS[action_index] + "_" + DIRECTIONS[direction_index])
			frames.add_animation(animation)
			frames.set_animation_speed(animation, FRAME_RATES[action_index])
			frames.set_animation_loop(animation, action_index < 3)
			# The equipped weapon and its color blur perform the attack. Keep
			# the same body silhouette while its carried equipment stays visible.
			var body_action = 0 if ACTIONS[action_index] == "attack" else action_index
			var row = body_action * 2 + floori(direction_index / 2.0)
			var first_column = (direction_index % 2) * 4
			for frame_index in range(4):
				var cell = Rect2i(BORDER + (first_column + frame_index) * CELL_SIZE, BORDER + row * CELL_SIZE, CELL_SIZE, CELL_SIZE)
				var bounds = image.get_region(cell).get_used_rect()
				var texture = AtlasTexture.new()
				texture.atlas = SHEET
				texture.region = Rect2(Vector2(cell.position + bounds.position), Vector2(bounds.size))
				# Keep the feet at the same anchor across generated frames.
				texture.margin = Rect2(Vector2((CELL_SIZE - bounds.size.x) * 0.5, 130 - bounds.size.y), Vector2(CELL_SIZE - bounds.size.x, CELL_SIZE - bounds.size.y))
				texture.filter_clip = true
				frames.add_frame(animation, texture)
	cached_frames = frames
	return frames

static func create_material() -> ShaderMaterial:
	if cached_material == null:
		cached_material = ShaderMaterial.new()
		cached_material.shader = preload("res://assets/art/hunter_palette.gdshader")
	return cached_material

static func facing(direction: Vector2) -> String:
	if absf(direction.x) > absf(direction.y):
		return "left" if direction.x < 0 else "right"
	return "up" if direction.y < 0 else "down"
