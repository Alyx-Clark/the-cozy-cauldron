class_name NotificationPopup
extends Label
## Self-contained notification banner. Fades in (0.25s), holds (1.5s), fades out
## (0.5s), then queue_free's itself. Used for "Order Complete! +Xg" messages.
## Call the static method: NotificationPopup.show_notification(parent, text)

static func show_notification(parent: Node, message: String) -> void:
	var popup := NotificationPopup.new()
	popup.text = message
	parent.add_child(popup)

func _ready() -> void:
	# Style
	add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	add_theme_font_size_override("font_size", 24)
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# Center on screen
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.35
	anchor_bottom = 0.35
	offset_left = -200
	offset_right = 200
	offset_top = -20
	offset_bottom = 20

	# Shadow for readability
	add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	add_theme_constant_override("shadow_offset_x", 2)
	add_theme_constant_override("shadow_offset_y", 2)

	# Start invisible, animate in
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.25)
	tween.tween_interval(1.5)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
