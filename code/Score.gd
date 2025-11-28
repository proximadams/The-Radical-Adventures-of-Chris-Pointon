extends Control

const MILESTONES = [100, 200, 300, 400, 500, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000, 11000, 12000, 13000, 14000, 15000, 16000, 17000, 18000, 19000, 20000, 30000, 40000, 50000, 60000, 70000, 80000, 90000, 100000]

var totalPoints := 0

onready var animNewPoints    : AnimationPlayer   = $NewPoints/AnimationPlayer
onready var animMilestones   : AnimationPlayer   = $Milestones/AnimationPlayer
onready var newPointsText1   : Label             = $NewPoints/Background
onready var newPointsText2   : Label             = $NewPoints/Main
onready var animTotalPoints  : AnimationPlayer   = $TotalPoints/AnimationPlayer
onready var milestoneText1   : Label             = $Milestones/TextBackground
onready var milestoneText2   : Label             = $Milestones/TextMain
onready var milestoneSound   : AudioStreamPlayer = $Milestones/AudioStreamPlayer
onready var totalPointsText1 : Label             = $TotalPoints/Background
onready var totalPointsText2 : Label             = $TotalPoints/Main

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
	_handle_potential_milestone_cross(points)

func increase_total_score() -> void:
	totalPointsText1.text = str(totalPoints)
	totalPointsText2.text = str(totalPoints)
	animTotalPoints.play('increase')
	animNewPoints.seek(0.0)

func _handle_potential_milestone_cross(points: int) -> void:
	var milestoneHit := 0
	for currMilestone in MILESTONES:
		if currMilestone <= totalPoints and totalPoints - points < currMilestone:
			milestoneHit = currMilestone
			break

	if milestoneHit:
		milestoneText1.text = 'Over ' + str(milestoneHit) + ' points!'
		milestoneText2.text = milestoneText1.text
		animMilestones.play('animate')
		milestoneSound.play()
