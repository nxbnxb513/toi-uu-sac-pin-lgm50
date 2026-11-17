# Giả định và các chỗ phải tự quyết định

**Quy tắc (theo yêu cầu của người dùng):** cái gì **bài báo in** (bài chính, bảng, phương trình trong SI của Li et al. 2025, Nat. Commun. 16:2776; và O'Regan 2022 cho những mục Li 2025 kế thừa) thì làm **đúng như in**. Mã nguồn của tác giả chỉ dùng cho những thứ bài **không ghi**. Phương trình in mà không cài được đúng nguyên văn thì **không tự chọn dạng của mã nguồn** mà đưa vào mục "Chờ quyết định".

"Mã nguồn" = script Zenodo 10.5281/zenodo.14995785 (`Fun_NC.py`, `Get_Input_files.ipynb`) và bộ tham số `OKane2023` mà script gọi (PyBaMM fork `RuiheLi/PyBaMM`, nhánh `GEM-2_NC`, file `pybamm/input/parameters/lithium_ion/OKane2023.py` và các submodel). Không có giá trị nào đọc từ đường cong trên hình. Mã `GD-xx` được nhắc lại trong chú thích của code (`src/dfn/`).

Trong code: `dfn_params(struct('src','paper'))` (mặc định) dùng cột "bài báo"; `dfn_params(struct('src','code'))` dùng cột "mã nguồn" cho các mục GD-02, GD-03, GD-04, GD-07. Bản kiểm chứng (`results/validation.md`) báo cáo **cả hai**.

## 1. Theo bài báo (code khác)

| Mã | Nội dung | Bài báo in (đang dùng, `src='paper'`) | Mã nguồn (`src='code'`) | Ghi chú |
|---|---|---|---|---|
| GD-03 | Hệ số trong độ dẫn điện giải κ_e, SI pt. (S14) | 0.8353 | 0.353 (trùng Landesfeind & Gasteiger 2019) | Với giá trị in: κ(1 M, 25 °C) = 2.45 S/m; với mã nguồn: 0.91 S/m. |
| GD-04 | Hệ số bậc nhất theo c trong t₊, SI pt. (S15) | −0.612 | −6.12 (trùng Landesfeind & Gasteiger 2019) | Với giá trị in: t₊(1 M, 25 °C) = 5.73 (> 1, tức 1 − t₊ < 0: gradient nồng độ và thế khuếch tán trong điện giải đổi dấu); với mã nguồn: 0.22. Xem kết quả kiểm chứng của hai biến thể. |
| GD-02 | Lớp SEI ban đầu (mỗi lớp) và độ xốp cực âm ban đầu | L_SEI,0 = 1.23625×10⁻⁸ m (SI Table 8, ghi "unchanged"); ε_n = 0.25 − 2·L_SEI,0·S_r·a_n = 0.2224 (SI Table 6 → pt. (S10)–(S11)) | 9.2326×10⁻⁹ m và ε_n = 0.234965 cho bộ "5 coupled": tính lại (S7) với V̄_SEI = 5.22×10⁻⁵, ΔQ = 5 − 4.86491 Ah, rồi **cộng 2.5 nm mỗi lớp** (`Fun_NC.py::Overwrite_Initial_L_SEI_0_Neg_Porosity`) | SI Note 9 nói L_SEI,0 phụ thuộc V̄_SEI (ví dụ 9.585×10⁻⁵ → 1.236×10⁻⁸ m) nhưng Table 8 lại liệt kê 1.23625×10⁻⁸ m là không đổi. Ảnh hưởng: điện trở màng ρ_SEI·L_SEI = 4.9×10⁻³ (bài) hay 3.7×10⁻³ Ω·m² (mã nguồn). |
| GD-07 | Mật độ lớp xốp khô "Density (porous)" dùng cho nhiệt dung | cực dương 3270, màng ngăn 1740, cực âm 946 kg/m³ (SI Table 6 như in) | cực âm 1740, màng ngăn 946 | O'Regan 2022 Table 7 (bài mà Li 2025 nói là kế thừa) cũng ghi graphite 1740, separator 946 — tức hai bài báo mâu thuẫn nhau; nhiều khả năng SI Table 6 in đổi chỗ hai cột. Ảnh hưởng tới nhiệt dung cell < 1 %. |
| GD-08b | Hệ số của ∂U_n/∂T, SI pt. (S6) | −0.111, 0.02901, 0.3562, 0.08308, 0.004621 | −0.1112, 0.02914, 0.3561, 0.08309, 0.004616 | Lệch ở chữ số thứ 3–4; dùng giá trị in. Hàm (S6) bỏ qua chỗ lõm của graphite ở x ≈ 0.47–0.57 (lệch tới 0.18 mV/K so với số liệu thô của O'Regan, data/ket_qua_du_lieu.md); O'Regan 2022 cố ý bỏ các điểm này (tr. 28, 31). |
| GD-12b | Nhiệt phản ứng | q_r = j·(φ_s − φ_e − U) (SI Table 3), tức gồm cả phần sụt áp trên màng SEI | a·j·η với η đã trừ sụt áp màng (PyBaMM `base_thermal.py`) | Khác nhau đúng bằng nhiệt Joule trên màng SEI (nhỏ). |
| GD-19 | ΔQ ban đầu trong (S7) | 5 − 4.865 = 0.135 Ah (SI Note 9) | 5 − 4.86491 Ah | Chỉ có tác dụng khi `src='code'` (bộ `paper` lấy L_SEI,0 trực tiếp từ Table 8). |

## 2. Theo code (bài không ghi)

| Mã | Nội dung | Giá trị / dạng dùng | Nguồn và lý do |
|---|---|---|---|
| GD-10 | Khuếch tán do ứng suất trong hạt | **bật** ở cả hai cực: D_eff = D_s·(1 + θ_M·(c − c_ref)), θ_M = Ω/(RT)·2ΩE/(9(1−ν)) | Bài và SI không nhắc; mã nguồn bật ngầm trong cả ba mô hình (PyBaMM `base_particle.py::_get_effective_diffusivity`). Với E_p = 375 GPa, D_s cực dương bị nhân ≈ 84–323 lần; cực âm 1.02–1.53 lần. Biến thể `code_no_stress` cho thấy ảnh hưởng. |
| GD-06 | ⟨c_e⟩ trong j₀, SI pt. (S26)–(S27) | hằng số 1000 mol/m³ | SI viết ⟨c_e⟩ mà không định nghĩa; mã nguồn dùng "Typical electrolyte concentration" = 1000 mol/m³. |
| GD-18 | Vị trí của thermodynamic factor χ (S16) | i_e = −κ_eff·(∂φ_e/∂x − 2(1 − t₊)·χ·(RT/F)·∂ln c_e/∂x) | SI Table 6 liệt kê χ là tham số (đánh dấu *), nhưng phương trình thế điện giải in ở SI Table 2 không có χ. Vị trí lấy theo mã nguồn (PyBaMM). `dfn_params(struct('use_tdf', false))` cho dạng đúng như Table 2 in. |
| GD-20 | Điện trở tiếp xúc R_0 = 11.5 mΩ vào đâu | V = φ_s,p(L) − φ_s,n(0) − I·R_0 | SI Table 6 cho giá trị, SI Table 2 in V = φ_p − φ_n không có R_0; cách dùng theo mã nguồn (tuỳ chọn "contact resistance": "true"). |
| GD-05 | Nhiệt I²·R_0 | **không** đưa vào cân bằng nhiệt | SI Table 3 chỉ có q_rev + q_j + q_r; mã nguồn (PyBaMM v23.4.1) cũng không cộng. Biến thể `code_Rc_heat` cho thấy ảnh hưởng. |
| GD-12 | Dạng lumped của cân bằng nhiệt | ρc_p,eff·dT/dt = Q̄ − h·A_cool/V_cell·(T − T_amb); Q̄ = nhiệt trung bình trên bề dày L_cc,n + L_n + L_s + L_p + L_cc,p (kể cả nhiệt Joule trong hai current collector); ρc_p,eff = trung bình theo bề dày các lớp | SI Table 3 chỉ in phương trình dạng PDE tổng quát và điều kiện biên đối lưu; dạng 0D theo mã nguồn (PyBaMM `thermal/lumped.py`, `thermal_parameters.py`). Hệ quả: nhiệt trên đơn vị thể tích chồng lớp được áp cho cả V_cell = 2.42×10⁻⁵ m³ (lớn hơn A·L ≈ 17 %). Mật độ điện giải 1280 kg/m³: O'Regan 2022 Table 5. |
| GD-01 | Năng lượng hoạt hoá của D_s cực âm | 2×10⁴ J/mol | Li 2025 Table 3 in ba giá trị tuỳ mô hình (SEI only, SEI + Dry out: 6×10⁴; 5 coupled: 2×10⁴); chọn cột "5 coupled" vì bước sau cài mô hình 5 cơ chế. Đây là lựa chọn của đồ án, đổi bằng `E_Ds_n`. |
| GD-14 | Nhánh OCP khi nghỉ và dạng sigmoid | (1 ± tanh[100(J + 0.2)])/2 theo SI pt. (S46)–(S47); J = I/A [A/m²] | Theo bài; mã nguồn trùng. Mô hình "zero-state": chuyển nhánh tức thời theo dòng. |
| GD-15 | Rời rạc hoá | thể tích hữu hạn; lưới mặc định [20, 10, 20 | 60, 20]; nồng độ bề mặt hạt ngoại suy tuyến tính từ hai vỏ ngoài cùng (như mặc định PyBaMM); thông lượng khuếch tán trong hạt tính bằng biến đổi Kirchhoff (K = ∫D_s dx) để luôn đơn điệu dù D_s(x) có đỉnh/hõm hẹp; tính chất điện giải tại mặt ô lấy trung bình điều hoà | Lựa chọn số học, bài không ghi. Mã nguồn dùng lưới [10, 10, 10 | 100, 20] (Expt 2) và [10, 5, 5 | 100, 20] (Expt 3). Sai số lưới được in trong `selftest.md` mỗi lần chạy CI. |
| GD-16 | Chặn số học và sự kiện dừng | stoichiometry bề mặt kẹp trong [10⁻⁸, 1 − 10⁻⁸] khi tính j₀, OCP (như PyBaMM); c_e ≥ 0.01 mol/m³ trong log/căn; mô phỏng **dừng** nếu c_e < 1 mol/m³ hoặc stoichiometry bề mặt chạm 10⁻⁴ / 1 − 10⁻⁴ | Tại stoich bề mặt = 0 hoặc 1, j₀ → 0 và mô hình suy biến. **Khác mã nguồn:** PyBaMM v23.4.1 của tác giả chỉ kẹp (10⁻⁸) mà không có sự kiện dừng, tức cho phép nồng độ bề mặt vượt c_max. Hệ quả quan trọng cho bước sạc: với bộ `code`, sạc CC 0.3C ở 25 °C làm bề mặt hạt cực âm phía màng ngăn chạm x = 1 trước khi áp đạt 4.2 V (ở 4.16 V, còn thiếu ≈ 0.3–0.4 Ah; không phụ thuộc lưới — xem `selftest.md` mục 3.2 và 4). Cách xử lý ở giới hạn này (dừng / cho vượt như mã nguồn / coi là ràng buộc của bài toán tối ưu) **cần người dùng quyết định ở bước 2**. Lý do dừng được ghi trong bảng kết quả. |

### Giả định của riêng phần kiểm chứng (không thuộc bài báo nào)

| Mã | Nội dung | Giá trị dùng | Lý do |
|---|---|---|---|
| GD-09 | Nhiệt độ môi trường và nhiệt độ đầu | bằng nhiệt độ bề mặt cell đo ngay trước khi xả, riêng cho từng cell | Phần lớn file của Zenodo 4864437 không có cảm biến môi trường; ở các file có, nó lệch 0.2–0.6 K so với cảm biến cell lúc nghỉ. Brosa Planella 2021 (`set_parameters.py`) cũng làm vậy. |
| GD-11 | Hệ số trao đổi nhiệt h | h = 20 W/m²/K (SI Table 6) trong biến thể `paper` và `code`; thêm `code_h15` (h = 15, O'Regan 2022 tr. 32) và `code_h_tau` (h suy từ τ nguội đo được 582 s và nhiệt dung của mô hình, ≈ 19.6) | h = 20 được Li 2025 chỉnh tay cho cell làm mát đáy; O'Regan chỉnh tay h = 15 cho chính bộ dữ liệu buồng nhiệt này. Không chỉnh h trong biến thể mặc định. |
| GD-13 | Trạng thái lithium ban đầu | trên đường cân bằng lithium đi qua điểm 100 % SOC của Li 2025 (x = 0.8771, y = 0.2411), sao cho OCV mô hình (nhánh xả) = áp nghỉ đo được | Cell kiểm chứng (LG M50, O'Regan) khác lô với cell mà Li 2025 chỉnh tham số (LG M50T, Kirkaldy 2024); lượng lithium thật của từng cell không đo được; áp nghỉ sau 2 h vẫn còn hồi phục chậm. |
| GD-17 | Kênh nhiệt độ dùng để so sánh | cặp nhiệt giữa thân cell ("Temp Cell") | Mô hình lumped chỉ có một nhiệt độ; bề mặt cell thật không đồng đều (ở 2C đầu dương chỉ tăng ≈ 41 %, đầu âm 57–60 % so với giữa thân; data/ket_qua_du_lieu.md). Báo cáo kèm độ tăng nhiệt đo ở hai đầu. |

## 3. Chờ quyết định

Các mục dưới đây là chỗ bài in **không cài được đúng nguyên văn** (sai thứ nguyên hoặc tự mâu thuẫn). Mô hình DFN không chạy được nếu bỏ trống chúng, nên code hiện dùng dạng ghi ở cột "đang tạm dùng" (lấy từ **bài báo gốc được kế thừa hoặc số liệu đo**, không lấy từ mã nguồn nếu có thể) và có tuỳ chọn để đổi. Cần người dùng xác nhận.

| Mã | Nội dung | Bài in | Vì sao không dùng được nguyên văn | Mã nguồn | Đang tạm dùng |
|---|---|---|---|---|---|
| GD-21 | Butler–Volmer, Li 2025 SI Table 2 | j_k = a_k·j_0,k·sinh(RT/(2F)·η_k); j_0,k = k_k·√(c_e·c_k·(c_k^max − c_k)) | Đối số RT/(2F)·η có thứ nguyên V² (không vô thứ nguyên); thiếu hệ số 2; dạng j_0 mâu thuẫn với (S26)–(S27) của chính SI (số mũ 0.43/0.57 và 0.792/0.208, không có k_k). | j = 2·j_0·sinh(F·η/(2RT)), j_0 theo (S26)–(S27) | j = 2·j_0·sinh(F·η/(2RT)) — dạng in trong **O'Kane 2022 Table S1** (bài mà SI Table 2 trích dẫn), với j_0 theo SI (S26)–(S27). |
| GD-08 | Đơn vị hệ số entropy, SI pt. (S5)–(S6) | SI Table 6 ghi đơn vị "V/K" | Với V/K, ∂U_n/∂T ≈ 0.03–0.36 V/K: OCP đổi hàng vôn khi T lệch 10 K và nhiệt thuận nghịch lớn gấp 1000 lần — mâu thuẫn với số liệu đo entropy của O'Regan (Zenodo 5171874) mà hàm này khớp (RMSE 0.009 / 0.074 mV/K khi hiểu là mV/K; data/ket_qua_du_lieu.md). | chia 1000 (mV/K) | mV/K (`dUdT_scale = 1e-3`), căn cứ số liệu đo của O'Regan. Đổi bằng `dfn_params(struct('dUdT_scale', 1))`. |
| GD-22 | D_e, SI pt. (S13) | "10⁻¹⁰ · 1010 · e^{…}" | Không sai thứ nguyên, nhưng cách in dễ đọc thành 10⁻¹⁰·10¹⁰. Đọc theo ảnh trang SI tr. 50 là 1010 (một nghìn không trăm mười). | 1.01e3 × 1e-10 | 1010 × 10⁻¹⁰ m²/s (D_e(1 M, 25 °C) = 2.9×10⁻¹⁰ m²/s). |

Các mục "Chờ quyết định" thuộc phần lão hoá (số mũ SEI không có F/RT, α của mạ lithium, t_0…) nằm trong `tai_lieu/dac_ta_lao_hoa.md` và sẽ được bổ sung vào đây ở bước 2.
