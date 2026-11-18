"""Gop ket qua chay thu NMPC + EKF (pilot_run, bien the pilot+ekf) va so voi CCCV va
NMPC biet het trang thai (tai_lieu/ket_qua_pilot_nmpc.csv). Chi doc CSV do MATLAB ghi.
  python3 src/nmpc/ekf_pilot_table.py <thu muc artifact> <csv ra> <md bang ra>
"""
import csv, glob, math, os, sys

def f(x):
    try:
        return float(x)
    except (TypeError, ValueError):
        return math.nan

def key(r):
    k = f(r['k'])
    return (int(f(r['iw'])), round(f(r['Cbase']), 3), k if math.isfinite(k) else 1e9)

def fmt(x, d=1, dash='—'):
    return dash if not math.isfinite(x) else f'{x:.{d}f}'

def main(indir, out_csv, out_md):
    rows = []
    for p in glob.glob(os.path.join(indir, '**', 'pilot_w*_k*.csv'), recursive=True):
        b = os.path.basename(p)
        if any(s in b for s in ('_series', '_solves')):
            continue
        with open(p, newline='') as fh:
            rows += list(csv.DictReader(fh))
    full = {}
    with open('tai_lieu/ket_qua_pilot_nmpc.csv', newline='') as fh:
        for r in csv.DictReader(fh):
            full[key(r)] = r
    rows.sort(key=key)
    out = []
    for r in rows:
        fs = full.get(key(r), {})
        pe, pc, pf = f(r['nmpc_perm_mAh']), f(r['cccv_perm_mAh']), f(fs.get('nmpc_perm_mAh'))
        ok = r['status'] in ('ok', 'ok_violation')
        d = dict(window=r['window'], Cbase=r['Cbase'], k=r['k'], budget_s=r['budget_s'], status=r['status'],
                 status_full=fs.get('status', ''), nmpc_reason=r['nmpc_reason'], t_charge_s=r['t_charge_s'],
                 t_charge_full_s=fs.get('t_charge_s', ''), cccv_perm_mAh=pc,
                 cccv_perm_full_run_mAh=f(fs.get('cccv_perm_mAh')), ekf_perm_mAh=pe, full_perm_mAh=pf,
                 red_ekf_pct=100 * (1 - pe / pc) if ok else math.nan,
                 red_full_pct=f(fs.get('reduction_pct')),
                 ekf_vs_full_pct=100 * (pe / pf - 1) if ok and fs.get('status') in ('ok', 'ok_violation') else math.nan,
                 eta_min_mV=f(r['nmpc_eta_min_mV']), eta_min_full_mV=f(fs.get('nmpc_eta_min_mV')),
                 viol_V_mV=f(r['viol_V_mV']), viol_eta_mV=f(r['viol_eta_mV']), viol_T_K=f(r['viol_T_K']),
                 viol_xs=f(r['viol_xs']), Vmax=f(r['nmpc_Vmax']), Tmax_C=f(r['nmpc_Tmax_C']),
                 cccv_eta_min_mV=f(r['cccv_eta_min_mV']))
        for c in ('est_soc0_err_pct', 'est_soc_rmse_pct', 'est_soc_maxabs_pct', 'est_soc_end_err_pct', 'est_eta_rmse_mV',
                  'est_eta_over_max_mV', 'est_eta_under_max_mV', 'est_eta_over_max_late_mV', 'est_eta_rmse_late_mV',
                  'est_eta_sd_med_mV', 'ekf_ms_per_step', 'ekf_steps', 'ekf_wall_s', 'n_solves', 'n_fail',
                  'n_status0', 'n_status2', 'n_status_other', 'solve_mean_ms', 'solve_median_ms', 'solve_p95_ms',
                  'solve_max_ms', 'sqp_mean', 'closed_loop_wall_s', 'job_wall_s', 'T_min_safe_s'):
            d[c] = f(r.get(c))
        d['solve_mean_full_ms'] = f(fs.get('solve_mean_ms'))
        out.append(d)
    with open(out_csv, 'w', newline='') as fh:
        w = csv.DictWriter(fh, fieldnames=list(out[0].keys()))
        w.writeheader()
        w.writerows(out)
    L = ['| Vùng | CCCV | k | trạng thái (biết hết TT) | t sạc (s) | mất CCCV (mAh) | mất NMPC+EKF (mAh) | giảm so CCCV (%) | giảm biết hết TT (%) | NMPC+EKF so biết hết TT (%) | η_Li min DFN (mV) | vi phạm V / η (mV) | T max (°C) | sai SOC đầu (%) | SOC RMSE / max (%) | η RMSE (mV) | η ước cao max (mV) | lần giải / thất bại | giải TB (ms) | EKF (ms/bước) |',
         '|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|']
    for d in out:
        kk = f(d['k'])
        ks = '∞' if not math.isfinite(kk) else f'{kk:g}'
        st = d['status'] + (f" ({d['status_full']})" if d['status_full'] else '')
        L.append(f"| {d['window']} | {float(d['Cbase']):g}C | {ks} | {st} | {fmt(f(d['t_charge_s']), 0)} | {d['cccv_perm_mAh']:.5f} | "
                 f"{fmt(d['ekf_perm_mAh'], 5)} | {fmt(d['red_ekf_pct'])} | {fmt(d['red_full_pct'])} | {fmt(d['ekf_vs_full_pct'], 2)} | "
                 f"{fmt(d['eta_min_mV'])} | {fmt(d['viol_V_mV'], 2)} / {fmt(d['viol_eta_mV'], 2)} | {fmt(d['Tmax_C'], 1)} | "
                 f"{fmt(d['est_soc0_err_pct'], 2)} | {fmt(d['est_soc_rmse_pct'], 2)} / {fmt(d['est_soc_maxabs_pct'], 2)} | "
                 f"{fmt(d['est_eta_rmse_mV'], 1)} | {fmt(d['est_eta_over_max_mV'], 1)} | {fmt(d['n_solves'], 0)} / {fmt(d['n_fail'], 0)} | "
                 f"{fmt(d['solve_mean_ms'], 0)} | {fmt(d['ekf_ms_per_step'], 0)} |")
    open(out_md, 'w').write('\n'.join(L) + '\n')
    print('\n'.join(L))

if __name__ == '__main__':
    main(*sys.argv[1:4])
