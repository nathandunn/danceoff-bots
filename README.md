# Dance-Off Bots

A 5v5 street dance-off between two AI crews, part of the Precog sim suite. Live at
https://danceoff-bots.apps.precogsoftwareservices.com

Each crew dances to a generated 120 BPM beat for 48 bars; a board under the DANCE-OFF sign shows
the countdown and each crew's running score. The captain (the showiest dancer still standing)
calls a move every two bars. Dancers score **sync** for being on the call and on the beat
together, and **flair** for how well they dance and how hard the move is. Anyone who stops
dancing - to punch a rival, barge him, fetch a prop or throw a bin lid - scores nothing until he
picks the call up again at the next bar. Hits score nothing either, except a **dance-strike**: a
kick or swing that lands on a strike beat of the move being danced (kick line, leap, windmill,
cane twirl). Three judges weigh sync and flair differently; the winners cheer for five seconds
and the losers sit down and cry.

## Personality (how they behave)
aggression, showmanship, discipline, grudge, caution, teamwork. Presets: Showboat, Drill Team,
Rumbler, Hothead, Wallflower, Balanced, Random.

## Build (what they are; always sums to 1)
- rhythm: timing on the beat, how fast the call is picked up
- flair: execution
- balance: fewer fumbles, harder to floor, up sooner
- strength: knockdowns from punches, barges and dance-strikes
- arm: arm-work moves (clap-snap, shimmy, spin, jazz hands, windmill, cane twirl), the hat and
  cane flourish, throwing

Presets: Even, Metronome, Diva, Rock, Bruiser, Pitcher, Hoofer, Heavy, Random.

## Balance
- `scripts/tune.gd` holds the behaviour levers (dance urge, brawl weight, knockdown chance, down
  time, rejoin at bar or phrase, strike points); `--tune=key:val,...` overrides them headless.
- `tools/tune_violence.py` sweeps them: violent crews (Rumbler, Hothead) against dancing crews.
  Shipped: rejoin at the next bar, knockdown base 0.30, dance urge 1.05 - Rumbler matchups came in
  at 42-50 % (it was 64 % on the first cut, with ~30 knockdowns a song).
- `tools/calibrate.py tune` sets GAINS/CURVE in `scripts/build.gd` so a specialist (0.6 in one
  property) beats an Even crew about half the time, across a pool of personalities. Arm was worth
  nothing while it only threw (throws are rare), which is why it now also scores arm-work moves.
  48-song probe on the shipped gains (bar 24 songs): rhythm 38 %, flair 53 %, balance 44 %,
  strength 48 %, arm 42 % (rhythm gain then set halfway back, 0.139 -> 0.18).

## Headless
```
godot --headless --path . -- --sim=20 --red=Rumbler --blue=Showboat --redbuild=Bruiser --seed=1 [--bars=48] [--tune=kd_base:0.3]
DOCELEB=1 godot --headless --path . -- --sim=1 --seed=3    # waits for the cheer to finish
GODOT=godot WORKERS=2 python3 tools/calibrate.py probe|tune|personas --games 48 [--bars 24]
GODOT=godot WORKERS=2 python3 tools/tune_violence.py --games 12 --bars 24 '' 'kd_base:0.3'
```
After adding a `class_name` script, run `godot --headless --import` once or headless runs hang.

## Build and deploy
`./build.sh` (Godot 4.7.2 + web templates) exports to `dist/`, boots the pack headless and gzips
the big artefacts; the Dockerfile serves `dist/` with nginx.
