@tool
class_name UiAnimatedProperty
extends Object


func _init() -> void:
	assert(false, "(Animated Ui) UiAnimatedProperty should never be instanciated.")


static func apply(_value: Variant, _control: Control, _animator: ControlAnimator) -> void:
	return


static func combine(_value_a: Variant, _value_b: Variant) -> Variant:
	assert(false, "(Animated Ui) Combine function not defined.")
	return null
