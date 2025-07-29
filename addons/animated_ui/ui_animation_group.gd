@tool
class_name UiAnimationGroup
extends Control

@warning_ignore_start("unused_signal")
signal wait_finished
signal fully_shown
signal fully_hidden
signal settings_modified
@warning_ignore_restore("unused_signal")

var handler := UiAnimationGroupHandler.new(self)
var inherited_animated_visible: bool = true:
	set(value):
		handler.inherited_animated_visible = value
	get():
		return handler.inherited_animated_visible

@export var animated_visible: bool = true:
	set(value):
		if value:
			animated_show()
		else:
			animated_hide()
	get():
		return handler.animated_visible
@export var settings: UiAnimationGroupSettings:
	set(value):
		settings = value
		settings_modified.emit()
		if settings != null:
			settings.modified.connect(settings_modified.emit)


func animated_show() -> void:
	handler.animated_show()


func animated_hide() -> void:
	handler.animated_hide()


func is_actually_visible() -> bool:
	return handler.actual_animated_visible
