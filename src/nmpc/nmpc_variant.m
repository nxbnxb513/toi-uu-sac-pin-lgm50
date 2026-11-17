function bo = nmpc_variant(bo, variant)
%NMPC_VARIANT  Bien the cai dat SO HOC cua bo giai NMPC (khong doi mo hinh, tham
% so hay rang buoc). 'base' = cai dat mac dinh cua nmpc_build.m.
switch variant
    case {'base', 'sweep'}
    case 's4n12', bo.num_steps = 4; bo.newton_iter = 12;
    case 'tol',   bo.newton_iter = 20; bo.newton_tol = 1e-8;
    case 'tols16', bo.num_steps = 16; bo.newton_iter = 20; bo.newton_tol = 1e-8;
    case 'lm10',  bo.lm = 10;
    case 's4lm10', bo.num_steps = 4; bo.newton_iter = 12; bo.lm = 10;
    otherwise, error('nmpc_variant: bien the %s', variant);
end
fprintf('Bien the so hoc NMPC: %s\n', variant);
end
