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
const ARM_MOVES: Array[String] = ["clap_snap", "shimmy", "spin", "jazz_hands", "windmill", "cane_twirl"]

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
}

const NAMES: Array[String] = ["step_touch", "clap_snap", "shimmy", "spin", "kick_line", "jazz_hands",
	"grapevine", "knee_slide", "leap", "windmill", "cane_twirl"]


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
		"arm_l": Vector3(0.15, 0, -0.1), "arm_r": Vector3(0.15, 0, 0.1), "leg_l": Vector3.ZERO, "leg_r": Vector3.ZERO}
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
			p["lean"] = lift * 0.12
			p["bob"] = lift * 0.05
		"jazz_hands":
			var jz := sin(t * PI * 8.0) * 0.12
			p["arm_l"] = Vector3(2.5, 0, -0.55 + jz)
			p["arm_r"] = Vector3(2.5, 0, 0.55 - jz)
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
			p["arm_l"] = Vector3(lerpf(0.2, 2.7, low), 0, -0.6 * low)
			p["arm_r"] = Vector3(lerpf(0.2, 2.7, low), 0, 0.6 * low)
		"leap":
			var h := sin(clampf((t - 1.0) / 2.0, 0.0, 1.0) * PI)
			p["bob"] = h * 0.9
			p["leg_l"] = Vector3(h * 1.3, 0, 0)
			p["leg_r"] = Vector3(-h * 1.0, 0, 0)
			p["arm_l"] = Vector3(0.3 + h * 2.4, 0, -0.4 * h)
			p["arm_r"] = Vector3(0.3 + h * 2.4, 0, 0.4 * h)
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
			p["arm_l"] = Vector3(lerpf(0.3, 2.6, c2), 0, -0.3)
			p["sway"] = sin(t * PI * 0.5) * 0.3
			p["leg_l"] = Vector3(maxf(sin(t * PI), 0.0) * 0.5, 0, 0)
			p["leg_r"] = Vector3(maxf(-sin(t * PI), 0.0) * 0.5, 0, 0)
			p["bob"] = pulse * 0.07
		_:
			# waiting for the next phrase: a bounce on the spot
			p["bob"] = pulse * 0.03
	return p
