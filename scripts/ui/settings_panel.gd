class_name SettingsPanel
extends PanelContainer
## Shared settings UI panel used by both Main Menu and Pause Menu.
##
## Shows volume sliders (Master, Music, SFX) and fullscreen toggle.
## Reads/writes via /root/SettingsManager. Emits `closed` when Back is pressed.

signal closed

var _master_slider: HSlider
var _music_slider: HSlider
var _sfx_slider: HSlider
var _fullscreen_check: CheckButton
var _master_label: Label
var _music_label: Label
var _sfx_label: Label

func _ready() -> void:
	# Position centered on screen
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.5
	anchor_bottom = 0.5
	offset_left = -180
	offset_right = 180
	offset_top = -160
	offset_bottom = 160

	add_theme_stylebox_override("panel", UITheme.make_wood_panel_style())

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "Settings"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_label_style(title, UITheme.FONT_SIZE_TITLE, UITheme.COLOR_TITLE)
	vbox.add_child(title)

	# Separator
	var sep := ColorRect.new()
	sep.color = Color(0.55, 0.42, 0.25, 0.6)
	sep.custom_minimum_size = Vector2(0, 2)
	vbox.add_child(sep)

	var settings = get_node_or_null("/root/SettingsManager")

	# Master Volume
	var master_row := _make_slider_row("Master Volume", settings.master_volume if settings else 1.0)
	_master_slider = master_row["slider"]
	_master_label = master_row["value_label"]
	_master_slider.value_changed.connect(_on_master_changed)
	vbox.add_child(master_row["container"])

	# Music Volume
	var music_row := _make_slider_row("Music Volume", settings.music_volume if settings else 0.8)
	_music_slider = music_row["slider"]
	_music_label = music_row["value_label"]
	_music_slider.value_changed.connect(_on_music_changed)
	vbox.add_child(music_row["container"])

	# SFX Volume
	var sfx_row := _make_slider_row("SFX Volume", settings.sfx_volume if settings else 0.8)
	_sfx_slider = sfx_row["slider"]
	_sfx_label = sfx_row["value_label"]
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	vbox.add_child(sfx_row["container"])

	# Fullscreen toggle
	var fs_row := HBoxContainer.new()
	fs_row.add_theme_constant_override("separation", 10)
	vbox.add_child(fs_row)

	var fs_label := Label.new()
	fs_label.text = "Fullscreen"
	fs_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.apply_label_style(fs_label, UITheme.FONT_SIZE_MEDIUM, UITheme.COLOR_TEXT)
	fs_row.add_child(fs_label)

	_fullscreen_check = CheckButton.new()
	_fullscreen_check.button_pressed = settings.fullscreen if settings else false
	_fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	UITheme.apply_button_font(_fullscreen_check, UITheme.FONT_SIZE_SMALL)
	fs_row.add_child(_fullscreen_check)

	# Spacer
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Back button
	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(100, 32)
	UITheme.apply_button_theme(back_btn, UITheme.FONT_SIZE_MEDIUM)
	back_btn.pressed.connect(func(): closed.emit())
	vbox.add_child(back_btn)

func _make_slider_row(label_text: String, initial_value: float) -> Dictionary:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 2)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 8)
	container.add_child(top_row)

	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.apply_label_style(label, UITheme.FONT_SIZE_MEDIUM, UITheme.COLOR_TEXT)
	top_row.add_child(label)

	var value_label := Label.new()
	value_label.text = str(int(initial_value * 100)) + "%"
	value_label.custom_minimum_size = Vector2(40, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UITheme.apply_label_style(value_label, UITheme.FONT_SIZE_SMALL, UITheme.COLOR_GOLD)
	top_row.add_child(value_label)

	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.value = int(initial_value * 100)
	slider.custom_minimum_size = Vector2(0, 20)
	container.add_child(slider)

	return {"container": container, "slider": slider, "value_label": value_label}

func _on_master_changed(value: float) -> void:
	_master_label.text = str(int(value)) + "%"
	var settings = get_node_or_null("/root/SettingsManager")
	if settings:
		settings.set_master_volume(value / 100.0)

func _on_music_changed(value: float) -> void:
	_music_label.text = str(int(value)) + "%"
	var settings = get_node_or_null("/root/SettingsManager")
	if settings:
		settings.set_music_volume(value / 100.0)

func _on_sfx_changed(value: float) -> void:
	_sfx_label.text = str(int(value)) + "%"
	var settings = get_node_or_null("/root/SettingsManager")
	if settings:
		settings.set_sfx_volume(value / 100.0)
	SoundManager.play("click")

func _on_fullscreen_toggled(pressed: bool) -> void:
	var settings = get_node_or_null("/root/SettingsManager")
	if settings:
		settings.set_fullscreen(pressed)
