function acados_matlab_test(src_dir)
% ACADOS_MATLAB_TEST  Feasibility test of acados' MATLAB interface on a
% GitHub-hosted runner (public-repo MATLAB licence). Runs in four separate
% stages so that each failure can be attributed:
%   1. mex -setup C            (is a C compiler configured?)
%   2. trivial hello-world MEX (can MEX files be built AND loaded/called?)
%   3. CasADi                  (casadiMEX is itself a MEX file)
%   4. acados closed-loop NMPC (code generation, mex of the solver, solve)
% Each stage prints PASS/FAIL with the exact error report. The function
% errors at the end if any stage failed, so the CI job status is honest.

results = struct('stage', {}, 'ok', {}, 'msg', {});

fprintf('\n===== ENVIRONMENT =====\n');
fprintf('MATLAB %s, computer=%s\n', version, computer);
fprintf('ACADOS_INSTALL_DIR=%s\n', getenv('ACADOS_INSTALL_DIR'));
fprintf('LD_LIBRARY_PATH=%s\n', getenv('LD_LIBRARY_PATH'));
fprintf('pwd=%s\n', pwd);
acados_dir = getenv('ACADOS_INSTALL_DIR');
addpath(fullfile(acados_dir, 'interfaces', 'acados_matlab_octave'));
addpath(fullfile(acados_dir, 'external', 'casadi-matlab'));

%% 1. mex -setup C
fprintf('\n===== STAGE 1: mex -setup C =====\n');
try
    mex -setup C
    cc = mex.getCompilerConfigurations('C', 'Selected');
    fprintf('Selected C compiler: %s %s\n', cc.Name, cc.Version);
    results(end+1) = struct('stage', 'mex -setup C', 'ok', true, 'msg', [cc.Name ' ' cc.Version]);
catch e
    fprintf('FAIL:\n%s\n', getReport(e, 'extended'));
    results(end+1) = struct('stage', 'mex -setup C', 'ok', false, 'msg', e.message);
end

%% 2. hello-world MEX
fprintf('\n===== STAGE 2: hello-world MEX (build + call) =====\n');
try
    outdir = fullfile(pwd, 'hello_mex_build');
    if ~exist(outdir, 'dir'), mkdir(outdir); end
    mex('-outdir', outdir, fullfile(src_dir, 'hello_mex.c'));
    fprintf('hello_mex built OK\n');
    addpath(outdir);
    y = hello_mex(21);
    assert(y == 42, 'hello_mex returned %g instead of 42', y);
    fprintf('hello_mex(21) = %g  -> PASS\n', y);
    results(end+1) = struct('stage', 'hello MEX', 'ok', true, 'msg', 'built and called');
catch e
    fprintf('FAIL:\n%s\n', getReport(e, 'extended'));
    results(end+1) = struct('stage', 'hello MEX', 'ok', false, 'msg', e.message);
end

%% 3. CasADi
fprintf('\n===== STAGE 3: CasADi =====\n');
try
    import casadi.*
    xs = SX.sym('x');
    f = Function('f', {xs}, {sin(xs)^2});
    val = full(f(0.3));
    fprintf('CasADi %s loaded, f(0.3)=%.6f\n', char(CasadiMeta.version()), val);
    assert(abs(val - sin(0.3)^2) < 1e-12);
    results(end+1) = struct('stage', 'CasADi', 'ok', true, 'msg', char(CasadiMeta.version()));
catch e
    fprintf('FAIL:\n%s\n', getReport(e, 'extended'));
    results(end+1) = struct('stage', 'CasADi', 'ok', false, 'msg', e.message);
end

%% 4. acados closed-loop NMPC (pendulum on cart, nonlinear constraint on u)
fprintf('\n===== STAGE 4: acados OCP + closed loop =====\n');
substage = 'build OCP';
try
    import casadi.*
    N = 20; Tf = 1.0; dt = Tf / N; Fmax = 80;
    model = pendulum_model();
    nx = 4; nu = 1;

    ocp = AcadosOcp();
    ocp.model = model;
    ocp.cost.cost_type_0 = 'NONLINEAR_LS';
    ocp.cost.cost_type = 'NONLINEAR_LS';
    ocp.cost.cost_type_e = 'NONLINEAR_LS';
    ocp.model.cost_y_expr_0 = model.u;
    ocp.model.cost_y_expr = vertcat(model.x, model.u);
    ocp.model.cost_y_expr_e = model.x;
    Wx = diag([1e3, 1e3, 1e-2, 1e-2]); Wu = 1e-2;
    ocp.cost.W_0 = Wu;
    ocp.cost.W = blkdiag(Wx, Wu);
    ocp.cost.W_e = Wx;
    ocp.cost.yref_0 = zeros(nu, 1);
    ocp.cost.yref = zeros(nx+nu, 1);
    ocp.cost.yref_e = zeros(nx, 1);
    % nonlinear (h) constraints, as in the target battery problem
    ocp.model.con_h_expr_0 = model.u;
    ocp.model.con_h_expr = model.u;
    ocp.constraints.lh_0 = -Fmax; ocp.constraints.uh_0 = Fmax;
    ocp.constraints.lh = -Fmax;   ocp.constraints.uh = Fmax;
    x0 = [0; pi; 0; 0];
    ocp.constraints.x0 = x0;
    ocp.solver_options.N_horizon = N;
    ocp.solver_options.tf = Tf;
    ocp.solver_options.nlp_solver_type = 'SQP';
    ocp.solver_options.integrator_type = 'IRK';
    ocp.solver_options.qp_solver = 'PARTIAL_CONDENSING_HPIPM';
    ocp.solver_options.hessian_approx = 'GAUSS_NEWTON';
    ocp.solver_options.globalization = 'MERIT_BACKTRACKING';
    ocp.solver_options.nlp_solver_max_iter = 200;
    ocp.name = 'pend_ocp';

    substage = 'AcadosOcpSolver (codegen + compile + mex)';
    t0 = tic;
    ocp_solver = AcadosOcpSolver(ocp);
    fprintf('AcadosOcpSolver created in %.1f s\n', toc(t0));

    substage = 'AcadosSimSolver';
    sim = AcadosSim();
    sim.model = model;
    sim.solver_options.Tsim = dt;
    sim.solver_options.integrator_type = 'IRK';
    sim.solver_options.num_stages = 3;
    sim.solver_options.num_steps = 3;
    sim_solver = AcadosSimSolver(sim);

    substage = 'closed loop';
    Nsim = 100;
    x = x0;
    t_wall = zeros(Nsim, 1); t_acados = zeros(Nsim, 1); sqp_it = zeros(Nsim, 1);
    status_all = zeros(Nsim, 1);
    for i = 1:Nsim
        ocp_solver.set('constr_x0', x);
        tw = tic;
        ocp_solver.solve();
        t_wall(i) = toc(tw);
        status_all(i) = ocp_solver.get('status');
        t_acados(i) = ocp_solver.get('time_tot');
        sqp_it(i) = ocp_solver.get('sqp_iter');
        u0 = ocp_solver.get('u', 0);
        x = sim_solver.simulate(x, u0);
    end
    fprintf('closed loop: %d solves, statuses: %s\n', Nsim, mat2str(unique(status_all)'));
    fprintf('final state: %s\n', mat2str(x', 4));
    fprintf('time per solve (MATLAB tic/toc incl. MEX call): mean %.3f ms, median %.3f ms, max %.3f ms\n', ...
        1e3*mean(t_wall), 1e3*median(t_wall), 1e3*max(t_wall));
    fprintf('time per solve (acados time_tot): mean %.3f ms, median %.3f ms, max %.3f ms\n', ...
        1e3*mean(t_acados), 1e3*median(t_acados), 1e3*max(t_acados));
    fprintf('SQP iterations: mean %.1f, max %d\n', mean(sqp_it), max(sqp_it));
    assert(all(status_all == 0), 'acados returned nonzero status: %s', mat2str(status_all'));
    assert(abs(x(2)) < 0.1, 'pendulum not stabilised upright: theta=%g', x(2));
    results(end+1) = struct('stage', 'acados closed loop', 'ok', true, ...
        'msg', sprintf('status 0 x%d, median %.3f ms/solve (time_tot)', Nsim, 1e3*median(t_acados)));
catch e
    fprintf('FAIL in substage "%s":\n%s\n', substage, getReport(e, 'extended'));
    results(end+1) = struct('stage', 'acados closed loop', 'ok', false, ...
        'msg', sprintf('[%s] %s', substage, e.message));
end

%% summary
fprintf('\n===== SUMMARY =====\n');
for k = 1:numel(results)
    if results(k).ok, s = 'PASS'; else, s = 'FAIL'; end
    fprintf('%-20s %s  %s\n', results(k).stage, s, results(k).msg);
end
if ~all([results.ok])
    error('acados_matlab_test:failed', 'At least one stage failed (see above).');
end
end

function model = pendulum_model()
import casadi.*
M = 1; m = 0.1; l = 0.8; g = 9.81;
p = SX.sym('p'); theta = SX.sym('theta'); v = SX.sym('v'); dtheta = SX.sym('dtheta');
F = SX.sym('F');
x = vertcat(p, theta, v, dtheta);
xdot = SX.sym('xdot', 4, 1);
s = sin(theta); c = cos(theta);
den = M + m - m*c^2;
f_expl = vertcat(v, dtheta, ...
    (-l*m*s*dtheta^2 + F + g*m*c*s)/den, ...
    (-l*m*c*s*dtheta^2 + F*c + (M+m)*g*s)/(l*den));
model = AcadosModel();
model.x = x;
model.xdot = xdot;
model.u = F;
model.f_expl_expr = f_expl;
model.f_impl_expr = f_expl - xdot;
model.name = 'pend';
end
