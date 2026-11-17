function [Ulith, Udelith, dUdT] = dfn_ocp_pos(y)
%DFN_OCP_POS  OCP cuc duong (NMC811) hai nhanh va he so entropy.
% y: stoichiometry be mat. U [V], dUdT [V/K].
% Nguon: Li 2025 SI Note 8, pt. (S1) lithiation, (S2) delithiation, (S5) entropy
% (he so pt. S5 la mV/K, xem GD-08).
Ulith = -0.7983*y + 4.513 - 0.03269*tanh(19.83*(y - 0.5424)) ...
      - 18.23*tanh(14.33*(y - 0.2771)) + 18.05*tanh(14.46*(y - 0.2776));
Udelith = -0.7836*y + 4.513 - 0.03432*tanh(19.83*(y - 0.5424)) ...
      - 19.35*tanh(14.33*(y - 0.2771)) + 19.17*tanh(14.45*(y - 0.2776));
if nargout > 2
    dUdT = 1e-3*(0.04006*exp(-(y - 0.2828).^2/0.0009855) ...
               - 0.06656*exp(-(y - 0.8032).^2/0.02179));
end
end
