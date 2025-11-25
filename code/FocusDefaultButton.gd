extends Button

export var nextFocusControlNP : NodePath

onready var nextFocusControl : Control = get_node(nextFocusControlNP)

func focus_on_default():
	if 0 < Input.get_connected_joypads().size() and is_instance_valid(nextFocusControl):
		nextFocusControl.grab_focus()
	else:
		grab_focus()
