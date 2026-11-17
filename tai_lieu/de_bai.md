# Đề bài

*Chốt ngày 17/11/2026.*

## 1. Mục tiêu

Nghiên cứu lão hoá của pin lithium-ion khi sạc, và tìm cách điều khiển dòng sạc để giảm lão hoá.

Cụ thể: với **mỗi vùng sạc** (0→10 %, 0→20 %, …, 0→100 %, 10→20 %, 10→30 %, …, 90→100 %), tính riêng hai trường hợp:

1. **Baseline:** sạc CCCV thông thường (dòng không đổi; nếu chạm 4.2 V thì giữ áp).
2. **Tối ưu:** profile dòng sạc nhiều đoạn, **cùng thời gian sạc** với baseline, có lão hoá nhỏ nhất.

Sau đó thống kê mức giảm lão hoá của profile tối ưu so với CCCV cho tất cả các vùng.

## 2. Đối tượng

Cell LG M50 21700 (NMC811 / graphite-SiOx, 5 Ah). Mọi tham số lấy từ các bài báo làm trên chính cell này; xem `tong_quan_tai_lieu.md` và `tham_so/`.

## 3. Biến điều khiển, đo lường, ước lượng

| Loại | Đại lượng |
|---|---|
| Biến điều khiển (duy nhất) | Dòng sạc I(t) |
| Cảm biến đo được | Dòng I, điện áp V, nhiệt độ pin T |
| Không đo được, phải ước lượng | SOC, nồng độ lithium trong điện cực, quá thế mạ lithium η_Li, độ dày SEI, lượng lithium đã mất |

## 4. Chỉ số lão hoá

Lượng lithium mất trong một lần sạc cộng 30 phút nghỉ, tính bằng Ah:

- lithium mất vào lớp SEI,
- lithium chết (lithium đã mạ rồi không bóc lại được),
- lithium đã mạ còn lại sau khi nghỉ (tính là mất, tức trường hợp xấu nhất).

## 5. Ràng buộc

| Ràng buộc | Giá trị | Nguồn |
|---|---|---|
| Điện áp | V ≤ 4.2 V | O'Kane 2022, Bảng S3 |
| Thời gian sạc | bằng thời gian của baseline (sai lệch ≤ 1 %) | Để so sánh công bằng |
| Dòng sạc tối đa | 2C | **Giả định** |
| Nhiệt độ tối đa | 45 °C | **Giả định** |
| Biên an toàn chống mạ lithium | η_Li ≥ 10 mV | **Giả định** |
| Dòng baseline | 0.3C và 1C | 0.3C theo O'Kane 2022 và Kirkaldy 2024; 1C là **giả định** |
| Nhiệt độ môi trường | 25 °C | **Giả định** |

## 6. Phạm vi

- **Trong phạm vi:** lão hoá do sạc (SEI, mạ lithium, lithium chết), ảnh hưởng của nhiệt độ, ước lượng trạng thái không đo được.
- **Ngoài phạm vi:**
  - Lão hoá lịch (khi lưu trữ). Báo cáo chỉ nhắc qua bằng đồ thị thực nghiệm riêng.
  - Điều khiển khi xả, vì dòng xả do tải quyết định.
  - Lão hoá của silicon ở SOC thấp và nứt hạt: chưa có mô hình và tham số cho cell này (xem mục 7).

## 7. Giới hạn đã biết

1. **Thiếu cơ chế silicon ở SOC thấp.** Thực nghiệm (Kirkaldy 2022, 2024) cho thấy vùng 0–30 % già nhanh vì silicon trong anode hỏng. Mô hình ở đây không có cơ chế này. Vì vậy:
   - kết luận "tối ưu so với CCCV trong cùng một vùng" là kết luận chính;
   - việc xếp hạng các vùng với nhau chỉ mang tính tham khảo.
2. **Mô hình lão hoá chỉ được kiểm chứng ở vùng 70–100 % và dòng sạc 0.3C** (Li 2025). Các vùng khác và dòng lớn hơn là ngoại suy.
3. **Không có thực nghiệm kiểm chứng cho profile tối ưu.** Mọi so sánh với CCCV là kết quả mô phỏng.
4. **Mô hình điện hoá là dạng rút gọn (SPMe)**, không phải DFN đầy đủ; xem `mo_hinh_toan.md`.
5. **Code chưa được chạy thử trước khi đẩy lên GitHub.** Lần chạy đầu tiên trên GitHub Actions chính là lần kiểm tra đầu tiên.
