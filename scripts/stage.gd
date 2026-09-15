class_name Stage
extends Node3D
## The street stage: a floor, a brick backdrop, invisible walls and a lid that keep thrown props
## in, three judges at a table along the front and a crowd on the bleachers behind them.
## The audience is at +z; dancers face +z to play to them.

const HALF_W := 10.0
const HALF_D := 7.0
const WALL_H := 6.0
# a V per team, point towards the crowd
const FORMATION := [Vector3(0, 0, 0.6), Vector3(-1.7, 0, -0.6), Vector3(1.7, 0, -0.6), Vector3(-3.4, 0, -1.8), Vector3(3.4, 0, -1.8)]

var crowd: Array[Node3D] = []
var _crowd_base: Array[float] = []
var _crowd_phase: Array[float] = []
var judge_cards: Array = []   # per judge: [Label3D for team 0, Label3D for team 1]


func _ready() -> void:
	_floor()
	_walls()
	_backdrop()
	_judges()
	_crowd()


static func home_spot(team: int, slot: int) -> Vector3:
	var side := -1.0 if team == 0 else 1.0
	var o: Vector3 = FORMATION[slot % FORMATION.size()]
	return Vector3(side * 5.2 + o.x, 0.0, 1.0 + o.z)


static func clamp_in(p: Vector3, margin: float = 0.5) -> Vector3:
	return Vector3(clampf(p.x, -HALF_W + margin, HALF_W - margin), 0.0, clampf(p.z, -HALF_D + margin, HALF_D - margin))


func _mat(c: Color, rough: float = 0.8, emit: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emit
	return m


func _box_mesh(size: Vector3, pos: Vector3, mat: Material, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	(parent if parent != null else self).add_child(mi)
	return mi


func _floor() -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(80, 1, 80)
	cs.shape = sh
	cs.position = Vector3(0, -0.5, 0)
	body.add_child(cs)
	add_child(body)
	_box_mesh(Vector3(HALF_W * 2.0 + 1.0, 0.2, HALF_D * 2.0 + 1.0), Vector3(0, -0.1, 0), _mat(Color(0.24, 0.21, 0.23), 0.6))
	_box_mesh(Vector3(80, 0.1, 80), Vector3(0, -0.3, 0), _mat(Color(0.09, 0.09, 0.11)))
	for t in 2:
		var side := -1.0 if t == 0 else 1.0
		var c: Color = MatchManager.TEAM_COLORS[t]
		_box_mesh(Vector3(HALF_W - 0.4, 0.01, HALF_D * 2.0 - 0.4), Vector3(side * HALF_W * 0.5, 0.004, 0), _mat(c.darkened(0.72), 0.7))
	_box_mesh(Vector3(0.1, 0.02, HALF_D * 2.0), Vector3(0, 0.01, 0), _mat(Color(1.0, 0.85, 0.3), 0.5, 1.2))
	# footlights along the front edge
	for i in 11:
		_box_mesh(Vector3(0.5, 0.12, 0.2), Vector3(-HALF_W + i * 2.0, 0.06, HALF_D + 0.3), _mat(Color(1.0, 0.9, 0.55), 0.4, 2.0))


func _walls() -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	var walls := [
		[Vector3(0.4, WALL_H, HALF_D * 2.0 + 2.0), Vector3(-HALF_W - 0.7, WALL_H * 0.5, 0)],
		[Vector3(0.4, WALL_H, HALF_D * 2.0 + 2.0), Vector3(HALF_W + 0.7, WALL_H * 0.5, 0)],
		[Vector3(HALF_W * 2.0 + 2.0, WALL_H, 0.4), Vector3(0, WALL_H * 0.5, -HALF_D - 0.7)],
		[Vector3(HALF_W * 2.0 + 2.0, WALL_H, 0.4), Vector3(0, WALL_H * 0.5, HALF_D + 0.7)],
		[Vector3(HALF_W * 2.0 + 2.0, 0.4, HALF_D * 2.0 + 2.0), Vector3(0, WALL_H, 0)],
	]
	for w in walls:
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = w[0]
		cs.shape = sh
		cs.position = w[1]
		body.add_child(cs)


func _backdrop() -> void:
	var z := -HALF_D - 1.0
	_box_mesh(Vector3(HALF_W * 2.0 + 3.0, 5.0, 0.3), Vector3(0, 2.5, z), _mat(Color(0.42, 0.18, 0.14), 0.95))
	# mortar lines
	for row in 9:
		_box_mesh(Vector3(HALF_W * 2.0 + 3.0, 0.03, 0.02), Vector3(0, 0.5 * row + 0.25, z + 0.16), _mat(Color(0.3, 0.26, 0.24)))
	var neon := Label3D.new()
	neon.text = "DANCE-OFF"
	neon.font_size = 180
	neon.pixel_size = 0.012
	neon.outline_size = 24
	neon.modulate = Color(1.0, 0.35, 0.75)
	neon.outline_modulate = Color(0.25, 0.0, 0.2)
	neon.position = Vector3(0, 3.6, z + 0.2)
	add_child(neon)
	for t in 2:
		var l := OmniLight3D.new()
		l.light_color = (MatchManager.TEAM_COLORS[t] as Color).lightened(0.3)
		l.light_energy = 2.2
		l.omni_range = 14.0
		l.position = Vector3((-1.0 if t == 0 else 1.0) * 6.0, 4.5, 1.0)
		add_child(l)


func _judges() -> void:
	var table_z := HALF_D + 1.7
	_box_mesh(Vector3(9.5, 0.08, 1.0), Vector3(0, 0.85, table_z), _mat(Color(0.35, 0.22, 0.12)))
	_box_mesh(Vector3(9.5, 0.8, 0.06), Vector3(0, 0.42, table_z - 0.48), _mat(Color(0.55, 0.08, 0.12)))
	for j in 3:
		var root := Node3D.new()
		root.position = Vector3((j - 1) * 3.0, 0, table_z + 0.75)
		add_child(root)
		_box_mesh(Vector3(0.5, 0.62, 0.3), Vector3(0, 1.12, 0), _mat(Color(0.12, 0.12, 0.16)), root)
		_box_mesh(Vector3(0.28, 0.28, 0.28), Vector3(0, 1.6, 0), _mat(Color(0.88, 0.72, 0.58)), root)
		_box_mesh(Vector3(0.06, 0.3, 0.02), Vector3(0, 1.18, -0.16), _mat(Color(0.8, 0.1, 0.1)), root)
		var pair := []
		for t in 2:
			var l := Label3D.new()
			l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			l.no_depth_test = true
			l.font_size = 72
			l.pixel_size = 0.01
			l.outline_size = 16
			l.modulate = (MatchManager.TEAM_COLORS[t] as Color).lightened(0.35)
			l.position = Vector3(-0.5 + 1.0 * t, 2.5, 0)
			l.visible = false
			root.add_child(l)
			pair.append(l)
		judge_cards.append(pair)


func _crowd() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 7
	for row in 3:
		var z := HALF_D + 3.6 + row * 1.3
		var rise := 0.35 * row
		if row > 0:
			_box_mesh(Vector3(HALF_W * 2.0 + 4.0, rise, 1.3), Vector3(0, rise * 0.5, z), _mat(Color(0.2, 0.2, 0.24)))
		for i in 14:
			var fig := Node3D.new()
			fig.position = Vector3(-11.0 + i * 1.7 + (0.85 if row % 2 == 1 else 0.0) + r.randf_range(-0.2, 0.2), rise, z)
			add_child(fig)
			var col := Color.from_hsv(r.randf(), 0.5, 0.8)
			var mi := MeshInstance3D.new()
			var cap := CapsuleMesh.new()
			cap.radius = 0.24
			cap.height = 1.15
			cap.radial_segments = 8
			cap.rings = 2
			mi.mesh = cap
			mi.material_override = _mat(col)
			mi.position = Vector3(0, 0.6, 0)
			fig.add_child(mi)
			var head := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.16
			sm.height = 0.32
			sm.radial_segments = 8
			sm.rings = 4
			head.mesh = sm
			head.material_override = _mat(Color(0.85, 0.7, 0.55).darkened(r.randf() * 0.5))
			head.position = Vector3(0, 1.35, 0)
			fig.add_child(head)
			crowd.append(fig)
			_crowd_base.append(rise)
			_crowd_phase.append(r.randf() * 0.4)


func bounce(beat_f: float) -> void:
	for i in crowd.size():
		crowd[i].position.y = _crowd_base[i] + absf(sin((beat_f + _crowd_phase[i]) * PI)) * 0.14


func show_cards(rows: Array) -> void:
	for j in mini(rows.size(), judge_cards.size()):
		var cards: Array = rows[j]["cards"]
		for t in 2:
			var l: Label3D = judge_cards[j][t]
			l.text = "%.1f" % float(cards[t])
			l.visible = true


func hide_cards() -> void:
	for pair in judge_cards:
		for l in pair:
			(l as Label3D).visible = false
