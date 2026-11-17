function j0 = dfn_j0(el, ce, xs, T, par)
%DFN_J0  Mat do dong trao doi cua phan ung dan xen [A/m^2].
% Nguon: Li 2025 SI Note 11 pt. (S26) cuc duong, (S27) cuc am:
%   j0 = j_ref exp(-E/R (1/T - 1/298.15)) (ce/<ce>)^(1-al) xs^al (1 - xs)^(1-al)
% <ce> = par.ce_ref = 1000 mol/m3 (GD-06).
al = el.j0_al;
j0 = el.j0_ref * exp(-el.j0_E/par.R*(1/T - 1/par.Tref)) ...
     .* (ce/par.ce_ref).^(1 - al) .* xs.^al .* (1 - xs).^(1 - al);
end
