function v = rom_smax(a, b, ep)
%ROM_SMAX  max(a, b) tron:  b + sp(a - b),  sp(u) = (u + sqrt(u^2 + ep^2))/2.
u = a - b;
v = b + (u + sqrt(u.^2 + ep^2))/2;
end
