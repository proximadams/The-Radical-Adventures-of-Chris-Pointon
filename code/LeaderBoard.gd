extends ScrollContainer

var entryRes : Resource = load('res://scenes/LeaderBoardEntry.tscn')

onready var container = $VBoxContainer

const data : Array = [
	{
		'name': 'Lucky',
		'points': 12035,
	},
	{
		'name': 'Braden',
		'points': 3761,
	},
	{
		'name': 'Pig',
		'points': 1312,
	},
	{
		'name': 'Poo',
		'points': 810,
	},
	{
		'name': 'Dude',
		'points': 237,
	}
]

func _ready():
	var currPlace : int = 1
	for currObj in data:
		var entryInst : Control = entryRes.instance()
		container.add_child(entryInst)
		entryInst.set_info(currObj.name, currObj.points)
		entryInst.set_place(currPlace)
		currPlace += 1
