"""Thong ke luoi day du cho bao cao: doc grid_all.csv (grid.py report), in cac so dung trong slide/tai lieu.
Chay: python grid_stats.py <grid_all.csv>
"""
import sys
import numpy as np
import pandas as pd

OK = ["ok", "ok_tol"]
d = pd.read_csv(sys.argv[1])
d["k"] = d["k"].astype(float)
print("so truong hop:", d.groupby("method").size().to_dict())
print(d.groupby(["method", "status"]).size().unstack(fill_value=0))

n = d[(d.method == "nmpc") & d.status.isin(OK)]
kinf = n[np.isinf(n.k)]
print("\n[thanh phan mat Li, NMPC k=inf dat, tong moi vung]")
for src in ("cccv", "nmpc"):
    tot = sum(kinf[f"{src}_perm_{p}_mAh"].sum() for p in ("sei", "lam", "dead"))
    print(src, {p: round(100 * kinf[f"{src}_perm_{p}_mAh"].sum() / tot, 1) for p in ("sei", "lam", "dead")},
          "tong/CCCV", round(tot / kinf.cccv_perm_mAh.sum(), 3))
g = kinf.groupby(["Cbase", "Tamb_C"])
for p in ("sei", "lam", "dead"):
    r = 100 * (1 - g[f"nmpc_perm_{p}_mAh"].sum() / g[f"cccv_perm_{p}_mAh"].sum())
    print(f"giam {p} (%) theo C,T:", r.round(1).to_dict())

print("\n[bo giai]")
for m in ("nmpc", "ekf"):
    x = d[d.method == m]
    ns = x.n_solves.sum()
    print(m, "lan giai", int(ns), "hoi tu", int(x.n_status0.sum()), f"({100 * x.n_status0.sum() / ns:.0f} %)",
          "status2", int(x.n_status2.sum()), f"({100 * x.n_status2.sum() / ns:.0f} %)", "that bai", int(x.n_fail.sum()),
          "SQP TB", f"{x.sqp_mean.min():.1f}-{x.sqp_mean.max():.1f} (trung vi {x.sqp_mean.median():.1f})",
          "giai trung vi/p95 (s)", round(x.solve_median_ms.median() / 1e3, 1), round(x.solve_p95_ms.median() / 1e3, 1),
          "TB (s)", round((x.solve_mean_ms * x.n_solves).sum() / ns / 1e3, 1),
          "sinh ma (s)", f"{x.build_s.min():.0f}-{x.build_s.max():.0f}")
    f = x[x.n_fail > 0]
    print("   that bai o:", f.groupby(["window", "Cbase", "Tamb_C"]).n_fail.sum().to_dict())

print("\n[EKF so voi NMPC]")
a = d[d.method == "nmpc"].set_index(["iw", "Cbase", "Tamb_C", "k"])
b = d[d.method == "ekf"].set_index(["iw", "Cbase", "Tamb_C", "k"])
j = a.join(b, rsuffix="_e", how="inner")
both = j[j.status.isin(OK) & j.status_e.isin(OK)]
df = both.reduction_pct_e - both.reduction_pct
print("cap cung dat", len(both), "lech trung vi", round(df.median(), 2), "|lech|<1:", round((df.abs() < 1).mean(), 3),
      "lech min/max", round(df.min(), 1), round(df.max(), 1))
x = j[j.status.isin(OK) & ~j.status_e.isin(OK)]
print("NMPC dat, EKF khong:", len(x), x.status_e.value_counts().to_dict(), "vuot V (mV)",
      round(x.viol_V_mV_e.min(), 2), round(x.viol_V_mV_e.max(), 2), "eta vi pham", int((x.viol_eta_mV_e > 0).sum()))
e = d[d.method == "ekf"]
print("RMSE SOC TB/max", round(e.est_soc_rmse_pct.mean(), 2), round(e.est_soc_rmse_pct.max(), 2),
      "RMSE eta TB/max", round(e.est_eta_rmse_mV.mean(), 2), round(e.est_eta_rmse_mV.max(), 2))
t = e[e.status == "ok_tol"]
print("ok_tol", len(t), "thieu", round(t.under_pct.min(), 2), round(t.under_pct.max(), 2))
q = e[e.status.isin(OK)]
print("EKF k=inf giam: trung vi", round(q[np.isinf(q.k)].reduction_pct.median(), 1))
