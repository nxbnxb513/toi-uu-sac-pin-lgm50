function par = dfn_params(opt)
%DFN_PARAMS  Bo tham so DFN + nhiet lumped cho cell LG M50(T) 21700, 5 Ah.
%
%   par = dfn_params()        luoi mac dinh
%   par = dfn_params(opt)     opt la struct ghi de: Nn, Ns, Np, Nrn, Nrp,
%                             E_Ds_n, V_SEI, L_SEI_extra, contact_heat, h, Rcontact,
%                             stress_diffusion
%
% BO THAM SO: baseline cua Li et al. 2025 (Nat. Commun. 16:2776) = O'Regan
% et al. 2022 (Electrochim. Acta 425:140700) + cac muc danh dau * trong
% Li 2025 Supplementary Table 6. Moi so deu ghi nguon (bai + bang/pt).
% Ky hieu nguon:
%   [Li-T6]   Li 2025 SI, Supplementary Table 6 (SI tr. 23-24)
%   [Li-T7]   Li 2025 SI, Supplementary Table 7 (SI tr. 25)
%   [Li-T3]   Li 2025 bai chinh, Table 3 (tr. 8), cot "5 coupled"
%   [Li-T8/9] Li 2025 SI, Supplementary Table 8, 9 (SI tr. 26-27)
%   [Li-Nx]   Li 2025 SI, Supplementary Note x
%   [OR-Tx]   O'Regan 2022, Table x
%   [code]    ma nguon cua Li 2025: script Zenodo 10.5281/zenodo.14995785
%             (Fun_NC.py, Get_Input_files.ipynb) va bo tham so "OKane2023"
%             ma script do goi (PyBaMM fork RuiheLi/PyBaMM, nhanh GEM-2_NC,
%             pybamm/input/parameters/lithium_ion/OKane2023.py).
% Cho nao bai in va ma nguon khac nhau, hoac bai khong ghi ro, deu duoc
% liet ke trong tai_lieu/gia_dinh.md (ma GD-xx duoi day).
%
% QUY UOC DAU: dong I > 0 la XA (discharge), I < 0 la SAC. Truc x: x = 0 tai
% current collector am, x = L tai current collector duong. Mat do dong be
% mat j [A/m^2] > 0 la phan ung anod (Li roi hat, vao dien giai).

if nargin < 1 || isempty(opt), opt = struct(); end

% ---- Hang so ------------------------------------------------------------
par.F    = 96485.33212;   % C/mol   hang so Faraday (CODATA)
par.R    = 8.314462618;   % J/mol/K hang so khi (CODATA)
par.Tref = 298.15;        % K       [Li-N11] pt. S18, S19, S26, S27

% ---- Luoi (cau hinh) ----------------------------------------------------
% Li 2025 dung [x_n, x_s, x_p, r_n, r_p] = [10, 5, 5, 100, 20] ([code],
% Get_Input_files.ipynb "Mesh list"). Mac dinh o day min hon theo x.
par.cfg.Nn  = getopt(opt, 'Nn', 20);
par.cfg.Ns  = getopt(opt, 'Ns', 10);
par.cfg.Np  = getopt(opt, 'Np', 20);
par.cfg.Nrn = getopt(opt, 'Nrn', 60);
par.cfg.Nrp = getopt(opt, 'Nrp', 20);

% ---- Cell ---------------------------------------------------------------
par.A        = 1.58 * 6.5e-2;  % m^2  dai x rong dien cuc            [Li-T6]
par.Qnom     = 5.0;            % Ah   dung luong danh dinh (1C = 5 A) [Li-N9]
par.Vmax     = 4.2;            % V    [code] Fun_NC.py V_max
par.Vmin     = 2.5;            % V    [code] Fun_NC.py V_min
par.Rcontact = getopt(opt, 'Rcontact', 11.5e-3);  % Ohm  [Li-T6] "Contact resistance"

% ---- Dien cuc am: graphite + SiOx --------------------------------------
par.neg.L      = 8.52e-5;     % m      [Li-T6]
par.neg.Rp     = 5.86e-6;     % m      [Li-T6]
par.neg.eps_s  = 0.75;        % -      [Li-T6]
par.neg.cmax   = 32544;       % mol/m3 [Li-T6]*
par.neg.sigma  = 215;         % S/m    [Li-T6]
par.neg.brug_s = 0;           % -      [Li-T6] Bruggeman (electrode)
par.neg.brug_e = 1.5;         % -      [Li-T6] Bruggeman (electrolyte)
par.neg.x0     = 0.0279;      % stoich tai 0 % SOC   [Li-N8] SI tr. 46-47
par.neg.x100   = 0.8771;      % stoich tai 100 % SOC [Li-N8]; 28543/32544 [Li-T6]*
% j0 [Li-N11] pt. S27: 2.668*exp(-4e4/R*(1/T-1/298.15))*(ce/<ce>)^0.208*x^0.792*(1-x)^0.208
par.neg.j0_ref = 2.668;       % A/m2
par.neg.j0_E   = 4e4;         % J/mol
par.neg.j0_al  = 0.792;       % so mu cua x_surf; (1-alpha) cho ce va (1-x)
% D_s [Li-N11] pt. S17-S18, he so [Li-T7]
par.neg.Ds.a   = [11.17, -1.553, -6.136, -9.725, 1.85];      % a0..a4
par.neg.Ds.b   = [-15.11, 0.2031, 0.5375, 0.9144, 0.5953];   % b0..b4
par.neg.Ds.c   = [NaN, 0.0006091, 0.06438, 0.0578, 0.001356];% c1..c4
par.neg.Ds.Rcor= 3.0321;                                     % [Li-T7]
% E_act cua D_s,n: [Li-T3] cot "5 coupled" = 2e4 J/mol (SEI only: 6e4). GD-01
par.neg.Ds.E   = getopt(opt, 'E_Ds_n', 2e4);
% co hoc hat (dung cho khuech tan do ung suat, va ung suat/nut o buoc sau)
par.neg.Omega  = 3.1e-6;      % m3/mol the tich mol rieng phan [Li-T6]
par.neg.E      = 15e9;        % Pa     modun Young             [Li-T6]
par.neg.nu     = 0.3;         % -      he so Poisson           [Li-T6]
par.neg.c_ref  = 0;           % mol/m3 nong do khong bien dang [Li-T6]

% ---- Dien cuc duong: NMC811 ---------------------------------------------
par.pos.L      = 7.56e-5;     % m      [Li-T6]
par.pos.Rp     = 5.22e-6;     % m      [Li-T6]
par.pos.eps_s  = 0.665;       % -      [Li-T6]
par.pos.eps_e  = 0.335;       % -      [Li-T6]
par.pos.cmax   = 52787;       % mol/m3 [Li-T6]*
par.pos.brug_s = 0;           % -      [Li-T6]
par.pos.brug_e = 1.5;         % -      [Li-T6]
par.pos.y0     = 0.9256;      % stoich tai 0 % SOC   [Li-N8]
par.pos.y100   = 0.2411;      % stoich tai 100 % SOC [Li-N8]; 12727/52787 [Li-T6]*
% sigma_s,p(T) [Li-N11] pt. S19
par.pos.sigma_ref = 0.8473;   % S/m
par.pos.sigma_E   = 3500;     % J/mol
% j0 [Li-N11] pt. S26
par.pos.j0_ref = 5.028;       % A/m2
par.pos.j0_E   = 2.401e4;     % J/mol
par.pos.j0_al  = 0.43;
% D_s [Li-T7] (duong: khong co a0, a4)
par.pos.Ds.a   = [0, -0.9231, -0.4066, -0.993, 0];
par.pos.Ds.b   = [-13.96, 0.3216, 0.4532, 0.8098, 0.5];
par.pos.Ds.c   = [NaN, 0.002534, 0.003926, 0.09924, 1];
par.pos.Ds.Rcor= 2.7;         % [Li-T7]
par.pos.Ds.E   = 12000;       % J/mol [Li-T7]
par.pos.Omega  = 1.25e-5;     % m3/mol [Li-T6]
par.pos.E      = 375e9;       % Pa     [Li-T6]
par.pos.nu     = 0.2;         % -      [Li-T6]
par.pos.c_ref  = 0;           % mol/m3 [Li-T6]

% ---- Khuech tan do ung suat trong hat (stress-induced diffusion) --------
% Ma nguon cua Li 2025 BAT so hang nay o ca hai cuc trong ca ba mo hinh
% (mac dinh cua PyBaMM khi "particle mechanics" khac "none"; [code]
% base_particle.py::_get_effective_diffusivity, Ai 2019 pt. 12):
%   D_eff = D_s(x,T) (1 + theta_M (c - c_ref)),  theta_M = Omega/(R T) . 2 Omega E/(9 (1 - nu))
% Bai bao va SI khong nhac toi so hang nay. GD-10
par.stress_diffusion = getopt(opt, 'stress_diffusion', true);

% ---- Mang ngan ----------------------------------------------------------
par.sep.L      = 1.2e-5;      % m  [Li-T6]
par.sep.eps_e  = 0.47;        % -  [Li-T6]
par.sep.brug_e = 1.5;         % -  [Li-T6]

% ---- Dien giai (EC:EMC 3:7, LiPF6) -------------------------------------
par.ce0    = 1000;            % mol/m3 nong do ban dau [Li-T6]
par.ce_ref = 1000;            % mol/m3 <c_e> trong pt. S26/S27 = "Typical
                              % electrolyte concentration" 1000 [code]. GD-06
% D_e, kappa, t+, TDF: xem dfn_elyte.m ([Li-N10] pt. S12-S16)

% ---- Hysteresis OCP "current sigmoid" [Li-N7] pt. S46-S47 ---------------
par.hys.k      = 100;         % m2/A
par.hys.offset = 0.2;         % A/m2

% ---- Trang thai dau doi (BOL) lien quan toi lao hoa ---------------------
% Lop SEI ban dau va do xop cuc am: [Li-N9] pt. S7-S11.
par.sei.Qloss0 = 5 - 4.86491; % Ah   [Li-N9] "5 - 4.865 = 0.135 Ah"; [code] Fun_NC.py dung 4.86491
par.sei.z      = 2;           % -    [Li-T8] z_SEI
par.sei.rho    = 2e5;         % Ohm.m [Li-T8] SEI resistivity
% V_SEI: [Li-T3] cot "5 coupled" = 5.22e-5 m3/mol. GD-02
par.sei.V      = getopt(opt, 'V_SEI', 5.22e-5);
par.crk.l0     = 2e-8;        % m    [Li-T9] initial crack length
par.crk.w0     = 1.5e-8;      % m    [Li-T9] initial crack width
par.crk.rho    = 3.18e15;     % 1/m2 [Li-T9] number of cracks per unit area
par.neg.as0    = 3*par.neg.eps_s/par.neg.Rp;       % 1/m [Li-N9] pt. S9
par.pos.as0    = 3*par.pos.eps_s/par.pos.Rp;       % 1/m
Sr   = 2*par.crk.l0*par.crk.w0*par.crk.rho + 1;    % [Li-N9] pt. S8
Vn   = par.A*par.neg.L;                            % m3 the tich cuc am
% pt. S7: do day moi lop (inner = outer) suy tu luong mat dung luong ban dau
L_S7 = 1800*par.sei.Qloss0/(par.F*par.sei.z) * par.sei.V/(Sr*par.neg.as0*Vn);
% [code] Fun_NC.py::Overwrite_Initial_L_SEI_0_Neg_Porosity cong them 2.5 nm cho
% moi lop (khong co trong SI); do xop thi KHONG tinh phan 2.5 nm nay. GD-02
par.sei.L_extra  = getopt(opt, 'L_SEI_extra', 2.5e-9);
par.sei.L_layer0 = L_S7 + par.sei.L_extra;         % m, moi lop
par.sei.L0       = 2*par.sei.L_layer0;             % m, inner + outer (Note 2 pt. S8)
par.sei.Sr       = Sr;
deps             = 2*L_S7*Sr*par.neg.as0;          % pt. S10
par.neg.eps_e    = 0.25 - deps;                    % pt. S11

% ---- Nhiet (lumped 0D) --------------------------------------------------
par.th.h       = getopt(opt, 'h', 20);  % W/m2/K [Li-T6] total heat transfer coeff.
par.th.Acool   = 5.31e-3;     % m2  [Li-T6] cell cooling surface area
par.th.Vcell   = 2.42e-5;     % m3  [Li-T6] cell volume
par.th.Lcc_n   = 1.2e-5;      % m   [Li-T6]
par.th.Lcc_p   = 1.6e-5;      % m   [Li-T6]
par.th.scc_n   = 5.8411e7;    % S/m [Li-T6]
par.th.scc_p   = 3.6914e7;    % S/m [Li-T6]
par.th.rhocc_n = 8960;        % kg/m3 [Li-T6]
par.th.rhocc_p = 2700;        % kg/m3 [Li-T6]
par.th.cpcc_n  = 385;         % J/kg/K [Li-T6]
par.th.cpcc_p  = 897;         % J/kg/K [Li-T6]
par.th.rho_wet = [2060, 1548, 3700];  % kg/m3 am, mang ngan, duong [Li-T6] "Density (wet)"
% Mat do xop kho: duong 3270, am 1740, mang ngan 946 kg/m3 [OR-T7], [OR-T5].
% (Li-T6 in cot am/mang ngan dao cho nhau: GD-07.)
par.th.rho_dry = [1740, 946, 3270];   % kg/m3 am, mang ngan, duong
par.th.rho_l   = 1280;        % kg/m3 mat do dien giai [OR-T5]
par.th.cp_l    = 229;         % J/kg/K [Li-T6] "Heat capacity of electrolyte"
% C_p,s(T) = p1 T^3 + p2 T^2 + p3 T + p4 [Li-N11] pt. S21-S23 (T [K])
par.th.cp_poly = [ 4.932e-4, -0.491,   169.4, -1.897e4;    % am       (S22)
                   1.494e-3, -1.444,   475.5, -5.13e4;     % mang ngan (S23)
                  -8.414e-4,  0.7892, -241.3,  2.508e4];   % duong    (S21)
% Nhiet do I^2.R_contact co dua vao can bang nhiet hay khong. GD-05
par.th.contact_heat = getopt(opt, 'contact_heat', false);
par.th.Ltot  = par.th.Lcc_n + par.neg.L + par.sep.L + par.pos.L + par.th.Lcc_p;
par.th.hA_V  = par.th.h*par.th.Acool/par.th.Vcell;       % W/m3/K

% ---- Dai luong dan xuat -------------------------------------------------
% Dung luong moi dien cuc tren mot don vi stoich [Ah]
par.neg.Qcap = par.neg.cmax*par.neg.eps_s*par.neg.L*par.A*par.F/3600;
par.pos.Qcap = par.pos.cmax*par.pos.eps_s*par.pos.L*par.A*par.F/3600;

par = dfn_mesh(par);
end

function v = getopt(opt, name, default)
if isfield(opt, name) && ~isempty(opt.(name)), v = opt.(name); else, v = default; end
end
