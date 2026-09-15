class_name BeatPlayer
extends AudioStreamPlayer
## A generated two-bar groove - kick, snare, hats and an off-beat bass - so the dancers have
## something to move to without licensed music. Kept in step with MatchManager's beat clock and
## pitched with the sim speed (silent above 4x).

const RATE := 16000

var manager = null
var muted := false
var _speed := 1.0
var _check := 0.0


func _ready() -> void:
	stream = _make_loop()
	volume_db = -5.0


func set_speed(s: float) -> void:
	_speed = s


func loop_len() -> float:
	return 8.0 * 60.0 / MatchManager.BPM


func _process(delta: float) -> void:
	if manager == null:
		return
	var active: bool = (manager.running or (manager.celebrating and manager.celebration_phase != "done")) and not muted and _speed <= 4.0
	if not active:
		if playing:
			stop()
		return
	var want := fposmod(float(manager.elapsed), loop_len())
	if absf(pitch_scale - _speed) > 0.01:
		pitch_scale = _speed
	if not playing:
		play(want)
		_check = 1.0
		return
	_check -= delta
	if _check <= 0.0:
		_check = 1.0
		var off := absf(get_playback_position() - want)
		if off > 0.25 * _speed and off < loop_len() - 0.25 * _speed:
			seek(want)


func _make_loop() -> AudioStreamWAV:
	var beat_len := 60.0 / MatchManager.BPM
	var n := int(RATE * beat_len * 8.0)
	var data := PackedByteArray()
	data.resize(n * 2)
	var bass := [110.0, 110.0, 82.41, 98.0]
	var lcg := 12345
	for i in n:
		var t := float(i) / RATE
		var bt := t / beat_len
		var beat := int(bt)
		var frac := bt - float(beat)
		var since := frac * beat_len
		var s := 0.0
		if beat % 2 == 0:
			var f := 50.0 + 90.0 * exp(-since * 30.0)
			s += sin(TAU * f * since) * exp(-since * 9.0) * 0.9
		else:
			lcg = (lcg * 1103515245 + 12345) & 0x7fffffff
			var noise := float(lcg) / float(0x3fffffff) - 1.0
			s += (noise * 0.5 + sin(TAU * 190.0 * since) * 0.3) * exp(-since * 16.0)
		var eighth := fposmod(bt * 2.0, 1.0) * beat_len * 0.5
		lcg = (lcg * 1103515245 + 12345) & 0x7fffffff
		s += (float(lcg) / float(0x3fffffff) - 1.0) * exp(-eighth * 70.0) * 0.12
		if frac >= 0.5:
			var note: float = bass[(beat / 2) % 4]
			s += sin(TAU * note * t) * exp(-(frac - 0.5) * beat_len * 7.0) * 0.4
		data.encode_s16(i * 2, int(clampf(s * 0.75, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = n
	return w
