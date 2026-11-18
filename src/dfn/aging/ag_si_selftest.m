function ag_si_selftest(outdir)
%AG_SI_SELFTEST  Tu kiem tra TANG 2 (lao hoa silicon, gia dinh; dfn_si_params.m) truoc khi chay dai.
%  1. Tang 2 voi k = 0  ==>  ve phai va mo phong trung tang 1 (tang 1 khong doi)
%  2. JPattern chua moi phan tu khac 0 cua Jacobian sai phan (bo co tang 2)
%  3. Bao toan lithium qua mot chu ky Expt 1 / Expt 5 / Expt 2 (k lon de ep mat Si)
%  4. Toc do LAM-Si moi chu ky (k cua dfn_si_params) o moi cua so: phai tap trung o SOC thap
%  5. ag_jump voi eps_Si: bao toan Li, trong mien vat ly
%  6. Thoi gian mot chu ky Expt 1 / Expt 5 (tang 1)
if nargin < 1, outdir = 'results/aging_selftest'; end
if ~exist(outdir, 'dir'), mkdir(outdir); end
fid = fopen(fullfile(outdir, 'aging_si_selftest.md'), 'w');
T25 = 298.15; T10 = 283.15; T40 = 313.15;
p('# Tu kiem tra tang 2 (silicon, gia dinh)\n\n');

% ---- 1. k = 0 ---------------------------------------------------------------
p1 = ag_par(1, 'default');
p0 = ag_par(1, 'siB_k0e0');
y1 = dfn_init_state(p1, p1.neg.x100, p1.pos.y100, T25);
st = ag_step('I', 5, 3000, T25, struct('Vmin', 2.5));
o = dfn_run(p1, y1, st); ym1 = o.y_end;
ym0 = to_si(p1, ym1, p0);
ctl = struct('mode', 'I', 'value', 5, 'Tamb', T25);
f1 = dfn_rhs(0, ym1, p1, ctl); f0 = dfn_rhs(0, ym0, p0, ctl);
d = max(abs(f1(1:p1.ix.ny - 0) - f0(map(p1, p0))));
p('## 1. k = 0: lech ve phai lon nhat (moi trang thai tang 1) = %.3e\n\n', d);
assert(d < 1e-12, 'tang 2 voi k = 0 lam doi ve phai');
[~, a1] = dfn_rhs(0, ym1, p1, ctl);
p('- trang thai thu: xa 1C %.0f s tu 100 %%; sto be mat cuc am [%.3f, %.3f]\n', o.t(end), min(a1.thsn), max(a1.thsn));
oa = dfn_run(p1, y1, ag_cycle_steps(p1, T25)); ob = dfn_run(p0, to_si(p1, y1, p0), ag_cycle_steps(p0, T25));
p('- mot chu ky Expt 5 (xa 1C, CCCV): V cuoi tang 1 %.7f, tang 2 (k = 0) %.7f (lech %.1e V); Q lech %.1e Ah\n\n', ...
    oa.V(end), ob.V(end), abs(oa.V(end) - ob.V(end)), abs(oa.Q(end) - ob.Q(end)));
assert(abs(oa.V(end) - ob.V(end)) < 1e-5, 'tang 2 voi k = 0 lech tang 1');

% ---- 2. JPattern -------------------------------------------------------------
p('## 2. JPattern (tang 2, luoi Expt 3, trang thai SOC thap, k = 1e-12)\n\n');
par = ag_par(1, 'siB_k1e-12'); ny = par.ix.ny; G = par.ix.ag;
yb = to_si(p1, ym1, par);
rng(3);
yb(G.cLi) = 1 + rand(numel(G.cLi),1); yb(G.cdl) = rand(numel(G.cdl),1);
yb(G.lcr) = yb(G.lcr).*(1 + rand(numel(G.lcr),1));
yb(G.epsSi) = yb(G.epsSi).*(0.5 + 0.5*rand(numel(G.epsSi),1));
yb(G.epsn) = yb(G.epsn) - 0.01*rand(numel(G.epsn),1);
excl = false(ny); excl([G.nLAMn, G.nLAMp, G.Qthr], :) = true;
agc = [G.Lin; G.Lout; G.Lcin; G.Lcout; G.cLi; G.cdl; G.lcr; G.epsn; G.xavn; G.epsp; G.xavp; G.nSEI; G.nSEIcr; G.nLAMn; G.nLAMp; G.Qthr; G.epsSi];
excl(par.ix.T, agc) = true;
miss = 0;
for c = {struct('mode', 'I', 'value', 5, 'Tamb', T25), struct('mode', 'I', 'value', 1.5, 'Tamb', T10)}
    cc = c{1};
    fb = dfn_rhs(0, yb, par, cc);
    nzSi = nnz(fb(G.epsSi));
    J = zeros(ny);
    for j = 1:ny
        yq = yb; dl = 1e-6*max(abs(yb(j)), 1e2*par.atol(j)); yq(j) = yq(j) + dl;
        J(:, j) = (dfn_rhs(0, yq, par, cc) - fb)/dl;
    end
    isag = false(ny, 1); isag(agc) = true; agm = isag | isag.';
    Jnz = (J ~= 0 & agm) | (abs(J) > 1e-9*max(abs(J(:))) & ~agm);
    bad = Jnz & ~full(par.S) & ~excl;
    miss = miss + nnz(bad);
    [r, ci] = find(bad);
    for k = 1:min(10, numel(r)), p('  - thieu (%d, %d)\n', r(k), ci(k)); end
    p('- I = %.1f A: d eps_Si/dt khac 0 tai %d/%d nut; nnz Jacobian %d, nnz JPattern %d, thieu %d\n', cc.value, nzSi, numel(G.epsSi), nnz(Jnz), nnz(par.S), nnz(bad));
end
assert(miss == 0, 'JPattern tang 2 thieu phan tu');

% ---- 3. bao toan lithium -----------------------------------------------------
p('\n## 3. Bao toan lithium qua mot chu ky (k = 1e-12, ep mat Si)\n\n');
p('| Truong hop | T | lech Li tuong doi | x_av lech | C_Si dau (Ah) | LAM-Si chu ky (%%) | Li trong vat lieu mat (umol) | ly do |\n|---|---|---|---|---|---|---|---|\n');
for cs = {1, T25; 5, T25; 2, T25; 1, T40}.'
    ex = cs{1}; Ta = cs{2};
    par = ag_par(ex, 'siB_k1e-12');
    y = start_state(par, ex, Ta);
    La = dfn_li_inventory(par, y);
    [y, c] = ag_cycle(par, y, ex, Ta);
    Lb = dfn_li_inventory(par, y);
    rel = (Lb.total - La.total)/La.total;
    p('| Expt %d | %.0f C | %.2e | %.1e | %.4f | %.4f | %.3f | %s |\n', ex, Ta - 273.15, rel, Lb.xav_err, La.CSi, 100*(1 - Lb.CSi/La.CSi), 1e6*(Lb.lam_n - La.lam_n), c.reason);
    assert(abs(rel) < 1e-6, 'tang 2: khong bao toan lithium');
end

% ---- 4. toc do theo cua so ------------------------------------------------------
pd = ag_par(1, 'si');
p('\n## 4. LAM-Si moi chu ky voi tham so mac dinh cua tang 2 (form %s, k = %.3g)\n\n', pd.ag.si.form, pd.ag.si.k);
p('| Expt | T | LAM-Si / chu ky (ppm) | LAM-Si / kAh (%%) | LAM-Gr / chu ky (ppm) | s / chu ky |\n|---|---|---|---|---|---|\n');
for ex = [1 5 2 3]
    for Ta = [T10 T25 T40]
        par = ag_par(ex, 'si');
        y = start_state(par, ex, Ta);
        [y, ~] = ag_cycle(par, y, ex, Ta);
        La = dfn_li_inventory(par, y);
        tic; [y, ~] = ag_cycle(par, y, ex, Ta); w = toc;
        Lb = dfn_li_inventory(par, y);
        dSi = 1 - Lb.CSi/La.CSi; dQ = Lb.Qthr - La.Qthr;
        dGr = 1 - (Lb.Cn - Lb.CSi)/(La.Cn - La.CSi);
        p('| %d | %.0f C | %.2f | %.3f | %.3f | %.1f |\n', ex, Ta - 273.15, 1e6*dSi, 100*dSi/dQ*1000, 1e6*dGr, w);
    end
end

% ---- 5. ag_jump --------------------------------------------------------------------
p('\n## 5. ag_jump voi eps_Si (Expt 1, 25 C, k = 1e-12, J = 10)\n\n');
par = ag_par(1, 'siB_k1e-12');
y = start_state(par, 1, T25);
[ya, ~] = ag_cycle(par, y, 1, T25); [yb2, ~] = ag_cycle(par, ya, 1, T25);
[yj, info] = ag_jump(par, ya, yb2, 10);
Lb = dfn_li_inventory(par, yb2); Lj = dfn_li_inventory(par, yj);
p('- ok = %d, phan Li bu %.2e, bao toan sau nhay %.1e; C_Si: a %.5f, b %.5f, sau nhay %.5f Ah (tuyen tinh: %.5f)\n', ...
    info.ok, info.err, info.cons, dfn_li_inventory(par, ya).CSi, Lb.CSi, Lj.CSi, Lb.CSi + 10*(Lb.CSi - dfn_li_inventory(par, ya).CSi));
assert(info.ok && info.cons < 1e-12, 'ag_jump tang 2');
[~, c] = ag_cycle(par, yj, 1, T25);
p('- chu ky sau nhay: %s\n', c.reason);
assert(c.ok, 'chu ky sau nhay that bai');

% ---- 6. thoi gian tang 1 ------------------------------------------------------------
p('\n## 6. Thoi gian mot chu ky, tang 1\n\n');
for ex = [1 5]
    par = ag_par(ex, 'default');
    y = start_state(par, ex, T25);
    tic; [~, c] = ag_cycle(par, y, ex, T25); w = toc;
    p('- Expt %d: %.1f s tuong, %.0f s mo phong, %s, V [%.3f, %.3f]\n', ex, w, c.dur, c.reason, c.Vmin, c.Vmax);
end
fclose(fid);
type(fullfile(outdir, 'aging_si_selftest.md'));

    function p(varargin)
        fprintf(fid, varargin{:});
    end
end

function y = start_state(par, ex, Ta)
% trang thai dau chu ky: Expt 1 o 2.5 V (sau xa 1C + CV), Expt 2 o 85 %, Expt 3/5 day
y = dfn_init_state(par, par.neg.x100, par.pos.y100, Ta);
if ex == 1
    [y, ~, ok] = ag_exec(par, y, [ag_step('I', 5, 2*3600, Ta, struct('Vmin', 2.5)), ag_step('V', 2.5, 30*3600, Ta, struct('Icut', 0.05))]);
    assert(ok, 'start_state Expt 1');
elseif ex == 2
    [y, ~] = ag_exec(par, y, ag_step('I', 5, 0.73/5*3600, Ta, struct('Vmin', 2.5)));
end
end

function st = ag_cycle_steps(par, Ta)
st = [ag_step('I', 5, 2*3600, Ta, struct('Vmin', 2.5)), ag_step('I', -1.5, 10*3600, Ta, struct('Vmax', par.V_cv)), ...
      ag_step('V', par.V_cv, 10*3600, Ta, struct('Icut', 0.05))];
end

function ys = to_si(p1, y1, ps)
% vector tang 1 (lao hoa, khong Si) -> tang 2 (them eps_Si = eps_Si,0)
ys = zeros(ps.ix.ny, 1);
ys(map(p1, ps)) = y1;
ys(ps.ix.ag.epsSi) = ps.ag.si.eps0;
end

function m = map(p1, ps)
% chi so trong vector tang 2 cua tung phan tu vector tang 1 (trang thai Si chen sau Qthr)
n1 = p1.ix.nd; nSi = numel(ps.ix.ag.epsSi);
m = [(1:n1).'; (n1 + nSi + 1 : p1.ix.ny + nSi).'];
end
