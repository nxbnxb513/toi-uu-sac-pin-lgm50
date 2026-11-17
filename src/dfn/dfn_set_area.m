function par = dfn_set_area(par, A)
%DFN_SET_AREA  Doi dien tich dien cuc hieu dung A [m^2] (can kho: Li 2025 SI (S38)
% A_cell(t + dt) = R_dry A_cell(t)) va cac dai luong dan xuat phu thuoc A.
par.A = A;
par.neg.Qcap = par.neg.cmax*par.neg.eps_s*par.neg.L*par.A*par.F/3600;
par.pos.Qcap = par.pos.cmax*par.pos.eps_s*par.pos.L*par.A*par.F/3600;
end
