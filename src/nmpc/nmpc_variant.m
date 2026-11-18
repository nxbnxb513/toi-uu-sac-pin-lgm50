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
    % --- so lan lap SQP / chi phi moi lan giai (18/11/2026, xem ket_qua_pilot_nmpc.md) ---
    % jr: dung lai Jacobian Newton cua IRK; wM: tu lan giai thu 2 (khoi dong nong tu
    % nghiem truoc) toi da M vong SQP. Lan giai dau van toi da 60 vong.
    case 'jr',    bo.jac_reuse = 1;
    case 'jrw5',  bo.jac_reuse = 1; bo.max_iter_warm = 5;
    case 'jrw2',  bo.jac_reuse = 1; bo.max_iter_warm = 2;
    case 'w5',    bo.max_iter_warm = 5;
    % pilot (chon 18/11/2026, GD-75): lan debug 44195329318 cho thay SQP dat nghiem sau
    % 3-4 vong (res_stat ~2e-4, res_eq ~3e-4 = san sai so cua IRK 2 nac x 8 buoc,
    % mo_hinh_rut_gon.md muc 8.4), 56 vong con lai chi bo tung buoc rat nho (alpha = 1).
    % => dung sai khop voi do chinh xac tich phan, lan giai lanh <= 15 vong, nong <= 4 vong.
    % (jac_reuse = 1 cho NaN o do nhay IRK ngay lan dau - khong dung.)
    case 'pilot', bo.max_iter = 15; bo.max_iter_warm = 4; bo.tol_stat = 2.5e-4; bo.tol_eq = 5e-4;
        bo.tol_ineq = 1e-6; bo.tol_comp = 1e-6;
    otherwise, error('nmpc_variant: bien the %s', variant);
end
fprintf('Bien the so hoc NMPC: %s\n', variant);
end
