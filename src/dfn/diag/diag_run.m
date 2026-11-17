function out = diag_run(par, y0, steps)
%DIAG_RUN (BAN CHAN DOAN) = dfn_run.m + tra them out.Y (trang thai day du tai cac thoi diem xuat).
% Chay mot chuoi buoc (dong cho truoc / giu ap / nghi) tu trang thai y0.
%
% steps(k) la struct voi cac truong:
%   .mode   'I'   dong cho truoc; .value [A] (so, > 0 la xa) hoac ham @(t) (t tinh tu dau buoc)
%           'V'   giu ap; .value [V] (dong la an dai so, rang buoc V(y) = value)
%           'rest' nghi (I = 0)
%   .tmax   thoi luong toi da cua buoc [s]
%   .Tamb   nhiet do moi truong [K]
%   .stop   struct dieu kien dung (truong nao vang mat = khong dung):
%           .Vmin, .Vmax [V]; .Icut [A] (|I| giam xuong duoi); .Qstop [Ah] (Q cham gia tri)
%   .tout   (tuy chon) cac thoi diem [s, tinh tu dau buoc] can xuat ket qua
% out: .t, .V, .I, .T, .Q, .step, .xsn, .xsp ([min max] stoich be mat), .y_end,
%      .reason{k}, .nfev(k) (so lan goi ve phai)
%
% Tich phan: ode15s (NDF, ma tran khoi luong suy bien, JPattern thua), khoi
% tao nhat quan bang dfn_consistent_init truoc moi buoc.
ix = par.ix;
y = y0; t0 = 0;
out.Y = []; out.ctl = {}; out.t = []; out.V = []; out.I = []; out.T = []; out.Q = []; out.step = [];
out.xsn = []; out.xsp = []; out.dphi_sep = []; out.eta_pl_min = []; out.Qgen = []; out.ce_min = []; out.ce_max = [];
out.reason = cell(1, numel(steps)); out.nfev = zeros(1, numel(steps));
for k = 1:numel(steps)
    ctl = make_ctl(steps(k));
    [y, ok] = dfn_consistent_init(0, y, par, ctl);
    if ~ok
        error('dfn_run: khoi tao nhat quan that bai o buoc %d (mode %s)', k, ctl.mode);
    end
    nfev = 0;
    f0 = dfn_rhs(0, y, par, ctl);
    yp0 = zeros(ix.ny,1); yp0(par.id) = f0(par.id);
    opts = odeset('Mass', par.M, 'MassSingular', 'yes', 'MStateDependence', 'none', ...
        'JPattern', par.S, 'RelTol', 1e-6, 'AbsTol', par.atol, ...
        'InitialSlope', yp0, 'InitialStep', min(1e-3, ctl.tmax/10), ...
        'Events', @(t, yy) dfn_events(t, yy, par, ctl));
    % Chi luu nghiem tai cac thoi diem xuat (khong luu moi buoc cua bo giai:
    % cau truc sol cua ode15s ton ~8 x ny x so_buoc x 8 byte, tran bo nho voi luoi min).
    if isempty(ctl.tout)
        tq = [linspace(0, min(60, ctl.tmax/4), 61), linspace(min(60, ctl.tmax/4), ctl.tmax, 600)].';
    else
        tq = ctl.tout(ctl.tout >= 0 & ctl.tout <= ctl.tmax);
    end
    tq = unique([0; tq; ctl.tmax]);
    [tt, Yt, te, ye, ie] = ode15s(@rhs, tq, y, opts);
    Y = Yt.';
    tend = tt(end);
    if ~isempty(ie) && te(end) >= tend
        names = {'Vmin', 'Vmax', 'Icut', 'Qstop', 'ce_depleted', 'xsn_max', 'xsn_min', 'xsp_max', 'xsp_min'};
        out.reason{k} = names{ie(end)};
        if te(end) > tend
            tt = [tt; te(end)]; Y = [Y, ye(end,:).']; tend = te(end); %#ok<AGROW>
        end
    elseif tend >= ctl.tmax*(1 - 1e-10)
        out.reason{k} = 'time';
    else
        out.reason{k} = 'solver_failed';
    end
    nt = numel(tt);
    V = zeros(nt,1); I = V; T = V; Q = V; xsn = zeros(nt,2); xsp = xsn; epl = V; Qg = V; cmin = V; cmax = V; dsep = V;
    for i = 1:nt
        [~, a] = dfn_rhs(tt(i), Y(:,i), par, ctl);
        V(i) = a.V; I(i) = a.I; T(i) = a.T; Q(i) = a.Q;
        xsn(i,:) = [min(a.thsn), max(a.thsn)]; xsp(i,:) = [min(a.thsp), max(a.thsp)];
        epl(i) = a.eta_pl_min; Qg(i) = a.Qgen; cmin(i) = a.ce_min; cmax(i) = a.ce_max;
        dsep(i) = a.dphi_n(end);
    end
    out.t = [out.t; t0 + tt]; out.V = [out.V; V]; out.I = [out.I; I]; out.T = [out.T; T];
    out.Q = [out.Q; Q]; out.step = [out.step; k*ones(nt,1)];
    out.Y = [out.Y, Y]; out.ctl{k} = ctl;
    out.xsn = [out.xsn; xsn]; out.xsp = [out.xsp; xsp]; out.dphi_sep = [out.dphi_sep; dsep];
    out.eta_pl_min = [out.eta_pl_min; epl]; out.Qgen = [out.Qgen; Qg];
    out.ce_min = [out.ce_min; cmin]; out.ce_max = [out.ce_max; cmax];
    out.nfev(k) = nfev;
    if strcmp(out.reason{k}, 'solver_failed')
        g = par.grid; yf = Y(:,end);
        thn = reshape(yf(ix.thn), g.Nrn, g.Nn); thp = reshape(yf(ix.thp), g.Nrp, g.Np);
        fprintf(['dfn_run: BO GIAI THAT BAI o buoc %d (mode %s) tai t = %.3f s: V = %.4f, I = %.4f, T = %.2f K\n', ...
            '  x_surf am [%.4f, %.4f], duong [%.4f, %.4f]; theta am [%.4f, %.4f], duong [%.4f, %.4f]\n', ...
            '  ce [%.1f, %.1f] mol/m3; max|d theta| giua hai vo ke: am %.4f, duong %.4f\n'], ...
            k, ctl.mode, tend, V(end), I(end), T(end), xsn(end,1), xsn(end,2), xsp(end,1), xsp(end,2), ...
            min(thn(:)), max(thn(:)), min(thp(:)), max(thp(:)), cmin(end), cmax(end), ...
            max(max(abs(diff(thn,1,1)))), max(max(abs(diff(thp,1,1)))));
    end
    y = Y(:,end); t0 = t0 + tend;
    if strcmp(out.reason{k}, 'solver_failed'), break; end
end
out.y_end = y;

    function f = rhs(t, yy)
        nfev = nfev + 1;
        f = dfn_rhs(t, yy, par, ctl);
    end
end

function ctl = make_ctl(s)
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
