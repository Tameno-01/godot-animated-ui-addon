@tool
class_name UiAnimatedProperty
extends Object


func _init() -> void:
	assert(false, "(Animated Ui) UiAnimatedProperty should never be instanciated.")


static func setup(_control: Control) -> Variant:
	return null


static func combine(_value_a: Variant, _value_b: Variant) -> Variant:
	return _value_b


static func apply(_value: Variant, _control: Control, _data: Variant) -> void:
	return


static func cleanup(_control: Control, _data: Variant) -> void:
	return
