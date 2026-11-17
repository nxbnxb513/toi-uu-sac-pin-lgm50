function d = val_read_cell(fname)
%VAL_READ_CELL  Doc mot file CSV cua bo du lieu Zenodo 10.5281/zenodo.4864437
% (repo brosaplanella/TEC-reduced-model, thu muc data/, giay phep BSD-3).
% File co 15 dong tieu de, 1 dong ten cot, 1 dong don vi, roi du lieu; moi
% dong ket thuc bang dau phay.
% Tra ve: d.t [s], d.V [V], d.I [A, > 0 la SAC nhu trong file], d.Tcell [degC],
% d.Tamb [degC, NaN neu file khong co cam bien moi truong], d.status (cellstr),
% d.tstep [s], d.seg (cac doan xa, xem duoi).
txt = fileread(fname);
lines = regexp(txt, '\r?\n', 'split');
h = find(strncmp(lines, 'Step,Status', 11), 1);
if isempty(h), error('val_read_cell: khong tim thay dong ten cot trong %s', fname); end
names = strtrim(strsplit(lines{h}, ','));
names = names(~cellfun(@isempty, names));
nc = numel(names);
body = lines(h+2:end);
body = body(~cellfun(@isempty, body));
body = regexprep(body, ',\s*$', '');          % bo dau phay cuoi dong
istxt = ismember(names, {'Status', 'Procedure'});
fmt = '';
for i = 1:nc
    if istxt(i), fmt = [fmt '%s']; else, fmt = [fmt '%f']; end %#ok<AGROW>
end
C = textscan(strjoin(body, newline), fmt, 'Delimiter', ',', 'EmptyValue', NaN);
n = min(cellfun(@numel, C));
col = @(nm) C{strcmp(names, nm)}(1:n);
d.t = col('Prog Time'); d.tstep = col('Step Time');
d.V = col('Voltage'); d.I = col('Current');
d.status = C{strcmp(names, 'Status')}(1:n);
has = @(nm) any(strcmp(names, nm));
% Cam bien nhiet (theo tec_reduced_model/process_experimental_data.py):
%   co LogTempMid: cell = LogTempMid, moi truong = LogTemp001 (neu co)
%   khong:         cell = LogTemp001, moi truong = LogTemp002 (neu co)
d.Tamb = nan(n,1);
if has('LogTempMid')
    d.Tcell = col('LogTempMid');
    if has('LogTemp001'), d.Tamb = col('LogTemp001'); end
else
    d.Tcell = col('LogTemp001');
    if has('LogTemp002'), d.Tamb = col('LogTemp002'); end
end

% ---- cac doan xa (Status = DCH) va doan nghi (PAU) ngay sau ------------
isd = strcmp(d.status, 'DCH');
isp = strcmp(d.status, 'PAU');
ds = find(isd & ~[false; isd(1:end-1)]);      % dong dau cua moi doan xa
seg = struct('t', {}, 'V', {}, 'I', {}, 'T', {}, 'Vrest0', {}, 'T0', {}, 'Tamb0', {}, ...
             'tr', {}, 'Vr', {}, 'Tr', {}, 'cap', {}, 'Imean', {});
for k = 1:numel(ds)
    a = ds(k);
    b = a; while b < n && isd(b+1), b = b + 1; end
    if b - a < 5, continue; end
    p = find(isp(1:a-1), 1, 'last');           % mau nghi cuoi cung truoc khi xa
    if isempty(p), continue; end
    s.t = d.tstep(a:b); s.V = d.V(a:b); s.I = -d.I(a:b); s.T = d.Tcell(a:b);
    s.Vrest0 = d.V(p); s.T0 = d.Tcell(p); s.Tamb0 = d.Tamb(p);
    r1 = b + 1; r2 = b;
    while r2 < n && isp(r2+1), r2 = r2 + 1; end
    if r2 >= r1
        s.tr = d.tstep(r1:r2); s.Vr = d.V(r1:r2); s.Tr = d.Tcell(r1:r2);
    else
        s.tr = []; s.Vr = []; s.Tr = [];
    end
    % dong trung binh theo thoi gian va dung luong xa (tich phan hinh thang)
    s.cap = trapz(s.t, s.I)/3600;
    s.Imean = s.cap*3600/(s.t(end) - s.t(1));
    seg(end+1) = s; %#ok<AGROW>
end
d.seg = seg;
end
