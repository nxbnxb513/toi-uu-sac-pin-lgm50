function q = ekf_outputs(E, xa, P, I, Ta)
%EKF_OUTPUTS  Cac dai luong uoc luong va do lech chuan (tu P, tuyen tinh hoa):
%   q.soc, q.s_soc     SOC = (xbar_n - x0)/(x100 - x0) (GD-24)
%   q.eta, q.s_eta     the ma lithium phia mang ngan eta_Li,sep [V] (rom_equations o.eta_sep)
%   q.T, q.s_T         nhiet do [K]
%   q.lli, q.s_lli     lithium mat so voi duong can bang BOL [Ah]
%                      = Qn x100 + Qp y100 - (Qn xbar_n + Qp ybar_p)
%   q.rf, q.s_rf       R_film / R_film,BOL;  q.Lsei, q.s_Lsei  do day SEI [m] = rf L_SEI,BOL
%   q.xs_sep           stoich be mat cuc am phia mang ngan
% I: dong [A] (DFN, > 0 xa) tai thoi diem uoc luong.
nx = E.nx; ix = E.ix; fi = E.fi; nf = E.nf;
x = xa(1:nx); rf = xa(nx+1);
z = ekf_solve_z(E, x, I, Ta, rf);
[~, ~, ~, ~, ~, ~, gx, gz, grf, ~, eta, ex, ez, erf, xs] = E.Hf(x, z, I, Ta, rf);
gx = full(gx); gz = full(gz); grf = full(grf);
dz = -gz\[gx(:, fi), grf];
ce = [full(ex(:, fi)), full(erf)] + full(ez)*dz;
q.eta = full(eta); q.s_eta = sqrt(max(ce*P*ce.', 0));
q.xs_sep = full(xs);
cs = zeros(1, E.na); cs(1:nf) = sel(E, ix.thn, E.wn.'/(E.x100n - E.x0n));
q.soc = (E.wn.'*x(ix.thn) - E.x0n)/(E.x100n - E.x0n); q.s_soc = sqrt(cs*P*cs.');
ct = zeros(1, E.na); ct(1:nf) = sel(E, ix.T, 1);
q.T = x(ix.T); q.s_T = sqrt(ct*P*ct.');
cl = zeros(1, E.na); cl(1:nf) = sel(E, ix.thn, -E.Qn*E.wn.') + sel(E, ix.thp, -E.Qp*E.wp.');
q.lli = E.Qli_bol - (E.Qn*E.wn.'*x(ix.thn) + E.Qp*E.wp.'*x(ix.thp)); q.s_lli = sqrt(cl*P*cl.');
q.rf = rf; q.s_rf = sqrt(P(end, end));
L0 = E.par.sei.L0; q.Lsei = rf*L0; q.s_Lsei = q.s_rf*L0;
q.z = z;
end

function r = sel(E, idx, w)
% dat hang trong so w (theo thu tu idx cua x) vao toa do bo loc E.fi
r = zeros(1, E.nf);
[tf, loc] = ismember(idx, E.fi);
if ~all(tf), error('ekf_outputs: chi so ngoai trang thai bo loc'); end
r(loc) = w;
end
