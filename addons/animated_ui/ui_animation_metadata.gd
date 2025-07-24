@tool
class_name UiAnimationMetadata
extends Resource

signal modified

@export var animation: UiAnimation:
	set(value):
		animation = value
		modified.emit()
@export var duration: float = 0.2:
	set(value):
		duration = value
		modified.emit()
@export var reverse: bool = false:
	set(value):
		reverse = value
		modified.emit()
