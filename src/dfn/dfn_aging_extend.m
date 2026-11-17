function ya = dfn_aging_extend(par0, y0, para)
%DFN_AGING_EXTEND  Chuyen trang thai cua DFN khong lao hoa (par0, y0) sang vector cua
% DFN co lao hoa (para = dfn_params(... 'aging', true) cung luoi), trang thai lao hoa BOL.
% Dung cho dfn_perm_loss.m khi trang thai dau den tu code khong bat lao hoa (vd. src/nmpc).
i0 = par0.ix; ia = para.ix;
assert(par0.grid.Nn == para.grid.Nn && par0.grid.Nrn == para.grid.Nrn && par0.grid.Np == para.grid.Np ...
    && par0.grid.Nrp == para.grid.Nrp && par0.grid.Ns == para.grid.Ns, 'dfn_aging_extend: luoi khac nhau');
ya = zeros(ia.ny, 1);
for nm = {'thn', 'thp', 'ce', 'T', 'Q', 'phisn', 'phisp', 'phie', 'jn', 'jp', 'H', 'I'}
    ya(ia.(nm{1})) = y0(i0.(nm{1}));
end
ya = dfn_aging_init(para, ya);
end
