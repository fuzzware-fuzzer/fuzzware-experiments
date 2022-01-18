#!/usr/bin/env python3
import os
import glob

try:
    from fuzzware_pipeline import naming_conventions as nc
    from fuzzware_pipeline.util.eval_utils import load_job_timing_summary, load_mmio_overhead_elimination_map, merge_mmio_overhead_elimination_maps, describe_mmio_overhead_elimination_map, load_milestone_discovery_timings
    from fuzzware_pipeline.workers.pool import MMIO_MODELING_INCLUDE_PATH
    from fuzzware_pipeline.util.config import load_config_shallow, get_modeled_mmio_contexts
except ImportError as e:
    print(e)
    print("Could not import pipeline. Workon fuzzware?")
    exit(1)

DIR = os.path.dirname(os.path.realpath(__file__))
target_names = ['ARCH_PRO', 'EFM32GG_STK3700', 'EFM32LG_STK3600', 'LPC1549', 'LPC1768', 'MOTE_L152RC', 'NUCLEO_F103RB', 'NUCLEO_F207ZG', 'NUCLEO_L152RE', 'UBLOX_C027']

# 1. Costs of Model Generation
"""
Here we aggregate the time spent modeling over all runs from the statistics (Paragraph "Costs of Model Generation" in the paper).
"""
num_projects, num_models_total = 0, 0
num_jobs_total, seconds_spent_total = 0, 0
for target_name in target_names:
    projdirs = glob.glob(os.path.join(DIR, target_name, "fuzzware-project*-run-[0-9][0-9]"))
    if not projdirs:
        print(f"[WARNING] Could not find any project directories for target '{target_name}'")
        continue

    for projdir in projdirs:
        if "_old" in projdir or "no-modeling" in projdir:
            continue

        num_projects += 1
        timing_summary_path = os.path.join(projdir, nc.PIPELINE_DIRNAME_STATS, nc.STATS_FILENAME_JOB_TIMING_SUMMARY)
        if not os.path.exists(timing_summary_path):
            print(f"[WARNING] Could not find job timing summary file '{timing_summary_path}' in project directory '{projdir}'. The fuzzing running probably has not concluded, yet, was interrupted, or genstats has not been run, yet. Skipping...")
            continue
        number_and_duration_per_jobtype = load_job_timing_summary(timing_summary_path)
        num_jobs, seconds_spent = number_and_duration_per_jobtype.get(MMIO_MODELING_INCLUDE_PATH, (0, 0))
        num_jobs_total += num_jobs
        seconds_spent_total += seconds_spent

        mmio_config = load_config_shallow(os.path.join(projdir, nc.PIPELINE_FILENAME_MMIO_MODEL_CFG))
        num_models_total += len(get_modeled_mmio_contexts(mmio_config))
avg_num_models = num_models_total / num_projects
avg_time_per_project = seconds_spent_total / num_projects
avg_time_per_model = round(seconds_spent_total / num_models_total if num_models_total != 0 else 0, 2)

print("\n=== Costs of Model Generation (Paper: Paragraph in Section 6.1) ===")

print(f"Total number of projects: {num_projects}.\nNumber of models total: {num_models_total}.\nAverage number of models per fuzzing run: {avg_num_models}")
print(f"Total time spent modeling: {seconds_spent_total}\nAverage modeling time per fuzzing run: {avg_time_per_project} seconds.\nAverage modeling time per model: {avg_time_per_model} seconds.")

print("=================================\n")

# 2. Input Overhead Elimination
"""
Here we collect and merge all MMIO overhead statistics yaml files per target and output them in an aggregated form (Table 2 rows in the paper).

We then also output the aggregation over all targets+runs as a separate "Total" output (last row of Table 2 in the paper).
"""

print("=== Input Overhead Elimination (Paper: Table 2)===")

aggregated_mmio_elim_maps = []
for target_name in target_names:
    projdirs = glob.glob(os.path.join(DIR, target_name, "fuzzware-project*-run-[0-9][0-9]"))
    if not projdirs:
        print(f"[WARNING] Could not find any project directories for target '{target_name}'")
        continue

    elim_maps = []
    for projdir in projdirs:
        if "_old" in projdir or "no-modeling" in projdir:
            continue

        overhead_elim_path = os.path.join(projdir, nc.PIPELINE_DIRNAME_STATS, nc.STATS_FILENAME_MMIO_OVERHEAD_ELIM)
        if not os.path.exists(overhead_elim_path):
            print(f"[WARNING] Could not find overhead elimination summary file {overhead_elim_path} in project directory '{projdir}'. The fuzzing running probably has not concluded, yet, was interrupted, or genstats has not been run, yet. Skipping...")
            continue
        elim_map = load_mmio_overhead_elimination_map(overhead_elim_path)
        elim_maps.append(elim_map)

    aggregated_mmio_elim_map = merge_mmio_overhead_elimination_maps(elim_maps)
    if aggregated_mmio_elim_map:
        print("\n" + describe_mmio_overhead_elimination_map(target_name, aggregated_mmio_elim_map))
        aggregated_mmio_elim_maps.append(aggregated_mmio_elim_map)

total_elim_map = merge_mmio_overhead_elimination_maps(aggregated_mmio_elim_maps)
print("\n" + describe_mmio_overhead_elimination_map("Total", total_elim_map))
print("==================================\n")

# 3. Password Discovery Timings
"""
Here we collect and print out all password character discovery timings per run.

This represents the data in Figure 6 (in the appendix) in the paper.
"""
print("=== Password Discovery Timings (Paper: Figure 6) ===")

for target_name in target_names:
    projdirs = glob.glob(os.path.join(DIR, target_name, "fuzzware-project*-run-[0-9][0-9]"))
    if not projdirs:
        print(f"\n[WARNING] Could not find any project directories for target '{target_name}'")
        continue

    discovery_timing_lists_modeling = []
    discovery_timing_lists_no_modeling = []
    for projdir in projdirs:
        if "_old" in projdir:
            continue
        if "no-modeling" in projdir:
            l = discovery_timing_lists_no_modeling
        else:
            l = discovery_timing_lists_modeling

        milestone_discovery_path = os.path.join(projdir, nc.PIPELINE_DIRNAME_STATS, nc.STATS_FILENAME_MILESTONE_DISCOVERY_TIMINGS)
        if not os.path.exists(milestone_discovery_path):
            print(f"[WARNING] Could not find password discovery timings file '{milestone_discovery_path}' in project directory '{projdir}'. The fuzzing running probably has not concluded, yet, was interrupted, or genstats has not been run, yet. Skipping...")
            continue

        char_discovery_timings = load_milestone_discovery_timings(milestone_discovery_path)
        l.append(char_discovery_timings)


    print(f"\n= Discovery timings per character for target {target_name} (modeling) =")
    for i, seconds_to_discovery in enumerate(zip(*discovery_timing_lists_modeling)):
        print(f"Character {i+1:2d}: {' '.join([f'{s:d}' for s in seconds_to_discovery])}")

    print(f"\n= Discovery timings per character for target {target_name} (no modeling) =")
    for i, seconds_to_discovery in enumerate(zip(*discovery_timing_lists_no_modeling)):
        print(f"Character {i+1:2d}: {' '.join([f'{s:d}' for s in seconds_to_discovery])}")

print("==================================\n")