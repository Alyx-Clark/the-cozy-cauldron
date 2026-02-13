class_name ItemTypes

# Item type enum
enum Type {
	NONE = 0,
	# Ingredients
	MUSHROOM,
	HERB,
	CRYSTAL,
	WATER,
	# Potions
	HEALTH_POTION,
	MANA_POTION,
}

# Display colors for each item type (used by _draw)
const COLORS: Dictionary = {
	Type.MUSHROOM: Color(0.72, 0.28, 0.28),       # Red-brown
	Type.HERB: Color(0.35, 0.75, 0.35),            # Green
	Type.CRYSTAL: Color(0.55, 0.55, 0.95),         # Light blue
	Type.WATER: Color(0.25, 0.55, 0.85),           # Blue
	Type.HEALTH_POTION: Color(1.0, 0.2, 0.3),      # Bright red
	Type.MANA_POTION: Color(0.3, 0.2, 1.0),        # Bright blue
}

# Display names
const NAMES: Dictionary = {
	Type.NONE: "None",
	Type.MUSHROOM: "Mushroom",
	Type.HERB: "Herb",
	Type.CRYSTAL: "Crystal",
	Type.WATER: "Water",
	Type.HEALTH_POTION: "Health Potion",
	Type.MANA_POTION: "Mana Potion",
}

# Which items are ingredients (can be dispensed)
const INGREDIENTS: Array = [
	Type.MUSHROOM,
	Type.HERB,
	Type.CRYSTAL,
	Type.WATER,
]

# Whether an item type is a potion
static func is_potion(type: Type) -> bool:
	return type >= Type.HEALTH_POTION
