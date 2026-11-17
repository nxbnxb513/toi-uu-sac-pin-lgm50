function J = dfn_numjac(fun, y, f0, rows, cols, S, grp)
%DFN_NUMJAC  Jacobian sai phan tien d f(rows) / d y(cols) voi mau thua S
% (numel(rows) x numel(cols)) va nhom mau grp (tu dfn_color).
% fun(y) tra ve vector f day du; f0 = fun(y).
nc = numel(cols);
del = 1e-7*max(1, abs(y(cols)));
ng = max(grp);
ii = cell(ng, 1); jj = cell(ng, 1); vv = cell(ng, 1);
f0r = f0(rows);
for k = 1:ng
    cg = find(grp == k);
    yp = y;
    yp(cols(cg)) = yp(cols(cg)) + del(cg);
    fp = fun(yp);
    df = fp(rows) - f0r;
    [r, cidx] = find(S(:, cg));
    ii{k} = r; jj{k} = cg(cidx);
    vv{k} = df(r) ./ del(cg(cidx));
end
J = sparse(vertcat(ii{:}), vertcat(jj{:}), vertcat(vv{:}), numel(rows), nc);
end
