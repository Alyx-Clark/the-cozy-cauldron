extends PanelContainer
## Unlock prompt that appears when the player walks near a locked region boundary.
##
## Positioned at the top-center of the screen. Shows region name, cost, and
## Yes/No buttons. The "Yes" button is disabled if the player can't afford it.
##
## LIFECYCLE: Created and freed by main._check_region_prompt() which runs every
## frame in _process(). When the player walks within 2 cells of a locked region,
## the prompt is created. When the player walks away or clicks No, it's freed.
## Clicking Yes calls region_manager.unlock_region() and dismisses.
##
## ANIMATION: Fades in over 0.2s on creation, fades out over 0.15s on dismiss.

var _region_id: int = -1
var _region_manager: RegionManager = null

func setup(region: Dictionary, rm: RegionManager) -> void:
	_region_id = region["id"]
	_region_manager = rm

	# Panel style
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.1, 0.08, 0.92)
	style.border_color = Color(0.7, 0.55, 0.2, 0.7)
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

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	add_child(vbox)

	var title := Label.new()
	title.text = "Unlock " + region["name"] + "?"
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.6))
	title.add_theme_font_size_override("font_size", 16)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var cost_label := Label.new()
	cost_label.text = "Cost: " + str(region["cost"]) + "g"
	var can_afford: bool = GameState.gold >= region["cost"]
	cost_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4) if can_afford else Color(1.0, 0.4, 0.3))
	cost_label.add_theme_font_size_override("font_size", 13)
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(cost_label)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 12)
	vbox.add_child(hbox)

	var yes_btn := Button.new()
	yes_btn.text = "Yes"
	yes_btn.custom_minimum_size = Vector2(60, 28)
	yes_btn.disabled = not can_afford
	yes_btn.pressed.connect(_on_yes)
	hbox.add_child(yes_btn)

	var no_btn := Button.new()
	no_btn.text = "No"
	no_btn.custom_minimum_size = Vector2(60, 28)
	no_btn.pressed.connect(_on_no)
	hbox.add_child(no_btn)

	# Position at top center
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.0
	anchor_bottom = 0.0
	offset_left = -120
	offset_right = 120
	offset_top = 10
	offset_bottom = 100

	# Fade in
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)

func _on_yes() -> void:
	if _region_manager != null:
		_region_manager.unlock_region(_region_id)
	_dismiss()

func _on_no() -> void:
	_dismiss()

func _dismiss() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_callback(queue_free)

func get_region_id() -> int:
	return _region_id
