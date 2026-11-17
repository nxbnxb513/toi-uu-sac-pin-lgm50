function [Un, Up, dUn, dUp] = dfn_ocp_mix(par, xsn, xsp, iapp, T)
%DFN_OCP_MIX  OCP hai dien cuc dung trong DFN (va ROM): chon nhanh / hysteresis.
%   xsn, xsp : stoichiometry be mat cuc am / duong;  iapp = I/A [A/m2] (I > 0 xa);  T [K]
%   Un, Up   : OCP [V] tai T;  dUn, dUp : he so entropy da nhan dUdT_scale [V/K]
% Cuc duong: hysteresis "current sigmoid" Li 2025 SI Note 7, pt. (S46)-(S47):
%   m = (1 + tanh(k (J + offset)))/2 (1: xa/nghi, 0: sac); Up = m U_lith + (1 - m) U_delith.
% Cuc am (GD-40, duyet 17/11/2026): par.ocp_n_branch = 'delith' (mac dinh) -> luon nhanh
%   delithiation (S4) (nhu O'Kane 2022, Chen 2020); 'hyst' -> (1 - m) U_lith + m U_delith (cu).
m = 0.5*(1 + tanh(par.hys.k*(iapp + par.hys.offset)));
if par.hys.n_delith, mn = 1; else, mn = m; end
[Unl, Und, dUn] = dfn_ocp_neg(xsn);
[Upl, Upd, dUp] = dfn_ocp_pos(xsp);
dUn = dUn*par.dUdT_scale/1e-3; dUp = dUp*par.dUdT_scale/1e-3;   % GD-08
Un = (1 - mn).*Unl + mn.*Und + (T - par.Tref).*dUn;
Up = m.*Upl + (1 - m).*Upd + (T - par.Tref).*dUp;
end
