@tool
class_name UiAnimatedPropertyPosition
extends UiAnimatedProperty


static func apply(value: Variant, control: Control, _control_animator: ControlAnimator) -> void:
	control.position = value


static func combine(value_a: Variant, value_b: Variant) -> Variant:
	return value_a + value_b
