#!/usr/bin/env python3
"""Bake @self/X requires into Roblox-instance-relative form for the Wally artifact.

The wrapper source uses `require("@self/X")` where @self is a .luaurc alias to ./src.
That works in Lune (alias resolved against the file system at parse time) but NOT in
Roblox runtime: there, @self resolves to `script`, which for a file at src/Foo.luau
means the Foo ModuleScript itself, not its siblings. The require fails.

This script rewrites every `require("@self/A/B/C")` to the equivalent
`require(script.Parent. ... .A.B.C)` form based on the calling file's depth under src/.

Mapping per source file (depth = path components beyond src/, where folder/init.luau
is treated the same as a file in that folder):

  src/init.luau          : @self -> script             ; @self/X -> script.X
  src/Foo.luau           : @self -> script.Parent      ; @self/X -> script.Parent.X
  src/A/init.luau        : @self -> script.Parent      ; @self/X -> script.Parent.X
  src/A/Foo.luau         : @self -> script.Parent.Parent
  src/A/B/init.luau      : @self -> script.Parent.Parent
  src/A/B/Foo.luau       : @self -> script.Parent.Parent.Parent

In short: depth = (number of "/" after src/, with init.luau collapsed). The chain
starts with one `script` and gets `.Parent` repeated `depth` times.

Run in place from the repo root: `python scripts/bake_self_for_publish.py`.
Use `--check` to verify nothing would change (useful in CI after publish to ensure
git-clean state).
"""

import argparse
import os
import re
import sys
from pathlib import Path

SRC = "src"
REQUIRE_RE = re.compile(r'require\(\s*["\']@self(/[^"\']*)?["\']\s*\)')


def depth_of(rel_path: str) -> int:
    """Return the number of .Parent walks needed for @self to reach src/."""
    parts = rel_path.replace("\\", "/").split("/")
    fname = parts[-1]
    folders = parts[:-1]
    if fname == "init.luau":
        return len(folders)
    return len(folders) + 1


def build_chain(depth: int, suffix: str) -> str:
    """Build `script(.Parent x depth)(.A.B.C)`."""
    base = "script" + (".Parent" * depth)
    if not suffix or suffix == "/":
        return base
    # suffix begins with "/", split components on "/"
    parts = [p for p in suffix.split("/") if p]
    return base + "".join(f".{p}" for p in parts)


def transform_file(path: Path, check: bool) -> bool:
    rel = path.relative_to(SRC).as_posix()
    depth = depth_of(rel)
    original = path.read_text(encoding="utf-8")

    def replace(match: re.Match[str]) -> str:
        suffix = match.group(1) or ""
        return f"require({build_chain(depth, suffix)})"

    updated = REQUIRE_RE.sub(replace, original)
    if updated == original:
        return False
    if check:
        # In check mode, just signal that a change would happen
        return True
    path.write_text(updated, encoding="utf-8", newline="\n")
    return True


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="report files that would change; non-zero exit if any")
    args = parser.parse_args()

    root = Path(SRC)
    if not root.is_dir():
        print(f"error: {SRC}/ not found (run from the repo root)", file=sys.stderr)
        return 2

    changed_files = []
    for path in sorted(root.rglob("*.luau")):
        if transform_file(path, args.check):
            changed_files.append(path.as_posix())

    if args.check:
        if changed_files:
            print("Files that would change:")
            for p in changed_files:
                print(f"  {p}")
            return 1
        print("No changes needed.")
        return 0

    if changed_files:
        print(f"Rewrote {len(changed_files)} file(s):")
        for p in changed_files:
            print(f"  {p}")
    else:
        print("No @self requires found; nothing to do.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
