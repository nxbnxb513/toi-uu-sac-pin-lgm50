function ag_report(resdir, outdir, datadir)
%AG_REPORT  So sanh mo phong lao hoa (rpt.csv cua moi ag_run) voi thuc nghiem Kirkaldy 2024
% (data/derived/D_kirkaldy_per_cell_rpt.csv, trung binh cac cell theo chi so RPT) va voi
% sai so mo hinh "5 coupled" do Li 2025 cong bo (Table 2; SI Table 12 - cach doc suy luan)
% va duong mo hinh cua tac gia cho Expt 2 (Source Data Fig. 3-4, data/derived/C_fig_ageing_long.csv;
% Fig. 6 KHONG dung vi gan nhan sai).
% MPE (Li 2025 pt. (1); code Reload_Exp2.ipynb::Calculate_MPE_re): MPE = mean(|exp - mo hinh|/|exp|)
% tren cac diem RPT thuc nghiem (noi suy tuyen tinh mo hinh theo dien luong thong qua, bo diem
% exp = 0 va diem ngoai khoang mo hinh); MPE_tot = MPE_SOH/2 + (MPE_Res + MPE_LLI + MPE_LAMNE + MPE_LAMPE)/8.
if nargin < 3, datadir = 'data/derived'; end
if ~exist(outdir, 'dir'), mkdir(outdir); end
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
q  = {'SOH_pct', 'R_mOhm', 'LLI_pct', 'LAM_NE_pct', 'LAM_PE_pct'};
qn = {'SOH', 'Res', 'LLI', 'LAM_NE', 'LAM_PE'};
qC = {'SOH_pct', 'R_0p1s_mOhm', 'LLI_pct', 'LAM_NE_tot_pct', 'LAM_PE_pct'};
fid = fopen(fullfile(outdir, 'aging_validation.md'), 'w');
p('# Kiem chung mo hinh lao hoa "5 coupled" trong DFN (buoc C)\n\n');
p('Thuc nghiem: Kirkaldy 2024 (Zenodo 10637534), trung binh cac cell theo RPT. MPE theo Li 2025 pt. (1). ');
p('"Li 2025" = sai so mo hinh cua tac gia (Table 2; SI Table 12 theo cach doc suy luan). "lech mo hinh tac gia" = RMS(mo hinh nay - mo hinh tac gia) tai cac RPT cua tac gia (Source Data Fig. 3-4, chi Expt 2).\n\n');
S = table(); MM = {};
for i = 1:numel(files)
    M = readtable(fullfile(files(i).folder, files(i).name), 'TextType', 'char');
    if height(M) < 2, continue; end
    ex = M.expt(1); T = M.T_degC(1); var = M.variant{1}; Jm = M.Jmax(1);
    if ex == 2, w = '70-85'; else, w = '85-100'; end
    E = expavg(K, w, T);
    xm = M.Qthr_Ah/1000;
    st = fullfile(files(i).folder, 'status.txt'); stat = '?';
    if exist(st, 'file'), l = strsplit(fileread(st), newline); stat = l{1}; end
    p('\n## Expt %d (%s %%), %g C, bien the `%s`, Jmax = %d (%s, %d RPT)\n\n', ex, w, T, var, Jm, stat, height(M) - 1);
    p('| RPT | Q_thr mo hinh (kAh) | SOH | LLI | LAM_NE | LAM_PE | R (mOhm) | Q_thr exp (kAh) | SOH exp | LLI exp | LAM_NE exp | LAM_PE exp | R exp |\n|---|---|---|---|---|---|---|---|---|---|---|---|---|\n');
    for r = 1:max(height(M), height(E))
        a = repmat({''}, 1, 13);
        if r <= height(M), a(1:7) = {sprintf('%d', M.rpt(r)), f3(xm(r)), f2(M.SOH_pct(r)), f2(M.LLI_pct(r)), f2(M.LAM_NE_pct(r)), f2(M.LAM_PE_pct(r)), f2(M.R_mOhm(r))}; end
        if r <= height(E), a(8:13) = {f3(E.x(r)), f2(E.SOH_pct(r)), f2(E.LLI_pct(r)), f2(E.LAM_NE_pct(r)), f2(E.LAM_PE_pct(r)), f2(E.R_mOhm(r))}; end
        if isempty(a{1}), a{1} = sprintf('(exp %d)', r - 1); end
        p('| %s |\n', strjoin(a, ' | '));
    end
    mpe = NaN(1, 5);
    for k = 1:5
        vm = interp1(xm, M.(q{k}), E.x, 'linear');
        ve = E.(q{k});
        ok = ~isnan(vm) & ~isnan(ve) & ve ~= 0;
        if any(ok), mpe(k) = 100*mean(abs(ve(ok) - vm(ok))./abs(ve(ok))); end
    end
    tot = 0.5*mpe(1) + 0.125*sum(mpe(2:5));
    it = find(Ts == T);
    if ex == 2, pb = pub.e2(it, :); else, pb = pub.e3(it, :); end
    % mo hinh tac gia (chi Expt 2)
    dL = NaN(1, 5); mpeL = NaN(1, 6);
    if ex == 2
        for k = 1:5
            sel = strcmp(C.series, 'model_5_coupled') & strcmp(C.quantity, qC{k}) & C.T_panel_degC == T & strcmp(C.soc_window_pct, '70-85');
            xl = C.charge_throughput_kAh(sel); vl = C.value(sel);
            vm = interp1(xm, M.(q{k}), xl, 'linear'); okk = ~isnan(vm);
            if any(okk), dL(k) = sqrt(mean((vm(okk) - vl(okk)).^2)); end
            vmL = interp1(xl, vl, E.x, 'linear'); ve = E.(q{k});
            ok = ~isnan(vmL) & ~isnan(ve) & ve ~= 0;
            if any(ok), mpeL(k) = 100*mean(abs(ve(ok) - vmL(ok))./abs(ve(ok))); end
        end
        mpeL(6) = 0.5*mpeL(1) + 0.125*sum(mpeL(2:5));
    end
    p('\n| MPE (%%) | SOH | Res | LLI | LAM_NE | LAM_PE | tot |\n|---|---|---|---|---|---|---|\n');
    p('| mo hinh nay | %s |\n', strjoin(arrayfun(@f2, [mpe tot], 'UniformOutput', false), ' | '));
    p('| Li 2025 cong bo | %s |\n', strjoin(arrayfun(@f2, pb, 'UniformOutput', false), ' | '));
    if ex == 2
        p('| mo hinh tac gia (Source Data) tinh lai bang script nay | %s |\n', strjoin(arrayfun(@f2, mpeL, 'UniformOutput', false), ' | '));
        p('\nLech RMS so voi mo hinh tac gia: SOH %.2f, R %.2f mOhm, LLI %.2f, LAM_NE %.2f, LAM_PE %.2f (diem %%).\n', dL);
    end
    last = height(M);
    p('\nPhan ra LLI o RPT cuoi (%% Li trong hat luc RPT0): SEI %.2f, SEI vet nut %.2f, ma con lai %.3f, chet %.3f, LAM %.2f, can kho %.2f, dien giai/reservoir %.3f. LAM do can kho %.2f %%. eps_n min %.4f, l_cr max %.3g m.\n', ...
        M.LLI_SEI_pct(last), M.LLI_SEIcr_pct(last), M.LLI_pl_pct(last), M.LLI_dead_pct(last), M.LLI_LAM_pct(last), M.LLI_dry_pct(last), M.LLI_elyte_pct(last), ...
        M.LAM_dry_pct(last), M.eps_n_min(last), M.lcr_max(last));
    p('Bao toan Li: max |lech tuong doi| = %.2e; sai so bao toan lon nhat cua mot buoc nhay chu ky %.2e. Thoi gian tuong: %.2f h.\n', ...
        max(abs(M.Li_cons_rel)), max(M.jump_err_max), M.wall_h(last));
    row = table({var}, ex, T, Jm, {stat}, height(M) - 1, xm(last), M.SOH_pct(last), M.LLI_pct(last), M.LAM_NE_pct(last), M.LAM_PE_pct(last), M.R_mOhm(last), ...
        mpe(1), mpe(2), mpe(3), mpe(4), mpe(5), tot, pb(6), mpeL(6), max(abs(M.Li_cons_rel)), M.wall_h(last), ...
        'VariableNames', {'variant', 'expt', 'T_degC', 'Jmax', 'status', 'nRPT', 'Qthr_kAh', 'SOH', 'LLI', 'LAM_NE', 'LAM_PE', 'R_mOhm', ...
        'MPE_SOH', 'MPE_Res', 'MPE_LLI', 'MPE_LAMNE', 'MPE_LAMPE', 'MPE_tot', 'MPE_tot_Li2025', 'MPE_tot_Li_model_recomputed', 'Li_cons_max', 'wall_h'});
    S = [S; row]; %#ok<AGROW>
    MM{end+1} = M; %#ok<AGROW>
end
% ---- kiem chung phuong phap nhay chu ky: RPT 1 (sau set 1) so voi brute force (Jmax = 0) ----
key = @(M) sprintf('%s|%d|%g', M.variant{1}, M.expt(1), M.T_degC(1));
keys = cellfun(key, MM, 'UniformOutput', false);
qj = {'SOH_pct', 'LLI_pct', 'LAM_NE_pct', 'LAM_PE_pct', 'R_mOhm', 'LLI_SEI_pct', 'LLI_SEIcr_pct', 'LLI_dead_pct', 'LLI_LAM_pct'};
first = true;
for i = 1:numel(MM)
    if MM{i}.Jmax(1) ~= 0, continue; end
    B = MM{i}; b1 = B(B.rpt == 1, :); b0 = B(B.rpt == 0, :);
    if isempty(b1), continue; end
    for j = find(strcmp(keys, keys{i}))
        if j == i || isempty(MM{j}(MM{j}.rpt == 1, :)), continue; end
        if first
            p('\n## Kiem chung nhay chu ky (set 1 = 515 chu ky, RPT 1): sai lech so voi brute force (Jmax = 0)\n\n');
            p('Cot: gia tri brute force -> sai lech tuyet doi cua ban nhay (diem %%; R: mOhm), va sai lech tuong doi tren phan tang trong set 1 (so voi RPT 0).\n\n');
            p('| truong hop | Jmax | %s | chu ky mo phong / nhay | gio tuong (brute / nhay) |\n|---|---|%s---|---|\n', strjoin(qj, ' | '), repmat('---|', 1, numel(qj)));
            first = false;
        end
        J1 = MM{j}(MM{j}.rpt == 1, :);
        c = cell(1, numel(qj));
        for k = 1:numel(qj)
            inc = b1.(qj{k}) - b0.(qj{k});
            c{k} = sprintf('%.3f -> %.1e (%.2g %%)', b1.(qj{k}), J1.(qj{k}) - b1.(qj{k}), 100*abs(J1.(qj{k}) - b1.(qj{k}))/max(abs(inc), eps));
        end
        p('| %s | %d | %s | - | %.2f / %.2f |\n', keys{i}, MM{j}.Jmax(1), strjoin(c, ' | '), B.wall_h(end), MM{j}.wall_h(end));
    end
end
if ~isempty(S)
    S = sortrows(S, {'variant', 'Jmax', 'expt', 'T_degC'});
    writetable(S, fullfile(outdir, 'aging_summary.csv'));
    p('\n## Tom tat\n\n| bien the | Jmax | Expt | T | trang thai | Q_thr cuoi (kAh) | SOH | LLI | LAM_NE | LAM_PE | R | MPE_tot | MPE_tot Li 2025 | Li bao toan | gio |\n|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|\n');
    for i = 1:height(S)
        p('| %s | %d | %d | %g | %s | %.2f | %.2f | %.2f | %.2f | %.2f | %.2f | %.2f | %.2f | %.1e | %.2f |\n', S.variant{i}, S.Jmax(i), S.expt(i), S.T_degC(i), S.status{i}, ...
            S.Qthr_kAh(i), S.SOH(i), S.LLI(i), S.LAM_NE(i), S.LAM_PE(i), S.R_mOhm(i), S.MPE_tot(i), S.MPE_tot_Li2025(i), S.Li_cons_max(i), S.wall_h(i));
    end
end
fclose(fid);
type(fullfile(outdir, 'aging_validation.md'));

    function p(varargin)
        fprintf(fid, varargin{:});
    end
end

function E = expavg(K, w, T)
sel = strcmp(K.soc_window_pct, w) & K.T_nominal_degC == T;
Kk = K(sel, :);
rp = unique(Kk.rpt);
E = table();
for i = 1:numel(rp)
    s = Kk.rpt == rp(i);
    E = [E; table(rp(i), mean(Kk.charge_throughput_Ah(s), 'omitnan')/1000, 100*mean(Kk.SOH_C10(s), 'omitnan'), ...
        100*mean(Kk.LLI(s), 'omitnan'), 100*mean(Kk.LAM_NE_tot(s), 'omitnan'), 100*mean(Kk.LAM_PE(s), 'omitnan'), ...
        1e3*mean(Kk.R_0p1s_Ohm(s), 'omitnan'), 'VariableNames', {'rpt', 'x', 'SOH_pct', 'LLI_pct', 'LAM_NE_pct', 'LAM_PE_pct', 'R_mOhm'})]; %#ok<AGROW>
end
end

function s = f2(v)
if isnan(v), s = '-'; else, s = sprintf('%.2f', v); end
end
function s = f3(v)
if isnan(v), s = '-'; else, s = sprintf('%.3f', v); end
end
