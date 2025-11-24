extends ScrollContainer

var entryRes    : Resource = load('res://scenes/LeaderBoardEntry.tscn')

onready var container = $VBoxContainer

const data : Array = [
	{
		'name': 'Lucky',
		'points': 14134,
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
	},
	{
		'name': 'YOU',
		'points': 0,
	}
]

func _ready() -> void:
	var currPlace : int = 1
	for currObj in data:
		var entryInst : Control = entryRes.instance()
		container.add_child(entryInst)
		entryInst.set_info(currObj.name, currObj.points)
		entryInst.set_place(currPlace)
		entryInst.set_is_new(false)
		currPlace += 1

func _get_player_data():
	var playerObjIndex = _get_player_data_index()
	var playerObj = data[playerObjIndex]
	return playerObj

func _get_player_data_index() -> int:
	var result = -1

	for currObj in data:
		result += 1
		if currObj.name == 'YOU':
			break

	return result

func _get_player_points_data() -> int:
	var result : int = 0
	var playerObj = _get_player_data()

	if playerObj != null:
		result = playerObj.points

	return result

func _update_player_in_leaderboard(totalPoints: int) -> void:
	var playerObjIndex = _get_player_data_index()
	var playerEntry = container.get_child(playerObjIndex)
	var hasBeatOldHighScore : bool = (_get_player_points_data() < totalPoints)

	playerEntry.set_is_new(hasBeatOldHighScore)

	if hasBeatOldHighScore:
		var playerObj = data[playerObjIndex]
		if playerObjIndex != -1:
			var newIndex = playerObjIndex -1
			playerObj.points = totalPoints
			playerEntry.set_info('YOU', totalPoints)

			while 0 < newIndex:
				if totalPoints <= data[newIndex -1].points:
					break
				newIndex -= 1

			playerEntry.set_place(newIndex +1)
			if newIndex != playerObjIndex:
				container.move_child(playerEntry, newIndex)
				data.remove(playerObjIndex)
				data.insert(newIndex, playerObj)

				# change the place of everyone after YOU
				if newIndex < data.size() -1:
					for i in range(newIndex +1, data.size()):
						var entryInst : Control = container.get_child(i)
						entryInst.set_info(data[i].name, data[i].points)
						entryInst.set_place(i +1)
