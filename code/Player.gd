extends Node2D

const CROUNCH_WINDOW_TIME := 0.3
const SPEED               := 500.0

onready var anim = $AnimationPlayer

# var shift_action_string_arr = ['shift_crouch', 'shift_forward', 'shift_back']

var crounchWindowTimer := CROUNCH_WINDOW_TIME

func _process(delta: float) -> void:
	# shifting weight and jumping
	if not anim.current_animation.begins_with('jump'):
		if _check_release_shift():
			if Input.is_action_just_released('shift_crouch'):
				anim.play('shift_uncrouch')
				anim.queue('idle')
			else:
				anim.play('idle')
		if Input.is_action_pressed('shift_jump'):
			if 0.0 < crounchWindowTimer:
				anim.play('jump_high')
			else:
				anim.play('jump_low')
			anim.queue('idle')
		elif Input.is_action_pressed('shift_crouch'):
			if crounchWindowTimer < CROUNCH_WINDOW_TIME* 0.9:
				anim.play('shift_crouch')
			crounchWindowTimer = CROUNCH_WINDOW_TIME
		elif Input.is_action_pressed('shift_forward'):
			anim.play('shift_forward')
		elif Input.is_action_pressed('shift_back'):
			anim.play('shift_back')
	if 0.0 < crounchWindowTimer:
		crounchWindowTimer -= delta
	crounchWindowTimer = max(0.0, crounchWindowTimer)

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
