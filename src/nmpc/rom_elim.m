function E = rom_elim(rom, par)
%ROM_ELIM  ROM voi bien dai so z DA KHU: z(x, I) la nghiem cua g(x, z, I) = 0
% tinh bang Newton cua CasADi ('fast_newton', sinh ma C duoc) ngay trong ham
% dong luc => ODE thuan  dx/dt = f(x, z(x, I), I). CUNG phuong trinh
% rom_equations.m, khong bo gi. Ly do: acados v0.6 khong cho tim kiem duong khi
% rang buoc phu thuoc z, va do nhay cua IRK cho DAE nay sinh NaN (mo_hinh_rut_gon.md muc 8, 9).
%   E.ode(x, I, Tamb) -> dx/dt;  E.out(x, I, Tamb) -> [V; T; soc; xs_sep; dphi_sep; eta_sep; xsn; xsp]
%   E.jac(x, I, Tamb) -> d(dx/dt)/dx;  E.zfun(x, I, Tamb) -> z;  E.sym(x, I, Ta) -> {f, out} (MX)
import casadi.*
nx = rom.nx; nz = rom.nz;
xs = SX.sym('x', nx); zs = SX.sym('z', nz); Is = SX.sym('I'); Ts = SX.sym('Ta');
[fx, g, o] = rom_equations(rom, par, xs, zs, Is, Ts);
outv = [o.V; o.T; o.soc; o.xs_sep; o.dphi_sep; o.eta_sep; o.xsn; o.xsp];
E.Fsx = Function('rom_fz', {xs, zs, Is, Ts}, {fx, outv});
pz = [xs; Is; Ts];
G = Function('rom_Gz', {zs, pz}, {g});
E.ZG = Function('rom_zg', {pz}, {rom_zguess(rom, par, xs, Is, Ts)});
E.rf = rootfinder('rom_rf', 'fast_newton', G, struct('abstol', 1e-10, 'abstolStep', 1e-14, ...
    'max_iter', 30, 'linear_solver', 'qr'));
x = MX.sym('x', nx); I = MX.sym('I'); Ta = MX.sym('Ta');
[f, ov, z] = elim_sym(x, I, Ta);
E.ode  = Function('rom_ode', {x, I, Ta}, {f});
E.out  = Function('rom_oute', {x, I, Ta}, {ov});
E.jac  = Function('rom_odejac', {x, I, Ta}, {jacobian(f, x)});
E.zfun = Function('rom_zfun', {x, I, Ta}, {z});
E.sym  = @elim_sym;

    function [f, ov, z] = elim_sym(x, I, Ta)
        p = [x; I; Ta];
        z = E.rf(E.ZG(p), p);
        [f, ov] = E.Fsx(x, z, I, Ta);
    end
end
