function si = dfn_si_params(o, par)
%DFN_SI_PARAMS  Tham so TANG 2 (lao hoa silicon o SOC thap, GIA DINH) - tai_lieu/dac_ta_lao_hoa.md
% muc 16 (de xuat T2-A), gia_dinh.md GD-90 tro di, tai_lieu/ket_qua_silicon.md.
%   si = dfn_si_params(o, par)   o = false (MAC DINH: tang 2 tat, tang 1 khong doi gi) |
%                                    true (tang 2, tham so da hieu chinh) | struct ghi de
% TOAN BO TANG 2 LA GIA DINH: khong phuong trinh/tham so nao do Li 2025 cung cap.
%
% Mo hinh (T2-A; mot trang thai them eps_Si(x,t) - phan the tich silicon theo duong luong dung
% luong; eps_s,n = eps_Gr + eps_Si, eps_s,n van la trang thai epsn cua tang 1):
%   w_Si  = w_lo + (w_hi - w_lo)(1 - tanh((sto_surf - sto_Si)/d_sto))/2   phan dong xen cai do Si mang
%   r     = eps_Si/eps_Si,0
%   a_Si  = 3 eps_s,n,0 V_Si/R_Si . r^q_a        (Ai 2022 pt. (3); q_a = 1: co theo LAM-Si nhu de xuat)
%   j_Si  = w_Si a_n j_int / a_Si                [A/m2]
%   dc_Si = j_Si R_Si/(5 F D_Si)                 [mol/m3] (tua dung, profile parabol; > 0 khi nha Li)
%   d eps_Si/dt = -k (max(dc_Si, 0))^m r^s       (luat LAM do ung suat (S21)-(S22) cua Li 2025 ap cho
%                                                 Si, gop hang so co hoc vao k; GD-90)
% Dang de xuat in trong dac_ta muc 16.2 la q_a = 1, s = 1 ("form A": toc do ~ r^(s - m q_a) = 1/r,
% hoi tiep duong). "form B" (q_a = 0, s = 1: mat do dong tren hat Si con lai khong doi, toc do ~ r)
% va "form C" (q_a = 0, s = 2: toc do ~ r^2) la hai bien the dang duong cong (GD-92); chon theo
% du lieu 25 C cua Expt 1 (GD-93).
%
% Nguon tung so (dac_ta_lao_hoa.md muc 16.3):
%   R_Si = 1.52 um, D_Si = 1.67e-14 m2/s, V_Si = 0.02    Ai 2022 Table 3 (tr. 12) [BAI]
%   f_Si = 0.800/5.272                                   Kirkaldy 2024 Table 7 (tr. 6) [BAI];
%                                                        dung lam eps_Si,0/eps_s,n,0 la GIA DINH (GD-91)
%   sto_Si = 0.800 Ah / dung luong cuc am mo hinh         GIA DINH (GD-91)
%   d_sto = 0.03; w_lo = 0.1, w_hi = 0.9 ("~0.9 I_app", Ai 2022 tr. 15); m = 2 (= m2 tang 1)  GIA DINH
%   k                                                     GIA DINH, hieu chinh (GD-93)
if nargin < 1 || isempty(o), o = false; end
si = struct('on', false);
if islogical(o) || isnumeric(o)
    if ~o, return; end
    o = struct();
end
si.on = true;
si.R    = 1.52e-6;            % m      Ai 2022 Table 3
si.D    = 1.67e-14;           % m2/s   Ai 2022 Table 3
si.V    = 0.02;               % -      Ai 2022 Table 3 (uoc luong cua ho)
si.f    = 0.800/5.272;        % -      Kirkaldy 2024 Table 7 (GD-91)
si.sto  = 0.800/par.neg.Qcap; % -      = 0.1398 (GD-91)
si.dsto = 0.03;               % -      GD-91
si.w_lo = 0.1; si.w_hi = 0.9; % -      GD-91
si.m    = 2;                  % -      GD-91
% Gia tri hieu chinh (GD-93; tai_lieu/ket_qua_silicon.md). form: 'A' | 'B' | 'C'
% Hieu chinh 18/11/2026 (Expt 1, 25 C; probe run 44258818797, siB_k3e-14 va siB_k3e-15):
% dang C co RMSE LAM_Si 7.9 diem % (B 13.2, A 28.4); k* = 3.53e-14 (probe 3e-14), 3.32e-14 (probe 3e-15).
si.form = 'C';
si.k    = 3.5e-14;            % (m3/mol)^m / s  (GD-93)
fn = fieldnames(o);
for i = 1:numel(fn), si.(fn{i}) = o.(fn{i}); end
switch si.form
    case 'A', si.q_a = 1; si.s = 1;
    case 'B', si.q_a = 0; si.s = 1;
    case 'C', si.q_a = 0; si.s = 2;
    otherwise, error('dfn_si_params: form khong hop le: %s', si.form);
end
si.eps0 = si.f*par.neg.eps_s;                     % eps_Si,0 (moi nut x)
si.a0   = 3*par.neg.eps_s*si.V/si.R;              % a_Si,0 [1/m]
si.cdc  = si.R/(5*par.F*si.D);                    % dc_Si = cdc . j_Si
si.rmin = 1e-6;                                   % chan duoi r trong luy thua am (an toan so hoc)
end
