@tool
class_name UiAnimationGroupHandler
extends RefCounted

signal wait_finished

const DEFAULT_SHOW_ORDER := UiAnimationGroupSettings.GroupOrders.FORWARD
const DEFAULT_HIDE_ORDER := UiAnimationGroupSettings.GroupOrders.BACKWARD

var animated_visible: bool = true
var inherited_animated_visible: bool = true:
	set(value):
		inherited_animated_visible = value
		var should_be_visible: bool = _should_be_visible()
		if actual_animated_visible != should_be_visible:
			if should_be_visible:
				_actual_animated_show(false)
			else:
				_actual_animated_hide(false)
var actual_animated_visible: bool = true

var _node: Control
var _what_were_waiting_for: Control = null
var _currently_showing: bool
var _i_triggered_the_animation: bool = false
var _hiding_animators: Array[Control] = []
var _show_order: UiAnimationGroupSettings.GroupOrders
var _hide_order: UiAnimationGroupSettings.GroupOrders


func _init(node: Control) -> void:
	assert(node is UiAnimationGroup or node is ContainerUiAnimationGroup)
	_node = node
	_node.settings_modified.connect(settings_modified)
	wait_finished.connect(_node.wait_finished.emit)
	_update_settings_for_myself()


func animated_show() -> void:
	if animated_visible:
		return
	animated_visible = true
	if actual_animated_visible != _should_be_visible():
		_actual_animated_show(true)


func animated_hide() -> void:
	if not animated_visible:
		return
	animated_visible = false
	if actual_animated_visible != _should_be_visible():
		_actual_animated_hide(true)


func settings_modified() -> void:
	_update_settings_recursive(_node)
	_update_settings_for_myself()


func what_were_waiting_for_finished() -> void:
	_animate_as_next(_find_next_node_to_animate(_node, _currently_showing), _currently_showing)


func prime_for_showing() -> void:
	if not animated_visible:
		return
	_node.show()
	_prime_nodes_for_showing_recursive(_node)


func finish_hiding_recursive(node: Node) -> void:
	if node is UiAnimationGroup or node is ContainerUiAnimationGroup:
		node.hide()
	for child in node.get_children():
		if child is UiAnimationGroup or child is ContainerUiAnimationGroup:
			child.handler.finish_hiding_recursive(child)
			continue
		if node is ControlAnimator:
			node.finish_hiding_process()
		finish_hiding_recursive(child)


func animator_started_hiding(animator: Control) -> void:
	_hiding_animators.append(animator)


func animator_finsihed_hiding(animator: Control) -> void:
	_hiding_animators.erase(animator)
	if (
		_hiding_animators.is_empty()
		and _what_were_waiting_for == null
		and not _should_be_visible()
	):
		if _i_triggered_the_animation:
			finish_hiding_recursive(_node)
		var group: Control = _get_animation_group()
		if group != null:
			group.handler.animator_finsihed_hiding(_node)
		_node.fully_hidden.emit()


func animator_interrupted_hiding(animator: Control) -> void:
	_hiding_animators.erase(animator)


func _actual_animated_show(i_triggered_the_animation: bool) -> void:
	if actual_animated_visible:
		return
	actual_animated_visible = true
	if not _currently_showing:
		_currently_showing = true
		var group: Control = _get_animation_group()
		if group != null:
			group.handler.animator_interrupted_hiding(_node)
	_i_triggered_the_animation = i_triggered_the_animation
	prime_for_showing()
	_animate_as_next(_find_next_node_to_animate(_node, _currently_showing), _currently_showing)


func _actual_animated_hide(i_triggered_the_animation: bool) -> void:
	if not actual_animated_visible:
		return
	actual_animated_visible = false
	_currently_showing = false
	_i_triggered_the_animation = i_triggered_the_animation
	var group: Control = _get_animation_group()
	if group != null:
		group.handler.animator_started_hiding(_node)
	_animate_as_next(_find_next_node_to_animate(_node, _currently_showing), _currently_showing)


func _should_be_visible() -> bool:
	return animated_visible and inherited_animated_visible


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


func _update_settings_recursive(p_node: CanvasItem) -> void:
	for child in p_node.get_children():
		if not (child is CanvasItem):
			continue
		if child is ControlAnimator:
			child.update_animation_library()
		if child is UiAnimationGroup or child is ContainerUiAnimationGroup:
			child.settings_modified.emit()
			continue
		_update_settings_recursive(child)


func _prime_nodes_for_showing_recursive(node: CanvasItem) -> void:
	for child in node.get_children():
		if not (child is CanvasItem):
			continue
		if child is UiAnimationGroup or child is ContainerUiAnimationGroup:
			child.handler.prime_for_showing()
			continue
		if child is ControlAnimator:
			child.prime_for_showing()
		_prime_nodes_for_showing_recursive(child)


func _find_next_node_to_animate(node: CanvasItem, show: bool) -> Control:
	var children: Array[Node] = node.get_children()
	var order: UiAnimationGroupSettings.GroupOrders = _show_order if show else _hide_order
	if order == UiAnimationGroupSettings.GroupOrders.BACKWARD:
		children.reverse()
	for child in children:
		if not (child is CanvasItem):
			continue
		if (
			child is ControlAnimator
			or child is UiAnimationGroup
			or child is ContainerUiAnimationGroup
		):
			if child.is_actually_visible() != show and child.animated_visible:
				return child
		if (child is UiAnimationGroup or child is ContainerUiAnimationGroup):
			continue
		var child_animator: Control = _find_next_node_to_animate(child, show)
		if child_animator != null:
			return child_animator
	return null


func _animate_as_next(node: Control, show: bool) -> void:
	if _what_were_waiting_for != null:
		_what_were_waiting_for.wait_finished.disconnect(what_were_waiting_for_finished)
	if node == null:
		_what_were_waiting_for = null
		wait_finished.emit()
		return
	_what_were_waiting_for = node
	_what_were_waiting_for.wait_finished.connect(what_were_waiting_for_finished)
	if not show:
		if _what_were_waiting_for is ControlAnimator:
			_what_were_waiting_for.prime_for_hiding()
	_what_were_waiting_for.inherited_animated_visible = show


func _get_animation_group() -> Control:
	var parent: Node = _node.get_parent()
	while parent != null:
		if (
			parent is UiAnimationGroup
			or parent is ContainerUiAnimationGroup
		):
			return parent
		parent = parent.get_parent()
	return null
