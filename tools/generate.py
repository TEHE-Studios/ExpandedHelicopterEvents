#!/usr/bin/env python3
"""
EHE Timeline Generator
Parses EHE_presets.lua (and any additional preset files) and outputs
a standalone timeline.html visualizer.

Usage (from tools/ directory):
    python generate.py
    python generate.py --extra ../Contents/media/lua/shared/SWH_presets.lua

Output: tools/timeline.html  (open directly in any browser, no server needed)
"""

import re
import json
import math
import argparse
import sys
import textwrap
from pathlib import Path

# Optional: Lua-based simulation for accurate initial counts in the HTML
def _try_install_lupa():
    try:
        import lupa  # noqa: F401
        return True
    except ImportError:
        pass
    try:
        import subprocess
        subprocess.check_call(
            [sys.executable, "-m", "pip", "install", "lupa", "--break-system-packages", "-q"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        return True
    except Exception:
        return False

try:
    _try_install_lupa()
    from simulate import run_simulation as _lua_simulate
    _LUA_SIM_AVAILABLE = True
except ImportError:
    _LUA_SIM_AVAILABLE = False

SCRIPT_DIR  = Path(__file__).parent
OUTPUT_FILE = SCRIPT_DIR / "timeline.html"

# Glob patterns for preset discovery, relative to SCRIPT_DIR (tools/).
# The version folder (e.g. "42.15", "common") is matched with *.
# All matching files are collected; later files extend earlier ones.
DEFAULT_PRESET_GLOBS = [
    "../Contents/mods/*/*/media/lua/shared/EHE_presets.lua",
    "../Contents/mods/*/*/media/lua/shared/SWH_presets.lua",
]

# Keep this for validate.py import compatibility
DEFAULT_PRESET_PATHS = DEFAULT_PRESET_GLOBS


def resolve_default_paths():
    """
    Expand DEFAULT_PRESET_GLOBS against the filesystem.
    Returns an ordered list of resolved Path objects, deduplicated.
    Returns an empty list if nothing matches (caller handles the error).
    """
    found = []
    for pattern in DEFAULT_PRESET_GLOBS:
        for m in sorted(SCRIPT_DIR.glob(pattern)):
            if m not in found:
                found.append(m)
    return found

# ── GLOBAL DEFAULTS (from EHE_mainVariables.lua) ───────────────────────
DEFAULTS = {
    "schedulingFactor":      1,
    "eventSpawnWeight":      10,
    "eventStartDayFactor":   0,
    "eventCutOffDayFactor":  0.34,
    "ignoreContinueScheduling": False,
}

# ── SANDBOX FREQUENCY VARS ─────────────────────────────────────────────
# Maps sandbox key → which preset IDs it actually controls.
# hasMatch is computed at runtime — True when the key matches an actual parsed preset ID.
SANDBOX_FREQ_VARS = [
    {"key": "military",      "label": "Military",       "affectsIDs": ["military_nonhostile", "military_hostile"]},
    {"key": "police",        "label": "Police",          "affectsIDs": ["police"]},
    {"key": "news_chopper",  "label": "News Chopper",    "affectsIDs": ["news_Bell206"]},
    {"key": "jet",           "label": "Jets",            "affectsIDs": ["jets", "jet_pass", "jet_pass_louder"]},
    {"key": "Resupply_drop", "label": "Resupply Drop",   "affectsIDs": []},
    {"key": "survivor_heli", "label": "Survivor Heli",   "affectsIDs": ["survivors"]},
    {"key": "deserters",     "label": "Deserters",       "affectsIDs": ["deserters"]},
]

# ── GROUP DEFINITIONS ──────────────────────────────────────────────────
# Order matters for display. Each rule: (id_prefix_or_exact, group_id)
GROUP_RULES = [
    ("air_raid",          "special"),
    ("military_nonhostile","military"),
    ("military_hostile",  "military"),
    ("military_",         "military"),
    ("drone",             "drones"),
    ("jet",               "jets"),
    ("news_",             "early"),
    ("police",            "early"),
    ("survivors",         "survivors"),
    ("deserters",         "late"),
]

GROUP_META = {
    "military":  {"label": "MILITARY",            "color": "#4fc35a"},
    "drones":    {"label": "DRONES",               "color": "#40e8e0"},
    "jets":      {"label": "JETS",                 "color": "#8080ff"},
    "special":   {"label": "SPECIAL EVENTS",       "color": "#e06030"},
    "early":     {"label": "EARLY GAME (CIVILIAN)","color": "#e0c020"},
    "survivors": {"label": "SURVIVORS",            "color": "#a8a8a8"},
    "late":      {"label": "LATE GAME",            "color": "#e08030"},
    "swh":       {"label": "SUPER WEIRD HELIS",    "color": "#c060e0"},
    "other":     {"label": "OTHER",                "color": "#808080"},
}

# Module-level store for raw source text, populated by main() before
# build_groups() is called, so build_preset_entry() can do raw-text checks.
_raw_source_texts = {}  # filename -> raw text


# ═══════════════════════════════════════════════════════════════════════
# LUA PARSER
# ═══════════════════════════════════════════════════════════════════════

def skip(s, i):
    """Skip whitespace and Lua comments."""
    n = len(s)
    while i < n:
        if s[i] in " \t\n\r":
            i += 1
        elif s[i:i+4] == "--[[":
            end = s.find("]]", i + 4)
            i = (end + 2) if end >= 0 else n
        elif s[i:i+2] == "--":
            end = s.find("\n", i)
            i = (end + 1) if end >= 0 else n
        else:
            break
    return i


def parse_value(s, i):
    """Parse any Lua value; return (value, new_pos)."""
    i = skip(s, i)
    n = len(s)
    if i >= n:
        return None, i

    c = s[i]

    if c == "{":
        return parse_table(s, i)

    if c == '"':
        j = i + 1
        while j < n and s[j] != '"':
            if s[j] == "\\":
                j += 1
            j += 1
        return s[i + 1:j], j + 1

    if c == "'":
        j = i + 1
        while j < n and s[j] != "'":
            if s[j] == "\\":
                j += 1
            j += 1
        return s[i + 1:j], j + 1

    # Keywords
    for kw, val in [("true", True), ("false", False), ("nil", None)]:
        end = i + len(kw)
        if s[i:end] == kw and (end >= n or not (s[end].isalnum() or s[end] == "_")):
            return val, end

    # Number
    m = re.match(r"-?(?:0x[0-9a-fA-F]+|[0-9]+\.?[0-9]*(?:[eE][+-]?[0-9]+)?)", s[i:])
    if m:
        tok = m.group(0)
        try:
            v = int(tok, 16) if "0x" in tok else (float(tok) if ("." in tok or "e" in tok.lower()) else int(tok))
        except ValueError:
            v = 0
        return v, i + len(tok)

    # Identifier or dotted name (function refs treated as opaque strings)
    m = re.match(r"[a-zA-Z_][a-zA-Z0-9_.]*", s[i:])
    if m:
        return m.group(0), i + len(m.group(0))

    return None, i + 1


def parse_table(s, i):
    """Parse a Lua table constructor { ... }; return (value, new_pos)."""
    assert s[i] == "{"
    i += 1
    arr, dct = [], {}

    while True:
        i = skip(s, i)
        if i >= len(s) or s[i] == "}":
            i += 1
            break
        if s[i] == ",":
            i += 1
            continue

        # ["key"] = value
        if s[i] == "[":
            i += 1
            key, i = parse_value(s, i)
            i = skip(s, i)
            if i < len(s) and s[i] == "]":
                i += 1
            i = skip(s, i)
            if i < len(s) and s[i] == "=":
                i += 1
            val, i = parse_value(s, i)
            if key is not None:
                dct[str(key)] = val
            continue

        # identifier = value  (but NOT ==)
        m = re.match(r"([a-zA-Z_][a-zA-Z0-9_]*)\s*=(?!=)", s[i:])
        if m:
            key = m.group(1)
            i += m.end()
            val, i = parse_value(s, i)
            dct[key] = val
            continue

        # positional array value
        val, i = parse_value(s, i)
        if val is not None:
            arr.append(val)

    if arr and not dct:
        return arr, i
    if dct and not arr:
        return dct, i
    merged = dict(dct)
    for idx, v in enumerate(arr):
        merged[idx + 1] = v
    return merged, i


def parse_preset_file(path):
    """
    Read a Lua file and extract all eHelicopter_PRESETS["id"] = {...} blocks.
    Returns dict of {preset_id: {fields...}}.
    """
    try:
        text = Path(path).read_text(encoding="utf-8", errors="replace")
    except FileNotFoundError:
        print(f"  [SKIP] Not found: {path}")
        return {}

    presets = {}
    pattern = re.compile(
        r'eHelicopter_PRESETS\["([^"]+)"\]\s*=\s*\{',
        re.MULTILINE,
    )

    for m in pattern.finditer(text):
        preset_id = m.group(1)
        body_start = m.end() - 1  # point back at opening {

        try:
            data, _ = parse_table(text, body_start)
        except Exception as e:
            print(f"  [WARN] Parse error in '{preset_id}': {e}")
            data = {}

        if not isinstance(data, dict):
            data = {}

        # Grab the nearest comment above this definition
        preceding = text[max(0, m.start() - 300) : m.start()]
        comment_matches = re.findall(r"--\s*([^\n\-][^\n]*)", preceding)
        description = comment_matches[-1].strip() if comment_matches else ""

        data["_id"]          = preset_id
        data["_description"] = description
        data["_source"]      = Path(path).name
        presets[preset_id]   = data

    print(f"  Parsed {len(presets)} presets from {Path(path).name}")
    return presets


# ═══════════════════════════════════════════════════════════════════════
# DATA BUILDING
# ═══════════════════════════════════════════════════════════════════════

def lua_color_to_hex(color):
    """Convert {r=0.37, g=1.00, b=0.27} dict to '#rrggbb'."""
    if not isinstance(color, dict):
        return None
    r = int(min(color.get("r", 1.0), 1.0) * 255)
    g = int(min(color.get("g", 1.0), 1.0) * 255)
    b = int(min(color.get("b", 1.0), 1.0) * 255)
    return f"#{r:02x}{g:02x}{b:02x}"


def infer_group(preset_id, source=""):
    if source.startswith("SWH_"):
        return "swh"
    for prefix, gid in GROUP_RULES:
        if preset_id == prefix or preset_id.startswith(prefix):
            return gid
    return "other"


def get_freq_key(preset_id):
    for sv in SANDBOX_FREQ_VARS:
        if preset_id in sv["affectsIDs"]:
            return sv["key"]
    return None


def parse_random_selection(raw):
    """Parse presetRandomSelection array into [{id, weight}]."""
    if isinstance(raw, dict):
        # Mixed table: collect numeric-keyed entries in order
        raw = [raw[k] for k in sorted(raw.keys(), key=lambda x: int(x) if str(x).isdigit() else 9999)]
    if not isinstance(raw, list):
        return []
    result = []
    i = 0
    while i < len(raw):
        if isinstance(raw[i], str):
            pid = raw[i]
            weight = 1
            if i + 1 < len(raw) and isinstance(raw[i + 1], (int, float)):
                weight = int(raw[i + 1])
                i += 1
            result.append({"id": pid, "weight": weight})
        i += 1
    return result


def parse_progression(raw):
    """Parse presetProgression dict into sorted [{id, factor}]."""
    if not isinstance(raw, dict):
        return []
    items = []
    for pid, factor in raw.items():
        if isinstance(factor, (int, float)):
            items.append({"id": pid, "factor": float(factor)})
    items.sort(key=lambda x: x["factor"])
    return items


def interpolate_color(hex_start, hex_end, t):
    """Interpolate between two hex colors, t in [0,1]."""
    def hx(h):
        h = h.lstrip("#")
        return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))
    r1, g1, b1 = hx(hex_start)
    r2, g2, b2 = hx(hex_end)
    r = int(r1 + (r2 - r1) * t)
    g = int(g1 + (g2 - g1) * t)
    b = int(b1 + (b2 - b1) * t)
    return f"#{r:02x}{g:02x}{b:02x}"


def build_preset_entry(pid, data, all_presets, group_color):
    """Build a single preset dict for the JS data structure."""
    f   = lambda key, default=None: data.get(key, DEFAULTS.get(key, default))

    start_factor  = float(f("eventStartDayFactor",  0))
    cutoff_factor = float(f("eventCutOffDayFactor",  0.34))
    spawn_weight  = int(f("eventSpawnWeight",         10))
    sched_factor  = float(f("schedulingFactor",        1))
    ignore_cont   = bool(f("ignoreContinueScheduling", False))
    for_sched     = bool(f("forScheduling",            False))
    marker_color  = f("markerColor")
    flight_hours  = f("flightHours")
    description   = data.get("_description", "")

    color = lua_color_to_hex(marker_color) if isinstance(marker_color, dict) else group_color

    # Notes / warnings
    notes = []
    bug_notes = []

    # Check for schedulingFactor sentinel (one-time events)
    is_one_time = (sched_factor >= 99990)

    freq_key = get_freq_key(pid)
    freq_sv = next((sv for sv in SANDBOX_FREQ_VARS if sv["key"] == freq_key), None) if freq_key else None
    if freq_sv and not freq_sv["hasMatch"]:
        notes.append(f"Frequency_{freq_key} sandbox var does not match preset ID '{pid}' — freq control may not apply.")

    # Build progression
    progression = None
    is_random   = False

    raw_prog = data.get("presetProgression")
    raw_rand = data.get("presetRandomSelection")

    if isinstance(raw_prog, dict) and raw_prog:
        items = parse_progression(raw_prog)

        # Detect duplicate keys via raw text — Lua silently drops earlier entries,
        # so our parser only sees the last value and factor collisions are invisible.
        # Scan the raw source text for repeated ["key"] = entries in this preset's block.
        src = data.get("_source", "")
        raw_src_text = _raw_source_texts.get(src, "")
        if raw_src_text:
            import re as _re
            # Find this preset's presetProgression block in the raw text
            pat = _re.compile(
                rf'eHelicopter_PRESETS\["{_re.escape(pid)}"\].*?presetProgression\s*=\s*\{{([^}}]+)\}}',
                _re.DOTALL
            )
            pm = pat.search(raw_src_text)
            if pm:
                block = pm.group(1)
                keys_found = _re.findall(r'\["([^"]+)"\]\s*=', block)
                seen_keys = {}
                for k in keys_found:
                    if k in seen_keys:
                        bug_notes.append(
                            f'Duplicate key in presetProgression: ["{k}"] '
                            f'appears twice — earlier entry (={seen_keys[k]}) silently overwritten'
                        )
                    else:
                        val_m = _re.search(rf'\["{_re.escape(k)}"\]\s*=\s*([^,\n}}]+)', block)
                        seen_keys[k] = val_m.group(1).strip() if val_m else "?"

        # Assign colors to each segment
        n = len(items)
        for idx, item in enumerate(items):
            child = all_presets.get(item["id"], {})
            child_color_raw = child.get("markerColor")
            if isinstance(child_color_raw, dict):
                item["color"] = lua_color_to_hex(child_color_raw)
            else:
                t = idx / max(n - 1, 1)
                item["color"] = interpolate_color(color, "#dd1010", t) if "military" in pid else \
                                 interpolate_color(color, "#2030a0", t)
            item["label"] = item["id"].replace("_", " ").title()
            item["note"]  = child.get("_description", "")

        progression = items

    elif isinstance(raw_rand, (list, dict)) and raw_rand:
        items = parse_random_selection(raw_rand)
        n = len(items)
        if n == 1:
            notes.append(f"presetRandomSelection has only one entry — always resolves to '{items[0]['id']}'.")
        for idx, item in enumerate(items):
            child = all_presets.get(item["id"], {})
            child_color_raw = child.get("markerColor")
            if isinstance(child_color_raw, dict):
                item["color"] = lua_color_to_hex(child_color_raw)
            else:
                t = idx / max(n - 1, 1)
                item["color"] = interpolate_color(color, "#404040", t)
            item["label"] = item["id"].replace("_", " ").title()
            item["note"]  = child.get("_description", "")
        progression = items
        is_random   = True

    entry = {
        "id":                     pid,
        "label":                  pid,
        "description":            description,
        "startFactor":            start_factor,
        "cutoffFactor":           cutoff_factor,
        "spawnWeight":            spawn_weight,
        "schedulingFactor":       sched_factor,
        "ignoreContinueScheduling": ignore_cont,
        "isOneTime":              is_one_time,
        "freqSandboxKey":         freq_key,
        "color":                  color,
        "source":                 data.get("_source", ""),
        "notes":                  notes,
        "bugNotes":               bug_notes,
        "isSub":                  False,
        "progression":            progression,
        "progressionIsRandom":    is_random,
    }

    if isinstance(flight_hours, list) and len(flight_hours) >= 2:
        entry["flightHours"] = [int(flight_hours[0]), int(flight_hours[1])]

    return entry


def build_groups(all_presets):
    """
    Take all parsed presets, filter to forScheduling=true,
    organize into groups, and build sub-variant rows.
    """
    schedulable = {
        pid: d for pid, d in all_presets.items()
        if d.get("forScheduling") is True
    }

    # Organize by group
    grouped = {}
    for pid, data in schedulable.items():
        gid = infer_group(pid, all_presets[pid].get("_source", ""))
        grouped.setdefault(gid, []).append(pid)

    # Determine group order
    seen_groups = []
    for _, gid in GROUP_RULES:
        if gid not in seen_groups:
            seen_groups.append(gid)
    for gid in grouped:
        if gid not in seen_groups:
            seen_groups.append(gid)

    groups = []
    # Compute hasMatch dynamically: True if the sandbox key == an actual preset ID
    all_preset_ids = set(all_presets.keys())
    for sv in SANDBOX_FREQ_VARS:
        sv["hasMatch"] = sv["key"] in all_preset_ids

    issues = []

    for gid in seen_groups:
        if gid not in grouped:
            continue

        meta  = GROUP_META.get(gid, {"label": gid.upper(), "color": "#808080"})
        pids  = grouped[gid]

        # Sort: parent presets first (no isSub), then subs
        # Heuristic: presets that appear in other presets' progressions/random are sub-presets
        all_parent_children = set()
        for pid in pids:
            d = all_presets[pid]
            rp = d.get("presetProgression")
            rr = d.get("presetRandomSelection")
            if isinstance(rp, dict):
                all_parent_children.update(rp.keys())
            items = parse_random_selection(rr) if isinstance(rr, (list, dict)) and rr else []
            all_parent_children.update(x["id"] for x in items)

        parents = [p for p in pids if p not in all_parent_children]
        subs    = [p for p in pids if p in all_parent_children]

        # Sort parents by start factor
        parents.sort(key=lambda p: float(all_presets[p].get("eventStartDayFactor", 0)))
        subs.sort(key=lambda p: float(all_presets[p].get("eventStartDayFactor", 0)))

        preset_rows = []
        for pid in parents + subs:
            entry = build_preset_entry(pid, all_presets[pid], all_presets, meta["color"])
            entry["isSub"] = pid in all_parent_children
            preset_rows.append(entry)

            # Collect issues
            for note in entry["bugNotes"]:
                issues.append({"type": "bug", "msg": f"{pid}: {note}"})
            for note in entry["notes"]:
                if "sandbox var does not match" in note:
                    issues.append({"type": "warn", "msg": f"{pid}: {note}"})

        groups.append({
            "id":      gid,
            "label":   meta["label"],
            "color":   meta["color"],
            "presets": preset_rows,
        })

    return groups, issues


# ═══════════════════════════════════════════════════════════════════════
# HTML TEMPLATE
# ═══════════════════════════════════════════════════════════════════════

HTML_TEMPLATE = r"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>EHE Timeline Visualizer · B42</title>
<style>
@import url('https://fonts.googleapis.com/css2?family=Share+Tech+Mono&family=Barlow+Condensed:wght@300;400;500;600;700&family=Barlow:wght@300;400;500&display=swap');
:root {
  --bg:#0b0c10;--bg2:#12141a;--bg3:#1a1d25;--panel:#161820;--border:#2a2d3a;
  --border2:#3a3e50;--text:#cdd2e0;--text-dim:#6a7090;--text-muted:#45485a;
  --accent:#4fa3e0;--accent2:#3e8ac4;--warn:#e0a030;--danger:#e04040;
  --mono:'Share Tech Mono',monospace;--sans:'Barlow Condensed',sans-serif;
  --body:'Barlow',sans-serif;--row-h:30px;--label-w:230px;
}
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0;}
body{background:var(--bg);color:var(--text);font-family:var(--body);font-size:13px;
  display:flex;flex-direction:column;height:100vh;overflow:hidden;}
header{background:var(--panel);border-bottom:1px solid var(--border);padding:10px 18px;
  display:flex;align-items:center;gap:14px;flex-shrink:0;}
header h1{font-family:var(--sans);font-weight:700;font-size:20px;letter-spacing:.04em;
  text-transform:uppercase;color:var(--accent);white-space:nowrap;}
.badge{font-family:var(--mono);font-size:10px;background:var(--bg3);border:1px solid var(--border2);
  color:var(--text-dim);padding:2px 7px;border-radius:3px;letter-spacing:.05em;white-space:nowrap;}
.badge.warn{border-color:var(--warn);color:var(--warn);}
header .spacer{flex:1;}
.app-body{display:flex;flex:1;overflow:hidden;}
#sidebar{width:264px;min-width:264px;background:var(--panel);border-right:1px solid var(--border);
  overflow-y:auto;display:flex;flex-direction:column;}
.cs{border-bottom:1px solid var(--border);padding:12px 14px;}
.cs-title{font-family:var(--sans);font-size:11px;font-weight:600;letter-spacing:.1em;
  text-transform:uppercase;color:var(--text-dim);margin-bottom:9px;}
.cr{display:flex;align-items:center;gap:8px;margin-bottom:7px;}
.cr:last-child{margin-bottom:0;}
.cl{font-size:12px;color:var(--text);min-width:115px;flex-shrink:0;}
.cv{font-family:var(--mono);font-size:11px;color:var(--accent);min-width:34px;text-align:right;}
input[type=range]{-webkit-appearance:none;flex:1;height:4px;background:var(--border2);
  border-radius:2px;outline:none;cursor:pointer;}
input[type=range]::-webkit-slider-thumb{-webkit-appearance:none;width:13px;height:13px;
  border-radius:50%;background:var(--accent);cursor:pointer;border:2px solid var(--bg);}
select{background:var(--bg3);border:1px solid var(--border2);color:var(--text);
  font-family:var(--body);font-size:11px;padding:3px 6px;border-radius:3px;cursor:pointer;flex:1;}
.tr{display:flex;align-items:center;gap:8px;margin-bottom:6px;}
.tr label{font-size:12px;cursor:pointer;user-select:none;}
input[type=checkbox]{accent-color:var(--accent);width:13px;height:13px;cursor:pointer;}
.frow{display:flex;align-items:center;gap:6px;margin-bottom:5px;}
.frow:last-child{margin-bottom:0;}
.fdot{width:8px;height:8px;border-radius:50%;flex-shrink:0;}
.flbl{font-size:11px;flex:1;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;}
.fwarn{font-size:9px;color:var(--warn);font-family:var(--mono);flex-shrink:0;}
.li{display:flex;align-items:center;gap:7px;margin-bottom:5px;font-size:11px;color:var(--text-dim);}
.ls{width:20px;height:8px;border-radius:2px;flex-shrink:0;}
#main{flex:1;overflow:auto;display:flex;flex-direction:column;}
.tl-top{position:sticky;top:0;z-index:50;background:var(--bg);border-bottom:1px solid var(--border);
  display:flex;align-items:stretch;}
.tl-lh{width:var(--label-w);min-width:var(--label-w);flex-shrink:0;background:var(--bg2);
  border-right:1px solid var(--border);display:flex;align-items:center;padding:0 10px;height:36px;}
.tl-lh span{font-family:var(--sans);font-size:10px;letter-spacing:.08em;text-transform:uppercase;color:var(--text-muted);}
.tl-aw{flex:1;position:relative;height:36px;overflow:hidden;}
#axis-canvas{position:absolute;top:0;left:0;width:100%;height:100%;}
.tl-body{display:flex;flex-direction:column;flex:1;}
.gh{display:flex;align-items:center;background:var(--bg3);border-bottom:1px solid var(--border);
  cursor:pointer;user-select:none;position:sticky;top:36px;z-index:40;}
.gh:hover{background:#1e2130;}
.ghl{width:var(--label-w);min-width:var(--label-w);font-family:var(--sans);font-size:11px;
  font-weight:600;letter-spacing:.08em;text-transform:uppercase;padding:6px 10px;color:var(--text-dim);
  border-right:1px solid var(--border);display:flex;align-items:center;gap:6px;}
.gt{font-size:9px;transition:transform .15s;}
.gh.collapsed .gt{transform:rotate(-90deg);}
.ght{flex:1;height:28px;position:relative;overflow:hidden;}
.preset-row{display:flex;align-items:stretch;border-bottom:1px solid var(--border);min-height:var(--row-h);}
.preset-row:hover{background:rgba(255,255,255,.015);}
.preset-row.sub .rl{padding-left:22px;}
.rl{width:var(--label-w);min-width:var(--label-w);border-right:1px solid var(--border);
  padding:0 8px;display:flex;align-items:center;gap:5px;background:var(--bg2);cursor:default;flex-shrink:0;}
.rid{font-family:var(--mono);font-size:10px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;color:var(--text);}
.rbadge{font-size:8px;font-family:var(--sans);letter-spacing:.05em;padding:1px 4px;border-radius:2px;
  background:var(--bg3);border:1px solid var(--border2);color:var(--text-muted);white-space:nowrap;flex-shrink:0;}
.rbadge.rw{border-color:var(--warn);color:var(--warn);}
.rbadge.rs{border-color:var(--accent);color:var(--accent);}
.rt{flex:1;position:relative;min-height:var(--row-h);}
.eb{position:absolute;top:5px;height:calc(var(--row-h) - 10px);border-radius:3px;cursor:pointer;
  transition:filter .12s;overflow:hidden;display:flex;}
.eb:hover{filter:brightness(1.3);z-index:10;}
.eb.off{opacity:.1;pointer-events:none;}
.ps{height:100%;border-right:1px solid rgba(0,0,0,.3);flex-shrink:0;cursor:pointer;position:absolute;top:0;}
.ps:last-child{border-right:none;}
.ps:hover{filter:brightness(1.15);}
#tooltip{display:none;position:fixed;background:var(--bg2);border:1px solid var(--border2);
  border-left:3px solid var(--accent);padding:10px 13px;border-radius:4px;max-width:320px;min-width:220px;
  pointer-events:none;z-index:9999;box-shadow:0 8px 24px rgba(0,0,0,.6);font-size:12px;line-height:1.5;}
.tt-id{font-family:var(--mono);font-size:11px;color:var(--accent);margin-bottom:5px;}
.tt-r{display:flex;gap:8px;margin-bottom:3px;}
.tt-k{color:var(--text-dim);min-width:90px;flex-shrink:0;font-size:11px;}
.tt-v{color:var(--text);font-family:var(--mono);font-size:11px;}
.tt-hr{border:none;border-top:1px solid var(--border);margin:5px 0;}
.tt-w{color:var(--warn);font-size:10px;margin-top:3px;}
.tt-n{color:var(--text-dim);font-size:10px;margin-top:3px;font-style:italic;}
#issues{border-top:1px solid var(--border);background:var(--panel);padding:5px 14px;
  display:flex;align-items:center;gap:12px;font-size:11px;flex-shrink:0;flex-wrap:wrap;min-height:28px;}
.it{display:flex;align-items:center;gap:5px;}
::-webkit-scrollbar{width:6px;height:6px;}
::-webkit-scrollbar-track{background:var(--bg);}
::-webkit-scrollbar-thumb{background:var(--border2);border-radius:3px;}
::-webkit-scrollbar-thumb:hover{background:var(--accent2);}
.src-tag{font-size:9px;font-family:var(--mono);color:var(--text-muted);flex-shrink:0;}
.sim-count{
  position:absolute;right:4px;top:50%;transform:translateY(-50%);
  font-family:var(--mono);font-size:10px;font-weight:700;
  padding:1px 5px;border-radius:3px;pointer-events:none;
  background:rgba(0,0,0,.55);z-index:5;white-space:nowrap;letter-spacing:.03em;
}
.gh-count{
  font-family:var(--mono);font-size:10px;font-weight:700;
  padding:1px 6px;border-radius:3px;background:rgba(0,0,0,.4);
  margin-left:auto;margin-right:8px;white-space:nowrap;flex-shrink:0;
}
.sim-note{font-size:10px;color:var(--text-muted);margin-top:6px;line-height:1.5;}
</style>
</head>
<body>
<header>
  <h1>EHE Timeline Visualizer</h1>
  <span class="badge">B42.16+</span>
  <span class="badge" id="hdr-dur">SchedulerDuration: 90d</span>
  <span class="badge warn" id="hdr-issues" style="display:none"></span>
  <div class="spacer"></div>
  <span style="font-size:11px;color:var(--text-muted);font-family:var(--mono);" id="hdr-total"></span>
</header>
<div class="app-body">
<div id="sidebar">
  <div class="cs">
    <div class="cs-title">Sandbox Settings</div>
    <div class="cr"><span class="cl">Scheduler Duration</span>
      <input type="range" id="c-dur" min="10" max="365" value="90" step="5">
      <span class="cv" id="v-dur">90d</span></div>
    <div class="cr"><span class="cl">Start Day Offset</span>
      <input type="range" id="c-sd" min="0" max="50" value="0" step="1">
      <span class="cv" id="v-sd">0d</span></div>
    <div class="tr" style="margin-top:6px;">
      <input type="checkbox" id="c-cont" checked>
      <label for="c-cont">Continue Scheduling (post-cutoff)</label></div>
    <div class="tr">
      <input type="checkbox" id="c-air" checked>
      <label for="c-air">Air Raid Siren Event enabled</label></div>
  </div>
  <div class="cs">
    <div class="cs-title">Event Frequency</div>
    <div style="font-size:10px;color:var(--text-muted);margin-bottom:8px;">
      Sandbox key → preset ID mapping. <span style="color:var(--warn);">⚠ = key mismatch.</span>
    </div>
    <div id="freq-ctrls"></div>
  </div>
  <div class="cs">
    <div class="cs-title">Display</div>
    <div class="tr"><input type="checkbox" id="o-dens" checked><label for="o-dens">Probability density</label></div>
    <div class="tr"><input type="checkbox" id="o-prog" checked><label for="o-prog">Progression segments</label></div>
    <div class="tr"><input type="checkbox" id="o-cont"><label for="o-cont">Continue-schedule zone</label></div>
    <div class="tr"><input type="checkbox" id="o-sub" checked><label for="o-sub">Sub-variants</label></div>
    <div class="tr"><input type="checkbox" id="o-sim" checked><label for="o-sim">Show event counts</label></div>
  </div>
  <div class="cs">
    <div class="cs-title">Simulation</div>
    <div class="cr"><span class="cl">Runs (avg of)</span>
      <input type="range" id="c-runs" min="10" max="500" value="100" step="10">
      <span class="cv" id="v-runs">100</span></div>
    <div class="sim-note">
      Mirrors the Lua scheduler: 24 ticks/day (once per in-game hour),
      global weight=10, insane=10× events. Count = avg fired per playthrough.
    </div>
  </div>
  <div class="cs">
    <div class="cs-title">Legend</div>
    <div id="legend"></div>
    <div style="margin-top:8px;font-size:10px;color:var(--text-muted);line-height:1.7;">
      <div>Bar = eligible spawn window</div>
      <div>Segments = active progression stage</div>
      <div style="color:var(--accent);">│ Blue line = SchedulerDuration end</div>
    </div>
  </div>
</div>
<div id="main">
  <div class="tl-top">
    <div class="tl-lh"><span>Preset ID</span></div>
    <div class="tl-aw"><canvas id="axis-canvas"></canvas></div>
  </div>
  <div class="tl-body" id="tl-body"></div>
</div>
</div>
<div id="issues"></div>
<div id="tooltip"></div>

<script>
// ── GENERATED DATA ────────────────────────────────────────────────────
/*PRESETS_DATA*/

// ── FREQ ENUM ─────────────────────────────────────────────────────────
const FREQ_ENUM = [
  {val:1,label:'Never',    fc:0 },
  {val:2,label:'Rarely',   fc:1 },
  {val:3,label:'Sometimes',fc:2 },
  {val:4,label:'Often',    fc:3 },
  {val:5,label:'Very Often',fc:4},
  {val:6,label:'Insane',   fc:50},
];

// ── STATE ─────────────────────────────────────────────────────────────
const S = {
  dur:90, startDay:0,
  cont:true, airRaid:true,
  freq:{}, density:true, prog:true, contBar:false, subs:true,
  showSim:true, simRuns:100,
};
// Initial counts from Lua simulation embedded at HTML build time.
let _simCache = EHE_DATA.initialSimCounts || {};
EHE_DATA.sandboxFreqVars.forEach(v=>{ S.freq[v.key]=3; });

// ── MATH ──────────────────────────────────────────────────────────────
function computeDays(sf,cf,dur,sd0){
  let sd=Math.floor(sf*dur+.5); sd=Math.max(sd,sd0);
  let cod=Math.floor(cf*(sd+dur)+.5);
  return {sd,cod};
}
function freqCalc(key,def=2){
  if(!key)return def;
  const v=S.freq[key]??3;
  if(v===1)return 0;
  const fc=v-1; return fc===5?50:fc;
}
function relProb(preset,day){
  const {sd,cod}=computeDays(preset.startFactor,preset.cutoffFactor,S.dur,S.startDay);
  if(day<sd||day>cod)return 0;
  const freq=freqCalc(preset.freqSandboxKey,2);
  if(freq===0)return 0;
  const sf=preset.schedulingFactor??1;
  const w=(preset.spawnWeight??10)*freq;
  const denom=(10-freq)*2500+1000*(day/S.dur);
  const num=Math.floor(freq*sf+.5);
  return w*num/Math.max(denom,1);
}
function maxProb(preset){
  const {sd,cod}=computeDays(preset.startFactor,preset.cutoffFactor,S.dur,S.startDay);
  if(sd>=cod)return .0001;
  let mx=0;
  for(let i=0;i<=20;i++){
    const d=sd+(cod-sd)*(i/20);
    mx=Math.max(mx,relProb(preset,d));
  }
  return mx||.0001;
}
const TIMELINE_PAD = 0.08; // 8% right padding so bars never touch the edge
function totalDays(){
  let mx=S.dur;
  for(const g of EHE_DATA.groups)for(const p of g.presets){
    const {cod}=computeDays(p.startFactor,p.cutoffFactor,S.dur,S.startDay);
    mx=Math.max(mx,cod);
  }
  return Math.ceil(mx*(1+TIMELINE_PAD));
}
function isActive(p){
  if(p.id==='air_raid'&&!S.airRaid)return false;
  return freqCalc(p.freqSandboxKey,2)>0;
}

// ── SIMULATION ────────────────────────────────────────────────────────
// Mirrors EHE_eventScheduler.lua: each day the scheduler builds a weighted
// pool of eligible preset IDs, then picks one at random to schedule.
// ZombRand(n) returns 0..n-1; the check is ZombRand(denom) <= numer.
function runSimulation(){
  const numRuns = S.simRuns;
  const counts  = {};

  // Build a lookup: presetId -> raw sandbox freq value (1-6)
  // Used to detect insane mode (rawFreq==6 → schedules 10 events per pick)
  const rawFreqOf = {};
  for(const group of EHE_DATA.groups)
    for(const p of group.presets)
      rawFreqOf[p.id] = p.freqSandboxKey ? (S.freq[p.freqSandboxKey] ?? 3) : 3;

  // Only top-level schedulable presets
  const schedulable = [];
  for(const group of EHE_DATA.groups)
    for(const preset of group.presets)
      if(!preset.isSub) schedulable.push(preset);

  // ── Key facts from EHE_eventScheduler.lua ─────────────────────────────
  // 1. eHeliEvent_OnHour fires on OnTick but only when the in-game hour
  //    changes → the scheduler runs ONCE PER IN-GAME HOUR = 24×/day.
  // 2. Weight uses eHelicopter.eventSpawnWeight (global default = 10),
  //    NOT the preset's own eventSpawnWeight field — that field is never
  //    read during pool-building.
  // 3. Insane (raw sandbox value == 6, fc = 50): denominator becomes
  //    (10-50)*2500 = -100000 (negative), which in practice means all
  //    slots always pass. Additionally, the selected preset is scheduled
  //    10 times instead of 1.
  const GLOBAL_WT = 10;  // eHelicopter.eventSpawnWeight

  for(let run=0; run<numRuns; run++){
    // 24 ticks per day (one per in-game hour)
    const totalTicks = Math.ceil(S.dur * 24);
    for(let tick=0; tick<totalTicks; tick++){
      const day = tick / 24;
      const options = [];

      for(const preset of schedulable){
        if(!isActive(preset)) continue;

        const {sd,cod}=computeDays(preset.startFactor,preset.cutoffFactor,S.dur,S.startDay);
        const dayInRange = day>=sd && day<=cod;
        const startValid = day>=sd;
        const notIgnore  = !preset.ignoreContinueScheduling;
        const contValid  = S.cont && notIgnore;

        const available = dayInRange || (startValid && contValid);
        if(!available) continue;

        const freq = freqCalc(preset.freqSandboxKey, 2);
        if(freq===0) continue;

        const sf = preset.schedulingFactor ?? 1;
        // (presetSettings.eventSpawnWeight or eHelicopter.eventSpawnWeight) * freq
        const wt = (preset.spawnWeight ?? GLOBAL_WT) * freq;

        if(freq >= 50){
          // Insane: negative denominator → all slots always pass
          for(let i=0; i<wt; i++) options.push(preset.id);
        } else {
          // denom grows over time, making events slightly less frequent later
          const denom = Math.max(1, (10-freq)*2500 + 1000*(day/Math.max(S.dur,1)));
          const numer = Math.floor(freq*sf + 0.5);
          for(let i=0; i<wt; i++){
            if(Math.floor(Math.random()*denom) <= numer) options.push(preset.id);
          }
        }
      }

      if(options.length>0){
        const picked = options[Math.floor(Math.random()*options.length)];
        // Insane mode schedules 10 events per selection instead of 1
        const isInsane = rawFreqOf[picked] === 6;
        counts[picked] = (counts[picked]||0) + (isInsane ? 10 : 1);
      }
    }
  }

  const avg = {};
  for(const [id,total] of Object.entries(counts)) avg[id] = total/numRuns;
  _simCache = avg;
  return avg;
}

function simCountColor(n){
  // colour-coded by expected events per playthrough
  if(n<=0)   return '#555';
  if(n<1)    return '#705030';
  if(n<5)    return '#a08020';
  if(n<15)   return '#70b030';
  if(n<40)   return '#40c060';
  return '#20d080';
}

// ── TOOLTIP ───────────────────────────────────────────────────────────
const TT=document.getElementById('tooltip');
function showTT(html,x,y,color){
  TT.innerHTML=html; TT.style.display='block';
  TT.style.borderLeftColor=color||'var(--accent)';
  let tx=x+16,ty=y-10;
  const r=TT.getBoundingClientRect();
  if(tx+r.width>window.innerWidth-10)tx=x-r.width-10;
  if(ty+r.height>window.innerHeight-10)ty=window.innerHeight-r.height-10;
  TT.style.left=tx+'px'; TT.style.top=ty+'px';
}
function hideTT(){TT.style.display='none';}

function ttHtml(preset,groupColor,seg){
  const {sd,cod}=computeDays(preset.startFactor,preset.cutoffFactor,S.dur,S.startDay);
  const simCount = _simCache[preset.id];
  const freq=freqCalc(preset.freqSandboxKey,2);
  const freqLbl=FREQ_ENUM.find(f=>f.fc===freq)?.label??`calc:${freq}`;
  let h=`<div class="tt-id">${seg?'↳ '+seg.id:preset.id}</div>`;
  if(simCount!=null)h+=`<div class="tt-r"><span class="tt-k">Avg events</span><span class="tt-v" style="color:${simCountColor(simCount)};">${simCount.toFixed(1)} per playthrough · ${S.simRuns} runs · 24 ticks/day</span></div>`;
  if(preset.description)h+=`<div style="color:var(--text-dim);font-size:11px;margin-bottom:5px;">${preset.description}</div>`;
  if(seg){
    const segDay=(seg.factor*cod).toFixed(1);
    h+=`<div class="tt-r"><span class="tt-k">Stage</span><span class="tt-v">${seg.label}</span></div>`;
    h+=`<div class="tt-r"><span class="tt-k">Active from</span><span class="tt-v">day ${segDay} (${(seg.factor*100).toFixed(2)}%)</span></div>`;
    if(seg.note)h+=`<div class="tt-n">ℹ ${seg.note}</div>`;
    h+='<hr class="tt-hr">';
  }
  h+=`<div class="tt-r"><span class="tt-k">Start Day</span><span class="tt-v">day ${sd} (×${preset.startFactor})</span></div>`;
  h+=`<div class="tt-r"><span class="tt-k">Cutoff Day</span><span class="tt-v">day ${cod} (×${preset.cutoffFactor})</span></div>`;
  h+=`<div class="tt-r"><span class="tt-k">Window</span><span class="tt-v">${cod-sd}d</span></div>`;
  h+=`<div class="tt-r"><span class="tt-k">SpawnWeight</span><span class="tt-v">${preset.spawnWeight}×freq</span></div>`;
  h+=`<div class="tt-r"><span class="tt-k">SchedFactor</span><span class="tt-v">${preset.schedulingFactor}</span></div>`;
  const sv=EHE_DATA.sandboxFreqVars.find(v=>v.key===preset.freqSandboxKey);
  if(preset.freqSandboxKey){
    const ok=sv&&sv.hasMatch?'✓':'⚠';
    h+=`<div class="tt-r"><span class="tt-k">Freq var</span><span class="tt-v">Frequency_${preset.freqSandboxKey} ${ok} (${freqLbl})</span></div>`;
  } else {
    h+=`<div class="tt-r"><span class="tt-k">Freq var</span><span class="tt-v" style="color:var(--text-muted)">none — default freq</span></div>`;
  }
  const fh=preset.flightHours;
  function fmtHour(h){ const w=h>24?h-24:h; return (w<10?'0':'')+w+':00'+(h>24?' (+1d)':''); }
  h+=`<div class="tt-r"><span class="tt-k">Flight hrs</span><span class="tt-v">${fh?fmtHour(fh[0])+' – '+fmtHour(fh[1]):'05:00 – 22:00 (default)'}</span></div>`;
  if(preset.source)h+=`<div class="tt-r"><span class="tt-k">Source</span><span class="tt-v">${preset.source}</span></div>`;
  if(preset.ignoreContinueScheduling)h+=`<div class="tt-w">⚠ ignoreContinueScheduling — will NOT continue past cutoff.</div>`;
  if(preset.isOneTime)h+=`<div class="tt-w">⚠ One-time event (schedulingFactor=${preset.schedulingFactor})</div>`;
  if(preset.progressionIsRandom&&preset.progression)h+=`<div class="tt-n">ℹ Random selection from ${preset.progression.length} variants.</div>`;
  for(const n of (preset.bugNotes||[]))h+=`<div class="tt-w">🐛 ${n}</div>`;
  for(const n of (preset.notes||[]))h+=`<div class="tt-n">📎 ${n}</div>`;
  return h;
}

// ── RENDER ────────────────────────────────────────────────────────────
function drawAxis(td){
  const cv=document.getElementById('axis-canvas');
  const p=cv.parentElement;
  cv.width=p.offsetWidth; cv.height=p.offsetHeight;
  const ctx=cv.getContext('2d');
  const W=cv.width,H=cv.height;
  ctx.clearRect(0,0,W,H);
  const ppd=W/td;
  let iv=1;
  for(const c of [1,2,5,10,15,20,25,30,50,60,90,100,180,365]){
    if(c*ppd>=45){iv=c;break;}
  }
  // scheduler end line
  const sx=(S.dur/td)*W;
  ctx.fillStyle='rgba(79,163,224,.45)';
  ctx.fillRect(sx-1,0,2,H);
  ctx.font='10px "Share Tech Mono"';
  ctx.fillStyle='rgba(79,163,224,.8)';
  ctx.textAlign='right';
  ctx.fillText(`d${S.dur}`,sx-3,12);
  ctx.textAlign='center';
  for(let d=0;d<=td;d+=iv){
    const x=(d/td)*W;
    const major=(d%(iv*5)===0);
    ctx.fillStyle=major?'#5a6080':'#3a3e55';
    ctx.fillRect(x,H-(major?10:5),1,major?10:5);
    if(major||ppd*iv>30){
      ctx.fillStyle='#6a7090';
      ctx.fillText(`d${d}`,x,H-12);
    }
  }
}

function bgStyle(td){
  const main=document.getElementById('main');
  const lw=parseInt(getComputedStyle(document.documentElement).getPropertyValue('--label-w'))||230;
  const pw=Math.max(main.offsetWidth-lw-2,100);
  const ppd=pw/td;
  const ip=Math.max(ppd*10,15);
  return `repeating-linear-gradient(90deg,transparent 0px,transparent ${ip-1}px,rgba(255,255,255,.025) ${ip-1}px,rgba(255,255,255,.025) ${ip}px)`;
}

function schedLine(td){
  const d=document.createElement('div');
  d.style.cssText=`position:absolute;top:0;left:${S.dur/td*100}%;width:2px;height:100%;background:rgba(79,163,224,.2);pointer-events:none;`;
  return d;
}

function buildBar(preset,group,td,track){
  const {sd,cod}=computeDays(preset.startFactor,preset.cutoffFactor,S.dur,S.startDay);
  const active=isActive(preset);
  if(cod<=sd)return;
  const lp=(sd/td)*100, wp=((cod-sd)/td)*100;
  const bar=document.createElement('div');
  bar.className='eb'+(active?'':' off');
  bar.style.left=lp+'%';
  bar.style.width=Math.max(wp,.1)+'%';
  bar.style.background=group.color+'55';
  bar.style.border=`1px solid ${group.color}88`;

  if(S.prog&&preset.progression&&!preset.progressionIsRandom){
    const segs=preset.progression;
    segs.forEach((seg,i)=>{
      const nextF=i<segs.length-1?segs[i+1].factor:1;
      const segSD=seg.factor*cod, segED=nextF*cod;
      const dur2=cod-sd;
      const sl=dur2>0?((segSD-sd)/dur2)*100:0;
      const sw=dur2>0?((segED-segSD)/dur2)*100:.2;
      const el=document.createElement('div');
      el.className='ps';
      el.style.cssText=`left:${sl}%;width:${Math.max(sw,.15)}%;background:${seg.color};`;
      el.addEventListener('mousemove',e=>{e.stopPropagation();showTT(ttHtml(preset,group.color,seg),e.clientX,e.clientY,seg.color);});
      el.addEventListener('mouseleave',hideTT);
      bar.appendChild(el);
    });
  } else if(S.prog&&preset.progression&&preset.progressionIsRandom){
    const segs=preset.progression;
    const n=segs.length;
    segs.forEach((seg,i)=>{
      const el=document.createElement('div');
      el.className='ps';
      el.style.cssText=`left:${(i/n)*100}%;width:${100/n}%;background:${seg.color};opacity:.9;`;
      el.addEventListener('mousemove',e=>{e.stopPropagation();showTT(ttHtml(preset,group.color,seg),e.clientX,e.clientY,seg.color);});
      el.addEventListener('mouseleave',hideTT);
      bar.appendChild(el);
    });
  } else {
    bar.style.background=group.color+'aa';
  }

  // density canvas
  if(S.density&&active){
    const cv=document.createElement('canvas');
    cv.width=200;cv.height=1;
    const ctx=cv.getContext('2d');
    const mx=maxProb(preset);
    for(let i=0;i<200;i++){
      const d=sd+(cod-sd)*(i/200);
      const norm=Math.min(relProb(preset,d)/mx,1);
      ctx.fillStyle=`rgba(255,255,255,${norm})`;
      ctx.fillRect(i,0,1,1);
    }
    cv.style.cssText='position:absolute;top:0;left:0;right:0;bottom:0;width:100%;height:100%;image-rendering:pixelated;opacity:.35;mix-blend-mode:overlay;pointer-events:none;';
    bar.appendChild(cv);
  }

  // continue zone
  if(S.contBar&&S.cont&&!preset.ignoreContinueScheduling&&active){
    const cz=document.createElement('div');
    const cStart=cod/td*100;
    const cW=(S.dur*0.4/td)*100;
    cz.style.cssText=`position:absolute;top:5px;height:calc(100% - 10px);left:${cStart}%;width:${cW}%;border-radius:0 3px 3px 0;border:1px dashed ${group.color};opacity:.18;pointer-events:none;`;
    track.appendChild(cz);
  }

  bar.addEventListener('mousemove',e=>{
    if(e.target===bar)showTT(ttHtml(preset,group.color,null),e.clientX,e.clientY,group.color);
  });
  bar.addEventListener('mouseleave',hideTT);

  // Event count badge
  if(S.showSim && active){
    const n = _simCache[preset.id];
    const badge = document.createElement('div');
    badge.className = 'sim-count';
    const display = n==null ? '…' : n<0.1 ? '~0' : n.toFixed(1);
    badge.textContent = display;
    badge.style.color = n==null ? 'var(--text-muted)' : simCountColor(n);
    bar.appendChild(badge);
  }

  track.appendChild(bar);
}

function render(){
  // Re-run the Monte Carlo simulation whenever settings change
  if(S.showSim) runSimulation();

  const td=totalDays();
  const bg=bgStyle(td);

  document.getElementById('hdr-dur').textContent=`SchedulerDuration: ${S.dur}d`;
  document.getElementById('hdr-total').textContent=`Timeline: ${td}d`;

  const body=document.getElementById('tl-body');
  body.innerHTML='';
  drawAxis(td);

  for(const group of EHE_DATA.groups){
    const gh=document.createElement('div');
    gh.className='gh';
    gh.dataset.gid=group.id;

    const ghl=document.createElement('div');
    ghl.className='ghl';
    ghl.style.color=group.color;
    const gt=document.createElement('span');
    gt.className='gt'; gt.textContent='▼';
    ghl.appendChild(gt);
    ghl.appendChild(document.createTextNode(' '+group.label));
    // Group total badge
    if(S.showSim){
      const groupTotal = group.presets
        .filter(p=>!p.isSub)
        .reduce((s,p)=>s+(_simCache[p.id]??0), 0);
      const gb = document.createElement('span');
      gb.className='gh-count';
      gb.textContent = groupTotal<0.1 ? '~0 events' : groupTotal.toFixed(1)+' events';
      gb.style.color = simCountColor(groupTotal/Math.max(group.presets.filter(p=>!p.isSub).length,1));
      ghl.appendChild(gb);
    }
    gh.appendChild(ghl);

    const ght=document.createElement('div');
    ght.className='ght';
    ght.style.background=bg;

    // Summary bar
    const tops=group.presets.filter(p=>!p.isSub);
    if(tops.length){
      const mns=Math.min(...tops.map(p=>computeDays(p.startFactor,p.cutoffFactor,S.dur,S.startDay).sd));
      const mxc=Math.max(...tops.map(p=>computeDays(p.startFactor,p.cutoffFactor,S.dur,S.startDay).cod));
      const sb=document.createElement('div');
      sb.style.cssText=`position:absolute;top:6px;height:16px;border-radius:2px;opacity:.35;background:${group.color};left:${mns/td*100}%;width:${(mxc-mns)/td*100}%;`;
      ght.appendChild(sb);
    }
    ght.appendChild(schedLine(td));
    gh.appendChild(ght);
    body.appendChild(gh);

    const rc=document.createElement('div');
    rc.dataset.grows=group.id;
    gh.addEventListener('click',()=>{
      const c=gh.classList.toggle('collapsed');
      rc.style.display=c?'none':'';
    });

    for(const preset of group.presets){
      if(preset.isSub&&!S.subs)continue;
      const row=document.createElement('div');
      row.className='preset-row'+(preset.isSub?' sub':'');

      const rl=document.createElement('div');
      rl.className='rl';
      const rid=document.createElement('span');
      rid.className='rid'; rid.title=preset.id; rid.textContent=preset.id;
      rl.appendChild(rid);
      if(preset.source&&preset.source!==EHE_DATA.groups[0]?.presets[0]?.source){
        const st=document.createElement('span');
        st.className='src-tag'; st.textContent=preset.source.replace('.lua','');
        rl.appendChild(st);
      }
      if(preset.isOneTime){
        const b=document.createElement('span');b.className='rbadge rs';b.textContent='1×';rl.appendChild(b);
      }
      if(preset.ignoreContinueScheduling){
        const b=document.createElement('span');b.className='rbadge rw';b.textContent='no-cont';rl.appendChild(b);
      }
      const sv=EHE_DATA.sandboxFreqVars.find(v=>v.key===preset.freqSandboxKey);
      if(sv&&!sv.hasMatch){
        const b=document.createElement('span');b.className='rbadge rw';b.textContent='⚠freq';rl.appendChild(b);
      }
      row.appendChild(rl);

      const rt=document.createElement('div');
      rt.className='rt';
      rt.style.background=bg;
      rt.appendChild(schedLine(td));
      buildBar(preset,group,td,rt);
      row.appendChild(rt);
      rc.appendChild(row);
    }
    body.appendChild(rc);
  }
}

// ── CONTROLS ──────────────────────────────────────────────────────────
function buildFreqCtrls(){
  const el=document.getElementById('freq-ctrls');
  el.innerHTML=EHE_DATA.sandboxFreqVars.map(sv=>{
    const groupColor=EHE_DATA.groups.find(g=>sv.affectsIDs.some(id=>g.presets.some(p=>p.id===id)))?.color||'#808080';
    const warnTag=!sv.hasMatch?`<span class="fwarn">⚠ ID mismatch</span>`:'';
    const noPreset=sv.affectsIDs.length===0?`<span class="fwarn">⚠ no preset</span>`:'';
    return `<div class="frow">
      <div class="fdot" style="background:${groupColor}"></div>
      <span class="flbl" title="${sv.affectsIDs.join(', ')}">${sv.label}</span>
      ${warnTag}${noPreset}
      <select id="f-${sv.key}" data-key="${sv.key}">
        ${FREQ_ENUM.map(f=>`<option value="${f.val}"${f.val===3?' selected':''}>${f.label}</option>`).join('')}
      </select></div>`;
  }).join('');
  el.querySelectorAll('select').forEach(s=>{
    s.addEventListener('change',()=>{ S.freq[s.dataset.key]=parseInt(s.value); render(); });
  });
}

function buildLegend(){
  const el=document.getElementById('legend');
  el.innerHTML=EHE_DATA.groups.map(g=>`
    <div class="li">
      <div class="ls" style="background:${g.color}aa;border:1px solid ${g.color}88;"></div>
      <span>${g.label}</span>
    </div>`).join('');
}

function buildIssues(){
  const el=document.getElementById('issues');
  const issues=EHE_DATA.issues;
  const warns=issues.filter(i=>i.type==='warn').length;
  const bugs=issues.filter(i=>i.type==='bug').length;
  const hdr=document.getElementById('hdr-issues');
  if(warns+bugs>0){
    hdr.style.display='';
    hdr.textContent=`${warns} ⚠  ${bugs} 🐛`;
  }
  el.innerHTML=`
    <span style="font-family:var(--sans);font-size:10px;letter-spacing:.08em;text-transform:uppercase;color:var(--text-muted);">QA Notes</span>
    ${issues.map(i=>`<span class="it" style="color:${i.type==='bug'?'var(--danger)':i.type==='warn'?'var(--warn)':'var(--text-dim)'};font-size:10px;font-family:var(--mono);">${i.msg}</span>`).join('')}
  `;
}

function wire(id,cb){const el=document.getElementById(id);if(el)el.addEventListener('input',cb);}
function wireChk(id,cb){const el=document.getElementById(id);if(el)el.addEventListener('change',cb);}

wire('c-dur', e=>{ S.dur=parseInt(e.target.value); document.getElementById('v-dur').textContent=S.dur+'d'; render(); });
wire('c-sd',  e=>{ S.startDay=parseInt(e.target.value); document.getElementById('v-sd').textContent=S.startDay+'d'; render(); });
wireChk('c-cont', e=>{ S.cont=e.target.checked; render(); });
wireChk('c-air',  e=>{ S.airRaid=e.target.checked; render(); });
wireChk('o-dens', e=>{ S.density=e.target.checked; render(); });
wireChk('o-prog', e=>{ S.prog=e.target.checked; render(); });
wireChk('o-cont', e=>{ S.contBar=e.target.checked; render(); });
wireChk('o-sub',  e=>{ S.subs=e.target.checked; render(); });
wireChk('o-sim',  e=>{ S.showSim=e.target.checked; render(); });
wire('c-runs', e=>{
  S.simRuns=parseInt(e.target.value);
  document.getElementById('v-runs').textContent=S.simRuns;
  render();
});

let rt; window.addEventListener('resize',()=>{ clearTimeout(rt); rt=setTimeout(render,120); });

buildFreqCtrls();
buildLegend();
buildIssues();
render();
</script>
</body>
</html>
"""


# ═══════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════

def main():
    parser = argparse.ArgumentParser(description="Generate EHE Timeline Visualizer HTML.")
    parser.add_argument(
        "--presets", nargs="*", metavar="FILE",
        help="Additional preset Lua files to include (relative to tools/ directory)."
    )
    parser.add_argument(
        "--out", default=str(OUTPUT_FILE), metavar="FILE",
        help="Output HTML path (default: tools/timeline.html)."
    )
    args = parser.parse_args()

    print("EHE Timeline Generator")
    print("=" * 40)

    if args.presets:
        # Explicit paths given — resolve relative to tools/
        paths = [(SCRIPT_DIR / p).resolve() for p in args.presets]
    else:
        paths = resolve_default_paths()

    if not paths:
        print("  [ERROR] No preset files found.")
        print("  Expected: Contents/mods/<mod>/<version>/media/lua/shared/EHE_presets.lua")
        sys.exit(1)

    all_presets = {}
    for abs_path in paths:
        print(f"Parsing: {abs_path}")
        parsed = parse_preset_file(abs_path)
        # Later files extend earlier ones (sub-mods add to the same table)
        all_presets.update(parsed)
        # Store raw text so build_preset_entry can do raw-text duplicate checks
        try:
            _raw_source_texts[abs_path.name] = abs_path.read_text(encoding="utf-8", errors="replace")
        except Exception:
            pass

    print(f"\nTotal presets parsed: {len(all_presets)}")
    schedulable = [pid for pid, d in all_presets.items() if d.get("forScheduling") is True]
    print(f"Schedulable (forScheduling=true): {len(schedulable)}")

    groups, issues = build_groups(all_presets)

    # Run Lua-based simulation for default sandbox settings
    initial_sim_counts = {}
    if _LUA_SIM_AVAILABLE:
        print("\nRunning Lua simulation for initial counts (100 runs)...")
        default_sandbox = {
            "SchedulerDuration": 90, "StartDay": 0,
            "ContinueSchedulingEvents": 2, "AirRaidSirenEvent": True,
            "Frequency_police": 3, "Frequency_deserters": 3,
        }
        try:
            raw = _lua_simulate(list(paths), default_sandbox, num_runs=100)
            initial_sim_counts = {k: round(v, 2) for k, v in raw.items()}
            total = sum(initial_sim_counts.values())
            print(f"  Done. Total avg events/playthrough: {total:.1f}")
        except Exception as e:
            print(f"  [WARN] Lua simulation failed: {e}")
    else:
        print("\n[INFO] simulate.py / lupa not available — HTML will use JS simulation only.")

    data = {
        "groups":          groups,
        "sandboxFreqVars": SANDBOX_FREQ_VARS,
        "issues":          issues,
        "initialSimCounts": initial_sim_counts,
    }

    data_js = "const EHE_DATA = " + json.dumps(data, indent=2) + ";"

    html_out = HTML_TEMPLATE.replace("/*PRESETS_DATA*/", data_js)

    out_path = Path(args.out)
    out_path.write_text(html_out, encoding="utf-8")
    print(f"\nOutput: {out_path.resolve()}")
    print("Open timeline.html in a browser to view.\n")

    # Summary of issues
    warns = [i for i in issues if i["type"] == "warn"]
    bugs  = [i for i in issues if i["type"] == "bug"]
    if warns or bugs:
        print(f"QA Notes: {len(warns)} warnings, {len(bugs)} bugs detected.")
        for i in bugs:
            print(f"  🐛 {i['msg']}")
        for i in warns[:5]:  # cap output
            print(f"  ⚠  {i['msg']}")
        if len(warns) > 5:
            print(f"  ... and {len(warns)-5} more (see timeline for full list)")


if __name__ == "__main__":
    main()
