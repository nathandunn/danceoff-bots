class_name Ragdoll
extends Node3D
## Six rigid bodies pinned together, spawned in the player's pose when a ball flattens them.
## Shares the player's materials so hit-flashes and team colours carry over.

const LAYER_WORLD := 1
const LAYER_RAGDOLL := 16

# name, shape kind, size, local position, joint anchor (local), mass
const PARTS := [
	["torso", "box", Vector3(0.5, 0.62, 0.3), Vector3(0, 1.12, 0), Vector3.ZERO, 10.0],
	["head", "box", Vector3(0.3, 0.3, 0.3), Vector3(0, 1.66, 0), Vector3(0, 1.45, 0), 3.0],
	["arm_l", "capsule", Vector3(0.08, 0.56, 0), Vector3(-0.35, 1.2, 0), Vector3(-0.35, 1.45, 0), 2.0],
	["arm_r", "capsule", Vector3(0.08, 0.56, 0), Vector3(0.35, 1.2, 0), Vector3(0.35, 1.45, 0), 2.0],
	["leg_l", "capsule", Vector3(0.1, 0.72, 0), Vector3(-0.14, 0.4, 0), Vector3(-0.14, 0.8, 0), 2.5],
	["leg_r", "capsule", Vector3(0.1, 0.72, 0), Vector3(0.14, 0.4, 0), Vector3(0.14, 0.8, 0), 2.5],
]

var bodies := {}
var torso: RigidBody3D


func build(pose: Transform3D, main_mat: Material, dark_mat: Material, eye_mat: Material, leg_mat: Material = null) -> void:
	global_transform = Transform3D.IDENTITY
	for p in PARTS:
		var rb := RigidBody3D.new()
		rb.name = p[0]
		rb.mass = p[5]
		rb.collision_layer = LAYER_RAGDOLL
		rb.collision_mask = LAYER_WORLD | LAYER_RAGDOLL
		rb.linear_damp = 2.5
		rb.angular_damp = 2.0
		rb.gravity_scale = 2.2
		var pm := PhysicsMaterial.new()
		pm.friction = 1.5
		pm.bounce = 0.0
		rb.physics_material_override = pm
		rb.can_sleep = true
		var cs := CollisionShape3D.new()
		var mi := MeshInstance3D.new()
		if p[1] == "box":
			var sh := BoxShape3D.new()
			sh.size = p[2]
			cs.shape = sh
			var m := BoxMesh.new()
			m.size = p[2]
			mi.mesh = m
		else:
			var sh := CapsuleShape3D.new()
			sh.radius = p[2].x + 0.02
			sh.height = p[2].y + 0.04
			cs.shape = sh
			var m := CapsuleMesh.new()
			m.radius = p[2].x
			m.height = p[2].y
			m.radial_segments = 8
			m.rings = 3
			mi.mesh = m
		var limb_mat: Material = leg_mat if (leg_mat != null and (p[0] == "leg_l" or p[0] == "leg_r")) else dark_mat
		mi.material_override = main_mat if p[0] == "torso" else (eye_mat if p[0] == "head" else limb_mat)
		rb.add_child(cs)
		rb.add_child(mi)
		add_child(rb)
		rb.global_transform = pose * Transform3D(Basis.IDENTITY, p[3])
		bodies[p[0]] = rb
	torso = bodies["torso"]
	for p in PARTS:
		if p[0] == "torso":
			continue
		var j := PinJoint3D.new()
		add_child(j)
		j.global_transform = pose * Transform3D(Basis.IDENTITY, p[4])
		j.node_a = j.get_path_to(torso)
		j.node_b = j.get_path_to(bodies[p[0]])
		j.exclude_nodes_from_collision = true


func shove(impulse: Vector3) -> void:
	if torso == null:
		return
	torso.apply_central_impulse(impulse)
	# no tumbling: the knees go, and he tips over the way he was hit and folds up where he stands
	torso.apply_torque_impulse(Vector3(randf_range(-1.5, 1.5), randf_range(-1, 1), randf_range(-1.5, 1.5)))
	if impulse.length() > 0.01:
		torso.apply_torque_impulse(Vector3.UP.cross(impulse.normalized()) * 3.0)
	if bodies.has("head"):
		bodies["head"].apply_central_impulse(impulse * 0.25)


func torso_position() -> Vector3:
	return torso.global_position if torso != null else global_position


func head_position() -> Vector3:
	return bodies["head"].global_position if bodies.has("head") else torso_position()
