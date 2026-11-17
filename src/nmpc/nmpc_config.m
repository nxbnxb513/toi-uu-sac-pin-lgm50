function c = nmpc_config(par)
%NMPC_CONFIG  Cac gia tri cua bo dieu khien NMPC. Moi so la GIA DINH hoac
% lua chon so hoc, liet ke trong tai_lieu/gia_dinh.md (GD-26 .. GD-30) va giai
% thich trong tai_lieu/mo_hinh_rut_gon.md muc 8.
c.Imax   = 2*par.Qnom;   % A    dong sac toi da 2C = 10 A (GD-26, gia dinh)
c.Tmax   = 318.15;       % K    nhiet do cell toi da 45 degC (GD-27, gia dinh)
c.delta  = 0.010;        % V    bien an toan the ma lithium eta_Li >= 10 mV (GD-28, gia dinh)
c.xsmax  = 0.99;         % -    stoich be mat cuc am phia mang ngan <= 0.99 (GD-29, gia dinh)
c.N      = 20;           % so khoang du bao tren phan sac con lai (GD-30, so hoc)
c.Ts     = 30;           % s    chu ky giai lai NMPC / lay mau (GD-30, so hoc)
c.w_loss = 10;           % 1/mAh trong so lithium mat (chuan hoa, khong lam doi nghiem khi khong co rang buoc mem nao hoat dong)
c.w_dI   = 1e-4;         % 1/A^2 trong so nho cua bien thien dong giua hai khoang (GD-30)
c.tmax_factor = 6;       % can tren thoi gian mo phong vong kin = 6 T_CCCV (an toan)
end
