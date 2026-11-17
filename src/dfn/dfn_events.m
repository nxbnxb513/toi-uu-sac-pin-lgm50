function [val, term, dirn] = dfn_events(t, y, par, ctl)
%DFN_EVENTS  Su kien dung cho ode15s: Vmin, Vmax, |I| <= Icut, Q = Qstop,
% dien giai can kiet (ce_min <= 1 mol/m3), va stoichiometry be mat hat cham
% gioi han 0 hoac 1 (tai do j0 -> 0 va mo hinh suy bien; PyBaMM cung dung mo
% phong tai day voi su kien "particle surface stoichiometry").
[~, a] = dfn_rhs(t, y, par, ctl);
s = ctl.stop;
val = ones(9,1);
if ~isnan(s.Vmin),  val(1) = a.V - s.Vmin; end
if ~isnan(s.Vmax),  val(2) = s.Vmax - a.V; end
if ~isnan(s.Icut),  val(3) = abs(a.I) - s.Icut; end
if ~isnan(s.Qstop), val(4) = a.Q - s.Qstop; end
val(5) = a.ce_min - 1;
tol = 1e-4;
val(6) = (1 - tol) - max(a.thsn);
val(7) = min(a.thsn) - tol;
val(8) = (1 - tol) - max(a.thsp);
val(9) = min(a.thsp) - tol;
term = ones(9,1);
dirn = [-1; -1; -1; 0; -1; -1; -1; -1; -1];
end
