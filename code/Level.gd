extends Node2D

func _ready():
	var _res = $Player.connect('environment_slow_down', $Environment, 'slow_down')
