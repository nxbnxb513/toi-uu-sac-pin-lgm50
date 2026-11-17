function el = diag_Ktable(el, xlo, xhi)
%DIAG_KTABLE  Nhu dfn_Ktable nhung D_ref(x) = D_ref(min(max(x, xlo), xhi)):
% ham (S17) chi duoc dung trong khoang [xlo, xhi], ngoai khoang giu hang so.
xg = linspace(-0.1, 1.1, 12001).';
h  = xg(2) - xg(1);
xm = xg(1:end-1) + h/2;
D0 = dref(el, min(max(xg, xlo), xhi)); Dm = dref(el, min(max(xm, xlo), xhi));
dK1 = h/6*(D0(1:end-1) + 4*Dm + D0(2:end));
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
