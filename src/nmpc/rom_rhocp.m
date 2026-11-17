function rhocp = rom_rhocp(par, T, eps_region)
%ROM_RHOCP  Nhiet dung the tich hieu dung [J/m3/K]: CUNG cong thuc voi
% src/dfn/dfn_rhocp.m (Li 2025 SI pt. S20-S23; trung binh theo be day nhu
% PyBaMM lumped, GD-12), viet bang vong lap vo huong de chay voi CasADi SX.
% eps_region = [eps am, eps mang ngan, eps duong] (trung binh vung, BOL).
th = par.th;
Lk = [par.neg.L, par.sep.L, par.pos.L];
acc = th.rhocc_n*th.cpcc_n*th.Lcc_n + th.rhocc_p*th.cpcc_p*th.Lcc_p;
for k = 1:3
    p = th.cp_poly(k, :);
    cpd = p(1)*T^3 + p(2)*T^2 + p(3)*T + p(4);
    cpw = (th.rho_dry(k)*cpd + th.rho_l*th.cp_l*eps_region(k))/(th.rho_dry(k) + th.rho_l*eps_region(k));
    acc = acc + th.rho_wet(k)*cpw*Lk(k);
end
rhocp = acc/th.Ltot;
end
