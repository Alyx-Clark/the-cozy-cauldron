extends PanelContainer

signal machine_selected(machine_type: String)

var _buttons: Dictionary = {}
var _current_selection: String = ""
var _hbox: HBoxContainer

# Machine button definitions: [short_label, key]
const MACHINE_DEFS: Array = [
	["Belt", "conveyor"],
	["Dispnsr", "dispenser"],
	["Cauldrn", "cauldron"],
	["Fast", "fast_belt"],
	["Chest", "storage"],
	["Split", "splitter"],
	["Sorter", "sorter"],
	["Bottler", "bottler"],
	["Seller", "auto_seller"],
]

# Sprite paths per machine type (duplicated — don't cross-reference class_name constants)
const MACHINE_SPRITE_PATHS: Dictionary = {
	"conveyor": "res://assets/sprites/machines/conveyor.png",
	"fast_belt": "res://assets/sprites/machines/fast_belt.png",
	"dispenser": "res://assets/sprites/machines/dispenser.png",
	"cauldron": "res://assets/sprites/machines/cauldron.png",
	"storage": "res://assets/sprites/machines/storage.png",
	"splitter": "res://assets/sprites/machines/splitter.png",
	"sorter": "res://assets/sprites/machines/sorter.png",
	"bottler": "res://assets/sprites/machines/bottler.png",
	"auto_seller": "res://assets/sprites/machines/auto_seller.png",
}

# Descriptions for tooltips (accessed by tooltip system)
const MACHINE_DESCRIPTIONS: Dictionary = {
	"conveyor": "Moves items forward",
	"fast_belt": "2x speed conveyor",
	"dispenser": "Spawns ingredients",
	"cauldron": "Brews potions from 2 items",
	"storage": "Buffers up to 8 items",
	"splitter": "Duplicates items (1->2)",
	"sorter": "Routes items by type",
	"bottler": "Bottles potions for 2x price",
	"auto_seller": "Sells potions for gold",
}

func _ready() -> void:
	_hbox = HBoxContainer.new()
	_hbox.name = "HBox"
	_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_hbox.add_theme_constant_override("separation", 3)
	add_child(_hbox)

	for def in MACHINE_DEFS:
		_add_button(_hbox, def[0], def[1])

	# Wood panel style
	add_theme_stylebox_override("panel", UITheme.make_wood_panel_style())

	# Listen for unlock events to update button states
	GameState.machine_unlocked.connect(_on_machine_unlocked)
	_update_lock_states()

func _add_button(parent: HBoxContainer, label_text: String, machine_type: String) -> void:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(62, 58)
	btn.toggle_mode = true
	btn.clip_text = true

	# Build a VBoxContainer with icon + label inside the button
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 1)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(vbox)

	# Machine sprite icon
	var icon := TextureRect.new()
	icon.name = "Icon"
	var tex_path: String = MACHINE_SPRITE_PATHS.get(machine_type, "")
	if tex_path != "" and ResourceLoader.exists(tex_path):
		icon.texture = load(tex_path) as Texture2D
	icon.custom_minimum_size = Vector2(32, 32)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(icon)

	# Short label
	var lbl := Label.new()
	lbl.text = label_text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UITheme.apply_label_style(lbl, 11, UITheme.COLOR_TEXT)
	vbox.add_child(lbl)

	# Lock icon overlay (positioned top-right, hidden by default)
	var lock_icon := TextureRect.new()
	lock_icon.name = "LockIcon"
	lock_icon.texture = UITheme.get_lock_texture()
	lock_icon.custom_minimum_size = Vector2(12, 12)
	lock_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	lock_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lock_icon.position = Vector2(46, 2)
	lock_icon.visible = false
	btn.add_child(lock_icon)

	# Apply wood button styles
	UITheme.apply_button_theme(btn, 11)

	btn.pressed.connect(_on_button_pressed.bind(machine_type, btn))
	btn.mouse_entered.connect(_on_button_hover.bind(machine_type, btn))
	btn.mouse_exited.connect(_on_button_unhover)
	parent.add_child(btn)
	_buttons[machine_type] = btn

func _on_button_hover(machine_type: String, btn: Button) -> void:
	var desc: String = MACHINE_DESCRIPTIONS.get(machine_type, "")
	var display_name: String = ""
	for def in MACHINE_DEFS:
		if def[1] == machine_type:
			display_name = def[0]
			break
	Tooltip.show_at(display_name, desc, "", btn.global_position + Vector2(0, btn.size.y + 4))

func _on_button_unhover() -> void:
	Tooltip.hide_tip()

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
			_update_button_visual(_current_selection, false)
		_current_selection = machine_type
		_update_button_visual(machine_type, true)
		machine_selected.emit(machine_type)

func _update_button_visual(machine_type: String, selected: bool) -> void:
	if not _buttons.has(machine_type):
		return
	var btn: Button = _buttons[machine_type]
	if selected:
		# Golden glow tint when selected
		btn.modulate = Color(1.2, 1.1, 0.7)
	else:
		btn.modulate = Color(1, 1, 1)

func _on_machine_unlocked(_key: String) -> void:
	_update_lock_states()

func _update_lock_states() -> void:
	for def in MACHINE_DEFS:
		var key: String = def[1]
		if _buttons.has(key):
			var btn: Button = _buttons[key]
			var locked: bool = not GameState.is_machine_unlocked(key)
			btn.disabled = locked

			# Show/hide lock icon
			var lock_node := btn.get_node_or_null("LockIcon")
			if lock_node != null:
				lock_node.visible = locked

			# Dim icon when locked
			var icon_node := btn.get_node_or_null("VBoxContainer/Icon")
			if icon_node == null:
				# Try through the button's child VBox
				for child in btn.get_children():
					if child is VBoxContainer:
						icon_node = child.get_node_or_null("Icon")
						break
			if icon_node != null:
				icon_node.modulate = Color(0.5, 0.5, 0.5) if locked else Color(1, 1, 1)

			if locked and _current_selection == key:
				_current_selection = ""
				btn.button_pressed = false
				machine_selected.emit("")
