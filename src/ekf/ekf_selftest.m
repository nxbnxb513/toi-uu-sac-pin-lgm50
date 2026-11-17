function ekf_selftest(outdir)
%EKF_SELFTEST  Kiem tra thanh phan cua EKF truoc khi chay cac phep thu:
%  1. Voi rf = 1, phuong trinh do cua EKF trung dau ra cua ROM NMPC (rom_model.m)
%  2. Du doan (khong cap nhat) cua EKF = mo phong ROM bang ode15s (rom_sim.m),
%     sac 1C 600 s tu SOC 0.2, 25 degC: hai bo tich phan cung mot mo hinh
%  3. Jacobian A = dx+/dx, dx+/dp (CasADi) so voi sai phan huu han
%  4. Jacobian do H so voi sai phan huu han
%  5. Thoi gian moi buoc: 'collocation' va 'idas'
% Loi lon -> error (job CI do).
if nargin < 1, outdir = 'results/ekf'; end
if ~exist(outdir, 'dir'), mkdir(outdir); end
fid = fopen(fullfile(outdir, 'ekf_selftest.md'), 'w');
par = dfn_params();
tb = tic; E = ekf_build(par); tB = toc(tb);
rom = E.rom; ix = E.ix; Ta = 298.15; I = -par.Qnom;
p('# Tu kiem tra EKF\n\n- ROM cau hinh %s: %d trang thai, %d dai so; trang thai bo loc %d (+ rf). Tao ham CasADi: %.1f s\n', E.cfg, E.nx, E.nz, E.na, tB);
c = ekf_config('lab');
y0 = dfn_state_soc(par, 0.2, Ta);
yc = dfn_consistent_init(0, y0, par, struct('mode', 'I', 'value', I, 'Tamb', Ta));
[x0, zg] = rom_from_dfn(rom, par, yc);
% 1. phuong trinh do
M = rom_model(rom, par);
[z0, ok] = rom_solve_z(M, x0, I, Ta, zg); assert(ok);
o = full(M.out([x0; z0], I, Ta));
hv = full(E.Hf(x0, z0, I, Ta, 1));
d1 = max(abs(hv - o([M.iout.V; M.iout.T])));
ze = ekf_solve_z(E, x0, I, Ta, 1);
p('- 1. Phuong trinh do EKF (rf = 1) vs rom_model: lech %.2e (V, K); z: lech %.2e\n', d1, max(abs(ze - z0)));
assert(d1 < 1e-10, 'phuong trinh do lech ROM');
% 2. du doan vs rom_sim
tout = (0:5:600).';
Rr = rom_sim(M, rom, x0, z0, I, Ta, tout, struct('sat', false));
for integ = {'collocation', 'idas'}
    if strcmp(integ{1}, 'collocation'), Ei = E; else
        try
            tb = tic; Ei = ekf_build(par, struct('integrator', 'idas')); p('- tao ham IDAS: %.1f s\n', toc(tb));
        catch err
            p('- IDAS: khong tao duoc (%s)\n', err.message); continue
        end
    end
    xa = [x0; 1]; P = eye(Ei.na)*1e-6; dV = 0; dx = 0;
    tw = tic;
    try
    for k = 2:numel(tout)
        [xa, P] = ekf_step(Ei, xa, P, struct('I0', I, 'I1', I, 'dt', 5, 'Tamb', Ta), [], c);
        j = find(abs(Rr.t - tout(k)) < 1e-9, 1);
        if ~isempty(j)
            dx = max(dx, max(abs(xa(Ei.fi) - Rr.Y(Ei.fi, j))));
            zz = ekf_solve_z(Ei, xa(1:Ei.nx), I, Ta, 1);
            h = full(Ei.Hf(xa(1:Ei.nx), zz, I, Ta, 1));
            dV = max(dV, abs(h(1) - Rr.V(j)));
        end
    end
    catch err
        p('- 2. %s: loi khi du doan (%s)\n', integ{1}, err.message);
        if strcmp(integ{1}, 'collocation'), rethrow(err); else, continue; end
    end
    tstep = toc(tw)/(numel(tout) - 1);
    p('- 2. Du doan EKF (%s, buoc 5 s, %d khoang con) vs rom_sim (ode15s, RelTol 1e-6), sac 1C 600 s: max lech trang thai bo loc %.2e, V %.3f mV; %.0f ms/buoc (gom Jacobian + hiep phuong sai)\n', ...
        integ{1}, Ei.nfe, dx, 1e3*dV, 1e3*tstep);
    if strcmp(integ{1}, 'collocation'), assert(dV < 0.5e-3, 'du doan EKF lech ROM > 0.5 mV'); xa_c = xa; end
end
xa = xa_c;
% 3. Jacobian buoc du doan
x1 = xa(1:E.nx);
zz = ekf_solve_z(E, x1, I, Ta, 1);
pv = [I; Ta; 1; 5];
[xf, ~, Jx, Jp] = E.FJ(x1, zz, pv); xf = full(xf); Jx = full(Jx); Jp = full(Jp);
cols = [ix.thn(end); ix.thn(5); ix.thp(end); ix.ce(3); ix.T];
err = 0;
for cidx = cols.'
    hstep = 1e-6*max(1, abs(x1(cidx)));
    xp = x1; xp(cidx) = xp(cidx) + hstep; xm = x1; xm(cidx) = xm(cidx) - hstep;
    fd = (full(E.F(xp, zz, pv)) - full(E.F(xm, zz, pv)))/(2*hstep);
    err = max(err, norm(fd - Jx(:, cidx), inf)/max(norm(Jx(:, cidx), inf), 1e-12));
end
for pj = [1 3]
    hstep = 1e-6*max(1, abs(pv(pj)));
    pp = pv; pp(pj) = pp(pj) + hstep; pm = pv; pm(pj) = pm(pj) - hstep;
    fd = (full(E.F(x1, zz, pp)) - full(E.F(x1, zz, pm)))/(2*hstep);
    err = max(err, norm(fd - Jp(:, pj), inf)/max(norm(Jp(:, pj), inf), 1e-12));
end
p('- 3. Jacobian du doan (CasADi) vs sai phan trung tam: lech tuong doi lon nhat %.2e (cot: be mat/trong hat am, be mat duong, c_e, T, dong, rf)\n', err);
assert(err < 1e-3, 'Jacobian du doan sai');
% 4. Jacobian do
[~, hx, hz, hrf, ~, ~, gx, gz, grf] = E.Hf(x1, zz, I, Ta, 1);
H = [full(hx(:, E.fi)), full(hrf)] + full(hz)*(-full(gz)\[full(gx(:, E.fi)), full(grf)]);
err = 0;
for j = [find(E.fi == ix.thn(end)), find(E.fi == ix.thp(end)), find(E.fi == ix.T), E.na]
    hstep = 1e-6;
    xp = [x1; 1]; xm = xp;
    if j <= E.nf, xp(E.fi(j)) = xp(E.fi(j)) + hstep; xm(E.fi(j)) = xm(E.fi(j)) - hstep; else, xp(end) = xp(end) + hstep; xm(end) = xm(end) - hstep; end
    hp = full(E.Hf(xp(1:E.nx), ekf_solve_z(E, xp(1:E.nx), I, Ta, xp(end)), I, Ta, xp(end)));
    hm = full(E.Hf(xm(1:E.nx), ekf_solve_z(E, xm(1:E.nx), I, Ta, xm(end)), I, Ta, xm(end)));
    fd = (hp - hm)/(2*hstep);
    err = max(err, norm(fd - H(:, j), inf)/max(norm(H(:, j), inf), 1e-12));
end
p('- 4. Jacobian do H = h_x - h_z g_z^-1 g_x vs sai phan: lech tuong doi lon nhat %.2e\n', err);
assert(err < 1e-4, 'Jacobian do sai');
p('- dV/d(rf) = %.3f mV tren 1 don vi rf o 1C (do nhay cua dien ap voi dien tro mang)\n', 1e3*H(1, end));
fclose(fid);
type(fullfile(outdir, 'ekf_selftest.md'));

    function p(varargin)
        fprintf(fid, varargin{:});
    end
end
