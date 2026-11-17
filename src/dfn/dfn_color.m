function grp = dfn_color(S)
%DFN_COLOR  To mau tham lam cac cot cua mau thua S: hai cot cung mau khong
% co hang chung, nen mot lan danh gia ham cho duoc nhieu cot Jacobian.
% grp(j) = chi so mau cua cot j.
n = size(S, 2);
Cg = (S.'*S) ~= 0;
grp = zeros(n, 1);
for j = 1:n
    used = grp(Cg(:, j));
    used = used(used > 0);
    k = 1;
    if ~isempty(used)
        mask = false(max(used) + 1, 1);
        mask(used) = true;
        k = find(~mask, 1);
    end
    grp(j) = k;
end
end
