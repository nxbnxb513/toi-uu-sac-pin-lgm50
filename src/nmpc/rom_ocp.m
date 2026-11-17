function [Un, Up, dUn, dUp] = rom_ocp(par, xsn, xsp, iapp, T)
%ROM_OCP  OCP hai dien cuc cua ROM = CHINH ham chung cua DFN src/dfn/dfn_ocp_mix.m
% (nhanh cuc am theo par.ocp_n_branch, mac dinh 'delith' - GD-40, duyet 17/11/2026;
% cuc duong hysteresis S46-S47). rom_unit_tests.m muc 6 so tung so voi dfn_rhs.m.
[Un, Up, dUn, dUp] = dfn_ocp_mix(par, xsn, xsp, iapp, T);
end
