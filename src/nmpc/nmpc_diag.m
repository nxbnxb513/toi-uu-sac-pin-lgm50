function nmpc_diag(C, prm)
%NMPC_DIAG  In chan doan khi acados that bai: thong ke SQP, NaN trong lap va
% trong ma tran QP tung nut.
s = C.solver; N = C.N;
try, s.print('stat'); catch, end
X = s.get('x'); U = s.get('u');
fprintf('nmpc_diag: status %d; NaN trong x: %d, u: %d; |x| max %.3g, |u| max %.3g\n', s.get('status'), ...
    nnz(~isfinite(X)), nnz(~isfinite(U)), max(abs(X(:))), max(abs(U(:))));
bad = [];
for k = 0:N-1
    try
        A = s.get('qp_A', k); B = s.get('qp_B', k); b = s.get('qp_b', k);
        if any(~isfinite([A(:); B(:); b(:)])), bad(end+1) = k; end %#ok<AGROW>
    catch e
        fprintf('nmpc_diag: khong doc duoc qp_A tai nut %d: %s\n', k, e.message); break;
    end
end
fprintf('nmpc_diag: cac nut co NaN/Inf trong dong luc QP: %s\n', mat2str(bad));
r = C.rom; ix = r.ix;
fprintf('nmpc_diag: nut | thn [min max] | thp [min max] | ce/ref [min max] | T | soc | cLi max | Ich | tf_h | u\n');
for k = 0:N
    x = X(:, k+1);
    if k < N, uk = U(k+1); else, uk = NaN; end
    fprintf('  %2d | %.3f %.3f | %.3f %.3f | %.3f %.3f | %.2f | %.4f | %.3g | %.3f | %.4f | %.3g\n', k, ...
        min(x(ix.thn)), max(x(ix.thn)), min(x(ix.thp)), max(x(ix.thp)), min(x(ix.ce)), max(x(ix.ce)), ...
        x(ix.T), x(ix.soc), max(x(ix.cLi)), x(C.iI), x(C.itf), uk);
end
try
    z = s.get('z', 0); fprintf('nmpc_diag: z nut 0 = %s\n', mat2str(z.', 4));
catch
end
% tich phan lai cac nut nghi van bang bo tich phan acados doc lap (cung cai dat)
% va bang ode15s tren ROM, de biet loi o bo tich phan IRK hay o mo hinh
if nargin < 2 || ~isfield(C, 'simchk') || ~isfield(C, 'M'), return; end
M = C.M; Ta = prm(1);
cand = unique([bad(:).', 0, N-1]);
if isfield(C, 'sweep') && C.sweep && ~isempty(bad)
    k = bad(1); xk = X(:, k+1);
    try, zk = s.get('z', k); catch, zk = zeros(r.nz, 1); end
    zk = rom_solve_z(M, xk(1:r.nx), -xk(C.iI), Ta, zk);
    nmpc_irk_sweep(r, C.par, M, C, xk, U(k+1), zk, prm);
end
for k = cand(1:min(4, numel(cand)))
    xk = X(:, k+1); uk = U(k+1);
    try, zk = s.get('z', k); catch, zk = zeros(r.nz, 1); end
    [zc, okz, rz] = rom_solve_z(M, xk(1:r.nx), -xk(C.iI), Ta, zk);
    fprintf('nmpc_diag: nut %d: z cua acados vs z nhat quan: ok %d, |g| %.2e, max|dz| %.3g\n', k, okz, rz, max(abs(zc - zk)));
    try
        xa = C.simchk.simulate(xk, uk, zc, [], prm(:));
        fprintf('  acados sim (z nhat quan): NaN %d, max|x| %.3g, T %.2f, soc %.4f\n', any(~isfinite(xa)), max(abs(xa)), xa(ix.T), xa(ix.soc));
    catch e
        fprintf('  acados sim loi: %s\n', e.message);
    end
    try
        xa2 = C.simchk.simulate(xk, uk, zk, [], prm(:));
        fprintf('  acados sim (z cua OCP): NaN %d, max|x| %.3g\n', any(~isfinite(xa2)), max(abs(xa2)));
    catch e
        fprintf('  acados sim (z cua OCP) loi: %s\n', e.message);
    end
    dt = 3600*xk(C.itf)/N;
    try
        rr = rom_sim(M, r, xk(1:r.nx), zc, @(t) -(xk(C.iI) + uk/N*t/dt), Ta, linspace(0, dt, 5).', struct('sat', false));
        fprintf('  ode15s ROM: %s, V cuoi %.4f, soc cuoi %.4f, max|x| %.3g\n', rr.reason, rr.V(end), rr.soc(end), max(abs(rr.Y(:, end))));
    catch e
        fprintf('  ode15s ROM loi: %s\n', e.message);
    end
end
end
