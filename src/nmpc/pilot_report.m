function pilot_report(indir, outdir)
%PILOT_REPORT  Gop ket qua cac job chay thu (pilot_*.csv) thanh bang md + hinh
% "thoi gian sac - lithium mat (tam thoi)" cho moi vung, kem diem CCCV.
if nargin < 2, outdir = indir; end
if ~exist(outdir, 'dir'), mkdir(outdir); end
f = dir(fullfile(indir, '**', 'pilot_w*_k*.csv'));
f = f(~contains({f.name}, '_series') & ~contains({f.name}, '_solves'));
if isempty(f), error('pilot_report: khong co file ket qua'); end
T = [];
for i = 1:numel(f)
    t = readtable(fullfile(f(i).folder, f(i).name), 'TextType', 'string');
    T = [T; t]; %#ok<AGROW>
end
T = sortrows(T, {'window', 'k'});
fid = fopen(fullfile(outdir, 'pilot_report.md'), 'w');
p('# Chay thu NMPC (biet het trang thai) so voi CCCV 0.5C, 25 degC\n\n');
p('Chi so: lithium mat VINH VIEN = SEI + lithium chet, tinh sau lan sac VA pha xa 0.5C ve SOC dau vung (eval_discharge.m), cung cach cho CCCV va NMPC. TAM THOI: toc do aging_rates.m tinh hau kiem tren quy dao DFN; lao hoa chua nam trong DFN (buoc C). Lithium ma thuan nghich chi la chan doan.\n\n');
p('| Vung | k | T_CCCV (s) | CCCV: dung / SOC | CCCV mat vinh vien (mAh) | CCCV dinh Li ma (mAh) | ngan sach (s) | NMPC: dung / t sac (s) / SOC | NMPC mat vinh vien (mAh) | NMPC / CCCV | NMPC dinh Li ma (mAh) | vi pham V (mV) / eta (mV) / x_s / ngan sach (s) | giai TB / trung vi / max (ms), SQP TB | lan giai / that bai | vong kin (s) |\n');
p('|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|\n');
for i = 1:height(T)
    r = T(i, :);
    p('| %s | %g | %.0f | %s / %.3f | %.5f | %.4f | %.0f | %s / %.0f / %.3f | %.5f | %.3f | %.4f | %.2f / %.2f / %.4f / %.0f | %.0f / %.0f / %.0f, %.1f | %d / %d | %.0f |\n', ...
        r.window, r.k, r.T_CCCV_s, r.cccv_reason, r.cccv_soc_end, r.cccv_perm_mAh, r.cccv_pl_peak_mAh, ...
        r.budget_s, r.nmpc_reason, r.t_charge_s, r.soc_end, r.nmpc_perm_mAh, r.nmpc_perm_mAh/r.cccv_perm_mAh, r.nmpc_pl_peak_mAh, ...
        r.viol_V_mV, r.viol_eta_mV, r.viol_xs, r.viol_budget_s, r.solve_mean_ms, r.solve_median_ms, r.solve_max_ms, r.sqp_mean, r.n_solves, r.n_fail, r.closed_loop_wall_s);
end
p('\nCot "status khac 0,2": so lan acados tra trang thai khac 0 (hoi tu) va 2 (het so lan lap).\n');
p('Tham so NMPC: I_max = %g A, T_s = %g s, N = %g (nmpc_config.m, gia_dinh.md GD-26..GD-30).\n', T.Imax_A(1), T.Ts_s(1), T.N(1));
fclose(fid);
writetable(T, fullfile(outdir, 'pilot_all.csv'));
wins = unique(T.window, 'stable');
fig = figure('Visible', 'off', 'Position', [0 0 400*numel(wins) 380]);
for w = 1:numel(wins)
    s = T(T.window == wins(w), :);
    subplot(1, numel(wins), w); hold on; grid on;
    plot(s.t_charge_s/60, s.nmpc_perm_mAh, 'ro-');
    for i = 1:height(s)
        if isfinite(s.k(i)), lb = sprintf('%g', s.k(i)); else, lb = 'inf'; end
        text(s.t_charge_s(i)/60, s.nmpc_perm_mAh(i), [' ' lb], 'FontSize', 8);
    end
    plot(s.T_CCCV_s(1)/60, s.cccv_perm_mAh(1), 'ks', 'MarkerFaceColor', 'k');
    xlabel('thoi gian sac (phut)'); ylabel('Li mat vinh vien, tam thoi (mAh)'); title(sprintf('Vung %s %%', wins(w)));
    legend('NMPC (nhan: k)', 'CCCV 0.5C', 'Location', 'best');
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
