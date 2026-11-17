function rom_validate(Tc, dirn, outdir, cfg)
%ROM_VALIDATE  So sanh ROM voi DFN day du: dong khong doi 0.3C, 1C, 2C.
%   rom_validate(25, 'charge', 'results')     sac tu SOC 0 toi khi DFN dung
%   rom_validate(10, 'discharge', 'results')  xa tu SOC 1 toi 2.5 V
% Ca hai mo hinh bat dau tu CUNG trang thai (ROM = anh xa cua trang thai DFN).
% Dieu kien dung giong nhau: V cham 4.2 V (sac) / 2.5 V (xa), hoac stoich be
% mat hat cham 1e-4 / 1 - 1e-4 (su kien cua dfn_events.m, GD-16).
% Bao cao (tren khoang thoi gian chung): sai so dien ap, stoich be mat cuc am
% phia mang ngan, phi_s - phi_e phia mang ngan, the ma lithium phia mang ngan,
% nhiet do; lao hoa tam thoi tich luy; thoi gian chay. Ghi CSV + md + hinh.
if nargin < 3, outdir = 'results'; end
if nargin < 4, cfg = 'A'; end
if ~exist(outdir, 'dir'), mkdir(outdir); end
par = dfn_params(); rom = rom_setup(par, cfg);
tg = tic; M = rom_model(rom, par); tbuild = toc(tg);
Ta = Tc + 273.15;
rates = [0.3 1 2];
tag = sprintf('%s_%dC_%s', dirn, Tc, cfg);
fid = fopen(fullfile(outdir, ['rom_validate_' tag '.md']), 'w');
p('# ROM (cau hinh %s) so voi DFN: %s, %d degC\n\n', cfg, dirn, Tc);
p('Tao ham CasADi cua ROM: %.1f s. ROM: %d trang thai vi phan + %d dai so; DFN: %d + %d.\n\n', tbuild, rom.nx, rom.nz, par.ix.nd, par.ix.ny - par.ix.nd);
p('| C-rate | ly do dung DFN / ROM | t cuoi DFN / ROM (s) | Q DFN / ROM (Ah) | V RMS / max (mV) | xs_sep RMS / max (-) | phi_s-phi_e sep RMS / max (mV) | eta_Li sep RMS / max (mV) | T max (K) | SEI DFN / ROM (uAh) | ma Li DFN / ROM (uAh) | chay DFN / ROM (s) |\n');
p('|---|---|---|---|---|---|---|---|---|---|---|---|\n');
hdr = 'cfg,dir,Tamb_C,crate,reason_dfn,reason_rom,tend_dfn,tend_rom,Q_dfn,Q_rom,V_rms_mV,V_max_mV,xs_rms,xs_max,dphi_rms_mV,dphi_max_mV,eta_rms_mV,eta_max_mV,T_max_K,sei_dfn_uAh,sei_rom_uAh,pl_dfn_uAh,pl_rom_uAh,wall_dfn_s,wall_rom_s,map_V_max_mV,map_dphi_max_mV';
rows = {};
fig = figure('Visible', 'off', 'Position', [0 0 1400 900]);
for ir = 1:numel(rates)
    cr = rates(ir);
    if strcmp(dirn, 'charge')
        soc0 = 0; I = -cr*par.Qnom; stopD = struct('Vmax', par.Vmax); stopR = struct('Vmax', par.Vmax);
    else
        soc0 = 1; I = cr*par.Qnom; stopD = struct('Vmin', par.Vmin); stopR = struct('Vmin', par.Vmin);
    end
    tmax = 1.15*3600/cr;
    dt = max(2, round(tmax/1500));
    tout = (0:dt:tmax).';
    y0 = dfn_state_soc(par, soc0, Ta);
    % ---- DFN ----
    st = struct('mode', 'I', 'value', I, 'tmax', tmax, 'Tamb', Ta, 'stop', stopD, 'tout', tout);
    snap = linspace(0.1, 0.9, 5)*tmax;
    tic; [D, ~] = plant_run(par, y0, st, aging_track('init', par), struct('dt', dt, 'snap', snap)); wD = toc;
    % ---- ROM (cung trang thai dau) ----
    yc = dfn_consistent_init(0, y0, par, struct('mode', 'I', 'value', I, 'Tamb', Ta));
    [x0, z0] = rom_from_dfn(rom, par, yc);
    tic; R = rom_sim(M, rom, x0, z0, I, Ta, tout, stopR); wR = toc;
    % ---- sai so tren khoang chung ----
    tc = min(D.t(end), R.t(end));
    k = tout <= tc + 1e-9;
    tk = tout(k);
    e = @(fd, fr) interp1(uniq(R.t), fr(iu(R.t)), tk) - interp1(uniq(D.t), D.(fd)(iu(D.t)), tk);
    dV = e('V', R.V); dX = e('xs_sep', R.xs_sep); dP = e('dphi_sep', R.dphi_sep);
    dE = e('eta_sep', R.eta_sep); dT = e('T', R.T);
    % sai so tuc thoi cua phep anh xa (ROM tinh tai trang thai DFN da anh xa)
    mV = 0; mP = 0;
    for js = 1:numel(D.tsnap)
        ys = D.Ysnap(:, js);
        [~, as] = dfn_rhs(0, ys, par, struct('mode', 'I', 'value', I, 'Tamb', Ta));
        [xs, zs0] = rom_from_dfn(rom, par, ys);
        [zs, oks] = rom_solve_z(M, xs, I, Ta, zs0);
        if oks
            os = full(M.out([xs; zs], I, Ta));
            mV = max(mV, abs(os(M.iout.V) - as.V)); mP = max(mP, abs(os(M.iout.dphi_sep) - as.dphi_n(end)));
        end
    end
    QD = -(D.Q(end)); QR = (R.soc(end) - soc0)*rom.Csoc;
    if strcmp(dirn, 'discharge'), QD = D.Q(end); QR = -QR; end
    nseiR = R.nsei(end); nplR = R.npl(end);
    v = {cr, [D.reason{end} ' / ' R.reason], sprintf('%.0f / %.0f', D.t(end), R.t(end)), sprintf('%.4f / %.4f', QD, QR), ...
        sprintf('%.2f / %.2f', 1e3*rmsv(dV), 1e3*max(abs(dV))), sprintf('%.4f / %.4f', rmsv(dX), max(abs(dX))), ...
        sprintf('%.2f / %.2f', 1e3*rmsv(dP), 1e3*max(abs(dP))), sprintf('%.2f / %.2f', 1e3*rmsv(dE), 1e3*max(abs(dE))), ...
        sprintf('%.3f', max(abs(dT))), sprintf('%.3f / %.3f', 1e3*D.nsei(end), 1e3*nseiR), sprintf('%.3f / %.3f', 1e3*D.npl(end), 1e3*nplR), ...
        sprintf('%.1f / %.1f', wD, wR)};
    p('| %.1fC | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s |\n', v{:});
    rows{end+1} = sprintf('%s,%s,%d,%.2f,%s,%s,%.1f,%.1f,%.5f,%.5f,%.3f,%.3f,%.5f,%.5f,%.3f,%.3f,%.3f,%.3f,%.4f,%.5f,%.5f,%.5f,%.5f,%.2f,%.2f,%.3f,%.3f', ...
        cfg, dirn, Tc, cr, D.reason{end}, R.reason, D.t(end), R.t(end), QD, QR, 1e3*rmsv(dV), 1e3*max(abs(dV)), rmsv(dX), max(abs(dX)), ...
        1e3*rmsv(dP), 1e3*max(abs(dP)), 1e3*rmsv(dE), 1e3*max(abs(dE)), max(abs(dT)), 1e3*D.nsei(end), 1e3*nseiR, 1e3*D.npl(end), 1e3*nplR, wD, wR, 1e3*mV, 1e3*mP); %#ok<AGROW>
    % ---- hinh ----
    sub = @(r, c) subplot(3, 4, (r - 1)*4 + c);
    sub(ir, 1); plot(D.t, D.V, 'k', R.t, R.V, 'r--'); ylabel(sprintf('%.1fC: V', cr)); grid on;
    if ir == 1, legend('DFN', 'ROM', 'Location', 'best'); title('Dien ap (V)'); end
    sub(ir, 2); plot(D.t, D.xs_sep, 'k', R.t, R.xs_sep, 'r--'); grid on; if ir == 1, title('x_{s} cuc am, phia mang ngan'); end
    sub(ir, 3); plot(D.t, 1e3*D.eta_sep, 'k', R.t, 1e3*R.eta_sep, 'r--'); grid on; if ir == 1, title('\eta_{Li} phia mang ngan (mV)'); end
    sub(ir, 4); plot(D.t, D.T - 273.15, 'k', R.t, R.T - 273.15, 'r--'); grid on; if ir == 1, title('T (degC)'); end
end
p('\nSai so tuc thoi cua phep anh xa trang thai (5 thoi diem moi lan chay, ROM tinh tai trang thai DFN da anh xa): xem cot map_* trong CSV.\n');
p('xs_sep, phi_s - phi_e, eta_Li: tai nut DFN cuc am sat mang ngan nhat va o ROM cuoi cuc am (cung tam x). eta_Li = phi_s - phi_e - rho_SEI L_SEI j.\n');
p('SEI, ma Li: lao hoa TAM THOI tich luy trong lan chay (aging_rates.m; DFN: hau kiem tren quy dao; ROM: trang thai cua ROM).\n');
fclose(fid);
saveas(fig, fullfile(outdir, ['rom_validate_' tag '.png']));
f2 = fopen(fullfile(outdir, ['rom_validate_' tag '.csv']), 'w');
fprintf(f2, '%s\n', hdr); fprintf(f2, '%s\n', rows{:}); fclose(f2);
fprintf('\nROM VALIDATE %s: XONG\n', tag);

    function p(varargin)
        fprintf(varargin{:}); fprintf(fid, varargin{:});
    end
end

function v = rmsv(x)
v = sqrt(mean(x.^2));
end

function t = uniq(t)
[t, ~] = unique(t, 'last');
end

function i = iu(t)
[~, i] = unique(t, 'last');
end
