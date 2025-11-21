extends Area2D

signal player_is_hurt
signal player_go_on_ramp
signal player_slow_down

func get_hurt() -> void:
	emit_signal('player_is_hurt')

func go_on_ramp() -> void:
	emit_signal('player_go_on_ramp')

func slow_down() -> void:
	emit_signal('player_slow_down')
