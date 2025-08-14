@tool
class_name UiAnimatedPropertyModulate
extends UiAnimatedProperty


static func combine(value_a: Variant, value_b: Variant) -> Variant:
	return value_a * value_b


static func apply(value: Variant, control: Control, _data: Variant) -> void:
	var animator: ControlAnimator = control.get_parent()
	if animator.act_as_canvas_group:
		animator.self_modulate = value
	else:
		control.modulate = value


static func cleanup(control: Control, _data: Variant) -> void:
	var animator: ControlAnimator = control.get_parent()
	if animator.act_as_canvas_group:
		animator.self_modulate = Color.WHITE
	else:
		control.modulate = Color.WHITE
