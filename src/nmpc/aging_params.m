function ap = aging_params(par)
%AGING_PARAMS  Tham so cua toc do lao hoa TAM THOI (SEI + ma lithium) dung cho
% ham muc tieu NMPC va de cham diem hau kiem tren quy dao DFN.
%
% TAM THOI: lao hoa CHUA nam trong DFN (buoc C chua lam). O day chi tinh
% TOC DO phan ung phu tu the dien cuc cua DFN/ROM, KHONG hoi tiep vao dong
% dien, do xop hay dien tro mang. Do day SEI, do nham be mat (vet nut) lay
% gia tri dau doi (BOL) va giu khong doi trong mot lan sac: trong mot lan sac
% L_SEI tang ~1e-12 m so voi 9.2e-9 m (xem tai_lieu/mo_hinh_rut_gon.md muc 6).
%
% Nguon (ky hieu nhu src/dfn/dfn_params.m; dang luat: tai_lieu/dac_ta_lao_hoa.md
% muc 3, 4, 6.2; phan xu bai goc: tai_lieu/gia_dinh.md muc 1):
ap.D_int   = 9.81e-19;        % m2/s  [Li-T3] cot "5 coupled" (inner SEI Li interstitial diffusivity)
ap.c_int   = 15;              % mol/m3 [Li-T8] Li interstitial reference concentration
ap.E_SEI   = 5e3;             % J/mol [Li-T3] cot "5 coupled"
ap.k_Li    = 1e-10;           % m/s   [Li-T3] cot "5 coupled" (plating kinetic rate constant)
ap.gamma0  = 1e-7;            % 1/s   [Li-T3] cot "5 coupled" (dead lithium decay constant)
ap.alpha_a = par.lp.alpha_a;  % 0.35 hoa tan, O'Kane 2022 (gia_dinh.md muc 1)
ap.alpha_c = par.lp.alpha_c;  % 0.65 ma, O'Kane 2022
ap.V_SEI   = par.sei.V;       % m3/mol [Li-T3] (chi de doi ra do day, khong dung trong toc do Li)
ap.z_SEI   = par.sei.z;       % 2 [Li-T8]
ap.L_outer0 = par.sei.L_layer0;   % m, BOL moi lop (GD-02, cach cua ma nguon)
ap.S0      = par.sei.Sr;      % - do nham be mat BOL [Li-N9] pt. S8 (SEI tren vet nut nhan (S0 - 1))
ap.as_n    = par.neg.as0;     % 1/m  a_n = 3 eps_s/R [Li-N9] pt. S9
ap.Rfilm   = par.sei.rho*par.sei.L0;  % Ohm.m2 [Li-N2] pt. S9: eta_SEI = rho_SEI L_SEI j_tot (nhu DFN)
end
