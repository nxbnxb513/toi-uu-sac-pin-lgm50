"""Dataset A - Zenodo 10.5281/zenodo.4864437 (brosaplanella/TEC-reduced-model v1.0, BSD-3).

LG M50 discharges at C/10, C/2, 1C, 2C and 0/10/25 degC (Brosa Planella, Sheikh, Widanage 2021).
Produces (in data/derived/):
  A_files.csv        one row per raw file: protocol, sampling, channels
  A_noise.csv        sensor noise / quantisation per file and channel (rest segments)
  A_thermal_tau.csv  lumped cooling time constant tau per file, discharge and thermocouple
  A_tc_spread.csv    differences between the three surface thermocouples during discharge
  A_summary.json     medians / ranges quoted in ket_qua_du_lieu.md

Usage: python a_tec_noise_thermal.py [--cache DIR]
Requires numpy, pandas, scipy. Raw files are parsed as CSV only (nothing is executed).
"""
import io
import json
import os
import re
import zipfile

import numpy as np
import pandas as pd
from scipy.optimize import curve_fit

import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # works with python -I
import common  # noqa: E402

RECORD = 4864437
KEY = "brosaplanella/TEC-reduced-model-v1.0.zip"
SETTLED_S = 1800.0      # noise is estimated on the last 30 min of each 2 h rest
SKIPS = (60.0, 120.0, 300.0, 600.0)  # seconds skipped after current cut before the exp fit
MAIN_SKIP = 120.0
MIN_DT0 = 2.0           # K; fits with smaller initial excess temperature are flagged unreliable

TEMP_NAMES = {  # as in tec_reduced_model/process_experimental_data.py::clean_dataset
    "4": {"LogTempPositive": "T_pos", "LogTempMid": "T_mid", "LogTempNegative": "T_neg", "LogTemp001": "T_amb"},
    "3": {"LogTempPositive": "T_pos", "LogTempMid": "T_mid", "LogTempNegative": "T_neg"},
    "2": {"LogTemp001": "T_cell", "LogTemp002": "T_amb"},
    "1": {"LogTemp001": "T_cell"},
}


def temp_map(cols):
    has3 = "LogTempPositive" in cols
    if has3 and "LogTemp001" in cols:
        return TEMP_NAMES["4"]
    if has3:
        return TEMP_NAMES["3"]
    if "LogTemp002" in cols:
        return TEMP_NAMES["2"]
    return TEMP_NAMES["1"]


def read_file(zf, name):
    raw = zf.read(name).decode("utf-8", "replace").splitlines()
    head = {}
    for line in raw[:15]:
        p = line.split(",", 1)
        if len(p) == 2 and p[0]:
            head[p[0]] = p[1].strip()
    units = raw[16]
    df = pd.read_csv(io.StringIO("\n".join(raw)), skiprows=list(range(15)) + [16])
    df = df.dropna(axis=1, how="all")
    return head, units, df


def quant_step(x):
    u = np.unique(np.round(np.asarray(x, float), 6))
    if len(u) < 2:
        return np.nan
    return float(np.min(np.diff(u)))


def noise_stats(x):
    """std_raw: plain std; std_d2: std of 2nd differences / sqrt(6) (insensitive to linear drift)."""
    x = np.asarray(x, float)
    out = {"n": len(x), "std_raw": float(np.std(x, ddof=1)) if len(x) > 2 else np.nan}
    out["std_d2"] = float(np.std(np.diff(x, 2), ddof=1) / np.sqrt(6.0)) if len(x) > 4 else np.nan
    return out


def expo(t, tinf, a, tau):
    return tinf + a * np.exp(-t / tau)


def segments(df):
    seg = (df["Step"] != df["Step"].shift()).cumsum()
    return [g for _, g in df.groupby(seg)]


def main():
    cache = common.cache_dir()
    zpath = common.zenodo_file(RECORD, KEY, cache)
    zf = zipfile.ZipFile(zpath)
    names = sorted(n for n in zf.namelist() if re.search(r"/data/\d+degC/Cell\d+_.*\.csv$", n))
    files, noise, taus, spread = [], [], [], []
    for name in names:
        base = os.path.basename(name)
        m = re.match(r"Cell(\d+)_(\w+?)C_(\d+)degC", base)
        cell, crate, tnom = m.group(1), float(m.group(2).replace("p", ".")), int(m.group(3))
        head, units, df = read_file(zf, name)
        tmap = temp_map(df.columns)
        df = df.rename(columns=tmap)
        tch = list(tmap.values())
        segs = segments(df)
        dch = [g for g in segs if g["Status"].iloc[0] == "DCH"]
        pau = [g for g in segs if g["Status"].iloc[0] == "PAU" and len(g) > 30]
        dt_dch = float(np.median(np.diff(dch[0]["Prog Time"]))) if dch and len(dch[0]) > 2 else np.nan
        files.append({
            "file": name.split("/", 1)[1], "cell": cell, "C_rate": crate, "T_nominal_degC": tnom,
            "measurement_id": head.get("Measurement ID", ""), "program": head.get("Program", ""),
            "start_time": head.get("Start Time", ""), "n_rows": len(df),
            "temperature_channels": "|".join(tch), "units_row": units.strip(","),
            "step_sequence": ">".join(g["Status"].iloc[0] for g in segs if len(g) > 2),
            "n_discharges": len(dch),
            "dt_discharge_median_s": dt_dch,
            "dt_rest_median_s": "|".join("%.0f" % np.median(np.diff(g["Prog Time"])) for g in pau),
            "I_discharge_mean_A": float(np.mean([g["Current"].iloc[1:].mean() for g in dch])) if dch else np.nan,
            "discharge_duration_s": "|".join("%.0f" % (g["Prog Time"].iloc[-1] - g["Prog Time"].iloc[0]) for g in dch),
            "rest_after_discharge_s": "",
        })
        # ---------------- noise on settled rests (last 30 min of every long pause)
        for ch in ["Voltage", "Current"] + tch:
            x_all = df[ch].values
            rows = []
            for g in pau:
                t = g["Prog Time"].values
                sel = g[t >= t[-1] - SETTLED_S]
                if len(sel) >= 10:
                    rows.append(noise_stats(sel[ch].values))
            rec = {"file": base, "cell": cell, "C_rate": crate, "T_nominal_degC": tnom, "channel": ch,
                   "unit": "V" if ch == "Voltage" else ("A" if ch == "Current" else "degC"),
                   "quantisation_step": quant_step(x_all),
                   "n_rest_windows": len(rows),
                   "rest_std_raw_median": float(np.nanmedian([r["std_raw"] for r in rows])) if rows else np.nan,
                   "rest_std_d2_median": float(np.nanmedian([r["std_d2"] for r in rows])) if rows else np.nan,
                   "rest_all_values_identical": bool(rows and all(r["std_raw"] == 0 for r in rows)),
                   "cc_discharge_std_d2": np.nan}
            if ch == "Current" and dch:
                # the cycler logs exactly 0 A in pauses, so current noise is taken on the CC discharge
                rec["cc_discharge_std_d2"] = float(np.median(
                    [noise_stats(g["Current"].values[2:-2])["std_d2"] for g in dch if len(g) > 10]))
            if ch == "T_amb" and np.all(x_all == 0):
                rec["quantisation_step"] = np.nan
                rec["note"] = "channel constant 0.0 (not connected)"
            noise.append(rec)
        # ---------------- cool-down after each discharge: T = Tinf + A exp(-t/tau)
        for k, g in enumerate(dch):
            i_end = g.index[-1]
            after = [p for p in pau if p.index[0] > i_end]
            if not after:
                continue
            r = after[0]
            if r.index[0] - i_end > 3:
                continue
            t_rel = r["Prog Time"].values - g["Prog Time"].iloc[-1]
            files[-1]["rest_after_discharge_s"] = "%.0f" % t_rel[-1]
            before = [p for p in pau if p.index[-1] < g.index[0]][-1]
            for ch in [c for c in tch if c != "T_amb"]:
                y = r[ch].values.astype(float)
                base_T = float(before[ch].values[-10:].mean())
                for skip in SKIPS:
                    msk = t_rel >= skip
                    tt, yy = t_rel[msk] - skip, y[msk]
                    rec = {"file": base, "cell": cell, "C_rate": crate, "T_nominal_degC": tnom,
                           "discharge_no": k + 1, "channel": ch, "skip_s": skip,
                           "T_before_discharge_degC": base_T, "T_end_discharge_degC": float(g[ch].iloc[-1]),
                           "T_max_degC": float(max(g[ch].max(), y.max())), "n_points": int(msk.sum()),
                           "dt_s": float(np.median(np.diff(t_rel)))}
                    dT0 = yy[0] - yy[-20:].mean() if len(yy) > 25 else np.nan
                    rec["dT0_K"] = float(dT0)
                    try:
                        p, _ = curve_fit(expo, tt, yy, p0=[yy[-1], max(dT0, 0.1), 600.0],
                                         bounds=([-50, 0, 10], [80, 100, 1e5]))
                        res = yy - expo(tt, *p)
                        rec.update({"T_inf_fit_degC": p[0], "A_fit_K": p[1], "tau_s": p[2],
                                    "rmse_K": float(np.sqrt(np.mean(res ** 2)))})
                    except Exception as e:  # noqa
                        rec.update({"T_inf_fit_degC": np.nan, "A_fit_K": np.nan, "tau_s": np.nan, "rmse_K": np.nan})
                    rec["reliable"] = bool(np.isfinite(rec["tau_s"]) and rec["dT0_K"] >= MIN_DT0)
                    if "T_amb" in tch and not np.all(df["T_amb"].values == 0):
                        rec["T_amb_channel_mean_degC"] = float(r["T_amb"].mean())
                    taus.append(rec)
            # ---------------- thermocouple spread during the discharge
            if all(c in tch for c in ("T_pos", "T_mid", "T_neg")):
                off = {c: float(before[c].values[-10:].mean()) for c in ("T_pos", "T_mid", "T_neg")}
                rise = {c: g[c].values - off[c] for c in off}
                d_mp, d_mn, d_np = rise["T_mid"] - rise["T_pos"], rise["T_mid"] - rise["T_neg"], rise["T_neg"] - rise["T_pos"]
                spread.append({
                    "file": base, "cell": cell, "C_rate": crate, "T_nominal_degC": tnom, "discharge_no": k + 1,
                    "rest_offset_mid_minus_pos_K": off["T_mid"] - off["T_pos"],
                    "rest_offset_mid_minus_neg_K": off["T_mid"] - off["T_neg"],
                    "rise_end_pos_K": float(rise["T_pos"][-1]), "rise_end_mid_K": float(rise["T_mid"][-1]),
                    "rise_end_neg_K": float(rise["T_neg"][-1]),
                    "max_rise_mid_minus_pos_K": float(d_mp.max()), "max_rise_mid_minus_neg_K": float(d_mn.max()),
                    "max_abs_rise_neg_minus_pos_K": float(np.abs(d_np).max()),
                    "end_rise_mid_minus_pos_K": float(d_mp[-1]), "end_rise_mid_minus_neg_K": float(d_mn[-1]),
                    "pos_rise_over_mid_rise_at_end": float(rise["T_pos"][-1] / rise["T_mid"][-1]) if rise["T_mid"][-1] > 0.5 else np.nan,
                    "neg_rise_over_mid_rise_at_end": float(rise["T_neg"][-1] / rise["T_mid"][-1]) if rise["T_mid"][-1] > 0.5 else np.nan,
                })
    D = common.DERIVED
    F, N, T, Sp = map(pd.DataFrame, (files, noise, taus, spread))
    F.to_csv(os.path.join(D, "A_files.csv"), index=False)
    N.to_csv(os.path.join(D, "A_noise.csv"), index=False, float_format="%.6g")
    T.to_csv(os.path.join(D, "A_thermal_tau.csv"), index=False, float_format="%.6g")
    Sp.to_csv(os.path.join(D, "A_tc_spread.csv"), index=False, float_format="%.6g")

    # ---------------- summary
    def rng(s):
        s = pd.Series(s).dropna()
        return {"n": int(len(s)), "median": float(s.median()), "min": float(s.min()), "max": float(s.max())} if len(s) else {"n": 0}
    summ = {"noise": {}, "tau": {}, "spread": {}}
    N["sampling"] = np.where(N["C_rate"] >= 1, "1s", "60s")
    for (ch, smp), g in N.groupby(["channel", "sampling"]):
        g = g[~g.get("note", pd.Series("", index=g.index)).fillna("").str.contains("not connected")]
        summ["noise"]["%s|%s" % (ch, smp)] = {
            "quantisation_step": rng(g["quantisation_step"]),
            "rest_std_d2": rng(g["rest_std_d2_median"]), "rest_std_raw": rng(g["rest_std_raw_median"]),
            "cc_discharge_std_d2": rng(g["cc_discharge_std_d2"]),
            "files_all_identical_at_rest": int(g["rest_all_values_identical"].sum()), "files": int(len(g))}
    main_ = T[(T["skip_s"] == MAIN_SKIP) & T["reliable"]]
    summ["tau"]["main_skip_s"] = MAIN_SKIP
    summ["tau"]["all_reliable"] = rng(main_["tau_s"])
    for ch, g in main_.groupby("channel"):
        summ["tau"]["channel|" + ch] = rng(g["tau_s"])
    for tn, g in main_.groupby("T_nominal_degC"):
        summ["tau"]["T|%d" % tn] = rng(g["tau_s"])
    for cr, g in main_.groupby("C_rate"):
        summ["tau"]["C|%g" % cr] = rng(g["tau_s"])
    for sk, g in T[T["reliable"]].groupby("skip_s"):
        summ["tau"]["skip|%g" % sk] = rng(g["tau_s"])
    summ["tau"]["rmse_K"] = rng(main_["rmse_K"])
    for (cr, tn), g in Sp.groupby(["C_rate", "T_nominal_degC"]):
        summ["spread"]["%gC|%ddegC" % (cr, tn)] = {c: float(g[c].mean()) for c in Sp.columns if c.endswith("_K") or "over" in c}
    with open(os.path.join(D, "A_summary.json"), "w") as f:
        json.dump(summ, f, indent=1)
    print(json.dumps(summ, indent=1))


if __name__ == "__main__":
    main()
