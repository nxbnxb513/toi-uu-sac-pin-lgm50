function S = ekf_run_case(Tc, crate, noise, socerr, scen, outdir, over)
%EKF_RUN_CASE  Thu EKF voi pin "that" la DFN day du (src/dfn) khi sac CCCV.
%   S = ekf_run_case(25, 1, 'lab', +0.10, 'mismatch', 'results/ekf')
%   Tc [degC] nhiet do moi truong; crate: dong CC (1C = par.Qnom = 5 A);
%   noise: 'lab' | 'bms' | 'bms_off' (ekf_config.m);
%   socerr: sai SOC ban dau cua EKF. > 0: pin that bat dau o SOC 0, EKF doan socerr
%           (sac 0 -> 100 %); < 0: pin that bat dau o |socerr|, EKF doan 0;
%   scen: kich ban pin that (ekf_plant_par.m: 'nominal' | 'mismatch' | 'mismatch_Rc').
% CCCV: CC toi V_cv = par.V_cv (GD-43), CV toi C/50 = 0.1 A (GD-25), dfn_cccv.m.
% EKF chi dung dong, dien ap, nhiet do be mat DO DUOC (ekf_sensor.m); nhiet do
% moi truong coi nhu biet (buong nhiet / cam bien moi truong).
% over: chuoi ghi de so dieu chinh cua ekf_config, vd 'n_iter=5; P0.rf=0.2' (bien the thu).
if nargin < 6 || isempty(outdir), outdir = 'results/ekf'; end
if ~exist(outdir, 'dir'), mkdir(outdir); end
tag = sprintf('T%d_c%02d_%s_e%+03d_%s', Tc, round(10*crate), noise, round(100*socerr), scen);
fprintf('\n===== EKF %s =====\n', tag);
Ta = 273.15 + Tc;
par = dfn_params();
c = ekf_config(noise);
if nargin >= 7 && ~isempty(over)
    c = apply_over(c, over); tag = [tag '_' regexprep(over, '[^A-Za-z0-9]+', '')];
end
fprintf('so dieu chinh: %s\n', jsonencode(c));
tb = tic; E = ekf_build(par); tbuild = toc(tb);
fprintf('ekf_build: %.1f s (ROM %s: %d trang thai, %d dai so; bo loc %d)\n', tbuild, E.cfg, E.nx, E.nz, E.na);
[pp, pinfo] = ekf_plant_par(par, scen);
% ---- pin that ------------------------------------------------------------
if socerr >= 0, soc0 = 0; soc_guess = socerr; else, soc0 = -socerr; soc_guess = 0; end
Csoc = pp.neg.Qcap*(pp.neg.x100 - pp.neg.x0);
q = (1 - soc0)*Csoc;
xn = pp.neg.x100 - q/pp.neg.Qcap;
yp = pp.pos.y100 + q/pp.pos.Qcap - pinfo.lli/pp.pos.Qcap;    % mat lithium: cuc duong it lithium hon
y0 = dfn_init_state(pp, xn, yp, Ta);
steps = dfn_cccv(crate*pp.Qnom, pp, 0.02*pp.Qnom, Ta, 20*3600);
tp = tic;
[D, ~] = plant_run(pp, y0, steps, aging_track('init', pp), struct('dt', c.dt, 'snap', 0:60:20*3600));
tplant = toc(tp);
[t, ia] = unique(D.t, 'last');
I = D.I(ia); V = D.V(ia); T = D.T(ia); soc_t = D.soc(ia); eta_t = D.eta_sep(ia); xs_t = D.xs_sep(ia);
fprintf('DFN: %s, %.0f s, SOC %.3f -> %.3f, chay %.1f s\n', strjoin(D.reason, '/'), t(end), soc_t(1), soc_t(end), tplant);
% ---- cam bien -------------------------------------------------------------
seed = 1000*Tc + 10*round(10*crate) + numel(noise) + 7*round(100*abs(socerr)) + numel(scen);
[Im, Vm, Tm] = ekf_sensor(c, I, V, T, seed);
% ---- EKF -------------------------------------------------------------------
n = numel(t);
[xa, P] = ekf_init(E, c, soc_guess, Tm(1));
f = {'soc', 's_soc', 'eta', 's_eta', 'T', 's_T', 'lli', 's_lli', 'rf', 's_rf', 'xs_sep', 'nis', 'proj', 'wall'};
for i = 1:numel(f), R.(f{i}) = NaN(n, 1); end
R = put(R, 1, ekf_outputs(E, xa, P, Im(1), Ta), NaN, 0, 0);
Xs = NaN(E.na, n); Ps = cell(n, 1); Xs(:, 1) = [xa(E.fi); xa(end)]; Ps{1} = P;
te = tic; nskip = 0; failed = 0; nls = 0; nfade = 0;
for k = 2:n
    dtk = t(k) - t(k-1);
    tw = tic;
    if dtk < 1e-3
        nskip = nskip + 1; R = put(R, k, ekf_outputs(E, xa, P, Im(k), Ta), NaN, 0, 0); continue
    end
    u = struct('I0', Im(k-1), 'I1', Im(k), 'dt', dtk, 'Tamb', Ta, 'hold', t(k) < c.t_hold);
    try
        [xa, P, inf_] = ekf_step(E, xa, P, u, [Vm(k); Tm(k)], c);
    catch err
        fprintf('EKF DUNG o buoc %d (t = %.1f s): %s\n', k, t(k), err.message);
        fprintf('  x: stoich am [%.4g, %.4g], duong [%.4g, %.4g], c_e [%.4g, %.4g], T %.2f, rf %.3f\n', ...
            min(xa(E.ix.thn)), max(xa(E.ix.thn)), min(xa(E.ix.thp)), max(xa(E.ix.thp)), min(xa(E.ix.ce)), max(xa(E.ix.ce)), xa(E.ix.T), xa(end));
        failed = k; break
    end
    if k <= 4
        fprintf('  buoc %d: innov V %.2f mV, T %.3f K, NIS %.2f, SOC %.4f, rf %.3f\n', k, 1e3*inf_.innov(1), inf_.innov(2), inf_.nis, xa(E.ix.soc), xa(end));
    end
    if isfield(inf_, 'alpha') && inf_.alpha < 1, nls = nls + 1; end
    if isfield(inf_, 'lam') && inf_.lam > 1, nfade = nfade + 1; end
    R = put(R, k, ekf_outputs(E, xa, P, Im(k), Ta), inf_.nis, inf_.proj, toc(tw));
    Xs(:, k) = [xa(E.fi); xa(end)]; Ps{k} = P;
    if mod(k, 200) == 0
        fprintf('  t = %6.0f s: SOC %.4f (that %.4f), eta %.1f mV (that %.1f), rf %.3f, LLI %.3f Ah, %.2f s/buoc\n', ...
            t(k), R.soc(k), soc_t(k), 1e3*R.eta(k), 1e3*eta_t(k), R.rf(k), R.lli(k), toc(te)/k);
    end
end
tekf = toc(te);
if failed
    keep = (1:n).' < failed;
    t = t(keep); I = I(keep); V = V(keep); T = T(keep); soc_t = soc_t(keep); eta_t = eta_t(keep); xs_t = xs_t(keep);
    Im = Im(keep); Vm = Vm(keep); Tm = Tm(keep); Xs = Xs(:, keep); Ps = Ps(keep); n = numel(t);
    fn = fieldnames(R); for i = 1:numel(fn), R.(fn{i}) = R.(fn{i})(keep); end
    if n < 130, error('ekf_run_case: EKF dung qua som (buoc %d)', failed); end
end
% ---- sai so -------------------------------------------------------------------
S.tag = tag; if nargin >= 7, S.over = string(over); else, S.over = ""; end; S.Tc = Tc; S.crate = crate; S.noise = noise; S.socerr = socerr; S.scen = scen;
S.plant_desc = pinfo.desc; S.reason = strjoin(D.reason, '/'); S.t_end = t(end);
S.failed_at = failed; S.n = n; S.tbuild = tbuild; S.tplant = tplant; S.tekf = tekf; S.ms_per_step = 1e3*tekf/(n-1);
S.nskip = nskip; S.nproj = sum(R.proj(2:end) > 0); S.nls = nls; S.nfade = nfade;
es = R.soc - soc_t; ee = R.eta - eta_t; eT = R.T - T;
late = t >= 600;
S.soc_rmse = 100*rmsv(es); S.soc_max = 100*max(abs(es));
S.soc_rmse_l = 100*rmsv(es(late)); S.soc_max_l = 100*max(abs(es(late)));
S.eta_rmse = 1e3*rmsv(ee); S.eta_max = 1e3*max(abs(ee));
S.eta_rmse_l = 1e3*rmsv(ee(late)); S.eta_max_l = 1e3*max(abs(ee(late)));
S.T_rmse = rmsv(eT); S.T_max = max(abs(eT)); S.T_rmse_l = rmsv(eT(late)); S.T_max_l = max(abs(eT(late)));
S.tconv_soc = tconv(t, abs(es) < 0.01);       % |sai SOC| < 1 % tu do ve sau
S.tconv_eta = tconv(t, abs(ee) < 5e-3);       % |sai eta_Li| < 5 mV tu do ve sau
% do nhat quan: NEES vo huong (ly tuong 1) va ty le nam trong +/-3 sigma (ly tuong 99.7 %)
[S.nees_soc, S.in3_soc] = cons(es(late), R.s_soc(late));
[S.nees_eta, S.in3_eta] = cons(ee(late), R.s_eta(late));
[S.nees_T, S.in3_T] = cons(eT(late), R.s_T(late));
S.nis = mean(R.nis(late), 'omitnan');         % ly tuong 2 (2 phep do)
% an toan ma lithium: e = eta_uoc - eta_that > 0 la UOC LUONG CAO (nguy hiem)
S.eta_over_max = 1e3*max(ee(late));
S.eta_over_p997 = 1e3*qtl(ee(late), 0.997);
S.eta_under_max = -1e3*min(ee(late));          % uoc THAP (an toan nhung ton thoi gian sac)
near = late & eta_t < 0.1;
if any(near), S.eta_over_near = 1e3*max(ee(near)); S.eta_rmse_near = 1e3*rmsv(ee(near)); else, S.eta_over_near = NaN; S.eta_rmse_near = NaN; end
S.s_eta_med = 1e3*median(R.s_eta(late));
S.cover1s = 100*mean(R.eta(late) - 3*R.s_eta(late) <= eta_t(late));   % eta_that >= eta_uoc - 3 sigma
S.eta_true_min = 1e3*min(eta_t); S.eta_est_min = 1e3*min(R.eta);
% lao hoa: gia tri cuoi
S.lli_true = pinfo.lli; S.lli_end = R.lli(end); S.s_lli_end = R.s_lli(end);
S.rf_true = pinfo.rf; S.rf_end = R.rf(end); S.s_rf_end = R.s_rf(end);
S.Lsei_true_nm = 1e9*pinfo.rf*par.sei.L0; S.Lsei_end_nm = 1e9*R.rf(end)*par.sei.L0;
% NEES toan trang thai (chan doan): so voi anh xa DFN -> ROM tai cac anh chup 60 s
S.nees_full = NaN;
if ~isempty(D.tsnap)
    nf = [];
    for j = 1:numel(D.tsnap)
        [dmin, k] = min(abs(t - D.tsnap(j)));
        if dmin > 1e-6 || t(k) < 600 || isempty(Ps{k}), continue; end
        xt = rom_from_dfn(E.rom, par, D.Ysnap(:, j));
        e = Xs(:, k) - [xt(E.fi); pinfo.rf];
        nf(end+1) = e.'*(Ps{k}\e)/E.na; %#ok<AGROW>
    end
    if ~isempty(nf), S.nees_full = median(nf); end
end
fprintf(['KET QUA %s: SOC RMSE %.2f %% (sau 600 s %.2f, max %.2f); eta RMSE %.2f mV (sau 600 s %.2f, max %.2f); ' ...
    'T RMSE %.3f K; hoi tu SOC %.0f s, eta %.0f s; NEES soc/eta/T %.2f/%.2f/%.2f; trong 3 sigma %.1f/%.1f/%.1f %%; ' ...
    'LLI %.3f (that %.3f) Ah; rf %.3f (that %.2f); %.0f ms/buoc\n'], tag, S.soc_rmse, S.soc_rmse_l, S.soc_max_l, ...
    S.eta_rmse, S.eta_rmse_l, S.eta_max_l, S.T_rmse, S.tconv_soc, S.tconv_eta, S.nees_soc, S.nees_eta, S.nees_T, ...
    S.in3_soc, S.in3_eta, S.in3_T, S.lli_end, S.lli_true, S.rf_end, S.rf_true, S.ms_per_step);
% ---- ghi ket qua ----------------------------------------------------------------
writetable(struct2table(S), fullfile(outdir, ['ekf_sum_' tag '.csv']));
Tt = table(t, I, Im, V, Vm, T, Tm, soc_t, R.soc, R.s_soc, eta_t, R.eta, R.s_eta, xs_t, R.xs_sep, R.T, R.s_T, ...
    R.lli, R.s_lli, R.rf, R.s_rf, R.nis, 'VariableNames', {'t', 'I', 'I_meas', 'V', 'V_meas', 'T', 'T_meas', ...
    'soc_true', 'soc_est', 'soc_sd', 'eta_true', 'eta_est', 'eta_sd', 'xs_true', 'xs_est', 'T_est', 'T_sd', ...
    'lli_est', 'lli_sd', 'rf_est', 'rf_sd', 'nis'});
writetable(Tt, fullfile(outdir, ['ekf_ts_' tag '.csv']));
try
    fig = figure('Visible', 'off', 'Position', [0 0 1400 900]);
    th = t/60;
    subplot(2, 3, 1); band(th, 100*R.soc, 300*R.s_soc); hold on; plot(th, 100*soc_t, 'k'); ylabel('SOC (%)'); title(tag, 'Interpreter', 'none');
    subplot(2, 3, 2); band(th, 1e3*R.eta, 3e3*R.s_eta); hold on; plot(th, 1e3*eta_t, 'k'); yline(1e3*(0.010 + par.ctrl.delta_pl_extra), 'r--'); ylabel('\eta_{Li,sep} (mV)');
    subplot(2, 3, 3); band(th, R.T - 273.15, 3*R.s_T); hold on; plot(th, T - 273.15, 'k'); ylabel('T (degC)');
    subplot(2, 3, 4); band(th, R.rf, 3*R.s_rf); hold on; yline(pinfo.rf, 'k'); ylabel('R_{film}/R_{film,BOL}'); xlabel('t (phut)');
    subplot(2, 3, 5); band(th, 1e3*R.lli, 3e3*R.s_lli); hold on; yline(1e3*pinfo.lli, 'k'); ylabel('LLI (mAh)'); xlabel('t (phut)');
    subplot(2, 3, 6); plot(th, 1e3*(R.eta - eta_t)); hold on; plot(th, 3e3*R.s_eta, 'r--', th, -3e3*R.s_eta, 'r--'); ylabel('sai so \eta (mV)'); xlabel('t (phut)');
    exportgraphics(fig, fullfile(outdir, ['ekf_' tag '.png']), 'Resolution', 90); close(fig);
catch err
    fprintf('Khong ve duoc hinh: %s\n', err.message);
end
end

function c = apply_over(c, over)
parts = strtrim(strsplit(over, ';'));
for i = 1:numel(parts)
    if isempty(parts{i}), continue; end
    kv = strtrim(strsplit(parts{i}, '='));
    f = strsplit(kv{1}, '.');
    c = setfield(c, f{:}, str2double(kv{2})); %#ok<SFLD>
end
end

function R = put(R, k, q, nis, proj, wall)
R.soc(k) = q.soc; R.s_soc(k) = q.s_soc; R.eta(k) = q.eta; R.s_eta(k) = q.s_eta;
R.T(k) = q.T; R.s_T(k) = q.s_T; R.lli(k) = q.lli; R.s_lli(k) = q.s_lli;
R.rf(k) = q.rf; R.s_rf(k) = q.s_rf; R.xs_sep(k) = q.xs_sep; R.nis(k) = nis; R.proj(k) = proj; R.wall(k) = wall;
end

function tc = tconv(t, ok)
% thoi diem som nhat ma tu do ve sau dieu kien luon dung
last_bad = find(~ok, 1, 'last');
if isempty(last_bad), tc = 0; elseif last_bad == numel(t), tc = NaN; else, tc = t(last_bad + 1); end
end

function [nees, in3] = cons(e, s)
ok = isfinite(e) & isfinite(s) & s > 0;
nees = mean((e(ok)./s(ok)).^2);
in3 = 100*mean(abs(e(ok)) <= 3*s(ok));
end

function v = rmsv(e)
e = e(isfinite(e)); v = sqrt(mean(e.^2));
end

function v = qtl(e, p)
e = sort(e(isfinite(e))); v = e(max(1, ceil(p*numel(e))));
end

function band(x, m, d)
fill([x; flipud(x)], [m - d; flipud(m + d)], [0.8 0.85 1], 'EdgeColor', 'none'); hold on; plot(x, m, 'b');
end
