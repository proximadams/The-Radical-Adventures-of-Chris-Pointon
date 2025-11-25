extends Control

onready var anim               : AnimationPlayer = $AnimationPlayer
onready var continueButton     : Button          = $ContinueButton
onready var focusDefaultButton : Button          = $FocusDefaultButton

func _ready() -> void:
	Global.showTutorial = true
	Input.connect('joy_connection_changed', self, '_on_joy_connection_changed')

func change_scene() -> void:
	get_tree().change_scene('res://scenes/Level.tscn')

func _on_StartButton_pressed() -> void:
	anim.play('hip_options')
	focusDefaultButton.nextFocusControl = $VBoxContainer/ButtonYes
	focusDefaultButton.focus_on_default()

func _go_back() -> void:
	focusDefaultButton.nextFocusControl = $StartButton
	focusDefaultButton.focus_on_default()

func _not_for_you() -> void:
	focusDefaultButton.nextFocusControl = $BackButton
	focusDefaultButton.focus_on_default()

func _yes_hip():
	if Global.check_is_controller_connected():
		anim.play('hip_lets_hit_it')
	else:
		anim.play('recommend_controller')

func _on_joy_connection_changed(_device, connected) -> void:
	if connected and (anim.current_animation == 'recommend_controller' or continueButton.visible):
		continueButton.grab_focus()
