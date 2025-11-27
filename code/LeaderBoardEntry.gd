extends Control

var place := -1

func set_info(name: String, points: int) -> void:
	var pointsStr       : String = str(points)
	var numBufferSpaces : int = 0
	var bufferSpaces    : String = ''
	numBufferSpaces = 10 - pointsStr.length()
	if numBufferSpaces < 1:
		numBufferSpaces = 1
	while 0 < numBufferSpaces:
		numBufferSpaces -= 1
		bufferSpaces += ' '
	$Label.text = pointsStr + bufferSpaces + name
	if name == 'YOU':
		modulate.b = 0.0# makes text yellow

func set_place(placeGiven: int) -> void:
	var colonStr := ':  '
	var suffix := 'th'
	place = placeGiven
	if place % 10 == 1:
		suffix = 'st'
	elif place % 10 == 1:
		suffix = 'st'
	elif place % 10 == 2:
		suffix = 'nd'
	elif place % 10 == 3:
		suffix = 'rd'
	if 10 < place % 100 and place % 100 < 20:
		suffix = 'th'
	if 9 < place:
		colonStr = ': '
	$Label.text = str(place) + suffix + colonStr + $Label.text

func set_is_new(value: bool) -> void:
	$New.visible = value
