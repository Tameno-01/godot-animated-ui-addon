@tool
class_name TestAnim1
extends UiAnimation


@export var distance: float = -100.0


func play(time: float) -> Dictionary[Script, Variant]:
	return {
		UiAnimatedPropertyPosition: Vector2((1.0 - time) * distance, 0.0),
		UiAnimatedPropertyModulate: Color(1.0, 1.0, 1.0, time),
	}
