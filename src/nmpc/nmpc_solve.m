function [plan, info] = nmpc_solve(C, xhat, Ich, prm, tfband, free0)
%NMPC_SOLVE  Mot lan giai NMPC tu UOC LUONG trang thai xhat (trang thai ROM).
% Giao dien danh cho ca hai bien the: "biet het trang thai" (xhat = anh xa
% cua trang thai DFN, rom_from_dfn.m) va "NMPC + EKF" (buoc F: xhat = uoc
% luong cua EKF tu I, V, T do duoc) - bo dieu khien chi nhin thay xhat.
%   Ich: dong sac dang ap [A, >= 0];  prm: vector tham so acados (nmpc_build.m)
% plan.slope [A/s]: dong sac ke hoach tren khoang dau  I_ch(t) = Ich + slope t,
% plan.dt1 [s] do dai khoang dau, plan.tf_h thoi gian con lai toi uu [h],
% plan.loss_pred [mAh] lithium mat VINH VIEN du doan (SEI + chet) cho phan sac con lai.
% tfband = [lo hi] (gio): vung tin cay cho t_f trong lan giai nay (bien cung).
% Ly do: ham muc tieu gan tuyen tinh theo t_f nen buoc SQP co the nhay t_f ra
% bien va lam bo tich phan phan ky.
% Vong kin dich vung nay theo nghiem (nmpc_closed_loop.m).
s = C.solver;
for k = 1:C.N
    s.set('constr_lbx', [0; tfband(1)], k);
    s.set('constr_ubx', [C.opt.Imax; tfband(2)], k);
end
if nargin < 6, free0 = false; end
if free0
    % lan giai DAU (chua co dong nao duoc ap): dong sac tai nut 0 tu do trong [0, I_max]
    % de bo sac co the bat dau ngay o dong bat ky nhu CCCV, khong bi buoc doc tu I = 0 (GD-82)
    s.set('constr_lbx', [xhat(:); 0], 0); s.set('constr_ubx', [xhat(:); C.opt.Imax], 0);
else
    s.set('constr_x0', [xhat(:); Ich]);
end
for k = 0:C.N, s.set('p', prm(:), k); end
tw = tic; s.solve(); info.wall = toc(tw);
info.status = s.get('status');
info.sqp_iter = s.get('sqp_iter');
info.time_tot = s.get('time_tot');
% phan bo thoi gian (s): tuyen tinh hoa (gom tich phan + do nhay), rieng tich phan, QP, tim kiem duong
tf_ = {'time_lin', 'time_sim', 'time_qp', 'time_glob'};
for i = 1:numel(tf_)
    try, info.(tf_{i}) = s.get(tf_{i}); catch, info.(tf_{i}) = NaN; end
end
X0 = s.get('x', 0); XN = s.get('x', C.N);
u0 = s.get('u', 0);
plan.tf_h = X0(C.itf);
plan.dt1 = 3600*plan.tf_h/C.N;
plan.slope = u0/(3600*plan.tf_h);
plan.I0 = X0(C.iI);                  % = Ich, tru lan giai dau (free0)
plan.I1 = plan.I0 + u0/C.N;
% quy dao du bao (de dich lam doan dau cho lan giai sau, nmpc_closed_loop.m)
plan.Inodes = zeros(C.N + 1, 1);
for k = 0:C.N, xk = s.get('x', k); plan.Inodes(k+1) = xk(C.iI); end
rom = C.rom;
plan.loss_pred = XN(rom.ix.nsei) + XN(rom.ix.ndl);            % mat vinh vien du doan (mAh)
plan.pl_pred = XN(rom.ix.npl);                                 % lithium ma du doan cuoi (chan doan)
plan.soc_end = XN(rom.ix.soc);
plan.at_edge = abs(plan.tf_h - tfband(1)) < 1e-4*tfband(1) || abs(plan.tf_h - tfband(2)) < 1e-4*tfband(2);
plan.ok = any(info.status == [0 2]) && all(isfinite([plan.tf_h, plan.slope, plan.loss_pred])) && plan.tf_h > 0;
end
