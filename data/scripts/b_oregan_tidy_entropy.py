"""Dataset B - Zenodo 10.5281/zenodo.5171874 (O'Regan et al. 2021 Data Repository, CC BY 4.0).

Raw measurements behind O'Regan et al., Electrochim. Acta 425 (2022) 140700.
Produces (data/derived/):
  B_entropic.csv              dU/dT raw points (both electrodes, 2 cells) + Li 2025 SI (S5),(S6) evaluated
  B_thermal_electronic.csv    thermal conductivity, electronic conductivity raw points + Li 2025 (S19),(S24),(S25)
  B_specific_heat.csv         DSC specific heat (every 10th raw row) + Li 2025 (S21)-(S23)
  B_exchange_current.csv      exchange current density raw points + Li 2025 (S26),(S27) at c_e = <c_e>
  B_diffusivity.csv           solid diffusivity from GITT (all 40 files, tidy)
  B_checks.json               RMSE of the printed fit functions vs raw data, unit verdicts, independent refit

Usage: python b_oregan_tidy_entropy.py [--cache DIR]
"""
import io
import json
import os
import re
import sys
import zipfile

import numpy as np
import pandas as pd
from scipy.optimize import curve_fit

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # works with python -I
import common  # noqa: E402

RECORD = 5171874
KEY = "ORegan 2021 Data Repository.zip"
R = 8.314462618


# ---- functions exactly as printed in Li et al. 2025 SI Note 8 / Note 11 (transcribed in tai_lieu/tham_so/Li2025_tham_so.md)
def li_S5_dUdT_pos(x):
    return 0.04006 * np.exp(-(x - 0.2828) ** 2 / 0.0009855) - 0.06656 * np.exp(-(x - 0.8032) ** 2 / 0.02179)


def li_S6_dUdT_neg(x):
    return -0.111 * x + 0.02901 + 0.3562 * np.exp(-(x - 0.08308) ** 2 / 0.004621)


def li_S19_sigma_pos(T):
    return 0.8473 * np.exp(-3500.0 / R * (1.0 / T - 1.0 / 298.15))


def li_S21_cp_pos(T):
    return -0.0008414 * T ** 3 + 0.7892 * T ** 2 - 241.3 * T + 2.508e4


def li_S22_cp_neg(T):
    return 0.0004932 * T ** 3 - 0.491 * T ** 2 + 169.4 * T - 1.897e4


def li_S23_cp_sep(T):
    return 0.001494 * T ** 3 - 1.444 * T ** 2 + 475.5 * T - 5.13e4


def li_S24_lambda_pos(T):
    return 2.063e-5 * T ** 2 - 0.01127 * T + 2.331


def li_S25_lambda_neg(T):
    return -2.61e-4 * T ** 2 + 0.1726 * T - 24.49


def li_S26_j0_pos(x, T):  # A/m2, c_e/<c_e> = 1
    return 5.028 * np.exp(-2.401e4 / R * (1 / T - 1 / 298.15)) * x ** 0.43 * (1 - x) ** 0.57


def li_S27_j0_neg(x, T):
    return 2.668 * np.exp(-4e4 / R * (1 / T - 1 / 298.15)) * x ** 0.792 * (1 - x) ** 0.208


def rmse(a, b):
    a, b = np.asarray(a, float), np.asarray(b, float)
    return float(np.sqrt(np.mean((a - b) ** 2)))


def read(zf, name, ncol=2):
    txt = zf.read(name).decode("latin-1")
    df = pd.read_csv(io.StringIO(txt)).dropna(axis=1, how="all").dropna(axis=0, how="all")
    return df


def main():
    cache = common.cache_dir()
    zf = zipfile.ZipFile(common.zenodo_file(RECORD, KEY, cache))
    names = [n for n in zf.namelist() if n.endswith(".csv")]
    D = common.DERIVED
    checks = {"source_headers": {}}

    # ---------------- entropic term
    rows = []
    for n in sorted(n for n in names if "/Entropic Term/" in n):
        df = read(zf, n)
        checks["source_headers"][os.path.basename(n)] = list(df.columns)
        el = "negative" if "Negative" in n else "positive"
        cell = re.search(r"Cell_(\d+)", n).group(1)
        for x, v in zip(df.iloc[:, 0], df.iloc[:, 1]):
            f = (li_S6_dUdT_neg if el == "negative" else li_S5_dUdT_pos)(float(x))
            rows.append({"electrode": el, "cell": cell, "stoichiometry": float(x), "dUdT_meas_mV_per_K": float(v),
                         "Li2025_fit_value_as_printed": float(f), "source_file": n})
    E = pd.DataFrame(rows)
    E["residual_if_fit_in_mV_per_K"] = E["dUdT_meas_mV_per_K"] - E["Li2025_fit_value_as_printed"]
    E["residual_if_fit_in_V_per_K"] = E["dUdT_meas_mV_per_K"] - 1000.0 * E["Li2025_fit_value_as_printed"]
    E.to_csv(os.path.join(D, "B_entropic.csv"), index=False, float_format="%.6g")
    ent = {}
    for el, g in E.groupby("electrode"):
        d = {"n_points": int(len(g)), "data_unit_in_file_header": "mV K-1",
             "data_min_mV_per_K": float(g["dUdT_meas_mV_per_K"].min()),
             "data_max_mV_per_K": float(g["dUdT_meas_mV_per_K"].max()),
             "rmse_mV_per_K_if_fit_is_mV_per_K": rmse(g["dUdT_meas_mV_per_K"], g["Li2025_fit_value_as_printed"]),
             "rmse_mV_per_K_if_fit_is_V_per_K": rmse(g["dUdT_meas_mV_per_K"], 1000 * g["Li2025_fit_value_as_printed"]),
             "max_abs_residual_mV_per_K_if_mV": float(g["residual_if_fit_in_mV_per_K"].abs().max()),
             "x_of_max_abs_residual": float(g.loc[g["residual_if_fit_in_mV_per_K"].abs().idxmax(), "stoichiometry"])}
        if el == "negative":  # graphite staging dip (x ~ 0.47-0.57) is not represented by the form of (S6)
            g2 = g[(g["stoichiometry"] < 0.45) | (g["stoichiometry"] > 0.6)]
            d["rmse_mV_per_K_if_mV_excluding_0p45_to_0p60"] = rmse(g2["dUdT_meas_mV_per_K"], g2["Li2025_fit_value_as_printed"])
        # independent least-squares refit of the same functional form to the pooled raw points
        x, y = g["stoichiometry"].values, g["dUdT_meas_mV_per_K"].values
        try:
            if el == "negative":
                fn = lambda x, a0, b0, a1, b1, c1: a0 * x + b0 + a1 * np.exp(-(x - b1) ** 2 / c1)  # noqa
                p0 = [-0.111, 0.02901, 0.3562, 0.08308, 0.004621]
                keys = ["a0", "b0", "a1", "b1", "c1"]
            else:
                fn = lambda x, a1, b1, c1, a2, b2, c2: a1 * np.exp(-(x - b1) ** 2 / c1) + a2 * np.exp(-(x - b2) ** 2 / c2)  # noqa
                p0 = [0.04006, 0.2828, 0.0009855, -0.06656, 0.8032, 0.02179]
                keys = ["a1", "b1", "c1", "a2", "b2", "c2"]
            p, _ = curve_fit(fn, x, y, p0=p0, maxfev=20000)
            d["refit_same_form_mV_per_K"] = dict(zip(keys, [float(v) for v in p]))
            d["refit_rmse_mV_per_K"] = rmse(y, fn(x, *p))
            d["Li2025_printed_coefficients"] = dict(zip(keys, p0))
        except Exception as e:  # noqa
            d["refit_error"] = str(e)
        ent[el] = d
    checks["entropic"] = ent

    # ---------------- thermal + electronic conductivity
    rows = []
    for n in sorted(n for n in names if "/Thermal Conductivity/" in n or "/Electronic Conductivity/" in n):
        df = read(zf, n)
        checks["source_headers"][os.path.basename(n)] = list(df.columns)
        el = "negative" if "Negative" in n else "positive"
        q = "thermal_conductivity" if "Thermal" in n else "electronic_conductivity"
        fn = {("thermal_conductivity", "positive"): li_S24_lambda_pos, ("thermal_conductivity", "negative"): li_S25_lambda_neg,
              ("electronic_conductivity", "positive"): li_S19_sigma_pos}[(q, el)]
        for T, v in zip(df.iloc[:, 0], df.iloc[:, 1]):
            rows.append({"quantity": q, "electrode": el, "T_K": float(T), "value": float(v),
                         "unit": "W m-1 K-1" if q.startswith("thermal") else "S m-1",
                         "Li2025_fit_value": float(fn(float(T))), "source_file": n})
    TE = pd.DataFrame(rows)
    TE.to_csv(os.path.join(D, "B_thermal_electronic.csv"), index=False, float_format="%.6g")
    checks["thermal_electronic"] = {
        "%s|%s" % k: {"n": int(len(g)), "rmse": rmse(g["value"], g["Li2025_fit_value"]),
                      "max_rel_err": float((g["Li2025_fit_value"] / g["value"] - 1).abs().max())}
        for k, g in TE.groupby(["quantity", "electrode"])}

    # ---------------- specific heat (DSC)
    rows, cp = [], {}
    for n in sorted(n for n in names if "/Specific Heat Capacity/" in n):
        df = read(zf, n)
        checks["source_headers"][os.path.basename(n)] = [c.encode("ascii", "replace").decode() for c in df.columns]
        comp = "negative" if "Negative" in n else ("positive" if "Positive" in n else "separator")
        fn = {"negative": li_S22_cp_neg, "positive": li_S21_cp_pos, "separator": li_S23_cp_sep}[comp]
        T = df.iloc[:, 0].values.astype(float)
        v = df.iloc[:, 1].values.astype(float)
        fit = fn(T + 273.15)
        m = (T >= 35) & (T <= 90)  # the first degrees of a DSC scan are a start-up transient
        cp[comp] = {"n_raw": int(len(T)), "T_min_degC": float(T.min()), "T_max_degC": float(T.max()),
                    "raw_value_at_25degC": float(v[0]), "raw_value_at_40degC": float(np.interp(40, T, v)),
                    "Li2025_fit_at_40degC_J_per_kg_K": float(fn(313.15)),
                    "ratio_fit_over_raw_median_35_90degC": float(np.median(fit[m] / v[m])),
                    "rmse_35_90degC_if_raw_is_J_per_g_K": rmse(1000 * v[m], fit[m]),
                    "rmse_35_90degC_if_raw_is_J_per_kg_K": rmse(v[m], fit[m])}
        for i in range(0, len(T), 10):
            rows.append({"component": comp, "T_degC": T[i], "cp_raw_value": v[i],
                         "raw_header_unit": "J kg-1 K-1 (as labelled; magnitude is J g-1 K-1)",
                         "Li2025_fit_J_per_kg_K": fit[i], "source_file": n})
    pd.DataFrame(rows).to_csv(os.path.join(D, "B_specific_heat.csv"), index=False, float_format="%.6g")
    checks["specific_heat"] = cp

    # ---------------- exchange current
    rows = []
    for n in sorted(n for n in names if "/Exchange Current/" in n):
        df = read(zf, n)
        checks["source_headers"][os.path.basename(n)] = list(df.columns)
        el = "negative" if "Negative" in n else "positive"
        TC = float(re.search(r"_(\d+)deg", n).group(1))
        fn = li_S27_j0_neg if el == "negative" else li_S26_j0_pos
        for x, v in zip(df.iloc[:, 0], df.iloc[:, 1]):
            x = float(x)
            rows.append({"electrode": el, "T_degC": TC, "stoichiometry": x, "j0_meas_mA_per_cm2": float(v),
                         "j0_meas_A_per_m2": 10.0 * float(v),
                         "Li2025_fit_A_per_m2_at_ce_ref": float(fn(min(x, 1.0), TC + 273.15)), "source_file": n})
    J = pd.DataFrame(rows)
    J.to_csv(os.path.join(D, "B_exchange_current.csv"), index=False, float_format="%.6g")
    checks["exchange_current"] = {
        "%s|%gdegC" % k: {"n": int(len(g)), "meas_max_A_per_m2": float(g["j0_meas_A_per_m2"].max()),
                          "fit_max_A_per_m2": float(g["Li2025_fit_A_per_m2_at_ce_ref"].max()),
                          "rmse_A_per_m2": rmse(g["j0_meas_A_per_m2"], g["Li2025_fit_A_per_m2_at_ce_ref"]),
                          "median_ratio_fit_over_meas": float(np.median(
                              g["Li2025_fit_A_per_m2_at_ce_ref"][g["j0_meas_A_per_m2"] > 0] / g["j0_meas_A_per_m2"][g["j0_meas_A_per_m2"] > 0]))}
        for k, g in J.groupby(["electrode", "T_degC"])}

    # ---------------- diffusivity
    parts = []
    for n in sorted(n for n in names if "/Solid-state Diffusivity/" in n):
        df = read(zf, n)
        m = re.search(r"Diffusivity_(\w+)_Electrode_Cell(\d+)_(\d+)_degC_(\w+)\.csv", n)
        df.columns = ["capacity_mAh_per_cm2", "stoichiometry", "D_s_m2_per_s", "R2", "T_K"]
        df.insert(0, "direction", m.group(4))
        df.insert(0, "T_degC", int(m.group(3)))
        df.insert(0, "cell", m.group(2))
        df.insert(0, "electrode", m.group(1).lower())
        parts.append(df)
    Dd = pd.concat(parts, ignore_index=True)
    Dd.to_csv(os.path.join(D, "B_diffusivity.csv"), index=False, float_format="%.5g")
    g = Dd[Dd["D_s_m2_per_s"] > 0].assign(lg=lambda d: np.log10(d["D_s_m2_per_s"]))
    checks["diffusivity"] = {
        "n_files": len(parts), "n_rows": int(len(Dd)),
        "median_log10_D_by_electrode_T": {"%s|%d" % k: float(v) for k, v in g.groupby(["electrode", "T_degC"])["lg"].median().items()},
        "stoichiometry_range": {k: [float(v["stoichiometry"].min()), float(v["stoichiometry"].max())] for k, v in Dd.groupby("electrode")},
    }
    with open(os.path.join(D, "B_checks.json"), "w") as f:
        json.dump(checks, f, indent=1)
    print(json.dumps({k: v for k, v in checks.items() if k != "source_headers"}, indent=1))


if __name__ == "__main__":
    main()
