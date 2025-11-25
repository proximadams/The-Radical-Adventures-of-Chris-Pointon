extends Control

onready var focusDefaultButton : Button = $FocusDefaultButton

func _ready() -> void:
	Global.showTutorial = true

func change_scene() -> void:
	get_tree().change_scene('res://scenes/Level.tscn')

func _on_StartButton_pressed() -> void:
	$AnimationPlayer.play('hip_options')
	focusDefaultButton.nextFocusControl = $VBoxContainer/ButtonYes
	focusDefaultButton.focus_on_default()

func _go_back() -> void:
	focusDefaultButton.nextFocusControl = $StartButton
	focusDefaultButton.focus_on_default()

func _not_for_you() -> void:
	focusDefaultButton.nextFocusControl = $BackButton
	focusDefaultButton.focus_on_default()
