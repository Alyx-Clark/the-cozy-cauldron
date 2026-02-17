extends PanelContainer

# Right-side panel showing active orders

var _content: VBoxContainer

# Sprite paths per potion type (duplicated — don't cross-reference class_name constants)
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
	# Position on right side
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 0.0
	offset_left = -195
	offset_right = -8
	offset_top = 50
	offset_bottom = 280

	# Wood panel style
	add_theme_stylebox_override("panel", UITheme.make_wood_panel_style())

	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 6)
	add_child(_content)

	# Title
	var title := Label.new()
	title.text = "Orders"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_label_style(title, UITheme.FONT_SIZE_MEDIUM, UITheme.COLOR_TITLE)
	_content.add_child(title)

func update_orders(orders: Array) -> void:
	# Clear existing order displays (keep title)
	while _content.get_child_count() > 1:
		var child := _content.get_child(1)
		_content.remove_child(child)
		child.queue_free()

	if orders.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No orders yet"
		UITheme.apply_label_style(empty_label, UITheme.FONT_SIZE_SMALL, UITheme.COLOR_TEXT_DIM)
		_content.add_child(empty_label)
		return

	for order in orders:
		_add_order_card(order)

func _add_order_card(order: Dictionary) -> void:
	var card := VBoxContainer.new()
	card.add_theme_constant_override("separation", 3)

	# Top row: potion icon + name
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 4)
	card.add_child(top_row)

	# Potion sprite icon
	var potion_icon := TextureRect.new()
	var tex_path: String = POTION_SPRITE_PATHS.get(order["potion_type"], "")
	if tex_path != "" and ResourceLoader.exists(tex_path):
		potion_icon.texture = load(tex_path) as Texture2D
	potion_icon.custom_minimum_size = Vector2(16, 16)
	potion_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	top_row.add_child(potion_icon)

	var potion_name: String = ItemTypes.NAMES.get(order["potion_type"], "?")
	var name_label := Label.new()
	name_label.text = potion_name
	var potion_color: Color = ItemTypes.COLORS.get(order["potion_type"], Color.WHITE)
	UITheme.apply_label_style(name_label, 13, potion_color)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(name_label)

	# Progress bar
	var progress: int = order["progress"]
	var quantity: int = order["quantity"]
	var bar_bg := ColorRect.new()
	bar_bg.custom_minimum_size = Vector2(0, 8)
	bar_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar_bg.color = Color(0.2, 0.18, 0.14)
	card.add_child(bar_bg)

	var fill_ratio: float = float(progress) / float(quantity) if quantity > 0 else 0.0
	var bar_fill := ColorRect.new()
	bar_fill.color = potion_color * Color(1, 1, 1, 0.8)
	bar_fill.size = Vector2(bar_bg.custom_minimum_size.x * fill_ratio, 8)
	bar_bg.add_child(bar_fill)
	# Stretch fill after bar_bg gets its real size
	bar_bg.resized.connect(func(): bar_fill.size = Vector2(bar_bg.size.x * fill_ratio, 8))

	# Progress text + reward row
	var bottom_row := HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 4)
	card.add_child(bottom_row)

	var progress_label := Label.new()
	progress_label.text = "%d/%d" % [progress, quantity]
	UITheme.apply_label_style(progress_label, UITheme.FONT_SIZE_SMALL, UITheme.COLOR_TEXT)
	progress_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_row.add_child(progress_label)

	# Coin icon + reward
	var coin_icon := TextureRect.new()
	coin_icon.texture = UITheme.get_coin_texture()
	coin_icon.custom_minimum_size = Vector2(10, 10)
	coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bottom_row.add_child(coin_icon)

	var reward_label := Label.new()
	reward_label.text = "%dg" % order["reward"]
	UITheme.apply_label_style(reward_label, UITheme.FONT_SIZE_SMALL, UITheme.COLOR_GOLD)
	bottom_row.add_child(reward_label)

	# Separator
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 2)
	sep.add_theme_stylebox_override("separator", _make_wood_separator())
	card.add_child(sep)

	_content.add_child(card)

func _make_wood_separator() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.45, 0.35, 0.2, 0.5)
	style.content_margin_top = 1
	style.content_margin_bottom = 1
	return style
