function [y, ok, nit] = dfn_consistent_init(t, y, par, ctl)
%DFN_CONSISTENT_INIT  Khoi tao nhat quan cho DAE: giu nguyen trang thai vi phan,
% giai cac phuong trinh dai so g(y_d, z) = 0 theo z bang Newton co tat dan
% (line search), Jacobian sai phan thua. Neu Newton truc tiep that bai o che
% do dong, dung phep tiep dien (continuation) theo dong tu gia tri hien tai.
ix = par.ix;
[y1, ok, nit] = newton(t, y, par, ctl);
if ok, y = y1; return; end
if strcmp(ctl.mode, 'I')
    if isa(ctl.value, 'function_handle'), Itar = ctl.value(t); else, Itar = ctl.value; end
    I0 = y(ix.I);
    for nsub = [4 16 64 256]
        yk = y; ok = true;
        for s = 1:nsub
            c2 = ctl; c2.value = I0 + (Itar - I0)*s/nsub;
            [yk, ok, n2] = newton(t, yk, par, c2);
            nit = nit + n2;
            if ~ok, break; end
        end
        if ok, y = yk; return; end
    end
end
ok = false;
end

function [y, ok, it] = newton(t, y, par, ctl)
ia = par.ia;
tol = 1e-8;
ok = false;
fun = @(yy) dfn_rhs(t, yy, par, ctl);
f = fun(y);
if ~all(isfinite(f)) || ~isreal(f), it = 0; return; end
nrm = norm(f(ia), inf);
for it = 1:60
    if nrm < tol, ok = true; return; end
    J = dfn_numjac(fun, y, f, ia, ia, par.Saa, par.grp_aa);
    dz = -(J\f(ia));
    if ~all(isfinite(dz)), return; end
    lam = 1; accepted = false;
    while lam > 1e-5
        yt = y; yt(ia) = y(ia) + lam*dz;
        ft = fun(yt);
        if all(isfinite(ft)) && isreal(ft)
            nt = norm(ft(ia), inf);
            if nt < (1 - 1e-4*lam)*nrm
                accepted = true; break;
            end
        end
        lam = lam/2;
    end
    if ~accepted
        % khong giam duoc nua: chap nhan neu thang du da nho
        ok = nrm < 1e-6; return;
    end
    y = yt; f = ft; nrm = nt;
end
ok = nrm < 1e-6;
end
