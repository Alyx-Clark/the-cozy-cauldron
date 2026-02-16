class_name RegionManager
extends Node
## Manages the 7 unlockable world regions that divide the 60x35 grid.
##
## The grid is partitioned into non-overlapping rectangular regions that together
## cover all 2100 cells (60*35). Region 0 ("Starter Workshop") is always unlocked.
## Other regions cost gold to unlock, providing a spatial progression system.
##
## REGION LAYOUT (grid coordinates, inclusive):
##   0 "Starter Workshop"  (0,0)->(14,11)     Free    15x12 = 180 cells
##   1 "East Wing"         (15,0)->(29,11)    500g    15x12 = 180 cells
##   2 "South Cellar"      (0,12)->(14,23)    750g    15x12 = 180 cells
##   3 "Grand Hall"        (15,12)->(29,23)  1000g    15x12 = 180 cells
##   4 "North Tower"       (0,24)->(29,34)   1500g    30x11 = 330 cells
##   5 "Enchanted Annex"   (30,0)->(59,17)   2000g    30x18 = 540 cells
##   6 "Master Laboratory" (30,18)->(59,34)  3000g    30x17 = 510 cells
##                                            Total:          2100 cells
##
## USAGE:
##   region_manager.is_unlocked(grid_pos)  -- check before placing machines
##   region_manager.unlock_region(id)      -- spend gold, emit signal
##   region_manager.get_region_at(pos)     -- get region dict or empty
##
## PERSISTENCE: get_save_data() / load_save_data() for save_manager.gd integration.

const CELL_SIZE := 64  # Duplicated from GridManager (load order safety)

## Each region: { id: int, name: String, rect: Rect2i(x, y, width, height), cost: int }
const REGIONS: Array = [
	{ "id": 0, "name": "Starter Workshop",  "rect": Rect2i(0,  0,  15, 12), "cost": 0 },
	{ "id": 1, "name": "East Wing",         "rect": Rect2i(15, 0,  15, 12), "cost": 500 },
	{ "id": 2, "name": "South Cellar",      "rect": Rect2i(0,  12, 15, 12), "cost": 750 },
	{ "id": 3, "name": "Grand Hall",        "rect": Rect2i(15, 12, 15, 12), "cost": 1000 },
	{ "id": 4, "name": "North Tower",       "rect": Rect2i(0,  24, 30, 11), "cost": 1500 },
	{ "id": 5, "name": "Enchanted Annex",   "rect": Rect2i(30, 0,  30, 18), "cost": 2000 },
	{ "id": 6, "name": "Master Laboratory", "rect": Rect2i(30, 18, 30, 17), "cost": 3000 },
]

## Array of unlocked region IDs. Region 0 is always present.
var unlocked_regions: Array = [0]

## Get the region dict containing a grid position, or empty dict if out of bounds.
func get_region_at(grid_pos: Vector2i) -> Dictionary:
	for region in REGIONS:
		var rect: Rect2i = region["rect"]
		if rect.has_point(grid_pos):
			return region
	return {}

## Check if the grid position is in an unlocked region.
func is_unlocked(grid_pos: Vector2i) -> bool:
	var region := get_region_at(grid_pos)
	if region.is_empty():
		return false
	return region["id"] in unlocked_regions

## Unlock a region by ID, spending gold via GameState. Returns true if successful.
## Emits GameState.region_unlocked signal on success.
func unlock_region(id: int) -> bool:
	if id in unlocked_regions:
		return false
	var region := get_region_by_id(id)
	if region.is_empty():
		return false
	if not GameState.spend_gold(region["cost"]):
		return false
	unlocked_regions.append(id)
	GameState.region_unlocked.emit(id)
	SoundManager.play("unlock")
	return true

## Get all regions that are currently locked.
func get_locked_regions() -> Array:
	var result: Array = []
	for region in REGIONS:
		if not (region["id"] in unlocked_regions):
			result.append(region)
	return result

## Get region dict by ID, or empty dict if not found.
func get_region_by_id(id: int) -> Dictionary:
	for region in REGIONS:
		if region["id"] == id:
			return region
	return {}

## Check if all 7 regions are unlocked (endgame condition).
func all_unlocked() -> bool:
	return unlocked_regions.size() >= REGIONS.size()

## Get save data (array of unlocked region IDs).
func get_save_data() -> Array:
	return unlocked_regions.duplicate()

## Load save data. Replaces current unlock state.
func load_save_data(data: Array) -> void:
	unlocked_regions = []
	for id in data:
		unlocked_regions.append(int(id))
