extends Node2D

const CROUNCH_WINDOW_TIME    := 0.3
const GROUND_180_WINDOW_TIME := 0.3
const JUMP_EARLY_WINDOW      := 0.5
const JUMP_LATE_GRIND_WINDOW := 0.15
const MIN_GRIND_TIME         := 0.3
const MIN_SPEED              := 300.0
const MAX_SPEED              := 500.0

const SCORE_TABLE := {
	'manual': 1,
	'noseManual': 1,
	'ollie': 2,
	'spin180': 5,
	'grind': 10,
	'kickflip': 30,
	'spin360': 30,
	'kickflipX2': 100,
	'spin720': 100,
	'threadNeedle': 100,
}

signal environment_slow_down
signal show_new_points(points)

var crounchWindowTimer         := CROUNCH_WINDOW_TIME
var framesSinceRamp            := 10
var health                     := 3
var isInTube                   := false
var isTryingToEndGrind         := false
var prevAnimation              := 'idle'
var speed                      := MIN_SPEED
var timeSinceInputShiftBack    := 1000.0
var timeSinceInputShiftCrouch  := 1000.0
var timeSinceInputShiftForward := 1000.0
var timeSinceInputShiftJump    := 1000.0
var timeSinceStartedGrind      := 1000.0
var timeSinceEndedGrind        := 1000.0

# rampState
enum {
	NOT_ON,
	ON,
	WAIT_JUMP_LOW,
	WAIT_JUMP_HIGH
}

var rampState = NOT_ON

onready var anim            : AnimationPlayer  = $VisualAnimationPlayer
onready var animHealth      : AnimationPlayer  = $Health/AnimationPlayer
onready var animHurt        : AnimationPlayer  = $HurtAnimationPlayer
onready var animTrickEffect : AnimationPlayer  = $TrickEffects/AnimationPlayer
onready var animTrickName   : AnimationPlayer  = $TrickLabels/TrickAnimationPlayer
onready var hurtCollision   : CollisionShape2D = $PlayerHurtableArea/CollisionShape2D
onready var sound := {
	'rolling': $SoundEffects/Rolling,
	'grinding': $SoundEffects/Grinding,
	'landing': [$SoundEffects/Landing/Clip1, $SoundEffects/Landing/Clip2, $SoundEffects/Landing/Clip3, $SoundEffects/Landing/Clip4, $SoundEffects/Landing/Clip5],
	'jumping': [$SoundEffects/Jumping/Clip1, $SoundEffects/Jumping/Clip2, $SoundEffects/Jumping/Clip3],
	'ramp': [$SoundEffects/Ramp/Clip1, $SoundEffects/Ramp/Clip2, $SoundEffects/Ramp/Clip3],
	'pain': [$SoundEffects/Pain/Clip1, $SoundEffects/Pain/Clip2, $SoundEffects/Pain/Clip3],
}

func _ready() -> void:
	var _res = $PlayerHurtableArea.connect('player_is_hurt', self, 'hurt_me')
	_res = $PlayerHurtableArea.connect('player_go_on_ramp', self, 'go_on_ramp')
	_res = $PlayerHurtableArea.connect('player_slow_down', self, 'slow_down')
	_res = $PlayerGrindArea.connect('player_try_start_grind', self, 'try_start_grind')
	_res = $PlayerGrindArea.connect('player_try_end_grind', self, 'try_end_grind')
	_res = $TrickLabels/TrickAnimationPlayer.connect('trick_complete', self, 'trick_complete')

func _process(delta: float) -> void:
	if _check_is_on_ramp():
		framesSinceRamp = 0
	else:
		framesSinceRamp += 1

	# shifting weight and jumping
	if not anim.current_animation.begins_with('jump'):
		if _check_release_shift() and not anim.current_animation.begins_with('grind_end') and not isInTube and not _check_is_on_ramp():
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
		elif not isInTube:
			if (not anim.current_animation.begins_with('grind_end') or timeSinceEndedGrind < JUMP_LATE_GRIND_WINDOW) and (Input.is_action_just_pressed('shift_jump') or (timeSinceInputShiftJump < JUMP_EARLY_WINDOW and not hurtCollision.disabled)):
				if 0.0 < crounchWindowTimer:
					if _check_is_grinding() or timeSinceEndedGrind < JUMP_LATE_GRIND_WINDOW:
						isTryingToEndGrind = false
						anim.play('grind_end_jump_high')
					elif not anim.current_animation.begins_with('grind_end'):
						anim.play('jump_high')
						_play_sound_jumping()
				else:
					if _check_is_grinding() or timeSinceEndedGrind < JUMP_LATE_GRIND_WINDOW:
						isTryingToEndGrind = false
						anim.play('grind_end_jump_low')
					elif not anim.current_animation.begins_with('grind_end'):
						anim.play('jump_low')
						_play_sound_jumping()
				anim.queue('idle')
			elif Input.is_action_pressed('shift_crouch') and not anim.current_animation.begins_with('grind_end'):
				if crounchWindowTimer < CROUNCH_WINDOW_TIME * 0.9:
					if _check_is_grinding():
						anim.play('grind_crouch')
					else:
						anim.play('shift_crouch')
				crounchWindowTimer = CROUNCH_WINDOW_TIME
			elif Input.is_action_pressed('shift_forward') and not anim.current_animation.begins_with('grind_end'):
				if anim.current_animation != 'shift_forward' and anim.current_animation != 'grind_forward' and anim.current_animation != 'hold_forward' and anim.current_animation != 'grind_forward_hold' and not anim.current_animation.begins_with('turn') and anim.current_animation != 'grind_turn_180_ftb':
					if _check_is_grinding():
						anim.play('grind_forward')
						anim.queue('grind_forward_hold')
					else:
						anim.play('shift_forward')
						anim.queue('hold_forward')
			elif Input.is_action_pressed('shift_back') and not anim.current_animation.begins_with('grind_end'):
				if anim.current_animation != 'shift_back' and anim.current_animation != 'grind_back' and anim.current_animation != 'hold_back' and anim.current_animation != 'grind_back_hold' and not anim.current_animation.begins_with('turn') and anim.current_animation != 'grind_turn_180_ftb':
					if _check_is_grinding():
						anim.play('grind_back')
						anim.queue('grind_back_hold')
					else:
						anim.play('shift_back')
						anim.queue('hold_back')
	if 0.0 < crounchWindowTimer:
		crounchWindowTimer -= delta
	crounchWindowTimer = max(0.0, crounchWindowTimer)

	# movement
	if not _check_is_on_ramp():
		var movementDirection = _get_movement_input_direction()
		if _check_is_grinding() or isInTube:
			movementDirection.y = 0.0
		movementDirection = movementDirection.normalized()
		position += movementDirection * delta * speed
	global_position.y = clamp(global_position.y, 180, 990)
	global_position.x = clamp(global_position.x, 60, 1850)

	_refresh_rolling_sound_volume()
	_refresh_sound_grinding()
	_refresh_effect_grinding()
	
	# tricks
	_listen_for_trick_inputs(delta)
	if (anim.current_animation == 'shift_back' or anim.current_animation == 'shift_forward' or anim.current_animation == 'hold_back' or anim.current_animation == 'hold_forward' or anim.current_animation == 'grind_back' or anim.current_animation == 'grind_forward') and not anim.current_animation.begins_with('turn') and (timeSinceInputShiftBack < GROUND_180_WINDOW_TIME and timeSinceInputShiftForward < GROUND_180_WINDOW_TIME) and not anim.current_animation.begins_with('grind_end') and anim.current_animation != 'grind_turn_180_ftb' and not _check_is_on_ramp() and not isInTube:
		if _check_is_grinding():
			anim.play('grind_turn_180_ftb')
			anim.queue('grind_forward_hold')
		else:
			anim.play('turn_180_ftb')
			anim.queue('idle')
	timeSinceStartedGrind += delta
	if anim.current_animation.begins_with('grind_end'):
		timeSinceEndedGrind += delta
	elif anim.current_animation.find('grind') != -1 or anim.current_animation.find('ramp') != -1:
		timeSinceEndedGrind = 0.0
	else:
		timeSinceEndedGrind = JUMP_LATE_GRIND_WINDOW
	if isTryingToEndGrind and MIN_GRIND_TIME < timeSinceStartedGrind and not _check_is_on_ramp() and not isInTube:
		isTryingToEndGrind = false
		anim.play('grind_end')
		anim.queue('idle')

	if anim.current_animation:
		prevAnimation = anim.current_animation

func _refresh_rolling_sound_volume() -> void:
	if hurtCollision.disabled:
		sound.rolling.volume_db = -80.0
	elif sound.rolling.volume_db == -80.0:
		sound.rolling.volume_db = 6.0
		if anim.current_animation.find('jump') != -1 or anim.current_animation.find('grind_end') != -1:
			_play_sound_landing()
			animTrickEffect.play('land')
	if _get_movement_input_direction() == Vector2(0.0, 0.0):
		sound.rolling.pitch_scale = 1.0
	else:
		sound.rolling.pitch_scale = 2.0
	if anim.current_animation == 'turn_180_ftb' and 0.1 <= anim.current_animation_position:
		sound.rolling.volume_db = 15.0
		sound.rolling.pitch_scale = 2.0
	elif sound.rolling.volume_db == 15.0:
		sound.rolling.volume_db = 6.0

func _refresh_effect_grinding() -> void:
	var isGrinding : bool = _check_is_grinding()
	if animTrickEffect.current_animation != 'grind' and isGrinding:
		animTrickEffect.play('grind')
	elif animTrickEffect.current_animation == 'grind' and not isGrinding:
		animTrickEffect.play('none')

func _refresh_sound_grinding() -> void:
	if anim.current_animation == 'grind_turn_180_ftb':
		sound.grinding.pitch_scale = 2.0
	else:
		sound.grinding.pitch_scale = 1.0

	if _check_is_grinding():
		sound.grinding.volume_db = 0.0
	elif anim.current_animation == 'grind_turn_180_ftb':
		sound.grinding.volume_db = 15.0
	else:
		sound.grinding.volume_db = -80.0

func refresh_player_speed(environmentSpeed: float) -> void:
	speed = clamp(MIN_SPEED * (0.5 + environmentSpeed * 0.25), MIN_SPEED, MAX_SPEED)

func _play_sound_landing() -> void:
	_play_random_sound(sound.landing)

func _play_sound_jumping() -> void:
	_play_random_sound(sound.jumping)

func _play_sound_ramp() -> void:
	_play_random_sound(sound.ramp)

func _play_random_sound(soundArr: Array) -> void:
	var soundIndex = Global.rng.randi_range(0, soundArr.size() -2)
	var soundClip = soundArr[soundIndex]
	soundClip.play()
	soundArr.remove(soundIndex)
	soundArr.append(soundClip)

func set_ramp_pitch_scale() -> void:
	for currRampSound in sound.ramp:
		currRampSound.pitch_scale = anim.playback_speed

func _get_movement_input_direction() -> Vector2:
	return Vector2(
		Input.get_action_strength('move_right') - Input.get_action_strength('move_left'),
		Input.get_action_strength('move_down') - Input.get_action_strength('move_up')
	)

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
	if timeSinceInputShiftCrouch < timeSpentJumping and (timeSinceInputShiftBack < timeSpentJumping or timeSinceInputShiftForward < timeSpentJumping):
		if anim.current_animation == 'jump_high':
			anim.play('jump_high_360')
			_play_sound_jumping()
		elif anim.current_animation == 'grind_end_jump_high':
			if isLate:
				anim.play('grind_end_jump_high_360_late')
				_play_sound_jumping()
			else:
				anim.play('grind_end_jump_high_360')
				_play_sound_jumping()
				timeSinceInputShiftBack = 1000.0
				timeSinceInputShiftForward = 1000.0
				timeSinceInputShiftCrouch = 1000.0
		elif anim.current_animation == 'grind_end_jump_high_360':
			anim.play('grind_end_jump_high_720')
			_play_sound_jumping()
		elif anim.current_animation == 'grind_end_jump_high_kickflip':
			anim.play('grind_end_jump_high_kickflip_360')
			_play_sound_jumping()

		anim.seek(timeSpentJumping)

		if anim.current_animation == 'grind_end' or anim.current_animation == 'grind_end_jump_low':
			anim.play('grind_end_jump_low_360')
			_play_sound_jumping()
	elif timeSinceInputShiftCrouch < timeSpentJumping and timeSinceInputShiftJump < timeSpentJumping:
		if anim.current_animation == 'jump_high':
			anim.play('jump_high_kickflip')
			_play_sound_jumping()
		elif anim.current_animation == 'grind_end_jump_high':
			if isLate:
				anim.play('grind_end_jump_high_kickflip_late')
				_play_sound_jumping()
			else:
				anim.play('grind_end_jump_high_kickflip')
				_play_sound_jumping()
				timeSinceInputShiftCrouch = 1000.0
				timeSinceInputShiftJump = 1000.0
		elif anim.current_animation == 'grind_end_jump_high_kickflip':
			anim.play('grind_end_jump_high_kickflip_kickflip')
			_play_sound_jumping()
		elif anim.current_animation == 'grind_end_jump_high_360':
			anim.play('grind_end_jump_high_360_kickflip')
			_play_sound_jumping()

		anim.seek(timeSpentJumping)

		if anim.current_animation == 'grind_end' or anim.current_animation == 'grind_end_jump_low':
			anim.play('grind_end_jump_low_kickflip')
			_play_sound_jumping()

func _check_release_shift() -> bool:
	var hasReleased     : bool = (Input.is_action_just_released('shift_forward') or Input.is_action_just_released('shift_back') or Input.is_action_just_released('shift_crouch'))
	var pressingNothing : bool = (not Input.is_action_pressed('shift_forward') and not Input.is_action_pressed('shift_back') and not Input.is_action_pressed('shift_crouch'))
	return hasReleased and pressingNothing and not anim.current_animation.begins_with('turn')

func hurt_me() -> void:
	yield(get_tree(), 'idle_frame')
	yield(get_tree(), 'idle_frame')
	yield(get_tree(), 'idle_frame')
	hurt_me_if_not_on_ramp()

func hurt_me_if_not_on_ramp() -> void:
	if 10 < framesSinceRamp:
		if not isInTube and not animHurt.current_animation == 'hurt':
			health -= 1
			animHurt.play('hurt')
			animHurt.queue('normal')
			emit_signal('environment_slow_down')
			match health:
				2:
					sound.pain[0].play()
				1:
					sound.pain[1].play()
				0:
					sound.pain[2].play()

func slow_down() -> void:
	emit_signal('environment_slow_down')

func go_on_ramp() -> void:
	if Input.is_action_pressed('shift_crouch'):
		anim.play('ramp_crouch')
	else:
		anim.play('ramp_idle')
	anim.queue('grind_end')
	rampState = ON
	_play_sound_ramp()

func go_off_ramp() -> void:
	if rampState == WAIT_JUMP_HIGH:
		anim.play('grind_end_jump_high')
	elif rampState == WAIT_JUMP_LOW:
		anim.play('grind_end_jump_low')
	elif anim.current_animation == 'ramp_crouch' or anim.current_animation == '':
		anim.play('grind_end')
	rampState = NOT_ON

func try_start_grind(positionY: float) -> void:
	isTryingToEndGrind = false
	if anim.current_animation == 'jump_high' or anim.current_animation == 'grind_end_jump_high' or anim.current_animation == 'grind_end_jump_high_kickflip' or anim.current_animation == 'grind_end_jump_high_360':
		timeSinceStartedGrind = 0.0
		global_position.y = positionY
		anim.play('grind_forward')
		_play_sound_landing()
		animTrickEffect.play('land_grind')
	elif anim.current_animation == 'jump_low' or anim.current_animation == 'grind_end_jump_low':
		timeSinceStartedGrind = 0.0
		global_position.y = positionY
		anim.play('grind_back')
		anim.queue('grind_back_hold')
		_play_sound_landing()
		animTrickEffect.play('land_grind')

func try_end_grind() -> void:
	if not anim.current_animation.begins_with('grind_end'):
		isTryingToEndGrind = true

func enter_tube() -> void:
	isInTube = true
	anim.play('hold_crouch')
	animTrickName.thread_needle()

func exit_tube() -> void:
	if isInTube:
		isInTube = false
		if not Input.is_action_pressed('shift_crouch'):
			anim.play('shift_uncrouch')
			anim.queue('idle')

func _check_is_grinding_animation(name: String) -> bool:
	return (name == 'grind_back' or name == 'grind_forward' or name == 'grind_crouch' or name == 'grind_uncrouch' or name == 'grind_turn_180_ftb' or name == 'grind_forward_hold' or name == 'grind_back_hold')

func _check_is_grinding() -> bool:
	return _check_is_grinding_animation(prevAnimation) or _check_is_grinding_animation(anim.current_animation)

func _check_is_on_ramp() -> bool:
	return rampState != NOT_ON

func trick_complete(name: String) -> void:
	if name in SCORE_TABLE.keys():
		var points = SCORE_TABLE[name]
		emit_signal('show_new_points', points)
	else:
		print('error in trick_complete() no trick named "' + name + '"')

func hide_heart() -> void:
	match health:
		2:
			animHealth.play('3to2')
		1:
			animHealth.play('2to1')
		0:
			animHealth.play('1to0')

func _on_VisualAnimationPlayer_animation_started(_anim_name:String):
	# print('anim_name = ' + anim_name)
	pass
