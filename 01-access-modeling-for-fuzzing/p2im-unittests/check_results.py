#!/usr/bin/env python3

""" P2IM Test Case Passing Checks
This script checks whether test cases have been passed during fuzzing based
on the groundtruth supplied in a CSV file.

The script takes the following steps:
1. Read in groundtruth CSV to find required basic block coverage for test passing.
2. For each target, check fuzzing code coverage against ground truth
    - For ordered coverage requirements (ground truth entries containing "->"), check full basic block traces
    - For unordered coverage (single-bb coverage requirement), check basic block sets
3. Print the resulting fail / passing numbers
"""

import sys
import os
from fuzzware_harness.util import load_config_deep, parse_symbols
from fuzzware_harness.tracing.serialization import parse_bbl_trace
from fuzzware_pipeline.util.eval_utils import find_traces_covering_all
from fuzzware_pipeline.naming_conventions import trace_paths_for_trace, input_for_trace_path
import subprocess

DIR = os.path.dirname(os.path.realpath(__file__))

NUM_TRACE_ALL = 999999

def parse_groundtruth_csv(file_path):
    entries = []

    with open(file_path, "r") as f:
        prev_elf = None
        first = True
        for l in f.readlines():
            # Skip first
            if first:
                first = False
                continue

            e = l.rstrip().split("\t")
            if not e[0]:
                # print("[*] Taking elf entry from previous")
                e[0] = prev_elf
            prev_elf = e[0]
            if len(e) == 2:
                continue

            entries.append(e)

    return entries

def extract_ordered_bb_lists(bb_text, name_to_addr):
    # First strip whitespaces
    bb_text = bb_text.replace(" ", "")
    if "||" in bb_text:
        bb_texts = bb_text.split("||")
    else:
        bb_texts = [bb_text]

    res = []
    # Check each || - separated entry as a possible success condition
    for bb_text in bb_texts:
        if "->" in bb_text:
            bbs = [int(v, 16) if v.startswith("0x") else name_to_addr[v] for v in bb_text.split("->")]
        else:
            bbs = [int(bb_text, 16) if bb_text.startswith("0x") else name_to_addr[bb_text]]
        res.append(bbs)

    return res


def main(file_path):
    entries = parse_groundtruth_csv(file_path)
    print(entries)

    successes, failures = [], []
    for elf_path, test_type, bb_text, comment in entries:
        print("elf_path:", elf_path)
        elf_name = os.path.basename(elf_path)
        target_dir = os.path.join(DIR, elf_path.split(".")[0])

        config_path = os.path.join(target_dir, "config.yml")
        proj_dir = os.path.join(target_dir, "fuzzware-project")
        print(proj_dir)
        assert(os.path.exists(proj_dir))
        assert(os.path.exists(config_path))
        assert(os.path.exists(target_dir))
        config_map = load_config_deep(config_path)
        name_to_addr, _ = parse_symbols(config_map)

        for bbs in extract_ordered_bb_lists(bb_text, name_to_addr):
            assert(len(bbs) != 0)
            found = False

            print(f"Got ordered basic block candidates: {bbs}")
            if len(bbs) == 1:
                # single one, use bb set
                trace_paths = find_traces_covering_all(proj_dir, bbs, find_num=NUM_TRACE_ALL, only_last_maindir=False)
                if trace_paths:
                    successes.append(elf_name)
                    found = True
                    break
                else:
                    print("[-] Did not find for single-bb")
            else:
                # multiple BBs, check ordered occurrence in full basic block traces
                trace_set_paths = find_traces_covering_all(proj_dir, bbs, find_num=NUM_TRACE_ALL, only_last_maindir=False)

                # look for a trace that booted
                for bbl_set_trace_path in trace_set_paths:
                    bbl_trace_path = trace_paths_for_trace(bbl_set_trace_path)[0]
                    input_path = input_for_trace_path(bbl_set_trace_path)
                    if not os.path.exists(bbl_trace_path):
                        print(f"[*] Needing to generate trace: {bbl_trace_path}")
                        subprocess.check_call(["fuzzware", "replay", input_path, "--bb-trace-out", bbl_trace_path])

                    # Follow along the trace and find each bb ordered by "->" consecutively in this trace
                    cnt=0
                    for _, pc, _ in parse_bbl_trace(bbl_trace_path):
                        if pc == bbs[cnt]:
                            cnt += 1
                            if cnt == len(bbs):
                                successes.append(elf_name)
                                print(f"Got {len(trace_set_paths)} traces")
                                found = True
                                break
                    if cnt == len(bbs):
                        break
            if found:
                break

        if not found:
            print(f"Failed {elf_path}")
            failures.append((elf_name, test_type))

    print(f"Got {len(successes)} successes and {len(failures)} failures")

    if failures:
        print("Failures: ", failures)

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print(f"Usage {sys.argv[0]} <csv_results_file_path>.csv")
        exit(0)

    file_path = sys.argv[1]
    if os.path.exists(file_path):
        main(file_path)
    else:
        print("[-] File does not exist")
