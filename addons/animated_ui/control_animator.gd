@tool
class_name ControlAnimator
extends AnimatedUiSimpleContaier

signal wait_finished
signal fully_shown
signal fully_hidden

const DEFAULT_WAIT_TIME: float = 0.05
const DEFAULT_HIDE_MODE: UiAnimationLibray.HideModes = UiAnimationLibray.HideModes.INTERRUPT

var inherited_animated_visible: bool = true:
	set(value):
		inherited_animated_visible = value
		var should_be_visible: bool = _should_be_visible()
		if _actual_animated_visible != should_be_visible:
			if should_be_visible:
				_actual_animated_show()
			else:
				_actual_animated_hide()

@export var animated_visible: bool = true:
	set(value):
		if value:
			animated_show()
		else:
			animated_hide()
	get():
		return _animated_visible
@export var animations: UiAnimationLibray = null:
	set(value):
		if animations != null:
			animations.modified.disconnect(update_animation_library)
		animations = value
		update_animation_library()
		if animations != null:
			animations.modified.connect(update_animation_library)
@export_group("Canvas Group")
@export var act_as_canvas_group: bool = false:
	set(value):
		act_as_canvas_group = value
		_update_canvas_group_mode()
@export var clear_margin: float = 10.0:
	set(value):
		clear_margin = value
		_update_canvas_group_mode()
@export var fit_margin: float = 10.0:
	set(value):
		fit_margin = value
		_update_canvas_group_mode()
@export var blur_mipmaps: bool = false:
	set(value):
		blur_mipmaps = value
		_update_canvas_group_mode()

var _constant_anim: UiAnimationMetadata = null
var _show_anim: UiAnimationMetadata = null
var _hide_mode: UiAnimationLibray.HideModes
var _hide_anim: UiAnimationMetadata = null
var _show_wait_time: float = DEFAULT_WAIT_TIME
var _hide_wait_time: float = DEFAULT_WAIT_TIME

var _animated_visible: bool = true
var _actual_animated_visible: bool = true
var _constant_playback: UiAnimationPlayback
var _show_playback: UiAnimationPlayback = null
var _hide_playback: UiAnimationPlayback = null
var _primed_for_showing: bool = false
var _primed_for_hiding: bool = false
var _awaiting_hide_finish: bool = false
var _wait_time_left: float = 0
var _active_properties: Dictionary[Script, Variant] = {}


func _ready() -> void:
	_update_canvas_group_mode()
	update_animation_library()


func _process(delta: float) -> void:
	_animate(delta)
	if _wait_time_left > 0:
		_wait_time_left -= delta
		if _wait_time_left <= 0:
			wait_finished.emit()


func animated_show() -> void:
	if _animated_visible:
		return
	_animated_visible = true
	if _actual_animated_visible != _should_be_visible():
		_actual_animated_show()


func animated_hide() -> void:
	if not _animated_visible:
		return
	_animated_visible = false
	if _actual_animated_visible != _should_be_visible():
		_actual_animated_hide()


func is_actually_visible() -> bool:
	return _actual_animated_visible


func update_animation_library() -> void:
	var library_array: Array[UiAnimationLibray] = []
	if animations != null:
		library_array.append(animations)
	var node: Node = get_parent()
	while node != null:
		if (
			node is UiAnimationGroup or node is ContainerUiAnimationGroup
			and node.settings != null
			and node.settings.default_library != null
		):
			library_array.append(node.settings.default_library)
		node = node.get_parent()
	var prev_constant_anim: UiAnimationMetadata = _constant_anim
	_constant_anim = null
	for library in library_array:
		if library.constant != null:
			_constant_anim = library.constant
			break
	if _constant_anim != prev_constant_anim:
		_update_constant_animation_playback()
		if prev_constant_anim != null:
			prev_constant_anim.modified.disconnect(_update_constant_animation_playback)
		if _constant_anim != null:
			_constant_anim.modified.connect(_update_constant_animation_playback)
	_show_anim = null
	for library in library_array:
		if library.show != null:
			_show_anim = library.show
			break
	_hide_anim = null
	for library in library_array:
		if library.hide != null:
			_hide_anim = library.hide
			break
	_hide_mode = DEFAULT_HIDE_MODE
	for library in library_array:
		if library.hide_mode != UiAnimationLibray.HideModes.INHERIT:
			_hide_mode = library.hide_mode
			break
	_show_wait_time = DEFAULT_WAIT_TIME
	for library in library_array:
		if library.show_wait_time >= 0:
			_show_wait_time = library.show_wait_time
			break
	_hide_wait_time = DEFAULT_WAIT_TIME
	for library in library_array:
		if library.hide_wait_time >= 0:
			_hide_wait_time = library.hide_wait_time
			break


func prime_for_showing() -> void:
	if is_technically_visible() or not animated_visible:
		return
	show()
	active_child.hide()
	_primed_for_showing = true


func prime_for_hiding() -> void:
	_primed_for_hiding = true


func finish_hiding_process() -> void:
	hide()
	active_child.show()
	_primed_for_hiding = false
	_awaiting_hide_finish = false


func is_awaiting_hide_finish() -> bool:
	return _awaiting_hide_finish


func is_technically_visible() -> bool:
	if not active_child:
		return false
	return visible and active_child.visible


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_EDITOR_PRE_SAVE:
			# TODO: make sure things are in a good state when saving
			pass


func _actual_animated_show() -> void:
	if _actual_animated_visible:
		return
	_actual_animated_visible = true
	if not _animated_visible:
		return
	show()
	if _primed_for_showing:
		active_child.show()
	_wait_time_left = _show_wait_time
	_primed_for_hiding = false
	if _hide_playback != null:
		var group: Control = _get_animation_group()
		if group != null:
			group.handler.animator_interrupted_hiding(self)
		match _hide_mode:
			UiAnimationLibray.HideModes.SHOW_IN_REVERSE:
				_show_playback = _hide_playback.duplicate_and_reverse()
				_hide_playback = null
				_animate(0.0)
				return
			UiAnimationLibray.HideModes.LAYER:
				pass
			UiAnimationLibray.HideModes.INTERRUPT:
				_hide_playback = null
	if _show_anim == null:
		return
	_show_playback = UiAnimationPlayback.new()
	_show_playback.animation = _show_anim.animation
	_show_playback.duration = _show_anim.duration
	_show_playback.reverse =  _show_anim.reverse
	_show_playback.start()
	_animate(0.0)


func _actual_animated_hide() -> void:
	if not _actual_animated_visible:
		return
	_actual_animated_visible = false
	_wait_time_left = _hide_wait_time
	var group: Control = _get_animation_group()
	if group != null:
		group.handler.animator_started_hiding(self)
	if _show_playback != null:
		match _hide_mode:
			UiAnimationLibray.HideModes.SHOW_IN_REVERSE:
				_hide_playback = _show_playback.duplicate_and_reverse()
				_show_playback = null
				_animate(0.0)
				return
			UiAnimationLibray.HideModes.LAYER:
				pass
			UiAnimationLibray.HideModes.INTERRUPT:
				_show_playback = null
	var new_hide_playback: UiAnimationPlayback = UiAnimationPlayback.new()
	if _hide_mode == UiAnimationLibray.HideModes.SHOW_IN_REVERSE:
		if _show_anim == null:
			_finish_hiding()
			return
		new_hide_playback.animation = _show_anim.animation
		new_hide_playback.duration = _show_anim.duration
		new_hide_playback.reverse = not _show_anim.reverse
	else: # We don't need to use the show aniation
		if _hide_anim == null:
			_finish_hiding()
			return
		new_hide_playback.animation = _hide_anim.animation
		new_hide_playback.duration = _hide_anim.duration
		new_hide_playback.reverse = _hide_anim.reverse
	_hide_playback = new_hide_playback
	_hide_playback.start()
	_animate(0.0)


func _animate(delta: float) -> void:
	var playbacks_to_play: Array[UiAnimationPlayback] = []
	if _constant_playback != null:
		playbacks_to_play.append(_constant_playback)
	if _show_playback != null:
		playbacks_to_play.append(_show_playback)
	if _hide_playback != null:
		playbacks_to_play.append(_hide_playback)
	var properties: Dictionary[Script, Variant] = {}
	for playback: UiAnimationPlayback in playbacks_to_play:
		var ended: bool = playback.play(properties, delta)
		if ended:
			if playback == _show_playback and _actual_animated_visible:
				_show_playback = null
				fully_shown.emit()
			if playback == _hide_playback and not _actual_animated_visible:
				_hide_playback = null
				_finish_hiding()
	var unused_properties: Array[Script] = _active_properties.keys()
	for property in properties:
		if _active_properties.has(property):
			unused_properties.erase(property)
		else:
			_active_properties[property] = property.setup(active_child)
		property.apply(properties[property], active_child, _active_properties[property])
	for property in unused_properties:
		property.cleanup(active_child, _active_properties[property])


func _should_be_visible() -> bool:
	return _animated_visible and inherited_animated_visible


func _finish_hiding() -> void:
	if _primed_for_hiding:
		active_child.hide()
		_primed_for_hiding = false
		_awaiting_hide_finish = true
	else:
		hide()
	var group: Control = _get_animation_group()
	if group != null:
		group.handler.animator_finsihed_hiding(self)
	fully_hidden.emit()


func _update_canvas_group_mode() -> void:
	if act_as_canvas_group:
		RenderingServer.canvas_item_set_canvas_group_mode(
			get_canvas_item(),
			RenderingServer.CANVAS_GROUP_MODE_TRANSPARENT,
			clear_margin,
			true,
			fit_margin,
			blur_mipmaps
		)
	else:
		RenderingServer.canvas_item_set_canvas_group_mode(
			get_canvas_item(),
			RenderingServer.CANVAS_GROUP_MODE_DISABLED
		)


func _update_constant_animation_playback() -> void:
	if _constant_anim == null:
		_constant_playback = null
		return
	if _constant_anim.animation == null:
		_constant_playback = null
		return
	_constant_playback = UiAnimationPlayback.new()
	_constant_playback.animation = _constant_anim.animation
	_constant_playback.duration = _constant_anim.duration
	_constant_playback.reverse = _constant_anim.reverse
	_constant_playback.loop = true
	_constant_playback.start()


func _get_animation_group() -> Control:
	var parent: Node = get_parent()
	while parent != null:
		if (
			parent is UiAnimationGroup
			or parent is ContainerUiAnimationGroup
		):
			return parent
		parent = parent.get_parent()
	return null
