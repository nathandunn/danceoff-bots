class_name Moves
extends RefCounted
## The dance book. Every move lasts 4 or 8 beats and has a tier (1 easy .. 3 hard) that sets its
## flair value and its fumble risk. Some moves have strike beats: offsets inside the move where a
## kick or a swing lands on a rival standing in reach - a hit that is also a dance move.
## `pose()` turns a move and a beat position into limb angles.

const PHRASE := 8           # beats per captain's call (two bars)
const BLOCK := 4            # flair is scored per four-beat block
const TIER_PTS := [0.0, 2.0, 4.0, 7.0]     # flair per block at perfect execution
const FUMBLE := [0.0, 0.04, 0.12, 0.26]    # fumble chance per block, times the build's factor

# moves whose execution depends on the arms (PlayerBuild arm)
const ARM_MOVES: Array[String] = ["clap_snap", "shimmy", "spin", "jazz_hands", "windmill", "cane_twirl", "jab_line", "disco_point", "robot", "charleston", "twerk", "hip_roll", "booty_drop"]

const BOOK := {
	"step_touch": {"label": "Step-touch", "beats": 4, "tier": 1, "strikes": [], "strike": "", "prop": ""},
	"clap_snap": {"label": "Clap-snap", "beats": 4, "tier": 1, "strikes": [], "strike": "", "prop": ""},
	"shimmy": {"label": "Shimmy", "beats": 4, "tier": 1, "strikes": [], "strike": "", "prop": ""},
	"spin": {"label": "Spin", "beats": 4, "tier": 2, "strikes": [], "strike": "", "prop": ""},
	"kick_line": {"label": "Kick line", "beats": 8, "tier": 2, "strikes": [1, 3, 5, 7], "strike": "kick", "prop": ""},
	"jazz_hands": {"label": "Jazz hands", "beats": 4, "tier": 2, "strikes": [], "strike": "", "prop": ""},
	"grapevine": {"label": "Grapevine", "beats": 8, "tier": 2, "strikes": [], "strike": "", "prop": ""},
	"knee_slide": {"label": "Knee slide", "beats": 4, "tier": 3, "strikes": [], "strike": "", "prop": ""},
	"leap": {"label": "Leap", "beats": 4, "tier": 3, "strikes": [2], "strike": "kick", "prop": ""},
	"windmill": {"label": "Windmill", "beats": 8, "tier": 3, "strikes": [2, 6], "strike": "swing", "prop": ""},
	"cane_twirl": {"label": "Cane twirl", "beats": 8, "tier": 3, "strikes": [4], "strike": "swing", "prop": "cane"},
	# fighting that is dancing: a whole crew throwing these together, on the beat, is a routine
	"spin_kick": {"label": "Spin kick", "beats": 4, "tier": 3, "strikes": [2], "strike": "kick", "prop": ""},
	"jab_line": {"label": "Jab line", "beats": 8, "tier": 2, "strikes": [1, 3, 5, 7], "strike": "punch", "prop": ""},
	# the new routines
	"the_twist": {"label": "The twist", "beats": 4, "tier": 1, "strikes": [], "strike": "", "prop": ""},
	"disco_point": {"label": "Disco point", "beats": 8, "tier": 2, "strikes": [], "strike": "", "prop": ""},
	"robot": {"label": "Robot", "beats": 4, "tier": 2, "strikes": [], "strike": "", "prop": ""},
	"charleston": {"label": "Charleston", "beats": 8, "tier": 2, "strikes": [], "strike": "", "prop": ""},
	"moonwalk": {"label": "Moonwalk", "beats": 8, "tier": 3, "strikes": [], "strike": "", "prop": ""},
	"cancan": {"label": "Can-can", "beats": 8, "tier": 3, "strikes": [], "strike": "", "prop": ""},
	# the hip-shaking numbers (cartoon blocks, mind)
	"hip_roll": {"label": "Hip roll", "beats": 4, "tier": 1, "strikes": [], "strike": "", "prop": ""},
	"twerk": {"label": "Twerk", "beats": 4, "tier": 2, "strikes": [], "strike": "", "prop": ""},
	"booty_drop": {"label": "Booty drop", "beats": 4, "tier": 3, "strikes": [], "strike": "", "prop": ""},
}

# how much of the all-purpose groove (knee give, head nod, shoulder roll) each move keeps
const GROOVE := {"knee_slide": 0.0, "leap": 0.0, "spin_kick": 0.0, "moonwalk": 0.0, "cancan": 0.0, "twerk": 0.0, "booty_drop": 0.0, "robot": 0.2}

const NAMES: Array[String] = ["step_touch", "clap_snap", "shimmy", "spin", "kick_line", "jazz_hands",
	"grapevine", "knee_slide", "leap", "windmill", "cane_twirl", "spin_kick", "jab_line", "the_twist", "disco_point", "robot", "charleston", "moonwalk", "cancan", "hip_roll", "twerk", "booty_drop"]


static func tier(m: String) -> int:
	if not BOOK.has(m):
		return 1
	return int(BOOK[m]["tier"])


static func beats(m: String) -> int:
	if not BOOK.has(m):
		return 4
	return int(BOOK[m]["beats"])


static func strikes(m: String) -> Array:
	if not BOOK.has(m):
		return []
	return BOOK[m]["strikes"]


static func label(m: String) -> String:
	if not BOOK.has(m):
		return m
	return String(BOOK[m]["label"])


## Weighted pick of a move: showmanship wants the hard tiers, aggression wants strike moves when
## rivals are close, `avoid` (recent calls) is discounted, the cane twirl needs canes.
static func choose(rng: RandomNumberGenerator, show: float, aggr: float, rivals_near: bool, canes: int, avoid: Array) -> String:
	var names: Array[String] = []
	var weights: Array[float] = []
	var total := 0.0
	for m: String in NAMES:
		var tr := tier(m)
		var w := 1.0 + show * float(tr - 1) * 1.2 - (1.0 - show) * float(tr - 1) * 0.45
		w = maxf(w, 0.05)
		if not strikes(m).is_empty():
			w *= 1.0 + aggr * (1.6 if rivals_near else 0.25)
		if String(BOOK[m]["prop"]) == "cane":
			if canes < 1:
				continue
			w *= 1.4
		w *= pow(0.3, float(avoid.count(m)))
		names.append(m)
		weights.append(w)
		total += w
	var r := rng.randf() * total
	for i in names.size():
		r -= weights[i]
		if r <= 0.0:
			return names[i]
	return names[names.size() - 1]


## Limb angles for move `m` at beat position `t` (0 .. beats). Limbs hang from their pivots:
## +x swings a limb forward, PI points it straight up; z splays it sideways (left arm negative).
static func pose(m: String, t: float) -> Dictionary:
	var p := {"yaw": 0.0, "tilt": 0.0, "lean": 0.0, "bob": 0.0, "sway": 0.0,
		"arm_l": Vector3(0.15, 0, -0.1), "arm_r": Vector3(0.15, 0, 0.1), "leg_l": Vector3.ZERO, "leg_r": Vector3.ZERO,
		# joints: elbows and knees bend (+), the waist turns and rolls, the head nods (+ = chin down)
		"elbow_l": 0.3, "elbow_r": 0.3, "knee_l": 0.0, "knee_r": 0.0, "twist": 0.0, "counter": 0.0,
		"hunch": 0.0, "nod": 0.0, "turn": 0.0, "cock": 0.0, "glide": 0.0}
	var pulse := absf(sin(t * PI))
	match m:
		"step_touch":
			var s := sin(t * PI * 0.5)
			p["sway"] = s * 0.35
			p["tilt"] = -s * 0.08
			p["bob"] = pulse * 0.06
			p["leg_l"] = Vector3(maxf(s, 0.0) * 0.3, 0, 0)
			p["leg_r"] = Vector3(maxf(-s, 0.0) * 0.3, 0, 0)
			p["arm_l"] = Vector3(s * 0.5, 0, -0.15)
			p["arm_r"] = Vector3(-s * 0.5, 0, 0.15)
		"clap_snap":
			var c := absf(sin(t * PI * 0.5))
			p["arm_l"] = Vector3(lerpf(0.4, 2.9, c), 0, lerpf(-0.5, 0.25, c))
			p["arm_r"] = Vector3(lerpf(0.4, 2.9, c), 0, lerpf(0.5, -0.25, c))
			p["bob"] = pulse * 0.08
			p["yaw"] = sin(t * PI * 0.25) * 0.25
		"shimmy":
			var sh := sin(t * PI * 4.0)
			p["tilt"] = sh * 0.14
			p["lean"] = -0.12
			p["arm_l"] = Vector3(0.3, 0, -1.25 + sh * 0.15)
			p["arm_r"] = Vector3(0.3, 0, 1.25 + sh * 0.15)
			p["counter"] = sh * 0.22
			p["elbow_l"] = 0.9
			p["elbow_r"] = 0.9
			p["bob"] = pulse * 0.04
			p["leg_l"] = Vector3(0.15, 0, 0)
			p["leg_r"] = Vector3(-0.1, 0, 0)
		"spin":
			var u := clampf(t / 2.0, 0.0, 1.0)
			var e := u * u * (3.0 - 2.0 * u)
			p["yaw"] = -TAU * e
			var up := clampf((t - 2.0) / 0.5, 0.0, 1.0)
			p["arm_l"] = Vector3(lerpf(0.2, 2.8, up), 0, lerpf(-1.3, -0.3, up))
			p["arm_r"] = Vector3(lerpf(0.2, 2.8, up), 0, lerpf(1.3, 0.3, up))
			p["bob"] = sin(e * PI) * 0.12
		"kick_line":
			var f := t - floorf(t)
			var lift := 0.5 + 0.5 * cos(TAU * f)      # the kick peaks on the beat
			var right := int(round(t)) % 2 == 1
			p["leg_r"] = Vector3(lift * 1.5 if right else 0.0, 0, 0)
			p["leg_l"] = Vector3(0.0 if right else lift * 1.5, 0, 0)
			p["arm_l"] = Vector3(0.2, 0, -1.15)
			p["arm_r"] = Vector3(0.2, 0, 1.15)
			p["elbow_l"] = 0.0
			p["elbow_r"] = 0.0
			p["knee_r"] = (1.0 - lift) * 0.5 if right else 0.0
			p["knee_l"] = 0.0 if right else (1.0 - lift) * 0.5
			p["lean"] = lift * 0.12
			p["bob"] = lift * 0.05
		"jazz_hands":
			var jz := sin(t * PI * 8.0) * 0.12
			p["arm_l"] = Vector3(2.5, 0, -0.55 + jz)
			p["arm_r"] = Vector3(2.5, 0, 0.55 - jz)
			p["elbow_l"] = 0.35
			p["elbow_r"] = 0.35
			p["cock"] = sin(t * PI) * 0.2
			p["bob"] = pulse * 0.1
			p["tilt"] = sin(t * PI) * 0.1
			p["lean"] = 0.08
		"grapevine":
			var g := sin(t * PI * 0.25)
			p["sway"] = g * 0.8
			p["yaw"] = g * 0.3
			p["leg_l"] = Vector3(sin(t * PI) * 0.45, 0, 0)
			p["leg_r"] = Vector3(-sin(t * PI) * 0.45, 0, 0)
			p["arm_l"] = Vector3(-sin(t * PI) * 0.6, 0, -0.2)
			p["arm_r"] = Vector3(sin(t * PI) * 0.6, 0, 0.2)
			p["bob"] = pulse * 0.05
		"knee_slide":
			var low := clampf(t / 0.8, 0.0, 1.0) if t < 2.0 else clampf((4.0 - t) / 0.8, 0.0, 1.0)
			p["bob"] = -0.5 * low
			p["lean"] = 0.55 * low
			p["leg_l"] = Vector3(-1.1 * low, 0, 0)
			p["leg_r"] = Vector3(-1.1 * low, 0, 0)
			p["knee_l"] = 1.5 * low
			p["knee_r"] = 1.5 * low
			p["arm_l"] = Vector3(lerpf(0.2, 2.7, low), 0, -0.6 * low)
			p["arm_r"] = Vector3(lerpf(0.2, 2.7, low), 0, 0.6 * low)
		"leap":
			var h := sin(clampf((t - 1.0) / 2.0, 0.0, 1.0) * PI)
			p["bob"] = h * 0.9
			p["leg_l"] = Vector3(h * 1.3, 0, 0)
			p["leg_r"] = Vector3(-h * 1.0, 0, 0)
			p["arm_l"] = Vector3(0.3 + h * 2.4, 0, -0.4 * h)
			p["arm_r"] = Vector3(0.3 + h * 2.4, 0, 0.4 * h)
			p["knee_l"] = h * 1.0
			p["knee_r"] = h * 1.5
			p["elbow_l"] = 0.1
			p["elbow_r"] = 0.1
			p["lean"] = -0.15 * h
		"windmill":
			p["arm_r"] = Vector3(fposmod(t * PI, TAU), 0, 0.2)
			p["arm_l"] = Vector3(fposmod(t * PI + PI, TAU), 0, -0.2)
			p["yaw"] = sin(t * PI * 0.25) * 0.5
			p["lean"] = -0.2
			p["bob"] = pulse * 0.05
			p["leg_l"] = Vector3(0.25, 0, 0)
			p["leg_r"] = Vector3(-0.25, 0, 0)
		"cane_twirl":
			var c2 := absf(sin(t * PI * 0.25))
			p["arm_r"] = Vector3(1.3 + sin(t * PI * 2.0) * 0.35, 0, 0.3)
			p["elbow_r"] = 0.7 + sin(t * PI * 2.0) * 0.4
			p["arm_l"] = Vector3(lerpf(0.3, 2.6, c2), 0, -0.3)
			p["sway"] = sin(t * PI * 0.5) * 0.3
			p["leg_l"] = Vector3(maxf(sin(t * PI), 0.0) * 0.5, 0, 0)
			p["leg_r"] = Vector3(maxf(-sin(t * PI), 0.0) * 0.5, 0, 0)
			p["bob"] = pulse * 0.07
		"the_twist":
			# hips corkscrew on every beat while the shoulders stay square, knees low
			var tw := sin(t * TAU)
			p["yaw"] = tw * 0.55
			p["twist"] = -tw * 0.5
			p["arm_l"] = Vector3(0.9, 0, -0.35)
			p["arm_r"] = Vector3(0.9, 0, 0.35)
			p["elbow_l"] = 1.0
			p["elbow_r"] = 1.0
			p["hunch"] = 0.12
			p["leg_l"] = Vector3(0.2, 0, 0)
			p["leg_r"] = Vector3(-0.1, 0, 0)
		"disco_point":
			# right arm stabs at the ceiling for two beats, then the left, hand on hip, hips and head following
			var side := 1.0 if int(floor(t / 2.0)) % 2 == 0 else -1.0
			var up := clampf(fposmod(t, 2.0) / 0.4, 0.0, 1.0)
			var pt := Vector3(0.0, 0.0, lerpf(0.9, 2.5, up))
			var hip := Vector3(-0.3, 0.0, 0.5)
			p["arm_r"] = pt if side > 0.0 else Vector3(hip.x, 0.0, hip.z)
			p["arm_l"] = Vector3(hip.x, 0.0, -hip.z) if side > 0.0 else Vector3(pt.x, 0.0, -pt.z)
			p["elbow_r"] = 0.05 if side > 0.0 else 1.7
			p["elbow_l"] = 1.7 if side > 0.0 else 0.05
			p["sway"] = side * 0.3 * up
			p["counter"] = side * 0.18
			p["yaw"] = -side * 0.3
			p["turn"] = side * 0.35
			p["leg_l"] = Vector3(0.0, 0.0, 0.12 * side)
			p["leg_r"] = Vector3(0.0, 0.0, 0.12 * side)
		"robot":
			# stiff, quantised: arms snap between right angles on each beat, head clicks round
			var st := int(floor(t)) % 4
			p["elbow_l"] = 1.57
			p["elbow_r"] = 1.57
			match st:
				0:
					p["arm_r"] = Vector3(1.57, 0, 0.1)
					p["arm_l"] = Vector3(0.0, 0, -0.1)
					p["turn"] = -0.5
					p["twist"] = -0.35
				1:
					p["arm_r"] = Vector3(0.0, 0, 0.1)
					p["arm_l"] = Vector3(1.57, 0, -0.1)
					p["turn"] = 0.5
					p["twist"] = 0.35
				2:
					p["arm_r"] = Vector3(0.0, 0, 1.57)
					p["arm_l"] = Vector3(0.0, 0, -1.57)
					p["turn"] = 0.0
				_:
					p["arm_r"] = Vector3(1.57, 0, 1.0)
					p["arm_l"] = Vector3(1.57, 0, -1.0)
					p["turn"] = 0.4
					p["twist"] = 0.0
			p["leg_l"] = Vector3(0.3 if st % 2 == 0 else 0.0, 0, 0)
			p["leg_r"] = Vector3(0.0 if st % 2 == 0 else 0.3, 0, 0)
		"charleston":
			# knees knock and swing, opposite arm to the forward leg, flapping hands
			var cs := sin(t * PI)
			p["leg_l"] = Vector3(cs * 0.55, 0, 0.12)
			p["leg_r"] = Vector3(-cs * 0.55, 0, -0.12)
			p["knee_l"] = maxf(-cs, 0.0) * 0.9 + 0.2
			p["knee_r"] = maxf(cs, 0.0) * 0.9 + 0.2
			p["arm_l"] = Vector3(-cs * 1.2, 0, -0.5)
			p["arm_r"] = Vector3(cs * 1.2, 0, 0.5)
			p["elbow_l"] = 0.6
			p["elbow_r"] = 0.6
			p["sway"] = sin(t * PI * 0.5) * 0.18
			p["counter"] = -cs * 0.12
			p["lean"] = 0.1
			p["bob"] = absf(cs) * 0.05
		"moonwalk":
			# the slide: one foot flat, the other on its toes, gliding backwards, hand to the brim
			var mw := int(floor(t)) % 2 == 0
			p["glide"] = 0.55 * sin(t * PI * 0.25)
			p["leg_l"] = Vector3(0.25 if mw else -0.2, 0, 0)
			p["leg_r"] = Vector3(-0.2 if mw else 0.25, 0, 0)
			p["knee_l"] = 0.0 if mw else 0.8
			p["knee_r"] = 0.8 if mw else 0.0
			p["arm_l"] = Vector3(1.9, 0, -0.3)
			p["elbow_l"] = 1.3
			p["arm_r"] = Vector3(0.3, 0, 0.45)
			p["lean"] = 0.12
			p["turn"] = 0.3
			p["nod"] = -0.1
			p["bob"] = absf(sin(t * PI)) * 0.03
		"cancan":
			# hands on hips, kicks way past the horizontal, alternating
			var cf := t - floorf(t)
			var cl := 0.5 + 0.5 * cos(TAU * cf)
			var cr := int(round(t)) % 2 == 1
			p["leg_r"] = Vector3(cl * 2.3 if cr else 0.0, 0, 0)
			p["leg_l"] = Vector3(0.0 if cr else cl * 2.3, 0, 0)
			p["knee_r"] = (1.0 - cl) * 0.9 if cr else 0.15
			p["knee_l"] = 0.15 if cr else (1.0 - cl) * 0.9
			p["arm_l"] = Vector3(0.1, 0, -0.85)
			p["arm_r"] = Vector3(0.1, 0, 0.85)
			p["elbow_l"] = 1.5
			p["elbow_r"] = 1.5
			p["lean"] = cl * 0.3
			p["nod"] = -0.15
			p["bob"] = cl * 0.04
			p["counter"] = (-0.14 if cr else 0.14) * cl
		"hip_roll":
			# slow circles of the hips, hands on them
			var ang := t * PI
			p["tilt"] = sin(ang) * 0.14
			p["counter"] = -sin(ang) * 0.12
			p["lean"] = cos(ang) * 0.1
			p["sway"] = cos(ang) * 0.12
			p["arm_l"] = Vector3(0.1, 0, -0.85)
			p["arm_r"] = Vector3(0.1, 0, 0.85)
			p["elbow_l"] = 1.5
			p["elbow_r"] = 1.5
			p["turn"] = sin(ang) * 0.3
		"twerk":
			# deep squat, hands on knees, hips rattling twice a beat while the shoulders stay put, a glance back
			var tk := sin(t * TAU * 2.0)
			p["tilt"] = tk * 0.18
			p["counter"] = -tk * 0.17
			p["hunch"] = 0.55
			p["leg_l"] = Vector3(0.7, 0, 0.12)
			p["leg_r"] = Vector3(0.7, 0, -0.12)
			p["knee_l"] = 1.4
			p["knee_r"] = 1.4
			p["bob"] = -0.76 * (1.0 - cos(0.7)) + absf(tk) * 0.04
			p["arm_l"] = Vector3(0.7, 0, -0.15)
			p["arm_r"] = Vector3(0.7, 0, 0.15)
			p["elbow_l"] = 0.0
			p["elbow_r"] = 0.0
			p["nod"] = -0.45
			p["turn"] = sin(t * PI * 0.5) * 0.5
		"booty_drop":
			# drop to the floor, bounce and shake it down there, then climb back up on the last beat
			var bl := clampf(t / 0.8, 0.0, 1.0) if t < 3.0 else clampf((4.0 - t) / 0.8, 0.0, 1.0)
			var bk := sin(t * TAU * 2.0) * bl
			p["tilt"] = bk * 0.2
			p["counter"] = -bk * 0.18
			p["hunch"] = 0.5 * bl
			p["leg_l"] = Vector3(1.1 * bl, 0, 0.15 * bl)
			p["leg_r"] = Vector3(1.1 * bl, 0, -0.15 * bl)
			p["knee_l"] = 2.2 * bl
			p["knee_r"] = 2.2 * bl
			p["bob"] = -0.76 * (1.0 - cos(1.1 * bl)) + absf(bk) * 0.05
			p["arm_l"] = Vector3(0.7 * bl + 0.15, 0, -0.15)
			p["arm_r"] = Vector3(0.7 * bl + 0.15, 0, 0.15)
			p["elbow_l"] = 0.0
			p["elbow_r"] = 0.0
			p["nod"] = -0.4 * bl
		"spin_kick":
			# wind up, whip round a full turn so the leg comes out on beat 2 facing the way he
			# started, then land
			var u2 := clampf((t - 0.5) / 1.5, 0.0, 1.0)
			var e2 := u2 * u2 * (3.0 - 2.0 * u2)
			p["yaw"] = -TAU * e2
			var ext := clampf(1.0 - absf(t - 2.0) / 0.6, 0.0, 1.0)
			p["leg_r"] = Vector3(ext * 1.55, 0, ext * 0.35)
			p["leg_l"] = Vector3(-0.1 * ext, 0, 0)
			p["arm_l"] = Vector3(0.9, 0, -1.0 - 0.3 * ext)
			p["arm_r"] = Vector3(0.9, 0, 1.0 + 0.3 * ext)
			p["tilt"] = -0.25 * ext
			p["bob"] = 0.15 * sin(e2 * PI)
		"jab_line":
			# fists up by the chin; one arm snaps straight out, landing on the beat, left then right
			var f3 := t - floorf(t)
			var jab := 0.5 + 0.5 * cos(TAU * f3)
			var right3 := int(round(t)) % 2 == 1
			var jr := jab if right3 else 0.0
			var jl := 0.0 if right3 else jab
			p["arm_r"] = Vector3(lerpf(1.15, 1.65, jr), 0, lerpf(-0.35, 0.0, jr))
			p["arm_l"] = Vector3(lerpf(1.15, 1.65, jl), 0, lerpf(0.35, 0.0, jl))
			p["yaw"] = 0.25 * (jr - jl)
			p["lean"] = 0.12 * jab
			p["bob"] = absf(sin(t * PI)) * 0.06
			p["leg_l"] = Vector3(0.25, 0, 0)
			p["leg_r"] = Vector3(-0.15, 0, 0)
		_:
			# waiting for the next phrase: a bounce on the spot
			p["bob"] = pulse * 0.03
	_groove(m, t, p)
	return p


## The all-purpose groove under every move: knees give on the beat (and the hips drop with them, so the
## planted feet stay planted), the head nods, the shoulders roll.
static func _groove(m: String, t: float, p: Dictionary) -> void:
	var amt: float = float(GROOVE.get(m, 1.0))
	if amt <= 0.0:
		return
	var down := 0.5 + 0.5 * cos(TAU * t)
	var deepest := 0.0
	for side in ["l", "r"]:
		var lv: Vector3 = p["leg_" + side]
		var plant := 1.0 - clampf(absf(lv.x) / 0.5, 0.0, 1.0)
		var a := (0.08 + 0.2 * down) * plant * amt
		lv.x += a
		p["leg_" + side] = lv
		p["knee_" + side] = float(p["knee_" + side]) + 2.0 * a
		deepest = maxf(deepest, a)
	p["bob"] = float(p["bob"]) - 0.76 * (1.0 - cos(deepest))
	p["nod"] = float(p["nod"]) + (0.08 + 0.14 * down) * amt
	p["cock"] = float(p["cock"]) + sin(t * PI) * 0.05 * amt
	p["counter"] = float(p["counter"]) + sin(t * PI) * 0.07 * amt
	p["twist"] = float(p["twist"]) + sin(t * PI * 0.5) * 0.1 * amt
