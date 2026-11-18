function par = ag_par(expt, variant)
%AG_PAR  Bo tham so DFN + lao hoa "5 coupled" cho mo phong thi nghiem lao hoa Li 2025.
%   expt = 2 (70-85 %), 3 (85-100 %); 1 (0-30 %), 5 (0-100 %) (Kirkaldy 2024, buoc D)
%   variant = 'default' | 'vcv42' | 'si' | 'si<form>_k<k>'
% Luoi [x_n, x_s, x_p, r_n, r_p]: Expt 2 [10, 10, 10, 100, 20], Expt 3 [10, 5, 5, 100, 20]
% - dung nhu cac lan chay cua tac gia (theo code: [ZD] cot "Mesh list"; GD-57).
% Expt 1, 5: luoi cua Expt 3 (tac gia khong chay Expt 1/5 voi "5 coupled"; GD-94).
% variant:
%   'default' : mac dinh du an, V_cv = 4.116 V (GD-43) cho moi buoc CV / nguong sac (TANG 1)
%   'vcv42'   : bien the do nhay, V_cv = 4.2 V (ap giao thuc in trong Kirkaldy 2024 / Li 2025)
%   'si'      : TANG 2 (lao hoa silicon, GIA DINH) voi tham so da hieu chinh (dfn_si_params.m)
%   'si<F>_k<k>' : TANG 2, dang F (A|B|C) va hang so k cho truoc (vd. 'siB_k3e-14'; hieu chinh GD-93)
if nargin < 2 || isempty(variant), variant = 'default'; end
if expt == 2, gr = [10 10 10 100 20]; else, gr = [10 5 5 100 20]; end
opt = struct('aging', true, 'Nn', gr(1), 'Ns', gr(2), 'Np', gr(3), 'Nrn', gr(4), 'Nrp', gr(5));
switch variant
    case 'default'
    case 'vcv42', opt.V_cv = 4.2;
    case 'si', opt.si = true;
    otherwise
        t = regexp(variant, '^si([ABC])_k([0-9.]+e-?[0-9]+)$', 'tokens', 'once');
        if isempty(t), error('ag_par: variant khong hop le: %s', variant); end
        opt.si = struct('form', t{1}, 'k', str2double(t{2}));
end
par = dfn_params(opt);
par.variant = variant;
end
