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
p('Trang thai: ok = nap du (toi SOC dich = SOC ma CCCV dat, GD-82) trong ngan sach, khong vi pham; ok_violation = nap du nhung vi pham rang buoc tren DFN; ');
p('infeasible = KHONG THE SAC AN TOAN TRONG THOI GIAN NAY (thoi gian sac an toan nhanh nhat tren ROM > ngan sach, khong chay vong kin); failed = bo giai that bai / dung giua chung. ');
p('Cot "giam" chi co nghia voi ok / ok_violation; cac trang thai khac de trong (ban cu in nham 100 %%).\n\n');
p('| Vung | CCCV | k | ngan sach (s) | sac an toan nhanh nhat (s) | trang thai | ly do dung | t sac (s) | SOC cuoi / dich | mat vinh vien (mAh) | giam so voi CCCV (%%) | Li ma dinh (mAh) | vi pham V (mV) / eta (mV) / x_s / T (K) / ngan sach (s) | lan giai / that bai (lien tiep max) / du phong (s) | giai TB / trung vi / p95 / max (ms) | SQP TB / max | vong kin (s) / trong do DFN (s) |\n');
p('|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|\n');
for i = 1:height(T)
    r = T(i, :);
    st = char(r.status);
    if any(strcmp(st, {'ok', 'ok_violation'})), red = sprintf('%.1f', r.reduction_pct); else, red = '-'; end
    if strcmp(st, 'infeasible')
        p('| %s | %gC | %g | %.0f | %.0f | **khong the sac an toan trong thoi gian nay** | - | - | - | - | - | - | - | - | - | - | - |\n', ...
            r.window, r.Cbase, r.k, r.budget_s, r.T_min_safe_s);
        continue
    end
    p('| %s | %gC | %g | %.0f | %.0f | %s | %s | %.0f | %.4f / %.4f | %.5f | %s | %.4f | %.2f / %.2f / %.4f / %.2f / %.0f | %d / %d (%d) / %.0f | %.0f / %.0f / %.0f / %.0f | %.1f / %d | %.0f / %.0f |\n', ...
        r.window, r.Cbase, r.k, r.budget_s, r.T_min_safe_s, st, r.nmpc_reason, r.t_charge_s, r.soc_end, r.soc_target, r.nmpc_perm_mAh, red, r.nmpc_pl_peak_mAh, ...
        r.viol_V_mV, r.viol_eta_mV, r.viol_xs, r.viol_T_K, r.viol_budget_s, r.n_solves, r.n_fail, r.max_consec_fail, r.t_fallback_s, ...
        r.solve_mean_ms, r.solve_median_ms, r.solve_p95_ms, r.solve_max_ms, r.sqp_mean, r.sqp_max, r.closed_loop_wall_s, r.plant_wall_s);
end
p('\n## Du doan (ROM) so voi cham diem (DFN), pha sac, mAh\n\n');
p('ROM chay lai = ROM (cung mo hinh trong acados) chay lai DUNG profile dong da ap len DFN tu cung trang thai dau (GD-85). "Phan xa" = mat vinh vien - mat trong pha sac (SEI khi xa + Li chet hinh thanh khi xa); neu bang nhau giua CCCV va NMPC thi ham muc tieu chi tinh pha sac la dai dien dung cho chi so cham diem.\n\n');
p('| Vung | CCCV | k | trang thai | CCCV: ROM chay lai / DFN (lech %%) | NMPC: du doan lan giai dau / doan dau CCCV (ROM) | NMPC: ROM chay lai / DFN (lech %%) | phan xa CCCV / NMPC |\n|---|---|---|---|---|---|---|---|\n');
for i = 1:height(T)
    r = T(i, :);
    if strcmp(char(r.status), 'infeasible'), continue; end
    p('| %s | %gC | %g | %s | %.6f / %.6f (%+.2f) | %.6f / %.6f | %.6f / %.6f (%+.2f) | %.6f / %.6f |\n', r.window, r.Cbase, r.k, char(r.status), ...
        r.rom_replay_cccv_mAh, r.cccv_charge_loss_mAh, 100*(r.rom_replay_cccv_mAh/r.cccv_charge_loss_mAh - 1), ...
        r.loss_pred0_mAh, r.guess_loss_mAh, r.rom_replay_nmpc_mAh, r.nmpc_charge_loss_mAh, 100*(r.rom_replay_nmpc_mAh/r.nmpc_charge_loss_mAh - 1), ...
        r.cccv_dis_part_mAh, r.nmpc_dis_part_mAh);
end
p('\n## Thoi gian chay (moi job = mot vung x dong x k)\n\n');
p('| Vung | CCCV | k | job (s) | tao bo giai (s) | vong kin (s) | DFN (s) | lan giai | lin / sim / qp / glob TB (ms) | status 2 khi khoi dong nong |\n|---|---|---|---|---|---|---|---|---|---|\n');
for i = 1:height(T)
    r = T(i, :);
    p('| %s | %gC | %g | %.0f | %.0f | %.0f | %.0f | %d | %.0f / %.0f / %.0f / %.0f | %d |\n', r.window, r.Cbase, r.k, r.job_wall_s, r.build_s, ...
        r.closed_loop_wall_s, r.plant_wall_s, r.n_solves, r.lin_mean_ms, r.sim_mean_ms, r.qp_mean_ms, r.glob_mean_ms, r.n_status2_warm);
end
ok = isfinite(T.job_wall_s);
jw = T.job_wall_s(ok);
p('\n## Ngoai suy thoi gian cho luoi day du\n\n');
p('Moi job = mot vung x mot dong CCCV x mot k (gom CCCV + tao bo giai + vong kin). Thoi gian job: trung binh %.0f s, trung vi %.0f s, max %.0f s (%d job).\n', mean(jw), median(jw), max(jw), numel(jw));
nfull = 15*3*3*7;
p('Luoi day du NMPC biet het trang thai: 15 vung x 3 dong CCCV x 3 nhiet do x 7 k = %d job; tren 20 job song song: ~%.1f h (theo trung binh), ~%.1f h (theo max, can tren); tong %.0f job-gio.\n', ...
    nfull, nfull*mean(jw)/20/3600, nfull*max(jw)/20/3600, nfull*mean(jw)/3600);
p('Luu y: vung 40-100 va dong 1C ton nhieu hon; nhiet do 10/40 degC chua do. Gioi han 256 job moi lan chay => it nhat %d lan chay.\n', ceil(nfull/256));
p('\nTham so NMPC: I_max = %g A, T_s = %g s, N = %g (nmpc_config.m, gia_dinh.md GD-26..GD-30). Bien the so hoc: %s.\n', T.Imax_A(1), T.Ts_s(1), T.N(1), strjoin(unique(T.variant), ', '));
fclose(fid);
writetable(T, fullfile(outdir, 'pilot_all.csv'));
G = unique(T(:, {'iw', 'Cbase'}), 'rows', 'stable');
fig = figure('Visible', 'off', 'Position', [0 0 380*height(G) 380]);
for w = 1:height(G)
    s0 = T(T.iw == G.iw(w) & T.Cbase == G.Cbase(w), :);
    s = s0(ismember(string(s0.status), ["ok", "ok_violation"]), :);   % chi lan chay nap du
    subplot(1, height(G), w); hold on; grid on;
    plot(s.t_charge_s/60, s.nmpc_perm_mAh, 'ro-');
    for i = 1:height(s)
        if isfinite(s.k(i)), lb = sprintf('%g', s.k(i)); else, lb = 'inf'; end
        text(s.t_charge_s(i)/60, s.nmpc_perm_mAh(i), [' ' lb], 'FontSize', 8);
    end
    plot(s0.T_CCCV_s(1)/60, s0.cccv_perm_mAh(1), 'ks', 'MarkerFaceColor', 'k');
    xlabel('thoi gian sac (phut)'); ylabel('Li mat vinh vien (mAh)');
    title(sprintf('Vung %s %%, CCCV %gC', s0.window(1), s0.Cbase(1)));
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
