#!/usr/bin/env python3
import os
import glob
import shutil
import subprocess

try:
    from fuzzware_pipeline import naming_conventions as nc
    from fuzzware_pipeline.util.eval_utils import parse_coverage_by_second_file
except ImportError as e:
    print(e)
    print("Could not import pipeline. Workon fuzzware?")
    exit(1)

DIR = os.path.dirname(os.path.realpath(__file__))
target_names = [
    "P2IM/CNC", "P2IM/Drone", "P2IM/Heat_Press", "P2IM/Reflow_Oven", "P2IM/Soldering_Iron", "P2IM/Console", "P2IM/Gateway", "P2IM/PLC", "P2IM/Robot", "P2IM/Steering_Control",
    "uEmu/6LoWPAN_Receiver", "uEmu/6LoWPAN_Sender", "uEmu/RF_Door_Lock", "uEmu/Thermostat", "uEmu/uEmu.3Dprinter", "uEmu/uEmu.GPSTracker", "uEmu/LiteOS_IoT", "uEmu/utasker_MODBUS", "uEmu/utasker_USB", "uEmu/Zepyhr_SocketCan", "uEmu/XML_Parser"
]

"""
Here we aggregate the coverage between experiments (Table 5 in the paper).
"""
print("=== Coverage min/max/avg/totals (paper Table 5) ===")

for target_name in target_names:
    num_projects = 0
    overall_covered_bb_set = set()
    min_bbs_individual_run, max_bbs_individual_run = 100000000, 0
    sum_bbs_covered = 0

    projdirs = glob.glob(os.path.join(DIR, target_name, "fuzzware-project*-run-[0-9][0-9]"))
    if not projdirs:
        print(f"\n[WARNING] Could not find any project directories for target '{target_name}'")
        continue

    for projdir in projdirs:
        if "_old" in projdir:
            continue
        cov_over_time_path = os.path.join(projdir, nc.PIPELINE_DIRNAME_STATS, nc.STATS_FILENAME_COVERAGE_OVER_TIME)
        if not os.path.exists(cov_over_time_path):
            print(f"\n[WARNING] Coverage over time metrics file does not exist for target '{target_name}', project {os.path.basename(projdir)}. The run was probably interrupted or results pulled prematurely. Skipping...")
            continue

        run_covered_bb_set = set()
        num_projects += 1
        entries = parse_coverage_by_second_file(cov_over_time_path)
        for seconds_into_experiment, num_bbs_total, new_bbs_since_last in entries:
            run_covered_bb_set |= set(new_bbs_since_last)

        run_num_bbs_covered = len(run_covered_bb_set)
        sum_bbs_covered += run_num_bbs_covered
        max_bbs_individual_run = max(run_num_bbs_covered, max_bbs_individual_run)
        min_bbs_individual_run = min(run_num_bbs_covered, min_bbs_individual_run)

        overall_covered_bb_set |= run_covered_bb_set
    
    if num_projects == 0:
        print(f"\nTarget {target_name} ---- Found only incomplete / interrupted runs ----")
    else:
        avg_bbs_individual_run = round(sum_bbs_covered / num_projects)

        print(f"\nTarget {target_name}: #BB min: {min_bbs_individual_run}, #BB avg: {avg_bbs_individual_run}, #BB max: {max_bbs_individual_run}, #BB total: {len(overall_covered_bb_set)}")

print("===================================\n")

print("=== Coverage Plots (paper Figure 5) ===")
"""
For the coverage plots, the 
"""
plots_dir = os.path.join(DIR, "plots")
if os.path.exists(plots_dir):
    shutil.rmtree(plots_dir)
os.mkdir(plots_dir)

for target_name in target_names:
    projdirs = glob.glob(os.path.join(DIR, target_name, "fuzzware-project*-run-[0-9][0-9]"))
    plot_data_paths = []

    if not projdirs:
        print(f"\n[WARNING] Could not find any project directories for target '{target_name}'")
        continue

    for projdir in sorted(projdirs):
        if "_old" in projdir:
            continue
        cov_over_time_path = os.path.join(projdir, nc.PIPELINE_DIRNAME_STATS, nc.STATS_FILENAME_COVERAGE_OVER_TIME)
        if not os.path.exists(cov_over_time_path):
            print(f"\n[WARNING] Coverage over time metrics file does not exist for target '{target_name}', project {os.path.basename(projdir)}. The run was probably interrupted. Skipping...")
            continue
        entries = parse_coverage_by_second_file(cov_over_time_path)

        gnuplot_lines = []
        for seconds_into_experiment, num_bbs_total, new_bbs_since_last in entries:
            gnuplot_lines.append(f"{seconds_into_experiment/3600:.08f} {num_bbs_total}")

        plot_data_path = os.path.join(plots_dir, target_name.replace("/", "_") + "_" + os.path.basename(projdir) + ".dat")
        print(f"\nWriting gnuplot coverage data to: {plot_data_path}")
        with open(plot_data_path, "w") as f:
            f.write("\n".join(gnuplot_lines))
        plot_data_paths.append(plot_data_path)

    if not plot_data_paths:
        print(f"\nTarget {target_name} ---- Found only incomplete / interrupted runs ----")
        continue

    gnuplot_png_outpath = os.path.join(plots_dir, "plot" + target_name.replace("/", "_") + ".png")
    gnuplot_code = f"set terminal png; set output '{gnuplot_png_outpath}'; set title 'Coverage {target_name}'; set ylabel '#BBs Found(bbs)'; set xlabel 'Time(h)';"
    gnuplot_code += "set xrange [0:24] noextend; set xtics 0,4,24; "
    gnuplot_code += "plot "

    for i, p in enumerate(plot_data_paths):
        if i != 0:
            gnuplot_code += ", "
        gnuplot_code += f"'{p}' with lines notitle"
    gnuplot_code += ";"

    try:
        output = subprocess.check_output(["gnuplot", "-e", gnuplot_code])
    except subprocess.CalledProcessError as e:
        print(f"[ERROR] Got gnuplot error.")
    else:
        print(f"Output coverage plot png to {gnuplot_png_outpath}")

print("======================\n")
