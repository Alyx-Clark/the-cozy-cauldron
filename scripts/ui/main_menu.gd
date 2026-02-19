extends Control
## Main menu scene script. Title screen with New Game, Continue, Settings, Quit.
##
## Built entirely in _ready() (code-first pattern). Plays menu music.
## Scene transitions use a black ColorRect fade overlay.

var _fade_rect: ColorRect
var _continue_btn: Button
var _settings_panel: Node = null

func _ready() -> void:
	# Full-screen dark warm background
	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.1, 0.08, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Center container for all menu content
	var center := VBoxContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	center.offset_left = -200
	center.offset_right = 200
	center.offset_top = -220
	center.offset_bottom = 220
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 12)
	add_child(center)

	# Spacer to push title down a bit
	var spacer_top := Control.new()
	spacer_top.custom_minimum_size = Vector2(0, 30)
	center.add_child(spacer_top)

	# Title
	var title := Label.new()
	title.text = "The Cozy Cauldron"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_label_style(title, 36, UITheme.COLOR_TITLE)
	# Drop shadow
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	title.add_theme_color_override("font_shadow_color", Color(0.1, 0.08, 0.05, 0.7))
	center.add_child(title)

	# Subtitle
	var subtitle := Label.new()
	subtitle.text = "A Cozy Potion Automation Game"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_label_style(subtitle, UITheme.FONT_SIZE_MEDIUM, UITheme.COLOR_TEXT_DIM)
	center.add_child(subtitle)

	# Spacer between subtitle and buttons
	var spacer_mid := Control.new()
	spacer_mid.custom_minimum_size = Vector2(0, 30)
	center.add_child(spacer_mid)

	# Buttons
	var has_save: bool = FileAccess.file_exists("user://savegame.json")

	_continue_btn = _make_button("Continue")
	_continue_btn.disabled = not has_save
	_continue_btn.pressed.connect(_on_continue)
	center.add_child(_continue_btn)

	var new_game_btn := _make_button("New Game")
	new_game_btn.pressed.connect(_on_new_game.bind(has_save))
	center.add_child(new_game_btn)

	var settings_btn := _make_button("Settings")
	settings_btn.pressed.connect(_on_settings)
	center.add_child(settings_btn)

	var quit_btn := _make_button("Quit")
	quit_btn.pressed.connect(_on_quit)
	center.add_child(quit_btn)

	# Fade overlay (starts transparent — we fade TO black for transitions)
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0, 0, 0, 0)
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade_rect)

	# Music
	MusicManager.play_track("menu_theme")

func _make_button(label_text: String) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(200, 40)
	UITheme.apply_button_theme(btn, UITheme.FONT_SIZE_LARGE)
	return btn

func _on_continue() -> void:
	_transition_to_game()

func _on_new_game(has_save: bool) -> void:
	if has_save:
		_show_confirm_dialog()
	else:
		GameState.reset()
		_transition_to_game()

func _on_settings() -> void:
	if _settings_panel != null:
		_settings_panel.queue_free()
		_settings_panel = null
		return

	var panel := preload("res://scripts/ui/settings_panel.gd").new()
	panel.closed.connect(_on_settings_closed)
	add_child(panel)
	# Move fade rect to top so it's always above settings
	move_child(_fade_rect, get_child_count() - 1)
	_settings_panel = panel

func _on_settings_closed() -> void:
	if _settings_panel != null:
		_settings_panel.queue_free()
		_settings_panel = null

func _on_quit() -> void:
	get_tree().quit()

func _show_confirm_dialog() -> void:
	# Simple confirmation overlay
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.make_wood_panel_style())
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -160
	panel.offset_right = 160
	panel.offset_top = -80
	panel.offset_bottom = 80
	overlay.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var msg := Label.new()
	msg.text = "Delete existing save\nand start fresh?"
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_label_style(msg, UITheme.FONT_SIZE_MEDIUM, UITheme.COLOR_TEXT)
	vbox.add_child(msg)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	vbox.add_child(btn_row)

	var yes_btn := Button.new()
	yes_btn.text = "Yes"
	yes_btn.custom_minimum_size = Vector2(80, 32)
	UITheme.apply_button_theme(yes_btn, UITheme.FONT_SIZE_MEDIUM)
	yes_btn.pressed.connect(func():
		# Delete save and start new game
		DirAccess.remove_absolute("user://savegame.json")
		GameState.reset()
		overlay.queue_free()
		_transition_to_game()
	)
	btn_row.add_child(yes_btn)

	var no_btn := Button.new()
	no_btn.text = "No"
	no_btn.custom_minimum_size = Vector2(80, 32)
	UITheme.apply_button_theme(no_btn, UITheme.FONT_SIZE_MEDIUM)
	no_btn.pressed.connect(func():
		overlay.queue_free()
	)
	btn_row.add_child(no_btn)

func _transition_to_game() -> void:
	# Disable buttons during transition
	for child in get_children():
		if child is Button:
			child.disabled = true

	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(_fade_rect, "color:a", 1.0, 0.5)
	tween.tween_callback(_load_game_scene)

func _load_game_scene() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
