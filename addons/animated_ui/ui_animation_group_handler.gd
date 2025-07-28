@tool
class_name UiAnimationGroupHandler
extends RefCounted

signal wait_finished

const DEFAULT_SHOW_ORDER := UiAnimationGroupSettings.GroupOrders.FORWARD
const DEFAULT_HIDE_ORDER := UiAnimationGroupSettings.GroupOrders.BACKWARD

var animated_visible: bool = true

var _node: Control
var _what_were_waiting_for: Control
var _currently_showing: bool
var _i_triggered_the_animation: bool = false
var _show_order: UiAnimationGroupSettings.GroupOrders
var _hide_order: UiAnimationGroupSettings.GroupOrders


func _init(node: Control) -> void:
	assert(node is UiAnimationGroup or node is ContainerUiAnimationGroup)
	_node = node
	_node.settings_modified.connect(settings_modified)
	wait_finished.connect(_node.wait_finished.emit)
	_update_settings_for_myself()


func settings_modified() -> void:
	_update_settings_recursive(_node)
	_update_settings_for_myself()


func animated_show(i_triggered_the_animation: bool) -> void:
	if animated_visible:
		return
	animated_visible = true
	_currently_showing = true
	_i_triggered_the_animation = i_triggered_the_animation
	prime_for_showing()
	_animate_as_next(_find_next_node_to_animate(_node, _currently_showing), _currently_showing)


func animated_hide(i_triggered_the_animation: bool) -> void:
	if not animated_visible:
		return
	animated_visible = false
	_currently_showing = false
	_i_triggered_the_animation = i_triggered_the_animation
	_animate_as_next(_find_next_node_to_animate(_node, _currently_showing), _currently_showing)


func what_were_waiting_for_finished() -> void:
	_animate_as_next(_find_next_node_to_animate(_node, _currently_showing), _currently_showing)


func prime_for_showing() -> void:
	_node.show()
	_prime_nodes_for_showing_recursive(_node)


func finish_hiding_recursive(node: Node):
	if node is UiAnimationGroup or node is ContainerUiAnimationGroup:
		node.hide()
	for child in node.get_children():
		if child is UiAnimationGroup or child is ContainerUiAnimationGroup:
			child.handler.finish_hiding_recursive(child)
			continue
		if node is ControlAnimator:
			node.finish_hiding_process()
		finish_hiding_recursive(child)


func _update_settings_for_myself() -> void:
	var settings_array: Array[UiAnimationGroupSettings] = []
	var node: Node = _node
	while node != null:
		if node is UiAnimationGroup or node is ContainerUiAnimationGroup:
			if node.settings != null:
				settings_array.append(node.settings)
		node = node.get_parent()
	_show_order = DEFAULT_SHOW_ORDER
	for settings in settings_array:
		if settings.show_order != UiAnimationGroupSettings.GroupOrders.INHERIT:
			_show_order = settings.show_order
			break
	_hide_order = DEFAULT_HIDE_ORDER
	for settings in settings_array:
		if settings.hide_order != UiAnimationGroupSettings.GroupOrders.INHERIT:
			_hide_order = settings.hide_order
			break


func _update_settings_recursive(p_node: Node) -> void:
	for child in p_node.get_children():
		if child is ControlAnimator:
			child.update_animation_library()
		if child is UiAnimationGroup or child is ContainerUiAnimationGroup:
			child.settings_modified.emit()
			return
		_update_settings_recursive(child)


func _prime_nodes_for_showing_recursive(node: Node) -> void:
	for child in node.get_children():
		if child is UiAnimationGroup or child is ContainerUiAnimationGroup:
			child.handler.prime_for_showing()
			continue
		if child is ControlAnimator:
			child.prime_for_showing()
		_prime_nodes_for_showing_recursive(child)


func _find_next_node_to_animate(node: Node, show: bool) -> Control:
	var children: Array[Node] = node.get_children()
	var order: UiAnimationGroupSettings.GroupOrders = _show_order if show else _hide_order
	if order == UiAnimationGroupSettings.GroupOrders.BACKWARD:
		children.reverse()
	for child in children:
		if (
				child is ControlAnimator
				or child is UiAnimationGroup
				or child is ContainerUiAnimationGroup
		):
			if child.animated_visible != show:
				return child
		var child_animator: Control = _find_next_node_to_animate(child, show)
		if child_animator != null:
			return child_animator
	return null


func _animate_as_next(node: Node, show: bool) -> void:
	if node == null:
		_finish_animating(show)
		return
	if _what_were_waiting_for != null:
		_what_were_waiting_for.wait_finished.disconnect(what_were_waiting_for_finished)
	_what_were_waiting_for = node
	_what_were_waiting_for.wait_finished.connect(what_were_waiting_for_finished)
	if (
			_what_were_waiting_for is UiAnimationGroup
			or _what_were_waiting_for is ContainerUiAnimationGroup
	):
		if show:
			_what_were_waiting_for.animated_show(false)
		else:
			_what_were_waiting_for.animated_hide(false)
	else:
		if show:
			_what_were_waiting_for.animated_show()
		else:
			_what_were_waiting_for.prime_for_hiding()
			_what_were_waiting_for.animated_hide()


func _finish_animating(showed: bool):
	wait_finished.emit()
	if _i_triggered_the_animation and not showed:
		finish_hiding_recursive(_node)
