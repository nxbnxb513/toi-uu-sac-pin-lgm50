function pilot_report(indir, outdir)
%PILOT_REPORT  Gop ket qua cac job chay thu (pilot_w*_k*.csv) thanh bang md + hinh
% "thoi gian sac - lithium mat vinh vien" cho moi (vung, dong CCCV), kem diem CCCV.
if nargin < 2, outdir = indir; end
if ~exist(outdir, 'dir'), mkdir(outdir); end
f = dir(fullfile(indir, '**', 'pilot_w*_k*.csv'));
f = f(~contains({f.name}, '_series') & ~contains({f.name}, '_solves'));
if isempty(f), error('pilot_report: khong co file ket qua'); end
T = [];
for i = 1:numel(f)
    t = readtable(fullfile(f(i).folder, f(i).name), 'TextType', 'string', 'Delimiter', ',');
    if isempty(T), T = t; else, T = [T; t(:, T.Properties.VariableNames)]; end %#ok<AGROW>
end
T = sortrows(T, {'iw', 'Cbase', 'k'});
fid = fopen(fullfile(outdir, 'pilot_report.md'), 'w');
p('# Chay thu NMPC (biet het trang thai) so voi CCCV, 25 degC\n\n');
p('Chi so: lithium mat VINH VIEN = SEI + lithium chet, do sau lan sac VA pha xa 0.5C ve SOC dau vung (eval_discharge.m), cung cach cho CCCV va NMPC. Nguon lao hoa: %s (posthoc_provisional = TAM THOI, aging_rates.m hau kiem tren quy dao DFN; plant = lao hoa cua chinh DFN).\n\n', strjoin(unique(T.aging_source), ', '));
p('## CCCV (moi vung x dong)\n\n');
p('| Vung | CCCV | dung | T_CCCV (s) | SOC cuoi | mat vinh vien (mAh) | SEI / chet (mAh) | Li ma dinh (mAh) | V max (V) | eta_Li min (mV) | x_s max | T max (C) | vi pham V (mV) / eta (mV) / x_s / T (K) |\n');
p('|---|---|---|---|---|---|---|---|---|---|---|---|---|\n');
[~, iu] = unique(T(:, {'iw', 'Cbase'}), 'rows', 'stable');
for i = iu.'
    r = T(i, :);
    p('| %s | %gC | %s | %.0f | %.4f | %.5f | %.5f / %.2e | %.4f | %.4f | %.1f | %.4f | %.2f | %.2f / %.2f / %.4f / %.2f |\n', ...
        r.window, r.Cbase, r.cccv_reason, r.T_CCCV_s, r.cccv_soc_end, r.cccv_perm_mAh, r.cccv_perm_sei_mAh, r.cccv_perm_dead_mAh, ...
        r.cccv_pl_peak_mAh, r.cccv_Vmax, r.cccv_eta_min_mV, r.cccv_xs_max, r.cccv_Tmax_C, ...
        r.cccv_viol_V_mV, r.cccv_viol_eta_mV, r.cccv_viol_xs, r.cccv_viol_T_K);
end
p('\n## NMPC theo ngan sach k (t <= k T_CCCV)\n\n');
p('| Vung | CCCV | k | ngan sach (s) | NMPC dung | t sac (s) | SOC cuoi | mat vinh vien (mAh) | giam so voi CCCV (%%) | Li ma dinh (mAh) | vi pham V (mV) / eta (mV) / x_s / T (K) / ngan sach (s) | lan giai / that bai / status khac 0,2 | giai TB / trung vi / p95 / max (ms) | SQP TB / max | vong kin (s) / trong do DFN (s) |\n');
p('|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|\n');
for i = 1:height(T)
    r = T(i, :);
    p('| %s | %gC | %g | %.0f | %s | %.0f | %.4f | %.5f | %.1f | %.4f | %.2f / %.2f / %.4f / %.2f / %.0f | %d / %d / %d | %.0f / %.0f / %.0f / %.0f | %.1f / %d | %.0f / %.0f |\n', ...
        r.window, r.Cbase, r.k, r.budget_s, r.nmpc_reason, r.t_charge_s, r.soc_end, r.nmpc_perm_mAh, r.reduction_pct, r.nmpc_pl_peak_mAh, ...
        r.viol_V_mV, r.viol_eta_mV, r.viol_xs, r.viol_T_K, r.viol_budget_s, r.n_solves, r.n_fail, r.n_status_other, ...
        r.solve_mean_ms, r.solve_median_ms, r.solve_p95_ms, r.solve_max_ms, r.sqp_mean, r.sqp_max, r.closed_loop_wall_s, r.plant_wall_s);
end
p('\nTham so NMPC: I_max = %g A, T_s = %g s, N = %g (nmpc_config.m, gia_dinh.md GD-26..GD-30). Bien the so hoc: %s.\n', T.Imax_A(1), T.Ts_s(1), T.N(1), strjoin(unique(T.variant), ', '));
fclose(fid);
writetable(T, fullfile(outdir, 'pilot_all.csv'));
G = unique(T(:, {'iw', 'Cbase'}), 'rows', 'stable');
fig = figure('Visible', 'off', 'Position', [0 0 380*height(G) 380]);
for w = 1:height(G)
    s = T(T.iw == G.iw(w) & T.Cbase == G.Cbase(w), :);
    subplot(1, height(G), w); hold on; grid on;
    plot(s.t_charge_s/60, s.nmpc_perm_mAh, 'ro-');
    for i = 1:height(s)
        if isfinite(s.k(i)), lb = sprintf('%g', s.k(i)); else, lb = 'inf'; end
        text(s.t_charge_s(i)/60, s.nmpc_perm_mAh(i), [' ' lb], 'FontSize', 8);
    end
    plot(s.T_CCCV_s(1)/60, s.cccv_perm_mAh(1), 'ks', 'MarkerFaceColor', 'k');
    xlabel('thoi gian sac (phut)'); ylabel('Li mat vinh vien (mAh)');
    title(sprintf('Vung %s %%, CCCV %gC', s.window(1), s.Cbase(1)));
    legend('NMPC (nhan: k)', 'CCCV', 'Location', 'best');
end
saveas(fig, fullfile(outdir, 'pilot_time_loss.png'));
txt = fileread(fullfile(outdir, 'pilot_report.md'));
sf = getenv('GITHUB_STEP_SUMMARY');
if ~isempty(sf), fs = fopen(sf, 'a'); fprintf(fs, '%s', txt); fclose(fs); end
fprintf('%s', txt);

    function p(varargin)
        fprintf(fid, varargin{:});
    end
end
