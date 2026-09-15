#!/usr/bin/env python3
"""Does violence pay about as well as dancing? Sweep the levers in scripts/tune.gd.

  GODOT=godot WORKERS=2 python3 tools/tune_violence.py --games 12 --bars 24 '' 'kd_base:0.3,rejoin_beats:4'

Each config ('' is the shipped defaults) plays every pair below, the violent crew first, games/2
songs on each side, and prints the violent crew's win rate per pair, the mean and knockdowns a song.
Target: every pair inside 40-60 %.
"""
import argparse, json, os, subprocess
from concurrent.futures import ThreadPoolExecutor

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GODOT = os.environ.get("GODOT", "godot")
WORKERS = int(os.environ.get("WORKERS", "2"))
PAIRS = [("Rumbler", "Showboat"), ("Rumbler", "Drill Team"), ("Rumbler", "Wallflower"),
         ("Rumbler", "Balanced"), ("Hothead", "Showboat"), ("Hothead", "Drill Team")]


def run(red, blue, games, seed, tune, bars):
    args = [GODOT, "--headless", "--path", ROOT, "--", f"--sim={games}", f"--red={red}", f"--blue={blue}",
            f"--seed={seed}", f"--bars={bars}"]
    if tune:
        args.append("--tune=" + tune)
    out = subprocess.run(args, capture_output=True, text=True, timeout=3600).stdout
    for line in out.splitlines():
        if line.startswith("SUMMARY "):
            return json.loads(line[8:])
    raise RuntimeError("no SUMMARY\n" + out[-2000:])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("configs", nargs="*", default=[""])
    ap.add_argument("--games", type=int, default=12)
    ap.add_argument("--bars", type=int, default=48)
    ap.add_argument("--seed", type=int, default=500)
    a = ap.parse_args()
    for cfg in a.configs:
        jobs = []
        for i, (v, d) in enumerate(PAIRS):
            jobs.append((i, 0, (v, d, a.games // 2, a.seed + i * 10, cfg, a.bars)))
            jobs.append((i, 1, (d, v, a.games // 2, a.seed + i * 10 + 5, cfg, a.bars)))
        with ThreadPoolExecutor(WORKERS) as ex:
            res = list(ex.map(lambda j: (j[0], j[1], run(*j[2])), jobs))
        rates, kos, parts = [], [], []
        for i, (v, d) in enumerate(PAIRS):
            w = n = ko = 0.0
            for k, side, r in res:
                if k == i:
                    w += r["wins"][side] + 0.5 * r["draws"]
                    n += r["games"]
                    ko += r["avg"]["knockdowns"][side] * r["games"]
            rates.append(w / n)
            kos.append(ko / n)
            parts.append(f"{v[:4]}-{d[:5]} {100 * w / n:.0f}%")
        print(f"[{cfg or 'defaults'}] " + "  ".join(parts) +
              f"  | mean {100 * sum(rates) / len(rates):.0f}%  worst {100 * max(abs(x - 0.5) for x in rates):.0f}pt off  KOs/song {sum(kos) / len(kos):.1f}", flush=True)


if __name__ == "__main__":
    main()
