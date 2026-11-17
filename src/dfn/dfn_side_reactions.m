function sr = dfn_side_reactions(par, ag, loc)
%DFN_SIDE_REACTIONS  Mat do dong cua phan ung phu tai tung nut.
%
% dfn_rhs.m dung:   j_tot = j_int + j_side   (A/m^2, tren be mat hat)
%   - j_tot vao bao toan dien tich (pha ran, dien giai) va nguon Li+ dien giai
%   - j_int = j_tot - j_side vao dieu kien bien khuech tan trong hat
% loc: loc.dphi_n = phi_s - phi_e (Nn x 1) [V]; loc.eta_film_n = j_tot.R_film [V];
%      loc.ce_n [mol/m^3]; loc.T [K]; loc.jn (j_tot); tuong tu cho _p
%
% par.aging.on = false (MAC DINH): khong co phan ung phu (tat ca bang 0).
% par.aging.on = true (mo hinh "5 coupled", dac_ta_lao_hoa.md muc 3, 4, 6):
%  SEI (Li 2025 SI Note 2) - quy uoc dau o day: j < 0 la phan ung khu
%    j_SEI   = -(c_int D_int F / L_inner) exp(-F (phi_s - phi_e)/(R T)) Arr      (S2), (S5)
%    j_SEIcr = -(c_int D_int F / L_inner,cr) exp(-F (phi_s - phi_e)/(R T)) Arr  (S20)
%    Arr = exp(E_SEI/(R T_ref) - E_SEI/(R T))                                    (S5)
%    so mu co F/(RT) (THEO BAI GOC Single 2018 pt. (5), von Kolzenberg 2020 pt. (18), (25):
%    bai in thieu F/(RT)); phi_s - phi_e KHONG tru eta_SEI (theo bai bao (S2)).
%    Dong SEI tren vet nut vao j_tot voi dien tich (S - 1) a_n (theo code; bai khong in
%    cach ghep, nhung dung (S8), (S25), (S27) cua bai).
%  Ma lithium (Li 2025 SI Note 3, "unchanged from O'Kane et al.") - theo bai bao (S10):
%    j_Li = F k_Li [ c_Li exp(alpha_a F eta/(RT)) - c_e exp(-alpha_c F eta/(RT)) ],
%    eta = phi_s - phi_e - eta_SEI,  alpha_a = 0.35 (hoa tan), alpha_c = 0.65 (ma):
%    THEO BAI GOC O'Kane 2022 (Li 2025 Table 8 ghi nham nhan alpha_a = 0.65).
%  j_side = j_SEI + (S - 1) j_SEIcr + j_Li.   Cuc duong: khong co phan ung phu.
%  Phan ung phu khong sinh nhiet (Li 2025 SI Table 3 chi co phan ung chinh) -> sr.q = 0.
g = par.grid;
sr.jn = zeros(g.Nn,1);   % tong mat do dong phan ung phu cuc am [A/m^2]
sr.jp = zeros(g.Np,1);   % cuc duong
sr.q  = zeros(g.N,1);    % nhiet cua phan ung phu tren don vi dien tich [W/m^2]
if ~(isfield(par, 'aging') && par.aging.on), return; end
A = par.ag; F = par.F;
T = loc.T;
f = F/(par.R*T);
arr = exp(A.E_SEI/par.R*(1/par.Tref - 1/T));
ex  = exp(min(-f*loc.dphi_n, 60));                         % chan tren chi de an toan so hoc
kS  = A.c_int*A.D_int*F*arr;
sr.jSEI   = -kS*ex./max(ag.Lin, A.Ty_min);
sr.jSEIcr = -kS*ex./max(ag.Lcin, A.Ty_min);
eta = loc.dphi_n - loc.eta_film_n;                         % phi_s - phi_e - eta_SEI
sr.etapl = eta;
sr.jLi = F*A.k_Li*(ag.cLi.*exp(min(A.alpha_a*f*eta, 60)) - loc.ce_n.*exp(min(-A.alpha_c*f*eta, 60)));
sr.jn = sr.jSEI + (ag.S - 1).*sr.jSEIcr + sr.jLi;
end
