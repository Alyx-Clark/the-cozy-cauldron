class_name RegionOverlay
extends Node2D
## Draws visual overlays for the region system on the game world.
##
## LOCKED REGIONS: Semi-transparent dark rectangles with region name + cost labels.
## ALL REGIONS: Dashed border lines (thicker/brighter for locked, subtle for unlocked).
##
## Redraws every frame via _process() because the camera moves and we want the
## overlay to always be visible. Also redraws immediately when a region is unlocked
## (via GameState.region_unlocked signal).
##
## This node is added to GameWorld at z_index=0 (same layer as GridOverlay),
## inserted after GridOverlay so it draws on top of the grid dots but below machines.

const CELL_SIZE := 64  # Duplicated from GridManager (load order safety)

## Set by main.gd during initialization.
var region_manager: RegionManager = null

func _ready() -> void:
	GameState.region_unlocked.connect(_on_region_unlocked)

func _on_region_unlocked(_id: int) -> void:
	queue_redraw()

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if region_manager == null:
		return

	for region in region_manager.REGIONS:
		var rid: int = region["id"]
		var rect: Rect2i = region["rect"]
		# Convert grid rect to world pixel rect
		var world_rect := Rect2(
			Vector2(rect.position) * CELL_SIZE,
			Vector2(rect.size) * CELL_SIZE,
		)

		if not (rid in region_manager.unlocked_regions):
			# Dark overlay on locked regions
			draw_rect(world_rect, Color(0.0, 0.0, 0.0, 0.55))
			# Region name + cost label centered in the region
			_draw_region_label(world_rect, region["name"], region["cost"])

		# Dashed border for all regions (subtle for unlocked, bold for locked)
		_draw_dashed_rect(world_rect, rid in region_manager.unlocked_regions)

## Draw a dashed rectangle border. Unlocked regions get subtle lines, locked get bold.
func _draw_dashed_rect(rect: Rect2, unlocked: bool) -> void:
	var color := Color(0.5, 0.4, 0.3, 0.3) if unlocked else Color(0.7, 0.5, 0.2, 0.5)
	var width := 1.0 if unlocked else 2.0
	var dash_len := 8.0
	var gap_len := 6.0

	# Four edges: top, bottom, left, right
	_draw_dashed_line(rect.position, rect.position + Vector2(rect.size.x, 0), color, width, dash_len, gap_len)
	_draw_dashed_line(rect.position + Vector2(0, rect.size.y), rect.position + rect.size, color, width, dash_len, gap_len)
	_draw_dashed_line(rect.position, rect.position + Vector2(0, rect.size.y), color, width, dash_len, gap_len)
	_draw_dashed_line(rect.position + Vector2(rect.size.x, 0), rect.position + rect.size, color, width, dash_len, gap_len)

## Draw a single dashed line between two points.
func _draw_dashed_line(from: Vector2, to: Vector2, color: Color, width: float, dash: float, gap: float) -> void:
	var length := from.distance_to(to)
	var dir := (to - from).normalized()
	var pos := 0.0
	while pos < length:
		var end_pos := minf(pos + dash, length)
		draw_line(from + dir * pos, from + dir * end_pos, color, width)
		pos = end_pos + gap

## Draw region name and cost label centered in the world rect.
func _draw_region_label(rect: Rect2, region_name: String, cost: int) -> void:
	var center := rect.get_center()
	var font: Font = UITheme.get_font()
	draw_string(
		font,
		center + Vector2(-60, -6),
		region_name,
		HORIZONTAL_ALIGNMENT_CENTER,
		120,
		16,
		Color(0.93, 0.85, 0.6, 0.75),
	)
	draw_string(
		font,
		center + Vector2(-30, 16),
		str(cost) + "g",
		HORIZONTAL_ALIGNMENT_CENTER,
		60,
		14,
		Color(1.0, 0.9, 0.3, 0.65),
	)
