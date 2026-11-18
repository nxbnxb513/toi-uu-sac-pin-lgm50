# Kết quả kiểm chứng mô hình lão hoá "5 coupled" (bước C)

*Viết ngày 18/11/2026. Số liệu lấy từ CI, không chỉnh tham số.*

## 1. Đã chạy gì

- Mô hình: DFN + lão hoá "5 coupled" của Li 2025 (SEI, SEI trên vết nứt, mạ lithium, nứt hạt, LAM, cạn dung môi). Tham số giữ nguyên như đã thống nhất.
- Thí nghiệm mô phỏng lại: Expt 2 (vùng 70–85 %) và Expt 3 (vùng 85–100 %) của Kirkaldy 2024, ở 10, 25 và 40 °C. Mỗi trường hợp có 12 set × 515 chu kỳ (khoảng 9.4 kAh điện lượng thông qua). Các chu kỳ được mô phỏng **từng cái một** (không nhảy chu kỳ).
- V_cv = 4.116 V. Người dùng đã chốt coi mức này tương đương 4.2 V của giao thức.
- **SOH = dung lượng xả 0.1C / 4.865 Ah**, theo quyết định của người dùng. Số liệu thực nghiệm cũng được chia cho 4.865 Ah. Cột phụ "SOH theo RPT0" chia cho dung lượng ở lần đo đầu tiên của chính nó.
- Các lần chạy CI:
  - [44123422399](https://github.com/nxbnxb513/toi-uu-sac-pin-lgm50/actions/runs/44123422399): năm trường hợp.
  - [44196614322](https://github.com/nxbnxb513/toi-uu-sac-pin-lgm50/actions/runs/44196614322): Expt 2 ở 25 °C, 12 job kiểm chứng nhảy chu kỳ, và báo cáo gộp (artifact `aging-report`).
- Bản sao báo cáo nằm trong `tai_lieu/ket_qua_lao_hoa/`:
  - `aging_validation.md`: bảng từng RPT.
  - `aging_summary.csv`, `aging_vs_exp_long.csv`, `jumpcheck.csv`.
  - Hình `aging_expt2.png`, `aging_expt3.png`.
- Cách tính sai số: MPE theo Li 2025 pt. (1), lấy trên các RPT thực nghiệm, bỏ các điểm có giá trị thực nghiệm bằng 0. MPE_tot = MPE_SOH/2 + (MPE_R + MPE_LLI + MPE_LAMNE + MPE_LAMPE)/8. RMSE tính trên cùng các điểm, đơn vị là điểm % (riêng R tính bằng mΩ).

## 2. Lỗi số đã sửa

| Lỗi | Nguyên nhân | Sửa |
|---|---|---|
| Expt 2 ở 25 °C dừng sau 1.5 giờ, không để lại checkpoint | **Không phải lỗi số.** GitHub báo runner mất kết nối ("lost communication"). Checkpoint chỉ được tải lên ở cuối job nên mất hết. | Mỗi chặng chia thành 3 đoạn MATLAB, mỗi đoạn 1.6 h. Sau mỗi đoạn, checkpoint được tải lên. Chặng sau tải checkpoint về và chạy tiếp, kể cả khi chặng trước hỏng. Thêm tuỳ chọn `resume_run` để lấy checkpoint từ một lần chạy cũ, và `mode=report` để chỉ gộp báo cáo. Trường hợp này phải chạy lại từ đầu vì chưa có checkpoint nào; lần chạy lại xong trong 6.1 h. |
| Cả 4 job kiểm chứng nhảy chu kỳ hỏng ở chu kỳ 92–212 ("Unable to meet integration tolerances", "khởi tạo nhất quán thất bại") | Bản cũ ngoại suy **mọi** trạng thái. Những thành phần vốn tắt nhanh sau vài chu kỳ (profile nồng độ trong hạt, c_Li, phân bố theo x) bị khuếch đại thêm sau mỗi lần nhảy. Sau 4–8 lần nhảy, θ ra ngoài [0, 1] (−0.33 … 2.8) và c_Li âm (tới −2·10⁴ mol/m³). | Viết `ag_jump.m`. Chỉ ngoại suy các biến lão hoá chậm. Lithium trong hạt của mỗi điện cực được dịch đều theo xu hướng tổng lượng Li. Các biến nhanh giữ như chu kỳ cuối. Lithium được bảo toàn chính xác. Nếu kết quả ra ngoài miền vật lý thì giảm J; nếu chu kỳ ngay sau bước nhảy hỏng thì quay về trước bước nhảy và giảm J. Ghi trong GD-58. Cả 12/12 job đều chạy xong, không có lần quay lui nào. |

Lần chạy từng chu kỳ không gặp lỗi số nào. Bảo toàn lithium lệch ≤ 3·10⁻⁹.

## 3. So với thực nghiệm (Kirkaldy 2024) và với sai số Li 2025 công bố

### 3.1 MPE (%)

Mỗi ô ghi "mô hình này / Li 2025 công bố". Với Expt 3, số của Li 2025 lấy theo SI Table 12, theo cách đọc suy luận.

| Expt | T | SOH | R_0.1s | LLI | LAM_NE | LAM_PE | **tot** | SOH theo RPT0 (mô hình này) |
|---|---|---|---|---|---|---|---|---|
| 2 (70–85 %) | 10 °C | 0.74 / 0.42 | 3.74 / 4.49 | 61.8 / 25.1 | 67.2 / 37.6 | 62.3 / 27.0 | **24.8 / 12.0** | 3.40 |
| 2 | 25 °C | 0.76 / 0.88 | 6.24 / 5.50 | 57.2 / 22.8 | 55.4 / 20.6 | 55.9 / 30.9 | **22.2 / 10.4** | 2.55 |
| 2 | 40 °C | 0.74 / 0.57 | 2.64 / 3.68 | 61.4 / 31.6 | 62.6 / 34.2 | 51.8 / 24.6 | **22.7 / 12.1** | 3.87 |
| 3 (85–100 %) | 10 °C | 4.60 / 5.30 | 10.3 / 6.95 | 47.8 / 38.1 | 82.5 / 81.1 | 70.1 / 61.5 | **28.6 / 26.1** | 8.13 |
| 3 | 25 °C | 1.88 / 2.44 | 2.99 / 2.64 | 40.5 / 28.7 | 43.5 / 32.6 | 62.2 / 54.6 | **19.6 / 16.0** | 3.88 |
| 3 | 40 °C | 1.97 / 0.75 | 7.24 / 5.86 | 33.8 / 22.7 | 33.1 / 19.8 | 41.4 / 33.3 | **15.4 / 10.6** | 2.00 |

Kiểm tra lại script: tính MPE cho chính đường mô hình của tác giả (Source Data Fig. 3–4, chỉ có Expt 2) bằng script này cho MPE_tot = 13.0 / 8.9 / 10.7 % ở 10/25/40 °C. Số công bố là 12.0 / 10.4 / 12.1 %, nên cách tính khớp với bài.

### 3.2 RMSE (điểm %; R tính bằng mΩ)

| Expt | T | SOH | SOH theo RPT0 | R_0.1s | LLI | LAM_NE | LAM_PE |
|---|---|---|---|---|---|---|---|
| 2 | 10 °C | 0.88 | 3.24 | 1.04 | 4.61 | 4.29 | 2.90 |
| 2 | 25 °C | 0.89 | 2.44 | 1.85 | 3.55 | 2.43 | 2.10 |
| 2 | 40 °C | 0.77 | 3.63 | 0.72 | 4.74 | 3.45 | 1.96 |
| 3 | 10 °C | 4.82 | 7.69 | 5.54 | 6.61 | 5.10 | 7.21 |
| 3 | 25 °C | 2.05 | 3.86 | 1.14 | 4.34 | 4.31 | 5.34 |
| 3 | 40 °C | 2.03 | 2.07 | 2.64 | 2.79 | 2.58 | 2.29 |

Để so sánh, RMSE của mô hình tác giả ở Expt 2 (10/25/40 °C) là:

| Đại lượng | 10 °C | 25 °C | 40 °C |
|---|---|---|---|
| SOH theo RPT0 | 0.55 | 0.81 | 0.76 |
| LLI | 1.80 | 1.00 | 1.90 |
| LAM_NE | 2.30 | 0.63 | 1.50 |

### 3.3 Giá trị ở RPT thực nghiệm cuối cùng

Mô hình được nội suy về cùng điện lượng thông qua. Mỗi ô ghi "mô hình / thực nghiệm" (%).

| Expt | T | Q_thr (kAh) | SOH | LLI | LAM_NE | LAM_PE |
|---|---|---|---|---|---|---|
| 2 | 10 °C | 9.09 | 90.0 / 89.9 | 5.3 / 10.3 | 4.0 / 8.3 | 3.2 / 5.2 |
| 2 | 25 °C | 9.12 | 90.3 / 90.7 | 5.0 / 9.2 | 3.6 / 6.7 | 3.1 / 4.6 |
| 2 | 40 °C | 9.13 | 89.9 / 88.8 | 5.5 / 11.3 | 3.8 / 8.4 | 3.5 / 5.6 |
| 3 | 10 °C | 7.15 | 86.9 / 78.6 | 8.1 / 18.0 | 6.3 / 15.5 | 4.5 / 12.4 |
| 3 | 25 °C | 8.34 | 86.1 / 86.7 | 8.7 / 13.8 | 6.5 / 14.4 | 5.1 / 9.4 |
| 3 | 40 °C | 9.12 | 84.8 / 84.9 | 9.9 / 13.3 | 7.2 / 11.4 | 5.9 / 7.5 |

## 4. Đọc kết quả

1. **Mô hình chưa tái hiện được tốc độ lão hoá.** Đã không chỉnh tham số.
   - LLI, LAM_NE, LAM_PE của mô hình chỉ bằng khoảng **½** thực nghiệm. So với đường mô hình của chính tác giả, LLI cuối của mô hình này bằng khoảng 0.55 lần ở Expt 2 và 0.85 lần ở Expt 3 (40 °C).
   - MPE_tot gấp khoảng **2 lần** số Li 2025 công bố ở Expt 2. Ở Expt 3, MPE_tot cao hơn số công bố 3–5 điểm.
2. **SOH theo định nghĩa mặc định (chia 4.865 Ah) khớp tốt ở Expt 2 (MPE ≈ 0.75 %), nhưng chủ yếu là do trùng hợp.**
   - Với V_cv = 4.116 V, dung lượng RPT0 của mô hình chỉ có 4.672 Ah. Vì vậy SOH mô hình bắt đầu ở 96.0 %, trong khi thực nghiệm bắt đầu ở 99.2–100.4 %.
   - Sau đó mô hình giảm chậm hơn. Hai sai lệch bù trừ nhau nên tới khoảng 9 kAh hai đường gặp nhau.
   - Nếu tính SOH theo RPT0, MPE_SOH là 2.5–3.9 % ở Expt 2. Con số này cao hơn nhiều so với 0.4–0.9 % mà Li 2025 công bố.
3. **Phụ thuộc nhiệt độ gần như bằng 0**: chênh lệch giữa ba nhiệt độ < 0.6 điểm SOH. Thực nghiệm Expt 3 ở 10 °C suy giảm mạnh hơn hẳn: SOH 78.6 % ở 7.2 kAh, trong khi mô hình cho 86.9 %. Mô hình của tác giả cũng không bắt được điều này (MPE_SOH công bố 5.3 %).
4. Phần LLI lớn nhất trong mô hình là **cạn dung môi**: 3.2–3.6 % ở Expt 2 và 5.6–6.0 % ở Expt 3. Tiếp theo là SEI trên vết nứt (1.1 / 1.9 %) và SEI bề mặt (0.6 / 1.0 %). Mạ lithium và lithium chết chỉ < 0.15 %. Tác giả báo cho Expt 2 ở 25 °C: cạn dung môi 5.2 %, SEI vết nứt 1.7 %, SEI 0.9 %.
5. R_0.1s tăng 1.7–3.3 mΩ, đúng cỡ thực nghiệm ở Expt 2. Ở Expt 3, R tăng ít hơn thực nghiệm.

### Lý do có thể (chưa kiểm chứng, chưa đổi gì)

- **Hệ số 1/4 trong tốc độ dày SEI.** Hệ số này lấy theo bài gốc Single 2018 (đối chiếu S3); bài Li 2025 và code của tác giả dùng 1/2. SEI giới hạn bởi khuếch tán dày theo √(k·t), nên giảm k một nửa thì độ dày còn khoảng 0.71 lần. Con số này gần đúng với tỉ lệ SEI, SEI vết nứt và cạn dung môi (cạn dung môi tính từ thể tích SEI) giữa mô hình này và mô hình tác giả ở Expt 2, 25 °C (≈ 0.6–0.65). Đây là ứng viên lớn nhất.
- **V_cv = 4.116 V thay cho 4.2 V.** Cửa sổ Expt 2 được đặt sau khi sạc đầy tới V_cv. Vì vậy cả cửa sổ thấp hơn khoảng 4 % dung lượng, thế anode cao hơn và SEI chậm hơn. Ở Expt 3, mỗi chu kỳ không lên tới 4.2 V. Người dùng đã chốt coi hai mức tương đương. Muốn đo ảnh hưởng thì có sẵn biến thể `vcv42` (chưa chạy).
- **Có thêm F/(RT) trong số mũ SEI** (theo bài gốc) và **độ xốp tính với a_n hiện thời** (GD-61). Cả hai khác cách code của tác giả.
- Độ phụ thuộc nhiệt độ yếu là đặc điểm của chính bộ tham số "5 coupled": mô hình của tác giả cũng gần như không đổi theo T. Đây là giới hạn của mô hình, không phải lỗi cài đặt.

Đây là những khác biệt có thể làm đổi kết luận chính, nên **người dùng cần quyết** có chạy thử độ nhạy hay không. Có hai lựa chọn: (a) chạy hệ số 1/2 như code của tác giả; (b) chạy `vcv42`. Mỗi lựa chọn mất khoảng 1–1.5 h CI nếu dùng nhảy chu kỳ.

## 5. Độ chính xác của phương pháp nhảy chu kỳ (để dùng cho lưới so sánh)

So với mô phỏng từng chu kỳ, trên đủ 12 set (12 RPT), 6 trường hợp, J_max = 20 và 50.

| | J_max = 20 | J_max = 50 |
|---|---|---|
| Sai lệch SOH lớn nhất | ≤ 0.093 điểm % | ≤ 0.091 điểm % |
| Sai lệch LLI / LAM_NE / LAM_PE lớn nhất | ≤ 0.064 / 0.017 / 0.013 điểm % | ≤ 0.058 / 0.027 / 0.028 điểm % |
| Sai lệch R_0.1s lớn nhất | ≤ 0.10 mΩ | ≤ 0.11 mΩ |
| Sai lệch so với phần suy giảm, ở RPT 12: SOH / LLI | ≤ 0.82 % / ≤ 0.64 % | ≤ 0.80 % / ≤ 0.59 % |
| Sai lệch so với phần tăng của R, ở RPT 12 | 2.8–3.3 % | 3.0–3.6 % |
| Phần Li phải bù mỗi bước nhảy | ≤ 3.7·10⁻⁴ | ≤ 9.4·10⁻⁴ |
| Thời gian (từng chu kỳ → nhảy chu kỳ) | 3.2–8.1 h → 0.9–1.7 h | 3.2–8.1 h → 0.6–1.1 h |

Kết luận: với J_max = 20, sai số do nhảy chu kỳ nhỏ hơn khoảng 50–100 lần so với sai lệch giữa mô hình và thực nghiệm. Thời gian chạy nhanh hơn 3.4–5.4 lần (J_max = 20). Phương pháp dùng được cho lưới so sánh. Chi tiết từng trường hợp: `tai_lieu/ket_qua_lao_hoa/jumpcheck.csv`.
