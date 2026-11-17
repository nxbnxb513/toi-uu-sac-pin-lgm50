function [xa, P] = ekf_init(E, c, soc_guess, T0)
%EKF_INIT  Uoc luong ban dau va hiep phuong sai ban dau P0 (GD-74).
%   soc_guess: SOC doan ban dau (vd. lay tu bang OCV - o day CO Y lam sai +/-10 %)
%   T0 [K]: nhiet do do duoc o mau dau tien
% x0: trang thai nghi can bang tai soc_guess tren duong can bang lithium BOL
% (dfn_state_soc.m, GD-13/GD-24) anh xa sang ROM (rom_from_dfn.m); rf = 1 (BOL).
% P0 = s_soc^2 v v' + s_lli^2 w w' + diag(...):
%   v = dx/dSOC doc duong can bang (hai cuc cung dich chuyen, cung luong lithium)
%   w = dx/dQ_LLI: cuc duong it lithium hon, cuc am giu nguyen (mat lithium)
par = E.par; rom = E.rom; ix = E.ix; nx = E.nx;
y = dfn_state_soc(par, soc_guess, T0);
x = rom_from_dfn(rom, par, y);
x(ix.T) = T0;
xa = [x; 1];
v = zeros(nx, 1); w = zeros(nx, 1);
v(ix.thn) = E.x100n - E.x0n;
v(ix.thp) = -E.Qn*(E.x100n - E.x0n)/E.Qp;
w(ix.thp) = -1/E.Qp;
d = zeros(nx, 1);
d([ix.thn; ix.thp]) = c.P0.th^2; d(ix.ce) = c.P0.ce^2; d(ix.T) = c.P0.T^2;
fi = E.fi;
P = zeros(E.na);
P(1:E.nf, 1:E.nf) = c.P0.soc^2*(v(fi)*v(fi).') + c.P0.lli^2*(w(fi)*w(fi).') + diag(d(fi));
P(end, end) = c.P0.rf^2;
end
