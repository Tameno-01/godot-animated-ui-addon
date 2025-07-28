@tool
class_name UiAnimationLibray
extends Resource

signal modified

@export var constant: UiAnimationMetadata:
	set(value):
		constant = value
		modified.emit()
		if constant != null:
			constant.modified.connect(modified.emit)
@export var show: UiAnimationMetadata:
	set(value):
		show = value
		modified.emit()
		if show != null:
			show.modified.connect(modified.emit)
@export var hide: UiAnimationMetadata:
	set(value):
		hide = value
		modified.emit()
		if hide != null:
			hide.modified.connect(modified.emit)
@export var show_wait_time: float = -1.0:
	set(value):
		show_wait_time = value
		modified.emit()
@export var hide_wait_time: float = -1.0:
	set(value):
		hide_wait_time = value
		modified.emit()
