#!/usr/bin/env python3
"""
split_partitions.py

Splits an alignment in PHYLIP format (sequential, strict, 10-character taxon
names) into N partitions, based on the coordinates defined in a NEXUS
"charsets" file (`sets` block), and writes all partitions to a single output
PHYLIP file (one block per partition, each with its own "ntax nchar" header).

Usage:
    python split_partitions.py aln_10P.phy aln_10P_partitions.nex aln_10P_split.phy

Expected input format:
  - Strict/sequential PHYLIP: first line "ntax nchar", then one line per
    taxon with the first 10 characters reserved for the name (space-padded)
    followed by the full sequence, with no internal line breaks.
  - NEXUS with a `sets` block containing lines such as:
        charset part1 = 1-2870;
    (1-based, inclusive coordinates, as in NEXUS/RAxML).

Output format:
  - A single PHYLIP file containing, for each partition, an "ntax nchar"
    header followed by the sequences of all taxa trimmed to that column
    range, with a blank line separating the blocks.
"""

import re
import sys
from pathlib import Path


def parse_phylip(path):
    """Reads a strict sequential PHYLIP file (10-character names, 1 line/taxon).

    Returns (ntax, nchar, list_of_tuples(name, sequence)) preserving the
    original taxon order.
    """
    with open(path, "r") as fh:
        lines = [l.rstrip("\n") for l in fh if l.strip() != ""]

    header = lines[0].split()
    ntax, nchar = int(header[0]), int(header[1])

    records = []
    for line in lines[1:1 + ntax]:
        name = line[:10].strip()
        seq = line[10:].strip()
        if len(seq) != nchar:
            raise ValueError(
                f"Taxon '{name}': expected {nchar} columns, found {len(seq)}. "
                "Check that the PHYLIP file is strict (10-character names) and sequential "
                "(entire sequence on a single line)."
            )
        records.append((name, seq))

    if len(records) != ntax:
        raise ValueError(
            f"Expected {ntax} taxa according to the header, but {len(records)} sequence lines were read."
        )

    return ntax, nchar, records


def parse_nexus_charsets(path):
    """Extracts the charsets from the `sets` block of a NEXUS file.

    Supports charsets with a single contiguous range, e.g.:
        charset part1 = 1-2870;
    Returns a list of tuples (partition_name, start_1based, end_1based),
    in the order in which they appear in the file.
    """
    text = Path(path).read_text()

    pattern = re.compile(
        r"charset\s+(\S+)\s*=\s*([\d\s\-]+?)\s*;",
        re.IGNORECASE,
    )

    charsets = []
    for match in pattern.finditer(text):
        name = match.group(1)
        coords = match.group(2).split()
        if len(coords) != 1 or "-" not in coords[0]:
            raise ValueError(
                f"Charset '{name}' has unsupported coordinates: '{match.group(2)}'. "
                "This script assumes a single contiguous range per partition (e.g., 1-2870)."
            )
        start_str, end_str = coords[0].split("-")
        start, end = int(start_str), int(end_str)
        charsets.append((name, start, end))

    if not charsets:
        raise ValueError(f"No 'charset' found in {path} ('sets' block).")

    return charsets


def write_combined_phylip(records, charsets, nchar, out_path):
    """Writes all partitions to a single PHYLIP file, one block per
    partition, each with its own 'ntax partition_nchar' header.
    """
    ntax = len(records)

    with open(out_path, "w") as out:
        for i, (name, start, end) in enumerate(charsets):
            if start < 1 or end > nchar or start > end:
                raise ValueError(
                    f"Charset '{name}' ({start}-{end}) is out of the alignment bounds "
                    f"(1-{nchar})."
                )
            part_len = end - start + 1

            out.write(f"{ntax} {part_len}\n")
            for taxon_name, seq in records:
                # NEXUS coordinates are 1-based and inclusive -> Python slice
                sub_seq = seq[start - 1:end]
                padded_name = f"{taxon_name:<10}"
                out.write(f"{padded_name} {sub_seq}\n")

            # blank line between blocks (except after the last one)
            if i < len(charsets) - 1:
                out.write("\n")

    return ntax


def main():
    if len(sys.argv) != 4:
        print(
            "Usage: python split_partitions.py <alignment.phy> <partitions.nex> <output.phy>",
            file=sys.stderr,
        )
        sys.exit(1)

    phy_path, nex_path, out_path = sys.argv[1], sys.argv[2], sys.argv[3]

    print(f"Reading PHYLIP alignment: {phy_path}")
    ntax, nchar, records = parse_phylip(phy_path)
    print(f"  -> {ntax} taxa, {nchar} columns")

    print(f"Reading NEXUS partitions: {nex_path}")
    charsets = parse_nexus_charsets(nex_path)
    print(f"  -> {len(charsets)} partitions found:")
    total = 0
    for name, start, end in charsets:
        length = end - start + 1
        total += length
        print(f"     {name}: {start}-{end} ({length} columns)")

    if total != nchar:
        print(
            f"WARNING: sum of partitions ({total}) differs from the total number of "
            f"alignment columns ({nchar}).",
            file=sys.stderr,
        )

    print(f"Writing combined file: {out_path}")
    write_combined_phylip(records, charsets, nchar, out_path)
    print("Done.")


if __name__ == "__main__":
    main()
