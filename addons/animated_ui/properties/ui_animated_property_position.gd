@tool
class_name UiAnimatedPropertyPosition
extends UiAnimatedProperty


static func combine(value_a: Variant, value_b: Variant) -> Variant:
	return value_a + value_b


static func apply(value: Variant, control: Control, _data: Variant) -> void:
	control.position = value


static func cleanup(control: Control, _data: Variant) -> void:
	control.position = Vector2.ZERO
