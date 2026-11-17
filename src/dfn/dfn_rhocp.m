function rhocp = dfn_rhocp(par, T, ag)
%DFN_RHOCP  Nhiet dung the tich hieu dung cua cell [J/m^3/K].
% Trung binh theo be day cac lop (current collector am, cuc am, mang ngan,
% cuc duong, current collector duong) nhu mo hinh lumped cua PyBaMM ma Li 2025
% dung ([code] thermal_parameters.py: rho_c_p_eff).
% Nhiet dung rieng cua lop da tham dien giai: Li 2025 SI Note 11 pt. (S20):
%   theta = rho_s C_p,s(T) + rho_l C_p,l eps_l ;  c_p,wet = theta / (rho_s + rho_l eps_l)
% voi rho_s la mat do lop xop kho, C_p,s(T) theo pt. (S21)-(S23).
th = par.th; g = par.grid;
eps_l = [mean(ag.eps(g.in)), mean(ag.eps(g.is)), mean(ag.eps(g.ip))];
cp_dry = th.cp_poly(:,1).'*T^3 + th.cp_poly(:,2).'*T^2 + th.cp_poly(:,3).'*T + th.cp_poly(:,4).';
cp_wet = (th.rho_dry.*cp_dry + th.rho_l*th.cp_l*eps_l)./(th.rho_dry + th.rho_l*eps_l);
Lk = [par.neg.L, par.sep.L, par.pos.L];
rhocp = (th.rhocc_n*th.cpcc_n*th.Lcc_n + sum(th.rho_wet.*cp_wet.*Lk) ...
       + th.rhocc_p*th.cpcc_p*th.Lcc_p)/th.Ltot;
end
