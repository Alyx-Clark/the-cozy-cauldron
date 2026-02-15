extends HBoxContainer

var _label: Label

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
	_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
	_label.add_theme_font_size_override("font_size", 20)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_label)

	add_theme_constant_override("separation", 6)

	GameState.gold_changed.connect(_on_gold_changed)
	_on_gold_changed(GameState.gold)

func _on_gold_changed(new_amount: int) -> void:
	_label.text = str(new_amount) + "g"
