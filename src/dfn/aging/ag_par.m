function par = ag_par(expt, variant)
%AG_PAR  Bo tham so DFN + lao hoa "5 coupled" cho mo phong thi nghiem lao hoa Li 2025.
%   expt = 2 (70-85 %) hoac 3 (85-100 %); variant = 'default' | 'vcv42'
% Luoi [x_n, x_s, x_p, r_n, r_p]: Expt 2 [10, 10, 10, 100, 20], Expt 3 [10, 5, 5, 100, 20]
% - dung nhu cac lan chay cua tac gia (theo code: [ZD] cot "Mesh list"; GD-57).
% variant:
%   'default' : mac dinh du an, V_cv = 4.116 V (GD-43) cho moi buoc CV / nguong sac
%   'vcv42'   : bien the do nhay, V_cv = 4.2 V (ap giao thuc in trong Kirkaldy 2024 / Li 2025)
if nargin < 2 || isempty(variant), variant = 'default'; end
if expt == 2, gr = [10 10 10 100 20]; else, gr = [10 5 5 100 20]; end
opt = struct('aging', true, 'Nn', gr(1), 'Ns', gr(2), 'Np', gr(3), 'Nrn', gr(4), 'Nrp', gr(5));
switch variant
    case 'default'
    case 'vcv42', opt.V_cv = 4.2;
    otherwise, error('ag_par: variant khong hop le: %s', variant);
end
par = dfn_params(opt);
par.variant = variant;
end
