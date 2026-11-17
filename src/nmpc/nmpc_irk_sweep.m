function nmpc_irk_sweep(rom, par, M, C, Xk, uk, zk, prm)
%NMPC_IRK_SWEEP  Go loi: tich phan MOT khoang du bao tu (Xk, uk) bang bo tich
% phan IRK cua acados voi nhieu so buoc / so lan lap Newton, so voi ode15s.
% Dung de chon cai dat tich phan ben vung cho OCP.
N = C.N; Ta = prm(1);
dt = 3600*Xk(C.itf)/N;
rr = rom_sim(M, rom, Xk(1:rom.nx), zk, @(t) -(Xk(C.iI) + uk/N*t/dt), Ta, linspace(0, dt, 5).', struct('sat', false));
xr = rr.Y(1:rom.nx, end);
fprintf('nmpc_irk_sweep: khoang %.1f s, I %.3f -> %.3f A; ode15s: %s, V cuoi %.4f\n', dt, Xk(C.iI), Xk(C.iI) + uk/N, rr.reason, rr.V(end));
for nst = [2 4 8 16 32]
    for nnw = [8 20]
        name = sprintf('rom_sw_%d_%d', nst, nnw);
        model = nmpc_model(rom, par, name, C.opt.eps_cost);
        sim = AcadosSim();
        sim.model = model; sim.parameter_values = prm(:);
        sim.solver_options.Tsim = 1/N;
        sim.solver_options.integrator_type = 'IRK';
        sim.solver_options.collocation_type = 'GAUSS_RADAU_IIA';
        sim.solver_options.num_stages = C.opt.num_stages;
        sim.solver_options.num_steps = nst;
        sim.solver_options.newton_iter = nnw;
        sim.code_gen_options.code_export_directory = C.opt.codegen_dir;
        try
            ss = AcadosSimSolver(sim);
            tw = tic; xa = ss.simulate(Xk, uk, zk, [], prm(:)); w = toc(tw);
            xa = xa(1:rom.nx);
            fprintf('  steps %2d newton %2d: NaN %d, max|dx| %.3g, chay %.1f ms\n', nst, nnw, any(~isfinite(xa)), max(abs(xa - xr)), 1e3*w);
        catch e
            fprintf('  steps %2d newton %2d: loi %s\n', nst, nnw, e.message);
        end
    end
end
end
