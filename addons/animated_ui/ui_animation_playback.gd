@tool
class_name UiAnimationPlayback
extends RefCounted

var animation: UiAnimation
var duration: float
var reverse: bool = false
var loop: bool = false
var progress: float


func start() -> void:
	progress = 1.0 if reverse else 0.0


# This function takes in a refernce to a dictionary and modifies said dictionary
# The boolean output is whether the animation finished or not
func play(properties: Dictionary[Script, Variant], delta: float) -> bool:
	if reverse:
		if progress == 0.0 and not loop:
			return true
		progress -= delta / duration
	else: # Not reverse.
		if progress == 1.0 and not loop:
			return true
		progress += delta / duration
	if loop:
		progress = fposmod(progress, duration)
	else:
		progress = clamp(progress, 0.0, 1.0)
	var anim_output: Dictionary[Script, Variant] = animation.play(progress)
	for property: Script in anim_output:
		if properties.has(property):
			properties[property] = property.combine(properties[property], anim_output[property])
		else:
			properties[property] = anim_output[property]
	return false


func duplicate_and_reverse() -> UiAnimationPlayback:
	var clone: UiAnimationPlayback = UiAnimationPlayback.new()
	clone.animation = animation
	clone.progress = progress
	clone.duration = duration
	clone.reverse = not reverse
	return clone
