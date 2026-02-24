extends Control

const SAMPLE_PROJECT_PATH := "res://sample_project/project.json"
const PROJECT_MODEL_SCRIPT := preload("res://scripts/models/ProjectModel.gd")
const SCENE_MODEL_SCRIPT := preload("res://scripts/models/SceneModel.gd")
const TIMELINE_CONTROLLER_SCRIPT := preload("res://scripts/runtime/TimelineController.gd")
const PLAYBACK_CLOCK_SCRIPT := preload("res://scripts/runtime/PlaybackClock.gd")
const SCENE_RUNTIME_SCRIPT := preload("res://scripts/runtime/SceneRuntime.gd")
const PROJECT_PANEL_SCRIPT := preload("res://scripts/ui/ProjectPanel.gd")
const TIMELINE_PANEL_SCRIPT := preload("res://scripts/ui/TimelinePanel.gd")
const SCENE_EDITOR_PANEL_SCRIPT := preload("res://scripts/ui/SceneEditorPanel.gd")
const INSPECTOR_PANEL_SCRIPT := preload("res://scripts/ui/InspectorPanel.gd")
const RIGHT_PANEL_WIDTH := 380

@onready var _viewport_container: SubViewportContainer = $InternalViewportContainer
@onready var _viewport: SubViewport = $InternalViewportContainer/InternalViewport
@onready var _world_root: Node2D = $InternalViewportContainer/InternalViewport/WorldRoot
@onready var _audio_player: AudioStreamPlayer = $AudioPlayer

var _project_model: RefCounted = PROJECT_MODEL_SCRIPT.new()
var _timeline_controller: RefCounted = TIMELINE_CONTROLLER_SCRIPT.new()
var _playback_clock: Node
var _scene_runtime: Node2D
var _active_scene_id: String = ""
var _current_project_path: String = ""
var _active_scene_model: RefCounted
var _scene_models_by_id: Dictionary = {}

var _project_panel: PanelContainer
var _timeline_panel: PanelContainer
var _scene_editor_panel: PanelContainer
var _inspector_panel: PanelContainer
var _time_label: Label
var _right_scroll: ScrollContainer


func _ready() -> void:
	_playback_clock = PLAYBACK_CLOCK_SCRIPT.new()
	add_child(_playback_clock)
	_playback_clock.bind_audio_player(_audio_player)

	_scene_runtime = SCENE_RUNTIME_SCRIPT.new()
	_world_root.add_child(_scene_runtime)

	_build_editor_layout()

	var ok: bool = load_project(SAMPLE_PROJECT_PATH)
	if not ok:
		push_error("Failed to load sample project.")
		return

	_playback_clock.play()


func _process(delta: float) -> void:
	if _timeline_controller == null:
		return

	var t: float = _playback_clock.get_time()
	var scene_id: String = _timeline_controller.get_active_scene_id(t)
	if scene_id != _active_scene_id and scene_id != "":
		_load_active_scene(scene_id)

	var local_t: float = _timeline_controller.get_scene_local_time(t)
	_scene_runtime.update_time(local_t)
	_scene_runtime.process_player_input(delta)

	if _timeline_panel != null:
		_timeline_panel.set_current_time(t)
	if _time_label != null:
		_time_label.text = "Playback: %.2fs" % t


func load_project(project_path: String) -> bool:
	if not _project_model.load(project_path):
		_set_project_status("Open failed: %s" % _project_model.last_error)
		push_error("Project load failed: %s" % _project_model.last_error)
		return false

	_current_project_path = project_path
	_scene_models_by_id.clear()
	_active_scene_model = null
	_active_scene_id = ""
	_timeline_controller.set_timeline(_project_model.timeline)
	_viewport.size = _project_model.internal_resolution
	_scene_runtime.set_internal_resolution(_project_model.internal_resolution)
	_apply_editor_preview_size(_project_model.internal_resolution)

	if _project_model.audio_path != "":
		var audio_resolved: String = _project_model.resolve_asset_path(_project_model.audio_path)
		var stream: AudioStream = load(audio_resolved) as AudioStream
		if stream == null:
			push_warning("Could not load audio stream: %s" % audio_resolved)
		else:
			_playback_clock.configure_audio(stream)

	if _project_panel != null:
		_project_panel.set_project_path(project_path)
		_set_project_status("Loaded project.")
	if _timeline_panel != null:
		_timeline_panel.set_timeline(_project_model.timeline)

	var first_scene: String = _timeline_controller.get_active_scene_id(0.0)
	if first_scene != "":
		_load_active_scene(first_scene)
	return true


func _build_editor_layout() -> void:
	var layout_root: HBoxContainer = HBoxContainer.new()
	layout_root.layout_mode = 1
	layout_root.anchors_preset = Control.PRESET_FULL_RECT
	layout_root.anchor_right = 1.0
	layout_root.anchor_bottom = 1.0
	add_child(layout_root)
	move_child(layout_root, 0)

	var left: VBoxContainer = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout_root.add_child(left)

	_viewport_container.reparent(left)
	_viewport_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_viewport_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_viewport_container.stretch = false

	var playback_row: HBoxContainer = HBoxContainer.new()
	left.add_child(playback_row)

	var play_button: Button = Button.new()
	play_button.text = "Play"
	play_button.pressed.connect(_on_play_pressed)
	playback_row.add_child(play_button)

	var pause_button: Button = Button.new()
	pause_button.text = "Pause"
	pause_button.pressed.connect(_on_pause_pressed)
	playback_row.add_child(pause_button)

	_time_label = Label.new()
	_time_label.text = "Playback: 0.00s"
	playback_row.add_child(_time_label)

	_right_scroll = ScrollContainer.new()
	_right_scroll.custom_minimum_size = Vector2(RIGHT_PANEL_WIDTH, 0)
	_right_scroll.size_flags_horizontal = Control.SIZE_SHRINK_END
	_right_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout_root.add_child(_right_scroll)

	var right: VBoxContainer = VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 10)
	_right_scroll.add_child(right)

	_project_panel = PROJECT_PANEL_SCRIPT.new()
	_project_panel.open_requested.connect(_on_project_open_requested)
	_project_panel.save_requested.connect(_on_project_save_requested)
	right.add_child(_project_panel)

	_timeline_panel = TIMELINE_PANEL_SCRIPT.new()
	_timeline_panel.timeline_updated.connect(_on_timeline_updated)
	_timeline_panel.scene_selected.connect(_on_timeline_scene_selected)
	_timeline_panel.scrub_requested.connect(_on_timeline_scrub_requested)
	right.add_child(_timeline_panel)

	_scene_editor_panel = SCENE_EDITOR_PANEL_SCRIPT.new()
	_scene_editor_panel.actor_position_changed.connect(_on_actor_position_changed)
	right.add_child(_scene_editor_panel)

	_inspector_panel = INSPECTOR_PANEL_SCRIPT.new()
	_inspector_panel.background_color_changed.connect(_on_background_color_changed)
	_inspector_panel.actor_velocity_changed.connect(_on_actor_velocity_changed)
	_inspector_panel.camera_mode_changed.connect(_on_camera_mode_changed)
	right.add_child(_inspector_panel)


func _load_active_scene(scene_id: String) -> void:
	if _current_project_path == "":
		return

	var model: RefCounted = _get_or_create_scene_model(scene_id)
	if model == null:
		return

	_scene_runtime.load_scene_model(model)
	_active_scene_model = model
	_active_scene_id = scene_id
	_sync_scene_ui_from_model()


func _get_or_create_scene_model(scene_id: String) -> RefCounted:
	if _scene_models_by_id.has(scene_id):
		return _scene_models_by_id[scene_id]

	var model: RefCounted = SCENE_MODEL_SCRIPT.new()
	var scene_path: String = _project_model.resolve_asset_path("scenes/%s.json" % scene_id)
	if FileAccess.file_exists(scene_path):
		if not model.load(scene_path):
			push_warning("Scene load failed (%s): %s" % [scene_path, model.last_error])
			return null
	else:
		_apply_default_scene_data(model, scene_id)
	_scene_models_by_id[scene_id] = model
	return model


func _apply_default_scene_data(model: RefCounted, scene_id: String) -> void:
	model.scene_name = "Scene %s" % scene_id
	model.background = {
		"type": "static_color",
		"color": "#243b55",
	}
	model.actors = [{
		"id": "actor_1",
		"start_pos": [32, 140],
		"velocity": [0, 0],
		"sprite_size": [16, 24],
		"animation": {
			"name": "run",
			"fps": 8,
			"colors": ["#f0c13a", "#ec9f19", "#f6da7c"],
		},
		"control": {
			"enabled": true,
			"speed": 120.0,
		},
	}]


func _sync_scene_ui_from_model() -> void:
	if _active_scene_model == null:
		return

	var background: Dictionary = _active_scene_model.background
	var color_text: String = str(background.get("color", "#243b55"))
	_inspector_panel.set_background_color(color_text)
	_scene_runtime.set_background_color(Color.from_string(color_text, Color("#243b55")))

	var actor: Dictionary = _get_active_actor()
	var actor_pos: Vector2 = _array_to_vec2(actor.get("start_pos", [32, 140]), Vector2(32, 140))
	var actor_velocity: Vector2 = _array_to_vec2(actor.get("velocity", [24, 0]), Vector2(24, 0))
	_scene_editor_panel.set_actor_position(actor_pos)
	_inspector_panel.set_actor_velocity(actor_velocity)
	_scene_runtime.set_actor_start_position(actor_pos)
	_scene_runtime.set_actor_velocity(actor_velocity)

	var camera: Dictionary = _active_scene_model.camera
	_inspector_panel.set_camera_mode(str(camera.get("mode", "static")))


func _get_active_actor() -> Dictionary:
	if _active_scene_model == null:
		return {}
	var actors: Array = _active_scene_model.actors
	if actors.is_empty():
		return {}
	var first_actor: Variant = actors[0]
	if typeof(first_actor) != TYPE_DICTIONARY:
		return {}
	return first_actor


func _set_active_actor(actor: Dictionary) -> void:
	if _active_scene_model == null:
		return
	var actors: Array = _active_scene_model.actors
	if actors.is_empty():
		actors.append(actor)
	else:
		actors[0] = actor
	_active_scene_model.actors = actors


func _on_play_pressed() -> void:
	_playback_clock.play()


func _on_pause_pressed() -> void:
	_playback_clock.pause()


func _on_project_open_requested(path: String) -> void:
	if path == "":
		_set_project_status("Enter a project path first.")
		return
	load_project(path)


func _on_project_save_requested(path: String) -> void:
	if path == "":
		_set_project_status("Enter a project path first.")
		return

	_project_model.timeline = _timeline_panel.get_timeline_entries()
	_timeline_controller.set_timeline(_project_model.timeline)

	if not _project_model.save(path):
		_set_project_status("Save failed: %s" % _project_model.last_error)
		return
	_current_project_path = path

	for scene_id in _scene_models_by_id.keys():
		var model: RefCounted = _scene_models_by_id[scene_id]
		var scene_path: String = _project_model.resolve_asset_path("scenes/%s.json" % str(scene_id))
		var scene_dir: String = scene_path.get_base_dir()
		DirAccess.make_dir_recursive_absolute(scene_dir)
		if not model.save(scene_path):
			push_warning("Failed to save scene %s: %s" % [scene_id, model.last_error])

	_set_project_status("Project saved.")


func _on_timeline_updated(entries: Array) -> void:
	_project_model.timeline = entries.duplicate(true)
	_timeline_controller.set_timeline(_project_model.timeline)
	for entry_raw in entries:
		if typeof(entry_raw) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_raw
		var scene_id: String = str(entry.get("scene_id", ""))
		if scene_id != "":
			_get_or_create_scene_model(scene_id)


func _on_timeline_scene_selected(scene_id: String) -> void:
	if scene_id == "":
		return
	_load_active_scene(scene_id)


func _on_timeline_scrub_requested(time_seconds: float) -> void:
	_playback_clock.seek(time_seconds)
	var scene_id: String = _timeline_controller.get_active_scene_id(time_seconds)
	if scene_id != "" and scene_id != _active_scene_id:
		_load_active_scene(scene_id)
	_scene_runtime.update_time(_timeline_controller.get_scene_local_time(time_seconds))


func _on_actor_position_changed(new_position: Vector2) -> void:
	var actor: Dictionary = _get_active_actor()
	if actor.is_empty():
		return
	actor["start_pos"] = [new_position.x, new_position.y]
	_set_active_actor(actor)
	_scene_runtime.set_actor_start_position(new_position)
	_playback_clock.pause()


func _on_background_color_changed(color_text: String) -> void:
	if _active_scene_model == null:
		return
	var background: Dictionary = _active_scene_model.background
	background["type"] = "static_color"
	background["color"] = color_text
	_active_scene_model.background = background
	_scene_runtime.set_background_color(Color.from_string(color_text, Color("#243b55")))


func _on_actor_velocity_changed(new_velocity: Vector2) -> void:
	var actor: Dictionary = _get_active_actor()
	if actor.is_empty():
		return
	actor["velocity"] = [new_velocity.x, new_velocity.y]
	_set_active_actor(actor)
	_scene_runtime.set_actor_velocity(new_velocity)
	_playback_clock.pause()


func _on_camera_mode_changed(mode: String) -> void:
	if _active_scene_model == null:
		return
	_active_scene_model.camera = {"mode": mode}


func _set_project_status(message: String) -> void:
	if _project_panel != null:
		_project_panel.set_status(message)


func _apply_editor_preview_size(internal_size: Vector2i) -> void:
	if internal_size.x <= 0 or internal_size.y <= 0:
		return
	# Keep editor UI readable by avoiding a huge forced minimum (e.g. 1920x1080).
	var scaled_width: float = float(internal_size.x) * 2.0
	var scaled_height: float = float(internal_size.y) * 2.0
	_viewport_container.custom_minimum_size = Vector2(scaled_width, scaled_height)


func _array_to_vec2(value: Variant, fallback: Vector2) -> Vector2:
	if typeof(value) != TYPE_ARRAY:
		return fallback
	var arr: Array = value
	if arr.size() != 2:
		return fallback
	return Vector2(float(arr[0]), float(arr[1]))
