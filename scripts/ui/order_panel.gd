extends PanelContainer

# Right-side panel showing active orders

var _content: VBoxContainer
var _order_labels: Dictionary = {}  # order_id → {name_label, progress_label, reward_label}

func _ready() -> void:
	# Position on right side
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 0.0
	offset_left = -190
	offset_right = -8
	offset_top = 52
	offset_bottom = 260

	# Panel style
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.09, 0.14, 0.85)
	style.border_color = Color(0.35, 0.3, 0.45, 0.6)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	add_theme_stylebox_override("panel", style)

	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 6)
	add_child(_content)

	# Title
	var title := Label.new()
	title.text = "Orders"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
	title.add_theme_font_size_override("font_size", 14)
	_content.add_child(title)

func update_orders(orders: Array) -> void:
	# Clear existing order displays (keep title)
	while _content.get_child_count() > 1:
		var child := _content.get_child(1)
		_content.remove_child(child)
		child.queue_free()
	_order_labels.clear()

	if orders.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No orders yet"
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
		empty_label.add_theme_font_size_override("font_size", 12)
		_content.add_child(empty_label)
		return

	for order in orders:
		_add_order_card(order)

func _add_order_card(order: Dictionary) -> void:
	var card := VBoxContainer.new()
	card.add_theme_constant_override("separation", 2)

	# Potion name
	var potion_name: String = ItemTypes.NAMES.get(order["potion_type"], "?")
	var name_label := Label.new()
	name_label.text = potion_name
	var potion_color: Color = ItemTypes.COLORS.get(order["potion_type"], Color.WHITE)
	name_label.add_theme_color_override("font_color", potion_color)
	name_label.add_theme_font_size_override("font_size", 13)
	card.add_child(name_label)

	# Progress
	var progress_label := Label.new()
	progress_label.text = "%d / %d" % [order["progress"], order["quantity"]]
	progress_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
	progress_label.add_theme_font_size_override("font_size", 12)
	card.add_child(progress_label)

	# Reward
	var reward_label := Label.new()
	reward_label.text = "Reward: %dg" % order["reward"]
	reward_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	reward_label.add_theme_font_size_override("font_size", 11)
	card.add_child(reward_label)

	# Separator line
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 4)
	card.add_child(sep)

	_content.add_child(card)
