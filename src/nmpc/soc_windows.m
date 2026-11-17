function W = soc_windows()
%SOC_WINDOWS  Luoi vung sac (nguoi dung chot 17/11/2026): buoc 20 %, 15 vung
% [SOC dau, SOC cuoi] theo thu tu 0->20, 0->40, 0->60, 0->80, 0->100, 20->40, ...,
% 80->100 (chi so: 3 = 0->60, 8 = 20->80, 12 = 40->100).
W = zeros(0, 2);
for a = 0:4
    for b = a+1:5
        W(end+1, :) = [a b]/5; %#ok<AGROW>
    end
end
end
