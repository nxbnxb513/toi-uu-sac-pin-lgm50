function opt = rom_preset(name)
%ROM_PRESET  Cac cau hinh luoi ROM duoc so sanh voi DFN (rom_validate.m).
% So o / so vo tinh theo luoi DFN mac dinh [20 10 20 | 60 20] (dfn_params.m).
%   A: cuc am 4 o [9 6 4 1], vo am 8 (vo ngoai cung 2/60 R), duong 2 o, vo duong 4
%   B: nhu A, vo am 8 nhung day hon sat be mat (vo ngoai cung 1/60 R nhu DFN)
%   C: nhu B, cuc am 6 o [8 5 3 2 1 1]
%   D: nhu C, vo am 10 [0 20 30 38 44 49 53 56 58 59 60]
switch upper(name)
    case 'A'
        opt = struct();
    case 'B'
        opt = struct('shn', [0 24 36 44 50 54 57 59 60]);
    case 'C'
        opt = struct('shn', [0 24 36 44 50 54 57 59 60], 'cellsn', [8 5 3 2 1 1]);
    case 'D'
        opt = struct('shn', [0 20 30 38 44 49 53 56 58 59 60], 'cellsn', [8 5 3 2 1 1]);
    otherwise
        error('rom_preset: khong co cau hinh %s', name);
end
opt.name = upper(name);
end
