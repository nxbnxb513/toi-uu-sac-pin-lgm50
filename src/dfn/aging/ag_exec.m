function [y, o, ok] = ag_exec(par, y, steps)
%AG_EXEC  Chay chuoi buoc bang dfn_run; khong nem loi (ok = false neu khoi tao/giai that bai).
ok = true;
try
    o = dfn_run(par, y, steps);
    y = o.y_end;
    if any(strcmp(o.reason, 'solver_failed')), ok = false; end
catch err
    fprintf('ag_exec: LOI %s\n', err.message);
    o = struct('reason', {{'error'}}, 't', 0, 'V', NaN, 'I', NaN, 'T', NaN, 'Q', NaN, 'step', 0);
    ok = false;
end
end
