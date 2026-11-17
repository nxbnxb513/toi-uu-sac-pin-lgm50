function [fx, g, o] = rom_equations(rom, par, x, z, I, Tamb)
%ROM_EQUATIONS  Ve phai cua mo hinh rut gon (ROM) viet bang CasADi SX.
%   [fx, g, o] = rom_equations(rom, par, x, z, I, Tamb)
%   x  trang thai vi phan (rom.ix), z bien dai so (rom.iz), I dong cell [A]
%   (> 0 la XA, nhu DFN), Tamb [K]. Tra ve dx/dt = fx, rang buoc dai so g = 0,
%   va cac dai luong ra o (dien ap, the phia mang ngan, toc do lao hoa ...).
%
% Day la DFN (src/dfn/dfn_rhs.m) voi cung phuong trinh va cung tham so, rời rạc
% hoa THO HON: it o theo x (luoi khong deu, rom_setup.m) va it vo trong hat
% (khong deu, day hon sat be mat). Cac thay doi so voi dfn_rhs.m, deu ghi trong
% tai_lieu/mo_hinh_rut_gon.md:
%  1. Bien dai so chi gom mat do dong j tai moi o va hai moc the (phi_e o o dau,
%     phi_s o o dau cuc duong). phi_s, phi_e, i_s, i_e tai moi cho duoc TICH PHAN
%     GIAI TICH tu j (phan ung deu trong moi o => dong bien thien tuyen tinh
%     trong o), thay vi giai he dai so tren luoi min.
%  2. Thong luong trong hat: hieu tich phan Kirchhoff tinh bang cau phuong
%     Gauss-Legendre cua dfn_Ds.m (DFN dung bang noi suy, rom_dK.m).
%  3. Chan [1e-8, 1 - 1e-8] cua stoich be mat va chan duoi c_e >= 1e-2 viet
%     bang ham min/max TRON (rom_smin/rom_smax) de NMPC co dao ham lien tuc.
%  4. Nhiet Joule tich phan dung voi profile dong tuyen tinh trong moi o.
% Cac ham OCP, j0, D_s dung TRUC TIEP ham cua DFN (dfn_ocp_neg/pos, dfn_j0,
% dfn_Ds); dien giai va nhiet dung la ban sao cong thuc (rom_elyte, rom_rhocp)
% duoc rom_unit_tests.m so tung so voi ham DFN.
F = par.F; Rg = par.R;
Nn = rom.Nn; Ns = rom.Ns; Np = rom.Np; N = rom.N; ix = rom.ix; iz = rom.iz;
dx = rom.dx; in = rom.in; ip = rom.ip;
T = x(ix.T);
RTF = Rg*T/F;
iapp = I/par.A;
ce  = x(ix.ce)*par.ce_ref;
cep = rom_smax(ce, 1e-2, 1e-3);
cLi = x(ix.cLi);
jn = z(iz.jn); jp = z(iz.jp);

% ---- stoich trong hat va tai be mat -------------------------------------
thn = cell(Nn, 1); thp = cell(Np, 1);
for k = 1:Nn, thn{k} = x(ix.thn((k-1)*rom.Nrn + (1:rom.Nrn))); end
for k = 1:Np, thp{k} = x(ix.thp((k-1)*rom.Nrp + (1:rom.Nrp))); end
thsn = cell(Nn, 1); thsp = cell(Np, 1);
for k = 1:Nn, t_ = thn{k}; thsn{k} = t_(rom.Nrn) + rom.cextn*(t_(rom.Nrn) - t_(rom.Nrn-1)); end
for k = 1:Np, t_ = thp{k}; thsp{k} = t_(rom.Nrp) + rom.cextp*(t_(rom.Nrp) - t_(rom.Nrp-1)); end
thsn = vertcat(thsn{:}); thsp = vertcat(thsp{:});
xsn = clamp01(thsn); xsp = clamp01(thsp);

% ---- OCP hai nhanh + hysteresis "current sigmoid" (giong dfn_rhs.m) ------
[Un, Up, dUn, dUp] = rom_ocp(par, xsn, xsp, iapp, T);   % cung logic voi dfn_rhs.m (kiem tra trong rom_unit_tests.m)

% ---- khuech tan trong hat -----------------------------------------------
dth = cell(Nn + Np, 1);
for k = 1:Nn
    dth{k} = particle(par.neg, thn{k}, jn(k), rom.rfn, rom.rcn, rom.Vshn);
end
for k = 1:Np
    dth{Nn + k} = particle(par.pos, thp{k}, jp(k), rom.rfp, rom.rcp, rom.Vshp);
end

% ---- dien giai: tinh chat, dong i_e, the phi_e --------------------------
[De, kap] = rom_elyte(cep, T, par);
Deff = De.*rom.eps.^rom.brug;  keff = kap.*rom.eps.^rom.brug;
wL = dx(1:N-1); wR = dx(2:N); dxc = 0.5*(wL + wR);
Df = (wL + wR)./(wL./Deff(1:N-1) + wR./Deff(2:N));            % trung binh dieu hoa (nhu DFN)
cf = (cep(1:N-1).*wR + cep(2:N).*wL)./(wL + wR);
[~, ~, tpf, tdff] = rom_elyte(cf, T, par);
aj = [rom.as_n*jn; zeros(Ns, 1); rom.as_p*jp];                 % A/m3
ajdx = aj.*dx;                                                  % A/m2 moi o
ief = cell(N-1, 1); acc = 0;
for k = 1:N-1, acc = acc + ajdx(k); ief{k} = acc; end
ief = vertcat(ief{:});                                          % i_e tai mat trong
ieL = [0; ief]; ieR = [ief; 0];                                 % i_e = 0 tai hai current collector
iec = ieL + 0.5*ajdx;                                           % i_e tai tam o
lnc = log(cep);
dlnc = lnc(2:N) - lnc(1:N-1);
difp = 2*(1 - tpf).*tdff.*RTF.*dlnc;                            % the khuech tan giua hai tam [V]
ohm  = (iec(1:N-1) + ief)/2.*(wL/2)./keff(1:N-1) + (ief + iec(2:N))/2.*(wR/2)./keff(2:N);
phie = cell(N, 1); phie{1} = z(iz.phie1);
for k = 1:N-1, phie{k+1} = phie{k} - ohm(k) + difp(k); end
phie = vertcat(phie{:});
Nf = -Df.*(ce(2:N) - ce(1:N-1))./dxc + tpf.*ief/F;             % mol/m2/s tai mat trong
dce = (-([Nf; 0] - [0; Nf])./dx + aj/F)./rom.eps;

% ---- pha ran -------------------------------------------------------------
sn = par.neg.sigma*par.neg.eps_s^par.neg.brug_s;
sp = par.pos.sigma_ref*exp(-par.pos.sigma_E/Rg*(1/T - 1/par.Tref))*par.pos.eps_s^par.pos.brug_s;
isL = iapp - ieL; isR = iapp - ieR; isC = iapp - iec;           % dong pha ran (chi dung trong dien cuc)
dxn = dx(in); dxp = dx(ip);
phisn = cell(Nn, 1);
phisn{1} = -(isL(1) + isC(1))/2*(dxn(1)/2)/sn;                   % phi_s = 0 tai x = 0
for k = 1:Nn-1
    phisn{k+1} = phisn{k} - ((isC(k) + isR(k))/2*dxn(k)/2 + (isL(k+1) + isC(k+1))/2*dxn(k+1)/2)/sn;
end
phisn = vertcat(phisn{:});
isLp = isL(ip); isRp = isR(ip); isCp = isC(ip);
phisp = cell(Np, 1); phisp{1} = z(iz.phisp1);
for k = 1:Np-1
    phisp{k+1} = phisp{k} - ((isCp(k) + isRp(k))/2*dxp(k)/2 + (isLp(k+1) + isCp(k+1))/2*dxp(k+1)/2)/sp;
end
phisp = vertcat(phisp{:});
phisL = phisp(Np) - (isCp(Np) + iapp)/2*(dxp(Np)/2)/sp;
V = phisL - I*par.Rcontact;

% ---- dong hoc Butler-Volmer (dang nghich dao nhu dfn_rhs.m) --------------
j0n = dfn_j0(par.neg, cep(in), xsn, T, par);
j0p = dfn_j0(par.pos, cep(ip), xsp, T, par);
dphin = phisn - phie(in); dphip = phisp - phie(ip);
eta_n = dphin - Un - jn*rom.Rfilm_n;
eta_p = dphip - Up - jp*rom.Rfilm_p;
res_n = eta_n - 2*RTF*asinh(jn./(2*j0n));
res_p = eta_p - 2*RTF*asinh(jp./(2*j0p));
jscale = rom.as_n*par.neg.L;
g = [res_n; res_p; (rom.as_n*(dxn.'*jn) - iapp)/jscale; (rom.as_p*(dxp.'*jp) + iapp)/jscale];

% ---- nhiet lumped (cung cac nguon nhiet nhu dfn_rhs.m) -------------------
q_ohm_s = (dxn.'*((isL(in).^2 + isL(in).*isR(in) + isR(in).^2)/3))/sn ...
        + (dxp.'*((isLp.^2 + isLp.*isRp + isRp.^2)/3))/sp;
q_ohm_e = dx.'*((ieL.^2 + ieL.*ieR + ieR.^2)/3./keff) ...
        - difp.'*(((iec(1:N-1) + ief)/2.*(wL/2) + (ief + iec(2:N))/2.*(wR/2))./dxc);
q_rxn = rom.as_n*(dxn.'*(jn.*(dphin - Un))) + rom.as_p*(dxp.'*(jp.*(dphip - Up)));
q_rev = rom.as_n*(dxn.'*(jn.*T.*dUn)) + rom.as_p*(dxp.'*(jp.*T.*dUp));
q_cc = iapp^2*(par.th.Lcc_n/par.th.scc_n + par.th.Lcc_p/par.th.scc_p);
q_ct = 0;
if par.th.contact_heat, q_ct = I^2*par.Rcontact/par.A; end
q = q_ohm_s + q_ohm_e + q_rxn + q_rev + q_cc + q_ct;            % W/m2 dien cuc
rhocp = rom_rhocp(par, T, rom.eps_region);
dT = (q/par.th.Ltot - par.th.hA_V*(T - Tamb))/rhocp;

% ---- lao hoa TAM THOI (khong hoi tiep vao dien hoa, xem aging_params.m) ---
ap = rom.ap;
[rsei, jpl, etapl] = aging_rates(ap, par, dphin, jn, cep(in), T, cLi);
dcLi  = -rom.as_n*jpl/F - ap.gamma0*cLi;                           % mol/m3/s
dnsei = par.A*(dxn.'*rsei)*F/3.6;                                 % mAh/s
dnpl  = -par.A*rom.as_n*(dxn.'*jpl)/3.6;                          % mAh/s (thuan nghich + chet)

dsoc = -I/(3600*rom.Csoc);
fx = [vertcat(dth{:}); dce/par.ce_ref; dT; dsoc; dcLi; dnsei; dnpl];

o.V = V; o.T = T; o.soc = x(ix.soc);
o.xsn = thsn; o.xsp = thsp;
o.dphi = dphin; o.etapl = etapl; o.rsei = rsei; o.jpl = jpl;
o.xs_sep = thsn(Nn); o.dphi_sep = dphin(Nn); o.eta_sep = etapl(Nn);
o.ce = ce; o.q = q; o.Un = Un; o.Up = Up; o.jn = jn; o.jp = jp;
o.phisn = phisn; o.phie = phie; o.phisp = phisp;

    function dthk = particle(el, th, j, rf, rc, Vsh)
        Nr = numel(Vsh);
        dK = rom_dK(el, th(1:Nr-1), th(2:Nr), T, par, rom.gl);
        fl = [0; dK./(rc(2:Nr) - rc(1:Nr-1)); -j/(F*el.cmax)];   % D dtheta/dr tai cac mat vo
        r2 = rf.^2;
        dthk = (r2(2:end).*fl(2:end) - r2(1:end-1).*fl(1:end-1))./Vsh;
    end
end

function v = clamp01(t)
% chan [1e-8, 1 - 1e-8] tron (DFN: min/max cung)
v = rom_smin(rom_smax(t, 1e-8, 1e-9), 1 - 1e-8, 1e-9);
end
