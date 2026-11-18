function nmpc_irk_probe(C, par, Xk, uk, Ta, k)
%NMPC_IRK_PROBE  Go loi (18/11/2026): tich phan LAI mot khoang du bao (nut k) cua OCP
% bang ban sao MATLAB cua bo tich phan IRK acados v0.6 (Radau IIA 2 nac, sim_irk_integrator.c:
% K khoi tao = xdot doan dau (0), giu K qua cac buoc, Newton day du newton_iter lan,
% khong tat dan, Jacobian chinh xac moi lan lap) va in tung buoc / tung lan lap Newton:
% |G|, NaN, stoich be mat, c_e, T, de biet NaN xuat hien DAU TIEN o dau.
% Sau do thu cac cai dat khac (so buoc, so lan lap, K khoi tao) va so voi ode15s.
%   Xk = [x_ROM; I_ch; t_f] tai nut k (lap acados), uk = dI_ch/dtau, Ta [K].
import casadi.*
rom = C.rom; M = C.M; E = M.E; N = C.N; nx = rom.nx; nX = nx + 2;
x = MX.sym('x', nx); Ich = MX.sym('I'); tf = MX.sym('tf'); u = MX.sym('u'); T_ = MX.sym('Ta');
X = [x; Ich; tf];
[fx, ov] = E.sym(x, -Ich, T_);
fe = [3600*tf*fx; u; 0];
F = Function('irk_probe_f', {X, u, T_}, {fe, jacobian(fe, X), ov});
io = M.iout;
dt = 3600*Xk(nX)/N;
fprintf('\n=== nmpc_irk_probe nut %d: khoang %.1f s, I %.3f -> %.3f A, t_f %.4f h, SOC %.4f ===\n', ...
    k, dt, Xk(nx+1), Xk(nx+1) + uk/N, Xk(nX), Xk(rom.ix.soc));
[f0, ~, ov0] = F(Xk, uk, Ta); f0 = full(f0); ov0 = full(ov0);
fprintf('  tai Xk: V %.4f, xs_sep %.5f, max xsn %.5f, min xsn %.5f, max xsp %.4f, eta_sep %.1f mV, NaN f %d, max|f| %.3g\n', ...
    ov0(io.V), ov0(io.xs_sep), max(ov0(io.xsn)), min(ov0(io.xsn)), max(ov0(io.xsp)), 1e3*ov0(io.eta_sep), any(~isfinite(f0)), max(abs(f0)));
% ode15s tham chieu (ROM da khu z)
Ifun = @(s) -(Xk(nx+1) + uk*s/(3600*Xk(nX)));
xr = [];
try
    rr = rom_sim_ode(E, M, rom, Xk(1:nx), Ifun, Ta, linspace(0, dt, 9).', struct('sat', false));
    if strcmp(rr.reason, 'time'), xr = rr.X(:, end); end
    fprintf('  ode15s: %s, V cuoi %.4f, xs_sep max %.5f, %.2f s\n', rr.reason, rr.V(end), max(rr.xs_sep), rr.wall);
catch e
    fprintf('  ode15s loi: %s\n', e.message);
end
cfgs = {8, 8, 'zero', true; 8, 20, 'zero', false; 16, 8, 'zero', false; 32, 8, 'zero', false; ...
        64, 8, 'zero', false; 8, 8, 'f0', false; 32, 8, 'f0', false};
for c = 1:size(cfgs, 1)
    [nst, nit, kin, verbose] = cfgs{c, :};
    if strcmp(kin, 'zero'), K0 = zeros(nX, 1); else, K0 = f0; end
    tw = tic;
    [Xn, first] = irk(nst, nit, K0, verbose);
    err = NaN; if ~isempty(xr) && all(isfinite(Xn)), err = max(abs(Xn(1:nx) - xr)); end
    fprintf('  IRK %2d buoc x %2d Newton, K0 = %s: NaN %d (dau tien: %s), max|x - ode15s| %.3g, %.1f s\n', ...
        nst, nit, kin, any(~isfinite(Xn)), first, err, toc(tw));
end
fprintf('=== het nmpc_irk_probe ===\n\n');

    function [Xc, first] = irk(nst, nit, K0, verbose)
        A = [5/12, -1/12; 3/4, 1/4]; b = A(2, :);
        h = (1/N)/nst; Xc = Xk; K = [K0, K0]; first = 'khong';
        for ss = 1:nst
            for it = 1:nit
                Xs = [Xc + h*(A(1, 1)*K(:, 1) + A(1, 2)*K(:, 2)), Xc + h*(A(2, 1)*K(:, 1) + A(2, 2)*K(:, 2))];
                [f1, J1, o1] = F(Xs(:, 1), uk, Ta); [f2, J2, o2] = F(Xs(:, 2), uk, Ta);
                f1 = full(f1); f2 = full(f2); J1 = full(J1); J2 = full(J2); o1 = full(o1); o2 = full(o2);
                G = [K(:, 1) - f1; K(:, 2) - f2];
                DG = eye(2*nX) - [h*A(1, 1)*J1, h*A(1, 2)*J1; h*A(2, 1)*J2, h*A(2, 2)*J2];
                bad = ~all(isfinite([G; DG(:)]));
                if verbose
                    stg = [stats(Xs(:, 1), o1); stats(Xs(:, 2), o2)];
                    fprintf(['    buoc %2d lap %2d: |G| %.3g | nac1: thn [%.4f %.4f] xs_sep %.5f ce [%.3f %.3f] T %.2f V %.4f eta %.1f mV' ...
                        ' | nac2: thn [%.4f %.4f] xs_sep %.5f ce [%.3f %.3f] T %.2f V %.4f eta %.1f mV | NaN f %d J %d\n'], ss, it, norm(G, inf), ...
                        stg(1, :), stg(2, :), any(~isfinite([f1; f2])), any(~isfinite([J1(:); J2(:)])));
                end
                if bad
                    first = sprintf('buoc %d lap %d (f %d, J %d)', ss, it, any(~isfinite([f1; f2])), any(~isfinite([J1(:); J2(:)])));
                    if verbose, explain(Xs, [f1, f2], [J1(:), J2(:)]); end
                    Xc = nan(nX, 1); return
                end
                dK = DG\G;
                K = K - reshape(dK, nX, 2);
            end
            Xc = Xc + h*(b(1)*K(:, 1) + b(2)*K(:, 2));
            if ~all(isfinite(Xc)), first = sprintf('cuoi buoc %d', ss); return; end
        end
    end

    function s = stats(Xs, o)
        s = [min(Xs(rom.ix.thn)), max(Xs(rom.ix.thn)), o(io.xs_sep), min(Xs(rom.ix.ce)), max(Xs(rom.ix.ce)), Xs(rom.ix.T), o(io.V), 1e3*o(io.eta_sep)];
    end

    function explain(Xs, Fs, Js)
        % nac co NaN: z cua Newton sinh ma (fast_newton) so voi Newton tat dan (rom_solve_z)
        for j = 1:2
            if all(isfinite([Fs(:, j); Js(:, j)])), continue; end
            xs = Xs(1:nx, j); Ij = -Xs(nx+1, j);
            fprintf('    -> nac %d: I %.3f A, thn [%.4f %.4f], thp [%.4f %.4f], ce [%.4f %.4f], T %.2f, cLi max %.3g\n', j, -Ij, ...
                min(xs(rom.ix.thn)), max(xs(rom.ix.thn)), min(xs(rom.ix.thp)), max(xs(rom.ix.thp)), min(xs(rom.ix.ce)), max(xs(rom.ix.ce)), ...
                xs(rom.ix.T), max(xs(rom.ix.cLi)));
            fprintf('       NaN trong f tai cac chi so: %s\n', mat2str(find(~isfinite(Fs(:, j))).'));
            try
                zg = full(E.ZG([xs; Ij; Ta])); zf = full(E.zfun(xs, Ij, Ta));
                gf = full(M.G(zf, [xs; Ij; Ta])); gg = full(M.G(zg, [xs; Ij; Ta]));
                fprintf('       z doan dau: NaN %d, |g| %.3g; z fast_newton: NaN %d, |g| %.3g, z [%s]\n', any(~isfinite(zg)), norm(gg, inf), ...
                    any(~isfinite(zf)), norm(gf, inf), num2str(zf(:).', '%.3g '));
                [zr, okr, rr2] = rom_solve_z(M, xs, Ij, Ta, zg);
                fprintf('       z Newton tat dan: ok %d, |g| %.3g, z [%s]\n', okr, rr2, num2str(zr(:).', '%.3g '));
                if okr
                    o = full(M.out([xs; zr], Ij, Ta)); fx2 = full(M.dae([xs; zr], Ij, Ta));
                    fprintf('       voi z tat dan: V %.4f, xs_sep %.5f, max xsn %.5f, eta_sep %.1f mV, NaN f %d\n', o(io.V), o(io.xs_sep), max(o(io.xsn)), 1e3*o(io.eta_sep), any(~isfinite(fx2)));
                end
            catch e
                fprintf('       giai thich loi: %s\n', e.message);
            end
        end
    end
end
