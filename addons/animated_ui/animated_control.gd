@tool
class_name AnimatedControl
extends Control

var _animated_visible: bool = true
var _child: Control = null
var _animation_library: UiAnimationLibray = null
var _show_playback: UiAnimationPlayback = null
var _hide_playback: UiAnimationPlayback = null

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
		_update_animation_library()


func _init() -> void:
	child_entered_tree.connect(_on_child_enter_tree)
	child_exiting_tree.connect(_on_child_exitig_tree)


func _ready() -> void:
	update_configuration_warnings()


func _process(delta: float) -> void:
	var playbacks_to_play: Array[UiAnimationPlayback] = []
	if _show_playback != null:
		playbacks_to_play.append(_show_playback)
	if _hide_playback != null:
		playbacks_to_play.append(_hide_playback)
	var properties: Dictionary[GDScript, Variant] = {}
	for playback: UiAnimationPlayback in playbacks_to_play:
		var ended: bool = playback.play(properties, delta)
		if ended:
			if playback == _show_playback:
				_show_playback = null
			if playback == _hide_playback:
				_hide_playback = null
				hide()
	for property: GDScript in properties:
		property.apply(properties[property], _child)


func animated_show() -> void:
	if animated_visible:
		return
	_animated_visible = true
	show()
	if _animation_library == null:
		return
	if _hide_playback != null:
		if _animation_library.hide == null:
			_show_playback = _hide_playback.duplicate_and_reverse()
			_hide_playback = null
			return
		_hide_playback = null
	_show_playback = UiAnimationPlayback.new()
	_show_playback.animation = _animation_library.show.animation
	_show_playback.duration = _animation_library.show.duration
	_show_playback.reverse =  _animation_library.show.reverse
	if _show_playback.reverse:
		_show_playback.progress = 1.0
	else:
		_show_playback.progress = 0.0


func animated_hide() -> void:
	if not animated_visible:
		return
	_animated_visible = false
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
	if _hide_playback.reverse:
		_hide_playback.progress = 1.0
	else:
		_hide_playback.progress = 0.0


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_EDITOR_PRE_SAVE:
			# TODO: make sure things are in a good state when saving
			pass


func _update_child(new_child: Control) -> void:
	if _child != null:
		_child.resized.disconnect(_update_child_properties)
		_child.minimum_size_changed.disconnect(_update_child_properties)
	_child = new_child
	if _child != null:
		_child.resized.connect(_update_child_properties)
		_child.minimum_size_changed.connect(_update_child_properties)
		_update_child_properties()


func _update_child_properties() -> void:
	size = _child.size
	custom_minimum_size = _child.get_minimum_size()


func _update_animation_library() -> void:
	# TODO: check parents until an animation library is found
	_animation_library = animations


func _on_child_enter_tree(node: Node) -> void:
	if get_child_count(true) == 1:
		_update_child(node)
	update_configuration_warnings()


func _on_child_exitig_tree(node: Node) -> void:
	if node == _child:
		_update_child(null)
	update_configuration_warnings()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if get_child_count(true) != 1:
		warnings.append("AnimatedControl nodes must have exactly 1 child.")
	elif not (get_child(0, true) is Control):
		warnings.append("Child of AnimatedControl must be a Control node.")
	return warnings
