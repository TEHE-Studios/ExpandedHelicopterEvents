#!/usr/bin/env python3
"""
EHE Preset Validator
Parses preset Lua files and runs static analysis checks.

Usage (from tools/ directory):
    python validate.py
    python validate.py --presets ../Contents/media/lua/shared/EHE_presets.lua

Exit codes:
    0  — no errors (warnings are allowed)
    1  — one or more ERROR-level checks failed
"""

import re
import sys
import argparse
from pathlib import Path

# Reuse parser + data from generate.py
sys.path.insert(0, str(Path(__file__).parent))
from pathlib import Path as _Path

SCRIPT_DIR = _Path(__file__).parent

from generate import (
    parse_preset_file,
    parse_random_selection,
    parse_progression,
    load_sandbox_freq_vars,
    build_freq_affects,
    resolve_default_paths,
    refresh_defaults,
    DEFAULTS,
)
import generate as _generate

# ── ANSI colours (disabled on Windows/CI if NO_COLOR set) ─────────────
import os
_USE_COLOR = sys.stdout.isatty() and os.environ.get("NO_COLOR") != "1"
def _c(code, s): return f"\033[{code}m{s}\033[0m" if _USE_COLOR else s
PASS  = lambda s: _c("32", s)
WARN  = lambda s: _c("33", s)
ERR   = lambda s: _c("31", s)
DIM   = lambda s: _c("2",  s)
BOLD  = lambda s: _c("1",  s)
CYAN  = lambda s: _c("36", s)


# ═══════════════════════════════════════════════════════════════════════
# RESULT HELPERS
# ═══════════════════════════════════════════════════════════════════════

class Result:
    __slots__ = ("level", "check", "preset", "msg")
    def __init__(self, level, check, preset, msg):
        self.level  = level   # "PASS" | "WARN" | "ERROR"
        self.check  = check
        self.preset = preset
        self.msg    = msg

    def __str__(self):
        tag = {"PASS": PASS("[PASS] "), "WARN": WARN("[WARN] "), "ERROR": ERR("[ERR]  ")}[self.level]
        loc = DIM(f" ({self.preset})") if self.preset else ""
        return f"  {tag}{self.check}: {self.msg}{loc}"


def passed(check, msg, preset=None):  return Result("PASS",  check, preset, msg)
def warned(check, msg, preset=None):  return Result("WARN",  check, preset, msg)
def errord(check, msg, preset=None):  return Result("ERROR", check, preset, msg)


# ═══════════════════════════════════════════════════════════════════════
# RAW-TEXT CHECKS (need source before parsing resolves duplicates)
# ═══════════════════════════════════════════════════════════════════════

def check_duplicate_progression_keys(raw_texts):
    """
    Lua silently drops earlier duplicate table keys.
    A presetProgression with two entries for the same child ID means one
    stage is unreachable — this can only be detected on raw source text.
    """
    results = []
    for source_name, text in raw_texts.items():
        # Find each presetProgression = { ... } block
        for prog_m in re.finditer(r'presetProgression\s*=\s*\{([^}]+)\}', text, re.DOTALL):
            block = prog_m.group(1)
            keys = re.findall(r'\["([^"]+)"\]\s*=', block)
            seen = {}
            for key in keys:
                if key in seen:
                    # Back-track to find the owning preset ID
                    pre = text[:prog_m.start()]
                    owners = re.findall(r'eHelicopter_PRESETS\["([^"]+)"\]', pre)
                    owner = owners[-1] if owners else "unknown"
                    prev_val_m = re.search(rf'\["{re.escape(key)}"\]\s*=\s*([^\n,}}]+)', block)
                    prev_val = prev_val_m.group(1).strip() if prev_val_m else "?"
                    results.append(errord(
                        "Duplicate presetProgression key",
                        f"key '{key}' appears twice — earlier factor({seen[key]}) silently "
                        f"overwritten; unreachable stage",
                        owner
                    ))
                else:
                    val_m = re.search(rf'\["{re.escape(key)}"\]\s*=\s*([^\n,}}]+)', block)
                    seen[key] = val_m.group(1).strip() if val_m else "?"

    if not results:
        results.append(passed("Duplicate presetProgression key", "No duplicate keys found"))
    return results


# ═══════════════════════════════════════════════════════════════════════
# PARSED-DATA CHECKS
# ═══════════════════════════════════════════════════════════════════════

def check_progression_refs(all_presets):
    """All IDs in presetProgression must exist in the preset table."""
    results = []
    bad = []
    for pid, data in all_presets.items():
        raw = data.get("presetProgression")
        if not isinstance(raw, dict):
            continue
        for child_id in raw.keys():
            if child_id not in all_presets:
                bad.append((pid, child_id))
    if bad:
        for owner, missing in bad:
            results.append(errord(
                "Progression ref",
                f"references unknown preset '{missing}'",
                owner
            ))
    else:
        results.append(passed("Progression ref", f"All presetProgression IDs resolve"))
    return results


def check_random_selection_refs(all_presets):
    """All IDs in presetRandomSelection must exist in the preset table."""
    results = []
    bad = []
    for pid, data in all_presets.items():
        raw = data.get("presetRandomSelection")
        if not isinstance(raw, (list, dict)):
            continue
        items = parse_random_selection(raw)
        for item in items:
            if item["id"] not in all_presets:
                bad.append((pid, item["id"]))
    if bad:
        for owner, missing in bad:
            results.append(errord(
                "Random selection ref",
                f"references unknown preset '{missing}'",
                owner
            ))
    else:
        results.append(passed("Random selection ref", "All presetRandomSelection IDs resolve"))
    return results


def check_inherit_refs(all_presets):
    """All IDs in inherit must exist in the preset table."""
    results = []
    bad = []
    for pid, data in all_presets.items():
        raw = data.get("inherit")
        if not isinstance(raw, (list, dict)):
            continue
        ids = raw if isinstance(raw, list) else list(raw.values())
        for iid in ids:
            if isinstance(iid, str) and iid not in all_presets:
                bad.append((pid, iid))
    if bad:
        for owner, missing in bad:
            results.append(errord(
                "Inherit ref",
                f"inherits from unknown preset '{missing}'",
                owner
            ))
    else:
        results.append(passed("Inherit ref", "All inherit IDs resolve"))
    return results


def check_inherit_cycles(all_presets):
    """Detect circular inheritance chains."""
    results = []
    cycles = []

    def get_parents(pid):
        raw = all_presets.get(pid, {}).get("inherit")
        if not isinstance(raw, (list, dict)):
            return []
        ids = raw if isinstance(raw, list) else list(raw.values())
        return [i for i in ids if isinstance(i, str)]

    def has_cycle(start, visited=None):
        if visited is None:
            visited = set()
        if start in visited:
            return True
        visited.add(start)
        for parent in get_parents(start):
            if has_cycle(parent, set(visited)):
                return True
        return False

    for pid in all_presets:
        if has_cycle(pid):
            cycles.append(pid)

    if cycles:
        for pid in cycles:
            results.append(errord("Circular inherit", f"circular inheritance chain detected", pid))
    else:
        results.append(passed("Circular inherit", "No circular inheritance chains"))
    return results


def _scalar(v, default):
    """Return the first element if v is a list, else v itself, else default."""
    if isinstance(v, list):
        return v[0] if v else default
    return v if v is not None else default


def check_spawn_windows(all_presets):
    """
    For forScheduling=true presets, the effective startDay should be ≤ cutOffDay.
    Also warn on zero-width windows (start == cutoff) for non-one-time events.
    """
    results = []
    dur = 90

    bad_windows  = []
    zero_windows = []

    for pid, data in all_presets.items():
        if not data.get("forScheduling"):
            continue
        sf      = float(_scalar(data.get("eventStartDayFactor"),  DEFAULTS.get("eventStartDayFactor",  0)))
        cf      = float(_scalar(data.get("eventCutOffDayFactor"), DEFAULTS.get("eventCutOffDayFactor", 0.34)))
        sched_f = float(_scalar(data.get("schedulingFactor"),     DEFAULTS.get("schedulingFactor",     1)))

        sd  = round(sf * dur + 0.5)
        cod = round(cf * (sd + dur) + 0.5)

        if sd > cod:
            bad_windows.append((pid, sd, cod))
        elif sd == cod and sched_f < 99990:
            zero_windows.append((pid, sd, cod))

    if bad_windows:
        for pid, sd, cod in bad_windows:
            results.append(errord(
                "Spawn window",
                f"startDay({sd}) > cutOffDay({cod}) — event can never spawn",
                pid
            ))
    else:
        results.append(passed("Spawn window", "All windows are valid (start ≤ cutoff)"))

    for pid, sd, cod in zero_windows:
        results.append(warned(
            "Zero-width window",
            f"startDay == cutOffDay == {sd} but not a one-time event (schedulingFactor not sentinel)",
            pid
        ))

    return results


def check_freq_sandbox_vars(all_presets):
    """
    Each Frequency_ sandbox var should match at least one preset ID directly
    (the scheduler does "Frequency_"..presetID). Vars with no matching preset
    are orphaned — the sandbox option has no in-game effect.
    """
    results = []
    all_ids = set(all_presets.keys())
    orphaned = []
    matched  = []

    for sv in _generate.SANDBOX_FREQ_VARS:
        if sv["key"] in all_ids:
            matched.append(sv["key"])
        else:
            orphaned.append(sv["key"])

    if matched:
        results.append(passed(
            "Freq var mapping",
            f"{len(matched)} Frequency_ var(s) matched to preset IDs"
        ))
    for key in orphaned:
        results.append(warned(
            "Freq var orphan",
            f"Frequency_{key} in sandbox-options.txt has no matching preset ID — "
            f"this option has no effect"
        ))

    return results


def check_single_entry_pools(all_presets):
    """Warn on presetRandomSelection with only one entry (always deterministic)."""
    results = []
    singletons = []
    for pid, data in all_presets.items():
        raw = data.get("presetRandomSelection")
        if not isinstance(raw, (list, dict)):
            continue
        items = parse_random_selection(raw)
        if len(items) == 1:
            singletons.append((pid, items[0]["id"]))

    if singletons:
        for pid, only in singletons:
            results.append(warned(
                "Single-entry pool",
                f"presetRandomSelection has one entry — always resolves to '{only}'",
                pid
            ))
    else:
        results.append(passed("Single-entry pool", "No single-entry random pools"))
    return results


def check_scheduling_fields(all_presets):
    """Validate field types and sensible ranges on schedulable presets."""
    results = []
    field_errors = []

    for pid, data in all_presets.items():
        if not data.get("forScheduling"):
            continue

        # eventSpawnWeight must be > 0
        w = data.get("eventSpawnWeight", DEFAULTS.get("eventSpawnWeight", 10))
        if isinstance(w, (int, float)) and w <= 0:
            field_errors.append((pid, f"eventSpawnWeight={w} — must be > 0"))

        sf = data.get("schedulingFactor", DEFAULTS.get("schedulingFactor", 1))
        if isinstance(sf, (int, float)) and sf <= 0:
            field_errors.append((pid, f"schedulingFactor={sf} — must be > 0"))

        # factors must be >= 0
        for field in ("eventStartDayFactor", "eventCutOffDayFactor"):
            v = data.get(field, DEFAULTS.get(field, 0))
            if isinstance(v, (int, float)) and v < 0:
                field_errors.append((pid, f"{field}={v} — must be ≥ 0"))

        # flightHours sanity
        # Values > 24 are intentional: the scheduler wraps them with
        #   `if startTime > 24 then startTime = startTime - 24 end`
        # so e.g. {20, 27} = 20:00–midnight or 01:00–03:00 next day (overnight).
        # Max useful value is 47 (= 24+23, still a single wrap).
        fh = data.get("flightHours")
        if isinstance(fh, list) and len(fh) >= 2:
            h0, h1 = fh[0], fh[1]
            if not (0 <= h0 <= 47 and 0 <= h1 <= 47):
                field_errors.append((pid, f"flightHours=[{h0},{h1}] — hours should be 0–47 (>24 wraps to next day)"))
            if h0 > h1:
                field_errors.append((pid, f"flightHours=[{h0},{h1}] — start > end"))

        # markerColor channels should be 0–1
        mc = data.get("markerColor")
        if isinstance(mc, dict):
            for ch in ("r", "g", "b"):
                v = mc.get(ch, 1)
                if isinstance(v, (int, float)) and not (0 <= v <= 1):
                    field_errors.append((pid, f"markerColor.{ch}={v} — expected 0.0–1.0"))

    if field_errors:
        for pid, msg in field_errors:
            results.append(errord("Field validation", msg, pid))
    else:
        results.append(passed("Field validation", "All schedulable preset fields pass range checks"))
    return results


def check_progression_factor_order(all_presets):
    """
    Warn if presetProgression factors aren't strictly increasing — the scheduler
    picks the highest qualifying factor, so equal factors create ambiguity.
    """
    results = []
    issues = []
    for pid, data in all_presets.items():
        raw = data.get("presetProgression")
        if not isinstance(raw, dict):
            continue
        items = parse_progression(raw)
        factors = [i["factor"] for i in items]
        # Check for duplicates (after parsing — distinct keys with same value)
        if len(factors) != len(set(factors)):
            seen = {}
            for item in items:
                f = item["factor"]
                if f in seen:
                    issues.append((pid, f"factor {f} appears more than once — ambiguous selection"))
                seen[f] = True

    if issues:
        for pid, msg in issues:
            results.append(warned("Progression factor order", msg, pid))
    else:
        results.append(passed("Progression factor order", "All progression factors are distinct"))
    return results


def check_unreferenced_schedulable(all_presets):
    """
    Info: forScheduling=true presets that are also referenced as children
    (progression/random) will be scheduled BOTH directly AND as part of their parent.
    This is usually intentional for one-time events but worth noting.
    """
    results = []
    all_children = set()
    for data in all_presets.values():
        rp = data.get("presetProgression")
        rr = data.get("presetRandomSelection")
        if isinstance(rp, dict):
            all_children.update(rp.keys())
        if isinstance(rr, (list, dict)):
            all_children.update(i["id"] for i in parse_random_selection(rr))

    dual = []
    for pid, data in all_presets.items():
        if data.get("forScheduling") and pid in all_children:
            sched_f = float(data.get("schedulingFactor", DEFAULTS.get("schedulingFactor", 1)))
            if sched_f >= 99990:
                # Expected — one-time events are scheduled both ways intentionally
                pass
            else:
                dual.append(pid)

    if dual:
        for pid in dual:
            results.append(warned(
                "Dual-scheduled",
                "forScheduling=true AND referenced as a child — will schedule independently "
                "AND through parent's progression/random",
                pid
            ))
    else:
        results.append(passed("Dual-scheduled", "No unexpected dual-scheduled presets"))
    return results



# ═══════════════════════════════════════════════════════════════════════
# ASSET DISCOVERY
# ═══════════════════════════════════════════════════════════════════════

def _glob_mod_files(patterns, fallback_patterns=None):
    """Try glob patterns rooted at SCRIPT_DIR; fall back if nothing found."""
    found = []
    for pattern in patterns:
        found.extend(SCRIPT_DIR.glob(pattern))
    if not found and fallback_patterns:
        for pattern in fallback_patterns:
            found.extend(SCRIPT_DIR.glob(pattern))
    return found


def discover_vehicle_ids():
    """
    Scan script .txt files for `vehicle XYZ` declarations.
    Returns a set of known vehicle type IDs.
    """
    ids = set()
    files = _glob_mod_files(
        ["../Contents/mods/*/*/media/scripts/*.txt",
         "../Contents/mods/*/*/media/lua/shared/*.txt"],
        ["../Contents/media/scripts/*.txt",
         "../Contents/media/lua/shared/*.txt"],
    )
    for f in files:
        try:
            text = f.read_text(encoding="utf-8", errors="replace")
            for m in re.finditer(r'(?:^|\n)[ \t]*vehicle\s+([A-Za-z0-9_]+)', text):
                ids.add(m.group(1))
        except Exception:
            pass
    return ids


def discover_outfit_ids():
    """
    Scan clothing.xml and hairOutfitDefinitions.lua for defined outfit IDs.
    Returns a set of known outfit IDs.
    """
    ids = set()
    files = _glob_mod_files(
        ["../Contents/mods/*/*/media/clothing/*.xml",
         "../Contents/mods/*/*/media/lua/shared/*[Hh]air[Oo]utfit*.lua"],
        ["../Contents/media/clothing/*.xml",
         "../Contents/media/lua/shared/*[Hh]air[Oo]utfit*.lua"],
    )
    for f in files:
        try:
            text = f.read_text(encoding="utf-8", errors="replace")
            for m in re.finditer(r'<m_Name>([^<]+)</m_Name>', text):
                ids.add(m.group(1).strip())
            for m in re.finditer(r'\boutfit\s*=\s*"([^"]+)"', text):
                ids.add(m.group(1))
        except Exception:
            pass
    return ids


def extract_formation_preset_ids(raw):
    """
    Extract preset ID strings from a formationIDs mixed array.
    Format: {presetID, spawnChance, {minCount, maxCount}, presetID, ...}
    """
    if isinstance(raw, dict):
        arr = [raw[k] for k in sorted(raw.keys(),
               key=lambda x: int(x) if str(x).isdigit() else 9999)]
    elif isinstance(raw, list):
        arr = raw
    else:
        return []
    ids = []
    i = 0
    while i < len(arr):
        if isinstance(arr[i], str):
            ids.append(arr[i])
            i += 1
            if i < len(arr) and isinstance(arr[i], (int, float)):
                i += 1
            if i < len(arr) and isinstance(arr[i], (list, dict)):
                i += 1
        else:
            i += 1
    return ids


# ═══════════════════════════════════════════════════════════════════════
# CHECKS 12-14  (vehicle IDs, outfit IDs, formationIDs)
# ═══════════════════════════════════════════════════════════════════════

def check_vehicle_ids(all_presets):
    """
    Warn when crashType or scrapVehicles references an ID not found in
    any scanned .txt script file.  Level is WARN (not ERROR) because some
    IDs may originate from vanilla PZ or unscanned mods.
    """
    results = []
    known = discover_vehicle_ids()

    if not known:
        results.append(warned(
            "Vehicle IDs",
            "No vehicle script (.txt) files found — cannot validate crashType/scrapVehicles. "
            "Expected at: Contents/mods/<mod>/<version>/media/scripts/*.txt"
        ))
        return results

    results.append(passed("Vehicle IDs discovered", f"{len(known)} type IDs found in .txt script files"))

    missing = []
    for pid, data in all_presets.items():
        for field in ("crashType", "scrapVehicles"):
            val = data.get(field)
            if not isinstance(val, list):
                continue
            for vid in val:
                if isinstance(vid, str) and vid not in known:
                    missing.append((pid, field, vid))

    if missing:
        for pid, field, vid in missing:
            results.append(warned(
                "Vehicle ID ref",
                f"{field} = '{vid}' — not in any scanned .txt file "
                "(may be vanilla PZ or unscanned sub-mod)",
                pid
            ))
    else:
        results.append(passed("Vehicle ID ref",
            "All crashType/scrapVehicles IDs found in scanned .txt files"))

    return results


def check_outfit_ids(all_presets):
    """
    Validate crew outfit IDs against discovered clothing definitions.
    - EHE_*/SWH_* prefixed IDs are mod-defined → ERROR if not found locally.
    - All others (vanilla PZ names) → WARN if not found locally.
    """
    results = []
    known = discover_outfit_ids()

    if known:
        results.append(passed("Outfit IDs discovered",
            f"{len(known)} outfit IDs found in clothing files"))
    else:
        results.append(warned(
            "Outfit IDs",
            "No clothing.xml or hairOutfitDefinitions.lua found — "
            "cannot validate crew outfit IDs. "
            "Expected at: Contents/mods/<mod>/<version>/media/clothing/*.xml"
        ))

    # Deduplicate: track unique (outfit_id -> set of preset IDs)
    seen_local    = {}   # EHE/SWH prefixed — should be discoverable locally
    seen_external = {}   # vanilla-looking names — may be fine

    for pid, data in all_presets.items():
        crew = data.get("crew")
        if not isinstance(crew, (list, dict)):
            continue
        entries = crew if isinstance(crew, list) else list(crew.values())
        for entry in entries:
            if not isinstance(entry, dict):
                continue
            outfit = entry.get("outfit")
            if not isinstance(outfit, str) or outfit in known:
                continue
            if re.match(r'^(EHE_?|SWH_)', outfit):
                seen_local.setdefault(outfit, set()).add(pid)
            else:
                seen_external.setdefault(outfit, set()).add(pid)

    for outfit, pids in sorted(seen_local.items()):
        results.append(errord(
            "Outfit ID ref",
            f"'{outfit}' has EHE/SWH prefix but not found in any scanned "
            f"clothing file (used in: {', '.join(sorted(pids))})"
        ))

    for outfit, pids in sorted(seen_external.items()):
        results.append(warned(
            "Outfit ID ref",
            f"'{outfit}' not found locally — assumed vanilla PZ or external mod "
            f"(used in: {', '.join(sorted(pids))})"
        ))

    if not seen_local and not seen_external and known:
        results.append(passed("Outfit ID ref",
            "All EHE/SWH outfit IDs found in scanned clothing files"))

    return results


def check_formation_ids(all_presets):
    """
    ERROR when a formationIDs entry references a preset that doesn't exist.
    """
    results = []
    bad = []

    for pid, data in all_presets.items():
        raw = data.get("formationIDs")
        if not raw:
            continue
        for fid in extract_formation_preset_ids(raw):
            if fid not in all_presets:
                bad.append((pid, fid))

    if bad:
        for pid, missing in bad:
            results.append(errord(
                "formationIDs ref",
                f"references undefined preset '{missing}'",
                pid
            ))
    else:
        results.append(passed("formationIDs ref",
            "All formationIDs preset references resolve"))

    return results



# ═══════════════════════════════════════════════════════════════════════
# RUNNER
# ═══════════════════════════════════════════════════════════════════════

CHECKS = [
    # (function,                        needs_raw_texts)
    (check_duplicate_progression_keys,  True),
    (check_progression_refs,            False),
    (check_random_selection_refs,       False),
    (check_inherit_refs,                False),
    (check_inherit_cycles,              False),
    (check_formation_ids,               False),
    (check_spawn_windows,               False),
    (check_freq_sandbox_vars,           False),
    (check_single_entry_pools,          False),
    (check_scheduling_fields,           False),
    (check_progression_factor_order,    False),
    (check_unreferenced_schedulable,    False),
    (check_vehicle_ids,                 False),
    (check_outfit_ids,                  False),
]


def run(preset_paths):
    print(BOLD("\nEHE Preset Validator"))
    print("=" * 44)

    refresh_defaults()

    # Load presets
    all_presets = {}
    raw_texts   = {}

    for path in preset_paths:
        p = Path(path)
        if not p.exists():
            print(DIM(f"  [skip] {p}"))
            continue
        print(f"  Loading: {p.name}")
        parsed = parse_preset_file(p)
        all_presets.update(parsed)
        try:
            raw_texts[p.name] = p.read_text(encoding="utf-8", errors="replace")
        except Exception:
            pass

    if not all_presets:
        print(ERR("\nNo presets loaded — check file paths."))
        return 1

    # Load SANDBOX_FREQ_VARS from disk so freq-key checks use live data
    _generate.SANDBOX_FREQ_VARS = load_sandbox_freq_vars()
    build_freq_affects(all_presets)

    schedulable = [pid for pid, d in all_presets.items() if d.get("forScheduling")]
    print(f"\n  Total presets : {len(all_presets)}")
    print(f"  Schedulable   : {len(schedulable)}")
    print(f"  Sources       : {', '.join(raw_texts.keys()) or 'none'}")
    print()

    all_results = []
    for fn, needs_raw in CHECKS:
        try:
            if needs_raw:
                res = fn(raw_texts)
            else:
                res = fn(all_presets)
            all_results.extend(res)
        except Exception as e:
            all_results.append(errord(fn.__name__, f"check threw an exception: {e}"))

    # Print results grouped by level
    errors = [r for r in all_results if r.level == "ERROR"]
    warns  = [r for r in all_results if r.level == "WARN"]
    passes = [r for r in all_results if r.level == "PASS"]

    if passes:
        print(BOLD("Passes:"))
        for r in passes:
            print(r)

    if warns:
        print(BOLD("\nWarnings:"))
        for r in warns:
            print(r)

    if errors:
        print(BOLD("\nErrors:"))
        for r in errors:
            print(r)

    # Summary
    total = len(all_results)
    print("\n" + "=" * 44)
    status_line = (
        f"  {PASS(str(len(passes)))} passed  "
        f"{WARN(str(len(warns)))} warnings  "
        f"{ERR(str(len(errors)))} errors"
        f"  {DIM(f'({total} checks)')}"
    )
    print(status_line)

    if errors:
        print(ERR(f"\n  ✗ FAILED — {len(errors)} error(s) must be resolved\n"))
        return 1
    elif warns:
        print(WARN(f"\n  ✓ PASSED with {len(warns)} warning(s)\n"))
        return 0
    else:
        print(PASS("\n  ✓ ALL CHECKS PASSED\n"))
        return 0


def main():
    parser = argparse.ArgumentParser(description="Validate EHE preset Lua files.")
    parser.add_argument(
        "--presets", nargs="*", metavar="FILE",
        help="Preset Lua files to validate (relative to tools/ directory). "
             "Defaults to EHE_presets.lua and SWH_presets.lua."
    )
    args = parser.parse_args()

    if args.presets:
        script_dir = Path(__file__).parent
        paths = [(script_dir / p).resolve() for p in args.presets]
    else:
        paths = resolve_default_paths()

    sys.exit(run(paths))


if __name__ == "__main__":
    main()
