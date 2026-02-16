class_name GridManager
extends Node2D
## 20×11 grid (64px cells → 1280×704 px). Dictionary-based storage mapping
## Vector2i grid coordinates to machine Node2D references.
##
## Coordinate system:
##   Grid (0,0) = top-left cell → world position (32, 32) (cell center)
##   Grid (19,10) = bottom-right cell → world position (1248, 672)
##   Conversion: world_pos = grid_pos * 64 + 32

const CELL_SIZE := 64
const GRID_WIDTH := 20
const GRID_HEIGHT := 11

var _grid: Dictionary = {}  # Vector2i → Node2D (machine) or absent (empty cell)

## Convert grid coordinates to world pixel position (center of cell).
func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * CELL_SIZE + CELL_SIZE / 2.0, grid_pos.y * CELL_SIZE + CELL_SIZE / 2.0)

## Convert world pixel position to grid coordinates.
func world_to_grid(world_pos: Vector2) -> Vector2i:
	@warning_ignore("integer_division")
	return Vector2i(int(world_pos.x) / CELL_SIZE, int(world_pos.y) / CELL_SIZE)

## Check if grid coordinates are within bounds.
func is_in_bounds(grid_pos: Vector2i) -> bool:
	return grid_pos.x >= 0 and grid_pos.x < GRID_WIDTH and grid_pos.y >= 0 and grid_pos.y < GRID_HEIGHT

## Check if a cell is empty.
func is_cell_empty(grid_pos: Vector2i) -> bool:
	return not _grid.has(grid_pos)

## Place a machine at grid coordinates. Returns true if successful.
func place_machine(grid_pos: Vector2i, machine: Node2D) -> bool:
	if not is_in_bounds(grid_pos) or not is_cell_empty(grid_pos):
		return false
	_grid[grid_pos] = machine
	machine.position = grid_to_world(grid_pos)
	return true

## Remove the machine at grid coordinates. Returns the removed machine or null.
func remove_machine(grid_pos: Vector2i) -> Node2D:
	if not _grid.has(grid_pos):
		return null
	var machine: Node2D = _grid[grid_pos]
	_grid.erase(grid_pos)
	return machine

## Get the machine at grid coordinates, or null.
func get_machine_at(grid_pos: Vector2i) -> Node2D:
	return _grid.get(grid_pos, null)

## Get the neighbor machine in a given direction from grid_pos.
func get_neighbor(grid_pos: Vector2i, direction: Vector2i) -> Node2D:
	return get_machine_at(grid_pos + direction)

## Get all placed machines.
func get_all_machines() -> Array:
	return _grid.values()
