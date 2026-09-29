#!/usr/bin/env python3
"""Copy root-level documents into docs/ so the site can render them.

The root files stay the source of truth (GitHub shows them there); the copies are
generated at build time and ignored by git.
"""
import pathlib
import shutil

ROOT = pathlib.Path(__file__).resolve().parent.parent
COPIES = {
    "ROADMAP.md": "docs/roadmap.md",
}

for source, target in COPIES.items():
    src = ROOT / source
    dst = ROOT / target
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(src, dst)
    print(f"{source} -> {target}")
