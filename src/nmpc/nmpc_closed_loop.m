function R = nmpc_closed_loop(C, M, par, cfg)
%NMPC_CLOSED_LOOP  Sac vong kin: pin "that" = DFN day du (src/dfn), bo dieu
% khien = NMPC tren ROM (nmpc_build.m) nhan UOC LUONG trang thai.
%   cfg.soc0, cfg.soc1      vung SOC
%   cfg.Tamb [K]            nhiet do moi truong
%   cfg.budget [s]          ngan sach thoi gian (Inf = khong gioi han)
%   cfg.Ts [s]              chu ky lay mau / giai lai (mac dinh 30 s)
%   cfg.w_loss, w_dI, Tmax, delta, xsmax   tham so acados (nmpc_build.m)
%   cfg.tmax [s]            can tren cua mo phong (an toan)
%   cfg.tf_guess [s]        doan dau thoi gian sac (che do khong gioi han)
%   cfg.estimator           @(y, trk, meas) -> xhat ; mac dinh: biet het trang
%                           thai = rom_from_dfn (anh xa DFN -> ROM). Buoc F thay
%                           bang EKF dung meas = (t, I, V, T) do duoc.
rom = C.rom; ix = par.ix;
if ~isfield(cfg, 'estimator') || isempty(cfg.estimator)
    cfg.estimator = @(y, trk, meas) rom_from_dfn(rom, par, y, trk);
end
Ta = cfg.Tamb; Csoc = rom.Csoc;
Qstop = -(cfg.soc1 - cfg.soc0)*Csoc;
y = dfn_state_soc(par, cfg.soc0, Ta);
trk = aging_track('init', par);
t = 0; Ich = 0;
unlimited = ~isfinite(cfg.budget);
prm = [Ta; cfg.soc1; 1; cfg.w_loss; cfg.w_dI; cfg.Tmax; cfg.delta; cfg.xsmax];
% ---- doan dau ----
yc = dfn_consistent_init(0, y, par, struct('mode', 'I', 'value', 0, 'Tamb', Ta));
[x0, zg] = rom_from_dfn(rom, par, yc, trk);
[z0, ~] = rom_solve_z(M, x0, 0, Ta, zg);
if unlimited, tf0 = cfg.tf_guess; else, tf0 = cfg.budget; end
Ig = min(C.opt.Imax, (cfg.soc1 - cfg.soc0)*Csoc/(tf0/3600));
nmpc_init_guess(C, M, x0, z0, 0, tf0/3600, Ta, Ig);
% ---- vong lap ----
S = struct('t', [], 'I', [], 'V', [], 'T', [], 'soc', [], 'xs_sep', [], 'eta_sep', [], 'dphi_sep', [], 'nsei', [], 'npl', []);
K = struct('t', [], 'status', [], 'sqp_iter', [], 'time_tot', [], 'wall', [], 'tf_h', [], 'slope', [], 'loss_pred', [], 'soc_end', [], 'nrep', [], ...
    'time_lin', [], 'time_sim', [], 'time_qp', [], 'time_glob', [], 'max_iter', []);
if ~isfield(cfg, 'band'), cfg.band = 1.3; end
tf_ref = tf0/3600;
reason = 'tmax'; nfail = 0; meas = struct('t', 0, 'I', 0, 'V', NaN, 'T', Ta);
if ~isfield(cfg, 'wall_max'), cfg.wall_max = Inf; end   % gioi han thoi gian CHAY (s) cua mot lan vong kin
tw = tic; tplant = 0;
% so vong SQP toi da: lan giai "lanh" (dau tien / sau khoi tao lai) = C.opt.max_iter;
% cac lan sau khoi dong nong tu nghiem truoc = C.opt.max_iter_warm (nmpc_variant.m)
cold = true;
if ~isfield(cfg, 'print_stat'), cfg.print_stat = 2; end
while t < cfg.tmax
    if toc(tw) > cfg.wall_max, reason = 'wall_limit'; break; end
    xhat = cfg.estimator(y, trk, meas);
    if xhat(rom.ix.soc) >= cfg.soc1 - 1e-6, reason = 'soc_reached'; break; end
    if unlimited
        prm(3) = C.opt.tf_cap_h;
    else
        prm(3) = max((cfg.budget - t)/3600, C.opt.tf_min_h);
    end
    % giai, dich vung tin cay cua t_f neu nghiem cham bien vung (toi da 8 lan)
    ttot = 0; twal = 0; tbr = zeros(1, 4);
    if cold, mi = C.opt.max_iter; else, mi = C.opt.max_iter_warm; end
    C.solver.set('nlp_solver_max_iter', mi);
    for rep = 1:8
        tfband = [max(C.opt.tf_min_h, tf_ref/cfg.band), min(C.opt.tf_cap_h, tf_ref*cfg.band)];
        [plan, info] = nmpc_solve(C, xhat, Ich, prm, tfband);
        ttot = ttot + info.time_tot; twal = twal + info.wall;
        tbr = tbr + [info.time_lin, info.time_sim, info.time_qp, info.time_glob];
        if numel(K.t) < cfg.print_stat
            fprintf('  thong ke SQP lan giai %d (rep %d, toi da %d vong):\n', numel(K.t) + 1, rep, mi);
            try, C.solver.print('stat'); catch, end
        end
        glob = abs(plan.tf_h - C.opt.tf_min_h) < 1e-6 || abs(plan.tf_h - C.opt.tf_cap_h) < 1e-6;
        if ~plan.ok || ~plan.at_edge || glob, break; end
        tf_ref = plan.tf_h;
    end
    info.time_tot = ttot; info.wall = twal;
    K.t(end+1, 1) = t; K.status(end+1, 1) = info.status; K.sqp_iter(end+1, 1) = info.sqp_iter;
    K.time_tot(end+1, 1) = info.time_tot; K.wall(end+1, 1) = info.wall;
    K.tf_h(end+1, 1) = plan.tf_h; K.slope(end+1, 1) = plan.slope; K.loss_pred(end+1, 1) = plan.loss_pred;
    K.soc_end(end+1, 1) = plan.soc_end; K.nrep(end+1, 1) = rep;
    K.time_lin(end+1, 1) = tbr(1); K.time_sim(end+1, 1) = tbr(2); K.time_qp(end+1, 1) = tbr(3); K.time_glob(end+1, 1) = tbr(4);
    K.max_iter(end+1, 1) = mi;
    if numel(K.t) <= 10 || mod(numel(K.t), 20) == 0 || ~plan.ok
        fprintf('  [%4d] t %6.0f s soc %.4f I %.2f A | status %d sqp %2d/%d rep %d %.0f ms (lin %.0f, sim %.0f, qp %.0f, glob %.0f) | tf %.3f h slope %.2e A/s loss %.4f mAh soc_N %.4f | wall %.0f s\n', ...
            numel(K.t), t, xhat(rom.ix.soc), Ich, info.status, info.sqp_iter, mi, rep, 1e3*info.time_tot, 1e3*tbr, plan.tf_h, plan.slope, plan.loss_pred, plan.soc_end, toc(tw));
    end
    if plan.ok
        cold = false;
        slope = plan.slope; Tseg = min(cfg.Ts, max(plan.dt1, 1));
    else
        % that bai: giu dong hien tai trong mot chu ky, khoi tao lai doan dau
        nfail = nfail + 1; slope = 0; Tseg = cfg.Ts; cold = true;
        if nfail <= 2, nmpc_diag(C, prm); C.sweep = false; end
        C.solver.reset();
        [zg2, ~] = rom_solve_z(M, xhat, -Ich, Ta, zg);
        rem = max(prm(3), 0.1);
        rem = min(rem, tf_ref);
        nmpc_init_guess(C, M, xhat, zg2, Ich, rem, Ta, max(Ich, min(C.opt.Imax, (cfg.soc1 - xhat(rom.ix.soc))*Csoc/rem)));
        tf_ref = rem;
        if nfail > 20, reason = 'nmpc_failed'; break; end
    end
    % khong de dong sac am / vuot I_max trong khoang (ke hoach tuyen tinh)
    Iend = Ich + slope*Tseg;
    if Iend < 0, Tseg = max(Ich/max(-slope, eps), 1); end
    if Iend > C.opt.Imax, slope = (C.opt.Imax - Ich)/Tseg; end
    I0 = Ich; sl = slope;
    st = struct('mode', 'I', 'value', @(tt) -max(I0 + sl*tt, 0), 'tmax', Tseg, 'Tamb', Ta, ...
        'stop', struct('Qstop', Qstop, 'Vmin', par.Vmin), 'tout', []);
    tp = tic;
    [o, trk] = plant_run(par, y, st, trk, struct('dt', min(5, Tseg/2)));
    tplant = tplant + toc(tp);
    f = fieldnames(S);
    for i = 1:numel(f)
        v = o.(f{i}); if strcmp(f{i}, 't'), v = v + t; end
        if strcmp(f{i}, 'I'), v = -v; end
        S.(f{i}) = [S.(f{i}); v];
    end
    y = o.y_end; tseg = o.t(end); t = t + tseg; Ich = max(I0 + sl*tseg, 0);
    if plan.ok, tf_ref = max(plan.tf_h - tseg/3600, C.opt.tf_min_h); end
    meas = struct('t', t, 'I', Ich, 'V', o.V(end), 'T', o.T(end));
    if strcmp(o.reason{end}, 'Qstop'), reason = 'soc_reached'; break; end
    if ~strcmp(o.reason{end}, 'time'), reason = ['plant_' o.reason{end}]; break; end
end
R.wall = toc(tw); R.plant_wall = tplant;
R.reason = reason; R.ser = S; R.solve = K; R.nfail = nfail;
R.t_charge = t;
R.soc_end = S.soc(end);
R.nsei = trk.nsei; R.npl = trk.npl; R.ndl = trk.ndl;     % sau pha sac
R.pl_peak = max(S.npl - interp1([0; S.t(end)], [0; trk.ndl], S.t));   % xap xi: tru lithium chet cuoi (rat nho)
if ~isfield(cfg, 'Cdis'), cfg.Cdis = 0.5; end
[R.dis, trk] = eval_discharge(par, y, trk, Ta, cfg.Cdis);
R.perm = R.dis.perm;
R.viol.V = max(max(S.V) - v_limit(par), 0);
R.viol.T = max(max(S.T) - cfg.Tmax, 0);
R.viol.eta = max(cfg.delta - min(S.eta_sep), 0);
R.viol.xs = max(max(S.xs_sep) - cfg.xsmax, 0);
R.viol.budget = max(t - cfg.budget, 0);
R.loss_pred0 = K.loss_pred(1);
end
