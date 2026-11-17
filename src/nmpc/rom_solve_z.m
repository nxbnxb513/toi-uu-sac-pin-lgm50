function [z, ok, res] = rom_solve_z(M, x, I, Tamb, z0)
%ROM_SOLVE_Z  Giai rang buoc dai so g(x, z, I) = 0 cua ROM theo z (Newton co tat dan).
pz = [x(:); I; Tamb];
z = z0(:);
r = full(M.G(z, pz)); nr = norm(r, inf);
ok = false;
for it = 1:100
    if nr < 1e-10, ok = true; break; end
    J = full(M.Gz(z, pz));
    dz = -(J\r);
    if ~all(isfinite(dz)), break; end
    lam = 1; acc = false;
    while lam > 1e-6
        zt = z + lam*dz;
        rt = full(M.G(zt, pz));
        if all(isfinite(rt)) && norm(rt, inf) < (1 - 1e-4*lam)*nr
            acc = true; break;
        end
        lam = lam/2;
    end
    if ~acc, break; end
    z = zt; r = rt; nr = norm(rt, inf);
end
ok = ok || nr < 1e-8;
res = nr;
end
