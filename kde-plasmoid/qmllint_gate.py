#!/usr/bin/env python3
"""Run qmllint while allowing only verified dynamic KConfig properties."""

from __future__ import annotations

import json
import re
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET
from pathlib import Path


MEMBER_RE = re.compile(r'^Member "([^"]+)" not found on type .*KConfigPropertyMap')


def config_names(schema_path: Path) -> set[str]:
    root = ET.parse(schema_path).getroot()
    return {
        entry.attrib["name"]
        for entry in root.iter()
        if entry.tag.rsplit("}", 1)[-1] == "entry" and entry.attrib.get("name")
    }


def allowed_dynamic_property(warning: dict, source: str, names: set[str]) -> bool:
    if warning.get("id") != "missing-property":
        return False
    match = MEMBER_RE.match(str(warning.get("message", "")))
    if not match or match.group(1) not in names:
        return False
    lines = source.splitlines()
    line_number = warning.get("line")
    if not isinstance(line_number, int) or not 1 <= line_number <= len(lines):
        return False
    name = re.escape(match.group(1))
    return re.search(rf"\bPlasmoid\.configuration\s*\.\s*{name}\b", lines[line_number - 1]) is not None


def main(argv: list[str]) -> int:
    if len(argv) < 4:
        print(f"usage: {argv[0]} QMLLINT CONFIG_XML QML_FILE...", file=sys.stderr)
        return 2

    qmllint, schema, *files = argv[1:]
    names = config_names(Path(schema))
    with tempfile.NamedTemporaryFile() as report:
        result = subprocess.run(
            [qmllint, "--json", report.name, "--unqualified", "disable", *files],
            text=True,
            capture_output=True,
            check=False,
        )
        report.seek(0)
        try:
            payload = json.load(report)
        except json.JSONDecodeError:
            sys.stderr.write(result.stderr)
            print("qmllint did not produce a valid JSON report", file=sys.stderr)
            return 1

    allowed = 0
    failures = []
    for file_report in payload.get("files", []):
        filename = file_report.get("filename", "<unknown>")
        try:
            source = Path(filename).read_text(encoding="utf-8")
        except OSError as error:
            failures.append(f"{filename}: cannot read source: {error}")
            continue
        for warning in file_report.get("warnings", []):
            if allowed_dynamic_property(warning, source, names):
                allowed += 1
                continue
            failures.append(
                f"{filename}:{warning.get('line', '?')}:{warning.get('column', '?')}: "
                f"{warning.get('type', 'warning')} [{warning.get('id', 'unknown')}]: "
                f"{warning.get('message', '')}"
            )

    if failures:
        print("qmllint found actionable diagnostics:", file=sys.stderr)
        for failure in failures:
            print(f"  {failure}", file=sys.stderr)
        return 1
    if result.returncode != 0:
        sys.stderr.write(result.stderr)
        print(f"qmllint exited with status {result.returncode}", file=sys.stderr)
        return result.returncode

    print(f"qmllint passed ({allowed} verified dynamic KConfig warnings allowed)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
