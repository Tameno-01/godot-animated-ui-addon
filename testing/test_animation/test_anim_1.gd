@tool
class_name TestAnim1
extends UiAnimation


func play(time: float) -> Dictionary[Script, Variant]:
	return {
		UiAnimatedPropertyPosition: Vector2((1.0 - time) * -40, 0.0),
		UiAnimatedPropertyModulate: Color(1.0, 1.0, 1.0, time),
	}
