extends PanelContainer

signal machine_selected(machine_type: String)

var _buttons: Dictionary = {}
var _current_selection: String = ""
var _hbox: HBoxContainer

# Machine button definitions: [label, key, color]
const MACHINE_DEFS: Array = [
	["Belt", "conveyor", Color(0.45, 0.45, 0.5)],
	["Dispenser", "dispenser", Color(0.3, 0.65, 0.4)],
	["Cauldron", "cauldron", Color(0.6, 0.35, 0.65)],
	["Fast Belt", "fast_belt", Color(0.75, 0.6, 0.2)],
	["Storage", "storage", Color(0.55, 0.38, 0.2)],
	["Splitter", "splitter", Color(0.6, 0.3, 0.7)],
	["Sorter", "sorter", Color(0.2, 0.6, 0.6)],
	["Bottler", "bottler", Color(0.75, 0.55, 0.15)],
	["Seller", "auto_seller", Color(0.8, 0.7, 0.1)],
]

func _ready() -> void:
	_hbox = HBoxContainer.new()
	_hbox.name = "HBox"
	_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_hbox.add_theme_constant_override("separation", 4)
	add_child(_hbox)

	# Add all machine buttons
	for def in MACHINE_DEFS:
		_add_button(_hbox, def[0], def[1], def[2])

	# Style the panel
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.11, 0.16, 0.9)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	add_theme_stylebox_override("panel", style)

	# Listen for unlock events to update button states
	GameState.machine_unlocked.connect(_on_machine_unlocked)
	_update_lock_states()

func _add_button(parent: HBoxContainer, label: String, machine_type: String, color: Color) -> void:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(80, 40)
	btn.toggle_mode = true

	# Style the button
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(color, 0.3)
	normal_style.corner_radius_top_left = 4
	normal_style.corner_radius_top_right = 4
	normal_style.corner_radius_bottom_left = 4
	normal_style.corner_radius_bottom_right = 4
	normal_style.content_margin_left = 4
	normal_style.content_margin_right = 4
	normal_style.content_margin_top = 4
	normal_style.content_margin_bottom = 4
	btn.add_theme_stylebox_override("normal", normal_style)

	var pressed_style := StyleBoxFlat.new()
	pressed_style.bg_color = Color(color, 0.8)
	pressed_style.corner_radius_top_left = 4
	pressed_style.corner_radius_top_right = 4
	pressed_style.corner_radius_bottom_left = 4
	pressed_style.corner_radius_bottom_right = 4
	pressed_style.content_margin_left = 4
	pressed_style.content_margin_right = 4
	pressed_style.content_margin_top = 4
	pressed_style.content_margin_bottom = 4
	btn.add_theme_stylebox_override("pressed", pressed_style)

	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color(color, 0.5)
	hover_style.corner_radius_top_left = 4
	hover_style.corner_radius_top_right = 4
	hover_style.corner_radius_bottom_left = 4
	hover_style.corner_radius_bottom_right = 4
	hover_style.content_margin_left = 4
	hover_style.content_margin_right = 4
	hover_style.content_margin_top = 4
	hover_style.content_margin_bottom = 4
	btn.add_theme_stylebox_override("hover", hover_style)

	# Disabled style
	var disabled_style := StyleBoxFlat.new()
	disabled_style.bg_color = Color(0.2, 0.2, 0.2, 0.4)
	disabled_style.corner_radius_top_left = 4
	disabled_style.corner_radius_top_right = 4
	disabled_style.corner_radius_bottom_left = 4
	disabled_style.corner_radius_bottom_right = 4
	disabled_style.content_margin_left = 4
	disabled_style.content_margin_right = 4
	disabled_style.content_margin_top = 4
	disabled_style.content_margin_bottom = 4
	btn.add_theme_stylebox_override("disabled", disabled_style)

	btn.add_theme_font_size_override("font_size", 12)
	btn.pressed.connect(_on_button_pressed.bind(machine_type, btn))
	parent.add_child(btn)
	_buttons[machine_type] = btn

func _on_button_pressed(machine_type: String, btn: Button) -> void:
	SoundManager.play("click")
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

func _on_machine_unlocked(_key: String) -> void:
	_update_lock_states()

func _update_lock_states() -> void:
	for def in MACHINE_DEFS:
		var key: String = def[1]
		if _buttons.has(key):
			var btn: Button = _buttons[key]
			btn.disabled = not GameState.is_machine_unlocked(key)
			if btn.disabled and _current_selection == key:
				_current_selection = ""
				btn.button_pressed = false
				machine_selected.emit("")
