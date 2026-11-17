function [De, kap, tp, tdf] = rom_elyte(ce, T, par)
%ROM_ELYTE  Tinh chat dien giai cho ROM: CUNG cong thuc va he so voi
% src/dfn/dfn_elyte.m (Landesfeind & Gasteiger 2019; Li 2025 SI pt. S12-S16,
% par.el.k4 / par.el.tp2 / par.el.use_tdf cua bo tham so dang dung). Khac duy
% nhat: chan tren 4000 mol/m3 cua pt. (S12) viet bang ham min TRON (rom_smin)
% de NMPC co dao ham lien tuc; lech so voi min that < 3e-8 mol/m3 khi ce < 3999.
% Chay voi double va CasADi SX. rom_unit_tests.m so tung so voi dfn_elyte.m.
c  = rom_smin(ce, 4000, 1e-2)/1000;
eT = exp(1000/T);
De  = 1e-10 * 1010 * exp(1.01*c) .* exp(-1560/T) .* exp(-487*c/T);
kap = 0.1 * 0.521 * (1 + (T - 228)) * c ...
      .* (1 - 1.06*sqrt(c) + par.el.k4*(1 - 0.00359*eT)*c) ...
      ./ (1 + c.^4 * (0.00148*eT));
if nargout > 2
    tp  = -12.8 + par.el.tp2*c + 0.0821*T + 0.904*c.^2 + 0.0318*c*T ...
          - 1.27e-4*T^2 + 0.0175*c.^3 - 3.12e-3*c.^2*T - 3.96e-5*c*T^2;
    tdf = 25.7 - 45.1*c - 0.177*T + 1.94*c.^2 + 0.295*c*T ...
          + 3.08e-4*T^2 + 0.259*c.^3 - 9.46e-3*c.^2*T - 4.54e-4*c*T^2;
    if ~par.el.use_tdf, tdf = 0*c + 1; end
end
end
