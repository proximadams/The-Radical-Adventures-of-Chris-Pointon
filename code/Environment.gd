extends Node2D

const BASE_MAX_SPEED             := 2.0
const RATE_INCREASE_PLAYER_SPEED := 0.1
const RATE_INCREASE_MAX_SPEED    := 0.003
const MIN_SPEED                  := 0.9
const REDUCE_SPEED_MULT          := 0.5

var maxSpeed: float = 2.0

onready var anim: AnimationPlayer = $AnimationPlayer

func _process(delta: float) -> void:
	anim.playback_speed = min(maxSpeed, anim.playback_speed + delta * RATE_INCREASE_PLAYER_SPEED)

func slow_down() -> void:
	anim.playback_speed = max(MIN_SPEED, anim.playback_speed * REDUCE_SPEED_MULT)

func increase_max_speed(points: int) -> void:
	maxSpeed += points * RATE_INCREASE_MAX_SPEED
