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


# ── Exact port of zombie.iso.weather.SimplexNoise (Java) ─────────────────────
# Only the 2D noise() variant is needed for weather generation.
_SN_P = [
    151,160,137,91,90,15,131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,
    8,99,37,240,21,10,23,190,6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,
    35,11,32,57,177,33,88,237,149,56,87,174,20,125,136,171,168,68,175,74,165,71,
    134,139,48,27,166,77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,
    55,46,245,40,244,102,143,54,65,25,63,161,1,216,80,73,209,76,132,187,208,89,18,
    169,200,196,135,130,116,188,159,86,164,100,109,198,173,186,3,64,52,217,226,250,
    124,123,5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,
    28,42,223,183,170,213,119,248,152,2,44,154,163,70,221,153,101,155,167,43,172,9,
    129,22,39,253,19,98,108,110,79,113,224,232,178,185,112,104,218,246,97,228,251,
    34,242,193,238,210,144,12,191,179,162,241,81,51,145,235,249,14,239,107,49,192,
    214,31,181,199,106,157,184,84,204,176,115,121,50,45,127,4,150,254,138,236,205,
    93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180,
]
_SN_PERM     = [_SN_P[i & 0xFF] for i in range(512)]
_SN_PERM12   = [v % 12 for v in _SN_PERM]
_SN_GRAD3 = [
    (1,1,0),(-1,1,0),(1,-1,0),(-1,-1,0),
    (1,0,1),(-1,0,1),(1,0,-1),(-1,0,-1),
    (0,1,1),(0,-1,1),(0,1,-1),(0,-1,-1),
]
_SN_F2 = 0.5 * (3.0 ** 0.5 - 1.0)
_SN_G2 = (3.0 - 3.0 ** 0.5) / 6.0


def _sn_fastfloor(x):
    xi = int(x)
    return xi - 1 if x < xi else xi


def simplex_noise_2d(xin, yin):
    """
    Exact Python port of SimplexNoise.noise(double xin, double yin) from Java.
    Returns a float in approximately [-1, 1].
    The offsets (xin, yin) map to the game's (simplexOffset, worldAgeHours/freqMod).
    """
    s  = (xin + yin) * _SN_F2
    i  = _sn_fastfloor(xin + s)
    j  = _sn_fastfloor(yin + s)
    t  = (i + j) * _SN_G2
    x0 = xin - (i - t)
    y0 = yin - (j - t)
    if x0 > y0:
        i1, j1 = 1, 0
    else:
        i1, j1 = 0, 1
    x1 = x0 - i1 + _SN_G2
    y1 = y0 - j1 + _SN_G2
    x2 = x0 - 1.0 + 2.0 * _SN_G2
    y2 = y0 - 1.0 + 2.0 * _SN_G2
    ii  = i & 0xFF
    jj  = j & 0xFF
    gi0 = _SN_PERM12[ii   + _SN_PERM[jj]]
    gi1 = _SN_PERM12[ii+i1+ _SN_PERM[jj+j1]]
    gi2 = _SN_PERM12[ii+1 + _SN_PERM[jj+1]]
    g0  = _SN_GRAD3[gi0]
    g1  = _SN_GRAD3[gi1]
    g2  = _SN_GRAD3[gi2]
    t0  = 0.5 - x0*x0 - y0*y0
    n0  = 0.0 if t0 < 0 else (t0*t0)*(t0*t0) * (g0[0]*x0 + g0[1]*y0)
    t1  = 0.5 - x1*x1 - y1*y1
    n1  = 0.0 if t1 < 0 else (t1*t1)*(t1*t1) * (g1[0]*x1 + g1[1]*y1)
    t2  = 0.5 - x2*x2 - y2*y2
    n2  = 0.0 if t2 < 0 else (t2*t2)*(t2*t2) * (g2[0]*x2 + g2[1]*y2)
    return 70.0 * (n0 + n1 + n2)


def generate_run_weather(duration, seed):
    """
    Generate per-day weather using the exact same algorithm as ClimateManager/ClimateValues.

    The game initialises:
        simplexOffsetA = Rand.Next(0, 8000)       -- drives airmass & wind
        simplexOffsetC = Rand.Next(0, -8000)      -- drives humidity/precipitation
        airMassNoiseFrequencyMod = 166.0           -- sandbox rain=3 (default Normal)

    Wind intensity (ClimateValues lines 283-287):
        noiseWindBase = SimplexNoise.noise(worldAgeHours / 40.0, offsetA)
        windBase      = (noiseWindBase + 1) * 0.5
        airMassTemperature = SimplexNoise.noise(offsetA, (worldAgeHours - 48) / freqMod)
        windMod       = 1 - (airMassTemperature + 1) * 0.5
        windIntensity = windBase * windMod * 0.65         (windMod2 ≈ 1 at noon)
        windspeedKph  = windIntensity * 120.0             (ClimateManager.getWindspeedKph)

    Precipitation (simplified from WeatherPeriod):
        humidity = ((noiseHumidity+1)/2) * tempOffset
        rain when humidity > 0.48 (approximate WeatherPeriod threshold)

    Fog (ClimateValues lines 200-235):
        20% daily probability; intensity sampled from seededRandom

    Each run gets unique offsets derived from `seed`.
    """
    rng       = random.Random(seed)
    offsetA   = rng.uniform(0,    8000)
    offsetB   = rng.uniform(8000, 16000)
    offsetC   = rng.uniform(-8000, 0)
    freqMod   = 166.0

    days = {}
    for day in range(int(duration) + 10):
        h = day * 24.0 + 12.0  # sample at solar noon, matching the game's day-tick update

        # Air mass temperature: drives cold/warm fronts and snow threshold
        air_mass_temp = simplex_noise_2d(offsetA, (h - 48.0) / freqMod)     # [-1, 1]

        # Humidity noise: drives precipitation
        noise_humidity = simplex_noise_2d(offsetC, h / freqMod)             # [-1, 1]

        # Wind (ClimateValues lines 283-287)
        noise_wind_base = simplex_noise_2d(h / 40.0, offsetA)               # [-1, 1]
        wind_base       = (noise_wind_base + 1.0) * 0.5                     # [0, 1]
        wind_mod        = 1.0 - (air_mass_temp + 1.0) * 0.5                 # cold=1, warm=0
        wind_intensity  = max(0.0, min(1.0, wind_base * wind_mod * 0.65))
        wind_kph        = wind_intensity * 120.0

        # Temperature (°C). Game adds season mean (~15°C for KY spring/summer).
        # Without tracking season progression, 15°C is the neutral baseline.
        SEASON_MEAN  = 15.0
        base_temp    = SEASON_MEAN + air_mass_temp * 8.0
        is_snow      = base_temp < 0.0

        # Humidity → precipitation (WeatherPeriod threshold ≈ 0.48)
        temp_offset     = max(0.0, min(1.0, 1.0 - (45.0 - base_temp) / 90.0))
        humidity        = ((noise_humidity + 1.0) * 0.5) * temp_offset
        is_raining      = humidity > 0.48
        precip_intensity = max(0.0, min(1.0, (humidity - 0.48) / 0.52)) if is_raining else 0.0

        # Thunderstorm: heavy rain + moderate wind
        thunder = is_raining and precip_intensity > 0.65 and wind_intensity > 0.30

        # Fog: 20% daily probability (ClimateValues line 202: r < 200 out of 1000)
        fog_r       = rng.random()
        has_fog     = fog_r < 0.20
        fog_strength = rng.random() if has_fog and fog_r >= 0.025 else (1.0 if has_fog else 0.0)

        days[day] = {
            "windKph":       round(wind_kph, 1),
            "precipitation": round(precip_intensity, 3),
            "fog":           round(fog_strength if has_fog else 0.0, 3),
            "thunder":       thunder,
            "isSnow":        is_snow,
        }
    return days


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


def build_lua_environment(all_presets, sandbox, heli_defaults, weather_days=None):
    """
    Construct the full Lua source that the simulation will execute.
    Includes:
      - require() override so EHE_util and other internal modules resolve safely
      - PZ API stubs (ZombRand, SandboxVars, getGameTime, ClimateManager, etc.)
      - Per-run weather data table (varies between runs)
      - eHelicopter global built from heli_defaults (read from EHE_mainVariables.lua)
      - eHelicopter_PRESETS table populated from parsed Python data
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

    # ── Weather data table ─────────────────────────────────────────────
    weather_entries = []
    for day, w in sorted((weather_days or {}).items()):
        weather_entries.append(
            f'  [{day}] = {{ windKph={w["windKph"]}, precipitation={w["precipitation"]},'
            f' fog={w["fog"]}, thunder={"true" if w["thunder"] else "false"},'
            f' isSnow={"true" if w["isSnow"] else "false"} }},'
        )
    weather_lua = "\n".join(weather_entries)

    stubs = f"""
-- ── require() override ────────────────────────────────────────────────
local _sim_req = {{}}
_sim_req["EHE_util"] = {{
    getModData                   = function() return modData end,
    getExpandedHeliEventsModData = function() return modData end,
    print = function(...) end, log = function(...) end,
}}
function require(modname)
    if _sim_req[modname] then return _sim_req[modname] end
    local proxy = setmetatable({{}}, {{ __index = function(_, _k) return function(...) end end }})
    _sim_req[modname] = proxy
    return proxy
end

-- ── PZ API stubs ──────────────────────────────────────────────────────

math.randomseed(os.time())

function ZombRand(n)
    n = math.floor(n)
    if not n or n <= 0 then return 0 end
    return math.random(0, n - 1)
end

-- Per-run weather (windKph, precipitation, fog, thunder, isSnow) keyed by day.
_SIM_WEATHER = {{
{weather_lua}
}}
_SIM_CURRENT_DAY  = 0
_SIM_CURRENT_HOUR = 0
function _getWeather(day)
    return _SIM_WEATHER[day] or {{ windKph=20, precipitation=0, fog=0, thunder=false, isSnow=false }}
end

ClimateManager = {{
    getInstance = function()
        return {{
            getWindspeedKph           = function(self) return _getWeather(_SIM_CURRENT_DAY).windKph end,
            getWindIntensity          = function(self) return _getWeather(_SIM_CURRENT_DAY).windKph / 120.0 end,
            getPrecipitationIntensity = function(self) return _getWeather(_SIM_CURRENT_DAY).precipitation end,
            getFogIntensity           = function(self) return _getWeather(_SIM_CURRENT_DAY).fog end,
            isRaining  = function(self) local w=_getWeather(_SIM_CURRENT_DAY) return w.precipitation>0 and not w.isSnow end,
            isSnowing  = function(self) local w=_getWeather(_SIM_CURRENT_DAY) return w.precipitation>0 and w.isSnow end,
            getThunderStorm = function(self) return {{ isActive=function() return _getWeather(_SIM_CURRENT_DAY).thunder end }} end,
            getTemperature  = function(self) return 15 end,
            getAirTemperatureForCharacter = function(self, ch, wc) return 15 end,
        }}
    end
}}

SandboxVars = {{
    ExpandedHeli = {{
        SchedulerDuration        = {duration},
        StartDay                 = {start_day},
        ContinueSchedulingEvents = {continue_val},
        AirRaidSirenEvent        = {air_raid},
        {chr(10).join(freq_lines)}
    }}
}}

eHelicopter = {{
{heli_field_lines}
}}

local _vanillaHeliDay = 9999
function getGameTime()
    return {{
        getHour             = function(self) return _SIM_CURRENT_HOUR end,
        getMonth            = function(self) return 1 end,
        getDay              = function(self) return _SIM_CURRENT_DAY end,
        getHelicopterDay    = function(self) return _vanillaHeliDay end,
        getHelicopterDay1   = function(self) return _vanillaHeliDay end,
        setHelicopterDay    = function(self, v) _vanillaHeliDay = v end,
        getHelicopterStartHour  = function(self) return 0 end,
        setHelicopterStartHour  = function(self, v) end,
        getHelicopterEndHour    = function(self) return 0 end,
        setHelicopterEndHour    = function(self, v) end,
    }}
end
function EHE_getWorldAgeDays() return _SIM_CURRENT_DAY end
function triggerEvent(...) end
function isServer() return true end
function isClient() return false end
function getDebug() return false end
Events = setmetatable({{}}, {{
    __index = function(t, k)
        return setmetatable({{}}, {{ __index = function(t2, k2) return function(...) end end }})
    end
}})

function _make_modData()
    local d = {{ DaysBeforeApoc=0, EventsOnSchedule={{}} }}
    setmetatable(d, {{ __index = function(t, k)
        if k == "get" then return function(s, key)
            if type(s)=="table" then return s[key] else return t[s] end end end
        if k == "put" then return function(s, key, val)
            if type(s)=="table" then s[key]=val else t[s]=key end end end
        if k == "containsKey" then return function(s, key)
            if type(s)=="table" then return s[key]~=nil else return t[s]~=nil end end end
    end }})
    return d
end
modData = _make_modData()
function getExpandedHeliEventsModData() return modData end
getEHEModData  = getExpandedHeliEventsModData
EHE_getModData = getExpandedHeliEventsModData

function eHeliEvent_new(startDay, startTime, preset)
    if _counts and preset then _counts[preset] = (_counts[preset] or 0) + 1 end
    table.insert(modData.EventsOnSchedule, {{
        startDay=startDay, startTime=startTime, preset=preset, triggered=false
    }})
end

function eHeliEvent_processSchedulerDates(targetDate, expectedDates)
    return false
end

{presets_lua}

eventsForScheduling = nil
"""

    return stubs



def sanitize_lua(code):
    return code.replace("\\[", "[").replace("\\]", "]")


def _strip_file_level_statements(text):
    """
    Pre-process a Lua source file for execution in a bare Lua environment.
    Rewrites top-level statements that reference unavailable PZ APIs:
      - Events.OnX.Add(fn)  → commented out
      - LuaEventManager.*   → commented out
      - file-level return X → commented out
    Leaves require() calls intact — our require-override stub handles those.
    """
    out = []
    for line in text.splitlines():
        s = line.lstrip()
        if (s.startswith("Events.") or
                s.startswith("LuaEventManager.") or
                re.match(r'^return\s+\w+\s*(?:--.*)?$', s)):
            out.append("-- SIM_STRIPPED: " + line)
        else:
            out.append(line)
    return "\n".join(out)


def load_full_scheduler_source(server_files):
    """
    Load EHE_mainCore.lua and EHE_eventScheduler.lua as complete source texts,
    returning a single Lua string that can be executed after the stubs.

    Crucially, this preserves all file-scope locals (upvalues), so extracted
    functions like eHeliEvent_ScheduleNew see the correct closures.
    """
    parts = []
    for name in ("EHE_mainCore.lua", "EHE_eventScheduler.lua"):
        path = server_files.get(name)
        if path and path.exists():
            raw = path.read_text(encoding="utf-8", errors="replace")
            processed = sanitize_lua(_strip_file_level_statements(raw))
            parts.append(f"-- ===== {name} =====\n" + processed)
            print(f"  Loaded full source: {name}")

    if not parts:
        return None
    return "\n\n".join(parts)


def load_scheduler_functions(server_files):
    """
    Load scheduler logic, preferring whole-file loading (which preserves upvalues)
    over individual function extraction.
    Returns a dict with key 'full_source' if whole-file loading succeeded,
    or individual function keys for fallback embedded copies.
    """
    full_source = load_full_scheduler_source(server_files)
    if full_source:
        return {"full_source": full_source}

    # ── Fallback: embedded copies ──────────────────────────────────────
    print("  [fallback] Using all embedded function copies.")
    funcs = {}

    funcs["fetchStartDayAndCutOffDay"] = """
function fetchStartDayAndCutOffDay(HelicopterOrPreset)
    local startDayFactor = HelicopterOrPreset.eventStartDayFactor or eHelicopter.eventStartDayFactor
    local startDay = math.floor((startDayFactor*SandboxVars.ExpandedHeli.SchedulerDuration)+0.5)
    startDay = math.max(startDay, SandboxVars.ExpandedHeli.StartDay)
    local cutOffDayFactor = HelicopterOrPreset.eventCutOffDayFactor or eHelicopter.eventCutOffDayFactor
    local cutOffDay = math.floor((cutOffDayFactor*(startDay+SandboxVars.ExpandedHeli.SchedulerDuration))+0.5)
    return startDay, cutOffDay
end"""

    funcs["eHeliEvent_determineContinuation"] = """
function eHeliEvent_determineContinuation()
    local continue = SandboxVars.ExpandedHeli.ContinueSchedulingEvents
    return continue>1, continue>=3
end"""

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

    print(f"\nLoading Lua scheduler source...")
    funcs = load_scheduler_functions(server_files)
    is_full_source = "full_source" in funcs

    heli_defaults = load_main_variable_defaults()
    if not heli_defaults:
        print("  [WARN] EHE_mainVariables.lua not found — eHelicopter defaults will be minimal.")

    # Build the seed-0 weather for the shared environment and smoke test.
    # Each real run gets its own weather generated inline in the runner.
    seed0_weather = generate_run_weather(duration, seed=0)
    env_lua = build_lua_environment(all_presets, sandbox, heli_defaults, weather_days=seed0_weather)

    if is_full_source:
        scheduler_lua = (
            funcs["full_source"]
            # Re-assert our stubs AFTER the file so any file-scope overrides
            # of getExpandedHeliEventsModData are replaced by ours.
            + "\n\nfunction getExpandedHeliEventsModData() return modData end"
            + "\ngetEHEModData  = getExpandedHeliEventsModData"
            + "\nEHE_getModData = getExpandedHeliEventsModData"
        )
    else:
        scheduler_lua = "\n\n".join(funcs[k] for k in [
            "fetchStartDayAndCutOffDay",
            "eHeliEvent_determineContinuation",
            "eHeliEvents_setEventsForScheduling",
            "eHeliEvent_ScheduleNew",
        ] if k in funcs)

    runner_lua = f"""
function run_one_playthrough(run_seed)
    -- Rebuild per-run weather in Lua from a Python-generated JSON blob.
    -- The actual weather table was already embedded for this run index.
    modData = _make_modData()
    eventsForScheduling = nil

    local counts = {{}}
    _counts = counts

    local total_ticks = math.ceil({duration} * 24)
    for tick = 0, total_ticks - 1 do
        local day  = math.floor(tick / 24)
        local hour = tick % 24

        _SIM_CURRENT_DAY  = day
        _SIM_CURRENT_HOUR = hour

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
        + "\n\n" + scheduler_lua
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
          f"{duration*24:,} ticks/run, unique weather per run)...")

    for i in range(num_runs):
        if verbose and (i+1) % 10 == 0:
            print(f"  Run {i+1}/{num_runs}")

        # Generate a unique weather profile for this run and push it into Lua.
        run_weather = generate_run_weather(duration, seed=i + 1)
        weather_tbl = lua.table()
        for day, w in run_weather.items():
            day_tbl = lua.table()
            day_tbl["windKph"]       = w["windKph"]
            day_tbl["precipitation"] = w["precipitation"]
            day_tbl["fog"]           = w["fog"]
            day_tbl["thunder"]       = w["thunder"]
            day_tbl["isSnow"]        = w["isSnow"]
            weather_tbl[day]         = day_tbl
        lua.globals()._SIM_WEATHER = weather_tbl

        result = run_one()
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
