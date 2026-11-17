function c = ekf_config(noise)
%EKF_CONFIG  Muc nhieu cam bien va cac so dieu chinh (tuning) cua EKF.
%   c = ekf_config('lab')      nhieu bo ghi phong thi nghiem (do tu du lieu)
%   c = ekf_config('bms')      nhieu BMS thuc te (GIA DINH, GD-71)
%   c = ekf_config('bms_off')  nhu 'bms' + lech khong (offset) cam bien dong (GD-71)
% Moi so o day la so DO TU DU LIEU (ghi nguon) hoac GIA DINH ghi trong
% tai_lieu/gia_dinh.md (GD-70 .. GD-74). Giai thich: tai_lieu/bo_uoc_luong_ekf.md.
%
% c.sens  : nhieu THAT dua vao tin hieu do (mo phong cam bien)
% c.R*, c.Q*, c.P0* : so dieu chinh cua bo loc (khong phai do chinh xac cam bien)
if nargin < 1 || isempty(noise), noise = 'lab'; end
c.noise = noise;
switch noise
    case 'lab'
        % GD-70: data/ket_qua_du_lieu.md muc A.2 (Zenodo 4864437, bo ghi phong thi nghiem)
        c.sens.sV = 35.5e-6;  c.sens.qV = 20e-6;   % V: sigma = 35.5 uV (trung vi std_d2), buoc luong tu 20 uV (trung vi)
        c.sens.sI = 0.17e-3;  c.sens.qI = 0.35e-3; % A: sigma = 0.17 mA (pha xa CC), buoc 0.35 mA
        c.sens.sT = 0;        c.sens.qT = 0.1;     % K: nhieu < 1 buoc; do phan giai 0.1 degC (=> q/sqrt(12) = 0.029 K)
        c.sens.bI = 0;                             % A: khong co lech khong
    case {'bms', 'bms_off'}
        % GD-71 (GIA DINH, khong co nguon trong cac bai da doc): BMS o to/thiet bi thong thuong
        c.sens.sV = 2e-3;     c.sens.qV = 1e-3;    % V: sigma 2 mV, do phan giai 1 mV
        c.sens.sI = 25e-3;    c.sens.qI = 10e-3;   % A: sigma 25 mA (0.5 % cua 1C), do phan giai 10 mA
        c.sens.sT = 0.5;      c.sens.qT = 0.1;     % K: sigma 0.5 K, do phan giai 0.1 degC
        c.sens.bI = 0;
        if strcmp(noise, 'bms_off')
            c.sens.bI = 50e-3;                     % A: lech khong +50 mA (1 % cua 1C), khong doi, bo loc KHONG biet
        end
    otherwise
        error('ekf_config: muc nhieu %s khong hop le', noise);
end
% ---- do lech chuan "hieu dung" cua cam bien dung trong bo loc ----------------
% luong tu hoa: phan bo deu, sigma = q/sqrt(12)
c.sV_sens = sqrt(c.sens.sV^2 + c.sens.qV^2/12);
c.sI_sens = sqrt(c.sens.sI^2 + c.sens.qI^2/12);
c.sT_sens = sqrt(c.sens.sT^2 + c.sens.qT^2/12);
% bo loc khong biet gia tri lech khong, chi biet co the co: GD-71 cho phep toi
% 50 mA (1 % cua 1C) o MOI muc BMS -> tinh vao nhieu dau vao nhu nhieu trang
if any(strcmp(noise, {'bms', 'bms_off'})), c.bI_filter = 50e-3; else, c.bI_filter = 0; end

% ---- GD-73: sai so mo hinh trong phuong trinh do (tuning) ---------------------
% ROM (cau hinh D) so voi DFN cung tham so: V RMS 1.2-8.6 mV khi sac
% (tai_lieu/mo_hinh_rut_gon.md muc 7); them lech tham so pin that (GD-72).
% Couto 2022 (muc IV-C) dung R_V = 1e-6 V^2 (1 mV) tren mo hinh cua ho.
c.sV_model = 5e-3;      % V
% Nhiet: ROM vs DFN T max 0.01-0.27 K; lech h (GD-72) lam mo hinh lech them -> 0.1 K
c.sT_model = 0.1;       % K

% ---- GD-73: nhieu qua trinh (toc do lien tuc, nhan voi dt) ---------------------
% duoi dang "do lech chuan tich luy sau 1 gio" (de doc):
c.q1h.th = 0.01;        % stoich hat (moi vo, ca hai cuc)
c.q1h.ce = 0.01;        % c_e / c_e,ref
c.q1h.T  = 0.5;         % K
c.q1h.rf = 0.1;         % R_film / R_film,BOL (tham so troi cham, Couto 2022: R_f(k+1) = R_f(k) + w_R)

% ---- GD-74: hiep phuong sai ban dau P0 -----------------------------------------
c.P0.soc = 0.10;        % SOC (1 sigma) theo duong can bang lithium (do sai SOC ban dau +/-10 %)
c.P0.lli = 0.15;        % Ah   luong lithium mat (huong lech cuc duong khi cuc am co dinh)
c.P0.rf  = 0.5;         % R_film / R_film,BOL
c.P0.T   = 1.0;         % K
c.P0.ce  = 1e-3;        % c_e / c_e,ref
c.P0.th  = 1e-4;        % stoich (tung vo, doc lap; trang thai nghi la deu nen nho)

% ---- buoc thoi gian -------------------------------------------------------------
c.n_iter = 5;           % so lan lap toi da cua buoc cap nhat (1 = EKF thuong; > 1 = EKF lap, GD-73)
c.t_hold = 0;           % s  giu rf va LLI (khong cap nhat) trong t < t_hold (hai thang thoi gian, GD-74); 0 = tat
c.dt = 5;               % s chu ky lay mau cua EKF (lua chon so hoc; NMPC giai lai moi 30 s)
end
