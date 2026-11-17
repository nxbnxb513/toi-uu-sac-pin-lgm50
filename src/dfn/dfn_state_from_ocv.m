function [y, q, xn, yp] = dfn_state_from_ocv(par, Vrest, T0)
%DFN_STATE_FROM_OCV  Trang thai can bang co ap ho mach bang Vrest tai T0.
% Trang thai nam tren duong can bang lithium di qua diem 100 % SOC cua
% Li 2025 (x100 = 0.8771, y100 = 0.2411; SI Table 6: 28543 va 12727 mol/m3):
%   xn = x100 - q/Qcap_n,   yp = y100 + q/Qcap_p,
% q [Ah] la dien luong da xa tinh tu diem 100 % SOC (q co the hoi am).
% OCV dung nhanh xa (trang thai nghi, xem dfn_init_state.m).
lo = -0.4; hi = 4.9;          % Ah
vlo = ocv(lo); vhi = ocv(hi);
if ~(Vrest <= vlo && Vrest >= vhi)
    error('dfn_state_from_ocv: Vrest = %.4f V nam ngoai khoang OCV [%.4f, %.4f]', Vrest, vhi, vlo);
end
for it = 1:80
    mid = 0.5*(lo + hi);
    if ocv(mid) > Vrest, lo = mid; else, hi = mid; end
end
q = 0.5*(lo + hi);
[~, xn, yp] = ocv(q);
y = dfn_init_state(par, xn, yp, T0);

    function [v, xn_, yp_] = ocv(qq)
        xn_ = par.neg.x100 - qq/par.neg.Qcap;
        yp_ = par.pos.y100 + qq/par.pos.Qcap;
        m = 0.5*(1 + tanh(par.hys.k*par.hys.offset));
        [Unl, Und, dUn] = dfn_ocp_neg(xn_);
        [Upl, Upd, dUp] = dfn_ocp_pos(yp_);
        dUn = dUn*par.dUdT_scale/1e-3; dUp = dUp*par.dUdT_scale/1e-3;
        v = m*Upl + (1 - m)*Upd + (T0 - par.Tref)*dUp ...
          - ((1 - m)*Unl + m*Und + (T0 - par.Tref)*dUn);
    end
end
