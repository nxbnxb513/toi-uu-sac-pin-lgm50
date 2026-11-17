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

Thư mục `src/dfn/` chứa mô hình Doyle–Fuller–Newman đầy đủ ghép với mô hình nhiệt lumped, bộ tham số Li et al. 2025 (O'Regan 2022 + các mục đánh dấu *), chưa có lão hoá.

**Bộ tham số mặc định `src = 'approved'`:** theo bài in; chỗ bài in sai thì theo bài gốc (Landesfeind & Gasteiger 2019 Table II cho điện giải: 0.353, −6.12, thermodynamic factor theo pt. [2]; Butler–Volmer 2·j₀·sinh(Fη/2RT) theo O'Kane 2022; ∂U/∂T theo mV/K; mật độ khô theo O'Regan 2022 Table 7); chỗ không bài nào ghi thì theo mã nguồn tác giả (L_SEI,0, khuếch tán do ứng suất, vị trí R_0, dạng nhiệt 0D — đều có tuỳ chọn đổi). `src = 'paper'` (đúng như bài in, kể cả lỗi in) và `src = 'code'` chỉ để so sánh. Chi tiết: [tai_lieu/gia_dinh.md](tai_lieu/gia_dinh.md), [tai_lieu/doi_chieu_tham_so.md](tai_lieu/doi_chieu_tham_so.md).

| File | Vai trò |
|---|---|
| `dfn_params.m` | Tham số, mỗi số ghi nguồn (bài + bảng/phương trình); `src = 'approved'` (mặc định), `'paper'`, `'code'` |
| `dfn_rhs.m` | Vế phải của hệ DAE (khuếch tán trong hạt tại mọi nút x, điện giải, Butler–Volmer, nhiệt) |
| `dfn_run.m`, `dfn_cccv.m` | Chạy chuỗi bước: dòng cho trước, giữ áp (ràng buộc đại số), nghỉ |
| `dfn_aging_state.m`, `dfn_side_reactions.m` | Chỗ móc cho lão hoá ở bước sau (ε, a, màng SEI theo nút; j_tot = j_int + j_phụ) |
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
