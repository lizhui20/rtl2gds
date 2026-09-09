#!/usr/bin/env python3
"""Drop identical duplicate SPICE .subckt blocks from a CDL bundle."""

import argparse
import re
from pathlib import Path


SUBCKT_RE = re.compile(r"^\s*\.subckt\s+(\S+)", re.IGNORECASE)
ENDS_RE = re.compile(r"^\s*\.ends\b", re.IGNORECASE)


def normalise_block(block):
    return "\n".join(line.strip().lower() for line in block if line.strip())


def split_blocks(lines):
    index = 0
    while index < len(lines):
        match = SUBCKT_RE.match(lines[index])
        if not match:
            yield None, [lines[index]]
            index += 1
            continue

        name = match.group(1).lower()
        block = [lines[index]]
        index += 1
        while index < len(lines):
            block.append(lines[index])
            if ENDS_RE.match(lines[index]):
                index += 1
                break
            index += 1
        yield name, block


def dedupe(input_path, output_path):
    lines = input_path.read_text(encoding="utf-8", errors="replace").splitlines(True)
    seen = {}
    skipped = 0

    with output_path.open("w", encoding="utf-8") as out:
        for name, block in split_blocks(lines):
            if name is None:
                out.writelines(block)
                continue

            body = normalise_block(block)
            if name in seen:
                if seen[name] != body:
                    raise RuntimeError(
                        "Conflicting .subckt definitions for '{}' in {}".format(
                            name, input_path
                        )
                    )
                skipped += 1
                continue

            seen[name] = body
            out.writelines(block)

    print(
        "dedupe_identical_spice_subckts: skipped {} identical duplicate .subckt block(s)".format(
            skipped
        )
    )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    dedupe(args.input, args.output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
