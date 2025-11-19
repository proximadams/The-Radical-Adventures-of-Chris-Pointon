extends Node2D

onready var environment  : Node2D          = $Environment
onready var player       : Node2D          = $Player
onready var score        : Control         = $CanvasLayer/Score
onready var tree         : SceneTree       = get_tree()
onready var animGameOver : AnimationPlayer = $CanvasLayer/GameOverScreen/AnimationPlayer

func _ready():
	var _res = $Player.connect('environment_slow_down', $Environment, 'slow_down')
	_res = $Player.connect('show_new_points', self, '_increase_points')

func _process(_delta):
	if player.rampState == player.NOT_ON:
		player.anim.playback_speed = 1.0
	else:
		player.anim.playback_speed = 0.75 + environment.anim.playback_speed * 0.25

func _increase_points(points: int) -> void:
	environment.increase_max_speed(points)
	score.show_new_points(points)

func game_over() -> void:
	animGameOver.play('animate')
	tree.paused = true

func play_again():
	tree.paused = false
	get_tree().change_scene('res://scenes/Level.tscn')

func exit():
	tree.paused = false
	get_tree().change_scene('res://scenes/TitleScreen.tscn')
