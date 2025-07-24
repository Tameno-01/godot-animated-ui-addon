@tool
class_name UiAnimatedPropertyModulate
extends UiAnimatedProperty


static func apply(value: Variant, control: Control, _control_animator: ControlAnimator) -> void:
	if _control_animator.act_as_canvas_group:
		_control_animator.self_modulate = value
	else:
		control.modulate = value


static func combine(value_a: Variant, value_b: Variant) -> Variant:
	return value_a * value_b
