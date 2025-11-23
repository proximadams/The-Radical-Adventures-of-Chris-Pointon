extends Node2D

const BASE_MAX_SPEED             := 2.0
const MIN_SPEED                  := 1.5
const PHASE_DURATION             := 10.0
const PHASE_NORMAL_DURATION      := 30.0
const PHASE_PAUSE_DURATION       := 3.0
const RATE_INCREASE_PLAYER_SPEED := 0.1
const RATE_INCREASE_MAX_SPEED    := 0.003
const REDUCE_SPEED_MULT          := 0.5

# phaseState
enum {
	NORMAL,
	PAUSE_PRE,
	PAUSE_POST,
	POTHOLE,
	BARRICADE,
	RAMP,
	CONCRETE
}

signal player_slow_down

var barricadeRes       : Resource = load('res://scenes/Barricade.tscn')
var concreteBarrierRes : Resource = load('res://scenes/ConcreteBarrier.tscn')
var potholeRes         : Resource = load('res://scenes/Pothole.tscn')
var potholeGroupRes    : Resource = load('res://scenes/PotholeGroup.tscn')
var rampRes            : Resource = load('res://scenes/Ramp.tscn')
var speedDecreaseRes   : Resource = load('res://scenes/SpeedDecreaseStrip.tscn')
var tubeRes            : Resource = load('res://scenes/Tube.tscn')

var isSpawning    : bool  = false
var maxSpeed      : float = 2.0
var phaseArr      : Array = [POTHOLE, BARRICADE, RAMP, CONCRETE]
var phaseState    : int   = NORMAL
var phaseTimer    : float = PHASE_NORMAL_DURATION
var resArr        : Array = [tubeRes, potholeGroupRes, barricadeRes, barricadeRes, barricadeRes, concreteBarrierRes, speedDecreaseRes, potholeRes, potholeRes, rampRes]
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

func _process(delta: float) -> void:
	anim.playback_speed = min(maxSpeed, anim.playback_speed + delta * RATE_INCREASE_PLAYER_SPEED)
	if isSpawning:
		_handle_phases(delta)

func _handle_phases(delta: float) -> void:
	phaseTimer -= delta
	if phaseTimer < 0.0:
		match phaseState:
			NORMAL:
				var doNormalAgain : bool = Global.rng.randf() < 0.5
				if doNormalAgain:
					phaseState = NORMAL
				else:
					phaseState = PAUSE_PRE
				phaseTimer = PHASE_PAUSE_DURATION
			PAUSE_PRE:
				var phaseIndex : int = Global.rng.randi_range(0, 1)
				phaseState = phaseArr[phaseIndex]
				phaseArr.remove(phaseIndex)
				phaseArr.append(phaseState)
				if phaseState == CONCRETE and totalPoints < 1000:
					phaseState = RAMP
				phaseTimer = PHASE_DURATION
			PAUSE_POST:
				phaseState = NORMAL
				phaseTimer = PHASE_NORMAL_DURATION
			_:
				phaseState = PAUSE_POST
				phaseTimer = PHASE_PAUSE_DURATION

func slow_down() -> void:
	anim.playback_speed = max(MIN_SPEED, anim.playback_speed * REDUCE_SPEED_MULT)
	emit_signal('player_slow_down')

func increase_max_speed(points: int) -> void:
	maxSpeed += points * RATE_INCREASE_MAX_SPEED
	totalPoints += points

func begin_spawning():
	isSpawning = true

func try_respawn() -> void:
	if isSpawning:
		_free_children()
		match phaseState:
			NORMAL:
				_instantiate_random_object(0)
				_instantiate_random_object(512)
			POTHOLE:
				_instantiate_pothole_phase(0)
				_instantiate_pothole_phase(256)
				_instantiate_pothole_phase(512)
				_instantiate_pothole_phase(768)
			BARRICADE:
				_instantiate_barricade_phase(0)
				_instantiate_barricade_phase(512)
			RAMP:
				_instantiate_ramp_phase(0)
				_instantiate_ramp_phase(512)
			CONCRETE:
				_instantiate_concrete_phase()
	subgroupIndex = (subgroupIndex + 1) % subgroupArr.size()

func _free_children() -> void:
	var childArr: Array = subgroupArr[subgroupIndex].get_children()
	for currChild in childArr:
		currChild.free()

func _instantiate_pothole_phase(offsetX: int) -> void:
	var doubleSpawn = Global.rng.randf() < 0.5
	if doubleSpawn:
		_instantiate_res(7, offsetX, Global.rng.randi_range(-300, 0))
		_instantiate_res(7, offsetX, Global.rng.randi_range(100, 400))
	else:
		_instantiate_res(7, offsetX, Global.rng.randi_range(-300, 400))

func _instantiate_barricade_phase(offsetX: int) -> void:
	var doubleSpawn = Global.rng.randf() < 0.5
	if doubleSpawn:
		_instantiate_res(2, offsetX, Global.rng.randi_range(-300, 0))
		_instantiate_res(2, offsetX, Global.rng.randi_range(100, 400))
	else:
		_instantiate_res(2, offsetX, Global.rng.randi_range(-300, 400))

func _instantiate_ramp_phase(offsetX: int) -> void:
	var doubleSpawn = Global.rng.randf() < 0.5
	var resIndex = resArr.size() -1
	if doubleSpawn:
		_instantiate_res(resIndex, offsetX, Global.rng.randi_range(-300, 0))
		_instantiate_res(resIndex, offsetX, Global.rng.randi_range(100, 400))
	else:
		_instantiate_res(resIndex, offsetX, Global.rng.randi_range(-300, 400))

func _instantiate_concrete_phase() -> void:
	if skipIncoming == 0:
		var doubleSpawn = Global.rng.randf() < 0.5
		if doubleSpawn:
			_instantiate_res(5, 0, Global.rng.randi_range(-300, -50))
			_instantiate_res(5, 0, Global.rng.randi_range(150, 400))
		else:
			_instantiate_res(5, 0, Global.rng.randi_range(-300, 400))
		skipIncoming += 1
	else:
		skipIncoming -= 1

func _instantiate_random_object(offsetX: int) -> void:
	if skipIncoming == 0:
		var resIndex: int = Global.rng.randi_range(0, resArr.size() -1)
		if totalPoints < 150:
			resIndex = 2
			skipIncoming += 1
		if resIndex == 6:
			if 1500 < totalPoints and Global.rng.randf() < 0.2:
				skipIncoming += 1
			else:
				resIndex = resArr.size() -1
		if resIndex == 5:
			if 1000 <= totalPoints and offsetX == 0:
				skipIncoming += 3
			else:
				resIndex = resArr.size() -1
		elif resIndex == 1:
			skipIncoming += 1
		if (offsetX == 0 or resIndex != 0) and (500 <= totalPoints or resIndex != 1):
			_instantiate_res(resIndex, offsetX, Global.rng.randi_range(-300, 400))
	else:
		skipIncoming -= 1

func _instantiate_res(resIndex: int, offsetX: int, offsetY: int) -> void:
	var inst = resArr[resIndex].instance()
	subgroupArr[subgroupIndex].add_child(inst)
	inst.owner = subgroupArr[subgroupIndex]
	inst.position.x += offsetX
	inst.position.y += offsetY
	if resIndex == 0:
		skipIncoming += 1
