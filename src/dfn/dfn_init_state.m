function y = dfn_init_state(par, xn, yp, T0)
%DFN_INIT_STATE  Trang thai can bang dong deu: stoich cuc am xn, cuc duong yp,
% nhiet do T0 [K], dien giai ce0, dong I = 0.
ix = par.ix; g = par.grid;
y = zeros(ix.ny,1);
y(ix.thn) = xn; y(ix.thp) = yp;
y(ix.ce)  = par.ce0/par.ce_ref;
y(ix.T)   = T0;
y(ix.Q)   = 0;
% Tai I = 0 ham sigmoid chon nhanh xa (offset 0.2 A/m2): am delithiation, duong lithiation
m = 0.5*(1 + tanh(par.hys.k*par.hys.offset));
[Unl, Und, dUn] = dfn_ocp_neg(xn);
[Upl, Upd, dUp] = dfn_ocp_pos(yp);
Un = (1 - m)*Unl + m*Und + (T0 - par.Tref)*dUn;
Up = m*Upl + (1 - m)*Upd + (T0 - par.Tref)*dUp;
y(ix.phisn) = 0;            % moc the: phi_s = 0 tai current collector am
y(ix.phie)  = -Un;
y(ix.phisp) = Up - Un;
y(ix.jn) = 0; y(ix.jp) = 0; y(ix.H) = 0; y(ix.I) = 0;
if g.N < 1, error('luoi rong'); end
end
