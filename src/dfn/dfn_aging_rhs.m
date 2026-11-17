function [fa, depsn, da] = dfn_aging_rhs(par, ag, sr, thsn, thsp, jin, jip, I)
%DFN_AGING_RHS  Ve phai cua cac trang thai lao hoa (mo hinh "5 coupled", buoc C).
% Goi tu dfn_rhs.m khi par.aging.on. Nhan nguon tung phuong trinh:
% tai_lieu/dac_ta_lao_hoa.md (muc 3-9) va tai_lieu/gia_dinh.md (GD-50 tro di).
%
% Ra:  fa    (vector theo thu tu chi so par.ix.ag, xem dfn_mesh.m)
%      depsn (Nn x 1) d(eps_e,n)/dt [1/s], dung trong bao toan dien giai dang
%            d(eps c_e)/dt (eps thay doi theo thoi gian)
%      da    struct chan doan (ung suat, toc do)
%
%  SEI tren be mat, moi lop (Note 2 (S3)-(S7); he so 1/4 = 0.5 x 1/(z F) x c D F/L:
%    THEO BAI GOC - Single 2018 pt. (1), z = 2; (S6)-(S7) in 1/2 la sai, doi_chieu S3):
%      dL_inner/dt = -alpha j_SEI Vbar/(z F),  dL_outer/dt = -(1 - alpha) j_SEI Vbar/(z F)
%  SEI tren vet nut, moi lop ((S20) + cung phan xu S3; so hang "lan rong" theo bai bao):
%      dL_cr,k/dt = -alpha_k j_SEIcr Vbar/(z F) - (dl_cr/dt) L_cr,k / l_cr
%  Ma lithium (S11)-(S13):  dc_Li/dt = -a_n j_Li/F - gamma c_Li ; dc_dl/dt = gamma c_Li ;
%      gamma = gamma_0 L_SEI,0 / L_SEI                                     - theo bai bao
%  Ung suat be mat (S14)-(S17) tai r = R (vi tri danh gia: theo code, bai khong ghi):
%      sigma_r(R) = 0,  sigma_t(R) = Omega E/(3(1 - nu)) (c_rav - c_surf),  sigma_h = (2/3) sigma_t
%      ((S15) voi c_avg cua (S17) cho dung bieu thuc nay tai r = R.)
%  Nut (Paris) (S18), chi cuc am:  dl_cr/dt = k_cr/t0 (sigma_t b_cr sqrt(pi l_cr))^m_cr, sigma_t > 0,
%      t0 = 3600 s (theo code; bai in "time for one cycle", khong cho gia tri - GD-53)
%  LAM (S21)-(S22), ca hai cuc:  d eps_s/dt = -beta (sigma_h/sigma_c)^m2, sigma_h > 0
%      (dau GIAM theo bai goc O'Kane 2022; beta [1/s] dung truc tiep theo code - GD-53)
%  LAM -> a = 3 eps_s/R (dfn_aging_state); nong do trong hat con lai KHONG doi -> lithium
%      trong phan vat lieu mat la LLI (theo code; so sach nLAM).
%  Do xop (S24)-(S25): d eps_n/dt = -d(L_total a_n)/dt.
%  So sach lithium (khong hoi tiep):
%      dnSEI/dt = -a_n j_SEI/F, dnSEIcr/dt = -(S - 1) a_n j_SEIcr/F       [mol/m3]
%      dnLAM_k/dt = -sum_x (d eps_s,k/dt) c_rav,k dx                      [mol/m2]
%  Trung binh hat (bat bien cua roi rac hoa the tich huu han, dfn_mesh.m):
%      dx_av/dt = -3 j_int/(R F c_max)
G = par.ix.ag; A = par.ag; F = par.F; g = par.grid;

% ---- ung suat be mat ----------------------------------------------------
crn = ag.xavn*par.neg.cmax; csn = thsn*par.neg.cmax;
crp = ag.xavp*par.pos.cmax; csp = thsp*par.pos.cmax;
sigt_n = A.kst_n*(crn - csn);           % Pa
sigt_p = A.kst_p*(crp - csp);
sigh_n = (2/3)*sigt_n;  sigh_p = (2/3)*sigt_p;

% ---- nut (cuc am) --------------------------------------------------------
lcr  = max(ag.lcr, A.Ty_min);
Kic  = max(sigt_n, 0)*A.b_cr.*sqrt(pi*lcr);
dlcr = A.k_cr/A.t0_cr*Kic.^A.m_cr;

% ---- LAM ----------------------------------------------------------------
depsn_s = -A.beta_n/A.t0_lam*(max(sigh_n, 0)/A.sigc_n).^A.m2_n;
depsp_s = -A.beta_p/A.t0_lam*(max(sigh_p, 0)/A.sigc_p).^A.m2_p;

% ---- SEI ----------------------------------------------------------------
zF = par.sei.z*F;
dLin  = -A.alpha*sr.jSEI*A.V_in/zF;
dLout = -(1 - A.alpha)*sr.jSEI*A.V_out/zF;
spread = dlcr./lcr;
dLcin  = -A.alpha*sr.jSEIcr*A.V_in/zF - spread.*ag.Lcin;
dLcout = -(1 - A.alpha)*sr.jSEIcr*A.V_out/zF - spread.*ag.Lcout;

% ---- ma lithium ---------------------------------------------------------
gam  = A.gamma0*A.Ltot0./max(ag.LSEI, A.Ty_min);
dcdl = gam.*ag.cLi;
dcLi = -ag.as_n.*sr.jLi/F - dcdl;

% ---- do xop: d(L_total a_n)/dt ------------------------------------------
dS    = 2*A.w_cr*A.rho_cr*dlcr;
dLf   = dLin + dLout + (ag.S - 1).*(dLcin + dLcout) + dS.*ag.LSEIcr;
dLta  = dLf.*ag.as_n + ag.Lfilm.*(3/par.neg.Rp).*depsn_s + (dcLi + dcdl)*A.V_Li;
depsn = -dLta;

% ---- so sach ------------------------------------------------------------
dnSEI   = -ag.as_n.*sr.jSEI/F;
dnSEIcr = -(ag.S - 1).*ag.as_n.*sr.jSEIcr/F;
dnLAMn  = -sum(depsn_s.*crn)*g.dxn;
dnLAMp  = -sum(depsp_s.*crp)*g.dxp;
dxavn = -3*jin/(par.neg.Rp*F*par.neg.cmax);
dxavp = -3*jip/(par.pos.Rp*F*par.pos.cmax);

fa = zeros(par.ix.nd, 1);   % chi dien vao chi so lao hoa (tra ve vector day du kich thuoc nd)
fa(G.Lin) = dLin; fa(G.Lout) = dLout; fa(G.Lcin) = dLcin; fa(G.Lcout) = dLcout;
fa(G.cLi) = dcLi; fa(G.cdl) = dcdl; fa(G.lcr) = dlcr;
fa(G.epsn) = depsn_s; fa(G.epsp) = depsp_s;
fa(G.xavn) = dxavn; fa(G.xavp) = dxavp;
fa(G.nSEI) = dnSEI; fa(G.nSEIcr) = dnSEIcr;
fa(G.nLAMn) = dnLAMn; fa(G.nLAMp) = dnLAMp;
fa(G.Qthr) = abs(I)/3600;

if nargout > 2
    da.sigt_n = sigt_n; da.sigt_p = sigt_p; da.dlcr = dlcr;
    da.depsn_s = depsn_s; da.depsp_s = depsp_s; da.gamma = gam;
end
end
