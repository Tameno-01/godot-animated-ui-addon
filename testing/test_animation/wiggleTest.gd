@tool
class_name WiggleTest
extends UiAnimation


@export var rotation_amplitude: float = 0.1
@export var position_amplitude: Vector2 = Vector2(5.0, 0.0)


func play(time: float) -> Dictionary[GDScript, Variant]:
	return {
		UiAnimatedPropertyPosition: position_amplitude * sin(time * TAU),
		UiAnimatedPropertyRotation: cos(time * TAU) * rotation_amplitude,
	}
