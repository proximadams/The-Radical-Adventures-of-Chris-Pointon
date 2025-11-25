extends Node

var rng
var showTutorial := true

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	rng = RandomNumberGenerator.new()
	rng.randomize()

func _input(event: InputEvent):
	if event is InputEventMouseMotion:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif event is InputEventJoypadMotion:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func check_is_controller_connected() -> bool:
	return 0 < Input.get_connected_joypads().size()
