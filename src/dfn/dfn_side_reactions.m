function sr = dfn_side_reactions(par, ag, loc) %#ok<INUSD>
%DFN_SIDE_REACTIONS  [HOOK lao hoa] Mat do dong cua phan ung phu tai tung nut.
% Buoc 1: chua co phan ung phu -> tat ca bang 0.
%
% dfn_rhs.m dung:   j_tot = j_int + j_side   (A/m^2, tren be mat hat)
%   - j_tot vao bao toan dien tich (pha ran, dien giai) va nguon Li+ dien giai
%   - j_int = j_tot - j_side vao dieu kien bien khuech tan trong hat
% loc chua cac truong cuc bo tai nut cuc am / duong:
%   loc.dphi_n = phi_s - phi_e (Nn x 1) [V]; loc.eta_film_n = j_tot.R_film [V]
%   loc.ce_n [mol/m^3]; loc.T [K]; loc.jn (j_tot) ; tuong tu cho _p
% Buoc sau dien vao (Li 2025 SI Note 2-5): j_SEI (S2), j_Li (S10), SEI tren
% vet nut (S20); va tra them dao ham cua cac trang thai lao hoa.
g = par.grid;
sr.jn = zeros(g.Nn,1);   % tong mat do dong phan ung phu cuc am [A/m^2]
sr.jp = zeros(g.Np,1);   % cuc duong
sr.q  = zeros(g.N,1);    % nhiet cua phan ung phu tren don vi dien tich [W/m^2]
end
