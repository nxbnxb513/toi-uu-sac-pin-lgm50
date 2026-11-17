function [y, o, ok] = ag_exec(par, y, steps)
%AG_EXEC  Chay chuoi buoc bang dfn_run; khong nem loi (ok = false neu khoi tao/giai that bai).
% Neu ode15s that bai giua mot buoc ("solver_failed"), KHOI DONG LAI tu trang thai cuoi cung
% hop le cua buoc do (khoi tao nhat quan lai, xoa lich su BDF) va chay not phan thoi gian con
% lai cua buoc, toi da 4 lan (bien phap so hoc, ghi lai so lan trong o.restarts).
ok = true; o = []; restarts = 0;
todo = steps;
while true
    try
        oo = dfn_run(par, y, todo);
    catch err
        fprintf('ag_exec: LOI %s\n', err.message);
        oo = struct('reason', {{'error'}}, 't', 0, 'V', NaN, 'I', NaN, 'T', NaN, 'Q', NaN, 'step', 0, 'y_end', y);
        o = merge(o, oo); ok = false; break
    end
    o = merge(o, oo);
    y = oo.y_end;
    k = find(strcmp(oo.reason, 'solver_failed'), 1);
    if isempty(k), break; end
    diag_fail(par, y);
    restarts = restarts + 1;
    if restarts > 4, ok = false; break; end
    tk = oo.t(oo.step == k);
    done_k = tk(end) - tk(1);
    rest = todo(k:end);
    rest(1).tmax = rest(1).tmax - done_k;
    if ~isempty(rest(1).tout) && numel(rest(1).tout) > 1
        rest(1).tout = rest(1).tout - done_k;
        rest(1).tout = rest(1).tout(rest(1).tout > 0);
    else
        rest(1).tout = rest(1).tmax;
    end
    if rest(1).tmax <= 0, rest = rest(2:end); end
    if isempty(rest), break; end
    fprintf('ag_exec: khoi dong lai lan %d tu buoc %d (con %.1f s)\n', restarts, k, rest(1).tmax);
    todo = rest;
end
o.restarts = restarts;
end

function o = merge(o, oo)
% noi ket qua (chi cac truong dung o ag_*: t, V, I, T, Q, step, reason)
if isempty(o)
    o = oo; o.reason = o.reason(~cellfun(@isempty, o.reason)); return
end
t0 = o.t(end);
o.t = [o.t; t0 + oo.t]; o.V = [o.V; oo.V]; o.I = [o.I; oo.I]; o.T = [o.T; oo.T]; o.Q = [o.Q; oo.Q];
o.step = [o.step; max(o.step) + oo.step];
r = oo.reason(~cellfun(@isempty, oo.reason));
o.reason = [o.reason, r];
o.y_end = oo.y_end;
end

function diag_fail(par, y)
if ~(isfield(par, 'aging') && par.aging.on), return; end
try
    [~, a] = dfn_rhs(0, y, par, struct('mode', 'I', 'value', y(par.ix.I), 'Tamb', y(par.ix.T)));
    G = par.ix.ag;
    fprintf(['  lao hoa: c_Li [%.3g, %.3g], c_dl max %.3g mol/m3; eta_pl [%.4f, %.4f] V; j_Li [%.3g, %.3g] A/m2;\n', ...
             '  j_SEI [%.3g, %.3g]; sigma_t,n [%.3g, %.3g] Pa; sigma_t,p [%.3g, %.3g]; eps_n min %.5f; l_cr max %.3g; eps_s [%.5f, %.5f]\n'], ...
        min(y(G.cLi)), max(y(G.cLi)), max(y(G.cdl)), min(a.etapl), max(a.etapl), min(a.jLi), max(a.jLi), ...
        min(a.jSEI), max(a.jSEI), min(a.sigt_n), max(a.sigt_n), min(a.sigt_p), max(a.sigt_p), a.eps_min, a.lcr_max, ...
        min(y(G.epsn)), max(y(G.epsp)));
catch
end
end
