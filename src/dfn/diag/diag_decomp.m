function r = diag_decomp(par, y, ctl)
%DIAG_DECOMP  (CHAN DOAN) Tach ap dau cuc V cua mo hinh DFN thanh cac thanh phan.
% Dung chinh cac cong thuc cua dfn_rhs.m; tai moi nut dien cuc:
%   phi_s - phi_e = U(x_surf, T, nhanh) + eta + j R_film
% nen, lay trung binh theo nut (luoi deu trong moi dien cuc), V dung CHINH XAC:
%   V = [U_p(ybar) - U_n(xbar)]                (OCV "khoi" theo nhanh dang dung)
%     + [<U_p(y_s)> - U_p(ybar)] - [<U_n(x_s)> - U_n(xbar)]   (phan cuc nong do pha ran)
%     + <eta_p> - <eta_n>                       (qua the dong hoc)
%     + <jR_f>_p - <jR_f>_n                      (sut ap mang SEI)
%     + (<phi_e>_p - <phi_e>_n) = e_ohm + e_diff (dien giai: phan ohm + phan nong do)
%     + s_ohm                                    (sut ap pha ran = V + I Rc - (<phi_s,p> - <phi_s,n>))
%     - I Rc                                     (dien tro tiep xuc, GD-20)
% Them: hys = [U_p - U_n](nhanh dang dung) - [U_p - U_n](nhanh xa: duong lith, am delith)
% tai ybar/xbar, tuc phan tre (hysteresis) dang cong vao V.
% Quy uoc: I > 0 xa. Tat ca [V].
g = par.grid; ix = par.ix; F = par.F;
[~, a] = dfn_rhs(0, y, par, ctl);
thn = reshape(y(ix.thn), g.Nrn, g.Nn); thp = reshape(y(ix.thp), g.Nrp, g.Np);
ce = y(ix.ce)*par.ce_ref; cep = max(ce, 1e-2); T = y(ix.T);
phisn = y(ix.phisn); phisp = y(ix.phisp); phie = y(ix.phie);
jn = y(ix.jn); jp = y(ix.jp); I = y(ix.I); iapp = I/par.A;
RTF = par.R*T/F;
ag = dfn_aging_state(par, y);
m = 0.5*(1 + tanh(par.hys.k*(iapp + par.hys.offset)));
if par.hys.n_delith, mn = 1; else, mn = m; end   % cuc am: GD-40 (nhu dfn_rhs)
xbn = (g.Vshn.'*thn)/sum(g.Vshn); ybp = (g.Vshp.'*thp)/sum(g.Vshp);   % 1 x N
xbar = mean(xbn); ybar = mean(ybp);
[Unl, Und, dUn] = dfn_ocp_neg(xbar); [Upl, Upd, dUp] = dfn_ocp_pos(ybar);
dUn = dUn*par.dUdT_scale/1e-3; dUp = dUp*par.dUdT_scale/1e-3;
Un_b = (1 - mn)*Unl + mn*Und + (T - par.Tref)*dUn;
Up_b = m*Upl + (1 - m)*Upd + (T - par.Tref)*dUp;
Un_bdis = Und + (T - par.Tref)*dUn; Up_bdis = Upl + (T - par.Tref)*dUp;
Un_bchg = Unl + (T - par.Tref)*dUn; Up_bchg = Upd + (T - par.Tref)*dUp;
r.I = I; r.V = a.V; r.T = T; r.Q = y(ix.Q); r.m = m;
r.xbar = xbar; r.ybar = ybar;
r.xs_n_mean = mean(a.thsn); r.xs_n_max = max(a.thsn); r.ys_p_mean = mean(a.thsp); r.ys_p_min = min(a.thsp);
r.ocv_bulk = Up_b - Un_b;                     % OCV khoi theo nhanh dang dung
r.ocv_bulk_dis = Up_bdis - Un_bdis;           % OCV khoi nhanh xa (nghi)
r.ocv_bulk_chg = Up_bchg - Un_bchg;           % OCV khoi nhanh sac
r.hys = r.ocv_bulk - r.ocv_bulk_dis;
r.hys_p = Up_b - Up_bdis; r.hys_n = -(Un_b - Un_bdis);   % phan cua tung cuc (cong vao V)
r.Up_bulk = Up_b; r.Un_bulk = Un_b;
r.sd_p = mean(a.Up) - Up_b;                   % phan cuc nong do pha ran cuc duong (cong vao V)
r.sd_n = -(mean(a.Un) - Un_b);                % cuc am (cong vao V)
eta_n = phisn - phie(g.in) - a.Un - jn.*ag.Rfilm_n;
eta_p = phisp - phie(g.ip) - a.Up - jp.*ag.Rfilm_p;
r.eta_p = mean(eta_p); r.eta_n = -mean(eta_n);  % cong vao V
r.film = mean(jp.*ag.Rfilm_p) - mean(jn.*ag.Rfilm_n);
% dien giai: tach dphi_e tai mat thanh phan khuech tan (thermodynamic) va phan ohm
N = g.N;
brug = [par.neg.brug_e*ones(g.Nn,1); par.sep.brug_e*ones(g.Ns,1); par.pos.brug_e*ones(g.Np,1)];
wL = g.dx(1:N-1); wR = g.dx(2:N);
cf = (cep(1:N-1).*wR + cep(2:N).*wL)./(wL + wR);
[~, ~, tpf, tdff] = dfn_elyte(cf, T, par);
dphie = diff(phie);
dd = 2*(1 - tpf).*tdff.*RTF.*diff(log(cep));
cumd = [0; cumsum(dd)]; cumo = [0; cumsum(dphie - dd)];
r.e_diff = mean(cumd(g.ip)) - mean(cumd(g.in));
r.e_ohm  = mean(cumo(g.ip)) - mean(cumo(g.in));
r.IRc = -I*par.Rcontact;
r.s_ohm = (a.V + I*par.Rcontact) - (mean(phisp) - mean(phisn));
r.resid = a.V - (r.ocv_bulk + r.sd_p + r.sd_n + r.eta_p + r.eta_n + r.film + r.e_diff + r.e_ohm + r.s_ohm + r.IRc);
r.ce_min = min(ce); r.ce_max = max(ce);
r.jsep_rel = jn(end)/mean(jn);
% j0 trung binh (A/m2) tai nut
r.j0n_mean = mean(dfn_j0(par.neg, cep(g.in), min(max(a.thsn,1e-8),1-1e-8), T, par));
r.j0p_mean = mean(dfn_j0(par.pos, cep(g.ip), min(max(a.thsp,1e-8),1-1e-8), T, par));
end
