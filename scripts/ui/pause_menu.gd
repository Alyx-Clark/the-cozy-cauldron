extends CanvasLayer
## Pause menu overlay. ESC opens/closes (coordinated with UnlockShop).
##
## process_mode = PROCESS_MODE_ALWAYS so it runs while tree is paused.
## Pauses the tree, ducks music to 50%, shows Resume/Settings/Main Menu/Quit.

var _dimmer: ColorRect
var _panel: PanelContainer
var _settings_panel: Node = null
var _is_open: bool = false

# Reference to save_manager for save-on-exit. Set by main.gd.
var save_manager: Node = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10  # Above all other UI

	# Dimmer (full-screen semi-transparent black)
	_dimmer = ColorRect.new()
	_dimmer.color = Color(0, 0, 0, 0.6)
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
	_panel.offset_left = -140
	_panel.offset_right = 140
	_panel.offset_top = -140
	_panel.offset_bottom = 140
	_dimmer.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	_panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "Paused"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_label_style(title, UITheme.FONT_SIZE_TITLE, UITheme.COLOR_TITLE)
	vbox.add_child(title)

	# Separator
	var sep := ColorRect.new()
	sep.color = Color(0.55, 0.42, 0.25, 0.6)
	sep.custom_minimum_size = Vector2(0, 2)
	vbox.add_child(sep)

	# Buttons
	var resume_btn := _make_button("Resume")
	resume_btn.pressed.connect(_close)
	vbox.add_child(resume_btn)

	var settings_btn := _make_button("Settings")
	settings_btn.pressed.connect(_on_settings)
	vbox.add_child(settings_btn)

	var main_menu_btn := _make_button("Main Menu")
	main_menu_btn.pressed.connect(_on_main_menu)
	vbox.add_child(main_menu_btn)

	var quit_btn := _make_button("Quit")
	quit_btn.pressed.connect(_on_quit)
	vbox.add_child(quit_btn)

	_dimmer.visible = false

func _make_button(label_text: String) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(180, 36)
	UITheme.apply_button_theme(btn, UITheme.FONT_SIZE_LARGE)
	return btn

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if _settings_panel != null:
			# Close settings sub-panel first
			_settings_panel.queue_free()
			_settings_panel = null
			get_viewport().set_input_as_handled()
			return

		if _is_open:
			_close()
			get_viewport().set_input_as_handled()
			return

		# Don't open pause if UnlockShop is visible (let ESC propagate to it)
		var unlock_shop = get_node_or_null("/root/Main/UI/UnlockShop")
		if unlock_shop != null and unlock_shop.visible:
			return

		_open()
		get_viewport().set_input_as_handled()

func _open() -> void:
	_is_open = true
	_dimmer.visible = true
	get_tree().paused = true
	MusicManager.set_volume_multiplier(0.5)

func _close() -> void:
	if _settings_panel != null:
		_settings_panel.queue_free()
		_settings_panel = null
	_is_open = false
	_dimmer.visible = false
	get_tree().paused = false
	MusicManager.set_volume_multiplier(1.0)

func _on_settings() -> void:
	if _settings_panel != null:
		_settings_panel.queue_free()
		_settings_panel = null
		return

	var panel := SettingsPanel.new()
	panel.closed.connect(func():
		if _settings_panel != null:
			_settings_panel.queue_free()
			_settings_panel = null
	)
	_dimmer.add_child(panel)
	_settings_panel = panel

func _on_main_menu() -> void:
	# Save before leaving
	if save_manager != null:
		save_manager.save_game()
	_is_open = false
	get_tree().paused = false
	MusicManager.play_track("menu_theme")
	MusicManager.set_volume_multiplier(1.0)
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_quit() -> void:
	if save_manager != null:
		save_manager.save_game()
	get_tree().quit()
