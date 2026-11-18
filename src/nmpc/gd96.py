"""Trang thai cham diem theo GD-96 (nguoi dung quyet 19/11/2026), dung chung cho cac bang
NMPC (pilot, NMPC + EKF, luoi day du). Chi doc cot CSV do pilot_run.m ghi.

  ok           nap du (thieu <= 0.2 % SOC so voi dien tich CCCV), vuot V_cv <= 1 mV, khong vi pham
  ok_tol       "dat trong dung sai": thieu <= 0.5 % SOC va vuot V_cv <= 2 mV (so that van ghi)
  ok_violation eta_Li < delta (> 1 mV), T > T_max (> 0.1 K), x_s > 0.99 (> 1e-3) hoac vuot V_cv > 2 mV
  failed       khong dung dung (nmpc_reason khac soc_reached/Icut), vuot ngan sach, hoac thieu > 0.5 % SOC
  infeasible / error giu nguyen
"""
import math

UNDER_OK = 0.2      # % SOC: nguong cu cua pilot_run.m (2e-3)
UNDER_TOL = 0.5     # % SOC, GD-96
V_OK = 1.0          # mV, nguong cu
V_TOL = 2.0         # mV, GD-96


def fnum(x):
    try:
        return float(x)
    except (TypeError, ValueError):
        return math.nan


def under_pct(r):
    """Nap thieu so voi dien tich CCCV (% SOC, duong = thieu)."""
    return 100 * (fnum(r.get('cccv_soc_end')) - fnum(r.get('soc_end')))


def status(r):
    raw = r.get('status', '')
    if raw in ('infeasible', 'error') or r.get('nmpc_reason') in ('infeasible_budget', 'error'):
        return raw
    under = under_pct(r)
    ts = max(fnum(r.get('Ts_s')), 1e-3 * fnum(r.get('budget_s')))
    vb = fnum(r.get('viol_budget_s'))
    reached = r.get('nmpc_reason') in ('soc_reached', 'Icut') and math.isfinite(under) and under <= UNDER_TOL \
        and not (math.isfinite(vb) and vb > ts)
    if not reached:
        return 'failed'
    vV, ve, vT, vx = (fnum(r.get(c)) for c in ('viol_V_mV', 'viol_eta_mV', 'viol_T_K', 'viol_xs'))
    g = lambda x: x if math.isfinite(x) else 0.0
    if g(ve) > 1.0 or g(vT) > 0.1 or g(vx) > 1e-3 or g(vV) > V_TOL:
        return 'ok_violation'
    if under > UNDER_OK or g(vV) > V_OK:
        return 'ok_tol'
    return 'ok'


def cccv_status(r):
    """CCCV cung luat: CCCV dung o Qstop/Icut (cccv_complete) va do vi pham cung cach."""
    if str(r.get('cccv_complete', '')).strip().lower() not in ('1', 'true'):
        return 'failed'
    vV, ve, vT, vx = (fnum(r.get(c)) for c in ('cccv_viol_V_mV', 'cccv_viol_eta_mV', 'cccv_viol_T_K', 'cccv_viol_xs'))
    g = lambda x: x if math.isfinite(x) else 0.0
    if g(ve) > 1.0 or g(vT) > 0.1 or g(vx) > 1e-3 or g(vV) > V_TOL:
        return 'ok_violation'
    if g(vV) > V_OK:
        return 'ok_tol'
    return 'ok'


COMPARABLE = ('ok', 'ok_tol', 'ok_violation')
