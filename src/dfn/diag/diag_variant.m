function [par, desc, start] = diag_variant(name)
%DIAG_VARIANT  Bo tham so cho mot bien the chan doan GD-16 (bao hoa be mat hat
% cuc am khi sac). Moi bien the doi DUNG MOT thu so voi 'base' (bo approved CU =
% dfn_params(struct('ocp_n_branch', 'hyst'))), tru cac bien the moi ghi duoi day. CHI DUNG DE CHAN DOAN: khong phai bo tham so de xuat.
%   start = 'balance' : 0 % SOC = x0 cuc am, cuc duong tren duong can bang
%                       lithium di qua diem 100 % (x100, y100) (GD-13)
%           'y0'      : (x0, y0) cua Li 2025 SI Note 8 (nhu val_selftest)
start = 'balance';
% Cac bien the cu (truoc 17/11/2026) doi MOT thu so voi bo approved CU, tuc cuc am con
% hysteresis (ocp_n_branch = 'hyst'); giu nguyen de tai lap. Bien the moi (muc A-C da duyet):
%   'new'          : bo mac dinh moi cua du an (cuc am luon nhanh delithiation, x100 = 0.8771)
%   'val_new'      : approved moi nhu dung trong kiem chung (cuc am delith + x100 = 0.9014)
%   'val_new_both' : val_new + cuc duong cung luon nhanh xa (khong hysteresis ca hai cuc)
%   'base'         : approved CU (hysteresis cuc am, x100 = 0.8771) - de so sanh
opt = struct('ocp_n_branch', 'hyst');
switch name
    case {'new', 'val_new', 'val_new_both'}
        opt.ocp_n_branch = 'delith'; desc = 'cuc am luon nhanh delithiation (GD-40, mac dinh moi)';
    case 'base',        desc = 'bo approved CU (hysteresis cuc am, ocp_n_branch = hyst)';
    case 'src_paper',   opt.src = 'paper'; desc = 'src=paper (he so dien giai nhu SI in: 0.8353, -0.612)';
    case 'src_code',    opt.src = 'code';  desc = 'src=code (Landesfeind: 0.353, -6.12)';
    case 'no_stress',   opt.stress_diffusion = false; desc = 'tat khuech tan do ung suat (GD-10)';
    case 'EDs_6e4',     opt.E_Ds_n = 6e4; desc = 'E_act D_s,n = 6e4 J/mol (GD-01, cot SEI only)';
    case 'grid_fine',   opt = struct('Nn', 40, 'Ns', 20, 'Np', 40, 'Nrn', 200, 'Nrp', 60, 'ocp_n_branch', 'hyst'); desc = 'luoi min [40 20 40 | 200 60]';
    case 'grid_li',     opt = struct('Nn', 10, 'Ns', 5, 'Np', 5, 'Nrn', 100, 'Nrp', 20, 'ocp_n_branch', 'hyst'); desc = 'luoi Li 2025 [10 5 5 | 100 20]';
    case 'no_tdf',      opt.use_tdf = false; desc = 'bo thermodynamic factor (GD-18)';
    case 'Rc17',        opt.Rcontact = 17e-3; desc = 'R_contact = 17 mOhm (11.5 + ~5.5 mOhm thieu o buoc nhay ap 1 s khi bat dau xa, du lieu mo 25 C) - chi chan doan';
    case 'Rc0',         opt.Rcontact = 0; desc = 'R_contact = 0 (SI Table 2 in V = phi_p - phi_n, khong co R_0; GD-20)';
    otherwise,          desc = '';
end
par = dfn_params(opt);
switch name
    case {'Dx2', 'Dx3', 'Dx5', 'Dx10', 'Dx30'}
        k = str2double(name(3:end));
        par.neg.Ds.Rcor = par.neg.Ds.Rcor*k; par.neg = dfn_Ktable(par.neg);
        desc = sprintf('D_s,n x %g (chi de chan doan)', k);
    case 'Dconst'
        % Chen 2020 Table IX / O'Kane 2022 Table S2: D_s,n = 3.3e-14 m2/s (hang so)
        par.neg.Ds.a = [0 0 0 0 0]; par.neg.Ds.b(1) = log10(3.3e-14); par.neg.Ds.Rcor = 1;
        par.neg = dfn_Ktable(par.neg);
        desc = 'D_s,n = 3.3e-14 m2/s hang so (Chen 2020 T.IX, O''Kane 2022 T.S2), giu E_act va ung suat';
    case 'fit_clamp'
        % Ung vien B: ham (S17) x R_cor nhu in, nhung chi dung trong khoang x co so
        % lieu GITT tho cua O'Regan (data/derived/B_diffusivity.csv, cuc am, moi
        % nhiet do: x = 0.0085-0.9914); ngoai khoang giu hang so (gia tri tai mep).
        % Luu y: dfn_Ds (chi dung de in bao cao) van tinh theo ham goc.
        par.neg = diag_Ktable(par.neg, 0.0084693, 0.99138);
        desc = 'D_s,n (S17) chi trong khoang x co so lieu tho [0.0085, 0.9914], hang so ngoai khoang';
    case 'ocp_end'
        % CHI CHAN DOAN: them vao U_n (ca hai nhanh) so hang (RT/F) ln((1-x)/(1-x+0.01)),
        % ~0 khi x < 0.95, -> -inf khi x -> 1 (diem ky di "het cho" o x = 1 ma ham (S3)
        % khong co). Thuc hien bang ban dfn_ocp_neg.m rieng trong diag/ocp_end/.
        addpath(fullfile(fileparts(mfilename('fullpath')), 'ocp_end'));
        desc = 'U_n + (RT/F) ln((1-x)/(1-x+0.01)) - chi de chan doan';
    case {'kap_x3', 'De_x10'}
        % CHI CHAN DOAN: ban dfn_elyte.m rieng trong diag/elyte_scale/ nhan kappa / D_e
        addpath(fullfile(fileparts(mfilename('fullpath')), 'elyte_scale'));
        par.diag.kfac = 1; par.diag.Dfac = 1;
        if strcmp(name, 'kap_x3'), par.diag.kfac = 3; else, par.diag.Dfac = 10; end
        desc = sprintf('kappa x %g, D_e x %g (chi de chan doan)', par.diag.kfac, par.diag.Dfac);
    case 'brug_n0'
        par.neg.brug_e = 0; desc = 'Bruggeman dien giai cuc am = 0 (chi cuc am)';
    case 'brug_s0'
        par.sep.brug_e = 0; desc = 'Bruggeman mang ngan = 0 (chi mang ngan)';
    case 'j0n_chen'
        % Chen 2020: k_n = 6.48e-7 -> j0,n(x = 0.5, 1 M, 25 C) ~ 0.30 A/m2; Li 2025 (S27): 1.33 A/m2
        par.neg.j0_ref = 0.228*par.neg.j0_ref; desc = 'j0,n x 0.228 (~ muc cua Chen 2020 tai x = 0.5)';
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
    case {'pos_lith', 'pos_delith', 'neg_lith', 'neg_delith'}
        % CHI CHAN DOAN: mot dien cuc luon dung mot nhanh OCP (ban dfn_ocp_*.m rieng
        % trong diag/<ten bien the>/); dien cuc kia giu hysteresis (S46)-(S47).
        addpath(fullfile(fileparts(mfilename('fullpath')), name));
        nm = struct('pos_lith', 'cuc duong luon nhanh lithiation (S1) ca khi sac', ...
                    'pos_delith', 'cuc duong luon nhanh delithiation (S2) ca khi xa/nghi', ...
                    'neg_lith', 'cuc am luon nhanh lithiation (S3) ca khi xa/nghi', ...
                    'neg_delith', 'cuc am luon nhanh delithiation (S4) ca khi sac');
        desc = nm.(name);
    case 'isoT'
        % CHI CHAN DOAN: dang nhiet (T = T moi truong) bang h rat lon (x 1e3)
        par.th.hA_V = 1e3*par.th.hA_V; desc = 'dang nhiet: h x 1000 (T cell ~ T moi truong)';
    case 'x100_fresh'
        % Li 2025 SI Note 8 (tr. 46-47): can bang 5 Ah "fresh" voi x100 = 0.9014 (Chen 2020
        % tr. 13); Li 2025 ha xuong 0.8771 cho cell LG M50T cua Kirkaldy (4.865 Ah).
        par.neg.x100 = par.val.x100_fresh; desc = 'duong can bang lithium qua x100 = 0.9014 (can bang 5 Ah, Li SI Note 8 / Chen 2020)';
    case 'new'
    case 'val_new'
        par.neg.x100 = par.val.x100_fresh;
        desc = [desc ' + x100 = 0.9014 cho cell kiem chung (GD-42)'];
    case 'val_new_both'
        par.neg.x100 = par.val.x100_fresh; par.hys.offset = 1e4;
        desc = [desc ' + x100 = 0.9014 + cuc duong cung luon nhanh xa (m = 1)'];
    case 'start_y0'
        start = 'y0'; desc = 'bat dau tai (x0, y0) cua Li 2025 thay vi duong can bang';
    case {'base', 'src_paper', 'src_code', 'no_stress', 'EDs_6e4', 'grid_fine', 'grid_li', 'no_tdf', 'Rc0', 'Rc17'}
    otherwise
        error('diag_variant: bien the khong ro: %s', name);
end
desc = sprintf('%s [src=%s]', desc, par.src);
end
