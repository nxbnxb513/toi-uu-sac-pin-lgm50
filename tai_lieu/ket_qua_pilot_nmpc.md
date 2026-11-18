# Kết quả chạy thử NMPC (biết hết trạng thái) — ĐANG CHẠY, CHƯA CÓ SỐ

Cập nhật 18/11/2026. **Chưa có kết quả NMPC nào.** Tài liệu này ghi tình trạng để phiên sau điền bảng.

## 1. Đang chạy
- Run pilot: https://github.com/nxbnxb513/toi-uu-sac-pin-lgm50/actions/runs/44204442587
  (42 job = 3 vùng 0→60, 20→80, 40→100 % × CCCV 0.5C/1C × 7 mức k; 25 °C; biến thể số học `pilot`, GD-80; tối đa 20 job song song; job `report` gộp thành artifact `pilot-report`).
- Pin "thật" = DFN **không** lão hoá; lão hoá chấm hậu kiểm TẠM THỜI (`aging_source = posthoc_provisional`, GD-81). Tự chuyển sang lão hoá của DFN khi `par.aging.validated = true`.

## 2. Đã biết từ các lần gỡ lỗi
- CCCV 0.5C, 0→60 % (run 44115620782): T_CCCV = 4200 s, dừng ở SOC đích trong pha CC; mất vĩnh viễn 0.01175 mAh (SEI 0.01149, Li chết 2.5·10⁻⁴) sau sạc + xả; Li mạ đỉnh 0.72 mAh (thống kê); không vi phạm (η_Li min 87 mV > 45 mV, x_s, T đều trong giới hạn).
- NMPC với cài đặt cũ: mỗi lần giải chạy hết 60 vòng SQP, 145–200 s/lần giải (≈ 3 s/vòng: tuyến tính hoá ≈ 1.2 s, tìm kiếm đường ≈ 2 s) ⇒ một lần sạc 4200 s cần ~7 giờ: **không khả thi**.
- Run debug 44195329318: SQP thực chất hội tụ sau 3–4 vòng (res_stat ≈ 2·10⁻⁴, res_eq ≈ 3·10⁻⁴ = sàn sai số tích phân IRK); 56 vòng sau gần như không đổi gì ⇒ biến thể `pilot` (GD-80). `jac_reuse = 1` cho NaN ⇒ bỏ.
- Tạo + biên dịch bộ giải acados: 450–620 s mỗi job.

## 3. Việc phiên sau
1. Đọc artifact `pilot-report` của run 44204442587, điền bảng: T_CCCV, mất vĩnh viễn CCCV/NMPC, % giảm, Li mạ, vi phạm trên DFN, thống kê bộ giải, thời gian mỗi job.
2. Ngoại suy lưới đầy đủ (15 vùng × 3 C_base × 3 T × 7 k) trên 20 job song song từ cột `job_wall_s`.
