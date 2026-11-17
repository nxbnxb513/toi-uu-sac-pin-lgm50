# Kirkaldy et al. 2024 — dữ liệu cycle ageing LG M50T theo SOC window

> Đã đọc TOÀN VĂN bản publisher (10 trang) + Supporting Information (17 trang, chỉ có hình).
> File: `tai_lieu/Kirkaldy2024_JPS.pdf`, `tai_lieu/Kirkaldy2024_JPS_SI.pdf`; text: `toan_van_trich_xuat/Kirkaldy2024.txt`, `Kirkaldy2024_SI.txt`.
> Số trang ghi "tr. N" là trang của PDF bài báo (1–10).

## 1. Trích dẫn, tạp chí, giấy phép

- N. Kirkaldy, M. A. Samieian, G. J. Offer, M. Marinescu, Y. Patel, "Lithium-ion battery degradation: Comprehensive cycle ageing data and analysis for commercial 21700 cells", *Journal of Power Sources* **603** (2024) 234185. DOI: https://doi.org/10.1016/j.jpowsour.2024.234185
- Nhận 30/09/2023, chấp nhận 04/02/2024, online 05/04/2024 (tr. 1).
- Giấy phép: **open access, CC BY 4.0** (ghi ở tr. 1). Bản PDF lấy từ kho Spiral của Imperial College (hdl.handle.net/10044/1/111070), là bản publisher.
- Nhóm tác giả: Imperial College London + Faraday Institution (cùng nhóm với O'Kane 2022).

## 2. Ma trận thí nghiệm

Cell: **LG M50T (LG GBM50T2170)**, NMC811 / C-SiOx, "đã được Chen et al. [22] đặc trưng hoá" (tr. 2). 40 cell, 15 điều kiện, tổng ~33 000 equivalent full cycles (tr. 1).

**Table 1 (tr. 2) — chép nguyên:**

| Experiment | SoC window | Cycles per ageing set | Current (charge/discharge) | Temperature | Number of cells |
|---|---|---|---|---|---|
| 1 | 0–30% | 258 | 0.3C / 1C | 10 / 25 / 40 °C | 3 / 3 / 3 |
| 2 | 70–85% | 515 | 0.3C / 1C | 10 / 25 / 40 °C | 2 / 2 / 2 |
| 3 | 85–100% | 515 | 0.3C / 1C | 10 / 25 / 40 °C | 3 / 3 / 3 |
| 4 | 0–100% (drive-cycle) | 78 | 0.3C / noisy C (WLTP) | 10 / 25 / 40 °C | 3 / 2 / 3 |
| 5 | 0–100% | 78 | 0.3C / 1C | 10 / 25 / 40 °C | 3 / 2 / 3 |

- Sạc **0.3C**, xả **1C** cho mọi thí nghiệm (trừ Expt 4 xả theo WLTP) (tr. 2). **Chỉ một C-rate sạc** → dữ liệu KHÔNG cho biết ảnh hưởng của dòng sạc.
- Mỗi ageing set ≈ 78 equivalent full cycles; sau mỗi set là một RPT ở 25 °C (tr. 3, 6).
- Mọi cell chạy ít nhất 8 ageing set (9 RPT kể cả BoL); một số chạy tới RPT12 (tr. 7, chú thích Fig. 8).
- Nhiệt: base-cooling (đế cell áp vào khối nhôm giữ nhiệt độ đặt bằng Peltier), phần còn lại bọc cách nhiệt; nhiệt độ bề mặt đo bằng thermocouple K ở giữa chiều cao cell (tr. 2, 6; SI tr. 1). Nhiệt độ bề mặt trung bình **cao hơn** set-point, rõ nhất ở 10 °C (tr. 6) — không có số.
- Break-in: 5 chu kỳ 0.2C, CV tới C/100, ở 25 °C (tr. 2).
- SoC tính theo dung lượng BoL **4.865 Ah** (không cập nhật khi lão hoá); riêng Expt 1 dùng 5 Ah → window thực là **0–30.8%** (Table 2, tr. 3).
- Giới hạn điện áp 2.5–4.2 V; safety limit nhiệt 60 °C, không bao giờ chạm (tr. 3).

**Quy trình từng window (Tables 2–6, tr. 3):**

| Expt | Cách đặt window |
|---|---|
| 1 (0–30%) | CC xả 1C tới 2.5 V → CV 2.5 V tới C/100 → nghỉ 4 h → [CC sạc 0.3C, Q = 1500 mAh → CC xả 1C tới 2.5 V] × 258 |
| 2 (70–85%) | CCCV sạc 0.3C/4.2 V/C/100 → nghỉ 1 h → xả 1C 730 mAh → nghỉ 3 h → [xả 1C 730 mAh → sạc 0.3C 730 mAh] × 515 |
| 3 (85–100%) | CCCV sạc → nghỉ 4 h → [xả 1C 730 mAh → CC sạc 0.3C tới 4.2 V → CV 4.2 V tới C/100] × 515 |
| 4 (0–100% drive) | CCCV sạc → nghỉ 4 h → [xả 1C 250 mAh → WLTP tới 2.5 V → CCCV sạc] × 78 |
| 5 (0–100%) | CCCV sạc → nghỉ 4 h → [xả 1C tới 2.5 V → CCCV sạc 0.3C/4.2 V/C/100] × 78 |

Lưu ý: 730 mAh = 4.865 × 0.15. Expt 2 KHÔNG có pha CV trong vòng lặp; Expt 3 và 5 CÓ pha CV 4.2 V mỗi chu kỳ.

**RPT (tr. 3–4):** luôn ở 25 °C; trước mỗi bước con: CCCV 0.3C/4.2 V/C/100 + nghỉ 1 h.
- RPT dài (sau set chẵn): C/10 xả-sạc; C/2 xả-sạc; GITT 0.5C 25 xung × 200 mAh, nghỉ 1 h; GITT 0.5C 5 xung × 1000 mAh.
- RPT ngắn (sau set lẻ): C/10 xả-sạc; pulse-under-load nền C/2 (xả và sạc); PUL nền 1C (chỉ xả).

## 3. Kết quả có dạng SỐ (bảng/văn bản)

**Chỉ có số ở BoL.** Table 7 (tr. 6) — trung bình trên 40 cell:

| Variable | Mean | Std | CoV (%) |
|---|---|---|---|
| Cell (C/10) capacity | 4.857 Ah | 0.022 Ah | 0.45 |
| Cell (C/2) capacity | 4.780 Ah | 0.022 Ah | 0.46 |
| Positive electrode capacity | 5.634 Ah | 0.064 Ah | 1.14 |
| Negative electrode capacity | 5.272 Ah | 0.092 Ah | 1.75 |
| Graphite capacity | 4.471 Ah | 0.085 Ah | 1.90 |
| Silicon capacity | 0.800 Ah | 0.022 Ah | 2.75 |
| Offset | 0.563 Ah | 0.046 Ah | 8.17 |
| R0.1s (≈52% SoC) | 26.42 mΩ | 0.78 mΩ | 2.95 |
| R10s | 32.96 mΩ | 0.79 mΩ | 2.40 |
| R10s–0.1s | 6.54 mΩ | 0.11 mΩ | 1.68 |

Ghi chú: dung lượng dùng để định nghĩa SoC là 4.865 Ah ("trung bình C/10 của một tập con 20 cell", tr. 3), khác 4.857 Ah (40 cell). SI tr. 2: trở kháng cell đo 4 điểm = 27 mΩ; đầu nối thêm < 3 mΩ.

**Kết quả lão hoá theo SOC window — CHỈ ĐỊNH TÍNH trong văn bản (tr. 7):**

| SOC window | Phát biểu của bài (không kèm số) |
|---|---|
| 70–85% | Suy giảm "particularly slow"; "generally the least destructive" |
| 0–30% | Suy giảm nhanh hơn; "detrimental for silicon capacity but not as harmful for graphite capacity" |
| 85–100% | Suy giảm nhanh hơn; ở 10 °C capacity fade lớn hơn so với nhiệt độ ấm — "likely due to lithium-plating" |
| 0–100% CC vs drive-cycle | Khác nhau "stark", nhất là ở 10 °C |
| Chung | Nhiệt độ lạnh thường suy giảm nhiều hơn; LLI tương quan với capacity fade và với LAM_NE |

Giả thuyết thiết kế của tác giả (tr. 2): 0–30% → suy giảm silicon; 70–85% → chủ yếu SEI growth; 85–100% → Li plating ở lạnh, phân huỷ cực dương ở nóng; 0–100% → mọi cơ chế.

**Capacity fade, LLI, LAM_PE, LAM_NE, LAM_Gr, LAM_Si, resistance increase theo từng window: KHÔNG có số nào trong bảng/văn bản** — chỉ có ở Fig. 7, Fig. 8 và SI Fig. S7–S16. Muốn có số phải tự xử lý dữ liệu thô Zenodo (mục 6).

## 4. Phương trình mô hình

**Không có mô hình lão hoá.** Bài chỉ mô tả bằng lời (không đánh số phương trình):
- Resistance = sụt áp tức thời khi đặt xung GITT; R0.1s (tần số lấy mẫu 10 Hz), R10s, R10s–0.1s; so sánh ở xung thứ 12 (~52% SoC) (tr. 4–5).
- Degradation mode analysis bằng OCV-fitting với OCP nửa pin của graphite, silicon, NMC811 từ tài liệu [22 = Chen 2020, 26, 28]; chi tiết ở Kirkaldy 2022 (tr. 5).

## 5. Bảng tham số fit

Không có tham số mô hình nào được fit. Trạng thái các số trong Table 7: **measured** (dung lượng cell, điện trở) hoặc **derived bằng OCV-fitting** (dung lượng PE/NE/Gr/Si, offset). Sai số validation: không áp dụng. Bài chỉ nói OCV-fitting cho "high RMSE" với một cell 85–100%/10 °C có hồi phục dung lượng sau 23 ngày nghỉ (tr. 7) — không có số RMSE.

## 6. Dữ liệu / mã nguồn (ghi nhận, KHÔNG tính là đã đọc)

- Dữ liệu: **Zenodo https://doi.org/10.5281/zenodo.10637534**, v1, 08/02/2024, giấy phép **CC BY 4.0** (theo metadata Zenodo). Gồm 7 file, tổng ~49 GB: `experiment_metadata.xlsx`, notebook ví dụ `.ipynb`, và 5 file zip: "Expt 1 - Si-based Degradation" (9.1 GB), "Expt 2,2 - C-based Degradation 2" (6.5 GB), "Expt 3 - Cathode Degradation and Li-Plating" (12.0 GB), "Expt 4 - Drive Cycle Aging (Control)" (11.4 GB), "Expt 5 - Standard Cycle Aging (Control)" (10.4 GB).
- Mã phân tích: https://github.com/ImperialCollegeLondon/batteryDAT (giấy phép: KHÔNG RÕ, chưa kiểm tra).
- Bộ dữ liệu nhỏ hơn đã xử lý sẵn cho Expt 2 và 3 (kèm kết quả mô phỏng): Zenodo 10.5281/zenodo.14995785 của Li et al. 2025 (835 MB + Source_Data.zip 10.8 MB, CC BY 4.0) — xem `Li2025_tham_so.md`.

## 7. Không có dạng số (chỉ có hình)

- Capacity fade, resistance increase, LAM-PE, LAM-NE, LAM-Gr, LAM-Si, LLI theo charge throughput cho từng window và nhiệt độ (Fig. 7; SI Fig. S7–S16).
- ECDF và ma trận tương quan các chỉ số tại RPT8 (Fig. 8).
- Q, E, V_av, V_range, T_av của từng ageing set (Fig. 5) — kể cả nhiệt độ bề mặt thực tế.
- Đường V–Q và R–SoC theo tuổi (Fig. 6; SI Fig. S2–S6).
- Số chu kỳ/charge throughput tới "knee point" của từng điều kiện.

## 8. Mâu thuẫn / KHÔNG RÕ

- Table 1 ghi 258 chu kỳ/set cho Expt 1; Table 2 ghi "loop 257 times" (tức 258 lần sạc — nhất quán); trang Zenodo ghi 257. Tương tự 515 vs "514 times".
- Dung lượng BoL: 4.865 Ah (20 cell, dùng cho SoC) vs 4.857 Ah (40 cell, Table 7) vs 5 Ah danh định (dùng cho Expt 1 và C-rate). 1C = 5 A hay 4.865 A: KHÔNG RÕ trong bài này (Kirkaldy 2022 ghi 1C = 5 A).
- Kết luận (tr. 8) viết "10s−1s resistance" trong khi thân bài và Table 7 là "R10s–0.1s" — lỗi đánh máy, cùng giá trị CoV 1.68%.
- Ref. [30] được gọi trong văn bản là "Schmidt et al." nhưng danh mục ghi "Schmitt".
- Zenodo chỉ có "Expt 2,2"; có hay không "Expt 2,1": KHÔNG RÕ.
- Nhiệt độ trung bình thực của cell trong từng điều kiện: KHÔNG RÕ (chỉ có hình).

## 9. Khớp với 5 bài cũ

- **Cùng cell: CÓ** — LG M50T 21700, NMC811/C-SiOx; bài trích trực tiếp Chen 2020 là nguồn đặc trưng hoá cell và nguồn OCP nửa pin cho OCV-fitting.
- **Bộ tham số nền:** không dùng mô hình nên không dùng bộ nào; chỉ dùng OCP nửa pin từ Chen 2020 (và Prosser 2021, Kitada 2019 cho Si).
- **Phương trình mở rộng/thay thế O'Kane 2022:** không có. Bài là dữ liệu để hiệu chỉnh/kiểm chứng.
- **Giá trị khác với Chen/O'Kane/O'Regan:** dung lượng C/10 đo được 4.857–4.865 Ah, thấp hơn 5 Ah danh định mà bộ Chen 2020 hướng tới; dung lượng điện cực từ OCV-fitting: PE 5.634 Ah, NE 5.272 Ah (Gr 4.471 + Si 0.800) — dùng được để kiểm tra electrode balancing của mô hình.
- **Điều kiện nhiệt khác O'Regan 2022:** base-cooling + cách nhiệt (không phải đối lưu trong buồng nhiệt) → hệ số trao đổi nhiệt h của O'Regan (15 W m⁻² K⁻¹, chỉnh tay) không áp dụng trực tiếp; Li 2025 dùng 20 W m⁻² K⁻¹ với diện tích 5.31·10⁻³ m².
- **Tham số vẫn phải giả định nếu dùng bài này:** toàn bộ tham số lão hoá (bài không fit gì); ảnh hưởng của dòng sạc (chỉ có 0.3C); mọi window không nằm trong {0–30, 70–85, 85–100, 0–100}%.

## 10. Đánh giá mức liên quan

**Liên quan cao — nên dùng làm tài liệu (a).** Đây là bộ dữ liệu cycle ageing duy nhất tìm được trên đúng cell LG M50T có nhiều SOC window và 3 nhiệt độ, mở hoàn toàn (CC BY). Hạn chế phải nêu rõ trong đồ án:
1. Chỉ 4 window (0–30, 70–85, 85–100, 0–100%), không phải lưới 10% của đề tài; các window còn lại phải nội suy bằng mô hình.
2. Chỉ một dòng sạc 0.3C → không kiểm chứng được phần "profile I(t) tối ưu so với CCCV".
3. Bài báo KHÔNG in số capacity fade/LLI/LAM theo window; chỉ có nhận định định tính + hình. Số định lượng phải lấy từ Zenodo (49 GB) hoặc từ bộ đã xử lý của Li 2025 (Expt 2, 3).
