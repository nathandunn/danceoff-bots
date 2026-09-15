#!/usr/bin/env python3
"""Calibrate Dance-Off Bots.

  GODOT=godot WORKERS=2 python3 tools/calibrate.py probe --games 48
  GODOT=godot WORKERS=2 python3 tools/calibrate.py tune --rounds 3 --games 32
  GODOT=godot WORKERS=2 python3 tools/calibrate.py personas --games 24

probe    for each build property, specialists (0.6 in it, 0.1 in the rest) against an Even team;
         both teams share a personality drawn from a pool (Balanced, Rumbler, Showboat, Hothead)
         so fighting and dancing both get exercised; sides mirrored. Prints the specialists' win
         rate per property.
tune     moves CURVE so the mean specialist rate -> 50 % and each GAIN so its rate -> the mean,
         geometric mean of the gains pinned to 1; rewrites the constants in scripts/build.gd.
personas round robin of the personality presets on Even builds (does violence pay?).
"""
import argparse, json, math, os, re, subprocess, sys
from concurrent.futures import ThreadPoolExecutor

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BUILD = os.path.join(ROOT, "scripts", "build.gd")
GODOT = os.environ.get("GODOT", "godot")
WORKERS = int(os.environ.get("WORKERS", "2"))
PROPS = ["rhythm", "flair", "balance", "strength", "arm"]
POOL = ["Balanced", "Rumbler", "Showboat", "Hothead"]
PERSONAS = ["Balanced", "Showboat", "Drill Team", "Rumbler", "Hothead", "Wallflower"]
EVEN = "0.2,0.2,0.2,0.2,0.2"


def run(red, blue, redbuild, bluebuild, games, seed, gains=None, bars=None):
    args = [GODOT, "--headless", "--path", ROOT, "--", f"--sim={games}", f"--red={red}", f"--blue={blue}",
            f"--redbuild={redbuild}", f"--bluebuild={bluebuild}", f"--seed={seed}"]
    if gains:
        args.append("--gains=" + ",".join(f"{k}:{v:.4f}" for k, v in gains.items()))
    if bars:
        args.append(f"--bars={bars}")
    if os.environ.get("TUNE"):
        args.append("--tune=" + os.environ["TUNE"])
    out = subprocess.run(args, capture_output=True, text=True, timeout=7200).stdout
    for line in out.splitlines():
        if line.startswith("SUMMARY "):
            return json.loads(line[8:])
    raise RuntimeError("no SUMMARY from " + " ".join(args) + "\n" + out[-3000:])


def spec(p):
    return ",".join("0.6" if q == p else "0.1" for q in PROPS)


def read_consts():
    src = open(BUILD).read()
    g = json.loads(re.search(r"const GAINS := (\{[^}]*\})", src).group(1))
    c = float(re.search(r"const CURVE := ([0-9.]+)", src).group(1))
    return g, c


def write_consts(g, c):
    src = open(BUILD).read()
    src = re.sub(r"const GAINS := \{[^}]*\}", "const GAINS := {" + ", ".join(f'"{k}": {g[k]:.3f}' for k in PROPS) + "}", src)
    src = re.sub(r"const CURVE := [0-9.]+", f"const CURVE := {c:.3f}", src)
    open(BUILD, "w").write(src)


def probe(games, gains, curve, seed=100, bars=None):
    g = dict(gains)
    g["curve"] = curve
    per = max(games // (2 * len(POOL)), 1)
    jobs = []
    for i, p in enumerate(PROPS):
        for j, persona in enumerate(POOL):
            s = seed + i * 1000 + j * 100
            jobs.append((p, 0, (persona, persona, spec(p), EVEN, per, s, g, bars)))
            jobs.append((p, 1, (persona, persona, EVEN, spec(p), per, s + 50, g, bars)))
    with ThreadPoolExecutor(WORKERS) as ex:
        res = list(ex.map(lambda jb: (jb[0], jb[1], run(*jb[2])), jobs))
    rates = {}
    for p in PROPS:
        w = n = 0.0
        for q, side, r in res:
            if q == p:
                w += r["wins"][side] + 0.5 * r["draws"]
                n += r["games"]
        rates[p] = w / n
    return rates, per * 2 * len(POOL)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("mode", choices=["probe", "tune", "personas"])
    ap.add_argument("--games", type=int, default=48)
    ap.add_argument("--rounds", type=int, default=3)
    ap.add_argument("--seed", type=int, default=100)
    ap.add_argument("--bars", type=int, default=None)
    a = ap.parse_args()
    gains, curve = read_consts()
    if a.mode == "probe":
        rates, n = probe(a.games, gains, curve, a.seed, a.bars)
        print(f"gains={gains} curve={curve:.3f}  ({n} games per property)")
        print("specialist win rate: " + "  ".join(f"{p} {100 * rates[p]:.0f}%" for p in PROPS))
        print(f"mean {100 * sum(rates.values()) / len(rates):.1f}%")
    elif a.mode == "tune":
        for r in range(a.rounds):
            rates, n = probe(a.games, gains, curve, a.seed + 7919 * r, a.bars)
            mean = sum(rates.values()) / len(rates)
            print(f"round {r + 1}: " + "  ".join(f"{p} {100 * rates[p]:.0f}%" for p in PROPS) + f"  mean {100 * mean:.0f}%  curve {curve:.3f}", flush=True)
            curve = min(max(curve * math.exp(-2.0 * (0.5 - mean)), 0.05), 2.0)
            for p in PROPS:
                gains[p] = min(max(gains[p] * math.exp(2.5 * (mean - rates[p])), 0.1), 5.0)
            gm = math.exp(sum(math.log(gains[p]) for p in PROPS) / len(PROPS))
            for p in PROPS:
                gains[p] = min(max(gains[p] / gm, 0.1), 5.0)
            write_consts(gains, curve)
            print("  -> " + ", ".join(f"{p} {gains[p]:.3f}" for p in PROPS) + f", curve {curve:.3f}", flush=True)
    else:
        jobs = []
        for i, x in enumerate(PERSONAS):
            for j, y in enumerate(PERSONAS):
                if j <= i:
                    continue
                s = a.seed + i * 100 + j
                jobs.append((x, y, 0, (x, y, EVEN, EVEN, a.games // 2, s, None, a.bars)))
                jobs.append((x, y, 1, (y, x, EVEN, EVEN, a.games // 2, s + 50, None, a.bars)))
        with ThreadPoolExecutor(WORKERS) as ex:
            res = list(ex.map(lambda jb: (jb[0], jb[1], jb[2], run(*jb[3])), jobs))
        table = {}
        for x, y, side, r in res:
            key = (x, y)
            w = r["wins"][side] + 0.5 * r["draws"]
            t = table.setdefault(key, [0.0, 0])
            t[0] += w
            t[1] += r["games"]
        for (x, y), (w, n) in sorted(table.items()):
            print(f"{x:>11} vs {y:<11} {100 * w / n:5.1f}% ({n} songs)")
        score = {p: [0.0, 0] for p in PERSONAS}
        for (x, y), (w, n) in table.items():
            score[x][0] += w; score[x][1] += n
            score[y][0] += n - w; score[y][1] += n
        print("overall: " + "  ".join(f"{p} {100 * s[0] / s[1]:.0f}%" for p, s in score.items()))


if __name__ == "__main__":
    main()
