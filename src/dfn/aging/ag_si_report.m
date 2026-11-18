function ag_si_report(resdir, outdir, datadir)
%AG_SI_REPORT  Bao cao TANG 2 (lao hoa silicon, gia dinh): hieu chinh, so sanh tang 1 / tang 2 /
% thuc nghiem Kirkaldy 2024 (data/derived/D_kirkaldy_per_cell_rpt.csv, trung binh cell theo RPT),
% cac moc van ban Kirkaldy 2022, kiem chung nhay chu ky. Doc moi rpt.csv duoi resdir.
%   variant 'default' = tang 1; 'si' = tang 2 (tham so hieu chinh); 'si<F>_k<k>' = lan do (probe).
% SOH = Q_0.1C / 4.865 Ah ca hai phia (GD-60). LAM_Si thuc nghiem = LAM_NE_Si (phan dung luong Si mat).
%
% Hieu chinh (GD-93; chi tren Expt 1, 25 C): moi dang F co dr/dt = -c(t) g_F(r), r = eps_Si/eps_Si,0,
%   g_A = 1/r, g_B = r, g_C = r^2; c(t) = (k/eps_Si,0) dc_Si,ref^m phu thuoc giao thuc, khong phu
%   thuoc r (bo qua hoi tiep yeu qua LLI/LAM_Gr). Tu mot lan do (dang F0, k0): tau(Q) = G_F0(r(Q))/k0,
%   G_F(r) = int_r^1 dr/g_F: G_A = (1 - r^2)/2, G_B = -ln r, G_C = 1/r - 1. Voi dang F va k bat ky:
%   r(Q) = G_F^-1(k tau(Q)). Chon k (va F) toi thieu RMSE LAM_Si so voi trung binh cell 25 C (RPT >= 1).
%   Lan chay tang 2 day du o 25 C sau do la phep kiem tra truc tiep cua phep anh xa nay.
if nargin < 3, datadir = 'data/derived'; end
if ~exist(outdir, 'dir'), mkdir(outdir); end
Qref = 4.865;
win = containers.Map({1, 2, 3, 5}, {'0-30', '70-85', '85-100', '0-100'});
oK = detectImportOptions(fullfile(datadir, 'D_kirkaldy_per_cell_rpt.csv'));
oK = setvartype(oK, {'expt', 'soc_window_pct', 'cell', 'source_file'}, 'char');
K = readtable(fullfile(datadir, 'D_kirkaldy_per_cell_rpt.csv'), oK);
files = dir(fullfile(resdir, '**', 'rpt.csv'));
MM = {};
for i = 1:numel(files)
    M = readtable(fullfile(files(i).folder, files(i).name), 'TextType', 'char');
    if height(M) < 2, continue; end
    M.SOH = 100*M.Qdis01_Ah/Qref;
    M.x = M.Qthr_Ah/1000;
    if ~any(strcmp(M.Properties.VariableNames, 'LAM_Si_pct')), M.LAM_Si_pct = NaN(height(M), 1); M.LAM_Gr_pct = NaN(height(M), 1); end
    st = fullfile(files(i).folder, 'status.txt'); M.status = repmat({'?'}, height(M), 1);
    if exist(st, 'file'), l = strtrim(fileread(st)); l = strsplit(l, newline); M.status(:) = l(1); end
    MM{end+1} = M; %#ok<AGROW>
end
% trung lap: giu ban nhieu RPT nhat
kf = cellfun(@(M) sprintf('%s|%d|%g|%d', M.variant{1}, M.expt(1), M.T_degC(1), M.Jmax(1)), MM, 'UniformOutput', false);
nr = cellfun(@height, MM); keep = true(size(MM));
for i = 1:numel(MM)
    same = find(strcmp(kf, kf{i})); [~, b] = max(nr(same)); keep(i) = same(b) == i;
end
MM = MM(keep); kf = kf(keep);
fid = fopen(fullfile(outdir, 'silicon_report.md'), 'w');
p('# Tang 2: lao hoa silicon o SOC thap (GIA DINH) - bao cao CI\n\n');
p('Tang 1 = mo hinh "5 coupled" giu nguyen (variant `default`); tang 2 = them LAM silicon (variant `si`). ');
p('Thuc nghiem: Kirkaldy 2024 (Zenodo 10637534), trung binh cell theo RPT. SOH = Q_0.1C/%.3f Ah. Don vi: diem %%.\n\n', Qref);
p('Cac lan chay: %s\n\n', strjoin(cellfun(@(M) sprintf('`%s/e%d/%gC/J%d` (%d RPT, %s)', M.variant{1}, M.expt(1), M.T_degC(1), M.Jmax(1), height(M) - 1, M.status{1}), MM, 'UniformOutput', false), ', '));

% ---- 1. hieu chinh ---------------------------------------------------------------
E25 = expavg(K, '0-30', 25, Qref);
iP = find(cellfun(@(M) M.expt(1) == 1 && M.T_degC(1) == 25 && ~isempty(regexp(M.variant{1}, '^si[ABC]_k', 'once')), MM));
CAL = table();
if ~isempty(iP)
    p('## 1. Hieu chinh k (Expt 1, 25 C; muc tieu: LAM_Si trung binh cell D, E, F)\n\n');
    Gf = struct('A', @(r) (1 - r.^2)/2, 'B', @(r) -log(r), 'C', @(r) 1./r - 1);
    Gi = struct('A', @(u) sqrt(max(1 - 2*u, 0)), 'B', @(u) exp(-u), 'C', @(u) 1./(1 + u));
    sel = E25.rpt >= 1;
    xe = E25.x(sel); ye = E25.LAM_Si(sel);
    for i = iP
        M = MM{i};
        t = regexp(M.variant{1}, '^si([ABC])_k(.+)$', 'tokens', 'once'); F0 = t{1}; k0 = str2double(t{2});
        r = 1 - M.LAM_Si_pct/100;
        tau = Gf.(F0)(max(r, 1e-9))/k0;
        p('### Lan do `%s` (%d RPT, Q_thr toi %.2f kAh; LAM_Si cuoi %.2f %%)\n\n', M.variant{1}, height(M) - 1, M.x(end), M.LAM_Si_pct(end));
        inr = xe <= M.x(end) + 1e-9;
        tq = interp1(M.x, tau, xe(inr), 'linear');
        p('| dang | k* | RMSE LAM_Si (diem %%) | so diem |%s\n|---|---|---|---|%s\n', sprintf(' %.2f kAh |', xe(inr)), repmat('---|', 1, nnz(inr)));
        p('| thuc nghiem | | | |%s\n', sprintf(' %.1f |', ye(inr)));
        for F = 'ABC'
            fun = @(lk) sqrt(mean((100*(1 - Gi.(F)(10^lk*tq)) - ye(inr)).^2));
            [lk, e] = fminbnd(fun, -18, -9);
            % kiem tra bien
            ks = 10^lk;
            pr = 100*(1 - Gi.(F)(ks*tq));
            p('| %s | %.4g | %.2f | %d |%s\n', F, ks, e, nnz(inr), sprintf(' %.1f |', pr));
            CAL = [CAL; table({M.variant{1}}, {F}, ks, e, nnz(inr), M.x(end), 'VariableNames', {'probe', 'form', 'k', 'RMSE_LAMSi', 'npts', 'probe_last_kAh'})]; %#ok<AGROW>
        end
        p('\n');
    end
    writetable(CAL, fullfile(outdir, 'si_calibration.csv'));
end

% ---- 2. tang 1 / tang 2 / thuc nghiem -------------------------------------------------
p('## 2. So sanh tang 1 / tang 2 / thuc nghiem (gia tri tai cac RPT thuc nghiem, mo hinh noi suy theo Q_thr)\n\n');
qs = {'SOH', 'LLI_pct', 'LAM_NE_pct', 'LAM_Si_pct', 'LAM_Gr_pct'};
qe = {'SOH', 'LLI', 'LAM_NE', 'LAM_Si', 'LAM_Gr'};
SUM = table(); LONG = table();
for ex = [1 5 2 3]
    for T = [10 25 40]
        i1 = find(strcmp(kf, sprintf('default|%d|%g|20', ex, T)) | strcmp(kf, sprintf('default|%d|%g|0', ex, T)));
        i2 = find(strcmp(kf, sprintf('si|%d|%g|20', ex, T)));
        i1 = i1(1:min(1, end)); i2 = i2(1:min(1, end));
        if isempty(i1) && isempty(i2), continue; end
        E = expavg(K, win(ex), T, Qref);
        p('### Expt %d (%s %%), %g C\n\n', ex, win(ex), T);
        p('| RPT exp | Q_thr (kAh) | SOH exp / T1 / T2 | LLI exp / T1 / T2 | LAM_NE exp / T1 / T2 | LAM_Si exp / T2 | LAM_Gr exp / T2 |\n|---|---|---|---|---|---|---|\n');
        V1 = interpq(MM, i1, E.x, qs); V2 = interpq(MM, i2, E.x, qs);
        for r = 1:height(E)
            p('| %d | %.2f | %s / %s / %s | %s / %s / %s | %s / %s / %s | %s / %s | %s / %s |\n', E.rpt(r), E.x(r), ...
                f1(E.SOH(r)), f1(V1(r,1)), f1(V2(r,1)), f1(E.LLI(r)), f1(V1(r,2)), f1(V2(r,2)), ...
                f1(E.LAM_NE(r)), f1(V1(r,3)), f1(V2(r,3)), f1(E.LAM_Si(r)), f1(V2(r,4)), f1(E.LAM_Gr(r)), f1(V2(r,5)));
            LONG = [LONG; table(ex, T, E.rpt(r), E.x(r), E.SOH(r), V1(r,1), V2(r,1), E.LLI(r), V1(r,2), V2(r,2), ...
                E.LAM_NE(r), V1(r,3), V2(r,3), E.LAM_Si(r), V2(r,4), E.LAM_Gr(r), V2(r,5), ...
                'VariableNames', {'expt', 'T_degC', 'rpt_exp', 'Qthr_kAh', 'SOH_exp', 'SOH_T1', 'SOH_T2', 'LLI_exp', 'LLI_T1', 'LLI_T2', ...
                'LAMNE_exp', 'LAMNE_T1', 'LAMNE_T2', 'LAMSi_exp', 'LAMSi_T2', 'LAMGr_exp', 'LAMGr_T2'})]; %#ok<AGROW>
        end
        r1 = rmse(V1, E, qe); r2 = rmse(V2, E, qe);
        p('\nRMSE (diem %%) SOH / LLI / LAM_NE / LAM_Si / LAM_Gr: tang 1 %s; tang 2 %s.\n', strjoin(arrayfun(@f2, r1(1:3), 'UniformOutput', false), ' / '), ...
            strjoin(arrayfun(@f2, r2, 'UniformOutput', false), ' / '));
        lc = NaN(1, 2);
        if ~isempty(i1), lc(1) = max(abs(MM{i1}.Li_cons_rel)); end
        if ~isempty(i2), lc(2) = max(abs(MM{i2}.Li_cons_rel)); end
        p('Bao toan Li (max |lech tuong doi|): tang 1 %.1e, tang 2 %.1e.\n\n', lc);
        % gia tri tai 2, 4, 5 kAh va RPT cuoi chung
        xs = [2 4 5];
        for xx = xs
            v1 = interpq(MM, i1, xx, qs); v2 = interpq(MM, i2, xx, qs); ve = expat(E, xx);
            SUM = [SUM; table(ex, T, xx, ve(1), v1(1), v2(1), ve(2), v1(2), v2(2), ve(3), v1(3), v2(3), ve(4), v2(4), ve(5), v2(5), r1(1), r2(1), r1(2), r2(2), r1(3), r2(3), r2(4), lc(1), lc(2), ...
                'VariableNames', {'expt', 'T_degC', 'Qthr_kAh', 'SOH_exp', 'SOH_T1', 'SOH_T2', 'LLI_exp', 'LLI_T1', 'LLI_T2', 'LAMNE_exp', 'LAMNE_T1', 'LAMNE_T2', ...
                'LAMSi_exp', 'LAMSi_T2', 'LAMGr_exp', 'LAMGr_T2', 'RMSE_SOH_T1', 'RMSE_SOH_T2', 'RMSE_LLI_T1', 'RMSE_LLI_T2', 'RMSE_LAMNE_T1', 'RMSE_LAMNE_T2', 'RMSE_LAMSi_T2', 'Li_cons_T1', 'Li_cons_T2'})]; %#ok<AGROW>
        end
    end
end
if ~isempty(LONG), writetable(LONG, fullfile(outdir, 'si_vs_exp_long.csv')); end
if ~isempty(SUM)
    writetable(SUM, fullfile(outdir, 'si_summary.csv'));
    p('## 3. Tom tat tai 4 kAh (mo hinh noi suy; thuc nghiem noi suy giua RPT)\n\n');
    p('| Expt | T | SOH exp / T1 / T2 | LLI exp / T1 / T2 | LAM_NE exp / T1 / T2 | LAM_Si exp / T2 | LAM_Gr exp / T2 | RMSE SOH T1/T2 | RMSE LLI T1/T2 | RMSE LAM_NE T1/T2 | RMSE LAM_Si T2 |\n|---|---|---|---|---|---|---|---|---|---|---|\n');
    s4 = SUM(SUM.Qthr_kAh == 4, :);
    for i = 1:height(s4)
        p('| %d | %g | %s / %s / %s | %s / %s / %s | %s / %s / %s | %s / %s | %s / %s | %s / %s | %s / %s | %s / %s | %s |\n', s4.expt(i), s4.T_degC(i), ...
            f1(s4.SOH_exp(i)), f1(s4.SOH_T1(i)), f1(s4.SOH_T2(i)), f1(s4.LLI_exp(i)), f1(s4.LLI_T1(i)), f1(s4.LLI_T2(i)), ...
            f1(s4.LAMNE_exp(i)), f1(s4.LAMNE_T1(i)), f1(s4.LAMNE_T2(i)), f1(s4.LAMSi_exp(i)), f1(s4.LAMSi_T2(i)), f1(s4.LAMGr_exp(i)), f1(s4.LAMGr_T2(i)), ...
            f2(s4.RMSE_SOH_T1(i)), f2(s4.RMSE_SOH_T2(i)), f2(s4.RMSE_LLI_T1(i)), f2(s4.RMSE_LLI_T2(i)), f2(s4.RMSE_LAMNE_T1(i)), f2(s4.RMSE_LAMNE_T2(i)), f2(s4.RMSE_LAMSi_T2(i)));
    end
end

% ---- 4. moc van ban Kirkaldy 2022 ---------------------------------------------------------
p('\n## 4. Cac moc in trong van ban Kirkaldy 2022 (tang 2)\n\n| Moc | Gia tri in | Tang 2 |\n|---|---|---|\n');
g = @(ex, T, q, x) interpq(MM, find(strcmp(kf, sprintf('si|%d|%g|20', ex, T))), x, {q});
p('| LAM-Si, 0-30 %%, 40 C, 4 kAh (tr. 1) | 80 %% | %s |\n', f1(g(1, 40, 'LAM_Si_pct', 4)));
p('| LAM-Gr, 0-30 %%, 40 C, 4 kAh (tr. 1) | 10 %% | %s |\n', f1(g(1, 40, 'LAM_Gr_pct', 4)));
p('| LAM-Si, 0-30 %%, 25 / 40 C, 4 kAh (tr. 8) | > 70 %% | %s / %s |\n', f1(g(1, 25, 'LAM_Si_pct', 4)), f1(g(1, 40, 'LAM_Si_pct', 4)));
p('| LAM-Si, 0-30 %%, 25 C, 5 kAh (tr. 8) | 80 %% | %s |\n', f1(g(1, 25, 'LAM_Si_pct', 5)));
p('| LAM-Si, 0-100 %%, 25 C, 5 kAh (tr. 8) | > 30 %% | %s |\n', f1(g(5, 25, 'LAM_Si_pct', 5)));
p('| Phan LAM-Si (4 kAh) da xay ra trong 2 kAh dau, 0-30 %%, 25 C (tr. 6: "giai doan nhanh trong 2 kAh dau") | dinh tinh | %s %%  (thuc nghiem: %s %%) |\n', ...
    f1(100*g(1, 25, 'LAM_Si_pct', 2)/g(1, 25, 'LAM_Si_pct', 4)), f1(100*expat(E25, 2, 4)/expat(E25, 4, 4)));
p('| 0-30 %%, 4 kAh: LAM-Si 10 C < 25 / 40 C (tr. 6, 8) | dinh tinh | %s / %s / %s |\n\n', f1(g(1, 10, 'LAM_Si_pct', 4)), f1(g(1, 25, 'LAM_Si_pct', 4)), f1(g(1, 40, 'LAM_Si_pct', 4)));

% ---- 5. tang 2 khong lam doi 70-85 / 85-100 -------------------------------------------------
p('## 5. Tang 2 - tang 1 o 70-85 %% va 85-100 %% (cung Jmax, moi RPT chung)\n\n| Expt | T | so RPT | max |dSOH| | max |dLLI| | max |dLAM_NE| | LAM_Si cuoi (T2) | Q_thr cuoi (kAh) |\n|---|---|---|---|---|---|---|---|\n');
for ex = [2 3 1 5]
    for T = [10 25 40]
        i1 = find(strcmp(kf, sprintf('default|%d|%g|20', ex, T))); i2 = find(strcmp(kf, sprintf('si|%d|%g|20', ex, T)));
        if isempty(i1) || isempty(i2), continue; end
        A1 = MM{i1}; A2 = MM{i2}; rr = intersect(A1.rpt, A2.rpt);
        d = @(q) max(abs(arrayfun(@(r) A2.(q)(A2.rpt == r) - A1.(q)(A1.rpt == r), rr)));
        p('| %d | %g | %d | %.3f | %.3f | %.3f | %.2f | %.2f |\n', ex, T, numel(rr) - 1, d('SOH'), d('LLI_pct'), d('LAM_NE_pct'), A2.LAM_Si_pct(A2.rpt == rr(end)), A2.x(A2.rpt == rr(end)));
    end
end

% ---- 6. kiem chung nhay chu ky (tang 2) -------------------------------------------------------
p('\n## 6. Kiem chung nhay chu ky (Jmax > 0 so voi brute force Jmax = 0, cung bien the/Expt/T)\n\n| truong hop | Jmax | so RPT | dSOH | dLLI | dLAM_NE | dLAM_Si | gio brute / nhay |\n|---|---|---|---|---|---|---|---|\n');
for i = 1:numel(MM)
    B = MM{i};
    if B.Jmax(1) ~= 0 || ~startsWith(B.variant{1}, 'si'), continue; end
    for j = 1:numel(MM)
        Jt = MM{j};
        if j == i || Jt.Jmax(1) == 0 || ~strcmp(Jt.variant{1}, B.variant{1}) || Jt.expt(1) ~= B.expt(1) || Jt.T_degC(1) ~= B.T_degC(1), continue; end
        rr = intersect(B.rpt(B.rpt > 0), Jt.rpt(Jt.rpt > 0));
        if isempty(rr), continue; end
        d = @(q) max(abs(arrayfun(@(r) Jt.(q)(Jt.rpt == r) - B.(q)(B.rpt == r), rr)));
        p('| %s e%d %gC | %d | %d | %.3f | %.3f | %.3f | %.3f | %.2f / %.2f |\n', B.variant{1}, B.expt(1), B.T_degC(1), Jt.Jmax(1), numel(rr), ...
            d('SOH'), d('LLI_pct'), d('LAM_NE_pct'), d('LAM_Si_pct'), B.wall_h(B.rpt == rr(end)), Jt.wall_h(Jt.rpt == rr(end)));
    end
end
fclose(fid);
try
    plots(MM, kf, K, win, Qref, outdir);
catch err
    fprintf('ag_si_report: khong ve duoc hinh: %s\n', err.message);
end
type(fullfile(outdir, 'silicon_report.md'));

    function p(varargin)
        fprintf(fid, varargin{:});
    end
end

function V = interpq(MM, i, x, qs)
V = NaN(numel(x), numel(qs));
if isempty(i), return; end
M = MM{i};
for k = 1:numel(qs)
    V(:, k) = interp1(M.x, M.(qs{k}), x(:), 'linear');
end
end

function v = expat(E, x, col)
% thuc nghiem noi suy tuyen tinh theo Q_thr; col: chi so cot (1 SOH, 2 LLI, 3 LAM_NE, 4 LAM_Si, 5 LAM_Gr)
q = {'SOH', 'LLI', 'LAM_NE', 'LAM_Si', 'LAM_Gr'};
v = cellfun(@(f) interp1(E.x, E.(f), x, 'linear'), q);
if nargin > 2, v = v(col); end
end

function r = rmse(V, E, qe)
r = NaN(1, numel(qe));
for k = 1:numel(qe)
    ve = E.(qe{k}); ok = ~isnan(V(:, k)) & ~isnan(ve) & E.rpt >= 1;
    if any(ok), r(k) = sqrt(mean((V(ok, k) - ve(ok)).^2)); end
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
        100*mean(Kk.LLI(s), 'omitnan'), 100*mean(Kk.LAM_NE_tot(s), 'omitnan'), 100*mean(Kk.LAM_NE_Si(s), 'omitnan'), ...
        100*mean(Kk.LAM_NE_Gr(s), 'omitnan'), nnz(s), 'VariableNames', {'rpt', 'x', 'SOH', 'LLI', 'LAM_NE', 'LAM_Si', 'LAM_Gr', 'ncell'})]; %#ok<AGROW>
end
end

function plots(MM, kf, K, win, Qref, outdir)
qq = {'SOH', 'LLI_pct', 'LAM_NE_pct', 'LAM_Si_pct'}; qe = {'SOH', 'LLI', 'LAM_NE', 'LAM_Si'};
tt = {'SOH (%, /4.865 Ah)', 'LLI (%)', 'LAM_{NE} (%)', 'LAM_{Si} (%)'};
cols = lines(3); Ts = [10 25 40];
for ex = [1 5 2 3]
    f = figure('Visible', 'off', 'Position', [0 0 1400 900]);
    for k = 1:4
        subplot(2, 2, k); hold on; grid on; title(sprintf('Expt %d (%s %%): %s', ex, win(ex), tt{k})); xlabel('Q_{thr} (kAh)');
        for it = 1:3
            T = Ts(it); c = cols(it, :);
            E = expavg(K, win(ex), T, Qref);
            if ~isempty(E), plot(E.x, E.(qe{k}), 'o', 'Color', c, 'DisplayName', sprintf('exp %g C', T)); end
            i1 = find(strcmp(kf, sprintf('default|%d|%g|20', ex, T)));
            i2 = find(strcmp(kf, sprintf('si|%d|%g|20', ex, T)));
            if ~isempty(i1), plot(MM{i1}.x, MM{i1}.(qq{k}), '--', 'Color', c, 'DisplayName', sprintf('tang 1 %g C', T)); end
            if ~isempty(i2), plot(MM{i2}.x, MM{i2}.(qq{k}), '-', 'Color', c, 'LineWidth', 1.5, 'DisplayName', sprintf('tang 2 %g C', T)); end
        end
        if k == 1, legend('Location', 'southwest', 'FontSize', 7); end
    end
    exportgraphics(f, fullfile(outdir, sprintf('silicon_expt%d.png', ex)), 'Resolution', 100);
    close(f);
end
end

function s = f1(v)
if isempty(v) || isnan(v), s = '-'; else, s = sprintf('%.1f', v); end
end
function s = f2(v)
if isempty(v) || isnan(v), s = '-'; else, s = sprintf('%.2f', v); end
end
