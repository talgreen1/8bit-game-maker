extends Control

const SAMPLE_PROJECT_PATH := "res://sample_project/project.json"

@onready var _viewport: SubViewport = $InternalViewportContainer/InternalViewport
@onready var _world_root: Node2D = $InternalViewportContainer/InternalViewport/WorldRoot
@onready var _audio_player: AudioStreamPlayer = $AudioPlayer

var _project_model := ProjectModel.new()
var _timeline_controller := TimelineController.new()
var _playback_clock: PlaybackClock
var _scene_runtime: SceneRuntime
var _active_scene_id := ""
var _current_project_path := ""


func _ready() -> void:
    _playback_clock = PlaybackClock.new()
    add_child(_playback_clock)
    _playback_clock.bind_audio_player(_audio_player)

    _scene_runtime = SceneRuntime.new()
    _world_root.add_child(_scene_runtime)

    var ok := load_project(SAMPLE_PROJECT_PATH)
    if not ok:
        push_error("Failed to load sample project.")
        return

    _playback_clock.play()


func _process(_delta: float) -> void:
    if _timeline_controller == null:
        return

    var t := _playback_clock.get_time()
    var scene_id := _timeline_controller.get_active_scene_id(t)
    if scene_id != _active_scene_id and scene_id != "":
        _load_active_scene(scene_id)

    var local_t := _timeline_controller.get_scene_local_time(t)
    _scene_runtime.update_time(local_t)


func load_project(project_path: String) -> bool:
    if not _project_model.load(project_path):
        push_error("Project load failed: %s" % _project_model.last_error)
        return false

    _current_project_path = project_path
    _timeline_controller.set_timeline(_project_model.timeline)
    _viewport.size = _project_model.internal_resolution
    _scene_runtime.set_internal_resolution(_project_model.internal_resolution)

    if _project_model.audio_path != "":
        var audio_resolved := _project_model.resolve_asset_path(_project_model.audio_path)
        var stream := load(audio_resolved) as AudioStream
        if stream == null:
            push_warning("Could not load audio stream: %s" % audio_resolved)
        else:
            _playback_clock.configure_audio(stream)

    var first_scene := _timeline_controller.get_active_scene_id(0.0)
    if first_scene != "":
        _load_active_scene(first_scene)
    return true


func _load_active_scene(scene_id: String) -> void:
    if _current_project_path == "":
        return

    var scene_rel_path := "scenes/%s.json" % scene_id
    var scene_path := _project_model.resolve_asset_path(scene_rel_path)
    var model := SceneModel.new()
    if not model.load(scene_path):
        push_error("Scene load failed (%s): %s" % [scene_path, model.last_error])
        return

    _scene_runtime.load_scene_model(model)
    _active_scene_id = scene_id
