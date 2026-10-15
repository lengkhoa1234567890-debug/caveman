# APT5.pine — đồng bộ với AutoPositionTool_UI.mq5 (bản hiện tại)

Phạm vi: nhãn, giá trị trong nhãn, đường vẽ, vị trí nhãn. **Bỏ qua nhãn/cột Pattern** (giữ nguyên).
Chuẩn so sánh: bảng `[BANG FORMAT NHAN HIEN TAI]` ở đầu file MQL5 và các hàm `DrawRv2RsiLabels`, `DrawWoodiePivotEma`,
`DrawBarChart`, `DrawBarChartLabels`, `BuildBarCurLblRows`, `DrawBrkDHHLL`, `DrawOwLabelsAll`, `DrawRvLinesSelTF`, `AptRndMarksDraw`, `DrawCloseSimpleLabels`.

## 1. Định dạng nhãn (trước → sau)

| Nhãn | Trước (Pine cũ) | Sau (khớp MQL5) |
|---|---|---|
| Pivot | `<TF><cdlS1> { <WPR1> <WPR2>}` | `<TF>[ <lamtron>] (<Pivotdiff>/<Pivotdiff2>)<diffpv> <SpR2>/<SpR1> <RV1MD>/<RV1OW>(<so nen>/<diffV1V2>) <TenMuc> <RSI> <RSI5>/<xu huong>` |
| RV1 | `<TF>{[SpR/dPv]<sig><brkD> <mau hinh> ...}` (tự chế) | `<TF> {<T>}[<W%>]<pls><IMB>{<erh>/<erhdiff> <erl>/<erldiff>}[ <SigBrk><brkD>(<streak>)]<FVG>` |
| RV2 | `<TF> (<V1V2>) <diffrv1>/<diffrv2>` | `<TF> <MA1> /<MA2> [<RV1W%>] <RV1erh>/.. <RV1erl>/.. [<RV2W%>] <RV2erh>/.. <RV2erl>/..` |
| Cụm dưới thân nến lớn | `%`, Dmax, Dmin, Elapsed, hết giờ, (DSS) | `%`, Dmax, Dmin, Elapsed, hết giờ, đệm `" "` đủ 5 hàng, `brkD`, `TC`, `UPDDND`, cặp khung, `RV2 <TF> : ...` |

Các trường mới được port: `<lamtron>` (AptRoundNearStr), `Pivotdiff/Pivotdiff2`, `SpR1/SpR2`, `RV1MD/RV1OW` (MD = TB Open, OW = LWMA(Open) n nến đã đóng),
`<so nen>` (số nến Pivot EMA cùng phía OW), `<pls>`, `<T>` (AptHHLLStrengthStr), `[W%]`, `erh/erl` (RSI-EMA trên kênh HH/LL giá và trên chuỗi RV1/RV2),
`<IMB>` có thời gian, `<FVG>` (`xxG` / `-xxG`), `<streak>` theo AptBrkStreakCount, MA của William %R **không kẹp** (Wpr8Unclamped, seed EMA = SMA mẫu cũ nhất).

## 2. Vị trí / neo nhãn
- Pivot, RV1, RV2 đều **neo TRÁI** (`label.style_label_left`) như `ANCHOR_LEFT` của MQL5 (RV1/RV2 trước đây neo phải).
- Mặc định cột: Pivot `+2`, RV1-1m `+20`, RV1(≥5m) `+30` (InpRv1LeftM1FutureBars), RV2 `+44` (InpRv1Rv2LeftM1BarIdx) (input `i_gapRv1m1`). Pine không đo được độ rộng chữ → chỉnh tay theo zoom.
- Mốc làm tròn màu trắng kết thúc ngay trước vạch Open của thân nến lớn (như hình MQL5), không còn ở xa bên phải.
- Khoảng cách dòng giữa các nhãn cùng cột = ATR14 × `i_crlStep` (mặc định 0.28).
- Nhãn Pivot đặt tại EMA(5) **live** của mức (ema[0]), không phải EMA đã chốt.
- Chống chồng nhãn giữ `f_priorityPushY` (khung nhỏ giữ đúng giá thật, khung sau bị đẩy theo chiều giá gốc; RV1-1m không bị đẩy). Khoảng đẩy là ATR14 × `i_crlStep`, không phải pixel như MQL5.

## 3. Thân nến lớn
- Khung mặc định `2h` (InpBarChartTF = H2), 16 nến (`i_barCount`): nến đang chạy tại `nến 1m hiện tại + 1`, nến đã đóng tại giữa chu kỳ; mỗi nến 3 đoạn (Low–High, Open trái, Close phải), độ dài vạch = `i_box15WidthBars` **nến chart** (trước chia đôi).
- Nhãn `%` biên độ ở đầu vạch Close của nến đã đóng (`i_barLblPctCount` = 30), màu theo nến.
- Hàng `brkD` / `TC` / `UPDDND` / cặp khung / `RV2 trend` chuyển từ cụm 6 hàng riêng cạnh RV1-1m **vào cụm dưới thân nến lớn** như MQL5.
- 6 hàng DaySwingStructure + nhãn Call/Flip/Put **không có** trong MQL5 hiện tại → giữ code nhưng mặc định TẮT (`i_showDss`).

## 4. Nhãn/đường mới
- `HH<tf>` / `LL<tf>` / `MD<tf>` của kênh brkD (khung chọn `i_hhllTf`), `OW<tf> <so nen>` cho mọi khung, mốc LÀM TRÒN màu trắng (R/S, HH, LL, OW — gộp khi trùng giá), nhãn Close Simple `< 1m SMA200`.
- Đường: chỉ vẽ **một bộ duy nhất** cho **một khung** chọn ở `i_hhllTf` (1m…6h, mặc định 1m, "Tat" = không vẽ): RV1 **magenta**, RV2 **màu khung**, EMA(5) của **mức Pivot đang chọn** `i_pivLvl` (thay S1 cố định), OW = LWMA(Open,n) xanh lá; tất cả nét đứt. Đã bỏ bộ đường 5m riêng.
- `max_labels_count` / `max_lines_count` nâng lên 500; `APT_SAMP_N` 12→100, `APT_TFBAR_HIST` 125→205 (đủ SMA200 và kênh W%/erh/erl).

## 5. Mặc định đã đổi cho khớp MQL5
`i_brkDBars` 5→10, `i_brkScoreTfCount` 2→3, `i_barTF` 15m→2h, `i_asymSpreadPts` → đổi thành `i_spreadPrice` = 0.5 (đơn vị GIÁ; TradingView có mintick 0.001 nên quy đổi "point" bị sai ~10 lần so với MT5), cỡ chữ `normal`→`small`.

## 6. Không thể giống 100% (giới hạn của Pine)
- Không có spread/tick sống → spread = hằng số `i_spreadPrice` (giá, ví dụ XAUUSD ≈ 0.5).
- Không có các bộ đếm giây `UpA/DnA, Up/Dn, UpB/DnB, UpC/DnC` → màu nhãn vẫn theo `rowClr` (brk), không theo `AptPivotRowColor`; `pvD` và phần `| per%` của hàng cặp khung bị bỏ; cặp `H4&D1`, `D1&W1` không có (Pine không có D1/W1).
- `brkScore Up/Dn`, `TC CMF Up/Dn`, `UpD/DnD`, thời điểm Pivot cắt OW trong nến hiện tại: đếm bằng `varip`, chỉ cộng dồn từ lúc script chạy live.
- Cụm dưới thân nến là **một label** nên không tô màu riêng từng hàng được như MQL5.
- Khung lớn thiếu lịch sử 1m → các trường cần nhiều nến (W%, erh/erl, SMA200, FVG…) hiện `-` hoặc ẩn, đúng quy ước "thiếu dữ liệu" của MQL5.
- Chưa port: `DrawFvgEdges`, `DrawLines`/`DrawSetup`, `LqzScanAndDraw`, `Rv1SignalDraw` (nằm ngoài 4 cột nhãn/thân nến).

> Chưa thể biên dịch trên TradingView trong môi trường này; đã kiểm tra cú pháp bằng trình phân tích Pine (pynescript) và rà soát tham chiếu thủ công. Cần dán vào Pine Editor để xác nhận kiểu dữ liệu.
