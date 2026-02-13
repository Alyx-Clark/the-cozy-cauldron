extends PanelContainer

signal machine_selected(machine_type: String)

var _buttons: Dictionary = {}
var _current_selection: String = ""

func _ready() -> void:
	var hbox := HBoxContainer.new()
	hbox.name = "HBox"
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 8)
	add_child(hbox)

	# Add machine buttons
	_add_button(hbox, "Conveyor", "conveyor", Color(0.45, 0.45, 0.5))
	_add_button(hbox, "Dispenser", "dispenser", Color(0.3, 0.65, 0.4))
	_add_button(hbox, "Cauldron", "cauldron", Color(0.6, 0.35, 0.65))

	# Style the panel
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.11, 0.16, 0.9)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	add_theme_stylebox_override("panel", style)

func _add_button(parent: HBoxContainer, label: String, machine_type: String, color: Color) -> void:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(100, 40)
	btn.toggle_mode = true

	# Style the button
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(color, 0.3)
	normal_style.corner_radius_top_left = 4
	normal_style.corner_radius_top_right = 4
	normal_style.corner_radius_bottom_left = 4
	normal_style.corner_radius_bottom_right = 4
	normal_style.content_margin_left = 8
	normal_style.content_margin_right = 8
	normal_style.content_margin_top = 4
	normal_style.content_margin_bottom = 4
	btn.add_theme_stylebox_override("normal", normal_style)

	var pressed_style := StyleBoxFlat.new()
	pressed_style.bg_color = Color(color, 0.8)
	pressed_style.corner_radius_top_left = 4
	pressed_style.corner_radius_top_right = 4
	pressed_style.corner_radius_bottom_left = 4
	pressed_style.corner_radius_bottom_right = 4
	pressed_style.content_margin_left = 8
	pressed_style.content_margin_right = 8
	pressed_style.content_margin_top = 4
	pressed_style.content_margin_bottom = 4
	btn.add_theme_stylebox_override("pressed", pressed_style)

	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color(color, 0.5)
	hover_style.corner_radius_top_left = 4
	hover_style.corner_radius_top_right = 4
	hover_style.corner_radius_bottom_left = 4
	hover_style.corner_radius_bottom_right = 4
	hover_style.content_margin_left = 8
	hover_style.content_margin_right = 8
	hover_style.content_margin_top = 4
	hover_style.content_margin_bottom = 4
	btn.add_theme_stylebox_override("hover", hover_style)

	btn.pressed.connect(_on_button_pressed.bind(machine_type, btn))
	parent.add_child(btn)
	_buttons[machine_type] = btn

func _on_button_pressed(machine_type: String, btn: Button) -> void:
	if _current_selection == machine_type:
		# Deselect
		_current_selection = ""
		btn.button_pressed = false
		machine_selected.emit("")
	else:
		# Deselect previous
		if _buttons.has(_current_selection):
			_buttons[_current_selection].button_pressed = false
		_current_selection = machine_type
		machine_selected.emit(machine_type)
