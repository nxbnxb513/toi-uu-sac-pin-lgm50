function dry = dfn_dryout_init(par, y)
%DFN_DRYOUT_INIT  Trang thai cua lop boc tieu thu dung moi / can kho (Li 2025 SI Note 6).
% Bien (S36)-(S43): V_res, c_e,res, c_EC,res (reservoir), A_cell, c_EC (jelly roll).
%   V_res(0) = (R_exc - 1) V_pore(0): "Initial excessive electrolyte amount" R_exc = V_tot/V_pore,0
%   ([Li-T8] in gia tri 1.0 nhung khong dinh nghia; dinh nghia theo code Fun_NC.py
%   Initialize_mdic_dry - GD-54). R_exc = 1.0 -> khong co reservoir.
L = dfn_li_inventory(par, y);
dry.Amax   = par.A;            % A_cell,max (dien tich ban dau)
dry.A      = par.A;
dry.Vres   = (par.ag.R_exc - 1)*L.Vpore;
dry.ce_res = par.ag.ce_res0;   % [Li-T8]
dry.cEC_res = par.ag.cEC0;     % [Li-T8]
dry.cEC    = par.ag.cEC0;      % [Li-T6]
dry.n_dry  = 0;                % mol Li nam trong phan dien cuc da kho (so sach)
dry.log    = zeros(0, 9);      % [case, R_dry, dV_pore, dV_EC, dV_add, dV_sq, A, V_res, c_ratio]
end
