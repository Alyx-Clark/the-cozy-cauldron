extends HBoxContainer

var _label: Label
var _previous_gold: int = 0
var _default_color := Color(1.0, 0.9, 0.6)

func _ready() -> void:
	# Position in top-right
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 0.0
	offset_left = -160
	offset_right = -16
	offset_top = 12
	offset_bottom = 44

	# Coin icon (drawn as a colored label)
	var coin := Label.new()
	coin.text = "●"
	coin.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	coin.add_theme_font_size_override("font_size", 22)
	add_child(coin)

	# Gold amount label
	_label = Label.new()
	_label.text = "0g"
	_label.add_theme_color_override("font_color", _default_color)
	_label.add_theme_font_size_override("font_size", 20)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_label)

	add_theme_constant_override("separation", 6)

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
	var flash_color := Color(0.3, 1.0, 0.3) if gained else Color(1.0, 0.35, 0.3)
	_label.add_theme_color_override("font_color", flash_color)
	var color_tween := create_tween()
	color_tween.tween_interval(0.12)
	color_tween.tween_callback(_label.add_theme_color_override.bind("font_color", _default_color))
