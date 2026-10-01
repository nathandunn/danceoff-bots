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
const ARM_MOVES: Array[String] = ["clap_snap", "shimmy", "spin", "jazz_hands", "windmill", "cane_twirl", "jab_line", "disco_point", "robot", "charleston", "twerk", "hip_roll", "booty_drop", "krump", "dougie", "shmoney"]

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
	"low_bounce": {"label": "Low bounce", "beats": 4, "tier": 2, "strikes": [], "strike": "", "prop": ""},
	"drop_and_pop": {"label": "Drop and pop", "beats": 8, "tier": 3, "strikes": [], "strike": "", "prop": ""},
	"wind_it_down": {"label": "Wind it down", "beats": 8, "tier": 3, "strikes": [], "strike": "", "prop": ""},
	"duck_walk": {"label": "Duck walk", "beats": 8, "tier": 2, "strikes": [], "strike": "", "prop": ""},
	"floor_shake": {"label": "Floor shake", "beats": 4, "tier": 3, "strikes": [], "strike": "", "prop": ""},
	"plie_port": {"label": "Plié", "beats": 4, "tier": 1, "strikes": [], "strike": "", "prop": ""},
	"pirouette": {"label": "Pirouette", "beats": 4, "tier": 2, "strikes": [], "strike": "", "prop": ""},
	"arabesque": {"label": "Arabesque", "beats": 4, "tier": 3, "strikes": [], "strike": "", "prop": ""},
	"grand_jete": {"label": "Grand jeté", "beats": 4, "tier": 3, "strikes": [], "strike": "", "prop": ""},
	"hip_bump": {"label": "Hip bump", "beats": 4, "tier": 1, "strikes": [], "strike": "", "prop": ""},
	"shoulder_tease": {"label": "Shoulder tease", "beats": 4, "tier": 2, "strikes": [], "strike": "", "prop": ""},
	"slow_strut": {"label": "Slow strut", "beats": 8, "tier": 2, "strikes": [], "strike": "", "prop": ""},
	"high_v": {"label": "High V", "beats": 4, "tier": 1, "strikes": [], "strike": "", "prop": ""},
	"clap_punch": {"label": "Clap and punch", "beats": 8, "tier": 1, "strikes": [], "strike": "", "prop": ""},
	"herkie": {"label": "Herkie", "beats": 4, "tier": 2, "strikes": [], "strike": "", "prop": ""},
	"toe_touch": {"label": "Toe touch", "beats": 4, "tier": 3, "strikes": [], "strike": "", "prop": ""},
	"soft_shoe": {"label": "Soft shoe", "beats": 8, "tier": 1, "strikes": [], "strike": "", "prop": ""},
	"hat_tip_bow": {"label": "Hat tip and bow", "beats": 4, "tier": 1, "strikes": [], "strike": "", "prop": ""},
	"buck_and_wing": {"label": "Buck and wing", "beats": 4, "tier": 2, "strikes": [], "strike": "", "prop": ""},
	# gritty street: krump, jerkin', the Dougie and the rest
	"stanky_leg": {"label": "Stanky leg", "beats": 4, "tier": 1, "strikes": [], "strike": "", "prop": ""},
	"jerk": {"label": "Jerk", "beats": 4, "tier": 1, "strikes": [], "strike": "", "prop": ""},
	"shmoney": {"label": "Shmoney", "beats": 4, "tier": 1, "strikes": [], "strike": "", "prop": ""},
	"dougie": {"label": "Dougie", "beats": 4, "tier": 2, "strikes": [], "strike": "", "prop": ""},
	"running_man": {"label": "Running man", "beats": 4, "tier": 2, "strikes": [], "strike": "", "prop": ""},
	"harlem_shake": {"label": "Harlem shake", "beats": 4, "tier": 2, "strikes": [], "strike": "", "prop": ""},
	"back_it_up": {"label": "Back it up", "beats": 4, "tier": 2, "strikes": [], "strike": "", "prop": ""},
	"krump": {"label": "Krump", "beats": 8, "tier": 3, "strikes": [2, 6], "strike": "punch", "prop": ""},
}

## Every move belongs to a style. Captains mix them up, and a crew whose last four calls cover several
## styles gets a little extra flair (MatchManager.style_mix).
const STYLE := {
	"step_touch": "street", "spin": "street", "knee_slide": "street", "windmill": "street", "spin_kick": "street",
	"jab_line": "street", "the_twist": "street", "disco_point": "street", "robot": "street", "moonwalk": "street",
	"twerk": "street", "booty_drop": "street", "low_bounce": "street", "drop_and_pop": "street", "duck_walk": "street",
	"floor_shake": "street", "stanky_leg": "street", "jerk": "street", "shmoney": "street", "dougie": "street",
	"running_man": "street", "harlem_shake": "street", "back_it_up": "street", "krump": "street",
	"leap": "ballet", "plie_port": "ballet", "pirouette": "ballet", "arabesque": "ballet", "grand_jete": "ballet",
	"shimmy": "burlesque", "hip_roll": "burlesque", "wind_it_down": "burlesque", "hip_bump": "burlesque",
	"shoulder_tease": "burlesque", "slow_strut": "burlesque",
	"kick_line": "cheer", "clap_snap": "cheer", "high_v": "cheer", "clap_punch": "cheer", "herkie": "cheer", "toe_touch": "cheer",
	"jazz_hands": "vaudeville", "grapevine": "vaudeville", "cane_twirl": "vaudeville", "charleston": "vaudeville",
	"cancan": "vaudeville", "soft_shoe": "vaudeville", "hat_tip_bow": "vaudeville", "buck_and_wing": "vaudeville",
}
const STYLES: Array[String] = ["street", "ballet", "burlesque", "cheer", "vaudeville"]

# the drop family: crews favour these, and showmen most of all
## The gritty end of the street: hip-shakers and battle moves. Crews call these far more often.
const GRITTY: Array[String] = ["twerk", "back_it_up", "booty_drop", "floor_shake", "low_bounce", "drop_and_pop",
	"stanky_leg", "jerk", "shmoney", "dougie", "running_man", "harlem_shake", "krump", "hip_roll", "wind_it_down"]
## Moves danced with the backside to whoever he'd otherwise face (the crowd, or the other lot as a taunt).
const REAR: Array[String] = ["twerk", "back_it_up", "low_bounce"]
const DROPS: Array[String] = ["hip_roll", "twerk", "booty_drop", "low_bounce", "drop_and_pop", "wind_it_down", "duck_walk", "floor_shake",
	"plie_port", "pirouette", "arabesque", "grand_jete", "hip_bump", "shoulder_tease", "slow_strut", "high_v", "clap_punch", "herkie", "toe_touch", "soft_shoe", "hat_tip_bow", "buck_and_wing",
	"stanky_leg", "jerk", "shmoney", "dougie", "running_man", "harlem_shake", "back_it_up", "krump"]

# how much of the all-purpose groove (knee give, head nod, shoulder roll) each move keeps
const GROOVE := {"knee_slide": 0.0, "leap": 0.0, "spin_kick": 0.0, "moonwalk": 0.0, "cancan": 0.0, "twerk": 0.0, "booty_drop": 0.0, "plie_port": 0.0, "pirouette": 0.0, "arabesque": 0.0, "grand_jete": 0.0, "toe_touch": 0.0, "herkie": 0.0, "hat_tip_bow": 0.0, "krump": 0.0, "running_man": 0.0, "back_it_up": 0.0, "harlem_shake": 0.0, "low_bounce": 0.0, "drop_and_pop": 0.0, "wind_it_down": 0.0, "duck_walk": 0.0, "floor_shake": 0.0, "robot": 0.2}

const NAMES: Array[String] = ["step_touch", "clap_snap", "shimmy", "spin", "kick_line", "jazz_hands",
	"grapevine", "knee_slide", "leap", "windmill", "cane_twirl", "spin_kick", "jab_line", "the_twist", "disco_point", "robot", "charleston", "moonwalk", "cancan", "hip_roll", "twerk", "booty_drop", "low_bounce", "drop_and_pop", "wind_it_down", "duck_walk", "floor_shake"]


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
	return "%s (%s)" % [String(BOOK[m]["label"]), style(m)]


static func style(m: String) -> String:
	return String(STYLE.get(m, "street"))


## Weighted pick of a move: showmanship wants the hard tiers, aggression wants strike moves when
## rivals are close, `avoid` (recent calls) is discounted, the cane twirl needs canes.
static func choose(rng: RandomNumberGenerator, show: float, aggr: float, rivals_near: bool, canes: int, avoid: Array, last_style: String = "") -> String:
	var names: Array[String] = []
	var weights: Array[float] = []
	var total := 0.0
	for m: String in BOOK.keys():
		var tr := tier(m)
		var w := 1.0 + show * float(tr - 1) * 1.2 - (1.0 - show) * float(tr - 1) * 0.45
		w = maxf(w, 0.05)
		if GRITTY.has(m):
			w *= 1.8 + 1.0 * show
		if REAR.has(m):
			w *= 2.0
		if last_style != "" and style(m) == last_style:
			w *= 0.6 if last_style == "street" else 0.3
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
			# bent right over, hands on the knees, the backside bouncing twice a beat and rolling side
			# to side while the shoulders hold still (danced with his back to the house: Moves.REAR)
			var tb := absf(sin(t * TAU * 2.0))
			var tr := sin(t * TAU)
			_low(p, 0.8, 0.85)
			p["bob"] = float(p["bob"]) + tb * 0.09
			p["tilt"] = tr * 0.2
			p["counter"] = -tr * 0.2
			p["hunch"] = 0.85 - tb * 0.15
			p["arm_l"] = Vector3(1.0, 0, -0.2)
			p["arm_r"] = Vector3(1.0, 0, 0.2)
			p["nod"] = -0.6
			p["turn"] = 0.6 * sin(t * PI * 0.5)
		"back_it_up":
			# the twerk walked backwards at the other lot, looking back over the shoulder
			var bb := absf(sin(t * TAU * 2.0))
			var bs := sin(t * TAU)
			_low(p, 0.7, 0.75)
			p["bob"] = float(p["bob"]) + bb * 0.08
			p["tilt"] = bs * 0.18
			p["counter"] = -bs * 0.18
			p["glide"] = 0.35 * sin(t * PI * 0.25)
			p["arm_l"] = Vector3(0.9, 0, -0.2)
			p["arm_r"] = Vector3(0.3, 0, 0.5)
			p["elbow_r"] = 1.5
			p["turn"] = 1.1
			p["nod"] = -0.3
		"stanky_leg":
			# one foot planted, the other leg out to the side with the knee rolling in and out
			var sk := sin(t * TAU)
			p["leg_r"] = Vector3(0.15, 0, 0.3 + 0.15 * sk)
			p["knee_r"] = 0.7 + 0.3 * sk
			p["leg_l"] = Vector3(0.1, 0, 0.0)
			p["knee_l"] = 0.3
			p["sway"] = 0.12 * sk
			p["tilt"] = -0.12 * sk
			p["counter"] = 0.1 * sk
			p["arm_l"] = Vector3(0.6, 0, -0.7)
			p["arm_r"] = Vector3(0.6, 0, 0.7)
			p["elbow_l"] = 1.3
			p["elbow_r"] = 1.3
			p["bob"] = -0.05
		"jerk":
			# knees bent, swaying, knees pivoting in and out, arms level with the chest
			var jk := sin(t * PI)
			_low(p, 0.35, 0.1)
			p["leg_l"] = Vector3(0.35, 0, -0.25 * jk)
			p["leg_r"] = Vector3(0.35, 0, -0.25 * jk)
			p["sway"] = 0.25 * jk
			p["counter"] = -0.12 * jk
			p["arm_l"] = Vector3(1.4, 0, -0.3)
			p["arm_r"] = Vector3(1.4, 0, 0.3)
			p["elbow_l"] = 1.0
			p["elbow_r"] = 1.0
			p["nod"] = 0.1 + 0.1 * absf(jk)
		"shmoney":
			# hip cocked, arms crossed in an X, then swung open, elbows bent
			var sm := 0.5 - 0.5 * cos(t * TAU)
			p["tilt"] = 0.15
			p["sway"] = 0.12 * sin(t * PI)
			p["arm_l"] = Vector3(1.1, 0, lerpf(0.55, -0.8, sm))
			p["arm_r"] = Vector3(1.1, 0, lerpf(-0.55, 0.8, sm))
			p["elbow_l"] = 1.3
			p["elbow_r"] = 1.3
			p["leg_l"] = Vector3(0.2 * sm, 0, 0)
			p["knee_l"] = 0.4 * sm
			p["turn"] = -0.3
		"dougie":
			# a lean-back sway, one arm pumping, the other hand slicking the hair back
			var dg := sin(t * PI)
			p["sway"] = 0.3 * dg
			p["tilt"] = -0.14 * dg
			p["counter"] = 0.12 * dg
			p["hunch"] = -0.12
			p["arm_r"] = Vector3(0.8 + 0.4 * absf(dg), 0, 0.5)
			p["elbow_r"] = 1.4
			var slick := clampf(fposmod(t, 2.0) / 1.0, 0.0, 1.0)
			p["arm_l"] = Vector3(lerpf(2.2, 3.0, slick), 0, -0.3)
			p["elbow_l"] = lerpf(1.9, 1.2, slick)
			p["turn"] = 0.4 * dg
			p["nod"] = -0.2
		"running_man":
			# a knee up to the hip, the other foot sliding back, arms pumping, on the spot
			var rm := sin(t * TAU * 0.5)
			var lu := maxf(rm, 0.0)
			var ru := maxf(-rm, 0.0)
			p["leg_l"] = Vector3(1.5 * lu - 0.35 * ru, 0, 0)
			p["leg_r"] = Vector3(1.5 * ru - 0.35 * lu, 0, 0)
			p["knee_l"] = 1.5 * lu
			p["knee_r"] = 1.5 * ru
			p["bob"] = 0.05 * absf(rm)
			p["arm_l"] = Vector3(-0.6 * rm + 0.3, 0, -0.2)
			p["arm_r"] = Vector3(0.6 * rm + 0.3, 0, 0.2)
			p["elbow_l"] = 1.4
			p["elbow_r"] = 1.4
		"harlem_shake":
			# loose and convulsive: shoulders jerking, knees knocking, arms flung about
			var hs := sin(t * TAU * 4.0)
			var hx := sin(t * TAU * 1.5)
			p["counter"] = hs * 0.3
			p["tilt"] = hx * 0.1
			p["hunch"] = 0.15 + 0.1 * hs
			_low(p, 0.3 + 0.1 * absf(hs), 0.15 + 0.1 * hs)
			p["arm_l"] = Vector3(1.2 + 0.8 * hx, 0, -0.6 - 0.3 * hs)
			p["arm_r"] = Vector3(1.2 - 0.8 * hx, 0, 0.6 + 0.3 * hs)
			p["elbow_l"] = 0.8 + 0.5 * hs
			p["elbow_r"] = 0.8 - 0.5 * hs
			p["nod"] = 0.2 * hs
			p["turn"] = 0.3 * hx
		"krump":
			# a stomp, a chest pop, a big arm swing and a two-fisted jab at the other lot on 2 and 6
			var kb := int(floor(t)) % 4
			var kf := t - floorf(t)
			var hit := clampf(1.0 - kf / 0.35, 0.0, 1.0)
			p["elbow_l"] = 1.2
			p["elbow_r"] = 1.2
			p["leg_l"] = Vector3(0.25, 0, -0.18)
			p["leg_r"] = Vector3(0.25, 0, 0.18)
			p["knee_l"] = 0.5
			p["knee_r"] = 0.5
			p["bob"] = -0.06
			match kb:
				0:
					# stomp: the right foot comes up and is driven into the floor on the beat
					p["leg_r"] = Vector3(0.9 * (1.0 - hit), 0, 0.18)
					p["knee_r"] = 1.4 * (1.0 - hit)
					p["bob"] = -0.06 - 0.05 * hit
					p["hunch"] = 0.35
					p["arm_l"] = Vector3(0.6, 0, -0.9)
					p["arm_r"] = Vector3(0.6, 0, 0.9)
				1:
					# chest pop
					p["hunch"] = -0.35 * hit
					p["arm_l"] = Vector3(0.3, 0, -1.0)
					p["arm_r"] = Vector3(0.3, 0, 1.0)
					p["elbow_l"] = 1.6
					p["elbow_r"] = 1.6
				2:
					# the jab: both fists straight out at whoever he's facing
					p["arm_l"] = Vector3(1.55, 0, 0.1)
					p["arm_r"] = Vector3(1.55, 0, -0.1)
					p["elbow_l"] = 1.6 * (1.0 - hit)
					p["elbow_r"] = 1.6 * (1.0 - hit)
					p["hunch"] = 0.3 * hit
				_:
					# the arm swing, like a bat
					p["arm_r"] = Vector3(fposmod(kf * TAU + 1.0, TAU), 0, 0.4)
					p["elbow_r"] = 0.2
					p["arm_l"] = Vector3(0.5, 0, -0.8)
					p["twist"] = -0.5 + kf
			p["nod"] = 0.15
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
		"low_bounce":
			# stay down in the squat and pulse on every half-beat
			var lbs := sin(t * TAU * 2.0)
			_low(p, 0.75 + 0.15 * cos(t * TAU * 2.0), 0.5)
			p["tilt"] = lbs * 0.12
			p["counter"] = -lbs * 0.11
			p["turn"] = sin(t * PI * 0.5) * 0.4
		"drop_and_pop":
			# down on the half-beat, shake it, then explode up with the arms thrown high; twice
			var du := fposmod(t, 4.0)
			var dl := clampf(du / 0.6, 0.0, 1.0) if du < 2.6 else clampf((3.2 - du) / 0.6, 0.0, 1.0)
			var dh := sin(clampf((du - 3.2) / 0.8, 0.0, 1.0) * PI)
			var dk := sin(t * TAU * 2.0) * dl
			_low(p, 1.1 * dl, 0.5 * dl)
			p["bob"] = float(p["bob"]) + dh * 0.55
			p["tilt"] = dk * 0.2
			p["counter"] = -dk * 0.18
			p["arm_l"] = Vector3(0.15 + 0.55 * dl + dh * 2.4, 0, -0.15 - dh * 0.4)
			p["arm_r"] = Vector3(0.15 + 0.55 * dl + dh * 2.4, 0, 0.15 + dh * 0.4)
			p["knee_l"] = float(p["knee_l"]) + dh * 0.9
			p["knee_r"] = float(p["knee_r"]) + dh * 0.9
		"wind_it_down":
			# a slow slide to the floor, hips circling, hands in the air, and a slow climb back
			var wl := sin(clampf(t / 8.0, 0.0, 1.0) * PI)
			var wa := t * PI
			_low(p, 1.1 * wl, 0.35 * wl)
			p["tilt"] = sin(wa) * 0.16 * wl
			p["counter"] = -sin(wa) * 0.14 * wl
			p["sway"] = cos(wa) * 0.12 * wl
			p["arm_l"] = Vector3(lerpf(0.15, 2.6, wl), 0, -0.4)
			p["arm_r"] = Vector3(lerpf(0.15, 2.6, wl), 0, 0.4)
			p["elbow_l"] = 0.3
			p["elbow_r"] = 0.3
			p["nod"] = -0.2 * wl
			p["turn"] = sin(wa * 0.5) * 0.35
		"duck_walk":
			# a low waddle from side to side, elbows flapping
			var dw := sin(t * PI)
			_low(p, 0.9, 0.35)
			p["leg_l"] = Vector3(0.9 + 0.2 * dw, 0, 0.15)
			p["leg_r"] = Vector3(0.9 - 0.2 * dw, 0, -0.15)
			p["sway"] = sin(t * PI * 0.5) * 0.45
			p["tilt"] = dw * 0.1
			p["counter"] = -dw * 0.1
			p["arm_l"] = Vector3(0.0, 0, -0.9)
			p["arm_r"] = Vector3(0.0, 0, 0.9)
			p["elbow_l"] = 1.2 + 0.4 * sin(t * TAU * 2.0)
			p["elbow_r"] = 1.2 - 0.4 * sin(t * TAU * 2.0)
		"floor_shake":
			# straight down to the floor, hands high, hips going like a sewing machine
			var fl := clampf(t / 0.4, 0.0, 1.0) if t < 3.4 else clampf((4.0 - t) / 0.4, 0.0, 1.0)
			var fk := sin(t * TAU * 2.5) * fl
			_low(p, 1.2 * fl, 0.4 * fl)
			p["tilt"] = fk * 0.22
			p["counter"] = -fk * 0.2
			p["arm_l"] = Vector3(0.15 + 2.45 * fl, 0, -0.5 * fl - 0.15)
			p["arm_r"] = Vector3(0.15 + 2.45 * fl, 0, 0.5 * fl + 0.15)
			p["elbow_l"] = 0.2
			p["elbow_r"] = 0.2
			p["turn"] = sin(t * PI) * 0.5
		"plie_port":
			# ballet: a slow plié, arms rising through first position to fifth overhead
			var pp := 0.5 - 0.5 * cos(t * PI * 0.5)
			_low(p, 0.45 * sin(t * PI * 0.25), 0.0)
			p["leg_l"] = Vector3(float(p["leg_l"].x), 0, -0.25)
			p["leg_r"] = Vector3(float(p["leg_r"].x), 0, 0.25)
			p["arm_l"] = Vector3(lerpf(0.5, 2.9, pp), 0, -0.35)
			p["arm_r"] = Vector3(lerpf(0.5, 2.9, pp), 0, 0.35)
			p["elbow_l"] = 0.5
			p["elbow_r"] = 0.5
			p["nod"] = -0.15
			p["turn"] = 0.3 * sin(t * PI * 0.25)
		"pirouette":
			# up on the toes, foot drawn to the knee, two turns, arms rounded in front
			var pu := clampf((t - 0.5) / 2.5, 0.0, 1.0)
			var pe := pu * pu * (3.0 - 2.0 * pu)
			p["yaw"] = -TAU * 2.0 * pe
			var up := clampf(t / 0.4, 0.0, 1.0) * clampf((4.0 - t) / 0.4, 0.0, 1.0)
			p["bob"] = 0.08 * up
			p["leg_r"] = Vector3(0.9 * up, 0, 0.5 * up)
			p["knee_r"] = 2.0 * up
			p["arm_l"] = Vector3(1.3, 0, 0.25)
			p["arm_r"] = Vector3(1.3, 0, -0.25)
			p["elbow_l"] = 0.9
			p["elbow_r"] = 0.9
			p["nod"] = -0.1
		"arabesque":
			# lean forward, back leg up behind, one arm reaching out front
			var ar := sin(clampf(t / 4.0, 0.0, 1.0) * PI)
			var ah := clampf(ar * 1.6, 0.0, 1.0)
			p["lean"] = 0.45 * ah
			p["leg_r"] = Vector3(-1.5 * ah, 0, 0)
			p["bob"] = 0.06 * ah
			p["arm_l"] = Vector3(1.4 + 0.6 * ah, 0, -0.1)
			p["arm_r"] = Vector3(0.6, 0, 1.3 * ah)
			p["elbow_l"] = 0.05
			p["elbow_r"] = 0.1
			p["nod"] = -0.35 * ah
		"grand_jete":
			# a leap in the splits, arms flung up and out
			var gj := sin(clampf((t - 0.8) / 2.2, 0.0, 1.0) * PI)
			p["bob"] = gj * 1.0
			p["leg_l"] = Vector3(1.55 * gj, 0, 0)
			p["leg_r"] = Vector3(-1.45 * gj, 0, 0)
			p["arm_l"] = Vector3(0.4 + 2.0 * gj, 0, -0.7 * gj)
			p["arm_r"] = Vector3(0.4 + 1.2 * gj, 0, 1.0 * gj)
			p["elbow_l"] = 0.15
			p["elbow_r"] = 0.15
			p["lean"] = 0.1 * gj
			p["nod"] = 0.2 * gj
		"hip_bump":
			# showgirl hip bump on each beat, one hand on the hip, the other overhead
			var hb := sin(t * PI)
			p["sway"] = hb * 0.22
			p["tilt"] = -hb * 0.2
			p["counter"] = hb * 0.15
			p["arm_l"] = Vector3(0.1, 0, -0.85)
			p["elbow_l"] = 1.5
			p["arm_r"] = Vector3(2.7, 0, 0.4)
			p["elbow_r"] = 0.7
			p["leg_l"] = Vector3(0.25 * maxf(hb, 0.0), 0, 0)
			p["leg_r"] = Vector3(0.25 * maxf(-hb, 0.0), 0, 0)
			p["knee_l"] = 0.5 * maxf(hb, 0.0)
			p["knee_r"] = 0.5 * maxf(-hb, 0.0)
			p["turn"] = 0.35
		"shoulder_tease":
			# a look back over the shoulder, a slow shoulder roll, hand to the brim
			var st := sin(t * PI * 0.5)
			p["yaw"] = 0.6
			p["turn"] = -0.9
			p["counter"] = st * 0.2
			p["twist"] = -0.3
			p["tilt"] = st * 0.08
			p["arm_r"] = Vector3(2.6, 0, 0.2)
			p["elbow_r"] = 1.7
			p["arm_l"] = Vector3(0.2, 0, -0.85)
			p["elbow_l"] = 1.5
			p["leg_l"] = Vector3(0.2, 0, 0.15)
			p["knee_l"] = 0.5
			p["nod"] = 0.1
		"slow_strut":
			# heel-to-toe, one foot crossing in front of the other, hips swinging, a trailing hand
			var ss := sin(t * PI * 0.5)
			var cross := 1.0 if int(floor(t / 2.0)) % 2 == 0 else -1.0
			p["leg_l"] = Vector3(0.35 * maxf(ss, 0.0), 0, -0.18 * cross)
			p["leg_r"] = Vector3(0.35 * maxf(-ss, 0.0), 0, -0.18 * cross)
			p["sway"] = ss * 0.25
			p["tilt"] = -ss * 0.16
			p["counter"] = ss * 0.12
			p["arm_l"] = Vector3(-0.4, 0, -0.5)
			p["arm_r"] = Vector3(0.6 + 0.3 * ss, 0, 0.6)
			p["elbow_r"] = 0.8
			p["nod"] = -0.1
			p["turn"] = 0.25
		"high_v":
			# sharp cheer motions: high V, T, low V, high V, snapping on the beat
			var hv := int(floor(t)) % 4
			p["elbow_l"] = 0.0
			p["elbow_r"] = 0.0
			match hv:
				0, 3:
					p["arm_l"] = Vector3(0.0, 0, -2.5)
					p["arm_r"] = Vector3(0.0, 0, 2.5)
				1:
					p["arm_l"] = Vector3(0.0, 0, -1.57)
					p["arm_r"] = Vector3(0.0, 0, 1.57)
				_:
					p["arm_l"] = Vector3(0.0, 0, -0.6)
					p["arm_r"] = Vector3(0.0, 0, 0.6)
			p["bob"] = absf(sin(t * PI)) * 0.08
			p["nod"] = -0.1
		"clap_punch":
			# clap on the beat, punch a fist at the sky on the off-beat
			var cf := t - floorf(t)
			var on := cf < 0.5
			var side := 1.0 if int(floor(t)) % 2 == 0 else -1.0
			if on:
				p["arm_l"] = Vector3(1.5, 0, 0.35)
				p["arm_r"] = Vector3(1.5, 0, -0.35)
				p["elbow_l"] = 0.6
				p["elbow_r"] = 0.6
			else:
				p["arm_r"] = Vector3(2.9, 0, 0.3) if side > 0.0 else Vector3(0.3, 0, 0.6)
				p["arm_l"] = Vector3(0.3, 0, -0.6) if side > 0.0 else Vector3(2.9, 0, -0.3)
				p["elbow_l"] = 0.1 if side < 0.0 else 1.4
				p["elbow_r"] = 0.1 if side > 0.0 else 1.4
			p["bob"] = absf(sin(t * TAU)) * 0.05
		"herkie":
			# a jump with one leg straight out to the side and the other tucked under
			var hk := sin(clampf((t - 1.0) / 1.6, 0.0, 1.0) * PI)
			p["bob"] = hk * 0.75
			p["leg_r"] = Vector3(0.6 * hk, 0, 1.3 * hk)
			p["leg_l"] = Vector3(-0.4 * hk, 0, 0)
			p["knee_l"] = 2.0 * hk
			p["arm_r"] = Vector3(0.0, 0, 2.5 * hk + 0.2)
			p["arm_l"] = Vector3(0.6, 0, -0.4 - 0.6 * hk)
			p["elbow_l"] = 0.0
			p["elbow_r"] = 0.0
			if t < 1.0:
				var crouch := 0.6 * clampf(1.0 - absf(t - 0.6) / 0.5, 0.0, 1.0)
				p["knee_l"] = float(p["knee_l"]) + 2.0 * crouch
				p["knee_r"] = 2.0 * crouch
				p["leg_r"] = Vector3(crouch, 0, 0)
				p["bob"] = -0.76 * (1.0 - cos(crouch))
		"toe_touch":
			# the big straddle jump: legs out to the sides, arms out to meet them
			var tt := sin(clampf((t - 1.0) / 1.8, 0.0, 1.0) * PI)
			p["bob"] = tt * 0.9
			p["leg_l"] = Vector3(0.7 * tt, 0, -1.35 * tt)
			p["leg_r"] = Vector3(0.7 * tt, 0, 1.35 * tt)
			p["arm_l"] = Vector3(0.6 * tt, 0, -1.6 * tt - 0.2)
			p["arm_r"] = Vector3(0.6 * tt, 0, 1.6 * tt + 0.2)
			p["elbow_l"] = 0.0
			p["elbow_r"] = 0.0
			p["lean"] = 0.25 * tt
			p["nod"] = -0.2 * tt
		"soft_shoe":
			# a lazy sand-dance shuffle, toe taps, the cane swinging, the hat tipped at the end
			var sf := sin(t * PI)
			p["leg_l"] = Vector3(0.35 * maxf(sf, 0.0), 0, 0)
			p["leg_r"] = Vector3(0.35 * maxf(-sf, 0.0), 0, 0)
			p["knee_l"] = 0.4 + 0.3 * maxf(sf, 0.0)
			p["knee_r"] = 0.4 + 0.3 * maxf(-sf, 0.0)
			p["sway"] = sin(t * PI * 0.5) * 0.3
			p["arm_r"] = Vector3(0.4 + 0.5 * sf, 0, 0.35)
			p["elbow_r"] = 0.5
			var tip := clampf((t - 6.0) / 0.5, 0.0, 1.0) * clampf((8.0 - t) / 0.5, 0.0, 1.0)
			p["arm_l"] = Vector3(lerpf(0.3, 2.7, tip), 0, -0.3)
			p["elbow_l"] = lerpf(0.3, 1.7, tip)
			p["lean"] = -0.08
			p["turn"] = 0.4 * sin(t * PI * 0.25)
		"hat_tip_bow":
			# step back, tip the hat, take a deep bow to the house, cane out to the side
			var bw := sin(clampf((t - 0.5) / 3.0, 0.0, 1.0) * PI)
			p["lean"] = 0.75 * bw
			p["leg_r"] = Vector3(-0.35 * bw, 0, 0)
			p["knee_l"] = 0.3 * bw
			p["arm_l"] = Vector3(lerpf(0.3, 2.4, bw), 0, -0.2)
			p["elbow_l"] = 1.6 * bw
			p["arm_r"] = Vector3(0.3, 0, 1.0 * bw + 0.1)
			p["elbow_r"] = 0.1
			p["nod"] = 0.3 * bw
		"buck_and_wing":
			# fast taps, a leg flicked out on every beat, the elbows flapping like wings
			var bk := sin(t * TAU)
			var right := int(floor(t)) % 2 == 0
			p["leg_r"] = Vector3(0.3, 0, 0.6 * maxf(bk, 0.0)) if right else Vector3(0.1, 0, 0)
			p["leg_l"] = Vector3(0.1, 0, 0) if right else Vector3(0.3, 0, -0.6 * maxf(bk, 0.0))
			p["knee_l"] = 0.5
			p["knee_r"] = 0.5
			p["arm_l"] = Vector3(0.0, 0, -1.0 - 0.3 * absf(bk))
			p["arm_r"] = Vector3(0.0, 0, 1.0 + 0.3 * absf(bk))
			p["elbow_l"] = 1.4
			p["elbow_r"] = 1.4
			p["bob"] = absf(sin(t * TAU * 2.0)) * 0.05
			p["lean"] = 0.1
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


## A planted squat of depth `a` (radians at the thigh): knees bend twice as far, the hips drop to keep
## the feet on the floor, hands on the knees, head up.
static func _low(p: Dictionary, a: float, hunch: float) -> void:
	var f := clampf(a, 0.0, 1.0)
	p["leg_l"] = Vector3(a, 0, 0.15 * f)
	p["leg_r"] = Vector3(a, 0, -0.15 * f)
	p["knee_l"] = 2.0 * a
	p["knee_r"] = 2.0 * a
	p["bob"] = float(p["bob"]) - 0.76 * (1.0 - cos(a))
	p["hunch"] = hunch
	p["arm_l"] = Vector3(0.15 + 0.55 * f, 0, -0.15)
	p["arm_r"] = Vector3(0.15 + 0.55 * f, 0, 0.15)
	p["elbow_l"] = 0.0
	p["elbow_r"] = 0.0
	p["nod"] = -0.4 * f


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
