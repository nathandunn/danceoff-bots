class_name PlayerBuild
extends RefCounted
## A dancer's make-up: five properties that ALWAYS sum to 1. Raising one lowers the others in
## proportion, so every dancer spends the same budget and the only question is where.
##
##   rhythm   - timing on the beat, how quickly the captain's call is picked up
##   flair    - execution quality: how much a move is worth to the judges
##   balance  - staying on your feet: fewer fumbles, harder to floor, up again sooner
##   strength - knocking rivals down with punches, barges and dance-strikes
##   arm      - throwing props: speed and accuracy
##
## Each property turns into game numbers through `skill()`, linear above an even split (0.2 ->
## 0.5, 0.4 -> 1.0), `0.5 * (v / 0.2) ^ CURVE` below it. GAINS scales each property's swing about
## the middle; tools/calibrate.py rewrites GAINS and CURVE.

const PROPS: Array[String] = ["rhythm", "flair", "balance", "strength", "arm"]

const PROP_HELP := {
	"rhythm": "Timing on the beat; picks up the call quickly",
	"flair": "Execution: how much each move is worth",
	"balance": "Fewer fumbles, harder to floor, up sooner",
	"strength": "Knocks rivals down (punch, barge, dance-strike)",
	"arm": "Throw speed and accuracy",
}

const GAINS := {"rhythm": 1.000, "flair": 1.000, "balance": 1.000, "strength": 1.000, "arm": 1.000}
const CURVE := 0.500

const PRESETS := {
	"Even":      {"rhythm": 0.20, "flair": 0.20, "balance": 0.20, "strength": 0.20, "arm": 0.20},
	"Metronome": {"rhythm": 0.50, "flair": 0.15, "balance": 0.15, "strength": 0.10, "arm": 0.10},
	"Diva":      {"rhythm": 0.15, "flair": 0.50, "balance": 0.15, "strength": 0.10, "arm": 0.10},
	"Rock":      {"rhythm": 0.15, "flair": 0.10, "balance": 0.50, "strength": 0.15, "arm": 0.10},
	"Bruiser":   {"rhythm": 0.10, "flair": 0.10, "balance": 0.20, "strength": 0.50, "arm": 0.10},
	"Pitcher":   {"rhythm": 0.10, "flair": 0.10, "balance": 0.15, "strength": 0.15, "arm": 0.50},
	"Hoofer":    {"rhythm": 0.35, "flair": 0.35, "balance": 0.20, "strength": 0.05, "arm": 0.05},
	"Heavy":     {"rhythm": 0.10, "flair": 0.10, "balance": 0.35, "strength": 0.30, "arm": 0.15},
}

const MID := 0.2

var props: Dictionary = {}
var gains: Dictionary = GAINS.duplicate()
var curve: float = CURVE


func _init(from: Dictionary = {}) -> void:
	for p in PROPS:
		props[p] = maxf(float(from.get(p, MID)), 0.0)
	normalize()


static func preset(preset_name: String) -> PlayerBuild:
	if preset_name == "Random":
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		var d := {}
		for p in PROPS:
			d[p] = rng.randf() + 0.05
		return PlayerBuild.new(d)
	return PlayerBuild.new(PRESETS.get(preset_name, PRESETS["Even"]))


## "0.3,0.2,0.2,0.2,0.1" in PROPS order, or a preset name.
static func parse(text: String) -> PlayerBuild:
	if text.find(",") < 0:
		return preset(text)
	var parts := text.split(",")
	var d := {}
	for i in mini(parts.size(), PROPS.size()):
		d[PROPS[i]] = float(parts[i])
	return PlayerBuild.new(d)


func normalize() -> void:
	var total := 0.0
	for p in PROPS:
		total += float(props[p])
	if total <= 0.0:
		for p in PROPS:
			props[p] = MID
		return
	for p in PROPS:
		props[p] = float(props[p]) / total


func get_prop(p: String) -> float:
	return float(props.get(p, MID))


## Set one property and rescale the rest so the total stays 1.
func set_prop(p: String, v: float) -> void:
	v = clampf(v, 0.0, 1.0)
	var others := 0.0
	for q in PROPS:
		if q != p:
			others += float(props[q])
	var rest := 1.0 - v
	for q in PROPS:
		if q == p:
			props[q] = v
		elif others > 0.0:
			props[q] = float(props[q]) / others * rest
		else:
			props[q] = rest / float(PROPS.size() - 1)


func skill(p: String) -> float:
	var v := get_prop(p)
	var s := 0.0
	if v >= MID:
		s = v / (2.0 * MID)
	else:
		s = 0.5 * pow(v / MID, float(curve))
	return 0.5 + (s - 0.5) * float(gains.get(p, 1.0))


## Linear game number: `lo` at skill 0, `hi` at skill 1, extrapolated and held in bounds.
func stat(p: String, lo: float, hi: float, floor_v: float = -INF, ceil_v: float = INF) -> float:
	var v := lo + (hi - lo) * skill(p)
	var a := minf(lo, hi)
	var b := maxf(lo, hi)
	return clampf(v, maxf(floor_v, a - (b - a)), minf(ceil_v, b + (b - a)))


func copy() -> PlayerBuild:
	var b := PlayerBuild.new(props)
	b.gains = gains.duplicate()
	b.curve = curve
	return b


func jittered(rng: RandomNumberGenerator, spread: float = 0.02) -> PlayerBuild:
	var d := {}
	for p in PROPS:
		d[p] = maxf(get_prop(p) + rng.randf_range(-spread, spread), 0.0)
	var b := PlayerBuild.new(d)
	b.gains = gains.duplicate()
	b.curve = curve
	return b


func label() -> String:
	var best := "Custom"
	var best_d := 0.09
	for n in PRESETS:
		var d := 0.0
		for p in PROPS:
			d += absf(get_prop(p) - float(PRESETS[n][p]))
		d /= PROPS.size()
		if d < best_d:
			best_d = d
			best = n
	return best


func short() -> String:
	var parts := PackedStringArray()
	for p in PROPS:
		parts.append("%s %d" % [p.substr(0, 2), int(round(get_prop(p) * 100.0))])
	return " ".join(parts)


func to_dict() -> Dictionary:
	return props.duplicate()
