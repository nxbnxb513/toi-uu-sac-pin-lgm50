function [f, aux] = dfn_rhs(t, y, par, ctl)
%DFN_RHS  Ve phai cua he DAE chi so 1:  M y' = f(t, y)  (mo hinh DFN + nhiet lumped).
%
% Phuong trinh (Li 2025 SI Supplementary Table 2, 3; O'Kane 2022 Table S1):
%  (1) Khuech tan trong hat tai moi nut x, D_s(x,T) phi tuyen:
%        dc/dt = 1/r^2 d/dr( r^2 D_s dc/dr ),  -D_s dc/dr|_R = j_int/F
%  (2) Bao toan dien tich pha ran:  d/dx( sigma_eff dphi_s/dx ) = a j_tot
%  (3) Bao toan khoi luong dien giai:
%        eps dce/dt = -d/dx( -eps^b D_e dce/dx + t+ i_e/F ) + a j_tot/F
%  (4) Bao toan dien tich dien giai:
%        i_e = -eps^b kappa ( dphi_e/dx - 2 (1 - t+) TDF (RT/F) dln(ce)/dx ),  di_e/dx = a j_tot
%  (5) Butler-Volmer: j_int = 2 j0 sinh( F eta/(2RT) ),
%        eta = phi_s - phi_e - U(x_surf, T, I) - j_tot R_film
%  (6) Ap dau cuc: V = phi_s,p(L) - phi_s,n(0) - I R_contact
%  (7) Nhiet lumped:  rho c_p,eff dT/dt = Q_tb - (h A_cool/V_cell)(T - T_amb)
%        Q_tb = [ tich phan theo x cua (q_ohm + q_rxn + q_rev) + nhiet current collector ] / L_tot
% Quy uoc dau: I > 0 la xa; j > 0 la anod (Li roi hat).
%
% ctl.mode : 'I' (dong cho truoc, ctl.value la so hoac ham @(t)),
%            'V' (giu ap, ctl.value [V]; dong la an dai so)
% ctl.Tamb : nhiet do moi truong [K]

g = par.grid; ix = par.ix;
F = par.F; Rg = par.R;
Nn = g.Nn; Ns = g.Ns; Np = g.Np; N = g.N;

thn   = reshape(y(ix.thn), g.Nrn, Nn);
thp   = reshape(y(ix.thp), g.Nrp, Np);
ce    = y(ix.ce)*par.ce_ref;            % mol/m^3
T     = y(ix.T);
phisn = y(ix.phisn); phisp = y(ix.phisp); phie = y(ix.phie);
jn    = y(ix.jn);    jp    = y(ix.jp);
H     = y(ix.H);     I     = y(ix.I);
iapp  = I/par.A;                        % A/m^2
RTF   = Rg*T/F;
cep   = max(ce, 1e-2);                  % chan duoi de log/sqrt xac dinh

% ---- [HOOK] trang thai lao hoa theo nut --------------------------------
ag = dfn_aging_state(par, y);

% ---- stoichiometry be mat (ngoai suy tuyen tinh tu hai vo ngoai cung) ---
thsn = (1.5*thn(end,:) - 0.5*thn(end-1,:)).';
thsp = (1.5*thp(end,:) - 0.5*thp(end-1,:)).';
xsn  = min(max(thsn, 1e-8), 1 - 1e-8);
xsp  = min(max(thsp, 1e-8), 1 - 1e-8);

% ---- OCP voi hysteresis "current sigmoid" (Li 2025 SI Note 7, S46-S47) --
m = 0.5*(1 + tanh(par.hys.k*(iapp + par.hys.offset)));   % 1: xa/nghi, 0: sac
[Unl, Und, dUn] = dfn_ocp_neg(xsn);
[Upl, Upd, dUp] = dfn_ocp_pos(xsp);
Un = (1 - m)*Unl + m*Und + (T - par.Tref)*dUn;
Up = m*Upl + (1 - m)*Upd + (T - par.Tref)*dUp;

% ---- dong hoc ----------------------------------------------------------
cen = cep(g.in); cepos = cep(g.ip);
phien = phie(g.in); phiep = phie(g.ip);
j0n = dfn_j0(par.neg, cen, xsn, T, par);
j0p = dfn_j0(par.pos, cepos, xsp, T, par);

% ---- [HOOK] phan ung phu: j_tot = j_int + j_side ------------------------
loc.T = T; loc.jn = jn; loc.jp = jp; loc.ce_n = cen; loc.ce_p = cepos;
loc.dphi_n = phisn - phien; loc.dphi_p = phisp - phiep;
loc.eta_film_n = jn.*ag.Rfilm_n; loc.eta_film_p = jp.*ag.Rfilm_p;
sr  = dfn_side_reactions(par, ag, loc);
jin = jn - sr.jn;                        % mat do dong dan xen (intercalation)
jip = jp - sr.jp;

eta_n = phisn - phien - Un - jn.*ag.Rfilm_n;
eta_p = phisp - phiep - Up - jp.*ag.Rfilm_p;
% Butler-Volmer viet o dang nghich dao (cung nghiem, on dinh so hon):
res_jn = eta_n - 2*RTF*asinh(jin./(2*j0n));
res_jp = eta_p - 2*RTF*asinh(jip./(2*j0p));

% ---- (1) khuech tan trong hat ------------------------------------------
% thong luong D dx/dr tai mat vo = (K(x_{i+1}) - K(x_i))/dr (bien doi Kirchhoff, dfn_Ktable.m)
Kn   = dfn_Kint(par.neg, thn, T, par);
fln  = [zeros(1,Nn); diff(Kn,1,1)/g.drn; -(jin.')/(F*par.neg.cmax)];
dthn = (g.r2fn(2:end).*fln(2:end,:) - g.r2fn(1:end-1).*fln(1:end-1,:))./g.Vshn;
Kp   = dfn_Kint(par.pos, thp, T, par);
flp  = [zeros(1,Np); diff(Kp,1,1)/g.drp; -(jip.')/(F*par.pos.cmax)];
dthp = (g.r2fp(2:end).*flp(2:end,:) - g.r2fp(1:end-1).*flp(1:end-1,:))./g.Vshp;

% ---- (3),(4) dien giai --------------------------------------------------
epe  = ag.eps;
brug = [par.neg.brug_e*ones(Nn,1); par.sep.brug_e*ones(Ns,1); par.pos.brug_e*ones(Np,1)];
[De, kap] = dfn_elyte(cep, T);
Deff = De.*epe.^brug;  keff = kap.*epe.^brug;
wL = g.dx(1:N-1); wR = g.dx(2:N); dxc = 0.5*(wL + wR);
Df = (wL + wR)./(wL./Deff(1:N-1) + wR./Deff(2:N));     % trung binh dieu hoa tai mat
kf = (wL + wR)./(wL./keff(1:N-1) + wR./keff(2:N));
cf = (cep(1:N-1).*wR + cep(2:N).*wL)./(wL + wR);
[~, ~, tpf, tdff] = dfn_elyte(cf, T);
dphie = diff(phie);
ie = -kf.*(dphie - 2*(1 - tpf).*tdff.*RTF.*diff(log(cep)))./dxc;   % A/m^2 tai mat trong
Nf = -Df.*diff(ce)./dxc + tpf.*ie/F;                               % mol/m^2/s
aj = [ag.as_n.*jn; zeros(Ns,1); ag.as_p.*jp];                      % A/m^3 (tong)
dce = (-([Nf; 0] - [0; Nf])./g.dx + aj/F)./epe;
res_phie = ([ie; 0] - [0; ie]) - aj.*g.dx;

% ---- (2) pha ran --------------------------------------------------------
sn = par.neg.sigma*par.neg.eps_s^par.neg.brug_s;
sp = par.pos.sigma_ref*exp(-par.pos.sigma_E/Rg*(1/T - 1/par.Tref))*par.pos.eps_s^par.pos.brug_s;
isn = [-sn*phisn(1)/(g.dxn/2); -sn*diff(phisn)/g.dxn; 0];   % phi_s = 0 tai x = 0
isp = [0; -sp*diff(phisp)/g.dxp; iapp];
res_phisn = (isn(2:end) - isn(1:end-1)) + ag.as_n.*jn*g.dxn;
res_phisp = (isp(2:end) - isp(1:end-1)) + ag.as_p.*jp*g.dxp;
V = phisp(end) - iapp*(g.dxp/2)/sp - I*par.Rcontact;

% ---- (7) nhiet: q(k) [W/m^2 dien cuc] cua tung o ------------------------
q_ohm_s = zeros(N,1);
q_ohm_s(g.in) = [isn(2:Nn).^2; 0]/sn*g.dxn;
q_ohm_s(1)    = q_ohm_s(1) + isn(1)^2/sn*(g.dxn/2);
q_ohm_s(g.ip) = [isp(2:Np).^2; 0]/sp*g.dxp;
q_ohm_s(N)    = q_ohm_s(N) + iapp^2/sp*(g.dxp/2);
q_ohm_e = [-ie.*dphie; 0];                                   % -i_e dphi_e/dx
q_rxn = zeros(N,1); q_rev = zeros(N,1);
q_rxn(g.in) = ag.as_n.*jin.*(phisn - phien - Un)*g.dxn;      % SI Table 3: j (phi_s - phi_e - U)
q_rxn(g.ip) = ag.as_p.*jip.*(phisp - phiep - Up)*g.dxp;
q_rev(g.in) = ag.as_n.*jin.*T.*dUn*g.dxn;                    % SI Table 3: j T dU/dT
q_rev(g.ip) = ag.as_p.*jip.*T.*dUp*g.dxp;
q_cc = iapp^2*(par.th.Lcc_n/par.th.scc_n + par.th.Lcc_p/par.th.scc_p);
q_ct = 0;
if par.th.contact_heat, q_ct = I^2*par.Rcontact/par.A; end
q = q_ohm_s + q_ohm_e + q_rxn + q_rev + sr.q;
q(1) = q(1) + q_cc + q_ct;
res_H = H - [0; H(1:end-1)] - q;
rhocp = dfn_rhocp(par, T, ag);
dT = (H(N)/par.th.Ltot - par.th.hA_V*(T - ctl.Tamb))/rhocp;

% ---- phuong trinh dieu khien -------------------------------------------
switch ctl.mode
    case 'I'
        if isa(ctl.value, 'function_handle'), Iset = ctl.value(t); else, Iset = ctl.value; end
        res_I = I - Iset;
    case 'V'
        res_I = V - ctl.value;
    otherwise
        error('dfn_rhs: mode khong hop le: %s', ctl.mode);
end

f = zeros(ix.ny,1);
f(ix.thn) = dthn(:);
f(ix.thp) = dthp(:);
f(ix.ce)  = dce/par.ce_ref;
f(ix.T)   = dT;
f(ix.Q)   = I/3600;
f(ix.phisn) = res_phisn;
f(ix.phisp) = res_phisp;
f(ix.phie)  = res_phie;
f(ix.jn)  = res_jn;
f(ix.jp)  = res_jp;
f(ix.H)   = res_H;
f(ix.I)   = res_I;

if nargout > 1
    aux.V = V; aux.I = I; aux.T = T; aux.Q = y(ix.Q);
    aux.thsn = thsn; aux.thsp = thsp;
    aux.xn_avg = mean((g.Vshn.'*thn)/sum(g.Vshn));   % stoich trung binh cuc am
    aux.yp_avg = mean((g.Vshp.'*thp)/sum(g.Vshp));
    aux.ce_min = min(ce); aux.ce_max = max(ce);
    aux.dphi_n = phisn - phien;                      % phi_s - phi_e tai cuc am [V]
    aux.eta_pl_min = min(phisn - phien - jn.*ag.Rfilm_n);   % the ma Li nho nhat [V]
    aux.q_area = H(N);                               % W/m^2 dien cuc
    aux.Qgen = H(N)/par.th.Ltot*par.th.Vcell;        % W, cong suat nhiet vao can bang lumped
    aux.q_parts = [sum(q_ohm_s), sum(q_ohm_e), sum(q_rxn), sum(q_rev), q_cc + q_ct]*par.A;  % W (theo dien tich dien cuc)
    aux.Un = Un; aux.Up = Up; aux.jn = jn; aux.jp = jp;
end
end
