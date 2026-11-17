# Giả định và các chỗ phải tự quyết định

**Quy tắc (theo yêu cầu của người dùng):**

1. Cái gì **bài báo in** (bài chính, bảng, phương trình trong SI của Li et al. 2025, Nat. Commun. 16:2776; và O'Regan 2022 cho những mục Li 2025 kế thừa) thì làm **đúng như in**.
2. Chỗ bài in **sai rõ ràng** thì **bài gốc** mà nó trích dẫn phân xử. Việc tra bài gốc đã làm xong: `tai_lieu/doi_chieu_tham_so.md` (Landesfeind & Gasteiger 2019; Single 2018; von Kolzenberg 2020; SI của O'Regan 2022; số liệu thô của O'Regan).
3. **Mã nguồn** của tác giả chỉ dùng cho những thứ **không bài nào ghi**.
4. Không đọc số từ hình. Mỗi số ghi nguồn. Mã `GD-xx` được nhắc lại trong chú thích của code (`src/dfn/`).

"Mã nguồn" = script Zenodo 10.5281/zenodo.14995785 (`Fun_NC.py`, `Get_Input_files.ipynb`) và bộ tham số `OKane2023` mà script gọi (PyBaMM fork `RuiheLi/PyBaMM`, nhánh `GEM-2_NC`, file `pybamm/input/parameters/lithium_ion/OKane2023.py` và các submodel).

**Trong code** (`src/dfn/dfn_params.m`):

| Tuỳ chọn | Ý nghĩa |
|---|---|
| `src = 'approved'` (**mặc định**) | Bộ đã duyệt: bài in; chỗ in sai thì theo bài gốc (mục 1); chỗ không bài nào ghi thì theo mã nguồn (mục 3). |
| `src = 'paper'` | Chỉ để so sánh: đúng như Li 2025 in, kể cả chỗ in sai (0.8353, −0.612; L_SEI,0 = 1.23625×10⁻⁸ m; mật độ khô như SI Table 6). |
| `src = 'code'` | Chỉ để so sánh: giá trị mã nguồn ở GD-02, GD-03, GD-04, GD-07, GD-19. Khác `approved` duy nhất ở ΔQ của (S7) (0.13509 thay vì 0.135 Ah, lệch 0.07 %). |

Các mục mà cả ba bộ giống nhau: GD-06, GD-08, GD-08b, GD-18, GD-21, GD-22 và toàn bộ mục 3. Bản kiểm chứng (`validation.md` trong artifact `validation-report`) báo cáo `approved` và các biến thể của nó, kèm `paper`, `code` để tham khảo.

## 0. Người dùng đã duyệt (17/11/2026)

| Mã | Nội dung đã duyệt | Căn cứ |
|---|---|---|
| GD-21 | Butler–Volmer j = 2·j₀·sinh(F·η/(2RT)); j₀ theo Li 2025 SI (S26)–(S27), ⟨c_e⟩ = 1000 mol/m³ | O'Kane 2022 Table S1; von Kolzenberg 2020 pt. (9). Li 2025 SI Table 2 chép lỗi in từ SI Table S2 của O'Regan 2022 (doi_chieu B1). |
| GD-08 | Hệ số entropy (S5)–(S6) có đơn vị mV/K (nhân 10⁻³) | Số liệu đo gốc của O'Regan (Zenodo 5171874, header "mV K-1"); hàm in khớp số đo với RMSE 0.009 / 0.074 mV/K (doi_chieu B7). |
| GD-22 | D_e (S13): 1010 × 10⁻¹⁰ m²/s | Landesfeind 2019 Table II, p1 = 1.01E+03 (doi_chieu E3). |

## 1. Theo bài gốc (bài in sai)

Li 2025 in sai; bài gốc mà nó trích dẫn phân xử. Dùng trong `approved`.

| Mã | Nội dung | Li 2025 in | Dùng (theo bài gốc) | Nguồn gốc (xem `doi_chieu_tham_so.md`) |
|---|---|---|---|---|
| GD-03 | Hệ số p4 trong κ_e, SI pt. (S14) | 0.8353 | **0.353** | Landesfeind 2019 Table II (EC:EMC 3:7). κ(1 M, 25 °C): in → 2.45 S/m; gốc → 0.91 S/m (E1). Trùng mã nguồn. |
| GD-04 | Hệ số p2 (bậc nhất theo c) trong t₊, SI pt. (S15) | −0.612 | **−6.12** | Landesfeind 2019 Table II. t₊(1 M, 25 °C): in → 5.73 (phi vật lý); gốc → 0.22 (E2). Trùng mã nguồn. |
| GD-18 | Thermodynamic factor χ trong dòng điện giải | SI Table 2 không có χ (chép từ O'Regan SI Table S2) | i_e = −κ_eff·(∂φ_e/∂x − 2(1 − t₊)·χ·(RT/F)·∂ln c_e/∂x) | Landesfeind 2019 pt. [2] (E6). Các hệ số còn lại của (S13)–(S16) trùng từng số với Table II (E5). `use_tdf = false` cho dạng in (để so sánh). |
| GD-21 | Butler–Volmer | j = a·j₀·sinh(RT/(2F)·η) (sai thứ nguyên) | j = 2·j₀·sinh(F·η/(2RT)) | xem mục 0. |
| GD-08 | Đơn vị ∂U/∂T, SI Table 6 | "V/K" | mV/K | xem mục 0. |
| GD-07 | Mật độ lớp xốp khô cực âm / màng ngăn, SI Table 6 | màng ngăn 1740, cực âm 946 kg/m³ | **cực âm 1740, màng ngăn 946** | O'Regan 2022 Table 7 (đo): graphite-SiOy 1740, separator 946 → Li 2025 đổi chỗ hai ô (B8). Trùng mã nguồn. Ảnh hưởng nhiệt dung < 1 %. |
| GD-06 | ⟨c_e⟩ trong j₀, SI pt. (S26)–(S27) | không định nghĩa | 1000 mol/m³ | O'Regan 2022 pt. [14]: (c_e/c_e0); c_e0 = 1 mol/dm³ (B3). Trùng mã nguồn. |
| — | Luật tăng SEI (dùng ở bước C, **chưa cài**) | số mũ exp(−(φ_s − φ_e)) không có F/(RT); hệ số 1/2 mỗi lớp | exp(−F·(φ_s − φ_e)/(RT)); hệ số **1/4** mỗi lớp; z_SEI = 2; φ_s − φ_e không trừ sụt áp màng | Single 2018 pt. (1), (5); von Kolzenberg 2020 pt. (18), (25); đại số trên (S2)–(S4) của chính Li 2025 (S1–S4). Lưu sẵn trong `par.sei.growth`. |
| — | Hệ số truyền của mạ lithium (bước C) | Table 8: "α_a,Li = 0.65" | α_c,Li = 0.65 (mạ), α_a,Li = 0.35 (hoà tan) | O'Kane 2022 (P1). Lưu sẵn trong `par.lp`. |

## 2. Theo bài báo (đúng như in)

| Mã | Nội dung | Dùng | Ghi chú |
|---|---|---|---|
| GD-08b | Hệ số của ∂U_n/∂T, SI pt. (S6) | −0.111, 0.02901, 0.3562, 0.08308, 0.004621 (in) | Trùng O'Regan SI Table S7; mã nguồn lệch ở chữ số thứ 3–4 (B5). Hàm (S6) bỏ qua chỗ lõm của graphite ở x ≈ 0.47–0.57 (lệch tới 0.18 mV/K so với số liệu thô; O'Regan cố ý bỏ các điểm này). |
| — | D_s(x), j₀, C_p(T), ∂U_p/∂T | như Li 2025 SI in | Trùng từng hệ số với O'Regan SI Table S4–S7 (B2, B4, B6, B9). E_a của D_s,p = 12000 J/mol (Li 2025 ghi là đã đổi; gốc 12047). |
| GD-12b | Nhiệt phản ứng | q_r = j·(φ_s − φ_e − U) (SI Table 3) | O'Regan SI Table S3 in cùng dạng. Mã nguồn dùng a·j·η (khác đúng bằng nhiệt Joule trên màng SEI, nhỏ). |
| GD-19 | ΔQ ban đầu trong (S7) | 5 − 4.865 = 0.135 Ah (SI Note 9) | Dùng trong `approved` để tính L_SEI,0 theo cách của mã nguồn (GD-02). Mã nguồn: 5 − 4.86491 Ah. |
| GD-14 | Nhánh OCP và dạng sigmoid | (1 ± tanh[100(J + 0.2)])/2 theo SI pt. (S46)–(S47); J = I/A [A/m²] | Mã nguồn trùng. Mô hình "zero-state": chuyển nhánh tức thời theo dòng. |
| GD-01 | Năng lượng hoạt hoá của D_s cực âm | 2×10⁴ J/mol | Li 2025 Table 3 in ba giá trị tuỳ mô hình (SEI only, SEI + Dry out: 6×10⁴; 5 coupled: 2×10⁴); chọn cột "5 coupled" vì bước C cài mô hình 5 cơ chế. Giá trị đo gốc của O'Regan: 17393 J/mol (P6). Đổi bằng `E_Ds_n`. |

## 3. Theo code (không bài nào ghi, chưa nguồn gốc nào phân xử)

Các mục "CHƯA GIẢI QUYẾT" trong `doi_chieu_tham_so.md`. Dùng mã nguồn, có tuỳ chọn để đổi.

| Mã | Nội dung | Giá trị / dạng dùng | Tuỳ chọn | Nguồn và lý do |
|---|---|---|---|---|
| GD-02 | Lớp SEI ban đầu (mỗi lớp) và độ xốp cực âm ban đầu | tính lại (S7) với V̄_SEI = 5.22×10⁻⁵ và ΔQ = 0.135 Ah, rồi **cộng 2.5 nm mỗi lớp**: L_SEI,0 = 9.228×10⁻⁹ m, ε_n = 0.23498 | `sei_init = 'paper'`: 1.23625×10⁻⁸ m (SI Table 8), ε_n = 0.2224 | `Fun_NC.py::Overwrite_Initial_L_SEI_0_Neg_Porosity`. SI Note 9 nói L_SEI,0 phụ thuộc V̄_SEI nhưng Table 8 ghi 1.23625×10⁻⁸ m "unchanged" — tự mâu thuẫn, không nguồn gốc nào phân xử (S5). Điện trở màng ρ_SEI·L_SEI = 3.7×10⁻³ (code) hay 4.9×10⁻³ Ω·m² (bài). |
| GD-10 | Khuếch tán do ứng suất trong hạt | **bật** ở cả hai cực: D_eff = D_s·(1 + θ_M·(c − c_ref)), θ_M = Ω/(RT)·2ΩE/(9(1−ν)) | `stress_diffusion = false` | Bài và SI không nhắc; mã nguồn bật ngầm (PyBaMM `base_particle.py::_get_effective_diffusivity`). Với E_p = 375 GPa, D_s cực dương bị nhân ≈ 84–323 lần; cực âm 1.02–1.53 lần (P3). Kiểm chứng báo cả biến thể tắt. |
| GD-20 | Điện trở tiếp xúc R_0 = 11.5 mΩ | V = φ_s,p(L) − φ_s,n(0) − I·R_0 | `Rcontact = 0` | SI Table 6 cho giá trị; SI Table 2 in V = φ_p − φ_n, không có R_0 (P4). |
| GD-05 | Nhiệt I²·R_0 | **không** đưa vào cân bằng nhiệt | `contact_heat = true` | SI Table 3 chỉ có q_rev + q_j + q_r; mã nguồn cũng không cộng (P4). |
| GD-12 | Dạng lumped 0D của cân bằng nhiệt | ρc_p,eff·dT/dt = Q̄ − h·A_cool/V_cell·(T − T_amb); Q̄ = nhiệt trung bình trên bề dày L_cc,n + L_n + L_s + L_p + L_cc,p; ρc_p,eff = trung bình theo bề dày | (chỉ cài dạng này) | Li 2025 SI Table 3 và O'Regan SI Table S3 chỉ in PDE tổng quát (P5); dạng 0D theo PyBaMM `thermal/lumped.py`. Mật độ điện giải 1280 kg/m³: O'Regan 2022 Table 5. λ(T) (S24)–(S25) không dùng trong 0D (B12). |
| GD-15 | Rời rạc hoá | thể tích hữu hạn; lưới mặc định [20, 10, 20 \| 60, 20]; nồng độ bề mặt hạt ngoại suy tuyến tính; thông lượng trong hạt bằng biến đổi Kirchhoff; tính chất điện giải tại mặt ô lấy trung bình điều hoà | `Nn, Ns, Np, Nrn, Nrp` | Lựa chọn số học, bài không ghi. Mã nguồn dùng [10, 10, 10 \| 100, 20] (Expt 2) và [10, 5, 5 \| 100, 20] (Expt 3). Sai số lưới in trong `selftest.md`. |

### Giả định của riêng phần kiểm chứng (không thuộc bài báo nào)

| Mã | Nội dung | Giá trị dùng | Lý do |
|---|---|---|---|
| GD-09 | Nhiệt độ môi trường và nhiệt độ đầu | bằng nhiệt độ bề mặt cell đo ngay trước khi xả, riêng cho từng cell | Phần lớn file của Zenodo 4864437 không có cảm biến môi trường; ở các file có, nó lệch 0.2–0.6 K so với cảm biến cell lúc nghỉ. Brosa Planella 2021 (`set_parameters.py`) cũng làm vậy. |
| GD-11 | Hệ số trao đổi nhiệt h | h = 20 W/m²/K (SI Table 6) trong `approved`, `paper`, `code`; biến thể `approved_h_tau`: h = ρc_p,eff(T_amb)·V_cell/(τ·A_cool) với τ = 582 s (trung vị đo được, data/ket_qua_du_lieu.md A.3) | h = 20 được Li 2025 chỉnh tay cho cell làm mát đáy; O'Regan chỉnh tay h = 15 cho chính bộ dữ liệu buồng nhiệt này. Biến thể `approved_h_tau` là **nhận dạng h từ dữ liệu** (ghi rõ), không phải mặc định. |
| GD-13 | Trạng thái lithium ban đầu | trên đường cân bằng lithium đi qua điểm 100 % SOC của Li 2025 (x = 0.8771, y = 0.2411), sao cho OCV mô hình (nhánh xả) = áp nghỉ đo được | Cell kiểm chứng (LG M50, O'Regan) khác lô với cell mà Li 2025 chỉnh tham số (LG M50T, Kirkaldy 2024); lượng lithium thật của từng cell không đo được. |
| GD-17 | Kênh nhiệt độ dùng để so sánh | cặp nhiệt giữa thân cell ("Temp Cell") | Mô hình lumped chỉ có một nhiệt độ; bề mặt cell thật không đồng đều (ở 2C đầu dương chỉ tăng ≈ 41 %, đầu âm 57–60 % so với giữa thân; data/ket_qua_du_lieu.md). |
| GD-23 | Lần xả có số liệu nhiệt độ bất thường | gắn cờ nếu T trước khi xả lệch > 5 K so với nhiệt độ danh định, hoặc nhảy > 5 K giữa hai mẫu liên tiếp (ví dụ cell 791, 1C, 0 °C, lần xả 2: cặp nhiệt đọc 27.7 °C trước khi xả) | Báo cáo **cả hai**: tất cả các lần xả và bỏ các lần bất thường; các lần này vẫn có trong `validation.csv`. |

## 4. Chờ quyết định

| Mã | Nội dung | Tình trạng |
|---|---|---|
| GD-16 | Chặn số học và sự kiện dừng khi bề mặt hạt bão hoà | Code hiện tại: stoichiometry bề mặt kẹp trong [10⁻⁸, 1 − 10⁻⁸] khi tính j₀, OCP (như PyBaMM); c_e ≥ 0.01 mol/m³ trong log/căn; mô phỏng **dừng** nếu c_e < 1 mol/m³ hoặc stoichiometry bề mặt chạm 10⁻⁴ / 1 − 10⁻⁴. **Khác mã nguồn:** PyBaMM v23.4.1 của tác giả chỉ kẹp mà không dừng, tức cho phép nồng độ bề mặt vượt c_max. Hệ quả: sạc CC 0.3C ở 25 °C làm bề mặt hạt cực âm phía màng ngăn chạm x = 1 trước khi áp đạt 4.2 V (ở ≈ 4.16 V, còn thiếu ≈ 0.3–0.4 Ah; xem `selftest.md` mục 3 và 4). **Chưa quyết định; đang được chẩn đoán riêng** (`src/dfn/diag/`). |

Các mục còn mở thuộc phần lão hoá (đơn vị β, t_0, k_cr — doi_chieu P2) nằm trong `tai_lieu/dac_ta_lao_hoa.md` và sẽ được bổ sung vào đây ở bước B/C.

## 5. Mô hình rút gọn và NMPC (bước E, G — `src/nmpc/`, `tai_lieu/mo_hinh_rut_gon.md`)

Các giá trị dưới đây **không có trong bài báo nào**: là giả định (được người dùng cho phép, ghi rõ) hoặc lựa chọn số học. Đổi trong `src/nmpc/nmpc_config.m`.

| Mã | Nội dung | Giá trị dùng | Loại / lý do |
|---|---|---|---|
| GD-24 | Định nghĩa SOC và trạng thái đầu vùng sạc | SOC = (x̄_n − x₀)/(x₁₀₀ − x₀) của cực âm (x₀ = 0.0279, x₁₀₀ = 0.8771, Li 2025 SI Note 8), dung lượng tương ứng 4.861 Ah; trạng thái đầu là trạng thái nghỉ cân bằng trên đường lithium đi qua điểm 100 % SOC (như GD-13), T = T_môi trường | Lựa chọn. Cặp (x₀, y₀) in trong SI không cùng lượng lithium với (x₁₀₀, y₁₀₀) (lệch ≈ 0.02 theo y); giữ lượng lithium không đổi giữa các vùng. C-rate tính theo 5 A (SI Note 9). |
| GD-25 | Điều kiện dừng CCCV cho vùng sạc một phần | CC tới 4.2 V **hoặc** SOC cuối vùng; CV 4.2 V tới I ≤ C/50 = 0.1 A **hoặc** SOC cuối vùng; cái nào tới trước | Theo yêu cầu người dùng. Vùng kết thúc < 100 % thường dừng ngay trong pha CC. Nếu DFN dừng vì bề mặt hạt bão hoà (GD-16) thì CCCV **không hoàn thành** vùng và được báo nguyên trạng. |
| GD-26 | Dòng sạc tối đa của NMPC | I_max = 2C = 10 A | **Giả định.** Không có nguồn cho phép sạc 2C với LG M50 trong các bài đã đọc; NMPC còn bị chặn bởi các ràng buộc V, T, η_Li, x_s. |
| GD-27 | Nhiệt độ cell tối đa | T_max = 45 °C | **Giả định.** |
| GD-28 | Biên an toàn thế mạ lithium | η_Li (phía màng ngăn) ≥ δ = δ_cơ bản + 35 mV = 10 + 35 = 45 mV | **Giả định.** Phần 35 mV: người dùng duyệt 17/11/2026 vì điện áp sạc của mô hình thấp ≈ 30–38 mV ở ≈ 1 Ah cuối (tai_lieu/dieu_tra_dien_ap_sac.md); đọc từ `par.ctrl.delta_pl_extra` (dfn_params.m, GD-41). Sai số η_Li của ROM so với DFN khi sạc: RMS 0.5–3.3 mV, lớn nhất 1.1–12.8 mV (cấu hình D, mo_hinh_rut_gon.md mục 7). |
| GD-29 | Stoichiometry bề mặt cực âm phía màng ngăn tối đa | x_s,sep ≤ 0.99 | **Giả định.** Cách sự kiện dừng của DFN (1 − 10⁻⁴, GD-16) 1 %. |
| GD-30 | Lựa chọn số học của NMPC | N = 20 khoảng dự báo phủ **toàn bộ** phần sạc còn lại (t_f tự do); giải lại mỗi T_s = 30 s; IRK Radau IIA 2 nấc × 8 bước mỗi khoảng (2 bước: Newton của IRK phân kỳ, xem mo_hinh_rut_gon.md mục 8.4); trọng số w_loss = 10 /mAh, w_ΔI = 10⁻⁴; phạt ràng buộc mềm (L1/L2) V, η_Li, x_s: 10⁴/10⁵, T: 10²/10², ngân sách: 10²/10² (theo giờ), SOC cuối: 10³/10⁴; Levenberg–Marquardt 1 (thay cho tìm kiếm đường); vùng tin cậy t_f × [1/1.3, 1.3]; t_f ≤ 20 h ở chế độ "không giới hạn" | Lựa chọn số học, giải thích ở mo_hinh_rut_gon.md mục 8. |
| GD-31 | Lão hoá **tạm thời** dùng trong NMPC và chấm điểm | Tốc độ SEI (bề mặt + vết nứt) và mạ lithium (`aging_rates.m`, công thức đã duyệt ở mục 1) tính từ thế điện cực; độ dày SEI, độ nhám S₀ = 2.908 giữ giá trị BOL trong một lần sạc; dòng phụ **không** hồi tiếp vào DFN; "lithium mất" = SEI + lithium mạ (thuận nghịch + chết) | Tạm thời cho tới khi bước C cài lão hoá vào DFN. Tham số: D_int, E_SEI, k_Li, γ₀ theo Li 2025 Table 3 cột "5 coupled"; c_int theo SI Table 8. **Cần người dùng quyết định**: có tính phần lithium mạ thuận nghịch (sẽ bóc lại khi xả) vào hàm mục tiêu hay không (mo_hinh_rut_gon.md mục 9). |
