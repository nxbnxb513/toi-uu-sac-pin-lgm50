# Kirkaldy et al. 2022 — mất silicon nhanh ở SOC thấp (LG M50T, 0–30% vs 0–100%)

> Đã đọc TOÀN VĂN bản publisher (ACS Appl. Energy Mater., 10 trang). Supporting Information (Fig. S1–S13, Tables S1–S2) KHÔNG tải được (pubs.acs.org chặn) → chưa đọc.
> File: `tai_lieu/Kirkaldy2022_ACSAEM.pdf`; text: `toan_van_trich_xuat/Kirkaldy2022.txt`.
> Số trang ghi "tr. N" là trang PDF (1–10) = trang tạp chí 13367–13376.

## 1. Trích dẫn, tạp chí, giấy phép

- N. Kirkaldy, M. A. Samieian, G. J. Offer, M. Marinescu, Y. Patel, "Lithium-Ion Battery Degradation: Measuring Rapid Loss of Active Silicon in Silicon–Graphite Composite Electrodes", *ACS Applied Energy Materials* **5** (2022) 13367–13376. DOI: https://doi.org/10.1021/acsaem.2c02047
- Nhận 29/06/2022, chấp nhận 21/10/2022, xuất bản 03/11/2022 (tr. 1).
- Giấy phép: **open access, CC BY** theo Unpaywall/PMC (PMC9709825); dòng giấy phép không xuất hiện trong text trích xuất → nếu cần chắc chắn, xem trang DOI. PDF lấy từ kho Spiral Imperial (hdl.handle.net/10044/1/101154), là bản publisher.

## 2. Ma trận thí nghiệm

Cell: **LG M50T (LG GBM50T2170)**, SiOx-doped graphite / NMC811, 18.2 Wh (5 Ah) (tr. 3). **17 cell**, 6 điều kiện (tr. 3).

| Experiment | SoC window | Charge / discharge | Temperature | Cycles per ageing set |
|---|---|---|---|---|
| 1 | 0–30% | 0.3C / 1C | 10, 25, 40 °C | 258 (loop 257 lần) |
| 2 ("control") | 0–100% | 0.3C CCCV (4.2 V, tới 0.01C) / 1C | 10, 25, 40 °C | 78 (loop 77 lần) |

- Số cell cho từng điều kiện: bài nói "listed below" nhưng không có bảng phân bố trong thân bài → KHÔNG RÕ trong bài này. (Kirkaldy 2024 Table 1 cho 0–30%: 3/3/3 và 0–100%: 3/2/3 = 17 cell, khớp tổng số; rất có thể là cùng các cell — suy luận, bài không khẳng định.)
- C-rate và SoC theo dung lượng danh định **5 Ah, 1C = 5 A**, không derate theo tuổi (tr. 3, 4).
- Table 1 (tr. 3), 0–30%: CC xả 1C tới 2.5 V → CV 2.5 V tới 0.01C → nghỉ 4 h → [CC sạc 0.3C, Q = 1500 mAh → CC xả 1C tới 2.5 V] loop 257 lần.
- Table 2 (tr. 3), 0–100%: CCCV sạc 0.3C/4.2 V/0.01C → nghỉ 4 h → [CC xả 1C tới 2.5 V → CCCV sạc] loop 77 lần.
- ~77 equivalent full cycles giữa hai RPT liên tiếp (tr. 6, chú thích Fig. 4).
- Nhiệt: base-cooling bằng Peltier, phần còn lại cách nhiệt (pseudo-adiabatic) (tr. 3).
- Break-in 5 chu kỳ 0.2C. RPT ở 25 °C, hai loại (dài ~100 h, ngắn ~nửa thời gian): 0.1C xả-sạc; 0.5C xả-sạc; GITT 0.5C 25 × 200 mAh nghỉ 1 h; GITT 0.5C 5 × 1000 mAh; trước mỗi bước CCCV 0.3C/4.2 V/0.01C + nghỉ 2 h; sau khi chạm 2.5 V nghỉ 6 h (tr. 3–4).
- Charge throughput = tổng điện lượng sạc + xả của các ageing cycle (tr. 4).

## 3. Kết quả có dạng SỐ (bảng/văn bản)

| Đại lượng | Điều kiện | Giá trị | Nguồn |
|---|---|---|---|
| Loss of silicon capacity (LAM-Si) | 0–30% SoC, 40 °C, sau 4 kAh (~400 equiv. full cycles) | **80%** | Abstract, tr. 1 |
| Loss of graphite capacity (LAM-Gr) | cùng điều kiện | **10%** ("just a 10% loss") | Abstract, tr. 1 |
| LAM-Si | 0–30% SoC, nhiệt độ trung/cao, sau 4 kAh đầu | **> 70%** | tr. 8 |
| LAM-Si | 0–100% SoC, 25 °C, sau 5 kAh | **> 30%** | Kết luận, tr. 8 |
| LAM-Si | 0–30% SoC, cùng 5 kAh | **80%** | Kết luận, tr. 8 |
| Tỉ lệ dung lượng Gr : Si trong NE ở BoL | fit half-cell NE | **0.85 : 0.15** | tr. 5 |
| Tỉ lệ dung lượng Gr : Si ở BoL | OCV-fitting full cell | **0.87 : 0.13** | tr. 5 |
| RMSE của OCV-fitting | hầu hết trường hợp | **5–15 mV**, tăng dần từ BoL tới EoL | tr. 7 |
| Giai đoạn "accelerated ageing" ở 0–30% | | trong **2 kAh** đầu | tr. 6 |
| 0–30% ở 10 °C có capacity fade thấp nhất | | trong **7 kAh** đầu | tr. 6 |
| "Cliff edge" của cell 0–30%/10 °C | | sau **~8 kAh** | tr. 7 |
| Ví dụ: tăng trở 20% | | ≈ 5 mΩ → thêm 2.5 mV quá thế ở 0.1C (500 mA) | tr. 6 |

Capacity fade (%) và resistance increase (%) theo window/nhiệt độ: **không có số**, chỉ Fig. 3.

**Nhận định định tính theo SOC window (tr. 6, 8):**
- Ở 25 và 40 °C: 0–100% suy giảm **chậm hơn** 0–30% (tính theo charge throughput).
- 0–30%: sụt dung lượng ban đầu lớn (2 kAh đầu), sau đó tuyến tính chậm. 0–100%: sụt ban đầu nhỏ hơn nhưng vùng tuyến tính dốc hơn.
- Ở 10 °C thì ngược lại: 0–100% già nhanh nhất; 0–30% già chậm nhất trong 7 kAh đầu, sau đó có knee.
- LAM-Si lớn hơn LAM-Gr ở mọi điều kiện, tệ nhất ở SOC thấp và nhiệt độ cao. Ở 0–30%, cell 10 °C có LAM-Si và LLI thấp hơn 25/40 °C.
- LAM-Gr ở 0–100%: cao nhất ở 10 °C; 25 và 40 °C tương đương.
- **LAM-PE tương tự nhau ở mọi cell, không phụ thuộc SOC window hay nhiệt độ** → cơ chế gây LAM-PE "not SoC-dependent" (tr. 8).
- Resistance increase đi cùng xu hướng với capacity fade (tr. 6).
- Lý giải (tr. 2, 8): Si có thế oxy hoá cao hơn graphite nên chỉ hoạt động ở SOC thấp; hạt Si chịu mật độ dòng cao hơn nhiều so với graphite do diện tích bề mặt hoạt động nhỏ.

## 4. Phương trình (đánh số theo bài)

Không có mô hình lão hoá vật lý. Các định nghĩa:
- (1) capacity fade (%) = (capacity_0.1C,BoL − capacity_0.1C) / capacity_0.1C,BoL × 100
- (2) resistance (Ω) = (V2 − V1)/(I2 − I1), V2/I2 lấy 0.1 s sau khi đặt xung (10 Hz); so sánh ở xung thứ 12 (~52% SoC)
- (3) resistance increase (%) = (resistance − resistance_BoL)/resistance_BoL × 100
- (4) Q_composite(V) = Q_Gr(V) + Q_Si(V) (chỉ đúng ở giới hạn nhiệt động, dòng nhỏ)
- (5) Q_composite = Q_composite × %Cap_Gr + Q_composite × %Cap_Si
- (6) %Cap_Gr + %Cap_Si = 1
- ICA: dSoC/dV, sai phân hữu hạn dV = 5 mV, không làm trơn (tr. 5).
- OCV-fitting: tối thiểu hoá sai lệch V–Q bằng nonlinear least squares trên 5 ẩn (χPE_lo, χPE_hi, χNE_lo, χNE_hi, %Cap_Gr); LLI chuẩn hoá theo dung lượng cell BoL (tr. 5, 7).

**Tốc độ lão hoá phụ thuộc SOC thế nào:** bài không cho hàm số; chỉ cho kết quả thực nghiệm ở hai window.

## 5. Bảng tham số fit

Không có tham số mô hình lão hoá. Số "fitted" duy nhất: tỉ lệ Gr:Si (0.85:0.15 và 0.87:0.13, mục 3). Validation error: RMSE OCV-fitting 5–15 mV.

## 6. Dữ liệu / mã nguồn (ghi nhận, KHÔNG tính là đã đọc)

- Zenodo: bài ghi https://doi.org/10.5281/zenodo.7235857 (concept DOI); bản ghi 10.5281/zenodo.7235858, 21/10/2022, **CC BY 4.0**, 1 file "Battery Degradation Data.zip" 850 MB.
- Dữ liệu đầy đủ hơn (kể cả hai window này): Zenodo 10.5281/zenodo.10637534 (Kirkaldy 2024).

## 7. Không có dạng số (chỉ có hình)

- Capacity fade và resistance increase theo charge throughput, từng cell (Fig. 3).
- LLI, LAM-PE, LAM-NE, LAM-Gr, LAM-Si theo charge throughput, trung bình ± độ lệch chuẩn (Fig. 5).
- Phổ ICA theo tuổi (Fig. 4).
- Số cell cho từng điều kiện, bảng RPT chi tiết, hình test rig (nằm ở SI, chưa đọc).

## 8. Mâu thuẫn / KHÔNG RÕ

- LAM-Si ở 0–30%: abstract "80% sau 4 kAh ở 40 °C"; tr. 8 "> 70% sau 4 kAh (nhiệt độ trung/cao)"; kết luận "80% cho cùng charge throughput 5 kAh". Ba phát biểu gần nhau nhưng không trùng mốc → dùng như khoảng 70–80% trong 4–5 kAh.
- tr. 8 viết "4 kA h of **energy** throughput" — thực ra là charge throughput.
- Table 1 ghi Q = 1500 mAh = "capacity_BoL × 0.3" với 5 Ah danh định; Kirkaldy 2024 nói window thực là 0–30.8% theo 4.865 Ah.
- "Loop 257 times" (bài này) vs "258 cycles per ageing set" (Kirkaldy 2024): cùng quy trình, khác cách đếm.
- LAM-Si là "mất dung lượng silicon khả dụng theo OCV-fitting"; bài lưu ý không phân biệt được mất vật liệu đã lithi hoá với chưa lithi hoá (tr. 7).
- DOI Zenodo trong bài (…7235857) khác bản ghi hiện có (…7235858): cái đầu là concept DOI.

## 9. Khớp với 5 bài cũ

- **Cùng cell: CÓ** — LG M50T, cùng nhóm Imperial/Faraday với O'Kane 2022.
- **Bộ tham số nền:** không có mô hình; half-cell V–Q của NE composite, Gr, Si, NMC811 lấy từ tài liệu [14 = Kitada 2019 (SiO), 29 = Prosser 2021, 43 = **Chen 2020**] (tr. 5, danh mục tham khảo tr. 9–10).
- **Phương trình mở rộng/thay thế O'Kane 2022:** không có. Bài cho thấy một cơ chế mà O'Kane 2022 và bộ Chen 2020 KHÔNG mô tả: cực âm là composite Gr + Si, và Si mất rất nhanh khi cycling ở SOC thấp. Trong Chen 2020 cực âm là một vật liệu "lumped".
- **Giá trị khác/bổ sung:** tỉ lệ dung lượng Gr:Si ≈ 0.85–0.87 : 0.15–0.13 (Chen 2020 không tách); 1C = 5 A.
- **Tham số vẫn phải giả định:** mọi tham số của mô hình mất Si (β_Si, k_cr,Si, σ_c,Si, OCP và khuếch tán của Si …) — bài không cung cấp. Mô hình tương ứng là Bonkile et al. 2024 (xem ghi chú cuối `Li2025_tham_so.md`), nhưng bài đó cũng không in đủ giá trị fit.

## 10. Đánh giá mức liên quan

**Liên quan — tài liệu thứ ba (bổ trợ cho (a)/(c)).** Giá trị chính: là nguồn DUY NHẤT trong ba bài có **số trong văn bản** về phụ thuộc SOC window trên đúng cell (LAM-Si 70–80% sau 4–5 kAh ở 0–30% so với > 30% ở 0–100%; Gr chỉ ~10%), và giải thích vì sao mô hình Li 2025 (không có cơ chế Si) thất bại ở các window chạm 0% SOC. Hệ quả cho đề tài: mọi window bắt đầu từ 0% (0→10, 0→20, 0→30 …) bị chi phối bởi mất silicon — một cơ chế gắn với pha XẢ sâu/SOC thấp, không phải với dạng dòng sạc; cần nêu rõ là ngoài phạm vi mô hình hoặc xử lý bằng giả định có gắn cờ. Hạn chế: chỉ 2 window, 1 dòng sạc; phần lớn kết quả chỉ ở dạng hình; trùng một phần dữ liệu với Kirkaldy 2024.
