extends AnimationPlayer

signal trick_complete(name)

func grind() -> void:
	_show_trick_text('grind')
func kickflip() -> void:
	_show_trick_text('kickflip')
func kickflip_x2() -> void:
	_show_trick_text('kickflipX2')
func manual() -> void:
	_show_trick_text('manual')
func nose_manual() -> void:
	_show_trick_text('noseManual')
func ollie() -> void:
	_show_trick_text('ollie')
func spin_180() -> void:
	_show_trick_text('spin180')
func spin_360() -> void:
	_show_trick_text('spin360')
func spin_720() -> void:
	_show_trick_text('spin720')
func thread_needle() -> void:
	_show_trick_text('threadNeedle')

func _show_trick_text(animName: String) -> void:
	play('none')
	queue(animName)
	emit_signal('trick_complete', animName)
