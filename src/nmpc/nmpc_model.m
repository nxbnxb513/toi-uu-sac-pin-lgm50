function [model, nh] = nmpc_model(rom, par, name, eps_cost)
%NMPC_MODEL  Mo hinh acados (DAE an, co bien dai so z) cua bai toan NMPC,
% dung chung cho bo giai OCP (nmpc_build.m) va bo tich phan kiem tra
% (nmpc_sim_check.m). Xem nmpc_build.m cho y nghia cac bien.
import casadi.*
nx = rom.nx; nX = nx + 2;
x  = SX.sym('x', nx); Ich = SX.sym('Ich'); tf = SX.sym('tf_h');
X  = [x; Ich; tf]; Xd = SX.sym('Xdot', nX);
z  = SX.sym('z', rom.nz); u = SX.sym('u'); p = SX.sym('p', 8);
Ta = p(1); soc_t = p(2); bud = p(3); wl = p(4); wd = p(5); Tmax = p(6); dlt = p(7); xsm = p(8);
[fx, g, o] = rom_equations(rom, par, x, z, -Ich, Ta);
model = AcadosModel();
model.name = name;
model.x = X; model.xdot = Xd; model.u = u; model.z = z; model.p = p;
model.f_impl_expr = [Xd - [3600*tf*fx; u; 0]; g];
loss = x(rom.ix.nsei) + x(rom.ix.npl);
model.cost_y_expr_0 = sqrt(wd)*u;
model.cost_y_expr   = sqrt(wd)*u;
model.cost_y_expr_e = sqrt(rom_smax(wl*loss, 0, 1e-3) + eps_cost);   % >= 0 ca khi lap SQP lam loss hoi am
hpath = [o.V - par.Vmax; o.T - Tmax; dlt - o.eta_sep; o.xs_sep - xsm; tf - bud];
model.con_h_expr   = hpath;
model.con_h_expr_e = [soc_t - x(rom.ix.soc); tf - bud];
nh = numel(hpath);
end
