extends Area2D

signal player_is_hurt

func get_hurt():
	emit_signal('player_is_hurt')
