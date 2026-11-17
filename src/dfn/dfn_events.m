function [val, term, dirn] = dfn_events(t, y, par, ctl)
%DFN_EVENTS  Su kien dung cho ode15s: Vmin, Vmax, |I| <= Icut, Q = Qstop,
% dien giai can kiet (ce_min <= 1 mol/m3, bao ve so hoc).
[~, a] = dfn_rhs(t, y, par, ctl);
s = ctl.stop;
val = ones(5,1);
if ~isnan(s.Vmin),  val(1) = a.V - s.Vmin; end
if ~isnan(s.Vmax),  val(2) = s.Vmax - a.V; end
if ~isnan(s.Icut),  val(3) = abs(a.I) - s.Icut; end
if ~isnan(s.Qstop), val(4) = a.Q - s.Qstop; end
val(5) = a.ce_min - 1;
term = ones(5,1);
dirn = [-1; -1; -1; 0; -1];
end
