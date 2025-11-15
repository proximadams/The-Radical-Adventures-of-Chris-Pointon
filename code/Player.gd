extends Node2D

const SPEED := 500.0

onready var anim = $AnimationPlayer

# var shift_action_string_arr = ['shift_crouch', 'shift_forward', 'shift_back']

func _process(delta: float) -> void:
	# shifting weight
	if _check_release_shift():
		anim.play('idle')
	if Input.is_action_pressed('shift_crouch'):
		anim.play('shift_crouch')
	elif Input.is_action_pressed('shift_forward'):
		anim.play('shift_forward')
	elif Input.is_action_pressed('shift_back'):
		anim.play('shift_back')

	# movement
	var movementDirection = Vector2(
		Input.get_action_strength('move_right') - Input.get_action_strength('move_left'),
		Input.get_action_strength('move_down') - Input.get_action_strength('move_up')
	)
	movementDirection = movementDirection.normalized()
	position += movementDirection * delta * SPEED

func _check_release_shift() -> bool:
	var hasReleased     : bool = (Input.is_action_just_released('shift_forward') or Input.is_action_just_released('shift_back') or Input.is_action_just_released('shift_crouch'))
	var pressingNothing : bool = (not Input.is_action_pressed('shift_forward') and not Input.is_action_pressed('shift_back') and not Input.is_action_pressed('shift_crouch'))
	return hasReleased and pressingNothing
