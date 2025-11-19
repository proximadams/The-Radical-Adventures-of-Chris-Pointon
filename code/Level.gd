extends Node2D

onready var environment : Node2D = $Environment
onready var score       : Control = $CanvasLayer/Score

func _ready():
	var _res = $Player.connect('environment_slow_down', $Environment, 'slow_down')
	_res = $Player.connect('show_new_points', self, '_increase_points')

func _increase_points(points: int) -> void:
	environment.increase_max_speed(points)
	score.show_new_points(points)
