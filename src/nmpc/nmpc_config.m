function c = nmpc_config(par)
%NMPC_CONFIG  Cac gia tri cua bo dieu khien NMPC. Moi so la GIA DINH hoac
% lua chon so hoc, liet ke trong tai_lieu/gia_dinh.md (GD-26 .. GD-30) va giai
% thich trong tai_lieu/mo_hinh_rut_gon.md muc 8.
c.Imax   = 2*par.Qnom;   % A    dong sac toi da 2C = 10 A (GD-26, gia dinh)
c.Tmax   = 318.15;       % K    nhiet do cell toi da 45 degC (GD-27, gia dinh)
c.delta_base = 0.010;    % V    bien an toan the ma lithium co ban 10 mV (GD-28, gia dinh)
% (B) nguoi dung duyet 17/11/2026 (GD-41): cong them bien an toan ma lithium, doc
% tu noi duy nhat trong src/dfn/dfn_params.m (par.ctrl.delta_pl_extra = 35 mV).
c.delta_extra = par.ctrl.delta_pl_extra;
c.delta  = c.delta_base + c.delta_extra;   % V  delta_total = 45 mV
c.xsmax  = 0.99;         % -    stoich be mat cuc am phia mang ngan <= 0.99 (GD-29, gia dinh)
c.N      = 20;           % so khoang du bao tren phan sac con lai (GD-30, so hoc)
c.Ts     = 30;           % s    chu ky giai lai NMPC / lay mau (GD-30, so hoc)
c.w_loss = 10;           % 1/mAh trong so lithium mat cu (GD-30); tu 18/11/2026 dung w_loss_scale (GD-84)
c.w_loss_scale = 0.1;    % muc tieu = 0.1 x (mat du doan) / (mat du doan cua doan dau CCCV tren ROM) (GD-84, sua 18/11/2026:
                         % muc tieu ~10 lam buoc Gauss-Newton qua lon -> NaN trong tim kiem duong, run 44234227906)
c.w_dI   = 1e-4;         % 1/A^2 trong so nho cua bien thien dong giua hai khoang (GD-30)
c.tmax_factor = 6;       % can tren thoi gian mo phong vong kin = 6 T_CCCV (an toan)
end
