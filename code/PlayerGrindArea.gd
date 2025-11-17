extends Area2D

signal player_try_start_grind(positionY)
signal player_try_end_grind

func try_start_grind(positionY: float):
	emit_signal('player_try_start_grind', positionY)

func try_end_grind() -> void:
	emit_signal('player_try_end_grind')
