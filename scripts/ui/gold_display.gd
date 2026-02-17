extends PanelContainer
## Top-right HUD showing gold coin icon + amount. Animates on change:
## scale bounces 1.0->1.2->1.0 and text flashes green (gain) or red (spend).

var _label: Label
var _previous_gold: int = 0

func _ready() -> void:
	# Position in top-right
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 0.0
	offset_left = -160
	offset_right = -12
	offset_top = 8
	offset_bottom = 42

	# Wood panel background
	add_theme_stylebox_override("panel", UITheme.make_wood_panel_style())

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(hbox)

	# Coin icon sprite
	var coin_icon := TextureRect.new()
	coin_icon.texture = UITheme.get_coin_texture()
	coin_icon.custom_minimum_size = Vector2(16, 16)
	coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox.add_child(coin_icon)

	# Gold amount label
	_label = Label.new()
	_label.text = "0g"
	UITheme.apply_label_style(_label, UITheme.FONT_SIZE_LARGE, UITheme.COLOR_GOLD)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(_label)

	_previous_gold = GameState.gold
	GameState.gold_changed.connect(_on_gold_changed)
	_on_gold_changed(GameState.gold)

func _on_gold_changed(new_amount: int) -> void:
	_label.text = str(new_amount) + "g"

	# Determine gain vs spend
	var gained: bool = new_amount > _previous_gold
	_previous_gold = new_amount

	# Scale bounce
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.08).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15).set_ease(Tween.EASE_IN)

	# Color flash
	var flash_color := UITheme.COLOR_POSITIVE if gained else UITheme.COLOR_NEGATIVE
	_label.add_theme_color_override("font_color", flash_color)
	var color_tween := create_tween()
	color_tween.tween_interval(0.12)
	color_tween.tween_callback(_label.add_theme_color_override.bind("font_color", UITheme.COLOR_GOLD))
