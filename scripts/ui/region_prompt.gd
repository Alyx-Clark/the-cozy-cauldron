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

	# Wood panel style
	add_theme_stylebox_override("panel", UITheme.make_wood_panel_style())

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	add_child(vbox)

	var title := Label.new()
	title.text = "Unlock " + region["name"] + "?"
	UITheme.apply_label_style(title, UITheme.FONT_SIZE_MEDIUM, UITheme.COLOR_TITLE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Cost row with coin icon
	var cost_row := HBoxContainer.new()
	cost_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cost_row.add_theme_constant_override("separation", 4)
	vbox.add_child(cost_row)

	var cost_prefix := Label.new()
	cost_prefix.text = "Cost: "
	var can_afford: bool = GameState.gold >= region["cost"]
	UITheme.apply_label_style(cost_prefix, 13, UITheme.COLOR_POSITIVE if can_afford else UITheme.COLOR_NEGATIVE)
	cost_row.add_child(cost_prefix)

	var coin := TextureRect.new()
	coin.texture = UITheme.get_coin_texture()
	coin.custom_minimum_size = Vector2(12, 12)
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cost_row.add_child(coin)

	var cost_amount := Label.new()
	cost_amount.text = str(region["cost"]) + "g"
	UITheme.apply_label_style(cost_amount, 13, UITheme.COLOR_POSITIVE if can_afford else UITheme.COLOR_NEGATIVE)
	cost_row.add_child(cost_amount)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 12)
	vbox.add_child(hbox)

	var yes_btn := Button.new()
	yes_btn.text = "Yes"
	yes_btn.custom_minimum_size = Vector2(60, 28)
	yes_btn.disabled = not can_afford
	UITheme.apply_button_theme(yes_btn, 14)
	yes_btn.pressed.connect(_on_yes)
	hbox.add_child(yes_btn)

	var no_btn := Button.new()
	no_btn.text = "No"
	no_btn.custom_minimum_size = Vector2(60, 28)
	UITheme.apply_button_theme(no_btn, 14)
	no_btn.pressed.connect(_on_no)
	hbox.add_child(no_btn)

	# Position at top center
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.0
	anchor_bottom = 0.0
	offset_left = -130
	offset_right = 130
	offset_top = 10
	offset_bottom = 110

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
