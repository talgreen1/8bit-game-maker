class_name ProjectModel
extends RefCounted

var project_name := ""
var fps := 60
var internal_resolution := Vector2i(320, 180)
var output_resolution := Vector2i(1920, 1080)
var audio_path := ""
var timeline: Array[Dictionary] = []
var project_dir := ""
var last_error := ""


func load(path: String) -> bool:
	last_error = ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		last_error = "Unable to open file at %s" % path
		return false

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		last_error = "Invalid JSON format in project file."
		return false

	var data: Dictionary = parsed
	var validation_error: String = validate_dict(data)
	if validation_error != "":
		last_error = validation_error
		return false

	project_name = str(data.get("project_name", "Untitled Project"))
	fps = int(data.get("fps", 60))
	internal_resolution = _array_to_vec2i(data.get("internal_resolution", [320, 180]), Vector2i(320, 180))
	output_resolution = _array_to_vec2i(data.get("output_resolution", [1920, 1080]), Vector2i(1920, 1080))
	audio_path = str(data.get("audio_path", ""))
	timeline = []
	for entry in data.get("timeline", []):
		timeline.append(entry)

	project_dir = path.get_base_dir()
	return true


func save(path: String) -> bool:
	last_error = ""
	var data := {
		"project_name": project_name,
		"fps": fps,
		"internal_resolution": [internal_resolution.x, internal_resolution.y],
		"output_resolution": [output_resolution.x, output_resolution.y],
		"audio_path": audio_path,
		"timeline": timeline,
	}

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		last_error = "Unable to write project file at %s" % path
		return false

	file.store_string(JSON.stringify(data, "  "))
	project_dir = path.get_base_dir()
	return true


func validate_dict(data: Dictionary) -> String:
	var required: Array = ["project_name", "fps", "internal_resolution", "output_resolution", "timeline"]
	for key in required:
		if not data.has(key):
			return "Missing required field '%s' in project file." % key

	if typeof(data["timeline"]) != TYPE_ARRAY:
		return "Field 'timeline' must be an array."

	var timeline_entries: Array = data["timeline"]
	for i in range(timeline_entries.size()):
		var entry: Variant = timeline_entries[i]
		if typeof(entry) != TYPE_DICTIONARY:
			return "Timeline entry %d must be an object." % i
		var entry_dict: Dictionary = entry
		for required_key in ["scene_id", "start", "duration"]:
			if not entry_dict.has(required_key):
				return "Timeline entry %d missing '%s'." % [i, required_key]

	return ""


func resolve_asset_path(asset_path: String) -> String:
	if asset_path == "":
		return ""
	if asset_path.begins_with("res://") or asset_path.begins_with("user://"):
		return asset_path
	if asset_path.is_absolute_path():
		return asset_path
	if project_dir == "":
		return asset_path
	return project_dir.path_join(asset_path)


func _array_to_vec2i(value: Variant, fallback: Vector2i) -> Vector2i:
	if typeof(value) != TYPE_ARRAY:
		return fallback
	var arr := value as Array
	if arr.size() != 2:
		return fallback
	return Vector2i(int(arr[0]), int(arr[1]))
