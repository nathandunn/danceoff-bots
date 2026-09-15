class_name MatchManager
extends Node
## Runs one dance-off: the beat clock, the captains' calls, sync and flair scoring, knockdown
## bookkeeping, the judges and the end-of-song cheer and tears.

signal match_ended(result: Dictionary)
signal dance_started(match_index: int)        # the winners' cheer begins (results panel opens)
signal celebration_finished(match_index: int)

const TEAM_SIZE := 5
const TEAM_NAMES := ["Alley Cats", "Night Owls"]
const TEAM_COLORS := [Color(0.93, 0.36, 0.22), Color(0.32, 0.5, 0.98)]
const DANCER_NAMES := [["Ace", "Blade", "Duke", "Jinx", "Rico"], ["Bix", "Dot", "Fez", "Lulu", "Moe"]]
const BPM := 120.0
const SONG_BARS := 48
const SYNC_PTS := 1.0          # per beat: SYNC_PTS * (dancers in sync)^2 / TEAM_SIZE
const JUDGES := [[0.65, 0.35], [0.5, 0.5], [0.35, 0.65]]   # weight on sync, weight on flair
const JUDGE_NOISE := 0.04
const JUDGING_TIME := 2.5
const CHEER_TIME := 5.0
# kind (Prop.Kind), where it starts
const PROP_LAYOUT := [
	[0, Vector3(-1.2, 0, -4.6)], [0, Vector3(1.2, 0, -4.6)],
	[1, Vector3(-3.0, 0, 4.2)], [1, Vector3(3.0, 0, 4.2)],
	[2, Vector3(0, 0, 1.2)], [3, Vector3(0, 0, -2.0)],
]

var world: Node3D
var stage: Stage
var headless := false
var dancers: Array[Dancer] = []
var props: Array[Prop] = []
var team_personalities: Array[Personality] = [Personality.preset("Rumbler"), Personality.preset("Showboat")]
var team_preset_names: Array[String] = ["Rumbler", "Showboat"]
var team_builds: Array[PlayerBuild] = [PlayerBuild.preset("Even"), PlayerBuild.preset("Even")]
var team_build_names: Array[String] = ["Even", "Even"]
var song_bars := SONG_BARS
var running := false
var celebrating := false
var celebration_phase := ""
var elapsed := 0.0
var beat_f := 0.0
var beat_i := -1
var match_index := 0
var rng := RandomNumberGenerator.new()
var calls: Array[String] = ["step_touch", "step_touch"]
var call_log: Array = [[], []]
var sync_pts: Array[float] = [0.0, 0.0]
var flair_pts: Array[float] = [0.0, 0.0]
var strike_pts: Array[float] = [0.0, 0.0]
var knockdowns: Array[int] = [0, 0]
var totals: Array[float] = [0.0, 0.0]
var judge_rows: Array = []
var winner := -1
var _phase_t := 0.0


func start_match(seed_value: int = -1) -> void:
	_clear()
	match_index += 1
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	for t in 2:
		for i in TEAM_SIZE:
			var d := Dancer.new()
			d.team = t
			d.slot = i
			d.team_color = TEAM_COLORS[t]
			d.dancer_name = DANCER_NAMES[t][i]
			d.manager = self
			d.rng = RandomNumberGenerator.new()
			d.rng.seed = rng.randi()
			d.personality = team_personalities[t].jittered(rng)
			d.build = team_builds[t].jittered(rng)
			d.position = Stage.home_spot(t, i)
			d.rotation.y = PI
			world.add_child(d)
			dancers.append(d)
	for entry in PROP_LAYOUT:
		var p := Prop.new()
		p.kind = int(entry[0])
		p.manager = self
		p.home = entry[1]
		p.position = p.home + Vector3(0, 0.3, 0)
		world.add_child(p)
		props.append(p)
	elapsed = 0.0
	beat_f = 0.0
	beat_i = -1
	running = true
	celebrating = false
	celebration_phase = ""
	winner = -1
	calls = ["step_touch", "step_touch"]
	call_log = [[], []]
	judge_rows = []
	for t in 2:
		sync_pts[t] = 0.0
		flair_pts[t] = 0.0
		strike_pts[t] = 0.0
		knockdowns[t] = 0
		totals[t] = 0.0
	if stage != null:
		stage.hide_cards()


func _clear() -> void:
	for d in dancers:
		if is_instance_valid(d):
			d.cleanup()
			d.queue_free()
	dancers.clear()
	for p in props:
		if is_instance_valid(p):
			p.queue_free()
	props.clear()
	running = false
	celebrating = false


func _physics_process(delta: float) -> void:
	if running:
		elapsed += delta
		beat_f = elapsed * BPM / 60.0
		var b := int(floor(beat_f))
		while running and beat_i < b:
			beat_i += 1
			if beat_i >= song_bars * 4:
				_end_song()
				break
			_on_beat(beat_i)
		if stage != null and not headless:
			stage.bounce(beat_f)
	elif celebrating:
		elapsed += delta
		beat_f = elapsed * BPM / 60.0
		if stage != null and not headless:
			stage.bounce(beat_f)
		_phase_t -= delta
		if _phase_t <= 0.0:
			if celebration_phase == "judging":
				celebration_phase = "cheer"
				_phase_t = CHEER_TIME
				dance_started.emit(match_index)
			elif celebration_phase == "cheer":
				celebration_phase = "done"
				_phase_t = 1e9
				celebration_finished.emit(match_index)


func _on_beat(b: int) -> void:
	if b % Moves.PHRASE == 0:
		for t in 2:
			calls[t] = _captain_call(t)
			(call_log[t] as Array).append(calls[t])
	for d in dancers:
		d.on_beat(b, calls[d.team])
	for t in 2:
		var n := 0
		for d in dancers:
			if d.team == t and d.in_sync:
				n += 1
		sync_pts[t] += SYNC_PTS * float(n * n) / float(TEAM_SIZE)


## The standing dancer with the most showmanship calls the next phrase.
func _captain_call(t: int) -> String:
	var cap: Dancer = null
	for d in dancers:
		if d.team == t and d.ragdoll == null and (cap == null or d.showmanship > cap.showmanship):
			cap = d
	if cap == null:
		cap = team_dancers(t)[0]
	var canes := 0
	var near := false
	for d in dancers:
		if d.team != t:
			continue
		if d.held != null and d.held.kind == Prop.Kind.CANE:
			canes += 1
		for e in dancers:
			if e.team != t and e.ragdoll == null and d.global_position.distance_to(e.global_position) < 5.0:
				near = true
	var log_t: Array = call_log[t]
	return Moves.choose(rng, cap.showmanship, cap.aggression, near, canes - 1, log_t.slice(-2))


func team_dancers(t: int) -> Array[Dancer]:
	var out: Array[Dancer] = []
	for d in dancers:
		if d.team == t:
			out.append(d)
	return out


func standing(t: int) -> Array[Dancer]:
	var out: Array[Dancer] = []
	for d in dancers:
		if d.team == t and d.ragdoll == null:
			out.append(d)
	return out


func add_flair(t: int, pts: float, strike: bool) -> void:
	flair_pts[t] += pts
	if strike:
		strike_pts[t] += pts


func note_knockdown(by: Dancer, victim: Dancer, _how: String) -> void:
	if by != null and is_instance_valid(by) and by.team != victim.team:
		knockdowns[by.team] += 1


func prop_thrown(by: Dancer, from: Vector3, v: Vector3) -> void:
	for d in dancers:
		d.consider_throw(by, from, v)


## 0..1: how far team t is ahead on points (the other side gets angrier).
func lead_fraction(t: int) -> float:
	var a := sync_pts[t] + flair_pts[t]
	var b := sync_pts[1 - t] + flair_pts[1 - t]
	return clampf((a - b) / maxf(a + b, 60.0) * 3.0, 0.0, 1.0)


func remaining_fraction() -> float:
	return clampf(1.0 - beat_f / float(song_bars * 4), 0.0, 1.0)


func score(t: int) -> float:
	return sync_pts[t] + flair_pts[t]


func count_standing(t: int) -> int:
	return standing(t).size()


func count_dancing(t: int) -> int:
	var n := 0
	for d in dancers:
		if d.team == t and d.is_dancing() and d.joined:
			n += 1
	return n


func _end_song() -> void:
	running = false
	judge_rows = []
	for t in 2:
		totals[t] = 0.0
	for j in JUDGES.size():
		var w: Array = JUDGES[j]
		var raw: Array[float] = [0.0, 0.0]
		for t in 2:
			raw[t] = (float(w[0]) * sync_pts[t] + float(w[1]) * flair_pts[t]) * maxf(1.0 + rng.randfn(0.0, JUDGE_NOISE), 0.5)
			totals[t] += raw[t]
		var top := maxf(maxf(raw[0], raw[1]), 1.0)
		var cards := [maxf(round(raw[0] / top * 20.0) / 2.0, 1.0), maxf(round(raw[1] / top * 20.0) / 2.0, 1.0)]
		judge_rows.append({"weights": w, "points": [raw[0], raw[1]], "cards": cards})
	winner = -1
	if absf(totals[0] - totals[1]) >= 0.5:
		winner = 0 if totals[0] > totals[1] else 1
	for d in dancers:
		if winner < 0:
			d.celebrate("shrug")
		else:
			d.celebrate("cheer" if d.team == winner else "cry")
	celebrating = true
	celebration_phase = "judging"
	_phase_t = JUDGING_TIME
	if stage != null:
		stage.show_cards(judge_rows)
	match_ended.emit(_result())


func _result() -> Dictionary:
	var st := {}
	for k in Dancer.STAT_KEYS:
		st[k] = [0.0, 0.0]
	var players := []
	for d in dancers:
		for k in Dancer.STAT_KEYS:
			st[k][d.team] += float(d.stats[k])
		players.append({"name": d.dancer_name, "team": d.team, "persona": team_preset_names[d.team],
			"build": d.build.label(), "stats": d.stats.duplicate()})
	return {
		"match": match_index,
		"winner": winner,
		"winner_name": TEAM_NAMES[winner] if winner >= 0 else "nobody",
		"reason": "judges",
		"duration": elapsed,
		"sync": [sync_pts[0], sync_pts[1]],
		"flair": [flair_pts[0], flair_pts[1]],
		"strike": [strike_pts[0], strike_pts[1]],
		"totals": [totals[0], totals[1]],
		"knockdowns": [knockdowns[0], knockdowns[1]],
		"judges": judge_rows,
		"stats": st,
		"players": players,
		"presets": [team_preset_names[0], team_preset_names[1]],
		"builds": [team_build_names[0], team_build_names[1]],
	}
