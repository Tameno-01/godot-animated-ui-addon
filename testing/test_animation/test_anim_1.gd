@tool
class_name TestAnim1
extends UiAnimation


@export var distance: float = -100.0


func play(time: float) -> Dictionary:
	var position: Vector2 = Vector2((1.0 - time) * distance, 0.0)
	var modulate: Color = Color.WHITE
	modulate.a = time
	return {
		&"position": position,
		&"modulate": modulate,
	}
