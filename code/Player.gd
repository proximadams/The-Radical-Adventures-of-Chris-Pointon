extends Node2D

const CROUNCH_WINDOW_TIME    := 0.3
const GROUND_180_WINDOW_TIME := 0.3
const SPEED                  := 300.0

onready var anim     : AnimationPlayer = $VisualAnimationPlayer
onready var animHurt : AnimationPlayer = $HurtAnimationPlayer

var crounchWindowTimer := CROUNCH_WINDOW_TIME
var timeSinceInputShiftBack := 1000.0
var timeSinceInputShiftCrouch := 1000.0
var timeSinceInputShiftForward := 1000.0
var timeSinceInputShiftJump := 1000.0

func _ready() -> void:
	var _res = $PlayerHurtableArea.connect('player_is_hurt', self, 'hurt_me')

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
			if anim.current_animation != 'shift_forward' and anim.current_animation != 'hold_forward' and not anim.current_animation.begins_with('turn'):
				anim.play('shift_forward')
				anim.queue('hold_forward')
		elif Input.is_action_pressed('shift_back'):
			if anim.current_animation != 'shift_back' and anim.current_animation != 'hold_back' and not anim.current_animation.begins_with('turn'):
				anim.play('shift_back')
				anim.queue('hold_back')
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
	
	# tricks
	_listen_for_trick_inputs(delta)
	if (anim.current_animation == 'shift_back' or anim.current_animation == 'shift_forward' or anim.current_animation == 'hold_back' or anim.current_animation == 'hold_forward') and not anim.current_animation.begins_with('turn') and timeSinceInputShiftBack < GROUND_180_WINDOW_TIME and timeSinceInputShiftForward < GROUND_180_WINDOW_TIME:
		anim.play('turn_180_ftb')
		anim.queue('idle')


func _listen_for_trick_inputs(delta: float) -> void:
	timeSinceInputShiftBack += delta
	timeSinceInputShiftCrouch += delta
	timeSinceInputShiftForward += delta
	timeSinceInputShiftJump += delta
	if Input.is_action_just_pressed('shift_back'):
		timeSinceInputShiftBack = 0.0
	if Input.is_action_just_pressed('shift_crouch'):
		timeSinceInputShiftCrouch = 0.0
	if Input.is_action_just_pressed('shift_forward'):
		timeSinceInputShiftForward = 0.0
	if Input.is_action_just_pressed('shift_jump'):
		timeSinceInputShiftJump = 0.0

func try_to_trick_jump() -> void:
	var timeSpentJumping: float = anim.current_animation_position
	if timeSinceInputShiftCrouch < timeSpentJumping and timeSinceInputShiftJump < timeSpentJumping:
		anim.play('jump_high_kickflip')
		anim.seek(timeSpentJumping)
	if timeSinceInputShiftBack < timeSpentJumping and timeSinceInputShiftForward < timeSpentJumping:
		anim.play('jump_high_360')
		anim.seek(timeSpentJumping)

func _check_release_shift() -> bool:
	var hasReleased     : bool = (Input.is_action_just_released('shift_forward') or Input.is_action_just_released('shift_back') or Input.is_action_just_released('shift_crouch'))
	var pressingNothing : bool = (not Input.is_action_pressed('shift_forward') and not Input.is_action_pressed('shift_back') and not Input.is_action_pressed('shift_crouch'))
	return hasReleased and pressingNothing and not anim.current_animation.begins_with('turn')

func hurt_me() -> void:
	animHurt.play('hurt')
	animHurt.queue('normal')
