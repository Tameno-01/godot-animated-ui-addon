class_name UiAnimationPlayback
extends RefCounted

var animation: UiAnimation
var duration: float
var reverse: bool
var progress: float


# This function takes in a refernce to a dictionary and modifies said dictionary
# The boolean output is whether the animation finished or not
func play(properties: Dictionary[GDScript, Variant], delta: float) -> bool:
	if reverse:
		if progress == 0.0:
			return true
		progress -= delta / duration
	else: # Not reverse.
		if progress == 1.0:
			return true
		progress += delta / duration
	progress = clamp(progress, 0.0, 1.0)
	var anim_output: Dictionary[GDScript, Variant] = animation.play(progress)
	for property: GDScript in anim_output:
		if properties.has(property):
			properties[property] = property.combine(properties[property], anim_output[property])
		else:
			properties[property] = anim_output[property]
	return false


func duplicate_and_reverse() -> UiAnimationPlayback:
	var clone = UiAnimationPlayback.new()
	clone.animation = animation
	clone.progress = progress
	clone.duration = duration
	clone.reverse = not reverse
	return clone
