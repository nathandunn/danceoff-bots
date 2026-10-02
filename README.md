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

## Gritty moves, line charges and the routine on screen (2026-10-01)
- Fixed: `Moves.choose` walked a NAMES list the last two patches had not reached, so the ballet, burlesque, cheer and vaudeville moves were never called. It now walks `Moves.BOOK`, so all 49 moves are live.
- Eight gritty street moves: Stanky leg, Jerk, Shmoney, Dougie, Running man, Harlem shake, Back it up and Krump (stomp, chest pop, arm swing, a two-fisted jab on 2 and 6 that lands as a dance-strike). `Moves.GRITTY` weighted x(1.8 + showmanship), and the twerk family (`Moves.REAR`) a further x2.
- The twerk is danced bent right over with the backside to whoever he would face (the crowd, or the other crew as a taunt), bouncing twice a beat; dancers now have hips to shake.
- Line charges: half of all charges (`line_charge`) pair each dancer with his opposite number by rank, and the crew kicks every man on the other side on the same beat. The board reads LINE CHARGE!.
- Each captain plans three moves ahead; the HUD shows the move now in capitals, its style, and the next three. On a phone it is one short line per crew.
- Round robin (10 songs a pair): Balanced 42, Showboat 60, Drill Team 44, Rumbler 51, Hothead 47, Wallflower 56.

## Performance in the browser (2026-10-01, from Drillbook Bots)
- `MeshBaker` (copied from drillbook-bots): each dancer's ~40 coloured pieces become 11 meshes (hips, torso, head, upper arms, forearms, thighs, shins) under one shared vertex-coloured material, cached per crew and slot; props one mesh each; the stage's static scenery one mesh; the crowd six bouncing blocks. The nosebleed stays separate. The hit flash is a short material override on the torso.
- Shadows off in the browser (`?shadows=1` turns them on).
- Browser physics: at most three catch-up steps a frame (still 60 a second, as the dancing is posed in the physics tick).
- `?debug=1`: fps, draw calls, objects, triangles, nodes, top right and in the console.
- Measured (1280x720, Chromium, mid-song): draw calls 1,825 -> 189 (548 with shadows off before the merge; 600 with `?shadows=1` after).

## Pop-up scores, slower get-ups, dancing out of harm's way (2026-10-01)
- A dancer's score floats up over his head and fades: +N in gold for a block of dancing, +N! in red for a dance-strike, slip! when he slips a blow.
- Getting up: after the floor time he struggles up from a crouch, hands on knees, for `rise_base` + `rise_per_fall` x earlier knockdowns seconds (x(1 + hurt), max 5 s), not dancing. Floor time grows `down_per_fall` (now 35%) a fall.
- Avoiding hits: every dancer edges away from a rival on a kicking or punching move within `shy_dist` (2.2 m), the cautious more; a dancer who sees a blow coming may slip it without breaking step (`slip_base` 0.1 + `slip_caution` 0.2 x caution).
- Round robin (8 songs a pair): Balanced 45, Showboat 55, Drill Team 42, Rumbler 62, Hothead 40, Wallflower 55.

## Only the dancing scores; injury shows (2026-10-01)
- Owner's rule changed: a blow that lands scores nothing (`strike_pts` 0); a landed dance-strike shows POW!. Dancing a kick line still scores as dancing.
- Injury (`Dancer.injury()` = wear x 1.2 + hurt x 0.7): an injured dancer dances slower (his pose clock runs up to 40% slow) and smaller, stooped, moves slower, and gets up slower still.
- Knocked out: after `ko_falls` (4) knockdowns, or injury past `ko_injury`, he stays down for the rest of the song, face down and pushing up on his arms every few seconds and flopping back (OUT!). Out dancers are not targets and take no more hits.
- Harder knockdowns so a fighting crew still has a way to win: `kd_base` 0.6, `down_mult` 1.6.
- Round robin (8 songs a pair): Balanced 48, Showboat 70, Drill Team 52, Rumbler 45, Hothead 22, Wallflower 62.
