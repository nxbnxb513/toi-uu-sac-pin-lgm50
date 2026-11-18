# Kết quả tầng 2: lão hoá silicon ở SOC thấp (bước D, 19/11/2026)

> **Tầng 2 là GIẢ ĐỊNH.** Không bài báo nào cho phương trình hay tham số mất silicon của pin LG M50T. Mọi kết quả "tầng 2" phải ghi nhãn giả định. Tầng 1 (mô hình "5 coupled" của Li 2025, giữ nguyên) vẫn là kết quả có cơ sở.

## 1. Tóm tắt ngắn

- Tầng 2 thêm **một** biến: lượng silicon còn lại ở mỗi điểm của cực âm. Silicon mất khi cực âm nhả lithium ở mức lithium thấp (cuối pha xả sâu). Mặc định **tắt**; khi tắt, tầng 1 không đổi một con số nào (tự kiểm tra: lệch 0).
- Chỉ **một** hằng số được hiệu chỉnh (k), cùng với việc chọn dạng đường cong (A/B/C), trên **đúng một tập dữ liệu**: 0–30 %, 25 °C. Các tập khác (10 °C, 40 °C, 0–100 %, 70–85 %, 85–100 %) dùng để kiểm tra.
- **Được:** đường mất silicon ở 0–30 %, 25 °C khớp tốt (RMSE 8 điểm %). Tầng 2 giảm sai số LAM cực âm ở mọi cửa sổ (0–30 %: 18–24 → 10–15 điểm; 0–100 %: 14–18 → 8–13 điểm). Lượng silicon mất ở 70–85 % và 85–100 % (≈ 8–10 % ở 4 kAh) cũng gần số đo (5–11 %).
- **Không được:**
  - Mất lithium (LLI) ở 0–30 % vẫn sai rất xa: mô hình 1 % so với đo 17 %. Silicon mất lúc gần như rỗng lithium nên mang theo rất ít lithium. Vì vậy SOH ở 0–30 % vẫn sai khoảng 12 điểm (mô hình 94.5 %, đo 82.6 % ở 4 kAh, 25 °C).
  - Tầng 2 không có phụ thuộc nhiệt độ riêng. Mất silicon ở 10 °C vì vậy bị tính quá cao (59 % so với 28 % đo), ở 40 °C quá thấp (59 % so với 78 %).
  - Mất graphite ở 0–30 % gần như bằng 0 (đo 9–12 %).
- **70–85 % và 85–100 %:** tầng 2 làm thay đổi nhỏ nhưng không bằng 0. Trên 9.5 kAh, SOH lệch tối đa 1.2–1.4 điểm, LLI 0.9–1.0 điểm, LAM_NE 1.9–2.0 điểm. Sai số so với đo hầu như giữ nguyên (SOH) hoặc giảm (LLI, LAM_NE). Chi tiết ở mục 5.

## 2. Mô hình (chi tiết: `dac_ta_lao_hoa.md` mục 16; giả định GD-90 … GD-95 trong `gia_dinh.md`)

Lượng silicon còn lại r = ε_Si/ε_Si,0 (ban đầu 15.2 % dung lượng cực âm, theo Kirkaldy 2024 Table 7):

- Phần dòng do silicon mang: w_Si từ 0.1 (khi bề mặt hạt nhiều lithium) tới 0.9 (khi ít lithium, dưới stoichiometry 0.14), theo mô tả của Ai 2022.
- Độ chênh nồng độ trong hạt silicon: Δc = j_Si·R_Si/(5F·D_Si), với R_Si = 1.52 µm và D_Si = 1.67·10⁻¹⁴ m²/s (Ai 2022 Table 3).
- Tốc độ mất: dε_Si/dt = −k·(Δc)²·r^s. Chỉ tính khi hạt nhả lithium. Đây là luật "mất vật liệu do ứng suất" của Li 2025 áp cho silicon, với mọi hằng số cơ học chưa biết gộp vào k.
- Phần silicon mất được trừ vào tổng vật liệu cực âm của tầng 1. Diện tích phản ứng, dung lượng, độ xốp và sổ sách lithium vì thế đi theo đúng cơ chế sẵn có, nên lithium vẫn bảo toàn.

Ba dạng đường cong (GD-92) chỉ khác cách tốc độ phụ thuộc r:

| Dạng | Ý nghĩa | Tốc độ ∝ |
|---|---|---|
| A | đúng như đề xuất in: diện tích Si co lại, dòng dồn vào phần Si còn lại | 1/r (tăng tốc tới khi hết sạch) |
| B | mật độ dòng trên mỗi hạt Si còn lại giữ nguyên | r |
| C | như B, thêm giả thiết hạt yếu hỏng trước, phần còn lại bền hơn | r² |

## 3. Hiệu chỉnh (chỉ 0–30 %, 25 °C)

- Mục tiêu: LAM_Si trung bình của 3 cell (D, E, F) ở 14 RPT. Số liệu lấy từ cột `LAM_NE_Si` của `data/derived/D_kirkaldy_per_cell_rpt.csv`, tính bằng script từ dữ liệu Zenodo, không đọc từ hình.
- Cách làm:
  - Chạy 3 lần "dò" ở dạng B với k = 3·10⁻¹⁵, 3·10⁻¹⁴ và 3·10⁻¹³ (run [44258818797](https://github.com/nxbnxb513/toi-uu-sac-pin-lgm50/actions/runs/44258818797)).
  - Từ mỗi lần dò suy ra đường cong của mọi dạng và mọi k (`ag_si_report.m` mục 1).
- Kết quả (RMSE nhỏ nhất của LAM_Si, điểm %):

| Lần dò | A | B | C | k* dạng C |
|---|---|---|---|---|
| k₀ = 3·10⁻¹⁵ (cuối 27 % Si mất) | 28.7 | 13.8 | **8.2** | 3.32·10⁻¹⁴ |
| k₀ = 3·10⁻¹⁴ (cuối 94 %) | 28.4 | 13.2 | **7.9** | 3.53·10⁻¹⁴ |
| k₀ = 3·10⁻¹³ (hết Si sau 1 set, không dùng) | 41.8 | 11.0 | 6.2 | 3.64·10⁻¹⁴ |

- **Chọn dạng C, k = 3.5·10⁻¹⁴ (m³/mol)²/s.**
  - Hai lần dò dùng được cho k* lệch nhau 6 %, và tối ưu nằm trong khoảng dò nên không cần dò rộng hơn.
  - Lần chạy đầy đủ với giá trị chọn cho RMSE 8.0 điểm, đúng như dự đoán 7.9.
  - Dạng A (đúng như bản đề xuất) bị loại: đường cong tăng chậm rồi sập về 100 %, ngược với thực nghiệm (mất nhanh lúc đầu rồi chững lại).

## 4. Tầng 1 / tầng 2 / thực nghiệm

Lần chạy:
- Tầng 1: run [44258808944](https://github.com/nxbnxb513/toi-uu-sac-pin-lgm50/actions/runs/44258808944).
- Tầng 2: run [44319826055](https://github.com/nxbnxb513/toi-uu-sac-pin-lgm50/actions/runs/44319826055).
- Cả hai: 12 set mỗi trường hợp, nhảy chu kỳ J_max = 20, V_cv = 4.116 V. Đây là lần đầu chạy Expt 1 và Expt 5; giao thức theo GD-94.
- Mọi số là %; SOH = Q_0.1C / 4.865 Ah.

Bản đầy đủ theo từng RPT: `tai_lieu/ket_qua_silicon/silicon_report.md`, `si_vs_exp_long.csv`. Hình: `silicon_expt1.png`, `silicon_expt5.png`, `silicon_expt2.png`, `silicon_expt3.png`.

### 4.1 Giá trị ở 4 kAh (đo / tầng 1 / tầng 2)

| Cửa sổ | T | SOH | LLI | LAM_NE | LAM_Si (đo / T2) |
|---|---|---|---|---|---|
| 0–30 % | 10 °C | 91.4 / 95.5 / 94.4 | 8.6 / 0.4 / 1.2 | 7.5 / 0.3 / 9.0 | 27.8 / 58.7 |
| 0–30 % | **25 °C (hiệu chỉnh)** | 82.6 / 95.6 / 94.5 | 16.8 / 0.3 / 1.1 | 19.8 / 0.3 / 9.0 | 65.9 / 58.5 |
| 0–30 % | 40 °C | 81.1 / 95.6 / 94.6 | 18.9 / 0.3 / 1.0 | 19.4 / 0.3 / 9.0 | 78.3 / 58.6 |
| 0–100 % | 10 °C | 82.6 / 93.4 / 92.6 | 16.7 / 2.2 / 2.8 | 20.1 / 1.9 / 7.1 | 29.3 / 37.0 |
| 0–100 % | 25 °C | 87.7 / 93.7 / 93.0 | 12.7 / 2.0 / 2.5 | 14.9 / 1.6 / 6.7 | 27.6 / 35.8 |
| 0–100 % | 40 °C | 87.1 / 93.6 / 92.9 | 13.2 / 2.0 / 2.5 | 15.8 / 1.6 / 6.6 | 30.3 / 35.8 |
| 70–85 % | 25 °C | 94.0 / 93.1 / 92.5 | 6.0 / 2.6 / 3.0 | 4.2 / 1.8 / 2.8 | 8.4 / 8.3 |
| 85–100 % | 25 °C | 90.9 / 90.5 / 89.8 | 9.1 / 4.9 / 5.4 | 7.2 / 3.6 / 4.6 | 11.2 / 9.5 |

### 4.2 RMSE trên mọi RPT (điểm %; tầng 1 → tầng 2)

| Cửa sổ | T | SOH | LLI | LAM_NE | LAM_Si (T2) |
|---|---|---|---|---|---|
| 0–30 % | 10 °C | 18.1 → 17.2 | 20.5 → 19.8 | 18.2 → 11.3 | 25.2 |
| 0–30 % | 25 °C | 19.9 → 18.9 | 22.4 → 21.7 | 23.7 → 14.7 | 8.0 |
| 0–30 % | 40 °C | 14.2 → 13.3 | 17.8 → 17.2 | 18.6 → 10.2 | 17.9 |
| 0–100 % | 10 °C | 11.3 → 10.3 | 13.9 → 13.3 | 18.1 → 12.5 | 10.7 |
| 0–100 % | 25 °C | 6.3 → 5.5 | 10.6 → 10.0 | 13.8 → 8.4 | 11.8 |
| 0–100 % | 40 °C | 7.7 → 7.0 | 10.5 → 10.1 | 14.5 → 9.1 | 10.6 |

(Ở 0–30 %, 4 RPT cuối của thực nghiệm (> 8 kAh) là giai đoạn "cliff edge" của từng cell, nên RMSE của SOH/LLI bị kéo lớn.)

### 4.3 Các mốc in trong văn bản Kirkaldy 2022 (chỉ để kiểm tra)

| Mốc | Bài in | Tầng 2 |
|---|---|---|
| Mất Si, 0–30 %, 40 °C, 4 kAh | 80 % | 58.6 % (thiếu) |
| Mất Si, 0–30 %, 25/40 °C, 4 kAh | > 70 % | 58.5 / 58.6 % (không đạt) |
| Mất Si, 0–30 %, 25 °C, 5 kAh | 80 % | 63.6 % |
| Mất Si, 0–100 %, 25 °C, 5 kAh | > 30 % | 41.1 % (đạt) |
| Mất graphite, 0–30 %, 40 °C, 4 kAh | 10 % | 0.1 % (thiếu hẳn) |
| Phần lớn mất Si xảy ra trong 2 kAh đầu (0–30 %) | định tính | 71 % của mức 4 kAh đã xảy ra trong 2 kAh đầu (đo: 74 %) — đạt |
| 10 °C mất Si ít hơn 25/40 °C | định tính | không phân biệt (58.7 / 58.5 / 58.6 %) — **không đạt** |

Mốc 80 %/70 % của Kirkaldy 2022 cao hơn trung bình Kirkaldy 2024 ở 25 °C (66 % ở 4 kAh). Hiệu chỉnh theo dữ liệu số từng RPT ở 25 °C, không theo các mốc chữ này.

## 5. 70–85 % và 85–100 % có giữ nguyên không?

Hiệu tầng 2 − tầng 1 lớn nhất trên mọi RPT chung (cùng J_max = 20), tới ≈ 9.5 kAh:

| Cửa sổ | T | max \|ΔSOH\| | max \|ΔLLI\| | max \|ΔLAM_NE\| | Si mất cuối (T2) |
|---|---|---|---|---|---|
| 70–85 % | 10 / 25 / 40 °C | 1.24 / 1.22 / 1.20 | 0.89 / 0.88 / 0.86 | 2.04 / 2.01 / 1.98 | 17.5 / 17.3 / 17.6 % |
| 85–100 % | 10 / 25 / 40 °C | 1.40 / 1.43 / 1.41 | 0.99 / 1.01 / 0.99 | 2.00 / 1.95 / 1.91 | 19.6 / 19.5 / 19.8 % |

Kết luận:
- Thay đổi **nhỏ nhưng không bằng 0**. Ở 4 kAh, SOH giảm 0.6–0.7 điểm, LLI tăng 0.4–0.5 điểm, LAM_NE tăng 0.9–1.0 điểm.
- Nguồn gốc của thay đổi: giả định silicon vẫn mang 10 % dòng khi pin nhiều lithium (w_lo = 0.1), cộng với các lần xả sâu trong RPT.
- Mức này **phù hợp với số đo**: thực nghiệm cũng mất 5–11 % silicon ở hai cửa sổ này sau 4 kAh, mô hình cho 8.3–9.7 %.
- Sai số so với đo:
  - LLI và LAM_NE **giảm** ở cả 6 trường hợp (ví dụ 70–85 %, 25 °C: LAM_NE 2.43 → 1.22).
  - SOH tăng nhẹ ở 4 trường hợp (lớn nhất 70–85 %, 25 °C: 0.88 → 1.42) và giảm ở 2 trường hợp.
- Vì vậy kết luận của tầng 1 cho hai cửa sổ này **giữ nguyên** (mô hình vẫn cho LLI/LAM khoảng một nửa số đo).

## 6. Kiểm chứng số

- **Tự kiểm tra** (run [44258798913](https://github.com/nxbnxb513/toi-uu-sac-pin-lgm50/actions/runs/44258798913), `ag_si_selftest.m`):
  - Với k = 0, tầng 2 trùng tầng 1: lệch vế phải 0, lệch điện áp 1.7·10⁻¹⁴ V sau một chu kỳ.
  - JPattern đủ.
  - Bảo toàn lithium qua một chu kỳ (k lớn): ≤ 1.4·10⁻¹¹.
  - Bước nhảy chu kỳ ngoại suy ε_Si đúng tuyến tính.
- **Bảo toàn lithium trong mọi lần chạy dài:** ≤ 2.9·10⁻⁹ (tầng 1 và 2).
- **Nhảy chu kỳ** (Expt 1, 25 °C, tầng 2; J_max = 20 so với chạy từng chu kỳ trên 4 RPT đầu, là phần chạy từng chu kỳ làm xong trong 5.3 h):
  - Lệch tối đa: SOH 0.015, LLI 0.011, LAM_NE 0.06, LAM_Si 0.39 điểm %.
  - Đây là giai đoạn silicon mất nhanh nhất. Nhanh hơn khoảng 8 lần.
- Job `run2 (2, 40, si)` báo lỗi chỉ vì xung đột tên artifact khi tải lên (409); chặng 3 đã chạy tiếp từ checkpoint và xong đủ 12 RPT.

## 7. Giới hạn (phải nêu trong báo cáo)

1. Tầng 2 là giả định: dạng luật, phần dòng w_Si, ngưỡng stoichiometry và số mũ đều không có nguồn. Chỉ k và dạng đường cong được chỉnh, trên 1 trong 12 tập dữ liệu.
2. Không có phụ thuộc nhiệt độ riêng cho silicon. Mô hình không tái hiện được việc 10 °C mất silicon ít hơn hẳn và 40 °C nhiều hơn.
3. OCP cực âm vẫn là đường "gộp". Mất silicon chỉ làm co đều dung lượng cực âm, không làm mất "đoạn silicon" ở SOC thấp như thí nghiệm thấy.
4. LLI ở 0–30 % (đo 17–19 % ở 4 kAh) **không giải thích được** bằng mất silicon trong mô hình này (chỉ thêm khoảng 1 điểm). Cả tầng 1 lẫn tầng 2 đều thiếu một nguồn mất lithium lớn ở SOC thấp. Vì vậy với các vùng sạc bắt đầu từ 0 %, mức lão hoá tuyệt đối của mô hình thấp hơn thực tế nhiều.
5. Mất graphite ở 0–30 % (đo 9–12 %) không có trong mô hình.
6. Các phần trên không ảnh hưởng tới so sánh "tối ưu so với CCCV trong cùng một vùng". Silicon mất chủ yếu ở pha xả sâu, giống nhau cho mọi cách sạc. Nhưng nếu so giữa các vùng sạc thì phải báo cả hai tầng.
