class_name CameraRig
extends Node3D
## Orbit camera: drag to rotate (mouse or touch), wheel/pinch to zoom. It does not move on its own.

var yaw := 0.6
var pitch := 0.5
var dist := 27.0
var idle := 0.0
var auto_orbit := false  # the view stays where you put it
var _cam: Camera3D
var _dragging := false
var _touches := {}
var _pinch_d := 0.0
# optional focus (the winners' celebration): the rig glides to the point and the
# auto-zoom tightens; a user who is dragging or pinching keeps their own zoom
var home := Vector3(0, 1.0, 1.0)   # where the view rests: the middle of the dancers
var _focus := Vector3(0, 1.0, 1.0)
var _focus_target := Vector3(0, 1.0, 1.0)
var _focus_dist := -1.0
var _rest_dist := 27.0  # the zoom the user last chose; the view returns to it after a celebration


func _ready() -> void:
	_cam = Camera3D.new()
	_cam.fov = 60.0
	_cam.keep_aspect = Camera3D.KEEP_WIDTH  # portrait phones see the whole arena too
	_cam.far = 300.0
	add_child(_cam)
	_apply()


func _process(delta: float) -> void:
	idle += delta
	if auto_orbit and idle > 6.0:
		yaw += delta * 0.05
	var k := clampf(delta * 2.0, 0.0, 1.0)
	_focus = _focus.lerp(_focus_target, k)
	if _focus_dist > 0.0 and idle > 6.0:
		dist = lerpf(dist, _focus_dist, k)
	_apply()


func camera_basis() -> Basis:
	return _cam.global_transform.basis


func set_focus(point: Vector3, want_dist: float = -1.0) -> void:
	_focus_target = Vector3(point.x, 1.0, point.z)
	_focus_dist = want_dist


func clear_focus() -> void:
	_focus_target = home
	_focus_dist = _rest_dist if absf(dist - _rest_dist) > 0.5 else -1.0


## Pull back (or in) until every point sits inside `free`, a rectangle in fractions of the screen
## (0..1 each way): the part the HUD leaves clear. A binary search on the distance.
func fit(points: Array, free: Rect2, loose_points: Array = [], loose := Rect2(0.02, 0.02, 0.96, 0.96)) -> void:
	if _cam == null or not is_inside_tree():
		return
	var vp := get_viewport().get_visible_rect().size
	if vp.x <= 0.0 or vp.y <= 0.0:
		return
	_focus = home
	_focus_target = home
	var lo := 6.0
	var hi := 90.0
	for i in 20:
		dist = (lo + hi) * 0.5
		_apply()
		var ok := true
		for pt in points:
			var p3: Vector3 = pt
			if _cam.is_position_behind(p3):
				ok = false
				break
			var s := _cam.unproject_position(p3) / vp
			if not free.has_point(s):
				ok = false
				break
		if ok:
			for pt in loose_points:
				var q3: Vector3 = pt
				if _cam.is_position_behind(q3) or not loose.has_point(_cam.unproject_position(q3) / vp):
					ok = false
					break
		if ok:
			hi = dist
		else:
			lo = dist
	dist = hi
	_rest_dist = dist
	_focus_dist = -1.0
	idle = 0.0
	_apply()


func _apply() -> void:
	pitch = clampf(pitch, 0.15, 1.45)
	dist = clampf(dist, 6.0, 90.0)
	var p := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * dist
	_cam.position = _focus + p
	_cam.look_at(_focus, Vector3.UP)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			_dragging = event.pressed
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			dist *= 0.9
			_rest_dist = clampf(dist, 10.0, 70.0)
			idle = 0.0
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			dist *= 1.1
			_rest_dist = clampf(dist, 10.0, 70.0)
			idle = 0.0
	elif event is InputEventMouseMotion and _dragging:
		yaw -= event.relative.x * 0.006
		pitch += event.relative.y * 0.006
		idle = 0.0
	elif event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = event.position
		else:
			_touches.erase(event.index)
		if _touches.size() == 2:
			var pts := _touches.values()
			_pinch_d = pts[0].distance_to(pts[1])
	elif event is InputEventScreenDrag:
		_touches[event.index] = event.position
		if _touches.size() == 1:
			yaw -= event.relative.x * 0.008
			pitch += event.relative.y * 0.008
		elif _touches.size() == 2:
			var pts := _touches.values()
			var d: float = pts[0].distance_to(pts[1])
			if _pinch_d > 0.0:
				dist *= _pinch_d / maxf(d, 1.0)
				_rest_dist = clampf(dist, 10.0, 70.0)
			_pinch_d = d
		idle = 0.0
