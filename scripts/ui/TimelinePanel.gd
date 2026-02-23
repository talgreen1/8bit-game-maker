class_name TimelinePanel
extends PanelContainer

signal timeline_updated(entries: Array)
signal scene_selected(scene_id: String)
signal scrub_requested(time_seconds: float)

var _entries: Array = []
var _list: ItemList
var _start_spin: SpinBox
var _duration_spin: SpinBox
var _scrub_slider: HSlider
var _time_label: Label
var _is_updating_controls: bool = false


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	add_child(root)

	var title: Label = Label.new()
	title.text = "Timeline"
	root.add_child(title)

	_list = ItemList.new()
	_list.custom_minimum_size = Vector2(0, 140)
	_list.item_selected.connect(_on_list_item_selected)
	root.add_child(_list)

	var button_row: HBoxContainer = HBoxContainer.new()
	root.add_child(button_row)

	var add_button: Button = Button.new()
	add_button.text = "Add Scene"
	add_button.pressed.connect(_on_add_scene_pressed)
	button_row.add_child(add_button)

	var remove_button: Button = Button.new()
	remove_button.text = "Remove"
	remove_button.pressed.connect(_on_remove_scene_pressed)
	button_row.add_child(remove_button)

	var props_row: HBoxContainer = HBoxContainer.new()
	root.add_child(props_row)

	_start_spin = SpinBox.new()
	_start_spin.step = 0.1
	_start_spin.min_value = 0.0
	_start_spin.prefix = "Start "
	_start_spin.value_changed.connect(_on_entry_value_changed)
	props_row.add_child(_start_spin)

	_duration_spin = SpinBox.new()
	_duration_spin.step = 0.1
	_duration_spin.min_value = 0.1
	_duration_spin.prefix = "Dur "
	_duration_spin.value_changed.connect(_on_entry_value_changed)
	props_row.add_child(_duration_spin)

	_time_label = Label.new()
	_time_label.text = "t=0.00s"
	root.add_child(_time_label)

	_scrub_slider = HSlider.new()
	_scrub_slider.min_value = 0.0
	_scrub_slider.max_value = 120.0
	_scrub_slider.step = 0.01
	_scrub_slider.value_changed.connect(_on_scrub_changed)
	root.add_child(_scrub_slider)


func set_timeline(entries: Array) -> void:
	_entries = []
	for raw_entry in entries:
		if typeof(raw_entry) != TYPE_DICTIONARY:
			continue
		_entries.append(raw_entry.duplicate(true))
	_refresh_list()
	_update_scrub_limit()


func set_current_time(time_seconds: float) -> void:
	_is_updating_controls = true
	_scrub_slider.value = clampf(time_seconds, _scrub_slider.min_value, _scrub_slider.max_value)
	_time_label.text = "t=%.2fs" % time_seconds
	_is_updating_controls = false


func get_timeline_entries() -> Array:
	return _entries.duplicate(true)


func _refresh_list() -> void:
	_list.clear()
	for entry in _entries:
		var scene_id: String = str(entry.get("scene_id", "scene_unknown"))
		var start: float = float(entry.get("start", 0.0))
		var duration: float = float(entry.get("duration", 0.0))
		_list.add_item("%s  [%.2f - %.2f]" % [scene_id, start, start + duration])

	if not _entries.is_empty():
		_list.select(0)
		_load_selected_entry_controls(0)
		emit_signal("scene_selected", str(_entries[0].get("scene_id", "")))


func _update_scrub_limit() -> void:
	var end_time: float = 1.0
	for entry in _entries:
		var start: float = float(entry.get("start", 0.0))
		var duration: float = float(entry.get("duration", 0.0))
		end_time = maxf(end_time, start + duration)
	_scrub_slider.max_value = end_time


func _load_selected_entry_controls(index: int) -> void:
	if index < 0 or index >= _entries.size():
		return
	var entry: Dictionary = _entries[index]
	_is_updating_controls = true
	_start_spin.value = float(entry.get("start", 0.0))
	_duration_spin.value = float(entry.get("duration", 1.0))
	_is_updating_controls = false


func _on_list_item_selected(index: int) -> void:
	_load_selected_entry_controls(index)
	var entry: Dictionary = _entries[index]
	emit_signal("scene_selected", str(entry.get("scene_id", "")))


func _on_entry_value_changed(_value: float) -> void:
	if _is_updating_controls:
		return
	var selected: Array = _list.get_selected_items()
	if selected.is_empty():
		return
	var index: int = int(selected[0])
	var entry: Dictionary = _entries[index]
	entry["start"] = _start_spin.value
	entry["duration"] = _duration_spin.value
	_entries[index] = entry
	_refresh_list()
	_list.select(index)
	_update_scrub_limit()
	emit_signal("timeline_updated", _entries.duplicate(true))


func _on_add_scene_pressed() -> void:
	var next_index: int = _entries.size() + 1
	var scene_id: String = "scene_%03d" % next_index
	var start: float = 0.0
	if not _entries.is_empty():
		var last: Dictionary = _entries[_entries.size() - 1]
		start = float(last.get("start", 0.0)) + float(last.get("duration", 0.0))
	var entry: Dictionary = {
		"scene_id": scene_id,
		"start": start,
		"duration": 4.0,
		"transition_out": "cut",
	}
	_entries.append(entry)
	_refresh_list()
	var idx: int = _entries.size() - 1
	_list.select(idx)
	_load_selected_entry_controls(idx)
	_update_scrub_limit()
	emit_signal("timeline_updated", _entries.duplicate(true))
	emit_signal("scene_selected", scene_id)


func _on_remove_scene_pressed() -> void:
	var selected: Array = _list.get_selected_items()
	if selected.is_empty():
		return
	var index: int = int(selected[0])
	_entries.remove_at(index)
	_refresh_list()
	_update_scrub_limit()
	emit_signal("timeline_updated", _entries.duplicate(true))
	if _entries.is_empty():
		emit_signal("scene_selected", "")


func _on_scrub_changed(value: float) -> void:
	if _is_updating_controls:
		return
	_time_label.text = "t=%.2fs" % value
	emit_signal("scrub_requested", value)
