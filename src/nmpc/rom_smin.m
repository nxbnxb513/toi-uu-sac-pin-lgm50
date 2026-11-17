function v = rom_smin(a, b, ep)
%ROM_SMIN  min(a, b) tron:  a - sp(a - b),  sp(u) = (u + sqrt(u^2 + ep^2))/2.
% sp(u) >= max(u, 0) va lech toi da ep/2 (tai u = 0); khi |u| >> ep lech ~ ep^2/(4|u|).
u = a - b;
v = a - (u + sqrt(u.^2 + ep^2))/2;
end
