function p = params_lgm50(grid)
%PARAMS_LGM50  Bo tham so cho cell LG M50 21700 (NMC811 / graphite-SiOx, 5 Ah).
%
%   p = params_lgm50()        luoi mac dinh (plant)
%   p = params_lgm50('coarse') luoi tho (dung cho bo uoc luong EKF)
%
% Nguon so lieu (xem tai_lieu/tham_so/*.md de biet so trang):
%   [1] O'Kane 2022, PCCP 24:7909        - Bang S2, S3, S4; pt. S1-S7, (12)-(16)
%   [4] Chen 2020, JES 167:080534        - pt. (8), (9) (OCP); Bang VII, IX
%   [5] O'Regan 2022, Electrochim. Acta  - Bang 3, 8 (nhiet)
%   [7] Li 2025, Nat. Commun. 16:2776    - Bang 3, SI Bang 8, SI Note 2, Note 8
% Gia tri co nhan "GIA DINH" la gia dinh cua de tai, khong co nguon truc tiep.

if nargin < 1, grid = 'fine'; end

% ---- Hang so -----------------------------------------------------------
p.F    = 96485;      % C/mol            [1] Bang S3
p.R    = 8.314;      % J/(mol K)        [1] Bang S3
p.Tref = 298.15;     % K                [1]

% ---- Hinh hoc va cell ---------------------------------------------------
p.A     = 0.1027;    % m^2  dien tich dien cuc            [1] Bang S2
p.Qnom  = 5.0;       % Ah   dung luong danh dinh          [1] Bang S3
p.Vmax  = 4.2;       % V                                  [1] Bang S3
p.Vmin  = 2.5;       % V                                  [1] Bang S3

% ---- Dien cuc am (graphite-SiOx) ---------------------------------------  [1] Bang S2
p.n.L     = 8.52e-5;   % m
p.n.Rp    = 5.86e-6;   % m
p.n.eps_e = 0.25;
p.n.eps_s = 0.75;
p.n.cmax  = 33133;     % mol/m^3
p.n.Ds    = 3.3e-14;   % m^2/s tai 25 C
p.n.EDs   = 30300;     % J/mol
p.n.k     = 2.12e-10;  % m/s tai 25 C
p.n.Ek    = 35000;     % J/mol
p.n.sigma = 215;       % S/m
p.n.x0    = 0.0279;    % he so ti luong tai 0 % SOC    [4] Bang VII
p.n.x100  = 0.9014;    % he so ti luong tai 100 % SOC  [4] Bang VII
p.n.a     = 3*p.n.eps_s/p.n.Rp;   % 1/m  ([4] pt. 26)

% ---- Dien cuc duong (NMC811) -------------------------------------------  [1] Bang S2
p.p.L     = 7.56e-5;
p.p.Rp    = 5.22e-6;
p.p.eps_e = 0.335;
p.p.eps_s = 0.665;
p.p.cmax  = 63104;
p.p.Ds    = 4e-15;
p.p.EDs   = 25000;     % gia tri cua NCA, [1] ghi ro
p.p.k     = 1.12e-9;
p.p.Ek    = 17800;
p.p.sigma = 0.18;
p.p.y100  = 0.27;      % he so ti luong tai 100 % SOC  [4] Bang IX
p.p.a     = 3*p.p.eps_s/p.p.Rp;

% ---- Mang ngan va chat dien phan ---------------------------------------  [1] Bang S3
p.s.L     = 1.2e-5;
p.s.eps_e = 0.47;
p.ce0     = 1000;      % mol/m^3
p.tplus   = 0.2594;
p.brug    = 1.5;       % [1] pt. S3
p.Ee      = 17100;     % J/mol, dung chung cho kappa va De  [1] Bang S3

% ---- Nhiet (mo hinh 0D) ------------------------------------------------  [5]
p.th.m   = 6.83e-2;    % kg   khoi luong cell               [5] Bang 3
p.th.Cp  = 866;        % J/(kg K) gia tri dung trong mo phong cua [5] (Bang 8)
p.th.As  = 5.31e-3;    % m^2  dien tich trao doi nhiet cell [5] Bang 8
p.th.h   = 15;         % W/(m^2 K), [5] chinh tay (tr. 32)
% GIA DINH: ap dung Cp cua jellyroll cho toan bo khoi luong cell.

% ---- SEI: gioi han boi khuech tan Li xen ke ----------------------------  [7]
p.sei.cint = 15;         % mol/m^3   [7] SI Bang 8
p.sei.Dint = 2.36e-18;   % m^2/s     [7] Bang 3, mo hinh "SEI only"
p.sei.V    = 4e-5;       % m^3/mol   [7] Bang 3
p.sei.E    = 1e4;        % J/mol     [7] Bang 3
p.sei.rho  = 2e5;        % Ohm m     [7] SI Bang 8, [1] Bang S4
p.sei.L0   = 2*1.23625e-8;  % m, tong hai lop  [7] SI Bang 8
% GIA DINH: [7] khop Dint tren bo tham so nen cua [5]; o day ghep vao bo
% tham so nen cua [4]/[1], nen Dint la gia tri khoi dau, chua kiem chung lai.
% GIA DINH: so mu cua SEI dung dang exp(-F*(phi_s-phi_e)/(R*T)); [7] in
% thieu he so F/(RT).

% ---- Ma lithium va lithium chet ----------------------------------------
p.pl.k      = 1e-10;   % m/s   [7] Bang 3, mo hinh "5 coupled"
p.pl.gamma0 = 1e-7;    % 1/s   [7] Bang 3
p.pl.aa     = 0.35;    % [1] Bang S4 (gia dinh cua [1])
p.pl.ac     = 0.65;    % [1] Bang S4 (gia dinh cua [1])

% ---- Luoi roi rac -------------------------------------------------------
switch lower(grid)
    case 'coarse'
        p.Nr = 4;  p.Nn = 2; p.Ns = 1; p.Np = 2;
    otherwise
        p.Nr = 10; p.Nn = 6; p.Ns = 3; p.Np = 6;
end

% ---- Dai luong dan xuat -------------------------------------------------
% Luong Li ung voi 0-100 % SOC, tinh theo dien cuc am.
p.nLi_n = p.n.eps_s*p.n.L*p.A*p.n.cmax;      % mol cho x = 1
p.nLi_p = p.p.eps_s*p.p.L*p.A*p.p.cmax;      % mol cho y = 1
p.Qcap  = p.F*p.nLi_n*(p.n.x100 - p.n.x0)/3600;   % Ah
end
