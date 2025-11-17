extends Area2D

export var offsetY := 80.0

func _ready() -> void:
	connect('area_entered', self, '_on_Area2D_area_entered')
	connect('area_exited', self, '_on_Area2D_area_exited')

func _on_Area2D_area_entered(area: Area2D):
	if area.name == 'PlayerGrindArea':
		area.try_start_grind(global_position.y + offsetY)

func _on_Area2D_area_exited(area: Area2D):
	if area.name == 'PlayerGrindArea':
		area.try_end_grind()
