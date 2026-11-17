function nmpc_init_guess(C, M, x0, z0, Ich0, tf_h, Tamb, Iguess)
%NMPC_INIT_GUESS  Doan dau cho SQP: mo phong ROM voi dong sac khong doi
% Iguess (tang tuyen tinh tu Ich0 trong khoang dau) tren t_f = tf_h gio,
% roi dat x, z, u cho moi nut. Neu ROM dung som (su kien), giu trang thai cuoi.
rom = C.rom; N = C.N;
tg = (0:N).'/N*3600*tf_h;
Ifun = @(t) -(Ich0 + (Iguess - Ich0)*min(t/tg(2), 1));
try
    r = rom_sim(M, rom, x0, z0, Ifun, Tamb, tg, struct('sat', false));
    Y = r.Y; tt = r.t;
catch
    Y = [x0(:); z0(:)]; tt = 0;
end
Ich = [Ich0; Iguess*ones(N, 1)];
for k = 0:N
    j = find(tt <= tg(k+1) + 1e-9, 1, 'last'); if isempty(j), j = 1; end
    X = [Y(1:rom.nx, j); Ich(k+1); tf_h];
    C.solver.set('x', X, k);
    if k < N
        C.solver.set('z', Y(rom.nx+1:end, j), k);
        C.solver.set('u', (Ich(k+2) - Ich(k+1))*N, k);
    end
end
end
