extends Node2D

@onready var game_world: Node2D = $GameWorld
@onready var toolbar: PanelContainer = $UI/Toolbar

func _ready() -> void:
	toolbar.machine_selected.connect(game_world.select_machine)
