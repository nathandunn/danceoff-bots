# Dance-Off Bots

A 5v5 street dance-off between two AI crews, part of the Precog sim suite. Live at
https://danceoff-bots.apps.precogsoftwareservices.com

Two crews square off across the stage to a generated 120 BPM beat for 48 bars; a board under the
DANCE-OFF sign shows the countdown, each crew's running score and what each crew is doing as a
crew (pressing, CHARGE!). The captain (the showiest dancer still standing) calls a move every two
bars. Dancers score **sync** for being on the call and on the beat together and **flair** for how
well they dance and how hard the move is; they may dance at whoever they like, and playing it out
to the audience earns a little extra.

## Crews move as crews
Once a phrase each crew decides, as a crew, whether to **hold** its line, **press** forward or
**charge** - from its dancers' aggression and caution, and how far behind it is.
- The crew's wedge advances and gives ground together, so the two ranks close and part as units.
- A **charge is danced**: the captain calls a move with kicks or swings in it (kick line,
  windmill, leap), the crew travels the stage on the beat and fans round one rival, and the
  kicks land in unison on the strike beats. Those hits score (a **dance-strike**) and floor
  him; then the crew struts back and dances at them.
- Outside a charge a dancer throws a punch only to answer one. Anyone who stops dancing - to
  punch, fetch a prop or throw a bin lid - scores nothing until he picks the call up again at
  the next bar.

Three judges weigh sync and flair differently; the winners cheer for five seconds and the losers
sit down and cry.

## Personality (how they behave)
aggression, showmanship, discipline, grudge, caution, teamwork. Presets: Showboat, Drill Team,
Rumbler, Hothead, Wallflower, Balanced, Random. Showmanship also sets how far a dancer opens out
to the audience rather than squaring up to the other lot.

## Build (what they are; always sums to 1)
- rhythm: timing on the beat, how fast the call is picked up
- flair: execution
- balance: fewer fumbles, harder to floor, up sooner
- strength: knockdowns from dance-strikes, punches and barges
- arm: arm-work moves (clap-snap, shimmy, spin, jazz hands, windmill, cane twirl), the hat and
  cane flourish, throwing

Presets: Even, Metronome, Diva, Rock, Bruiser, Pitcher, Hoofer, Heavy, Random.

## Balance
- `scripts/tune.gd` holds the levers (dance urge, knockdown chance, rejoin at bar or phrase,
  strike points, audience bonus, charge rest and speed, advance distance...); `--tune=key:val,...`
  overrides them headless.
- `tools/tune_characters.py` plays one preset (and variants of it, via `--redtraits`) against the
  rest of the field; `tools/calibrate.py personas` is the full round robin; `tools/tune_violence.py`
  sweeps violent crews against dancing ones.
- `tools/calibrate.py tune` sets GAINS/CURVE in `scripts/build.gd` so a specialist (0.6 in one
  property) beats an Even crew about half the time.
- Target for every preset: 40-60 % over the field. See the commit history for the latest numbers.

## Headless
```
godot --headless --path . -- --sim=20 --red=Rumbler --blue=Showboat --redbuild=Bruiser --seed=1 [--bars=48] [--tune=kd_base:0.3] [--redtraits=discipline:0.7]
DOCELEB=1 godot --headless --path . -- --sim=1 --seed=3    # waits for the cheer to finish
GODOT=godot WORKERS=2 python3 tools/calibrate.py probe|tune|personas --games 48 [--bars 24]
GODOT=godot WORKERS=2 python3 tools/tune_characters.py --persona 'Drill Team' '' 'discipline:0.7'
```
After adding a `class_name` script, run `godot --headless --import` once or headless runs hang.

## Build and deploy
`./build.sh` (Godot 4.7.2 + web templates) exports to `dist/`, boots the pack headless and gzips
the big artefacts; the Dockerfile serves `dist/` with nginx.

## Hats, canes and bloody noses (2026-09-26)
- Every dancer starts in a hat and with a cane (flair +0.15 and +0.2, times arm skill). A knockdown knocks the hat off; it can be fetched back. Lids and rubber chickens stay on the floor to be thrown.
- Kicks, spin kicks and punches landed as part of a called move are dance routines and score (`strike_pts` 14). New moves: **Spin kick** (tier 3, strike on beat 2) and **Jab line** (tier 2, jabs on beats 1/3/5/7). Charges call kick line, jab line, spin kick, windmill or leap.
- A dancer who is hit gets *hurt* (+`hurt_hit` per hit, up to `hurt_max`, healing `hurt_heal` a tick): he moves slower (speed × (1 − hurt)), his timing gets ragged (`hurt_sloppy`), and blood trickles from his nose, with a gush on each hit.
- The opening camera fits both crews' whole dancing area below the button rows, whatever the screen shape; the board may sit behind the dimmed button band.
- Round robin after the change (8 songs a pair): Showboat 58, Drill Team 58, Rumbler 60, Hothead 50, Wallflower 52; Balanced (now discipline and showmanship .6) about 45.

## Better dancing and costumes (2026-09-30)
- Dancers now have joints: elbows, knees, a waist that turns and rolls against the hips, and a nodding head. Every move gets a groove underneath it (knees give on the beat with the hips dropping to match, head nod, shoulder roll). Running bends the knees; a hurt dancer droops.
- Nine new moves: The twist, Disco point, Robot, Charleston, Moonwalk (glides), Can-can, Hip roll, Twerk and Booty drop (cartoon blocks, all strictly for laughs). 22 moves in all.
- Costumes: Alley Cats wear orange jackets, black slacks with a gold stripe, white shoes and gold trim; Night Owls wear blue blazers, cream slacks with a navy stripe, tan shoes, pink trim and white hats. White gloves, shirt front, lapels, belt and buckle for all. Five dancers a side, no two alike: own skin tone, hair (quiff, slicked, bun, mohawk, bald) and a bandana, bow tie, braces, necktie or shades.

## Drops, crumples and wear (2026-09-30)
- More drop dances: Low bounce, Drop and pop, Wind it down, Duck walk and Floor shake join Hip roll, Twerk and Booty drop (27 moves in all). The drop family gets a weight boost (x1.4 to x2.0 with showmanship).
- A knockdown no longer sends the dancer flying: the ragdoll is heavy (gravity x2.2, high damping, grippy, no bounce), the shove is small and tips him the way he was hit, so he folds up where he stands.
- Wear: each knockdown makes the next getting-up `down_per_fall` (25%) longer and dulls his dancing by `wear_per_fall` (7% per fall, capped at 50%): timing wobble, fumble risk, execution and strike points all suffer, and he droops.
- strike_pts raised from 14 to 18 to keep the fighting crews level.

## Dance styles (2026-10-01)
- Every move belongs to one of five styles: street, ballet, burlesque (showgirl, cartoon), cheer and vaudeville. 14 new moves (41 in all): Plie, Pirouette, Arabesque, Grand jete; Hip bump, Shoulder tease, Slow strut; High V, Clap and punch, Herkie, Toe touch; Soft shoe, Hat tip and bow, Buck and wing.
- Captains mix styles: a call in the same style as the last one is weighted x0.3. A crew whose last four calls span several styles earns up to `style_bonus` (15%) extra flair. The board shows the style next to the move.
- Round robin (10 songs a pair): Balanced 46, Showboat 58, Drill Team 42, Rumbler 62, Hothead 44, Wallflower 48.
