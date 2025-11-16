extends Node2D

onready var player = get_tree().get_root().find_node('Player', true, false)

export var offsetY := 50.0

func _process(_delta: float) -> void:
	if player.global_position.y < global_position.y + offsetY:
		z_index = 3
	else:
		z_index = 0
