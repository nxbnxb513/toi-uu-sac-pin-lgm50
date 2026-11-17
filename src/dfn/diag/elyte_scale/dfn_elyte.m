function [De, kap, tp, tdf] = dfn_elyte(ce, T, par)
%DFN_ELYTE (BAN CHAN DOAN, chi dung trong cac bien the 'kap_x3', 'De_x10' cua
% diag_variant): giong het src/dfn/dfn_elyte.m (Landesfeind 2019 qua Li 2025 SI
% (S12)-(S16)), nhung nhan kappa voi par.diag.kfac va D_e voi par.diag.Dfac.
c = min(ce, 4000)/1000;
eT = exp(1000/T);
De  = 1e-10 * 1010 * exp(1.01*c) .* exp(-1560/T) .* exp(-487*c/T);
kap = 0.1 * 0.521 * (1 + (T - 228)) * c ...
      .* (1 - 1.06*sqrt(c) + par.el.k4*(1 - 0.00359*eT)*c) ...
      ./ (1 + c.^4 * (0.00148*eT));
De = De*par.diag.Dfac; kap = kap*par.diag.kfac;
if nargout > 2
    tp  = -12.8 + par.el.tp2*c + 0.0821*T + 0.904*c.^2 + 0.0318*c*T ...
          - 1.27e-4*T^2 + 0.0175*c.^3 - 3.12e-3*c.^2*T - 3.96e-5*c*T^2;
    tdf = 25.7 - 45.1*c - 0.177*T + 1.94*c.^2 + 0.295*c*T ...
          + 3.08e-4*T^2 + 0.259*c.^3 - 9.46e-3*c.^2*T - 4.54e-4*c*T^2;
    if ~par.el.use_tdf, tdf = ones(size(c)); end
end
end
