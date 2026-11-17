function ag = dfn_aging_state(par, y) %#ok<INUSD>
%DFN_AGING_STATE  [HOOK lao hoa] Cac dai luong ma lao hoa lam thay doi, theo
% tung nut x. Buoc 1 (chua co lao hoa): tat ca la hang so BOL.
%
% Buoc sau: them trang thai vi phan (L_SEI(k), eps_n(k), eps_s(k), l_cr(k),
% c_Li(k)...) vao vector y (sau Q, xem dfn_mesh.m) va tinh cac truong duoi
% day tu y thay vi tu par. dfn_rhs.m chi doc cac truong nay:
%   ag.eps     (N x 1)   do xop dien giai eps_e(x)   -> D_eff, kappa_eff, d(ce)/dt
%   ag.as_n    (Nn x 1)  dien tich be mat rieng a_n = 3 eps_s/R [1/m]
%   ag.as_p    (Np x 1)
%   ag.Rfilm_n (Nn x 1)  dien tro mang SEI rho_SEI.L_SEI [Ohm.m^2]
%   ag.Rfilm_p (Np x 1)  (= 0)
g = par.grid;
ag.eps     = [par.neg.eps_e*ones(g.Nn,1); par.sep.eps_e*ones(g.Ns,1); par.pos.eps_e*ones(g.Np,1)];
ag.as_n    = par.neg.as0*ones(g.Nn,1);
ag.as_p    = par.pos.as0*ones(g.Np,1);
% Li 2025 SI Note 2 pt. (S9): eta_SEI = rho_SEI . j_tot . L_SEI, L_SEI = inner + outer
ag.Rfilm_n = par.sei.rho*par.sei.L0*ones(g.Nn,1);
ag.Rfilm_p = zeros(g.Np,1);
end
