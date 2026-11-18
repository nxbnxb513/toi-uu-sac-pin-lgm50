function ag_report(resdir, outdir, datadir)
%AG_REPORT  So sanh mo phong lao hoa (rpt.csv cua moi ag_run) voi thuc nghiem Kirkaldy 2024
% (data/derived/D_kirkaldy_per_cell_rpt.csv, trung binh cac cell theo chi so RPT) va voi
% sai so mo hinh "5 coupled" do Li 2025 cong bo (Table 2; SI Table 12 - cach doc suy luan)
% va duong mo hinh cua tac gia cho Expt 2 (Source Data Fig. 3-4, data/derived/C_fig_ageing_long.csv;
% Fig. 6 KHONG dung vi gan nhan sai).
% SOH (GD-60, nguoi dung chot 17/11/2026): MAC DINH = Q_0.1C / 4.865 Ah (co dinh, Li 2025) cho
% mo hinh; thuc nghiem cung dinh nghia (cap_C10 / 4.865 Ah, trung binh cell). Phu: ca hai chuan
% hoa theo RPT0 cua chinh no (thuc nghiem: SOH_C10 cua Kirkaldy 2024). SOH tinh lai tu Qdis01_Ah
% nen doc duoc ca rpt.csv cua ban truoc 18/11/2026.
% MPE (Li 2025 pt. (1); code Reload_Exp2.ipynb::Calculate_MPE_re): MPE = mean(|exp - mo hinh|/|exp|)
% tren cac diem RPT thuc nghiem (noi suy tuyen tinh mo hinh theo dien luong thong qua, bo diem
% exp = 0 va diem ngoai khoang mo hinh); MPE_tot = MPE_SOH/2 + (MPE_Res + MPE_LLI + MPE_LAMNE + MPE_LAMPE)/8.
% RMSE: cung cac diem, don vi diem % (R: mOhm), ke ca diem exp = 0 (RPT0).
% Kiem chung nhay chu ky: moi rpt.csv co Jmax > 0 so voi brute force (Jmax = 0) cung Expt, T,
% bien the, tai MOI RPT chung.
if nargin < 3, datadir = 'data/derived'; end
if ~exist(outdir, 'dir'), mkdir(outdir); end
Qref = 4.865;     % Ah (Li 2025; GD-60)
files = dir(fullfile(resdir, '**', 'rpt.csv'));
oK = detectImportOptions(fullfile(datadir, 'D_kirkaldy_per_cell_rpt.csv'));
oK = setvartype(oK, {'expt', 'soc_window_pct', 'cell', 'source_file'}, 'char');
K = readtable(fullfile(datadir, 'D_kirkaldy_per_cell_rpt.csv'), oK);
oC = detectImportOptions(fullfile(datadir, 'C_fig_ageing_long.csv'));
oC = setvartype(oC, {'figure', 'panel', 'expt', 'soc_window_pct', 'series', 'quantity'}, 'char');
C = readtable(fullfile(datadir, 'C_fig_ageing_long.csv'), oC);
% Li 2025 "5 coupled": [SOH Res LLI LAMNE LAMPE tot] (%)
pub.e2 = [0.42 4.49 25.10 37.64 27.02 11.99; 0.88 5.50 22.75 20.58 30.94 10.41; 0.57 3.68 31.58 34.18 24.64 12.05]; % Table 2 (tr. 4)
pub.e3 = [5.3 6.95 38.1 81.06 61.45 26.1; 2.44 2.64 28.67 32.63 54.58 16.04; 0.75 5.86 22.67 19.82 33.32 10.58];    % SI Table 12 (doc suy luan)
Ts = [10 25 40];
q  = {'SOH', 'R_mOhm', 'LLI_pct', 'LAM_NE_pct', 'LAM_PE_pct', 'SOH0'};     % SOH0 = chuan hoa RPT0 (phu)
qn = {'SOH', 'Res', 'LLI', 'LAM_NE', 'LAM_PE', 'SOH_RPT0'};
qC = {'SOH_pct', 'R_0p1s_mOhm', 'LLI_pct', 'LAM_NE_tot_pct', 'LAM_PE_pct'};
fid = fopen(fullfile(outdir, 'aging_validation.md'), 'w');
p('# Kiem chung mo hinh lao hoa "5 coupled" trong DFN (buoc C)\n\n');
p('Thuc nghiem: Kirkaldy 2024 (Zenodo 10637534), trung binh cac cell theo RPT. MPE theo Li 2025 pt. (1); RMSE cung cac diem (diem %%; R: mOhm). ');
p('SOH mac dinh = Q_0.1C / %.3f Ah ca hai phia (GD-60); SOH_RPT0 = chuan hoa theo RPT0 cua chinh no (phu). ', Qref);
p('"Li 2025" = sai so mo hinh cua tac gia (Table 2; SI Table 12 theo cach doc suy luan; SOH cua tac gia ~ chuan hoa RPT0 vi mo hinh tac gia co Q(RPT0) = 4.865 Ah). "mo hinh tac gia tinh lai" = MPE cua duong mo hinh tac gia (Source Data Fig. 3-4, chi Expt 2) so voi cung du lieu thuc nghiem, bang script nay.\n\n');
S = table(); MM = {}; EE = {}; Lall = table();
for i = 1:numel(files)
    M = readtable(fullfile(files(i).folder, files(i).name), 'TextType', 'char');
    if height(M) < 2, continue; end
    M.SOH = 100*M.Qdis01_Ah/Qref;
    M.SOH0 = 100*M.Qdis01_Ah/M.Qdis01_Ah(M.rpt == 0);
    if ~any(M.expt(1) == [2 3]), continue; end     % Expt 1/5 (buoc D): ag_si_report.m
    MM{end+1} = M; %#ok<AGROW>
end
% trung lap (cung bien the, Expt, T, Jmax tu nhieu lan chay): giu ban co nhieu RPT nhat
if ~isempty(MM)
    kf = cellfun(@(M) sprintf('%s|%d|%g|%d', M.variant{1}, M.expt(1), M.T_degC(1), M.Jmax(1)), MM, 'UniformOutput', false);
    nr = cellfun(@height, MM);
    keep = true(size(MM));
    for i = 1:numel(MM)
        same = find(strcmp(kf, kf{i}));
        [~, b] = max(nr(same));
        keep(i) = same(b) == i;
    end
    MM = MM(keep);
end
% thu tu: brute force truoc, theo Expt, T
if ~isempty(MM)
    kk = cellfun(@(M) [M.Jmax(1), M.expt(1), M.T_degC(1)], MM, 'UniformOutput', false);
    [~, o] = sortrows(cell2mat(kk.')); MM = MM(o);
end
for i = 1:numel(MM)
    M = MM{i};
    ex = M.expt(1); T = M.T_degC(1); var = M.variant{1}; Jm = M.Jmax(1);
    if ex == 2, w = '70-85'; else, w = '85-100'; end
    E = expavg(K, w, T, Qref);
    EE{i} = E; %#ok<AGROW>
    xm = M.Qthr_Ah/1000;
    stat = '?';
    if any(strcmp(M.Properties.VariableNames, 'status_txt')), stat = M.status_txt{1}; end
    p('\n## Expt %d (%s %%), %g C, bien the `%s`, Jmax = %d (%d RPT)\n\n', ex, w, T, var, Jm, height(M) - 1);
    if Jm > 0
        p('(ban nhay chu ky; xem muc kiem chung nhay chu ky)\n');
        continue
    end
    p('| RPT | Q_thr mo hinh (kAh) | SOH | SOH_RPT0 | LLI | LAM_NE | LAM_PE | R (mOhm) | Q_thr exp (kAh) | SOH exp | SOH_RPT0 exp | LLI exp | LAM_NE exp | LAM_PE exp | R exp |\n|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|\n');
    for r = 1:max(height(M), height(E))
        a = repmat({''}, 1, 15);
        if r <= height(M), a(1:8) = {sprintf('%d', M.rpt(r)), f3(xm(r)), f2(M.SOH(r)), f2(M.SOH0(r)), f2(M.LLI_pct(r)), f2(M.LAM_NE_pct(r)), f2(M.LAM_PE_pct(r)), f2(M.R_mOhm(r))}; end
        if r <= height(E), a(9:15) = {f3(E.x(r)), f2(E.SOH(r)), f2(E.SOH0(r)), f2(E.LLI_pct(r)), f2(E.LAM_NE_pct(r)), f2(E.LAM_PE_pct(r)), f2(E.R_mOhm(r))}; end
        if isempty(a{1}), a{1} = sprintf('(exp %d)', r - 1); end
        p('| %s |\n', strjoin(a, ' | '));
    end
    [mpe, rmse] = errs(xm, M, E, q);
    tot = 0.5*mpe(1) + 0.125*sum(mpe(2:5));
    tot0 = 0.5*mpe(6) + 0.125*sum(mpe(2:5));
    it = find(Ts == T);
    if ex == 2, pb = pub.e2(it, :); else, pb = pub.e3(it, :); end
    % mo hinh tac gia (chi Expt 2)
    dL = NaN(1, 5); mpeL = NaN(1, 6); rmseL = NaN(1, 5);
    if ex == 2
        for k = 1:5
            sel = strcmp(C.series, 'model_5_coupled') & strcmp(C.quantity, qC{k}) & C.T_panel_degC == T & strcmp(C.soc_window_pct, '70-85');
            xl = C.charge_throughput_kAh(sel); vl = C.value(sel);
            if k == 1, kq = 'SOH0'; else, kq = q{k}; end
            vm = interp1(xm, M.(kq), xl, 'linear'); okk = ~isnan(vm);
            if any(okk), dL(k) = sqrt(mean((vm(okk) - vl(okk)).^2)); end
            vmL = interp1(xl, vl, E.x, 'linear', 'extrap'); vmL(E.x < min(xl) - 0.1 | E.x > max(xl) + 0.1) = NaN;
            ve = E.(kq);
            ok = ~isnan(vmL) & ~isnan(ve) & ve ~= 0;
            if any(ok), mpeL(k) = 100*mean(abs(ve(ok) - vmL(ok))./abs(ve(ok))); end
            ok = ~isnan(vmL) & ~isnan(ve);
            if any(ok), rmseL(k) = sqrt(mean((ve(ok) - vmL(ok)).^2)); end
        end
        mpeL(6) = 0.5*mpeL(1) + 0.125*sum(mpeL(2:5));
    end
    p('\n| MPE (%%) | SOH | Res | LLI | LAM_NE | LAM_PE | tot | SOH_RPT0 | tot (SOH_RPT0) |\n|---|---|---|---|---|---|---|---|---|\n');
    p('| mo hinh nay | %s | %s | %s | %s |\n', strjoin(arrayfun(@f2, mpe(1:5), 'UniformOutput', false), ' | '), f2(tot), f2(mpe(6)), f2(tot0));
    p('| Li 2025 cong bo | %s | - | - |\n', strjoin(arrayfun(@f2, pb, 'UniformOutput', false), ' | '));
    if ex == 2
        p('| mo hinh tac gia tinh lai (SOH so voi SOH_RPT0 exp) | %s | - | - |\n', strjoin(arrayfun(@f2, mpeL, 'UniformOutput', false), ' | '));
    end
    p('\n| RMSE (diem %%; R: mOhm) | SOH | Res | LLI | LAM_NE | LAM_PE | SOH_RPT0 |\n|---|---|---|---|---|---|---|\n');
    p('| mo hinh nay | %s |\n', strjoin(arrayfun(@f2, rmse, 'UniformOutput', false), ' | '));
    if ex == 2
        p('| mo hinh tac gia | - | %s | %s |\n', strjoin(arrayfun(@f2, rmseL(2:5), 'UniformOutput', false), ' | '), f2(rmseL(1)));
        p('\nLech RMS so voi mo hinh tac gia (SOH theo RPT0): SOH %.2f, R %.2f mOhm, LLI %.2f, LAM_NE %.2f, LAM_PE %.2f (diem %%).\n', dL);
    end
    last = height(M);
    p('\nPhan ra LLI o RPT cuoi (%% Li trong hat luc RPT0): SEI %.2f, SEI vet nut %.2f, ma con lai %.3f, chet %.3f, LAM %.2f, can kho %.2f, dien giai/reservoir %.3f. LAM do can kho %.2f %%. eps_n min %.4f, l_cr max %.3g m.\n', ...
        M.LLI_SEI_pct(last), M.LLI_SEIcr_pct(last), M.LLI_pl_pct(last), M.LLI_dead_pct(last), M.LLI_LAM_pct(last), M.LLI_dry_pct(last), M.LLI_elyte_pct(last), ...
        M.LAM_dry_pct(last), M.eps_n_min(last), M.lcr_max(last));
    p('Bao toan Li: max |lech tuong doi| = %.2e. Thoi gian tuong: %.2f h.\n', max(abs(M.Li_cons_rel)), M.wall_h(last));
    % so sanh tai cung Q_thr cuoi cua thuc nghiem
    xe = E.x(end);
    vme = cellfun(@(f) interp1(xm, M.(f), xe, 'linear'), q(1:5));
    row = table({var}, ex, T, Jm, height(M) - 1, xm(last), M.SOH(last), M.SOH0(last), M.LLI_pct(last), M.LAM_NE_pct(last), M.LAM_PE_pct(last), M.R_mOhm(last), ...
        xe, vme(1), E.SOH(end), vme(3), E.LLI_pct(end), vme(4), E.LAM_NE_pct(end), vme(5), E.LAM_PE_pct(end), ...
        mpe(1), mpe(2), mpe(3), mpe(4), mpe(5), tot, mpe(6), tot0, rmse(1), rmse(2), rmse(3), rmse(4), rmse(5), rmse(6), ...
        pb(1), pb(2), pb(3), pb(4), pb(5), pb(6), mpeL(6), max(abs(M.Li_cons_rel)), M.wall_h(last), ...
        'VariableNames', {'variant', 'expt', 'T_degC', 'Jmax', 'nRPT', 'Qthr_kAh', 'SOH', 'SOH_RPT0', 'LLI', 'LAM_NE', 'LAM_PE', 'R_mOhm', ...
        'Qthr_exp_last_kAh', 'SOH_at_exp_last', 'SOH_exp_last', 'LLI_at_exp_last', 'LLI_exp_last', 'LAMNE_at_exp_last', 'LAMNE_exp_last', 'LAMPE_at_exp_last', 'LAMPE_exp_last', ...
        'MPE_SOH', 'MPE_Res', 'MPE_LLI', 'MPE_LAMNE', 'MPE_LAMPE', 'MPE_tot', 'MPE_SOH_RPT0', 'MPE_tot_SOH_RPT0', ...
        'RMSE_SOH', 'RMSE_Res', 'RMSE_LLI', 'RMSE_LAMNE', 'RMSE_LAMPE', 'RMSE_SOH_RPT0', ...
        'Li2025_SOH', 'Li2025_Res', 'Li2025_LLI', 'Li2025_LAMNE', 'Li2025_LAMPE', 'Li2025_tot', 'MPE_tot_Li_model_recomputed', 'Li_cons_max', 'wall_h'});
    S = [S; row]; %#ok<AGROW>
    % bang dai cho tai lieu: moi RPT thuc nghiem, mo hinh noi suy
    for r = 1:height(E)
        vm = cellfun(@(f) interp1(xm, M.(f), E.x(r), 'linear'), q);
        Lall = [Lall; table(ex, T, E.rpt(r), E.x(r), vm(1), E.SOH(r), vm(6), E.SOH0(r), vm(3), E.LLI_pct(r), vm(4), E.LAM_NE_pct(r), vm(5), E.LAM_PE_pct(r), vm(2), E.R_mOhm(r), ...
            'VariableNames', {'expt', 'T_degC', 'rpt_exp', 'Qthr_kAh', 'SOH_mod', 'SOH_exp', 'SOH_RPT0_mod', 'SOH_RPT0_exp', 'LLI_mod', 'LLI_exp', 'LAMNE_mod', 'LAMNE_exp', 'LAMPE_mod', 'LAMPE_exp', 'R_mod', 'R_exp'})]; %#ok<AGROW>
    end
end
if ~isempty(Lall), writetable(Lall, fullfile(outdir, 'aging_vs_exp_long.csv')); end
% ---- kiem chung phuong phap nhay chu ky: moi RPT chung, so voi brute force (Jmax = 0) ----
key = @(M) sprintf('%s|%d|%g', M.variant{1}, M.expt(1), M.T_degC(1));
keys = cellfun(key, MM, 'UniformOutput', false);
qj = {'SOH', 'LLI_pct', 'LAM_NE_pct', 'LAM_PE_pct', 'R_mOhm'};
JC = table();
for i = 1:numel(MM)
    if MM{i}.Jmax(1) ~= 0, continue; end
    B = MM{i};
    for j = find(strcmp(keys, keys{i}))
        if j == i || MM{j}.Jmax(1) == 0, continue; end
        Jt = MM{j};
        rr = intersect(B.rpt(B.rpt > 0), Jt.rpt(Jt.rpt > 0));
        if isempty(rr), continue; end
        e = NaN(1, numel(qj)); rel = e; inc = e;
        for k = 1:numel(qj)
            vb = B.(qj{k}); vj = Jt.(qj{k});
            d = arrayfun(@(r) vj(Jt.rpt == r) - vb(B.rpt == r), rr);
            e(k) = max(abs(d));
            rl = rr(end);
            inc(k) = vb(B.rpt == rl) - vb(B.rpt == 0);
            rel(k) = 100*abs(d(end))/max(abs(inc(k)), eps);
        end
        nsimB = NaN; nsimJ = NaN;
        JC = [JC; table({keys{i}}, Jt.Jmax(1), numel(rr), rr(end), e(1), e(2), e(3), e(4), e(5), rel(1), rel(2), rel(3), rel(4), rel(5), ...
            max(Jt.jump_err_max), B.wall_h(B.rpt == rr(end)), Jt.wall_h(Jt.rpt == rr(end)), ...
            'VariableNames', {'case', 'Jmax', 'nRPT', 'last_rpt', 'dSOH_max', 'dLLI_max', 'dLAMNE_max', 'dLAMPE_max', 'dR_max_mOhm', ...
            'relSOH_last_pct', 'relLLI_last_pct', 'relLAMNE_last_pct', 'relLAMPE_last_pct', 'relR_last_pct', 'Li_jump_corr_max', 'wall_h_brute', 'wall_h_jump'})]; %#ok<AGROW>
    end
end
if ~isempty(JC)
    writetable(JC, fullfile(outdir, 'jumpcheck.csv'));
    p('\n## Kiem chung nhay chu ky (so voi brute force Jmax = 0, cung truong hop)\n\n');
    p('Sai lech tuyet doi lon nhat tren moi RPT chung (diem %%; R: mOhm), sai lech tuong doi o RPT chung cuoi so voi phan tang tu RPT0 (%%), phan Li da bu moi buoc nhay (tuong doi), gio tuong toi RPT chung cuoi.\n\n');
    p('| truong hop | Jmax | so RPT | dSOH | dLLI | dLAM_NE | dLAM_PE | dR | tuong doi SOH / LLI / LAM_NE / LAM_PE / R (%%) | bu Li max | gio brute / nhay |\n|---|---|---|---|---|---|---|---|---|---|---|\n');
    for i = 1:height(JC)
        p('| %s | %d | %d | %.3f | %.3f | %.3f | %.3f | %.3f | %.2f / %.2f / %.2f / %.2f / %.2f | %.1e | %.2f / %.2f |\n', JC.case{i}, JC.Jmax(i), JC.nRPT(i), ...
            JC.dSOH_max(i), JC.dLLI_max(i), JC.dLAMNE_max(i), JC.dLAMPE_max(i), JC.dR_max_mOhm(i), JC.relSOH_last_pct(i), JC.relLLI_last_pct(i), ...
            JC.relLAMNE_last_pct(i), JC.relLAMPE_last_pct(i), JC.relR_last_pct(i), JC.Li_jump_corr_max(i), JC.wall_h_brute(i), JC.wall_h_jump(i));
    end
end
if ~isempty(S)
    S = sortrows(S, {'variant', 'Jmax', 'expt', 'T_degC'});
    writetable(S, fullfile(outdir, 'aging_summary.csv'));
    p('\n## Tom tat (brute force)\n\n| Expt | T | Q_thr cuoi (kAh) | SOH | SOH_RPT0 | LLI | LAM_NE | LAM_PE | R | MPE SOH / Res / LLI / LAM_NE / LAM_PE / tot | Li 2025 cong bo | MPE tot (SOH_RPT0) | RMSE SOH / LLI / LAM_NE / LAM_PE / R | gio |\n|---|---|---|---|---|---|---|---|---|---|---|---|---|---|\n');
    for i = 1:height(S)
        p('| %d | %g | %.2f | %.2f | %.2f | %.2f | %.2f | %.2f | %.2f | %.2f / %.2f / %.2f / %.2f / %.2f / %.2f | %.2f / %.2f / %.2f / %.2f / %.2f / %.2f | %.2f | %.2f / %.2f / %.2f / %.2f / %.2f | %.2f |\n', ...
            S.expt(i), S.T_degC(i), S.Qthr_kAh(i), S.SOH(i), S.SOH_RPT0(i), S.LLI(i), S.LAM_NE(i), S.LAM_PE(i), S.R_mOhm(i), ...
            S.MPE_SOH(i), S.MPE_Res(i), S.MPE_LLI(i), S.MPE_LAMNE(i), S.MPE_LAMPE(i), S.MPE_tot(i), ...
            S.Li2025_SOH(i), S.Li2025_Res(i), S.Li2025_LLI(i), S.Li2025_LAMNE(i), S.Li2025_LAMPE(i), S.Li2025_tot(i), S.MPE_tot_SOH_RPT0(i), ...
            S.RMSE_SOH(i), S.RMSE_LLI(i), S.RMSE_LAMNE(i), S.RMSE_LAMPE(i), S.RMSE_Res(i), S.wall_h(i));
    end
    p('\n## Tai Q_thr cuoi cua thuc nghiem (mo hinh noi suy)\n\n| Expt | T | Q_thr (kAh) | SOH mo hinh / exp | LLI mo hinh / exp | LAM_NE mo hinh / exp | LAM_PE mo hinh / exp |\n|---|---|---|---|---|---|---|\n');
    for i = 1:height(S)
        p('| %d | %g | %.2f | %.2f / %.2f | %.2f / %.2f | %.2f / %.2f | %.2f / %.2f |\n', S.expt(i), S.T_degC(i), S.Qthr_exp_last_kAh(i), ...
            S.SOH_at_exp_last(i), S.SOH_exp_last(i), S.LLI_at_exp_last(i), S.LLI_exp_last(i), S.LAMNE_at_exp_last(i), S.LAMNE_exp_last(i), ...
            S.LAMPE_at_exp_last(i), S.LAMPE_exp_last(i));
    end
end
fclose(fid);
try
    plots(MM, EE, C, outdir);
catch err
    fprintf('ag_report: khong ve duoc hinh: %s\n', err.message);
end
type(fullfile(outdir, 'aging_validation.md'));

    function p(varargin)
        fprintf(fid, varargin{:});
    end
end

function [mpe, rmse] = errs(xm, M, E, q)
mpe = NaN(1, numel(q)); rmse = mpe;
ef = {'SOH', 'R_mOhm', 'LLI_pct', 'LAM_NE_pct', 'LAM_PE_pct', 'SOH0'};
for k = 1:numel(q)
    vm = interp1(xm, M.(q{k}), E.x, 'linear');
    ve = E.(ef{k});
    ok = ~isnan(vm) & ~isnan(ve) & ve ~= 0;
    if any(ok), mpe(k) = 100*mean(abs(ve(ok) - vm(ok))./abs(ve(ok))); end
    ok = ~isnan(vm) & ~isnan(ve);
    if any(ok), rmse(k) = sqrt(mean((ve(ok) - vm(ok)).^2)); end
end
end

function E = expavg(K, w, T, Qref)
sel = strcmp(K.soc_window_pct, w) & K.T_nominal_degC == T;
Kk = K(sel, :);
rp = unique(Kk.rpt);
E = table();
for i = 1:numel(rp)
    s = Kk.rpt == rp(i);
    E = [E; table(rp(i), mean(Kk.charge_throughput_Ah(s), 'omitnan')/1000, 100*mean(Kk.cap_C10_mAh(s), 'omitnan')/(1000*Qref), ...
        100*mean(Kk.SOH_C10(s), 'omitnan'), ...
        100*mean(Kk.LLI(s), 'omitnan'), 100*mean(Kk.LAM_NE_tot(s), 'omitnan'), 100*mean(Kk.LAM_PE(s), 'omitnan'), ...
        1e3*mean(Kk.R_0p1s_Ohm(s), 'omitnan'), 'VariableNames', {'rpt', 'x', 'SOH', 'SOH0', 'LLI_pct', 'LAM_NE_pct', 'LAM_PE_pct', 'R_mOhm'})]; %#ok<AGROW>
end
end

function plots(MM, EE, C, outdir)
qq = {'SOH', 'LLI_pct', 'LAM_NE_pct', 'LAM_PE_pct', 'R_mOhm'};
tt = {'SOH (%, /4.865 Ah)', 'LLI (%)', 'LAM_{NE} (%)', 'LAM_{PE} (%)', 'R_{0.1s} (m\Omega)'};
qC = {'', 'LLI_pct', 'LAM_NE_tot_pct', 'LAM_PE_pct', 'R_0p1s_mOhm'};
for ex = [2 3]
    f = figure('Visible', 'off', 'Position', [0 0 1500 800]);
    cols = lines(3); Ts = [10 25 40];
    for k = 1:5
        subplot(2, 3, k); hold on; grid on; title(tt{k}); xlabel('Q_{thr} (kAh)');
        for i = 1:numel(MM)
            M = MM{i};
            if M.expt(1) ~= ex || M.Jmax(1) ~= 0, continue; end
            c = cols(Ts == M.T_degC(1), :);
            plot(M.Qthr_Ah/1000, M.(qq{k}), '-', 'Color', c, 'LineWidth', 1.5, 'DisplayName', sprintf('mo hinh %g C', M.T_degC(1)));
            E = EE{i};
            plot(E.x, E.(qq{k}), 'o', 'Color', c, 'DisplayName', sprintf('exp %g C', M.T_degC(1)));
            if ex == 2 && ~isempty(qC{k})
                sel = strcmp(C.series, 'model_5_coupled') & strcmp(C.quantity, qC{k}) & C.T_panel_degC == M.T_degC(1) & strcmp(C.soc_window_pct, '70-85');
                plot(C.charge_throughput_kAh(sel), C.value(sel), '--', 'Color', c, 'DisplayName', sprintf('Li 2025 %g C', M.T_degC(1)));
            end
        end
        if k == 1, legend('Location', 'southwest', 'FontSize', 7); end
    end
    exportgraphics(f, fullfile(outdir, sprintf('aging_expt%d.png', ex)), 'Resolution', 110);
    close(f);
end
end

function s = f2(v)
if isnan(v), s = '-'; else, s = sprintf('%.2f', v); end
end
function s = f3(v)
if isnan(v), s = '-'; else, s = sprintf('%.3f', v); end
end
