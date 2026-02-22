class_name PlaybackClock
extends Node

var _audio_player: AudioStreamPlayer
var _playhead_time := 0.0
var _is_playing := false


func bind_audio_player(player: AudioStreamPlayer) -> void:
    _audio_player = player


func configure_audio(stream: AudioStream) -> void:
    if _audio_player == null:
        return
    _audio_player.stream = stream


func play() -> void:
    if _is_playing:
        return
    _is_playing = true
    if _audio_player != null and _audio_player.stream != null:
        _audio_player.play(_playhead_time)


func pause() -> void:
    _is_playing = false
    if _audio_player != null and _audio_player.playing:
        _playhead_time = _audio_player.get_playback_position()
        _audio_player.stop()


func seek(t: float) -> void:
    _playhead_time = max(0.0, t)
    if _audio_player == null or _audio_player.stream == null:
        return

    var was_playing := _is_playing
    if _audio_player.playing:
        _audio_player.stop()
    if was_playing:
        _audio_player.play(_playhead_time)


func get_time() -> float:
    if _audio_player != null and _audio_player.playing:
        return _audio_player.get_playback_position()
    return _playhead_time


func _process(delta: float) -> void:
    if not _is_playing:
        return
    if _audio_player != null and _audio_player.stream != null:
        if not _audio_player.playing:
            _is_playing = false
        return
    _playhead_time += delta
