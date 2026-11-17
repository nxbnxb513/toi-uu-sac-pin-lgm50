# Chọn hệ số khuếch tán pha rắn cực âm D_s,n — và nguyên nhân thật của GD-16

*Viết 17/11/2026. Mọi số mô phỏng lấy từ CI (workflow `diag.yml`, code `src/dfn/diag/`). Không đổi tham số mặc định: file này chỉ đưa bằng chứng để người dùng quyết định.*

## 1. Câu hỏi

Khi sạc CC 0.3C ở 25 °C từ 0 % SOC, mô hình dừng ở **4.158 V** (chưa tới 4.2 V) vì bề mặt hạt graphite sát màng ngăn chạm x = 1, đã nạp **4.508 Ah** (GD-16). Giả thuyết của người dùng: D_s,n quá nhỏ nên Li không kịp đi vào lõi hạt.

**Kết luận ngắn: D_s,n KHÔNG phải nguyên nhân.** Hạt sát màng ngăn đầy **cả lõi** (x trung bình trong hạt 0.9998), không chỉ bề mặt. Tăng D_s,n gấp 30 lần hay thay bằng hằng số 3.3·10⁻¹⁴ m²/s đều không đổi kết quả. Nguyên nhân nằm ở chỗ khác (mục 5).

## 2. D_s,n đang dùng (Li 2025 SI pt. S17 + Supp. Table 7, nhân R_cor = 3.0321, kèm hệ số ứng suất GD-10)

| x | 0.5 | 0.6 | 0.7 | 0.8 | 0.85 | 0.88 | 0.9 | 0.95 | 0.99 | 1.0 |
|---|---|---|---|---|---|---|---|---|---|---|
| D 25 °C (m²/s) | 3.7e-16 | 3.1e-14 | 7.6e-16 | 4.2e-16 | 4.4e-16 | 7.3e-16 | 1.3e-15 | 1.7e-14 | 3.7e-13 | 9.1e-13 |
| D 10 °C (m²/s), E = 2·10⁴ | 2.5e-16 | 2.1e-14 | 5.1e-16 | 2.8e-16 | 3.0e-16 | 4.9e-16 | 8.9e-16 | 1.1e-14 | 2.5e-13 | 6.0e-13 |
| R²/D ở 25 °C (s), R = 5.86 µm | 9.2e4 | 1.1e3 | 4.5e4 | 8.2e4 | 7.7e4 | 4.7e4 | 2.6e4 | 2.0e3 | 93 | 38 |

Hệ số nhân do ứng suất ở cực âm: 1.30 (x = 0.5) đến 1.60 (x = 1). Với E_act = 6·10⁴ (GD-01) D ở 10 °C nhỏ hơn thêm 2.3 lần.

- Vùng x = 0.65–0.88: R²/D ≈ 5–8·10⁴ s, lớn hơn thời gian sạc 0.3C (≈ 1.2·10⁴ s). Vậy D nhỏ thật ở vùng này.
- Gần x → 1 hàm fit **không sụp** mà **tăng mạnh** (9·10⁻¹³ ở x = 1). Không có “sụp do ngoại suy”.
- Dữ liệu GITT thô của O'Regan (`data/derived/B_diffusivity.csv`, cực âm) phủ x = **0.0085–0.9914** (5 °C: 0.018–0.991; 25 °C: 0.015–0.980; 45 °C: 0.008–0.957). Hàm fit chỉ ra ngoài khoảng này ở x > 0.991.
- O'Regan 2022 tr. 20 nói giá trị GITT của graphite-SiOy trong khoảng 10⁻¹⁴–10⁻¹² cm²/s (= **10⁻¹⁸–10⁻¹⁶ m²/s**) là **bị đánh giá thấp** (vùng plateau, quá thế phản ứng lấn át). Số liệu thô ở 25 °C: 58 % điểm dưới 10⁻¹⁶ m²/s; riêng x = 0.6–0.9 là 96 % (trung vị 2.6·10⁻¹⁸). Hàm fit × 3.03 ở vùng này là 3–7·10⁻¹⁶, tức đã cao hơn số đo khoảng 100 lần nhưng vẫn sát mép vùng “bị đánh giá thấp”.
- Trung bình số học của fit × 3.03 trên x = 0.03–0.88: 6.5·10⁻¹⁵ m²/s; của số thô 25 °C: 8.3·10⁻¹⁶ m²/s.
- Các giá trị trong chữ/bảng của tài liệu: Chen 2020 Table V (tr. 15) GITT trung bình 1.74·10⁻¹⁵ m²/s; Table IX (tr. 20) chỉnh thành 3.3·10⁻¹⁴ (tăng ≈ 1800 %, chỉnh theo xả 1C), riêng xả C/2 dùng 1.3·10⁻¹⁴, xả 1.5C dùng 6.3·10⁻¹⁴; O'Kane 2022 dùng 3.3·10⁻¹⁴ (bộ Chen 2020). O'Regan 2022 tr. 21: hệ số 3.03 (= R_cor) để trung bình fit khớp trung bình đo; tr. 31: mô hình chỉ được chỉnh trên **xả** 1C/25 °C.

## 3. Tiêu chí (chốt trước khi xem ứng viên nào thắng)

- **C1** Sạc 0.3C tới 4.2 V + CV tới C/100 ở 25 °C phải chạy hết mà stoich bề mặt không chạm 1; dung lượng sạc phải hợp với dung lượng bài báo nêu (4.865 Ah, Kirkaldy 2024 tr. 3).
- **C2** Ưu tiên số đo trên chính cell này; tôn trọng cảnh báo của tác giả đo; thay đổi ít nhất.
- **C3** Không làm xấu sai số xả trên 12 điều kiện dữ liệu mở; và so trực tiếp với **pha sạc** trong dữ liệu mở (chưa từng dùng để chỉnh).
- **C4** Hệ số nào cũng phải lấy từ nguồn hoặc nhận dạng trên dữ liệu không dùng để kiểm chứng nó.

## 4. Kết quả các ứng viên D_s,n (CI)

Sạc từ 0 % SOC trên đường cân bằng lithium (GD-13), lưới mặc định, bộ `approved`:

| Ứng viên | 0.3C/25 °C: dừng vì | V lúc dừng CC | Ah CC | x trung bình hạt [phía collector, phía màng ngăn] | C1 |
|---|---|---|---|---|---|
| A. hàm S17 như in | bề mặt chạm 1 | 4.158 | 4.508 | [0.720, 1.000] | trượt |
| B. S17 chỉ trong x = 0.0085–0.9914 | bề mặt chạm 1 | 4.158 | 4.508 | [0.720, 1.000] | trượt |
| C. hằng số 3.3·10⁻¹⁴ | bề mặt chạm 1 | 4.162 | 4.580 | [0.719, 0.999] | trượt |
| D. S17 × 2 / × 3 / × 5 / × 10 / × 30 | bề mặt chạm 1 | 4.158 / 4.158 / 4.158 / 4.159 / 4.161 | 4.529 / 4.537 / 4.547 / 4.561 / 4.573 | sát màng ngăn 0.9999 ở mọi mức | trượt |

Cùng các ứng viên ở 1C/25 °C và 0.3C/10 °C: đều dừng do bề mặt chạm 1 trước 4.2 V. Ở C/20/25 °C cả năm đều tới 4.2 V (bề mặt lớn nhất 0.934–0.940).

So với **pha sạc trong dữ liệu mở** (Zenodo 4864437; cell LG M50 sạc CC 1.67 A tới 4.2 V rồi CV tới 0.25 A):

| 25 °C, cell 781 | Thời gian CC tới 4.2 V | Ah pha CC | Pha CV |
|---|---|---|---|
| Đo | 9420 s | 4.369 | 2196 s, thêm 0.54 Ah |
| A (như in) | dừng ở 9360 s, 4.159 V | 4.342 | không chạy được |
| C (3.3·10⁻¹⁴) | dừng ở 9491 s, 4.159 V | 4.403 | không chạy được |
| D × 10 | dừng ở 9453 s, 4.158 V | 4.385 | không chạy được |

Ở cả 0, 10, 25 °C và mọi cell: mô hình dừng vì bề mặt bão hoà **gần đúng thời điểm** cell thật chạm 4.2 V (lệch ≤ 3 %), nhưng điện áp mô hình lúc đó thấp hơn đo khoảng **30–45 mV** (25 °C). Đổi D_s,n không đổi điều này.

**Không ứng viên D_s,n nào qua được C1, nên C2–C4 không phân định được giữa chúng.** Không có hệ số nhân nào (D) làm C1 đạt, nên không nhận dạng được hệ số từ pha sạc.

## 5. Nguyên nhân thật (thử đổi đúng một thứ mỗi lần, 0.3C/25 °C)

| Thay đổi duy nhất | Tới 4.2 V? | x bề mặt lớn nhất | j(màng ngăn)/j(trung bình) |
|---|---|---|---|
| (gốc) | không | 1.000 | 1.80 |
| D_e × 10 (chỉ chẩn đoán) | **có** | 0.968 | 1.43 |
| Bruggeman điện giải cực âm = 0 (chỉ chẩn đoán) | **có** | 0.954 | 1.16 |
| Bruggeman màng ngăn = 0 | không | 1.000 | 1.80 |
| κ × 3 | không (4.185 V) | 1.000 | 1.69 |
| bỏ thermodynamic factor (đúng như SI Table 2 in, GD-18) | **có** (0.3C/25 °C), không ở 0.3C/10 °C | 0.996 | 1.62 |
| j₀,n × 0.228 (≈ Chen 2020) | **có** | 0.995 | 1.51 |
| U_n có điểm kỳ dị ở x = 1 (chỉ chẩn đoán) | **có** | 0.990 | 1.79 |
| luôn dùng nhánh delithiation cực âm | có (sát: 0.9993) | 0.999 | 1.88 |
| tắt khuếch tán do ứng suất, E_act = 6·10⁴, bỏ điện trở màng SEI, đổi điểm đầu, lưới mịn | không | 1.000 | ≈ 1.7–1.9 |

Cơ chế: trong cực âm dày 85 µm, độ xốp 0.235, phản ứng dồn về phía màng ngăn (gấp 1.4–1.8 lần trung bình suốt quá trình sạc) do phân cực nồng độ của điện giải (c_e 844–1106 mol/m³, cộng thế khuếch tán với TDF ≈ 2.2). Đường OCP lithiation (S3) gần như phẳng tới tận x = 1 (U_n = 84 mV ở x = 0.85, 68 mV ở x = 1), nên hạt sắp đầy không “đẩy” dòng sang chỗ khác: hạt phía màng ngăn đầy hẳn (x = 1) trong khi hạt phía collector mới 0.72.

**Không phải lỗi code**: bảo toàn lithium sai lệch 7.7·10⁻¹⁵ (tương đối); nút phía màng ngăn đúng là nút N_n (c_e ở đó cao hơn phía collector khi sạc, đúng chiều vật lý); không phụ thuộc lưới.

## 6. So với pha sạc của dữ liệu mở (cell 781–792, 25 °C; chi tiết: log job `data` của workflow `diag.yml`)

| Biến thể | CC tới 4.2 V? | t CC mô hình / đo (cell 781) | Pha CV mô hình / đo | V mô hình − V đo ở 98 % thời gian CC | RMSE điện áp pha CC |
|---|---|---|---|---|---|
| gốc (approved) | không, dừng 4.159 V | 9360 / 9420 s | – / 2196 s | −24 … −30 mV | 49–105 mV |
| D_s,n hằng 3.3·10⁻¹⁴ | không, 4.159 V | 9491 / 9420 s | – | −31 … −37 mV | 41–99 mV |
| U_n có điểm kỳ dị ở x = 1 | có | 9914 / 9420 s (dài hơn 5 %) | 708 / 2196 s | −24 … −26 mV | 49–105 mV |
| Bruggeman = 0 | có | 10096 / 9420 s (dài hơn 7 %) | 417 / 2196 s | −46 … −50 mV | 35–97 mV |
| nhánh delithiation | không, 4.18 V | 9909 / 9420 s | – | −40 … −43 mV | 28–41 mV |

Nhận xét: ở cả 0, 10, 25 °C, cell thật chạm 4.2 V **gần đúng lúc** hạt sát màng ngăn của mô hình đầy (lệch ≤ 3 %), nhưng điện áp sạc của mô hình thấp hơn đo vài chục mV. Pha CV đo được dài (≈ 2200 s ở 25 °C, thêm 0.54 Ah) cho thấy cell thật cũng không đều mạnh ở cuối pha CC. Không biến thể nào ở trên tái tạo đúng pha sạc đo được.

## 7. Việc người dùng cần quyết định

1. **D_s,n**: giữ hàm S17 × 3.03 như in (ứng viên A). Không ứng viên nào (B, C, D) giải được GD-16 hay làm khớp pha sạc tốt hơn; đổi D_s,n chỉ là chỉnh tham số không có lợi ích kiểm chứng được.
2. **GD-16** nằm ở phân bố phản ứng theo bề dày + OCP phẳng tới x = 1 + điện áp sạc của mô hình thấp hơn đo. Các hướng (chưa áp dụng):
   - GD-18: SI Table 2 của Li 2025 in phương trình thế điện giải **không có** thermodynamic factor. Dùng đúng như in thì 0.3C/25 °C sạc tới 4.2 V (bề mặt lớn nhất 0.996) nhưng 0.3C/10 °C vẫn bão hoà; còn Landesfeind 2019 (pt. [2]) định nghĩa TDF để dùng đúng chỗ đó.
   - Tìm nguyên nhân điện áp sạc thấp (nhánh OCP khi sạc, động học khi sạc): cần thêm thí nghiệm.
   - Cách của mã nguồn tác giả (kẹp stoich, cho nồng độ vượt c_max) là lách, không phải sửa.
