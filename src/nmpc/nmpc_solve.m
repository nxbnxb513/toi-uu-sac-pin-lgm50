function [plan, info] = nmpc_solve(C, xhat, Ich, prm, tfband)
%NMPC_SOLVE  Mot lan giai NMPC tu UOC LUONG trang thai xhat (trang thai ROM).
% Giao dien danh cho ca hai bien the: "biet het trang thai" (xhat = anh xa
% cua trang thai DFN, rom_from_dfn.m) va "NMPC + EKF" (buoc F: xhat = uoc
% luong cua EKF tu I, V, T do duoc) - bo dieu khien chi nhin thay xhat.
%   Ich: dong sac dang ap [A, >= 0];  prm: vector tham so acados (nmpc_build.m)
% plan.slope [A/s]: dong sac ke hoach tren khoang dau  I_ch(t) = Ich + slope t,
% plan.dt1 [s] do dai khoang dau, plan.tf_h thoi gian con lai toi uu [h],
% plan.loss_pred [mAh] lithium mat du doan cho phan sac con lai.
% tfband = [lo hi] (gio): vung tin cay cho t_f trong lan giai nay (bien cung).
% Ly do: acados v0.6 khong cho tim kiem duong (merit line search) khi rang buoc
% phi tuyen phu thuoc bien dai so z; ham muc tieu gan tuyen tinh theo t_f nen
% buoc SQP day du co the nhay t_f ra bien va lam bo tich phan phan ky.
% Vong kin dich vung nay theo nghiem (nmpc_closed_loop.m).
s = C.solver;
for k = 1:C.N
    s.set('constr_lbx', [0; tfband(1)], k);
    s.set('constr_ubx', [C.opt.Imax; tfband(2)], k);
end
s.set('constr_x0', [xhat(:); Ich]);
for k = 0:C.N, s.set('p', prm(:), k); end
tw = tic; s.solve(); info.wall = toc(tw);
info.status = s.get('status');
info.sqp_iter = s.get('sqp_iter');
info.time_tot = s.get('time_tot');
X0 = s.get('x', 0); XN = s.get('x', C.N);
u0 = s.get('u', 0);
plan.tf_h = X0(C.itf);
plan.dt1 = 3600*plan.tf_h/C.N;
plan.slope = u0/(3600*plan.tf_h);
plan.I1 = Ich + u0/C.N;
rom = C.rom;
plan.loss_pred = XN(rom.ix.nsei) + XN(rom.ix.npl) - xhat(rom.ix.npl);
plan.soc_end = XN(rom.ix.soc);
plan.at_edge = abs(plan.tf_h - tfband(1)) < 1e-4*tfband(1) || abs(plan.tf_h - tfband(2)) < 1e-4*tfband(2);
plan.ok = any(info.status == [0 2]) && all(isfinite([plan.tf_h, plan.slope, plan.loss_pred])) && plan.tf_h > 0;
end
