@tool
class_name UiAnimatedPropertyRotation
extends UiAnimatedProperty


static func apply(value: Variant, control: Control, _control_animator: ControlAnimator) -> void:
	control.rotation = value


static func combine(value_a: Variant, value_b: Variant) -> Variant:
	return value_a + value_b
