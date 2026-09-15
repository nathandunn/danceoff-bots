# Dance-Off Bots

A 5v5 street dance-off between two AI crews, part of the Precog sim suite. Live at
https://danceoff-bots.apps.precogsoftwareservices.com

Each crew dances to a generated 120 BPM beat for 48 bars. The captain (the showiest dancer still
standing) calls a move every two bars; dancers score **sync** for being on the call and on the
beat together, and **flair** for how well they dance and how hard the move is. Anyone who stops
dancing - to punch a rival, barge him, fetch a prop or throw a bin lid - scores nothing and has to
rejoin at the next phrase. Hits score nothing either, except a **dance-strike**: a kick or swing
that lands on a strike beat of the move being danced (kick line, leap, windmill, cane twirl).
Three judges weigh sync and flair differently; the winners cheer for five seconds and the losers
sit down and cry.

## Personality (how they behave)
aggression, showmanship, discipline, grudge, caution, teamwork. Presets: Showboat, Drill Team,
Rumbler, Hothead, Wallflower, Balanced, Random.

## Build (what they are; always sums to 1)
rhythm, flair, balance, strength, arm. Presets: Even, Metronome, Diva, Rock, Bruiser, Pitcher,
Hoofer, Heavy, Random. `tools/calibrate.py` tunes GAINS/CURVE in `scripts/build.gd` so a
specialist in any property beats an Even crew about half the time.

## Headless
```
godot --headless --path . -- --sim=20 --red=Rumbler --blue=Showboat --redbuild=Bruiser --seed=1 [--bars=48]
DOCELEB=1 godot --headless --path . -- --sim=1 --seed=3    # waits for the cheer to finish
GODOT=godot WORKERS=2 python3 tools/calibrate.py probe|tune|personas --games 48
```

## Build and deploy
`./build.sh` (Godot 4.7.2 + web templates) exports to `dist/`, boots the pack headless and gzips
the big artefacts; the Dockerfile serves `dist/` with nginx.
