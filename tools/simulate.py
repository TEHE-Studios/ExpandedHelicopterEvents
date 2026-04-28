#!/usr/bin/env python3
"""
EHE Scheduler Simulation — runs the actual Lua scheduling code via lupa.

Extracts fetchStartDayAndCutOffDay, eHeliEvent_determineContinuation, and
eHeliEvent_ScheduleNew from the real Lua files, stubs out PZ-specific APIs,
loads the parsed preset table, and runs the scheduler loop exactly as the
game does (24 ticks per day, one per in-game hour).

Usage:
    python simulate.py
    python simulate.py --duration 90 --runs 200
    python simulate.py --freq military=4 --freq deserters=5
    python simulate.py --presets path/to/EHE_presets.lua
"""

import re
import sys
import json
import argparse
import random
from pathlib import Path

def _ensure_lupa():
    try:
        from lupa import LuaRuntime  # noqa: F401
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
    except Exception as e:
        print(f"ERROR: Could not install lupa automatically: {e}")
        print("       Try manually: pip install lupa --break-system-packages")
        sys.exit(1)

_ensure_lupa()
from lupa import LuaRuntime

sys.path.insert(0, str(Path(__file__).parent))
from generate import parse_preset_file, resolve_default_paths, load_main_variable_defaults, load_sandbox_defaults

# ── Glob patterns for Lua server files ────────────────────────────────
SCRIPT_DIR = Path(__file__).parent
SERVER_GLOBS = [
    "../Contents/mods/*/*/media/lua/server/EHE_mainCore.lua",
    "../Contents/mods/*/*/media/lua/server/EHE_eventScheduler.lua",
]


def find_server_files():
    """Locate EHE_mainCore.lua and EHE_eventScheduler.lua."""
    found = {}
    for pattern in SERVER_GLOBS:
        for m in sorted(SCRIPT_DIR.glob(pattern)):
            name = m.name
            if name not in found:
                found[name] = m
    return found


def _lua_skip_over(text, pos):
    """
    From `pos`, skip one Lua token that should not be inspected for keywords:
    a string literal (short or long), a block comment, or a line comment.
    Returns new pos if something was skipped, else None.
    """
    n = len(text)

    # Line comment
    if text[pos:pos+2] == '--':
        # Check for block comment  --[=*[
        bracket = re.match(r'--\[(?P<eq>=*)\[', text[pos:])
        if bracket:
            level = len(bracket.group('eq'))
            close = f']{" =" * level}]'.replace(' =', '=')  # ]=*]
            close = ']' + '=' * level + ']'
            end = text.find(close, pos + len(bracket.group(0)))
            return (end + len(close)) if end >= 0 else n
        else:
            end = text.find('\n', pos)
            return (end + 1) if end >= 0 else n

    # Long string  [=*[...]=*]
    ls = re.match(r'\[(?P<eq>=*)\[', text[pos:])
    if ls:
        level = len(ls.group('eq'))
        close = ']' + '=' * level + ']'
        end = text.find(close, pos + len(ls.group(0)))
        return (end + len(close)) if end >= 0 else n

    # Short string
    if text[pos] in ('"', "'"):
        q = text[pos]
        j = pos + 1
        while j < n:
            if text[j] == '\\':
                j += 2
                continue
            if text[j] == q:
                return j + 1
            j += 1
        return n

    return None


def extract_function(lua_text, func_name):
    """
    Pull a top-level function out of Lua source.
    Handles nested function bodies by counting function/end tokens,
    correctly skipping string literals and block comments so keywords
    inside them don't corrupt the depth counter.
    """
    header_pat = re.compile(
        rf'^function\s+{re.escape(func_name)}\s*\(',
        re.MULTILINE
    )
    m = header_pat.search(lua_text)
    if not m:
        return None

    start = m.start()
    pos   = m.end()
    depth = 1

    text = lua_text
    n    = len(text)

    while pos < n and depth > 0:
        skipped = _lua_skip_over(text, pos)
        if skipped is not None:
            pos = skipped
            continue

        kw_m = re.match(r'\b(function|do|if|repeat|then|else|elseif|end|until)\b', text[pos:])
        if kw_m:
            kw = kw_m.group(1)
            if kw in ('function', 'do', 'if', 'repeat'):
                depth += 1
            elif kw in ('end', 'until'):
                depth -= 1
            pos += kw_m.end()
        else:
            pos += 1

    return text[start:pos].strip()


def lua_error_context(lua_source, error_msg, context=5):
    """
    Parse a Lua error like '[string "<python>"]:104: ...' and print
    the lines around the offending line to aid debugging.
    """
    m = re.search(r':(\d+):', error_msg)
    if not m:
        return
    line_no = int(m.group(1))
    lines = lua_source.splitlines()
    lo = max(0, line_no - context - 1)
    hi = min(len(lines), line_no + context)
    print(f"\n  Lua source around line {line_no}:")
    for i, ln in enumerate(lines[lo:hi], start=lo + 1):
        marker = ">>>" if i == line_no else "   "
        print(f"  {marker} {i:4d}  {ln}")
    print()


def _to_lua_val(v):
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, str):
        escaped = v.replace("\\", "\\\\").replace('"', '\\"')
        return f'"{escaped}"'
    if isinstance(v, list):
        return "{" + ", ".join(_to_lua_val(x) for x in v) + "}"
    if isinstance(v, dict):
        pairs = ", ".join(f"{k}={_to_lua_val(vv)}" for k, vv in v.items())
        return "{" + pairs + "}"
    if isinstance(v, float):
        return repr(v)
    return str(v)


def build_lua_environment(all_presets, sandbox, heli_defaults):
    """
    Construct the full Lua source that the simulation will execute.
    Includes:
      - PZ API stubs (ZombRand, SandboxVars, getGameTime, etc.)
      - eHelicopter global built from heli_defaults (read from EHE_mainVariables.lua)
      - eHelicopter_PRESETS table populated from parsed Python data
      - The actual scheduler functions extracted from Lua files
      - A simulation runner that records counts
    """

    # ── Preset table ──────────────────────────────────────────────────
    preset_lines = ["eHelicopter_PRESETS = {}"]
    for pid, data in all_presets.items():
        if not data.get("forScheduling"):
            continue
        sf  = data.get("schedulingFactor",    heli_defaults.get("schedulingFactor",    1))
        sw  = data.get("eventSpawnWeight",     heli_defaults.get("eventSpawnWeight",    10))
        sdf = data.get("eventStartDayFactor",  heli_defaults.get("eventStartDayFactor", 0))
        cdf = data.get("eventCutOffDayFactor", heli_defaults.get("eventCutOffDayFactor", 0.34))
        ic  = "true" if data.get("ignoreContinueScheduling") else "false"
        preset_lines.append(
            f'eHelicopter_PRESETS["{pid}"] = {{'
            f' forScheduling=true,'
            f' schedulingFactor={_to_lua_val(sf)},'
            f' eventSpawnWeight={_to_lua_val(sw)},'
            f' eventStartDayFactor={_to_lua_val(sdf)},'
            f' eventCutOffDayFactor={_to_lua_val(cdf)},'
            f' ignoreContinueScheduling={ic}'
            f' }}'
        )
    presets_lua = "\n".join(preset_lines)

    # ── SandboxVars ───────────────────────────────────────────────────
    sv = sandbox
    freq_lines = []
    for k, v in sv.items():
        if k.startswith("Frequency_"):
            freq_lines.append(f'  ["{k}"] = {v},')

    continue_val = sv.get("ContinueSchedulingEvents", 1)
    air_raid     = "true" if sv.get("AirRaidSirenEvent", True) else "false"
    duration     = sv.get("SchedulerDuration", 90)
    start_day    = sv.get("StartDay", 0)

    # ── eHelicopter Lua table from runtime-loaded defaults ─────────────
    heli_field_lines = "\n".join(
        f"    {k} = {_to_lua_val(v)},"
        for k, v in heli_defaults.items()
    )
    if not heli_field_lines:
        heli_field_lines = "    schedulingFactor = 1, eventSpawnWeight = 10,"

    stubs = f"""
-- ── PZ API stubs ──────────────────────────────────────────────────────

math.randomseed(os.time())

-- ZombRand(n): returns integer in [0, n-1].
-- With negative n (insane mode denom), treat as always passing by returning 0.
function ZombRand(n)
    -- n may be a float (denom is computed with floats); floor it
    n = math.floor(n)
    -- n<=0 means insane-mode negative denominator → always pass (return 0)
    if not n or n <= 0 then return 0 end
    return math.random(0, n - 1)
end

-- Sandbox settings
SandboxVars = {{
    ExpandedHeli = {{
        SchedulerDuration = {duration},
        StartDay          = {start_day},
        ContinueSchedulingEvents = {continue_val},
        AirRaidSirenEvent = {air_raid},
        {chr(10).join(freq_lines)}
    }}
}}

-- eHelicopter global defaults (loaded at runtime from EHE_mainVariables.lua)
eHelicopter = {{
{heli_field_lines}
}}

-- Stub GameTime — covers every method called anywhere in the scheduler
local _vanillaHeliDay = 9999
function getGameTime()
    return {{
        getHour             = function(self) return 0 end,
        getMonth            = function(self) return 1 end,
        getDay              = function(self) return 1 end,
        getHelicopterDay    = function(self) return _vanillaHeliDay end,
        getHelicopterDay1   = function(self) return _vanillaHeliDay end,
        setHelicopterDay    = function(self, v) _vanillaHeliDay = v end,
        getHelicopterStartHour = function(self) return 0 end,
        setHelicopterStartHour = function(self, v) end,
        getHelicopterEndHour   = function(self) return 0 end,
        setHelicopterEndHour   = function(self, v) end,
    }}
end
function EHE_getWorldAgeDays() return 0 end
function triggerEvent(...) end
function isServer() return true end
function isClient() return false end
function getDebug() return false end
-- Events must be a table that absorbs any .X.Add(fn) access pattern
Events = setmetatable({{}}, {{
    __index = function(t, k)
        return setmetatable({{}}, {{
            __index = function(t2, k2) return function(...) end end
        }})
    end
}})

-- modData stub — plain table with Java HashMap-style proxy methods.
-- B42.16 scheduler code may call modData:get(key) / modData:put(key,val).
-- Colon calls desugar to modData.get(modData, key), so we check arg type
-- to distinguish colon (table first arg) from dot (string first arg) calls.
function _make_modData()
    local d = {{ DaysBeforeApoc=0, EventsOnSchedule={{}} }}
    setmetatable(d, {{ __index = function(t, k)
        if k == "get" then return function(self_or_key, key)
            if type(self_or_key) == "table" then return self_or_key[key]
            else return t[self_or_key] end
        end end
        if k == "put" then return function(self_or_key, key, val)
            if type(self_or_key) == "table" then self_or_key[key] = val
            else t[self_or_key] = key end
        end end
        if k == "containsKey" then return function(self_or_key, key)
            if type(self_or_key) == "table" then return self_or_key[key] ~= nil
            else return t[self_or_key] ~= nil end
        end end
    end }})
    return d
end
modData = _make_modData()
function getExpandedHeliEventsModData() return modData end

-- eHeliEvent_new stub — intercepts scheduling, records to count table
-- (defined after _counts is set up in the runner)
function eHeliEvent_new(startDay, startTime, preset)
    if _counts and preset then
        _counts[preset] = (_counts[preset] or 0) + 1
    end
    -- Also store in schedule for same-day dedup
    table.insert(modData.EventsOnSchedule, {{
        startDay = startDay, startTime = startTime,
        preset = preset, triggered = false
    }})
end

-- eHeliEvent_processSchedulerDates: special date gates — skipped in simulation
function eHeliEvent_processSchedulerDates(targetDate, expectedDates)
    return false  -- treat all special date gates as inactive
end

-- Preset table
{presets_lua}

-- eventsForScheduling module-level cache (reset each run)
eventsForScheduling = nil
"""

    return stubs


def sanitize_lua(code):
    # Lua 5.5 is strict about escape sequences.
    # \[ and \] appear in PZ print statements but are not valid Lua escapes.
    # They are silently accepted by older runtimes but error in Lua 5.5.
    return code.replace("\\[", "[").replace("\\]", "]")


def load_scheduler_functions(server_files):
    """
    Extract the three functions we need from the actual Lua source files.
    Falls back to embedded copies if the files aren't found.
    """
    funcs = {}

    mc_path = server_files.get("EHE_mainCore.lua")
    sc_path = server_files.get("EHE_eventScheduler.lua")

    if mc_path and mc_path.exists():
        text = mc_path.read_text(encoding="utf-8", errors="replace")
        f = extract_function(text, "fetchStartDayAndCutOffDay")
        if f:
            funcs["fetchStartDayAndCutOffDay"] = sanitize_lua(f)
            print(f"  Extracted fetchStartDayAndCutOffDay from {mc_path.name}")

    if sc_path and sc_path.exists():
        text = sc_path.read_text(encoding="utf-8", errors="replace")
        for name in ("eHeliEvent_determineContinuation",
                     "eHeliEvents_setEventsForScheduling",
                     "eHeliEvent_ScheduleNew"):
            f = extract_function(text, name)
            if f:
                funcs[name] = sanitize_lua(f)
                print(f"  Extracted {name} from {sc_path.name}")

    # ── Fallback embedded copies (from project source) ─────────────────
    if "fetchStartDayAndCutOffDay" not in funcs:
        print("  [fallback] fetchStartDayAndCutOffDay (embedded)")
        funcs["fetchStartDayAndCutOffDay"] = """
function fetchStartDayAndCutOffDay(HelicopterOrPreset)
    local startDayFactor = HelicopterOrPreset.eventStartDayFactor or eHelicopter.eventStartDayFactor
    local startDay = math.floor((startDayFactor*SandboxVars.ExpandedHeli.SchedulerDuration)+0.5)
    startDay = math.max(startDay, SandboxVars.ExpandedHeli.StartDay)
    local cutOffDayFactor = HelicopterOrPreset.eventCutOffDayFactor or eHelicopter.eventCutOffDayFactor
    local cutOffDay = math.floor((cutOffDayFactor*(startDay+SandboxVars.ExpandedHeli.SchedulerDuration))+0.5)
    return startDay, cutOffDay
end"""

    if "eHeliEvent_determineContinuation" not in funcs:
        print("  [fallback] eHeliEvent_determineContinuation (embedded)")
        funcs["eHeliEvent_determineContinuation"] = """
function eHeliEvent_determineContinuation()
    local continue = SandboxVars.ExpandedHeli.ContinueSchedulingEvents
    return continue>1, continue>=3
end"""

    if "eHeliEvents_setEventsForScheduling" not in funcs:
        print("  [fallback] eHeliEvents_setEventsForScheduling (embedded)")
        funcs["eHeliEvents_setEventsForScheduling"] = """
function eHeliEvents_setEventsForScheduling()
    if not eventsForScheduling then
        eventsForScheduling = {}
        for presetID,presetVars in pairs(eHelicopter_PRESETS) do
            local forScheduling = presetVars.forScheduling
            if forScheduling then
                if SandboxVars.ExpandedHeli.AirRaidSirenEvent==false and presetID=="air_raid" then
                    forScheduling = false
                end
                local freqKey = presetVars.frequencyKey or presetID
                local presetFreq = SandboxVars.ExpandedHeli["Frequency_"..freqKey]
                if presetFreq and presetFreq==1 then forScheduling = false end
            end
            if forScheduling then table.insert(eventsForScheduling, presetID) end
        end
    end
end"""

    if "eHeliEvent_ScheduleNew" not in funcs:
        print("  [fallback] eHeliEvent_ScheduleNew (embedded)")
        funcs["eHeliEvent_ScheduleNew"] = """
function eHeliEvent_ScheduleNew(currentDay, currentHour, freqOverride, noPrint)
    local continueScheduling, csLateGameOnly = eHeliEvent_determineContinuation()
    local globalModData = getExpandedHeliEventsModData()
    local daysIntoApoc = (globalModData.DaysBeforeApoc or 0) + currentDay
    local eventIDsScheduled = {}
    for k,v in pairs(globalModData.EventsOnSchedule) do
        if not v.triggered and v.startDay == currentDay then
            eventIDsScheduled[v.preset] = true
        end
    end
    local schedulerStartDay = SandboxVars.ExpandedHeli.StartDay or 0
    local schedulerDuration = SandboxVars.ExpandedHeli.SchedulerDuration or 90
    if (continueScheduling or (daysIntoApoc <= (schedulerStartDay+schedulerDuration)))
        and (daysIntoApoc >= schedulerStartDay) then
        local options = {}
        eHeliEvents_setEventsForScheduling()
        if #eventsForScheduling <= 0 then return end
        for k,presetID in pairs(eventsForScheduling) do
            local presetSettings = eHelicopter_PRESETS[presetID]
            if (not eventIDsScheduled[presetID]) and presetSettings and eHelicopter then
                local rawSF = presetSettings.schedulingFactor or eHelicopter.schedulingFactor
                local schedulingFactor = (type(rawSF)=="table") and rawSF[1] or rawSF
                local startDay, cutOffDay = fetchStartDayAndCutOffDay(presetSettings)
                local freqKey = presetSettings.frequencyKey or presetID
                local freq = 3
                local presetFreq = SandboxVars.ExpandedHeli["Frequency_"..freqKey]
                if presetFreq then
                    freq = presetFreq-1
                    if freq == 5 then freq = 50 end
                end
                freq = freqOverride or freq
                local probabilityDenominator = ((10-freq)*2500)
                probabilityDenominator = probabilityDenominator+(1000*(daysIntoApoc/schedulerDuration))
                local eventAvailable = false
                local dayInRange = ((daysIntoApoc >= startDay) and (daysIntoApoc <= cutOffDay))
                local startDayValid = daysIntoApoc >= startDay
                local notIgnore = not presetSettings.ignoreContinueScheduling
                local contScheduleValid = (continueScheduling==true and
                    ((not csLateGameOnly) or (csLateGameOnly and cutOffDay>=schedulerDuration)))
                if dayInRange then
                    eventAvailable = true
                elseif (startDayValid and notIgnore and contScheduleValid) then
                    eventAvailable = true
                end
                if eventAvailable then
                    local rawW = presetSettings.eventSpawnWeight or eHelicopter.eventSpawnWeight
                    local weight = (type(rawW)=="table") and rawW[1] or rawW
                    local probabilityNumerator = math.floor((freq*schedulingFactor) + 0.5)
                    for i=1, weight do
                        if (ZombRand(probabilityDenominator) <= probabilityNumerator) then
                            table.insert(options, presetID)
                        end
                    end
                end
            end
        end
        local selectedPresetID = options[ZombRand(#options)+1]
        if selectedPresetID and (selectedPresetID ~= false) then
            local selectedSettings = eHelicopter_PRESETS[selectedPresetID]
            local selectedFreqKey = (selectedSettings and selectedSettings.frequencyKey) or selectedPresetID
            local freq = SandboxVars.ExpandedHeli["Frequency_"..selectedFreqKey]
            local insane = (freqOverride or freq) == 6
            local iterations = insane and 10 or 1
            for i=1, iterations do
                local dayOffset = ({0,0,0,1,1,2,2})[ZombRand(7)+1]
                local nextStartDay = math.min(currentDay+dayOffset,
                    (fetchStartDayAndCutOffDay(eHelicopter_PRESETS[selectedPresetID])))
                eHeliEvent_new(nextStartDay, currentHour, selectedPresetID)
            end
        end
    end
end"""

    return funcs


def run_simulation(preset_paths, sandbox, num_runs=100, verbose=False):
    """
    Run the Lua simulation and return {presetID: avg_count_per_playthrough}.
    """
    duration = sandbox.get("SchedulerDuration", 90)

    all_presets = {}
    for p in preset_paths:
        all_presets.update(parse_preset_file(p))

    schedulable = {pid for pid, d in all_presets.items() if d.get("forScheduling")}
    if not schedulable:
        print("  No schedulable presets found.")
        return {}

    server_files = find_server_files()

    print(f"\nExtracting Lua functions...")
    funcs = load_scheduler_functions(server_files)

    heli_defaults = load_main_variable_defaults()
    if not heli_defaults:
        print("  [WARN] EHE_mainVariables.lua not found — eHelicopter defaults will be minimal.")

    env_lua = build_lua_environment(all_presets, sandbox, heli_defaults)
    func_lua = "\n\n".join(funcs[k] for k in [
        "fetchStartDayAndCutOffDay",
        "eHeliEvent_determineContinuation",
        "eHeliEvents_setEventsForScheduling",
        "eHeliEvent_ScheduleNew",
    ] if k in funcs)

    runner_lua = f"""
function run_one_playthrough()
    modData = _make_modData()
    eventsForScheduling = nil

    local counts = {{}}
    _counts = counts

    local total_ticks = math.ceil({duration} * 24)
    for tick = 0, total_ticks - 1 do
        local day  = math.floor(tick / 24)
        local hour = tick % 24

        if hour == 0 then
            local still_pending = {{}}
            for _, v in pairs(modData.EventsOnSchedule) do
                if v.startDay ~= day then
                    table.insert(still_pending, v)
                end
            end
            modData.EventsOnSchedule = still_pending
        end

        eHeliEvent_ScheduleNew(day, hour, nil, true)
    end

    return counts
end
"""

    full_lua = (
        env_lua
        + "\n\n" + func_lua
        # Re-assert the modData getter after extracted functions in case any
        # file-scope upvalue or B42 refactor shadowed/renamed it.
        + "\n\nfunction getExpandedHeliEventsModData() return modData end"
        + "\ngetEHEModData = getExpandedHeliEventsModData"
        + "\nEHE_getModData = getExpandedHeliEventsModData"
        + "\n\n" + runner_lua
    )

    # Set up Lua runtime
    lua = LuaRuntime(unpack_returned_tuples=False)
    try:
        lua.execute(full_lua)
    except Exception as e:
        print(f"  ERROR: Lua setup failed: {e}")
        lua_error_context(full_lua, str(e))
        raise

    # ── Pre-flight: run a quick smoke test with forced selections
    # before the real simulation to catch any remaining stub gaps cleanly.
    smoke_test_lua = """
function _smoke_test()
    modData = _make_modData()
    eventsForScheduling = nil
    _counts = {}
    local errors = {}
    for day=0, 10 do
        for hour=0, 23 do
            local ok, err = pcall(eHeliEvent_ScheduleNew, day, hour, 4, true)
            if not ok then
                local msg = tostring(err)
                local dup = false
                for _, e in ipairs(errors) do if e == msg then dup=true break end end
                if not dup then table.insert(errors, msg) end
            end
        end
    end
    return errors
end
"""
    lua.execute(smoke_test_lua)
    smoke_errors = lua.globals()._smoke_test()
    if smoke_errors and len(smoke_errors) > 0:
        msgs = [smoke_errors[k] for k in smoke_errors]
        raise RuntimeError(
            "Lua stub gaps detected during smoke test:\n" +
            "\n".join(f"  {m}" for m in msgs) +
            "\n\nPlease report this at the EHE issue tracker."
        )

    run_one = lua.globals().run_one_playthrough
    totals  = {}

    print(f"\nRunning {num_runs} simulations ({duration}d × 24 ticks/day = "
          f"{duration*24:,} ticks/run)...")

    for i in range(num_runs):
        if verbose and (i+1) % 10 == 0:
            print(f"  Run {i+1}/{num_runs}")
        result = run_one()
        # Convert Lua table to Python dict
        for k in result:
            v = result[k]
            totals[k] = totals.get(k, 0) + (v or 0)

    avg = {pid: totals.get(pid, 0) / num_runs for pid in schedulable}
    return avg


# ── CLI ────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Simulate the EHE scheduler using actual Lua functions."
    )
    parser.add_argument("--presets", nargs="*", metavar="FILE",
        help="Preset Lua files (default: auto-discover)")
    parser.add_argument("--duration", type=int, default=90, metavar="DAYS",
        help="SchedulerDuration sandbox setting (default: 90)")
    parser.add_argument("--start-day", type=int, default=0,
        help="StartDay sandbox setting (default: 0)")
    parser.add_argument("--runs", type=int, default=100, metavar="N",
        help="Number of simulated playthroughs (default: 100)")
    parser.add_argument("--no-continue", action="store_true",
        help="Disable ContinueSchedulingEvents (default: enabled)")
    parser.add_argument("--freq", nargs="*", metavar="KEY=VAL",
        help="Frequency overrides e.g. --freq military=4 police=2  (1=Never … 6=Insane)")
    parser.add_argument("--verbose", action="store_true")
    parser.add_argument("--json", action="store_true",
        help="Output results as JSON")
    args = parser.parse_args()

    # Resolve preset files
    if args.presets:
        paths = [Path(p).resolve() for p in args.presets]
    else:
        paths = resolve_default_paths()

    if not paths:
        print("ERROR: No preset files found.")
        sys.exit(1)

    print("EHE Scheduler Simulation (Lua)")
    print("=" * 44)
    for p in paths:
        print(f"  Preset file: {p}")

    # Build sandbox from sandbox-options.txt defaults, then apply CLI overrides
    sb = load_sandbox_defaults()
    sandbox = {k: v for k, v in sb.items() if k.startswith("Frequency_")}
    sandbox["SchedulerDuration"] = args.duration
    sandbox["StartDay"]          = args.start_day
    sandbox["AirRaidSirenEvent"] = sb.get("AirRaidSirenEvent", True)
    if args.no_continue:
        sandbox["ContinueSchedulingEvents"] = 1
    else:
        sandbox["ContinueSchedulingEvents"] = sb.get("ContinueSchedulingEvents", 1)
    if args.freq:
        for pair in args.freq:
            k, v = pair.split("=", 1)
            sandbox[f"Frequency_{k}"] = int(v)

    print(f"\nSandbox:")
    for k, v in sandbox.items():
        print(f"  {k} = {v}")

    # Run
    avg = run_simulation(paths, sandbox, num_runs=args.runs, verbose=args.verbose)

    # Output
    print(f"\nResults (avg events per {args.duration}-day playthrough, {args.runs} runs):")
    print("-" * 44)

    if args.json:
        print(json.dumps({k: round(v, 2) for k, v in sorted(avg.items())}, indent=2))
    else:
        # Sort by count descending
        for pid, count in sorted(avg.items(), key=lambda x: -x[1]):
            bar = "█" * min(int(count), 40)
            print(f"  {pid:<45} {count:6.2f}  {bar}")

    total = sum(avg.values())
    print(f"\n  Total avg events/playthrough: {total:.1f}")


if __name__ == "__main__":
    main()
