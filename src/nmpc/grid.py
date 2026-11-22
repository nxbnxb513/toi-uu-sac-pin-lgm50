"""Luoi so sanh day du (grid.yml): lap ke hoach cac job con lai va gop ket qua.
Chi doc CSV do pilot_run.m ghi (moi truong hop mot file pilot_w<iw>_c<10C>_T<T>_k<ik>.csv).

  python3 src/nmpc/grid.py plan   <thu muc ket qua cu> <wins> <cbases> <temps> <ks> <methods> <kper> <maxjobs>
      -> in JSON {"include": [...]} cua cac job con thieu (moi job = mot vung x mot dong CCCV x
         mot nhiet do x mot phuong phap x toi da kper muc k) va so truong hop con lai.
  python3 src/nmpc/grid.py report <thu muc ket qua (moi run)> <thu muc ra>

Truong hop "da xong" = co dong CSV va nmpc_reason khac 'wall_limit' (het gio cua job thi chay
lai). Trang thai cham theo GD-96 (gd96.py).
"""
import csv, glob, json, math, os, re, sys, statistics
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gd96

KS = [0.8, 1, 1.25, 1.5, 2, 3, math.inf]
METHODS = {'nmpc': 'pilot', 'ekf': 'pilot+ekf'}
VAR2M = {v: m for m, v in METHODS.items()}
PAT = re.compile(r'pilot_w(\d+)_c([\d.]+)_T([-\d.]+)_k(\d)\.csv$')


def read_rows(root):
    rows = []
    for p in glob.glob(os.path.join(root, '**', 'pilot_w*_k*.csv'), recursive=True):
        m = PAT.search(os.path.basename(p))
        if not m:
            continue
        with open(p, newline='') as fh:
            for r in csv.DictReader(fh):
                r['_ik'] = int(m.group(4))
                r['_file'] = p
                r['method'] = VAR2M.get(r.get('variant', ''), r.get('variant', ''))
                rows.append(r)
    return rows


def ckey(r):
    return (r['method'], int(float(r['iw'])), round(float(r['Cbase']), 3), round(float(r['Tamb_C']), 1), r['_ik'])


def best(rows):
    """Moi truong hop giu mot dong: uu tien dong khong bi het gio job, sau do dong moi nhat (mtime)."""
    out = {}
    for r in rows:
        k = ckey(r)
        o = out.get(k)
        rank = (r.get('nmpc_reason') != 'wall_limit', os.path.getmtime(r['_file']))
        if o is None or rank > o[0]:
            out[k] = (rank, r)
    return {k: v[1] for k, v in out.items()}


CKPAT = re.compile(r'ckpt_w(\d+)_c([\d.]+)_T([-\d.]+)_k(\d)\.mat$')


def checkpoints(root):
    """Diem luu giua chung (GD-98) con dung: {key: 'runid:artifact'} cua run moi nhat.
    Cau truc thu muc: <root>/<runid>/<artifact gcase-<m>-...>/ckpt_*.mat"""
    out = {}
    for p in glob.glob(os.path.join(root, '*', 'g*-*', 'ckpt_*.mat')):
        m = CKPAT.search(os.path.basename(p))
        art = os.path.basename(os.path.dirname(p))
        rid = os.path.basename(os.path.dirname(os.path.dirname(p)))
        meth = art.split('-')[1]
        c10 = float(m.group(2))
        key = (meth, int(m.group(1)), round(c10 / 10, 3), round(float(m.group(3)), 1), int(m.group(4)))
        if key not in out or int(rid) > int(out[key].split(':')[0]):
            out[key] = f'{rid}:{art}'
    return out


def plan(prev, wins, cbases, temps, ks, methods, kper, maxjobs):
    done = {k for k, r in best(read_rows(prev)).items() if r.get('nmpc_reason') != 'wall_limit'} if os.path.isdir(prev) else set()
    ck = checkpoints(prev) if os.path.isdir(prev) else {}
    jobs, nleft = [], 0
    for m in methods:
        for w in wins:
            for c in cbases:
                for T in temps:
                    left = [ik for ik in ks if (m, w, round(c, 3), round(float(T), 1), ik) not in done]
                    nleft += len(left)
                    for i in range(0, len(left), kper):
                        kk = left[i:i + kper]
                        rs = sorted({ck[(m, w, round(c, 3), round(float(T), 1), ik)] for ik in kk
                                     if (m, w, round(c, 3), round(float(T), 1), ik) in ck})
                        jobs.append(dict(m=m, v=METHODS[m], w=w, c=c, T=T, ks=' '.join(str(x) for x in kk),
                                         n='-'.join(str(x) for x in kk), rs=' '.join(rs)))
    # xen ke cac phuong phap/dong de tai deu cac dot 20 job
    W = [(a, b) for a in range(5) for b in range(a + 1, 6)]   # = soc_windows.m (chi so 1..15)
    span = lambda w: (W[w - 1][1] - W[w - 1][0]) + (1 if W[w - 1][1] == 5 else 0)   # vung toi 100 % co pha CV dai
    # job dai (vung rong, dong nho, co diem luu) chay truoc de cac lan chay tiep bat dau som
    jobs.sort(key=lambda j: (-bool(j['rs']), -span(j['w']), j['c'], j['T'], j['w'], j['m']))
    print(json.dumps({'include': jobs[:maxjobs]}))
    sys.stderr.write(f'con {nleft} truong hop ({sum(1 for j in jobs if j["rs"])} job co diem luu), {len(jobs)} job; '
                     f'chay {min(len(jobs), maxjobs)} job lan nay\n')
    return jobs, nleft


def fnum(x):
    return gd96.fnum(x)


def report(root, outdir):
    os.makedirs(outdir, exist_ok=True)
    B = best(read_rows(root))
    keys = sorted(B, key=lambda k: (k[1], k[2], k[3], k[4], k[0]))
    cols = ['method', 'iw', 'window', 'Cbase', 'Tamb_C', 'k', 'status', 'status_raw', 'nmpc_reason', 'under_pct', 'soc_end',
            'cccv_soc_end', 'budget_s', 't_charge_s', 'T_CCCV_s', 'cccv_perm_mAh', 'nmpc_perm_mAh', 'reduction_pct',
            'viol_V_mV', 'viol_eta_mV', 'viol_T_K', 'viol_xs', 'nmpc_eta_min_mV', 'nmpc_Tmax_C', 'cccv_status',
            'cccv_viol_V_mV', 'cccv_viol_eta_mV', 'cccv_viol_T_K', 'cccv_Tmax_C', 'cccv_eta_min_mV', 'aging_source',
            'n_solves', 'n_fail', 'solve_mean_ms', 'case_wall_s', 'prep_wall_s', 'closed_loop_wall_s', 'cl_wall_total_s', 'n_resume',
            'num_steps', 'job_wall_s',
            'cccv_perm_sei_mAh', 'cccv_perm_dead_mAh', 'cccv_perm_lam_mAh', 'nmpc_perm_sei_mAh', 'nmpc_perm_dead_mAh',
            'nmpc_perm_lam_mAh', 'cccv_pl_peak_mAh', 'nmpc_pl_peak_mAh',
            'n_status0', 'n_status2', 'sqp_mean', 'solve_median_ms', 'solve_p95_ms', 'build_s',
            'est_soc_rmse_pct', 'est_eta_rmse_mV', 'src']
    out = []
    for k in keys:
        r = B[k]
        st = gd96.status(r)
        pe, pc = fnum(r.get('nmpc_perm_mAh')), fnum(r.get('cccv_perm_mAh'))
        d = {c: r.get(c, '') for c in cols}
        d.update(method=k[0], status=st, status_raw=r.get('status', ''), under_pct=gd96.under_pct(r),
                 reduction_pct=100 * (1 - pe / pc) if st in gd96.COMPARABLE else math.nan,
                 cccv_status=gd96.cccv_status(r), src=os.path.relpath(r['_file'], root).split(os.sep)[0])
        out.append(d)
    with open(os.path.join(outdir, 'grid_all.csv'), 'w', newline='') as fh:
        w = csv.DictWriter(fh, fieldnames=cols, lineterminator='\n')
        w.writeheader()
        w.writerows(out)
    L = ['# Luoi so sanh day du: tong hop', '', f'{len(out)} truong hop (moi phuong phap x vung x dong x nhiet do x k).', '',
         '## Trang thai (GD-96)', '', '| phuong phap | ok | ok_tol | ok_violation | failed | infeasible | error | het gio (wall_limit) |',
         '|---|---|---|---|---|---|---|---|']
    for m in METHODS:
        R = [d for d in out if d['method'] == m]
        c = lambda s: sum(d['status'] == s for d in R)
        L.append(f"| {m} | {c('ok')} | {c('ok_tol')} | {c('ok_violation')} | {c('failed')} | {c('infeasible')} | {c('error')} | "
                 f"{sum(d['nmpc_reason'] == 'wall_limit' for d in R)} |")
    cc = {}
    for d in out:
        cc[(d['window'], float(d['Cbase']), float(d['Tamb_C']))] = d
    L += ['', '## CCCV (GD-96/GD-97: bao nguyen trang; "cccv_vi_pham" = CCCV vi pham an toan tren DFN)', '',
          '| vung | C | T (°C) | trang thai CCCV | eta_Li min (mV) | T max (°C) | NMPC k = 1 (nmpc / ekf) |', '|---|---|---|---|---|---|---|']
    for key in sorted(cc, key=lambda x: (x[1], x[2], x[0])):
        d = cc[key]
        if d['cccv_status'] == 'ok':
            continue
        k1 = {m: next((e['status'] for e in out if e['method'] == m and (e['window'], float(e['Cbase']), float(e['Tamb_C'])) == key
                       and fnum(e['k']) == 1), '—') for m in METHODS}
        L.append(f"| {key[0]} | {key[1]:g} | {key[2]:g} | {d['cccv_status']} | {fnum(d['cccv_eta_min_mV']):.1f} | "
                 f"{fnum(d['cccv_Tmax_C']):.1f} | {k1['nmpc']} / {k1['ekf']} |")
    L += ['', '## Thoi gian chay moi truong hop (case_wall_s, s)', '',
          '| phuong phap | C | T (°C) | n | TB | trung vi | max | phan chung/job TB (s) |', '|---|---|---|---|---|---|---|---|']
    groups = {}
    for d in out:
        groups.setdefault((d['method'], float(d['Cbase']), float(d['Tamb_C'])), []).append(d)
    for g in sorted(groups):
        v = [fnum(d['case_wall_s']) for d in groups[g] if math.isfinite(fnum(d['case_wall_s']))]
        p = [fnum(d['prep_wall_s']) for d in groups[g] if math.isfinite(fnum(d['prep_wall_s']))]
        if v:
            L.append(f'| {g[0]} | {g[1]:g} | {g[2]:g} | {len(v)} | {statistics.mean(v):.0f} | {statistics.median(v):.0f} | '
                     f'{max(v):.0f} | {statistics.mean(p) if p else math.nan:.0f} |')
    L += ['', '## Tung truong hop', '', '| PP | vung | C | T | k | trang thai | thieu (% SOC) | V / eta vi pham (mV) | mat CCCV | mat PP | giam (%) | t case (s) |',
          '|---|---|---|---|---|---|---|---|---|---|---|---|']
    for d in out:
        f2 = lambda x, n=2: '—' if not math.isfinite(fnum(x)) else f'{fnum(x):.{n}f}'
        L.append(f"| {d['method']} | {d['window']} | {float(d['Cbase']):g} | {float(d['Tamb_C']):g} | {d['k']} | {d['status']} | "
                 f"{f2(d['under_pct'])} | {f2(d['viol_V_mV'])} / {f2(d['viol_eta_mV'])} | {f2(d['cccv_perm_mAh'], 5)} | "
                 f"{f2(d['nmpc_perm_mAh'], 5)} | {f2(d['reduction_pct'], 1)} | {f2(d['case_wall_s'], 0)} |")
    open(os.path.join(outdir, 'grid_summary.md'), 'w').write('\n'.join(L) + '\n')
    print('\n'.join(L[:40]))


if __name__ == '__main__':
    cmd = sys.argv[1]
    if cmd == 'plan':
        a = sys.argv[2:]
        plan(a[0], json.loads(a[1]), json.loads(a[2]), json.loads(a[3]), json.loads(a[4]), json.loads(a[5]), int(a[6]), int(a[7]))
    elif cmd == 'report':
        report(sys.argv[2], sys.argv[3])
    else:
        raise SystemExit(__doc__)
