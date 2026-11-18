function ag = dfn_aging_state(par, y)
%DFN_AGING_STATE  Cac dai luong ma lao hoa lam thay doi, theo tung nut x.
% dfn_rhs.m chi doc cac truong:
%   ag.eps     (N x 1)   do xop dien giai eps_e(x)   -> D_eff, kappa_eff, d(eps c_e)/dt
%   ag.as_n    (Nn x 1)  dien tich be mat rieng a_n = 3 eps_s/R [1/m]
%   ag.as_p    (Np x 1)
%   ag.Rfilm_n (Nn x 1)  dien tro mang SEI rho_SEI.L_SEI [Ohm.m^2]
%   ag.Rfilm_p (Np x 1)  (= 0)
%
% par.aging.on = false (MAC DINH): hang so BOL, y khong dung (co the la []).
% par.aging.on = true: tinh tu trang thai lao hoa trong y (dfn_mesh.m):
%   a_k   = 3 eps_s,k / R_k                     Li 2025 SI Note 2, Note 9 (S9) - theo bai bao
%   S     = 1 + 2 l_cr w_cr rho_cr              Li 2025 SI Note 9 (S8)       - theo bai bao
%   L_SEI = L_inner + L_outer                   (S8)
%   R_film = rho_SEI L_SEI                      (S9) eta_SEI = rho_SEI j_tot L_SEI - theo bai bao
%   eps_n = eps_n,0 - (L_total a_n - (L_total a_n)_0),
%   L_total a_n = (L_SEI + 2 l_cr w_cr rho_cr L_SEI,cr) a_n + (c_Li + c_dl) V_Li
%                                               (S24)-(S25), tich phan theo t - theo bai bao
%   (mang ngan, cuc duong: do xop khong doi - (S26) "pore volume change can only occur in
%    the negative electrode")
g = par.grid;
if ~(isfield(par, 'aging') && par.aging.on)
    ag.eps     = [par.neg.eps_e*ones(g.Nn,1); par.sep.eps_e*ones(g.Ns,1); par.pos.eps_e*ones(g.Np,1)];
    ag.as_n    = par.neg.as0*ones(g.Nn,1);
    ag.as_p    = par.pos.as0*ones(g.Np,1);
    % Li 2025 SI Note 2 pt. (S9): eta_SEI = rho_SEI . j_tot . L_SEI, L_SEI = inner + outer
    ag.Rfilm_n = par.sei.rho*par.sei.L0*ones(g.Nn,1);
    ag.Rfilm_p = zeros(g.Np,1);
    return
end
G = par.ix.ag; A = par.ag;
ag.Lin  = y(G.Lin);  ag.Lout  = y(G.Lout);
ag.Lcin = y(G.Lcin); ag.Lcout = y(G.Lcout);
ag.cLi  = y(G.cLi);  ag.cdl   = y(G.cdl);
ag.lcr  = y(G.lcr);
ag.epsn = y(G.epsn); ag.epsp  = y(G.epsp);
ag.xavn = y(G.xavn); ag.xavp  = y(G.xavp);
if isfield(G, 'epsSi'), ag.epsSi = y(G.epsSi); end     % tang 2 (gia dinh, dfn_si_params.m)
ag.S    = 1 + 2*ag.lcr*A.w_cr*A.rho_cr;
ag.as_n = 3*ag.epsn/par.neg.Rp;
ag.as_p = 3*ag.epsp/par.pos.Rp;
ag.LSEI = ag.Lin + ag.Lout;
ag.LSEIcr = ag.Lcin + ag.Lcout;
ag.Lfilm = ag.LSEI + (ag.S - 1).*ag.LSEIcr;              % L_SEI + 2 l w rho L_SEI,cr
ag.Lta  = ag.Lfilm.*ag.as_n + (ag.cLi + ag.cdl)*A.V_Li;   % L_total . a_n
epsn_e  = par.neg.eps_e - (ag.Lta - A.Lta0);
ag.eps  = [epsn_e; par.sep.eps_e*ones(g.Ns,1); par.pos.eps_e*ones(g.Np,1)];
ag.Rfilm_n = par.sei.rho*ag.LSEI;
ag.Rfilm_p = zeros(g.Np,1);
end
