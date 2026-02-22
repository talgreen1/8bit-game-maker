class_name TimelineController
extends RefCounted

var _entries: Array[Dictionary] = []


func set_timeline(entries: Array) -> void:
    _entries.clear()
    for raw_entry in entries:
        if typeof(raw_entry) != TYPE_DICTIONARY:
            continue
        _entries.append(raw_entry)
    _entries.sort_custom(func(a: Dictionary, b: Dictionary): return float(a.get("start", 0.0)) < float(b.get("start", 0.0)))


func get_active_entry(t: float) -> Dictionary:
    for entry: Dictionary in _entries:
        var start := float(entry.get("start", 0.0))
        var duration := max(0.0, float(entry.get("duration", 0.0)))
        if t >= start and t < start + duration:
            return entry
    return {}


func get_active_scene_id(t: float) -> String:
    var entry := get_active_entry(t)
    if entry.is_empty():
        return ""
    return str(entry.get("scene_id", ""))


func get_scene_local_time(t: float) -> float:
    var entry := get_active_entry(t)
    if entry.is_empty():
        return 0.0
    return max(0.0, t - float(entry.get("start", 0.0)))
