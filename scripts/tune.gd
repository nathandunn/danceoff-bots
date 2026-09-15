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
	"kd_base": 0.3,         # knockdown chance at equal strength and balance
	"down_mult": 1.0,       # scale on time spent on the floor
	"rejoin_beats": 4.0,    # a dancer who stopped rejoins at the next phrase (8) or bar (4)
	"strike_pts": 5.0,      # flair for a dance-strike that lands
}

static var values := DEFAULTS.duplicate()


static func v(key: String) -> float:
	return float(values.get(key, DEFAULTS.get(key, 0.0)))


static func apply(text: String) -> void:
	for kv in text.split(","):
		var p := kv.split(":")
		if p.size() == 2 and DEFAULTS.has(p[0]):
			values[p[0]] = float(p[1])
