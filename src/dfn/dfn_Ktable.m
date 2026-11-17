function el = dfn_Ktable(el)
%DFN_KTABLE  Bang tich phan Kirchhoff cua D_s theo stoichiometry (tai T_ref):
%   K1(x) = int_0^x D_ref(s) ds,   K2(x) = int_0^x s D_ref(s) ds
% voi D_ref(x) = R_cor 10^(...) theo Li 2025 SI pt. (S17) (xem dfn_Ds.m).
% Thong luong khuech tan giua hai vo cau ke nhau duoc tinh bang
%   D dx/dr ~ (K(x_{i+1}) - K(x_i))/dr,
% tuc D trung binh tich phan tren doan [x_i, x_{i+1}]. Cach nay luon don dieu
% (dK/dx = D > 0) du D_s(x) co cac dinh/hom Gauss rat hep (do rong ~0.025):
% lay D tai diem giua co the cho "khuech tan am" ve mat so hoc khi chenh lech
% stoich giua hai vo lon hon do rong cua dinh. (GD-15)
xg = linspace(-0.1, 1.1, 12001).';
h  = xg(2) - xg(1);
xm = xg(1:end-1) + h/2;
D0 = dref(el, xg); Dm = dref(el, xm);
dK1 = h/6*(D0(1:end-1) + 4*Dm + D0(2:end));                       % Simpson
dK2 = h/6*(xg(1:end-1).*D0(1:end-1) + 4*xm.*Dm + xg(2:end).*D0(2:end));
K1 = [0; cumsum(dK1)]; K2 = [0; cumsum(dK2)];
i0 = find(xg >= 0, 1);
K1 = K1 - K1(i0); K2 = K2 - K2(i0);
el.K1 = griddedInterpolant(xg, K1, 'pchip', 'linear');
el.K2 = griddedInterpolant(xg, K2, 'pchip', 'linear');
end

function D = dref(el, x)
a = el.Ds.a; b = el.Ds.b; c = el.Ds.c;
lg = a(1)*x + b(1);
for i = 2:5
    if a(i) ~= 0, lg = lg + a(i)*exp(-(x - b(i)).^2/c(i)); end
end
D = el.Ds.Rcor*10.^lg;
end
