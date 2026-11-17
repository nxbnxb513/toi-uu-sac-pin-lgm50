function nmpc_diag(C)
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
end
