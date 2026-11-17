function [D, trk] = eval_discharge(par, y, trk, Tamb, Crate)
%EVAL_DISCHARGE  Chi so lao hoa dung CHUNG cho moi phuong phap (CCCV, NMPC):
% sau lan sac, xa DFN ve lai SOC dau vung (Q = 0, Q tinh tu dau vung) voi dong
% khong doi Crate.Q_nom (GD-32), de lithium ma thuan nghich boc lai. Bo dem lao
% hoa hau kiem (aging_track.m) chay tiep qua pha xa.
%   Mat VINH VIEN = SEI (sac + xa) + lithium chet (sac + xa)          [mAh]
%   Chan doan: lithium ma thuan nghich con lai sau xa, va dinh khi sac.
st = struct('mode', 'I', 'value', Crate*par.Qnom, 'tmax', 6*3600, 'Tamb', Tamb, ...
    'stop', struct('Qstop', 0, 'Vmin', par.Vmin), 'tout', []);
[o, trk] = plant_run(par, y, st, trk, struct('dt', 10));
D.reason = o.reason{end}; D.t = o.t(end);
D.nsei = trk.nsei; D.ndl = trk.ndl;
D.pl_rev_left = trk.npl - trk.ndl;              % lithium ma thuan nghich chua boc lai
D.perm = trk.nsei + trk.ndl;
D.y_end = o.y_end;
end
