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

**Bước H. Các phương án so sánh cho từng vùng sạc (cập nhật 17/11/2026)**
1. CCCV (baseline). Ngưỡng chuyển sang giữ áp là `par.V_cv` dùng chung.
2. **Sạc nhiều bậc (bảng tra) rút ra từ kết quả tối ưu.** Đây là mức "dùng được ngay ngoài đời"; người dùng yêu cầu thêm ngày 17/11/2026.
   - Dạng: dòng sạc là hằng số theo từng dải SOC và từng nhiệt độ môi trường, có thể theo cả ngân sách thời gian k.
   - Rút bảng từ profile tối ưu tính sẵn của **một tập vùng sạc "huấn luyện"**, rồi đánh giá trên **mọi** vùng. Không lấy bảng từ chính trường hợp đang chấm.
   - Vẫn phải chịu đủ ràng buộc an toàn; nếu một bậc vi phạm thì tự giảm dòng (luật đơn giản, ghi rõ).
3. Profile tối ưu tính sẵn, áp vòng hở.
4. NMPC biết hết trạng thái (cận trên lý tưởng).
5. NMPC + EKF (thực tế, chỉ dùng cảm biến).
6. **Phân tích tách hiệu ứng:** tối ưu tính sẵn chỉ với giới hạn điện áp và dòng như CCCV, không có ràng buộc an toàn. So với (3) để thấy phần lợi do tối ưu dòng và phần chi phí do bắt sạc an toàn.

Quy tắc công bằng:
- CCCV cũng được kiểm tra bằng đúng các ràng buộc an toàn. Báo rõ khi CCCV mạ lithium, làm bề mặt hạt đầy, hoặc quá nhiệt.
- Bộ tối ưu khởi đầu từ đường CCCV.
- Trường hợp không có cách sạc an toàn nào trong ngân sách thời gian thì ghi "không thể sạc an toàn trong thời gian này", không bỏ qua.
- Lão hoá = lithium mất vĩnh viễn (SEI + lithium chết), đo sau khi sạc rồi xả về SOC đầu vùng. Lithium mạ tạm thời chỉ thống kê.
- **Người dùng chốt (17/11/2026): KHÔNG cho CCCV nghỉ thêm.** Mỗi cách sạc được chấm ngay khi sạc xong (rồi xả về SOC đầu vùng, giống nhau cho mọi cách). Cách nào sạc lâu hơn thì tự chịu phần SEI tăng thêm theo thời gian.

**Thiết kế so sánh do người dùng chốt (17/11/2026)**

Với mỗi trường hợp (vùng sạc × mức dòng CCCV × nhiệt độ môi trường):
1. Chạy CCCV, lấy thời gian sạc T_CCCV và mức lão hoá.
2. Chạy phương pháp đề xuất với **ngân sách thời gian** k·T_CCCV, k ∈ {0.8; 1; 1.25; 1.5; 2; 3; không giới hạn}.
   - **Ngân sách là thời gian TỐI ĐA, không bắt buộc dùng hết** (người dùng chốt 17/11/2026): thời gian sạc t ≤ k·T_CCCV. Ví dụ cho tối đa 60 phút mà sạc xong trong 30 phút cũng được.
   - k = 1: "không lâu hơn CCCV".
   - "Không giới hạn": chỉ tối thiểu lão hoá. Sẽ có điểm tối ưu, vì sạc quá chậm thì SEI lại tăng theo thời gian.
3. Kết quả mỗi trường hợp là một đường "thời gian sạc ↔ lão hoá", trên đó có điểm CCCV.

| Chiều của lưới | Giá trị | Số mức |
|---|---|---|
| Vùng sạc | **bước 20 %** (người dùng chốt 17/11/2026): 0→20, 0→40, 0→60, 0→80, 0→100, 20→40, …, 80→100 | 15 |
| Dòng CCCV | 0.3C, 0.5C, 1C (2C nếu có nguồn cho phép) | 3–4 |
| Nhiệt độ môi trường | 10, 25, 40 °C | 3 |
| Ngân sách thời gian k | 0.8; 1; 1.25; 1.5; 2; 3; không giới hạn | 7 |
| Phương pháp | bảng nhiều bậc; tối ưu tính sẵn; NMPC biết hết trạng thái; NMPC + EKF; tối ưu không ràng buộc an toàn (tách hiệu ứng) | 5 |


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

## 6b. Trạng thái khi tắt máy (17/11/2026, tối)

**Đã xong và đã đẩy lên:**
- DFN với bộ tham số "approved"; kiểm chứng xả: 35 mV (90 % đầu), nhiệt độ 2.1 K.
- A/B/C, tham số `par.V_cv` (xem "Ghi chú bàn giao DFN A/B/C + V_cv" ở cuối file).
- Mô hình rút gọn (src/nmpc/, tai_lieu/mo_hinh_rut_gon.md), khớp DFN 1–9 mV.
- NMPC acados, đã khử biến đại số (commit d8d667c). **Chưa chạy thử thành công lần nào.**
- Commit a88fcf4 là WIP của luồng NMPC (lưới 20 %, pilot_run), lưu vội trước khi tắt máy, chưa chạy CI.

**Quyết định của người dùng (17/11/2026):**
- Lão hoá chỉ tính phần mất vĩnh viễn (SEI + lithium chết). Lithium mạ tạm thời chỉ thống kê và giải thích.
- Giả định đã xác nhận: I_max 2C; T_max 45 °C; δ = 10 + 35 mV; x_s,max 0.99.
- Coi sai số điện áp mô hình ~1 % là chấp nhận được. Ngưỡng giữ áp `par.V_cv` = 4.2 V × (1 − f), chọn f từ phép quét.
- Lưới vùng sạc bước 20 % (15 vùng).
- Ngân sách thời gian là giới hạn trên (t ≤ k·T_CCCV).
- Chấm ngay khi sạc xong, không cho CCCV nghỉ thêm.
- Thêm phương án bảng sạc nhiều bậc và phân tích tách hiệu ứng.

**Việc dở dang, làm theo thứ tự khi mở lại:**
1. **Đọc kết quả phép quét V_cv** (run 44069154814, artifact `diag-all`). Chọn f trên dữ liệu 25 °C, kiểm tra ở 0 và 10 °C, rồi **báo người dùng** (không tự đổi mặc định).
   - Lưu ý: với mặc định mới, cả ba nhiệt độ trên dữ liệu mở vẫn dừng vì bề mặt hạt đầy trước 4.2 V; độ lệch cuối CC khoảng −52 đến −55 mV. Vì vậy cần xem f nào chạm được ngưỡng trước khi hạt đầy.
2. **Đọc kiểm chứng xả** (run 44065810310, artifact `validation-report`), so approved-new với approved-old.
3. **Cập nhật gia_dinh.md** (GD-40 A, GD-41 B, GD-42 C, GD-43 V_cv là sai số mô hình chứ không phải độ chính xác cảm biến, trạng thái GD-16) và mục DFN trong README.
4. **NMPC:** chuyển `cccv_window.m`, `nmpc_model.m` sang `par.V_cv` qua `v_limit.m`; chạy thử trên 3 vùng thuộc lưới 20 %, đủ 7 mức k; báo bảng thời gian ↔ lão hoá, thời gian giải, vi phạm ràng buộc.
5. Tiếp tục các bước B, C, D, F, H… như mục 5.

## 7. Cách làm việc gợi ý

- Việc lớn và độc lập thì giao cho luồng phụ chạy song song, mỗi luồng ghi vào thư mục riêng để không đè file của nhau. Chỉ một luồng được commit vào `src/dfn/` tại một thời điểm.
- Commit chỉ thêm đúng file mình tạo hoặc sửa, không dùng `git add -A`.
- Sau mỗi bước, báo người dùng bằng số liệu thật từ CI, kể cả khi kết quả xấu.

## Ghi chú bàn giao DFN A/B/C + V_cv (17/11/2026)

- **Code đã đẩy hết** (commit 9451b61 và fab337d): A — `par.ocp_n_branch = 'delith'` (mặc định; `'hyst'` = cũ), hàm chung `src/dfn/dfn_ocp_mix.m` (ROM nên gọi hàm này); B — `par.ctrl.delta_pl_extra = 35e-3` V trong `dfn_params.m` (δ_total = δ_base + 35 mV); C — `par.val.x100_fresh = 0.9014`, chỉ áp trong `val_run_condition` (tuỳ chọn `x100mode`, mặc định `'fresh'`), biến thể so sánh `approved_old`. V_cv: `par.V_cv` (mặc định 4.2 V, GD-43), `dfn_cccv` nhận `par.V_cv`; NMPC (`cccv_window.m`, `nmpc_model.m`) vẫn dùng `par.Vmax` — cần chuyển sang `par.V_cv`.
- **Chưa làm:** cập nhật `gia_dinh.md` (GD-40 A, GD-41 B, GD-42 C, GD-43 V_cv; mục 0 ngày 17/11/2026; trạng thái GD-16) và mục DFN của `README.md` bằng số CI.
- **Kết quả đã có:** self-test (validate run 44065810310, artifact `selftest`): mới — CC 0.3C tới 4.2 V sau 10833 s, CV 1126 s, nạp 4.641 Ah, x_surf max 0.99957, min(φs−φe) phía màng ngăn 67.7 mV; cũ — dừng vì bão hoà (x = 0.9999) ở 4.158 V sau 10207 s, nạp 4.253 Ah, 57.7 mV.
- Sạc dữ liệu mở (diag run 44065862869, artifact `diag-all`): mới (`val_new`, x100 = 0.9014) — bước nhảy đầu sạc 139/120/89 mV (đo 108/88/69; cũ 287/334/342), RMSE pha CC 19/24/33 mV (cũ 49/52/68) ở 0/10/25 °C, sai số cuối CC −55/−54/−52 mV (cũ −21/−20/−27); **mọi lần sạc vẫn dừng vì bão hoà bề mặt phía màng ngăn trước 4.2 V → GD-16 CHƯA giải quyết** trên dữ liệu mở. `val_new_both` (bỏ hysteresis cả cực dương): RMSE CC 25/30/39 mV, kém hơn → chỉ bỏ ở cực âm.
- **Đang chạy:** kiểm chứng xả 12 điều kiện, approved mới và `approved_old` cạnh nhau (validate run 44065810310, artifact `validation-report`); quét V_cv = 4.2(1 − f), f = 0/0.5/0.75/1/1.25 % (diag run 44069154814, artifact `diag-all`; tổng hợp: cột tCC_sim, tCV_sim, Qtot_sim, QCC_sim, stop_CC, xsn_max, dphi_sep_min_mV của `hyst_*_phases.csv`, lần sạc sau xả). Chọn f chỉ theo 25 °C (khớp tCV và Ah), báo 0/10 °C là kiểm tra; **không đổi mặc định V_cv** — người dùng quyết.

## Ghi chú bàn giao lão hoá B+C (17/11/2026)

- **Xong (đã đẩy):** bước B — `tai_lieu/dac_ta_lao_hoa.md` viết lại, nhãn [BÀI]/[GỐC]/[CODE]/[GĐ] cho từng phương trình/tham số; GD-50…GD-64 trong `gia_dinh.md`.
- **Xong (đã đẩy):** bước C — lão hoá "5 coupled" trong DFN (tuỳ chọn `aging = true`, mặc định tắt): `dfn_aging_*.m`, `dfn_side_reactions.m`, `dfn_dryout_*.m`, `dfn_li_inventory.m`, `dfn_perm_loss.m` (mất Li vĩnh viễn cho lưới so sánh), driver `src/dfn/aging/ag_*.m`, workflow `aging.yml` (mode selftest | smoke | full).
- **Selftest đạt** (aging run 44115706119, artifact `aging-selftest`): tốc độ = 0 trùng DFN (lệch 0), JPattern đủ, bảo toàn Li ≤ 2e-11, cạn khô bảo toàn chính xác, ~2 s/chu kỳ ⇒ chạy từng chu kỳ (Jmax = 0) khả thi (~4–5 h/trường hợp).
- **Đang dở:** smoke run 44118010063 (`ag_run` ngắn). Lần smoke trước (44116560905) hỏng: ode15s thất bại ở pha CV 0.1C trong RPT1 (t = 1154 s, I = −0.08 A); đã thêm khởi động lại + in chẩn đoán trong `ag_exec.m` — đọc log của 44118010063 trước.
- **Tiếp theo:** khi smoke đạt → `gh workflow run aging.yml -f mode=full` (12 job: Expt 2/3 × 10/25/40 °C × V_cv 4.116/4.2, 3 chặng checkpoint, jumpcheck Jmax 20/50) → đọc artifact `aging-report` (`aging_validation.md`), điền bảng kết quả vào README (chỗ `KETQUA_LAO_HOA`).
- **Validate (hồi quy, aging tắt):** run 44115694736 — kiểm tra số trùng 44102112653.
- **Cần người dùng quyết:** GD-55 (Table 4 mâu thuẫn (S41), đã chọn (S41) bảo toàn Li), GD-56 (thấm ướt lại có trần A_max), GD-60 (SOH chuẩn hoá theo RPT0), V_cv 4.116 V vs 4.2 V của giao thức (chạy cả hai).

## Ghi chú bàn giao EKF (17/11/2026)

- **Đã xong:** `src/ekf/` (ekf_build: dùng nguyên `rom_equations` của NMPC, R_film thành tham số rf; tích phân CasADi collocation + Jacobian giải tích; ekf_step = IEKF 5 lần lặp, Joseph; ekf_init/P0; ekf_outputs: SOC, η_Li sep, T, LLI, R_film/L_SEI kèm σ; ekf_sensor; ekf_plant_par (GD-72); ekf_run_case; ekf_report; ekf_estimator = bộ bọc handle cho `cfg.estimator` của nmpc_closed_loop), workflow `.github/workflows/ekf.yml`, GD-70…74 trong `gia_dinh.md` mục 7, bản nháp `tai_lieu/bo_uoc_luong_ekf.md` (mục 5–8 còn chỗ trống KQ_*).
- **Tự kiểm tra đạt** (run 44112714209, job selftest): dự đoán EKF = rom_sim lệch 1.2e-6 (V 0.000 mV); Jacobian A lệch 2e-5, H lệch 7e-9 so với sai phân; 0.54 s/bước (IDAS 4 s/bước).
- **Kết quả thử v1 (EKF thường, run 44112714209) XẤU:** bước cập nhật đầu (sai SOC 10 %) dồn sai số vào rf và LLI rồi kẹt: nominal 25 °C 1C rf → 5.6 (thật 1), SOC lệch 0.7 %, η_Li max 13.5 mV, NEES η 265; mismatch: rf → 10 (thật 1.5), SOC lệch 1.8 %, η_Li max 23 mV (ước CAO = phía nguy hiểm); bms −10 %: SOC lệch −6 %, LLI 0.77 Ah (thật 0.097); 10 °C bms_off: dừng vì g_z suy biến (đã thêm chia đôi khoảng + kiểm tra).
- **Đang chạy:** run 44120710755 (IEKF n_iter = 5, các biến thể P0 nhỏ, q1h.rf, sV_model = 10 mV, t_hold = 600 s giữ rf/LLI). Run 44120144673 hỏng vì lỗi cú pháp (đã sửa).
- **Việc tiếp:** đọc run 44120710755 (`/tmp` script: lấy log từng job, dòng "KET QUA"); chọn cấu hình; chạy `stage=full` (32 job) bằng workflow_dispatch; điền bảng vào bo_uoc_luong_ekf.md; đánh giá biên 45 mV (σ_η từ P đang quá tự tin → cần biên lùi theo sai số thực nghiệm); ghi chú tích hợp NMPC (truyền chuỗi mẫu đo, NMPC nên nhận rf ước lượng làm tham số).
- **Vấn đề mở:** LLI và rf quan sát yếu trong một lần sạc, lẫn với sai SOC đầu và lệch j₀/D_s; lệch j₀/D_s gây sai η_Li có hệ thống mà EKF không thấy.

## Ghi chú bàn giao NMPC pilot (17/11/2026, viết bởi điều phối)

- Luồng NMPC bị dừng khi tắt máy, trước khi kịp viết ghi chú. Commit cuối của nó: cf85569. Commit 33a0adf: mỗi job = một vùng × một dòng CCCV, chạy đủ 7 mức k; có báo vi phạm của CCCV; tự dùng lão hoá của DFN khi bật (`aging_from_plant`).
- **Chưa có kết quả chạy thử NMPC nào.** Việc dở dang lúc dừng: nối `plant_run` (dòng cuối của luồng: "Now wire it into plant_run"). Kiểm tra `git diff cf85569 -- src/nmpc` không còn gì dang dở trước khi chạy.
- Việc tiếp: chạy `nmpc.yml` (workflow_dispatch, chế độ pilot), đọc log, báo bảng kết quả vào `tai_lieu/ket_qua_pilot_nmpc.md`.
- Lượt NMPC cũ 44068312720 nằm chờ rất lâu; người dùng có thể huỷ trong tab Actions.

## Quyết định người dùng (17/11/2026, tối)

- Điện áp sạc: coi 4.116 V (V_cv mặc định) **tương đương 4.2 V**. Sạc lên 4.116 V được coi như đã đạt 4.2 V của giao thức thí nghiệm. Kiểm chứng lão hoá (Expt 2/3) chạy với V_cv = 4.116 V; biến thể 4.2 V không cần thiết.
- GD-60 (chuẩn hoá SOH): **người dùng chốt dùng một con số cố định chung**: SOH = dung lượng / 4.865 Ah (Li 2025, dung lượng ban đầu của cell LG M50T) cho mọi mô phỏng và mọi phương pháp. Cần đổi mặc định trong code (hiện đang chuẩn hoá theo RPT đầu của mô hình).
- GD-55 (nồng độ sau khi cạn) và GD-56 (thấm lại): giữ lựa chọn hiện tại (bảo toàn lithium; thấm lại tối đa bằng diện tích ban đầu).
- Người dùng không muốn bị hỏi lắt nhắt: với các điểm mơ hồ nhỏ trong bài báo, chọn phương án đúng vật lý và bảo toàn, ghi vào gia_dinh.md, rồi báo gộp. Chỉ hỏi ngay khi lựa chọn có thể làm đổi kết luận chính.
- 17/11/2026 (khoảng 23:20 giờ VN): đã khởi động kiểm chứng lão hoá đầy đủ, chỉ biến thể V_cv = 4.116 V: run 44123422399 (`aging.yml`, mode=full: selftest + Expt 2/3 × 10/25/40 °C, nối tối đa 3 chặng, kiểm chứng nhảy chu kỳ Jmax 20/50, báo cáo `aging-report`). Phiên sau: đọc kết quả, so với Kirkaldy 2024 / Li 2025, điền README mục KETQUA_LAO_HOA. SOH phải tính theo 4.865 Ah (cột chuẩn hoá cố định đã được lưu).

## Ghi chú bàn giao EKF (18/11/2026)

- Chọn cấu hình theo tiêu chí đặt trước (bo_uoc_luong_ekf.md mục 6.1–6.2): IEKF 5 lần lặp, **giữ rf/LLI cả lần sạc** (`t_hold = Inf`), P₀ rf 0.2, LLI 0.05 Ah (GD-75, GD-76). Ước cao η_Li xấu nhất trên 3 ca khó: 8.9 mV (cũ 19.5).
- Đang chạy lưới đầy đủ 76 ca: run 44202422495 (`ekf.yml` stage=full, GD-77). Việc tiếp: tải artifact `ekf-report`, điền mục 6.3–6.4 và 8 của bo_uoc_luong_ekf.md, mục EKF trong README.

## Ghi chú bàn giao kiểm chứng lão hoá (18/11/2026)

- **Xong:** đủ 6 trường hợp (Expt 2/3 × 10/25/40 °C), V_cv = 4.116 V, mô phỏng từng chu kỳ (run 44123422399 + 44196614322). Báo cáo: `tai_lieu/ket_qua_lao_hoa.md`, bản sao artifact ở `tai_lieu/ket_qua_lao_hoa/`; README mục "Kết quả kiểm chứng lão hoá".
- **Sửa lỗi:**
  - Expt 2 25 °C hỏng vì runner mất kết nối, không phải lỗi số. Đã thêm tải checkpoint giữa chặng, `resume_run` và `mode=report`.
  - 4 job jumpcheck hỏng vì ngoại suy mọi trạng thái. Đã viết `ag_jump.m` (GD-58); 12/12 job đạt, sai số ≤ 0.09 điểm SOH.
- SOH mặc định = Q/4.865 Ah (GD-60); cột phụ `SOH_rpt0_pct`.
- **Kết quả:** mô hình cho LLI/LAM khoảng ½ thực nghiệm; MPE_tot 22–25 % (Expt 2) so với 10–12 % của Li 2025. Không chỉnh tham số.
- **Cần người dùng quyết:** chạy độ nhạy hay không — (a) hệ số SEI 1/2 như code tác giả thay vì 1/4 theo bài gốc; (b) biến thể `vcv42`. Với nhảy chu kỳ J_max = 20, mỗi phương án mất khoảng 1–1.7 h CI cho 6 trường hợp chạy song song.

## Ghi chú bàn giao NMPC: NaN vùng SOC cao (18/11/2026)

- **Nguyên nhân** status 1 (NaN, SQP vòng 0) ở 40→100 %: Newton của bộ tích phân IRK acados phân kỳ khi một bước nạp quá nhiều điện tích lúc dòng lớn (khoảng dự báo ~246 s, 8 bước = 31 s/bước). Không phải lỗi mô hình. Chi tiết và số liệu: GD-87 trong `gia_dinh.md`; công cụ `nmpc_irk_probe.m` (biến thể `+irk`).
- **Sửa** (commit 5f2d3c3): số bước IRK mỗi khoảng chọn theo điện tích nạp mỗi bước ≤ 36 A·s (`nmpc_steps.m`), đoạn đầu tách ra `nmpc_guess.m` và tính trước khi tạo bộ giải trong `pilot_run.m`. Token biến thể mới: `f32` (khoảng đầu 32 bước), `s16`, `h<A·s>`, `irk`.
- **Kiểm chứng**: runs 44246288104 / 44246300668 / 44246313263 / 44246325754: 96/96 lần giải không NaN.
- `nmpc.yml` stage pilot có thêm input `wins`, `cbases` (JSON) để chạy lại một phần.
- **Chạy lại**: run 44249312514 (40→100 %, 0.5C và 1C, đủ 7 k) và run 44249331640 (20→80 % 1C k = 0.8, 7 lần thất bại trong 44237965357). Các job vùng 12 của 44237965357 chạy code cũ ⇒ bỏ, dùng kết quả của 44249312514. Việc tiếp: tải artifact, gộp với các job vùng 3/8 của 44237965357 (`pilot_report`), điền `ket_qua_pilot_nmpc.md`.
- **Cập nhật 18/11/2026 (sáng):** lưới đầy đủ lần 1 (run 44202422495) có 15 ca dừng ở 0.5C sai SOC +10 % ⇒ thêm tìm theo đường + fading memory (GD-78). Lưới lại: run 44219685690 (chỉ tìm theo đường) và 44219690606 (thêm fading, **được chọn** theo tiêu chí đặt trước, gần hoà). 0/76 ca dừng. Ước cao η_Li xấu nhất 17 mV (pin lệch tham số) ⇒ biên 45 mV không che sai số ước lượng; **cần người dùng quyết** có cộng biên lùi ≈ 20 mV cho NMPC + EKF không. bo_uoc_luong_ekf.md mục 5–8 và README đã điền.

## Quyết định người dùng (18/11/2026)

- **Lão hoá:** giữ nguyên mô hình như hiện tại (hệ số SEI 1/4 theo bài gốc, V_cv = 4.116 V). **Không chạy** hai phép thử độ nhạy (hệ số 1/2, sạc 4.2 V). Báo cáo phải nêu rõ: mô hình cho LLI/LAM khoảng một nửa số đo Kirkaldy 2024 (MPE_tot 15–29 % so với 10–26 % của Li 2025), kèm các nguyên nhân có thể (tai_lieu/ket_qua_lao_hoa.md).
- **EKF:** giữ biên an toàn 45 mV cho cả NMPC + EKF. **Không** nâng lên 65 mV. Báo cáo phải nêu rủi ro: khi tham số pin lệch, EKF có thể ước lượng η_Li cao hơn thật tới 17 mV (phía nguy hiểm) và tính số lần vi phạm thật trên DFN trong kết quả NMPC + EKF.
- Lão hoá trong DFN được coi là đã kiểm chứng (kèm giới hạn trên) để dùng làm "pin thật" cho lưới so sánh: đặt `par.aging.validated = true` khi chạy lưới.

## Ghi chú bàn giao bước D — tầng 2 silicon (18/11/2026)

- **Đã đẩy** (commit c95e3f3): tuỳ chọn `si` (mặc định tắt; tắt thì tầng 1 không đổi), `src/dfn/dfn_si_params.m`, trạng thái ε_Si trong `dfn_mesh`/`dfn_aging_*`, Expt 1 (0–30 %) và Expt 5 (0–100 %) trong `ag_cycle`/`ag_rpt`/`ag_run`, `ag_si_selftest.m`, `ag_si_report.m`, `aging.yml` (input `extra`, mode `si_selftest`, bước báo cáo silicon). GD-90…GD-95 trong `gia_dinh.md` (còn chỗ trống KQ_SI_CAL, KQ_SI_JC).
- **Tự kiểm tra đạt** (run 44258798913): k = 0 trùng tầng 1 (lệch 0 / 1.7e-14 V), JPattern đủ, bảo toàn Li ≤ 1.4e-11, nhảy chu kỳ đúng. Với k tạm 3e-14 (dạng B): mất Si ~33 %/kAh ở 0–30 %, ~12 %/kAh ở 0–100 %, ~1.4 %/kAh ở 70–85/85–100 % (do w_lo = 0.1).
- **Đang chạy khi tắt máy:** run 44258818797 (probe hiệu chỉnh: Expt 1, 25 °C, dạng B, k = 3e-15 / 3e-14 / 3e-13, J_max 20); run 44258808944 (tầng 1: Expt 1/5/2/3 × 10/25/40 °C, J_max 20).
- **Chọn k và dạng:** tải artifact `aging-report` của 44258818797, đọc `silicon/silicon_report.md` mục 1 (`si_calibration.csv`): mỗi probe cho k* và RMSE LAM_Si cho dạng A/B/C so với trung bình cell D/E/F ở 25 °C. Chọn dạng + k có RMSE nhỏ nhất, ưu tiên probe có LAM_Si cuối 5–70 % (ánh xạ chính xác nhất). Nếu k* chạm biên hoặc không có tối ưu rõ: mở rộng dải probe một lần (vd. k = 3e-16 hoặc 3e-12); nếu vẫn không có thì báo, không đoán. Ghi vào `dfn_si_params.m` (`si.form`, `si.k` — hiện là giá trị TẠM) và GD-93.
- **Lệnh chạy tầng 2 (sau khi sửa k):**
  `gh workflow run aging.yml -f mode=runs -f expts='[1,5,2,3]' -f variants='["si"]' -f jmax=20 -f jumpcheck='[0]' -f jc_temps='[25]' -f extra='{"jc_expts":[1],"jc_variant":"si","jc_nsets":8}' -f report_runs='44258808944'`
  (báo cáo gộp tầng 1 từ 44258808944; jumpcheck = chạy từng chu kỳ Expt 1 25 °C, 8 set, để kiểm chứng nhảy chu kỳ → KQ_SI_JC).
- **Còn lại:** viết `tai_lieu/ket_qua_silicon.md` (tiếng Việt đơn giản: tầng 1 / tầng 2 / đo cho 0–30 % và 0–100 % — SOH /4.865 Ah, LLI, LAM_NE, LAM_Si; các mốc văn bản Kirkaldy 2022; 10/40 °C và 0–100 % là dữ liệu kiểm tra; mục 5 của báo cáo: tầng 2 − tầng 1 ở 70–85 / 85–100 % có "gần như không đổi" không); điền KQ_SI_CAL, KQ_SI_JC trong `gia_dinh.md`; cập nhật README (mục lão hoá: tầng 2 là tuỳ chọn giả định).

### Cập nhật bàn giao NMPC (18/11/2026, tắt máy)

- **Đã đẩy:** GD-87 (số bước IRK theo điện tích, sửa NaN), GD-88 (lệch η pin − ROM e_b, tham số acados thứ 10; kiểm tra ngân sách trên DFN `nmpc_safe_plant.m`), sửa `struct2table(..., 'AsArray', true)` (job 40→100 % 1C k = 0.8 của 44237965357 hỏng vì lỗi này), cột mới `T_min_safe_plant_s`, `eb_min_mV`; `nmpc_replay_diag` thêm lệch V ở 1/4 cuối.
- **Đang chạy:** run 44258812043 (`nmpc.yml` stage pilot, wins [12], cbases [0.5, 1], đủ 7 k, code 13bf439) = chạy lại toàn bộ vùng 40→100 % với các sửa trên. Các run 44249312514 / 44258668502 đã huỷ (code cũ), bỏ qua.
- **Đã có:** run 44249331640 = 20→80 % 1C k = 0.8 chạy lại với GD-87: ok, 0 thất bại, mất +8.95 % so với CCCV (thay dòng cũ có 7 thất bại).
- **Chẩn đoán replay (run 44258903310, artifact `replay-diag`):** (1) vi phạm η 41.2 mV ở 40→100 % (1C k = 1, 0.5C k = 0.8 của 44237965357) xuất hiện **cả trên ROM** khi chạy lại cùng profile (η min ROM = DFN = 41.2 mV; lệch η RMS 0.7 mV, max 3.8 mV) ⇒ nguyên nhân chính không phải lệch ROM–DFN mà là lần giải thất bại (NaN, 11 lần, dự phòng 330 s) / nghiệm status 2 chưa hội tụ của code cũ; GD-87 đã bỏ NaN. Lời giải thích trong GD-88 cần sửa theo điểm này sau khi có 44258812043. (2) 40→100 % 0.5C: NMPC kém CCCV 0.5–0.7 % **cả trên ROM** (ROM: CCCV 0.07618, NMPC 0.07674 mAh; lệch V ROM − DFN 1/4 cuối chỉ 0.3 mV) ⇒ không do ROM lệch; do NMPC sạc lâu hơn ~100 s (6196 so với 6090 s): đoạn đầu CCCV-an-toàn bậc 30 s trên ROM (6180 s) chậm hơn CV liên tục, và SQP (≤ 4 vòng/lần giải nóng) không rời xa đoạn đầu. Ở vùng kết thúc gần đầy, pha CV chiếm phần lớn nên lời tối đa có thể rất nhỏ.
- **Việc tiếp theo (đúng thứ tự):**
  1. `gh run view 44258812043` đến khi xong; `gh run download 44258812043 -p 'pilot-w*'`.
  2. Gộp: lấy các dòng `pilot_w3_*`, `pilot_w8_*` của 44237965357 (thay `pilot_w8_c10_T25_k1` bằng dòng của 44249331640) + mọi dòng `pilot_w12_*` của 44258812043; bỏ dòng w12 của 44237965357. Lưu ý cột mới chỉ có ở dòng mới (điền NaN khi gộp). Chạy `pilot_report` (hoặc stage report) trên thư mục gộp.
  3. Kiểm tra ở 40→100 %: số lần status 1 (mong 0), trạng thái k = 0.8/1 (infeasible theo kiểm tra DFN hay ok không vi phạm), η min ≥ 45 mV.
  4. Viết lại `tai_lieu/ket_qua_pilot_nmpc.md`: bảng trung thực (lão hoá là hậu kiểm TẠM THỜI), ghi rõ vùng 0→60/20→80 chạy với 8 bước IRK cố định, vùng 40→100 với GD-87/88; nêu chẩn đoán (2) ở trên. Sửa lời giải thích GD-88 theo (1).
  5. (Tuỳ chọn, cần người dùng/điều phối đồng ý) đoạn đầu CCCV trên ROM với CV liên tục thay cho bậc 30 s, để NMPC 40→100 % 0.5C không chậm hơn CCCV.

### Quyết định người dùng 18/11/2026 (sau bàn giao)
- KHÔNG thử warm start CV liên tục cho vùng gần đầy lúc này. Hoàn thành toàn bộ dự án theo kế hoạch trước (silicon bước D, NMPC+EKF, bước H, lưới đầy đủ, K, L); chênh lệch 0,5–0,7 % ở 40→100 % 0,5C được báo cáo như hiện tại.
- **18/11/2026 (sau):** đã gộp 42 trường hợp (44237965357 + 44249331640 + 44258812043) vào `ket_qua_pilot_nmpc.md` / `.csv`, sửa GD-88. Còn mở: vi phạm η 2.5 mV ở 40→100 % ngân sách sát (0.5C k = 0.8, 1C k = 1); NMPC kém CCCV 0.4–0.7 % ở 40→100 % 0.5C (người dùng: chưa sửa, ghi là giới hạn).
- **Cập nhật 19/11/2026: bước D XONG.** Dạng C, k = 3.5e-14 (68debba); tầng 2 chạy đủ (run 44319826055). Kết quả: `tai_lieu/ket_qua_silicon.md`, artifact sao ở `tai_lieu/ket_qua_silicon/`; README và GD-93/95 đã điền.

### Bàn giao NMPC + EKF và phân tích dòng (19/11/2026)
- **Xong:** vòng kín NMPC + EKF (GD-89, biến thể `pilot+ekf`), run 44332295621, 42 trường hợp: `tai_lieu/ket_qua_nmpc_ekf.md` / `.csv`. Phân tích dòng sạc (`src/nmpc/current_analysis.m`, stage `current`, run 44421878394): mục 5 của `ket_qua_pilot_nmpc.md`, mục 4 của `ket_qua_nmpc_ekf.md`, dữ liệu `tai_lieu/dong_sac/`.
- **Cần quyết:** ở 40→100 % NMPC + EKF nạp thiếu 0.21–0.35 % SOC (5 trường hợp) và vượt V_cv 0.45–1.89 mV do nhiễu đo V gần ngưỡng (v_b và điều kiện dừng dùng một mẫu đo). Đề xuất: lọc bằng trung bình 30 s, chạy lại 14 job vùng 40→100 %; hoặc giữ và báo. Vòng kín với pin lệch tham số chưa chạy.

## Quyết định người dùng 19/11/2026
- **Lưới đầy đủ chỉ chạy mô hình 5 cơ chế** (tầng 1). Tầng silicon không dùng trong lưới; chỉ nêu trong báo cáo (kết quả `ket_qua_silicon.md`) và phần giới hạn cho các vùng chạm SOC thấp.
- **Nạp thiếu / vượt áp nhỏ chấp nhận được** (không cần chính xác tuyệt đối): KHÔNG lọc điện áp đo, KHÔNG chạy lại 14 job 40→100 %. Phân loại theo dung sai GD-96: nạp thiếu ≤ 0.5 % SOC và vượt V_cv ≤ 2 mV được tính là "đạt (trong dung sai)", vẫn ghi số thật. η_Li < 45 mV vẫn là vi phạm.

### Lưới đầy đủ: chạy thử đo thời gian (19/11/2026)
- Code: `.github/workflows/grid.yml` (plan → run → report, chạy tiếp được qua `prev_runs`), `src/nmpc/grid.py`, `src/nmpc/gd96.py`, GD-97. Pin thật = DFN có lão hoá (`NMPC_PLANT_AGING=1`).
- Mẫu đo: run 44425116351 (vùng 0→20, 0→100, 60→80 × 0.3C/1C × 10/40 °C × k = 1, ∞ × NMPC/NMPC+EKF; 2 job 0→100 1C 10 °C hỏng do `rom_replay` → sửa, chạy lại ở run 44425494274). 47/48 trường hợp có CSV; 3 trường hợp 0→100 bị hết giờ job (`wall_limit`), 1 bị bỏ qua.
- Thời gian một trường hợp (vòng kín + xả): vùng 20 % 1250–5500 s; 0→100 % 6300–18200 s, một số > 5.3 h (không xong trong một job 6 h). Phần chung mỗi job ~10–13 phút (CCCV + tạo bộ giải acados ~9 phút).
- **Ước tính lưới đầy đủ (1890 trường hợp): ~3300 giờ máy, ~830 job ⇒ ~7 ngày với 20 job song song** (> 3 ngày). Người dùng chọn phương án 2 + điểm lưu (tăng tốc, không đổi kết quả, không cắt phạm vi).

### Quyết định người dùng 19/11/2026 (lưới đầy đủ)
- Chọn phương án **tăng tốc rồi chạy đủ**: chạy song song 3–4 trường hợp/job, lưu bộ giải acados đã biên dịch giữa các job, thêm lưu dở/chạy tiếp cho trường hợp dài; kiểm tra lại kết quả trùng mẫu cũ; sau đó chạy toàn bộ lưới (không bớt phạm vi).

### Lưới đầy đủ: tăng tốc + điểm lưu, đang chạy (19–20/11/2026)
- GD-98: 4 worker Parallel Computing Toolbox mỗi job (`grid_run_all.m`), số bước IRK riêng từng k, bộ giải acados lưu trong actions/cache (`grid_build_all.m`, tên OCP cố định `ocp_rom_nmpc_<mã>`), điểm lưu giữa chừng (`nmpc_closed_loop.m` `ckpt_*`). CCCV vi phạm: cột `cccv_status` (GD-97).
- Kiểm chứng: so lại mẫu (run 44558052403 so với 44425116351, 14 trường hợp chung): cùng trạng thái, cùng số lần giải, lệch mất tương đối ≤ 1.2e-7. Lưu sau 40 lần giải (44488927646) rồi chạy tiếp ở job khác (44496107266, bộ giải mới; 44561078637, bộ giải từ cache): trùng chạy một mạch (lệch ~5e-9), hai bản chạy tiếp trùng nhau từng bit.
- Thời gian: 4 trường hợp cùng lúc chậm 1.42× mỗi trường hợp (2 nhân thật) ⇒ ~2.8× nhanh hơn mỗi job. **Ước tính mới ~1580 giờ máy ⇒ ~3.3 ngày** (±25 %).
- **Đang chạy (đợt 1):** run 44595405408 (NMPC biết hết trạng thái, 135 job) và 44595428301 (NMPC + EKF, 135 job); job vùng rộng chạy trước.
- **Chạy tiếp (lặp tới khi hết):** khi cả hai run xong, bấm lại với mọi run đã chạy:
  `gh workflow run grid.yml -f methods='["nmpc","ekf"]' -f tag=full-2 -f prev_runs='[44595405408,44595428301]'`
  (plan bỏ qua trường hợp đã có CSV, xếp job chạy tiếp cho trường hợp có `ckpt_*.mat`, còn lại chạy mới; mỗi run ≤ 256 job). Đợt sau thêm run ID vào `prev_runs`. Báo cáo gộp: artifact `grid-report-<tag>` (`grid_all.csv`, `grid_summary.md`, `remaining.json` = việc còn lại).

### 20/11/2026 — trạng thái lưới
- Run 44595405408 (nmpc) xong: 897/945 trường hợp (799 ok, 2 ok_tol, 30 ok_violation, 3 failed, 63 infeasible); 48 trường hợp lưu dở (17 job).
- Đợt 2 nmpc: run 44774406780 (`methods=["nmpc"]`, `prev_runs=[44595405408]`).
- Run 44595428301 (ekf) đang chạy; 2 job failure (w2 c1 T10, w10 c0.3 T10) — xem log khi run xong. Đợt tiếp ekf: `prev_runs=[44595428301]`, `methods=["ekf"]`.
