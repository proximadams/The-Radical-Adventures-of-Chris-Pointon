extends Node2D

onready var gameOverHeader   : Control = $CanvasLayer/GameOverScreen/Header
onready var environment      : Node2D          = $Environment
onready var player           : Node2D          = $Player
onready var score            : Control         = $CanvasLayer/Score
onready var tree             : SceneTree       = get_tree()
onready var animGameOver     : AnimationPlayer = $CanvasLayer/GameOverScreen/AnimationPlayer
onready var animInstructions : AnimationPlayer = $CanvasLayer/Tutorial/AnimationPlayer
enum {
	MOVE,
	KICKFLIP,
	SPIN,
	GRIND,
	FINISHED
}

var instructionsState := MOVE

func _ready():
	var _res = $Player.connect('environment_slow_down', $Environment, 'slow_down')
	_res = $Player.connect('show_new_points', self, '_increase_points')

func _process(_delta):
	if player.rampState == player.NOT_ON:
		player.anim.playback_speed = 1.0
	else:
		player.anim.playback_speed = 0.75 + environment.anim.playback_speed * 0.25
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
				instructionsState = FINISHED
				animInstructions.play('begin')

func _increase_points(points: int) -> void:
	environment.increase_max_speed(points)
	if (instructionsState == GRIND or instructionsState == FINISHED):
		score.show_new_points(points)

func game_over() -> void:
	var isNewRecord : bool = (Records.recordsArr.size() != 0 and Records.recordsArr.max() < score.totalPoints)
	animGameOver.play('animate')
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
