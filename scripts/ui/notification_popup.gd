class_name NotificationPopup
extends PanelContainer
## Self-contained notification banner. Fades in (0.25s), holds (1.5s), fades out
## (0.5s), then queue_free's itself. Used for "Order Complete! +Xg" messages.
## Call the static method: NotificationPopup.show_notification(parent, text)

static func show_notification(parent: Node, message: String) -> void:
	var popup := NotificationPopup.new()
	popup._message = message
	parent.add_child(popup)

var _message: String = ""

func _ready() -> void:
	# Center on screen
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.35
	anchor_bottom = 0.35
	offset_left = -200
	offset_right = 200
	offset_top = -24
	offset_bottom = 24

	# Wood panel background
	add_theme_stylebox_override("panel", UITheme.make_wood_panel_style())

	# Content: HBox with optional coin icon + message label
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 8)
	add_child(hbox)

	# Coin icon if the message contains gold amount
	if "g" in _message or "+" in _message:
		var coin := TextureRect.new()
		coin.texture = UITheme.get_coin_texture()
		coin.custom_minimum_size = Vector2(16, 16)
		coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hbox.add_child(coin)

	var label := Label.new()
	label.text = _message
	UITheme.apply_label_style(label, UITheme.FONT_SIZE_LARGE, UITheme.COLOR_GOLD)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Shadow for readability
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	hbox.add_child(label)

	# Start invisible, animate in
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.25)
	tween.tween_interval(1.5)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
