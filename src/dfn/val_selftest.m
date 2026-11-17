function val_selftest(outdir)
%VAL_SELFTEST  Kiem tra nhanh mo hinh DFN truoc khi chay kiem chung:
%  1. in cac gia tri tham so dan xuat (bo 'approved' = mac dinh, 'paper', 'code') de doi chieu
%  2. JPattern viet tay chua moi phan tu khac 0 cua Jacobian sai phan day du
%  3. bao toan lithium (pha ran va dien giai)
%  4. chu trinh: xa 1C -> nghi -> sac CC 0.3C -> giu ap CV (rang buoc dai so) -> nghi
%  5. hoi tu luoi
if nargin < 1, outdir = 'results'; end
if ~exist(outdir, 'dir'), mkdir(outdir); end
fid = fopen(fullfile(outdir, 'selftest.md'), 'w');
T25 = 298.15;
srcs = {'approved', 'paper', 'code'};
P = {dfn_params(struct('src', 'approved')), dfn_params(struct('src', 'paper')), dfn_params(struct('src', 'code'))};
nP = numel(P);

% ---- 1. tham so ----------------------------------------------------------
p('# Tu kiem tra mo hinh DFN\n\n## 1. Tham so dan xuat\n\n');
par = P{1};
p('- So an: %d (vi phan %d, dai so %d); so mau cot cua khoi dai so: %d\n', par.ix.ny, par.ix.nd, par.ix.ny - par.ix.nd, max(par.grp_aa));
p('- Dung luong dien cuc tren don vi stoich: am %.4f Ah, duong %.4f Ah\n', par.neg.Qcap, par.pos.Qcap);
p('- Dung luong giua cac gioi han stoich: am %.4f Ah, duong %.4f Ah (Li 2025: 4.865 Ah)\n', ...
    par.neg.Qcap*(par.neg.x100 - par.neg.x0), par.pos.Qcap*(par.pos.y0 - par.pos.y100));
pns = dfn_params(struct('src', 'approved', 'stress_diffusion', false));
p('- He so nhan khuech tan do ung suat (25 C): am x=0.03/0.88: %.3f / %.3f; duong y=0.24/0.93: %.1f / %.1f\n', ...
    dfn_Ds(par.neg, 0.03, T25, par)/dfn_Ds(pns.neg, 0.03, T25, pns), dfn_Ds(par.neg, 0.88, T25, par)/dfn_Ds(pns.neg, 0.88, T25, pns), ...
    dfn_Ds(par.pos, 0.24, T25, par)/dfn_Ds(pns.pos, 0.24, T25, pns), dfn_Ds(par.pos, 0.93, T25, par)/dfn_Ds(pns.pos, 0.93, T25, pns));
xs = [0.05 0.2 0.5 0.75 0.9];
p('- D_eff,n(x = %s; 25 C) = %s m2/s\n', mat2str(xs), mat2str(dfn_Ds(par.neg, xs, T25, par), 3));
p('- D_eff,p(y = %s; 25 C) = %s m2/s\n', mat2str(xs), mat2str(dfn_Ds(par.pos, xs, T25, par), 3));
p('- Kiem tra bang Kirchhoff: (K(0.6) - K(0.5))/0.1 = %.4e, D_eff(0.55) = %.4e m2/s (am)\n', ...
    (dfn_Kint(par.neg, 0.6, T25, par) - dfn_Kint(par.neg, 0.5, T25, par))/0.1, dfn_Ds(par.neg, 0.55, T25, par));
p('- j0,n(x = 0.5), j0,p(y = 0.5) tai 1 M, 25 C: %.4f, %.4f A/m2\n', dfn_j0(par.neg, 1000, 0.5, T25, par), dfn_j0(par.pos, 1000, 0.5, T25, par));
p('\n| Dai luong | bo `approved` (mac dinh) | bo `paper` (nhu bai in) | bo `code` (ma nguon tac gia) |\n|---|---|---|---|\n');
v = cell(nP, 9);
for s = 1:nP
    q = P{s};
    [De, kap, tp, tdf] = dfn_elyte(1000, T25, q);
    ag = dfn_aging_state(q, []);
    rc = dfn_rhocp(q, T25, ag);
    y100 = dfn_init_state(q, q.neg.x100, q.pos.y100, T25);
    [~, a] = dfn_rhs(0, y100, q, struct('mode', 'I', 'value', 0, 'Tamb', T25));
    v(s,:) = {sprintf('%.3e', De), sprintf('%.4f', kap), sprintf('%.4f', tp), sprintf('%.4f', tdf), ...
        sprintf('%.5e', q.sei.L_layer0), sprintf('%.6f', q.neg.eps_e), sprintf('%.3e', q.sei.rho*q.sei.L0), ...
        sprintf('%.2f J/K, tau = %.0f s', rc*q.th.Vcell, rc*q.th.Vcell/(q.th.h*q.th.Acool)), sprintf('%.4f', a.V)};
end
lab = {'D_e (1 M, 25 C) [m2/s]', 'kappa (1 M, 25 C) [S/m]', 't+ (1 M, 25 C)', 'TDF (1 M, 25 C)', 'L_SEI,0 moi lop [m]', ...
       'eps_n ban dau', 'R_film = rho_SEI.L_SEI [Ohm.m2]', 'nhiet dung cell, tau = C/(h.A) voi h = 20', 'OCV tai (x100, y100), nhanh xa [V]'};
for i = 1:9, p('| %s | %s | %s | %s |\n', lab{i}, v{1,i}, v{2,i}, v{3,i}); end
qa = P{1};
p('- Bo `approved`: rho kho [am, mang ngan, duong] = %s kg/m3; dQ ban dau (S7) = %.5f Ah; L_SEI,0 cach tinh: %s\n', ...
    mat2str(qa.th.rho_dry), qa.sei.Qloss0, qa.sei.init);
p('- Luat SEI cho buoc C (chua dung): exp(-F(phi_s - phi_e)/(RT)), he so moi lop %.4g, z_SEI = %d\n', qa.sei.growth.k_layer, qa.sei.z);
assert(qa.el.k4 == 0.353 && qa.el.tp2 == -6.12 && isequal(qa.th.rho_dry, [1740, 946, 3270]), 'bo approved: sai he so dien giai / mat do kho');
assert(abs(qa.sei.L_layer0 - 9.2282e-9) < 1e-12, 'bo approved: L_SEI,0 lech ma nguon qua nhieu');
qc = P{3};
assert(abs(qc.sei.L_layer0 - 9.23265e-9) < 2e-13 && abs(qc.neg.eps_e - 0.234965) < 2e-6, 'bo code: SEI/do xop ban dau khong khop ma nguon');
pchk = dfn_params(struct('src', 'paper', 'L_SEI_layer0', 1.236e-8));
assert(abs(pchk.neg.eps_e - 0.222) < 1e-3, 'S10-S11 khong khop vi du cua bai bao');

% ---- 2, 3. JPattern va bao toan (ca hai bo) ------------------------------
for s = 1:nP
    par = P{s};
    p('\n## 2.%d JPattern va bao toan - bo `%s` (xa 1C 600 s tu 100 %% SOC, 25 C)\n\n', s, srcs{s});
    y100 = dfn_init_state(par, par.neg.x100, par.pos.y100, T25);
    st = struct('mode', 'I', 'value', 5, 'tmax', 600, 'Tamb', T25, 'stop', struct('Vmin', par.Vmin), 'tout', []);
    tic; o1 = dfn_run(par, y100, st); w1 = toc;
    ymid = o1.y_end;
    p('- xa 1C 600 s: ket thuc "%s" tai t = %.1f s, V = %.4f V, T = %.2f degC; %d lan goi ve phai, %.1f s\n', ...
        o1.reason{1}, o1.t(end), o1.V(end), o1.T(end) - 273.15, o1.nfev(1), w1);
    ctlI = struct('mode', 'I', 'value', 5, 'Tamb', T25);
    ctlV = struct('mode', 'V', 'value', 4.0, 'Tamb', T25);
    rng(1);
    miss = 0; nnzJ = 0; ny = par.ix.ny;
    for trial = 1:2
        yb = ymid.*(1 + 1e-3*randn(ny,1)) + 1e-4*randn(ny,1);
        yb(par.ix.I) = -0.02 - 0.001*trial;      % gan diem chuyen nhanh hysteresis de dOCP/dI khac 0
        for cc = {ctlI, ctlV}
            c = cc{1};
            f0 = dfn_rhs(0, yb, par, c);
            J = zeros(ny);
            for j = 1:ny
                yq = yb; dl = 1e-6*max(1, abs(yb(j))); yq(j) = yq(j) + dl;
                J(:,j) = (dfn_rhs(0, yq, par, c) - f0)/dl;
            end
            nzm = abs(J) > 1e-9*max(abs(J(:)));
            bad = nzm & ~full(par.S);
            miss = miss + nnz(bad); nnzJ = max(nnzJ, nnz(nzm));
            [r, cidx] = find(bad);
            for k = 1:min(10, numel(r)), p('  - thieu (%d, %d), |J| = %.3e\n', r(k), cidx(k), abs(J(r(k), cidx(k)))); end
        end
    end
    p('- nnz(JPattern) = %d, nnz lon nhat cua Jacobian sai phan = %d, phan tu nam ngoai JPattern: %d\n', nnz(par.S), nnzJ, miss);
    assert(miss == 0, 'JPattern thieu phan tu');
    [n1, p1, e1] = inventory(par, y100); [n2, p2, e2] = inventory(par, ymid);
    dq = o1.Q(end)*3600/par.F;
    p('- Li roi cuc am: %.6f mol; Li vao cuc duong: %.6f mol; I.t/F = %.6f mol\n', n1 - n2, p2 - p1, dq);
    p('- Li trong dien giai: %.8f -> %.8f mol (sai lech tuong doi %.2e)\n', e1, e2, abs(e2 - e1)/e1);
    assert(abs((n1 - n2) - dq) < 1e-4*dq && abs((p2 - p1) - dq) < 1e-4*dq, 'khong bao toan lithium pha ran');
    assert(abs(e2 - e1)/e1 < 1e-6, 'khong bao toan lithium dien giai');
end

% ---- 4. chu trinh ---------------------------------------------------------
% Them bo approved CU (cuc am con hysteresis, ocp_n_branch = 'hyst', truoc 17/11/2026) de so sanh.
Pc = [P, {dfn_params(struct('src', 'approved', 'ocp_n_branch', 'hyst'))}];
srcc = [srcs, {'approved_old (hyst cuc am)'}];
for s = 1:numel(Pc)
    par = Pc{s};
    p('\n## 3.%d Chu trinh - bo `%s`: xa 1C toi 2.5 V -> nghi 30 phut -> sac CC 0.3C toi 4.2 V -> giu ap toi C/100 -> nghi 30 phut (25 C)\n\n', s, srcc{s});
    p(['| Buoc | Ly do dung | thoi luong (s) | V cuoi (V) | I cuoi (A) | T cuoi (degC) | Q da xa (Ah) | x_surf am [min, max] | ' ...
       'max x_surf am trong buoc | min(phi_s - phi_e) phia mang ngan trong buoc (mV) | so lan goi ve phai | thoi gian chay (s) |\n|---|---|---|---|---|---|---|---|---|---|---|---|\n']);
    y = dfn_init_state(par, par.neg.x100, par.pos.y100, T25);
    nm = {'xa 1C', 'nghi', 'sac CC 0.3C', 'giu ap CV 4.2 V', 'nghi'};
    cc = dfn_cccv(0.3*par.Qnom, par.Vmax, par.Qnom/100, T25);
    stl = {struct('mode', 'I', 'value', 5, 'tmax', 2*3600, 'Tamb', T25, 'stop', struct('Vmin', par.Vmin), 'tout', []), ...
           struct('mode', 'rest', 'value', 0, 'tmax', 1800, 'Tamb', T25, 'stop', struct(), 'tout', []), ...
           cc(1), cc(2), ...
           struct('mode', 'rest', 'value', 0, 'tmax', 1800, 'Tamb', T25, 'stop', struct(), 'tout', [])};
    prev = '';
    for k = 1:5
        if k == 4 && ~strcmp(prev, 'Vmax')
            p('| %s | (bo qua: pha CC khong ket thuc o Vmax) | | | | | | | | | | |\n', nm{k}); continue;
        end
        tic; o = dfn_run(par, y, stl{k}); w = toc;
        y = o.y_end; prev = o.reason{1};
        p('| %s | %s | %.1f | %.4f | %.3f | %.2f | %.4f | [%.4f, %.4f] | %.5f | %.1f | %d | %.1f |\n', nm{k}, o.reason{1}, o.t(end), o.V(end), o.I(end), ...
            o.T(end) - 273.15, o.Q(end), o.xsn(end,1), o.xsn(end,2), max(o.xsn(:,2)), 1e3*min(o.dphi_sep), o.nfev(1), w);
        if k == 4
            p('\n- Pha CV: max|V - 4.2| = %.2e V\n\n', max(abs(o.V - par.Vmax)));
            assert(max(abs(o.V - par.Vmax)) < 1e-4, 'rang buoc giu ap khong thoa');
        end
        if strcmp(o.reason{1}, 'solver_failed'), p('\n- BO GIAI THAT BAI o buoc "%s" (bo `%s`)\n', nm{k}, srcc{s}); break; end
    end
end

% ---- 5. hoi tu luoi -------------------------------------------------------
p('\n## 4. Hoi tu luoi - bo `approved` (so voi luoi min [40 20 40 | 200 60])\n\n');
mo = {struct('src', 'approved', 'Nn', 40, 'Ns', 20, 'Np', 40, 'Nrn', 200, 'Nrp', 60), struct('src', 'approved'), ...
      struct('src', 'approved', 'Nn', 10, 'Ns', 5, 'Np', 5, 'Nrn', 100, 'Nrp', 20)};
pl = {dfn_params(mo{1}), dfn_params(mo{2}), dfn_params(mo{3})};
lab = {'min [40 20 40 - 200 60]', sprintf('mac dinh [%d %d %d - %d %d]', pl{2}.cfg.Nn, pl{2}.cfg.Ns, pl{2}.cfg.Np, pl{2}.cfg.Nrn, pl{2}.cfg.Nrp), 'Li 2025 [10 5 5 - 100 20]'};
% {ten, I [A], T [degC], x dau, y dau}
cases = {'xa 1C, 25 degC', 5, 25, par.neg.x100, par.pos.y100; ...
         'xa 2C, 0 degC', 10, 0, par.neg.x100, par.pos.y100; ...
         'sac 0.3C, 25 degC (tu 0 % SOC)', -1.5, 25, par.neg.x0, par.pos.y0; ...
         'sac 1C, 25 degC (tu 0 % SOC)', -5, 25, par.neg.x0, par.pos.y0};
p('| Truong hop | Luoi | ly do dung | RMS(dV) (mV) | max(dV) (mV) | max(dT) (K) | Q cuoi (Ah) | x_surf am max | so lan goi ve phai | thoi gian chay (s) |\n|---|---|---|---|---|---|---|---|---|---|\n');
for ci = 1:size(cases,1)
    Ta = cases{ci,3} + 273.15; Ic = cases{ci,2};
    tg = linspace(0, 3600*5/abs(Ic)*1.1, 800).';
    stp = struct('mode', 'I', 'value', Ic, 'tmax', tg(end), 'Tamb', Ta, 'stop', struct('Vmin', par.Vmin, 'Vmax', par.Vmax), 'tout', tg);
    res = cell(1,3); wl = zeros(1,3);
    for m = 1:3
        tic; res{m} = dfn_run(pl{m}, dfn_init_state(pl{m}, cases{ci,4}, cases{ci,5}, Ta), stp); wl(m) = toc;
    end
    for m = 1:3
        tc = min(res{1}.t(end), res{m}.t(end))*0.98;
        k = tg <= tc;
        dV = interp1(res{m}.t, res{m}.V, tg(k)) - interp1(res{1}.t, res{1}.V, tg(k));
        dT = interp1(res{m}.t, res{m}.T, tg(k)) - interp1(res{1}.t, res{1}.T, tg(k));
        p('| %s | %s | %s | %.2f | %.2f | %.3f | %.4f | %.4f | %d | %.1f |\n', cases{ci,1}, lab{m}, res{m}.reason{1}, ...
            1e3*sqrt(mean(dV.^2)), 1e3*max(abs(dV)), max(abs(dT)), res{m}.Q(end), max(res{m}.xsn(:,2)), res{m}.nfev(1), wl(m));
    end
end
fclose(fid);
fprintf('\nTU KIEM TRA: XONG\n');

    function p(varargin)
        fprintf(varargin{:}); fprintf(fid, varargin{:});
    end
end

function [nLi_n, nLi_p, nLi_e] = inventory(par, y)
g = par.grid;
thn = reshape(y(par.ix.thn), g.Nrn, g.Nn); thp = reshape(y(par.ix.thp), g.Nrp, g.Np);
ag = dfn_aging_state(par, y);
xn = (g.Vshn.'*thn)/sum(g.Vshn); yp = (g.Vshp.'*thp)/sum(g.Vshp);
nLi_n = par.A*sum(xn.'.*ag.as_n/3*par.neg.Rp*g.dxn)*par.neg.cmax;      % mol
nLi_p = par.A*sum(yp.'.*ag.as_p/3*par.pos.Rp*g.dxp)*par.pos.cmax;
nLi_e = par.A*sum(ag.eps.*g.dx.*y(par.ix.ce))*par.ce_ref;
end
