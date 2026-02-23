class_name SceneRuntime
extends Node2D

var _internal_resolution: Vector2i = Vector2i(320, 180)
var _background_root: Node2D
var _actor_root: Node2D
var _actor_sprite: AnimatedSprite2D
var _actor_start: Vector2 = Vector2.ZERO
var _actor_velocity: Vector2 = Vector2.ZERO
var _actor_position: Vector2 = Vector2.ZERO
var _actor_size: Vector2i = Vector2i(16, 24)
var _background_fill: Polygon2D
var _player_control_enabled: bool = false
var _player_move_speed: float = 80.0


func _ready() -> void:
	_ensure_roots()


func _ensure_roots() -> void:
	if _background_root != null and _actor_root != null:
		return
	_background_root = Node2D.new()
	_background_root.name = "BackgroundRoot"
	add_child(_background_root)

	_actor_root = Node2D.new()
	_actor_root.name = "ActorRoot"
	add_child(_actor_root)


func set_internal_resolution(size: Vector2i) -> void:
	_internal_resolution = size


func load_scene_model(model: SceneModel) -> void:
	_ensure_roots()
	_clear_children(_background_root)
	_clear_children(_actor_root)
	_actor_start = Vector2.ZERO
	_actor_velocity = Vector2.ZERO
	_actor_position = Vector2.ZERO
	_actor_size = Vector2i(16, 24)
	_player_control_enabled = false
	_player_move_speed = 80.0

	_build_background(model, model.background)
	_build_actor(model.actors[0] if not model.actors.is_empty() else {})


func update_time(local_time: float) -> void:
	if _actor_root == null:
		return
	if _player_control_enabled:
		_actor_root.position = _actor_position
		return
	_actor_position = _actor_start + (_actor_velocity * local_time)
	_actor_root.position = _actor_position


func process_player_input(delta: float) -> void:
	if not _player_control_enabled or _actor_root == null:
		return
	var input_dir := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)
	if input_dir.length_squared() > 1.0:
		input_dir = input_dir.normalized()
	_actor_position += input_dir * _player_move_speed * delta
	_clamp_actor_position()
	_actor_root.position = _actor_position


func _build_background(model: SceneModel, data: Dictionary) -> void:
	var kind: String = str(data.get("type", "static_color"))
	if kind == "parallax":
		_build_parallax_background(model, data)
		return
	if kind == "image" or data.has("image_path"):
		if _build_image_background(model, data):
			return
		return

	var polygon: Polygon2D = Polygon2D.new()
	polygon.polygon = PackedVector2Array([
		Vector2(0, 0),
		Vector2(_internal_resolution.x, 0),
		Vector2(_internal_resolution.x, _internal_resolution.y),
		Vector2(0, _internal_resolution.y),
	])
	polygon.color = Color(data.get("color", "#1f2a44"))
	_background_root.add_child(polygon)
	_background_fill = polygon


func _build_parallax_background(model: SceneModel, data: Dictionary) -> void:
	var layers: Array = data.get("layers", [])
	if typeof(layers) != TYPE_ARRAY or layers.is_empty():
		_build_background(model, {"type": "static_color", "color": "#1f2a44"})
		return

	var layer_index: int = 0
	for layer in layers:
		if typeof(layer) != TYPE_DICTIONARY:
			continue
		if not _build_image_background(model, layer, Vector2(layer_index * 2, 0)):
			var polygon: Polygon2D = Polygon2D.new()
			polygon.polygon = PackedVector2Array([
				Vector2(0, 0),
				Vector2(_internal_resolution.x, 0),
				Vector2(_internal_resolution.x, _internal_resolution.y),
				Vector2(0, _internal_resolution.y),
			])
			polygon.color = Color(layer.get("color", "#2b3d6b"))
			polygon.modulate = Color(1, 1, 1, clamp(float(layer.get("alpha", 1.0)), 0.0, 1.0))
			polygon.position = Vector2(layer_index * 2, 0)
			_background_root.add_child(polygon)
		layer_index += 1


func _build_actor(data: Dictionary) -> void:
	_actor_start = _array_to_vec2(data.get("start_pos", [32, 140]), Vector2(32, 140))
	_actor_velocity = _array_to_vec2(data.get("velocity", [24, 0]), Vector2(24, 0))
	_actor_position = _actor_start
	_actor_root.position = _actor_position

	_actor_sprite = AnimatedSprite2D.new()
	_actor_sprite.centered = false
	_actor_root.add_child(_actor_sprite)

	var anim_config: Dictionary = data.get("animation", {})
	var anim_fps: float = 8.0
	var colors: Array = [Color("#f7d35d"), Color("#f39c12"), Color("#f7e29a")]
	anim_fps = float(anim_config.get("fps", 8.0))
	var source_colors: Array = anim_config.get("colors", [])
	if not source_colors.is_empty():
		colors.clear()
		for value in source_colors:
			colors.append(Color(value))

	var sprite_size: Vector2i = _array_to_vec2i(data.get("sprite_size", [16, 24]), Vector2i(16, 24))
	_actor_size = sprite_size
	var frames: SpriteFrames = SpriteFrames.new()
	frames.add_animation("run")
	frames.set_animation_loop("run", true)
	frames.set_animation_speed("run", anim_fps)
	for color in colors:
		frames.add_frame("run", _create_solid_texture(sprite_size, color))

	_actor_sprite.sprite_frames = frames
	_actor_sprite.play("run")

	var control_data: Variant = data.get("control", {})
	if typeof(control_data) == TYPE_DICTIONARY:
		var control: Dictionary = control_data
		_player_control_enabled = bool(control.get("enabled", false))
		_player_move_speed = float(control.get("speed", 80.0))
	_clamp_actor_position()
	_actor_root.position = _actor_position


func _clear_children(node: Node) -> void:
	if node == null:
		return
	for child in node.get_children():
		child.queue_free()


func _build_image_background(model: SceneModel, data: Dictionary, offset: Vector2 = Vector2.ZERO) -> bool:
	if not data.has("image_path"):
		return false
	var image_path: String = str(data.get("image_path", ""))
	if image_path == "":
		return false
	var resolved: String = model.resolve_asset_path(image_path)
	var texture: Texture2D = load(resolved) as Texture2D
	if texture == null:
		return false

	var sprite: Sprite2D = Sprite2D.new()
	sprite.centered = false
	sprite.position = offset
	sprite.texture = texture
	sprite.modulate.a = clamp(float(data.get("alpha", 1.0)), 0.0, 1.0)

	var stretch: bool = bool(data.get("stretch", true))
	if stretch and texture.get_width() > 0 and texture.get_height() > 0:
		sprite.scale = Vector2(
			float(_internal_resolution.x) / float(texture.get_width()),
			float(_internal_resolution.y) / float(texture.get_height())
		)

	_background_root.add_child(sprite)
	return true


func get_actor_start_position() -> Vector2:
	return _actor_start


func set_actor_start_position(value: Vector2) -> void:
	_actor_start = value
	_actor_position = value
	_clamp_actor_position()
	if _actor_root != null:
		_actor_root.position = _actor_position


func get_actor_velocity() -> Vector2:
	return _actor_velocity


func set_actor_velocity(value: Vector2) -> void:
	_actor_velocity = value


func set_background_color(color_value: Color) -> void:
	if _background_fill != null:
		_background_fill.color = color_value


func _array_to_vec2(value: Variant, fallback: Vector2) -> Vector2:
	if typeof(value) != TYPE_ARRAY:
		return fallback
	var arr := value as Array
	if arr.size() != 2:
		return fallback
	return Vector2(float(arr[0]), float(arr[1]))


func _array_to_vec2i(value: Variant, fallback: Vector2i) -> Vector2i:
	if typeof(value) != TYPE_ARRAY:
		return fallback
	var arr := value as Array
	if arr.size() != 2:
		return fallback
	return Vector2i(int(arr[0]), int(arr[1]))


func _create_solid_texture(size: Vector2i, color: Color) -> Texture2D:
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)


func _clamp_actor_position() -> void:
	var max_x: float = maxf(0.0, float(_internal_resolution.x - _actor_size.x))
	var max_y: float = maxf(0.0, float(_internal_resolution.y - _actor_size.y))
	_actor_position.x = clampf(_actor_position.x, 0.0, max_x)
	_actor_position.y = clampf(_actor_position.y, 0.0, max_y)
