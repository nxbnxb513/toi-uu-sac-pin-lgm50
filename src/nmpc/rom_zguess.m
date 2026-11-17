function zg = rom_zguess(rom, par, x, I, Tamb) %#ok<INUSD>
%ROM_ZGUESS  Doan dau cho bien dai so z cua ROM, chi tu x va I (dung lam diem
% bat dau cua Newton trong mo hinh da khu z, rom_elim.m): phan ung deu trong
% moi dien cuc, phi_e o o dau = -U_n, phi_s o o dau cuc duong = U_p - U_n
% (OCP tai be mat hat o dau moi dien cuc, cung ham rom_ocp/dfn_ocp_mix).
ix = rom.ix; iapp = I/par.A;
tn = x(ix.thn(rom.Nrn-1:rom.Nrn)); tp = x(ix.thp(rom.Nrp-1:rom.Nrp));
xn = tn(2) + rom.cextn*(tn(2) - tn(1)); xp = tp(2) + rom.cextp*(tp(2) - tp(1));
xn = rom_smin(rom_smax(xn, 1e-6, 1e-7), 1 - 1e-6, 1e-7);
xp = rom_smin(rom_smax(xp, 1e-6, 1e-7), 1 - 1e-6, 1e-7);
[Un, Up] = rom_ocp(par, xn, xp, iapp, x(ix.T));
zg = [iapp/(rom.as_n*par.neg.L)*ones(rom.Nn, 1); -iapp/(rom.as_p*par.pos.L)*ones(rom.Np, 1); -Un; Up - Un];
end
