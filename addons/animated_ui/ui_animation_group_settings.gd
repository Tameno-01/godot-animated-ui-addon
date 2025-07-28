@tool
class_name UiAnimationGroupSettings
extends Resource

enum GroupOrders {
	INHERIT,
	FORWARD,
	BACKWARD,
	RANDOM,
}

signal modified

@export var default_library: UiAnimationLibray:
	set(value):
		default_library = value
		modified.emit()
		if default_library != null:
			default_library.modified.connect(modified.emit)
@export var show_order: GroupOrders = GroupOrders.INHERIT:
	set(value):
		show_order = value
		modified.emit()
@export var hide_order: GroupOrders = GroupOrders.INHERIT:
	set(value):
		hide_order = value
		modified.emit()
