#!/usr/bin/env python3
"""Convert all `require(script.X.Y)` style requires under src/ to the modern
Luau `require("@self/X/Y")` form, which works in both Roblox (with require-by-
string enabled) and Lune.

The @self alias is defined in .luaurc as "./src".

Rules:
- File at src/init.luau:               script.X      -> @self/X
- File at src/A/init.luau:             script.X      -> @self/A/X
                                       script.Parent -> @self
- File at src/A/B/init.luau:           script.X      -> @self/A/B/X
                                       script.Parent -> @self/A
- File at src/Foo.luau (non-init):     script.Parent.X      -> @self/X
                                       script.Parent.Parent -> error (above src)
- File at src/A/Foo.luau (non-init):   script.Parent.X      -> @self/A/X
                                       script.Parent.Parent.X -> @self/X
"""

import os
import re
import sys

SRC_DIR = "src"


def compute_replacement(file_path: str, chain: str) -> str | None:
    rel = file_path[len(SRC_DIR) + 1:] if file_path.startswith(SRC_DIR + os.sep) or file_path.startswith(SRC_DIR + "/") else file_path
    rel = rel.replace("\\", "/")
    parts = rel.split("/")
    fname = parts[-1]
    folders = parts[:-1]

    chain_parts = [p for p in chain.split(".") if p]
    n_parents = 0
    for p in chain_parts:
        if p == "Parent":
            n_parents += 1
        else:
            break
    descendants = chain_parts[n_parents:]

    if fname == "init.luau":
        # script IS the folder containing init.luau; .Parent walks up one folder
        landing_idx = len(folders) - n_parents
        if landing_idx < 0:
            return None
        landing_folders = folders[:landing_idx]
    else:
        # script is the file; .Parent IS the containing folder; .Parent.Parent is the parent of that
        if n_parents == 0:
            return None  # we don't use script.X without Parent for non-init files
        landing_idx = len(folders) - (n_parents - 1)
        if landing_idx < 0:
            return None
        landing_folders = folders[:landing_idx]

    full_path_parts = landing_folders + descendants
    if not full_path_parts:
        return "@self"
    return "@self/" + "/".join(full_path_parts)


REQUIRE_RE = re.compile(r"require\(script((?:\.\w+)*)\)")


def process_file(file_path: str) -> bool:
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    def replace(match):
        chain = match.group(1).lstrip(".")
        new_path = compute_replacement(file_path, chain)
        if new_path is None:
            return match.group(0)
        return f'require("{new_path}")'

    new_content = REQUIRE_RE.sub(replace, content)
    if new_content == content:
        return False
    with open(file_path, "w", encoding="utf-8", newline="\n") as f:
        f.write(new_content)
    return True


def main():
    changed = 0
    for root, _dirs, files in os.walk(SRC_DIR):
        for fn in files:
            if fn.endswith(".luau"):
                path = os.path.join(root, fn).replace("\\", "/")
                if process_file(path):
                    changed += 1
                    print(f"updated {path}")
    print(f"\n{changed} files updated")


if __name__ == "__main__":
    main()
