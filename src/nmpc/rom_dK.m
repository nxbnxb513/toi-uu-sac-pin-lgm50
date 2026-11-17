function dK = rom_dK(el, a, b, T, par, gl)
%ROM_DK  Hieu tich phan Kirchhoff  K(b) - K(a) = int_a^b D_eff(s, T) ds  [m2/s]
% bang cau phuong Gauss-Legendre (gl.s nut tren [0, 1], gl.w trong so).
% D_eff lay tu CHINH ham DFN src/dfn/dfn_Ds.m (Li 2025 SI pt. S17-S18, he so
% Table 7, khuech tan do ung suat GD-10). DFN dung bang K(x) noi suy pchip
% (dfn_Ktable.m, GD-15); ROM can bieu thuc ky hieu tron nen tinh truc tiep
% tich phan. Ca hai la cung mot dai luong: thong luong giua hai vo = dK/dr.
dK = 0;
for q = 1:numel(gl.w)
    dK = dK + gl.w(q)*dfn_Ds(el, a + (b - a)*gl.s(q), T, par);
end
dK = (b - a).*dK;
end
