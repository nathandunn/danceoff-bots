class_name Dancer
extends CharacterBody3D
## One dancer: a boxes-and-capsules body, a brain that weighs dancing against fighting, and the
## beat-by-beat bookkeeping that turns dancing into sync and flair for the team. The crew moves as
## a crew: MatchManager sets the stance each phrase (hold / press / charge) and this file follows
## it - the wedge advances or gives ground together, and a charge sends the lot at one rival.
##
## Scoring rules this file enforces: a dancer who is not dancing (brawling, fetching, throwing,
## dodging, floored, running back to his spot) scores nothing and is out of sync; having stopped,
## he rejoins at the next phrase. Hits score nothing - except a dance-strike, a kick or swing on a
## strike beat of the move being danced, which scores flair and hits.

const STAT_KEYS: Array[String] = ["flair", "strike_pts", "beats", "dance_beats", "sync_beats", "strikes",
	"strike_hits", "punches", "punch_hits", "throws", "throw_hits", "friendly_hits", "knockdowns",
	"floored", "hits_taken", "fumbles", "freestyles", "dodges", "pickups"]

const DECISION_INTERVAL := 0.12
const WALK_SPEED := 4.6
const DRIFT_SPEED := 1.5
const RETURN_DIST := 2.2
const PUNCH_RANGE := 1.25
const PUNCH_WINDUP := 0.25
const PUNCH_COOLDOWN := 0.75
const THROW_WINDUP := 0.3
const THROW_MIN := 2.5
const THROW_MAX := 12.0
const PICKUP_RANGE := 0.8
const STRIKE_REACH := {"kick": 1.7, "swing": 1.9, "punch": 1.4}
const STRIKE_PTS := 5.0
const FOV_COS := -0.09
const TIMING_TOL := 0.12
const COMMIT := 1.5
const GETUP_GRACE := 1.5     # just back on his feet: can be staggered, not floored
const LAYER_WORLD := 1
const LAYER_DANCERS := 2
const CROWD_DIR := Vector3(0, 0, 1)

var team := 0
var slot := 0
var team_color := Color.RED
var dancer_name := "d"
var personality: Personality
var build: PlayerBuild
## What the setup panel called this one, so the results can name it (a jittered build no
## longer matches its preset exactly, and "Custom" everywhere would tell nobody anything).
var persona_name := ""
var build_name := ""
var manager = null
var rng: RandomNumberGenerator

# from the build
var timing_sigma := 0.08
var adopt_base := 0.8
var execution := 0.7
var fumble_mult := 1.0
var down_base := 1.9
var strength_skill := 0.5
var balance_skill := 0.5
var arm_skill := 0.5
var throw_speed := 13.0
var throw_err := 4.5

# from the personality
var aggression := 0.5
var showmanship := 0.5
var discipline := 0.5
var grudge := 0.5
var caution := 0.5
var teamwork := 0.5

# brain and body state
var action := "dance"      # dance / brawl / fetch / throw (cheer / cry / shrug at the end)
var target: Dancer = null
var claim: Prop = null
var held: Prop = null
var strike_target: Dancer = null
var returning := false
var decide_timer := 0.0
var _commit := 0.0
var _punch_t := 0.0
var _punch_cd := 0.0
var _throw_t := 0.0
var _dodge_t := 0.0
var _dodge_dir := Vector3.ZERO
var _pending_dodge := -1.0
var _pending_dodge_dir := Vector3.ZERO
var _stagger := 0.0
var _down := 0.0
var _last_floored := -100.0
var _run_up := 0.0
var last_attacker: Dancer = null
var last_attacked_at := -100.0
var ragdoll: Ragdoll = null
var _got_up_at := -100.0
var _had_enough := {}      # Dancer -> time until which he is left alone after being floored

# dance bookkeeping
var move := "step_touch"
var freestyle := false
var phrase_start := 0
var joined := false
var block_beats := 0
var block_ok := false
var block_on_time := 0
var fumbled := false
var adopt_delay := 0.5
var tempo_err := 0.0
var in_sync := false
var recent_moves: Array[String] = []
var _wobble := 0.0

var stats := {}

# celebration
var celeb_role := ""
var _celeb_t := 0.0
var _tears: CPUParticles3D = null

# body
const ACCENT := [Color(0.98, 0.82, 0.2), Color(1.0, 0.45, 0.72)]
const FELT := [Color(0.08, 0.08, 0.1), Color(0.93, 0.92, 0.88)]
const TROUSERS := [Color(0.09, 0.09, 0.11), Color(0.93, 0.88, 0.74)]
const SHOES := [Color(0.96, 0.96, 0.98), Color(0.52, 0.31, 0.16)]
const SKINS := [Color(0.9, 0.75, 0.6), Color(0.62, 0.42, 0.3), Color(0.78, 0.58, 0.42), Color(0.45, 0.3, 0.22), Color(0.95, 0.8, 0.68)]
const HAIRS := [Color(0.08, 0.07, 0.07), Color(0.36, 0.2, 0.1), Color(0.9, 0.74, 0.34), Color(0.62, 0.2, 0.1), Color(0.78, 0.78, 0.8)]

var body_root: Node3D
var upper: Node3D          # everything above the waist: it turns and rolls against the hips
var head_node: Node3D
var fore_l: Node3D
var fore_r: Node3D
var shin_l: Node3D
var shin_r: Node3D
var _trouser_mat: StandardMaterial3D
var _core_mi: MeshInstance3D = null
var _rise_t := 0.0        # struggling back to his feet: not dancing yet
var _rise_len := 0.0
var _slip_t := 0.0        # slipping a blow without breaking step
var _slip_side := 1.0      # the baked torso, for the hit flash
static var _flash_mats := {}
var arm_l: Node3D
var arm_r: Node3D
var leg_l: Node3D
var leg_r: Node3D
var hat_anchor: Node3D
var hat: Prop = null            # on his head; the cane (or whatever he picked up) is `held`
var hurt := 0.0                 # 0 fresh .. hurt_max: slows him down and roughens his timing
var _trickle: MeshInstance3D = null
var _drip: CPUParticles3D = null
var _blood_mat: StandardMaterial3D
var hand_anchor: Node3D
var label: Label3D
var _mat: StandardMaterial3D
var _dark_mat: StandardMaterial3D
var _skin_mat: StandardMaterial3D
var _flash_tween: Tween
var _gait := 0.0


func _ready() -> void:
	collision_layer = LAYER_DANCERS
	collision_mask = LAYER_WORLD
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	if personality == null:
		personality = Personality.preset("Balanced")
	if build == null:
		build = PlayerBuild.preset("Even")
	aggression = personality.get_trait("aggression")
	showmanship = personality.get_trait("showmanship")
	discipline = personality.get_trait("discipline")
	grudge = personality.get_trait("grudge")
	caution = personality.get_trait("caution")
	teamwork = personality.get_trait("teamwork")
	apply_build()
	for k in STAT_KEYS:
		stats[k] = 0.0
	decide_timer = rng.randf_range(0.0, DECISION_INTERVAL)
	_build_body()


## The five properties become game numbers; spans are the designed ranges, GAINS scale them.
func apply_build() -> void:
	timing_sigma = build.stat("rhythm", 0.13, 0.03, 0.012, 0.25)
	adopt_base = build.stat("rhythm", 1.4, 0.3, 0.05, 2.5)
	execution = build.stat("flair", 0.45, 1.0, 0.15, 1.5)
	fumble_mult = build.stat("balance", 1.6, 0.5, 0.2, 2.6)
	down_base = build.stat("balance", 2.6, 1.2, 0.7, 4.0)
	balance_skill = build.skill("balance")
	strength_skill = build.skill("strength")
	arm_skill = build.skill("arm")
	throw_speed = build.stat("arm", 9.0, 17.0, 6.0, 22.0)
	throw_err = build.stat("arm", 7.0, 2.0, 0.8, 12.0)


# ---------------------------------------------------------------- body

func _build_body() -> void:
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.32
	cap.height = 1.8
	cs.shape = cap
	cs.position = Vector3(0, 0.9, 0)
	add_child(cs)

	body_root = Node3D.new()
	add_child(body_root)
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = team_color
	_mat.roughness = 0.55
	_dark_mat = StandardMaterial3D.new()
	_dark_mat.albedo_color = team_color.darkened(0.45)
	_dark_mat.roughness = 0.8
	_skin_mat = StandardMaterial3D.new()
	_skin_mat.albedo_color = Color(0.9, 0.75, 0.6)

	var vis: bool = manager == null or not manager.headless
	_skin_mat.albedo_color = SKINS[(slot + team * 2) % 5]
	var accent: Color = ACCENT[team]
	var sleeve := StandardMaterial3D.new()
	sleeve.albedo_color = team_color.darkened(0.12)
	sleeve.roughness = 0.6
	var glove := StandardMaterial3D.new()
	glove.albedo_color = Color(0.97, 0.97, 0.97)
	_trouser_mat = StandardMaterial3D.new()
	_trouser_mat.albedo_color = TROUSERS[team]
	_trouser_mat.roughness = 0.8
	var shoe := StandardMaterial3D.new()
	shoe.albedo_color = SHOES[team]
	shoe.roughness = 0.35
	var stripe_mat := StandardMaterial3D.new()
	stripe_mat.albedo_color = accent if team == 0 else team_color.darkened(0.3)

	upper = Node3D.new()
	upper.position = Vector3(0, 0.82, 0)
	body_root.add_child(upper)
	_dec(upper, _box(Vector3(0.5, 0.62, 0.3)), Vector3(0, 0.30, 0), _mat)
	head_node = Node3D.new()
	head_node.position = Vector3(0, 0.64, 0)
	upper.add_child(head_node)
	_dec(head_node, _box(Vector3(0.3, 0.3, 0.3)), Vector3(0, 0.2, 0), _skin_mat)
	var ink := StandardMaterial3D.new()
	ink.albedo_color = Color(0.08, 0.08, 0.1)
	_dec(head_node, _box(Vector3(0.2, 0.05, 0.03)), Vector3(0, 0.26, -0.16), ink)
	var lip := StandardMaterial3D.new()
	lip.albedo_color = Color(0.6, 0.15, 0.15)
	_dec(head_node, _box(Vector3(0.12, 0.03, 0.03)), Vector3(0, 0.12, -0.16), lip)
	# the nosebleed: a trickle down the face that lengthens with the damage, and drops off the chin
	_blood_mat = StandardMaterial3D.new()
	_blood_mat.albedo_color = Color(0.62, 0.02, 0.03)
	_blood_mat.emission_enabled = true
	_blood_mat.emission = Color(0.3, 0.0, 0.0)
	if vis:
		_trickle = _dec(head_node, _box(Vector3(0.05, 0.14, 0.02)), Vector3(0, 0.09, -0.163), _blood_mat)
		_trickle.visible = false
		_drip = CPUParticles3D.new()
		_drip.amount = 18
		_drip.lifetime = 0.7
		_drip.local_coords = false
		_drip.direction = Vector3(0, -1, -0.4)
		_drip.spread = 12.0
		_drip.initial_velocity_min = 0.4
		_drip.initial_velocity_max = 1.1
		_drip.gravity = Vector3(0, -9.8, 0)
		var dm := SphereMesh.new()
		dm.radius = 0.025
		dm.height = 0.05
		dm.radial_segments = 6
		dm.rings = 3
		_drip.mesh = dm
		_drip.material_override = _blood_mat
		_drip.position = Vector3(0, 0.14, -0.17)
		head_node.add_child(_drip)
		_drip.emitting = false
	# arms: sleeve, elbow, forearm, white glove
	arm_l = _joint(upper, Vector3(-0.35, 0.63, 0), 0.08, 0.3, sleeve)
	arm_r = _joint(upper, Vector3(0.35, 0.63, 0), 0.08, 0.3, sleeve)
	fore_l = _joint(arm_l, Vector3(0, -0.28, 0), 0.07, 0.31, sleeve)
	fore_r = _joint(arm_r, Vector3(0, -0.28, 0), 0.07, 0.31, sleeve)
	var ball := SphereMesh.new()
	ball.radius = 0.075
	ball.height = 0.15
	_dec(fore_l, ball, Vector3(0, -0.32, 0), glove)
	_dec(fore_r, ball, Vector3(0, -0.32, 0), glove)
	# legs: thigh, knee, shin, shoe
	leg_l = _joint(body_root, Vector3(-0.14, 0.8, 0), 0.1, 0.4, _trouser_mat)
	leg_r = _joint(body_root, Vector3(0.14, 0.8, 0), 0.1, 0.4, _trouser_mat)
	shin_l = _joint(leg_l, Vector3(0, -0.38, 0), 0.085, 0.4, _trouser_mat)
	shin_r = _joint(leg_r, Vector3(0, -0.38, 0), 0.085, 0.4, _trouser_mat)
	var sole := StandardMaterial3D.new()
	sole.albedo_color = Color(0.05, 0.05, 0.06)
	for sh in [shin_l, shin_r]:
		_dec(sh, _box(Vector3(0.17, 0.09, 0.3)), Vector3(0, -0.4, -0.05), shoe)
		_dec(sh, _box(Vector3(0.18, 0.025, 0.31)), Vector3(0, -0.445, -0.05), sole)
	hat_anchor = Node3D.new()
	hat_anchor.position = Vector3(0, 0.35, 0)
	head_node.add_child(hat_anchor)
	hand_anchor = Node3D.new()
	hand_anchor.position = Vector3(0, -0.28, 0)
	fore_r.add_child(hand_anchor)
	if vis:
		_dress(accent, stripe_mat, ink)
		_bake_body()

	label = Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.font_size = 28
	label.pixel_size = 0.008
	label.outline_size = 8
	label.position = Vector3(0, 2.2, 0)
	label.text = dancer_name
	label.modulate = team_color.lightened(0.5)
	add_child(label)


## Merge each moving part's pieces (some forty a dancer, with the costume) into one mesh under a
## shared vertex-coloured material: the web renderer draws every mesh on its own. Eleven meshes a
## dancer: hips, torso, head, two upper arms, two forearms, two thighs, two shins. The nosebleed
## stays separate so it can show and hide. Shared between matches (same crew, same slot).
func _bake_body() -> void:
	var k := "dancer/%d/%d/" % [team, slot]
	_core_mi = MeshBaker.bake_into(upper, [head_node, arm_l, arm_r], k + "upper")
	MeshBaker.bake_into(head_node, [hat_anchor, _trickle, _drip], k + "head")
	MeshBaker.bake_into(body_root, [upper, leg_l, leg_r], k + "hips")
	MeshBaker.bake_into(arm_l, [fore_l], k + "arm")
	MeshBaker.bake_into(arm_r, [fore_r], k + "arm")
	MeshBaker.bake_into(fore_l, [], k + "fore")
	MeshBaker.bake_into(fore_r, [hand_anchor], k + "fore")
	MeshBaker.bake_into(leg_l, [shin_l], k + "thigh_l")
	MeshBaker.bake_into(leg_r, [shin_r], k + "thigh_r")
	MeshBaker.bake_into(shin_l, [], k + "shin_l")
	MeshBaker.bake_into(shin_r, [], k + "shin_r")


func _dec(parent: Node3D, mesh: Mesh, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


## A limb segment: a pivot at its top with a capsule hanging below it.
func _joint(parent: Node3D, pivot: Vector3, r: float, h: float, mat: Material) -> Node3D:
	var piv := Node3D.new()
	piv.position = pivot
	parent.add_child(piv)
	_dec(piv, _capsule(r, h), Vector3(0, -h * 0.5, 0), mat)
	return piv


func _flat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.7
	return m


## Costume. Alley Cats: team-orange jackets, black slacks with a gold stripe, white shoes, gold trim.
## Night Owls: blue blazers, cream slacks with a navy stripe, tan shoes, pink trim. Five of each, and
## no two alike: their own skin, hair, and a collar-and-tie, bandana, bow tie, braces or shades.
func _dress(accent: Color, stripe_mat: StandardMaterial3D, ink: StandardMaterial3D) -> void:
	var white := _flat(Color(0.96, 0.96, 0.98))
	var lapel := _flat(team_color.darkened(0.4))
	var acc := _flat(accent)
	var hair := _flat(HAIRS[(slot * 2 + team + 1) % 5])
	# shirt front, lapels, collar, belt and buckle
	_dec(upper, _box(Vector3(0.22, 0.5, 0.012)), Vector3(0, 0.34, -0.152), white)
	for sx in [-1.0, 1.0]:
		var lp := _dec(upper, _box(Vector3(0.09, 0.44, 0.016)), Vector3(sx * 0.14, 0.36, -0.154), lapel)
		lp.rotation.z = -sx * 0.18
	_dec(upper, _box(Vector3(0.28, 0.06, 0.2)), Vector3(0, 0.62, 0), white)
	_dec(upper, _box(Vector3(0.52, 0.07, 0.32)), Vector3(0, 0.03, 0), _flat(Color(0.06, 0.06, 0.07)))
	_dec(upper, _box(Vector3(0.09, 0.06, 0.02)), Vector3(0, 0.03, -0.165), _flat(Color(0.95, 0.8, 0.25)))
	# hips and seat, so a twerk has something to shake
	_dec(body_root, _box(Vector3(0.48, 0.16, 0.3)), Vector3(0, 0.77, 0.01), _trouser_mat)
	_dec(body_root, _box(Vector3(0.44, 0.2, 0.12)), Vector3(0, 0.74, 0.14), _trouser_mat)
	# trouser stripes, thigh and shin, outer side
	for pair in [[leg_l, shin_l, -1.0], [leg_r, shin_r, 1.0]]:
		_dec(pair[0], _box(Vector3(0.02, 0.38, 0.05)), Vector3(pair[2] * 0.1, -0.2, 0), stripe_mat)
		_dec(pair[1], _box(Vector3(0.02, 0.38, 0.05)), Vector3(pair[2] * 0.085, -0.2, 0), stripe_mat)
	# hair under the hat: a cap, sideburns, and a style apiece
	if slot != 4:
		_dec(head_node, _box(Vector3(0.33, 0.09, 0.33)), Vector3(0, 0.33, 0), hair)
	for sx in [-1.0, 1.0]:
		_dec(head_node, _box(Vector3(0.03, 0.12, 0.04)), Vector3(sx * 0.165, 0.14, -0.1), hair)
	match slot:
		0:
			_dec(head_node, _box(Vector3(0.18, 0.08, 0.12)), Vector3(0, 0.38, -0.1), hair)   # quiff
			_dec(upper, _box(Vector3(0.07, 0.05, 0.012)), Vector3(-0.17, 0.5, -0.153), acc)   # pocket square
			_dec(head_node, _box(Vector3(0.24, 0.06, 0.03)), Vector3(0, 0.25, -0.162), ink)    # shades
		1:
			_dec(head_node, _box(Vector3(0.32, 0.2, 0.05)), Vector3(0, 0.2, 0.16), hair)       # slicked back
			_dec(head_node, _box(Vector3(0.14, 0.025, 0.03)), Vector3(0, 0.15, -0.165), hair)  # moustache
			_dec(upper, _box(Vector3(0.34, 0.09, 0.24)), Vector3(0, 0.6, 0.0), acc)            # bandana
		2:
			var bun := SphereMesh.new()
			bun.radius = 0.13
			bun.height = 0.26
			_dec(head_node, bun, Vector3(0, 0.24, 0.2), hair)                                   # bun
			for sx in [-1.0, 1.0]:
				_dec(upper, _box(Vector3(0.07, 0.07, 0.02)), Vector3(sx * 0.06, 0.56, -0.16), acc)
			_dec(upper, _box(Vector3(0.04, 0.04, 0.025)), Vector3(0, 0.56, -0.16), acc)         # bow tie
		3:
			_dec(head_node, _box(Vector3(0.05, 0.14, 0.34)), Vector3(0, 0.4, 0), hair)          # mohawk
			_dec(head_node, _box(Vector3(0.14, 0.025, 0.03)), Vector3(0, 0.15, -0.165), hair)
			for sx in [-1.0, 1.0]:
				_dec(upper, _box(Vector3(0.04, 0.5, 0.014)), Vector3(sx * 0.15, 0.3, -0.158), acc)   # braces
		_:
			_dec(upper, _box(Vector3(0.06, 0.34, 0.014)), Vector3(0, 0.4, -0.158), acc)         # necktie
			_dec(head_node, _box(Vector3(0.24, 0.06, 0.03)), Vector3(0, 0.25, -0.162), ink)     # shades, bald


func _part(mesh: Mesh, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	body_root.add_child(mi)
	return mi


func _limb(pivot: Vector3, r: float, h: float, drop: float) -> Node3D:
	var piv := Node3D.new()
	piv.position = pivot
	body_root.add_child(piv)
	var mi := MeshInstance3D.new()
	mi.mesh = _capsule(r, h)
	mi.material_override = _dark_mat
	mi.position = Vector3(0, -drop, 0)
	piv.add_child(mi)
	return piv


func _box(size: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	return m


func _capsule(r: float, h: float) -> CapsuleMesh:
	var m := CapsuleMesh.new()
	m.radius = r
	m.height = h
	m.radial_segments = 8
	m.rings = 3
	return m


func flash(c: Color) -> void:
	if _core_mi != null:
		# baked torso: a plain override of the flash colour for a moment
		if _flash_tween != null and _flash_tween.is_valid():
			_flash_tween.kill()
		var key := c.to_html()
		if not _flash_mats.has(key):
			var fm := StandardMaterial3D.new()
			fm.albedo_color = c
			_flash_mats[key] = fm
		_core_mi.material_override = _flash_mats[key]
		_flash_tween = create_tween()
		_flash_tween.tween_interval(0.2)
		_flash_tween.tween_callback(func():
			if is_instance_valid(_core_mi):
				_core_mi.material_override = null)
		return
	if _mat == null:
		return
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_mat.albedo_color = c
	_flash_tween = create_tween()
	_flash_tween.tween_property(_mat, "albedo_color", team_color, 0.4)


func _side() -> float:
	return -1.0 if team == 0 else 1.0


func facing() -> Vector3:
	return -global_transform.basis.z


func can_see(point: Vector3) -> bool:
	var d := point - global_position
	d.y = 0.0
	if d.length_squared() < 0.04:
		return true
	return facing().dot(d.normalized()) > FOV_COS


func is_dancing() -> bool:
	return action == "dance" and not returning and ragdoll == null and _stagger <= 0.0 and _dodge_t <= 0.0 and _rise_t <= 0.0


# ---------------------------------------------------------------- loop

func _physics_process(delta: float) -> void:
	if manager == null:
		return
	if held != null and is_instance_valid(held):
		held.global_transform = _hold_transform()
	if hat != null and is_instance_valid(hat):
		hat.global_transform = hat_anchor.global_transform
	if manager.running and hurt > 0.0:
		hurt = maxf(hurt - Tune.v("hurt_heal") * delta, 0.0)
	_update_blood()
	if ragdoll != null:
		_follow_ragdoll()
		_down -= delta
		if _down <= 0.0 or manager.celebrating:
			_get_up()
		return
	if _rise_t > 0.0 and not manager.celebrating:
		_rise_t -= delta
		velocity = Vector3.ZERO
		_rise_pose(delta)
		return
	if manager.celebrating:
		_celebrate(delta)
		return
	if not manager.running:
		velocity = Vector3.ZERO
		_apply_pose(Moves.pose("", float(manager.beat_f)), delta)
		return
	_punch_cd -= delta
	if _wobble > 0.0:
		_wobble -= delta
	if _pending_dodge > 0.0:
		_pending_dodge -= delta
		if _pending_dodge <= 0.0:
			_start_dodge(_pending_dodge_dir)
	if _dodge_t > 0.0:
		_dodge_t -= delta
		velocity = _dodge_dir * 5.2
		_move()
		_run_pose(delta)
		return
	if _stagger > 0.0:
		_stagger -= delta
		velocity = Vector3.ZERO
		body_root.rotation.x = lerpf(body_root.rotation.x, 0.45, clampf(delta * 12.0, 0.0, 1.0))
		return
	decide_timer -= delta
	if decide_timer <= 0.0:
		decide_timer = DECISION_INTERVAL
		_decide()
	match action:
		"brawl":
			_do_brawl(delta)
		"fetch":
			_do_fetch(delta)
		"throw":
			_do_throw(delta)
		_:
			_do_dance(delta)


func _move() -> void:
	velocity *= 1.0 - hurt   # a battered dancer is a slower one
	move_and_slide()
	global_position = Stage.clamp_in(global_position, 0.4)


func _face(point: Vector3, delta: float) -> void:
	var d := point - global_position
	d.y = 0.0
	if d.length_squared() < 0.0001:
		return
	var want := atan2(-d.x, -d.z)
	rotation.y = lerp_angle(rotation.y, want, clampf(delta * 9.0, 0.0, 1.0))


func _hold_transform() -> Transform3D:
	if held != null and held.kind == Prop.Kind.HAT:
		return hat_anchor.global_transform
	return hand_anchor.global_transform


# ---------------------------------------------------------------- brain

func _decide() -> void:
	_commit -= DECISION_INTERVAL
	if _punch_t > 0.0 or _throw_t > 0.0:
		return
	if _commit > 0.0 and action != "dance" and _action_valid():
		return
	var now: float = manager.elapsed
	var best := "dance"
	var best_s := _dance_score()
	var best_target: Dancer = null
	var best_prop: Prop = null
	for e: Dancer in manager.standing(1 - team):
		var s := _brawl_score(e, now)
		if s > best_s:
			best = "brawl"
			best_s = s
			best_target = e
	var guard := _guard_choice()
	if guard.size() == 2 and float(guard[1]) > best_s:
		best = "brawl"
		best_s = float(guard[1])
		best_target = guard[0]
	if held != null:
		var th := _throw_choice(now)
		if th.size() == 2 and float(th[1]) > best_s:
			best = "throw"
			best_s = float(th[1])
			best_target = th[0]
	# a hat for his head if he has lost his, something for his hand if it is empty
	var fc := _fetch_choice()
	if fc.size() == 2 and float(fc[1]) > best_s:
		best = "fetch"
		best_s = float(fc[1])
		best_prop = fc[0]
	_set_action(best, best_target, best_prop)


func _action_valid() -> bool:
	match action:
		"brawl":
			return target != null and is_instance_valid(target) and target.ragdoll == null
		"fetch":
			return claim != null and is_instance_valid(claim) and claim.is_available()
		"throw":
			return held != null
	return true


func _set_action(a: String, t: Dancer, p: Prop) -> void:
	if a == action and t == target and p == claim:
		return
	if claim != null and is_instance_valid(claim) and claim.claimed_by == self and p != claim:
		claim.claimed_by = null
	if action == "dance" and a != "dance":
		joined = false
		block_ok = false
	action = a
	target = t
	claim = p
	if p != null:
		p.claimed_by = self
	if a == "brawl" or a == "fetch":
		_commit = COMMIT
		_run_up = 0.0
	if a == "throw":
		_throw_t = THROW_WINDUP


func _dance_score() -> float:
	return Tune.v("dance_base") + 0.5 * discipline + 0.3 * showmanship


func _brawl_score(e: Dancer, now: float) -> float:
	var d := global_position.distance_to(e.global_position)
	if d > 9.0:
		return -1.0
	var prox := 1.0 - d / 10.0
	var s := aggression * Tune.v("brawl_mult") * prox - caution * 0.5 * (1.0 - prox * 0.5)
	if e == last_attacker and now - last_attacked_at < 8.0:
		s += grudge * Tune.v("grudge_mult")
	if e.held != null and e.held.is_dance_prop():
		s += 0.25 * aggression
	if float(_had_enough.get(e, -100.0)) > now:
		s -= 1.2
	# the crew fights as a crew. Outside a charge a dancer throws a punch only to answer one. In
	# a charge the fighting is danced - kicks and swings on the beat into the rival the charge
	# named - so anyone on the strike move keeps dancing it, and only a dancer who isn't goes in
	# with his fists
	var st: String = manager.stance[team]
	if st == "charge":
		if not Moves.strikes(move).is_empty():
			return -1.0
		if e == manager.focus[team]:
			s += Tune.v("charge_bonus") * (0.4 + aggression)
	elif not (e == last_attacker and now - last_attacked_at < Tune.v("retort_s")):
		return -1.0
	var lead: float = manager.lead_fraction(1 - team)
	s += 0.6 * aggression * lead
	return s


## A mate being thumped, or floored with a rival standing over him: go and sort the rival out.
func _guard_choice() -> Array:
	var best: Array = []
	var best_s := -INF
	for m: Dancer in manager.team_dancers(team):
		if m == self:
			continue
		for e: Dancer in manager.standing(1 - team):
			var threat := false
			if e.action == "brawl" and e.target == m and e.global_position.distance_to(m.global_position) < 3.5:
				threat = true
			elif m.ragdoll != null and e.global_position.distance_to(m.global_position) < 2.5:
				threat = true
			if not threat:
				continue
			var d := global_position.distance_to(e.global_position)
			var s := teamwork * Tune.v("guard_mult") * maxf(1.0 - d / 12.0, 0.0) + aggression * 0.3 - caution * 0.3
			if s > best_s:
				best_s = s
				best = [e, s]
	return best


func _throw_choice(now: float) -> Array:
	var keep := showmanship * 0.8 if held.is_dance_prop() else 0.0
	var best: Array = []
	var best_s := -INF
	for e: Dancer in manager.standing(1 - team):
		var d := global_position.distance_to(e.global_position)
		if d < THROW_MIN or d > THROW_MAX or not can_see(e.global_position):
			continue
		if _lane_blocked(e.global_position):
			continue
		var s := 0.3 + aggression * 1.4 - keep - caution * 0.2 - 0.25 * d / THROW_MAX
		if e == last_attacker and now - last_attacked_at < 8.0:
			s += grudge * 1.2
		if e.held != null and e.held.is_dance_prop():
			s += 0.3
		if s > best_s:
			best_s = s
			best = [e, s]
	return best


func _lane_blocked(to: Vector3) -> bool:
	var a := Vector2(global_position.x, global_position.z)
	var ab := Vector2(to.x, to.z) - a
	for m: Dancer in manager.team_dancers(team):
		if m == self or m.ragdoll != null:
			continue
		var p := Vector2(m.global_position.x, m.global_position.z)
		var u := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.001), 0.0, 1.0)
		if u > 0.05 and (a + ab * u).distance_to(p) < 0.8:
			return true
	return false


func _fetch_choice() -> Array:
	var remaining: float = manager.remaining_fraction()
	var best: Array = []
	var best_s := -INF
	for p: Prop in manager.props:
		if not p.is_available():
			continue
		if p.kind == Prop.Kind.HAT:
			if hat != null:
				continue
		elif held != null:
			continue
		if p.claimed_by != null and p.claimed_by != self and is_instance_valid(p.claimed_by):
			continue
		var d := global_position.distance_to(p.global_position)
		if d > 14.0:
			continue
		var value := aggression * 1.2
		if p.is_dance_prop():
			value += showmanship * 1.8 * remaining
		var s := value * Tune.v("fetch_mult") * (1.0 - d / 14.0) + 0.2 - caution * 0.15
		if s > best_s:
			best_s = s
			best = [p, s]
	return best


# ---------------------------------------------------------------- dancing

func _do_dance(delta: float) -> void:
	var spot := _dance_spot()
	var to := spot - global_position
	to.y = 0.0
	var d := to.length()
	# a spot a few metres off (a strike move's rival, home after a small shove) is danced
	# towards; only a long way off does the dancer stop and run back. A charging crew travels
	# the whole stage on the beat - the walk-up is part of the number, not a break from it
	var travel := DRIFT_SPEED
	var reach := 5.0
	if strike_target != null and manager.stance[team] == "charge":
		travel = Tune.v("charge_speed")
		reach = 12.0
	if not returning and d > RETURN_DIST and d < reach:
		to *= RETURN_DIST * 0.8 / d
		d = to.length()
	if d > RETURN_DIST:
		returning = true
	elif d < 0.8:
		returning = false
	if returning:
		velocity = to.normalized() * WALK_SPEED
		_face(spot, delta)
		_move()
		_run_pose(delta)
		return
	velocity = to.normalized() * minf(travel, d * 3.0) if d > 0.12 else Vector3.ZERO
	_move()
	if strike_target != null and is_instance_valid(strike_target):
		_face(strike_target.global_position, delta)
	else:
		# square up to the other lot, opened out to the audience as far as showmanship takes him
		var at: Vector3 = manager.crew_centre(1 - team) - global_position
		at.y = 0.0
		var w := showmanship * 0.8
		var dir := CROWD_DIR
		if at.length() > 0.01:
			dir = at.normalized() * (1.0 - w) + CROWD_DIR * w
		# a twerk is danced with the back to them
		if joined and Moves.REAR.has(move):
			dir = -dir
		_face(global_position + dir, delta)
	var t := fposmod(float(manager.beat_f) - float(phrase_start) + tempo_err, float(Moves.beats(move)))
	_apply_pose(Moves.pose(move if joined else "", t), delta)


## His place in the crew's wedge, wherever the crew has advanced it to; on a strike move an
## aggressive dancer drifts up to a rival within reach of a kick, and a cautious one edges away.
func _dance_spot() -> Vector3:
	var home: Vector3 = manager.formation_spot(team, slot)
	strike_target = null
	# a crew charge: everyone dances the strike move into the rival the charge named, fanned
	# round him on the crew's side so every kick on the beat has him in reach
	if manager.stance[team] == "charge" and not Moves.strikes(move).is_empty() and manager.charge_mode[team] == "line":
		var mine: Dancer = manager.matchup_for(self)
		if mine != null:
			strike_target = mine
			var toward: Vector3 = manager.crew_centre(team) - mine.global_position
			toward.y = 0.0
			if absf(toward.x) < 0.01:
				toward = Vector3(_side(), 0, 0)
			# square up to him from our side of the stage, so the two lines face each other
			return Stage.clamp_in(mine.global_position + Vector3(signf(toward.x), 0, 0) * 1.3, 0.6)
	if manager.stance[team] == "charge" and not Moves.strikes(move).is_empty():
		var f = manager.focus[team]
		if f != null and is_instance_valid(f) and f.ragdoll == null:
			strike_target = f
			var back: Vector3 = manager.crew_centre(team) - f.global_position
			back.y = 0.0
			if back.length() < 0.01:
				back = Vector3(_side(), 0, 0)
			var fan := back.normalized().rotated(Vector3.UP, float(slot - 2) * 0.55)
			return Stage.clamp_in(f.global_position + fan * 1.3, 0.6)
	# pressing up close, the crew's hard men kick at whoever is nearest on the strike beats
	if joined and manager.stance[team] == "press" and not Moves.strikes(move).is_empty() and aggression > 0.5:
		var best: Dancer = null
		var best_d := 5.0
		for e: Dancer in manager.standing(1 - team):
			var dd := global_position.distance_to(e.global_position)
			if dd < best_d:
				best_d = dd
				best = e
		if best != null:
			strike_target = best
			var away := global_position - best.global_position
			away.y = 0.0
			if away.length() < 0.01:
				away = Vector3(_side(), 0, 0)
			return Stage.clamp_in(best.global_position + away.normalized() * 1.3, 0.6)
	# nobody wants a boot in the face while he's dancing: edge away from any rival on a kicking
	# or punching move close by (the cautious most of all), and the cautious from any rival at all
	var shy: float = Tune.v("shy_dist")
	for e: Dancer in manager.standing(1 - team):
		var off := home - e.global_position
		off.y = 0.0
		var dd := off.length()
		if dd < 0.01:
			continue
		var threat: bool = e.joined and not Moves.strikes(e.move).is_empty()
		if threat and dd < shy:
			home += off / dd * (shy - dd) * (0.4 + 0.6 * caution)
		elif caution > 0.55 and dd < 2.5:
			home += off / dd * (2.5 - dd) * caution
	return Stage.clamp_in(home, 0.6)


## Called by the manager on every beat, after the calls for a new phrase are made.
func on_beat(b: int, call: String) -> void:
	stats["beats"] += 1.0
	var dancing := is_dancing()
	if b % Moves.BLOCK == 0:
		if block_beats >= Moves.BLOCK and block_ok:
			_score_block()
		block_beats = 0
		block_on_time = 0
		block_ok = true
		fumbled = rng.randf() < float(Moves.FUMBLE[Moves.tier(move)]) * fumble_mult * (1.0 + 2.0 * wear())
	if b % Moves.PHRASE == 0:
		var was := move
		var was_following := joined and not freestyle
		phrase_start = b
		joined = dancing
		freestyle = rng.randf() < (1.0 - discipline) * 0.35
		if freestyle:
			var canes := 1 if held != null and held.kind == Prop.Kind.CANE else 0
			move = Moves.choose(rng, showmanship, aggression, false, canes, [call])
			stats["freestyles"] += 1.0
		else:
			move = call
		if was_following and was == move:
			adopt_delay = 0.0
		else:
			adopt_delay = maxf(adopt_base * (1.3 - discipline * 0.6) + rng.randfn(0.0, 0.15), 0.0)
		recent_moves.append(move)
		if recent_moves.size() > 4:
			recent_moves.pop_front()
		fumbled = rng.randf() < float(Moves.FUMBLE[Moves.tier(move)]) * fumble_mult * (1.0 + 2.0 * wear())
	# a dancer who stopped mid-phrase may pick the call up again at the next bar
	if not joined and dancing and b % Moves.BLOCK == 0 and b % Moves.PHRASE != 0 and Tune.v("rejoin_beats") <= 4.0:
		joined = true
	tempo_err = tempo_err * 0.7 + rng.randfn(0.0, timing_sigma * (1.0 + Tune.v("hurt_sloppy") * hurt + 1.5 * wear()))
	in_sync = false
	if dancing and joined:
		stats["dance_beats"] += 1.0
		block_beats += 1
		var on_time := absf(tempo_err) < TIMING_TOL
		if on_time:
			block_on_time += 1
		var k := b - phrase_start
		in_sync = (not freestyle) and move == call and on_time and float(k) >= adopt_delay
		if in_sync:
			stats["sync_beats"] += 1.0
		if on_time:
			_try_strike(b)
		if fumbled and k % Moves.BLOCK == 1:
			_wobble = 0.4
	else:
		joined = false
		block_ok = false


func _score_block() -> void:
	var q := execution * (1.0 - 0.8 * wear())
	if fumbled:
		q *= 0.3
		stats["fumbles"] += 1.0
	q *= 0.5 + 0.5 * float(block_on_time) / float(Moves.BLOCK)
	# dance at whoever you like; playing it out to the audience earns a little extra
	q *= 1.0 + Tune.v("crowd_bonus") * maxf((-facing() if Moves.REAR.has(move) else facing()).dot(CROWD_DIR), 0.0)
	var repeats := 0
	for i in range(0, recent_moves.size() - 1):
		if recent_moves[i] == move:
			repeats += 1
	q *= maxf(1.0 - 0.2 * float(repeats), 0.4)
	# a crew that mixes its styles - ballet into burlesque into cheer - pleases the judges
	q *= 1.0 + Tune.v("style_bonus") * manager.style_mix(team)
	# a hat to tip and a cane to twirl: hand work, so arm sets how much each adds
	var kit := 0.0
	if hat != null:
		kit += 0.15
	if held != null and held.is_dance_prop():
		kit += 0.2
	q *= 1.0 + kit * clampf(arm_skill, 0.0, 1.5)
	if String(Moves.BOOK[move]["prop"]) == "cane" and (held == null or held.kind != Prop.Kind.CANE):
		q *= 0.6
	if Moves.ARM_MOVES.has(move):
		# arm work - claps, shimmies, spins, windmills, twirls - is judged partly on the arms
		q *= 0.8 + 0.4 * clampf(arm_skill, 0.0, 1.5)
	var pts := float(Moves.TIER_PTS[Moves.tier(move)]) * q
	stats["flair"] += pts
	manager.add_flair(team, pts, false)
	if pts >= 0.5:
		_pop("+%d" % maxi(int(round(pts)), 1), Color(1.0, 0.9, 0.35))


func _try_strike(b: int) -> void:
	var st := Moves.strikes(move)
	if st.is_empty():
		return
	var local := (b - phrase_start) % Moves.beats(move)
	if not st.has(local):
		return
	var reach: float = STRIKE_REACH[String(Moves.BOOK[move]["strike"])]
	if held != null and held.kind == Prop.Kind.CANE:
		reach += 0.5
	var victim: Dancer = null
	var best_d := reach
	for e: Dancer in manager.standing(1 - team):
		var off := e.global_position - global_position
		off.y = 0.0
		var d := off.length()
		if d < best_d and (d < 0.4 or facing().dot(off / maxf(d, 0.001)) > 0.25):
			best_d = d
			victim = e
	if victim == null:
		return
	stats["strikes"] += 1.0
	# a dancer who sees it coming may slip it - a duck and a lean - and keep dancing
	if victim.is_dancing() and victim.can_see(global_position) \
			and rng.randf() < Tune.v("slip_base") + Tune.v("slip_caution") * victim.caution:
		victim._slip(_sidestep_for(victim))
		return
	if victim.can_see(global_position) and rng.randf() < 0.05 + 0.3 * victim.caution:
		victim._start_dodge(_sidestep_for(victim))
		return
	if rng.randf() > 0.8:
		return
	stats["strike_hits"] += 1.0
	var pts := Tune.v("strike_pts") * clampf(execution * (1.0 - 0.8 * wear()), 0.2, 1.4)
	stats["flair"] += pts
	stats["strike_pts"] += pts
	manager.add_flair(team, pts, true)
	_pop("+%d!" % int(round(pts)), Color(1.0, 0.38, 0.25), true)
	victim.take_hit(self, "strike", victim.global_position - global_position, strength_skill)


## Slipping a blow: a quick duck and lean to one side, still dancing.
func _slip(side_dir: Vector3) -> void:
	_slip_t = 0.4
	var right := global_transform.basis.x
	_slip_side = 1.0 if side_dir.dot(right) >= 0.0 else -1.0
	stats["dodges"] += 1.0
	_pop("slip!", Color(0.85, 0.95, 1.0))


## A score (or a slip) floats up over his head and fades.
func _pop(text: String, col: Color, big := false) -> void:
	if manager == null or manager.headless or manager.world == null or not is_inside_tree():
		return
	var l := Label3D.new()
	l.text = text
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.font_size = 60 if big else 40
	l.pixel_size = 0.01
	l.outline_size = 12
	l.outline_modulate = Color(0.1, 0.05, 0.05)
	l.modulate = col
	manager.world.add_child(l)
	var start := global_position + Vector3(rng.randf_range(-0.25, 0.25), 2.55, 0.0)
	l.global_position = start
	var tw := l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "global_position:y", start.y + 1.1, 0.95)
	tw.tween_property(l, "modulate:a", 0.0, 0.6).set_delay(0.35)
	tw.chain().tween_callback(l.queue_free)


func _sidestep_for(victim: Dancer) -> Vector3:
	var dir := victim.global_position - global_position
	dir.y = 0.0
	var perp := Vector3(-dir.z, 0, dir.x).normalized()
	return perp if rng.randf() < 0.5 else -perp


# ---------------------------------------------------------------- fighting

func _do_brawl(delta: float) -> void:
	if target == null or not is_instance_valid(target) or target.ragdoll != null:
		_punch_t = 0.0
		_set_action("dance", null, null)
		decide_timer = 0.0
		return
	var to := target.global_position - global_position
	to.y = 0.0
	var d := to.length()
	_face(target.global_position, delta)
	if _punch_t > 0.0:
		velocity = Vector3.ZERO
		_punch_t -= delta
		arm_r.rotation.x = lerpf(arm_r.rotation.x, -1.1, clampf(delta * 14.0, 0.0, 1.0))
		if _punch_t <= 0.0:
			_punch_land()
		return
	if d > PUNCH_RANGE:
		velocity = to.normalized() * WALK_SPEED
		_run_up += WALK_SPEED * delta
		_move()
		_run_pose(delta)
		return
	velocity = Vector3.ZERO
	if _run_up > 2.5:
		_run_up = 0.0
		_barge()
		return
	_run_up = 0.0
	if _punch_cd <= 0.0:
		_punch_t = PUNCH_WINDUP
		stats["punches"] += 1.0
		target.notice_attack(self)
	_fists_pose(delta)


func _barge() -> void:
	stats["punches"] += 1.0
	_punch_cd = PUNCH_COOLDOWN
	if target.can_see(global_position) and rng.randf() < 0.1 + 0.4 * target.caution:
		target._start_dodge(_sidestep_for(target))
		return
	stats["punch_hits"] += 1.0
	target.take_hit(self, "barge", target.global_position - global_position, strength_skill + 0.1)


func _punch_land() -> void:
	_punch_cd = PUNCH_COOLDOWN
	arm_r.rotation.x = 1.6
	if target == null or not is_instance_valid(target) or target.ragdoll != null or target._dodge_t > 0.0:
		return
	var off := target.global_position - global_position
	off.y = 0.0
	if off.length() > PUNCH_RANGE + 0.35 or facing().dot(off.normalized()) < 0.3:
		return
	if rng.randf() > 0.8:
		return
	stats["punch_hits"] += 1.0
	target.take_hit(self, "punch", off, strength_skill)


func notice_attack(by: Dancer) -> void:
	if ragdoll != null or not can_see(by.global_position):
		return
	if rng.randf() < 0.1 + 0.45 * caution:
		var dir := global_position - by.global_position
		dir.y = 0.0
		var perp := Vector3(-dir.z, 0, dir.x).normalized()
		_pending_dodge = 0.08
		_pending_dodge_dir = perp if rng.randf() < 0.5 else -perp


func _start_dodge(dir: Vector3) -> void:
	if ragdoll != null or _dodge_t > 0.0 or dir.length_squared() < 0.0001:
		return
	_dodge_dir = Vector3(dir.x, 0, dir.z).normalized()
	_dodge_t = 0.4
	_punch_t = 0.0
	_throw_t = 0.0
	stats["dodges"] += 1.0


func _do_fetch(delta: float) -> void:
	if claim == null or not is_instance_valid(claim) or not claim.is_available():
		_set_action("dance", null, null)
		decide_timer = 0.0
		return
	var to := claim.global_position - global_position
	to.y = 0.0
	if to.length() <= PICKUP_RANGE:
		var p := claim
		p.take(self)
		if p.kind == Prop.Kind.HAT and hat == null:
			hat = p
		else:
			held = p
		claim = null
		stats["pickups"] += 1.0
		_set_action("dance", null, null)
		decide_timer = 0.0
		return
	velocity = to.normalized() * WALK_SPEED
	_face(claim.global_position, delta)
	_move()
	_run_pose(delta)


func _do_throw(delta: float) -> void:
	if held == null or target == null or not is_instance_valid(target):
		_throw_t = 0.0
		_set_action("dance", null, null)
		return
	velocity = Vector3.ZERO
	_face(target.global_position, delta)
	arm_r.rotation.x = lerpf(arm_r.rotation.x, -2.5, clampf(delta * 12.0, 0.0, 1.0))
	_throw_t -= delta
	if _throw_t <= 0.0:
		_release()
		_set_action("dance", null, null)
		decide_timer = 0.0


func _release() -> void:
	var p := held
	held = null
	var from := hand_anchor.global_position
	var aim := target.global_position + Vector3(0, 1.1, 0)
	var flight := from.distance_to(aim) / throw_speed
	aim += target.velocity * flight * 0.6
	var v := _ballistic(from, aim, throw_speed)
	v = v.rotated(Vector3.UP, deg_to_rad(rng.randfn(0.0, throw_err)))
	var side := v.cross(Vector3.UP)
	if side.length() > 0.01:
		v = v.rotated(side.normalized(), deg_to_rad(rng.randfn(0.0, throw_err * 0.5)))
	stats["throws"] += 1.0
	p.throw_to(from, v, self)
	manager.prop_thrown(self, from, v)
	arm_r.rotation.x = 1.8


static func _ballistic(from: Vector3, to: Vector3, v: float) -> Vector3:
	var g := 9.8
	var dxz := Vector3(to.x - from.x, 0, to.z - from.z)
	var r := dxz.length()
	var h := to.y - from.y
	var dir := dxz / maxf(r, 0.001)
	var v2 := v * v
	var disc := v2 * v2 - g * (g * r * r + 2.0 * h * v2)
	var ang := PI * 0.25
	if disc >= 0.0 and r > 0.01:
		ang = atan((v2 - sqrt(disc)) / (g * r))
	return dir * v * cos(ang) + Vector3.UP * v * sin(ang)


## Manager: a prop has just left someone's hand. A dancer who sees it coming his way may sidestep.
func consider_throw(by: Dancer, from: Vector3, v: Vector3) -> void:
	if by == self or ragdoll != null or not can_see(from):
		return
	var vxz := Vector2(v.x, v.z)
	var sp2 := vxz.length_squared()
	if sp2 < 0.01:
		return
	var me := Vector2(global_position.x, global_position.z)
	var src := Vector2(from.x, from.z)
	var tc := clampf((me - src).dot(vxz) / sp2, 0.0, 2.5)
	var closest := src + vxz * tc
	if closest.distance_to(me) > 1.0:
		return
	if rng.randf() > 0.3 + 0.5 * caution:
		return
	var react := rng.randf_range(0.14, 0.34) - 0.08 * caution
	if react >= tc:
		return
	var perp := Vector3(-v.z, 0, v.x).normalized()
	if Vector2(perp.x, perp.z).dot(me - closest) < 0.0:
		perp = -perp
	_pending_dodge = react
	_pending_dodge_dir = perp


func prop_hit(p: Prop) -> void:
	var by := p.thrower
	var power := 0.5
	if by != null and is_instance_valid(by):
		power = by.arm_skill
		if by.team == team:
			by.stats["friendly_hits"] += 1.0
		else:
			by.stats["throw_hits"] += 1.0
	if p.kind == Prop.Kind.LID:
		power += 0.2
	elif p.kind == Prop.Kind.HAT:
		power -= 0.15
	take_hit(by, "throw", p.linear_velocity, power)


func take_hit(by: Dancer, how: String, dir: Vector3, power: float) -> void:
	if ragdoll != null or manager == null or not manager.running:
		return
	var now: float = manager.elapsed
	if by != null and is_instance_valid(by) and by.team != team:
		last_attacker = by
		last_attacked_at = now
	block_ok = false
	stats["hits_taken"] += 1.0
	flash(Color(1, 1, 1))
	# every hit tells: he slows, goes ragged on the beat, and his nose goes
	hurt = minf(hurt + Tune.v("hurt_hit"), Tune.v("hurt_max"))
	_gush()
	var kd := Tune.v("kd_base") + 0.35 * (power - balance_skill)
	kd = clampf(kd, 0.08, 0.92)
	if now - _got_up_at < GETUP_GRACE:
		kd = 0.0
	if rng.randf() < kd:
		_knock_down(by, how, dir, power, now)
	else:
		_stagger = 0.35
		_punch_t = 0.0
		_throw_t = 0.0


## Every time he goes down he gets up a little worse: timing, execution and fumble risk all suffer.
func wear() -> float:
	return minf(float(stats["floored"]) * Tune.v("wear_per_fall"), 0.5)


func _knock_down(by: Dancer, how: String, dir: Vector3, power: float, now: float) -> void:
	stats["floored"] += 1.0
	if by != null and is_instance_valid(by) and by.team != team:
		by.stats["knockdowns"] += 1.0
		by._had_enough[self] = now + 5.0
	manager.note_knockdown(by, self, how)
	var flat := Vector3(dir.x, 0, dir.z)
	if flat.length() < 0.01:
		flat = Vector3(-_side(), 0, 0)
	flat = flat.normalized()
	if held != null:
		var h := held
		held = null
		h.drop(_hold_transform().origin, flat * 2.0 + Vector3(0, 2.5, 0))
	if hat != null:
		var hh := hat
		hat = null
		hh.drop(hat_anchor.global_position, flat * 1.5 + Vector3(0, 3.0, 0))
	if claim != null and is_instance_valid(claim) and claim.claimed_by == self:
		claim.claimed_by = null
	claim = null
	target = null
	action = "dance"
	returning = false
	_punch_t = 0.0
	_throw_t = 0.0
	_dodge_t = 0.0
	_pending_dodge = -1.0
	joined = false
	in_sync = false
	var prior := maxf(float(stats["floored"]) - 1.0, 0.0)
	_down = down_base * Tune.v("down_mult") * (1.0 + Tune.v("down_per_fall") * minf(prior, 8.0)) + (0.6 if now - _last_floored < 6.0 else 0.0)
	_last_floored = now
	_spawn_ragdoll()
	if ragdoll != null:
		ragdoll.shove(flat * (3.0 + 2.0 * clampf(power, 0.0, 1.5)) + Vector3(0, -2.0, 0))
	_stars(global_position + Vector3(0, 1.5, 0))


## The nosebleed follows the damage: the trickle lengthens with it and drips while it is bad.
func _update_blood() -> void:
	if _trickle == null:
		return
	var bleeding := hurt > 0.02
	_trickle.visible = bleeding
	if bleeding:
		var k := clampf(hurt / 0.3, 0.35, 1.6)
		_trickle.scale = Vector3(1.0, k, 1.0)
		_trickle.position.y = 1.62 - 0.07 * k
	if _drip != null:
		_drip.emitting = hurt > 0.05


## A spray from the nose the moment a hit lands.
func _gush() -> void:
	if manager == null or manager.world == null or manager.headless or body_root == null:
		return
	var p := CPUParticles3D.new()
	p.emitting = false
	p.one_shot = true
	p.amount = 28
	p.lifetime = 0.9
	p.explosiveness = 0.85
	p.direction = facing() + Vector3(0, 0.3, 0)
	p.spread = 35.0
	p.initial_velocity_min = 1.5
	p.initial_velocity_max = 3.5
	p.gravity = Vector3(0, -9.8, 0)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.2
	var m := SphereMesh.new()
	m.radius = 0.035
	m.height = 0.07
	m.radial_segments = 6
	m.rings = 3
	p.mesh = m
	p.material_override = _blood_mat
	manager.world.add_child(p)
	p.global_position = body_root.to_global(Vector3(0, 1.62, -0.17))
	p.emitting = true
	get_tree().create_timer(1.3).timeout.connect(p.queue_free)


func _stars(at: Vector3) -> void:
	if manager == null or manager.world == null or manager.headless:
		return
	var p := CPUParticles3D.new()
	p.emitting = false
	p.one_shot = true
	p.amount = 24
	p.lifetime = 0.8
	p.explosiveness = 1.0
	p.direction = Vector3(0, 1, 0)
	p.spread = 70.0
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 5.0
	p.gravity = Vector3(0, -6, 0)
	var m := BoxMesh.new()
	m.size = Vector3(0.1, 0.1, 0.1)
	p.mesh = m
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.9, 0.2)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.8, 0.1)
	p.material_override = mat
	manager.world.add_child(p)
	p.global_position = at
	p.emitting = true
	get_tree().create_timer(1.2).timeout.connect(p.queue_free)


func _spawn_ragdoll() -> void:
	if ragdoll != null or manager == null or manager.world == null:
		return
	ragdoll = Ragdoll.new()
	manager.world.add_child(ragdoll)
	var pose := global_transform
	pose.origin.y = 0.0
	ragdoll.build(pose, _mat, _dark_mat, _skin_mat, _trouser_mat)
	body_root.visible = false
	label.visible = false


func _follow_ragdoll() -> void:
	if ragdoll == null:
		return
	global_position = Stage.clamp_in(ragdoll.torso_position(), 0.4)


func _get_up() -> void:
	if ragdoll != null:
		_follow_ragdoll()
		ragdoll.queue_free()
		ragdoll = null
	body_root.visible = true
	body_root.rotation = Vector3.ZERO
	body_root.position = Vector3.ZERO
	label.visible = true
	_stagger = 0.0
	action = "dance"
	decide_timer = 0.0
	if manager != null:
		_got_up_at = float(manager.elapsed)
		# every time he's put down he takes longer to get back up, and longer still while he's hurt
		if not manager.celebrating:
			var prior := maxf(float(stats["floored"]) - 1.0, 0.0)
			_rise_len = minf((Tune.v("rise_base") + Tune.v("rise_per_fall") * prior) * (1.0 + hurt), 5.0)
			_rise_t = _rise_len


## Hands on knees, pushing himself up from a crouch, swaying - slower the more he's been floored.
func _rise_pose(delta: float) -> void:
	var u := 1.0 - clampf(_rise_t / maxf(_rise_len, 0.01), 0.0, 1.0)
	var p := Moves.pose("", 0.0)
	Moves._low(p, 1.25 * (1.0 - u), 0.9 * (1.0 - u) + 0.1)
	var wob := sin(float(Time.get_ticks_msec()) * 0.012)
	p["tilt"] = wob * 0.12 * (1.0 - u)
	p["nod"] = float(p["nod"]) + 0.3 * (1.0 - u)
	_apply_pose(p, delta)


# ---------------------------------------------------------------- poses

func _limb_to(n: Node3D, r: Vector3, k: float) -> void:
	n.rotation = Vector3(lerp_angle(n.rotation.x, r.x, k), lerp_angle(n.rotation.y, r.y, k), lerp_angle(n.rotation.z, r.z, k))


func _apply_pose(p: Dictionary, delta: float) -> void:
	if _slip_t > 0.0:
		var sk := sin(clampf(_slip_t / 0.4, 0.0, 1.0) * PI)
		p["sway"] = float(p["sway"]) + _slip_side * 0.45 * sk
		p["tilt"] = float(p["tilt"]) - _slip_side * 0.25 * sk
		p["hunch"] = float(p.get("hunch", 0.0)) + 0.35 * sk
		_slip_t -= delta
	var k := clampf(delta * 16.0, 0.0, 1.0)
	var wob := sin(float(Time.get_ticks_msec()) * 0.03) * 0.3 * clampf(_wobble / 0.4, 0.0, 1.0)
	body_root.rotation = Vector3(
		lerp_angle(body_root.rotation.x, float(p["lean"]), k),
		lerp_angle(body_root.rotation.y, float(p["yaw"]), k),
		lerp_angle(body_root.rotation.z, float(p["tilt"]) + wob, k))
	body_root.position = body_root.position.lerp(Vector3(float(p["sway"]), float(p["bob"]), float(p.get("glide", 0.0))), k)
	_limb_to(arm_l, p["arm_l"], k)
	_limb_to(arm_r, p["arm_r"], k)
	_limb_to(leg_l, p["leg_l"], k)
	_limb_to(leg_r, p["leg_r"], k)
	# the joints: waist, neck, elbows, knees (a hurt dancer droops and dances smaller)
	var droop := hurt * 0.6 + wear() * 0.5
	_limb_to(upper, Vector3(-float(p.get("hunch", 0.0)) - droop * 0.5, float(p.get("twist", 0.0)), float(p.get("counter", 0.0))), k)
	_limb_to(head_node, Vector3(-float(p.get("nod", 0.0)) - droop * 0.4, float(p.get("turn", 0.0)), float(p.get("cock", 0.0))), k)
	_limb_to(fore_l, Vector3(float(p.get("elbow_l", 0.3)), 0, 0), k)
	_limb_to(fore_r, Vector3(float(p.get("elbow_r", 0.3)), 0, 0), k)
	_limb_to(shin_l, Vector3(-float(p.get("knee_l", 0.0)), 0, 0), k)
	_limb_to(shin_r, Vector3(-float(p.get("knee_r", 0.0)), 0, 0), k)


## Back to a neutral frame for the poses that don't use the joints (running, brawling, cheering).
func _relax(k: float, knee_l := 0.0, knee_r := 0.0) -> void:
	_limb_to(upper, Vector3.ZERO, k)
	_limb_to(head_node, Vector3.ZERO, k)
	_limb_to(fore_l, Vector3(0.3, 0, 0), k)
	_limb_to(fore_r, Vector3(0.3, 0, 0), k)
	_limb_to(shin_l, Vector3(-knee_l, 0, 0), k)
	_limb_to(shin_r, Vector3(-knee_r, 0, 0), k)


func _run_pose(delta: float) -> void:
	_gait += delta * velocity.length() * 1.8
	var s := sin(_gait)
	var k := clampf(delta * 12.0, 0.0, 1.0)
	body_root.rotation = Vector3(lerp_angle(body_root.rotation.x, -0.12, k), lerp_angle(body_root.rotation.y, 0.0, k), lerp_angle(body_root.rotation.z, 0.0, k))
	body_root.position = body_root.position.lerp(Vector3(0, absf(s) * 0.05, 0), k)
	_relax(k, maxf(-s, 0.0) * 1.1, maxf(s, 0.0) * 1.1)
	_limb_to(fore_l, Vector3(0.9, 0, 0), k)
	_limb_to(fore_r, Vector3(0.9, 0, 0), k)
	_limb_to(leg_l, Vector3(s * 0.7, 0, 0), k)
	_limb_to(leg_r, Vector3(-s * 0.7, 0, 0), k)
	_limb_to(arm_l, Vector3(-s * 0.5, 0, -0.1), k)
	if _punch_t <= 0.0 and _throw_t <= 0.0:
		_limb_to(arm_r, Vector3(s * 0.5, 0, 0.1), k)


func _fists_pose(delta: float) -> void:
	var k := clampf(delta * 12.0, 0.0, 1.0)
	body_root.rotation = Vector3(lerp_angle(body_root.rotation.x, -0.1, k), lerp_angle(body_root.rotation.y, 0.0, k), 0.0)
	body_root.position = body_root.position.lerp(Vector3(0, absf(sin(float(Time.get_ticks_msec()) * 0.008)) * 0.05, 0), k)
	_relax(k, 0.35, 0.35)
	_limb_to(fore_l, Vector3(1.6, 0, 0), k)
	_limb_to(fore_r, Vector3(1.6, 0, 0), k)
	_limb_to(arm_l, Vector3(1.3, 0, 0.3), k)
	_limb_to(arm_r, Vector3(1.1, 0, -0.3), k)
	_limb_to(leg_l, Vector3(0.25, 0, 0), k)
	_limb_to(leg_r, Vector3(-0.2, 0, 0), k)


# ---------------------------------------------------------------- celebration

## Manager: the judges have spoken. role = cheer / cry / shrug.
func celebrate(role: String) -> void:
	celeb_role = role
	_celeb_t = rng.randf() * 0.3
	if ragdoll != null:
		_get_up()
	_dodge_t = 0.0
	_pending_dodge = -1.0
	_punch_t = 0.0
	_throw_t = 0.0
	_stagger = 0.0
	action = role
	target = null
	velocity = Vector3.ZERO


func _celebrate(delta: float) -> void:
	_celeb_t += delta
	var phase: String = manager.celebration_phase
	_face(global_position + CROWD_DIR, delta)
	if phase == "judging":
		_apply_pose(Moves.pose("", float(manager.beat_f)), delta)
		return
	var k := clampf(delta * 8.0, 0.0, 1.0)
	_relax(k)
	match celeb_role:
		"cheer":
			if phase == "cheer":
				var beat: float = manager.beat_f
				var j := absf(sin(beat * PI))
				body_root.position = Vector3(0, j * 0.55, 0)
				body_root.rotation = Vector3(0.0, sin(beat * PI * 0.5) * 0.35, 0.0)
				arm_l.rotation = Vector3(2.9, 0, -0.35 - j * 0.25)
				arm_r.rotation = Vector3(2.9, 0, 0.35 + j * 0.25)
				leg_l.rotation = Vector3(j * 0.45, 0, 0)
				leg_r.rotation = Vector3(-j * 0.25, 0, 0)
			else:
				body_root.position = body_root.position.lerp(Vector3.ZERO, k)
				body_root.rotation = Vector3(0, lerp_angle(body_root.rotation.y, 0.0, k), 0)
				_limb_to(arm_r, Vector3(2.7, 0, 0.5 + sin(_celeb_t * 7.0) * 0.4), k)
				_limb_to(arm_l, Vector3(0.1, 0, -0.1), k)
				_limb_to(leg_l, Vector3.ZERO, k)
				_limb_to(leg_r, Vector3.ZERO, k)
		"cry":
			var shake := sin(_celeb_t * 14.0) * 0.03
			_limb_to(head_node, Vector3(-0.55, 0, 0), k)
			_limb_to(upper, Vector3(0.35, 0, 0), k)
			_limb_to(shin_l, Vector3(-1.5, 0, 0), k)
			_limb_to(shin_r, Vector3(-1.5, 0, 0), k)
			body_root.position = body_root.position.lerp(Vector3(0, -0.6 + shake, 0), k)
			body_root.rotation = Vector3(lerp_angle(body_root.rotation.x, -0.25, k), lerp_angle(body_root.rotation.y, 0.0, k), 0.0)
			_limb_to(leg_l, Vector3(1.45, 0, -0.1), k)
			_limb_to(leg_r, Vector3(1.45, 0, 0.1), k)
			_limb_to(arm_l, Vector3(2.35, 0, 0.35), k)
			_limb_to(arm_r, Vector3(2.35, 0, -0.35), k)
			if _tears == null and not manager.headless:
				_tears = _make_tears()
		_:
			var b2: float = manager.beat_f
			body_root.position = body_root.position.lerp(Vector3(0, absf(sin(b2 * PI)) * 0.06, 0), k)
			_limb_to(arm_l, Vector3(0.7, 0, -0.9), k)
			_limb_to(arm_r, Vector3(0.7, 0, 0.9), k)
			_limb_to(leg_l, Vector3.ZERO, k)
			_limb_to(leg_r, Vector3.ZERO, k)


func _make_tears() -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = 16
	p.lifetime = 0.7
	p.local_coords = true
	p.direction = Vector3(0, -1, -0.5)
	p.spread = 30.0
	p.initial_velocity_min = 0.6
	p.initial_velocity_max = 1.5
	p.gravity = Vector3(0, -6, 0)
	var m := SphereMesh.new()
	m.radius = 0.035
	m.height = 0.07
	m.radial_segments = 6
	m.rings = 3
	p.mesh = m
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.45, 0.75, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.6, 1.0)
	p.material_override = mat
	p.position = Vector3(0, 1.68, -0.18)
	body_root.add_child(p)
	p.emitting = true
	return p


func cleanup() -> void:
	if held != null and is_instance_valid(held):
		held.holder = null
	held = null
	if hat != null and is_instance_valid(hat):
		hat.holder = null
	hat = null
	if ragdoll != null and is_instance_valid(ragdoll):
		ragdoll.queue_free()
	ragdoll = null
