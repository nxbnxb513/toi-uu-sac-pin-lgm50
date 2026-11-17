function y = dfn_state_soc(par, soc, T0)
%DFN_STATE_SOC  Trang thai nghi can bang cua DFN tai SOC cho truoc, tren duong
% can bang lithium di qua diem 100 % SOC cua Li 2025 (x100 = 0.8771,
% y100 = 0.2411; cung cach voi src/dfn/dfn_state_from_ocv.m, GD-13):
%   q  = (1 - soc) Csoc,  Csoc = Qcap_n (x100 - x0)   [Ah]
%   xn = x100 - q/Qcap_n, yp = y100 + q/Qcap_p
% SOC dinh nghia theo cuc am: soc = (x_avg - x0)/(x100 - x0) (GD-24).
Csoc = par.neg.Qcap*(par.neg.x100 - par.neg.x0);
q  = (1 - soc)*Csoc;
xn = par.neg.x100 - q/par.neg.Qcap;
yp = par.pos.y100 + q/par.pos.Qcap;
y  = dfn_init_state(par, xn, yp, T0);
end
