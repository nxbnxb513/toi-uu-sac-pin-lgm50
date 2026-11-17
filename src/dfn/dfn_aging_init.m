function y = dfn_aging_init(par, y)
%DFN_AGING_INIT  Dat trang thai lao hoa dau doi (BOL) trong y (khi par.aging.on).
%   y = dfn_aging_init(par, y)  y co kich thuoc par.ix.ny; cac trang thai DFN giu nguyen.
% Gia tri BOL ("5 coupled"):
%   L_inner = L_outer = L_inner,cr = L_outer,cr = L_SEI,0 moi lop (Li 2025 SI (S7) - dang
%       theo bai bao; gia tri theo code: tinh lai voi V_SEI fit + 2.5 nm, GD-02)
%   c_Li = c_dl = 0 ([Li-T8]); l_cr = 2e-8 m ([Li-T9]); eps_s,n = 0.75, eps_s,p = 0.665 ([Li-T6])
%   so sach = 0; x_av = trung binh the tich cua theta trong tung hat (bat bien).
% Mot vector khong lao hoa (kich thuoc khac) duoc mo rong bang dfn_aging_extend.m.
if ~(isfield(par, 'aging') && par.aging.on), return; end
G = par.ix.ag; A = par.ag;
y(G.Lin) = A.L0; y(G.Lout) = A.L0; y(G.Lcin) = A.L0; y(G.Lcout) = A.L0;
y(G.cLi) = 0; y(G.cdl) = 0; y(G.lcr) = A.l_cr0;
y(G.epsn) = A.epsn0; y(G.epsp) = A.epsp0;
y(G.nSEI) = 0; y(G.nSEIcr) = 0; y(G.nLAMn) = 0; y(G.nLAMp) = 0; y(G.Qthr) = 0;
y = dfn_aging_sync_xav(par, y);
end
