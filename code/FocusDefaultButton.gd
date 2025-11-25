extends Button

export var nextFocusControlNP : NodePath

onready var nextFocusControl : Control = get_node(nextFocusControlNP)

func focus_on_default():
	if Global.check_is_controller_connected() and is_instance_valid(nextFocusControl):
		nextFocusControl.grab_focus()
	else:
		grab_focus()
