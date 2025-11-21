extends Node2D

const BASE_MAX_SPEED             := 2.0
const RATE_INCREASE_PLAYER_SPEED := 0.1
const RATE_INCREASE_MAX_SPEED    := 0.003
const MIN_SPEED                  := 1.5
const REDUCE_SPEED_MULT          := 0.5

var barricadeRes       : Resource = load('res://scenes/Barricade.tscn')
var concreteBarrierRes : Resource = load('res://scenes/ConcreteBarrier.tscn')
var potholeRes         : Resource = load('res://scenes/Pothole.tscn')
var potholeGroupRes    : Resource = load('res://scenes/PotholeGroup.tscn')
var rampRes            : Resource = load('res://scenes/Ramp.tscn')
var speedDecreaseRes   : Resource = load('res://scenes/SpeedDecreaseStrip.tscn')
var tubeRes            : Resource = load('res://scenes/Tube.tscn')

var isSpawning    : bool  = false
var maxSpeed      : float = 2.0
var resArr        : Array = [tubeRes, potholeGroupRes, barricadeRes, barricadeRes, barricadeRes, concreteBarrierRes, speedDecreaseRes, potholeRes, potholeRes, rampRes]
var rng
var skipIncoming  : int = 0
var subgroupIndex : int = 2
var totalPoints   : int = 0

onready var anim        : AnimationPlayer = $AnimationPlayer
onready var subgroupArr : Array = [
	$Group1/SubGroup1,
	$Group1/SubGroup2,
	$Group1/SubGroup3,
	$Group2/SubGroup4,
	$Group2/SubGroup5,
	$Group2/SubGroup6,
]

func _ready() -> void:
	rng = RandomNumberGenerator.new()
	rng.randomize()

func _process(delta: float) -> void:
	anim.playback_speed = min(maxSpeed, anim.playback_speed + delta * RATE_INCREASE_PLAYER_SPEED)

func slow_down() -> void:
	anim.playback_speed = max(MIN_SPEED, anim.playback_speed * REDUCE_SPEED_MULT)

func increase_max_speed(points: int) -> void:
	maxSpeed += points * RATE_INCREASE_MAX_SPEED
	totalPoints += points

func begin_spawning():
	isSpawning = true

func try_respawn() -> void:
	if isSpawning:
		_free_children()
		_instantiate_res(0)
		_instantiate_res(512)
	subgroupIndex = (subgroupIndex + 1) % subgroupArr.size()

func _free_children() -> void:
	var childArr: Array = subgroupArr[subgroupIndex].get_children()
	for currChild in childArr:
		currChild.free()

func _instantiate_res(offsetX: int) -> void:
	if skipIncoming == 0:
		var resIndex: int = rng.randi_range(0, resArr.size() -1)
		if totalPoints < 150:
			resIndex = 2
			skipIncoming += 1
		if resIndex == 6:
			if 1500 < totalPoints and rng.randf() < 0.2:
				skipIncoming += 1
			else:
				resIndex = resArr.size() -1
		if resIndex == 5:
			if 1000 < totalPoints and offsetX == 0:
				skipIncoming += 3
			else:
				resIndex = resArr.size() -1
		if (offsetX == 0 or resIndex != 0) and (500 <= totalPoints or resIndex != 1):
			var inst = resArr[resIndex].instance()
			subgroupArr[subgroupIndex].add_child(inst)
			inst.owner = subgroupArr[subgroupIndex]
			inst.position.x += offsetX
			inst.position.y += rng.randi_range(-300, 300)
			if resIndex == 0:
				skipIncoming += 1
	else:
		skipIncoming -= 1
