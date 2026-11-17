function [Un, Up, dUn, dUp] = rom_ocp(par, xsn, xsp, iapp, T)
%ROM_OCP  OCP hai dien cuc dung trong ROM: PHAI trung logic nhanh/hysteresis
% cua DFN mac dinh (src/dfn/dfn_rhs.m). rom_unit_tests.m so tung so voi
% aux.Un, aux.Up cua dfn_rhs khi sac va khi xa - neu DFN doi logic (vi du
% cuc am dung MOT nhanh, quyet dinh 17/11/2026) ma ham nay chua doi theo,
% kiem tra se bao loi.
% Neu src/dfn co ham chung dfn_ocp_mix (tach tu dfn_rhs), dung truc tiep no.
if exist('dfn_ocp_mix', 'file')
    [Un, Up, dUn, dUp] = dfn_ocp_mix(par, xsn, xsp, iapp, T);
    return
end
m = 0.5*(1 + tanh(par.hys.k*(iapp + par.hys.offset)));   % 1: xa/nghi, 0: sac
[Unl, Und, dUn] = dfn_ocp_neg(xsn);
[Upl, Upd, dUp] = dfn_ocp_pos(xsp);
dUn = dUn*par.dUdT_scale/1e-3; dUp = dUp*par.dUdT_scale/1e-3;
mn = m;
if isfield(par.hys, 'neg_single_branch') && par.hys.neg_single_branch, mn = 1; end   % cuc am: chi nhanh xa
Un = (1 - mn)*Unl + mn*Und + (T - par.Tref)*dUn;
Up = m*Upl + (1 - m)*Upd + (T - par.Tref)*dUp;
end
