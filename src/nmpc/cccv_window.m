function R = cccv_window(par, soc0, soc1, Crate, Tamb, opt)
%CCCV_WINDOW  Sac CCCV cho mot vung SOC tren DFN day du (dung dfn_cccv.m).
%   R = cccv_window(par, soc0, soc1, Crate, Tamb)
% Bat dau: trang thai nghi can bang tai soc0 (dfn_state_soc.m), T = Tamb.
% CC: dong Crate.Q_nom (1C = 5 A, par.Qnom) toi khi V = 4.2 V HOAC SOC = soc1.
% CV: giu 4.2 V (rang buoc dai so) toi khi |I| <= C/50 HOAC SOC = soc1.
% Dieu kien dung nao den truoc thi dung (GD-25). Voi vung ket thuc < 100 %
% thuong dung o soc1 ngay trong pha CC. Neu DFN dung vi stoich be mat cuc
% am cham 1 - 1e-4 (su kien xsn_max, GD-16) truoc khi toi 4.2 V hay soc1 thi
% CCCV KHONG hoan thanh vung; R.complete = false va bao cao nguyen trang.
% R.T_CCCV [s]; lao hoa tam thoi hau kiem sau sac R.nsei, R.npl, R.ndl [mAh];
% R.perm [mAh] = mat vinh vien sau sac + xa ve SOC dau (eval_discharge.m).
if nargin < 6, opt = struct(); end
if ~isfield(opt, 'dt'), opt.dt = 10; end
if ~isfield(opt, 'tmax'), opt.tmax = 12*3600; end
if ~isfield(opt, 'Cdis'), opt.Cdis = Crate; end
Csoc = par.neg.Qcap*(par.neg.x100 - par.neg.x0);
Qstop = -(soc1 - soc0)*Csoc;
st = dfn_cccv(Crate*par.Qnom, v_limit(par), par.Qnom/50, Tamb, opt.tmax);
st(1).stop.Qstop = Qstop; st(2).stop.Qstop = Qstop;
y0 = dfn_state_soc(par, soc0, Tamb);
trk = aging_track('init', par);
tw = tic;
[o1, trk] = plant_run(par, y0, st(1), trk, struct('dt', opt.dt));
o = o1; reasons = o1.reason;
if strcmp(o1.reason{end}, 'Vmax')
    [o2, trk] = plant_run(par, o1.y_end, st(2), trk, struct('dt', opt.dt));
    f = fieldnames(o2);
    for i = 1:numel(f)
        if isnumeric(o2.(f{i})) && size(o2.(f{i}), 2) == 1 && ~strcmp(f{i}, 'nfev') && ~strcmp(f{i}, 'tsnap')
            v = o2.(f{i});
            if strcmp(f{i}, 't'), v = v + o1.t(end); end
            if strcmp(f{i}, 'step'), v = v + 1; end
            o.(f{i}) = [o1.(f{i}); v];
        end
    end
    o.y_end = o2.y_end; reasons = [reasons, o2.reason];
end
R.wall = toc(tw);
R.ser = o; R.reasons = reasons; R.reason = strjoin(reasons, '+');
R.T_CCCV = o.t(end);
R.soc_end = o.soc(end);
R.complete = any(strcmp(reasons{end}, {'Qstop', 'Icut'}));
R.nsei = trk.nsei; R.npl = trk.npl; R.ndl = trk.ndl;     % sau pha sac
R.pl_peak = max(o.npl - o.ndl);                         % lithium ma thuan nghich lon nhat khi sac (chan doan)
[R.dis, trk] = eval_discharge(par, o.y_end, trk, Tamb, opt.Cdis);   % chi so chung: sac + xa ve SOC dau
R.perm = R.dis.perm;
R.Vmax = max(o.V); R.Tmax = max(o.T); R.eta_min = min(o.eta_sep); R.xs_max = max(o.xs_sep);
R.trk = trk; R.y_end = o.y_end;
end
