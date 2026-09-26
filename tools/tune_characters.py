#!/usr/bin/env python3
"""Tune one personality preset against the rest of the field.

  GODOT=godot WORKERS=2 python3 tools/tune_characters.py --persona 'Drill Team' --games 10 \
      '' 'discipline:0.7' 'discipline:0.6,showmanship:0.55'

Each variant ('' is the preset as shipped) plays every other preset on Even builds, half the songs
on each side, and prints its win rate per opponent and overall. Target: 40-60 % overall.
"""
import argparse, json, os, subprocess
from concurrent.futures import ThreadPoolExecutor

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GODOT = os.environ.get("GODOT", "godot")
WORKERS = int(os.environ.get("WORKERS", "2"))
PERSONAS = ["Balanced", "Showboat", "Drill Team", "Rumbler", "Hothead", "Wallflower"]


def run(red, blue, games, seed, bars, red_traits, blue_traits):
    args = [GODOT, "--headless", "--path", ROOT, "--", f"--sim={games}", f"--red={red}",
            f"--blue={blue}", f"--seed={seed}", f"--bars={bars}"]
    if red_traits:
        args.append("--redtraits=" + red_traits)
    if blue_traits:
        args.append("--bluetraits=" + blue_traits)
    if os.environ.get("TUNE"):
        args.append("--tune=" + os.environ["TUNE"])
    out = subprocess.run(args, capture_output=True, text=True, timeout=7200).stdout
    for line in out.splitlines():
        if line.startswith("SUMMARY "):
            return json.loads(line[8:])
    raise RuntimeError("no SUMMARY\n" + out[-2000:])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("variants", nargs="*", default=[""])
    ap.add_argument("--persona", required=True)
    ap.add_argument("--games", type=int, default=10)
    ap.add_argument("--bars", type=int, default=24)
    ap.add_argument("--seed", type=int, default=700)
    a = ap.parse_args()
    field = [p for p in PERSONAS if p != a.persona]
    for var in a.variants:
        jobs = []
        for i, foe in enumerate(field):
            jobs.append((i, 0, (a.persona, foe, a.games // 2, a.seed + i * 10, a.bars, var, "")))
            jobs.append((i, 1, (foe, a.persona, a.games // 2, a.seed + i * 10 + 5, a.bars, "", var)))
        with ThreadPoolExecutor(WORKERS) as ex:
            res = list(ex.map(lambda j: (j[0], j[1], run(*j[2])), jobs))
        parts, tot_w, tot_n = [], 0.0, 0.0
        for i, foe in enumerate(field):
            w = n = 0.0
            for k, side, r in res:
                if k == i:
                    w += r["wins"][side] + 0.5 * r["draws"]
                    n += r["games"]
            parts.append(f"vs {foe[:5]} {100 * w / n:.0f}%")
            tot_w += w
            tot_n += n
        print(f"[{a.persona}: {var or 'as shipped'}] " + "  ".join(parts) +
              f"  | overall {100 * tot_w / tot_n:.0f}%", flush=True)


if __name__ == "__main__":
    main()
