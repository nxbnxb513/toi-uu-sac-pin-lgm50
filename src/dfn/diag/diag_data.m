function diag_data(variant, Tdeg, datadir, outdir)
%DIAG_DATA  So sanh mot bien the tham so (diag_variant) voi du lieu mo Zenodo
% 4864437 o nhiet do buong Tdeg (0 | 10 | 25), cho MOI file (moi C-rate xa):
%   (1) cac pha SAC CC-CV (Status = CHA) - du lieu nay KHONG duoc dung de chinh
%       tham so nao: so thoi gian CC toi 4.2 V, Ah pha CC, Ah pha CV;
%   (2) cac pha XA (nhu val_run_condition): RMSE dien ap (toan bo va 90 % dau).
% Trang thai dau: OCV mo hinh = ap nghi do ngay truoc pha (GD-13); T dau = T
% moi truong = nhiet do be mat cell truoc pha (GD-09).
% Dau ra: outdir/data_<variant>_<T>degC_charge.csv, ..._discharge.csv
if ischar(Tdeg) || isstring(Tdeg), Tdeg = str2double(Tdeg); end
if ~exist(outdir, 'dir'), mkdir(outdir); end
[par, desc] = diag_variant(variant);
fprintf('=== diag_data %s (%s), %d degC ===\n', variant, desc, Tdeg);
files = dir(fullfile(datadir, sprintf('%ddegC', Tdeg), 'Cell*.csv'));
rc = {}; rd = {};
for fi = 1:numel(files)
    fn = fullfile(files(fi).folder, files(fi).name);
    d = val_read_cell(fn);
    cellid = str2double(regexp(files(fi).name, 'Cell(\d+)', 'tokens', 'once'));
    crt = regexp(files(fi).name, '_([0-9p]+)C_', 'tokens', 'once'); crt = str2double(strrep(crt{1}, 'p', '.'));
    % ---- (1) cac pha sac ------------------------------------------------
    isc = strcmp(d.status, 'CHA'); isp = strcmp(d.status, 'PAU'); isd = strcmp(d.status, 'DCH');
    cs = find(isc & ~[false; isc(1:end-1)]);
    for k = 1:numel(cs)
        a = cs(k); b = a; while b < numel(isc) && isc(b+1), b = b + 1; end
        pz = find(isp(1:a-1), 1, 'last');
        if isempty(pz) || b - a < 10, continue; end
        afterdis = any(isd(1:a-1));
        t = d.t(a:b) - d.t(a); I = d.I(a:b); V = d.V(a:b);
        kcv = find(V >= par.Vmax - 0.005, 1);
        if isempty(kcv) || kcv < 3, continue; end   % pha sac bat dau o gan 4.2 V: bo qua
        Icc = median(I(1:max(1, round(kcv*0.8))));
        Iend = I(end);
        QCC = trapz(t(1:kcv), I(1:kcv))/3600; Qtot = trapz(t, I)/3600;
        Vr = d.V(pz); T0 = d.Tcell(pz) + 273.15;
        e = struct('tCC', t(kcv), 'QCC', QCC, 'Qtot', Qtot, 'tCV', t(end) - t(kcv));
        try
            tic; s = sim_charge(par, Vr, T0, Icc, Iend, e); w = toc;
        catch ME
            fprintf('  !!! cell %d sac %d: %s\n', cellid, k, ME.message);
            s = struct('q0', NaN, 'tCC', NaN, 'QCC', NaN, 'tCV', NaN, 'Qtot', NaN, 'r1', 'error', 'r2', '', 'xsmax', NaN, 'xsmin_end', NaN, 'eplmin', NaN, 'Vend', NaN, 'tt', [0; 1], 'VV', [NaN; NaN]); w = NaN;
        end
        % sai so dien ap pha CC (tren khoang thoi gian chung) va ap mo hinh tai thoi diem
        % ma cell that cham 4.2 V
        tcm = min(t(kcv), s.tt(end)); kk = t <= tcm;
        [tu, iu] = unique(s.tt);
        if nnz(kk) > 2 && numel(tu) > 2
            rmseCC = sqrt(mean((interp1(tu, s.VV(iu), t(kk)) - V(kk)).^2));
        else
            rmseCC = NaN;
        end
        Vsim_at = NaN; if s.tt(end) >= t(kcv), Vsim_at = interp1(tu, s.VV(iu), t(kcv)); end
        dV98 = NaN; k98 = find(t <= 0.98*min(t(kcv), s.tt(end)), 1, 'last');
        if ~isempty(k98) && numel(tu) > 2, dV98 = interp1(tu, s.VV(iu), t(k98)) - V(k98); end
        fprintf(['  cell %d (xa %gC) sac %d (sau xa: %d): Vrest=%.4f T0=%.1f Icc=%.3f Iend=%.3f | tCC do/mo=%.0f/%.0f s, QCC=%.3f/%.3f Ah, tCV=%.0f/%.0f s, Qtot=%.3f/%.3f Ah | ', ...
                 'CC dung: %s (V=%.4f), CV dung: %s, x_surf,n max=%.4f, min(phi_s-phi_e-jR)=%.1f mV, RMSE_V(CC)=%.1f mV, V_mo(98%% t chung)-V_do=%.1f mV, %.0f s\n'], ...
            cellid, crt, k, afterdis, Vr, T0 - 273.15, Icc, Iend, e.tCC, s.tCC, e.QCC, s.QCC, e.tCV, s.tCV, e.Qtot, s.Qtot, ...
            s.r1, s.Vend, s.r2, s.xsmax, 1e3*s.eplmin, 1e3*rmseCC, 1e3*dV98, w);
        rc(end+1,:) = {variant, Tdeg, cellid, crt, k, afterdis, Vr, T0 - 273.15, Icc, Iend, s.q0, ...
            e.tCC, s.tCC, e.QCC, s.QCC, e.tCV, s.tCV, e.Qtot, s.Qtot, s.r1, s.Vend, s.r2, s.xsmax, 1e3*s.eplmin, 1e3*rmseCC, Vsim_at, 1e3*dV98}; %#ok<AGROW>
    end
    % ---- (2) cac pha xa ------------------------------------------------------
    for si = 1:numel(d.seg)
        sg = d.seg(si);
        if abs(sg.Imean/(crt*par.Qnom) - 1) > 0.1, continue; end
        T0 = sg.T0 + 273.15;
        try
            [y0, q0] = dfn_state_from_ocv(par, sg.Vrest0, T0);
            te = sg.t - sg.t(1);
            st = struct('mode', 'I', 'value', sg.Imean, 'tmax', 1.5*te(end) + 600, 'Tamb', T0, ...
                'stop', struct('Vmin', par.Vmin), 'tout', linspace(0, 1.5*te(end) + 600, 2500).');
            o = dfn_run(par, y0, st);
            tc = min(o.t(end), te(end)); kk = te <= tc;
            dV = interp1(o.t, o.V, te(kk)) - sg.V(kk);
            k9 = te(kk) <= 0.9*te(end);
            m = [sqrt(mean(dV.^2)), sqrt(mean(dV(k9).^2)), o.Q(end), max(o.xsn(:,2))];
            rs = o.reason{1};
        catch ME
            fprintf('  !!! cell %d xa %d: %s\n', cellid, si, ME.message);
            m = [NaN NaN NaN NaN]; rs = 'error'; q0 = NaN;
        end
        fprintf('  cell %d xa %d (%gC): RMSE_V=%.1f mV, 90%%: %.1f mV, Ah mo/do=%.3f/%.3f, %s\n', cellid, si, crt, 1e3*m(1), 1e3*m(2), m(3), sg.cap, rs);
        rd(end+1,:) = {variant, Tdeg, cellid, crt, si, sg.Vrest0, sg.T0, sg.Imean, q0, 1e3*m(1), 1e3*m(2), sg.cap, m(3), m(4), rs}; %#ok<AGROW>
    end
end
if ~isempty(rc)
    writetable(cell2table(rc, 'VariableNames', {'variant', 'T_degC', 'cell', 'crate_dis', 'k', 'after_discharge', 'Vrest_V', 'T0_degC', ...
        'Icc_A', 'Iend_A', 'q0_Ah', 'tCC_exp_s', 'tCC_sim_s', 'QCC_exp_Ah', 'QCC_sim_Ah', 'tCV_exp_s', 'tCV_sim_s', ...
        'Qtot_exp_Ah', 'Qtot_sim_Ah', 'stop_CC', 'V_end_CC', 'stop_CV', 'xsn_max', 'min_eta_pl_mV', ...
        'rmseV_CC_mV', 'Vsim_at_tCCexp', 'dV_98pct_mV'}), ...
        fullfile(outdir, sprintf('data_%s_%ddegC_charge.csv', variant, Tdeg)));
end
if ~isempty(rd)
    writetable(cell2table(rd, 'VariableNames', {'variant', 'T_degC', 'cell', 'crate', 'k', 'Vrest_V', 'T0_degC', 'I_A', 'q0_Ah', ...
        'rmseV_mV', 'rmseV90_mV', 'cap_exp_Ah', 'cap_sim_Ah', 'xsn_max', 'stop'}), ...
        fullfile(outdir, sprintf('data_%s_%ddegC_discharge.csv', variant, Tdeg)));
end
fprintf('DIAG_DATA %s %d: XONG\n', variant, Tdeg);
end

function s = sim_charge(par, Vr, T0, Icc, Iend, e)
[y0, q0] = dfn_state_from_ocv(par, Vr, T0);
st = struct('mode', 'I', 'value', -abs(Icc), 'tmax', 1.5*e.tCC + 3600, 'Tamb', T0, ...
    'stop', struct('Vmax', par.Vmax), 'tout', linspace(0, 1.5*e.tCC + 3600, 600).');
o = dfn_run(par, y0, st);
s.q0 = q0; s.r1 = o.reason{1}; s.tCC = o.t(end); s.QCC = -o.Q(end); s.Vend = o.V(end);
s.xsmax = max(o.xsn(:,2)); s.eplmin = min(o.eta_pl_min); s.tt = o.t; s.VV = o.V;
s.r2 = 'skipped'; s.tCV = NaN; s.Qtot = s.QCC; s.xsmin_end = NaN;
if strcmp(s.r1, 'Vmax')
    tm = 3*e.tCV + 3600;
    st2 = struct('mode', 'V', 'value', par.Vmax, 'tmax', tm, 'Tamb', T0, ...
        'stop', struct('Icut', abs(Iend)), 'tout', linspace(0, tm, 600).');
    o2 = dfn_run(par, o.y_end, st2);
    s.r2 = o2.reason{1}; s.tCV = o2.t(end); s.Qtot = -o2.Q(end);
    s.xsmax = max(s.xsmax, max(o2.xsn(:,2))); s.eplmin = min(s.eplmin, min(o2.eta_pl_min));
end
end
