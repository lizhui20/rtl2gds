#!/usr/bin/env python3
import os
import re
import sys
import gzip
from pathlib import Path


ALLOWED_BLOCK_WARNINGS = {
    "IO_CONNECT_CORE_NET_VOLTAGE_IS_CORE:WARNING1": (
        "Deck reminder that USE_IO_VOLTAGE_ON_CORE_TO_IO_NET is off. "
        "The rule text states this warning is a reminder, not a tapeout gate. "
        "For this block-level std-cell run, IO/pad libraries are disabled; if a "
        "design enables IO devices or mixed core/IO-voltage nets, add voltage "
        "markers or revisit the deck option instead of carrying this explanation."
    ),
    "FLIP_CHIP_WITHOUT_28K_AP:WARNING": (
        "Package/AP-RDL reminder from the foundry deck when AP_28K_THICKNESS is "
        "not defined. N28_DRC_MODE=block deliberately disables full-chip/package/"
        "AP-RDL options, and the layout summary has no AP/RV geometry. Full-chip "
        "or flip-chip package signoff must use N28_DRC_MODE=fullchip with the "
        "proper package options."
    ),
    "DIODMY_L:WARNING": (
        "Low-leakage diode marker reminder. The deck text says it can be ignored "
        "when there is no low-leakage diode concern cell; this block has zero "
        "DIODMY and DIODMY_L original geometry in the DRC summary."
    ),
}


RULE_RE = re.compile(r"^RULECHECK\s+(.+?)\s+\.+\s+TOTAL Result Count =\s+([0-9]+)")
LAYER_RE = re.compile(r"^LAYER\s+(\S+)\s+\.+\s+TOTAL Original Geometry Count =\s+([0-9]+)")
TOKEN_RE = re.compile(r"[A-Za-z_$][A-Za-z0-9_$]*")
MACRO_RE = re.compile(r"^MACRO\s+(\S+)")
SIZE_RE = re.compile(r"^\s*SIZE\s+([0-9.]+)\s+BY\s+([0-9.]+)\s*;")
COMP_RE = re.compile(
    r"^\s*-\s+(\S+)\s+(\S+).*?\+\s+(?:PLACED|FIXED)\s+\(\s+(-?\d+)\s+(-?\d+)\s+\)\s+(\S+)"
)
INT_RE = re.compile(r"^-?\d+$")
RDB_RULE_HEADER_RE = re.compile(r"^[A-Za-z0-9_.$:]+$")


def parse_summary(path: Path):
    nonzero = []
    layers = {}
    for line in path.read_text(errors="replace").splitlines():
        m = RULE_RE.match(line)
        if m:
            name = m.group(1).strip()
            count = int(m.group(2))
            if count:
                nonzero.append((name, count))
            continue
        m = LAYER_RE.match(line)
        if m:
            layers[m.group(1)] = int(m.group(2))
    return nonzero, layers


def load_stdcell_names(summary: Path):
    root = Path(os.environ.get("ROOT_PATH", str(Path(__file__).resolve().parents[2])))
    design = os.environ.get("DESIGN_NAME", summary.name.split(".drc.summary")[0])
    run_dir = summary.parents[2] if len(summary.parents) > 2 else root / design
    candidates = [
        root / design / "work" / "signoff" / "calibre" / "stdcell_drc.cells",
        run_dir / "work" / "signoff" / "calibre" / "stdcell_drc.cells",
    ]
    for path in candidates:
        if path.is_file():
            names = {line.strip() for line in path.read_text(errors="replace").splitlines() if line.strip()}
            if names:
                return names, path
    return set(), None


def load_lef_sizes(run_dir: Path, stdcell_names):
    sizes = {}
    for lef in (run_dir / "ref").glob("*.lef"):
        current = None
        for raw in lef.read_text(errors="replace").splitlines():
            line = raw.strip()
            m = MACRO_RE.match(line)
            if m:
                current = m.group(1)
                continue
            if current in stdcell_names:
                m = SIZE_RE.match(line)
                if m:
                    sizes[current] = (int(round(float(m.group(1)) * 1000)), int(round(float(m.group(2)) * 1000)))
                    current = None
    return sizes


def read_text_lines(path: Path):
    if path.suffix == ".gz":
        with gzip.open(path, "rt", errors="replace") as fh:
            yield from fh
    else:
        yield from path.read_text(errors="replace").splitlines()


def load_stdcell_instances(run_dir: Path, stdcell_names):
    design = os.environ.get("DESIGN_NAME", run_dir.name)
    def_path = run_dir / "results" / f"{design}.pnr.def.gz"
    if not def_path.is_file():
        def_path = run_dir / "results" / f"{design}.pnr.def"
    if not def_path.is_file():
        return [], None

    sizes = load_lef_sizes(run_dir, stdcell_names)
    insts = []
    in_components = False
    pending = ""
    for raw in read_text_lines(def_path):
        line = raw.strip()
        if line.startswith("COMPONENTS "):
            in_components = True
            continue
        if in_components and line.startswith("END COMPONENTS"):
            break
        if not in_components:
            continue
        if not line:
            continue

        pending = f"{pending} {line}".strip()
        if not pending.endswith(";"):
            continue

        m = COMP_RE.match(pending)
        pending = ""
        if not m:
            continue
        inst_name, ref_name, x_s, y_s, orient = m.groups()
        if ref_name not in stdcell_names or ref_name not in sizes:
            continue
        width, height = sizes[ref_name]
        if orient in {"E", "W", "FE", "FW"}:
            width, height = height, width
        x = int(x_s)
        y = int(y_s)
        insts.append((x, y, x + width, y + height, inst_name, ref_name))
    return insts, def_path


def point_in_stdcell(x, y, insts):
    for x0, y0, x1, y1, inst_name, ref_name in insts:
        if x0 <= x <= x1 and y0 <= y <= y1:
            return inst_name, ref_name
    return None


def parse_rdb_results(rdb: Path, rule_names):
    bboxes = parse_rdb_result_bboxes(rdb, rule_names)
    return {
        name: [((x0 + x1) // 2, (y0 + y1) // 2) for x0, y0, x1, y1 in boxes]
        for name, boxes in bboxes.items()
    }


def parse_rdb_result_bboxes(rdb: Path, rule_names):
    results = {name: [] for name in rule_names}
    if not rdb.is_file():
        return results

    rule_set = set(rule_names)
    current_rule = None
    current_points = []

    def commit():
        if current_rule and current_points:
            xs = [p[0] for p in current_points]
            ys = [p[1] for p in current_points]
            results[current_rule].append((min(xs), min(ys), max(xs), max(ys)))

    for raw in rdb.read_text(errors="replace").splitlines():
        text = raw.strip()
        if text in rule_set:
            commit()
            current_rule = text
            current_points = []
            continue
        if current_rule and RDB_RULE_HEADER_RE.match(text):
            commit()
            current_rule = None
            current_points = []
            continue
        if current_rule is None:
            continue
        fields = text.split()
        if len(fields) >= 3 and fields[0] in {"p", "e"} and fields[1].lstrip("-").isdigit():
            commit()
            current_points = []
            continue
        if len(fields) == 2 and INT_RE.match(fields[0]) and INT_RE.match(fields[1]):
            current_points.append((int(fields[0]), int(fields[1])))
        elif len(fields) == 4 and all(INT_RE.match(field) for field in fields):
            x1, y1, x2, y2 = (int(field) for field in fields)
            current_points.append((x1, y1))
            current_points.append((x2, y2))
    commit()
    return results


def parse_rdb_cells(rdb: Path, rule_names, stdcell_names):
    cells_by_rule = {name: set() for name in rule_names}
    top_hits_by_rule = {name: set() for name in rule_names}
    if not rdb.is_file() or not stdcell_names:
        return cells_by_rule, top_hits_by_rule

    design = os.environ.get("DESIGN_NAME", rdb.name.split(".drc.results")[0])
    top_names = {design, f"merge_{design}"}
    rule_set = set(rule_names)
    current = None
    for line in rdb.read_text(errors="replace").splitlines():
        text = line.strip()
        if text in rule_set:
            current = text
            continue
        if current is None:
            continue
        for token in TOKEN_RE.findall(line):
            if token in stdcell_names:
                cells_by_rule[current].add(token)
            elif token in top_names:
                top_hits_by_rule[current].add(token)
    return cells_by_rule, top_hits_by_rule


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: drc_review.py <summary> <explanation_report>", file=sys.stderr)
        return 2

    summary = Path(sys.argv[1])
    report = Path(sys.argv[2])
    if not summary.is_file():
        print(f"ERROR: missing DRC summary: {summary}", file=sys.stderr)
        return 1

    nonzero, layers = parse_summary(summary)
    mode = os.environ.get("N28_DRC_MODE", "block")
    allowed = ALLOWED_BLOCK_WARNINGS if mode == "block" else {}
    stdcell_names, stdcell_path = load_stdcell_names(summary)
    unexpected_names = [name for name, _ in nonzero if name not in allowed]
    run_dir = summary.parents[2] if len(summary.parents) > 2 else Path(os.environ.get("ROOT_PATH", str(Path(__file__).resolve().parents[2]))) / os.environ.get("DESIGN_NAME", summary.name.split(".drc.summary")[0])
    rdb = run_dir / "results" / "signoff" / summary.name.replace(".summary", ".results")
    if not rdb.is_file():
        rdb = run_dir / "results" / "signoff" / f"{os.environ.get('DESIGN_NAME', summary.name.split('.drc.summary')[0])}.drc.results"
    rdb_cells, rdb_top_hits = parse_rdb_cells(rdb, unexpected_names, stdcell_names)
    stdcell_insts, def_path = load_stdcell_instances(run_dir, stdcell_names)
    rdb_points = parse_rdb_results(rdb, unexpected_names)

    stdcell_internal = {}
    unexpected = []
    for name, count in nonzero:
        if name in allowed:
            continue
        cells = rdb_cells.get(name, set())
        top_hits = rdb_top_hits.get(name, set())
        if mode == "block" and cells and not top_hits:
            stdcell_internal[name] = cells
        elif mode == "block" and stdcell_insts and rdb_points.get(name):
            hits = []
            misses = []
            for x, y in rdb_points[name]:
                hit = point_in_stdcell(x, y, stdcell_insts)
                if hit:
                    hits.append(hit)
                else:
                    misses.append((x, y))
            if hits and not misses:
                stdcell_internal[name] = {ref_name for _, ref_name in hits}
            else:
                unexpected.append((name, count))
        else:
            unexpected.append((name, count))

    report.parent.mkdir(parents=True, exist_ok=True)
    with report.open("w") as fh:
        fh.write(f"N28_DRC_MODE={mode}\n")
        fh.write(f"summary={summary}\n")
        fh.write(f"rdb={rdb}\n")
        if stdcell_path:
            fh.write(f"stdcell_cell_list={stdcell_path}\n")
        if def_path:
            fh.write(f"stdcell_instance_source={def_path}\n")
        fh.write("\nNonzero rulechecks:\n")
        if nonzero:
            for name, count in nonzero:
                if name in allowed:
                    status = "explained"
                elif name in stdcell_internal:
                    status = "stdcell-internal"
                else:
                    status = "unexpected"
                fh.write(f"- {name}: {count} ({status})\n")
        else:
            fh.write("- none\n")

        if stdcell_internal:
            fh.write("\nStandard-cell internal rulechecks:\n")
            fh.write(
                "These rulechecks have RDB coordinate evidence inside DEF-placed "
                "ref LEF standard-cell instances. The flow treats them as "
                "preverified library geometry for block-level PR signoff; "
                "top-level design hits still fail.\n"
            )
            for name, cells in stdcell_internal.items():
                shown = " ".join(sorted(cells)[:20])
                suffix = "" if len(cells) <= 20 else f" ... ({len(cells)} cells)"
                fh.write(f"- {name}: {shown}{suffix}\n")

        fh.write("\nRelevant layer counts:\n")
        for layer in ("APi", "RVi", "DIODMY", "DIODMY_L", "DOD", "SRDOD", "DPO", "SRDPO"):
            fh.write(f"- {layer}: {layers.get(layer, 'not present')}\n")

        if nonzero:
            fh.write("\nExplanations:\n")
            for name, count in nonzero:
                if name in allowed:
                    fh.write(f"- {name}: {allowed[name]}\n")

    if unexpected:
        print(f"ERROR: N28 DRC has unexpected nonzero rulechecks; see {report}", file=sys.stderr)
        for name, count in unexpected:
            print(f"  {name}: {count}", file=sys.stderr)
        return 1

    if nonzero:
        print(f"N28 DRC has only explained block-mode warnings/library-internal results; see {report}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
