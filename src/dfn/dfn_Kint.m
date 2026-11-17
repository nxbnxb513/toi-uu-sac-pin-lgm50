function K = dfn_Kint(el, x, T, par)
%DFN_KINT  Tich phan Kirchhoff K(x, T) = int_0^x D_eff(s, T) ds [m^2/s], voi
%   D_eff = D_ref(x) exp(-E/R (1/T - 1/T_ref)) (1 + theta_M(T) (x c_max - c_ref))
% (Li 2025 SI pt. S17-S18 + khuech tan do ung suat, xem dfn_Ds.m, dfn_Ktable.m).
arr = exp(-el.Ds.E/par.R*(1/T - 1/par.Tref));
K = el.K1(x);
if par.stress_diffusion
    thetaM = el.Omega/(par.R*T) * 2*el.Omega*el.E/(9*(1 - el.nu));
    K = K*(1 - thetaM*el.c_ref) + thetaM*el.cmax*el.K2(x);
end
K = arr*K;
end
