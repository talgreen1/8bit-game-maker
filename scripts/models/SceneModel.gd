class_name SceneModel
extends RefCounted

var scene_name := ""
var background: Dictionary = {}
var actors: Array[Dictionary] = []
var scene_dir := ""
var last_error := ""


func load(path: String) -> bool:
	last_error = ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		last_error = "Unable to open scene file at %s" % path
		return false

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		last_error = "Invalid JSON format in scene file."
		return false

	var data: Dictionary = parsed
	var validation_error: String = validate_dict(data)
	if validation_error != "":
		last_error = validation_error
		return false

	scene_name = str(data.get("scene_name", "Unnamed Scene"))
	background = data.get("background", {})
	actors = []
	for actor in data.get("actors", []):
		actors.append(actor)

	scene_dir = path.get_base_dir()
	return true


func save(path: String) -> bool:
	last_error = ""
	var data := {
		"scene_name": scene_name,
		"background": background,
		"actors": actors,
	}

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		last_error = "Unable to write scene file at %s" % path
		return false

	file.store_string(JSON.stringify(data, "  "))
	scene_dir = path.get_base_dir()
	return true


func validate_dict(data: Dictionary) -> String:
	for key in ["scene_name", "background", "actors"]:
		if not data.has(key):
			return "Missing required field '%s' in scene file." % key

	if typeof(data["background"]) != TYPE_DICTIONARY:
		return "Field 'background' must be an object."
	if typeof(data["actors"]) != TYPE_ARRAY:
		return "Field 'actors' must be an array."

	if data["actors"].is_empty():
		return "Scene requires at least one actor."

	var actor_entries: Array = data["actors"]
	var first_actor: Variant = actor_entries[0]
	if typeof(first_actor) != TYPE_DICTIONARY:
		return "First actor entry must be an object."
	var first_actor_dict: Dictionary = first_actor
	if not first_actor_dict.has("start_pos"):
		return "First actor is missing required field 'start_pos'."

	return ""


func resolve_asset_path(asset_path: String) -> String:
	if asset_path == "":
		return ""
	if asset_path.begins_with("res://") or asset_path.begins_with("user://"):
		return asset_path
	if asset_path.is_absolute_path():
		return asset_path
	if scene_dir == "":
		return asset_path
	return scene_dir.path_join(asset_path)
