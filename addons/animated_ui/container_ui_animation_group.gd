@tool
class_name ContainerUiAnimationGroup
extends AnimatedUiSimpleContaier

signal wait_finished
signal settings_modified

var handler := UiAnimationGroupHandler.new(self)

@export var animated_visible: bool = true:
	set(value):
		if value:
			animated_show(true)
		else:
			animated_hide(true)
	get():
		return handler.animated_visible
@export var settings: UiAnimationGroupSettings:
	set(value):
		settings = value
		settings_modified.emit()
		if settings != null:
			settings.modified.connect(settings_modified.emit)


func animated_show(i_triggered_the_animation: bool = true) -> void:
	handler.animated_show(i_triggered_the_animation)


func animated_hide(i_triggered_the_animation: bool = true) -> void:
	handler.animated_hide(i_triggered_the_animation)
