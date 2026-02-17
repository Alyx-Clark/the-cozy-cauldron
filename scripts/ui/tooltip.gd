class_name Tooltip
extends PanelContainer
## Single tooltip instance attached to UI CanvasLayer.
## Shows title, description, and optional info on hover.
##
## Static API:
##   Tooltip.setup(ui_layer) — create and attach to CanvasLayer
##   Tooltip.show_at(title, desc, info, global_pos) — show near cursor
##   Tooltip.hide_tip() — hide immediately

static var _instance: Tooltip = null

static func setup(ui_layer: Node) -> void:
	_instance = Tooltip.new()
	_instance.visible = false
	_instance.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(_instance)

static func show_at(title_text: String, desc: String, info: String, global_pos: Vector2) -> void:
	if _instance == null:
		return
	_instance._show(title_text, desc, info, global_pos)

static func hide_tip() -> void:
	if _instance == null:
		return
	_instance.visible = false

# ── Instance ─────────────────────────────────────────────────────────────────

var _title_label: Label
var _desc_label: Label
var _info_label: Label
var _vbox: VBoxContainer

func _ready() -> void:
	# Dark panel background
	add_theme_stylebox_override("panel", UITheme.make_dark_panel_style())

	_vbox = VBoxContainer.new()
	_vbox.add_theme_constant_override("separation", 2)
	_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_vbox)

	_title_label = Label.new()
	UITheme.apply_label_style(_title_label, UITheme.FONT_SIZE_MEDIUM, UITheme.COLOR_TITLE)
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vbox.add_child(_title_label)

	_desc_label = Label.new()
	UITheme.apply_label_style(_desc_label, UITheme.FONT_SIZE_SMALL, UITheme.COLOR_TEXT)
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.custom_minimum_size = Vector2(140, 0)
	_desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vbox.add_child(_desc_label)

	_info_label = Label.new()
	UITheme.apply_label_style(_info_label, UITheme.FONT_SIZE_SMALL, UITheme.COLOR_GOLD)
	_info_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vbox.add_child(_info_label)

	# Ensure tooltip doesn't eat clicks
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Keep on top
	z_index = 100

func _show(title_text: String, desc: String, info: String, pos: Vector2) -> void:
	_title_label.text = title_text
	_desc_label.text = desc
	_desc_label.visible = desc != ""
	_info_label.text = info
	_info_label.visible = info != ""

	visible = true

	# Position near cursor, offset slightly, clamped to viewport
	var vp_size := Vector2(1280, 720)
	var tip_size := get_combined_minimum_size()
	var x := pos.x + 16
	var y := pos.y + 8
	if x + tip_size.x > vp_size.x:
		x = pos.x - tip_size.x - 8
	if y + tip_size.y > vp_size.y:
		y = vp_size.y - tip_size.y - 4
	position = Vector2(x, y)
