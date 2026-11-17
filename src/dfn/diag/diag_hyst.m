function diag_hyst(variant, Tdeg, datadir, outdir)
%DIAG_HYST  (CHAN DOAN) Nguon goc sai lech dien ap pha SAC so voi du lieu mo
% Zenodo 4864437 (Brosa Planella 2021; cell LG M50; sac CC 1.67 A toi 4.2 V, CV toi
% 0.25 A; xa CC toi 2.5 V; nghi 2 h giua cac pha). Chi doc du lieu, KHONG chinh tham so.
% Cho moi pha CHA va DCH (theo thu tu trong file) cua moi cell o nhiet do Tdeg:
%  (a) giao thuc do thuc (dong, thoi gian nghi truoc, T, chu ky lay mau, buoc nhay ap
%      khi dong bat, ap nghi truoc/sau, do tang nhiet);
%  (b) mo phong cung pha (trang thai dau: OCV mo hinh nhanh xa = ap nghi do, GD-13;
%      T dau = T moi truong = T be mat truoc pha, GD-09); sai so dien ap co dau;
%  (c) tach V cua mo hinh thanh cac thanh phan (diag_decomp) doc theo pha;
%  (d) them mot lan xa mo hinh voi DUNG dong sac (1.67 A) tu trang thai day, de so
%      sanh sac/xa o cung SOC va cung do lon dong;
%  (e) "khep Ah": q(ap nghi truoc) - q(ap nghi sau) theo OCV mo hinh so voi Ah do.
% Dau ra: outdir/hyst_<variant>_<T>degC_phases.csv, ..._decomp.csv
if ischar(Tdeg) || isstring(Tdeg), Tdeg = str2double(Tdeg); end
if ~exist(outdir, 'dir'), mkdir(outdir); end
[par, desc] = diag_variant(variant);
fprintf('=== diag_hyst %s (%s), %d degC ===\n', variant, desc, Tdeg);
files = dir(fullfile(datadir, sprintf('%ddegC', Tdeg), 'Cell*.csv'));
PH = []; DC = [];
for fi = 1:numel(files)
    fn = fullfile(files(fi).folder, files(fi).name);
    d = val_read_cell(fn);
    cellid = str2double(regexp(files(fi).name, 'Cell(\d+)', 'tokens', 'once'));
    crt = regexp(files(fi).name, '_([0-9p]+)C_', 'tokens', 'once'); crt = str2double(strrep(crt{1}, 'p', '.'));
    code = zeros(numel(d.V), 1);
    code(strcmp(d.status, 'PAU')) = 1; code(strcmp(d.status, 'CHA')) = 2; code(strcmp(d.status, 'DCH')) = 3;
    bs = find([true; diff(code) ~= 0]); be = [bs(2:end) - 1; numel(code)];
    seenDis = false; did167 = false;
    bc = code(bs); bl = be - bs + 1;
    fprintf('  file %s: %d khoi [%s]\n', files(fi).name, numel(bs), sprintf('%d(%d) ', [bc bl].'));
    for b = 1:numel(bs)
        if ~(bc(b) == 2 || bc(b) == 3) || bl(b) < 10, continue; end
        % khoi nghi lien truoc / lien sau (bo qua cac khoi trang thai khac, ngan)
        bp = b - 1; while bp >= 1 && bc(bp) == 0 && bl(bp) < 5, bp = bp - 1; end
        bn = b + 1; while bn <= numel(bs) && bc(bn) == 0 && bl(bn) < 5, bn = bn + 1; end
        if bp < 1 || bc(bp) ~= 1, continue; end
        ischa = bc(b) == 2;
        a = bs(b); e = be(b); pz = be(bp);
        R = blankrow();
        R.variant = string(variant); R.T_degC = Tdeg; R.cell = cellid; R.crate_file = crt; R.block = b;
        R.type = string(ternary(ischa, 'CHA', 'DCH')); R.after_dis = double(seenDis);
        R.rest_before_s = d.tstep(pz); R.Vr_before = d.V(pz); R.T0 = d.Tcell(pz);
        t = d.tstep(a:e); V = d.V(a:e); Ia = d.I(a:e); Tc = d.Tcell(a:e);
        R.t_first = t(1); R.dt_med = median(diff(t));
        R.dV_first_exp = V(1) - R.Vr_before;
        R.dV10_exp = interp_ok(t, V, 10) - R.Vr_before; R.dV60_exp = interp_ok(t, V, 60) - R.Vr_before;
        hasAfter = bn <= numel(bs) && bc(bn) == 1;
        if hasAfter
            r1 = bs(bn); r2 = be(bn); tr = d.tstep(r1:r2); Vr = d.V(r1:r2);
            R.rest_after_s = tr(end); R.Vr_after_exp = Vr(end);
            R.Vr_after10_exp = interp_ok(tr, Vr, 10); R.Vr_after600_exp = interp_ok(tr, Vr, 600);
            R.Vlast_phase = V(end);
        end
        Q = cumtrapz([0; t], [Ia(1); Ia])/3600;  Q = Q(2:end);   % Ah tu dau buoc (> 0 sac trong file)
        T0K = R.T0 + 273.15;
        try
            [y0, q0] = ocv_state(par, R.Vr_before, T0K, 'dis');
            R.q0 = q0;
            if hasAfter
                [~, R.q_after] = ocv_state(par, R.Vr_after_exp, T0K, 'dis');
                [~, R.q_after_chgbr] = ocv_state(par, R.Vr_after_exp, T0K, 'chg');
            end
        catch ME
            fprintf('  !!! cell %d block %d: OCV: %s\n', cellid, b, ME.message);
            continue;
        end
        if ischa
            kcv = find(V >= par.Vmax - 0.005, 1);
            if isempty(kcv) || kcv < 3, continue; end
            Icc = median(Ia(1:max(1, round(kcv*0.8))));
            R.Iset = Icc; R.Iend = Ia(end);
            R.tCC_exp = t(kcv); R.QCC_exp = Q(kcv); R.Qtot_exp = Q(end); R.tCV_exp = t(end) - t(kcv);
            R.dT_endCC_exp = Tc(kcv) - R.T0;
            if hasAfter, R.closure_Ah = (R.q0 - R.q_after) - R.Qtot_exp; end
            tmax = 1.5*R.tCC_exp + 3600;
            tq = unique([0 0.1 1 2 5 10 30 60 t(1) linspace(0, tmax, 500)]);
            % mo phong: CC toi par.V_cv roi giu par.V_cv (GD-43); du lieu van nhan CV o 4.2 V
            R.V_cv = par.V_cv;
            st = mkstep('I', -abs(Icc), tmax, T0K, struct('Vmax', par.V_cv), tq);
            o = diag_run(par, y0, st);
            R.stop_CC = string(o.reason{1}); R.tCC_sim = o.t(end); R.QCC_sim = -o.Q(end); R.V_end_CC = o.V(end);
            R.xsn_max = max(o.xsn(:,2)); R.dT_endCC_sim = o.T(end) - T0K;
            R.dphi_sep_min_mV = 1e3*min(o.dphi_sep);
            R.dV_first_sim = interp1(o.t, o.V, t(1)) - R.Vr_before;
            R.dV10_sim = interp1(o.t, o.V, 10) - R.Vr_before; R.dV60_sim = interp1(o.t, o.V, 60) - R.Vr_before;
            tc = min(R.tCC_exp, R.tCC_sim); kk = t <= tc & t >= t(1);
            [tu, iu] = unique(o.t);
            err = interp1(tu, o.V(iu), t(kk)) - V(kk);
            R.rmse_CC_mV = 1e3*sqrt(mean(err.^2)); R.mean_CC_mV = 1e3*mean(err);
            fr = [0.1 0.25 0.5 0.75 0.9 0.98];
            nmf = {'dV_f10', 'dV_f25', 'dV_f50', 'dV_f75', 'dV_f90', 'dV_f98'};
            for i = 1:numel(fr)
                tf = fr(i)*tc; R.(nmf{i}) = 1e3*(interp1(tu, o.V(iu), tf) - interp_ok(t, V, tf));
            end
            % T tai 98 % thoi gian chung
            R.dT98_exp = interp_ok(t, Tc, 0.98*tc) - R.T0; R.dT98_sim = interp1(tu, o.T(iu), 0.98*tc) - T0K;
            DC = adddec(DC, par, o, 1, R, t, V, Tc, R.Qtot_exp - Q, 1, 70);
            if strcmp(o.reason{1}, 'Vmax')
                tm = 3*R.tCV_exp + 3600; trest = 7200; if hasAfter, trest = R.rest_after_s; end
                s2 = [mkstep('V', par.V_cv, tm, T0K, struct('Icut', abs(R.Iend)), linspace(0, tm, 300)), ...
                      mkstep('rest', 0, trest, T0K, struct(), unique([0 1 10 60 600 linspace(0, trest, 100)]))];
                o2 = diag_run(par, o.y_end, s2);
                R.stop_CV = string(o2.reason{1});
                k2 = o2.step == 1; R.tCV_sim = max(o2.t(k2)); R.Qtot_sim = -o2.Q(find(k2, 1, 'last'));
                R.xsn_max = max(R.xsn_max, max(o2.xsn(k2,2)));
                R.dphi_sep_min_mV = min(R.dphi_sep_min_mV, 1e3*min(o2.dphi_sep(k2)));
                if numel(o2.reason) > 1 && any(o2.step == 2)
                    k3 = find(o2.step == 2); tr0 = o2.t(k3) - o2.t(k3(1));
                    R.Vr_after_sim = o2.V(k3(end));
                    R.Vr_after10_sim = interp_ok(tr0, o2.V(k3), 10); R.Vr_after600_sim = interp_ok(tr0, o2.V(k3), 600);
                end
                DC = adddec(DC, par, o2, 1, R, [], [], [], [], 2, 30);
                DC = adddec(DC, par, o2, 2, R, [], [], [], [], 3, 20);
            end
            fprintf(['  cell %d CHA b%d (sau xa %d): nghi %.0f s, Vr=%.4f, T0=%.1f, I=%.3f/%.3f A, dt1=%.1f s, dtmed=%.1f s | ', ...
                'tCC do/mo %.0f/%.0f, QCC %.3f/%.3f, Qtot do %.3f, tCV do/mo %.0f/%.0f, stop %s V=%.4f | ', ...
                'dV(t1) do/mo %.1f/%.1f mV, dV10 %.1f/%.1f, dV60 %.1f/%.1f | sai so CC mean %.1f rmse %.1f, f50 %.1f f90 %.1f f98 %.1f mV | ', ...
                'dT98 do/mo %.2f/%.2f K | Vr sau do/mo %.4f/%.4f, khep Ah %.3f\n'], ...
                cellid, b, R.after_dis, R.rest_before_s, R.Vr_before, R.T0, Icc, R.Iend, R.t_first, R.dt_med, ...
                R.tCC_exp, R.tCC_sim, R.QCC_exp, R.QCC_sim, R.Qtot_exp, R.tCV_exp, R.tCV_sim, R.stop_CC, R.V_end_CC, ...
                1e3*R.dV_first_exp, 1e3*R.dV_first_sim, 1e3*R.dV10_exp, 1e3*R.dV10_sim, 1e3*R.dV60_exp, 1e3*R.dV60_sim, ...
                R.mean_CC_mV, R.rmse_CC_mV, R.dV_f50, R.dV_f90, R.dV_f98, R.dT98_exp, R.dT98_sim, R.Vr_after_exp, R.Vr_after_sim, R.closure_Ah);
        else
            Id = -Ia; cap = trapz(t, Id)/3600; Imean = cap*3600/(t(end) - t(1));
            R.Iset = Imean; R.cap_exp = cap; R.Qtot_exp = cap;
            if hasAfter, R.closure_Ah = (R.q_after - R.q0) - cap; end
            seenDis = true;
            if abs(Imean/(crt*par.Qnom) - 1) > 0.1, PH = addrow(PH, R); continue; end
            te = t - t(1);
            tmax = 1.5*te(end) + 600;
            tq = unique([0 0.1 1 2 5 10 30 60 t(1) linspace(0, tmax, 500)]);
            st = mkstep('I', Imean, tmax, T0K, struct('Vmin', par.Vmin), tq);
            o = diag_run(par, y0, st);
            R.stop_CC = string(o.reason{1}); R.cap_sim = o.Q(end);
            R.dV_first_sim = interp1(o.t, o.V, t(1)) - R.Vr_before;
            R.dV10_sim = interp1(o.t, o.V, 10) - R.Vr_before; R.dV60_sim = interp1(o.t, o.V, 60) - R.Vr_before;
            tc = min(o.t(end), te(end)); kk = te <= tc;
            dV = interp1(o.t, o.V, te(kk)) - V(kk);
            k9 = te(kk) <= 0.9*te(end);
            R.rmse_dis_mV = 1e3*sqrt(mean(dV.^2)); R.rmse_dis90_mV = 1e3*sqrt(mean(dV(k9).^2)); R.mean_dis90_mV = 1e3*mean(dV(k9));
            dq = [0.25 0.5 1 2 3 4]; nmq = {'dV_q025', 'dV_q05', 'dV_q1', 'dV_q2', 'dV_q3', 'dV_q4'};
            for i = 1:numel(dq)
                tf = dq(i)*3600/Imean;
                if tf <= tc, R.(nmq{i}) = 1e3*(interp1(o.t, o.V, tf) - interp_ok(te, V, tf)); end
            end
            DC = adddec(DC, par, o, 1, R, te, V, Tc, Q*(-1), 4, 70);
            fprintf(['  cell %d DCH b%d: nghi %.0f s, Vr=%.4f, T0=%.1f, I=%.3f A, dt1=%.1f s | Ah do/mo %.3f/%.3f | ', ...
                'dV(t1) do/mo %.1f/%.1f mV, dV10 %.1f/%.1f, dV60 %.1f/%.1f | RMSE %.1f, 90%% %.1f, mean90 %.1f mV | ', ...
                'dV(q=0.25/0.5/1/2 Ah) %.1f/%.1f/%.1f/%.1f mV | Vr sau %.4f, khep Ah %.3f\n'], ...
                cellid, b, R.rest_before_s, R.Vr_before, R.T0, Imean, R.t_first, cap, R.cap_sim, ...
                1e3*R.dV_first_exp, 1e3*R.dV_first_sim, 1e3*R.dV10_exp, 1e3*R.dV10_sim, 1e3*R.dV60_exp, 1e3*R.dV60_sim, ...
                R.rmse_dis_mV, R.rmse_dis90_mV, R.mean_dis90_mV, R.dV_q025, R.dV_q05, R.dV_q1, R.dV_q2, R.Vr_after_exp, R.closure_Ah);
            % (d) xa voi dung dong sac (1.67 A) tu cung trang thai day, mot lan moi file
            if ~did167
                did167 = true;
                I167 = 1.67;
                tm = 1.6*3600*par.Qnom/I167;
                o5 = diag_run(par, y0, mkstep('I', I167, tm, T0K, struct('Vmin', par.Vmin), linspace(0, tm, 400)));
                R5 = R; R5.type = "DCH167"; R5.Iset = I167; R5.cap_sim = o5.Q(end); R5.stop_CC = string(o5.reason{1});
                DC = adddec(DC, par, o5, 1, R5, [], [], [], [], 5, 70);
                PH = addrow(PH, R5);
            end
        end
        PH = addrow(PH, R);
    end
end
if ~isempty(PH)
    writetable(struct2table(PH), fullfile(outdir, sprintf('hyst_%s_%ddegC_phases.csv', variant, Tdeg)));
end
if ~isempty(DC)
    writetable(struct2table(DC), fullfile(outdir, sprintf('hyst_%s_%ddegC_decomp.csv', variant, Tdeg)));
end
fprintf('DIAG_HYST %s %d: XONG\n', variant, Tdeg);
end

% =========================================================================
function DC = adddec(DC, par, o, stepk, R, te, Ve, Te, dexp, kind, nsamp)
% Tach V tai ~nsamp thoi diem cua buoc stepk trong ket qua diag_run o.
k = find(o.step == stepk);
if isempty(k), return; end
t0 = o.t(k(1));
sel = unique(round(linspace(1, numel(k), min(nsamp, numel(k)))));
for i = k(sel).'
    r = diag_decomp(par, o.Y(:,i), o.ctl{stepk});
    r.variant = R.variant; r.T_degC = R.T_degC; r.cell = R.cell; r.block = R.block; r.kind = kind;
    r.t = o.t(i) - t0;
    r.q_bal = (par.neg.x100 - r.xbar)*par.neg.Qcap;
    r.q0 = R.q0; r.q_after = R.q_after;
    r.V_exp = NaN; r.T_exp = NaN; r.d_exp = NaN;
    if ~isempty(te) && r.t >= te(1) && r.t <= te(end)
        r.V_exp = interp_ok(te, Ve, r.t); r.T_exp = interp_ok(te, Te, r.t) + 273.15; r.d_exp = interp_ok(te, dexp, r.t);
    end
    DC = addrow(DC, r);
end
end

function S = addrow(S, r)
if isempty(S), S = r; else, S(end+1) = orderfields(r, S(1)); end
end

function R = blankrow()
f = {'T_degC', 'cell', 'crate_file', 'block', 'after_dis', 'rest_before_s', 'Vr_before', 'T0', 'Iset', 'Iend', ...
     't_first', 'dt_med', 'dV_first_exp', 'dV_first_sim', 'dV10_exp', 'dV10_sim', 'dV60_exp', 'dV60_sim', ...
     'tCC_exp', 'tCC_sim', 'QCC_exp', 'QCC_sim', 'tCV_exp', 'tCV_sim', 'Qtot_exp', 'Qtot_sim', 'V_end_CC', 'xsn_max', ...
     'dT_endCC_exp', 'dT_endCC_sim', 'dT98_exp', 'dT98_sim', 'rmse_CC_mV', 'mean_CC_mV', ...
     'dV_f10', 'dV_f25', 'dV_f50', 'dV_f75', 'dV_f90', 'dV_f98', ...
     'rest_after_s', 'Vr_after_exp', 'Vr_after10_exp', 'Vr_after600_exp', 'Vlast_phase', ...
     'Vr_after_sim', 'Vr_after10_sim', 'Vr_after600_sim', 'q0', 'q_after', 'q_after_chgbr', 'closure_Ah', ...
     'cap_exp', 'cap_sim', 'rmse_dis_mV', 'rmse_dis90_mV', 'mean_dis90_mV', ...
     'dV_q025', 'dV_q05', 'dV_q1', 'dV_q2', 'dV_q3', 'dV_q4', 'V_cv', 'dphi_sep_min_mV'};
R = struct('variant', "", 'type', "", 'stop_CC', "", 'stop_CV', "");
for i = 1:numel(f), R.(f{i}) = NaN; end
end

function s = mkstep(mode, value, tmax, Tamb, stop, tout)
s = struct('mode', mode, 'value', value, 'tmax', tmax, 'Tamb', Tamb, 'stop', stop, 'tout', tout(:));
end

function v = interp_ok(t, V, tq)
v = NaN;
if numel(t) > 1 && tq >= t(1) && tq <= t(end)
    [tu, iu] = unique(t); v = interp1(tu, V(iu), tq);
end
end

function [y, q] = ocv_state(par, Vrest, T0, br)
% Nhu dfn_state_from_ocv.m (duong can bang lithium qua x100, y100) nhung khoang q rong
% hon [-0.8, 5.6] Ah va chon nhanh OCV: 'dis' (nhanh mo hinh dung luc nghi, I = 0) hoac 'chg'.
lo = -0.8; hi = 5.6;
if ~(Vrest <= f(lo) && Vrest >= f(hi))
    error('ocv_state: Vrest = %.4f V ngoai khoang [%.4f, %.4f]', Vrest, f(hi), f(lo));
end
for it = 1:80
    mid = 0.5*(lo + hi);
    if f(mid) > Vrest, lo = mid; else, hi = mid; end
end
q = 0.5*(lo + hi);
xn = par.neg.x100 - q/par.neg.Qcap; yp = par.pos.y100 + q/par.pos.Qcap;
y = dfn_init_state(par, xn, yp, T0);
    function v = f(qq)
        x = par.neg.x100 - qq/par.neg.Qcap; z = par.pos.y100 + qq/par.pos.Qcap;
        [Unl, Und, dUn] = dfn_ocp_neg(x); [Upl, Upd, dUp] = dfn_ocp_pos(z);
        dUn = dUn*par.dUdT_scale/1e-3; dUp = dUp*par.dUdT_scale/1e-3;
        if strcmp(br, 'dis'), m = 0.5*(1 + tanh(par.hys.k*par.hys.offset)); else, m = 0; end
        if par.hys.n_delith, mn = 1; else, mn = m; end   % cuc am: GD-40 (ocp_n_branch)
        v = m*Upl + (1 - m)*Upd - ((1 - mn)*Unl + mn*Und);
        v = v + (T0 - par.Tref)*(dUp - dUn);
    end
end

function v = ternary(c, a, b)
if c, v = a; else, v = b; end
end
