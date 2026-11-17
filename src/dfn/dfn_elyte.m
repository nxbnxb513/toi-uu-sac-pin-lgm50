function [De, kap, tp, tdf] = dfn_elyte(ce, T)
%DFN_ELYTE  Tinh chat dien giai EC:EMC 3:7 + LiPF6 (Landesfeind & Gasteiger 2019).
% ce [mol/m^3] (mang), T [K] (vo huong).
%   De  [m^2/s]  he so khuech tan         Li 2025 SI Note 10 pt. (S13)
%   kap [S/m]    do dan ion               pt. (S14)
%   tp  [-]      so van chuyen cation     pt. (S15)
%   tdf [-]      thermodynamic factor     pt. (S16)
% Gioi han bao hoa 4000 mol/m3: pt. (S12).
% Hai he so in trong SI khac voi ma nguon cua chinh bai bao; o day dung gia
% tri cua ma nguon ([code] OKane2023.py, trung voi Landesfeind 2019), vi gia
% tri in cho ket qua phi vat ly (xem GD-03, GD-04):
%   (S14) SI in 0.8353, ma nguon 0.353  (kappa(1M, 25C) = 0.91 S/m thay vi 2.4)
%   (S15) SI in -0.612, ma nguon -6.12  (t+(1M, 25C) = 0.22 thay vi 5.7)
% (S13) SI in "10^-10 . 1010": doc la 1010 x 1e-10 ([code] coeffs 1.01e3).
c = min(ce, 4000)/1000;          % mol/L, pt. (S12)
eT = exp(1000/T);
De  = 1e-10 * 1010 * exp(1.01*c) .* exp(-1560/T) .* exp(-487*c/T);
kap = 0.1 * 0.521 * (1 + (T - 228)) * c ...
      .* (1 - 1.06*sqrt(c) + 0.353*(1 - 0.00359*eT)*c) ...
      ./ (1 + c.^4 * (0.00148*eT));
if nargout > 2
    tp  = -12.8 - 6.12*c + 0.0821*T + 0.904*c.^2 + 0.0318*c*T ...
          - 1.27e-4*T^2 + 0.0175*c.^3 - 3.12e-3*c.^2*T - 3.96e-5*c*T^2;
    tdf = 25.7 - 45.1*c - 0.177*T + 1.94*c.^2 + 0.295*c*T ...
          + 3.08e-4*T^2 + 0.259*c.^3 - 9.46e-3*c.^2*T - 4.54e-4*c*T^2;
end
end
