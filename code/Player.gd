extends Node2D

const CROUNCH_WINDOW_TIME    := 0.3
const GROUND_180_WINDOW_TIME := 0.3
const MIN_GRIND_TIME         := 0.3
const SPEED                  := 300.0

onready var anim     : AnimationPlayer = $VisualAnimationPlayer
onready var animHurt : AnimationPlayer = $HurtAnimationPlayer

var crounchWindowTimer         := CROUNCH_WINDOW_TIME
var isInTube                   := false
var isTryingToEndGrind         := false
var timeSinceInputShiftBack    := 1000.0
var timeSinceInputShiftCrouch  := 1000.0
var timeSinceInputShiftForward := 1000.0
var timeSinceInputShiftJump    := 1000.0
var timeSinceStartedGrind      := 1000.0

# rampState
enum {
	NOT_ON,
	ON,
	WAIT_JUMP_LOW,
	WAIT_JUMP_HIGH
}

var rampState = NOT_ON

func _ready() -> void:
	var _res = $PlayerHurtableArea.connect('player_is_hurt', self, 'hurt_me')
	_res = $PlayerHurtableArea.connect('player_go_on_ramp', self, 'go_on_ramp')
	_res = $PlayerGrindArea.connect('player_try_start_grind', self, 'try_start_grind')
	_res = $PlayerGrindArea.connect('player_try_end_grind', self, 'try_end_grind')

func _process(delta: float) -> void:
	# shifting weight and jumping
	if not anim.current_animation.begins_with('jump'):
		if _check_release_shift() and not anim.current_animation.begins_with('grind_end') and not isInTube:
			if Input.is_action_just_released('shift_crouch'):
				if _check_is_grinding():
					anim.play('grind_uncrouch')
					anim.queue('grind_forward_hold')
				elif _check_is_on_ramp():
					var currentTime = anim.current_animation_position
					anim.play('ramp_idle')
					anim.seek(currentTime)
					anim.queue('grind_end')
				else:
					anim.play('shift_uncrouch')
					anim.queue('idle')
			elif not _check_is_grinding():
				anim.play('idle')
		if _check_is_on_ramp():
			if Input.is_action_just_pressed('shift_jump'):
				if 0.0 < crounchWindowTimer:
					rampState = WAIT_JUMP_HIGH
				else:
					rampState = WAIT_JUMP_LOW
			elif Input.is_action_pressed('shift_crouch'):
				crounchWindowTimer = CROUNCH_WINDOW_TIME
				if anim.current_animation != 'ramp_crouch':
					var currentTime = anim.current_animation_position
					anim.play('ramp_crouch')
					anim.seek(currentTime)
		elif not anim.current_animation.begins_with('grind_end') and not isInTube:
			if Input.is_action_just_pressed('shift_jump'):
				if 0.0 < crounchWindowTimer:
					if _check_is_grinding():
						isTryingToEndGrind = false
						anim.play('grind_end_jump_high')
					elif not anim.current_animation.begins_with('grind_end'):
						anim.play('jump_high')
				else:
					if _check_is_grinding():
						isTryingToEndGrind = false
						anim.play('grind_end_jump_low')
					elif not anim.current_animation.begins_with('grind_end'):
						anim.play('jump_low')
				anim.queue('idle')
			elif Input.is_action_pressed('shift_crouch'):
				if crounchWindowTimer < CROUNCH_WINDOW_TIME * 0.9:
					if _check_is_grinding():
						anim.play('grind_crouch')
					else:
						anim.play('shift_crouch')
				crounchWindowTimer = CROUNCH_WINDOW_TIME
			elif Input.is_action_pressed('shift_forward'):
				if anim.current_animation != 'shift_forward' and anim.current_animation != 'grind_forward' and anim.current_animation != 'hold_forward' and anim.current_animation != 'grind_forward_hold' and not anim.current_animation.begins_with('turn') and anim.current_animation != 'grind_turn_180_ftb':
					if _check_is_grinding():
						anim.play('grind_forward')
						anim.queue('grind_forward_hold')
					else:
						anim.play('shift_forward')
						anim.queue('hold_forward')
			elif Input.is_action_pressed('shift_back'):
				if anim.current_animation != 'shift_back' and anim.current_animation != 'grind_back' and anim.current_animation != 'hold_back' and anim.current_animation != 'grind_back_hold' and not anim.current_animation.begins_with('turn') and anim.current_animation != 'grind_turn_180_ftb':
					if _check_is_grinding():
						anim.play('grind_back')
					else:
						anim.play('shift_back')
						anim.queue('hold_back')
	if 0.0 < crounchWindowTimer:
		crounchWindowTimer -= delta
	crounchWindowTimer = max(0.0, crounchWindowTimer)

	# movement
	if not _check_is_on_ramp():
		var movementDirection = Vector2(
			Input.get_action_strength('move_right') - Input.get_action_strength('move_left'),
			Input.get_action_strength('move_down') - Input.get_action_strength('move_up')
		)
		if _check_is_grinding() or isInTube:
			movementDirection.y = 0.0
		movementDirection = movementDirection.normalized()
		position += movementDirection * delta * SPEED
	
	# tricks
	_listen_for_trick_inputs(delta)
	if (anim.current_animation == 'shift_back' or anim.current_animation == 'shift_forward' or anim.current_animation == 'hold_back' or anim.current_animation == 'hold_forward' or anim.current_animation == 'grind_back' or anim.current_animation == 'grind_forward') and not anim.current_animation.begins_with('turn') and timeSinceInputShiftBack < GROUND_180_WINDOW_TIME and timeSinceInputShiftForward < GROUND_180_WINDOW_TIME and not anim.current_animation.begins_with('grind_end') and anim.current_animation != 'grind_turn_180_ftb' and not _check_is_on_ramp() and not isInTube:
		if _check_is_grinding():
			anim.play('grind_turn_180_ftb')
			anim.queue('grind_forward_hold')
		else:
			anim.play('turn_180_ftb')
			anim.queue('idle')
	timeSinceStartedGrind += delta
	if isTryingToEndGrind and MIN_GRIND_TIME < timeSinceStartedGrind and not _check_is_on_ramp() and not isInTube:
		isTryingToEndGrind = false
		anim.play('grind_end')
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

func try_to_trick_jump(isLate := false) -> void:
	var timeSpentJumping: float = anim.current_animation_position
	if timeSinceInputShiftBack < timeSpentJumping and timeSinceInputShiftForward < timeSpentJumping:
		if anim.current_animation == 'jump_high':
			anim.play('jump_high_360')
		elif anim.current_animation == 'grind_end_jump_high':
			if isLate:
				anim.play('grind_end_jump_high_360_late')
			else:
				anim.play('grind_end_jump_high_360')
				timeSinceInputShiftBack = 1000.0
				timeSinceInputShiftForward = 1000.0
		elif anim.current_animation == 'grind_end_jump_high_360':
			anim.play('grind_end_jump_high_720')
		elif anim.current_animation == 'grind_end_jump_high_kickflip':
			anim.play('grind_end_jump_high_kickflip_360')

		anim.seek(timeSpentJumping)

		if anim.current_animation == 'grind_end' or anim.current_animation == 'grind_end_jump_low':
			anim.play('grind_end_jump_low_360')
	elif timeSinceInputShiftCrouch < timeSpentJumping and timeSinceInputShiftJump < timeSpentJumping:
		if anim.current_animation == 'jump_high':
			anim.play('jump_high_kickflip')
		elif anim.current_animation == 'grind_end_jump_high':
			if isLate:
				anim.play('grind_end_jump_high_kickflip_late')
			else:
				anim.play('grind_end_jump_high_kickflip')
				timeSinceInputShiftCrouch = 1000.0
				timeSinceInputShiftJump = 1000.0
		elif anim.current_animation == 'grind_end_jump_high_kickflip':
			anim.play('grind_end_jump_high_kickflip_kickflip')
		elif anim.current_animation == 'grind_end_jump_high_360':
			anim.play('grind_end_jump_high_360_kickflip')

		anim.seek(timeSpentJumping)

		if anim.current_animation == 'grind_end' or anim.current_animation == 'grind_end_jump_low':
			anim.play('grind_end_jump_low_kickflip')

func _check_release_shift() -> bool:
	var hasReleased     : bool = (Input.is_action_just_released('shift_forward') or Input.is_action_just_released('shift_back') or Input.is_action_just_released('shift_crouch'))
	var pressingNothing : bool = (not Input.is_action_pressed('shift_forward') and not Input.is_action_pressed('shift_back') and not Input.is_action_pressed('shift_crouch'))
	return hasReleased and pressingNothing and not anim.current_animation.begins_with('turn')

func hurt_me() -> void:
	if not isInTube:
		animHurt.play('hurt')
		animHurt.queue('normal')

func go_on_ramp() -> void:
	if Input.is_action_pressed('shift_crouch'):
		anim.play('ramp_crouch')
	else:
		anim.play('ramp_idle')
	anim.queue('grind_end')
	rampState = ON

func go_off_ramp() -> void:
	if rampState == WAIT_JUMP_HIGH:
		anim.play('grind_end_jump_high')
	elif rampState == WAIT_JUMP_LOW:
		anim.play('grind_end_jump_low')
	elif anim.current_animation == 'ramp_crouch':
		anim.play('grind_end')
	rampState = NOT_ON

func try_start_grind(positionY: float) -> void:
	isTryingToEndGrind = false
	if anim.current_animation == 'jump_high' or anim.current_animation == 'grind_end_jump_high' or anim.current_animation == 'grind_end_jump_high_kickflip' or anim.current_animation == 'grind_end_jump_high_360':
		timeSinceStartedGrind = 0.0
		global_position.y = positionY
		anim.play('grind_forward')
	elif anim.current_animation == 'jump_low' or anim.current_animation == 'grind_end_jump_low':
		timeSinceStartedGrind = 0.0
		global_position.y = positionY
		anim.play('grind_back')

func try_end_grind() -> void:
	if not anim.current_animation.begins_with('grind_end'):
		isTryingToEndGrind = true

func enter_tube() -> void:
	isInTube = true
	anim.play('hold_crouch')

func exit_tube() -> void:
	isInTube = false
	if not Input.is_action_pressed('shift_crouch'):
		anim.play('shift_uncrouch')
		anim.queue('idle')

func _check_is_grinding() -> bool:
	return (anim.current_animation == 'grind_back' or anim.current_animation == 'grind_forward' or anim.current_animation == 'grind_crouch' or anim.current_animation == 'grind_uncrouch' or anim.current_animation == 'grind_turn_180_ftb' or anim.current_animation == 'grind_forward_hold')

func _check_is_on_ramp() -> bool:
	return rampState != NOT_ON

func _on_VisualAnimationPlayer_animation_started(_anim_name:String):
	# print('anim_name = ' + anim_name)
	pass
