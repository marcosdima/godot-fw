extends RefCounted
class_name UIScreen


## Root element of the screen.
var root: UIElement

## Optional selection group that navigates the screen's buttons. Null for
## screens without keyboard navigation.
var group: SelectionGroup

## Playbacks started when the screen becomes current.
var playbacks: Array[UIAnimationPlayback] = []