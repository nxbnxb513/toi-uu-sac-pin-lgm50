function pilot_run(iw, ik, outdir, romcfg, variant)
%PILOT_RUN  Chay thu (dot 1): mot vung SOC x mot muc ngan sach, NMPC biet het
% trang thai, pin "that" = DFN day du, 25 degC, CCCV goc 0.5C.
%   iw: 1 = 0->50 %, 2 = 25->75 %, 3 = 50->100 %
%   ik: 1..7 ung voi k = 0.8, 1, 1.25, 1.5, 2, 3, khong gioi han (ngan sach k.T_CCCV)
% Bo giai acados duoc tao MOT lan trong job (nmpc_build.m), cac thong so chay
% (SOC dich, ngan sach, trong so, T moi truong) truyen qua tham so acados.
% Lao hoa: TAM THOI - toc do SEI + ma lithium (aging_rates.m) tinh hau kiem
% tren quy dao DFN; lao hoa chua co trong DFN (buoc C). Ghi CSV, md, hinh.
if nargin < 3, outdir = 'results'; end
if nargin < 4, romcfg = 'D'; end
if nargin < 5 || isempty(variant), variant = 'base'; end
if ~exist(outdir, 'dir'), mkdir(outdir); end
W = [0 0.5; 0.25 0.75; 0.5 1.0];
Ks = [0.8 1 1.25 1.5 2 3 Inf];
soc0 = W(iw, 1); soc1 = W(iw, 2); k = Ks(ik);
Ta = 298.15; Cbase = 0.5;
par = dfn_params();
rom = rom_setup(par, romcfg);
M = rom_model(rom, par);
cfgn = nmpc_config(par);           % gia dinh NMPC (GD-26..GD-30)
tag = sprintf('w%d_k%d', iw, ik);
fprintf('\n===== PILOT %s: vung %.0f -> %.0f %%, k = %g, ROM %s =====\n', tag, 100*soc0, 100*soc1, k, romcfg);

% ---- CCCV goc ----
cc = cccv_window(par, soc0, soc1, Cbase, Ta);
fprintf('CCCV 0.5C: %s, T_CCCV = %.0f s, SOC cuoi %.4f, SEI %.4f mAh, ma Li %.4f mAh, chay %.1f s\n', ...
    cc.reason, cc.T_CCCV, cc.soc_end, cc.nsei, cc.npl, cc.wall);

% ---- NMPC (tao bo giai mot lan) ----
bo = struct('N', cfgn.N, 'Imax', cfgn.Imax, 'codegen_dir', fullfile(pwd, 'c_generated_code'));
switch variant      % bien the so hoc de do tim cai dat on dinh (chi dung khi go loi)
    case 'base'
    case 's4n12', bo.num_steps = 4; bo.newton_iter = 12;
    case 'lm10',  bo.lm = 10;
    case 's4lm10', bo.num_steps = 4; bo.newton_iter = 12; bo.lm = 10;
    otherwise, error('pilot_run: bien the %s', variant);
end
fprintf('Bien the so hoc NMPC: %s\n', variant);
C = nmpc_build(rom, par, bo);
fprintf('acados: tao + bien dich bo giai %.1f s\n', C.t_build);
% kiem tra bo tich phan IRK tren khoang du bao dau tien (doan dau cua NMPC)
y0 = dfn_state_soc(par, soc0, Ta);
y0 = dfn_consistent_init(0, y0, par, struct('mode', 'I', 'value', 0, 'Tamb', Ta));
[xs0, zg] = rom_from_dfn(rom, par, y0); zs0 = rom_solve_z(M, xs0, 0, Ta, zg);
tfb = min(k, 1.5)*cc.T_CCCV/3600; Igs = min(cfgn.Imax, (soc1 - soc0)*rom.Csoc/tfb);
prm0 = [Ta; soc1; tfb; cfgn.w_loss; cfgn.w_dI; cfgn.Tmax; cfgn.delta; cfgn.xsmax];
[~, C.simchk] = nmpc_sim_check(rom, par, M, xs0, zs0, 0, Igs, tfb, prm0, C, ...
    struct('num_stages', C.opt.num_stages, 'num_steps', C.opt.num_steps, 'newton_iter', C.opt.newton_iter));
C.M = M;
cl.soc0 = soc0; cl.soc1 = soc1; cl.Tamb = Ta;
cl.budget = k*cc.T_CCCV; cl.Ts = cfgn.Ts;
cl.w_loss = cfgn.w_loss; cl.w_dI = cfgn.w_dI; cl.Tmax = cfgn.Tmax; cl.delta = cfgn.delta; cl.xsmax = cfgn.xsmax;
cl.tmax = cfgn.tmax_factor*cc.T_CCCV; cl.tf_guess = 1.5*cc.T_CCCV;
R = nmpc_closed_loop(C, M, par, cl);
K = R.solve;
fprintf('NMPC: %s, t = %.0f s (ngan sach %.0f s), SOC cuoi %.4f, SEI %.4f mAh, ma Li %.4f mAh, %d lan giai, that bai %d\n', ...
    R.reason, R.t_charge, cl.budget, R.soc_end, R.nsei, R.npl, numel(K.t), R.nfail);
fprintf('  thoi gian giai moi buoc (acados time_tot): trung binh %.1f ms, trung vi %.1f ms, max %.1f ms; SQP lap trung binh %.1f, max %d\n', ...
    1e3*mean(K.time_tot), 1e3*median(K.time_tot), 1e3*max(K.time_tot), mean(K.sqp_iter), max(K.sqp_iter));
fprintf('  vi pham tren DFN: V %.2f mV, T %.3f K, eta_Li %.2f mV, x_s %.4f, ngan sach %.0f s\n', ...
    1e3*R.viol.V, R.viol.T, 1e3*R.viol.eta, R.viol.xs, R.viol.budget);
st = K.status;
row = struct('window', sprintf('%g-%g', 100*soc0, 100*soc1), 'k', k, 'rom', romcfg, ...
    'T_CCCV_s', cc.T_CCCV, 'cccv_reason', cc.reason, 'cccv_soc_end', cc.soc_end, 'cccv_complete', cc.complete, ...
    'cccv_sei_mAh', cc.nsei, 'cccv_pl_mAh', cc.npl, 'cccv_dead_mAh', cc.ndl, 'cccv_Vmax', cc.Vmax, 'cccv_eta_min_mV', 1e3*cc.eta_min, ...
    'cccv_xs_max', cc.xs_max, 'cccv_Tmax_C', cc.Tmax - 273.15, ...
    'budget_s', cl.budget, 'nmpc_reason', R.reason, 't_charge_s', R.t_charge, 'soc_end', R.soc_end, ...
    'nmpc_sei_mAh', R.nsei, 'nmpc_pl_mAh', R.npl, 'nmpc_dead_mAh', R.ndl, 'loss_pred0_mAh', R.loss_pred0, ...
    'viol_V_mV', 1e3*R.viol.V, 'viol_T_K', R.viol.T, 'viol_eta_mV', 1e3*R.viol.eta, 'viol_xs', R.viol.xs, 'viol_budget_s', R.viol.budget, ...
    'n_solves', numel(K.t), 'n_fail', R.nfail, 'n_status0', sum(st == 0), 'n_status2', sum(st == 2), 'n_status_other', sum(~ismember(st, [0 2])), ...
    'solve_mean_ms', 1e3*mean(K.time_tot), 'solve_median_ms', 1e3*median(K.time_tot), 'solve_max_ms', 1e3*max(K.time_tot), ...
    'wall_solve_mean_ms', 1e3*mean(K.wall), 'sqp_mean', mean(K.sqp_iter), 'sqp_max', max(K.sqp_iter), ...
    'closed_loop_wall_s', R.wall, 'cccv_wall_s', cc.wall, 'build_s', C.t_build, 'Imax_A', cfgn.Imax, 'Ts_s', cfgn.Ts, 'N', cfgn.N);
writetable(struct2table(row), fullfile(outdir, ['pilot_' tag '.csv']));
S = R.ser;
writetable(table(S.t, S.I, S.V, S.T - 273.15, S.soc, S.xs_sep, 1e3*S.eta_sep, S.nsei, S.npl, ...
    'VariableNames', {'t_s', 'I_A', 'V', 'T_C', 'soc', 'xs_sep', 'eta_sep_mV', 'sei_mAh', 'pl_mAh'}), fullfile(outdir, ['pilot_' tag '_nmpc_series.csv']));
writetable(struct2table(K), fullfile(outdir, ['pilot_' tag '_solves.csv']));
Sc = cc.ser;
writetable(table(Sc.t, -Sc.I, Sc.V, Sc.T - 273.15, Sc.soc, Sc.xs_sep, 1e3*Sc.eta_sep, Sc.nsei, Sc.npl, ...
    'VariableNames', {'t_s', 'I_A', 'V', 'T_C', 'soc', 'xs_sep', 'eta_sep_mV', 'sei_mAh', 'pl_mAh'}), fullfile(outdir, ['pilot_' tag '_cccv_series.csv']));
fig = figure('Visible', 'off', 'Position', [0 0 1200 800]);
subplot(2, 3, 1); plot(Sc.t/60, -Sc.I, 'k', S.t/60, S.I, 'r'); ylabel('I sac (A)'); grid on; legend('CCCV 0.5C', 'NMPC', 'Location', 'best');
subplot(2, 3, 2); plot(Sc.t/60, Sc.V, 'k', S.t/60, S.V, 'r'); ylabel('V (V)'); grid on;
subplot(2, 3, 3); plot(Sc.t/60, 1e3*Sc.eta_sep, 'k', S.t/60, 1e3*S.eta_sep, 'r'); yline(1e3*cfgn.delta, ':'); ylabel('\eta_{Li} phia mang ngan (mV)'); grid on;
subplot(2, 3, 4); plot(Sc.t/60, Sc.soc, 'k', S.t/60, S.soc, 'r'); ylabel('SOC'); xlabel('t (phut)'); grid on;
subplot(2, 3, 5); plot(Sc.t/60, Sc.xs_sep, 'k', S.t/60, S.xs_sep, 'r'); yline(cfgn.xsmax, ':'); ylabel('x_s phia mang ngan'); xlabel('t (phut)'); grid on;
subplot(2, 3, 6); plot(Sc.t/60, Sc.nsei + Sc.npl, 'k', S.t/60, S.nsei + S.npl, 'r'); ylabel('Li mat tam thoi (mAh)'); xlabel('t (phut)'); grid on;
sgtitle(sprintf('Vung %g-%g %%, k = %g (ngan sach %.0f s), 25 degC', 100*soc0, 100*soc1, k, cl.budget));
saveas(fig, fullfile(outdir, ['pilot_' tag '.png']));
fprintf('PILOT %s: XONG\n', tag);
end
