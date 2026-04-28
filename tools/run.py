#!/usr/bin/env python3
"""
EHE QA Runner
Runs validate → generate → opens timeline.html in one command.

Usage (from tools/ directory):
    python run.py
    python run.py --runs 200
    python run.py --skip-validate
    python run.py --no-open
"""

import sys
import argparse
import subprocess
import webbrowser
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent
VALIDATE   = SCRIPT_DIR / "validate.py"
GENERATE   = SCRIPT_DIR / "generate.py"
TIMELINE   = SCRIPT_DIR / "timeline.html"


def separator(title=""):
    width = 44
    if title:
        pad = (width - len(title) - 2) // 2
        print(f"\n{'─'*pad} {title} {'─'*(width-pad-len(title)-2)}")
    else:
        print(f"\n{'─'*width}")


def run_step(label, cmd, allow_warnings=False):
    """Run a subprocess step. Returns True if it passed (or only warnings)."""
    separator(label)
    result = subprocess.run([sys.executable] + cmd)
    if result.returncode == 0:
        return True
    if allow_warnings:
        # validate.py exits 0 on warnings, 1 on errors — no ambiguity needed
        pass
    return False


def main():
    parser = argparse.ArgumentParser(
        description="Validate presets → generate timeline → open in browser."
    )
    parser.add_argument(
        "--skip-validate", action="store_true",
        help="Skip the validate step (still generates and opens)."
    )
    parser.add_argument(
        "--no-open", action="store_true",
        help="Don't open the browser after generating."
    )
    parser.add_argument(
        "--runs", type=int, default=100, metavar="N",
        help="Number of simulation runs for generate.py (default: 100)."
    )
    parser.add_argument(
        "--presets", nargs="*", metavar="FILE",
        help="Preset Lua files to use (passed to both scripts)."
    )
    args = parser.parse_args()

    print("EHE QA Runner")
    print("=" * 44)

    preset_args = []
    if args.presets:
        preset_args = ["--presets"] + args.presets

    # ── Step 1: Validate ──────────────────────────────────────────────
    validate_ok = True
    if not args.skip_validate:
        validate_ok = run_step(
            "1 / 3  VALIDATE",
            [str(VALIDATE)] + preset_args,
        )
        if not validate_ok:
            print("\n  Validation found errors — fix them before shipping.")
            print("  Generation will continue so you can review the timeline.")
    else:
        separator("1 / 3  VALIDATE")
        print("  Skipped.")

    # ── Step 2: Generate ──────────────────────────────────────────────
    generate_cmd = [str(GENERATE), "--runs", str(args.runs)] + preset_args
    generate_ok  = run_step("2 / 3  GENERATE", generate_cmd)

    if not generate_ok:
        print("\n  Generation failed — cannot open timeline.")
        sys.exit(1)

    # ── Step 3: Open ──────────────────────────────────────────────────
    separator("3 / 3  OPEN")
    if args.no_open:
        print("  Skipped.")
    elif not TIMELINE.exists():
        print(f"  {TIMELINE} not found — skipping browser open.")
    else:
        url = TIMELINE.resolve().as_uri()
        print(f"  Opening: {url}")
        webbrowser.open(url)
        print("  Done.")

    # ── Summary ───────────────────────────────────────────────────────
    separator()
    status = []
    if not args.skip_validate:
        status.append("Validate: " + ("✓ passed" if validate_ok else "✗ errors"))
    status.append("Generate: " + ("✓ done"   if generate_ok else "✗ failed"))
    if not args.no_open:
        status.append("Browser:  ✓ opened")
    for s in status:
        print(f"  {s}")
    print()

    sys.exit(0 if validate_ok and generate_ok else 1)


if __name__ == "__main__":
    main()
