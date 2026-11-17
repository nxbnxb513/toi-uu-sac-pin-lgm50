function r = rom_sim_ode(E, M, rom, x0, Ifun, Tamb, tout, stop)
%ROM_SIM_ODE  Mo phong ROM da khu z (rom_elim.m) bang ode15s (ODE thuan).
% Cung dau vao / dau ra voi rom_sim.m de so sanh truc tiep.
if ~isa(Ifun, 'function_handle'), Ic = Ifun; Ifun = @(t) Ic; end
if nargin < 8 || isempty(stop), stop = struct(); end
def = struct('Vmin', NaN, 'Vmax', NaN, 'soc', NaN, 'sat', true);
fn = fieldnames(def);
for i = 1:numel(fn), if ~isfield(stop, fn{i}), stop.(fn{i}) = def.(fn{i}); end, end
opts = odeset('RelTol', 1e-6, 'AbsTol', rom.atol_x, 'Jacobian', @(t, x) sparse(E.jac(x, Ifun(t), Tamb)), ...
    'Events', @ev, 'InitialStep', 1e-3);
tout = tout(:); if numel(tout) < 3, tout = linspace(tout(1), tout(end), 3).'; end
tic; [t, X, te, ~, ie] = ode15s(@(t, x) full(E.ode(x, Ifun(t), Tamb)), tout, x0(:), opts); r.wall = toc;
names = {'Vmin', 'Vmax', 'soc', 'xsn_max', 'xsn_min', 'xsp_max', 'xsp_min'};
if ~isempty(ie) && te(end) >= t(end) - 1e-9, r.reason = names{ie(end)};
elseif t(end) >= tout(end)*(1 - 1e-10), r.reason = 'time'; else, r.reason = 'solver_failed'; end
r.t = t; r.X = X.';
O = zeros(M.iout.xsp(end), numel(t));
for i = 1:numel(t), O(:, i) = full(E.out(r.X(:, i), Ifun(t(i)), Tamb)); end
r.V = O(M.iout.V, :).'; r.T = O(M.iout.T, :).'; r.soc = O(M.iout.soc, :).';
r.xs_sep = O(M.iout.xs_sep, :).'; r.dphi_sep = O(M.iout.dphi_sep, :).'; r.eta_sep = O(M.iout.eta_sep, :).';
r.nsei = r.X(rom.ix.nsei, :).'; r.npl = r.X(rom.ix.npl, :).'; r.ndl = r.X(rom.ix.ndl, :).';
    function [val, term, dirn] = ev(t, x)
        o = full(E.out(x, Ifun(t), Tamb));
        val = ones(7, 1);
        if ~isnan(stop.Vmin), val(1) = o(M.iout.V) - stop.Vmin; end
        if ~isnan(stop.Vmax), val(2) = stop.Vmax - o(M.iout.V); end
        if ~isnan(stop.soc),  val(3) = stop.soc - o(M.iout.soc); end
        if stop.sat
            tol = 1e-4;
            val(4) = (1 - tol) - max(o(M.iout.xsn)); val(5) = min(o(M.iout.xsn)) - tol;
            val(6) = (1 - tol) - max(o(M.iout.xsp)); val(7) = min(o(M.iout.xsp)) - tol;
        end
        term = ones(7, 1); dirn = -ones(7, 1); if ~isnan(stop.soc), dirn(3) = 0; end
    end
end
