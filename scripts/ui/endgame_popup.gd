class_name EndgamePopup
extends CanvasLayer
## Congratulations popup shown when all recipes, machines, and regions are unlocked.
##
## Static API: EndgamePopup.show_popup(parent)
## Shown once per save (guarded by GameState.endgame_shown).

static func show_popup(parent: Node) -> void:
	var popup := EndgamePopup.new()
	parent.add_child(popup)

var _dimmer: ColorRect
var _panel: PanelContainer

func _ready() -> void:
	layer = 11  # Above pause menu

	# Dimmer
	_dimmer = ColorRect.new()
	_dimmer.color = Color(0, 0, 0, 0.5)
	_dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dimmer)

	# Center panel
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UITheme.make_wood_panel_style())
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -180
	_panel.offset_right = 180
	_panel.offset_top = -130
	_panel.offset_bottom = 130
	_dimmer.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	_panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "Congratulations!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_label_style(title, UITheme.FONT_SIZE_TITLE, UITheme.COLOR_TITLE)
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	title.add_theme_color_override("font_shadow_color", Color(0.1, 0.08, 0.05, 0.7))
	vbox.add_child(title)

	# Separator
	var sep := ColorRect.new()
	sep.color = Color(0.9, 0.78, 0.15, 0.6)
	sep.custom_minimum_size = Vector2(0, 2)
	vbox.add_child(sep)

	# Stats
	var stats_text := "All 10 recipes unlocked!\nAll 9 machines unlocked!\nAll 7 regions unlocked!"
	var stats := Label.new()
	stats.text = stats_text
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_label_style(stats, UITheme.FONT_SIZE_MEDIUM, UITheme.COLOR_TEXT)
	vbox.add_child(stats)

	# Gold display
	var gold_row := HBoxContainer.new()
	gold_row.alignment = BoxContainer.ALIGNMENT_CENTER
	gold_row.add_theme_constant_override("separation", 6)
	vbox.add_child(gold_row)

	var coin_icon := TextureRect.new()
	coin_icon.texture = UITheme.get_coin_texture()
	coin_icon.custom_minimum_size = Vector2(16, 16)
	coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gold_row.add_child(coin_icon)

	var gold_label := Label.new()
	gold_label.text = str(GameState.gold) + "g earned"
	UITheme.apply_label_style(gold_label, UITheme.FONT_SIZE_LARGE, UITheme.COLOR_GOLD)
	gold_row.add_child(gold_label)

	# Continue button
	var btn := Button.new()
	btn.text = "Continue Playing"
	btn.custom_minimum_size = Vector2(180, 36)
	UITheme.apply_button_theme(btn, UITheme.FONT_SIZE_LARGE)
	btn.pressed.connect(_on_continue)
	vbox.add_child(btn)

	# Entrance animation: scale + fade
	_panel.scale = Vector2(0.8, 0.8)
	_panel.modulate.a = 0.0
	_dimmer.modulate.a = 0.0

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_dimmer, "modulate:a", 1.0, 0.3)
	tween.tween_property(_panel, "modulate:a", 1.0, 0.5)
	tween.tween_property(_panel, "scale", Vector2(1.0, 1.0), 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	SoundManager.play("order_complete")

func _on_continue() -> void:
	var tween := create_tween()
	tween.tween_property(_dimmer, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)
