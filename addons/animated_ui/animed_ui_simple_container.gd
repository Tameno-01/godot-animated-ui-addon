class_name AnimatedUiSimpleContaier
extends Container


func _get_minimum_size() -> Vector2:
	var control_child: Control = null
	for child in get_children():
		if child is Control:
			control_child = child
			break
	if not control_child:
		return Vector2.ZERO
	return control_child.get_minimum_size()


func _get_allowed_size_flags_horizontal() -> PackedInt32Array:
	return []


func _get_allowed_size_flags_vertical() -> PackedInt32Array:
	return []


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SORT_CHILDREN:
			var control_child: Control = null
			for child in get_children():
				if child is Control:
					control_child = child
					break
			if not control_child:
				return
			fit_child_in_rect(control_child, Rect2(Vector2.ZERO, control_child.get_minimum_size()))
