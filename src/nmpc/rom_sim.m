function r = rom_sim(M, rom, x0, z0, Ifun, Tamb, tout, stop)
%ROM_SIM  Mo phong ROM trong MATLAB (ode15s, DAE chi so 1, Jacobian giai tich
% tu CasADi). Cung ham CasADi voi NMPC (rom_model.m).
%   Ifun: dong [A] (> 0 xa) - so hoac ham @(t); tout: luoi xuat [s];
%   stop: .Vmin, .Vmax, .soc (dung khi SOC cham), .sat (true: dung khi stoich
%   be mat bat ky cham 1e-4 hoac 1 - 1e-4, giong dfn_events.m)
if ~isa(Ifun, 'function_handle'), Ic = Ifun; Ifun = @(t) Ic; end
if nargin < 8 || isempty(stop), stop = struct(); end
def = struct('Vmin', NaN, 'Vmax', NaN, 'soc', NaN, 'sat', true);
fn = fieldnames(def);
for i = 1:numel(fn), if ~isfield(stop, fn{i}), stop.(fn{i}) = def.(fn{i}); end, end
nx = rom.nx; nz = rom.nz;
[z, ok] = rom_solve_z(M, x0, Ifun(0), Tamb, z0);
if ~ok, error('rom_sim: khong giai duoc rang buoc dai so ban dau'); end
Y0 = [x0(:); z];
Mm = spdiags([ones(nx, 1); zeros(nz, 1)], 0, nx + nz, nx + nz);
opts = odeset('Mass', Mm, 'MassSingular', 'yes', 'MStateDependence', 'none', ...
    'RelTol', 1e-6, 'AbsTol', [rom.atol_x; rom.atol_z], ...
    'Jacobian', @(t, Y) sparse(M.jac(Y, Ifun(t), Tamb)), ...
    'Events', @ev, 'InitialStep', 1e-3);
tout = tout(:);
if numel(tout) < 3, tout = linspace(tout(1), tout(end), 3).'; end
tic;
[t, Y, te, ~, ie] = ode15s(@(t, Y) full(M.dae(Y, Ifun(t), Tamb)), tout, Y0, opts);
r.wall = toc;
names = {'Vmin', 'Vmax', 'soc', 'xsn_max', 'xsn_min', 'xsp_max', 'xsp_min'};
if ~isempty(ie) && te(end) >= t(end) - 1e-9
    r.reason = names{ie(end)};
elseif t(end) >= tout(end)*(1 - 1e-10)
    r.reason = 'time';
else
    r.reason = 'solver_failed';
end
r.t = t; r.Y = Y.';
no = numel(M.iout.xsp) + M.iout.xsp(1) - 1;
O = zeros(no, numel(t));
for i = 1:numel(t), O(:, i) = full(M.out(r.Y(:, i), Ifun(t(i)), Tamb)); end
r.V = O(M.iout.V, :).'; r.T = O(M.iout.T, :).'; r.soc = O(M.iout.soc, :).';
r.xs_sep = O(M.iout.xs_sep, :).'; r.dphi_sep = O(M.iout.dphi_sep, :).'; r.eta_sep = O(M.iout.eta_sep, :).';
r.xs_max = max(O(M.iout.xsn, :), [], 1).';
r.nsei = r.Y(rom.ix.nsei, :).'; r.npl = r.Y(rom.ix.npl, :).';
r.I = arrayfun(Ifun, t);

    function [val, term, dirn] = ev(t, Y)
        o = full(M.out(Y, Ifun(t), Tamb));
        val = ones(7, 1);
        if ~isnan(stop.Vmin), val(1) = o(M.iout.V) - stop.Vmin; end
        if ~isnan(stop.Vmax), val(2) = stop.Vmax - o(M.iout.V); end
        if ~isnan(stop.soc),  val(3) = stop.soc - o(M.iout.soc); end
        if stop.sat
            tol = 1e-4;
            val(4) = (1 - tol) - max(o(M.iout.xsn)); val(5) = min(o(M.iout.xsn)) - tol;
            val(6) = (1 - tol) - max(o(M.iout.xsp)); val(7) = min(o(M.iout.xsp)) - tol;
        end
        term = ones(7, 1); dirn = -ones(7, 1);
        if ~isnan(stop.soc), dirn(3) = 0; end
    end
end
