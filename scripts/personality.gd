class_name Personality
extends RefCounted
## How a dancer behaves (as opposed to what they are, which is PlayerBuild): 0..1 traits that
## shape the brain's utility scores.

const TRAITS: Array[String] = ["aggression", "showmanship", "discipline", "grudge", "caution", "teamwork"]

const TRAIT_HELP := {
	"aggression": "Break off to thump a rival, throw props, strike on the beat",
	"showmanship": "Hard, flashy moves; play to the crowd; grab a hat or cane",
	"discipline": "Follow the captain's call and stay in step; never freestyle",
	"grudge": "Get even with whoever floored you",
	"caution": "Keep clear of rivals and dodge what's thrown",
	"teamwork": "Wade in when a mate is being thumped",
}

const PRESETS := {
	"Showboat":   {"aggression": 0.25, "showmanship": 0.95, "discipline": 0.45, "grudge": 0.30, "caution": 0.50, "teamwork": 0.40},
	"Drill Team": {"aggression": 0.15, "showmanship": 0.45, "discipline": 0.95, "grudge": 0.15, "caution": 0.60, "teamwork": 0.70},
	"Rumbler":    {"aggression": 0.90, "showmanship": 0.35, "discipline": 0.45, "grudge": 0.60, "caution": 0.20, "teamwork": 0.60},
	"Hothead":    {"aggression": 0.60, "showmanship": 0.55, "discipline": 0.25, "grudge": 0.95, "caution": 0.15, "teamwork": 0.30},
	"Wallflower": {"aggression": 0.05, "showmanship": 0.15, "discipline": 0.70, "grudge": 0.10, "caution": 0.95, "teamwork": 0.30},
	"Balanced":   {"aggression": 0.50, "showmanship": 0.50, "discipline": 0.50, "grudge": 0.50, "caution": 0.50, "teamwork": 0.50},
}

var traits: Dictionary = {}


func _init(from: Dictionary = {}) -> void:
	for t in TRAITS:
		traits[t] = clampf(float(from.get(t, 0.5)), 0.0, 1.0)


static func preset(preset_name: String) -> Personality:
	if preset_name == "Random":
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		var d := {}
		for t in TRAITS:
			d[t] = rng.randf()
		return Personality.new(d)
	return Personality.new(PRESETS.get(preset_name, PRESETS["Balanced"]))


func get_trait(t: String) -> float:
	return float(traits.get(t, 0.5))


func set_trait(t: String, v: float) -> void:
	traits[t] = clampf(v, 0.0, 1.0)


func copy() -> Personality:
	return Personality.new(traits)


func jittered(rng: RandomNumberGenerator, spread: float = 0.08) -> Personality:
	var d := {}
	for t in TRAITS:
		d[t] = clampf(get_trait(t) + rng.randf_range(-spread, spread), 0.0, 1.0)
	return Personality.new(d)


func label() -> String:
	var best := "Custom"
	var best_d := 0.3
	for n in PRESETS:
		var d := 0.0
		for t in TRAITS:
			d += absf(get_trait(t) - float(PRESETS[n][t]))
		d /= TRAITS.size()
		if d < best_d:
			best_d = d
			best = n
	return best


func to_dict() -> Dictionary:
	return traits.duplicate()
