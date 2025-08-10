@tool
class_name TestAnim3
extends UiAnimation


func play(time: float) -> Dictionary[Script, Variant]:
	return {
		UiAnimatedPropertyRotation: PI * (1.0 - time),
	}
