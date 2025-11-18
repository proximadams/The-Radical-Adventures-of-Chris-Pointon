extends Area2D

func _ready() -> void:
	connect('area_entered', self, '_on_Area2D_area_entered')

func _on_Area2D_area_entered(area: Area2D):
	if area.name == 'PlayerHurtableArea':
		area.get_hurt()
