class_name Recipes

# Recipe: a set of 2 ingredient types → result potion type
# Keys are sorted arrays of ItemTypes.Type values (as a string key for lookup)
# We use a helper to make lookup order-independent

const _RECIPE_LIST: Array = [
	# [ingredient_a, ingredient_b, result]
	[ItemTypes.Type.MUSHROOM, ItemTypes.Type.HERB, ItemTypes.Type.HEALTH_POTION],
	[ItemTypes.Type.CRYSTAL, ItemTypes.Type.WATER, ItemTypes.Type.MANA_POTION],
]

# Built at load time: Dictionary mapping "typeA,typeB" (sorted) → result type
static var _lookup: Dictionary = {}

static func _build_lookup() -> void:
	if not _lookup.is_empty():
		return
	for recipe in _RECIPE_LIST:
		var key := _make_key(recipe[0], recipe[1])
		_lookup[key] = recipe[2]

static func _make_key(a: int, b: int) -> String:
	if a > b:
		var tmp := a
		a = b
		b = tmp
	return "%d,%d" % [a, b]

## Returns the result potion type, or ItemTypes.Type.NONE if no recipe matches.
static func check(ingredient_a: int, ingredient_b: int) -> int:
	_build_lookup()
	var key := _make_key(ingredient_a, ingredient_b)
	return _lookup.get(key, ItemTypes.Type.NONE)
