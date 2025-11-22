extends Node2D

var barricadeRes : Resource = load('res://scenes/Barricade.tscn')
var potholeRes   : Resource = load('res://scenes/Pothole.tscn')
var rampRes      : Resource = load('res://scenes/Ramp.tscn')
var tubeRes      : Resource = load('res://scenes/Tube.tscn')

var resArr : Array = [barricadeRes, potholeRes, rampRes, tubeRes]
var skipIncoming: int = 0

func try_respawn() -> void:
	print('try_respawn')
	_free_children()
	_instantiate_res(0)
	# _instantiate_res(512)

func _free_children() -> void:
	var childArr: Array = get_children()
	for currChild in childArr:
		currChild.free()

func _instantiate_res(offsetX: int) -> void:
	print('_instantiate_res')
	if skipIncoming == 0:
		var resIndex: int = Global.rng.randi_range(0, resArr.size() -1)
		var inst = resArr[resIndex].instance()
		add_child(inst)
		inst.owner = self
		inst.position.x += offsetX
		print('resIndex = ' + str(resIndex))
		if resIndex == 3:
			skipIncoming += 2
	else:
		skipIncoming -= 1
	print('skipIncoming = ' + str(skipIncoming))
