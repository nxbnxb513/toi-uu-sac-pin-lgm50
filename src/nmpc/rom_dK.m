function dK = rom_dK(el, a, b, T, par, gl)
%ROM_DK  Hieu tich phan Kirchhoff  K(b) - K(a) = int_a^b D_eff(s, T) ds  [m2/s]
% bang cau phuong Gauss-Legendre (gl.s nut tren [0, 1], gl.w trong so).
% D_eff lay tu CHINH ham DFN src/dfn/dfn_Ds.m (Li 2025 SI pt. S17-S18, he so
% Table 7, khuech tan do ung suat GD-10). DFN dung bang K(x) noi suy pchip
% (dfn_Ktable.m, GD-15); ROM can bieu thuc ky hieu tron nen tinh truc tiep
% tich phan. Ca hai la cung mot dai luong: thong luong giua hai vo = dK/dr.
% Diem cau phuong duoc chan TRON vao [-0.5, 1.5] truoc khi goi dfn_Ds (ngoai
% xa [0, 1] - chi gap khi bo giai thu diem lap xa; 10^(...) cua D_s khong tran so).
dK = 0;
for q = 1:numel(gl.w)
    s = a + (b - a)*gl.s(q);
    s = rom_smin(rom_smax(s, -0.5, 1e-4), 1.5, 1e-4);
    dK = dK + gl.w(q)*dfn_Ds(el, s, T, par);
end
dK = (b - a).*dK;
end
