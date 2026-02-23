class_name SceneEditorPanel
extends PanelContainer

signal actor_position_changed(new_position: Vector2)

var _x_spin: SpinBox
var _y_spin: SpinBox
var _is_updating_controls: bool = false


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	add_child(root)

	var title: Label = Label.new()
	title.text = "Scene Editor"
	root.add_child(title)

	var pos_row: HBoxContainer = HBoxContainer.new()
	root.add_child(pos_row)

	_x_spin = SpinBox.new()
	_x_spin.min_value = -4096
	_x_spin.max_value = 4096
	_x_spin.step = 1.0
	_x_spin.prefix = "X "
	_x_spin.value_changed.connect(_on_position_changed)
	pos_row.add_child(_x_spin)

	_y_spin = SpinBox.new()
	_y_spin.min_value = -4096
	_y_spin.max_value = 4096
	_y_spin.step = 1.0
	_y_spin.prefix = "Y "
	_y_spin.value_changed.connect(_on_position_changed)
	pos_row.add_child(_y_spin)


func set_actor_position(position_value: Vector2) -> void:
	_is_updating_controls = true
	_x_spin.value = position_value.x
	_y_spin.value = position_value.y
	_is_updating_controls = false


func _on_position_changed(_value: float) -> void:
	if _is_updating_controls:
		return
	emit_signal("actor_position_changed", Vector2(_x_spin.value, _y_spin.value))
