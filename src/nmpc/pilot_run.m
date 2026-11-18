function pilot_run(iw, Cbase, iks, outdir, romcfg, variant, Tamb_C, job_min)
%PILOT_RUN  Chay thu (dot 1, buoc G): MOT vung SOC x MOT muc dong CCCV, du cac
% muc ngan sach, NMPC biet het trang thai, pin "that" = DFN day du.
%   iw:    chi so trong luoi soc_windows.m (15 vung buoc 20 %); dot chay thu dung
%          3 vung: 3 = 0->60 %, 8 = 20->80 %, 12 = 40->100 %
%   Cbase: dong CCCV goc (C-rate, 1C = par.Qnom), vd 0.5 hoac 1
%   iks:   chi so ngan sach 1..7 ung voi k = 0.8, 1, 1.25, 1.5, 2, 3, khong gioi han
%          (thoi gian sac t <= k.T_CCCV, gioi han TREN, khong bat buoc dung het)
%   Tamb_C: nhiet do moi truong [degC] (mac dinh 25); job_min: thoi gian toi da
%          cua ca job [phut] de chia ngan sach thoi gian chay cho tung lan vong kin.
% Bo giai acados duoc tao MOT lan trong job (nmpc_build.m); CCCV chay mot lan;
% sau do lan luot tung k. Moi k ghi CSV ngay khi xong (job bi ngat van con ket qua).
% Lao hoa: neu DFN chua co lao hoa (buoc C) thi TAM THOI tinh hau kiem bang
% aging_rates.m tren quy dao DFN; tu dong dung lao hoa cua DFN khi da co
% (aging_from_plant.m). Cot aging_source ghi ro cach nao.
if nargin < 3 || isempty(iks), iks = 1:7; end
if nargin < 4 || isempty(outdir), outdir = 'results'; end
if nargin < 5 || isempty(romcfg), romcfg = 'D'; end
if nargin < 6 || isempty(variant), variant = 'base'; end
if nargin < 7 || isempty(Tamb_C), Tamb_C = 25; end
if nargin < 8 || isempty(job_min), job_min = 320; end
tjob = tic;
if ~exist(outdir, 'dir'), mkdir(outdir); end
W = soc_windows();
Ks = [0.8 1 1.25 1.5 2 3 Inf];
soc0 = W(iw, 1); soc1 = W(iw, 2);
Ta = 273.15 + Tamb_C;
par = dfn_params();                % tham so ROM/NMPC (DFN khong lao hoa)
parp = plant_params(par);          % "pin that": co lao hoa DFN chi khi da duoc kiem chung
rom = rom_setup(par, romcfg);
M = rom_model(rom, par);
cfgn = nmpc_config(par);           % gia dinh NMPC (GD-26..GD-30)
jtag = sprintf('w%d_c%g_T%g', iw, 10*Cbase, Tamb_C);
fprintf('\n===== PILOT %s: vung %.0f -> %.0f %%, CCCV %gC, %g degC, ROM %s, bien the %s =====\n', ...
    jtag, 100*soc0, 100*soc1, Cbase, Tamb_C, romcfg, variant);

% ---- CCCV goc ----
cc = cccv_window(parp, soc0, soc1, Cbase, Ta, struct('Cdis', 0.5));
cv = cccv_viol(par, cfgn, cc.ser);
fprintf(['CCCV %gC: %s, T_CCCV = %.0f s, SOC cuoi %.4f; sau sac + xa: mat vinh vien %.5f mAh (SEI %.5f, chet %.2e) [%s]; ' ...
    'Li ma dinh %.4f mAh, con lai sau xa %.2e; vi pham V %.2f mV, T %.3f K, eta %.2f mV (min %.1f mV), x_s %.4f; chay %.1f s\n'], ...
    Cbase, cc.reason, cc.T_CCCV, cc.soc_end, cc.perm, cc.dis.nsei, cc.dis.ndl, cc.dis.source, cc.pl_peak, cc.dis.pl_rev_left, ...
    1e3*cv.V, cv.T, 1e3*cv.eta, 1e3*cc.eta_min, cv.xs, cc.wall);
Sc = cc.ser;
% SOC dich cua NMPC = SOC ma CCCV thuc su dat (GD-82): CCCV dung o I <= C/50 (GD-25) truoc
% 100 % o vung ket thuc 100 %; NMPC phai nap dung luong do de so sanh cung mot viec.
soc_t = min(soc1, cc.soc_end);
fprintf('SOC dich cua NMPC: %.4f (vung %.2f, CCCV dat %.4f)\n', soc_t, soc1, cc.soc_end);
% ROM chay lai profile dong CCCV (chan doan sai lech lao hoa ROM - DFN, GD-85)
rp_cc = rom_replay(M, rom, par, soc0, Ta, Sc.t, -Sc.I);
fprintf('ROM chay lai CCCV: mat (SEI + chet) ROM %.6f mAh, DFN %.6f mAh (lech %+.2f %%)\n', rp_cc.loss, cc.nsei + cc.ndl, 100*(rp_cc.loss/(cc.nsei + cc.ndl) - 1));
writetable(table(Sc.t, -Sc.I, Sc.V, Sc.T - 273.15, Sc.soc, Sc.xs_sep, 1e3*Sc.eta_sep, Sc.nsei, Sc.npl, ...
    'VariableNames', {'t_s', 'I_A', 'V', 'T_C', 'soc', 'xs_sep', 'eta_sep_mV', 'sei_mAh', 'pl_mAh'}), fullfile(outdir, ['pilot_' jtag '_cccv_series.csv']));

% ---- NMPC (tao bo giai mot lan) ----
bo = struct('N', cfgn.N, 'Imax', cfgn.Imax, 'codegen_dir', fullfile(pwd, 'c_generated_code'), 'E', M.E);
bo = nmpc_variant(bo, variant);
if isfield(bo, 'w_loss_scale'), cfgn.w_loss_scale = bo.w_loss_scale; end
% doan dau cua tung ngan sach (cung x0 voi vong kin, estimator mac dinh = rom_from_dfn)
% -> so buoc IRK moi khoang theo dien tich nap moi buoc (GD-87), tru khi bien the dat san
y0 = dfn_state_soc(parp, soc0, Ta);
y0 = dfn_consistent_init(0, y0, parp, struct('mode', 'I', 'value', 0, 'Tamb', Ta));
x0 = rom_from_dfn(rom, parp, y0, aging_track('init', parp));
limg = struct('Vcv', v_limit(parp), 'Tmax', cfgn.Tmax, 'delta', cfgn.delta, 'xsmax', cfgn.xsmax, 'Icut', parp.Qnom/50, 'soc_tol', 0.005);
Gs = cell(1, numel(Ks));
for ik = iks(:).'
    fprintf('doan dau, k = %g:\n', Ks(ik));
    Gs{ik} = nmpc_guess(M, rom, x0, cl_cfg(Ks(ik)), limg, cfgn.Imax);
end
if ~isfield(bo, 'num_steps')
    hI = 36; if isfield(bo, 'steps_hI'), hI = bo.steps_hI; end
    Pl = cellfun(@(g) g.P, Gs(iks), 'UniformOutput', false);
    bo.num_steps = nmpc_steps(Pl, cfgn.N, hI);
end
fprintf('So buoc IRK moi khoang (GD-87): %s (tong %d)\n', mat2str(bo.num_steps), sum(bo.num_steps .* ones(1, cfgn.N)));
C = nmpc_build(rom, par, bo);
fprintf('acados: tao + bien dich bo giai %.1f s\n', C.t_build);
C.M = M; C.par = par; C.sweep = false;

for ik = iks(:).'
    k = Ks(ik);
    tag = sprintf('%s_k%d', jtag, ik);
    left_s = 60*job_min - toc(tjob);
    nleft = sum(iks >= ik);
    fprintf('\n----- %s: k = %g, ngan sach %.0f s (con %.0f s thoi gian job cho %d lan) -----\n', tag, k, k*cc.T_CCCV, left_s, nleft);
    cl = cl_cfg(k);
    cl.wall_max = max(left_s/nleft, 60);
    cl.guess = Gs{ik};
    % cong tac cua bien the (chia doi tim loi, GD-86) chuyen sang vong kin
    ff = {'free_I0', 'guess_mode', 'shift', 'vb_on', 'w_abs', 'soc_rom', 'qp_dump', 'max_solves', 'irk_probe'};
    for i = 1:numel(ff), if isfield(bo, ff{i}), cl.(ff{i}) = bo.(ff{i}); end, end
    try
        R = nmpc_closed_loop(C, M, parp, cl);
    catch e
        fprintf('NMPC LOI: %s\n%s\n', e.message, getReport(e, 'extended', 'hyperlinks', 'off'));
        R = [];
    end
    rp = [];
    if ~isempty(R) && isfield(R, 'ser') && ~isempty(R.ser.t)
        try, rp = rom_replay(M, rom, par, soc0, Ta, R.ser.t, R.ser.I); catch e, fprintf('rom_replay loi: %s\n', e.message); end
    end
    row = pilot_row(iw, soc0, soc1, Cbase, Tamb_C, k, romcfg, variant, cc, cv, cl, R, C, cfgn, rp_cc, rp);
    row.job_wall_s = toc(tjob);    % tu dau pilot_run (gom CCCV + tao bo giai) toi khi xong lan vong kin nay
    writetable(struct2table(row), fullfile(outdir, ['pilot_' tag '.csv']));
    if isempty(R) || strcmp(R.reason, 'infeasible_budget'), continue; end
    K = R.solve;
    fprintf(['NMPC: %s, t = %.0f s (ngan sach %.0f s), SOC cuoi %.4f; mat vinh vien %.5f mAh (CCCV %.5f, giam %.1f %%) [%s]; ' ...
        'Li ma dinh %.4f mAh; %d lan giai, that bai %d; vong kin %.0f s; trang thai %s\n'], ...
        R.reason, R.t_charge, cl.budget, R.soc_end, R.perm, cc.perm, row.reduction_pct, R.dis.source, R.pl_peak, numel(K.t), R.nfail, R.wall, row.status);
    if ~isempty(rp)
        fprintf('  du doan vs DFN (pha sac, mAh): NMPC lan giai dau %.6f | ROM chay lai profile NMPC %.6f | DFN %.6f; CCCV: ROM %.6f, DFN %.6f\n', ...
            R.loss_pred0, rp.loss, R.nsei + R.ndl, rp_cc.loss, cc.nsei + cc.ndl);
    end
    fprintf('  giai (acados time_tot): TB %.1f ms, trung vi %.1f ms, max %.1f ms; SQP lap TB %.1f, max %d\n', ...
        1e3*mean(K.time_tot), 1e3*median(K.time_tot), 1e3*max(K.time_tot), mean(K.sqp_iter), max(K.sqp_iter));
    fprintf('  vi pham tren DFN: V %.2f mV, T %.3f K, eta_Li %.2f mV, x_s %.4f, ngan sach %.0f s\n', ...
        1e3*R.viol.V, R.viol.T, 1e3*R.viol.eta, R.viol.xs, R.viol.budget);
    S = R.ser;
    writetable(table(S.t, S.I, S.V, S.T - 273.15, S.soc, S.xs_sep, 1e3*S.eta_sep, S.nsei, S.npl, ...
        'VariableNames', {'t_s', 'I_A', 'V', 'T_C', 'soc', 'xs_sep', 'eta_sep_mV', 'sei_mAh', 'pl_mAh'}), fullfile(outdir, ['pilot_' tag '_nmpc_series.csv']));
    writetable(struct2table(K), fullfile(outdir, ['pilot_' tag '_solves.csv']));
    try
        fig = figure('Visible', 'off', 'Position', [0 0 1200 800]);
        subplot(2, 3, 1); plot(Sc.t/60, -Sc.I, 'k', S.t/60, S.I, 'r'); ylabel('I sac (A)'); grid on; legend(sprintf('CCCV %gC', Cbase), 'NMPC', 'Location', 'best');
        subplot(2, 3, 2); plot(Sc.t/60, Sc.V, 'k', S.t/60, S.V, 'r'); yline(v_limit(par), ':'); ylabel('V (V)'); grid on;
        subplot(2, 3, 3); plot(Sc.t/60, 1e3*Sc.eta_sep, 'k', S.t/60, 1e3*S.eta_sep, 'r'); yline(1e3*cfgn.delta, ':'); yline(0, 'k:'); ylabel('\eta_{Li} phia mang ngan (mV)'); grid on;
        subplot(2, 3, 4); plot(Sc.t/60, Sc.soc, 'k', S.t/60, S.soc, 'r'); ylabel('SOC'); xlabel('t (phut)'); grid on;
        subplot(2, 3, 5); plot(Sc.t/60, Sc.xs_sep, 'k', S.t/60, S.xs_sep, 'r'); yline(cfgn.xsmax, ':'); ylabel('x_s phia mang ngan'); xlabel('t (phut)'); grid on;
        subplot(2, 3, 6); plot(Sc.t/60, Sc.nsei, 'k', S.t/60, S.nsei, 'r', Sc.t/60, Sc.npl, 'k:', S.t/60, S.npl, 'r:'); ylabel('SEI (-), Li ma (:) (mAh)'); xlabel('t (phut)'); grid on;
        sgtitle(sprintf('Vung %g-%g %%, CCCV %gC, k = %g (ngan sach %.0f s), %g degC', 100*soc0, 100*soc1, Cbase, k, cl.budget, Tamb_C));
        saveas(fig, fullfile(outdir, ['pilot_' tag '.png'])); close(fig);
    catch e
        fprintf('hinh loi: %s\n', e.message);
    end
end
fprintf('PILOT %s: XONG sau %.0f s\n', jtag, toc(tjob));

    function cl = cl_cfg(k)
        cl = struct('soc0', soc0, 'soc1', soc1, 'soc_target', soc_t, 'Tamb', Ta, 'budget', k*cc.T_CCCV, 'Ts', cfgn.Ts, ...
            'w_loss_scale', cfgn.w_loss_scale, 'w_dI', cfgn.w_dI, 'Tmax', cfgn.Tmax, 'delta', cfgn.delta, 'xsmax', cfgn.xsmax, ...
            'tmax', cfgn.tmax_factor*cc.T_CCCV, 'Cdis', 0.5, 'Icc_cccv', Cbase*par.Qnom, 'T_cccv', cc.T_CCCV, 'dt_prof', 30);
    end
end

function parp = plant_params(par)
% DFN co lao hoa (buoc C, src/dfn) chi dung lam "pin that" khi luong lao hoa da danh
% dau kiem chung xong: par.aging.validated = true trong src/dfn/dfn_params.m (do luong
% lao hoa dat), hoac bien moi truong NMPC_PLANT_AGING = 1 (chi de thu). Nguoc lai: DFN
% khong lao hoa + cham diem hau kiem TAM THOI (aging_track.m). Cot aging_source ghi ro.
ok = isfield(par, 'aging') && isfield(par.aging, 'validated') && isequal(par.aging.validated, true);
if strcmp(getenv('NMPC_PLANT_AGING'), '1'), ok = true; end
if ~ok
    parp = par;
    fprintf('Pin that: DFN KHONG lao hoa; lao hoa cham diem hau kiem TAM THOI (aging_rates.m)\n');
    return
end
o2 = struct(); if isfield(par, 'opt'), o2 = par.opt; end
o2.aging = true;
parp = dfn_params(o2);
fprintf('Pin that: DFN CO lao hoa (buoc C); mat vinh vien = SEI + Li chet + Li theo LAM cua DFN\n');
end

function v = cccv_viol(par, cfgn, S)
% vi pham rang buoc an toan cua CCCV tren DFN (cung cach do voi NMPC)
v.V = max(max(S.V) - v_limit(par), 0);
v.T = max(max(S.T) - cfgn.Tmax, 0);
v.eta = max(cfgn.delta - min(S.eta_sep), 0);
v.xs = max(max(S.xs_sep) - cfgn.xsmax, 0);
end

function row = pilot_row(iw, soc0, soc1, Cbase, Tamb_C, k, romcfg, variant, cc, cv, cl, R, C, cfgn, rp_cc, rp)
row = struct('iw', iw, 'window', sprintf('%g-%g', 100*soc0, 100*soc1), 'Cbase', Cbase, 'Tamb_C', Tamb_C, 'k', k, ...
    'rom', romcfg, 'variant', variant, 'aging_source', cc.dis.source, ...
    'T_CCCV_s', cc.T_CCCV, 'cccv_reason', cc.reason, 'cccv_soc_end', cc.soc_end, 'cccv_complete', cc.complete, ...
    'cccv_perm_mAh', cc.perm, 'cccv_perm_sei_mAh', cc.dis.nsei, 'cccv_perm_dead_mAh', cc.dis.ndl, 'cccv_perm_lam_mAh', cc.dis.nlam, ...
    'cccv_pl_left_mAh', cc.dis.pl_rev_left, ...
    'cccv_pl_peak_mAh', cc.pl_peak, 'cccv_sei_charge_mAh', cc.nsei, 'cccv_pl_charge_end_mAh', cc.npl, ...
    'cccv_Vmax', cc.Vmax, 'cccv_eta_min_mV', 1e3*cc.eta_min, 'cccv_xs_max', cc.xs_max, 'cccv_Tmax_C', cc.Tmax - 273.15, ...
    'cccv_viol_V_mV', 1e3*cv.V, 'cccv_viol_T_K', cv.T, 'cccv_viol_eta_mV', 1e3*cv.eta, 'cccv_viol_xs', cv.xs, ...
    'cccv_wall_s', cc.wall, 'budget_s', cl.budget, 'build_s', C.t_build, ...
    'Imax_A', cfgn.Imax, 'Ts_s', cfgn.Ts, 'N', cfgn.N, 'soc_target', cl.soc_target, ...
    'cccv_charge_loss_mAh', cc.nsei + cc.ndl, 'cccv_dis_part_mAh', cc.perm - cc.nsei - cc.ndl, 'rom_replay_cccv_mAh', rp_cc.loss);
nanf = {'t_charge_s', 'soc_end', 'nmpc_perm_mAh', 'nmpc_perm_sei_mAh', 'nmpc_perm_dead_mAh', 'nmpc_perm_lam_mAh', 'nmpc_pl_left_mAh', ...
    'nmpc_pl_peak_mAh', 'nmpc_sei_charge_mAh', 'nmpc_pl_charge_end_mAh', 'reduction_pct', 'loss_pred0_mAh', ...
    'nmpc_Vmax', 'nmpc_eta_min_mV', 'nmpc_xs_max', 'nmpc_Tmax_C', ...
    'viol_V_mV', 'viol_T_K', 'viol_eta_mV', 'viol_xs', 'viol_budget_s', 'n_solves', 'n_fail', 'n_status0', 'n_status2', ...
    'n_status_other', 'solve_mean_ms', 'solve_median_ms', 'solve_p95_ms', 'solve_max_ms', 'wall_solve_mean_ms', ...
    'sqp_mean', 'sqp_max', 'closed_loop_wall_s', 'plant_wall_s', 'lin_mean_ms', 'sim_mean_ms', 'qp_mean_ms', 'glob_mean_ms', ...
    'n_status2_warm', 'max_iter_warm', 'T_min_safe_s', 'guess_T_s', 'guess_Icc_A', 'guess_loss_mAh', 'w_loss', ...
    'nmpc_charge_loss_mAh', 'nmpc_dis_part_mAh', 'rom_replay_nmpc_mAh', 'max_consec_fail', 't_fallback_s', 'guess_mean_s', 'T_min_safe_plant_s', 'eb_min_mV'};
for i = 1:numel(nanf), row.(nanf{i}) = NaN; end
row.nmpc_reason = 'error'; row.dis_reason = ''; row.status = 'error';
if isempty(R), return; end
row.nmpc_reason = R.reason; row.T_min_safe_s = R.T_min_safe;
if isfield(R, 'T_min_safe_plant'), row.T_min_safe_plant_s = R.T_min_safe_plant; end
if strcmp(R.reason, 'infeasible_budget')
    % "khong the sac an toan trong thoi gian nay" - KHONG phai mot muc giam lao hoa
    row.status = 'infeasible'; return
end
row.guess_T_s = R.guess_T; row.guess_Icc_A = R.guess_Icc; row.guess_loss_mAh = R.guess_loss; row.w_loss = R.w_loss;
row.max_consec_fail = R.max_consec_fail; row.t_fallback_s = R.t_fallback;
K = R.solve; st = K.status; S = R.ser;
row.dis_reason = R.dis.reason;
row.t_charge_s = R.t_charge; row.soc_end = R.soc_end;
row.nmpc_perm_mAh = R.perm; row.nmpc_perm_sei_mAh = R.dis.nsei; row.nmpc_perm_dead_mAh = R.dis.ndl; row.nmpc_perm_lam_mAh = R.dis.nlam;
row.nmpc_pl_left_mAh = R.dis.pl_rev_left; row.nmpc_pl_peak_mAh = R.pl_peak;
row.nmpc_sei_charge_mAh = R.nsei; row.nmpc_pl_charge_end_mAh = R.npl;
row.loss_pred0_mAh = R.loss_pred0;
row.nmpc_charge_loss_mAh = R.nsei + R.ndl; row.nmpc_dis_part_mAh = R.perm - R.nsei - R.ndl;
if ~isempty(rp), row.rom_replay_nmpc_mAh = rp.loss; end
row.guess_mean_s = mean(K.guess_s);
if isfield(K, 'eb_mV') && ~isempty(K.eb_mV), row.eb_min_mV = min(K.eb_mV); end
% trang thai: chi so sanh voi CCCV khi NMPC nap DU (toi SOC dich hoac dung nhu CCCV o I <= C/50)
% va trong ngan sach. Lan chay that bai / dung giua chung KHONG bao la muc giam (sua loi bao cao cu).
done = any(strcmp(R.reason, {'soc_reached', 'Icut'})) && R.soc_end >= cl.soc_target - 2e-3 ...
    && R.viol.budget <= max(cl.Ts, 1e-3*cl.budget);
if ~done
    row.status = 'failed';
else
    row.reduction_pct = 100*(1 - R.perm/cc.perm);
    vio = R.viol.V > 1e-3 || R.viol.eta > 1e-3 || R.viol.xs > 1e-3 || R.viol.T > 0.1;
    if vio, row.status = 'ok_violation'; else, row.status = 'ok'; end
end
row.nmpc_Vmax = max(S.V); row.nmpc_eta_min_mV = 1e3*min(S.eta_sep); row.nmpc_xs_max = max(S.xs_sep); row.nmpc_Tmax_C = max(S.T) - 273.15;
row.viol_V_mV = 1e3*R.viol.V; row.viol_T_K = R.viol.T; row.viol_eta_mV = 1e3*R.viol.eta; row.viol_xs = R.viol.xs; row.viol_budget_s = R.viol.budget;
row.n_solves = numel(K.t); row.n_fail = R.nfail;
row.n_status0 = sum(st == 0); row.n_status2 = sum(st == 2); row.n_status_other = sum(~ismember(st, [0 2]));
row.solve_mean_ms = 1e3*mean(K.time_tot); row.solve_median_ms = 1e3*median(K.time_tot);
q = sort(K.time_tot); row.solve_p95_ms = 1e3*q(max(1, ceil(0.95*numel(q)))); row.solve_max_ms = 1e3*max(K.time_tot);
row.wall_solve_mean_ms = 1e3*mean(K.wall); row.sqp_mean = mean(K.sqp_iter); row.sqp_max = max(K.sqp_iter);
row.closed_loop_wall_s = R.wall; row.plant_wall_s = R.plant_wall;
row.lin_mean_ms = 1e3*mean(K.time_lin); row.sim_mean_ms = 1e3*mean(K.time_sim);
row.qp_mean_ms = 1e3*mean(K.time_qp); row.glob_mean_ms = 1e3*mean(K.time_glob);
row.max_iter_warm = C.opt.max_iter_warm; row.n_status2_warm = sum(st == 2 & K.max_iter == C.opt.max_iter_warm);
end
