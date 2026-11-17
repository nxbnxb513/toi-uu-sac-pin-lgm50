function [par, y1, dry, info] = dfn_dryout_update(par, y0, y1, dry)
%DFN_DRYOUT_UPDATE  Cap nhat roi rac "tieu thu dung moi / can kho" (Li 2025 SI Note 6,
% pt. (S24)-(S43), Supplementary Table 4) sau mot doan mo phong tu y0 (dau doan) toi y1
% (cuoi doan), cung dien tich par.A. Tra ve par (A moi), y1 (c_e da nhan ti so (S43)), dry.
%
% Nhan nguon (chi tiet: tai_lieu/dac_ta_lao_hoa.md muc 10; gia_dinh.md GD-54..GD-56):
%  - (S24)-(S26) dV_pore = d int eps_n A dx (chi cuc am thay doi)            theo bai bao
%  - (S27)-(S30) dV_EC = -2 Vbar_EC d int (L_SEI + 2 l w rho L_SEI,cr)/Vbar_SEI a_n A dx
%                (gom SEI tren vet nut; a_n hien thoi)                        theo bai bao
%  - (S31) dV_need = dV_pore - dV_EC; 5 truong hop (Table 4)                  theo bai bao
%  - (S32)-(S38) the tich, R_dry = V_e(t+dt)/V_pore(t+dt), A <- R_dry A        theo bai bao
%  - (S39)-(S43) nong do: dung cac PHUONG TRINH (S39)-(S43); o truong hop 3-5 Table 4 ghi
%    "c_e khong doi", mau thuan voi (S41) (mat Li+ khi the tich EC giam) -> chon (S41)
%    (bao toan lithium), voi c_e^avg(t) V_e(t) hieu la luong Li+ trong jelly roll (GD-55).
%  - Truong hop 4 (tham uot lai, R_dry > 1): A khong vuot A_max; phan the tich du day ra
%    reservoir (bai khong noi; GD-56).
%  - Khoang Delta t giua hai lan cap nhat: moi doan (truoc moi ageing set va moi RPT),
%    theo code (bai khong ghi Delta t) (GD-54).
%  - Nong do EC chi theo doi, khong hoi tiep (SEI interstitial khong dung c_EC).
A = par.A; ag = par.ag;
L0 = dfn_li_inventory(par, y0); L1 = dfn_li_inventory(par, y1);
Ve   = L0.Vpore;                       % (S34) V_e(t) = V_pore(t)
Vp1  = L1.Vpore;
dVpore = Vp1 - Ve;                     % (S26)
dVEC = -2*ag.V_EC*(nsei_mol(par, y1) - nsei_mol(par, y0));   % (S28)
need = dVpore - dVEC;                  % (S31)
add = 0; sq = 0; tol = 1e-15;
if need > tol
    if dry.Vres >= need, cas = 1; add = need; else, cas = 2; add = dry.Vres; end
elseif need < -tol
    if dry.A < dry.Amax*(1 - 1e-12)
        cas = 4;                                           % tham uot lai
    else
        cas = 5; sq = -need;                               % ep ra reservoir
    end
else
    cas = 3;
end
dVe  = dVEC + add - sq;                % (S32)
Vnew = Ve + dVe;                       % (S35)
R = Vnew/Vp1;                          % (S37)
if cas == 4 && R*dry.A > dry.Amax      % GD-56: khong vuot A_max, phan du ep ra reservoir
    R = dry.Amax/dry.A; sq = Vnew - R*Vp1; Vnew = R*Vp1;
end
% ---- nong do (S39)-(S43) --------------------------------------------------
ne   = L1.elyte; cbar = ne/Vp1;        % c_e^avg trong jelly roll (trung binh theo the tich lo)
ne_new = ne - cbar*sq + dry.ce_res*add;
cnew = ne_new/Vnew;                                                    % (S41)
Vr2 = dry.Vres - add + sq;                                             % (S36)
if Vr2 > 0
    ce_res = (dry.ce_res*(dry.Vres - add) + sq*cbar)/Vr2;              % (S39)
    cEC_res = (dry.cEC_res*(dry.Vres - add) + sq*dry.cEC)/Vr2;         % (S40)
else
    ce_res = 0; cEC_res = 0; Vr2 = 0;                                  % Table 4 truong hop 2
end
cEC = (dry.cEC*(Ve + dVEC - sq) + dry.cEC_res*add)/Vnew;               % (S42)
ratio = cnew/cbar;
y1(par.ix.ce) = y1(par.ix.ce)*ratio;                                   % (S43)
% ---- so sach lithium: phan ran/SEI/ma... trong dien tich bi kho (hoac tham lai) ----------
solid = L1.total - L1.elyte;
dry.n_dry = dry.n_dry + (1 - R)*solid;
dry.Vres = Vr2; dry.ce_res = ce_res; dry.cEC_res = cEC_res; dry.cEC = cEC;
dry.A = R*A;
par = dfn_set_area(par, dry.A);
dry.log(end+1, :) = [cas, R, dVpore, dVEC, add, sq, dry.A, dry.Vres, ratio];
info = struct('case', cas, 'R_dry', R, 'dV_pore', dVpore, 'dV_EC', dVEC, 'dV_add', add, ...
    'dV_squeeze', sq, 'A', dry.A, 'c_ratio', ratio);
end

function n = nsei_mol(par, y)
% (S27): so mol SEI = int (L_SEI/Vbar + 2 l w rho L_SEI,cr/Vbar) a_n A dx (a_n hien thoi)
a = dfn_aging_state(par, y); ag = par.ag;
n = par.A*par.grid.dxn*sum(((a.Lin/ag.V_in + a.Lout/ag.V_out) + (a.S - 1).*(a.Lcin/ag.V_in + a.Lcout/ag.V_out)).*a.as_n);
end
