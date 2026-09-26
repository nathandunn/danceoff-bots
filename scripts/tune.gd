class_name Tune
extends RefCounted
## Balance levers in one place. DEFAULTS are the shipped values; `--tune=key:val,...` overrides
## them for sweeps (tools/tune_violence.py) without touching the code.

const DEFAULTS := {
	"dance_base": 1.05,     # utility of dancing before discipline and showmanship
	"brawl_mult": 2.4,      # aggression x proximity weight on starting a fight
	"grudge_mult": 1.5,     # pull towards whoever last hit you
	"guard_mult": 2.2,      # teamwork weight on wading in for a mate
	"fetch_mult": 1.0,      # scale on the urge to fetch a prop
	"kd_base": 0.38,         # knockdown chance at equal strength and balance
	"down_mult": 1.0,       # scale on time spent on the floor
	"rejoin_beats": 4.0,    # a dancer who stopped rejoins at the next phrase (8) or bar (4)
	"strike_pts": 10.0,      # flair for a dance-strike that lands
	"press_bias": 0.0,      # added to every crew's urge to move up on the other lot
	"charge_bonus": 0.5,    # extra pull for a hothead to throw a punch at the charge's target too
	"retort_s": 4.0,        # outside a charge, a dancer only punches someone who hit him this recently
	"advance_m": 3.0,       # metres a crew moves up at a full press
	"charge_rest": 1.0,     # phrases a crew dances before it may charge again
	"charge_speed": 3.2,    # m/s a charging crew travels while still dancing the move
	"crowd_bonus": 0.1,    # extra flair, at most, for dancing it out to the audience
}

static var values := DEFAULTS.duplicate()


static func v(key: String) -> float:
	return float(values.get(key, DEFAULTS.get(key, 0.0)))


static func apply(text: String) -> void:
	for kv in text.split(","):
		var p := kv.split(":")
		if p.size() == 2 and DEFAULTS.has(p[0]):
			values[p[0]] = float(p[1])
