function nmpc_qp_dump(C, info)
%NMPC_QP_DUMP  In du lieu QP cuoi cung cua lan giai acados vua xong (chan doan GD-86):
% moi nut: NaN/Inf trong A, B, b, Q, R, S, q, r, bien lbx/ubx/lbu/ubu/lg/ug, so cap
% lb > ub, so cap lb == ub (do rong 0), gia tri rieng nho nhat cua [Q S; S' R],
% trong so mem zl/zu/Zl/Zu; NaN trong lap (x, u, pi, lam, sl, su).
s = C.solver; N = C.N;
fprintf('nmpc_qp_dump: status %d, sqp %d\n', info.status, info.sqp_iter);
f = {'qp_A', 'qp_B', 'qp_b', 'qp_Q', 'qp_R', 'qp_S', 'qp_q', 'qp_r', 'qp_lbx', 'qp_ubx', 'qp_lbu', 'qp_ubu', ...
    'qp_C', 'qp_D', 'qp_lg', 'qp_ug', 'qp_zl', 'qp_zu', 'qp_Zl', 'qp_Zu', 'qp_idxb', 'qp_idxs'};
ok = true(size(f));
for k = 0:N
    D = struct();
    for i = 1:numel(f)
        if ~ok(i), continue; end
        try
            D.(f{i}) = s.get(f{i}, k);
        catch e
            if k == 0, fprintf('  (khong doc duoc %s: %s)\n', f{i}, strtok(e.message, newline)); end
            ok(i) = false;
        end
    end
    fn = fieldnames(D); bad = {};
    for i = 1:numel(fn)
        v = D.(fn{i}); if any(~isfinite(v(:))), bad{end+1} = sprintf('%s(%d)', fn{i}, nnz(~isfinite(v(:)))); end %#ok<AGROW>
    end
    ln = sprintf('  nut %2d: NaN/Inf: %s', k, strjoin(bad, ' '));
    pr = {'qp_lbx', 'qp_ubx'; 'qp_lbu', 'qp_ubu'; 'qp_lg', 'qp_ug'};
    for j = 1:3
        if isfield(D, pr{j, 1}) && isfield(D, pr{j, 2}) && ~isempty(D.(pr{j, 1}))
            lb = D.(pr{j, 1})(:); ub = D.(pr{j, 2})(:);
            if numel(lb) == numel(ub)
                w = ub - lb;
                ln = [ln, sprintf(' | %s: n %d, lb>ub %d, lb==ub %d, min(ub-lb) %.3g, lb [%s] ub [%s]', pr{j, 1}(4:end), numel(lb), ...
                    nnz(w < 0), nnz(w == 0), min(w), num2str(lb(1:min(end, 6)).', '%.3g '), num2str(ub(1:min(end, 6)).', '%.3g '))]; %#ok<AGROW>
            end
        end
    end
    if isfield(D, 'qp_Q') && isfield(D, 'qp_R') && isfield(D, 'qp_S') && ~isempty(D.qp_R)
        try
            S = D.qp_S; if size(S, 1) ~= size(D.qp_Q, 1), S = S.'; end
            H = [D.qp_Q, S; S.', D.qp_R]; H = (H + H.')/2;
            ln = [ln, sprintf(' | eig H [%.3g %.3g]', min(eig(H)), max(eig(H)))]; %#ok<AGROW>
        catch
        end
    elseif isfield(D, 'qp_Q')
        try, ln = [ln, sprintf(' | eig Q [%.3g %.3g]', min(eig((D.qp_Q + D.qp_Q.')/2)), max(eig((D.qp_Q + D.qp_Q.')/2)))]; catch, end %#ok<AGROW>
    end
    if isfield(D, 'qp_idxb'), ln = [ln, sprintf(' | idxb %s', mat2str(D.qp_idxb(:).'))]; end %#ok<AGROW>
    if isfield(D, 'qp_zl') && ~isempty(D.qp_zl), ln = [ln, sprintf(' | zl %s Zl %s', mat2str(D.qp_zl(:).', 3), mat2str(D.qp_Zl(:).', 3))]; end %#ok<AGROW>
    fprintf('%s\n', ln);
    if k == 0 || k == N
        if isfield(D, 'qp_q'), fprintf('    |q| max %.3g, |r| max %.3g, |b| max %.3g\n', max(abs(D.qp_q(:))), max(abs([D.qp_r(:); 0])), max(abs([D.qp_b(:); 0]))); end
    end
end
it = {'x', 'u', 'pi', 'lam', 'sl', 'su', 't'};
ln = '  lap: ';
for i = 1:numel(it)
    try
        v = s.get(it{i}); ln = [ln, sprintf('%s NaN %d max|.| %.3g; ', it{i}, nnz(~isfinite(v(:))), max(abs(v(:))))]; %#ok<AGROW>
    catch
        ln = [ln, sprintf('%s (khong doc); ', it{i})]; %#ok<AGROW>
    end
end
fprintf('%s\n', ln);
end
