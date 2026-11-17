function x = init_state(p, soc, T0)
%INIT_STATE  Trang thai can bang tai muc SOC cho truoc (0..1) va nhiet do T0 [K].
%   SOC dinh nghia theo he so ti luong trung binh cua dien cuc am.
ix = state_index(p);
xn = p.n.x0 + soc*(p.n.x100 - p.n.x0);
% Bao toan Li: dien cuc duong nhan luong Li ma dien cuc am nha ra.
yp = p.p.y100 + (1 - soc)*(p.n.x100 - p.n.x0)*p.nLi_n/p.nLi_p;

x = zeros(ix.n, 1);
x(ix.cn)   = xn*p.n.cmax;
x(ix.cp)   = yp*p.p.cmax;
x(ix.ce)   = p.ce0;
x(ix.T)    = T0;
x(ix.Lsei) = p.sei.L0;
x(ix.cLi)  = 0;
x(ix.cdl)  = 0;
x(ix.Qsei) = 0;
end
