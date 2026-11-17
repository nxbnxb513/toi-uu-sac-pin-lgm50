# Hướng xử lý tiếp theo (bàn giao)

*Viết ngày 17/11/2026 để phiên làm việc sau tiếp tục. Đọc file này trước, rồi mới đọc các file được dẫn tới.*

## 1. Đề tài

Với mỗi vùng sạc của pin LG M50 (0→10 %, 0→20 %, …, 10→20 %, …, 90→100 %), tìm cách điều khiển dòng sạc I(t) để pin ít lão hoá nhất, và so với sạc CCCV thông thường trong chính vùng đó. Mỗi vùng tính riêng từng phương án, sau đó thống kê.

- Chi tiết đề bài: `tai_lieu/de_bai.md`. Lưu ý: file này còn mô tả bản rút gọn cũ ở mục 7, phải cập nhật ở bước cuối.
- Lão hoá lịch (khi lưu trữ) nằm ngoài phạm vi. Người dùng có đồ thị thực nghiệm riêng và chỉ nhắc qua.

## 2. Quy tắc bắt buộc của người dùng

1. **Không được cắt bớt hay đơn giản hoá** những gì đã thống nhất. Nếu không làm được đúng như đã thống nhất thì dừng lại hỏi, không tự thay thế.
2. **Bài báo trước, code sau.** Bài báo in gì thì theo bài báo. Chỉ dùng code của tác giả cho những gì bài không ghi. Chỗ bài in sai rõ ràng thì tra về bài gốc mà nó trích dẫn.
3. **Số liệu minh bạch.** Số chỉ lấy từ bảng hoặc chữ trong bài báo, hoặc tính từ dữ liệu thô công khai bằng script trong repo. Không đọc số từ hình. Được phép giả định một vài tham số nếu ghi rõ trong `tai_lieu/gia_dinh.md`.
4. **Tài liệu tham khảo.** Chỉ dùng bài đã đọc toàn văn. Bài không có bản mở thì gửi tên đầy đủ và link cho người dùng tải. Bài khác loại pin thì không thêm. Khoảng 8–9 bài; chỉ vượt khi thực sự quan trọng. Bài không dùng nữa thì xoá file.
5. **MATLAB chỉ chạy trên GitHub Actions**, không chạy trên máy, kể cả Octave. Có tối đa 20 job song song, cần tận dụng.
6. **Được phép chạy thử nhiều lần, không cần vội.** Mỗi bước phải chạy thử và kiểm chứng trước khi sang bước sau.
7. **Trả lời người dùng bằng tiếng Việt, đơn giản, dễ hiểu.**

## 3. Trạng thái hiện tại

Repo: https://github.com/nxbnxb513/toi-uu-sac-pin-lgm50 (công khai, nhánh `main`). Email commit dùng địa chỉ noreply. PDF và toàn văn bài báo không đưa lên repo (đã có trong `.gitignore`).

| Hạng mục | Tình trạng | Xem ở |
|---|---|---|
| 9 tài liệu tham khảo, bảng tham số từng bài | Xong | `tai_lieu/tong_quan_tai_lieu.md`, `tai_lieu/tham_so/` |
| Dữ liệu mở: nhiễu cảm biến, hằng số thời gian nhiệt, đơn vị entropy, số liệu lão hoá theo vùng SOC (Kirkaldy 2024, Li 2025) | Xong | `data/README.md`, `data/ket_qua_du_lieu.md`, `data/derived/`, `data/scripts/` |
| Đặc tả lão hoá đủ cơ chế | Xong, nhưng **đang viết theo code**; phải sửa theo quy tắc 2 | `tai_lieu/dac_ta_lao_hoa.md` |
| Mô hình DFN + nhiệt | Chạy được, đã kiểm chứng | `src/dfn/`, `.github/workflows/validate.yml` |
| Tra tham số in sai về bài gốc (Landesfeind 2019; nguồn gốc luật SEI) | **Đang chạy khi viết file này** | `tai_lieu/doi_chieu_tham_so.md` (nếu đã có) |
| Bản rút gọn cũ (SPMe) | **Không dùng**; xoá ở bước cuối | `src/*.m` (ngoài `src/dfn/`), `simulate.yml`, `tai_lieu/mo_hinh_toan.md` |

### Kết quả kiểm chứng DFN (93 lần xả, 12 điều kiện, không chỉnh tham số)

| Biến thể | Sai số điện áp | Sai số nhiệt độ | Xả không đến cuối |
|---|---|---|---|
| Hệ số điện ly theo số in trong bài | 436 mV | 10.1 K | 71 / 93 |
| Hệ số điện ly theo code tác giả | 74 mV | 2.8 K | 0 / 93 |

- Số in trong bài (0.8353 và −0.612) cho hệ số vận chuyển ion t⁺ ≈ 5.7, vô lý về vật lý. Số trong code (0.353 và −6.12) cho t⁺ ≈ 0.22.
- Tác giả Li 2025 công bố sai số 23–39 mV trên lô pin của họ. Bộ dữ liệu kiểm chứng ở đây là lô pin khác.
- Phần nhiệt tính nóng quá ở 1C: mô hình tăng 10.8 K, đo thật tăng 5.1 K (ở 25 °C).
- Một lần mô phỏng mất 10–20 giây. Lưới mặc định lệch 0.6 mV so với lưới rất mịn ở 1C.

## 4. Việc dở dang cần kiểm tra đầu tiên

1. **Kết quả tra bài gốc.** Đọc `tai_lieu/doi_chieu_tham_so.md` và các file mới trong `tai_lieu/tham_so/`. Nếu chưa có thì làm lại việc này:
   - Đọc toàn văn Landesfeind & Gasteiger, J. Electrochem. Soc. 166 (2019) A3079 để lấy hệ số chất điện phân EC:EMC 3:7.
   - Đọc bài gốc của luật SEI khuếch tán xen kẽ (Single 2018; von Kolzenberg 2020) để chốt dạng số mũ và hệ số 1/2 hay 1/4.
2. **Báo cáo cuối của bước DFN.** Đọc `tai_lieu/gia_dinh.md` (ba nhóm: theo bài báo, theo code, chờ quyết định) và `README.md`. Xem lượt chạy mới nhất của workflow "Kiem chung mo hinh DFN" bằng `gh run list`.
3. **Xin người dùng chốt** giá trị dùng cho từng mục trong nhóm "chờ quyết định", dựa trên bảng đối chiếu.

## 5. Các bước còn lại, theo thứ tự

Mỗi bước: viết code → đẩy lên → đọc kết quả CI → sửa → báo người dùng bằng số liệu.

**Bước A. Chốt tham số nền của DFN**
- Áp các giá trị đã được phân xử từ bài gốc vào `src/dfn/dfn_params.m`.
- Chạy lại kiểm chứng, báo sai số.
- Xem lại phần nhiệt: thử thêm hoặc bớt các nguồn nhiệt, và nhận dạng h từ hằng số thời gian nguội đo được (582 s). Không tự chỉnh tham số theo dữ liệu mà không ghi rõ.

**Bước B. Sửa đặc tả lão hoá theo quy tắc 2**
- Trong `tai_lieu/dac_ta_lao_hoa.md`, mỗi phương trình và tham số ghi rõ: theo bài báo / theo code (bài không ghi) / theo bài gốc (bài in sai).

**Bước C. Cài lão hoá đủ cơ chế vào DFN**
- Mô hình "5 coupled" của Li 2025: SEI hai lớp phụ thuộc điện thế anode, SEI trên vết nứt, mạ lithium và lithium chết, nứt hạt, mất vật liệu hoạt tính, cạn dung môi, cùng các phản hồi (điện trở màng, độ xốp, mất lithium).
- Chỗ móc đã có sẵn: `src/dfn/dfn_side_reactions.m`, `src/dfn/dfn_aging_state.m`.
- Kiểm chứng: chạy lại thí nghiệm lão hoá vùng 70–85 % và 85–100 % ở ba nhiệt độ. So với `data/derived/D_kirkaldy_per_cell_rpt.csv` và với kết quả mô hình của tác giả.
- Lưu ý: dữ liệu nguồn Hình 6 của Li 2025 bị gắn nhãn sai, không dùng.
- Mô phỏng hàng trăm chu kỳ sẽ lâu: chia theo thí nghiệm và nhiệt độ thành các job song song.

**Bước D. Tầng 2: lão hoá silicon ở SOC thấp**
- Theo đề xuất ở cuối `dac_ta_lao_hoa.md`. Tham số là giả định, ghi rõ.
- Chỉnh theo số liệu vùng 0–30 % của Kirkaldy 2022 và 2024.
- Kết quả luôn báo ở hai tầng: tầng 1 (không có silicon, có cơ sở) và tầng 2 (có silicon, giả định).

**Bước E. Mô hình rút gọn cho bộ ước lượng và bộ điều khiển**
- Rút gọn từ DFN. Phải kiểm chứng bằng cách so với DFN, báo sai số điện áp và sai số quá thế mạ lithium.

**Bước F. Bộ ước lượng EKF**
- Chỉ dùng dòng, điện áp, nhiệt độ bề mặt.
- Ước lượng: SOC, quá thế mạ lithium, độ dày SEI hoặc lượng lithium mất.
- Hai mức nhiễu: mức phòng thí nghiệm từ dữ liệu (điện áp σ ≈ 35 µV, dòng bước 0.35 mA, nhiệt độ phân giải 0.1 °C), và mức thực tế (giả định, ghi rõ).

**Bước G. Bộ điều khiển NMPC**
- Tính lại dòng sạc liên tục theo trạng thái ước lượng.
- Hàm mục tiêu cân bằng thời gian sạc và lão hoá.
- Ràng buộc: V ≤ 4.2 V, nhiệt độ, quá thế mạ lithium có biên an toàn.
- Pin "thật" trong mô phỏng là DFN đầy đủ với tham số bị làm lệch.

**Bước H. Bốn phương án so sánh cho từng vùng sạc**
1. CCCV (baseline 0.3C và 1C);
2. Profile tối ưu tính sẵn, áp vòng hở;
3. NMPC biết hết trạng thái;
4. NMPC + EKF.

So sánh phải công bằng: cùng thời gian sạc, hoặc báo cả thời gian và lão hoá.

**Thiết kế so sánh do người dùng chốt (17/11/2026)**

Với mỗi trường hợp (vùng sạc × mức dòng CCCV × nhiệt độ môi trường):
1. Chạy CCCV, lấy thời gian sạc T_CCCV và mức lão hoá.
2. Chạy phương pháp đề xuất với **ngân sách thời gian** k·T_CCCV, k ∈ {0.8; 1; 1.25; 1.5; 2; 3; không giới hạn}.
   - k = 1: "sạc đúng bằng thời gian của CCCV".
   - "Không giới hạn": chỉ tối thiểu lão hoá. Sẽ có điểm tối ưu, vì sạc quá chậm thì SEI lại tăng theo thời gian.
3. Kết quả mỗi trường hợp là một đường "thời gian sạc ↔ lão hoá", trên đó có điểm CCCV.

| Chiều của lưới | Giá trị | Số mức |
|---|---|---|
| Vùng sạc | bắt đầu 0–95 %, kết thúc cao hơn, **bước 5 %** (người dùng chốt lưới mịn) | 210 |
| Dòng CCCV | 0.3C, 0.5C, 1C (2C nếu có nguồn cho phép) | 3–4 |
| Nhiệt độ môi trường | 10, 25, 40 °C | 3 |
| Ngân sách thời gian k | 0.8; 1; 1.25; 1.5; 2; 3; không giới hạn | 7 |
| Phương pháp | tối ưu tính sẵn; NMPC biết hết trạng thái; NMPC + EKF | 3 |


Tổng số trường hợp: 210 vùng × 3 mức dòng × 3 nhiệt độ × 7 mức thời gian × 3 phương pháp ≈ 39 700 bài toán tối ưu, cộng 210 × 3 × 3 = 1 890 lần chạy CCCV.

**Chạy trên GitHub Actions, tận dụng 20 job song song**
- Repo công khai: tối đa 20 job Linux chạy cùng lúc; mỗi job tối đa 6 giờ; một workflow tối đa 256 job trong ma trận. Đặt `max-parallel: 20`; một lượt chạy xếp hàng được 256 job, tức tối đa khoảng 20 × 6 h mỗi đợt 20 job.
- Chia việc: mỗi job nhận một "lô" trường hợp, ví dụ một nhiệt độ × một mức dòng × một nhóm vùng sạc. Mỗi job ghi CSV riêng; một job cuối gộp kết quả.
- Mỗi lô phải chạy xong dưới khoảng 5 giờ. Nếu không, chia nhỏ hơn hoặc dùng nhiều lượt chạy nối tiếp. Kết quả từng lô được lưu, để chạy lại thì bỏ qua lô đã xong.
- Tối ưu dùng mô hình rút gọn; chấm điểm cuối dùng DFN đầy đủ cho mọi trường hợp.
- Hai đợt: đợt 1 là lát cắt nhỏ (vài vùng, 25 °C, đủ 7 mức k, đủ 3 phương pháp) để đo thời gian chạy thật; báo người dùng tổng thời gian dự kiến trước khi chạy đợt 2 (toàn lưới).

**Bước I. Đường Pareto thời gian – lão hoá**
- Thay đổi trọng số trong hàm mục tiêu, vẽ cho một số vùng đại diện.

**Bước J. Chạy toàn bộ**
- 55 vùng sạc (bước 10 %) × 4 phương án × các mức baseline.
- Nhiều chu kỳ (không chỉ một lần sạc), nhiều nhiệt độ môi trường (ít nhất 10, 25, 40 °C).
- Chỉ số lão hoá chỉ tính phần **không lấy lại được**: mô phỏng cả pha xả sau khi sạc, để lithium mạ tạm thời bóc lại. Đây là bài học từ bản cũ.

**Bước K. Kiểm tra độ tin cậy**
- Độ bền khi tham số của pin "thật" lệch so với mô hình trong bộ điều khiển.
- Đối chiếu thứ hạng các vùng sạc với thực nghiệm Kirkaldy 2024. Ví dụ ở 6 kAh: vùng 70–85 % còn 91–93 % dung lượng; 85–100 % còn 82–89 %; 0–30 % còn 79–87 %.

**Bước L. Dọn dẹp và tài liệu**
- Xoá bản rút gọn cũ.
- Viết lại `de_bai.md`, `mo_hinh_toan.md`, `README.md`, `tong_quan_tai_lieu.md` (thêm các bài gốc mới dùng).
- Báo cáo tổng hợp: bảng thống kê từng vùng, hình, danh sách giả định, giới hạn.

## 6. Giới hạn đã biết, phải nêu trong báo cáo

- Không có tham số lão hoá silicon cho LG M50: tầng 2 là giả định.
- Mô hình lão hoá của Li 2025 chỉ được khớp ở vùng 70–85 % và kiểm chứng ở 85–100 %, với dòng sạc 0.3C. Vùng khác và dòng lớn hơn là ngoại suy.
- Không có thực nghiệm kiểm chứng cho profile sạc tối ưu: so sánh với CCCV là kết quả mô phỏng.
- Mô hình nhiệt chỉ có một nhiệt độ cho cả cell. Số đo cho thấy bề mặt không đều: ở 2C, giữa thân nóng lên 33–42 K, đầu dương chỉ khoảng 41 % mức đó.
- Một bài khác loại pin (Karger 2024) cho thấy dòng sạc không nằm trong ba yếu tố lão hoá chính. Mức cải thiện so với CCCV có thể nhỏ ở nhiều vùng; nếu vậy vẫn báo đúng như thế.

## 7. Cách làm việc gợi ý

- Việc lớn và độc lập thì giao cho luồng phụ chạy song song, mỗi luồng ghi vào thư mục riêng để không đè file của nhau. Chỉ một luồng được commit vào `src/dfn/` tại một thời điểm.
- Commit chỉ thêm đúng file mình tạo hoặc sửa, không dùng `git add -A`.
- Sau mỗi bước, báo người dùng bằng số liệu thật từ CI, kể cả khi kết quả xấu.
