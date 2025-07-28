@tool
class_name ControlAnimator
extends AnimatedUiSimpleContaier

signal wait_finished

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
		animations = value
		update_animation_library()
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

var _animated_visible: bool = true
var _child: Control = null
var _animation_library: UiAnimationLibray = null:
	set(value):
		if _animation_library == value:
			return
		_animation_library = value
		_update_constant_animation_playback()
		if _animation_library != null:
			_animation_library.modified.connect(
					_update_constant_animation_playback
			)
var _constant_playback: UiAnimationPlayback
var _show_playback: UiAnimationPlayback = null
var _hide_playback: UiAnimationPlayback = null
var _primed_for_showing: bool = false
var _primed_for_hiding: bool = false
var _awaiting_hide_finish: bool = false
var _wait_time_left: float = 0

func _init() -> void:
	child_entered_tree.connect(_on_child_enter_tree)
	child_exiting_tree.connect(_on_child_exitig_tree)
	resized.connect(_update_child_properties)
	minimum_size_changed.connect(_update_child_properties)


func _ready() -> void:
	update_configuration_warnings()
	_update_canvas_group_mode()
	update_animation_library()


func _process(delta: float) -> void:
	var playbacks_to_play: Array[UiAnimationPlayback] = []
	if _constant_playback != null:
		playbacks_to_play.append(_constant_playback)
	if _show_playback != null:
		playbacks_to_play.append(_show_playback)
	if _hide_playback != null:
		playbacks_to_play.append(_hide_playback)
	var properties: Dictionary[GDScript, Variant] = {}
	for playback: UiAnimationPlayback in playbacks_to_play:
		var ended: bool = playback.play(properties, delta)
		if ended:
			if playback == _constant_playback:
				_constant_playback = null
			if playback == _show_playback:
				_show_playback = null
			if playback == _hide_playback:
				_hide_playback = null
				if _primed_for_hiding:
					_child.hide()
					_primed_for_hiding = false
					_awaiting_hide_finish = true
				else:
					hide()
	for property: GDScript in properties:
		property.apply(properties[property], _child, self)
	if _wait_time_left > 0:
		_wait_time_left -= delta
		if _wait_time_left <= 0:
			wait_finished.emit()


func animated_show() -> void:
	if animated_visible:
		return
	_animated_visible = true
	show()
	if _primed_for_showing:
		_child.show()
	_wait_time_left = _animation_library.show_wait_time
	_primed_for_hiding = false
	if _animation_library == null:
		return
	if _hide_playback != null:
		if _animation_library.hide == null:
			_show_playback = _hide_playback.duplicate_and_reverse()
			_hide_playback = null
			return
		_hide_playback = null
	if _animation_library.show == null:
		return
	_show_playback = UiAnimationPlayback.new()
	_show_playback.animation = _animation_library.show.animation
	_show_playback.duration = _animation_library.show.duration
	_show_playback.reverse =  _animation_library.show.reverse
	_show_playback.start()


func animated_hide() -> void:
	if not animated_visible:
		return
	_animated_visible = false
	_wait_time_left = _animation_library.hide_wait_time
	if _animation_library == null:
		hide()
		return
	if _show_playback != null:
		if _animation_library.hide == null:
			_hide_playback = _show_playback.duplicate_and_reverse()
			_show_playback = null
			return
		_show_playback = null
	_hide_playback = UiAnimationPlayback.new()
	if _animation_library.hide == null:
		_hide_playback.animation = _animation_library.show.animation
		_hide_playback.duration = _animation_library.show.duration
		_hide_playback.reverse = not _animation_library.show.reverse
	else: # Hide animation exists
		_hide_playback.animation = _animation_library.hide.animation
		_hide_playback.duration = _animation_library.hide.duration
		_hide_playback.reverse = _animation_library.hide.reverse
	_hide_playback.start()


func update_animation_library() -> void:
	# TODO: do inheritance per-animation
	if animations != null:
		_animation_library = animations
		return
	var node: Node = get_parent()
	while node != null:
		if (
				node is UiAnimationGroup or node is ContainerUiAnimationGroup
				and node.settings != null
				and node.settings.default_library != null
		):
			_animation_library = node.settings.default_library
			return
		node = node.get_parent()
	_animation_library = null


func prime_for_showing() -> void:
	if animated_visible:
		return
	show()
	_child.hide()
	_primed_for_showing = true


func un_prime_for_showing() -> void:
	if animated_visible:
		return
	hide()
	_child.show()
	_primed_for_showing = false


func prime_for_hiding() -> void:
	_primed_for_hiding = true


func finish_hiding_process() -> void:
	hide()
	_child.show()
	_primed_for_hiding = false
	_awaiting_hide_finish = false


func is_awaiting_hide_finish() -> bool:
	return _awaiting_hide_finish


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_EDITOR_PRE_SAVE:
			# TODO: make sure things are in a good state when saving
			pass


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


func _update_constant_animation_playback():
	if _animation_library == null:
		_constant_playback = null
		return
	if _animation_library.constant == null:
		_constant_playback = null
		return
	if _animation_library.constant.animation == null:
		_constant_playback = null
		return
	_constant_playback = UiAnimationPlayback.new()
	_constant_playback.animation = _animation_library.constant.animation
	_constant_playback.duration = _animation_library.constant.duration
	_constant_playback.reverse = _animation_library.constant.reverse
	_constant_playback.loop = true
	_constant_playback.start()


func _update_child(new_child: Control) -> void:
	if _child != null:
		_child.resized.disconnect(_update_child_properties)
		_child.minimum_size_changed.disconnect(_update_child_properties)
	_child = new_child
	if _child != null:
		_child.resized.connect(_update_child_properties)
		_child.minimum_size_changed.connect(_update_child_properties)
		_update_child_properties()


func _update_child_properties() -> void: pass
	#if _child == null:
		#return
	#size = _child.size
	#custom_minimum_size = _child.get_minimum_size()
	#await get_tree().process_frame
	#_child.size = size


func _on_child_enter_tree(node: Node) -> void:
	if get_child_count() == 1:
		_update_child(node)
	update_configuration_warnings()


func _on_child_exitig_tree(node: Node) -> void:
	if node == _child:
		if get_child_count() == 0:
			_update_child(null)
		else:
			_update_child(get_child(0))
	update_configuration_warnings()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if get_child_count(true) != 1:
		warnings.append("AnimatedControl nodes must have exactly 1 child.")
	elif not (get_child(0, true) is Control):
		warnings.append("Child of AnimatedControl must be a Control node.")
	return warnings
