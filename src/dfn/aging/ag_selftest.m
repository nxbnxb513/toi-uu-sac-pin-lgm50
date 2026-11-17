function ag_selftest(outdir)
%AG_SELFTEST  Kiem tra mo hinh lao hoa trong DFN (buoc C) truoc khi chay thi nghiem dai.
%  1. Lao hoa bat nhung moi toc do = 0  ==>  ve phai DFN trung voi DFN khong lao hoa
%  2. JPattern chua moi phan tu khac 0 cua Jacobian sai phan day du (tru cac hang so sach
%     va T x do xop - da khai bao trong dfn_mesh.m)
%  3. Bao toan lithium (hat + dien giai + SEI + SEI vet nut + ma + chet + LAM) qua chu ky
%     Expt 2 / Expt 3 o 10 va 25 C, va voi k_Li x 1000 (ep ma lithium)
%  4. Can kho: bao toan Li qua cap nhat, cac truong hop
%  5. Thoi gian mot chu ky; toc do lao hoa moi chu ky
%  6. dfn_perm_loss
if nargin < 1, outdir = 'results/aging_selftest'; end
if ~exist(outdir, 'dir'), mkdir(outdir); end
fid = fopen(fullfile(outdir, 'aging_selftest.md'), 'w');
T25 = 298.15; T10 = 283.15;
p('# Tu kiem tra mo hinh lao hoa (buoc C)\n\n');

% ---- 1. tuong duong khi toc do = 0 --------------------------------------
gr = struct('Nn', 10, 'Ns', 5, 'Np', 5, 'Nrn', 100, 'Nrp', 20);
poff = dfn_params(gr);
o = gr; o.aging = true; pon = dfn_params(o);
pz = pon; pz.ag.D_int = 0; pz.ag.k_Li = 0; pz.ag.beta_n = 0; pz.ag.beta_p = 0; pz.ag.k_cr = 0;
y100 = dfn_init_state(poff, poff.neg.x100, poff.pos.y100, T25);
st = struct('mode', 'I', 'value', 5, 'tmax', 600, 'Tamb', T25, 'stop', struct('Vmin', 2.5), 'tout', 600);
o1 = dfn_run(poff, y100, st); ym = o1.y_end;
ctl = struct('mode', 'I', 'value', 5, 'Tamb', T25);
f0 = dfn_rhs(0, ym, poff, ctl);
yz = dfn_aging_extend(poff, ym, pz);
fz = dfn_rhs(0, yz, pz, ctl);
i0 = poff.ix; ia = pz.ix; d = 0;
for nm = {'thn', 'thp', 'ce', 'T', 'Q', 'phisn', 'phisp', 'phie', 'jn', 'jp', 'H', 'I'}
    d = max(d, max(abs(f0(i0.(nm{1})) - fz(ia.(nm{1})))));
end
p('## 1. Toc do lao hoa = 0: lech ve phai DFN lon nhat = %.3e\n\n', d);
assert(d < 1e-9, 'lao hoa voi toc do 0 lam doi DFN');
oz = dfn_run(pz, dfn_aging_extend(poff, y100, pz), st);
p('- Xa 1C 600 s: V cuoi khong lao hoa %.6f V, lao hoa toc do 0: %.6f V (lech %.2e V)\n', o1.V(end), oz.V(end), abs(o1.V(end) - oz.V(end)));
assert(abs(o1.V(end) - oz.V(end)) < 1e-6, 'mo phong lao hoa toc do 0 lech DFN');
p('- So an: khong lao hoa %d (vi phan %d); co lao hoa %d (vi phan %d); so mau cot JPattern: %d\n\n', ...
    poff.ix.ny, poff.ix.nd, pon.ix.ny, pon.ix.nd, max(dfn_color(pon.S)));

% ---- 2. JPattern ---------------------------------------------------------
p('## 2. JPattern (bo co lao hoa, luoi Expt 3)\n\n');
par = pon; ny = par.ix.ny; G = par.ix.ag;
yb = dfn_aging_extend(poff, ym, par);
rng(2);
% lam lech trang thai lao hoa de moi toc do khac 0 (ma, vet nut, LAM)
yb(G.cLi) = 1 + rand(numel(G.cLi),1); yb(G.cdl) = rand(numel(G.cdl),1);
yb(G.Lin) = yb(G.Lin).*(1 + 0.1*rand(numel(G.Lin),1)); yb(G.lcr) = yb(G.lcr).*(1 + rand(numel(G.lcr),1));
yb(G.epsn) = yb(G.epsn) - 0.01*rand(numel(G.epsn),1);
yb(G.xavn) = yb(G.xavn) + 0.01; yb(G.xavp) = yb(G.xavp) - 0.01;
excl = false(ny); excl([G.nLAMn, G.nLAMp, G.Qthr], :) = true;
agc = [G.Lin; G.Lout; G.Lcin; G.Lcout; G.cLi; G.cdl; G.lcr; G.epsn; G.xavn; G.epsp; G.xavp; G.nSEI; G.nSEIcr; G.nLAMn; G.nLAMp; G.Qthr];
excl(par.ix.T, agc) = true;
miss = 0;
for c = {struct('mode', 'I', 'value', 5, 'Tamb', T25), struct('mode', 'V', 'value', 3.9, 'Tamb', T25), struct('mode', 'I', 'value', -5, 'Tamb', T10)}
    cc = c{1};
    f0 = dfn_rhs(0, yb, par, cc);
    J = zeros(ny);
    for j = 1:ny
        yq = yb; dl = 1e-6*max(abs(yb(j)), 1e2*par.atol(j)); yq(j) = yq(j) + dl;
        J(:, j) = (dfn_rhs(0, yq, par, cc) - f0)/dl;
    end
    % hang/cot lao hoa: moi phan tu khac 0 (chinh xac); khoi DFN x DFN: nguong nhu val_selftest
    isag = false(ny, 1); isag(agc) = true;
    agm = isag | isag.';
    Jnz = (J ~= 0 & agm) | (abs(J) > 1e-9*max(abs(J(:))) & ~agm);
    bad = Jnz & ~full(par.S) & ~excl;
    miss = miss + nnz(bad);
    [r, cidx] = find(bad);
    for k = 1:min(10, numel(r)), p('  - thieu (%d, %d)\n', r(k), cidx(k)); end
    p('- che do %s %.2f: nnz Jacobian %d, nnz JPattern %d, thieu %d\n', cc.mode, cc.value, nnz(Jnz), nnz(par.S), nnz(bad));
end
assert(miss == 0, 'JPattern lao hoa thieu phan tu');

% ---- 3. bao toan lithium ----------------------------------------------------
p('\n## 3. Bao toan lithium qua mot chu ky (tu 100 %% SOC)\n\n');
p('| Truong hop | T | Li tong dau (mol) | lech tuong doi | x_av lech | SEI (umol) | SEI vet nut (umol) | ma (umol) | chet (umol) | LAM (umol) | thoi gian (s) |\n|---|---|---|---|---|---|---|---|---|---|---|\n');
cases = {2, T25, 1; 3, T25, 1; 3, T10, 1; 3, T10, 1000};
for i = 1:size(cases, 1)
    ex = cases{i,1}; Ta = cases{i,2}; kf = cases{i,3};
    par = ag_par(ex); par.ag.k_Li = par.ag.k_Li*kf;
    y = dfn_init_state(par, par.neg.x100, par.pos.y100, Ta);
    La = dfn_li_inventory(par, y);
    tic; [y, c] = ag_cycle(par, y, ex, Ta); w = toc;
    Lb = dfn_li_inventory(par, y);
    rel = (Lb.total - La.total)/La.total;
    p('| Expt %d cycle, k_Li x %g (%s) | %.0f C | %.6f | %.2e | %.1e | %.4f | %.4f | %.4f | %.4f | %.4f | %.1f |\n', ex, kf, c.reason, Ta - 273.15, ...
        La.total, rel, Lb.xav_err, 1e6*Lb.sei, 1e6*Lb.seicr, 1e6*Lb.plated, 1e6*Lb.dead, 1e6*(Lb.lam_n + Lb.lam_p), w);
    assert(abs(rel) < 1e-6, 'khong bao toan lithium');
    assert(Lb.xav_err < 1e-6, 'x_av lech trung binh hat');
end

% ---- 4. can kho ---------------------------------------------------------------
p('\n## 4. Can kho (dfn_dryout_update)\n\n');
for Rx = [1.0, 1.02]
    par = ag_par(3); par.ag.R_exc = Rx;
    y0 = dfn_init_state(par, par.neg.x100, par.pos.y100, T25);
    dry = dfn_dryout_init(par, y0);
    y1 = y0;
    for k = 1:3, [y1, ~] = ag_cycle(par, y1, 3, 313.15); end
    Lb = dfn_li_inventory(par, y1); tb = Lb.total + dry.Vres*dry.ce_res + dry.n_dry;
    [par2, y2, dry2, info] = dfn_dryout_update(par, y0, y1, dry);
    La = dfn_li_inventory(par2, y2); ta = La.total + dry2.Vres*dry2.ce_res + dry2.n_dry;
    p('- R_exc = %.2f: truong hop %d, R_dry = %.8f, dV_pore = %.3e m3, dV_EC = %.3e m3, A: %.6f -> %.6f m2, ti so c_e = %.8f; lech Li %.2e\n', ...
        Rx, info.case, info.R_dry, info.dV_pore, info.dV_EC, par.A, par2.A, info.c_ratio, (ta - tb)/tb);
    assert(abs(ta - tb)/tb < 1e-12, 'can kho khong bao toan Li');
    % chay tiep sau cap nhat (khoi tao nhat quan voi A moi)
    [~, c] = ag_cycle(par2, y2, 3, 313.15);
    p('  chu ky sau cap nhat: %s\n', c.reason);
end

% ---- 5. thoi gian, toc do lao hoa -------------------------------------------------
p('\n## 5. Thoi gian va toc do lao hoa (5 chu ky, bo "5 coupled")\n\n');
p('| Expt | T | s/chu ky | LLI moi chu ky (ppm Li hat) | SEI | SEI vet nut | chet | LAM | ma con lai (umol) |\n|---|---|---|---|---|---|---|---|---|\n');
for ex = [2 3]
    for Ta = [T10, T25, 313.15]
        par = ag_par(ex);
        y = dfn_init_state(par, par.neg.x100, par.pos.y100, Ta);
        if ex == 2
            [y, ~] = ag_exec(par, y, ag_step('I', 5, 0.73/5*3600, Ta, struct('Vmin', 2.5)));
        end
        [y, ~] = ag_cycle(par, y, ex, Ta);
        La = dfn_li_inventory(par, y);
        tic; for k = 1:5, [y, ~] = ag_cycle(par, y, ex, Ta); end; w = toc/5;
        Lb = dfn_li_inventory(par, y);
        p0 = La.part_n + La.part_p; q = @(f) 1e6*(Lb.(f) - La.(f))/p0/5;
        p('| %d | %.0f C | %.1f | %.2f | %.2f | %.2f | %.3f | %.3f | %.3f |\n', ex, Ta - 273.15, w, ...
            1e6*(p0 - (Lb.part_n + Lb.part_p))/p0/5, q('sei'), q('seicr'), q('dead'), ...
            1e6*((Lb.lam_n + Lb.lam_p) - (La.lam_n + La.lam_p))/p0/5, 1e6*Lb.plated);
    end
end
p('\nSo sanh: mo hinh "5 coupled" cua Li 2025, Expt 2, 25 C: LLI 9.28 %% sau 12 x 515 chu ky (dac_ta_lao_hoa.md muc 14.3) = %.1f ppm/chu ky trung binh (ca RPT, ca can kho).\n', 9.28e4/(12*515));

% ---- 6. dfn_perm_loss -----------------------------------------------------------
p('\n## 6. dfn_perm_loss: sac CC 1C 1 Ah tu ~ 60 %% SOC roi xa 0.5C ve, 25 C\n\n');
par = dfn_params();      % khong lao hoa: ham tu tao bo co lao hoa
y = dfn_init_state(par, par.neg.x100, par.pos.y100, T25);
o = dfn_run(par, y, struct('mode', 'I', 'value', 5, 'tmax', 1.9/5*3600, 'Tamb', T25, 'stop', struct('Vmin', 2.5), 'tout', []));
chg = struct('mode', 'I', 'value', -5, 'tmax', 3600/5, 'Tamb', T25, 'stop', struct('Vmax', par.V_cv), 'tout', []);
tic; R = dfn_perm_loss(par, o.y_end, chg); w = toc;
p('- %s; SEI %.4f, SEI vet nut %.4f, chet %.5f, LAM %.5f, VINH VIEN %.4f mAh; ma con lai %.2e mAh; lech Li %.1e; %.1f s\n', ...
    strjoin(R.reason, '/'), R.sei, R.seicr, R.dead, R.lam, R.perm, R.plated_left, R.Li_cons_rel, w);
assert(abs(R.Li_cons_rel) < 1e-6, 'dfn_perm_loss: khong bao toan Li');
fclose(fid);
type(fullfile(outdir, 'aging_selftest.md'));

    function p(varargin)
        fprintf(fid, varargin{:});
    end
end
