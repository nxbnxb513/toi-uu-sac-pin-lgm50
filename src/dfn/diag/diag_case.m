function diag_case(variant, outdir, scen_list)
%DIAG_CASE  Chan doan GD-16: sac CC toi 4.2 V + CV toi C/100 tu 0 % SOC cho mot
% bien the tham so (diag_variant), ghi chuoi thoi gian va profile.
%   diag_case('base', 'results/diag')
%   diag_case('base', 'results/diag', {'0.3C_25C'})
% Dau ra (outdir): diag_<variant>.md (bang tom tat) va
%   <variant>_<kich ban>_ts.csv   chuoi thoi gian (nut phia mang ngan = nut Nn,
%                                 nut phia current collector = nut 1)
%   <variant>_<kich ban>_prof.csv profile theo x: c_e, j, x_surf, x_bulk tai cac thoi diem
%   <variant>_<kich ban>_rad.csv  profile ban kinh trong hat nut phia mang ngan / phia collector luc dung CC
if nargin < 2, outdir = 'results/diag'; end
if ~exist(outdir, 'dir'), mkdir(outdir); end
allscen = {'0.3C_25C', 0.3, 25; '1C_25C', 1, 25; '0.3C_10C', 0.3, 10; 'C20_25C', 0.05, 25};
if nargin >= 3 && ~isempty(scen_list)
    allscen = allscen(ismember(allscen(:,1), scen_list), :);
end
[par, desc, start] = diag_variant(variant);
fid = fopen(fullfile(outdir, ['diag_' variant '.md']), 'w');
p('### Bien the `%s`: %s\n\n', variant, desc);
p('Luoi [%d %d %d | %d %d]; Qcap_n = %.4f Ah, Qcap_p = %.4f Ah (N/P theo dung luong tong = %.4f)\n\n', ...
    par.cfg.Nn, par.cfg.Ns, par.cfg.Np, par.cfg.Nrn, par.cfg.Nrp, par.neg.Qcap, par.pos.Qcap, par.neg.Qcap/par.pos.Qcap);
if strcmp(variant, 'base'), balance_report(); end
p('| Kich ban | CC dung vi | t CC (s) | V cuoi CC (V) | Ah CC | CV dung vi | t CV (s) | Ah tong | x_surf max (nut) | x_bulk luc dung CC [col, sep] | x_surf luc dung CC [col, sep] | min(phi_s-phi_e) phia mang ngan (mV) | j_sep/j_tb max | c_e [min max] (mol/m3) | D_s,n(x_surf,sep) / D_s,n(x_bulk,sep) luc dung CC (m2/s) | sai lech bao toan Li | so lan goi ve phai |\n');
p('|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|\n');
for s = 1:size(allscen, 1)
    nm = allscen{s,1}; C = allscen{s,2}; T0 = allscen{s,3} + 273.15;
    tic;
    r = run_cccv(par, start, C, T0);
    w = toc;
    S = r.S;
    iCC = find(S.phase == 1, 1, 'last');
    xsmax = max(S.xs_max);
    [~, kmax] = max(S.xs_max);
    p('| %s | %s | %.0f | %.4f | %.4f | %s | %.0f | %.4f | %.5f (nut %d) | [%.4f, %.4f] | [%.4f, %.4f] | %.1f | %.2f | [%.1f %.1f] | %.2e / %.2e | %.1e | %d (%.0f s) |\n', ...
        nm, r.reason{1}, r.tCC, S.V(iCC), -S.Q(iCC), r.reason{2}, r.tCV, -S.Q(end), xsmax, S.xs_argmax(kmax), ...
        S.xb_cc(iCC), S.xb_sep(iCC), S.xs_cc(iCC), S.xs_sep(iCC), 1e3*min(S.dphi_sep), max(S.jsep_rel), ...
        min(S.ce_min), max(S.ce_max), S.D_xs_sep(iCC), S.D_xb_sep(iCC), max(abs(S.Li - S.Li(1)))/S.Li(1), r.nfev, w);
    base = fullfile(outdir, sprintf('%s_%s', variant, nm));
    writetable(struct2table(S), [base '_ts.csv']);
    writematrix(r.prof, [base '_prof.csv']);
    writematrix(r.rad, [base '_rad.csv']);
end
fclose(fid);
fprintf('DIAG %s: XONG\n', variant);

    function p(varargin)
        fprintf(varargin{:}); fprintf(fid, varargin{:});
    end

    function balance_report()
        % Gia thuyet (a): can bang dung luong va OCV can bang tai 4.2 V
        n = par.neg; q = par.pos;
        p('Can bang dung luong (gia thuyet a):\n\n');
        p('- Cua so stoich: am %.4f-%.4f -> %.4f Ah; duong %.4f-%.4f -> %.4f Ah (Li 2025: 4.865 Ah)\n', ...
            n.x0, n.x100, n.Qcap*(n.x100 - n.x0), q.y0, q.y100, q.Qcap*(q.y0 - q.y100));
        p('- Du tru cuc am tren 100 %% SOC: (1 - x100) Qcap_n = %.4f Ah\n', (1 - n.x100)*n.Qcap);
        qq = -0.6:0.05:0.3;
        p('- OCV can bang (25 C) doc theo duong can bang lithium qua (x100, y100); q < 0 = sac qua 100 %%:\n\n| q (Ah) | x_n | y_p | OCV nhanh sac (V) | OCV nhanh xa (V) | U_n lith (V) |\n|---|---|---|---|---|---|\n');
        for qi = qq
            xn = n.x100 - qi/n.Qcap; yp = q.y100 + qi/q.Qcap;
            [Unl, Und] = dfn_ocp_neg(xn); [Upl, Upd] = dfn_ocp_pos(yp);
            p('| %.2f | %.4f | %.4f | %.4f | %.4f | %.4f |\n', qi, xn, yp, Upd - Unl, Upl - Und, Unl);
        end
        xg = [0.5 0.6 0.7 0.75 0.8 0.85 0.88 0.9 0.92 0.95 0.97 0.99 1.0];
        p('\n- D_s,n (gom ung suat) theo x: x = %s\n  - 25 C: %s m2/s\n  - 10 C: %s m2/s\n  - R^2/D (25 C): %s s\n\n', mat2str(xg), ...
            mat2str(dfn_Ds(n, xg, 298.15, par), 3), mat2str(dfn_Ds(n, xg, 283.15, par), 3), mat2str(n.Rp^2./dfn_Ds(n, xg, 298.15, par), 3));
    end
end

% =========================================================================
function r = run_cccv(par, start, C, T0)
% Sac CC (C-rate C) toi Vmax roi CV toi C/100. Chay tung doan ngan bang dfn_run
% de luu trang thai day du sau moi doan (dfn_run chi tra y_end).
g = par.grid;
switch start
    case 'balance'
        xn = par.neg.x0; yp = par.pos.y100 + (par.neg.x100 - xn)*par.neg.Qcap/par.pos.Qcap;
    case 'y0'
        xn = par.neg.x0; yp = par.pos.y0;
end
y = dfn_init_state(par, xn, yp, T0);
Ichg = C*par.Qnom; Icut = par.Qnom/100;
chunk = 36/C;                          % ~ 1 % SOC moi doan
S = []; t = 0; r.nfev = 0; r.reason = {'', 'skipped'}; r.tCC = 0; r.tCV = 0;
prof = []; rad = [];
S = sample(S, 0, y, 1, struct('mode', 'I', 'value', -Ichg, 'Tamb', T0));
phases = {'I', 'V'};
for ph = 1:2
    if ph == 2 && ~strcmp(r.reason{1}, 'Vmax'), break; end
    if ph == 1
        st = struct('mode', 'I', 'value', -Ichg, 'tmax', chunk, 'Tamb', T0, 'stop', struct('Vmax', par.Vmax), 'tout', chunk);
        tlim = 1.6*3600/C;
    else
        st = struct('mode', 'V', 'value', par.Vmax, 'tmax', chunk, 'Tamb', T0, 'stop', struct('Icut', Icut), 'tout', chunk);
        st.tmax = max(chunk, 120); st.tout = st.tmax;
        tlim = 10*3600;
    end
    tph = 0;
    while true
        o = dfn_run(par, y, st);
        r.nfev = r.nfev + o.nfev(1);
        y = o.y_end; dt = o.t(end); t = t + dt; tph = tph + dt;
        ctl = struct('mode', phases{ph}, 'value', st.value, 'Tamb', T0);
        S = sample(S, t, y, ph, ctl);
        rs = o.reason{1};
        if ~strcmp(rs, 'time') || tph >= tlim
            if strcmp(rs, 'time'), rs = 'tlim'; end
            break;
        end
    end
    r.reason{ph} = rs;
    if ph == 1, r.tCC = tph; rad = radial(y); else, r.tCV = tph; end
end
S.phase = S.phase(:);
r.S = S; r.prof = prof; r.rad = rad;

    function S = sample(S, tt, yy, ph, ctl)
        [~, a] = dfn_rhs(tt, yy, par, ctl);
        thn = reshape(yy(par.ix.thn), g.Nrn, g.Nn);
        xb = (g.Vshn.'*thn)/sum(g.Vshn);
        ce = yy(par.ix.ce)*par.ce_ref;
        T = yy(par.ix.T);
        row.t = tt; row.phase = ph; row.V = a.V; row.I = a.I; row.T = T; row.Q = a.Q;
        row.xs_sep = a.thsn(end); row.xs_cc = a.thsn(1);
        row.xb_sep = xb(end); row.xb_cc = xb(1);
        [row.xs_max, row.xs_argmax] = max(a.thsn);
        row.xs_min = min(a.thsn);
        row.xn_avg = a.xn_avg; row.yp_avg = a.yp_avg;
        row.ysurf_max = max(a.thsp); row.ysurf_min = min(a.thsp);
        row.dphi_sep = a.dphi_n(end); row.dphi_cc = a.dphi_n(1); row.dphi_min = min(a.dphi_n);
        row.Un_sep = a.Un(end);
        row.j_sep = a.jn(end); row.j_cc = a.jn(1); row.j_avg = mean(a.jn);
        row.jsep_rel = a.jn(end)/mean(a.jn);
        row.ce_min = min(ce); row.ce_max = max(ce); row.ce_negsep = ce(g.Nn); row.ce_ncc = ce(1);
        row.D_xs_sep = dfn_Ds(par.neg, min(max(a.thsn(end), 0), 1), T, par);
        row.D_xb_sep = dfn_Ds(par.neg, xb(end), T, par);
        row.Li = inventory(par, yy);
        fn = fieldnames(row);
        for i = 1:numel(fn)
            if isempty(S), S0.(fn{i}) = row.(fn{i}); else, S.(fn{i})(end+1,1) = row.(fn{i}); end
        end
        if isempty(S), S = S0; end
        % profile theo x: [t, phase, loai (1 ce, 2 j, 3 x_surf, 4 x_bulk), gia tri tai cac nut]
        N = g.N;
        jx = nan(1, N); jx(g.in) = a.jn; jx(g.ip) = a.jp;
        xs = nan(1, N); xs(g.in) = a.thsn; xs(g.ip) = a.thsp;
        xbx = nan(1, N); xbx(g.in) = xb;
        prof = [prof; tt ph 1 ce.'; tt ph 2 jx; tt ph 3 xs; tt ph 4 xbx];
    end
    function R = radial(yy)
        thn = reshape(yy(par.ix.thn), g.Nrn, g.Nn);
        rc = ((1:g.Nrn).' - 0.5)*g.drn;
        R = [rc, thn(:,1), thn(:,end)];
    end
end

function n = inventory(par, y)
% tong lithium (pha ran hai cuc + dien giai) [mol]
g = par.grid;
thn = reshape(y(par.ix.thn), g.Nrn, g.Nn); thp = reshape(y(par.ix.thp), g.Nrp, g.Np);
ag = dfn_aging_state(par, y);
xn = (g.Vshn.'*thn)/sum(g.Vshn); yp = (g.Vshp.'*thp)/sum(g.Vshp);
n = par.A*sum(xn.'.*ag.as_n/3*par.neg.Rp*g.dxn)*par.neg.cmax ...
  + par.A*sum(yp.'.*ag.as_p/3*par.pos.Rp*g.dxp)*par.pos.cmax ...
  + par.A*sum(ag.eps.*g.dx.*y(par.ix.ce))*par.ce_ref;
end
