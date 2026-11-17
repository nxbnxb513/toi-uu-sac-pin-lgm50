function [out, trk] = plant_run(par, y0, steps, trk, popt)
%PLANT_RUN  Chay "pin that" = DFN day du (src/dfn) cho mot chuoi buoc, giong
% dfn_run.m (cung khoi tao nhat quan, ode15s, su kien dung dfn_events.m), va:
%   - xuat ket qua tai luoi deu popt.dt [s] (mac dinh 5 s) gom ca cac dai luong
%     phia mang ngan (stoich be mat, phi_s - phi_e, the ma lithium) tai nut DFN
%     cuc am sat mang ngan nhat;
%   - cham diem lao hoa TAM THOI hau kiem (aging_track.m): tich phan toc do SEI
%     va ma lithium (aging_rates.m, CUNG cong thuc voi ROM/NMPC) doc theo quy dao;
%     neu par.aging.on (DFN co lao hoa, buoc C) thi dung lao hoa CUA DFN
%     (aging_from_plant.m), cot trk.source ghi ro nguon.
% Khong sua src/dfn: chi goi dfn_consistent_init, dfn_rhs, dfn_events.
%
% steps(k): nhu dfn_run.m (.mode 'I'|'V'|'rest', .value, .tmax, .Tamb, .stop, .tout)
% trk: trang thai bo dem lao hoa (aging_track('init', par)); popt.dt, popt.snap
% (cac thoi diem [s, tinh tu dau chuoi] can luu trang thai DFN day du).
if nargin < 5 || isempty(popt), popt = struct(); end
if ~isfield(popt, 'dt'), popt.dt = 5; end
if ~isfield(popt, 'snap'), popt.snap = []; end
ix = par.ix;
ap = aging_params(par);
y = y0; t0 = 0;
f = {'t', 'V', 'I', 'T', 'Q', 'soc', 'xs_sep', 'xs_max', 'xsp_min', 'dphi_sep', 'eta_sep', 'eta_min', 'nsei', 'npl', 'ndl', 'step'};
for i = 1:numel(f), out.(f{i}) = []; end
out.reason = cell(1, numel(steps)); out.nfev = zeros(1, numel(steps));
out.Ysnap = []; out.tsnap = [];
for k = 1:numel(steps)
    ctl = make_ctl(steps(k));
    [y, ok] = dfn_consistent_init(0, y, par, ctl);
    if ~ok
        out.reason{k} = 'init_failed'; break;
    end
    nfev = 0;
    f0 = dfn_rhs(0, y, par, ctl);
    yp0 = zeros(ix.ny, 1); yp0(par.id) = f0(par.id);
    opts = odeset('Mass', par.M, 'MassSingular', 'yes', 'MStateDependence', 'none', ...
        'JPattern', par.S, 'RelTol', 1e-6, 'AbsTol', par.atol, ...
        'InitialSlope', yp0, 'InitialStep', min(1e-3, ctl.tmax/10), ...
        'Events', @(t, yy) dfn_events(t, yy, par, ctl));
    if isempty(ctl.tout)
        tq = (0:popt.dt:ctl.tmax).';
    else
        tq = ctl.tout(ctl.tout >= 0 & ctl.tout <= ctl.tmax);
    end
    tq = unique([0; tq(:); ctl.tmax]);
    if numel(tq) < 3, tq = linspace(0, ctl.tmax, 3).'; end   % ode15s voi 2 diem tra ve moi buoc
    [tt, Yt, te, ye, ie] = ode15s(@rhs, tq, y, opts);
    Y = Yt.';
    tend = tt(end);
    if ~isempty(ie) && te(end) >= tend
        names = {'Vmin', 'Vmax', 'Icut', 'Qstop', 'ce_depleted', 'xsn_max', 'xsn_min', 'xsp_max', 'xsp_min'};
        out.reason{k} = names{ie(end)};
        if te(end) > tend
            tt = [tt; te(end)]; Y = [Y, ye(end, :).']; tend = te(end); %#ok<AGROW>
        end
    elseif tend >= ctl.tmax*(1 - 1e-10)
        out.reason{k} = 'time';
    else
        out.reason{k} = 'solver_failed';
    end
    nt = numel(tt);
    a = cell(nt, 1);
    for i = 1:nt
        [~, a{i}] = dfn_rhs(tt(i), Y(:, i), par, ctl);
    end
    % lao hoa hau kiem doc theo quy dao cua buoc nay
    [trk, ser] = aging_track('run', par, ap, trk, tt, Y, a);
    % lao hoa CUA DFN neu da co (buoc C): thay so hau kiem bang trang thai cua DFN,
    % tinh tu dau vung (trk.nat0 = gia tri luc bat dau dem). aging_from_plant.m.
    nat = aging_from_plant(par, Y);
    if isempty(nat)
        trk.source = 'posthoc_provisional';
    else
        if ~isfield(trk, 'nat0') || isempty(trk.nat0)
            trk.nat0 = [nat.nsei(1), nat.ndl(1), nat.npl(1), nat.nlam(1)];
        end
        ser.nsei = nat.nsei - trk.nat0(1); ser.ndl = nat.ndl - trk.nat0(2); ser.npl = nat.npl - trk.nat0(3);
        trk.nsei = ser.nsei(end); trk.ndl = ser.ndl(end); trk.npl = ser.npl(end); trk.nlam = nat.nlam(end) - trk.nat0(4);
        trk.source = 'plant';
    end
    s.t = t0 + tt; s.step = k*ones(nt, 1);
    s.V = cellfun(@(q) q.V, a); s.I = cellfun(@(q) q.I, a); s.T = cellfun(@(q) q.T, a); s.Q = cellfun(@(q) q.Q, a);
    s.soc = cellfun(@(q) (q.xn_avg - par.neg.x0)/(par.neg.x100 - par.neg.x0), a);
    s.xs_sep = cellfun(@(q) q.thsn(end), a); s.xs_max = cellfun(@(q) max(q.thsn), a);
    s.xsp_min = cellfun(@(q) min(q.thsp), a);
    s.dphi_sep = cellfun(@(q) q.dphi_n(end), a);
    s.eta_sep = ser.eta_sep; s.eta_min = ser.eta_min;
    s.nsei = ser.nsei; s.npl = ser.npl; s.ndl = ser.ndl;
    for i = 1:numel(f), out.(f{i}) = [out.(f{i}); s.(f{i})]; end
    if ~isempty(popt.snap)
        for ts = popt.snap(:).'
            if ts >= t0 && ts <= t0 + tend
                [~, j] = min(abs(tt + t0 - ts));
                out.Ysnap = [out.Ysnap, Y(:, j)]; out.tsnap = [out.tsnap; t0 + tt(j)];
            end
        end
    end
    out.nfev(k) = nfev;
    y = Y(:, end); t0 = t0 + tend;
    if any(strcmp(out.reason{k}, {'solver_failed', 'init_failed'})), break; end
end
out.y_end = y;
out.reason = out.reason(~cellfun(@isempty, out.reason));

    function fv = rhs(t, yy)
        nfev = nfev + 1;
        fv = dfn_rhs(t, yy, par, ctl);
    end
end

function ctl = make_ctl(s)
% nhu make_ctl trong src/dfn/dfn_run.m
ctl.mode = s.mode; ctl.value = [];
if isfield(s, 'value'), ctl.value = s.value; end
if strcmp(ctl.mode, 'rest'), ctl.mode = 'I'; ctl.value = 0; end
ctl.tmax = s.tmax; ctl.Tamb = s.Tamb;
ctl.stop = struct('Vmin', NaN, 'Vmax', NaN, 'Icut', NaN, 'Qstop', NaN);
if isfield(s, 'stop') && isstruct(s.stop)
    fn = fieldnames(s.stop);
    for i = 1:numel(fn)
        if ~isempty(s.stop.(fn{i})), ctl.stop.(fn{i}) = s.stop.(fn{i}); end
    end
end
ctl.tout = [];
if isfield(s, 'tout') && ~isempty(s.tout), ctl.tout = s.tout(:); end
end
