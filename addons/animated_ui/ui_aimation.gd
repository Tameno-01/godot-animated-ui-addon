@tool
class_name UiAnimation
extends Resource


func play(time: float) -> Dictionary:
	return {}


func apply_property(
		property: StringName,
		value: Variant,
		control: Control,
		canvas_group: CanvasGroup,
) -> bool:
	match property:
		&"position":
			control.position = value
			return true
		&"rotation":
			control.rotation = value
			return true
		&"scale":
			control.scale = value
			return true
		&"modulate":
			if canvas_group == null:
				control.modulate = value
			else:
				canvas_group.self_modulate = value
			return true
	return false


func requires_canvas_group(property: StringName, value: Variant) -> bool:
	match property:
		&"modulate":
			if value.a < 1.0:
				return true
	return false


func combine_property(property: StringName, value_a: Variant, value_b: Variant) -> Variant:
	match property:
		&"position":
			return value_a + value_b
		&"rotation":
			return value_a + value_b
		&"scale":
			return value_a * value_b
		&"modulate":
			return value_a * value_b
		var unkown_property:
			push_error("(Animated Ui) Couldn't combine property \"%s\"" % unkown_property)
			return null
