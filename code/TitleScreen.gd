extends Control

func _ready() -> void:
	Global.showTutorial = true

func change_scene() -> void:
	get_tree().change_scene('res://scenes/Level.tscn')
