class_name InspectorPanel
extends PanelContainer

signal background_color_changed(color_text: String)
signal actor_velocity_changed(new_velocity: Vector2)
signal camera_mode_changed(mode: String)

var _background_color_edit: LineEdit
var _velocity_x_spin: SpinBox
var _velocity_y_spin: SpinBox
var _camera_mode_option: OptionButton
var _is_updating_controls: bool = false


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	add_child(root)

	var title: Label = Label.new()
	title.text = "Inspector"
	root.add_child(title)

	_background_color_edit = LineEdit.new()
	_background_color_edit.placeholder_text = "Background color, e.g. #243b55"
	_background_color_edit.text_submitted.connect(_on_background_color_submitted)
	root.add_child(_background_color_edit)

	var velocity_row: HBoxContainer = HBoxContainer.new()
	root.add_child(velocity_row)

	_velocity_x_spin = SpinBox.new()
	_velocity_x_spin.min_value = -500
	_velocity_x_spin.max_value = 500
	_velocity_x_spin.step = 1.0
	_velocity_x_spin.prefix = "Vel X "
	_velocity_x_spin.value_changed.connect(_on_velocity_changed)
	velocity_row.add_child(_velocity_x_spin)

	_velocity_y_spin = SpinBox.new()
	_velocity_y_spin.min_value = -500
	_velocity_y_spin.max_value = 500
	_velocity_y_spin.step = 1.0
	_velocity_y_spin.prefix = "Vel Y "
	_velocity_y_spin.value_changed.connect(_on_velocity_changed)
	velocity_row.add_child(_velocity_y_spin)

	_camera_mode_option = OptionButton.new()
	_camera_mode_option.add_item("static")
	_camera_mode_option.add_item("follow")
	_camera_mode_option.add_item("pan")
	_camera_mode_option.item_selected.connect(_on_camera_mode_selected)
	root.add_child(_camera_mode_option)


func set_background_color(color_text: String) -> void:
	_background_color_edit.text = color_text


func set_actor_velocity(velocity_value: Vector2) -> void:
	_is_updating_controls = true
	_velocity_x_spin.value = velocity_value.x
	_velocity_y_spin.value = velocity_value.y
	_is_updating_controls = false


func set_camera_mode(mode: String) -> void:
	var target_index: int = 0
	for i in range(_camera_mode_option.item_count):
		if _camera_mode_option.get_item_text(i) == mode:
			target_index = i
			break
	_camera_mode_option.select(target_index)


func _on_background_color_submitted(text: String) -> void:
	emit_signal("background_color_changed", text.strip_edges())


func _on_velocity_changed(_value: float) -> void:
	if _is_updating_controls:
		return
	emit_signal("actor_velocity_changed", Vector2(_velocity_x_spin.value, _velocity_y_spin.value))


func _on_camera_mode_selected(index: int) -> void:
	emit_signal("camera_mode_changed", _camera_mode_option.get_item_text(index))
