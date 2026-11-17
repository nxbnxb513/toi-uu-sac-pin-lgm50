# Điều tra: vì sao điện áp SẠC của mô hình thấp hơn đo?

*Viết 17/11/2026. Chỉ điều tra và báo cáo: **không** đổi mô hình, không đổi tham số mặc định. Mọi số mô phỏng lấy từ CI: workflow `diag.yml`, job `hyst` (lượt chạy 44045350150, 42 job, đều thành công; job `report` báo lỗi chỉ vì bước tóm tắt, đã sửa). Code: `src/dfn/diag/diag_hyst.m` (chạy từng pha sạc/xả của dữ liệu), `diag_decomp.m` (tách điện áp), `diag_run.m`, các biến thể trong `diag_variant.m`. Script tổng hợp: `src/dfn/diag/hyst_tong_hop.py`, `hyst_khoang_cach.py`.*

Dữ liệu: Zenodo 4864437 (cell LG M50, 0/10/25 °C, 4 C-rate xả, mỗi file 2 chu kỳ). Chỉ dùng các lần sạc **sau một lần xả** (15–16 lần mỗi nhiệt độ). Số trong bảng là **trung vị** trên các cell, trừ khi ghi khác.

---

## 0. Kết luận ngắn

1. **Sai số lớn nhất của pha sạc không nằm ở cuối mà ở ĐẦU pha sạc.** Khi bắt đầu sạc từ SOC thấp, mô hình nhảy áp tức thời **+342 mV** (25 °C), đo thật chỉ **+69 mV**. Nguyên nhân: mô hình hysteresis "zero-state" (Li 2025 SI pt. S46–S47) chuyển ngay sang nhánh lithiation của cực âm, mà ở x ≈ 0.04–0.07 hai nhánh (S3), (S4) lệch nhau **240–350 mV**. Đây là lý do RMSE pha CC lớn (46–106 mV). Chắc chắn (đo trực tiếp).
2. **Ở cuối pha CC** (1 Ah trên cùng), điện áp sạc mô hình thấp hơn đo **42–47 mV** (25 °C, so ở cùng Ah tính từ trạng thái đầy), trong khi điện áp xả C/10 của mô hình ở đúng chỗ đó chỉ lệch **+3…+5 mV**. Vậy phần thiếu là **riêng của chiều sạc**, khoảng:
   - **≈ 8–12 mV** do điện trở tức thời của mô hình thiếu ≈ 5.5 mΩ (thấy cả khi xả, đối xứng), và
   - **≈ 30–38 mV còn lại chỉ có khi sạc**, tập trung ở ~1 Ah trên cùng (x_n ≈ 0.75–0.88, y_p ≈ 0.24–0.31), giảm về ~0 khi xa đỉnh 1.5 Ah.
3. **Không có thay đổi đơn lẻ nào có nguồn** giải thích phần 30–38 mV này. Mô hình chỉ có hysteresis **6.7 mV** ở đó (cực âm +8.9, cực dương **−2.1** — nhánh S2 thấp hơn S1). Đổi nhánh OCP của cực dương chỉ thay đổi ±2 mV. Cực nào gây ra? **Không xác định được chắc chắn** từ dữ liệu này (xem mục 5).
4. Dữ liệu cho thấy **cell kiểm chứng có nhiều lithium hơn** cell mà Li 2025 cân bằng: "khép Ah" lệch −0.15…−0.21 Ah với x100 = 0.8771, còn −0.01…−0.05 Ah với x100 = 0.9014 (giá trị "5 Ah" của Li SI Note 8 / Chen 2020). Nhưng điều này **không** sửa được điện áp sạc.

---

## 1. Giao thức đo có đúng như mô phỏng không? (câu 4)

| Mục | Dữ liệu (đọc từ file) | Mô phỏng dùng |
|---|---|---|
| Dòng CC | 1.6695–1.6702 A (≈ C/3 của 5 Ah) | đúng giá trị đo từng lần |
| Dòng cắt CV | 0.249–0.250 A (C/20) | đúng giá trị đo |
| Nghỉ trước sạc | 7200 s (mọi lần) | trạng thái cân bằng tại áp nghỉ cuối (GD-13) |
| Nhiệt độ đầu | T bề mặt trước pha: −0.6…1.6 / 9.2…11.3 / 24.2…25.6 °C | T đầu = T môi trường = T đo trước pha (GD-09) |
| Lấy mẫu | 1 s (file 1C, 2C); ~40–60 s (file C/10, C/2); mẫu đầu ở thời điểm 0 s của bước | – |

- **Chữ trong bài khác dữ liệu:** O'Regan 2022 tr. 8 ghi "charged at 0.3C with a C/100 current cut-off". File đo cho 1.67 A và cắt 0.25 A. Mô phỏng theo **dữ liệu**, nên không lệch giao thức.
- **Nhiệt độ khi sạc:** đo tăng 1.6 K tại 98 % thời gian CC (25 °C), mô hình 1.1 K (0 °C: 2.4 / 2.06 K). Mô hình **mát hơn** một chút, tức đẩy áp sạc lên chứ không xuống. Biến thể đẳng nhiệt (isoT) chỉ đổi sai số cuối CC 3 mV.
- Trạng thái đầu: áp nghỉ sau xả nằm ở nhánh xả, đúng như mô hình dùng khi nghỉ (I = 0 → nhánh xả, theo S46–S47 có offset 0.2 A/m²).

## 2. Tách điện áp mô hình khi sạc và khi xả, cùng SOC, cùng dòng 1.67 A (câu 1)

Cách tách (`diag_decomp.m`): tại mỗi nút điện cực φ_s − φ_e = U(x mặt hạt) + η + j·R_màng, lấy trung bình theo nút, nên tổng **đúng chính xác** (phần dư 0.0 mV). Cell 781, 25 °C, cuối CC (x̄_n = 0.802, ȳ_p ≈ 0.27). Đơn vị mV; dấu = phần cộng vào V khi sạc, trừ khỏi V khi xả.

| Thành phần | Sạc 1.67 A | Xả 1.67 A (cùng x̄_n) |
|---|---|---|
| OCV khối, nhánh xả | 4086 | 4086 |
| Hysteresis (nhánh sạc − nhánh xả) | **+6.7** (âm +8.9, dương −2.1) | 0 |
| R_contact · I (11.5 mΩ) | 19.2 | 19.2 |
| Điện giải: thế khuếch tán (nồng độ) | 15.7 | 16.4 |
| Điện giải: ohm | 7.3 | 7.3 |
| Quá thế động học cực âm | 9.5 | 8.3 |
| Quá thế động học cực dương | 5.6 | 6.2 |
| Phân cực nồng độ pha rắn cực âm | 6.1 | 9.4 |
| Phân cực nồng độ pha rắn cực dương | 0.3 | 0.1 |
| Màng SEI | 1.8 | 1.8 |
| Ohm pha rắn | 0.5 | 0.5 |
| **Tổng lệch so với OCV khối nhánh xả** | **+72.8** → V = 4159 | **−69.4** → V = 4017 |

**Kết luận câu 1:** trong mô hình, sạc và xả gần như **đối xứng**; thứ duy nhất chỉ có khi sạc là hysteresis 6.7 mV. Ở 0 °C và 10 °C: sạc +135 mV (trong đó hysteresis 11.7) / xả −147 mV ở 0 °C; sạc +102 (hysteresis 9.3) / xả −111 mV ở 10 °C — tức phân cực khi sạc của mô hình còn **nhỏ hơn** khi xả 9–24 mV, không lớn hơn. Không thành phần nào của mô hình tạo ra 30–40 mV "chỉ khi sạc".

Lưu ý: cuối CC, j phía màng ngăn / j trung bình rơi về 0.4 (hạt phía màng ngăn đã đầy, các hạt khác gánh dòng) nhưng điện áp mô hình gần như không tăng — đó là GD-16 (`lua_chon_Ds_am.md`).

## 3. Dữ liệu nói gì, không cần khớp tham số (câu 2)

### 3a. So sạc và xả ở cùng "Ah tính từ trạng thái đầy"

Chuỗi đo: sạc CCCV → nghỉ 2 h (trạng thái "đầy") → xả. Đếm Ah từ trạng thái đầy đó cho cả pha sạc (Ah còn phải nạp) và pha xả kế tiếp (Ah đã xả). Không cần OCV hay khớp gì. Mô hình được đặt cùng mốc (OCV mô hình = áp nghỉ sau sạc). Sai số mô hình − đo, mV, 25 °C:

| Ah từ đầy | Sạc 1.67 A | Xả C/10 (0.5 A) | Xả C/2 | Xả 1C |
|---|---|---|---|---|
| 0.6 | **−47** | +4 | +12 | +24 |
| 0.8 | **−42** | +3 | +15 | +25 |
| 1.0 | −30 | +5 | +20 | +30 |
| 1.5 | −5 | +6 | +27 | +44 |

(cell 781, 785, 789; 0 °C và 10 °C tương tự: sạc −41…−46 mV ở 0.8 Ah, xả C/10 +3…+11 mV.)

- Xả C/10 (dòng nhỏ, gần OCV) khớp trong vài mV → **OCV nhánh xả của mô hình ở vùng đỉnh là đúng**.
- Sai số xả tăng theo dòng (+4 → +24 mV từ 0.5 → 5 A): mô hình **thiếu điện trở**, đối xứng (xem 3c).
- Sai số sạc âm, lớn, và **biến mất sau ~1.5 Ah** → có một phần **riêng của chiều sạc ở vùng SOC cao**.

### 3b. Áp nghỉ sau sạc và sau xả; hysteresis trong nguồn

- Áp nghỉ 2 h sau CCCV: 4.133 / 4.149 / 4.163 V (0/10/25 °C). Ngay sau đó xả C/10 thì mô hình (nhánh xả) khớp +3…+5 mV → **sau 2 h nghỉ, cell nằm sát nhánh xả**; nếu đổi cách hiểu áp nghỉ sang nhánh sạc thì vị trí chỉ đổi 0.024 Ah (q = 0.061 so với 0.037 Ah). Dữ liệu này **không** cho thấy hysteresis tĩnh lớn ở đỉnh.
- Không có điểm nghỉ nào đạt tới **cùng SOC từ hai chiều** trong bộ dữ liệu này (nghỉ sau sạc ở ~100 %, sau xả ở ~0 %), nên **không đo trực tiếp được hysteresis tĩnh** ở x_n 0.8–0.9.
- **Hysteresis mô hình dùng** (S1–S4, Li 2025 SI Note 8): cực âm (S4)−(S3) = 8.8 mV (x = 0.8), 9.6 (0.85), 11.6 (0.9), 15.6 (0.95); cực dương (S2)−(S1) = −0.5 (y = 0.25), −2.0 (0.27), −2.4 (0.28), −2.1 (0.30) mV, tức **nhánh delithiation của NMC thấp hơn nhánh lithiation** ở vùng này (ngược chiều vật lý thông thường). Tổng OCV sạc − OCV xả: 7–11 mV.
- Ở SOC thấp hysteresis cực âm rất lớn: 464 mV (x = 0.02), 352 (0.04), 241 (0.07), 175 (0.1), 69 (0.15), 50 (0.2), 44 (0.3) mV.
- **Chữ trong nguồn:** Chen 2020 tr. 10–11: NMC và graphite-SiOx có "small hysteresis" giữa lithiation và delithiation; hysteresis lớn nhất ở **SOC thấp**; tr. 16, 22: "significant hysteresis at low states of lithiation" của cực âm. Chen không in số. O'Regan 2022 tr. 18: các thông số đo **chỉ theo chiều xả** (dương lithiation, âm delithiation) vì hysteresis thường bị bỏ qua. O'Kane 2022 SI: dùng **nhánh xả** của OCP như Chen. Li 2025 SI Note 7: dùng zero-state hysteresis; Note 8: (S1)–(S4) khớp số liệu O'Regan cung cấp, RMSE < 8 mV. Không nguồn nào in con số hysteresis ở x_n 0.8–0.9 hay y_p 0.25–0.3 ngoài chính (S1)–(S4).

### 3c. Bước nhảy áp tức thời khi đổi dòng

| | Đo | Mô hình (approved) |
|---|---|---|
| Bắt đầu XẢ từ đầy, 25 °C, C/2 / 1C / 2C | −77 / −152 / −303 mV → **30.3–30.9 mΩ** | −65 / −128 / −249 mV → 24.9–25.8 mΩ |
| Bắt đầu XẢ, 0 °C, 1C / 2C | −260 / −481 mV | −204 / −356 mV |
| Bắt đầu SẠC từ SOC thấp, 25 / 10 / 0 °C | **+69 / +88 / +109 mV** | **+342 / +334 / +287 mV** |
| Sau 10 s sạc, 25 °C | +108 mV | +358 mV |

- Khi xả, mô hình thiếu ~**16 % điện trở tức thời** (≈ 5–5.5 mΩ ở 25 °C). Đối xứng, nên cũng làm áp sạc thấp ≈ 9 mV ở 1.67 A. Để so: Kirkaldy 2024 (cell M50T, dữ liệu của chính bài) R(0.1 s) đầu đời = 26.4 mΩ ở 25 °C (`data/derived/D_kirkaldy_per_cell_rpt.csv`).
- Khi bắt đầu sạc, mô hình nhảy thêm ~270 mV so với đo. Bỏ hysteresis (luôn nhánh xả) thì mô hình nhảy +78 mV, sát số đo +69 mV. **Chắc chắn:** việc chuyển nhánh tức thời ở SOC thấp mâu thuẫn với dữ liệu. Cell thật cần nạp một lượng Ah mới chuyển dần sang nhánh sạc; zero-state không có "trí nhớ" này.
- Tốc độ sigmoid (k = 100 m²/A, offset 0.2 A/m²) **không ảnh hưởng**: khi sạc 1.67 A, |J| = 16.3 A/m², và cuối CV 0.25 A vẫn 2.4 A/m², nên tanh đã bão hoà (m = 0 chính xác tới 10⁻¹⁰⁰). Tính trực tiếp, không cần chạy.

## 4. Đổi đúng MỘT thứ (chỉ trong chẩn đoán) (câu 3)

Cột: sai số cuối CC (mô hình − đo tại 98 % thời gian CC chung, mV); sai số ở 0.6–0.8 Ah từ đầy (sạc / xả C/10, 25 °C); có tới 4.2 V không; t_CC; pha CV; RMSE pha CC; **RMSE xả 90 % đầu, trung bình 93 lần xả, 12 điều kiện** (gốc 38.5 mV).

| Biến thể (một thay đổi) | Cuối CC 0/10/25 °C | 0.6–0.8 Ah: sạc / xả C/10 | Tới 4.2 V? | t_CC mô hình / đo (25 °C) | CV (25 °C) | RMSE CC 25 °C | RMSE xả (12 đk) |
|---|---|---|---|---|---|---|---|
| gốc (approved) | −21 / −20 / −27 | −47…−42 / +4 | không (4.159 V) | 9090 / 9197 s | – / 2177 s | 68 | **38.5** |
| R_contact = 17 mΩ (Rc17) | −11 / −11 / −18 | −38…−32 / +1 | không (4.168) | 9090 | – | 75 | **25.0** |
| R_contact = 0 (Rc0, SI Table 2 in) | −40 / −40 / −46 | −66…−61 / +9 | không | 9090 | – | 58 | 86.8 |
| cực dương luôn nhánh lith. (pos_lith) | −24 / −22 / −26 | −47…−44 / +4 | không | 9090 | – | 62 | 38.5 |
| cực dương luôn nhánh delith. (pos_delith) | −24 / −24 / −29 | – | không | 9114 | – | 67 | 44.0 |
| cực âm luôn nhánh delith. (neg_delith) | −35 / −36 / −45 | −60…−55 / +4 | không | 9639 | – | 28 | 38.5 |
| cực âm luôn nhánh lith. (neg_lith) | −92 / −74 / −53 | – | không | 9653 | – | 34 | 70.8 |
| không hysteresis, nhánh xả cả hai cực (hys_delith) | −39 / −37 / −43 | −60…−57 / +4 | không | 9639 | – | **32** | 38.5 |
| luôn nhánh sạc cả hai cực (hys_lith) | −93 / −76 / −54 | – | không | 9666 | – | 33 | 78.2 |
| đẳng nhiệt (isoT) | −10 / −14 / −24 | −45…−40 / +4 | không | 9057 | – | 68 | 75.7 |
| x100 = 0.9014 (cân bằng 5 Ah) | −40 / −37 / −34 | −45…−41 / +5…+6 | không (4.151) | 9055 | – | 61 | 42.8 |
| tắt khuếch tán do ứng suất (no_stress, GD-10) | +13 / +2 / −15 | −31…−18 / −9…−11 | chỉ 0 °C | 9107 | 149 s (0 °C) | 82 | 46.9 |
| bỏ thermodynamic factor (no_tdf, GD-18) | −34 / −33 / −38 | −55…−50 / +6…+7 | chỉ 25 °C | 9752 | 90 s | 64 | 57.5 |
| j₀,n × 0.228 (≈ Chen 2020) | +40 / +28 / −4 | −21…−16 / −5…−4 | **có, mọi T** | 9432 | 849 / 2177 s | 100 | 33.0 |

Khép Ah (q(áp nghỉ trước) − q(áp nghỉ sau) − Ah đo): gốc −0.13 / −0.13 / −0.18 Ah; x100_fresh −0.01 / −0.02 / −0.05 Ah. Dung lượng xả C/10 ở 25 °C: đo 4.922, gốc 4.824, x100_fresh 4.959 Ah.

Đọc bảng:
- **Nhánh OCP cực dương** (câu hỏi chính về "cực nào"): ±2 mV ở cuối CC. Không phải nguyên nhân.
- **Nhánh cực âm / hysteresis:** bỏ hysteresis sửa được **đầu** pha sạc (RMSE 68 → 32 mV) nhưng làm **cuối** pha sạc tệ hơn ~15 mV (mất 6.7–11 mV hysteresis ở đỉnh). Không ảnh hưởng pha xả.
- **Rc17** là thay đổi duy nhất vừa giảm sai số cuối CC (≈ 9 mV) vừa cải thiện rõ pha xả (38.5 → 25.0 mV). Nó chỉ bù phần **đối xứng**; phần riêng của sạc (−32…−38 mV ở đỉnh) vẫn còn.
- **j₀,n × 0.228** làm mô hình tới 4.2 V và cuối CC gần đúng ở 25 °C, nhưng sai ở chỗ khác (+68 mV giữa pha, +40 mV cuối CC ở 0 °C; CV 849 s so với đo 2177 s). Không phải lời giải.
- **no_stress, no_tdf:** thêm phân cực cả hai chiều; xả xấu đi (46.9, 57.5 mV).
- **Nhiệt độ, lượng lithium (x100):** không giải thích điện áp sạc.

## 5. Cái gì chắc chắn, cái gì chưa

**Chắc chắn (đo trực tiếp, không khớp):**
- Giao thức mô phỏng khớp giao thức đo (dòng, dòng cắt, nghỉ, T đầu).
- Bước nhảy khi bắt đầu sạc: đo +69…+109 mV; mô hình +287…+342 mV do zero-state hysteresis của cực âm ở x thấp.
- Điện trở tức thời khi bắt đầu xả: đo 30.3–30.9 mΩ (25 °C); mô hình 24.9–25.8 mΩ.
- OCV nhánh xả của mô hình ở ~1.5 Ah trên cùng khớp dữ liệu C/10 trong vài mV.
- Ở ~1 Ah trên cùng, áp sạc đo cao hơn mô hình 42–47 mV (25 °C); sau khi trừ phần điện trở đối xứng còn **~30–38 mV chỉ có khi sạc**. Mô hình chỉ có 6.7 mV cho phần này.
- Cell kiểm chứng có Ah giữa hai áp nghỉ lớn hơn mô hình 0.13–0.18 Ah; x100 = 0.9014 khép được.

**Chưa chắc chắn:**
- Phần 30–38 mV là **hysteresis OCP thật lớn hơn** (S1)–(S4) ở x_n 0.75–0.9 / y_p 0.24–0.31, hay **quá thế riêng chiều sạc** (ví dụ động học hoặc khuếch tán khi delithiation NMC ở y thấp, hoặc khi lithiation graphite ở giai đoạn cuối). Dữ liệu này **không tách được** hai khả năng, và cũng **không chỉ ra được cực âm hay cực dương**: không có điện cực tham chiếu, không có điểm nghỉ đạt từ hai chiều ở cùng SOC. Gợi ý (chưa chứng minh): sau 2 h nghỉ cell nằm sát nhánh xả, nên nếu là hysteresis thì nó phải tự hồi trong vòng 2 h, tức không phải dạng "zero-state" tĩnh.
- 5.5 mΩ thiếu là ở R_contact, ở điện giải hay ở điện cực: bước nhảy 1 s không phân biệt được.

## 6. Các hướng sửa (người dùng quyết định; chưa áp dụng)

| Hướng | Cơ sở nguồn | Hiệu quả đo được (CI) | Loại |
|---|---|---|---|
| Không dùng hysteresis, chỉ nhánh xả (như O'Kane 2022 SI, Chen 2020 PyBaMM; O'Regan đo theo chiều xả) | có chữ trong nguồn, nhưng **trái** Li 2025 SI Note 7 (bài chính in S46–S47) | RMSE pha CC 68 → 32 mV (25 °C); cuối CC tệ hơn ~15 mV; xả không đổi | sửa có nguồn, nhưng phải chọn giữa hai nguồn (quy tắc 2: bài chính in zero-state → giữ, trừ khi người dùng coi đây là "sai rõ ràng") |
| Hysteresis có trạng thái (chuyển dần theo Ah) thay cho zero-state | **không** có trong các bài đã đọc; cần tham số mới | chưa thử | sẽ là giả định / chỉnh |
| x100 = 0.9014 cho cell kiểm chứng (cân bằng 5 Ah, Li SI Note 8; Chen 2020 tr. 13) | có nguồn; cell kiểm chứng là LG M50 "fresh", không phải M50T đã lưu kho | khép Ah −0.18 → −0.05 Ah; dung lượng C/10 4.824 → 4.959 (đo 4.922); áp sạc **không** cải thiện; RMSE xả 38.5 → 42.8 | sửa có nguồn, **chỉ cho phần kiểm chứng** (GD-13), không cho mô hình lão hoá M50T |
| R_contact 17 mΩ | **không** nguồn; số nhận dạng từ bước nhảy áp của chính dữ liệu kiểm chứng | cuối CC −27 → −18 mV; RMSE xả 38.5 → 25.0 | **chỉnh tham số** theo dữ liệu (nếu dùng phải ghi rõ, và nên nhận dạng trên dữ liệu khác, ví dụ R(0.1 s) của Kirkaldy) |
| j₀,n theo Chen 2020 | có nguồn (bộ tham số khác) | tới 4.2 V nhưng sai giữa pha +68 mV, CV 849 / 2177 s | không khuyến nghị |
| Phần 30–38 mV riêng của sạc | chưa có nguồn nào in số | – | cần dữ liệu khác: OCV/GITT hai chiều ở SOC cao (dữ liệu thô O'Regan, Zenodo 5171874, nếu có nhánh sạc), hoặc dữ liệu điện cực tham chiếu |

Ghi chú cho GD-16: không biến thể nào làm mô hình sạc tới 4.2 V **và** khớp pha CV đo (2177 s, +0.54 Ah ở 25 °C). Phần thiếu ~30–38 mV ở đỉnh chính là lý do mô hình "không đủ áp" để vào CV đúng lúc.
