@tool
class_name UiAnimationLibray
extends Resource

signal constant_animation_changed

@export var constant: UiAnimationMetadata:
	set(value):
		constant = value
		constant_animation_changed.emit(constant)
		constant.modified.connect(constant_animation_changed.emit)
@export var show: UiAnimationMetadata
@export var hide: UiAnimationMetadata
