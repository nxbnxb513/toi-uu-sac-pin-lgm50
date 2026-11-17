function [par, desc, start] = diag_variant(name)
%DIAG_VARIANT  Bo tham so cho mot bien the chan doan GD-16 (bao hoa be mat hat
% cuc am khi sac). Moi bien the doi DUNG MOT thu so voi 'base' (bo mac dinh cua
% dfn_params). CHI DUNG DE CHAN DOAN: khong phai bo tham so de xuat.
%   start = 'balance' : 0 % SOC = x0 cuc am, cuc duong tren duong can bang
%                       lithium di qua diem 100 % (x100, y100) (GD-13)
%           'y0'      : (x0, y0) cua Li 2025 SI Note 8 (nhu val_selftest)
start = 'balance';
opt = struct();
switch name
    case 'base',        desc = 'bo mac dinh cua dfn_params';
    case 'src_paper',   opt.src = 'paper'; desc = 'src=paper (he so dien giai nhu SI in: 0.8353, -0.612)';
    case 'src_code',    opt.src = 'code';  desc = 'src=code (Landesfeind: 0.353, -6.12)';
    case 'no_stress',   opt.stress_diffusion = false; desc = 'tat khuech tan do ung suat (GD-10)';
    case 'EDs_6e4',     opt.E_Ds_n = 6e4; desc = 'E_act D_s,n = 6e4 J/mol (GD-01, cot SEI only)';
    case 'grid_fine',   opt = struct('Nn', 40, 'Ns', 20, 'Np', 40, 'Nrn', 200, 'Nrp', 60); desc = 'luoi min [40 20 40 | 200 60]';
    case 'grid_li',     opt = struct('Nn', 10, 'Ns', 5, 'Np', 5, 'Nrn', 100, 'Nrp', 20); desc = 'luoi Li 2025 [10 5 5 | 100 20]';
    otherwise,          desc = '';
end
par = dfn_params(opt);
switch name
    case {'Dx2', 'Dx5', 'Dx10', 'Dx30'}
        k = str2double(name(3:end));
        par.neg.Ds.Rcor = par.neg.Ds.Rcor*k; par.neg = dfn_Ktable(par.neg);
        desc = sprintf('D_s,n x %g (chi de chan doan)', k);
    case 'Dconst'
        % Chen 2020 Table IX / O'Kane 2022 Table S2: D_s,n = 3.3e-14 m2/s (hang so)
        par.neg.Ds.a = [0 0 0 0 0]; par.neg.Ds.b(1) = log10(3.3e-14); par.neg.Ds.Rcor = 1;
        par.neg = dfn_Ktable(par.neg);
        desc = 'D_s,n = 3.3e-14 m2/s hang so (Chen 2020 T.IX, O''Kane 2022 T.S2), giu E_act va ung suat';
    case 'hys_delith'
        par.hys.offset = 1e4;  desc = 'luon dung nhanh delithiation cuc am (m = 1) ca khi sac';
    case 'hys_lith'
        par.hys.offset = -1e4; desc = 'luon dung nhanh lithiation cuc am (m = 0) ca khi nghi';
    case 'no_film'
        par.sei.rho = 0; desc = 'bo dien tro mang SEI (rho_SEI = 0)';
    case 'j0n_x10'
        par.neg.j0_ref = 10*par.neg.j0_ref; desc = 'j0,n x 10';
    case 'brug0'
        par.neg.brug_e = 0; par.sep.brug_e = 0; par.pos.brug_e = 0;
        desc = 'Bruggeman dien giai = 0 (van chuyen dien giai nhanh ~5-10x)';
    case 'start_y0'
        start = 'y0'; desc = 'bat dau tai (x0, y0) cua Li 2025 thay vi duong can bang';
    case {'base', 'src_paper', 'src_code', 'no_stress', 'EDs_6e4', 'grid_fine', 'grid_li'}
    otherwise
        error('diag_variant: bien the khong ro: %s', name);
end
desc = sprintf('%s [src=%s]', desc, par.src);
end
