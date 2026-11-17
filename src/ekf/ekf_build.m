function E = ekf_build(par, opt)
%EKF_BUILD  Tao cac ham CasADi cho EKF tren mo hinh rut gon (ROM) cua NMPC.
%   E = ekf_build(par)            par = dfn_params() (bo 'approved')
%   E = ekf_build(par, opt)       opt.cfg ('D'), opt.dtmax (5 s), opt.nfe (5),
%                                 opt.integrator ('collocation' | 'idas')
%
% KHONG co phuong trinh vat ly nao o day: ve phai, rang buoc dai so va dai luong
% ra lay tu src/nmpc/rom_equations.m (cung ham voi NMPC), luoi tu rom_setup.m.
% Thay doi duy nhat: dien tro mang SEI R_film (rom.Rfilm_n va rom.ap.Rfilm, cung
% mot so trong ROM, = rho_SEI L_SEI) duoc thay bang bien ky hieu rf*R_film,BOL,
% de EKF uoc luong rf nhu mot tham so troi cham (Couto 2022 muc IV-C). Voi rf = 1
% mo hinh trung hoan toan ROM cua NMPC (kiem tra trong ekf_selftest.m).
%
% Trang thai bo loc (co hiep phuong sai): stoich trong hat (hai cuc), c_e, T, rf.
% Cac trang thai con lai cua ROM (bo dem SOC, c_Li, bo dem lao hoa) chi duoc
% truyen theo mo hinh: SOC tinh lai tu stoich cuc am sau moi buoc (GD-24),
% c_Li va bo dem lao hoa khong quan sat duoc tu V, T (khong hoi tiep, GD-31).
%
% Roi rac hoa thoi gian: tich phan DAE (x, z) tren mot buoc bang tich phan
% CasADi ('collocation': Radau IIA bac 3, opt.nfe khoang con / buoc; hoac
% 'idas'). Jacobian A = dx+/dx, dx+/dp la dao ham GIAI TICH (CasADi, dinh ly
% ham an qua bo giai Newton). Jacobian do H = h_x - h_z g_z^-1 g_x giai tich.
import casadi.*
if nargin < 2 || isempty(opt), opt = struct(); end
cfg   = gf(opt, 'cfg', 'D');
nfe   = gf(opt, 'nfe', 5);
integ = gf(opt, 'integrator', 'collocation');
E.dtmax = gf(opt, 'dtmax', 5);
rom = rom_setup(par, cfg);
E.rom = rom; E.par = par; E.cfg = cfg;
nx = rom.nx; nz = rom.nz; ix = rom.ix;
E.nx = nx; E.nz = nz;
E.Rf0 = rom.Rfilm_n;
if abs(rom.ap.Rfilm - rom.Rfilm_n) > 1e-15*abs(rom.Rfilm_n)
    error('ekf_build: R_film cua dong hoc va cua the ma lithium khac nhau');
end
% ---- bieu thuc ky hieu (mot nguon: rom_equations.m) ----------------------
x = SX.sym('x', nx); z = SX.sym('z', nz); I = SX.sym('I'); Ta = SX.sym('Ta');
rf = SX.sym('rf'); dt = SX.sym('dt');
rs = rom; rs.Rfilm_n = rf*rom.Rfilm_n; rs.ap.Rfilm = rf*rom.ap.Rfilm;
[fx, g, o] = rom_equations(rs, par, x, z, I, Ta);
% ---- chi so trang thai bo loc ------------------------------------------
E.fi = [ix.thn; ix.thp; ix.ce; ix.T];
E.nf = numel(E.fi); E.na = E.nf + 1;          % + rf
% ---- trong so lay trung binh the tich (SOC, luong lithium) --------------
dxn = rom.dx(rom.in); dxp = rom.dx(rom.ip);
E.wn = kron(dxn/sum(dxn), rom.Vshn/sum(rom.Vshn));   % xbar_n = wn' x(thn)
E.wp = kron(dxp/sum(dxp), rom.Vshp/sum(rom.Vshp));   % ybar_p = wp' x(thp)
E.Qn = par.neg.Qcap; E.Qp = par.pos.Qcap;            % Ah tren mot don vi stoich
E.x0n = par.neg.x0; E.x100n = par.neg.x100; E.y100p = par.pos.y100;
E.Qli_bol = E.Qn*E.x100n + E.Qp*E.y100p;            % Ah lithium trao doi duoc (duong can bang GD-13/GD-24)
% ---- tich phan mot buoc (thoi gian chuan hoa [0, 1], dt la tham so) -----
p = [I; Ta; rf; dt];
dae = struct('x', x, 'z', z, 'p', p, 'ode', dt*fx, 'alg', g);
switch integ
    case 'collocation'
        io = struct('number_of_finite_elements', nfe, 'interpolation_order', 3, ...
            'collocation_scheme', 'radau', 'rootfinder', 'newton', ...
            'rootfinder_options', struct('abstol', 1e-10, 'max_iter', 50, 'error_on_fail', false));
    case 'idas'
        io = struct('abstol', 1e-9, 'reltol', 1e-7, 'calc_ic', true);
    otherwise
        error('ekf_build: integrator %s', integ);
end
E.integrator = integ; E.nfe = nfe;
Fi = integrator('ekf_int', integ, dae, 0, 1, io);
X0 = MX.sym('x0', nx); Z0 = MX.sym('z0', nz); P = MX.sym('p', 4);
r = Fi('x0', X0, 'z0', Z0, 'p', P);
E.F  = Function('ekf_F', {X0, Z0, P}, {r.xf, r.zf});
E.FJ = Function('ekf_FJ', {X0, Z0, P}, {r.xf, r.zf, jacobian(r.xf, X0), jacobian(r.xf, P)});
% ---- phuong trinh do va dai luong can uoc luong (cung SX) ----------------
hv = [o.V; o.T];
eta = o.eta_sep;
E.Hf = Function('ekf_H', {x, z, I, Ta, rf}, ...
    {hv, jacobian(hv, x), jacobian(hv, z), jacobian(hv, rf), jacobian(hv, I), ...
     g, jacobian(g, x), jacobian(g, z), jacobian(g, rf), jacobian(g, I), ...
     eta, jacobian(eta, x), jacobian(eta, z), jacobian(eta, rf), o.xs_sep});
% rang buoc dai so cho rom_solve_z.m: pz = [x; I; Tamb] voi "Tamb" = [Ta; rf]
pz = SX.sym('pz', nx + 3);
gz = substitute(g, [x; I; Ta; rf], pz);
E.M.G  = Function('ekf_G', {z, pz}, {gz});
E.M.Gz = Function('ekf_Gz', {z, pz}, {jacobian(gz, z)});
E.ZG = Function('ekf_zg', {x, I, Ta}, {rom_zguess(rom, par, x, I, Ta)});
E.ix = ix;
end

function v = gf(s, n, d)
if isfield(s, n) && ~isempty(s.(n)), v = s.(n); else, v = d; end
end
