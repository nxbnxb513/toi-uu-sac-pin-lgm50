function rom_unit_tests(outdir, cfg)
%ROM_UNIT_TESTS  Kiem tra tung thanh phan cua ROM so voi ham DFN (src/dfn):
%  1. rom_elyte  vs dfn_elyte  (cung cong thuc, chi khac min tron)
%  2. rom_rhocp  vs dfn_rhocp
%  3. rom_dK (cau phuong Gauss-Legendre) vs dfn_Kint (bang Kirchhoff cua DFN)
%  4. trang thai nghi: anh xa DFN -> ROM, dien ap ho mach va dao ham ~ 0
%  5. bao toan lithium cua phep anh xa
% Loi -> error (job CI do).
if nargin < 1, outdir = 'results'; end
if nargin < 2, cfg = 'A'; end
if ~exist(outdir, 'dir'), mkdir(outdir); end
fid = fopen(fullfile(outdir, ['rom_unit_tests_' cfg '.md']), 'w');
par = dfn_params(); rom = rom_setup(par, cfg);
p('# Kiem tra thanh phan ROM (cau hinh %s)\n\n', cfg);
p('- ROM: cuc am %d o %s (so o DFN), mang ngan %d o, cuc duong %d o; vo hat am %d %s, duong %d %s (don vi R/Nr DFN)\n', ...
    rom.Nn, mat2str(rom.cellsn), rom.Ns, rom.Np, rom.Nrn, mat2str(rom.shn), rom.Nrp, mat2str(rom.shp));
p('- So trang thai vi phan %d, dai so %d (DFN: %d vi phan, %d dai so)\n', rom.nx, rom.nz, par.ix.nd, par.ix.ny - par.ix.nd);
p('- Tam o ROM cuoi cuc am: x = %.4e m; tam nut DFN sat mang ngan: x = %.4e m\n', rom.xc(rom.Nn), par.grid.xc(par.grid.Nn));
assert(abs(rom.xc(rom.Nn) - par.grid.xc(par.grid.Nn)) < 1e-12, 'vi tri phia mang ngan khong trung');

% 1. dien giai
ce = [50 300 1000 1500 2500 3500].'; err = 0;
for T = [263.15 283.15 298.15 318.15]
    [a1, b1, c1, d1] = dfn_elyte(ce, T, par); [a2, b2, c2, d2] = rom_elyte(ce, T, par);
    err = max([err; abs(a2 - a1)./abs(a1); abs(b2 - b1)./abs(b1); abs(c2 - c1)./abs(c1); abs(d2 - d1)./abs(d1)]);
end
p('- 1. rom_elyte vs dfn_elyte: sai lech tuong doi lon nhat %.2e\n', err);
assert(err < 1e-8, 'rom_elyte lech dfn_elyte');
% 2. nhiet dung
ag = dfn_aging_state(par, []); err = 0;
for T = [263.15 283.15 298.15 318.15]
    err = max(err, abs(rom_rhocp(par, T, rom.eps_region) - dfn_rhocp(par, T, ag))/dfn_rhocp(par, T, ag));
end
p('- 2. rom_rhocp vs dfn_rhocp: sai lech tuong doi lon nhat %.2e\n', err);
assert(err < 1e-12, 'rom_rhocp lech dfn_rhocp');
% 3. tich phan Kirchhoff
pr = [0.03 0.05; 0.1 0.2; 0.19 0.22; 0.5 0.6; 0.55 0.65; 0.8 0.9; 0.88 0.92; 0.9 0.99; 0.5 0.5005];
p('- 3. rom_dK (%d diem Gauss-Legendre) vs dfn_Kint (bang Kirchhoff DFN):\n\n| cuc | [a, b] | T (K) | DFN (m2/s) | ROM (m2/s) | lech tuong doi |\n|---|---|---|---|---|---|\n', rom.ngl);
emax = 0;
for el = {'neg', 'pos'}
    E = par.(el{1});
    for T = [283.15 298.15]
        for i = 1:size(pr, 1)
            d1 = dfn_Kint(E, pr(i,2), T, par) - dfn_Kint(E, pr(i,1), T, par);
            d2 = rom_dK(E, pr(i,1), pr(i,2), T, par, rom.gl);
            e = abs(d2 - d1)/abs(d1); emax = max(emax, e);
            p('| %s | [%.4f, %.4f] | %.2f | %.4e | %.4e | %.2e |\n', el{1}, pr(i,1), pr(i,2), T, d1, d2, e);
        end
    end
end
p('\n  Lech lon nhat %.2e (bang DFN noi suy pchip tren luoi 1e-4; ca hai la xap xi cua cung tich phan).\n', emax);
% 4, 5. trang thai nghi
M = rom_model(rom, par);
p('\n- 4-5. Trang thai nghi (DFN tai SOC, anh xa sang ROM, I = 0):\n\n| SOC | T (C) | OCV DFN (V) | V ROM (V) | lech (mV) | max abs(dx/dt) ROM | Li pha ran DFN / ROM (mol) | Li dien giai DFN / ROM (mol) |\n|---|---|---|---|---|---|---|---|\n');
for soc = [0.05 0.5 0.95]
    for Tc = [10 25]
        Ta = Tc + 273.15;
        y = dfn_state_soc(par, soc, Ta);
        ctl = struct('mode', 'I', 'value', 0, 'Tamb', Ta);
        y = dfn_consistent_init(0, y, par, ctl);
        [~, a] = dfn_rhs(0, y, par, ctl);
        [x, z0] = rom_from_dfn(rom, par, y);
        [z, ok] = rom_solve_z(M, x, 0, Ta, z0);
        assert(ok, 'rom_solve_z khong hoi tu o trang thai nghi');
        o = full(M.out([x; z], 0, Ta)); fx = full(M.dae([x; z], 0, Ta));
        [nsD, neD] = li_dfn(par, y); [nsR, neR] = li_rom(rom, par, x);
        p('| %.2f | %d | %.5f | %.5f | %.3f | %.2e | %.6f / %.6f | %.6f / %.6f |\n', soc, Tc, a.V, o(M.iout.V), 1e3*(o(M.iout.V) - a.V), ...
            max(abs(fx(1:rom.nx))), nsD, nsR, neD, neR);
        assert(abs(o(M.iout.V) - a.V) < 1e-6, 'OCV ROM lech DFN');
        assert(abs(nsR - nsD) < 1e-9*nsD && abs(neR - neD) < 1e-9*neD, 'anh xa khong bao toan lithium');
    end
end
% 6. OCP cua ROM trung DFN mac dinh khi sac va khi xa (logic nhanh / hysteresis)
y = dfn_state_soc(par, 0.5, 298.15); err = 0;
for I = [-10 -1 -0.01 0 0.01 5]
    ctl = struct('mode', 'I', 'value', I, 'Tamb', 298.15);
    yc = dfn_consistent_init(0, y, par, ctl);
    [~, a] = dfn_rhs(0, yc, par, ctl);
    xn = min(max(a.thsn, 1e-8), 1 - 1e-8); xp = min(max(a.thsp, 1e-8), 1 - 1e-8);
    [Un, Up] = rom_ocp(par, xn, xp, I/par.A, a.T);
    err = max([err; abs(Un - a.Un); abs(Up - a.Up)]);
end
p('\n- 6. rom_ocp so voi aux.Un, aux.Up cua dfn_rhs (I = -10 ... 5 A): lech lon nhat %.2e V\n', err);
assert(err < 1e-12, 'OCP cua ROM khac logic OCP cua DFN mac dinh');
fclose(fid);
fprintf('\nROM UNIT TESTS: DAT\n');

    function p(varargin)
        fprintf(varargin{:}); fprintf(fid, varargin{:});
    end
end

function [ns, ne] = li_dfn(par, y)
g = par.grid; ix = par.ix; ag = dfn_aging_state(par, y);
thn = reshape(y(ix.thn), g.Nrn, g.Nn); thp = reshape(y(ix.thp), g.Nrp, g.Np);
xn = (g.Vshn.'*thn)/sum(g.Vshn); yp = (g.Vshp.'*thp)/sum(g.Vshp);
ns = par.A*(sum(xn.'.*ag.as_n/3*par.neg.Rp*g.dxn)*par.neg.cmax + sum(yp.'.*ag.as_p/3*par.pos.Rp*g.dxp)*par.pos.cmax);
ne = par.A*sum(ag.eps.*g.dx.*y(ix.ce))*par.ce_ref;
end

function [ns, ne] = li_rom(rom, par, x)
thn = reshape(x(rom.ix.thn), rom.Nrn, rom.Nn); thp = reshape(x(rom.ix.thp), rom.Nrp, rom.Np);
xn = (rom.Vshn.'*thn)/sum(rom.Vshn); yp = (rom.Vshp.'*thp)/sum(rom.Vshp);
ns = par.A*(sum(xn.'*rom.as_n/3*par.neg.Rp.*rom.dx(rom.in))*par.neg.cmax + sum(yp.'*rom.as_p/3*par.pos.Rp.*rom.dx(rom.ip))*par.pos.cmax);
ne = par.A*sum(rom.eps.*rom.dx.*x(rom.ix.ce))*par.ce_ref;
end
