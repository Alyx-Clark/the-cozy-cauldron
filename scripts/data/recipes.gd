class_name Recipes

# Recipe: a set of 2 ingredient types → result potion type
# Keys are sorted arrays of ItemTypes.Type values (as a string key for lookup)
# We use a helper to make lookup order-independent

const RECIPE_LIST: Array = [
	# [ingredient_a, ingredient_b, result]
	[ItemTypes.Type.MUSHROOM, ItemTypes.Type.HERB, ItemTypes.Type.HEALTH_POTION],
	[ItemTypes.Type.CRYSTAL, ItemTypes.Type.WATER, ItemTypes.Type.MANA_POTION],
	[ItemTypes.Type.FEATHER, ItemTypes.Type.LIGHTNING, ItemTypes.Type.SPEED_POTION],
	[ItemTypes.Type.ROSE, ItemTypes.Type.HEART, ItemTypes.Type.LOVE_POTION],
	[ItemTypes.Type.SHADOW, ItemTypes.Type.MOONLIGHT, ItemTypes.Type.INVISIBILITY_POTION],
	[ItemTypes.Type.ICE, ItemTypes.Type.LAVA, ItemTypes.Type.FIRE_RESISTANCE_POTION],
	[ItemTypes.Type.DRAGON_SCALE, ItemTypes.Type.EMBER, ItemTypes.Type.STRENGTH_POTION],
	[ItemTypes.Type.GLOWSHROOM, ItemTypes.Type.EYE, ItemTypes.Type.NIGHT_VISION_POTION],
	[ItemTypes.Type.SEAWEED, ItemTypes.Type.BUBBLE, ItemTypes.Type.WATER_BREATHING_POTION],
	[ItemTypes.Type.CLOVER, ItemTypes.Type.STAR, ItemTypes.Type.LUCKY_POTION],
]

# Which recipe indices are unlocked (starts with first 2)
static var unlocked_indices: Array = [0, 1]

# Built at load time: Dictionary mapping "typeA,typeB" (sorted) → [recipe_index, result_type]
static var _lookup: Dictionary = {}

static func _build_lookup() -> void:
	if not _lookup.is_empty():
		return
	for i in range(RECIPE_LIST.size()):
		var recipe: Array = RECIPE_LIST[i]
		var key := _make_key(recipe[0], recipe[1])
		_lookup[key] = [i, recipe[2]]

static func _make_key(a: int, b: int) -> String:
	if a > b:
		var tmp := a
		a = b
		b = tmp
	return "%d,%d" % [a, b]

## Returns the result potion type, or ItemTypes.Type.NONE if no recipe matches or recipe is locked.
static func check(ingredient_a: int, ingredient_b: int) -> int:
	_build_lookup()
	var key := _make_key(ingredient_a, ingredient_b)
	var entry: Array = _lookup.get(key, [])
	if entry.is_empty():
		return ItemTypes.Type.NONE
	# Check if this recipe is unlocked
	if not (entry[0] in unlocked_indices):
		return ItemTypes.Type.NONE
	return entry[1]

## Get ingredients used by a specific recipe index.
static func get_recipe_ingredients(index: int) -> Array:
	if index < 0 or index >= RECIPE_LIST.size():
		return []
	return [RECIPE_LIST[index][0], RECIPE_LIST[index][1]]

## Get the result potion type for a recipe index.
static func get_recipe_result(index: int) -> int:
	if index < 0 or index >= RECIPE_LIST.size():
		return ItemTypes.Type.NONE
	return RECIPE_LIST[index][2]

## Rebuild lookup (call after modifying unlocked_indices externally).
static func rebuild() -> void:
	_lookup.clear()
	_build_lookup()
