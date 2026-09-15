class_name Prop
extends RigidBody3D
## Something to dance with or to throw. Hats and canes add flair to the holder's moves; any prop
## thrown at a rival can floor him. A held prop is frozen and carried by its holder.

enum Kind { HAT, CANE, LID, CHICKEN }

const LAYER_WORLD := 1
const LAYER_DANCERS := 2
const LAYER_PROPS := 4
const NAMES := ["hat", "cane", "bin lid", "rubber chicken"]
const MASSES := [0.3, 0.6, 1.5, 0.5]

var kind: int = Kind.HAT
var manager = null
var holder: Dancer = null
var thrower: Dancer = null
var claimed_by: Dancer = null
var live := false
var home := Vector3.ZERO
var _live_t := 0.0
var _pending := false
var _pending_vel := Vector3.ZERO
var _hit := {}


func _ready() -> void:
	collision_layer = LAYER_PROPS
	collision_mask = LAYER_WORLD | LAYER_PROPS
	contact_monitor = true
	max_contacts_reported = 4
	continuous_cd = true
	linear_damp = 0.3
	angular_damp = 1.0
	mass = float(MASSES[kind])
	body_entered.connect(_on_body_entered)
	_build()
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = LAYER_DANCERS
	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = 0.4
	cs.shape = sh
	area.add_child(cs)
	add_child(area)
	area.body_entered.connect(_on_area_body)


func prop_name() -> String:
	return String(NAMES[kind])


func is_dance_prop() -> bool:
	return kind == Kind.HAT or kind == Kind.CANE


func is_available() -> bool:
	return holder == null and not live and is_inside_tree() and linear_velocity.length() < 1.5


func take(d: Dancer) -> void:
	holder = d
	thrower = null
	live = false
	claimed_by = null
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	freeze = true
	collision_layer = 0
	collision_mask = 0


func throw_to(from: Vector3, v: Vector3, by: Dancer) -> void:
	holder = null
	thrower = by
	_release_body(from, v)
	live = true
	_live_t = 3.0
	_hit.clear()


func drop(from: Vector3, v: Vector3) -> void:
	holder = null
	thrower = null
	live = false
	_release_body(from, v)


func _release_body(from: Vector3, v: Vector3) -> void:
	global_position = from
	collision_layer = LAYER_PROPS
	collision_mask = LAYER_WORLD | LAYER_PROPS
	freeze = false
	sleeping = false
	_pending_vel = v
	_pending = true


# velocity set on a body that was frozen this frame is lost; apply it here
func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if _pending:
		_pending = false
		state.linear_velocity = _pending_vel
		state.angular_velocity = Vector3(randf_range(-8, 8), randf_range(-8, 8), randf_range(-8, 8))


func _physics_process(delta: float) -> void:
	if live:
		_live_t -= delta
		if _live_t <= 0.0:
			live = false
	if holder == null and global_position.y < -3.0:
		_release_body(home + Vector3(0, 0.4, 0), Vector3.ZERO)


func _on_body_entered(body: Node) -> void:
	if live and body is StaticBody3D:
		live = false


func _on_area_body(body: Node3D) -> void:
	if not live or holder != null:
		return
	if not (body is Dancer) or body == thrower or _hit.has(body):
		return
	var d: Dancer = body
	if d.ragdoll != null:
		return
	_hit[d] = true
	live = false
	d.prop_hit(self)


func _mat(c: Color, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.5
	m.metallic = metal
	return m


func _mesh(mesh: Mesh, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	add_child(mi)


func _cyl(r: float, h: float) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = r
	m.bottom_radius = r
	m.height = h
	m.radial_segments = 12
	m.rings = 1
	return m


func _box(s: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = s
	return m


func _build() -> void:
	var cs := CollisionShape3D.new()
	match kind:
		Kind.HAT:
			_mesh(_cyl(0.2, 0.025), Vector3(0, 0.012, 0), _mat(Color(0.07, 0.07, 0.09)))
			_mesh(_cyl(0.125, 0.18), Vector3(0, 0.11, 0), _mat(Color(0.07, 0.07, 0.09)))
			_mesh(_cyl(0.13, 0.04), Vector3(0, 0.05, 0), _mat(Color(0.8, 0.1, 0.15)))
			var sh := CylinderShape3D.new()
			sh.radius = 0.2
			sh.height = 0.2
			cs.shape = sh
			cs.position = Vector3(0, 0.1, 0)
		Kind.CANE:
			_mesh(_cyl(0.025, 0.9), Vector3.ZERO, _mat(Color(0.07, 0.07, 0.09)))
			_mesh(_cyl(0.03, 0.08), Vector3(0, -0.42, 0), _mat(Color(0.95, 0.95, 0.95)))
			_mesh(_box(Vector3(0.16, 0.05, 0.05)), Vector3(0.06, 0.45, 0), _mat(Color(0.95, 0.85, 0.3), 0.6))
			var sh := BoxShape3D.new()
			sh.size = Vector3(0.1, 0.9, 0.1)
			cs.shape = sh
		Kind.LID:
			_mesh(_cyl(0.32, 0.05), Vector3.ZERO, _mat(Color(0.6, 0.62, 0.66), 0.7))
			_mesh(_box(Vector3(0.16, 0.05, 0.05)), Vector3(0, 0.05, 0), _mat(Color(0.4, 0.42, 0.45), 0.7))
			var sh := CylinderShape3D.new()
			sh.radius = 0.32
			sh.height = 0.08
			cs.shape = sh
		_:
			var body := CapsuleMesh.new()
			body.radius = 0.08
			body.height = 0.34
			_mesh(body, Vector3.ZERO, _mat(Color(1.0, 0.85, 0.1)))
			var head := SphereMesh.new()
			head.radius = 0.07
			head.height = 0.14
			_mesh(head, Vector3(0, 0.22, -0.02), _mat(Color(1.0, 0.85, 0.1)))
			_mesh(_box(Vector3(0.04, 0.03, 0.07)), Vector3(0, 0.21, -0.1), _mat(Color(1.0, 0.5, 0.1)))
			_mesh(_box(Vector3(0.02, 0.05, 0.08)), Vector3(0, 0.3, -0.01), _mat(Color(0.9, 0.1, 0.1)))
			var sh := CapsuleShape3D.new()
			sh.radius = 0.09
			sh.height = 0.4
			cs.shape = sh
	add_child(cs)
