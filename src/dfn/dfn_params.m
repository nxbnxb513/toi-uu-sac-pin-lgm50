function par = dfn_params(opt)
%DFN_PARAMS  Bo tham so DFN + nhiet lumped cho cell LG M50(T) 21700, 5 Ah.
%
%   par = dfn_params()        luoi mac dinh
%   par = dfn_params(opt)     opt la struct ghi de: Nn, Ns, Np, Nrn, Nrp,
%                             src ('approved'|'paper'|'code'), E_Ds_n, V_SEI, contact_heat, h,
%                             Rcontact, stress_diffusion, sei_init ('code'|'paper'), use_tdf,
%                             dUdT_scale, L_SEI_layer0, ocp_n_branch ('delith'|'hyst'), V_cv
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
%   [OR-SI]   O'Regan 2022 Supplementary (Table S2-S7)
%   [LG]      Landesfeind & Gasteiger, J. Electrochem. Soc. 166 (2019) A3079,
%             Table II (EC:EMC 3:7), eq. [2]
%   [OK-S1]   O'Kane et al. 2022, Table S1
%   [vK]      von Kolzenberg et al., ChemSusChem 13 (2020) 3901, eq. (9), (18), (25)
%   [S18]     Single et al., ChemSusChem 11 (2018) 1950, eq. (1), (5)
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

% ---- NGUON khi bai bao, bai goc va ma nguon khac nhau --------------------
% QUY TAC (yeu cau cua nguoi dung): cai gi BAI BAO in thi lam dung nhu in; cho
% bai in sai ro rang thi BAI GOC ma no trich dan phan xu (tai_lieu/doi_chieu_tham_so.md);
% ma nguon cua tac gia chi dung cho nhung thu khong bai nao ghi.
%   src = 'approved' (MAC DINH) bo da duyet: bai in + bai goc cho cho in sai
%                     + ma nguon cho cho khong bai nao ghi (xem tung muc duoi day)
%   src = 'paper'     de so sanh: dung nhu Li 2025 in, ke ca cho in sai
%                     (0.8353, -0.612; L_SEI,0 = 1.23625e-8 m; mat do kho nhu SI Table 6)
%   src = 'code'      de so sanh: gia tri cua ma nguon tac gia o cac muc tren
% Cac cho ba bo khac nhau:
%   - he so dien giai pt. (S14), (S15)            (GD-03, GD-04): approved = code = [LG]
%   - lop SEI ban dau va do xop cuc am ban dau    (GD-02, GD-19): approved theo code
%                                                   (chua nguon nao phan xu), dQ nhu in
%   - mat do lop xop kho cuc am / mang ngan       (GD-07): approved = code = [OR-T7]
% Cac muc ca ba bo GIONG nhau (da duyet / da phan xu): Butler-Volmer
% 2 j0 sinh(F eta/(2RT)) (GD-21, dfn_rhs.m), dU/dT theo mV/K va he so in (S5)-(S6)
% (GD-08, GD-08b, dfn_ocp_*.m), D_e = 1010e-10 (GD-22), thermodynamic factor
% trong dong dien giai theo Landesfeind 2019 eq. [2] (GD-18).
par.src = getopt(opt, 'src', 'approved');
if ~any(strcmp(par.src, {'approved', 'paper', 'code'}))
    error('dfn_params: src phai la approved, paper hoac code');
end
iscode  = strcmp(par.src, 'code');
ispaper = strcmp(par.src, 'paper');

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
% par.Vmax: gioi han ap danh dinh cua cell (4.2 V), CHI de ghi chep / doc du lieu do (pha
% CV cua du lieu o 4.2 V); KHONG dung lam nguong sac trong mo phong.
% Ap chuyen CC -> CV va ap giu CV trong MO PHONG sac, va rang buoc V cua bo dieu khien
% (GD-43, NGUOI DUNG QUYET DINH 17/11/2026): chap nhan sai so ap CO DINH cua mo hinh 2 %:
%   V_cv = 4.2 V x (1 - 0.02) = 4.116 V.
% Day la phan du cho SAI SO MO HINH (mo hinh thieu ~30-38 mV khi sac o ~1 Ah tren cung,
% tai_lieu/dieu_tra_dien_ap_sac.md), KHONG phai do chinh xac cam bien. Dung boi dfn_cccv.m,
% val_selftest.m, src/nmpc (qua v_limit.m: cccv_window, nmpc_model, rom_validate ...).
par.V_cv     = getopt(opt, 'V_cv', 4.2*(1 - 0.02));   % V  (= 4.116 V, GD-43)
par.Vmin     = 2.5;            % V    [code] Fun_NC.py V_min
par.Rcontact = getopt(opt, 'Rcontact', 11.5e-3);  % Ohm  [Li-T6] "Contact resistance"
% Vi tri: V = phi_s,p(L) - phi_s,n(0) - I.R_contact theo [code] (khong bai nao
% ghi; doi_chieu P4, GD-20). Rcontact = 0 de bo. Nhiet I^2.R: tuy chon contact_heat (GD-05).

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
% CHI cho kiem chung voi du lieu mo O'Regan/Brosa Planella (Zenodo 4864437; GD-42, nguoi
% dung duyet 17/11/2026, muc C): luong lithium cua cell kiem chung = duong can bang qua
% x100 = 0.9014 (Li 2025 SI Note 8, gia tri cell "fresh" 5 Ah; Chen 2020 tr. 13).
% KHONG dung o dau khac: bo mac dinh cua du an giu x100 = 0.8771 (LG M50T, Li 2025).
% Ap dung trong val_run_condition.m (tuy chon 'x100', mac dinh 'fresh').
par.val.x100_fresh = 0.9014;
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
% Bai bao va SI khong nhac toi so hang nay; khong nguon goc nao phan xu
% (doi_chieu P3) -> theo [code], BAT mac dinh; bao cao ca bien the tat. GD-10
par.stress_diffusion = getopt(opt, 'stress_diffusion', true);

% ---- Mang ngan ----------------------------------------------------------
par.sep.L      = 1.2e-5;      % m  [Li-T6]
par.sep.eps_e  = 0.47;        % -  [Li-T6]
par.sep.brug_e = 1.5;         % -  [Li-T6]

% ---- Dien giai (EC:EMC 3:7, LiPF6) -------------------------------------
par.ce0    = 1000;            % mol/m3 nong do ban dau [Li-T6]
par.ce_ref = 1000;            % mol/m3 <c_e> trong pt. S26/S27 = "Typical
                              % electrolyte concentration" 1000 [code]. GD-06
% D_e, kappa, t+, TDF: xem dfn_elyte.m ([Li-N10] pt. S12-S16). Hai he so ma
% SI in khac voi bai goc [LG] (GD-03, GD-04):
if ispaper
    par.el.k4  = 0.8353;      % [Li-N10] pt. (S14) nhu in (loi in)
    par.el.tp2 = -0.612;      % [Li-N10] pt. (S15) nhu in (loi in)
elseif iscode
    par.el.k4  = 0.353;       % [code] OKane2023.py
    par.el.tp2 = -6.12;       % [code]
else
    par.el.k4  = 0.353;       % [LG] Table II (EC:EMC 3:7) p4 = 3.53E-01 (Landesfeind 2019 Table II)
    par.el.tp2 = -6.12;       % [LG] Table II p2 = -6.12E+00 (Landesfeind 2019 Table II)
end
% Cac he so con lai cua (S13)-(S16) trung tung so voi [LG] Table II; D_e: tien to
% 1010 x 1e-10 m2/s ([LG] Table II p1 = 1.01E+03, eq. [18]; GD-22, nguoi dung duyet).
% Thermodynamic factor (S16): nhan voi 2 (1 - t+) (RT/F) dln(c_e)/dx trong dong
% dien giai, theo Landesfeind 2019 eq. [2] (Li 2025 SI Table 2 va [OR-SI] Table S2
% in thieu). GD-18. use_tdf = false: dung dung nhu SI Table 2 in (de so sanh).
par.el.use_tdf = getopt(opt, 'use_tdf', true);
% Don vi he so entropy (S5), (S6): 1e-3 = he so la mV/K (GD-08, nguoi dung duyet
% 17/11/2026; can cu so lieu do goc cua O'Regan, Zenodo 5171874, header "mV K-1").
% He so (S6) dung gia tri IN (= [OR-SI] Table S7; ma nguon lech chu so thu 3-4). GD-08b
par.dUdT_scale = getopt(opt, 'dUdT_scale', 1e-3);
% Butler-Volmer (GD-21, nguoi dung duyet 17/11/2026): j = 2 j0 sinh(F eta/(2RT))
% ([OK-S1]; [vK] eq. 9), j0 theo [Li-N11] (S26)-(S27) (= [OR-SI] Table S6) voi
% <c_e> = c_e0 = 1000 mol/m3 (GD-06). Cai dat: dfn_rhs.m, dfn_j0.m.

% ---- Hysteresis OCP "current sigmoid" [Li-N7] pt. S46-S47 ---------------
par.hys.k      = 100;         % m2/A
par.hys.offset = 0.2;         % A/m2
% Nhanh OCP cuc AM (GD-40, nguoi dung duyet 17/11/2026, muc A):
%   'delith' (MAC DINH) : luon dung nhanh delithiation (S4) = nhanh xa, ca khi sac va khi
%                         xa (khong chuyen nhanh hysteresis o cuc am), nhu O'Kane 2022 (SI:
%                         OCP nhanh xa nhu Chen) va Chen 2020 (tr. 10-11, 16, 22: chi tham so
%                         hoa nhanh xa); O'Regan 2022 tr. 18 do theo chieu xa. TRAI Li 2025 SI
%                         Note 7 (zero-state hysteresis S46-S47) - xem tai_lieu/gia_dinh.md.
%                         Ly do: tai_lieu/dieu_tra_dien_ap_sac.md (buoc nhay dau pha sac
%                         mo hinh +342 mV, do +69 mV).
%   'hyst'              : hanh vi cu (Li 2025 SI Note 7): cuc am chuyen nhanh theo sigmoid.
% Cuc DUONG khong doi: van hysteresis (S46)-(S47) theo sigmoid (dieu tra: doi nhanh
% cuc duong chi doi +-2 mV).
par.ocp_n_branch = getopt(opt, 'ocp_n_branch', 'delith');
if ~any(strcmp(par.ocp_n_branch, {'delith', 'hyst'}))
    error('dfn_params: ocp_n_branch phai la delith hoac hyst');
end
par.hys.n_delith = strcmp(par.ocp_n_branch, 'delith');   % co dung trong dfn_rhs (nhanh)

% ---- Bien an toan the ma lithium cho bo dieu khien (GD-41, duyet 17/11/2026, muc B)
% Mo hinh KHONG sua phan thieu ~30-38 mV chi co khi sac o ~1 Ah tren cung
% (tai_lieu/dieu_tra_dien_ap_sac.md muc 0.2). Bu bat dinh: bien an toan ma lithium cua
% moi bo dieu khien tang them 35 mV:  delta_total = delta_base + par.ctrl.delta_pl_extra.
% delta_base la gia dinh rieng (GD-28, do bo dieu khien dat). DAY LA NOI DUY NHAT dat so 35 mV.
par.ctrl.delta_pl_extra = 35e-3;   % V

% ---- Trang thai dau doi (BOL) lien quan toi lao hoa ---------------------
% Lop SEI ban dau va do xop cuc am: [Li-N9] pt. S7-S11.
par.sei.Qloss0 = 5 - 4.865;   % Ah   [Li-N9] "5 - 4.865 = 0.135 Ah" (GD-19)
if iscode, par.sei.Qloss0 = 5 - 4.86491; end   % [code] Fun_NC.py
par.sei.z      = 2;           % -    [Li-T8] z_SEI; [S18] SI Table SI-2 s = 2
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
par.sei.Sr = Sr;
% Lop SEI ban dau: CHUA nguon nao phan xu (doi_chieu S5). 'code' = cach cua ma
% nguon (mac dinh cho approved va code); 'paper' = Li 2025 SI Table 8 nhu in.
par.sei.init = getopt(opt, 'sei_init', ternary(ispaper, 'paper', 'code'));
if strcmp(par.sei.init, 'code')
    % [code] Fun_NC.py::Overwrite_Initial_L_SEI_0_Neg_Porosity: tinh lai theo
    % (S7) voi V_SEI da fit, cong them 2.5 nm cho moi lop (khong co trong SI);
    % do xop khong tinh phan 2.5 nm. Bo "5 coupled": 9.2326e-9 m, eps_n = 0.234965.
    L_S7 = 1800*par.sei.Qloss0/(par.F*par.sei.z) * par.sei.V/(Sr*par.neg.as0*Vn);
    par.sei.L_layer0 = L_S7 + 2.5e-9;
    deps = 2*L_S7*Sr*par.neg.as0;
else
    % [Li-T8]: "Initial inner/outer SEI thickness" = 1.23625e-8 m (ghi la khong doi);
    % do xop: [Li-T6] "See Eq. (S11)", [Li-N9] pt. (S10): d_eps = 2 L_SEI,0^inner S_r a
    par.sei.L_layer0 = getopt(opt, 'L_SEI_layer0', 1.23625e-8);
    deps = 2*par.sei.L_layer0*Sr*par.neg.as0;       % pt. S10
end
% ---- Dang luat tang SEI (dung o buoc C, CHUA cai vat ly lao hoa) ---------
% Da phan xu bang bai goc (tai_lieu/doi_chieu_tham_so.md muc 1.2):
%  - so mu exp(-F (phi_s - phi_e)/(R T)), T = nhiet do cell: [S18] eq. (5),
%    [vK] eq. (18), (25); Li 2025 (S2), (S6), (S7) in thieu F/(RT). (S1)
%  - the trong so mu la phi_s - phi_e, KHONG tru sut ap mang (Li 2025 in, [code]). (S2)
%  - moi lop (inner/outer) nhan 1/2 dong SEI ([Li-N2] (S3)-(S4), alpha = 0.5 [Li-T8]):
%    dL_layer/dt = c_int D_int V_SEI/(4 L) exp(...)  (he so 1/4; (S6)-(S7) in 1/2 la sai). (S3)
%  - z_SEI = 2 ([Li-T8]; [S18]).
%  - ma lithium: alpha_a,Li = 0.35 (hoa tan), alpha_c,Li = 0.65 (ma) (O'Kane 2022; (P1)).
par.sei.growth.exp_scale  = par.F/par.R;   % nhan voi (phi_s - phi_e)/T trong so mu
par.sei.growth.eta_minus_film = false;     % khong tru sut ap mang SEI
par.sei.growth.k_layer    = 1/4;           % he so truoc c_int D_int V_SEI / L moi lop
par.sei.growth.alpha_layer = 0.5;          % ti le dong SEI vao lop trong [Li-T8]
par.lp.alpha_a = 0.35;                     % hoa tan lithium ma [OK]
par.lp.alpha_c = 0.65;                     % ma lithium [OK]
par.sei.L0    = 2*par.sei.L_layer0;                 % m, inner + outer (Note 2 pt. S8)
par.neg.eps_e = 0.25 - deps;                        % pt. S11

% ---- Nhiet (lumped 0D) --------------------------------------------------
% Dang 0D theo [code] (PyBaMM lumped): Li 2025 SI Table 3 va [OR-SI] Table S3 chi
% in PDE tong quat (doi_chieu P5, GD-12). Day la dang nhiet duy nhat duoc cai;
% lambda(T) (S24)-(S25) khong dung trong 0D (doi_chieu B12).
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
% Mat do lop xop kho "Density (porous)": [Li-T6] in doi cho hai o (mang ngan
% 1740, am 946); bai goc O'Regan 2022 Table 7 (do): graphite-SiOy 1740,
% separator 946 kg/m3 (trung [code]). GD-07
par.th.rho_dry = [1740, 946, 3270];   % kg/m3 am, mang ngan, duong  [OR-T7] (duong: [Li-T6])
if ispaper, par.th.rho_dry = [946, 1740, 3270]; end  % [Li-T6] nhu in (loi in)
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

par.neg = dfn_Ktable(par.neg);   % bang tich phan Kirchhoff cua D_s (GD-15)
par.pos = dfn_Ktable(par.pos);
par = dfn_mesh(par);
end

function v = ternary(c, a, b)
if c, v = a; else, v = b; end
end

function v = getopt(opt, name, default)
if isfield(opt, name) && ~isempty(opt.(name)), v = opt.(name); else, v = default; end
end
