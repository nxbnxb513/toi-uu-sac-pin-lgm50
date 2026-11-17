# Kết quả trích xuất từ dữ liệu mở (sinh tự động)

File này do `data/scripts/make_report.py` sinh ra từ các CSV/JSON trong `data/derived/`. **Không có số nào được gõ tay hay đọc từ hình vẽ**; mỗi bảng ghi rõ script và file nguồn. Mô tả dữ liệu, DOI, giấy phép: xem `data/README.md`.

## A. Zenodo 4864437 — phóng điện LG M50 ở C/10, C/2, 1C, 2C; 0/10/25 °C

Script: `data/scripts/a_tec_noise_thermal.py` → `A_files.csv`, `A_noise.csv`, `A_thermal_tau.csv`, `A_tc_spread.csv`, `A_summary.json`.

### A.1 Cấu trúc file và giao thức thử

- Số file: **48** (`data/<T>degC/Cell<id>_<C-rate>C_<T>degC.csv`), 16 cell (ID 781 … 796), mỗi tổ hợp (C-rate, nhiệt độ) có 4 cell.
- Dòng 1–15: header thiết bị (Measurement ID, Battery Name = LG M50, Program, Start/End Time…); dòng 16: tên cột; dòng 17: đơn vị; dữ liệu từ dòng 18.
- Cột: `Step`, `Status` (PAU = nghỉ, CHA = sạc, DCH = xả, RANGE, STO), `Step Time` [s], `Prog Time` [s], `Cycle`, `Cycle Level`, `Procedure`, `Voltage` [V], `Current` [A] (âm = xả), `AhAccu` [Ah], `AhPrev` [Ah], `WhAccu` [Wh], `Watt` [W], các kênh nhiệt độ [°C].
- Trình tự bước (giống nhau ở mọi file đầy đủ): `PAU>CHA>PAU>DCH>PAU>CHA>PAU>DCH>PAU`. Tức là: nghỉ 2 h → sạc CC-CV tới 4,2 V → nghỉ 2 h → xả CC tới 2,5 V → nghỉ 2 h, lặp 2 lần.
- Số lần xả trong mỗi file: 2 lần: 46 file; 1 lần: 2 file. File có ít hơn 2 lần xả: Cell781_0p1C_0degC.csv, Cell796_2C_25degC.csv.

Kênh nhiệt độ theo cell (tên đã đổi theo `tec_reduced_model/process_experimental_data.py::clean_dataset`: `LogTempPositive`→T_pos (đầu cực dương), `LogTempMid`→T_mid (giữa thân cell), `LogTempNegative`→T_neg (đầu cực âm); `LogTemp001` = môi trường nếu file có 3 cặp nhiệt bề mặt, ngược lại = bề mặt cell; `LogTemp002` = môi trường):

| Kênh nhiệt độ có trong file | Cell |
|---|---|
| T_cell | 782, 783, 784, 786, 787, 788, 790, 791, 792, 794, 795 |
| T_cell + T_amb | 790, 792, 796 |
| T_pos + T_mid + T_neg | 785, 789, 793 |
| T_pos + T_mid + T_neg + T_amb | 781 |

Lấy mẫu:

| C-rate | Dòng xả (trung vị các file) [A] | Chu kỳ lấy mẫu khi xả (trung vị) [s] | Chu kỳ lấy mẫu các pha nghỉ [s] (theo thứ tự) |
|---|---|---|---|
| 0.1 | -0.4998 | 59.94 | 120 + 60 + 60 + 60 + 60 |
| 0.5 | -2.4998 | 19.42 | 120 + 60 + 60 + 60 + 60 |
| 1 | -4.9999 | 0.99 | 120 + 1 + 1 + 1 + 1 |
| 2 | -9.9998 | 0.99 | 120 + 1 + 1 + 1 + 1 |

Kênh môi trường chỉ có ở một số file; ở file nào kênh này hằng 0,0 thì được đánh dấu "not connected" trong `A_noise.csv`: Cell790_1C_10degC.csv, Cell792_1C_10degC.csv.

### A.2 Nhiễu cảm biến (pha nghỉ, 30 phút cuối của mỗi pha nghỉ 2 h)

Cách tính (`noise_stats`): `std_raw` = độ lệch chuẩn thô trong cửa sổ; `std_d2` = std(sai phân bậc 2)/√6 — ước lượng nhiễu trắng không bị ảnh hưởng bởi trôi tuyến tính (điện áp vẫn hồi phục chậm trong pha nghỉ nên `std_raw` của điện áp là **cận trên**, gồm cả trôi). `quantisation_step` = khoảng cách nhỏ nhất giữa hai giá trị khác nhau trong toàn file. Bộ ghi báo dòng đúng 0,00000 A trong mọi pha nghỉ, nên nhiễu dòng được lấy trên pha xả CC (`cc_discharge_std_d2`). Mỗi ô: trung vị (min … max; số file).

| Kênh | Nhóm file | Đơn vị | quantisation_step | rest std_d2 | rest std_raw | CC-discharge std_d2 |
|---|---|---|---|---|---|---|
| Current | 1C, 2C (nghỉ lấy mẫu 1 s) | A | 0.00035 (0.00035 … 0.00036; n=24) | 0 (0 … 0; n=24) | 0 (0 … 0; n=24) | 0.000172 (0.000159 … 0.000177; n=24) |
| Current | C/10, C/2 (nghỉ lấy mẫu 60 s) | A | 0.00036 (0.00035 … 0.00036; n=24) | 0 (0 … 0; n=24) | 0 (0 … 0; n=24) | 0.000178 (0.000161 … 0.000187; n=23) |
| T_amb | 1C, 2C (nghỉ lấy mẫu 1 s) | degC | 0.1 (0.1 … 0.1; n=3) | 0.0108 (0.00903 … 0.0149; n=3) | 0.0467 (0.0349 … 0.0548; n=3) | – |
| T_amb | C/10, C/2 (nghỉ lấy mẫu 60 s) | degC | 0.1 (0.1 … 0.1; n=3) | 0 (0 … 0.071; n=3) | 0 (0 … 0.562; n=3) | – |
| T_cell | 1C, 2C (nghỉ lấy mẫu 1 s) | degC | 0.1 (0.1 … 0.1; n=18) | 0 (0 … 0.00136; n=18) | 0 (0 … 0.0313; n=18) | – |
| T_cell | C/10, C/2 (nghỉ lấy mẫu 60 s) | degC | 0.1 (0.1 … 0.1; n=18) | 0 (0 … 0.0109; n=18) | 0 (0 … 0.0445; n=18) | – |
| T_mid | 1C, 2C (nghỉ lấy mẫu 1 s) | degC | 0.1 (0.1 … 0.1; n=6) | 0 (0 … 0; n=6) | 0 (0 … 0; n=6) | – |
| T_mid | C/10, C/2 (nghỉ lấy mẫu 60 s) | degC | 0.1 (0.1 … 0.1; n=6) | 0 (0 … 0.0164; n=6) | 0 (0 … 0.0424; n=6) | – |
| T_neg | 1C, 2C (nghỉ lấy mẫu 1 s) | degC | 0.1 (0.1 … 0.1; n=6) | 0.000681 (0 … 0.00193; n=6) | 0.00372 (0 … 0.0343; n=6) | – |
| T_neg | C/10, C/2 (nghỉ lấy mẫu 60 s) | degC | 0.1 (0.1 … 0.1; n=6) | 0 (0 … 0.00527; n=6) | 0 (0 … 0.0121; n=6) | – |
| T_pos | 1C, 2C (nghỉ lấy mẫu 1 s) | degC | 0.1 (0.1 … 0.1; n=6) | 0 (0 … 0; n=6) | 0 (0 … 0; n=6) | – |
| T_pos | C/10, C/2 (nghỉ lấy mẫu 60 s) | degC | 0.1 (0.1 … 0.1; n=6) | 0 (0 … 0.0204; n=6) | 0 (0 … 0.0343; n=6) | – |
| Voltage | 1C, 2C (nghỉ lấy mẫu 1 s) | V | 2e-05 (1e-05 … 3e-05; n=24) | 3.34e-05 (2.93e-05 … 3.62e-05; n=24) | 0.000428 (5.84e-05 … 0.000528; n=24) | – |
| Voltage | C/10, C/2 (nghỉ lấy mẫu 60 s) | V | 2e-05 (1e-05 … 4e-05; n=24) | 4.05e-05 (3.53e-05 … 4.47e-05; n=24) | 0.000457 (0.000183 … 0.000535; n=24) | – |

Tóm tắt dùng cho mô hình (đều tính từ bảng trên):

- **Điện áp**: σ ≈ 35.5 µV (trung vị `std_d2` trên 48 file; khoảng 29.3–44.7 µV); bước lượng tử hoá 10–40 µV.
- **Dòng điện**: σ ≈ 0.17 mA trên pha xả CC (khoảng 0.16–0.19 mA); bước lượng tử hoá 0.35–0.36 mA; trong pha nghỉ bộ ghi luôn báo 0 (không ước lượng được nhiễu khi nghỉ).
- **Nhiệt độ bề mặt cell** (T_cell, T_mid, T_pos, T_neg): độ phân giải ghi 0.1 °C; ở 72/72 (file, kênh) `std_raw` khi nghỉ nhỏ hơn một bước lượng tử (trung vị 0 °C, max 0.0445 °C) → nhiễu thực **nhỏ hơn độ phân giải**; sai số lượng tử hoá tương đương q/√12 = 0.029 °C.
- **Nhiệt độ môi trường** (T_amb, 6 file có kênh hoạt động): `std_raw` khi nghỉ 0.0408 (0 … 0.562; n=6) °C — gồm cả dao động thật của buồng nhiệt, không chỉ nhiễu cảm biến.
- Đây là nhiễu ngắn hạn + độ phân giải của **bộ ghi trong phòng thí nghiệm**, không phải độ chính xác tuyệt đối (sai lệch hệ thống giữa các cặp nhiệt không xác định được từ dữ liệu; xem cột `rest_offset_*` ở A.4 và chênh lệch T_amb – T_cell ở A.3).

### A.3 Hằng số thời gian nhiệt gộp τ = m·C_p/(h·A)

Cách tính: sau mỗi lần xả, pha nghỉ 2 h; khớp `T(t) = T_inf + A·exp(−t/τ)` (scipy `curve_fit`, 3 tham số tự do T_inf, A, τ) cho từng cặp nhiệt bề mặt, bỏ `skip_s` giây đầu sau khi ngắt dòng. **T_inf là tham số khớp, không dùng kênh môi trường** (kênh này chỉ có ở vài file và lệch so với cặp nhiệt cell khi cân bằng). Chỉ coi là tin cậy (`reliable`) khi độ dư nhiệt ban đầu ≥ 2 K (vì độ phân giải 0,1 °C) — do đó C/10 bị loại. Kết quả chính dùng `skip_s = 120`.

- Tất cả các khớp tin cậy: **τ = 582 (462 … 911; n=100) s**; RMSE khớp: 0.054 (0.021 … 0.476; n=100) K.

Theo C-rate và nhiệt độ:

| C-rate | T danh định [°C] | τ trung vị [s] | τ min [s] | τ max [s] | số khớp |
|---|---|---|---|---|---|
| 0.5 | 0 | 500 | 462 | 596 | 12 |
| 0.5 | 10 | 520 | 483 | 655 | 12 |
| 0.5 | 25 | 525 | 488 | 638 | 10 |
| 1 | 0 | 538 | 467 | 640 | 11 |
| 1 | 10 | 559 | 478 | 648 | 10 |
| 1 | 25 | 565 | 476 | 748 | 10 |
| 2 | 0 | 642 | 528 | 875 | 12 |
| 2 | 10 | 648 | 554 | 874 | 12 |
| 2 | 25 | 674 | 544 | 911 | 11 |

Theo vị trí cặp nhiệt:

| Cặp nhiệt | τ trung vị [s] | τ min [s] | τ max [s] | số khớp |
|---|---|---|---|---|
| T_cell | 582 | 462 | 748 | 48 |
| T_mid | 515 | 467 | 678 | 18 |
| T_neg | 587 | 504 | 911 | 18 |
| T_pos | 597 | 532 | 832 | 16 |

- Độ phân tán giữa các cell (kênh T_cell, cùng C-rate và nhiệt độ): (max−min)/trung vị = 0.12 (0.09 … 0.25; n=9).

Độ nhạy với cửa sổ khớp (τ tăng khi bỏ nhiều thời gian đầu hơn → quá trình nguội **không thuần một hàm mũ**; mô hình nhiệt gộp một nút chỉ là xấp xỉ):

| skip_s [s] | τ trung vị [s] | τ min [s] | τ max [s] | số khớp tin cậy |
|---|---|---|---|---|
| 60 | 579 | 458 | 891 | 103 |
| 120 | 582 | 462 | 911 | 100 |
| 300 | 596 | 480 | 987 | 96 |
| 600 | 691 | 511 | 1153 | 67 |

- Ở các file có kênh môi trường hoạt động: T_inf (khớp) − T_amb (kênh đo, trung bình pha nghỉ) = -0.16 (-0.39 … 1.50; n=17) K → hai cảm biến không trùng nhau (có file lệch hơn 1 K), nên không dùng trực tiếp T_amb làm tiệm cận.

**Nhận dạng được / không nhận dạng được:**

- Nhận dạng được: chỉ **τ = m·C_p/(h·A)** (tương đương tỉ số h·A/(m·C_p) = 1/τ ≈ 1.72e-03 s⁻¹ với τ trung vị), và nhiệt độ tiệm cận.
- **Không** tách được h (hay h·A) và m·C_p riêng rẽ từ pha nguội: muốn tách phải biết công suất sinh nhiệt Q(t) trong pha xả (dữ liệu không đo nhiệt lượng; Q phụ thuộc mô hình: quá thế + nhiệt entropy), hoặc lấy m·C_p từ nguồn khác rồi suy ra h·A = m·C_p/τ.
- τ đo trên **bề mặt** cell; chênh lệch lõi–bề mặt không quan sát được. Điều kiện đối lưu là của buồng nhiệt trong thí nghiệm này, không tự động áp dụng cho bố trí khác.

### A.4 Chênh lệch giữa ba cặp nhiệt bề mặt trong lúc xả

Cách tính: lấy độ tăng nhiệt so với giá trị trung bình 10 mẫu cuối của pha nghỉ ngay trước khi xả (loại offset tĩnh giữa các cặp nhiệt), rồi so sánh mid/pos/neg. Chỉ các cell có 3 cặp nhiệt (781, 785, 789, 793). Giá trị = trung bình các lần xả.

| C-rate | T danh định [°C] | ΔT_mid cuối xả [K] | ΔT_pos cuối xả [K] | ΔT_neg cuối xả [K] | max(ΔT_mid−ΔT_pos) [K] | max(ΔT_mid−ΔT_neg) [K] | offset tĩnh mid−pos [K] | offset tĩnh mid−neg [K] | số lần xả |
|---|---|---|---|---|---|---|---|---|---|
| 0.1 | 10 | 1.75 | 0.46 | 1.10 | 1.29 | 0.70 | 0.01 | 0.00 | 2 |
| 0.1 | 25 | 0.90 | 0.15 | 0.50 | 0.80 | 0.40 | 0.05 | 0.05 | 2 |
| 0.5 | 0 | 6.95 | 2.70 | 5.30 | 4.25 | 1.70 | 0.11 | -0.04 | 2 |
| 0.5 | 10 | 5.90 | 2.40 | 4.40 | 3.55 | 1.50 | 0.20 | 0.00 | 2 |
| 0.5 | 25 | 4.60 | 1.75 | 3.40 | 2.85 | 1.20 | 0.15 | 0.00 | 2 |
| 1 | 0 | 14.10 | 5.60 | 12.15 | 8.50 | 2.15 | 0.00 | 0.00 | 2 |
| 1 | 10 | 12.05 | 5.05 | 10.15 | 7.05 | 1.95 | 0.00 | 0.05 | 2 |
| 1 | 25 | 9.00 | 3.85 | 8.00 | 5.20 | 1.15 | 0.05 | 0.05 | 2 |
| 2 | 0 | 42.40 | 16.90 | 24.20 | 25.55 | 18.30 | 0.15 | -0.05 | 2 |
| 2 | 10 | 37.95 | 15.40 | 22.20 | 22.65 | 16.00 | 0.15 | 0.10 | 2 |
| 2 | 25 | 32.85 | 13.70 | 19.85 | 19.25 | 13.15 | 0.10 | 0.05 | 2 |

- Ở 1C–2C: ΔT_pos/ΔT_mid cuối xả = 0.41 (0.39 … 0.43; n=12); ΔT_neg/ΔT_mid = 0.71 (0.57 … 0.89; n=12). Offset tĩnh giữa các cặp nhiệt khi nghỉ chỉ 0.00 (-0.10 … 0.20; n=44) K.
- Diễn giải thận trọng: bề mặt cell **không đẳng nhiệt** khi xả nhanh (giữa thân nóng hơn hai đầu, đầu dương mát nhất). Dữ liệu không cho biết nguyên nhân (tản nhiệt qua đầu kẹp/dây dẫn, vị trí gắn cặp nhiệt…), và chỉ có một cell cho mỗi (C-rate, nhiệt độ) nên không có độ lặp. Mô hình nhiệt gộp một nút vì vậy mang sai số mô hình cỡ các giá trị trong bảng; khi so mô hình với đo đạc phải nêu rõ so với cặp nhiệt nào (T_mid là vị trí nóng nhất trong ba vị trí đo).

## B. Zenodo 5171874 — O'Regan 2021 Data Repository (dữ liệu thô của O'Regan 2022)

Script: `data/scripts/b_oregan_tidy_entropy.py` → `B_entropic.csv`, `B_thermal_electronic.csv`, `B_specific_heat.csv`, `B_exchange_current.csv`, `B_diffusivity.csv`, `B_checks.json`.

### B.1 Hệ số entropy ∂U/∂T — kiểm tra đơn vị của Li 2025 SI Note 8, (S5), (S6)

Header của cả 4 file thô ghi đơn vị **`mV K-1`** (`Entropic Term  / mV K-1`). So sánh hàm in trong Li 2025 (S5)/(S6), tính đúng như in, với điểm đo (2 cell mỗi điện cực):

| Điện cực | số điểm đo | khoảng dữ liệu [mV/K] | RMSE nếu hàm cho mV/K [mV/K] | RMSE nếu hàm cho V/K [mV/K] | |sai lệch| lớn nhất (giả thiết mV/K) [mV/K] | tại x |
|---|---|---|---|---|---|---|
| dương — (S5) | 24 | -0.0634 … 0.0324 | 0.0090 | 37.1 | 0.019 | 0.9127 |
| âm — (S6) | 24 | -0.2135 … 0.3807 | 0.0739 | 185.0 | 0.183 | 0.4719 |

**Kết luận (từ số liệu):** hàm (S5), (S6) như in trong Li 2025 cho giá trị theo **mV/K**, không phải V/K như cột đơn vị của Table 6 ghi. Khi dùng trong mô hình (đơn vị SI) phải nhân 10⁻³: ∂U/∂T [V/K] = 10⁻³ × (S5)/(S6).

- Điện cực âm: (S6) (tuyến tính + 1 Gauss) **không** mô tả vùng lõm quanh x ≈ 0,47–0,57 của dữ liệu (tới -0.213 mV/K); bỏ các điểm 0,45 < x < 0,60 thì RMSE còn 0.0119 mV/K. Đây là giới hạn của dạng hàm, cần ghi là sai số mô hình nếu dùng (S6).
- Điện cực dương: khớp lại độc lập cùng dạng hàm trên dữ liệu thô cho hệ số {'a1': 0.04108, 'b1': 0.2833, 'c1': 0.0008345, 'a2': -0.06654, 'b2': 0.8032, 'c2': 0.02182} (RMSE 0.0090 mV/K) so với hệ số in {'a1': 0.04006, 'b1': 0.2828, 'c1': 0.0009855, 'a2': -0.06656, 'b2': 0.8032, 'c2': 0.02179} → (S5) đúng là hàm khớp của bộ dữ liệu này.
- Điện cực âm: khớp lại bình phương tối thiểu trên **toàn bộ** điểm cho nghiệm khác hẳn (RMSE 0.0486 mV/K, Gauss rất rộng) → dạng hàm (S6) không xác định duy nhất khi giữ các điểm vùng lõm; hệ số in trong bài nhiều khả năng được khớp khi bỏ/giảm trọng số vùng này (**không kiểm chứng được** từ dữ liệu).
- Đối chiếu thêm với source data của chính Li 2025 (Supplementary Figure 10 c, d; script `c_li2025_ageing.py`): đường cong tác giả vẽ có giá trị -0.08206 … 0.376 (âm) và -0.06656 … 0.04005 (dương), trùng với hàm in (RMSE 4.6e-05 và 9.7e-18) → con số trong hình SI cũng là mV/K. Kho mã công bố (`Scripts_to_reproduce_paper.zip`) **không chứa** định nghĩa ∂U/∂T (nằm trong bộ tham số PyBaMM riêng của tác giả), nên không kiểm được mã mô phỏng của họ có nhân 10⁻³ hay không.

### B.2 Các hàm khác của Li 2025 SI Note 11 so với dữ liệu thô (kiểm tra phụ)

| Đại lượng | điện cực | số điểm | RMSE | sai lệch tương đối lớn nhất |
|---|---|---|---|---|
| electronic_conductivity | positive | 5 | 0.0063 | 0.014 |
| thermal_conductivity | negative | 5 | 0.0130 | 0.006 |
| thermal_conductivity | positive | 5 | 0.0052 | 0.011 |

(thermal_conductivity [W m⁻¹ K⁻¹] so với (S24), (S25); electronic_conductivity [S m⁻¹] so với (S19).)

| Thành phần | số điểm thô | T [°C] | giá trị thô ở 40 °C | (S21–S23) ở 40 °C [J/kg/K] | tỉ số hàm/thô (35–90 °C) | RMSE nếu thô là J/g/K [J/kg/K] |
|---|---|---|---|---|---|---|
| negative | 4500 | 25 … 100 | 1.0765 | 1074.1 | 999.6 | 1.5 |
| positive | 4500 | 25 … 100 | 1.0564 | 1070.1 | 1017.1 | 20.0 |
| separator | 4500 | 25 … 100 | 1.8751 | 1878.3 | 1002.3 | 5.9 |

- Header file nhiệt dung ghi `J kg-1 K-1` nhưng độ lớn (≈1–2,5) và tỉ số ≈1000 với (S21)–(S23) cho thấy số thô thực tế là **J g⁻¹ K⁻¹** (nhãn đơn vị trong file sai). Đoạn đầu quét DSC (25 → ~32 °C) là quá độ khởi động (giá trị ở 25 °C: xem `raw_value_at_25degC` trong `B_checks.json`), không dùng được.

Mật độ dòng trao đổi (file ghi mA cm⁻² = 10 A m⁻²), so với (S26)/(S27) tại c_e = ⟨c_e⟩:

| điện cực | T | số điểm | j0 đo lớn nhất [A/m²] | (S26)/(S27) lớn nhất [A/m²] | RMSE [A/m²] | trung vị hàm/đo |
|---|---|---|---|---|---|---|
| negative | 15degC | 10 | 0.407 | 0.910 | 0.351 | 1.867 |
| negative | 25degC | 10 | 0.973 | 1.592 | 0.466 | 1.371 |
| negative | 35degC | 10 | 2.596 | 2.688 | 0.527 | 0.970 |
| negative | 45degC | 10 | 4.960 | 4.391 | 0.460 | 0.932 |
| positive | 15degC | 10 | 1.274 | 1.812 | 0.804 | 1.660 |
| positive | 25degC | 10 | 2.648 | 2.535 | 0.487 | 1.022 |
| positive | 35degC | 10 | 4.678 | 3.472 | 1.039 | 0.822 |
| positive | 45degC | 10 | 5.205 | 4.661 | 0.762 | 0.924 |

- Khuếch tán pha rắn (GITT): 40 file, 9996 dòng; stoichiometry âm 0.008–0.991, dương 0.254–0.962; 5/15/25/35/45 °C, 2 cell, 2 chiều (lit/delit). Trung vị log10(D_s [m²/s]) theo (điện cực|T °C): {'negative|5': -16.89, 'negative|15': -16.55, 'negative|25': -16.53, 'negative|35': -16.43, 'negative|45': -16.24, 'positive|5': -15.01, 'positive|15': -14.91, 'positive|25': -14.8, 'positive|35': -14.69, 'positive|45': -14.61}. Chưa so với (S17) trong script này.

## C + D. Dữ liệu lão hoá: Kirkaldy 2024 (Zenodo 10637534) và Li 2025 (Zenodo 14995785)

Script: `data/scripts/d_kirkaldy_summary.py` → `D_kirkaldy_per_cell_rpt.csv`, `D_kirkaldy_ageing_sets.csv`, `D_kirkaldy_summary.csv`, `D_kirkaldy_cells.csv`, `D_archive_dirs.csv`, `D_checks.json`; `data/scripts/c_li2025_ageing.py` → `C_experiment_per_cell_rpt.csv`, `C_experiment_summary.csv`, `C_fig_ageing_long.csv`, `C_fig_small_tables_long.csv`, `C_model_input_cases.csv`, `C_li_dUdT_curves.csv`, `C_checks.json`, `C_archive_listing.tsv`.

- Kirkaldy 2024: 5 file ZIP, tổng dung lượng giải nén 160.6 GB. **Có file tóm tắt nhỏ**: `Summary Data/Performance Summary/* - Processed Data.csv` (mỗi cell một file, mỗi RPT một dòng: dung lượng C/10, C/2, điện trở 0,1 s, SoH, LLI, LAM_PE, LAM_NE (tổng/Gr/Si), thông lượng điện tích, số chu kỳ, nhiệt độ trung bình) và `Summary per Set/*set_data.csv`. Script chỉ tải 80 file này (345 kB) bằng HTTP Range, không tải dữ liệu thô.
- Bản sao cùng dữ liệu trong kho Li 2025 (`SimSave/InputData/Expt */…Extracted Data.csv` + `DMA Output/`) khớp với bản Kirkaldy: 511/511 dòng trùng khoá; sai khác lớn nhất SoH 5.0e-08, LLI 5.0e-08, LAM_NE 5.0e-08, LAM_PE 4.9e-08, dung lượng C/10 5.0e-04 mAh. **Ngoại lệ:** trục thông lượng điện tích của Expt 2,2 trong bản Li 2025 lớn hơn bản Kirkaldy 0.0 … 418.0 Ah (các thí nghiệm khác: chênh 0) — hai nguồn đếm thông lượng khác nhau cho Expt 2,2; khi so mô hình phải nói rõ dùng trục nào.

### D.1 Thực nghiệm theo cửa sổ SOC và nhiệt độ (nguồn: Kirkaldy 2024, `D_kirkaldy_summary.csv`)

Cách tính: SOH = dung lượng C/10 tại RPT / dung lượng C/10 tại RPT0 (mỗi cell); LLI, LAM lấy nguyên từ cột DMA của tác giả (khớp OCV); "tại thông lượng chung" = nội suy tuyến tính từng cell tới thông lượng lớn nhất mà mọi cell của nhóm đều đạt, rồi lấy trung bình (min…max giữa các cell có trong CSV). T_cell là nhiệt độ bề mặt cell trung bình trong lúc lão hoá (file `set_data`), **khác** nhiệt độ buồng danh định.

| SOC [%] | Expt | T buồng [°C] | số cell | T_cell TB [°C] | chu kỳ/đợt | Q chung [Ah] | SOH [%] | LLI [%] | LAM_NE [%] | LAM_PE [%] | R0.1s BOL [mΩ] | R0.1s cuối [mΩ] | tại Q_R [Ah] |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 0-30 | 1 | 10 | 3 | 17.9 | 257 | 7754 | 81.9 | 17.3 | 15.1 | 7.3 | 26.0 | 31.5 | 7754 |
| 0-30 | 1 | 25 | 3 | 30.3 | 257 | 8531 | 66.4 | 32.1 | 31.9 | 21.7 | 26.5 | 40.6 | 8531 |
| 0-30 | 1 | 40 | 3 | 42.3 | 257 | 7734 | 77.7 | 21.6 | 23.0 | 8.8 | 26.2 | 32.7 | 7734 |
| 70-85 | 2,2 | 10 | 2 | 16.5 | 517 | 9054 | 90.3 | 10.3 | 8.3 | 5.3 | 26.2 | 27.1 | 9054 |
| 70-85 | 2,2 | 25 | 2 | 28.3 | 517 | 9121 | 91.4 | 9.2 | 6.7 | 4.6 | 28.5 | 30.5 | 9121 |
| 70-85 | 2,2 | 40 | 2 | 40.7 | 517 | 9127 | 89.3 | 11.3 | 8.4 | 5.6 | 25.8 | 27.8 | 9127 |
| 85-100 | 3 | 10 | 3 | 15.3 | 517 | 6367 | 81.7 | 15.2 | 12.3 | 9.6 | 26.3 | 35.6 | 6367 |
| 85-100 | 3 | 25 | 3 | 27.6 | 517 | 8308 | 86.2 | 13.7 | 14.1 | 9.4 | 26.5 | 30.8 | 7553 |
| 85-100 | 3 | 40 | 3 | 41.1 | 517 | 8358 | 84.7 | 13.5 | 12.1 | 9.1 | 27.0 | 33.6 | 7599 |
| 0-100 (drive cycle) | 4 | 10 | 3 | 16.3 | 517 | 6351 | 72.1 | 27.3 | 29.7 | 18.1 | 26.8 | 33.2 | 6006 |
| 0-100 (drive cycle) | 4 | 25 | 2 | 28.8 | 517 | 7076 | 86.6 | 14.0 | 17.3 | 7.1 | 26.1 | 28.4 | 6315 |
| 0-100 (drive cycle) | 4 | 40 | 3 | 40.5 | 517 | 7002 | 82.7 | 17.7 | 19.5 | 12.4 | 26.5 | 30.7 | 6276 |
| 0-100 | 5 | 10 | 3 | 16.7 | 78 | 6624 | 76.9 | 20.2 | 24.7 | 8.6 | 26.0 | 33.2 | 6412 |
| 0-100 | 5 | 25 | 2 | 28.3 | 78 | 9358 | 81.4 | 17.4 | 21.2 | 8.7 | 26.3 | 31.0 | 8791 |
| 0-100 | 5 | 40 | 3 | 41.9 | 78 | 9402 | 77.3 | 16.5 | 21.0 | 8.7 | 25.9 | 34.7 | 8872 |

Cùng một thông lượng 3 kAh và 6 kAh (để so các cửa sổ SOC với nhau; trung bình các cell đạt tới mức đó):

| SOC [%] | T buồng [°C] | SOH@3kAh | LLI@3kAh | LAM_NE@3kAh | LAM_PE@3kAh | SOH@6kAh | LLI@6kAh | LAM_NE@6kAh | LAM_PE@6kAh | số cell @6kAh |
|---|---|---|---|---|---|---|---|---|---|---|
| 0-30 | 10 | 93.8 | 6.2 | 5.6 | 3.2 | 87.2 | 13.1 | 11.2 | 5.0 | 3 |
| 0-30 | 25 | 83.9 | 15.5 | 18.3 | 3.0 | 80.1 | 19.1 | 22.0 | 6.5 | 3 |
| 0-30 | 40 | 82.8 | 17.6 | 18.2 | 4.8 | 79.3 | 21.0 | 21.3 | 8.0 | 3 |
| 70-85 | 10 | 94.8 | 5.9 | 5.1 | 3.8 | 91.5 | 9.4 | 7.9 | 5.8 | 2 |
| 70-85 | 25 | 95.5 | 5.3 | 3.2 | 3.8 | 92.9 | 7.6 | 5.3 | 4.2 | 2 |
| 70-85 | 40 | 94.0 | 6.3 | 4.5 | 3.0 | 91.3 | 9.2 | 6.4 | 4.5 | 2 |
| 85-100 | 10 | 90.1 | 8.5 | 3.9 | 8.7 | 81.5 | 15.8 | 12.4 | 13.2 | 3 |
| 85-100 | 25 | 92.9 | 6.5 | 4.8 | 6.5 | 86.6 | 12.6 | 9.8 | 10.5 | 3 |
| 85-100 | 40 | 94.2 | 6.2 | 4.2 | 5.1 | 89.1 | 10.3 | 7.8 | 5.7 | 3 |
| 0-100 (drive cycle) | 10 | 92.0 | 8.8 | 11.8 | 4.0 | 77.6 | 22.7 | 25.8 | 13.8 | 3 |
| 0-100 (drive cycle) | 25 | 91.5 | 9.3 | 12.3 | 4.5 | 88.0 | 12.7 | 16.0 | 6.2 | 2 |
| 0-100 (drive cycle) | 40 | 89.7 | 11.4 | 13.1 | 6.8 | 84.5 | 16.0 | 17.8 | 10.8 | 3 |
| 0-100 | 10 | 84.9 | 15.0 | 17.5 | 5.5 | 78.5 | 19.2 | 23.4 | 7.6 | 3 |
| 0-100 | 25 | 88.9 | 11.5 | 14.0 | 6.2 | 85.5 | 14.3 | 17.8 | 6.4 | 2 |
| 0-100 | 40 | 89.2 | 11.5 | 14.1 | 7.0 | 84.1 | 14.9 | 18.6 | 8.9 | 3 |

- Số cell ít (2–3 mỗi điều kiện) và DMA có nhiễu (LAM âm ở vài RPT đầu, xem CSV theo cell) → các con số trên là trung bình mẫu nhỏ, không kèm khoảng tin cậy.
- Nhiệt độ cell trung bình khi lão hoá cao hơn nhiệt độ buồng danh định (cột T_cell TB); cần dùng giá trị này, không phải 10/25/40 °C, nếu mô hình không tự tính tự nung.

### C.1 Mô hình của Li 2025 so với thực nghiệm (source data của Fig. 3, 4, 6; `C_fig_ageing_long.csv`)

Giá trị tại điểm cuối của mỗi chuỗi (thông lượng lớn nhất có trong source data). `exp_avg` = trung bình 2 cell do tác giả tính. **Điểm cuối của thực nghiệm và của mô hình nằm ở thông lượng khác nhau (hai cột Q)** — bảng này chỉ để định hướng; khi so sánh định lượng phải nội suy từ `C_fig_ageing_long.csv` về cùng thông lượng. Thí nghiệm của mỗi hình được xác định bằng cách **so khớp số** chuỗi thực nghiệm với file theo cell (`panel_to_experiment_matching` trong `C_checks.json`), không dựa vào chú thích.

| Hình | Expt | T panel [°C] | Đại lượng | Q exp_avg [kAh] | exp_avg | Q model_5_coupled [kAh] | model_SEI_only | model_SEI_dry_out | model_5_coupled |
|---|---|---|---|---|---|---|---|---|---|
| Fig.3 | 2,2 | 10 | R_0p1s_mOhm | 9.47 | 27.08 | 9.52 | 29.26 | 30.02 | 29.47 |
| Fig.3 | 2,2 | 10 | SOH_pct | 9.47 | 90.33 | 9.52 | 90.92 | 90.49 | 88.78 |
| Fig.3 | 2,2 | 25 | R_0p1s_mOhm | 9.54 | 30.47 | 9.52 | 29.07 | 29.77 | 29.24 |
| Fig.3 | 2,2 | 25 | SOH_pct | 9.54 | 91.41 | 9.52 | 91.18 | 90.87 | 89.35 |
| Fig.3 | 2,2 | 40 | R_0p1s_mOhm | 9.54 | 27.75 | 9.52 | 29.43 | 30.24 | 29.46 |
| Fig.3 | 2,2 | 40 | SOH_pct | 9.54 | 89.32 | 9.52 | 90.18 | 89.65 | 88.69 |
| Fig.4 | 2,2 | 10 | LAM_NE_tot_pct | 9.47 | 8.33 | 9.52 | 0.00 | 5.20 | 7.15 |
| Fig.4 | 2,2 | 10 | LAM_PE_pct | 9.47 | 5.26 | 9.52 | 0.00 | 5.20 | 6.20 |
| Fig.4 | 2,2 | 10 | LLI_pct | 9.47 | 10.27 | 9.52 | 6.66 | 8.25 | 9.78 |
| Fig.4 | 2,2 | 25 | LAM_NE_tot_pct | 9.54 | 6.69 | 9.52 | 0.00 | 4.98 | 6.50 |
| Fig.4 | 2,2 | 25 | LAM_PE_pct | 9.54 | 4.62 | 9.52 | 0.00 | 4.98 | 5.98 |
| Fig.4 | 2,2 | 25 | LLI_pct | 9.54 | 9.18 | 9.52 | 6.46 | 7.91 | 9.28 |
| Fig.4 | 2,2 | 40 | LAM_NE_tot_pct | 9.54 | 8.43 | 9.52 | 0.00 | 5.67 | 6.81 |
| Fig.4 | 2,2 | 40 | LAM_PE_pct | 9.54 | 5.56 | 9.52 | 0.00 | 5.67 | 6.44 |
| Fig.4 | 2,2 | 40 | LLI_pct | 9.54 | 11.25 | 9.52 | 7.21 | 8.98 | 9.89 |
| Fig.6 | 3 | 10 | LAM_NE_tot_pct | 6.37 | 13.61 | 9.48 | 0.00 | 5.95 | 10.07 |
| Fig.6 | 3 | 10 | LAM_PE_pct | 6.37 | 9.84 | 9.48 | 0.00 | 5.95 | 7.06 |
| Fig.6 | 3 | 10 | LLI_pct | 6.37 | 17.05 | 9.48 | 7.57 | 9.42 | 12.60 |
| Fig.6 | 3 | 10 | R_0p1s_mOhm | 3.75 | 36.35 | 9.48 | 30.01 | 30.86 | 30.61 |
| Fig.6 | 3 | 10 | SOH_pct | 6.37 | 79.47 | 9.48 | 89.70 | 89.20 | 85.34 |
| Fig.6 | 3 | 25 | LAM_NE_tot_pct | 7.58 | 13.73 | 9.48 | 0.00 | 5.76 | 8.80 |
| Fig.6 | 3 | 25 | LAM_PE_pct | 7.58 | 12.61 | 9.48 | 0.00 | 5.76 | 6.73 |
| Fig.6 | 3 | 25 | LLI_pct | 7.58 | 15.01 | 9.48 | 7.40 | 9.12 | 11.51 |
| Fig.6 | 3 | 25 | R_0p1s_mOhm | 3.79 | 37.32 | 9.48 | 29.84 | 30.64 | 30.22 |
| Fig.6 | 3 | 25 | SOH_pct | 7.58 | 83.09 | 9.48 | 90.00 | 89.62 | 86.70 |
| Fig.6 | 3 | 40 | LAM_NE_tot_pct | 8.31 | 15.00 | 9.48 | 0.00 | 6.40 | 8.83 |
| Fig.6 | 3 | 40 | LAM_PE_pct | 8.31 | 9.94 | 9.48 | 0.00 | 6.40 | 7.17 |
| Fig.6 | 3 | 40 | LLI_pct | 8.31 | 14.00 | 9.48 | 8.16 | 10.12 | 11.90 |
| Fig.6 | 3 | 40 | R_0p1s_mOhm | 3.78 | 31.07 | 9.48 | 30.22 | 31.09 | 30.42 |
| Fig.6 | 3 | 40 | SOH_pct | 8.31 | 86.52 | 9.48 | 88.99 | 88.51 | 86.30 |

**Cảnh báo về source data của Fig. 6 (Expt 3) — phát hiện bằng so khớp số:** các chuỗi thực nghiệm ở cột thứ 2 và 3 của Fig. 6 trùng với các cell có nhiệt độ danh định khác với nhiệt độ của cột (giả định thứ tự cột 10/25/40 °C như Fig. 3/4, nơi thứ tự này được xác nhận bằng so khớp):

- Fig.6|b|exp_sample1 -> Expt 3 cell C (10 degC nominal), panel = 25.0 degC
- Fig.6|c|exp_sample1 -> Expt 3 cell E (25 degC nominal), panel = 40.0 degC
- Fig.6|c|exp_sample2 -> Expt 3 cell F (25 degC nominal), panel = 40.0 degC
- Fig.6|h|exp_sample1 -> Expt 3 cell C (10 degC nominal), panel = 25.0 degC
- Fig.6|i|exp_sample1 -> Expt 3 cell E (25 degC nominal), panel = 40.0 degC
- Fig.6|i|exp_sample2 -> Expt 3 cell F (25 degC nominal), panel = 40.0 degC
- Fig.6|k|exp_sample1 -> Expt 3 cell C (10 degC nominal), panel = 25.0 degC
- Fig.6|l|exp_sample1 -> Expt 3 cell E (25 degC nominal), panel = 40.0 degC
- Fig.6|l|exp_sample2 -> Expt 3 cell F (25 degC nominal), panel = 40.0 degC
- Fig.6|n|exp_sample1 -> Expt 3 cell C (10 degC nominal), panel = 25.0 degC
- Fig.6|o|exp_sample1 -> Expt 3 cell E (25 degC nominal), panel = 40.0 degC
- Fig.6|o|exp_sample2 -> Expt 3 cell F (25 degC nominal), panel = 40.0 degC

Theo tên file trong chính kho dữ liệu và theo `Temp_Cell_Exp_3` trong `Fun_NC.py`, Expt 3 dùng cell A, B, C ở 10 °C; D, E, F ở 25 °C; G, H, I ở 40 °C; trong khi source data Fig. 6 lấy A, B / C, D / E, F (kiểu ánh xạ của Expt 2). Riêng cột thứ 2 ghép cell C (10 °C) với cell D (25 °C) nên bất nhất này **không phụ thuộc** vào giả định về thứ tự cột. Vì vậy **không dùng các chuỗi `exp_*` của Fig. 6 cột 25 và 40 °C để kiểm chứng**; hãy dùng `D_kirkaldy_per_cell_rpt.csv` (theo cell, đúng nhiệt độ). Đường mô hình trong Fig. 6 không kiểm tra được nhiệt độ từ source data. Ngoài ra các panel điện trở Fig. 6 d–f không so khớp được với file theo cell (xem `C_checks.json`: không có mục cho các panel này).

- `C_model_input_cases.csv`: 27 bộ tham số đầu vào của lượt chạy `Full_Exp23_Paper_11_fine` (`Exp No.` = [2]; nhiệt độ [10.0, 25.0, 40.0] °C; quét `SEI growth activation energy` = [500.0, 5000.0, 10000.0] J/mol và `Negative electrode diffusivity activation energy` = [20000.0, 40000.0, 60000.0] J/mol) kèm các cột sai số `Error … %` của tác giả; dùng để đối chiếu tham số suy giảm (ví dụ `Inner SEI lithium interstitial diffusivity`, `Contact resistance`, `Total heat transfer coefficient`).
- Kết quả mô phỏng dài theo từng RPT của tác giả (`SimSave/Li2024_Results/Save_LongRun/**/Mats/*-StructData.json`, ~1,3 MB mỗi lượt) **chưa tải**; các đường mô hình trong bảng trên lấy từ source data của hình.

## Những gì chưa lấy được / giới hạn

- A: không có phép đo nhiệt lượng hay nhiệt độ lõi → không tách được h và m·C_p; kênh môi trường chỉ có ở một phần file; cell 781 ở 0 °C chỉ có file rút gọn (xem `A_files.csv`).
- B: hệ số khớp gốc của O'Regan 2022 (Table S9) không có trong kho dữ liệu; chỉ kiểm tra được qua hàm in lại trong Li 2025. D_s chưa so với (S17).
- C: mã định nghĩa ∂U/∂T của Li 2025 không nằm trong kho mã công bố; kết quả mô phỏng chi tiết theo RPT chưa tải; source data Fig. 6 có vấn đề gán cell nêu trên.
- D: chỉ dùng file tóm tắt; chuỗi thời gian thô (đường cong C/10, GITT, chu kỳ lão hoá) **không tải**. Nếu cần tự chạy lại DMA: chỉ cần thư mục `Processed Timeseries Data/0.1C Voltage Curves/` của từng ZIP (xem dung lượng trong `D_archive_dirs.csv`), có thể lấy bằng `common.fetch_members` mà không tải cả ZIP.
