"""Dataset D - Zenodo 10.5281/zenodo.10637534 (Kirkaldy et al. 2024, J. Power Sources 603, 234185; CC BY 4.0).

The record is ~49 GB (five ZIPs of 6.5-12 GB). Nothing big is downloaded: the ZIP central directories are
read by HTTP Range requests and only the small summary CSVs are extracted
   <Expt>/Summary Data/Performance Summary/<Expt> - cell X (TTdegC) - Processed Data.csv
   <Expt>/Summary Data/Ageing Sets Summary/Summary per Set/expt N - cell X - set_data.csv
plus experiment_metadata.xlsx (22 kB).

Produces (data/derived/):
  D_kirkaldy_per_cell_rpt.csv   one row per cell and RPT: capacity, 0.1 s resistance, SOH, LLI, LAM_PE, LAM_NE,
                                throughput, cycles, temperature (all five experiments / SOC windows)
  D_kirkaldy_ageing_sets.csv    per cell and ageing set: av/max/min cell temperature and voltage, throughput
  D_kirkaldy_summary.csv        per SOC window and temperature: fade and degradation modes (mean/min/max over cells)
  D_kirkaldy_cells.csv          experiment_metadata.xlsx as one table
  D_archive_dirs.csv            number of files and bytes per directory of each ZIP (what the 49 GB consist of)
  D_checks.json                 bytes fetched, cross-check against the copy shipped in Li 2025 (dataset C)

Usage: python d_kirkaldy_summary.py [--cache DIR]
"""
import json
import os
import re
import sys

import numpy as np
import pandas as pd

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # works with python -I
import common  # noqa: E402

RECORD = 10637534
ZIPS = ["Expt 1 - Si-based Degradation.zip", "Expt 2,2 - C-based Degradation 2.zip",
        "Expt 3 - Cathode Degradation and Li-Plating.zip", "Expt 4 - Drive Cycle Aging (Control).zip",
        "Expt 5 - Standard Cycle Aging (Control).zip"]
SOC_WINDOW = {"1": "0-30", "2,2": "70-85", "3": "85-100", "4": "0-100 (drive cycle)", "5": "0-100"}
REN = {"Ageing Sets": "ageing_set", "Ageing Cycles": "ageing_cycles", "Days of degradation": "days",
       "Age set av. temperature [°C]": "T_ageing_avg_degC", "Charge Throughput [A h]": "charge_throughput_Ah",
       "Energy Throughput [W h]": "energy_throughput_Wh", "C/10 Capacity [mA h]": "cap_C10_mAh",
       "C/2 Capacity [mA h]": "cap_C2_mAh", "0.1s Resistance [Ohms]": "R_0p1s_Ohm",
       "Cell Capacity [mA h]": "cell_cap_dma_mAh", "PE Capacity [mA h]": "PE_cap_mAh", "NE Capacity [mA h]": "NE_tot_cap_mAh",
       "NE_Gr Capacity [mA h]": "NE_Gr_cap_mAh", "NE_Si Capacity [mA h]": "NE_Si_cap_mAh",
       "Electrode Offset [mA h]": "offset_mAh", "SoH": "SOH_dma", "LAM PE": "LAM_PE", "LAM NE_tot": "LAM_NE_tot",
       "LAM NE_Gr": "LAM_NE_Gr", "LAM NE_Si": "LAM_NE_Si", "RMSE of OCV-fitting [V]": "ocv_fit_rmse_V"}
REN_SET = {"Age Set": "ageing_set", "Charge Throughput [A h]": "charge_throughput_set_Ah",
           "Energy Throughput [W h]": "energy_throughput_set_Wh", "Start Dates": "start_date", "End Dates": "end_date",
           "Av. Temperature [°C]": "T_avg_degC", "Max. Temperature [°C]": "T_max_degC", "Min. Temperature [°C]": "T_min_degC",
           "Av. Voltage [V]": "V_avg", "Max. Voltage [V]": "V_max", "Min. Voltage [V]": "V_min",
           "Av. Voltage Range [V]": "V_range_avg", "Cumulative Charge Throughput [A h]": "charge_throughput_cum_Ah",
           "Cumulative Energy Throughput [W h]": "energy_throughput_cum_Wh"}


def want(n):
    return "/Performance Summary/" in n or "/Summary per Set/" in n


def main():
    cache = common.cache_dir()
    D = common.DERIVED
    checks = {"zips": {}}
    meta_path = common.zenodo_file(RECORD, "experiment_metadata.xlsx", cache)
    M = pd.concat(pd.read_excel(meta_path, sheet_name=None).values(), ignore_index=True)
    M["Expt"] = M["Expt"].astype(str)
    M.to_csv(os.path.join(D, "D_kirkaldy_cells.csv"), index=False)

    rpt, sets, dirs = [], [], []
    for z in ZIPS:
        tag = z[:8].strip().replace(",", "_").replace(" ", "_")
        lst = os.path.join(cache, str(RECORD), "listing_%s.tsv" % tag)
        got = common.fetch_members(common.zenodo_url(RECORD, z), want, os.path.join(cache, str(RECORD), tag), listing_path=lst)
        if not os.path.exists(lst):
            zf, _ = common.remote_zip(common.zenodo_url(RECORD, z))
            common.write_listing(zf, lst)
        checks["zips"][z] = {"members_fetched": len(got), "bytes_fetched_members": int(sum(os.path.getsize(p) for _, p in got))}
        if os.path.exists(lst):
            Ls = pd.read_csv(lst, sep="\t")
            Ls = Ls[~Ls["name"].str.endswith("/")]
            Ls["dir"] = Ls["name"].str.rsplit("/", n=1).str[0]
            g = Ls.groupby("dir").agg(n_files=("name", "size"), bytes=("size_bytes", "sum")).reset_index()
            g.insert(0, "zip", z)
            dirs.append(g)
            checks["zips"][z]["total_uncompressed_bytes"] = int(Ls["size_bytes"].sum())
        for n, p in got:
            m = re.search(r"Expt ([\d,]+) - cell (\w) \((\d+)degC\) - Processed Data\.csv$", n)
            if m:
                df = pd.read_csv(p).rename(columns=REN)
                df = df.drop(columns=[c for c in df.columns if "date" in c])
                df.insert(0, "rpt", np.arange(len(df)))
                df.insert(0, "cell", m.group(2))
                df.insert(0, "T_nominal_degC", int(m.group(3)))
                df.insert(0, "soc_window_pct", SOC_WINDOW[m.group(1)])
                df.insert(0, "expt", m.group(1))
                df["SOH_C10"] = df["cap_C10_mAh"] / df["cap_C10_mAh"].iloc[0]
                df["source_file"] = z + "::" + n
                rpt.append(df)
                continue
            m = re.search(r"expt ([\d,]+) - cell (\w) - set_data\.csv$", n)
            if m:
                df = pd.read_csv(p).rename(columns=REN_SET)
                df.insert(0, "cell", m.group(2))
                df.insert(0, "expt", m.group(1))
                sets.append(df)
    X = pd.concat(rpt, ignore_index=True)
    X.to_csv(os.path.join(D, "D_kirkaldy_per_cell_rpt.csv"), index=False, float_format="%.7g")
    Sset = pd.concat(sets, ignore_index=True)
    Sset = Sset.merge(X[["expt", "cell", "T_nominal_degC", "soc_window_pct"]].drop_duplicates(), on=["expt", "cell"], how="left")
    Sset.to_csv(os.path.join(D, "D_kirkaldy_ageing_sets.csv"), index=False, float_format="%.6g")
    if dirs:
        pd.concat(dirs, ignore_index=True).to_csv(os.path.join(D, "D_archive_dirs.csv"), index=False)

    rows = []
    for (ex, T), g in X.groupby(["expt", "T_nominal_degC"]):
        def at(col):
            gg = g.dropna(subset=[col])
            qc = gg.groupby("cell")["charge_throughput_Ah"].max().min()
            v = [np.interp(qc, c.sort_values("charge_throughput_Ah")["charge_throughput_Ah"],
                           c.sort_values("charge_throughput_Ah")[col]) for _, c in gg.groupby("cell")]
            return float(np.mean(v)), float(np.min(v)), float(np.max(v)), float(qc)
        ss = Sset[(Sset["expt"] == ex) & (Sset["T_nominal_degC"] == T)]
        r = {"expt": ex, "soc_window_pct": SOC_WINDOW[ex], "T_nominal_degC": T,
             "cells": "|".join(sorted(g["cell"].unique())), "n_cells": g["cell"].nunique(),
             "n_rpt_max": int(g["rpt"].max()) + 1,
             "cycles_per_ageing_set": float(g[g["rpt"] == 1]["ageing_cycles"].median()),
             "T_cell_avg_during_ageing_degC": float(ss["T_avg_degC"].mean()),
             "T_cell_max_during_ageing_degC": float(ss["T_max_degC"].max()),
             "V_min_during_ageing": float(ss["V_min"].min()), "V_max_during_ageing": float(ss["V_max"].max()),
             "cap_C10_mAh_BOL_mean": float(g[g["rpt"] == 0]["cap_C10_mAh"].mean()),
             "R_0p1s_mOhm_BOL_mean": float(g[g["rpt"] == 0]["R_0p1s_Ohm"].mean() * 1000)}
        for col, nm, sc in (("SOH_C10", "SOH_pct", 100), ("LLI", "LLI_pct", 100), ("LAM_NE_tot", "LAM_NE_tot_pct", 100),
                            ("LAM_NE_Gr", "LAM_NE_Gr_pct", 100), ("LAM_NE_Si", "LAM_NE_Si_pct", 100),
                            ("LAM_PE", "LAM_PE_pct", 100), ("R_0p1s_Ohm", "R_0p1s_mOhm", 1000)):
            a = at(col)
            if nm == "SOH_pct":
                r["common_throughput_Ah"] = a[3]
            if nm.startswith("R_"):
                r["R_common_throughput_Ah"] = a[3]
            r[nm + "_at_common_mean"], r[nm + "_at_common_min"], r[nm + "_at_common_max"] = a[0] * sc, a[1] * sc, a[2] * sc
        q = r["common_throughput_Ah"] / 1000.0
        r["SOH_loss_pct_per_kAh"] = (100 - r["SOH_pct_at_common_mean"]) / q
        r["LLI_pct_per_kAh"] = r["LLI_pct_at_common_mean"] / q
        r["LAM_NE_tot_pct_per_kAh"] = r["LAM_NE_tot_pct_at_common_mean"] / q
        r["LAM_PE_pct_per_kAh"] = r["LAM_PE_pct_at_common_mean"] / q
        # same throughput for every window/temperature would be nicer for comparison: interpolate at 6 kAh if reached
        for qq in (3000.0, 6000.0):
            for col, nm in (("SOH_C10", "SOH_pct"), ("LLI", "LLI_pct"), ("LAM_NE_tot", "LAM_NE_tot_pct"), ("LAM_PE", "LAM_PE_pct")):
                v = [np.interp(qq, c.sort_values("charge_throughput_Ah")["charge_throughput_Ah"],
                               c.sort_values("charge_throughput_Ah")[col]) * 100
                     for _, c in g.dropna(subset=[col]).groupby("cell") if c["charge_throughput_Ah"].max() >= qq]
                r["%s_at_%dkAh_mean" % (nm, qq / 1000)] = float(np.mean(v)) if v else np.nan
                r["%s_at_%dkAh_n_cells" % (nm, qq / 1000)] = len(v)
        rows.append(r)
    Sm = pd.DataFrame(rows)
    Sm.to_csv(os.path.join(D, "D_kirkaldy_summary.csv"), index=False, float_format="%.5g")

    # cross-check with the copy of the same data shipped inside Li 2025's archive (dataset C)
    cpath = os.path.join(D, "C_experiment_per_cell_rpt.csv")
    if os.path.exists(cpath):
        C = pd.read_csv(cpath, dtype={"expt": str})
        mrg = X.merge(C, on=["expt", "cell", "rpt"], suffixes=("_K", "_Li"))
        cc = {"rows_kirkaldy": int(len(X)), "rows_li_copy": int(len(C)), "rows_matched": int(len(mrg))}
        for col in ("charge_throughput_Ah", "cap_C10_mAh", "R_0p1s_Ohm", "SOH_dma", "LLI", "LAM_NE_tot", "LAM_PE"):
            d = (mrg[col + "_K"] - mrg[col + "_Li"]).abs()
            cc["max_abs_diff_" + col] = float(d.max())
            cc["n_only_one_side_has_value_" + col] = int((mrg[col + "_K"].isna() != mrg[col + "_Li"].isna()).sum())
        mrg["dq"] = mrg["charge_throughput_Ah_Li"] - mrg["charge_throughput_Ah_K"]
        cc["throughput_Li_minus_Kirkaldy_Ah_by_expt_min_max"] = {
            k: [float(v["dq"].min()), float(v["dq"].max())] for k, v in mrg.groupby("expt")}
        checks["cross_check_vs_Li2025_copy"] = cc
    with open(os.path.join(D, "D_checks.json"), "w") as f:
        json.dump(checks, f, indent=1)
    pd.set_option("display.width", 250)
    print(Sm[["expt", "soc_window_pct", "T_nominal_degC", "n_cells", "T_cell_avg_during_ageing_degC", "common_throughput_Ah",
              "SOH_pct_at_common_mean", "LLI_pct_at_common_mean", "LAM_NE_tot_pct_at_common_mean", "LAM_PE_pct_at_common_mean",
              "SOH_pct_at_6kAh_mean", "LLI_pct_at_6kAh_mean", "LAM_NE_tot_pct_at_6kAh_mean", "LAM_PE_pct_at_6kAh_mean",
              "R_0p1s_mOhm_BOL_mean", "R_0p1s_mOhm_at_common_mean"]].round(2).to_string())
    print(json.dumps(checks, indent=1))


if __name__ == "__main__":
    main()
