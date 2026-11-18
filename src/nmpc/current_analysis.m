function current_analysis(fs_dirs, ekf_dir, outdir)
%CURRENT_ANALYSIS  Phan tich DONG SAC (khong chi lao hoa) cua cac lan chay thu:
% CCCV, NMPC biet het trang thai, NMPC + EKF. Chi doc cac CSV quy dao ma pilot_run.m
% da ghi (pilot_<w>_c<C>_T<T>_cccv_series.csv, pilot_<...>_k<i>_nmpc_series.csv:
% t_s, I_A (sac > 0), V, T_C, soc, xs_sep, eta_sep_mV, ...).
%   fs_dirs: cell cac thu muc ket qua NMPC biet het trang thai, theo THU TU UU TIEN
%            (truong hop co o nhieu thu muc thi lay thu muc dau tien; vd run chay lai
%            44249331640 dung truoc 44237965357)
%   ekf_dir: thu muc ket qua NMPC + EKF ('' = khong co)
% Ra (outdir): current_metrics.csv (moi phuong phap x truong hop), current_soc_bins.csv
% (dong trung binh moi khoang SOC 10 %, dung cho bang sac nhieu bac buoc H),
% current_report.md, hinh current_w<i>_c<C>.png (I(t), I(SOC); NMPC moi k) va
% current_ekf_w<i>_c<C>.png (CCCV / biet het trang thai / EKF).
% Dinh nghia chi so (ghi lai trong bao cao):
%   I TB = dien tich nap / thoi gian sac; C-rate theo 1C = par.Qnom.
%   dong TB moi khoang SOC = tich phan I dt / thoi gian, cac doan mau gan vao khoang
%     theo SOC o giua doan.
%   SOC bat dau giam dong = SOC (pin that) o mau dau tien SAU dinh ma I < 0.95 I_dinh.
%   CCCV: SOC chuyen CC -> CV = mau dau tien V >= V_cv - 1 mV.
%   phan dien tich nap o SOC > 80 % (chi khi vung ket thuc > 80 %).
%   thoi gian o I_max: I >= 0.99 I_max (GD-26: 2C = 10 A).
%   eta khi dong lon: eta_Li min trong cac mau I >= 0.8 I_dinh; thoi gian eta < 50 mV
%     (trong khoang 5 mV tren gioi han 45 mV) va dong TB trong thoi gian do.
if nargin < 3, outdir = 'results/current'; end
if ischar(fs_dirs) || isstring(fs_dirs), fs_dirs = cellstr(fs_dirs); end
if ~exist(outdir, 'dir'), mkdir(outdir); end
par = dfn_params(); cfgn = nmpc_config(par);
Qn = par.Qnom; Imax = cfgn.Imax; Vcv = v_limit(par); delta_mV = 1e3*cfgn.delta;
W = soc_windows(); Ks = [0.8 1 1.25 1.5 2 3 Inf];
fs = index_dirs(fs_dirs);
ek = containers.Map();
if nargin >= 2 && ~isempty(ekf_dir) && exist(ekf_dir, 'dir'), ek = index_dirs({ekf_dir}); end
% danh sach truong hop (vung x dong) tu file CCCV
keys_c = fs.keys; cases = {};
for i = 1:numel(keys_c)
    tk = regexp(keys_c{i}, '^w(\d+)_c(\d+)_T(\d+)_cccv$', 'tokens', 'once');
    if ~isempty(tk), cases{end+1} = tk; end %#ok<AGROW>
end
M = {}; B = {};
for ic = 1:numel(cases)
    iw = str2double(cases{ic}{1}); c10 = str2double(cases{ic}{2}); Tc = str2double(cases{ic}{3});
    jt = sprintf('w%d_c%d_T%d', iw, c10, Tc);
    soc0 = W(iw, 1); soc1 = W(iw, 2); Cb = c10/10;
    Sc = readtable(fs(sprintf('%s_cccv', jt)));
    [m, b] = metrics(Sc, 'CCCV', NaN); M{end+1} = m; B{end+1} = b; %#ok<AGROW>
    prof = struct('k', {}, 'fs', {}, 'ekf', {});
    for ik = 1:7
        key = sprintf('%s_k%d_nmpc', jt, ik);
        p = struct('k', Ks(ik), 'fs', [], 'ekf', []);
        if fs.isKey(key), p.fs = readtable(fs(key)); [m, b] = metrics(p.fs, 'NMPC', Ks(ik)); M{end+1} = m; B{end+1} = b; end %#ok<AGROW>
        if ek.isKey(key), p.ekf = readtable(ek(key)); [m, b] = metrics(p.ekf, 'NMPC+EKF', Ks(ik)); M{end+1} = m; B{end+1} = b; end %#ok<AGROW>
        prof(end+1) = p; %#ok<AGROW>
    end
    plots(Sc, prof, iw, c10, soc0, soc1, Cb);
end
Mt = vertcat(M{:}); Bt = vertcat(B{:});
writetable(Mt, fullfile(outdir, 'current_metrics.csv'));
writetable(Bt, fullfile(outdir, 'current_soc_bins.csv'));
report(Mt, Bt);
fprintf('current_analysis: %d dong chi so, %d dong khoang SOC -> %s\n', height(Mt), height(Bt), outdir);

    function [m, b] = metrics(S, meth, k)
        [t, iu] = unique(S.t_s, 'last'); I = max(S.I_A(iu), 0); soc = S.soc(iu); V = S.V(iu); eta = S.eta_sep_mV(iu);
        dt = diff(t); Im = (I(1:end-1) + I(2:end))/2; sm = (soc(1:end-1) + soc(2:end))/2;
        Qtot = sum(Im.*dt);
        [Ipk, ipk] = max(I);
        j = find(I(ipk:end) < 0.95*Ipk, 1); if isempty(j), soc_taper = NaN; else, soc_taper = soc(ipk + j - 1); end
        jv = find(V >= Vcv - 1e-3, 1); if isempty(jv), soc_cv = NaN; else, soc_cv = soc(jv); end
        if soc1 > 0.8 + 1e-9, f80 = sum(Im(sm >= 0.8).*dt(sm >= 0.8))/Qtot; else, f80 = NaN; end
        hi = I >= 0.8*Ipk; em = (eta(1:end-1) + eta(2:end))/2; near = em < delta_mV + 5;
        m = table(string(meth), iw, string(sprintf('%g-%g', 100*soc0, 100*soc1)), Cb, k, t(end), soc(1), soc(end), ...
            Ipk, Ipk/Qn, Qtot/t(end), Qtot/t(end)/Qn, soc(ipk), soc_taper, soc_cv, f80, sum(dt(Im >= 0.99*Imax)), ...
            min(eta), min(eta(hi)), sum(dt(near)), mean_or_nan(Im(near), dt(near))/Qn, ...
            'VariableNames', {'method', 'iw', 'window', 'Cbase', 'k', 't_charge_s', 'soc_start', 'soc_end', ...
            'I_peak_A', 'C_peak', 'I_mean_A', 'C_mean', 'soc_at_peak', 'soc_taper', 'soc_cc_cv', 'frac_Q_above80', ...
            't_at_Imax_s', 'eta_min_mV', 'eta_min_highI_mV', 't_eta_below50_s', 'C_mean_eta_below50'});
        ed = (floor(10*soc0 + 1e-9):ceil(10*soc1 - 1e-9))/10;
        nb = numel(ed) - 1; b = table();
        for q = 1:nb
            in = sm >= ed(q) & sm < ed(q+1) + (q == nb)*1e-9;
            tb_ = sum(dt(in));
            b = [b; table(string(meth), iw, string(sprintf('%g-%g', 100*soc0, 100*soc1)), Cb, k, ed(q), ed(q+1), ...
                mean_or_nan(Im(in), dt(in)), mean_or_nan(Im(in), dt(in))/Qn, tb_, sum(Im(in).*dt(in))/3600, ...
                'VariableNames', {'method', 'iw', 'window', 'Cbase', 'k', 'soc_lo', 'soc_hi', 'I_mean_A', 'C_mean', 't_s', 'Q_Ah'})]; %#ok<AGROW>
        end
    end

    function plots(Sc, prof, iw, c10, soc0, soc1, Cb)
        fig = figure('Visible', 'off', 'Position', [0 0 1100 420]);
        cm = parula(8);
        for sp = 1:2
            subplot(1, 2, sp); hold on; grid on;
            xx = Sc.t_s/60; if sp == 2, xx = 100*Sc.soc; end
            plot(xx, Sc.I_A/Qn, 'k', 'LineWidth', 2, 'DisplayName', sprintf('CCCV %gC', Cb));
            for q = 1:numel(prof)
                if isempty(prof(q).fs), continue; end
                S = prof(q).fs; xx = S.t_s/60; if sp == 2, xx = 100*S.soc; end
                plot(xx, max(S.I_A, 0)/Qn, 'Color', cm(q, :), 'DisplayName', sprintf('NMPC k = %g', prof(q).k));
            end
            ylabel('I (C)'); if sp == 1, xlabel('t (phut)'); else, xlabel('SOC (%)'); xlim(100*[soc0 soc1]); end
        end
        legend('Location', 'eastoutside'); sgtitle(sprintf('Dong sac, vung %g-%g %%, CCCV %gC, 25 degC (NMPC biet het trang thai)', 100*soc0, 100*soc1, Cb));
        exportgraphics(fig, fullfile(outdir, sprintf('current_w%d_c%d.png', iw, c10)), 'Resolution', 70); close(fig);
        if ~any(arrayfun(@(p) ~isempty(p.ekf), prof)), return; end
        fig = figure('Visible', 'off', 'Position', [0 0 1100 650]);
        sel = [2 3 7];   % k = 1, 1.25, khong gioi han
        for r = 1:numel(sel)
            p = prof(sel(r));
            for sp = 1:2
                subplot(numel(sel), 2, 2*(r-1) + sp); hold on; grid on;
                xx = Sc.t_s/60; if sp == 2, xx = 100*Sc.soc; end
                plot(xx, Sc.I_A/Qn, 'k', 'LineWidth', 1.5);
                if ~isempty(p.fs), S = p.fs; xx = S.t_s/60; if sp == 2, xx = 100*S.soc; end; plot(xx, max(S.I_A, 0)/Qn, 'b'); end
                if ~isempty(p.ekf), S = p.ekf; xx = S.t_s/60; if sp == 2, xx = 100*S.soc; end; plot(xx, max(S.I_A, 0)/Qn, 'r--'); end
                ylabel(sprintf('I (C), k = %g', p.k));
                if sp == 2, xlim(100*[soc0 soc1]); end
                if r == numel(sel), if sp == 1, xlabel('t (phut)'); else, xlabel('SOC (%)'); end, end
                if r == 1 && sp == 1, legend('CCCV', 'NMPC biet het', 'NMPC + EKF', 'Location', 'best'); end
            end
        end
        sgtitle(sprintf('Vung %g-%g %%, CCCV %gC: CCCV / NMPC biet het trang thai / NMPC + EKF', 100*soc0, 100*soc1, Cb));
        exportgraphics(fig, fullfile(outdir, sprintf('current_ekf_w%d_c%d.png', iw, c10)), 'Resolution', 70); close(fig);
    end

    function report(Mt, Bt)
        fid = fopen(fullfile(outdir, 'current_report.md'), 'w');
        fprintf(fid, '# Phan tich dong sac (tu dong, current_analysis.m)\n\n');
        fprintf(fid, '1C = %.1f A, I_max = %.0f A, V_cv = %.3f V, gioi han eta = %.0f mV. SOC = SOC pin that (DFN).\n\n', Qn, Imax, Vcv, delta_mV);
        fprintf(fid, '| Phuong phap | Vung | CCCV | k | t sac (s) | I dinh (C) | I TB (C) | SOC o dinh | SOC bat dau giam | SOC khi V cham V_cv (CCCV: CC->CV) | phan Q o SOC > 80 %% | t o I_max (s) | eta min (mV) | eta min khi I >= 0.8 I_dinh (mV) | t eta < 50 mV (s) | I TB khi eta < 50 mV (C) |\n');
        fprintf(fid, '|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|\n');
        for i = 1:height(Mt)
            r = Mt(i, :);
            fprintf(fid, '| %s | %s | %gC | %g | %.0f | %.2f | %.2f | %.3f | %.3f | %.3f | %.3f | %.0f | %.1f | %.1f | %.0f | %.2f |\n', r.method, r.window, r.Cbase, r.k, ...
                r.t_charge_s, r.C_peak, r.C_mean, r.soc_at_peak, r.soc_taper, r.soc_cc_cv, r.frac_Q_above80, r.t_at_Imax_s, r.eta_min_mV, r.eta_min_highI_mV, r.t_eta_below50_s, r.C_mean_eta_below50);
        end
        fprintf(fid, '\n## Dong TB (C) moi khoang SOC 10 %%\n\n');
        lo = unique(Bt.soc_lo).';
        fprintf(fid, '| Phuong phap | Vung | CCCV | k |%s\n|---|---|---|---|%s\n', sprintf(' %g-%g |', [100*lo; 100*lo + 10]), repmat('---|', 1, numel(lo)));
        Bg = Bt; Bg.k(isnan(Bg.k)) = -1;   % CCCV: k = NaN (findgroups bo NaN)
        [G, ~] = findgroups(Bg(:, {'method', 'iw', 'Cbase', 'k'}));
        for g = 1:max(G)
            r = Bt(G == g, :); v = repmat({''}, 1, numel(lo));
            for q = 1:height(r), v{abs(lo - r.soc_lo(q)) < 1e-9} = sprintf('%.2f', r.C_mean(q)); end
            fprintf(fid, '| %s | %s | %gC | %g |%s\n', r.method(1), r.window(1), r.Cbase(1), r.k(1), sprintf(' %s |', v{:}));
        end
        fclose(fid);
    end
end

function v = mean_or_nan(x, w)
if isempty(x) || sum(w) <= 0, v = NaN; else, v = sum(x.*w)/sum(w); end
end

function mp = index_dirs(dirs)
% key 'w3_c5_T25_cccv' / 'w3_c5_T25_k2_nmpc' -> duong dan file; thu muc dau uu tien
mp = containers.Map();
for d = 1:numel(dirs)
    f = dir(fullfile(dirs{d}, '**', 'pilot_w*_*_series.csv'));
    for i = 1:numel(f)
        tk = regexp(f(i).name, '^pilot_(w\d+_c\d+_T\d+(?:_k\d+)?)_(cccv|nmpc)_series\.csv$', 'tokens', 'once');
        if isempty(tk), continue; end
        key = [tk{1} '_' tk{2}];
        if ~mp.isKey(key), mp(key) = fullfile(f(i).folder, f(i).name); end
    end
end
end
