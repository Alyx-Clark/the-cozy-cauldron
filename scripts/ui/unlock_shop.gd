extends PanelContainer

# Toggle visibility with U key

var _content: VBoxContainer
var _recipe_buttons: Array = []
var _machine_buttons: Array = []

func _ready() -> void:
	# Position centered on screen
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.5
	anchor_bottom = 0.5
	offset_left = -200
	offset_right = 200
	offset_top = -220
	offset_bottom = 220

	# Panel style
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.09, 0.14, 0.95)
	style.border_color = Color(0.4, 0.35, 0.55, 0.8)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	add_theme_stylebox_override("panel", style)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)

	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 6)
	scroll.add_child(_content)

	# Title
	var title := Label.new()
	title.text = "~ Unlock Shop ~"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
	title.add_theme_font_size_override("font_size", 18)
	_content.add_child(title)

	# Recipe section
	var recipe_header := Label.new()
	recipe_header.text = "Recipes"
	recipe_header.add_theme_color_override("font_color", Color(0.8, 0.7, 1.0))
	recipe_header.add_theme_font_size_override("font_size", 14)
	_content.add_child(recipe_header)

	for i in range(Recipes.RECIPE_LIST.size()):
		_add_recipe_row(i)

	# Separator
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 8)
	_content.add_child(sep)

	# Machine section
	var machine_header := Label.new()
	machine_header.text = "Machines"
	machine_header.add_theme_color_override("font_color", Color(0.7, 1.0, 0.8))
	machine_header.add_theme_font_size_override("font_size", 14)
	_content.add_child(machine_header)

	for key in GameState.MACHINE_COSTS.keys():
		if GameState.MACHINE_COSTS[key] > 0:
			_add_machine_row(key)

	# Listen for changes
	GameState.gold_changed.connect(_on_gold_changed)
	GameState.recipe_unlocked.connect(_on_recipe_unlocked)
	GameState.machine_unlocked.connect(_on_machine_unlocked)

	visible = false

func _add_recipe_row(index: int) -> void:
	var recipe: Array = Recipes.RECIPE_LIST[index]
	var result_name: String = ItemTypes.NAMES.get(recipe[2], "?")
	var cost: int = GameState.RECIPE_COSTS[index]

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)

	var name_label := Label.new()
	name_label.text = result_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	hbox.add_child(name_label)

	var btn := Button.new()
	if cost == 0:
		btn.text = "Free"
		btn.disabled = true
	else:
		btn.text = str(cost) + "g"
	btn.custom_minimum_size = Vector2(70, 28)
	btn.add_theme_font_size_override("font_size", 12)
	btn.pressed.connect(_on_recipe_buy.bind(index, btn))
	hbox.add_child(btn)

	_content.add_child(hbox)
	_recipe_buttons.append({"index": index, "button": btn, "cost": cost})

func _add_machine_row(key: String) -> void:
	var display_name: String = GameState.MACHINE_NAMES.get(key, key)
	var cost: int = GameState.MACHINE_COSTS[key]

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)

	var name_label := Label.new()
	name_label.text = display_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	hbox.add_child(name_label)

	var btn := Button.new()
	btn.text = str(cost) + "g"
	btn.custom_minimum_size = Vector2(70, 28)
	btn.add_theme_font_size_override("font_size", 12)
	btn.pressed.connect(_on_machine_buy.bind(key, btn))
	hbox.add_child(btn)

	_content.add_child(hbox)
	_machine_buttons.append({"key": key, "button": btn, "cost": cost})

func _on_recipe_buy(index: int, btn: Button) -> void:
	if GameState.unlock_recipe(index):
		btn.text = "Owned"
		btn.disabled = true

func _on_machine_buy(key: String, btn: Button) -> void:
	if GameState.unlock_machine(key):
		btn.text = "Owned"
		btn.disabled = true

func _on_gold_changed(_amount: int) -> void:
	_refresh_button_states()

func _on_recipe_unlocked(_index: int) -> void:
	_refresh_button_states()

func _on_machine_unlocked(_key: String) -> void:
	_refresh_button_states()

func _refresh_button_states() -> void:
	for entry in _recipe_buttons:
		var btn: Button = entry["button"]
		var index: int = entry["index"]
		var cost: int = entry["cost"]
		if GameState.is_recipe_unlocked(index):
			btn.text = "Owned"
			btn.disabled = true
		else:
			btn.text = str(cost) + "g"
			btn.disabled = GameState.gold < cost

	for entry in _machine_buttons:
		var btn: Button = entry["button"]
		var key: String = entry["key"]
		var cost: int = entry["cost"]
		if GameState.is_machine_unlocked(key):
			btn.text = "Owned"
			btn.disabled = true
		else:
			btn.text = str(cost) + "g"
			btn.disabled = GameState.gold < cost

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_U:
			visible = not visible
			if visible:
				_refresh_button_states()
			get_viewport().set_input_as_handled()
