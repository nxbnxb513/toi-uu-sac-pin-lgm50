function z = ekf_solve_z(E, x, I, Ta, rf)
%EKF_SOLVE_Z  Bien dai so z cua ROM (mat do dong moi o, hai moc the) tai (x, I,
% Ta, rf): Newton co tat dan cua src/nmpc/rom_solve_z.m, doan dau rom_zguess.m.
zg = full(E.ZG(x, I, Ta));
[z, ok, res] = rom_solve_z(E.M, x, I, [Ta; rf], zg);
if ~ok
    error('ekf_solve_z: khong giai duoc rang buoc dai so (du %.2e)', res);
end
end
