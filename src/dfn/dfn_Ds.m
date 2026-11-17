function D = dfn_Ds(el, x, T, par)
%DFN_DS  He so khuech tan pha ran D_s(x, T) [m^2/s].
% el: par.neg hoac par.pos. x: stoichiometry (mang bat ky). T [K].
% Nguon: Li 2025 SI Note 11 pt. (S17), (S18); he so Supplementary Table 7.
%   log10(D_ref/R_cor) = a0 x + b0 + sum_{i=1..4} a_i exp(-(x - b_i)^2/c_i)
%   D = D_ref exp(-E_act/R (1/T - 1/T_ref))
a = el.Ds.a; b = el.Ds.b; c = el.Ds.c;
lg = a(1)*x + b(1);
for i = 2:5
    if a(i) ~= 0
        lg = lg + a(i)*exp(-(x - b(i)).^2/c(i));
    end
end
D = el.Ds.Rcor * 10.^lg * exp(-el.Ds.E/par.R*(1/T - 1/par.Tref));
% Khuech tan do ung suat (xem dfn_params.m, GD-10): c = x.c_max la nong do cuc bo
if par.stress_diffusion
    thetaM = el.Omega/(par.R*T) * 2*el.Omega*el.E/(9*(1 - el.nu));   % m3/mol
    D = D .* (1 + thetaM*(x*el.cmax - el.c_ref));
end
end
