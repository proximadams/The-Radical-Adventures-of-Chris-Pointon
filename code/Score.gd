extends Control

onready var animNewPoints    : AnimationPlayer   = $NewPoints/AnimationPlayer
onready var newPointsText1   : Label             = $NewPoints/Background
onready var newPointsText2   : Label             = $NewPoints/Main
onready var animTotalPoints  : AnimationPlayer   = $TotalPoints/AnimationPlayer
onready var totalPointsText1 : Label             = $TotalPoints/Background
onready var totalPointsText2 : Label             = $TotalPoints/Main

var totalPoints := 0

func show_new_points(points: int) -> void:
	newPointsText1.text = '+' + str(points)
	newPointsText2.text = '+' + str(points)
	totalPointsText1.text = str(totalPoints)
	totalPointsText2.text = str(totalPoints)
	totalPoints += points
	animNewPoints.play('increase')
	animNewPoints.seek(0.0)
	animTotalPoints.play('delay_increase')
	animNewPoints.seek(0.0)

func increase_total_score() -> void:
	totalPointsText1.text = str(totalPoints)
	totalPointsText2.text = str(totalPoints)
	animTotalPoints.play('increase')
	animNewPoints.seek(0.0)
