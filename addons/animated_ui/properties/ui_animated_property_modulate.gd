@tool
class_name UiAnimatedPropertyModulate
extends UiAnimatedProperty


static func apply(value: Variant, control: Control) -> void:
	control.modulate = value


static func combine(value_a: Variant, value_b: Variant) -> Variant:
	return value_a * value_b
