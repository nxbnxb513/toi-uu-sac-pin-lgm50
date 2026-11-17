function [Up, Un, dUp, dUn] = ocp(y, x)
%OCP  The ho mach cua hai dien cuc va he so entropy.
%   y: he so ti luong be mat dien cuc duong, x: dien cuc am.
%   Up, Un [V]     - Chen 2020, pt. (8) va (9)
%   dUp, dUn [V/K] - Li 2025, SI Note 8, pt. (S5) va (S6).
%   GIA DINH: he so cua (S5), (S6) co don vi mV/K (bai in "V/K").

y = min(max(y, 1e-4), 1-1e-4);
x = min(max(x, 1e-4), 1-1e-4);

Up = -0.8090*y + 4.4875 ...
     - 0.0428*tanh(18.5138*(y - 0.5542)) ...
     - 17.7326*tanh(15.7890*(y - 0.3117)) ...
     + 17.5842*tanh(15.9308*(y - 0.3120));

Un = 1.9793*exp(-39.3631*x) + 0.2482 ...
     - 0.0909*tanh(29.8538*(x - 0.1234)) ...
     - 0.04478*tanh(14.9159*(x - 0.2769)) ...
     - 0.0205*tanh(30.4444*(x - 0.6103));

if nargout > 2
    dUp = 1e-3*(0.04006*exp(-(y - 0.2828).^2/0.0009855) ...
              - 0.06656*exp(-(y - 0.8032).^2/0.02179));
    dUn = 1e-3*(-0.111*x + 0.02901 ...
              + 0.3562*exp(-(x - 0.08308).^2/0.004621));
end
end
