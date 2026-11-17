function [D, trk] = eval_discharge(par, y, trk, Tamb, Crate)
%EVAL_DISCHARGE  Chi so lao hoa dung CHUNG cho moi phuong phap (CCCV, NMPC):
% sau lan sac, xa DFN ve lai SOC dau vung (Q = 0, Q tinh tu dau vung) voi dong
% khong doi Crate.Q_nom (GD-32), de lithium ma thuan nghich boc lai. Bo dem lao
% hoa hau kiem (aging_track.m) chay tiep qua pha xa.
%   Mat VINH VIEN = SEI (sac + xa) + lithium chet (sac + xa)          [mAh]
%                   (+ lithium mat theo LAM khi DFN co lao hoa, aging_from_plant.m)
%   Chan doan: lithium ma thuan nghich con lai sau xa, va dinh khi sac.
st = struct('mode', 'I', 'value', Crate*par.Qnom, 'tmax', 6*3600, 'Tamb', Tamb, ...
    'stop', struct('Qstop', 0, 'Vmin', par.Vmin), 'tout', []);
[o, trk] = plant_run(par, y, st, trk, struct('dt', 10));
D.reason = o.reason{end}; D.t = o.t(end);
D.nsei = trk.nsei; D.ndl = trk.ndl;
D.pl_rev_left = trk.npl - trk.ndl;              % lithium ma thuan nghich chua boc lai
D.nlam = 0; if isfield(trk, 'nlam'), D.nlam = trk.nlam; end   % Li trong vat lieu mat (LAM), chi khi DFN co lao hoa
D.perm = trk.nsei + trk.ndl + D.nlam;
D.source = 'posthoc_provisional';
if isfield(trk, 'source'), D.source = trk.source; end   % 'plant' khi DFN da co lao hoa (aging_from_plant.m)
D.y_end = o.y_end;
end
