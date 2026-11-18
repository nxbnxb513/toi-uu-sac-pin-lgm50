function ns = nmpc_steps(Ps, N, hI, nmin, nmax)
%NMPC_STEPS  So buoc IRK cho tung khoang du bao (GD-87, 18/11/2026).
% Newton cua IRK acados (Radau IIA 2 nac, khong tat dan, K khoi tao 0) phan ky ra NaN
% khi mot buoc tich phan nap qua nhieu dien tich trong pha dong lon: be mat hat cuc am
% doi nhanh va rat phi tuyen (D_s(x), OCP, j0 gan bao hoa), lap Newton day stoich cua
% vo hat ra ngoai [0, 1] (vd -6.9 va 4.9), Newton sinh ma cua z that bai => NaN
% (nmpc_irk_probe.m, run 44243336093). Vi vay chon so buoc sao cho DIEN TICH NAP MOI
% BUOC (A s) theo doan dau khong qua hI:
%   ns_k = min(nmax, max(nmin, ceil(dt_k * I_k / hI))),  dt_k = T_doan_dau / N,
%   I_k = dong lon nhat cua doan dau trong khoang k.
% Dien tich moi buoc gan nhu bat bien khi t_f doi (sac lau hon <=> dong nho hon), va
% khoang dau cua cac lan giai sau ngan hon / dong nho hon (dong giam dan) nen bang so
% buoc tinh tu doan dau o t = 0 la an toan cho ca vong kin.
%   Ps: mot hoac nhieu doan dau (cell) {P.t [s], P.I [A], P.t_end}; lay max theo tung khoang.
if ~iscell(Ps), Ps = {Ps}; end
if nargin < 3 || isempty(hI), hI = 36; end
if nargin < 4 || isempty(nmin), nmin = 8; end
if nargin < 5 || isempty(nmax), nmax = 96; end
ns = nmin*ones(1, N);
for j = 1:numel(Ps)
    P = Ps{j}; if isempty(P), continue; end
    tf = P.t_end; dt = tf/N; t = P.t(:); I = P.I(1:numel(t)); I = I(:);
    for k = 1:N
        a = (k-1)*dt; b = k*dt;
        i0 = find(t <= a + 1e-9, 1, 'last'); if isempty(i0), i0 = 1; end
        idx = [i0; find(t > a & t < b)];
        Ik = max(abs(I(idx)));
        ns(k) = max(ns(k), min(nmax, max(nmin, ceil(dt*Ik/hI))));
    end
end
end
