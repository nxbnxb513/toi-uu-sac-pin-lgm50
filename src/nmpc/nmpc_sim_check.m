function chk = nmpc_sim_check(rom, par, M, x0, z0, Ich0, Ig, tf_h, prm, C, opt)
%NMPC_SIM_CHECK  Kiem tra bo tich phan IRK cua acados (cung cai dat voi OCP)
% tren MOT khoang du bao: tu x0, dong sac tang tuyen tinh Ich0 -> Ig, dai
% 3600 tf_h / N giay; so voi ROM tich phan bang ode15s (rom_sim.m).
% In sai lech V, T, SOC, x_s,sep; bao NaN neu bo tich phan phan ky.
N = C.N;
model = nmpc_model(rom, par, sprintf('rom_simchk_%d_%d', opt.num_stages, opt.num_steps), C.opt.eps_cost);
sim = AcadosSim();
sim.model = model;
sim.parameter_values = prm(:);
sim.solver_options.Tsim = 1/N;
sim.solver_options.integrator_type = 'IRK';
sim.solver_options.collocation_type = 'GAUSS_RADAU_IIA';
sim.solver_options.num_stages = opt.num_stages;
sim.solver_options.num_steps = opt.num_steps;
sim.solver_options.newton_iter = opt.newton_iter;
sim.code_gen_options.code_export_directory = C.opt.codegen_dir;
ss = AcadosSimSolver(sim);
u0 = (Ig - Ich0)*N;
X0 = [x0(:); Ich0; tf_h];
chk.ok = true;
try
    Xn = ss.simulate(X0, u0, z0(:), [], prm(:));
catch e
    fprintf('nmpc_sim_check: acados sim loi: %s\n', e.message);
    Xn = nan(size(X0)); chk.ok = false;
end
dt = 3600*tf_h/N;
r = rom_sim(M, rom, x0, z0, @(t) -(Ich0 + (Ig - Ich0)*t/dt), prm(1), linspace(0, dt, 5).', struct('sat', false));
xr = r.Y(1:rom.nx, end);
xa = Xn(1:rom.nx);
[za, oka] = rom_solve_z(M, xa, -Ig, prm(1), r.Y(rom.nx+1:end, end));
oa = nan(M.iout.xsp(end), 1);
if oka && all(isfinite(xa)), oa = full(M.out([xa; za], -Ig, prm(1))); end
or = full(M.out(r.Y(:, end), -Ig, prm(1)));
chk.nan = any(~isfinite(Xn));
chk.dV = oa(M.iout.V) - or(M.iout.V); chk.dT = oa(M.iout.T) - or(M.iout.T);
chk.dsoc = oa(M.iout.soc) - or(M.iout.soc); chk.dxs = oa(M.iout.xs_sep) - or(M.iout.xs_sep);
chk.dx_max = max(abs(xa - xr));
fprintf(['nmpc_sim_check (stages %d, steps %d, newton %d, khoang %.1f s, I %.2f -> %.2f A): NaN %d, ' ...
    'dV %.3g mV, dT %.3g K, dSOC %.3g, dxs_sep %.3g, max|dx| %.3g\n'], opt.num_stages, opt.num_steps, opt.newton_iter, ...
    dt, Ich0, Ig, chk.nan, 1e3*chk.dV, chk.dT, chk.dsoc, chk.dxs, chk.dx_max);
end
