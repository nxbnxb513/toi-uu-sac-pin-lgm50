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

## Chạy trên GitHub

Workflow `.github/workflows/simulate.yml` chạy khi đẩy code lên nhánh `main`, hoặc bấm **Run workflow** trong tab Actions.

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
