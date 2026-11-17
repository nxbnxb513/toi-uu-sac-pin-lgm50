"""Closed-loop NMPC timing test of acados' Python interface (same problem as
acados_matlab_test.m: pendulum on cart, N=20, Tf=1 s, SQP + IRK, nonlinear
constraint on u, 100 closed-loop steps). Exits nonzero on any failure."""
import sys
import time

import casadi as ca
import numpy as np
from acados_template import AcadosModel, AcadosOcp, AcadosOcpSolver, AcadosSim, AcadosSimSolver


def pendulum_model():
    M, m, l, g = 1.0, 0.1, 0.8, 9.81
    p, theta, v, dtheta = (ca.SX.sym(n) for n in ("p", "theta", "v", "dtheta"))
    F = ca.SX.sym("F")
    x = ca.vertcat(p, theta, v, dtheta)
    xdot = ca.SX.sym("xdot", 4)
    s, c = ca.sin(theta), ca.cos(theta)
    den = M + m - m * c**2
    f_expl = ca.vertcat(
        v,
        dtheta,
        (-l * m * s * dtheta**2 + F + g * m * c * s) / den,
        (-l * m * c * s * dtheta**2 + F * c + (M + m) * g * s) / (l * den),
    )
    model = AcadosModel()
    model.x, model.xdot, model.u = x, xdot, F
    model.f_expl_expr = f_expl
    model.f_impl_expr = f_expl - xdot
    model.name = "pend"
    return model


def main():
    N, Tf, Fmax, Nsim = 20, 1.0, 80.0, 100
    model = pendulum_model()
    nx, nu = 4, 1
    ocp = AcadosOcp()
    ocp.model = model
    ocp.cost.cost_type_0 = ocp.cost.cost_type = ocp.cost.cost_type_e = "NONLINEAR_LS"
    ocp.model.cost_y_expr_0 = model.u
    ocp.model.cost_y_expr = ca.vertcat(model.x, model.u)
    ocp.model.cost_y_expr_e = model.x
    Wx = np.diag([1e3, 1e3, 1e-2, 1e-2])
    Wu = np.array([[1e-2]])
    ocp.cost.W_0 = Wu
    ocp.cost.W = np.block([[Wx, np.zeros((nx, nu))], [np.zeros((nu, nx)), Wu]])
    ocp.cost.W_e = Wx
    ocp.cost.yref_0 = np.zeros(nu)
    ocp.cost.yref = np.zeros(nx + nu)
    ocp.cost.yref_e = np.zeros(nx)
    ocp.model.con_h_expr_0 = model.u
    ocp.model.con_h_expr = model.u
    ocp.constraints.lh_0 = ocp.constraints.lh = np.array([-Fmax])
    ocp.constraints.uh_0 = ocp.constraints.uh = np.array([Fmax])
    x0 = np.array([0.0, np.pi, 0.0, 0.0])
    ocp.constraints.x0 = x0
    so = ocp.solver_options
    so.N_horizon, so.tf = N, Tf
    so.nlp_solver_type = "SQP"
    so.integrator_type = "IRK"
    so.qp_solver = "PARTIAL_CONDENSING_HPIPM"
    so.hessian_approx = "GAUSS_NEWTON"
    so.globalization = "MERIT_BACKTRACKING"
    so.nlp_solver_max_iter = 200

    t0 = time.perf_counter()
    solver = AcadosOcpSolver(ocp, json_file="pend_ocp.json")
    print(f"AcadosOcpSolver created in {time.perf_counter() - t0:.1f} s")

    sim = AcadosSim()
    sim.model = model
    sim.solver_options.T = Tf / N
    sim.solver_options.integrator_type = "IRK"
    sim.solver_options.num_stages = 3
    sim.solver_options.num_steps = 3
    integrator = AcadosSimSolver(sim, json_file="pend_sim.json")

    x = x0.copy()
    t_wall, t_acados, iters, statuses = [], [], [], []
    for _ in range(Nsim):
        tw = time.perf_counter()
        u0 = solver.solve_for_x0(x, fail_on_nonzero_status=False)
        t_wall.append(time.perf_counter() - tw)
        t_acados.append(solver.get_stats("time_tot"))
        iters.append(solver.get_stats("sqp_iter"))
        statuses.append(solver.get_status())
        x = integrator.simulate(x=x, u=u0)

    t_acados = 1e3 * np.array(t_acados)
    t_wall = 1e3 * np.array(t_wall)
    print(f"closed loop: {Nsim} solves, statuses: {sorted(set(statuses))}")
    print(f"final state: {np.round(x, 4)}")
    print(f"time per solve (acados time_tot): mean {t_acados.mean():.3f} ms, "
          f"median {np.median(t_acados):.3f} ms, max {t_acados.max():.3f} ms")
    print(f"time per solve (Python wall incl. ctypes call): mean {t_wall.mean():.3f} ms, "
          f"median {np.median(t_wall):.3f} ms, max {t_wall.max():.3f} ms")
    print(f"SQP iterations: mean {np.mean(iters):.1f}, max {max(iters)}")
    ok = all(s == 0 for s in statuses) and abs(x[1]) < 0.1
    print("RESULT:", "PASS" if ok else "FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
