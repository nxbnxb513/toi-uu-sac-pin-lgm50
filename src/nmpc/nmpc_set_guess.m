function nmpc_set_guess(C, P, tshift, tf_h)
%NMPC_SET_GUESS  Dat doan dau cho SQP tu mot quy dao ROM P (P.t [s], P.X (nx x nt),
% P.I dong SAC [A] tai P.t): nut k cua luoi du bao (thoi gian chuan hoa) ung voi
% thoi diem tshift + k t_f/N cua P; trang thai va dong noi suy tuyen tinh, giu gia
% tri cuoi neu vuot qua P. t_f = tf_h [h]. u_k = N (I_{k+1} - I_k).
% Thay cho nmpc_init_guess.m (dong khong doi + doc tuyen tinh tu I = 0): doan dau
% bay gio la duong CCCV (an toan) hoac nghiem truoc dich theo thoi gian (GD-82).
N = C.N; nx = C.rom.nx;
tn = tshift + (0:N).'/N*3600*tf_h;
tn = min(max(tn, P.t(1)), P.t(end));
if numel(P.t) < 2
    Xn = repmat(P.X(:, 1).', N + 1, 1); In = P.I(1)*ones(N + 1, 1);
else
    Xn = interp1(P.t, P.X.', tn, 'linear');
    In = interp1(P.t, P.I(1:numel(P.t)), tn, 'linear');
end
In = min(max(In, 0), C.opt.Imax);
for k = 0:N
    C.solver.set('x', [Xn(k+1, 1:nx).'; In(k+1); tf_h], k);
    if k < N
        C.solver.set('xdot', zeros(nx + 2, 1), k);   % xoa doan dau dao ham cu (co the NaN sau that bai)
        C.solver.set('u', (In(k+2) - In(k+1))*N, k);
    end
end
end
