function R = nmpc_closed_loop(C, M, par, cfg)
%NMPC_CLOSED_LOOP  Sac vong kin: pin "that" = DFN day du (src/dfn), bo dieu
% khien = NMPC tren ROM (nmpc_build.m) nhan UOC LUONG trang thai.
%   cfg.soc0, cfg.soc1      vung SOC
%   cfg.soc_target          SOC dich cua NMPC (mac dinh soc1). pilot_run dat = SOC ma
%                           CCCV thuc su dat (GD-82: vung ket thuc 100 % thi CCCV dung o
%                           I <= C/50 truoc 100 %, NMPC phai nap DUNG luong do)
%   cfg.Tamb [K]            nhiet do moi truong
%   cfg.budget [s]          ngan sach thoi gian (Inf = khong gioi han)
%   cfg.Ts [s]              chu ky lay mau / giai lai (mac dinh 30 s)
%   cfg.Icc_cccv [A]        dong CC cua CCCV goc (doan dau "tu duong CCCV", GD-82)
%   cfg.w_loss_scale        muc tieu chuan hoa: w_loss = scale / (mat du doan cua CCCV tren ROM) (GD-84)
%   cfg.w_dI, Tmax, delta, xsmax   tham so acados (nmpc_build.m)
%   cfg.tmax [s]            can tren cua mo phong (an toan)
%   cfg.estimator           @(y, trk, meas) -> xhat ; mac dinh: biet het trang
%                           thai = rom_from_dfn (anh xa DFN -> ROM). Buoc F thay
%                           bang EKF dung meas = (t, I, V, T) do duoc.
% Thay doi 18/11/2026 (sau chay thu 44204442587, GD-82..GD-85):
%   - truoc vong lap: tinh thoi gian sac AN TOAN NHANH NHAT tren ROM (nmpc_cccv_rom, I_max);
%     neu > ngan sach: R.reason = 'infeasible_budget' ("khong the sac an toan trong thoi
%     gian nay"), khong chay vong kin;
%   - doan dau = duong CCCV (an toan) tren ROM, khong con I = 0 + doc tuyen tinh; lan giai
%     dau de dong sac tai nut 0 tu do;
%   - lan giai sau: doan dau = ke hoach truoc DICH theo thoi gian, mo phong lai ROM tu
%     trang thai moi (nhat quan dong luc);
%   - that bai: ap dong cua CCCV an toan tren ROM tu trang thai hien tai (du phong an
%     toan) va khoi tao lai tu do; dung han khi > 20 lan that bai LIEN TIEP;
%   - ket thuc nhu CCCV (GD-25): SOC dich, hoac dien ap o nguong va dong <= C/50.
rom = C.rom; E = M.E; io = M.iout;
if ~isfield(cfg, 'estimator') || isempty(cfg.estimator)
    cfg.estimator = @(y, trk, meas) rom_from_dfn(rom, par, y, trk);
end
if ~isfield(cfg, 'soc_target') || isempty(cfg.soc_target), cfg.soc_target = cfg.soc1; end
if ~isfield(cfg, 'band'), cfg.band = 1.3; end
if ~isfield(cfg, 'wall_max'), cfg.wall_max = Inf; end   % gioi han thoi gian CHAY (s) cua mot lan vong kin
if ~isfield(cfg, 'print_stat'), cfg.print_stat = 2; end
if ~isfield(cfg, 'dt_prof'), cfg.dt_prof = 30; end
if ~isfield(cfg, 'w_loss_scale'), cfg.w_loss_scale = 10; end
if ~isfield(cfg, 'max_consec_fail'), cfg.max_consec_fail = 20; end
if ~isfield(cfg, 'Cdis'), cfg.Cdis = 0.5; end
Ta = cfg.Tamb; Csoc = rom.Csoc; soc_t = cfg.soc_target;
Qstop = -(soc_t - cfg.soc0)*Csoc;
Vcv = v_limit(par); Icut = par.Qnom/50;
if ~isfield(cfg, 'soc_tol'), cfg.soc_tol = 0.005; end
lim = struct('Vcv', Vcv, 'Tmax', cfg.Tmax, 'delta', cfg.delta, 'xsmax', cfg.xsmax, 'Icut', Icut, 'soc_tol', cfg.soc_tol);
unlimited = ~isfinite(cfg.budget);
y = dfn_state_soc(par, cfg.soc0, Ta);
trk = aging_track('init', par);
t = 0; Ich = 0;
yc = dfn_consistent_init(0, y, par, struct('mode', 'I', 'value', 0, 'Tamb', Ta));
x0 = cfg.estimator(yc, trk, struct('t', 0, 'I', 0, 'V', NaN, 'T', Ta));
R = struct('reason', '', 'T_min_safe', NaN, 'guess_T', NaN, 'guess_Icc', NaN, 'guess_loss', NaN, 'w_loss', NaN, ...
    'nfail', 0, 'max_consec_fail', 0, 't_fallback', 0, 'wall', 0, 'plant_wall', 0, 't_prof', 0);
tw = tic;
% ---- thoi gian sac an toan nhanh nhat (ROM) va doan dau tu CCCV ----
Imax = C.opt.Imax;
tmax_prof = max(cfg.tmax, 1);
Pf = nmpc_cccv_rom(M, rom, x0, Ta, soc_t, Imax, lim, 0, cfg.dt_prof, tmax_prof);
R.T_min_safe = Pf.T;
fprintf('  sac an toan nhanh nhat (ROM, I <= %.1f A): %s, t = %.0f s, SOC %.4f (%d lan tich phan, %.1f s)\n', ...
    Imax, Pf.reason, Pf.t_end, Pf.soc_end, Pf.nsim, Pf.wall);
if ~unlimited && R.T_min_safe > cfg.budget
    R.reason = 'infeasible_budget';
    R.t_prof = toc(tw); R.wall = toc(tw);
    fprintf('  => KHONG THE SAC AN TOAN trong ngan sach %.0f s (nhanh nhat %.0f s)\n', cfg.budget, R.T_min_safe);
    return
end
% doan dau "tu duong CCCV": CCCV an toan o dong goc; neu qua ngan sach thi dong CC
% lon dan (I_cc T_CCCV / ngan sach, roi I_max) - duong an toan nhanh nhat da tinh.
P = []; Icc_list = cfg.Icc_cccv;
if ~unlimited
    Icc_list = unique(min(Imax, [cfg.Icc_cccv, cfg.Icc_cccv*max(1, cfg.T_cccv/cfg.budget)*1.05]));
end
for Icc = Icc_list
    Pc = nmpc_cccv_rom(M, rom, x0, Ta, soc_t, Icc, lim, 0, cfg.dt_prof, tmax_prof);
    fprintf('  doan dau CCCV an toan tren ROM, I_cc = %.2f A: %s, t = %.0f s, SOC %.4f (%.1f s)\n', Icc, Pc.reason, Pc.t_end, Pc.soc_end, Pc.wall);
    if isfinite(Pc.T) && (unlimited || Pc.T <= cfg.budget), P = Pc; break; end
end
if isempty(P), P = Pf; Icc = Imax; end
R.guess_T = P.t_end; R.guess_Icc = Icc;
R.guess_loss = P.X(rom.ix.nsei, end) + P.X(rom.ix.ndl, end);
R.t_prof = toc(tw);
% muc tieu chuan hoa theo mat du doan cua doan dau CCCV (GD-84)
wl = cfg.w_loss_scale/max(R.guess_loss, 1e-6); R.w_loss = wl;
% SOC dich trong du bao: neu ROM chi toi duoc SOC thap hon mot chut truoc khi I <= C/50
% (sai so dien ap ROM, vung ket thuc 100 %) thi dung muc do lam dich cua bai toan toi uu;
% vong kin van dung theo SOC dich tren pin that hoac theo dieu kien CV (GD-82).
soc_t_rom = soc_t; if strcmp(P.reason, 'Icut'), soc_t_rom = min(soc_t, P.soc_end); end
prm = [Ta; soc_t_rom; 1; wl; cfg.w_dI; cfg.Tmax; cfg.delta; cfg.xsmax; 0];
tf_ref = P.t_end/3600;
nmpc_set_guess(C, P, 0, tf_ref);
% ---- vong lap ----
S = struct('t', [], 'I', [], 'V', [], 'T', [], 'soc', [], 'xs_sep', [], 'eta_sep', [], 'dphi_sep', [], 'nsei', [], 'npl', []);
K = struct('t', [], 'status', [], 'sqp_iter', [], 'time_tot', [], 'wall', [], 'tf_h', [], 'slope', [], 'loss_pred', [], 'soc_end', [], 'nrep', [], ...
    'time_lin', [], 'time_sim', [], 'time_qp', [], 'time_glob', [], 'max_iter', [], 'vb_mV', [], 'fallback', [], 'guess_s', []);
reason = 'tmax'; nfail = 0; ncons = 0; meas = struct('t', 0, 'I', 0, 'V', NaN, 'T', Ta);
tplant = 0; tfb = 0;
cold = true; first = true; prev = [];
while t < cfg.tmax
    if toc(tw) > cfg.wall_max, reason = 'wall_limit'; break; end
    xhat = cfg.estimator(y, trk, meas);
    if xhat(rom.ix.soc) >= soc_t - 1e-6, reason = 'soc_reached'; break; end
    if unlimited
        prm(3) = C.opt.tf_cap_h;
    else
        prm(3) = max((cfg.budget - t)/3600, C.opt.tf_min_h);
    end
    % lech dien ap do duoc - ROM tai trang thai hien tai (GD-83)
    if isfinite(meas.V)
        o = full(E.out(xhat, -Ich, Ta)); prm(9) = meas.V - o(io.V);
    end
    % doan dau: ke hoach truoc dich theo thoi gian, mo phong lai ROM tu xhat
    tg = tic;
    if ~isempty(prev)
        shift_guess(prev, xhat);
    end
    tguess = toc(tg);
    % giai, dich vung tin cay cua t_f neu nghiem cham bien vung (toi da 8 lan)
    ttot = 0; twal = 0; tbr = zeros(1, 4);
    if cold, mi = C.opt.max_iter; else, mi = C.opt.max_iter_warm; end
    C.solver.set('nlp_solver_max_iter', mi);
    for rep = 1:8
        tfband = [max(C.opt.tf_min_h, tf_ref/cfg.band), min(C.opt.tf_cap_h, tf_ref*cfg.band)];
        [plan, info] = nmpc_solve(C, xhat, Ich, prm, tfband, first);
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
    fb = ~plan.ok;
    K.t(end+1, 1) = t; K.status(end+1, 1) = info.status; K.sqp_iter(end+1, 1) = info.sqp_iter;
    K.time_tot(end+1, 1) = info.time_tot; K.wall(end+1, 1) = info.wall;
    K.tf_h(end+1, 1) = plan.tf_h; K.slope(end+1, 1) = plan.slope; K.loss_pred(end+1, 1) = plan.loss_pred;
    K.soc_end(end+1, 1) = plan.soc_end; K.nrep(end+1, 1) = rep;
    K.time_lin(end+1, 1) = tbr(1); K.time_sim(end+1, 1) = tbr(2); K.time_qp(end+1, 1) = tbr(3); K.time_glob(end+1, 1) = tbr(4);
    K.max_iter(end+1, 1) = mi; K.vb_mV(end+1, 1) = 1e3*prm(9); K.fallback(end+1, 1) = fb; K.guess_s(end+1, 1) = tguess;
    if numel(K.t) <= 10 || mod(numel(K.t), 20) == 0 || fb
        fprintf('  [%4d] t %6.0f s soc %.4f I %.2f A | status %d sqp %2d/%d rep %d %.0f ms (lin %.0f, sim %.0f, qp %.0f, glob %.0f) | tf %.3f h I0 %.2f slope %.2e A/s loss %.5f mAh soc_N %.4f | vb %.1f mV | doan dau %.1f s | wall %.0f s\n', ...
            numel(K.t), t, xhat(rom.ix.soc), Ich, info.status, info.sqp_iter, mi, rep, 1e3*info.time_tot, 1e3*tbr, plan.tf_h, plan.I0, plan.slope, plan.loss_pred, plan.soc_end, 1e3*prm(9), tguess, toc(tw));
    end
    if plan.ok
        cold = false; ncons = 0;
        if first, Ich = plan.I0; end
        first = false;
        slope = plan.slope; Tseg = min(cfg.Ts, max(plan.dt1, 1));
        prev = struct('Inodes', plan.Inodes, 'tf_h', plan.tf_h);
        prev.Inodes(1) = Ich;
    else
        % that bai: du phong AN TOAN = CCCV an toan tren ROM tu trang thai hien tai (dong CC
        % = max(dong hien tai, dong can de kip ngan sach)); khoi tao lai doan dau tu do
        nfail = nfail + 1; ncons = ncons + 1; cold = true;
        R.max_consec_fail = max(R.max_consec_fail, ncons);
        if nfail <= 2, nmpc_diag(C, prm); end
        C.solver.reset();
        rem_h = max(prm(3), 0.05);
        Ineed = (soc_t - xhat(rom.ix.soc))*Csoc/rem_h;
        Pfb = nmpc_cccv_rom(M, rom, xhat, Ta, soc_t, min(Imax, max([Ich, Ineed, Icut*2])), lim, prm(9), cfg.dt_prof, tmax_prof);
        fprintf('  du phong: CCCV an toan ROM tu SOC %.4f: %s, con %.0f s, I dau %.2f A\n', xhat(rom.ix.soc), Pfb.reason, Pfb.t_end, Pfb.I(1));
        Tseg = cfg.Ts;
        Ifb = Pfb.I(1);
        slope = 0; Ich = Ifb; first = false;
        tf_ref = max(Pfb.t_end/3600, C.opt.tf_min_h);
        nmpc_set_guess(C, Pfb, min(Tseg, Pfb.t_end), max(tf_ref - Tseg/3600, C.opt.tf_min_h));
        prev = [];
        tfb = tfb + Tseg;
        if ncons > cfg.max_consec_fail, reason = 'nmpc_failed'; break; end
    end
    % khong de dong sac am / vuot I_max trong khoang (ke hoach tuyen tinh)
    Iend = Ich + slope*Tseg;
    if Iend < 0, Tseg = max(Ich/max(-slope, eps), 1); end
    if Iend > Imax, slope = (Imax - Ich)/Tseg; end
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
    if plan.ok
        tf_ref = max(plan.tf_h - tseg/3600, C.opt.tf_min_h);
        prev.elapsed = tseg;
    end
    meas = struct('t', t, 'I', Ich, 'V', o.V(end), 'T', o.T(end));
    if strcmp(o.reason{end}, 'Qstop'), reason = 'soc_reached'; break; end
    if ~strcmp(o.reason{end}, 'time'), reason = ['plant_' o.reason{end}]; break; end
    % ket thuc nhu pha CV cua CCCV (GD-25): dien ap o nguong va dong <= C/50
    if o.V(end) >= Vcv - 2e-3 && Ich <= Icut, reason = 'Icut'; break; end
end
R.wall = toc(tw); R.plant_wall = tplant; R.t_fallback = tfb;
R.reason = reason; R.ser = S; R.solve = K; R.nfail = nfail;
R.t_charge = t;
R.soc_end = S.soc(end);
R.nsei = trk.nsei; R.npl = trk.npl; R.ndl = trk.ndl;     % sau pha sac
R.pl_peak = max(S.npl - interp1([0; S.t(end)], [0; trk.ndl], S.t));   % xap xi: tru lithium chet cuoi (rat nho)
[R.dis, trk] = eval_discharge(par, y, trk, Ta, cfg.Cdis);
R.perm = R.dis.perm;
R.viol.V = max(max(S.V) - Vcv, 0);
R.viol.T = max(max(S.T) - cfg.Tmax, 0);
R.viol.eta = max(cfg.delta - min(S.eta_sep), 0);
R.viol.xs = max(max(S.xs_sep) - cfg.xsmax, 0);
R.viol.budget = max(t - cfg.budget, 0);
R.loss_pred0 = K.loss_pred(1);

    function shift_guess(pv, xh)
        % ke hoach truoc (dong tai cac nut, t_f) dich di pv.elapsed giay, mo phong lai
        % ROM tu trang thai moi xh voi dung dong do -> doan dau nhat quan dong luc
        tfo = 3600*pv.tf_h; tfn = max(tfo - pv.elapsed, 3600*C.opt.tf_min_h);
        to = (0:C.N).'/C.N*tfo;
        Ifn = @(s) interp1(to, pv.Inodes, min(s + pv.elapsed, tfo), 'linear');
        tn = (0:C.N).'/C.N*tfn;
        okg = false;
        try
            rr = rom_sim_ode(E, M, rom, xh, @(s) -Ifn(s), Ta, tn, struct('sat', false));
            okg = numel(rr.t) == C.N + 1 && all(isfinite(rr.X(:)));
        catch
        end
        if okg
            Pg = struct('t', tn, 'X', rr.X, 'I', Ifn(tn));
        else
            Pg = struct('t', [0; tfn], 'X', [xh(:), xh(:)], 'I', Ifn([0; tfn]));
        end
        Pg.I(1) = Ich;
        nmpc_set_guess(C, Pg, 0, tfn/3600);
    end
end
