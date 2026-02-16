class_name TutorialManager
extends Node

# Lightweight contextual hint system. Shows one hint at a time.

# Hint definitions: [id, text, trigger description]
const HINTS: Array = [
	["select_dispenser", "Select a Dispenser from the toolbar, then click the grid to place it."],
	["rotate_hint", "Press R to rotate. The arrow shows the output direction."],
	["place_belts", "Place Conveyor Belts to move items along."],
	["place_cauldron", "Place a Cauldron to combine ingredients into a potion."],
	["cycle_dispenser", "Click a Dispenser (no tool selected) to change its ingredient."],
	["hand_sell", "Click a potion on a machine to hand-sell it for gold."],
	["open_shop", "Press U to open the Unlock Shop."],
]

var hints_seen: Array = []
var _current_hint: PanelContainer = null
var _ui_layer: Node = null

# Track game events for triggering hints
var _machines_placed: int = 0
var _has_brewed: bool = false
var _has_earned_gold: bool = false

func setup(ui_layer: Node) -> void:
	_ui_layer = ui_layer
	# Connect to game signals
	GameState.gold_changed.connect(_on_gold_changed)
	GameState.potion_brewed.connect(_on_potion_brewed)

func _on_gold_changed(amount: int) -> void:
	if amount > 0 and not _has_earned_gold:
		_has_earned_gold = true
		_try_show("open_shop")

func _on_potion_brewed(_potion_type: int) -> void:
	on_potion_brewed()
	on_potion_available()

## Called by game_world after placing a machine.
func on_machine_placed(machine_type: String) -> void:
	_machines_placed += 1

	if _machines_placed == 1:
		_try_show("rotate_hint")
	elif machine_type == "dispenser" and _machines_placed >= 1:
		_try_show("place_belts")
	elif _machines_placed >= 3:
		_try_show("place_cauldron")

## Called when a potion is brewed for the first time.
func on_potion_brewed() -> void:
	if not _has_brewed:
		_has_brewed = true
		_try_show("cycle_dispenser")

## Called after the first cauldron is placed.
func on_cauldron_placed() -> void:
	_try_show("cycle_dispenser")

## Called after a potion exists on a machine (for hand-sell hint).
func on_potion_available() -> void:
	_try_show("hand_sell")

## Show the initial hint on fresh start.
func show_initial_hint() -> void:
	_try_show("select_dispenser")

func _try_show(hint_id: String) -> void:
	if hint_id in hints_seen:
		return
	if _current_hint != null:
		return  # Don't stack hints

	# Find the hint text
	var hint_text := ""
	for h in HINTS:
		if h[0] == hint_id:
			hint_text = h[1]
			break
	if hint_text == "":
		return

	hints_seen.append(hint_id)
	_show_hint_panel(hint_text)

func _show_hint_panel(text: String) -> void:
	if _ui_layer == null:
		return

	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_left = -220
	panel.offset_right = 220
	panel.offset_top = 60
	panel.offset_bottom = 110

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.12, 0.92)
	style.border_color = Color(0.5, 0.4, 0.7, 0.6)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	label.add_theme_font_size_override("font_size", 14)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(label)

	var dismiss := Label.new()
	dismiss.text = "(click anywhere to dismiss)"
	dismiss.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5, 0.6))
	dismiss.add_theme_font_size_override("font_size", 11)
	dismiss.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(dismiss)

	# Fade in
	panel.modulate.a = 0.0
	_ui_layer.add_child(panel)
	_current_hint = panel

	var tween := panel.create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.3)

func _unhandled_input(event: InputEvent) -> void:
	if _current_hint != null and event is InputEventMouseButton and event.pressed:
		_dismiss_hint()

func _dismiss_hint() -> void:
	if _current_hint == null:
		return
	var panel := _current_hint
	_current_hint = null
	var tween := panel.create_tween()
	tween.tween_property(panel, "modulate:a", 0.0, 0.2)
	tween.tween_callback(panel.queue_free)

## Get tutorial state for saving.
func get_save_data() -> Array:
	return hints_seen.duplicate()

## Restore tutorial state from save data.
func load_save_data(data: Array) -> void:
	hints_seen = data.duplicate()
