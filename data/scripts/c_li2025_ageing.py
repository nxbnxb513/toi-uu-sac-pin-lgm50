"""Dataset C - Zenodo 10.5281/zenodo.14995785 (Li et al. 2025, Nat. Commun., CC BY 4.0).

Fetches Source_Data.zip (10.8 MB, whole) and - by HTTP Range requests, without downloading the
835 MB archive - only the small per-cell CSV summaries inside
"Experiment Data, long simulation data and saved figures in the paper.zip".

Produces (data/derived/):
  C_experiment_per_cell_rpt.csv   experiment: one row per cell and RPT, Expt 1,2,3,4,5 (capacity, SOH,
                                  0.1 s resistance, LLI, LAM_PE, LAM_NE, throughput, cycles, temperature)
  C_experiment_summary.csv        per experiment / temperature: end-of-test and per-kAh numbers (mean over cells)
  C_fig_ageing_long.csv           source data of Fig. 3, 4, 6 and Suppl. Fig. 7: experiment AND the three models
                                  (SEI only, SEI + Dry out, 5 coupled) vs charge throughput
  C_fig_small_tables_long.csv     small source tables (Suppl. Fig. 2, 3, 5, 6, 13, 15) as long table
  C_model_input_cases.csv         parameter sets of the 27 "Full_Exp23_Paper_11_fine" cases + error summary
  C_li_dUdT_curves.csv            dU/dT curves plotted in Suppl. Fig. 10 c,d (every 10th point) + (S5),(S6)
  C_checks.json                   panel -> (experiment, temperature, cell) matching, dU/dT unit check
  C_archive_listing.tsv           full file list of the 835 MB archive (name, size)

Usage: python c_li2025_ageing.py [--cache DIR]
"""
import io
import json
import os
import re
import sys
import zipfile

import numpy as np
import pandas as pd

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # works with python -I
import common  # noqa: E402

RECORD = 14995785
BIG = "Experiment Data, long simulation data and saved figures in the paper.zip"
SOC_WINDOW = {"1": "0-30", "2,2": "70-85", "3": "85-100", "4": "0-100 (drive cycle)", "5": "0-100"}


def want(n):
    if "/InputData/Expt " in n:
        return n.endswith("Extracted Data.csv") or "/DMA Output/" in n
    if re.search(r"/InputData/(Full|SEI|SEI_Dry)_Exp(23_Paper_11_fine|1235_NC)/", n):
        return True
    if "/Save_LongRun/" in n:
        return bool(re.search(r"/Save_LongRun/[^/]+/Summary of [^/]+\.xlsx$", n))
    return False


def li_S5(x):
    return 0.04006 * np.exp(-(x - 0.2828) ** 2 / 0.0009855) - 0.06656 * np.exp(-(x - 0.8032) ** 2 / 0.02179)


def li_S6(x):
    return -0.111 * x + 0.02901 + 0.3562 * np.exp(-(x - 0.08308) ** 2 / 0.004621)


def series_of(h):
    s = h.replace("_", " ")
    m = re.search(r"exp ([A-Z])\b", s)
    if m:
        return "exp_cell_" + m.group(1)
    if re.search(r"Sample ?1", s):
        return "exp_sample1"
    if re.search(r"Sample ?2", s):
        return "exp_sample2"
    if re.search(r"avg", s, re.I):
        return "exp_avg"
    if "Dry" in s:
        return "model_SEI_dry_out"
    if "SEI only" in s:
        return "model_SEI_only"
    if "5 coupled" in s or "5couple" in s:
        return "model_5_coupled"
    return None


def quantity_of(h):
    s = h.replace("_", " ")
    if re.search(r"SoH", s, re.I):
        return "SOH_pct"
    if "Resistance" in s:
        return "R_0p1s_mOhm"
    if "Res midSOC" in s:
        return "R_midSOC_model_mOhm"
    if "LLI" in s:
        return "LLI_pct"
    if re.search(r"LAM NE", s):
        return "LAM_NE_tot_pct"
    if re.search(r"LAM PE", s):
        return "LAM_PE_pct"
    return None


def main():
    cache = common.cache_dir()
    D = common.DERIVED
    src = common.zenodo_file(RECORD, "Source_Data.zip", cache)
    listing = os.path.join(D, "C_archive_listing.tsv")
    got = common.fetch_members(common.zenodo_url(RECORD, BIG), want,
                               os.path.join(cache, str(RECORD), "big_members"), listing_path=listing)
    got = [(n, p) for n, p in got if want(n)]
    if not os.path.exists(listing):
        zf_remote, _ = common.remote_zip(common.zenodo_url(RECORD, BIG))
        common.write_listing(zf_remote, listing)
    checks = {"n_members_fetched_from_big_zip": len(got),
              "bytes_fetched_members": int(sum(os.path.getsize(p) for _, p in got))}

    # ---------------- experiment per cell / RPT
    by = {}
    for n, p in got:
        m = re.search(r"InputData/Expt ([\d,]+) - [^/]+/(?:DMA Output/cell (\w)/)?Expt [\d,]+ - (.*)\.csv$", n)
        if not m:
            continue
        ex, rest = m.group(1), m.group(3)
        if "Extracted Data" in rest:
            mm = re.match(r"cell (\w) \((\d+)degC\) - Extracted Data", rest)
            by.setdefault((ex, mm.group(1)), {})["extracted"] = (n, p)
            by[(ex, mm.group(1))]["T"] = int(mm.group(2))
        else:
            kind = [k for k in ("Capacity and offset", "DM data", "fitting parameters", "RMSE data") if k in rest][0]
            by.setdefault((ex, m.group(2)), {})[kind] = (n, p)
    parts = []
    for (ex, cell), d in sorted(by.items()):
        if "extracted" not in d:
            continue
        e = pd.read_csv(d["extracted"][1], index_col=0)
        e = e.rename(columns={
            "Ageing Sets": "ageing_set", "Ageing Cycles": "ageing_cycles", "Days of degradation": "days",
            "Age set average temperature (degC)": "T_ageing_avg_degC", "Charge Throughput (A.h)": "charge_throughput_Ah",
            "Energy Throughput (W.h)": "energy_throughput_Wh", "C/10 Capacity (mA.h)": "cap_C10_mAh",
            "C/2 Capacity (mA.h)": "cap_C2_mAh", "0.1s Resistance (Ohms)": "R_0p1s_Ohm", "Mean_R (Ohms)": "R_mean_Ohm",
            "R_80to48_SOC (Ohms)": "R_80to48SOC_Ohm", "R_100SOC (Ohms)": "R_100SOC_Ohm"})
        e = e.drop(columns=[c for c in e.columns if "date" in c])
        if "DM data" in d:
            dm = pd.read_csv(d["DM data"][1], index_col=0)
            if dm.shape[1] > 6:  # one file carries extra scratch columns after the six documented ones
                checks.setdefault("dm_files_with_extra_columns_ignored", []).append(d["DM data"][0])
            assert list(dm.columns[:6]) == ["SoH", "LAM PE", "LAM NE_tot", "LAM NE_Gr", "LAM NE_Si", "LLI"]
            dm = dm.iloc[:, :6].dropna(how="all")
            dm.index = dm.index.astype(int)
            dm.columns = ["SOH_dma", "LAM_PE", "LAM_NE_tot", "LAM_NE_Gr", "LAM_NE_Si", "LLI"]
            e = e.join(dm)
        if "Capacity and offset" in d:
            cp = pd.read_csv(d["Capacity and offset"][1], index_col=0)
            cp.columns = ["cell_cap_dma_mAh", "PE_cap_mAh", "NE_tot_cap_mAh", "NE_Gr_cap_mAh", "NE_Si_cap_mAh", "offset_mAh"]
            e = e.join(cp)
        if "RMSE data" in d:
            e = e.join(pd.read_csv(d["RMSE data"][1], index_col=0).rename(columns={"RMSE (V)": "ocv_fit_rmse_V"}))
        e.insert(0, "rpt", e.index)
        e.insert(0, "cell", cell)
        e.insert(0, "T_nominal_degC", d["T"])
        e.insert(0, "soc_window_pct", SOC_WINDOW[ex])
        e.insert(0, "expt", ex)
        e["SOH_C10"] = e["cap_C10_mAh"] / e["cap_C10_mAh"].iloc[0]
        e["source_file"] = d["extracted"][0]
        parts.append(e)
    X = pd.concat(parts, ignore_index=True)
    X.to_csv(os.path.join(D, "C_experiment_per_cell_rpt.csv"), index=False, float_format="%.7g")

    # ---------------- summary per experiment and temperature
    rows = []
    for (ex, T), g in X.groupby(["expt", "T_nominal_degC"]):
        last = g.sort_values("rpt").groupby("cell").tail(1)
        # common throughput reached by all cells -> linear interpolation of each cell to that point
        q_common = g.groupby("cell")["charge_throughput_Ah"].max().min()
        def at(col):
            # largest throughput at which EVERY cell of the group still has a value of this column
            # (resistance is only measured at every second RPT), then linear interpolation per cell
            gg = g.dropna(subset=[col])
            qc = gg.groupby("cell")["charge_throughput_Ah"].max().min()
            v = [np.interp(qc, c.sort_values("charge_throughput_Ah")["charge_throughput_Ah"],
                           c.sort_values("charge_throughput_Ah")[col]) for _, c in gg.groupby("cell")]
            return float(np.mean(v)), float(np.min(v)), float(np.max(v)), float(qc)
        r = {"expt": ex, "soc_window_pct": SOC_WINDOW[ex], "T_nominal_degC": T, "cells": "|".join(sorted(g["cell"].unique())),
             "n_cells": g["cell"].nunique(), "n_rpt_max": int(g["rpt"].max()) + 1,
             "cycles_per_ageing_set": float(g[g["rpt"] == 1]["ageing_cycles"].median()),
             "T_ageing_avg_degC_mean": float(g["T_ageing_avg_degC"].mean()),
             "throughput_last_rpt_Ah_min": float(last["charge_throughput_Ah"].min()),
             "throughput_last_rpt_Ah_max": float(last["charge_throughput_Ah"].max()),
             "common_throughput_Ah": float(q_common)}
        for col, nm, sc in (("SOH_C10", "SOH_pct", 100), ("LLI", "LLI_pct", 100), ("LAM_NE_tot", "LAM_NE_tot_pct", 100),
                            ("LAM_PE", "LAM_PE_pct", 100), ("R_0p1s_Ohm", "R_0p1s_mOhm", 1000)):
            a = at(col)
            r[nm + "_at_common_mean"], r[nm + "_at_common_min"], r[nm + "_at_common_max"] = a[0] * sc, a[1] * sc, a[2] * sc
            if nm.startswith("R_"):
                r["R_common_throughput_Ah"] = a[3]
        r["R_0p1s_mOhm_BOL_mean"] = float(g[g["rpt"] == 0]["R_0p1s_Ohm"].mean() * 1000)
        r["cap_C10_mAh_BOL_mean"] = float(g[g["rpt"] == 0]["cap_C10_mAh"].mean())
        r["SOH_loss_pct_per_kAh"] = (100 - r["SOH_pct_at_common_mean"]) / (q_common / 1000)
        r["LLI_pct_per_kAh"] = r["LLI_pct_at_common_mean"] / (q_common / 1000)
        rows.append(r)
    Sm = pd.DataFrame(rows)
    Sm.to_csv(os.path.join(D, "C_experiment_summary.csv"), index=False, float_format="%.5g")

    # ---------------- figure source data
    zf = zipfile.ZipFile(src)
    QCOL = {"SOH_pct": ("SOH_dma", 100.0), "R_0p1s_mOhm": ("R_0p1s_Ohm", 1000.0), "LLI_pct": ("LLI", 100.0),
            "LAM_NE_tot_pct": ("LAM_NE_tot", 100.0), "LAM_PE_pct": ("LAM_PE", 100.0)}
    cells = {k: g for k, g in X.groupby(["expt", "T_nominal_degC", "cell"])}

    def match_cell(x, y, quantity):
        """Identify which cell a plotted experimental series is, by matching BOTH throughput and value
        (throughput alone is ambiguous: cells of one experiment have almost equal throughput)."""
        col, sc = QCOL[quantity]
        pts = [(a, b) for a, b in zip(x, y) if pd.notna(a) and pd.notna(b) and a > 0.2]
        best, score = None, 0.0
        if len(pts) < 3:
            return None, 0.0
        for k, g in cells.items():
            q, v = g["charge_throughput_Ah"].values / 1000.0, g[col].values * sc
            s = np.mean([np.any((np.abs(q - a) < 2e-3) & (np.abs(v - b) < 2e-3 * max(1.0, abs(b)))) for a, b in pts])
            if s > score:
                best, score = k, s
        return best, float(score)

    long_rows, small_rows, panel_map = [], [], {}
    dudt = None
    for n in sorted(zf.namelist()):
        if not n.endswith(".xlsx"):
            continue
        fig = os.path.basename(n)[:-5]
        if fig == "Supplementary Figure 14":
            continue  # 9.5 MB GITT voltage traces, not ageing data
        sheets = pd.read_excel(io.BytesIO(zf.read(n)), sheet_name=None)
        for sh, df in sheets.items():
            panel = re.sub(r"[^a-z]", "", sh.split("(")[-1]) if "(" in sh else sh
            cols = list(df.columns)
            if fig == "Supplementary Figure 10" and "dUdT" in "".join(cols):
                el = "negative" if "gr" in cols[1] else "positive"
                t = pd.DataFrame({"electrode": el, "stoichiometry": df.iloc[:, 0], "dUdT_plotted_value": df.iloc[:, 1]})
                t["Li2025_S5_S6_as_printed"] = (li_S6 if el == "negative" else li_S5)(t["stoichiometry"].values)
                dudt = t if dudt is None else pd.concat([dudt, t], ignore_index=True)
                continue
            is_age = any("hroughput" in c for c in cols) and len(cols) % 2 == 0
            if is_age:
                matched = {}
                for i in range(0, len(cols), 2):
                    s = series_of(cols[i + 1])
                    if s and s.startswith("exp_") and s != "exp_avg":
                        k, sc = match_cell(df.iloc[:, i].tolist(), df.iloc[:, i + 1].tolist(), quantity_of(cols[i + 1]))
                        if k and sc >= 0.8:
                            panel_map.setdefault("%s|%s" % (fig, panel), []).append(
                                {"series": s, "expt": k[0], "T_nominal_degC": int(k[1]), "cell": k[2], "match_fraction": sc})
                            matched[s] = k
                for i in range(0, len(cols), 2):
                    s, q = series_of(cols[i + 1]), quantity_of(cols[i + 1])
                    k = matched.get(s)
                    for xv, yv in zip(df.iloc[:, i], df.iloc[:, i + 1]):
                        if pd.notna(xv) and pd.notna(yv):
                            long_rows.append({"figure": fig, "panel": panel, "series": s, "quantity": q,
                                              "charge_throughput_kAh": xv, "value": yv,
                                              "matched_cell": k[2] if k else "",
                                              "matched_cell_T_nominal_degC": k[1] if k else "",
                                              "matched_expt": k[0] if k else "", "source_header": cols[i + 1]})
            elif len(df) <= 40:
                for c in cols:
                    for r_i, v in enumerate(df[c]):
                        if pd.notna(v):
                            small_rows.append({"figure": fig, "panel": panel, "column": c, "row": r_i, "value": v})
    L = pd.DataFrame(long_rows)
    # experiment of a figure = experiment of the matched cells (computed, not assumed)
    fig_expt = L[L["matched_expt"] != ""].groupby("figure")["matched_expt"].agg(lambda v: "|".join(sorted(set(v))))
    L.insert(2, "expt", L["figure"].map(fig_expt))
    # panel temperature: Fig. 3/4/6 have one column of panels per temperature (captions); the column order
    # 10/25/40 degC is CONFIRMED by cell matching for Fig. 3/4 and is ASSUMED to be the same for Fig. 6.
    def panel_T(r):
        if r["figure"] in ("Fig.3", "Fig.4", "Fig.6"):
            return (10, 25, 40)[(ord(r["panel"][0]) - ord("a")) % 3]
        return np.nan
    L.insert(3, "T_panel_degC", L.apply(panel_T, axis=1))
    s7 = L["figure"] == "Supplementary Figure 7"
    t7 = L[s7 & (L["matched_cell_T_nominal_degC"] != "")].groupby("panel")["matched_cell_T_nominal_degC"].first()
    L.loc[s7, "T_panel_degC"] = L.loc[s7, "panel"].map(t7).astype(float)
    e7 = L[s7 & (L["matched_expt"] != "")].groupby("panel")["matched_expt"].first()
    L.loc[s7, "expt"] = L.loc[s7, "panel"].map(e7)
    L.insert(3, "soc_window_pct", L["expt"].map(SOC_WINDOW))
    bad = L[(L["matched_cell"] != "") & (L["matched_cell_T_nominal_degC"] != L["T_panel_degC"])]
    checks["exp_series_whose_cell_temperature_differs_from_panel_temperature"] = sorted(
        "%s|%s|%s -> Expt %s cell %s (%s degC nominal), panel = %s degC" % t for t in set(zip(
            bad["figure"], bad["panel"], bad["series"], bad["matched_expt"], bad["matched_cell"],
            bad["matched_cell_T_nominal_degC"], bad["T_panel_degC"])))
    L.to_csv(os.path.join(D, "C_fig_ageing_long.csv"), index=False, float_format="%.6g")
    pd.DataFrame(small_rows).to_csv(os.path.join(D, "C_fig_small_tables_long.csv"), index=False, float_format="%.6g")
    checks["panel_to_experiment_matching"] = panel_map
    checks["fig_ageing_rows"] = int(len(L))
    checks["fig_ageing_series_counts"] = {"%s|%s" % k: int(v) for k, v in L.groupby(["figure", "series"]).size().items()}

    # dU/dT curves used for the paper's Suppl. Fig. 10 c,d
    if dudt is not None:
        dudt.iloc[::10].to_csv(os.path.join(D, "C_li_dUdT_curves.csv"), index=False, float_format="%.6g")
        ck = {}
        for el, g in dudt.groupby("electrode"):
            y, f = g["dUdT_plotted_value"].values, g["Li2025_S5_S6_as_printed"].values
            ck[el] = {"n": int(len(g)), "plotted_min": float(y.min()), "plotted_max": float(y.max()),
                      "printed_function_min": float(f.min()), "printed_function_max": float(f.max()),
                      "rmse_plotted_vs_printed": float(np.sqrt(np.mean((y - f) ** 2))),
                      "rmse_plotted_vs_printed_times_1e-3": float(np.sqrt(np.mean((y - 1e-3 * f) ** 2))),
                      "median_ratio_plotted_over_printed": float(np.median(y[np.abs(f) > 1e-3] / f[np.abs(f) > 1e-3]))}
        checks["dUdT_suppl_fig10"] = ck

    # ---------------- model input cases + error summary (Full_Exp23_Paper_11_fine)
    case = [p for n, p in got if n.endswith("InputData/Full_Exp23_Paper_11_fine/Full_Exp23_Paper_11_fine.csv")]
    if case:
        C = pd.read_csv(case[0])
        summ = [p for n, p in got if n.endswith("Summary of Full_Exp23_Paper_11_fine_NC.xlsx")]
        if summ:
            Sx = pd.read_excel(summ[0], sheet_name=0)
            Sx = Sx.loc[:, ~Sx.columns.duplicated()]
            keep = [c for c in Sx.columns if c.startswith("Error") or c in ("Scan No", "Y or N", "Punish")]
            C = C.merge(Sx[keep], on="Scan No", how="left")
        C.to_csv(os.path.join(D, "C_model_input_cases.csv"), index=False)
        checks["model_input_cases"] = {"n_cases": int(len(C)), "columns": list(C.columns)}
    with open(os.path.join(D, "C_checks.json"), "w") as f:
        json.dump(checks, f, indent=1)
    pd.set_option("display.width", 250)
    print(Sm[["expt", "soc_window_pct", "T_nominal_degC", "n_cells", "n_rpt_max", "common_throughput_Ah",
              "SOH_pct_at_common_mean", "LLI_pct_at_common_mean", "LAM_NE_tot_pct_at_common_mean",
              "LAM_PE_pct_at_common_mean", "R_0p1s_mOhm_at_common_mean"]].round(2).to_string())
    print(json.dumps(checks.get("dUdT_suppl_fig10"), indent=1))
    print({k: [(d["series"], d["expt"], d["T_nominal_degC"], d["cell"]) for d in v] for k, v in panel_map.items()})


if __name__ == "__main__":
    main()
