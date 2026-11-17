function [rsei, jpl, etapl] = aging_rates(ap, par, dphi, jtot, ce, T, cLi)
%AGING_RATES  Toc do mat lithium do SEI va ma lithium tai cac nut cuc am.
% MOT nguon cong thuc duy nhat, dung cho ca ROM (CasADi SX, trong acados) va
% cho cham diem hau kiem tren quy dao DFN (so thuc). Chi dung phep toan tung
% phan tu nen chay voi double va SX nhu nhau.
%
% Vao (vector cot theo nut cuc am, T vo huong):
%   dphi = phi_s - phi_e [V];  jtot = mat do dong be mat tong [A/m2] (> 0 anod)
%   ce [mol/m3] dien giai cuc bo;  T [K];  cLi [mol/m3 dien cuc] lithium ma thuan nghich
% Ra:
%   rsei  [mol Li/(m3 dien cuc . s)] >= 0: SEI tren be mat goc + SEI tren vet nut
%         = a_n S0 (D_int c_int / L_outer) exp(-F dphi/(R T)) exp(E_SEI/R (1/T_ref - 1/T))
%         (dac_ta_lao_hoa.md muc 3 va 6.2; so mu co F/(RT), khong tru sut ap mang:
%          Single 2018 pt. (5), von Kolzenberg 2020 pt. (18), (25) - gia_dinh.md muc 1)
%   jpl   [A/m2] dong ma/hoa tan (< 0 khi ma), dac_ta_lao_hoa.md muc 4:
%         F k_Li [ cLi exp(alpha_a F eta/(RT)) - ce exp(-alpha_c F eta/(RT)) ]
%   etapl [V] the ma lithium eta_Li = phi_s - phi_e - rho_SEI L_SEI j_tot
%         (= aux.eta_pl_min cua dfn_rhs.m tai tung nut)
%
% So mu duoc chan tren TRON o 40 (exp(40) = 2e17; tuong ung |eta| > 3 V hoac
% phi_s - phi_e < -1 V - ngoai xa vung vat ly) de bieu thuc khong tran so
% (0 x Inf = NaN) khi bo giai thu cac diem lap xa. Trong vung vat ly
% (so mu < 30) so mu lech < 3e-6, tuc sai lech tuong doi < 3e-6.
f     = par.F/(par.R*T);
arr   = exp(ap.E_SEI/par.R*(1/par.Tref - 1/T));
rsei  = (ap.as_n*ap.S0*ap.D_int*ap.c_int/ap.L_outer0*arr)*exp(capx(-f*dphi));
etapl = dphi - ap.Rfilm*jtot;
jpl   = par.F*ap.k_Li*(cLi.*exp(capx(ap.alpha_a*f*etapl)) - ce.*exp(capx(-ap.alpha_c*f*etapl)));
end

function v = capx(a)
v = rom_smin(a, 40, 0.01);
end
