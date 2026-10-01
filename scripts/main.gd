extends Node3D
## Entry point. Builds the stage, wires the HUD and the beat, runs songs; headless batch sim:
##   godot --headless --path . -- --sim=20 [--red=Rumbler --blue=Showboat]
##        [--redbuild=Diva --bluebuild=0.2,0.2,0.2,0.2,0.2] [--seed=1] [--bars=48]
##        [--gains=rhythm:1,flair:1,balance:1,strength:1,arm:1,curve:0.5]

var manager: MatchManager
var stage: Stage
var cam: CameraRig
var hud: Hud
var beat: BeatPlayer
var headless := false
var batch_left := 0
var batch_results: Array[Dictionary] = []
var _restart_timer := -1.0
var _base_seed := -1
var _sun: DirectionalLight3D = null
var _dbg_label: Label = null
var _last_result: Dictionary = {}
var _results_shown_for := -1


func _ready() -> void:
	var args := _parse_args(OS.get_cmdline_user_args())
	headless = (DisplayServer.get_name() == "headless" or args.has("sim")) and not args.has("ui")

	stage = Stage.new()
	add_child(stage)
	_build_lighting()

	manager = MatchManager.new()
	manager.world = self
	manager.stage = stage
	manager.headless = headless
	manager.match_ended.connect(_on_match_ended)
	manager.dance_started.connect(_on_dance_started)
	manager.celebration_finished.connect(_on_celebration_finished)
	add_child(manager)

	if args.has("gains"):
		var g := PlayerBuild.GAINS.duplicate()
		var curve := PlayerBuild.CURVE
		for kv in String(args["gains"]).split(","):
			var pair := kv.split(":")
			if pair.size() == 2:
				if pair[0] == "curve":
					curve = float(pair[1])
				else:
					g[pair[0]] = float(pair[1])
		for t in 2:
			manager.team_builds[t].gains = g.duplicate()
			manager.team_builds[t].curve = curve
	for t in 2:
		var pkey := "red" if t == 0 else "blue"
		if args.has(pkey):
			manager.team_personalities[t] = Personality.preset(String(args[pkey]))
			manager.team_preset_names[t] = String(args[pkey])
		var tkey := pkey + "traits"
		if args.has(tkey):
			# --redtraits=discipline:0.7,caution:0.5 for character sweeps
			for kv in String(args[tkey]).split(","):
				var pr := kv.split(":")
				if pr.size() == 2:
					manager.team_personalities[t].set_trait(pr[0], float(pr[1]))
			manager.team_preset_names[t] = manager.team_personalities[t].label()
		var bkey := pkey + "build"
		if args.has(bkey):
			var gains: Dictionary = manager.team_builds[t].gains
			var curve2: float = manager.team_builds[t].curve
			manager.team_builds[t] = PlayerBuild.parse(String(args[bkey]))
			manager.team_builds[t].gains = gains
			manager.team_builds[t].curve = curve2
			manager.team_build_names[t] = manager.team_builds[t].label()
	if args.has("tune"):
		Tune.apply(String(args["tune"]))
	if args.has("seed"):
		_base_seed = int(args["seed"])
	if args.has("bars"):
		manager.song_bars = maxi(int(args["bars"]), 1)

	if headless:
		set_sim_speed(float(args.get("speed", "20")))
		batch_left = maxi(int(args.get("sim", "5")), 1)
		print("Dance-Off Bots headless sim: %d songs of %d bars, %s/%s vs %s/%s gains=%s" % [batch_left, manager.song_bars,
			manager.team_preset_names[0], manager.team_builds[0].short(), manager.team_preset_names[1], manager.team_builds[1].short(),
			JSON.stringify(manager.team_builds[0].gains) + " curve=%.2f" % manager.team_builds[0].curve])
		_start_next()
		return

	_setup_ui_scale()
	cam = CameraRig.new()
	add_child(cam)
	get_tree().root.size_changed.connect(_reframe)
	_reframe()
	beat = BeatPlayer.new()
	beat.manager = manager
	add_child(beat)
	hud = Hud.new()
	add_child(hud)
	hud.setup(manager)
	hud.band_resized.connect(_reframe)
	hud.new_match_requested.connect(func(): batch_left = 0; batch_results.clear(); _start_next())
	hud.batch_requested.connect(_run_batch)
	hud.speed_changed.connect(set_sim_speed)
	hud.pause_toggled.connect(func(p: bool): get_tree().paused = p)
	hud.mute_toggled.connect(func(m: bool): beat.muted = m)
	hud.process_mode = Node.PROCESS_MODE_ALWAYS
	cam.process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.has_feature("web"):
		# ?speed=0.25 for slow motion (screenshots)
		var q: String = str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('speed') || ''", true))
		if q.is_valid_float() and float(q) > 0.0:
			set_sim_speed(clampf(float(q), 0.05, 8.0))
		# ?shadows=0/1 overrides the default; ?debug=1 shows (and logs) the drawing counters
		var sq: String = str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('shadows') || ''", true))
		if sq != "" and _sun != null:
			_sun.shadow_enabled = sq != "0"
		var dq: String = str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('debug') || ''", true))
		if dq != "" and dq != "0":
			_debug_on()
	_start_next()


## What the opening view must hold: the box both crews dance in (at their widest, backed off to
## their back ranks) and the score board on the back wall.
const FRAME_POINTS := [
	Vector3(-8.2, 0.0, -3.0), Vector3(8.2, 0.0, -3.0), Vector3(-8.2, 0.0, 5.0), Vector3(8.2, 0.0, 5.0),
	Vector3(-8.2, 2.4, -3.0), Vector3(8.2, 2.4, -3.0), Vector3(-8.2, 2.4, 5.0), Vector3(8.2, 2.4, 5.0),
]
## The board need only be on screen: it may sit behind the dimmed button band.
const BOARD_POINTS := [
	Vector3(-6.8, 1.0, -7.8), Vector3(6.8, 1.0, -7.8), Vector3(-6.8, 2.2, -7.8), Vector3(6.8, 2.2, -7.8),
	Vector3(0.0, 3.3, -7.8),
]


## Frame again once the HUD has laid itself out (its button rows wrap on a narrow screen).
func _reframe() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	_frame_stage()


## The audience's view, from over the judges, pulled back just far enough that every dancer and the
## board sit in the part of the screen the buttons leave clear, whatever the window shape.
func _frame_stage() -> void:
	if cam == null or cam._cam == null:
		return
	var vs := get_viewport().get_visible_rect().size
	var portrait := vs.y > vs.x
	cam.yaw = 0.0
	cam.pitch = 0.95 if portrait else 0.62
	cam._cam.keep_aspect = Camera3D.KEEP_HEIGHT if portrait else Camera3D.KEEP_WIDTH
	cam._cam.fov = 50.0 if portrait else 60.0
	var top := hud.top_band_frac() if hud != null else 0.15
	cam.fit(FRAME_POINTS, Rect2(0.03, top + 0.02, 0.94, maxf(0.96 - top - 0.02, 0.3)), BOARD_POINTS)


func _setup_ui_scale() -> void:
	var root := get_tree().root
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	var dpi := DisplayServer.screen_get_dpi()
	var sc := clampf(float(dpi) / 96.0, 1.0, 3.0)
	var short := float(mini(DisplayServer.window_get_size().x, DisplayServer.window_get_size().y))
	if short > 0.0:
		sc = clampf(minf(sc, short / 400.0), 1.0, 3.0)
	root.content_scale_factor = sc


func set_sim_speed(s: float) -> void:
	Engine.time_scale = s
	Engine.physics_ticks_per_second = maxi(int(round(60.0 * s)), 12)
	# in a browser at most three catch-up steps a frame: a slow frame slows the song a touch
	# rather than snowballing into a slide show
	Engine.max_physics_steps_per_frame = maxi(3, int(s * 3.0)) if OS.has_feature("web") else maxi(8, int(s * 4.0))
	if beat != null:
		beat.set_speed(s)


## ?debug=1: frames a second, draw calls, objects and triangles drawn, nodes - top right, and in
## the browser console once a second (so a headless browser can read them).
func _debug_on() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	_dbg_label = Label.new()
	_dbg_label.add_theme_font_size_override("font_size", 13)
	_dbg_label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	_dbg_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_dbg_label.position.x -= 330.0
	_dbg_label.position.y += 4.0
	layer.add_child(_dbg_label)
	var tm := Timer.new()
	tm.wait_time = 1.0
	tm.autostart = true
	tm.process_mode = Node.PROCESS_MODE_ALWAYS
	tm.timeout.connect(_debug_tick)
	add_child(tm)


func _debug_tick() -> void:
	var t := "fps %d  draws %d  objects %d  tris %dk  nodes %d  shadows %s" % [
		int(Performance.get_monitor(Performance.TIME_FPS)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME) / 1000.0),
		int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"on" if _sun != null and _sun.shadow_enabled else "off"]
	_dbg_label.text = t
	print("DEBUG " + t)


func _build_lighting() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 15, 0)
	sun.light_energy = 0.85
	sun.light_color = Color(1.0, 0.92, 0.85)
	sun.shadow_enabled = not headless and not OS.has_feature("web")   # ?shadows=1 turns them on in a browser
	_sun = sun
	add_child(sun)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.05, 0.04, 0.08)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.62, 0.58, 0.78)
	e.ambient_light_energy = 0.7
	env.environment = e
	add_child(env)


func _parse_args(list: PackedStringArray) -> Dictionary:
	var d := {}
	for a in list:
		if a.begins_with("--"):
			var kv := a.substr(2).split("=", true, 1)
			d[kv[0]] = kv[1] if kv.size() > 1 else "1"
	return d


func _start_next() -> void:
	_restart_timer = -1.0
	if hud != null:
		hud.on_match_started()
	var s := -1
	if _base_seed >= 0:
		s = _base_seed + manager.match_index
	manager.start_match(s)


func _run_batch(n: int) -> void:
	batch_left = n
	batch_results.clear()
	set_sim_speed(8.0)
	if hud != null:
		hud._set_speed(8.0)
	_start_next()


func _process(delta: float) -> void:
	if cam != null and manager != null and manager.celebrating and manager.winner >= 0:
		var c := Vector3.ZERO
		var n := 0
		for d in manager.dancers:
			if d.team == manager.winner:
				c += d.global_position
				n += 1
		if n > 0:
			var f := c / n
			var b := cam.camera_basis()
			var vs := get_viewport().get_visible_rect().size
			if hud != null and hud.results_overlay.visible:
				if vs.x > vs.y:
					f += Vector3(b.x.x, 0, b.x.z).normalized() * 4.5
				else:
					f += Vector3(b.z.x, 0, b.z.z).normalized() * 3.5
			cam.set_focus(f, 16.0)
	elif cam != null:
		cam.clear_focus()
	if _restart_timer > 0.0:
		_restart_timer -= delta
		if _restart_timer <= 0.0:
			_start_next()


func _game_line(r: Dictionary) -> String:
	var st: Dictionary = r["stats"]
	return "song %d: %s (totals %d-%d, sync %d-%d, flair %d-%d incl. strikes %d-%d, KOs %d-%d, dancing %d%%-%d%%)" % [
		r["match"], (String(r["winner_name"]) + " win") if int(r["winner"]) >= 0 else "a dead heat",
		int(r["totals"][0]), int(r["totals"][1]), int(r["sync"][0]), int(r["sync"][1]),
		int(r["flair"][0]), int(r["flair"][1]), int(r["strike"][0]), int(r["strike"][1]),
		int(r["knockdowns"][0]), int(r["knockdowns"][1]),
		int(100.0 * st["dance_beats"][0] / maxf(st["beats"][0], 1.0)), int(100.0 * st["dance_beats"][1] / maxf(st["beats"][1], 1.0))]


func _on_match_ended(result: Dictionary) -> void:
	if batch_left > 0:
		batch_left -= 1
		batch_results.append(result)
		if headless:
			print("  " + _game_line(result))
		if batch_left > 0:
			if hud != null:
				hud.set_status("Batch: %d done, %d to go..." % [batch_results.size(), batch_left])
			_restart_timer = 0.05
			return
		var summary := _summarize(batch_results)
		if headless:
			print(summary["text"])
			for pp in batch_results[-1]["players"]:
				var s: Dictionary = pp["stats"]
				print("  %s %s/%s flair=%d sync=%d/%d dancing=%d strikes=%d/%d punches=%d/%d throws=%d/%d KOs=%d floored=%d fumbles=%d freestyle=%d" % [
					pp["name"], pp["persona"], pp["build"], int(s["flair"]), int(s["sync_beats"]), int(s["beats"]), int(s["dance_beats"]),
					int(s["strike_hits"]), int(s["strikes"]), int(s["punch_hits"]), int(s["punches"]), int(s["throw_hits"]), int(s["throws"]),
					int(s["knockdowns"]), int(s["floored"]), int(s["fumbles"]), int(s["freestyles"])])
			print("SUMMARY " + JSON.stringify(summary["data"]))
			if OS.has_environment("DOCELEB") and manager.celebrating:
				get_tree().create_timer(30.0).timeout.connect(func(): print("celebration: CAP HIT in phase %s" % manager.celebration_phase); get_tree().quit())
				return
			get_tree().quit()
			return
		hud.show_batch(summary)
		set_sim_speed(1.0)
		hud._set_speed(1.0)
		return
	if hud != null:
		_last_result = result
		_results_shown_for = -1
		hud.set_status("The judges are scoring...")
		# the panel opens with the cheer; a safety timer in case that signal is missed
		get_tree().create_timer(MatchManager.JUDGING_TIME + 1.5).timeout.connect(func(): _show_results(int(result["match"])))
	elif headless:
		print(_game_line(result))


func _show_results(idx: int) -> void:
	if hud == null or _last_result.is_empty() or _results_shown_for == idx or idx != manager.match_index or manager.running:
		return
	_results_shown_for = idx
	hud.show_result(_last_result)


func _on_dance_started(idx: int) -> void:
	if batch_left > 0:
		return
	_show_results(idx)


func _on_celebration_finished(idx: int) -> void:
	if headless and OS.has_environment("DOCELEB"):
		print("celebration finished for song %d" % idx)
		get_tree().quit()


func _summarize(results: Array[Dictionary]) -> Dictionary:
	var wins := [0, 0]
	var draws := 0
	var sums := {"totals": [0.0, 0.0], "sync": [0.0, 0.0], "flair": [0.0, 0.0], "strike": [0.0, 0.0], "knockdowns": [0.0, 0.0]}
	var agg := {}
	for k in Dancer.STAT_KEYS:
		agg[k] = [0.0, 0.0]
	for r in results:
		if int(r["winner"]) >= 0:
			wins[int(r["winner"])] += 1
		else:
			draws += 1
		for k in sums:
			for t in 2:
				sums[k][t] += float(r[k][t])
		for k in agg:
			for t in 2:
				agg[k][t] += float(r["stats"][k][t])
	var n := float(maxi(results.size(), 1))
	var txt := "Batch of %d: Red(%s/%s) %d wins, Blue(%s/%s) %d wins, %d dead heats.  " % [
		results.size(), manager.team_preset_names[0], manager.team_build_names[0], wins[0],
		manager.team_preset_names[1], manager.team_build_names[1], wins[1], draws]
	var avg := {}
	for t in 2:
		var beats: float = maxf(agg["beats"][t], 1.0)
		txt += "%s per song: total %d, sync %d, flair %d (strikes %d), in sync %d%%, dancing %d%%, knockdowns %.1f, punches %d/%d, throws %d/%d, fumbles %.1f.  " % [
			MatchManager.TEAM_NAMES[t], int(sums["totals"][t] / n), int(sums["sync"][t] / n), int(sums["flair"][t] / n), int(sums["strike"][t] / n),
			int(100.0 * agg["sync_beats"][t] / beats), int(100.0 * agg["dance_beats"][t] / beats), sums["knockdowns"][t] / n,
			int(agg["punch_hits"][t] / n), int(agg["punches"][t] / n), int(agg["throw_hits"][t] / n), int(agg["throws"][t] / n), agg["fumbles"][t] / n]
	for k in sums:
		avg[k] = [sums[k][0] / n, sums[k][1] / n]
	avg["dance_pct"] = [agg["dance_beats"][0] / maxf(agg["beats"][0], 1.0), agg["dance_beats"][1] / maxf(agg["beats"][1], 1.0)]
	avg["sync_pct"] = [agg["sync_beats"][0] / maxf(agg["beats"][0], 1.0), agg["sync_beats"][1] / maxf(agg["beats"][1], 1.0)]
	return {"text": txt, "data": {"games": results.size(), "wins": wins, "draws": draws, "avg": avg,
		"presets": manager.team_preset_names, "builds": manager.team_build_names}}
