extends Control

const SAMPLE_PROJECT_PATH := "res://sample_project/project.json"
const PROJECT_MODEL_SCRIPT := preload("res://scripts/models/ProjectModel.gd")
const SCENE_MODEL_SCRIPT := preload("res://scripts/models/SceneModel.gd")
const TIMELINE_CONTROLLER_SCRIPT := preload("res://scripts/runtime/TimelineController.gd")
const PLAYBACK_CLOCK_SCRIPT := preload("res://scripts/runtime/PlaybackClock.gd")
const SCENE_RUNTIME_SCRIPT := preload("res://scripts/runtime/SceneRuntime.gd")

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


func _ready() -> void:
	_playback_clock = PLAYBACK_CLOCK_SCRIPT.new()
	add_child(_playback_clock)
	_playback_clock.bind_audio_player(_audio_player)

	_scene_runtime = SCENE_RUNTIME_SCRIPT.new()
	_world_root.add_child(_scene_runtime)

	var ok: bool = load_project(SAMPLE_PROJECT_PATH)
	if not ok:
		push_error("Failed to load sample project.")
		return

	_playback_clock.play()


func _process(_delta: float) -> void:
	if _timeline_controller == null:
		return

	var t: float = _playback_clock.get_time()
	var scene_id: String = _timeline_controller.get_active_scene_id(t)
	if scene_id != _active_scene_id and scene_id != "":
		_load_active_scene(scene_id)

	var local_t: float = _timeline_controller.get_scene_local_time(t)
	_scene_runtime.update_time(local_t)


func load_project(project_path: String) -> bool:
	if not _project_model.load(project_path):
		push_error("Project load failed: %s" % _project_model.last_error)
		return false

	_current_project_path = project_path
	_timeline_controller.set_timeline(_project_model.timeline)
	_viewport.size = _project_model.internal_resolution
	_scene_runtime.set_internal_resolution(_project_model.internal_resolution)
	_apply_output_resolution(_project_model.output_resolution)

	if _project_model.audio_path != "":
		var audio_resolved: String = _project_model.resolve_asset_path(_project_model.audio_path)
		var stream: AudioStream = load(audio_resolved) as AudioStream
		if stream == null:
			push_warning("Could not load audio stream: %s" % audio_resolved)
		else:
			_playback_clock.configure_audio(stream)

	var first_scene: String = _timeline_controller.get_active_scene_id(0.0)
	if first_scene != "":
		_load_active_scene(first_scene)
	return true


func _load_active_scene(scene_id: String) -> void:
	if _current_project_path == "":
		return

	var scene_rel_path: String = "scenes/%s.json" % scene_id
	var scene_path: String = _project_model.resolve_asset_path(scene_rel_path)
	var model: RefCounted = SCENE_MODEL_SCRIPT.new()
	if not model.load(scene_path):
		push_error("Scene load failed (%s): %s" % [scene_path, model.last_error])
		return

	_scene_runtime.load_scene_model(model)
	_active_scene_id = scene_id


func _apply_output_resolution(size: Vector2i) -> void:
	if size.x <= 0 or size.y <= 0:
		return
	_viewport_container.custom_minimum_size = Vector2(size)
	DisplayServer.window_set_size(size)
