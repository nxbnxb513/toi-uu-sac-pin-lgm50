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
    % pilot (chon 18/11/2026, GD-80): lan debug 44195329318 cho thay SQP dat nghiem sau
    % 3-4 vong (res_stat ~2e-4, res_eq ~3e-4 = san sai so cua IRK 2 nac x 8 buoc,
    % mo_hinh_rut_gon.md muc 8.4), 56 vong con lai chi bo tung buoc rat nho (alpha = 1).
    % => dung sai khop voi do chinh xac tich phan, lan giai lanh <= 15 vong, nong <= 4 vong.
    % (jac_reuse = 1 cho NaN o do nhay IRK ngay lan dau - khong dung.)
    case 'pilot', bo.max_iter = 15; bo.max_iter_warm = 4; bo.tol_stat = 2.5e-4; bo.tol_eq = 5e-4;
        bo.tol_ineq = 1e-6; bo.tol_comp = 1e-6;
        % GD-86: I_ch nut 0 la dang thuc, dong dau co dinh = dong dau cua doan dau CCCV
        bo.eqI0 = true; bo.free_I0 = false;
    % 18/11/2026 (sau run 44230426135): thu LM lon hon / trong so cu khi lan giai dau NaN
    case {'pilot_lm1', 'pilot_lm10', 'pilot_wold', 'pilot_lm1_wold', 'pilot_fix0', 'pilot_wold_fix0'}
        bo = nmpc_variant(bo, 'pilot');
        bo.eqI0 = false; bo.free_I0 = ~contains(variant, 'fix0');   % trang thai cua 81a1682
        if contains(variant, 'lm10'), bo.lm = 10; elseif contains(variant, 'lm1'), bo.lm = 1; end
        if contains(variant, 'wold'), bo.w_loss_scale = 0.1; end   % ~ w_loss = 10 /mAh cu (muc tieu ~0.1)
    otherwise
        % chia doi tim loi (GD-86): 'pilot+tok1+tok2...' - moi tok hoan lai MOT thay doi
        tk = strsplit(variant, '+');
        if numel(tk) < 2, error('nmpc_variant: bien the %s', variant); end
        bo = nmpc_variant(bo, tk{1});
        for i = 2:numel(tk)
            switch tk{i}
                case 'neq',     bo.eqI0 = false;            % I_ch nut 0 khong la dang thuc (81a1682)
                case 'free',    bo.free_I0 = true;          % lan giai dau: I_ch nut 0 tu do (9d7815b/81a1682)
                case 'ramp',    bo.guess_mode = 'ramp';     % doan dau cu: I = 0 doc len (ae443c1)
                case 'noshift', bo.shift = false;           % khong dich nghiem: giu nghiem acados lam doan dau
                case 'novb',    bo.vb_on = false;           % bo lech dien ap do duoc (tham so 9 = 0)
                case 'wabs',    bo.w_abs = 10;              % trong so cu w_loss = 10 /mAh (khong chuan hoa)
                case 'socr',    bo.soc_rom = false;         % SOC dich du bao = SOC dich (khong lay SOC ROM dat)
                case 'qd',      bo.qp_dump = 2;             % in du lieu QP 2 lan giai dau
                case 'irk',     bo.irk_probe = true;        % tich phan lai nut 0 bang ban sao IRK khi that bai
                case 's16',     bo.num_steps = 16;          % 16 buoc IRK moi khoang
                otherwise
                    if startsWith(tk{i}, 'f') && ~isnan(str2double(tk{i}(2:end)))
                        % 'f32': khoang dau 32 buoc IRK, cac khoang sau giu so buoc mac dinh
                        ns = 8; if isfield(bo, 'num_steps'), ns = bo.num_steps(end); end
                        bo.num_steps = [str2double(tk{i}(2:end)), ns*ones(1, bo.N - 1)];
                        continue
                    end
                    if startsWith(tk{i}, 'h') && ~isnan(str2double(tk{i}(2:end)))
                        bo.steps_hI = str2double(tk{i}(2:end));   % 'h18': dien tich nap toi da moi buoc IRK 18 A s (GD-87)
                        continue
                    end
                    if startsWith(tk{i}, 'n'), bo.max_solves = str2double(tk{i}(2:end));   % 'n8': dung sau 8 lan giai
                    else, error('nmpc_variant: tok %s', tk{i}); end
            end
        end
end
fprintf('Bien the so hoc NMPC: %s\n', variant);
end
