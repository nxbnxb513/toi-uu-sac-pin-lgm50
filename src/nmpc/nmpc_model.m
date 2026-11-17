function [model, nh] = nmpc_model(rom, par, name, eps_cost, E)
%NMPC_MODEL  Mo hinh acados cua bai toan NMPC: ODE THUAN (bien dai so z da khu
% trong ham dong luc bang Newton sinh ma cua CasADi, rom_elim.m - quyet dinh
% nguoi dung 17/11/2026, phuong an (a)). Cung phuong trinh voi ROM DAE.
% Dung chung cho bo giai OCP (nmpc_build.m) va bo tich phan kiem tra.
%   Trang thai X = [x_ROM; I_ch; t_f], dieu khien u = dI_ch/dtau.
%   Ham muc tieu: lithium mat VINH VIEN = SEI + lithium chet (quyet dinh 17/11/2026);
%   lithium ma thuan nghich khong vao ham muc tieu, ma bi chan boi eta_Li,sep >= delta.
import casadi.*
if nargin < 5 || isempty(E), E = rom_elim(rom, par); end
nx = rom.nx; nX = nx + 2;
x  = MX.sym('x', nx); Ich = MX.sym('Ich'); tf = MX.sym('tf_h');
X  = [x; Ich; tf]; Xd = MX.sym('Xdot', nX);
u  = MX.sym('u'); p = MX.sym('p', 8);
Ta = p(1); soc_t = p(2); bud = p(3); wl = p(4); wd = p(5); Tmax = p(6); dlt = p(7); xsm = p(8);
[fx, ov] = E.sym(x, -Ich, Ta);
V = ov(1); T = ov(2); xs_sep = ov(4); eta_sep = ov(6);
model = AcadosModel();
model.name = name;
model.x = X; model.xdot = Xd; model.u = u; model.p = p;
fe = [3600*tf*fx; u; 0];
model.f_expl_expr = fe;
model.f_impl_expr = Xd - fe;
loss = x(rom.ix.nsei) + x(rom.ix.ndl);           % mAh, mat vinh vien du doan
model.cost_y_expr_0 = sqrt(wd)*u;
model.cost_y_expr   = sqrt(wd)*u;
model.cost_y_expr_e = sqrt(rom_smax(wl*loss, 0, 1e-3) + eps_cost);
hpath = [V - v_limit(par); T - Tmax; dlt - eta_sep; xs_sep - xsm; tf - bud];
model.con_h_expr   = hpath;
model.con_h_expr_e = [soc_t - x(rom.ix.soc); tf - bud; V - v_limit(par); dlt - eta_sep; xs_sep - xsm];
nh = numel(hpath);
end
