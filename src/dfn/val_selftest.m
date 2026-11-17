function val_selftest(outdir)
%VAL_SELFTEST  Kiem tra nhanh mo hinh DFN truoc khi chay kiem chung:
%  1. in cac gia tri tham so dan xuat de doi chieu voi bai bao
%  2. JPattern viet tay co chua moi phan tu khac 0 cua Jacobian sai phan day du
%  3. bao toan lithium (pha ran va dien giai) va can bang nang luong
%  4. chu trinh: xa 1C -> nghi -> sac CC-CV 0.3C (giu ap bang rang buoc dai so) -> nghi
%  5. hoi tu luoi: luoi mac dinh so voi luoi min
if nargin < 1, outdir = 'results'; end
if ~exist(outdir, 'dir'), mkdir(outdir); end
fid = fopen(fullfile(outdir, 'selftest.md'), 'w');
par = dfn_params();
T25 = 298.15;

% ---- 1. tham so ----------------------------------------------------------
p('# Tu kiem tra mo hinh DFN\n\n## 1. Tham so dan xuat\n\n');
p('- So an: %d (vi phan %d, dai so %d); so mau cot cua khoi dai so: %d\n', par.ix.ny, par.ix.nd, par.ix.ny - par.ix.nd, max(par.grp_aa));
p('- L_SEI,0 moi lop = %.5e m; eps_n = %.6f (ma nguon Li 2025, bo "5 coupled": 9.23265e-9 m va 0.234965)\n', par.sei.L_layer0, par.neg.eps_e);
assert(abs(par.sei.L_layer0 - 9.23265e-9) < 2e-13 && abs(par.neg.eps_e - 0.234965) < 2e-6, 'SEI/do xop ban dau khong khop ma nguon');
pchk = dfn_params(struct('V_SEI', 9.585e-5, 'L_SEI_extra', 0));
p('- Kiem tra pt. S7-S11 voi V_SEI = 9.585e-5, khong cong 2.5 nm: L_layer0 = %.4e m, eps_n = %.4f (SI Note 9: 1.236e-8 m va 0.222)\n', pchk.sei.L_layer0, pchk.neg.eps_e);
assert(abs(pchk.sei.L_layer0 - 1.236e-8) < 2e-11 && abs(pchk.neg.eps_e - 0.222) < 1e-3, 'S7-S11 khong khop vi du cua bai bao');
pns = dfn_params(struct('stress_diffusion', false));
p('- He so nhan khuech tan do ung suat (25 C): am x=0.03/0.88: %.3f / %.3f; duong y=0.24/0.93: %.1f / %.1f\n', ...
    dfn_Ds(par.neg, 0.03, T25, par)/dfn_Ds(pns.neg, 0.03, T25, pns), dfn_Ds(par.neg, 0.88, T25, par)/dfn_Ds(pns.neg, 0.88, T25, pns), ...
    dfn_Ds(par.pos, 0.24, T25, par)/dfn_Ds(pns.pos, 0.24, T25, pns), dfn_Ds(par.pos, 0.93, T25, par)/dfn_Ds(pns.pos, 0.93, T25, pns));
p('- Dung luong dien cuc tren don vi stoich: am %.4f Ah, duong %.4f Ah\n', par.neg.Qcap, par.pos.Qcap);
p('- Dung luong giua cac gioi han stoich: am %.4f Ah, duong %.4f Ah (Li 2025: 4.865 Ah)\n', ...
    par.neg.Qcap*(par.neg.x100 - par.neg.x0), par.pos.Qcap*(par.pos.y0 - par.pos.y100));
[De, kap, tp, tdf] = dfn_elyte(1000, T25);
p('- Dien giai 1 M, 25 C: D_e = %.3e m2/s, kappa = %.4f S/m, t+ = %.4f, TDF = %.4f\n', De, kap, tp, tdf);
assert(kap > 0.5 && kap < 1.5 && tp > 0.1 && tp < 0.5 && tdf > 1 && tdf < 4, 'tinh chat dien giai phi vat ly');
xs = [0.05 0.2 0.5 0.9];
p('- D_eff,n(x = %s; 25 C) = %s m2/s\n', mat2str(xs), mat2str(dfn_Ds(par.neg, xs, T25, par), 3));
p('- D_eff,p(y = %s; 25 C) = %s m2/s\n', mat2str(xs), mat2str(dfn_Ds(par.pos, xs, T25, par), 3));
p('- j0,n(x = 0.5), j0,p(y = 0.5) tai 1 M, 25 C: %.4f, %.4f A/m2\n', dfn_j0(par.neg, 1000, 0.5, T25, par), dfn_j0(par.pos, 1000, 0.5, T25, par));
ag = dfn_aging_state(par, []);
rc = dfn_rhocp(par, T25, ag);
p('- rho.c_p hieu dung (25 C) = %.4e J/m3/K -> nhiet dung cell = %.2f J/K; h.A = %.4f W/K; hang so thoi gian nhiet = %.0f s\n', ...
    rc, rc*par.th.Vcell, par.th.h*par.th.Acool, rc*par.th.Vcell/(par.th.h*par.th.Acool));
y100 = dfn_init_state(par, par.neg.x100, par.pos.y100, T25);
[~, a] = dfn_rhs(0, y100, par, struct('mode', 'I', 'value', 0, 'Tamb', T25));
p('- OCV tai diem 100 %% SOC (x = %.4f, y = %.4f), nhanh xa: %.4f V\n', par.neg.x100, par.pos.y100, a.V);
y0s = dfn_init_state(par, par.neg.x0, par.pos.y0, T25);
[~, a0] = dfn_rhs(0, y0s, par, struct('mode', 'I', 'value', 0, 'Tamb', T25));
p('- OCV tai diem 0 %% SOC (x = %.4f, y = %.4f), nhanh xa: %.4f V\n', par.neg.x0, par.pos.y0, a0.V);

% ---- 4. chu trinh (chay truoc de co trang thai giua chung cho muc 2, 3) --
p('\n## 2. Chu trinh xa 1C -> nghi 30 phut -> sac CC-CV 0.3C / 4.2 V / C-100 -> nghi 30 phut (25 C)\n\n');
st = struct('mode', 'I', 'value', 5, 'tmax', 600, 'Tamb', T25, 'stop', struct('Vmin', par.Vmin), 'tout', []);
tic; o1 = dfn_run(par, y100, st); w1 = toc;
ymid = o1.y_end;
st2(1) = struct('mode', 'I', 'value', 5, 'tmax', 2*3600, 'Tamb', T25, 'stop', struct('Vmin', par.Vmin), 'tout', []);
st2(2) = struct('mode', 'rest', 'value', 0, 'tmax', 1800, 'Tamb', T25, 'stop', struct(), 'tout', []);
cc = dfn_cccv(0.3*par.Qnom, par.Vmax, par.Qnom/100, T25);
st2(3) = cc(1); st2(4) = cc(2);
st2(5) = struct('mode', 'rest', 'value', 0, 'tmax', 1800, 'Tamb', T25, 'stop', struct(), 'tout', []);
tic; o2 = dfn_run(par, ymid, st2); w2 = toc;
nm = {'xa 1C (tiep)', 'nghi', 'sac CC 0.3C', 'giu ap CV', 'nghi'};
p('| Buoc | Ly do dung | t cuoi buoc (s) | V cuoi (V) | I cuoi (A) | T cuoi (degC) | Q (Ah) | so buoc ode | buoc hong |\n|---|---|---|---|---|---|---|---|---|\n');
p('| xa 1C 600 s | %s | %.1f | %.4f | %.3f | %.2f | %.4f | %d | %d |\n', o1.reason{1}, o1.t(end), o1.V(end), o1.I(end), o1.T(end) - 273.15, o1.Q(end), o1.nsteps(1), o1.nfail(1));
for k = 1:5
    i = find(o2.step == k, 1, 'last');
    p('| %s | %s | %.1f | %.4f | %.3f | %.2f | %.4f | %d | %d |\n', nm{k}, o2.reason{k}, o2.t(i), o2.V(i), o2.I(i), o2.T(i) - 273.15, o2.Q(i), o2.nsteps(k), o2.nfail(k));
end
p('\n- Thoi gian chay: xa 600 s: %.1f s; chu trinh con lai: %.1f s (may GitHub Actions)\n', w1, w2);
assert(~any(strcmp([o1.reason, o2.reason], 'solver_failed')), 'bo giai that bai trong chu trinh');
assert(strcmp(o2.reason{1}, 'Vmin') && strcmp(o2.reason{3}, 'Vmax') && strcmp(o2.reason{4}, 'Icut'), 'ly do dung khong dung');
i3 = find(o2.step == 3, 1, 'last'); i4 = o2.step == 4;
p('- Chuyen CC -> CV: V = %.5f V, dong lien tuc %.4f -> %.4f A; trong pha CV: max|V - 4.2| = %.2e V\n', ...
    o2.V(i3), o2.I(i3), o2.I(find(i4, 1)), max(abs(o2.V(i4) - par.Vmax)));
assert(max(abs(o2.V(i4) - par.Vmax)) < 1e-4, 'rang buoc giu ap khong thoa');
p('- Dung luong xa 1C tu diem 100 %% SOC: %.4f Ah; dung luong sac lai: %.4f Ah\n', o1.Q(end) + (o2.Q(find(o2.step == 1, 1, 'last')) - o2.Q(1)), ...
    o2.Q(find(o2.step == 2, 1, 'last')) - o2.Q(end));

% ---- 2. JPattern --------------------------------------------------------
p('\n## 3. Kiem tra JPattern\n\n');
ctlI = struct('mode', 'I', 'value', 5, 'Tamb', T25);
ctlV = struct('mode', 'V', 'value', 4.0, 'Tamb', T25);
rng(1);
miss = 0; nnzJ = 0;
ny = par.ix.ny;
for trial = 1:2
    yb = ymid.*(1 + 1e-3*randn(ny,1)) + 1e-4*randn(ny,1);
    yb(par.ix.I) = -0.02 - 0.001*trial;      % gan diem chuyen nhanh hysteresis de dOCP/dI khac 0
    for ctl = {ctlI, ctlV}
        c = ctl{1};
        f0 = dfn_rhs(0, yb, par, c);
        J = zeros(ny);
        for j = 1:ny
            yp = yb; dl = 1e-6*max(1, abs(yb(j))); yp(j) = yp(j) + dl;
            J(:,j) = (dfn_rhs(0, yp, par, c) - f0)/dl;
        end
        nzm = abs(J) > 1e-9*max(abs(J(:)));
        miss = miss + nnz(nzm & ~full(par.S));
        nnzJ = max(nnzJ, nnz(nzm));
        if nnz(nzm & ~full(par.S)) > 0
            [r, cidx] = find(nzm & ~full(par.S));
            for q = 1:min(10, numel(r)), p('  - thieu (%d, %d), |J| = %.3e\n', r(q), cidx(q), abs(J(r(q), cidx(q)))); end
        end
    end
end
p('- nnz(JPattern) = %d, nnz lon nhat cua Jacobian sai phan = %d, phan tu nam ngoai JPattern: %d\n', nnz(par.S), nnzJ, miss);
assert(miss == 0, 'JPattern thieu phan tu');

% ---- 3. bao toan ---------------------------------------------------------
p('\n## 4. Bao toan (xa 1C trong 600 s tu 100 %% SOC, 25 C)\n\n');
g = par.grid;
[n1, p1, e1] = inventory(y100); [n2, p2, e2] = inventory(ymid);
dq = o1.Q(end)*3600/par.F;
p('- Li roi cuc am: %.6f mol; Li vao cuc duong: %.6f mol; I.t/F = %.6f mol\n', n1 - n2, p2 - p1, dq);
p('- Li trong dien giai: %.8f -> %.8f mol (sai lech tuong doi %.2e)\n', e1, e2, abs(e2 - e1)/e1);
assert(abs((n1 - n2) - dq) < 1e-4*dq && abs((p2 - p1) - dq) < 1e-4*dq, 'khong bao toan lithium pha ran');
assert(abs(e2 - e1)/e1 < 1e-6, 'khong bao toan lithium dien giai');

% ---- 5. hoi tu luoi ------------------------------------------------------
p('\n## 5. Hoi tu luoi (xa tu 100 %% SOC toi 2.5 V; so voi luoi min [40 20 40 | 200 60])\n\n');
parF = dfn_params(struct('Nn', 40, 'Ns', 20, 'Np', 40, 'Nrn', 200, 'Nrp', 60));
parC = dfn_params(struct('Nn', 10, 'Ns', 5, 'Np', 5, 'Nrn', 100, 'Nrp', 20));
cases = {1, 25; 2, 25; 2, 0};
p('| Truong hop | Luoi | RMS(dV) (mV) | max(dV) (mV) | max(dT) (K) | dung luong (Ah) | thoi gian chay (s) |\n|---|---|---|---|---|---|---|\n');
for ci = 1:size(cases,1)
    Ta = cases{ci,2} + 273.15; Ic = cases{ci,1}*par.Qnom;
    tg = linspace(0, 3600/cases{ci,1}*1.1, 800).';
    stp = struct('mode', 'I', 'value', Ic, 'tmax', tg(end), 'Tamb', Ta, 'stop', struct('Vmin', par.Vmin), 'tout', tg);
    res = cell(1,3); wl = zeros(1,3); pl = {parF, par, parC};
    for m = 1:3
        tic; res{m} = dfn_run(pl{m}, dfn_init_state(pl{m}, par.neg.x100, par.pos.y100, Ta), stp); wl(m) = toc;
        assert(~strcmp(res{m}.reason{1}, 'solver_failed'), 'bo giai that bai (hoi tu luoi)');
    end
    lab = {'min [40 20 40 | 200 60]', sprintf('mac dinh [%d %d %d | %d %d]', par.cfg.Nn, par.cfg.Ns, par.cfg.Np, par.cfg.Nrn, par.cfg.Nrp), 'Li 2025 [10 5 5 | 100 20]'};
    for m = 1:3
        tc = min(res{1}.t(end), res{m}.t(end))*0.98;
        k = tg <= tc;
        dV = interp1(res{m}.t, res{m}.V, tg(k)) - interp1(res{1}.t, res{1}.V, tg(k));
        dT = interp1(res{m}.t, res{m}.T, tg(k)) - interp1(res{1}.t, res{1}.T, tg(k));
        p('| %gC, %d degC | %s | %.2f | %.2f | %.3f | %.4f | %.1f |\n', cases{ci,1}, cases{ci,2}, lab{m}, ...
            1e3*sqrt(mean(dV.^2)), 1e3*max(abs(dV)), max(abs(dT)), res{m}.Q(end), wl(m));
    end
end
fclose(fid);
fprintf('\nTU KIEM TRA: DAT\n');

    function p(varargin)
        fprintf(varargin{:}); fprintf(fid, varargin{:});
    end
    function [nLi_n, nLi_p, nLi_e] = inventory(y)
        thn = reshape(y(par.ix.thn), g.Nrn, g.Nn); thp = reshape(y(par.ix.thp), g.Nrp, g.Np);
        agl = dfn_aging_state(par, y);
        xn = (g.Vshn.'*thn)/sum(g.Vshn); yp_ = (g.Vshp.'*thp)/sum(g.Vshp);
        nLi_n = par.A*sum(xn.'.*agl.as_n/3*par.neg.Rp*g.dxn)*par.neg.cmax;      % mol
        nLi_p = par.A*sum(yp_.'.*agl.as_p/3*par.pos.Rp*g.dxp)*par.pos.cmax;
        nLi_e = par.A*sum(agl.eps.*g.dx.*y(par.ix.ce))*par.ce_ref;
    end
end
