class_name ProjectPanel
extends PanelContainer

signal open_requested(path: String)
signal save_requested(path: String)

var _path_edit: LineEdit
var _status_label: Label


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	add_child(root)

	var title: Label = Label.new()
	title.text = "Project"
	root.add_child(title)

	_path_edit = LineEdit.new()
	_path_edit.placeholder_text = "res://sample_project/project.json"
	root.add_child(_path_edit)

	var button_row: HBoxContainer = HBoxContainer.new()
	root.add_child(button_row)

	var open_button: Button = Button.new()
	open_button.text = "Open"
	open_button.pressed.connect(_on_open_pressed)
	button_row.add_child(open_button)

	var save_button: Button = Button.new()
	save_button.text = "Save"
	save_button.pressed.connect(_on_save_pressed)
	button_row.add_child(save_button)

	_status_label = Label.new()
	_status_label.text = ""
	root.add_child(_status_label)


func set_project_path(path: String) -> void:
	_path_edit.text = path


func set_status(message: String) -> void:
	_status_label.text = message


func _on_open_pressed() -> void:
	emit_signal("open_requested", _path_edit.text.strip_edges())


func _on_save_pressed() -> void:
	emit_signal("save_requested", _path_edit.text.strip_edges())
