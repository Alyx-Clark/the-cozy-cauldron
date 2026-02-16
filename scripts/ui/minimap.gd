extends PanelContainer
## Corner minimap showing the full 60x35 world at reduced scale.
##
## Toggle visibility with M key. Positioned top-right, below the gold display.
## Uses a child Control node with a custom _draw() signal connection for rendering.
##
## VISUAL ELEMENTS:
##   Locked regions  — dark overlay rectangles
##   Region borders  — subtle brown outlines for all regions
##   Machines        — small green squares at grid positions
##   Player          — white dot at player's world position (scaled)
##   Camera rect     — faint white outline showing the current viewport
##
## SCALE: 4px per grid cell → 240x140 pixel display for the 60x35 grid.
##
## References (set by main.gd): grid_manager, region_manager, player.

const GRID_WIDTH := 60
const GRID_HEIGHT := 35
const SCALE := 4.0  # Pixels per grid cell on minimap
const MAP_W := GRID_WIDTH * SCALE   # 240
const MAP_H := GRID_HEIGHT * SCALE  # 140

var grid_manager: GridManager = null
var region_manager: RegionManager = null
var player: Player = null

var _draw_node: Control = null

func _ready() -> void:
	name = "Minimap"
	visible = false

	# Position top-right, below gold display
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 0.0
	offset_left = -MAP_W - 18
	offset_right = -8
	offset_top = 40
	offset_bottom = 40 + MAP_H + 12

	# Panel style
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.1, 0.85)
	style.border_color = Color(0.5, 0.4, 0.3, 0.6)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	add_theme_stylebox_override("panel", style)

	# Custom draw control inside the panel
	_draw_node = Control.new()
	_draw_node.custom_minimum_size = Vector2(MAP_W, MAP_H)
	_draw_node.draw.connect(_on_draw)
	add_child(_draw_node)

func _process(_delta: float) -> void:
	if visible and _draw_node != null:
		_draw_node.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_M:
			visible = not visible
			get_viewport().set_input_as_handled()

func _on_draw() -> void:
	if grid_manager == null:
		return

	# Draw locked region overlays
	if region_manager != null:
		for region in region_manager.REGIONS:
			var rect: Rect2i = region["rect"]
			var region_rect := Rect2(
				Vector2(rect.position) * SCALE,
				Vector2(rect.size) * SCALE,
			)
			if not (region["id"] in region_manager.unlocked_regions):
				_draw_node.draw_rect(region_rect, Color(0.0, 0.0, 0.0, 0.5))
			# Region border
			_draw_node.draw_rect(region_rect, Color(0.6, 0.5, 0.3, 0.4), false, 1.0)

	# Draw machines as dots
	for machine in grid_manager.get_all_machines():
		if machine is MachineBase:
			var pos := Vector2(machine.grid_pos) * SCALE + Vector2(SCALE / 2, SCALE / 2)
			_draw_node.draw_rect(Rect2(pos - Vector2(1.5, 1.5), Vector2(3, 3)), Color(0.4, 0.7, 0.5, 0.8))

	# Draw player dot
	if player != null:
		var ppos := player.position / 64.0 * SCALE
		_draw_node.draw_circle(ppos, 3.0, Color(1.0, 1.0, 1.0, 0.9))

	# Draw camera viewport rect
	if player != null:
		var vp_size := get_viewport_rect().size
		var cam_center := player.position
		var cam_tl := (cam_center - vp_size / 2.0) / 64.0 * SCALE
		var cam_size := vp_size / 64.0 * SCALE
		var cam_rect := Rect2(cam_tl, cam_size)
		_draw_node.draw_rect(cam_rect, Color(1.0, 1.0, 1.0, 0.25), false, 1.0)
