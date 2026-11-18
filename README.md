# Tối ưu dòng sạc để giảm lão hoá pin lithium-ion (LG M50)

Đồ án môn Mô hình hoá. Với mỗi vùng sạc (0→10 %, 0→20 %, …, 10→20 %, …, 90→100 %), dự án tính riêng hai trường hợp rồi so sánh:

1. sạc **CCCV** thông thường (baseline);
2. profile **dòng sạc tối ưu** nhiều đoạn, cùng thời gian sạc, ít lão hoá nhất.

Mô hình pin ghép điện hoá – nhiệt – lão hoá (SEI phụ thuộc vùng SOC, mạ lithium, lithium chết), viết bằng MATLAB thuần và chạy hoàn toàn trên GitHub Actions.

> **Trạng thái:** code được đẩy lên mà **chưa chạy thử**. Lần chạy đầu tiên trên GitHub Actions là lần kiểm tra đầu tiên, nên có thể cần sửa lỗi.

## Tài liệu

| File | Nội dung |
|---|---|
| [tai_lieu/de_bai.md](tai_lieu/de_bai.md) | Đề bài, ràng buộc, phạm vi, các giả định và giới hạn |
| [tai_lieu/mo_hinh_toan.md](tai_lieu/mo_hinh_toan.md) | Mô hình toán, nguồn của từng phương trình, các tương tác |
| [tai_lieu/tong_quan_tai_lieu.md](tai_lieu/tong_quan_tai_lieu.md) | Tổng quan 9 tài liệu tham khảo |
| [tai_lieu/tham_so/](tai_lieu/tham_so/) | Bảng tham số chép từ từng bài báo, kèm số trang |

File PDF và toàn văn của các bài báo không nằm trong repo vì lý do bản quyền.

## Code

| File | Vai trò |
|---|---|
| `src/params_lgm50.m` | Tham số của cell, mỗi dòng ghi nguồn |
| `src/ocp.m` | Thế hở mạch và hệ số entropy của hai điện cực |
| `src/model_rhs.m` | Vế phải của mô hình (hệ phương trình vi phân) |
| `src/sim_charge.m` | Mô phỏng một lần sạc: nhiều đoạn dòng không đổi, tự chuyển sang giữ áp |
| `src/optimise_window.m` | Tối ưu profile dòng cho một vùng sạc và so với CCCV |
| `src/run_window.m` | Chạy tất cả các vùng có cùng SOC bắt đầu |
| `src/make_report.m` | Gộp kết quả thành bảng thống kê và hình |
| `src/run_ekf_demo.m` | Sạc vòng kín, chỉ dùng dòng, điện áp, nhiệt độ đo được (EKF) |
| `src/default_cfg.m` | Cấu hình và các giá trị giả định |

## Mô hình DFN (bước 1 của bản làm lại)

Thư mục `src/dfn/` chứa mô hình Doyle–Fuller–Newman đầy đủ ghép với mô hình nhiệt lumped, bộ tham số Li et al. 2025 (O'Regan 2022 + các mục đánh dấu *). Lão hoá "5 coupled" (bước C) là tuỳ chọn `aging = true`, mặc định tắt — xem mục dưới.

**Bộ tham số mặc định `src = 'approved'`:** theo bài in; chỗ bài in sai thì theo bài gốc (Landesfeind & Gasteiger 2019 Table II cho điện giải: 0.353, −6.12, thermodynamic factor theo pt. [2]; Butler–Volmer 2·j₀·sinh(Fη/2RT) theo O'Kane 2022; ∂U/∂T theo mV/K; mật độ khô theo O'Regan 2022 Table 7); chỗ không bài nào ghi thì theo mã nguồn tác giả (L_SEI,0, khuếch tán do ứng suất, vị trí R_0, dạng nhiệt 0D — đều có tuỳ chọn đổi). `src = 'paper'` (đúng như bài in, kể cả lỗi in) và `src = 'code'` chỉ để so sánh. Chi tiết: [tai_lieu/gia_dinh.md](tai_lieu/gia_dinh.md), [tai_lieu/doi_chieu_tham_so.md](tai_lieu/doi_chieu_tham_so.md).

| File | Vai trò |
|---|---|
| `dfn_params.m` | Tham số, mỗi số ghi nguồn (bài + bảng/phương trình); `src = 'approved'` (mặc định), `'paper'`, `'code'` |
| `dfn_rhs.m` | Vế phải của hệ DAE (khuếch tán trong hạt tại mọi nút x, điện giải, Butler–Volmer, nhiệt) |
| `dfn_run.m`, `dfn_cccv.m` | Chạy chuỗi bước: dòng cho trước, giữ áp (ràng buộc đại số), nghỉ |
| `dfn_aging_state.m`, `dfn_side_reactions.m`, `dfn_aging_rhs.m` | Lão hoá (khi `aging = true`): ε, a, màng SEI theo nút; j_tot = j_int + j_phụ; vế phải các trạng thái lão hoá |
| `val_selftest.m`, `val_run_condition.m`, `val_report.m` | Tự kiểm tra và kiểm chứng với dữ liệu xả mở (Zenodo 4864437) |

Workflow `.github/workflows/validate.yml` chạy kiểm chứng (12 điều kiện xả song song) cho các biến thể `approved`, `approved_old` (bộ cũ trước 17/11/2026), `approved_no_stress`, `approved_h_tau` (h nhận dạng từ τ nguội đo được 582 s), `approved_Rc_heat`, `paper`, `code` (thêm `approved_A_only`, `approved_C_only` khi chạy tay với `extra = AC`), và xuất `validation.md`, CSV, hình trong artifact `validation-report`. Sai số báo cho cả "tất cả lần xả" và "bỏ lần xả có số liệu nhiệt bất thường" (GD-23).

**Các điểm đã duyệt ngày 17/11/2026** (chi tiết: `tai_lieu/gia_dinh.md` mục 0):
- GD-40 (A): cực âm luôn dùng nhánh OCP delithiation (trái Li 2025 SI Note 7).
- GD-41 (B): biên an toàn mạ lithium cộng thêm 35 mV (`par.ctrl.delta_pl_extra`).
- GD-42 (C): x100 = 0.9014, chỉ dùng cho cell kiểm chứng.
- GD-43: ngưỡng CC → CV và áp giữ CV trong mọi mô phỏng là `par.V_cv` = 4.2 V × (1 − 2 %) = **4.116 V**. Đây là phần dư cho sai số mô hình, không phải độ chính xác cảm biến. `par.Vmax` = 4.2 V chỉ dùng để ghi chép.

**Kết quả kiểm chứng hiện tại** (bộ `approved` mặc định, validate run 44102112653; 90 lần xả, bỏ 3 lần bất thường):

| | Toàn pha xả | 90 % đầu | 0 °C (toàn / 90 %) | 10 °C | 25 °C | Nhiệt độ |
|---|---|---|---|---|---|---|
| `approved` (A + C) | 85.6 mV | 39.4 mV | 115.5 / 43.5 mV | 92.5 / 35.5 mV | 49.6 / 39.4 mV | 2.11 K |
| `approved_old` (trước 17/11) | 71.4 mV | 35.3 mV | 93.7 / 37.1 mV | 58.2 / 31.3 mV | 63.5 / 37.6 mV | 2.11 K |

- Toàn bộ phần chênh giữa hai dòng là do C (x100 = 0.9014). A không đổi pha xả.
- Sạc trên dữ liệu mở (CC 1.67 A, V_cv = 4.116 V; trung vị theo cell, mô hình / đo):

| T | t_CC (s) | t_CV (s) | Ah tổng |
|---|---|---|---|
| 0 °C | 7462 / 7681 | 4729 / 4313 | 4.216 / 4.402 |
| 10 °C | 8153 / 8447 | 3533 / 3216 | 4.431 / 4.647 |
| 25 °C | 8667 / 9197 | 2385 / 2177 | 4.544 / 4.805 |

  Mọi lần sạc đều kết thúc CV ở dòng cắt; không lần nào dừng vì bề mặt hạt bão hoà (GD-16).
- Self-test 0.3C, 25 °C:
  - CC 9386 s, CV 3181 s, nạp 4.422 Ah.
  - x_surf lớn nhất 0.981.

## Lão hoá "5 coupled" trong DFN (bước C)

Bật bằng `par = dfn_params(struct('aging', true))`. Đủ năm cơ chế của Li et al. 2025 và mọi hồi tiếp: SEI hai lớp giới hạn bởi khuếch tán interstitial (cả trên vết nứt), mạ lithium bán thuận nghịch + lithium chết, nứt hạt (luật Paris), LAM do ứng suất ở cả hai cực, tiêu thụ dung môi / cạn khô với reservoir (5 trường hợp), điện trở màng, độ xốp, LLI, LAM → ε_s và a. Tham số: cột "5 coupled" của Li 2025 Table 3. Mỗi phương trình và tham số có nhãn theo bài báo / theo bài gốc (bài in sai) / theo code (bài không ghi) / giả định: [tai_lieu/dac_ta_lao_hoa.md](tai_lieu/dac_ta_lao_hoa.md); giả định GD-50 … GD-64 ở [tai_lieu/gia_dinh.md](tai_lieu/gia_dinh.md).

| File | Vai trò |
|---|---|
| `dfn_dryout_update.m`, `dfn_dryout_init.m`, `dfn_set_area.m` | Cạn khô (SI Note 6, (S24)–(S43)), cập nhật trước mỗi ageing set và RPT |
| `dfn_li_inventory.m` | Sổ sách lithium: hạt, điện giải, SEI, SEI vết nứt, mạ, chết, LAM (bảo toàn chính xác) |
| `dfn_perm_loss.m` | Mất lithium vĩnh viễn (SEI + SEI vết nứt + Li chết + Li trong vật liệu mất do LAM) của một lần sạc rồi xả về SOC đầu — dùng cho lưới so sánh |
| `aging/ag_run.m`, `ag_rpt.m`, `ag_cycle.m`, `ag_set.m` | Mô phỏng Expt 2 (70–85 %) và Expt 3 (85–100 %) của Li 2025 / Kirkaldy 2024, có checkpoint; tuỳ chọn nhảy chu kỳ |
| `aging/ag_selftest.m`, `ag_report.m` | Tự kiểm tra (tương đương DFN khi tốc độ = 0, JPattern, bảo toàn Li, cạn khô) và so sánh với Kirkaldy 2024 / sai số Li 2025 |

Workflow `.github/workflows/aging.yml` (chạy tay):

- Các bước: selftest, rồi mô phỏng (mỗi trường hợp Expt × T × biến thể là một chuỗi tối đa 3 chặng; mỗi chặng 3 đoạn × 1.6 h, sau mỗi đoạn tải checkpoint lên), rồi kiểm chứng nhảy chu kỳ (Expt 2/3 × 10/25/40 °C × J_max 20/50, đủ 12 set), cuối cùng là báo cáo `aging_validation.md` (artifact `aging-report`).
- `resume_run`: chạy tiếp từ checkpoint của một lần chạy trước.
- `mode=report` cùng `report_runs`: chỉ gộp báo cáo từ các lần chạy đã có.

### Kết quả kiểm chứng lão hoá (18/11/2026)

Chi tiết ở [tai_lieu/ket_qua_lao_hoa.md](tai_lieu/ket_qua_lao_hoa.md). Các lần chạy CI: [44123422399](https://github.com/nxbnxb513/toi-uu-sac-pin-lgm50/actions/runs/44123422399) và [44196614322](https://github.com/nxbnxb513/toi-uu-sac-pin-lgm50/actions/runs/44196614322).

Điều kiện chạy:
- Mỗi trường hợp gồm 12 set × 515 chu kỳ, mô phỏng từng chu kỳ.
- V_cv = 4.116 V.
- SOH = Q_0.1C / 4.865 Ah. Cột phụ "SOH theo RPT0" chia cho dung lượng ở lần đo đầu.
- So với Kirkaldy 2024 (trung bình các cell).

**MPE_tot (%)** của mô hình này, so với số Li 2025 công bố:

| | 10 °C | 25 °C | 40 °C |
|---|---|---|---|
| Expt 2 (70–85 %) | 24.8 / 12.0 | 22.2 / 10.4 | 22.7 / 12.1 |
| Expt 3 (85–100 %) | 28.6 / 26.1 | 19.6 / 16.0 | 15.4 / 10.6 |

**MPE_SOH (%)** ở 10/25/40 °C:

| | Theo 4.865 Ah | Theo RPT0 | Li 2025 công bố |
|---|---|---|---|
| Expt 2 | 0.74 / 0.76 / 0.74 | 3.40 / 2.55 / 3.87 | 0.42 / 0.88 / 0.57 |
| Expt 3 | 4.60 / 1.88 / 1.97 | 8.13 / 3.88 / 2.00 | 5.30 / 2.44 / 0.75 |

Nhận xét:
- LLI, LAM_NE và LAM_PE của mô hình chỉ bằng khoảng **một nửa** thực nghiệm. MPE_LLI là 34–62 %, trong khi Li 2025 công bố 23–38 %.
- SOH theo 4.865 Ah khớp ở Expt 2 phần lớn là nhờ hai sai lệch bù trừ nhau. Dung lượng RPT0 ở 4.116 V chỉ có 4.672 Ah, tức SOH bắt đầu ở 96.0 %. Sau đó mô hình lại suy giảm chậm hơn thực nghiệm.
- Mô hình gần như không phụ thuộc nhiệt độ. Mô hình của tác giả cũng vậy.
- **Không chỉnh tham số.** Ứng viên lớn nhất là hệ số 1/4 của tốc độ dày SEI: hệ số này lấy theo bài gốc, còn code của tác giả dùng 1/2. Ứng viên thứ hai là V_cv = 4.116 V. Người dùng cần quyết có chạy thử độ nhạy hay không.

**Nhảy chu kỳ** (bản mới, `ag_jump.m`, GD-58), so với mô phỏng từng chu kỳ, trên đủ 12 set:
- Với J_max = 20, sai lệch lớn nhất là ≤ 0.09 điểm SOH, ≤ 0.06 điểm LLI, ≤ 0.03 điểm LAM và ≤ 0.11 mΩ.
- Thời gian chạy nhanh hơn 3.4–5.4 lần.

## Chạy trên GitHub

Workflow `.github/workflows/simulate.yml` (mô hình cũ) chỉ chạy khi bấm **Run workflow** trong tab Actions.

- **20 job song song:** 10 mức SOC bắt đầu × 2 mức dòng baseline (0.3C và 1C).
- Sau đó một job gộp kết quả và chạy minh hoạ EKF.
- Kết quả nằm trong mục **Artifacts** của lần chạy; gói `bao-cao-tong-hop` gồm:
  - `summary.md`, `summary.csv`: bảng thống kê từng vùng sạc;
  - `heatmap_c030.png`, `heatmap_c100.png`: mức giảm lão hoá theo vùng sạc;
  - `ekf_demo.md`, `ekf_demo.png`, `ekf_demo.csv`: kết quả sạc vòng kín.

Repo cần để ở chế độ public để MATLAB được cấp license tự động trên GitHub Actions.

## Giới hạn chính

- Mô hình không có cơ chế lão hoá của silicon ở SOC thấp. So sánh "tối ưu so với CCCV trong cùng một vùng" là kết quả chính; xếp hạng giữa các vùng chỉ để tham khảo.
- Mô hình lão hoá chỉ được tác giả gốc kiểm chứng ở vùng 70–100 % và dòng sạc 0.3C.
- Không có thực nghiệm kiểm chứng cho profile tối ưu.
- Một số giá trị là giả định, được liệt kê trong `tai_lieu/de_bai.md` và `src/default_cfg.m`.
