extends 'res://code/SpriteAdjustZ.gd'

var isInTube := false

func _ready() -> void:
	$TubeFront/EnterArea.connect('area_entered', self, '_try_enter_tube')
	$TubeFront/ExitArea.connect('area_exited', self, '_try_exit_tube')

func _try_enter_tube(area: Area2D) -> void:
	if area.name == 'PlayerHurtableArea' and Input.is_action_pressed('shift_crouch'):
		isInTube = true
		player.enter_tube()
		player.global_position.y = global_position.y + 60.0

func _try_exit_tube(area: Area2D) -> void:
	if area.name == 'PlayerHurtableArea':
		isInTube = false
		player.exit_tube()
