@tool
class_name TestAnim2
extends UiAnimation


func play(time: float) -> Dictionary[Script, Variant]:
	return {
		UiAnimatedPropertyRotation: PI * (1.0 - time),
		UiAnimatedPropertyScale: Vector2(time, time),
	}
