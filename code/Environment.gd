extends Node2D

const INCREASE_SPEED    := 0.1
const MAX_SPEED         := 10.0# TODO should speed up by doing tricks
const MIN_SPEED         := 0.9
const REDUCE_SPEED_MULT := 0.75

onready var anim: AnimationPlayer = $AnimationPlayer

func _process(delta: float) -> void:
	anim.playback_speed = min(MAX_SPEED, anim.playback_speed + delta * INCREASE_SPEED)

func slow_down() -> void:
	anim.playback_speed = max(MIN_SPEED, anim.playback_speed * REDUCE_SPEED_MULT)
