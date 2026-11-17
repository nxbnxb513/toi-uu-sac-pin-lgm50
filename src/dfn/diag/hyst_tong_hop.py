# Tong hop CSV cua diag_hyst (artifact hyst-*): python3 hyst_tong_hop.py <thu_muc_artifact> [protocol|charge|dis|decomp] [bien_the]
import csv, glob, os, sys, statistics as st, math
D = sys.argv[1]
def rd(p):
    with open(p) as f:
        return list(csv.DictReader(f))
def fl(x):
    try:
        v = float(x); return v
    except: return float('nan')
def med(v):
    v = [x for x in v if not math.isnan(x)]
    return st.median(v) if v else float('nan')
def rng(v):
    v = [x for x in v if not math.isnan(x)]
    return (min(v), max(v)) if v else (float('nan'),)*2
PH = {}
for p in glob.glob(os.path.join(D, '**', 'hyst_*_phases.csv'), recursive=True):
    for r in rd(p):
        PH.setdefault(r['variant'], []).append(r)
DC = {}
for p in glob.glob(os.path.join(D, '**', 'hyst_*_decomp.csv'), recursive=True):
    for r in rd(p):
        DC.setdefault(r['variant'], []).append(r)
mode = sys.argv[2] if len(sys.argv) > 2 else 'all'
variants = sorted(PH)
if 'base' in variants: variants.remove('base'); variants = ['base'] + variants

if mode in ('all', 'protocol'):
    print('## Protocol (base)')
    for T in ['0', '10', '25']:
        rs = [r for r in PH.get('base', []) if r['T_degC'] == T]
        for typ in ['CHA', 'DCH']:
            q = [r for r in rs if r['type'] == typ]
            if not q: continue
            f = lambda k: [fl(r[k]) for r in q]
            print(T, typ, 'n', len(q), 'after_dis', sorted(set(r['after_dis'] for r in q)),
                  'I med %.3f rng %s' % (med(f('Iset')), rng(f('Iset'))), 'Iend', rng(f('Iend')),
                  'rest_before', rng(f('rest_before_s')), 'T0', rng(f('T0')), 't_first', rng(f('t_first')), 'dt_med', rng(f('dt_med')),
                  'rest_after', rng(f('rest_after_s')))

if mode in ('all', 'charge'):
    print('## Charge (after discharge only), median over cells [min max]')
    keys = ['tCC_exp', 'tCC_sim', 'QCC_exp', 'QCC_sim', 'tCV_exp', 'tCV_sim', 'Qtot_exp', 'Qtot_sim', 'V_end_CC', 'xsn_max',
            'dV_f10', 'dV_f25', 'dV_f50', 'dV_f75', 'dV_f90', 'dV_f98', 'mean_CC_mV', 'rmse_CC_mV', 'dT98_exp', 'dT98_sim',
            'Vr_after_exp', 'Vr_after_sim', 'Vr_after600_exp', 'Vr_after600_sim', 'q0', 'q_after', 'q_after_chgbr', 'closure_Ah',
            'dV_first_exp', 'dV_first_sim', 'dV10_exp', 'dV10_sim', 'dV60_exp', 'dV60_sim', 'Vr_before', 't_first']
    for v in variants:
        for T in ['0', '10', '25']:
            q = [r for r in PH[v] if r['T_degC'] == T and r['type'] == 'CHA' and r['after_dis'] == '1']
            if not q: continue
            stops = {}
            for r in q: stops[r['stop_CC']] = stops.get(r['stop_CC'], 0) + 1
            out = []
            for k in keys:
                vals = [fl(r[k]) for r in q]
                sc = 1e3 if k.startswith('dV_first') or k.startswith('dV10') or k.startswith('dV60') else 1
                out.append('%s=%.4g[%.4g,%.4g]' % (k, sc*med(vals), sc*rng(vals)[0], sc*rng(vals)[1]))
            print(v, T, 'n=%d' % len(q), 'stop', stops, ' '.join(out))

if mode in ('all', 'dis'):
    print('## Discharge per C-rate: rmse90 / mean90 / cap')
    for v in variants:
        line = [v]
        allr = []
        for T in ['0', '10', '25']:
            for c in ['0.1', '0.5', '1', '2']:
                q = [r for r in PH[v] if r['T_degC'] == T and r['type'] == 'DCH' and fl(r['crate_file']) == fl(c) and not math.isnan(fl(r['rmse_dis90_mV']))]
                if not q: continue
                r90 = [fl(r['rmse_dis90_mV']) for r in q]; allr += r90
                line.append('%sC/%s: %.1f(%+.1f) cap %.3f/%.3f q05 %+.1f' % (T, c, st.mean(r90), med([fl(r['mean_dis90_mV']) for r in q]),
                    med([fl(r['cap_exp']) for r in q]), med([fl(r['cap_sim']) for r in q]), med([fl(r['dV_q05']) for r in q])))
        if allr: line.append('MEAN rmse90 over all discharges %.1f (n=%d)' % (st.mean(allr), len(allr)))
        print(' | '.join(line))
    print('## Discharge jumps / closure (base)')
    for T in ['0', '10', '25']:
        for c in ['0.1', '0.5', '1', '2']:
            q = [r for r in PH.get('base', []) if r['T_degC'] == T and r['type'] == 'DCH' and fl(r['crate_file']) == fl(c)]
            if not q: continue
            f = lambda k: [fl(r[k]) for r in q]
            print(T, c, 'I', med(f('Iset')), 'Vr_before', med(f('Vr_before')), 'dV1 exp/sim %.1f/%.1f' % (1e3*med(f('dV_first_exp')), 1e3*med(f('dV_first_sim'))),
                  't1', med(f('t_first')), 'dV10 %.1f/%.1f dV60 %.1f/%.1f' % (1e3*med(f('dV10_exp')), 1e3*med(f('dV10_sim')), 1e3*med(f('dV60_exp')), 1e3*med(f('dV60_sim'))),
                  'Vr_after', med(f('Vr_after_exp')), 'closure', med(f('closure_Ah')), 'q0', med(f('q0')), 'q_after', med(f('q_after')))

if mode in ('all', 'decomp'):
    v = sys.argv[3] if len(sys.argv) > 3 else 'base'
    terms = ['V', 'ocv_bulk', 'hys', 'hys_p', 'hys_n', 'sd_p', 'sd_n', 'eta_p', 'eta_n', 'film', 'e_ohm', 'e_diff', 's_ohm', 'IRc', 'resid', 'T', 'xbar', 'ybar', 'xs_n_max', 'j0n_mean', 'j0p_mean', 'jsep_rel']
    for T in ['0', '10', '25']:
        rows = [r for r in DC.get(v, []) if r['T_degC'] == T]
        cells = sorted(set(r['cell'] for r in rows))
        for cell in cells[:2]:
            ch = [r for r in rows if r['cell'] == cell and r['kind'] == '1']
            blocks = sorted(set(r['block'] for r in ch), key=int)
            if not blocks: continue
            ch = [r for r in ch if r['block'] == blocks[-1]]
            dis = [r for r in rows if r['cell'] == cell and r['kind'] == '5']
            if not dis: continue
            # choose charge points: last point (end CC), and points at xbar targets
            dis.sort(key=lambda r: fl(r['xbar']))
            def interp_dis(x, k):
                xs = [fl(r['xbar']) for r in dis]; ys = [fl(r[k]) for r in dis]
                for i in range(len(xs) - 1):
                    if xs[i] <= x <= xs[i+1]:
                        w = (x - xs[i]) / (xs[i+1] - xs[i]) if xs[i+1] > xs[i] else 0
                        return ys[i] + w * (ys[i+1] - ys[i])
                return float('nan')
            n = len(ch)
            picks = [ch[int(n*f)] for f in (0.5, 0.75, 0.9)] + [ch[-2], ch[-1]]
            print('### decomp %s T=%s cell %s (charge block %s, last t=%s s, Vexp at pick)' % (v, T, cell, blocks[-1], ch[-1]['t']))
            for r in picks:
                x = fl(r['xbar'])
                s = 't=%5.0f xbar=%.4f Vexp=%.4f | ' % (fl(r['t']), x, fl(r['V_exp']))
                s += ' '.join('%s=%.1f/%.1f' % (k, 1e3*fl(r[k]) if k not in ('T', 'xbar', 'ybar', 'xs_n_max', 'j0n_mean', 'j0p_mean', 'jsep_rel') else fl(r[k]),
                              1e3*interp_dis(x, k) if k not in ('T', 'xbar', 'ybar', 'xs_n_max', 'j0n_mean', 'j0p_mean', 'jsep_rel') else interp_dis(x, k)) for k in terms)
                print(s)
