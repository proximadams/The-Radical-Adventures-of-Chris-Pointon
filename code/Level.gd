extends Node2D

onready var animGameOver       : AnimationPlayer = $CanvasLayer/GameOverScreen/AnimationPlayer
onready var animInstructions   : AnimationPlayer = $CanvasLayer/Tutorial/AnimationPlayer
onready var environment        : Node2D          = $Environment
onready var gameOverHeader     : Control         = $CanvasLayer/GameOverScreen/Header
onready var inputSticks        : Control         = $CanvasLayer/Tutorial/InputSticks
onready var leaderBoard        : Control         = $CanvasLayer/GameOverScreen/LeaderBoard
onready var player             : Node2D          = $Player
onready var score              : Control         = $CanvasLayer/Score
onready var tree               : SceneTree       = get_tree()
onready var tutorialController : Array           = [
	$CanvasLayer/Tutorial/Move/Controller,
	$CanvasLayer/Tutorial/Kickflip/Controller,
	$CanvasLayer/Tutorial/Spin/Controller,
	$CanvasLayer/Tutorial/Grind/Controller,
]
onready var tutorialKeyboard  : Array           = [
	$CanvasLayer/Tutorial/Move/Keyboard,
	$CanvasLayer/Tutorial/Kickflip/Keyboard,
	$CanvasLayer/Tutorial/Spin/Keyboard,
	$CanvasLayer/Tutorial/Grind/Keyboard,
]
enum {
	MOVE,
	KICKFLIP,
	SPIN,
	GRIND,
	SCORE,
	FINISHED
}

var instructionsState := MOVE

func _ready():
	var _res = $Player.connect('environment_slow_down', $Environment, 'slow_down')
	_res = $Player.connect('show_new_points', self, '_increase_points')
	_res = $Environment.connect('player_slow_down', self, 'player_slow_down')
	if not Global.showTutorial:
		instructionsState = FINISHED
		animInstructions.play('hide')
		environment.begin_spawning()

func _show_controller_tutorial() -> void:
	inputSticks.modulate.a = 1.0
	_refresh_tutorial_input_visibility(true)

func _show_keyboard_tutorial() -> void:
	inputSticks.modulate.a = 0.0
	_refresh_tutorial_input_visibility(false)

func _refresh_tutorial_input_visibility(usesController: bool) -> void:
	for currNode in tutorialController:
		currNode.visible = usesController
	for currNode in tutorialKeyboard:
		currNode.visible = not usesController

func _process(_delta: float) -> void:
	if Global.showTutorial and instructionsState == FINISHED and 500 <= environment.totalPoints:
		Global.showTutorial = false

	if Global.showTutorial and instructionsState != FINISHED:
		if Global.check_is_controller_connected():
			_show_controller_tutorial()
		else:
			inputSticks.modulate.a = 0.0

	if player.rampState == player.NOT_ON:
		player.anim.playback_speed = 1.0
	else:
		player.anim.playback_speed = 0.75 + environment.anim.playback_speed * 0.25
		player.set_ramp_pitch_scale()
	match instructionsState:
		MOVE:
			if Input.is_action_just_pressed('move_down') or Input.is_action_just_pressed('move_up') or Input.is_action_just_pressed('move_left') or Input.is_action_just_pressed('move_right'):
				instructionsState = KICKFLIP
				animInstructions.play('kickflip')
		KICKFLIP:
			if player.anim.current_animation == 'jump_high_kickflip':
				instructionsState = SPIN
				animInstructions.play('spin')
		SPIN:
			if player.anim.current_animation == 'jump_high_360':
				instructionsState = GRIND
				animInstructions.play('grind')
				environment.begin_spawning()
		GRIND:
			if player.anim.current_animation.begins_with('grind'):
				instructionsState = SCORE
				animInstructions.play('score')
		SCORE:
			if player.anim.current_animation == 'grind_end_jump_high_kickflip_kickflip' or player.anim.current_animation == 'grind_end_jump_high_720':
				instructionsState = FINISHED
				animInstructions.play('begin')

func _increase_points(points: int) -> void:
	if (instructionsState == GRIND or instructionsState == SCORE or instructionsState == FINISHED):
		environment.increase_max_speed(points)
		score.show_new_points(points)
		player.refresh_player_speed(environment.anim.playback_speed)

func player_slow_down() -> void:
	player.refresh_player_speed(environment.anim.playback_speed)

func game_over() -> void:
	var isNewRecord : bool = (Records.recordsArr.size() != 0 and Records.recordsArr.max() < score.totalPoints)
	animGameOver.play('animate')
	leaderBoard._update_player_in_leaderboard(environment.totalPoints)
	tree.paused = true
	Records.recordsArr.append(score.totalPoints)
	if isNewRecord:
		gameOverHeader.text = 'New Record!'
	else:
		gameOverHeader.text = 'Try Again.'

func play_again():
	tree.paused = false
	get_tree().change_scene('res://scenes/Level.tscn')

func exit():
	tree.paused = false
	get_tree().change_scene('res://scenes/TitleScreen.tscn')
