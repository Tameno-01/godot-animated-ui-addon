@tool
class_name UiAnimatedPropertyScale
extends UiAnimatedProperty


static func apply(value: Variant, control: Control, _control_animator: ControlAnimator) -> void:
	control.scale = value


static func combine(value_a: Variant, value_b: Variant) -> Variant:
	return value_a * value_b
