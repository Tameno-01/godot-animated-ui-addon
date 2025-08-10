@tool
class_name AnimatedUiSimpleContaier
extends Container

var active_child: Control = null


func _init() -> void:
	child_entered_tree.connect(_update_active_child.unbind(1))
	child_exiting_tree.connect(_update_active_child.unbind(1))
	child_order_changed.connect(_update_active_child)
	resized.connect(_on_resized)


func _get_minimum_size() -> Vector2:
	return active_child.get_minimum_size() if active_child != null else Vector2.ZERO


func _get_allowed_size_flags_horizontal() -> PackedInt32Array:
	return []


func _get_allowed_size_flags_vertical() -> PackedInt32Array:
	return []


func _on_resized() -> void:
	active_child.size = size


func _update_active_child() -> void:
	update_configuration_warnings()
	var new_active_child: Control = _get_active_child()
	if active_child == new_active_child:
		return
	active_child = new_active_child
	if active_child != null:
		active_child.set_rotation.call_deferred(0.0)
		active_child.set_scale.call_deferred(Vector2.ONE)
		active_child.set_position.call_deferred(Vector2.ZERO)
		active_child.set_size.call_deferred(size)


func _get_active_child() -> Control:
	if get_child_count() == 0:
		return null
	var first_child: Node = get_child(0)
	if first_child is Control:
		return first_child
	else:
		return null


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if get_child_count() != 1:
		warnings.append("This node must have exactly 1 child.")
	elif not (get_child(0) is Control):
		warnings.append("This of node's child must be a Control node.")
	return warnings
