function M = rom_model(rom, par)
%ROM_MODEL  Tao cac ham CasADi cua ROM tu bieu thuc ky hieu rom_equations.m.
% Cung bieu thuc nay duoc dung trong acados (nmpc_build.m) va de mo phong ROM
% trong MATLAB (rom_sim.m) - mot nguon duy nhat.
%   M.dae(y, I, Tamb)  -> [dx/dt; g]   voi y = [x; z]
%   M.jac(y, I, Tamb)  -> d[dx/dt; g]/dy (thua)
%   M.out(y, I, Tamb)  -> [V; T; soc; xs_sep; dphi_sep; eta_sep; xsn (Nn); xsp (Np)]
%   M.G(z, [x; I; Tamb]), M.Gz(...)  rang buoc dai so va Jacobian theo z (rom_solve_z.m)
import casadi.*
x = SX.sym('x', rom.nx); z = SX.sym('z', rom.nz); I = SX.sym('I'); Ta = SX.sym('Tamb');
[fx, g, o] = rom_equations(rom, par, x, z, I, Ta);
y = [x; z];
M.dae = Function('rom_dae', {y, I, Ta}, {[fx; g]});
M.jac = Function('rom_jac', {y, I, Ta}, {jacobian([fx; g], y)});
outv = [o.V; o.T; o.soc; o.xs_sep; o.dphi_sep; o.eta_sep; o.xsn; o.xsp];
M.out = Function('rom_out', {y, I, Ta}, {outv});
M.iout.V = 1; M.iout.T = 2; M.iout.soc = 3; M.iout.xs_sep = 4; M.iout.dphi_sep = 5; M.iout.eta_sep = 6;
M.iout.xsn = 6 + (1:rom.Nn).'; M.iout.xsp = 6 + rom.Nn + (1:rom.Np).';
M.diag = Function('rom_diag', {y, I, Ta}, {o.dphi, o.etapl, o.rsei, o.jpl, o.q, o.phie, o.phisn, o.phisp});
pz = [x; I; Ta];
G = Function('rom_G', {z, pz}, {g});
M.G = G;
M.Gz = Function('rom_Gz', {z, pz}, {jacobian(g, z)});
M.nx = rom.nx; M.nz = rom.nz;
M.E = rom_elim(rom, par);   % cung mo hinh, z da khu (ODE thuan) - dung cho acados
end
