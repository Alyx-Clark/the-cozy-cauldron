extends PanelContainer

# Toggle visibility with U key

var _content: VBoxContainer
var _recipe_buttons: Array = []
var _machine_buttons: Array = []

# Sprite paths (duplicated — don't cross-reference class_name constants)
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

const POTION_SPRITE_PATHS: Dictionary = {
	21: "res://assets/sprites/items/health_potion.png",
	22: "res://assets/sprites/items/mana_potion.png",
	23: "res://assets/sprites/items/speed_potion.png",
	24: "res://assets/sprites/items/love_potion.png",
	25: "res://assets/sprites/items/invisibility_potion.png",
	26: "res://assets/sprites/items/fire_resistance_potion.png",
	27: "res://assets/sprites/items/strength_potion.png",
	28: "res://assets/sprites/items/night_vision_potion.png",
	29: "res://assets/sprites/items/water_breathing_potion.png",
	30: "res://assets/sprites/items/lucky_potion.png",
}

func _ready() -> void:
	# Position centered on screen, slightly larger
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.5
	anchor_bottom = 0.5
	offset_left = -250
	offset_right = 250
	offset_top = -230
	offset_bottom = 230

	# Wood panel style
	add_theme_stylebox_override("panel", UITheme.make_wood_panel_style())

	# Close button (top-right corner)
	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(28, 24)
	UITheme.apply_button_theme(close_btn, UITheme.FONT_SIZE_MEDIUM)
	close_btn.anchor_left = 1.0
	close_btn.anchor_right = 1.0
	close_btn.offset_left = -36
	close_btn.offset_right = -8
	close_btn.offset_top = 6
	close_btn.offset_bottom = 30
	close_btn.pressed.connect(func(): visible = false)
	add_child(close_btn)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)

	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 8)
	scroll.add_child(_content)

	# Title
	var title := Label.new()
	title.text = "Unlock Shop"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_label_style(title, UITheme.FONT_SIZE_TITLE, UITheme.COLOR_TITLE)
	_content.add_child(title)

	# ── Recipe section ──
	var recipe_header := Label.new()
	recipe_header.text = "Recipes"
	UITheme.apply_label_style(recipe_header, UITheme.FONT_SIZE_LARGE, Color(0.8, 0.7, 1.0))
	_content.add_child(recipe_header)

	# Decorative underline
	var recipe_line := ColorRect.new()
	recipe_line.color = Color(0.55, 0.42, 0.25, 0.6)
	recipe_line.custom_minimum_size = Vector2(0, 2)
	_content.add_child(recipe_line)

	# Grid: 2 columns for recipes
	var recipe_grid := GridContainer.new()
	recipe_grid.columns = 2
	recipe_grid.add_theme_constant_override("h_separation", 8)
	recipe_grid.add_theme_constant_override("v_separation", 6)
	_content.add_child(recipe_grid)

	for i in range(Recipes.RECIPE_LIST.size()):
		_add_recipe_item(recipe_grid, i)

	# Separator
	var sep := ColorRect.new()
	sep.color = Color(0.55, 0.42, 0.25, 0.4)
	sep.custom_minimum_size = Vector2(0, 2)
	_content.add_child(sep)

	# ── Machine section ──
	var machine_header := Label.new()
	machine_header.text = "Machines"
	UITheme.apply_label_style(machine_header, UITheme.FONT_SIZE_LARGE, Color(0.7, 1.0, 0.8))
	_content.add_child(machine_header)

	var machine_line := ColorRect.new()
	machine_line.color = Color(0.55, 0.42, 0.25, 0.6)
	machine_line.custom_minimum_size = Vector2(0, 2)
	_content.add_child(machine_line)

	# Grid: 3 columns for machines
	var machine_grid := GridContainer.new()
	machine_grid.columns = 3
	machine_grid.add_theme_constant_override("h_separation", 6)
	machine_grid.add_theme_constant_override("v_separation", 6)
	_content.add_child(machine_grid)

	for key in GameState.MACHINE_COSTS.keys():
		if GameState.MACHINE_COSTS[key] > 0:
			_add_machine_item(machine_grid, key)

	# Listen for changes
	GameState.gold_changed.connect(_on_gold_changed)
	GameState.recipe_unlocked.connect(_on_recipe_unlocked)
	GameState.machine_unlocked.connect(_on_machine_unlocked)

	visible = false

func _add_recipe_item(parent: GridContainer, index: int) -> void:
	var recipe: Array = Recipes.RECIPE_LIST[index]
	var result_name: String = ItemTypes.NAMES.get(recipe[2], "?")
	var cost: int = GameState.RECIPE_COSTS[index]

	var card := VBoxContainer.new()
	card.add_theme_constant_override("separation", 2)
	card.custom_minimum_size = Vector2(220, 0)

	# Top: icon + name
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	card.add_child(top)

	# Potion sprite
	var icon := TextureRect.new()
	var tex_path: String = POTION_SPRITE_PATHS.get(recipe[2], "")
	if tex_path != "" and ResourceLoader.exists(tex_path):
		icon.texture = load(tex_path) as Texture2D
	icon.custom_minimum_size = Vector2(24, 24)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	top.add_child(icon)

	var name_label := Label.new()
	name_label.text = result_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.apply_label_style(name_label, 13, UITheme.COLOR_TEXT)
	top.add_child(name_label)

	# Buy button
	var btn := Button.new()
	if cost == 0:
		btn.text = "Free"
		btn.disabled = true
	else:
		btn.text = str(cost) + "g"
	btn.custom_minimum_size = Vector2(65, 24)
	UITheme.apply_button_theme(btn, UITheme.FONT_SIZE_SMALL)
	btn.pressed.connect(_on_recipe_buy.bind(index, btn))
	top.add_child(btn)

	# Ingredient hint
	var ing_a: String = ItemTypes.NAMES.get(recipe[0], "?")
	var ing_b: String = ItemTypes.NAMES.get(recipe[1], "?")
	var hint := Label.new()
	hint.text = ing_a + " + " + ing_b
	UITheme.apply_label_style(hint, 11, UITheme.COLOR_TEXT_DIM)
	card.add_child(hint)

	parent.add_child(card)
	_recipe_buttons.append({"index": index, "button": btn, "cost": cost})

func _add_machine_item(parent: GridContainer, key: String) -> void:
	var display_name: String = GameState.MACHINE_NAMES.get(key, key)
	var cost: int = GameState.MACHINE_COSTS[key]

	var card := VBoxContainer.new()
	card.add_theme_constant_override("separation", 2)
	card.alignment = BoxContainer.ALIGNMENT_CENTER
	card.custom_minimum_size = Vector2(148, 0)

	# Machine sprite
	var icon := TextureRect.new()
	var tex_path: String = MACHINE_SPRITE_PATHS.get(key, "")
	if tex_path != "" and ResourceLoader.exists(tex_path):
		icon.texture = load(tex_path) as Texture2D
	icon.custom_minimum_size = Vector2(32, 32)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card.add_child(icon)

	# Name
	var name_label := Label.new()
	name_label.text = display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_label_style(name_label, 13, UITheme.COLOR_TEXT)
	card.add_child(name_label)

	# Buy button
	var btn := Button.new()
	btn.text = str(cost) + "g"
	btn.custom_minimum_size = Vector2(65, 24)
	UITheme.apply_button_theme(btn, UITheme.FONT_SIZE_SMALL)
	btn.pressed.connect(_on_machine_buy.bind(key, btn))
	card.add_child(btn)

	parent.add_child(card)
	_machine_buttons.append({"key": key, "button": btn, "cost": cost})

func _on_recipe_buy(index: int, btn: Button) -> void:
	if GameState.unlock_recipe(index):
		btn.text = "Owned"
		btn.disabled = true
		SoundManager.play("unlock")
		_animate_purchase(btn)

func _on_machine_buy(key: String, btn: Button) -> void:
	if GameState.unlock_machine(key):
		btn.text = "Owned"
		btn.disabled = true
		SoundManager.play("unlock")
		_animate_purchase(btn)

func _animate_purchase(btn: Button) -> void:
	# Green flash then fade back
	btn.add_theme_color_override("font_color", UITheme.COLOR_POSITIVE)
	var tween := btn.create_tween()
	tween.set_parallel(true)
	tween.tween_property(btn, "scale", Vector2(1.15, 1.15), 0.1).set_ease(Tween.EASE_OUT)
	tween.set_parallel(false)
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.15).set_ease(Tween.EASE_IN)
	tween.tween_callback(btn.remove_theme_color_override.bind("font_color"))

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
		elif event.keycode == KEY_ESCAPE and visible:
			visible = false
			get_viewport().set_input_as_handled()
