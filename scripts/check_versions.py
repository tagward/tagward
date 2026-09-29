#!/usr/bin/env python3
"""Validate versions.yaml: structure, allowed statuses, and that no version is missing.

Usage: check_versions.py versions.yaml
Exit code 0 when valid, 1 otherwise. Dependencies: PyYAML.
"""
import sys

import yaml

ALLOWED_STATUS = {"proposed", "verified", "pinned"}
REQUIRED_TOP = {"distribution", "components", "runtime"}
REQUIRED_COMPONENT_KEYS = {"version", "status"}


def main(path: str) -> int:
    with open(path, encoding="utf-8") as handle:
        data = yaml.safe_load(handle)
    errors = []
    missing_top = REQUIRED_TOP - set(data or {})
    if missing_top:
        errors.append(f"missing top-level keys: {sorted(missing_top)}")
        return report(errors)
    dist = data["distribution"]
    if dist.get("status") not in ALLOWED_STATUS:
        errors.append(f"distribution.status must be one of {sorted(ALLOWED_STATUS)}")
    if not dist.get("version"):
        errors.append("distribution.version is required")
    for name, comp in (data["components"] or {}).items():
        missing = REQUIRED_COMPONENT_KEYS - set(comp or {})
        if missing:
            errors.append(f"components.{name}: missing {sorted(missing)}")
            continue
        if comp["status"] not in ALLOWED_STATUS:
            errors.append(f"components.{name}.status must be one of {sorted(ALLOWED_STATUS)}")
        if str(comp["version"]).strip() in {"", "TBD"}:
            errors.append(f"components.{name}.version must not be empty or TBD")
        if "image" in comp and "<org>" in str(comp["image"]):
            errors.append(f"components.{name}.image still contains the <org> placeholder")
    return report(errors)


def report(errors: list) -> int:
    if errors:
        for error in errors:
            print(f"versions.yaml: {error}", file=sys.stderr)
        return 1
    print("versions.yaml: ok")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else "versions.yaml"))
