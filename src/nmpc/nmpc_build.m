function C = nmpc_build(rom, par, opt)
%NMPC_BUILD  Tao bo giai NMPC (acados, mot lan moi job) tren mo hinh rut gon.
%
% Bai toan toi uu (thoi gian chuan hoa tau in [0, 1], thoi gian sac con lai
% t_f la TRANG THAI tu do, khong co dinh o nut dau):
%   trang thai X = [x_ROM; I_ch; t_f],  dieu khien u = dI_ch/dtau  [A]
%   dx_ROM/dtau = 3600 t_f f_ROM(x_ROM, z(x_ROM, I), I = -I_ch)   (t_f tinh bang gio;
%                 z(x, I): nghiem g = 0 bang Newton sinh ma, rom_elim.m => ODE thuan)
%   dI_ch/dtau = u,  dt_f/dtau = 0
%   min   0.5 w_loss (n_SEI(1) + n_dl(1))  +  0.5 w_dI int u^2 dtau
%         (n_SEI, n_dl: lithium mat VINH VIEN du doan do SEI va lithium chet [mAh],
%          dat ve 0 o moi lan giai; lithium ma thuan nghich KHONG vao muc tieu)
%   v.d.k. 0 <= I_ch <= I_max (cung), va (mem, phat L1 + L2 lon):
%          V <= V_cv (v_limit.m), T <= T_max, eta_Li,sep >= delta, x_s,sep <= x_s,max,
%          t_f <= ngan sach con lai;   cuoi: SOC >= SOC_dich, t_f <= ngan sach, V, eta, x_s
% Ham muc tieu viet dang binh phuong toi thieu (NONLINEAR_LS) de dung
% Gauss-Newton: y_e = sqrt(w_loss (n_SEI + n_dl) + eps)  (n >= 0), y = sqrt(w_dI) u.
% Tham so acados p = [T_amb; SOC_dich; ngan sach (h); w_loss; w_dI; T_max; delta; x_s,max; lech V (GD-83)].
% Che do "ngan sach": ngan sach = k T_CCCV - t (thu hep dan); che do "khong
% gioi han": ngan sach = opt.tf_cap_h (chi la can so hoc, phai bao neu cham).
% Xem tai_lieu/mo_hinh_rut_gon.md muc 8.
import casadi.*
if nargin < 3, opt = struct(); end
d = struct('N', 20, 'Imax', 2*par.Qnom, 'tf_min_h', 10/3600, 'tf_cap_h', 20, 'eps_cost', 1e-3, ...
    'name', 'rom_nmpc', 'codegen_dir', fullfile(pwd, 'c_generated_code'), 'max_iter', 60, ...
    'num_stages', 2, 'num_steps', 8, 'lm', 1e-2, 'newton_iter', 8, 'newton_tol', 0, 'E', [], ...
    'globalization', 'MERIT_BACKTRACKING', 'jac_reuse', 0, 'tol_stat', 1e-6, 'tol_eq', 1e-7, ...
    'tol_ineq', 1e-7, 'tol_comp', 1e-7, 'max_iter_warm', 60, 'timeout', 0, 'eqI0', true);
fn = fieldnames(d);
for i = 1:numel(fn), if ~isfield(opt, fn{i}), opt.(fn{i}) = d.(fn{i}); end, end
nx = rom.nx; nX = nx + 2; iI = nx + 1; itf = nx + 2;
[model, nh] = nmpc_model(rom, par, opt.name, opt.eps_cost, opt.E);

ocp = AcadosOcp();
ocp.model = model;
ocp.cost.cost_type_0 = 'NONLINEAR_LS'; ocp.cost.cost_type = 'NONLINEAR_LS'; ocp.cost.cost_type_e = 'NONLINEAR_LS';
ocp.cost.W_0 = 1; ocp.cost.W = 1; ocp.cost.W_e = 1;
ocp.cost.yref_0 = 0; ocp.cost.yref = 0; ocp.cost.yref_e = 0;
% nut dau: co dinh x_ROM va I_ch (do/uoc luong), t_f tu do
ocp.constraints.idxbx_0 = 0:nx;
ocp.constraints.lbx_0 = zeros(nx + 1, 1); ocp.constraints.ubx_0 = zeros(nx + 1, 1);
% GD-86 (18/11/2026): I_ch tai nut 0 PHAI khai bao la dang thuc (idxbxe_0 = 0:nx). Ban
% 81a1682 bo I_ch khoi idxbxe_0 de lan giai dau de I_ch tu do; khi do moi lan giai sau
% (lb = ub = I_ch do duoc) HPIPM coi I_ch la bat dang thuc co do rong 0 -> phuong phap
% diem trong ket o buoc nho nhat (QP status 3 MINSTEP, acados status 4) o MOI lan giai.
if opt.eqI0, ocp.constraints.idxbxe_0 = 0:nx; else, ocp.constraints.idxbxe_0 = 0:nx-1; end
% bien cung: dong sac va t_f
ocp.constraints.idxbx = [iI - 1, itf - 1];
ocp.constraints.lbx = [0; opt.tf_min_h]; ocp.constraints.ubx = [opt.Imax; opt.tf_cap_h];
ocp.constraints.idxbx_e = [iI - 1, itf - 1];
ocp.constraints.lbx_e = [0; opt.tf_min_h]; ocp.constraints.ubx_e = [opt.Imax; opt.tf_cap_h];
ocp.constraints.idxbu = 0;
ocp.constraints.lbu = -opt.Imax*opt.N; ocp.constraints.ubu = opt.Imax*opt.N;
% rang buoc phi tuyen (mem) - viet dang h <= 0
ocp.constraints.lh = -1e4*ones(nh, 1); ocp.constraints.uh = zeros(nh, 1);
ocp.constraints.lh_e = -1e4*ones(5, 1); ocp.constraints.uh_e = zeros(5, 1);
ocp.constraints.idxsh = 0:nh-1;
ocp.constraints.idxsh_e = 0:4;
% phat vi pham: [V (V), T (K), eta (V), x_s (-), t_f (h)] - xem mo_hinh_rut_gon.md muc 8.4
zu = [1e4; 1e2; 1e4; 1e4; 1e2]; Zu = [1e5; 1e2; 1e5; 1e5; 1e2];
ocp.cost.zl = zu; ocp.cost.zu = zu; ocp.cost.Zl = Zu; ocp.cost.Zu = Zu;
zue = [1e3; 1e2; zu(1); zu(3); zu(4)]; Zue = [1e4; 1e2; Zu(1); Zu(3); Zu(4)];
ocp.cost.zl_e = zue; ocp.cost.zu_e = zue; ocp.cost.Zl_e = Zue; ocp.cost.Zu_e = Zue;
ocp.parameter_values = [298.15; 0.5; 1; 10; 1e-4; 318.15; 0.01; 0.99; 0];

so = ocp.solver_options;
so.N_horizon = opt.N; so.tf = 1;
so.integrator_type = 'IRK';
so.collocation_type = 'GAUSS_RADAU_IIA';
so.sim_method_num_stages = opt.num_stages;
so.sim_method_num_steps = opt.num_steps;
so.sim_method_newton_iter = opt.newton_iter;
so.sim_method_jac_reuse = opt.jac_reuse;   % 1: dung lai Jacobian Newton cua IRK trong mot buoc (nhanh hon)
if opt.newton_tol > 0, so.sim_method_newton_tol = opt.newton_tol; end
so.nlp_solver_type = 'SQP';
so.qp_solver = 'PARTIAL_CONDENSING_HPIPM';
so.hessian_approx = 'GAUSS_NEWTON';
so.globalization = opt.globalization;   % mo hinh la ODE thuan (z da khu) nen tim kiem duong dung duoc
so.nlp_solver_max_iter = opt.max_iter;
so.nlp_solver_tol_stat = opt.tol_stat; so.nlp_solver_tol_eq = opt.tol_eq;
so.nlp_solver_tol_ineq = opt.tol_ineq; so.nlp_solver_tol_comp = opt.tol_comp;
if opt.timeout > 0, so.timeout_max_time = opt.timeout; end   % s, gioi han thoi gian MOT lan giai
so.qp_solver_iter_max = 200;
% Levenberg-Marquardt nho lam on dinh QP (Hessian Gauss-Newton gan bang 0 vi
% muc tieu gan tuyen tinh); buoc SQP con duoc tim kiem duong (merit) gioi han.
so.levenberg_marquardt = opt.lm;
so.print_level = 0;
ocp.solver_options = so;
ocp.code_gen_options.code_export_directory = opt.codegen_dir;

t0 = tic;
C.solver = AcadosOcpSolver(ocp);
C.t_build = toc(t0);
C.ocp = ocp; C.opt = opt; C.rom = rom; C.nX = nX; C.iI = iI; C.itf = itf; C.N = opt.N;
C.ip = struct('Tamb', 1, 'soc_t', 2, 'bud', 3, 'wl', 4, 'wd', 5, 'Tmax', 6, 'dlt', 7, 'xsm', 8, 'vb', 9);
end
