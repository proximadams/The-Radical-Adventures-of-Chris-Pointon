extends Node

var rng

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	rng = RandomNumberGenerator.new()
	rng.randomize()

func _input(event: InputEvent):
	if event is InputEventMouseMotion:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif event is InputEventJoypadMotion:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
