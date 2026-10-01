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
	"strike_pts": 18.0,      # flair for a dance-strike that lands
	"press_bias": 0.0,      # added to every crew's urge to move up on the other lot
	"charge_bonus": 0.5,    # extra pull for a hothead to throw a punch at the charge's target too
	"retort_s": 4.0,        # outside a charge, a dancer only punches someone who hit him this recently
	"advance_m": 3.0,       # metres a crew moves up at a full press
	"charge_rest": 1.0,     # phrases a crew dances before it may charge again
	"charge_speed": 3.2,    # m/s a charging crew travels while still dancing the move
	"crowd_bonus": 0.1,    # extra flair, at most, for dancing it out to the audience
	"hurt_hit": 0.12,       # how much slower (and sloppier) each hit taken leaves a dancer
	"hurt_max": 0.6,        # the most a dancer can be slowed
	"hurt_heal": 0.006,     # per second he mends
	"down_per_fall": 0.25,  # each earlier knockdown makes the next getting-up this much longer (fraction)
	"wear_per_fall": 0.07,  # each knockdown so far dulls his dancing by this much (capped at 0.5)
	"hurt_sloppy": 0.5,
	"style_bonus": 0.15,
	"line_charge": 0.5,     # chance a charge is a line (each kicks his own man) rather than a gang rush    # extra flair, at most, for a crew whose last four calls span four styles     # extra timing wobble per unit of hurt (1 = twice as ragged at full hurt)
}

static var values := DEFAULTS.duplicate()


static func v(key: String) -> float:
	return float(values.get(key, DEFAULTS.get(key, 0.0)))


static func apply(text: String) -> void:
	for kv in text.split(","):
		var p := kv.split(":")
		if p.size() == 2 and DEFAULTS.has(p[0]):
			values[p[0]] = float(p[1])
