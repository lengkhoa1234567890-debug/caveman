//+------------------------------------------------------------------+
//|                                             AutoPositionTool.mq5 |
//|   Tu dong quet cau truc -> de xuat Entry / SL / TP                |
//|   Ve vung Risk - Reward + Forecast giong cong cu                  |
//|   "Long Position / Short Position / Forecast" cua TradingView     |
//+------------------------------------------------------------------+
//==================================================================
//  [BANG FORMAT NHAN HIEN TAI] Format cac nhan tren chart theo code dang chay. Comment trong than ham mo ta hanh vi hien tai cua doan code ngay duoi no.
//  Quy uoc: <x> = mot truong; cac ky tu ( ) { } [ ] / in ra DUNG NHU VIET; dau cach chi in o cho co dau cach. Thieu du lieu -> truong in "-".
//
//  Vi tri tren chart (tu than nen lon sang phai): cot PIVOT (sat truc than nen lon) -> cot RV1 -> cot RV2; cot PATTERN neo trai-duoi tai
//  moc thoi gian cua nhan RV1 khung 1m. Moi khung thoi gian co 1 nhan o moi cot.
//
//  LUU Y: TEN nhan o day = TEN OBJECT tren chart; moi nhan hien chuoi nhu sau (khong theo ten goi cua chuoi trong code):
//        - nhan "PIVOT" (object nhan Woodie cua muc <TenMuc>) hien chuoi dai _swapPvTxt (<TF> <Pivotdiff> <Pivotdiff2> <RSI5>/<xu huong>).
//        - nhan "RV1"   (object g_rv1RsiLblPrefix+TF)  hien chuoi txt1 trong DrawRv2RsiLabels: <TF> <SpR2>/<SpR1> (<rawdiffV1V2>/<diffV1V2>)[<SigBrk>...].
//        - nhan "RV2"   (object g_rv2RsiLblPrefix+TF)  chi hien <TF> (bien txt trong DrawRv2RsiLabels).
//        - COT "PATTERN" (object PFX"PATL_"+i)         hien <TF>{<DxyTenMuc>} <UpE>/<DnE> <UpB>/<DnB> <Up>/<Dn> ... <FVG><LVN><IMB> (g_patCdlStr[]).
//      Moi muc duoi day ghi ro: TEN nhan tren chart | bien/dong code tao ra chuoi | FORMAT theo THU TU TRAI -> PHAI | y nghia tung truong.
//
//  ------------------------------------------------------------------------------------------------------------------------------------
//  1) NHAN PIVOT  | chuoi = _swapPvTxt trong DrawRv2RsiLabels() (dong "_swapPvTxt = g_tfName[i] + " " + _pvDiff1Txt + ...") | object = nhan Woodie cua muc <TenMuc>
//     FORMAT : <TF> <Pivotdiff> <Pivotdiff2> <RSI5>/<xu huong>
//     vd     : 4h 0.3 0.5 48/+2       (vd minh hoa hinh dang, khong phai so thuc)
//     LUU Y  : nhan Pivot da bo [ ] cung <diffavg>, <(Bid-Open)/spread>, <TenMuc>, <RSI>, <Owtron> (<Owtron> nay o nhan RV2); cac muc 4d/4e/5/6 duoi day chi con la mo ta cach tinh.
//     Nhan KHONG in <lamtron> (chi con dung de danh dau len thang gia - AptRndMarksDraw()), <so nen>, [<OWW%>] va <RV1MD>/<RV1OW>.
//     0. <TF>          = ten khung (g_tfName[i]), cach <Pivotdiff> 1 dau cach.
//     1. <Pivotdiff>   = (ema[0]-ema[1])/spread cua muc Pivot dang chon o bang UI (g_pivotEmaDiffStr[]); thieu -> "-"; cach <RSI5>/<xu huong> 1 dau cach.
//     2. <RSI5>/<xu huong> = RSI cua EMA muc Pivot / do lech RSI, nguon g_pivotLblBaseText[i] (DrawEmaSeries()), bo dau cach quanh "/" -> "48/+2", thieu -> "-".
//     3. (da chuyen) [<PivotW%>] = William %R cua Pivot khong con tren nhan PIVOT; chuyen sang COT hang 2.. duoi nhan RV1 1m (muc 2c, truong <PivotW%>).
//                        (tren nhan PIVOT, <Pivotdiff2> cach <RSI5>/<xu huong> 1 dau cach.)
//     4. <Pivotdiff2>  = cung cach tinh <Pivotdiff> nhung cho muc <TenMuc> (g_pivotEmaDiff2Str[]); thieu -> "-"; cach <RSI5>/<xu huong> 1 dau cach.
//     4b. [<diffpv>] [<diffpv2>] = (chuyen tu nhan RV1) [<diffpv>] = (RV1 - gia muc Pivot)/spread, [<diffpv2>] = (RV2 - gia muc Pivot)/spread, moi so 1 so le (M1_ELP_LBL_DIF1_DIGITS); thieu -> [-];
//                        cach <Pivotdiff2> 1 dau cach, 2 cum cach nhau 1 dau cach, [<diffpv2>] DINH LIEN truoc [<diffpv3>] (khong dau cach).
//     4e. [<Owtron>/<diffavg>/<(Bid-Open)/spread>] = 1 cum trong [ ] dinh lien truoc <TenMuc>, cach <Pivotdiff2> 1 dau cach. <Owtron> = (OW - gia nhan lam tron GAN GIA GIUA NHAT)/spread, 1 so le (M1_ELP_LBL_DIF1_DIGITS);
//                        OW = OW cua khung do (cung nguon <diffpv3>); nhan = nhan lam tron mau trang gan (Bid + Ask)/2 nhat, khong gioi han khoang cach (AptRndNearestMidLvl());
//                        khong co nhan lam tron / thieu OW / spread -> "-". <diffavg> xem 4d. Vd "[-1.5/4.1]", "[-/4.1]" (chua co nhan lam tron).
//     4d. <diffavg>    = (<diffpv> + <diffpv2> + <diffpv3>)/3 (thay cho 3 cum [<diffpv>] [<diffpv2>][<diffpv3>] cu), tinh tu gia tri CHUA lam tron cua ca 3, 1 so le (M1_ELP_LBL_DIF1_DIGITS);
//                        thieu RV1 / RV2 / muc Pivot / OW / spread -> "-"; khong ngoac, cach <Pivotdiff2> 1 dau cach, DINH LIEN truoc <TenMuc> (khong dau cach). (4b, 4c duoi day = cach tinh 3 thanh phan.)
//     4c. [<diffpv3>]  = (gia muc Pivot - OW)/spread, OW = EMA(Open) chu ky n = g_aptBrkDBars (AptOpenLwma(), cung nguon nhan OW<khung>), 1 so le (M1_ELP_LBL_DIF1_DIGITS);
//                        thieu OW / muc Pivot / spread -> [-]; DINH LIEN sau [<diffpv2>] va DINH LIEN truoc <TenMuc> (khong dau cach).
//     5. <TenMuc>      = muc Woodie gan Bid nhat cua khung (PP / R1..R9 / S1..S9, AptWoodieDisplayLvlForTF()), cach <Pivotdiff2> 1 dau cach; khong xac dinh -> rong (con nguyen 2 dau cach 2 ben).
//     6. <RSI>         = phan "<RSI>/<+-dRSI>" cua muc <TenMuc> (AptS1RsiTextForTF()), thieu -> "-".
//     7. <MA1> /<MA2>  = (chuyen tu nhan RV2) MA (InpMa8Period1/InpMa8Method1 cho RV1; InpMa8Period/InpMa8Method cho RV2) cua William %R tinh tren chuoi RV1(tf) / RV2(tf); SO NGUYEN; thieu -> "-".
//                        PERIOD William %R = chu ky nut B<n> dang chon tren UI (B5 / B10 / B20 / B50 / B200 = g_aptBrkDBars, kep 2..500; AptRvChanP()) - KHONG con lay InpWpr8Period1 / InpWpr8Period; cung chu ky voi <RV1W%> / <RV2W%> (o cot hang 2.. duoi nhan RV1 1m).
//                        William %R o day KHONG kep 0..-100: HH/LL lay tren "period" gia tri RV DA DONG ngay truoc (khong gom gia tri hien tai) -> Wpr8UnclampedAt().
//                        Dinh dang: <MA1>, 1 dau cach, "/", <MA2> (dau cach o TRUOC "/", KHONG co dau cach sau "/"); ca cum "(<MA1> /<MA2>)" bao trong ( ), cach <RSI> 1 dau cach, "(" dinh lien truoc <MA1>, ")" dinh lien sau <MA2>.
//     8. (da chuyen) [<RV1W%>] khong con tren nhan PIVOT; chuyen sang COT hang 2.. duoi nhan RV1 1m (muc 2c, truong <RV1W%>).
//     9. (da chuyen) [<RV2W%>] khong con tren nhan PIVOT; chuyen sang COT hang 2.. duoi nhan RV1 1m (muc 2c, truong <RV2W%>).
//     (Da bo <RV1MD>/<RV1OW> khoi nhan; AptRv1MdStr() / AptOwStr() con trong file nhung khong con duoc goi. Nhan OW<khung> tren chart khong doi.)
//     Nhan PIVOT KHONG co: {<T>}, [<W%>] (W% cua kenh brkD GIA, khong con tren nhan nao), [<PivotW%>] / [<RV1W%>] / [<RV2W%>] (nam o COT hang 2.. duoi nhan RV1 1m, muc 2c), <SigBrk><brkD>(<streak>), <SpR2>/<SpR1>, (<rawdiffV1V2>/<diffV1V2>) (nam o nhan RV1), <IMB>, <FVG>, <LVN> (nam o cot PATTERN); <pls> khong con tren nhan nao.
//
//  2) NHAN RV1    | object = g_rv1RsiLblPrefix+TF | chuoi = txt1 trong DrawRv2RsiLabels() (dong "txt1 = g_tfName[i] + " [" + _rv2LblDiffPvStr + ..."), 14 khung
//     FORMAT : <TF> (<rawdiffV1V2>/<diffV1V2>)
//     vd     : 4h (1.8/+3)        (vd minh hoa hinh dang, khong phai so thuc)
//     (<SpR2>/<SpR1> va <brkD>(<streak>)<SigBrk> da chuyen sang COT hang 2.. duoi nhan RV1 1m, xem muc 2c ngay duoi muc 2.)
//     1. <TF>          = ten khung (g_tfName[i]), cach (<rawdiffV1V2>/<diffV1V2>) 1 dau cach.
//     2. [<diffpv>]    = (da chuyen sang nhan PIVOT, xem muc 1 - 4b) khong con tren nhan RV1.
//     2b. [<diffpv2>]  = (da chuyen sang nhan PIVOT, xem muc 1 - 4b) khong con tren nhan RV1.
//     3. (<rawdiffV1V2>/<diffV1V2>) = cach <TF> 1 dau cach, bao trong ( ):
//          <rawdiffV1V2> = (RV1 - RV2)/spread, 1 so le (M1_ELP_LBL_DIF1_DIGITS), RV1 = g_rv1ValCache[], RV2 = g_aptRv2All[]; thieu RV1/RV2/spread -> "-".
//          <diffV1V2>    = so nen RV1 lien tuc cung phia so voi RV2 (+3 / -2), thieu -> "-".
//     (Da bo {<T>} va [<W%>] khoi nhan RV1; AptHHLLStrengthStr() / AptBrkWAt() con trong file, AptBrkWAt() van duoc cac bo dem Up/Dn dung.)
//     4. (da chuyen) <brkD>(<streak>)<SigBrk> khong con tren nhan RV1, xem muc 2c.
//     5-6. <IMB> = (da chuyen sang COT PATTERN, xem muc 4 - hien dang <TF>{<DxyTenMuc>} <UpE>/<DnE> <UpB>/<DnB> <Up>/<Dn> ... <FVG><LVN><IMB>); nhan RV1 ket thuc o (<rawdiffV1V2>/<diffV1V2>).
//     (Da bo {<erh>/<erhdiff> <erl>/<erldiff>} khoi nhan; AptErhErlStr() con trong file nhung khong con duoc goi. <FVG> = AptFvgPushStr() nay in o COT PATTERN, xem muc 4.)
//     Nhan RV1 KHONG co: [<diffpv>], [<diffpv2>], <Pivotdiff>, <Pivotdiff2>, <TenMuc>, <RSI>, <RSI5>/<xu huong>, <MA1> /<MA2> (nam o nhan PIVOT), <PivotW%>, <RV1W%>, <RV2W%>, <SpR2>/<SpR1>, <brkD>(<streak>)<SigBrk> (nam o COT hang 2.. duoi nhan RV1 1m), <IMB>, <FVG>, <LVN> (nam o cot PATTERN); <pls> khong con tren nhan nao.
//
//  2c) COT HANG 2.. DUOI NHAN RV1 1m | object = PFX"MIDLBL_1".."MIDLBL_14" | chuoi = txt[r] trong DrawMidPriceLabel() | 14 khung (1m 5m 15m 30m 1h 2h 3h 4h 6h 8h 12h 1d 1w 1nm, theo g_tfList)
//     FORMAT : <TF> <RV1W%>/<RV2W%> <PivotW%> [<brkD>(<streak>)<SigBrk>] <(Bid-Open)/spread> <SpR2>/<SpR1> <diffavg>
//     vd     : 5m -62/-48 -35 [112(3)▲] -0.8 -3/-5 4.1        (vd minh hoa hinh dang, khong phai so thuc)
//     1. <TF>                       = ten khung (g_tfName[]), cach <RV1W%>/<RV2W%> 1 dau cach.
//     2. <RV1W%>/<RV2W%>            = (chuyen tu nhan PIVOT) William %R cua RV1 / RV2 hien tai trong KENH HH/LL tinh tren CHINH chuoi RV1 / RV2 cua khung (chu ky P = nut B<n>): (HH-RV)/(HH-LL)*-100,
//                                     KHONG kep, SO NGUYEN (AptRvChanW()); thieu -> "-" (in "-/-" neu thieu ca hai). Khong ngoac. Do DrawRv2RsiLabels() tinh va cache o g_midRv1WStr[] / g_midRv2WStr[].
//     3. <PivotW%>                  = (chuyen tu nhan PIVOT) William %R cua gia tri Pivot (EMA Pivot cua muc chon o bang Pivot UI) trong KENH HH/LL cua CHINH chuoi Pivot cua khung, cung cach tinh <RV1W%>; thieu -> "-". Khong ngoac, cach <RV1W%>/<RV2W%> 1 dau cach (cache g_midPvWStr[]).
//     4. [<brkD>(<streak>)<SigBrk>] = (chuyen tu nhan RV1) brkD = (Close - LL)/(HH - LL)*100 cua kenh brkD GIA (AptBrkDAt(); >100 = pha dinh, <0 = thung day); <streak> = AptBrkStreakCount();
//                                     <SigBrk> = ▲ khi brkD >= 110, ▼ khi brkD <= -10, con lai khong in (dinh lien sau ")"); bao trong [ ], cach <PivotW%> 1 dau cach; thieu du lieu kenh -> [-].
//     5. <(Bid-Open)/spread>        = (Bid - Open nen DANG CHAY cua khung)/spread, 1 so le; thieu -> "-"; cach [ ] truoc 1 dau cach.
//     6. <SpR2>/<SpR1>              = (chuyen tu nhan RV1) lam tron (Bid-RV2)/spread va (Bid-RV1)/spread cua CHINH khung do, SO NGUYEN; thieu -> "-".
//     7. <diffavg>                  = (diffpv + diffpv2 + diffpv3)/3 cua CHINH khung do (cung cach tinh nhan Pivot), 1 so le; thieu -> "-".
//     LUU Y: <RV1W%>/<RV2W%>/<PivotW%> chi duoc cap nhat khi DrawRv2RsiLabels() chay den khung do (can bat cot nhan RV1 hoac RV2); khung thieu lich su hoac cot nhan tat -> "-".
//
//  3) NHAN RV2    | object = g_rv2RsiLblPrefix+TF | chuoi = txt trong DrawRv2RsiLabels() (dong "txt = g_tfName[i] + " " + _rv2LblOwTronStr + "(" + ...; txt += g_midRowTailStr[idx];" - cum nay tu dong dong ngoac ")")
//     FORMAT : <TF> <Owtron>(<RSI>/<dRSI> <RSI5>/<xu huong> <Pivotdiff2> <Pivotdiff> { <SigBrk><brkD>/<brkddiff><TenMuc> <bodiff>/<(Bid-Open)/spread> } <SpR2>/<SpR1> <diffavg>/<diffavg2>)   (<Owtron> chuyen tu nhan Pivot; cum tu <SigBrk> tro di lay tu hang khung cu cua nhan gia giua; (<RSI>/<dRSI> <RSI5>/<xu huong> <Pivotdiff2> <Pivotdiff>) dinh lien sau <Owtron> va truoc <SigBrk>)
//     vd     : 5m -1.5(48/+10 48/+2 0.3 -0.5 { ▲112/+5R2 0.1/-0.8 } -3/-5 4.1/0.2) 48/+10
//     0. <TF>          = ten khung (g_tfName[i]); sau do 1 dau cach roi <SigBrk><brkD>/<brkddiff> (brkD = (Close-LL)/(HH-LL)*100 cua kenh brkD GIA, <SigBrk> = tam giac tang khi brkD >= 110 / giam khi <= -10, brkddiff = brkD nen hien tai - brkD nen da dong truoc, co dau "+" khi duong; thieu -> "-"). Nhan RV2 khong con gi khac: <MA1> /<MA2> da chuyen sang nhan PIVOT, <RV1W%>/<RV2W%> sang cot hang 2.. duoi nhan RV1 1m; <RV1erh>/... <RV2erh>/... da bo (ke ca phan tinh toan; AptRvChanErStr() con trong file nhung khong con duoc goi).
//
//  4) COT PATTERN | object = PFX"PATL_"+i | chuoi = g_patCdlStr[i] (do DrawRv2RsiLabels() ghi, dong "g_patCdlStr[_rv1UdIdx] = g_tfName[i] + AptDxyLvlTag(...) + " " + <5 cap UpE, UpB, Up, UpC, UpA> + " " + _rv1NewFvg + _rv1NewLvn + _rv1NewImb"); chua co -> chi <TF>{<DxyTenMuc>}
//     FORMAT : <TF>{<DxyTenMuc>} <UpE>/<DnE> <UpB>/<DnB> <Up>/<Dn> <UpC>/<DnC> <UpA>/<DnA> <FVG><LVN><IMB>        vd: 3h{R2} 2.05/0 1.49/0 0/0 2.29/0 2.29/0 87G45L+12% 1.45s   (vd minh hoa hinh dang, khong phai so thuc)
//     {<DxyTenMuc>} = <TenMuc> (muc Woodie PP/R1..R9/S1..S9 gan gia nhat) cua CHINH khung do nhung tinh tren symbol DXY (o nhap g_edtDxyPrefix+"SYM", mac dinh InpDxySymbol),
//                     cung cong thuc AptWoodieDisplayLvlForTF() (EMA(5) cua muc Woodie, chon muc gan Bid DXY nhat); DINH LIEN sau <TF>; thieu du lieu / symbol khong ton tai -> {-}. Xem AptDxyLvlTag().
//     1. <TF>          = ten khung.            2. (da bo <cdlS1>; chuoi _rv1CdlS1Str van duoc tinh nhung KHONG con in ra cot Pattern).
//     3. 5 cap = bo dem Up/Dn (bo ky tu "s") theo DUNG thu tu: UpE/DnE, UpB/DnB, Up/Dn, UpC/DnC, UpA/DnA; cach nhau 1 dau cach; KHONG co ngoac tron; cap UpE/DnE cach {<DxyTenMuc>} 1 dau cach; cap UpA/DnA cach <FVG><LVN><IMB> 1 dau cach.
//        UpE/DnE = giay cong don: UpE cong khi <TenMuc> thuoc {PP, R1..R9} VA <brkD> >= 80 VA <brkddiff> > 0.1 VA <bodiff> > 0.1 ; DnE cong khi <TenMuc> thuoc {PP, S1..S9} VA <brkD> <= 20 VA <brkddiff> < -0.1 VA <bodiff> < -0.1 (<brkddiff> / <bodiff> = cung gia tri in o hang khung cua nhan gia giua, xem muc 2c; thieu <TenMuc> / <brkddiff> / <bodiff> -> khong cong). Cung nhip dt va cung moc reset (sang nen moi cua _aptAccResetTf) voi UpB/DnB, Up/Dn, UpC/DnC, UpA/DnA; do DrawBreakStats() cong.
//     4. <FVG>         = (AptFvgPushStr()) "<pct>G" (FVG tang) / "-<pct>G" (FVG giam) khi Bid DANG NAM TRONG mot vung FVG con hieu luc cua khung; ngoai vung -> RONG. Cach cap <UpA>/<DnA> 1 dau cach.
//     5. <LVN>         = (AptLvnPushStr()) "<pct>L" (vd "45L") khi Bid DANG NAM TRONG mot vung LVN (Low Volume Node) cua khung; pct = vi tri Bid trong vung, 0 = mep duoi, 100 = mep tren; ngoai vung -> RONG.
//                        LVN = cac muc gia LIEN TIEP co volume < 30% volume POC (APT_LVN_PCT) trong Volume Profile dung chung voi <IMB>; vung ngan hon 2 muc (APT_LVN_MIN_BINS) bi bo. DINH LIEN sau <FVG>.
//     6. <IMB>         = (chuyen tu nhan RV1) Imbalance cua khung (AptImbalanceForTF()), bo ngoac tron: "<+-pct>% <thoi gian>s"; co the RONG; DINH LIEN sau <LVN> (khong dau cach).
//     7. <pls>         = (da bo khoi nhan Pattern, truoc do chuyen tu nhan RV1; AptPlsStr() con trong file nhung khong con duoc goi.)
//                        Cac truong <FVG>, <LVN>, <IMB> dinh lien nhau, khong dau cach giua cac truong; <IMB> la truong CUOI cua nhan (vd "3h{R2} 1.49/0 0/0 2.29/0 2.29/0 " khi <FVG>, <LVN> va <IMB> rong).
//
//  5) COT <TenMuc> LICH SU | object = PFX"LVC_"+<nen>+"_"+<khung> | ve boi DrawAptLvlColumn() (goi tu DrawAptPatternColumn()) | input nhom "16."
//     FORMAT : MOI nen 1m trong pham vi co 1 COT nhan DUNG NGAY TREN DINH nen do; moi cot 14 nhan (1m o DUOI CUNG, khung lon xep len tren, giong cot PATTERN).
//              Moi nhan chi hien <TenMuc> = PP / R1..R9 / S1..S9 cua khung do (khong co ten khung; re chuot len nhan de xem tooltip "<khung> <TenMuc>"; mau = mau duong cua khung).
//     1. Pham vi       = InpLvlColBars nen 1m GAN NEN 1m HIEN TAI NHAT (mac dinh 5; tinh CA nen dang chay: shift 0..N-1).
//     2. Nen dang chay (shift 0) = <TenMuc> theo BID hien tai (cung ket qua voi AptWoodieDisplayLvlForTF() cua nhan PIVOT).
//     3. Nen lich su (shift >= 1) = <TenMuc> TAI THOI DIEM nen do: voi moi khung, lay nen cua khung do CHUA nen 1m ay (iBarShift), muc Woodie tinh tu H/L/C nen lien truoc cua khung,
//        EMA(APT_S1_EMA_PERIOD) tren chuoi muc - dung cong thuc AptWoodieDisplayLvlForTF() nhung doc DUNG diem lich su thay vi diem moi nhat; gia so sanh = Close nen 1m do
//        (Close nen 1m dong = Bid cuoi cung cua nen). Chon muc gan gia do nhat. Thieu du lieu -> "-".
//     4. Neo           = tren dinh nen 1m + InpLvlColAbovePts + APT_LVC_EXTRA_PTS (50) point; cac nhan xep len tren cach nhau (InpFontSize+7) pixel.
//     5. CAU TRUC 14 HANG (1m o hang 1 duoi cung): hang 1..6 = <TenMuc> cua khung 1m,5m,15m,30m,1h,2h (nhu tren). Hang 7..12 = (<diffpv>+<diffpv2>+<diffpv3>)/3 cua khung 1m,5m,15m,30m,1h,2h (hang 7 = 1m ... hang 12 = 2h),
//        lam tron SO NGUYEN (MathRound); <diffpv> = (RV1 - gia muc Pivot)/spread, <diffpv2> = (RV2 - gia muc Pivot)/spread (cung nguon voi nhan RV1: g_rv1ValCache[], g_aptRv2All[], g_pivotLvlValCache[]); thieu 1 trong 2 -> "-".
//        Hang 13, 14 de TRONG (khong ve nhan). Nen dang chay = gia tri tuc thoi; nen lich su = gia tri CUOI CUNG da ghi nhan truoc khi nen 1m do dong (ghi lai moi lan ve,
//        nen nen 1m xuat hien truoc luc indicator chay -> "-"). Mau = mau duong cua khung; tooltip "<khung> (diffpv+diffpv2+diffpv3)/3 <gia tri>".
//  5b) (DA BO - khong con ve) COT v0..v4 CHENH LECH SO VOI MUC LAM TRON GAN NHAT | object = PFX"RDC_"+j (j = 0..4) | DrawAptRndDiffColumn() con trong file nhung khong con duoc goi
//     FORMAT : 5 nhan SO NGUYEN xep doc, v0 tren cung -> v4 duoi cung, ngay DUOI DAY nen 1m hien tai (khung 1m). Moi nhan = (X - lamtron(X)) / spread, lamtron(X) = boi so GAN NHAT cua B
//              (nut LAM TRON UI) so voi X; am = X duoi moc, duong = X tren moc. X: v0 = Bid | v1 = RV1 1m | v2 = RV2 1m | v3 = Pivot (EMA muc chon o bang Pivot UI) | v4 = OW 1m. Thieu du lieu -> "-".
//  6) BANG TK GIA LAP / TK THAT HOM NAY | phan chi tiet them SAU 16 hang thong ke cu | ve boi StDetRows() (goi tu StBuild() va RtBuild())
//     FORMAT : hang "Gia vao + TenMuc 1m:" roi toi da 4 nhom (chi in nhom co lenh): "Mua thang (<so lenh>):" / "Mua thua (<so lenh>):" / "Ban thang (<so lenh>):" / "Ban thua (<so lenh>):",
//              moi nhom liet ke cac lenh HOM NAY (theo thu tu mo lenh; toi da SPM_DET_MAXITEMS lenh GAN NHAT, SPM_DET_PERROW lenh / hang) dang <gia vao><TenMuc>, vd 4120R2 4125R1 4135S1.
//              Mau: thang = xanh, thua = do. Lenh gia lap dang mo tinh theo lai/lo hien tai.
//     1. <gia vao>   = gia vao lenh (lenh that: gia deal vao dau tien cua vi the), lam tron so nguyen khi gia >= 100, nguoc lai _Digits so le.
//     2. <TenMuc>    = muc Woodie (PP / R1..R9 / S1..S9) cua khung 1m gan <gia vao> nhat TAI THOI DIEM MO LENH (AptLvlNameM1At(): EMA(APT_S1_EMA_PERIOD) cua muc Woodie
//                      tinh den dung nen 1m chua gio mo lenh, cung cong thuc AptWoodieDisplayLvlForTF()); thieu du lieu nen 1m -> "-".
//     3. Lenh gia lap DA DONG chi co gia vao tu khi co tinh nang nay (file phu SPM_<symbol>_hpx.csv); lenh dong truoc do khong co trong danh sach (van nam trong 16 hang thong ke cu).
//  7) VACH CHAN LO LENH GIA LAP | object = SPM_SLOSS_B<id> / SPM_SLOSS_S<id> | ve boi DrawStopLossMarks() (goi tu UpdateAll())
//     FORMAT : moi lenh 1 vach chu trang "-----STB" (BUY, tai muc S cua Pivot 1m) / "-----STS" (SELL, tai muc R cua Pivot 1m); gia CHOT LUC VAO LENH, khong dich chuyen theo Pivot sau do.
//              muc theo bang Pivot UI luc vao lenh (BUY: Rn doi thanh Sn; SELL: Sn doi thanh Rn; PP giu nguyen); cung truc thoi gian voi nhan Pivot 1m, sat ben trai nhan.
//
//  NHAN DUOI DAY THAN NEN LON (BuildBarCurLblRows): hang 1 = % bien do nen + $ + <artday> <artweek> <artmonth> (ATR nen manh D1/W1/MN1, AptAtrHi()), 2 = Dmax, 3 = Dmin, 4 = elapsed, hang 5..12 = CAO NHAT / THAP NHAT cua TUAN / THANG / QUI / NAM / 2 / 3 / 4 / 5 NAM hien tai,
//     lam tron ra BEN NGOAI dinh / day ve moc cua nut LAM TRON dang chon + so lan cham quanh khu vuc (pham vi W = o nhap trong bang LAM TRON UI, mac dinh 50). FORMAT hang 5..12: <ten> cao <gia> (<n> lan) thap <gia> (<m> lan),
//     vd "tuan cao 4155 (2 lan) thap 3955 (1 lan)" (chu viet co dau tren chart); canh bao het gio (neu co) nam sau hang 12. Xem AptPeriodExtremeUpdate().
//     Cac moc nay con duoc DANH DAU tren thang gia tai truc thoi gian cua than nen lon (AptPeriodExtremeMarksDraw()): nhan "◆ <gia> <ky> cao (<n> lan)" / "◆ <gia> <ky> thap (<m> lan)", moc trung gia gop 1 nhan noi bang " | ".
//     ALERT RIENG cho 8 moc nay (tuan / thang / qui / nam x cao / thap): am thanh rieng tung moc + push sang app MT5 dien thoai khi Bid vao vung moc - xem input nhom "18." va AptPeriodExtremeAlertCheck().
//  Ngoai ra than nen lon con cum hang nhan rieng (DrawBarChartLabels), nhan HH/LL/MD (DrawBrkDHHLL) va moc LAM TRON mau trang ten khung o mep phai chart
//  (AptRndMarksDraw(); chinh la <lamtron> cua nhan PIVOT) - khong thuoc 4 nhan tren.
//  Moc LAM TRON mau trang con co them moc tinh tu HH (nhu R1..R9) va LL (nhu S1..S9) cua KENH brkD tren cac khung tu 5m tro len
//  (ten nhan = ten khung + "H" hoac "L", vd "1hH" / "4hL"); cach tinh nhu R / S. Xem AptRndMarksDraw().
//  Them moc LAM TRON tinh tu muc OW (EMA(Open)) cac khung tu 5m tro len (nhan "<khung>OW", vd "1hOW"): RV1 >= OW -> cach tinh R (lam tron len), nguoc lai -> cach tinh S (lam tron xuong).
//  Nut "KC" (sau nut x5 cua LAM TRON UI): BAT -> nhan LAM TRON chi ve muc LE cua buoc (n * buoc + do lech, n le), vd buoc 10: 4170, 4190, bo 4180. Xem AptRndGapKeep().
//  Nhan LAM TRON GAN GIA GIUA NHAT them chuoi DOC NHANH (AptQuickReadStr()) rut gon tu <IMB> <LVN> <FVG> cua 14 khung o cot Pattern:
//     ĐCT/ĐCG = dao chieu tang/giam, XT/XG = xuyen/tiep dien tang/giam, TL = trung lap (|diem tong hop| < InpQrBand); diem tong hop S thuoc [-1, +1] co dau, cong theo trong so khung; kem <tang>/<giam>/<trung lap> = so khung nghieng tang / giam / trung lap, vd "ĐCT +0.42 7/2/5". Nguong IMB lon = input InpQrImbBigPct, vung chet TL = InpQrBand.
//  TO MAU NEN 1M theo nhan LAM TRON (AptRndCandlePaint(), chi khi chart la M1): nen cham/xuyen qua gia nhan roi bi BAT LEN tren nhan -> nen mau VANG; bi BAT XUONG duoi nhan -> nen mau TRANG.
//==================================================================
#property copyright "AutoPositionTool"
#property version   "1.00"
#property description "Auto scan swing structure -> Entry/SL/TP, SL/TP lines, lot size, R:R, ETA."
#property indicator_chart_window
#property indicator_buffers 5
#property indicator_plots   1
#property indicator_label1  "RndBounce Open;RndBounce High;RndBounce Low;RndBounce Close"
#property indicator_type1   DRAW_COLOR_BARS
#property indicator_color1  clrYellow,clrWhite
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

//==================================================================
//  ENUM
//==================================================================
enum EAptMode
  {
   APT_AUTO_BOTH  = 0, // Auto - ca 2 chieu
   APT_AUTO_LONG  = 1, // Auto - chi LONG
   APT_AUTO_SHORT = 2, // Auto - chi SHORT
   APT_MANUAL     = 3  // Manual - keo tay 3 duong
  };

enum EAptEntry
  {
   ENTRY_MARKET   = 0, // Entry = gia thi truong
   ENTRY_PULLBACK = 1, // Entry = hoi ve Fibo cua leg
   ENTRY_BREAKOUT = 2  // Entry = pha dinh / day
  };

enum EAptTP
  {
   TP_RR      = 0,     // TP theo he so R:R
   TP_STRUCT  = 1,     // TP tai dinh/day ke tiep
   TP_FIBOEXT = 2      // TP theo Fibo mo rong
  };

//==================================================================
//  INPUT
//==================================================================
input group             "=== 1. CHE DO QUET ==="
input EAptMode          InpMode           = APT_AUTO_BOTH; // Che do
input int               InpSwingDepth     = 5;             // Do sau swing (bar moi ben)
input int               InpLookback       = 300;           // So bar quet nguoc
input bool              InpRescanNewBar   = true;          // Quet lai moi bar moi

input group             "=== 2. BIAS / XU HUONG ==="
input bool              InpUseBias        = true;          // Dung multi-TF bias (CalcMultiTFBias: H12 -> M30)
input group             "=== 3. ENTRY / SL / TP ==="
input EAptEntry         InpEntryMode      = ENTRY_PULLBACK;// Kieu vao lenh
input double            InpFiboEntry      = 0.618;           // Ty le hoi (0.382/0.5/0.618)
input int               InpATRPeriod      = 14;            // Chu ky ATR
input double            InpSLatrMult      = 0.5;           // Dem SL = ATR x ...
input double            InpBreakBufATR    = 0.15;          // Dem breakout = ATR x ...
input EAptTP            InpTPMode         = TP_RR;         // Kieu chot loi
input double            InpRR             = 2.0;           // He so R:R muc tieu
input double            InpFiboExt        = 1.618;         // Fibo mo rong cho TP

input group             "=== 4. QUAN LY VON ==="
input bool              InpUseFixedMoney  = false;         // Dung so tien co dinh
input double            InpRiskPercent    = 1.0;           // Rui ro % balance
input double            InpFixedRisk      = 100.0;         // Rui ro co dinh (tien)

input group             "=== 5. ETA ==="
input double            InpSpeedFactor    = 0.60;          // Toc do gia = ATR x ... / bar

input group             "=== 6. HIEN THI ==="
input bool              InpShowPanel      = false;          // Hien bang thong tin
input ENUM_BASE_CORNER  InpCorner         = CORNER_LEFT_UPPER; // Goc panel
input int               InpPanelX         = 400;            // Panel X
input int               InpPanelY         = 10;            // Panel Y
input int               InpFontSize       = 10;             // Co chu
input string            InpFontName       = "Consolas";    // Font (monospace)
input color             InpColUp          = clrGold;        // Mau chieu TANG
input color             InpColDown        = clrWhiteSmoke;  // Mau chieu GIAM
input color             InpColEntry       = clrDodgerBlue;  // Mau duong Entry
input color             InpPanelBG        = C'20,20,20';    // Nen panel
input color             InpPanelBorder    = C'90,90,90';    // Vien panel

input group             "=== 7. CANH BAO ==="
input bool              InpAlertNewSetup  = false;         // Bao khi co setup moi
input bool              InpAlertTouch     = false;         // Bao khi cham Entry/SL/TP
input bool              InpPushAlert      = false;         // Gui push notification

// Nguong khoang cach (gia) giua Bid va dinh/day cua nen NGAY (D1) hien tai, quyet dinh phat Topday.wav / Baseday.wav trong AptCheckSoundAlerts().
input group             "=== 9. AM THANH CANH BAO ==="
input double            InpDayEdgeThresholdUSD = 5.0;      // Nguong Bid cach dinh/day nen ngay (gia) de phat Topday/Baseday

// Nguong dem UpA/UpB (>= InpUpBDiffPvMin) va DnA/DnB (<= -InpDnBDiffPvMax); xem khoi cong don trong DrawBreakStats().
input group             "=== 9B. NGUONG DEM UpA/DnA/UpB/DnB ==="
input double            InpUpBDiffPvMin   = 1.0;   // (khong con dung: UpA nay dung dRV1W%/dRV2W%/dPivotW% > 0.1, UpB dung <brkddiff> / <brkD>)
input double            InpDnBDiffPvMax   = 1.0;   // (khong con dung: DnA nay dung dRV1W%/dRV2W%/dPivotW% < -0.1, DnB dung <brkddiff> / <brkD>)

// William %R + MA tinh tren RV2(1m)/RV1(1m); cac khung khac dung chung cac chu ky nay. Hien trong nhan RV2 (<MA1> /<MA2>; luu y: PERIOD William %R cua <MA1> /<MA2> nay theo nut B<n> - AptRvChanP(), khong theo InpWpr8Period1/InpWpr8Period), InpWpr8Period con dung cho dieu kien WPR2 cua UpA/DnA. Mac dinh khop WPR_rVWAP_Osc.mq5.
input group             "=== 10. WILLIAM %R + MA CUA RV1/RV2 ==="
input int               InpWpr8Period     = 5;      // William %R Period tren RV2(1m) - khop InpWpr2Period cua WPR_rVWAP_Osc
input int               InpMa8Period      = 5;       // MA Period cua WPR tren RV2(1m) - khop InpMa2Period
input ENUM_MA_METHOD    InpMa8Method      = MODE_EMA;// Phuong phap MA cua WPR tren RV2(1m) - khop InpMa2Method
input int               InpWpr8Period1    = 5;      // William %R Period tren RV1(1m) - khop InpWprPeriod
input int               InpMa8Period1     = 5;       // MA Period cua WPR tren RV1(1m) - khop InpMaPeriod
input ENUM_MA_METHOD    InpMa8Method1     = MODE_EMA;// Phuong phap MA cua WPR tren RV1(1m) - khop InpMaMethod

// Cac khung 5m..1nm dung chung 6 chu ky WPR/MA o tren; chi them tran so nen M1 dung chung (khung W1/MN1 can nhieu nen M1 de warmup, xem Wpr9BuildM1Cache).
input group             "=== 11. WPR CAC KHUNG 5M..1NM ==="
input int               InpWpr9MaxM1Bars  = 50000;   // Tran so nen M1 dung chung cho ca 13 khung 5m..1nm (an toan hieu nang)

// Cot nhan Pattern + quet mau hinh dang tao (port logic ChartPatternScanner_Forming.pine). InpPatAbovePts = khoang cach (point) tu day cot nhan len dinh nen M1 hien tai, chi dung khi chua co nhan RV1 1m de neo (xem InpPatAboveRv1Pts).
input group             "=== 12. MAU HINH DANG TAO (MULTI-TF) ==="
input int               InpPatAbovePts    = 100;    // Day cot nhan pattern cao hon dinh nen M1 (point)
// Cot nhan Pattern neo theo truc thoi gian cua nhan RV1 khung 1m (g_rv1M1LblT, mep trai thang voi nhan RV1 1m), day cot cao hon nhan RV1 1m InpPatAboveRv1Pts point.
input int               InpPatAboveRv1Pts = 200;    // Day cot nhan pattern cao hon nhan RV1 khung 1m (point) - tuy chon
input int               InpPatLeftBars    = 5;      // Pivot trai
input int               InpPatRightBars   = 3;      // Pivot phai (xac nhan)
input double            InpPatEqTolPct    = 1.2;    // Dung sai dinh/day bang nhau (%)
input int               InpPatMinBars     = 8;      // Khoang cach toi thieu 2 swing (nen)
input int               InpPatMaxBars     = 80;     // Khoang cach toi da 2 swing (nen)
input int               InpPatAtrLen      = 14;     // ATR pattern
input bool              InpPatEnHS        = true;   // Head & Shoulders / Inverse
input bool              InpPatEnDT        = true;   // Double Top / Double Bottom
input bool              InpPatEnTT        = true;   // Triple Top / Triple Bottom
input bool              InpPatEnRound     = true;   // Rounding Top / Bottom
input bool              InpPatEnDiamond   = true;   // Diamond Top / Bottom
input double            InpPatHsHeadMin   = 0.8;    // H&S: dau cao/sau hon vai (xATR)
input double            InpPatHsSym       = 35.0;   // H&S: dung sai doi xung vai (%)
input bool              InpPatEnFlag      = true;   // Flag / Pennant
input bool              InpPatEnTri       = true;   // Triangle
input bool              InpPatEnRect      = true;   // Rectangle
input bool              InpPatEnWedge     = true;   // Wedge
input bool              InpPatEnCup       = true;   // Cup and Handle
input double            InpPatPoleAtr     = 2.2;    // Flag: chieu cao pole toi thieu (xATR)
input int               InpPatPoleLook    = 20;     // Flag: lookback pole (nen)
input int               InpPatCupMin      = 20;     // Cup: so nen toi thieu
input int               InpPatCupMax      = 120;    // Cup: so nen toi da

//==================================================================
//  GLOBAL
//==================================================================
#define PFX "APT_"

struct SSetup
  {
   bool     valid;
   int      dir;            // +1 = LONG, -1 = SHORT
   double   entry;
   double   sl;
   double   tp;
   double   slPts;
   double   tpPts;
   double   rr;
   double   lots;
   double   riskMoney;
   double   rewardMoney;
   int      etaBars;
   datetime etaTime;
   double   atr;
   string   note;
  };

SSetup     g_s;
int        g_hATR  = INVALID_HANDLE;
datetime   g_lastBar   = 0;
bool       g_started   = false;
double     g_prevEntry = 0.0;
int        g_prevDir   = 0;
uint       g_lastDraw  = 0;
bool       g_touchedE  = false;

//--- Break Stats
datetime        g_lastBarTF = 0;

// [KHONG CON DUNG cho dem Up/Dn - nay dung diffavg, xem DrawBreakStats()] Nguong cu: Up cong giay khi W% > InpUpWUp VA brkD > InpUpBrkUp; Dn cong giay khi W% < InpDnWDn VA brkD < InpDnBrkDn. W% = AptBrkWAt(), brkD = AptBrkDAt().
input group "=== Dieu kien dem Up/Dn (theo tung khung) ==="
input double InpUpWUp   = -20.0;  // Up: W% phai LON HON gia tri nay
input double InpUpBrkUp = 80.0;   // Up: brkD phai LON HON gia tri nay
input double InpDnWDn   = -80.0;  // Dn: W% phai NHO HON gia tri nay
input double InpDnBrkDn = 20.0;   // Dn: brkD phai NHO HON gia tri nay

input group "=== Doc nhanh IMB/LVN/FVG (nhan lam tron gan gia giua) ==="
input double InpQrBand      = 0.15;   // Doc nhanh: |diem tong hop| < gia tri nay -> TL (trung lap)
input double InpQrImbBigPct = 50.0;   // IMB: |pct| >= gia tri nay (% do rong Value Area) -> mat can bang LON (xuyen/tiep dien: XT/XG); nho hon -> hoi ve gia tri (dao chieu)
    // (khai bao dat TRUOC noi dung DrawBreakStats vi MQL5 yeu cau khai bao truoc khi dung)

// Bo dem Up/Dn (giay cong don) cua tung khung g_tfList[i]. DrawBreakStats() cong dt moi nhip khi dieu kien Up/Dn thoa (Up: diffavg2 > 0.1; Dn: diffavg2 < -0.1). Reset ve 0 khi sang nen moi cua moc reset (_aptAccResetTf trong DrawBreakStats).
// g_aptBrkAccLast = moc thoi gian lan cap nhat truoc, dung chung cho ca 14 khung trong mot nhip.
long            g_aptBrkAccUp[14];
long            g_aptBrkAccDn[14];
datetime        g_aptBrkAccBarT[14];
datetime        g_aptBrkAccLast = 0;

// Bo dem UpA/DnA (giay): UpA cong khi <dRV1W%>, <dRV2W%>, <dPivotW%> (thay doi W% theo giay, g_aptWChgV[]) deu > 0.1; DnA khi ca ba deu < -0.1.
// Dung chung moc reset g_aptBrkAccBarT[i] va dt voi cap Up/Dn.
long            g_aptBrkAccUpA[14];
long            g_aptBrkAccDnA[14];

// Bo dem UpB/DnB (giay): UpB cong khi (<TenMuc> thuoc {PP, R1..R9} va <brkddiff> > 1 va <bodiff> > 0.1) hoac <brkD> >= 100; DnB khi (<TenMuc> thuoc {PP, S1..S9} va <brkddiff> < -1 va <bodiff> < -0.1) hoac <brkD> <= 0 (g_aptBrkDDiffV[] / g_aptBoDiffV[] / g_aptBrkDV[], xem DrawBreakStats()).
// Dung chung moc reset g_aptBrkAccBarT[i].
long            g_aptBrkAccUpB[14];
long            g_aptBrkAccDnB[14];

// Bo dem UpC/DnC (giay): UpC khi <Pivotdiff> > 0.1 va <Pivotdiff2> > 0.1; DnC khi ca hai < -0.1.
long            g_aptBrkAccUpC[14];
long            g_aptBrkAccDnC[14];

// Bo dem UpE/DnE (giay): UpE cong khi <TenMuc> thuoc {PP, R1..R9} VA <brkD> >= 80 VA <brkddiff> > 0.1 VA <bodiff> > 0.1 ; DnE khi <TenMuc> thuoc {PP, S1..S9} VA <brkD> <= 20 VA <brkddiff> < -0.1 VA <bodiff> < -0.1.
// <brkddiff> / <bodiff> = cung gia tri hien tren hang khung cua nhan gia giua (brkD nen hien tai - brkD nen da dong truoc; (Bid-Open)/spread hien tai - gia tri giay truoc), do DrawMidPriceLabel() ghi vao g_aptBrkDDiffV[] / g_aptBoDiffV[] (cung chi so g_tfList).
// Dung chung moc reset g_aptBrkAccBarT[i] va dt voi cac bo dem tren.
long            g_aptBrkAccUpE[14];
long            g_aptBrkAccDnE[14];
double          g_aptBrkDDiffV[14];    // <brkddiff> (so nguyen, double de so sanh voi 0.1); hop le khi g_aptBrkDDiffOk[i]
bool            g_aptBrkDDiffOk[14];
double          g_aptBoDiffV[14];      // <bodiff> (da lam tron M1_ELP_LBL_DIF1_DIGITS chu so); hop le khi g_aptBoDiffOk[i]
bool            g_aptBoDiffOk[14];
double          g_aptBoValV[14];       // <(Bid-Open)/spread> (da lam tron M1_ELP_LBL_DIF1_DIGITS chu so), dung to mau nhan RV1/RV2 (AptRv2RowColor); hop le khi g_aptBoValOk[i]
bool            g_aptBoValOk[14];
double          g_aptDiffAvg2V[14];    // <diffavg2> (da lam tron M1_ELP_LBL_DIF1_DIGITS chu so), dung cho dem Up/Dn; hop le khi g_aptDiffAvg2Ok[i]
bool            g_aptDiffAvg2Ok[14];
double          g_aptBrkDV[14];        // <brkD> (so nguyen, double de so sanh), dung cho dem UpB/DnB; hop le khi g_aptBrkDOk[i]
bool            g_aptBrkDOk[14];
double          g_aptWChgV[56];        // thay doi theo giay cua W% (so nguyen, double de so sanh), dung cho dem UpA/DnA; chi so = khung*4 + truong (0 = dOWW%, 1 = dRV1W%, 2 = dRV2W%, 3 = dPivotW%); AptWChgStr() ghi
bool            g_aptWChgOk[56];       // hop le khi tinh duoc trong lan ve gan nhat cua DrawMidPriceLabel()

// Cache RV1 that (double) cua tung khung g_tfList[i]; DrawBreakStats() ghi moi nhip. Doc boi: dieu kien UpB/DnB, so nen RV1 cat OW (AptOwStr, nhan OW), huong lam tron moc OW (AptRndMarksDraw), diffpv.
double          g_rv1ValCache[14];
// Gia muc Pivot (gia tri EMA cua muc dang ve) theo g_tfList[i]; DrawWoodiePivotEma() ghi. 0.0 = chua co nhan Pivot hop le (tat InpShowWoodiePivotEma, thieu lich su...) -> noi doc ghi "-" hoac bo qua nhip cong don.
double          g_pivotLvlValCache[14];

// <Pivotdiff> = (Pivot ema[0] - ema[1]) / spread cua tung khung g_tfList[i] (ema = duong EMA(InpWoodiePivotEmaPeriod) cua muc Pivot dang chon).
// g_dsEma0/g_dsEma1/g_dsEmaOk: DrawEmaSeries() ghi ema[0]/ema[1] cua lan goi gan nhat, DrawWoodiePivotEma() doc ngay sau lenh goi. g_pivotEmaDiffStr[]: chuoi da dinh dang ("" = chua co).
double          g_dsEma0 = 0.0;
double          g_dsEma1 = 0.0;
bool            g_dsEmaOk = false;
string          g_pivotEmaDiffStr[14];
// <Pivotdiff2> = (ema[0] - ema[1]) / spread cua duong EMA tren muc <TenMuc> (muc gan Bid nhat cua khung, AptWoodieDisplayLvlForTF()), khong phu thuoc muc chon o bang Pivot UI.
// DrawWoodiePivotEma() ghi; DrawBreakStats() va DrawAptPatternColumn() doc. "" = chua co.
string          g_pivotEmaDiff2Str[14];
// g_patCdlStr[] = chuoi <TF>{<DxyTenMuc>} <UpE>/<DnE> <UpB>/<DnB> <Up>/<Dn> ... <FVG><LVN><IMB> do DrawRv2RsiLabels() ghi, DrawAptPatternColumn doc. "" = chua co.
string          g_patCdlStr[14];
// g_patFvgStr[] / g_patLvnStr[] / g_patImbStr[] = 3 truong <FVG> <LVN> <IMB> (da bo ngoac) cua tung khung g_tfList, DrawRv2RsiLabels() ghi cung luc voi g_patCdlStr[]; AptQuickReadStr() doc. "" = rong / chua co.
string          g_patFvgStr[14];
string          g_patLvnStr[14];
string          g_patImbStr[14];

double          g_aptRv2All[14];
bool            g_aptRv2AllOk[14];
// RV2 cua nen lien truoc (shift 1) cua tung khung; AptRv2BuildAll14() ghi cung nhip voi g_aptRv2All[] (shift 0)
//   de so sanh ra do doc RV2 (len/xuong).
ENUM_TIMEFRAMES g_tfList[14] = {PERIOD_M1,PERIOD_M5,PERIOD_M15,PERIOD_M30,
                                 PERIOD_H1,PERIOD_H2,PERIOD_H3,PERIOD_H4,
                                 PERIOD_H6,PERIOD_H8,PERIOD_H12,
                                 PERIOD_D1,PERIOD_W1,PERIOD_MN1};
string          g_tfLabel[14] = {"1m","5m","15m","30m","1h","2h","3h","4h",
                                  "6h","8h","12h","1d","1w","1nm"};

// Chuoi 3 hang cua cum nhan duoi than nen lon: DrawRv2RsiLabels() tinh chuoi + mau, BuildBarCurLblRows() doc de chen hang.
//   Thu tu: [0]=brkD (kem pvD), [1]=TC, [2]=UPDDND. Chuoi rong = hang khong duoc chen.
//   g_bcRowClr[] = mau tung hang cua cum (mac dinh InpBarLblColorCur).
string          g_bcTopTxt[3];
// Moc thoi gian (mep trai, ANCHOR_LEFT) cua khu vuc nhan RV1 khung 1m: DrawRv2RsiLabels() ghi moi lan ve
//   (= _mShiftT, da gom khe ho InpRv1M1GapM1Bars). 0 = chua ve. Nhan lenh gia lap, nhan muc nhoi (DrawOneLine), cot Pattern doc de can cung cot.
datetime        g_rv1M1LblT = 0;
double          g_rv1M1LblPx = 0.0;   // gia (truc gia) cua nhan RV1 1m, DrawRv2RsiLabels() ghi cung luc g_rv1M1LblT; 0 = chua ve. Cot <TF> <(Bid - Open)/spread> cua DrawMidPriceLabel() xep xuong duoi tu day.
int             g_rv1M1LblFs = 0;     // co chu nhan RV1 1m (cot <TF> <...> dung cung co chu va khoang cach hang)
color           g_bcTopClr[3];
color           g_bcRowClr[];

// Trang thai chong spam cua AptCheckSoundAlerts() (bien noi bo, khong phai input/object):
//   g_aptSndTopDayT / g_aptSndBaseDayT = iTime(D1,0) cua ngay da phat Topday.wav / Baseday.wav gan nhat (moi ngay phat 1 lan).
datetime        g_aptSndTopDayT  = 0;
datetime        g_aptSndBaseDayT = 0;
// Tuong tu cho nen tuan (W1) va thang (MN1): moi khung giu iTime(...,0) cua nen da phat am gan nhat (1 lan / nen), cung nguong InpDayEdgeThresholdUSD.
datetime        g_aptSndTopWeekT   = 0;
datetime        g_aptSndBaseWeekT  = 0;
datetime        g_aptSndTopMonthT  = 0;
datetime        g_aptSndBaseMonthT = 0;

// RV2 EMA UI: bang nut chon chu ky EMA ra RV2 (5 / 10 / 20 / 50 / 200), nam ngay duoi bang nut RSI - xem CreateRv2EmaPanel().
//   g_aptRv2EmaPeriod (khoi tao = InpEmaPeriod trong OnInit) la chu ky dang dung de tinh RV2; bam nut thi RV2 doi theo.
#define APT_RV2EMA_COUNT 5
#define APT_RV2EMA_COLS  5
int    g_aptRv2EmaVals[APT_RV2EMA_COUNT] = {5,10,20,50,200};
int    g_aptRv2EmaPeriod = 5;    // chu ky EMA ra RV2 DANG DUNG (khoi tao = InpEmaPeriod trong OnInit)
int    g_aptRv2EmaIdx    = 0;    // chi so nut dang chon trong g_aptRv2EmaVals[], -1 = khong nut nao khop
string g_btnRv2EmaPrefix = "RV2_EMAPEBTN_";

// Hang nut "B<n>" ngay duoi hang nut RV2 EMA: chon so nen n cua kenh brkD (g_aptBrkDBars; khoi tao = InpBrkDBars trong OnInit).
//   Idx = -1: gia tri khoi tao khong khop nut nao. brkD kep 2..500 trong ham tinh.
#define APT_BRKDUI_COUNT 5
int    g_aptBrkDBarsVals[APT_BRKDUI_COUNT] = {5,10,20,50,200};
int    g_aptBrkDBars   = 10;    // so nen kenh brkD DANG DUNG (mac dinh 10; khoi tao = InpBrkDBars trong OnInit)
int    g_aptBrkDBarsIdx = -1;
string g_btnBrkDPrefix    = "RV2_BRKDBTN_";

// Hang nut chon KHUNG THOI GIAN (toan bo g_tfList[0..13], 3 hang x APT_RV2EMA_COLS=5 cot) ngay duoi hang "B<n>":
//   hang 1: 1m 5m 15m 30m 1h | hang 2: 2h 3h 4h 6h 8h | hang 3: 12h 1d 1w 1nm.
//   Khung duoc chon quyet dinh: nhan HH/LL cua kenh brkD (DrawBrkDHHLL) va khung ve duong RV1/RV2/Pivot/OW (AptExtraLineTf).
//   Bam lai nut dang sang -> tat (idx = -1).
#define APT_BRKDTF_COUNT 14
int    g_aptBrkDTfIdx = 0;                       // 0 = 1m (mac dinh), -1 = tat
string g_btnBrkDTfPrefix = "RV2_BRKDTFBTN_";

// OW MODE UI: 3 nut chon CACH TINH OW (nhan OW<khung>, duong OW, moc lam tron <khung>OW, [<diffpv3>], <RV1OW>, so nen Pivot cat OW), dat NGAY TREN bang check box khung
//   (CreateRowTfPanel()) - xem CreateOwModePanel(). n = g_aptBrkDBars (nut B<n>) dung chung cho ca 3 che do; tinh tren nen DA DONG (shift >= 1).
//     APT_OW_MODE_LWMA     : OW = LWMA(Open, n)            (trong so n..1, nen moi nhat trong so n)
//     APT_OW_MODE_EMA      : OW = EMA(Open, n)             (mac dinh - giu dung hanh vi hien tai)
//     APT_OW_MODE_EMA_LWMA : OW = EMA(LWMA(Open, n), n)    (lam muot 2 lan, cung chu ky n)
#define APT_OW_MODE_LWMA     0
#define APT_OW_MODE_EMA      1
#define APT_OW_MODE_EMA_LWMA 2
#define APT_OW_MODE_COUNT    3
int    g_aptOwMode       = APT_OW_MODE_EMA;
string g_btnOwModePrefix = "RV2_OWMODEBTN_";
string g_aptOwModeLbl[APT_OW_MODE_COUNT] = {"LWMA", "EMA", "EMA(LWMA)"};

// Khoa cache cua cac gia tri OW: gop n (nut B<n>) va che do OW, de doi che do o OW MODE UI thi moi cache OW tinh lai.
int AptOwModeKey(const int n)
{
   return n + 1000 * g_aptOwMode;
}

// Khung ve duong RV1/RV2/Pivot/OW lay tu nut chon khung o tren (g_aptBrkDTfIdx). Tra false khi dang tat (idx = -1).
bool AptExtraLineTf(ENUM_TIMEFRAMES &outTf)
  {
   outTf = PERIOD_CURRENT;
   if(g_aptBrkDTfIdx < 0 || g_aptBrkDTfIdx >= APT_BRKDTF_COUNT)
      return(false);
   outTf = g_tfList[g_aptBrkDTfIdx];
   return(true);
  }

// Close Simple UI: bang nut chon period duong Close Simple (SMA gia dong cua) 5 / 10 / 20 / 50 / 200 (mac dinh 200), ngay duoi RV2 EMA UI.
//   Nhan Close Simple cua moi khung ve tai gia SMA(Close, period) cua chinh khung do, lech InpCsmaFutureBars nen ve phia tuong lai - xem DrawCloseSimpleLabels().
#define APT_CSMA_COUNT       5
#define APT_CSMA_COLS        5
int    g_aptCsmaVals[APT_CSMA_COUNT] = {5,10,20,50,200};
int    g_aptCsmaPeriod = 200;   // period Close Simple DANG DUNG
int    g_aptCsmaIdx    = 4;     // chi so nut dang chon trong g_aptCsmaVals[] (4 = 200)
string g_btnCsmaPrefix = "CSMA_BTN_";
string g_csmaLblPrefix = "CSMA_LBL_";

// LAM TRON UI: 3 nut chon muc lam tron (hang ngan / tram / chuc) + o nhap PHAM VI tim kiem, ngay duoi Close Simple UI.
//   Nhan Pivot: <TF> <lamtron> <TenMuc> ... voi <TenMuc> = R1..R9 hoac S1..S9 cua khung do, P = gia muc <TenMuc>, B = buoc lam tron (1000/100/10; nut "x5" = cac gia tri co hang don vi la 5: 4195, 4205...), W = pham vi:
//     R1..R9: lamtron = boi so nho nhat cua B thoa lamtron >= P  va  lamtron - P <= W   (vd P=4187.4, B=100, W=20 -> 4200)
//     S1..S9: lamtron = boi so lon nhat cua B thoa lamtron <  P  va  P - lamtron <= W   (vd P=4162.0, B=10,  W=20 -> 4160)
//   Khong thoa / <TenMuc> khac -> rong (khong in gi). In so nguyen. Xem AptRoundNearStr().
//   Nut thu 4 "x5" = cac gia tri co hang don vi la 5 (4195, 4205, 4215...): buoc 10, lech 5 (g_aptRndOff[3] = 5), cach tinh R / S nhu cac nut con lai.
int    g_aptRndVals[4]   = {1000, 100, 10, 10};
int    g_aptRndOff [4]   = {0, 0, 0, 5};          // do lech cua boi so: lamtron = n * buoc + do lech (nut x5 = 5, cac nut con lai = 0)
string g_aptRndLbl [4]   = {"1000", "100", "10", "x5"};   // chu tren nut
int    g_aptRndIdx       = 2;           // chi so nut dang chon (mac dinh 10)
double g_aptRndRange     = 50.0;        // pham vi tim kiem (mac dinh 50, doi bang o nhap)
string g_aptRndRangeTxt  = "50";        // chuoi o nhap (de ve lai dung nhu nguoi dung go)
string g_btnRndPrefix    = "RND_BTN_";  // nut muc lam tron: ten doi tuong = prefix + chi so 0..3
string g_edtRndPrefix    = "RND_EDT_";  // o nhap pham vi : ten doi tuong = prefix + "VAL"
// Nut "KC" (khoang cach) sau nut x5: BAT -> nhan LAM TRON chi ve cac muc LE cua buoc dang chon, bo cac muc CHAN xen giua.
//   Muc thu n = n * buoc + do lech (cung cong thuc AptRoundNearStr()); giu khi n LE. vd buoc 10: giu 4170, 4190, bo 4180; nut x5: giu 4175, 4195, bo 4185.
//   Loc ap dung cho nhan mau trang tren thang gia (AptRndMarksDraw()) va moi thu dung bo nhan do (alert gan moc, to mau nen 1m, <pls>).
bool   g_aptRndGap       = false;       // trang thai nut "KC"
string g_btnRndGapName   = "RND_GAPBTN";   // ten nut "KC" (khong trung prefix g_btnRndPrefix de khoi lan voi 4 nut muc lam tron)

bool AptRndGapKeep(const double v)
{
   if(!g_aptRndGap)
      return true;
   int    ridx = (g_aptRndIdx < 0 || g_aptRndIdx > 3) ? 1 : g_aptRndIdx;
   double step = (double)g_aptRndVals[ridx];
   double off  = (double)g_aptRndOff[ridx];
   if(step <= 0.0)
      return true;
   long n = (long)MathRound((v - off) / step);
   return ((n % 2) != 0);
}

// Moc LAM TRON BEN NGOAI dinh / day theo luoi cua nut dang chon (n * buoc + do lech, cung luoi voi R / S va nhan trang):
//   dinh -> moc nho nhat >= dinh (ra ngoai phia tren) ; day -> moc lon nhat <= day (ra ngoai phia duoi). vd nut 10: dinh 4192 -> 4200, day 4111.13 -> 4110;
//   nut x5: day 4111.13 -> 4105. Dinh / day nam dung tren moc thi giu nguyen moc do. Dung cho moc cao / thap tuan-thang-qui-nam (AptPeriodExtremeFromRates()).
double AptRndOutsideHigh(const double v)
{
   int    ridx = (g_aptRndIdx < 0 || g_aptRndIdx > 3) ? 1 : g_aptRndIdx;
   double step = (double)g_aptRndVals[ridx];
   double off  = (double)g_aptRndOff[ridx];
   if(step <= 0.0)
      return v;
   return MathCeil((v - off) / step - 1e-9) * step + off;
}

double AptRndOutsideLow(const double v)
{
   int    ridx = (g_aptRndIdx < 0 || g_aptRndIdx > 3) ? 1 : g_aptRndIdx;
   double step = (double)g_aptRndVals[ridx];
   double off  = (double)g_aptRndOff[ridx];
   if(step <= 0.0)
      return v;
   return MathFloor((v - off) / step + 1e-9) * step + off;
}

// Muc `v` co DANG BI nut "KC" AN khong? = KC bat VA `v` nam dung tren luoi lam tron dang chon (n * buoc + do lech) VA n CHAN.
//   Muc khong nam tren luoi (vd moc cao/thap tuan-thang-qui-nam x5 khi dang chon nut x10) khong co nhan trang nao de an -> false.
//   Dung cho alert cua moc cao/thap tuan-thang-qui-nam (AptPeriodExtremeAlertCheck()): nhan trang bi KC an thi khong am thanh / push.
bool AptRndGapHides(const double v)
{
   if(!g_aptRndGap)
      return false;
   int    ridx = (g_aptRndIdx < 0 || g_aptRndIdx > 3) ? 1 : g_aptRndIdx;
   double step = (double)g_aptRndVals[ridx];
   double off  = (double)g_aptRndOff[ridx];
   if(step <= 0.0)
      return false;
   double q = (v - off) / step;
   if(MathAbs(q - MathRound(q)) * step > _Point * 0.5)
      return false;
   return !AptRndGapKeep(v);
}
double g_aptWdLastVal    = 0.0;         // gia (EMA) cua muc <TenMuc> do AptWoodieDisplayLvlForTF() tra ve lan goi gan nhat (chi hop le ngay sau khi ham do tra true)

// DXY: symbol dung de lay <TenMuc> tham chieu (muc Woodie gan gia DXY nhat cua tung khung), hien trong cot Pattern ngay sau <TF> (xem AptDxyLvlTag()).
//   InpDxySymbol = gia tri khoi tao; doi luc chay bang o nhap DXY (CreateDxyPanel(), object g_edtDxyPrefix + "SYM", ngay duoi o nhap pham vi LAM TRON).
//   Ten symbol phai dung nhu trong Market Watch cua broker (vd "DXY", "USDX", "DX.f"...).
input group             "=== 15. DXY (TenMuc tham chieu tren cot Pattern) ==="
input string            InpDxySymbol      = "DXY";   // Symbol DXY (ten dung nhu Market Watch)

input group             "=== 16. COT NHAN TenMuc TREN DINH NEN 1M (lich su) ==="
input bool              InpLvlColShow     = true;   // Bat/tat cot nhan <TenMuc> cac khung tren dinh nen 1m
input int               InpLvlColBars     = 5;      // So nen 1m gan nen hien tai nhat co cot nhan (tinh ca nen dang chay; 1..100)
input int               InpLvlColAbovePts = 100;    // Day cot nhan cao hon dinh nen 1m (point)

input group             "=== 17. ALERT GIA GAN MOC LAM TRON ==="
input bool              InpRndAlertOn     = true;        // Bat/tat alert khi OW khung 1m den gan nhan moc lam tron (nhan mau trang tren thang gia)
input double            InpRndAlertDist   = 2.0;         // Khoang cach (gia) +/- quanh moc lam tron de bao (|OW 1m - moc| <= gia tri nay)
input int               InpRndAlertRepeatSec = 10;       // Am thanh: phat lap lai cach nhau bao nhieu GIAY khi Bid con trong vung (toi thieu 1)
input string            InpRndAlertSound  = "alert.wav"; // Am thanh: file (trong MQL5\Sounds; de trong = khong phat)
input bool              InpRndAlertPush   = true;        // Push notification sang app MT5 dien thoai: bao 1 lan moi khi OW 1m VAO vung cua 1 moc (log Experts luon ghi)

// ALERT RIENG CHO CAO NHAT / THAP NHAT CUA TUAN, THANG, QUI, NAM (gia lam tron ra ben ngoai dinh / day theo nut LAM TRON, xem AptPeriodExtremeStr()): Bid VAO vung cua moc thi phat AM THANH RIENG cua moc do + gui PUSH sang app MT5 tren dien thoai.
//   Moc CAO : Bid >= moc - InpPexAlertDist (gom ca khi Bid da vuot len tren moc) | Moc THAP: Bid <= moc + InpPexAlertDist.
//   PUSH dung SendNotification(): can bat Tools > Options > Notifications > "Enable Push Notifications" va dien MetaQuotes ID cua app MT5 tren dien thoai (Cai dat > Tin nhan). Toi da 255 ky tu / thong bao, MT5 gioi han ~10 thong bao / phut.
input group             "=== 18. ALERT CAO / THAP TUAN - THANG - QUI - NAM ==="
input bool              InpPexAlertOn        = true;          // Bat/tat alert cao/thap tuan, thang, qui, nam
input double            InpPexAlertDist      = 5.0;           // Khoang cach (gia) tu moc de bao (moc cao: Bid >= moc - X ; moc thap: Bid <= moc + X)
input int               InpPexAlertRepeatSec = 0;             // Am thanh: lap lai moi X giay khi Bid con trong vung (0 = chi phat 1 lan moi khi Bid VAO vung)
input string            InpPexSndWeekHigh    = "alert.wav";   // Am thanh: TUAN cao (file trong MQL5\Sounds; de trong = khong phat)
input string            InpPexSndWeekLow     = "alert2.wav";  // Am thanh: TUAN thap
input string            InpPexSndMonthHigh   = "news.wav";    // Am thanh: THANG cao
input string            InpPexSndMonthLow    = "ok.wav";      // Am thanh: THANG thap
input string            InpPexSndQuarterHigh = "request.wav"; // Am thanh: QUI cao
input string            InpPexSndQuarterLow  = "stops.wav";   // Am thanh: QUI thap
input string            InpPexSndYearHigh    = "timeout.wav"; // Am thanh: NAM cao (dung chung 2 / 3 / 4 / 5 nam)
input string            InpPexSndYearLow     = "wait.wav";    // Am thanh: NAM thap (dung chung 2 / 3 / 4 / 5 nam)
input bool              InpPexPushOn         = true;          // Gui push sang app MT5 tren dien thoai khi Bid vao vung moc (can bat Notifications trong Tools > Options)
input int               InpPexPushMinSec     = 60;            // Push: khoang cach toi thieu (giay) giua 2 thong bao cung 1 moc (chong spam; MT5 gioi han ~10 thong bao / phut)

// NHAN GIA GIUA (Bid + Ask)/2: 1 nhan OBJ_TEXT mau magenta, ghi gia giua lam tron 1 so thap phan, dat tai gia giua, cach nen M1 hien tai InpMidLblFutureM1Bars nen M1 ve TUONG LAI. Xem DrawMidPriceLabel().
input group             "=== 19. NHAN GIA GIUA (Bid + Ask)/2 ==="
input int               InpMidLblFutureM1Bars = 44;           // Nhan gia giua: cach nen M1 hien tai bao nhieu nen M1 ve tuong lai
input int               InpMidLblFontSize     = 11;           // Nhan gia giua: co chu
string g_dxySym          = "DXY";       // symbol DXY DANG DUNG (khoi tao = InpDxySymbol trong OnInit, doi bang o nhap)
string g_edtDxyPrefix    = "DXY_EDT_";  // o nhap symbol DXY : ten doi tuong = prefix + "SYM"

// Danh dau cac muc lam tron len thang gia (mep phai chart): nhan MAU TRANG = ten khung + the gia (OBJ_ARROW_RIGHT_PRICE). Xem AptRndMarksDraw().
//   g_aptRndPx[i] (i = chi so g_tfList) = <lamtron> cua muc R/S khung do, 0 = khong co.
//   g_aptRndHPx[i] = <lamtron> cua HH kenh brkD (cac khung tu 5m), theo cach tinh R -> nhan "<khung>H", vd "1hH".
//   g_aptRndLPx[i] = <lamtron> cua LL kenh brkD, theo cach tinh S -> nhan "<khung>L", vd "4hL".
//   HH / LL = High cao nhat / Low thap nhat cua g_aptBrkDBars nen DA DONG gan nhat (shift 1..N, kep 2..500) - cung kenh voi DrawBrkDHHLL() / AptBrkDAt().
//   Khung trung gia (giua cac loai moc) gop thanh 1 nhan ("1h 4hH"). So cap object RND_MK_A / RND_MK_T = 14 khung x 4 loai moc = 56.
double g_aptRndPx[14];
double g_aptRndHPx[14];   // <lamtron> tu HH cua kenh brkD (cach tinh nhu R), 0 = khong co
double g_aptRndLPx[14];   // <lamtron> tu LL cua kenh brkD (cach tinh nhu S), 0 = khong co
// g_aptRndOwPx[i] = <lamtron> cua muc OW (EMA(Open) chu ky n = g_aptBrkDBars, AptOpenLwma()) cua cac khung tu 5m tro len -> nhan "<khung>OW", vd "1hOW".
//   Cach tinh theo RV1 cua chinh khung do (g_rv1ValCache[i]): RV1 >= OW -> lam tron LEN (cach tinh R); RV1 < OW -> lam tron XUONG (cach tinh S).
//   Chua co RV1 cua khung (<= 0) -> khong co moc. B, W, mau, font giong cac moc khac; khong thoa -> 0 (khong ve).
double g_aptRndOwPx[14];
string g_rndMkPrefix = "RND_MK_";

string AptRoundNearStr(const string tenMuc, const double lvlPx);   // khai bao truoc: than ham nam o duoi
bool   AptOpenLwma(const ENUM_TIMEFRAMES tf, const int n, double &outLwma);   // khai bao truoc: than ham nam o duoi

// So nen M1 DA DONG toi da quet lui de tim luc gia cat qua moc lam tron (2880 nen = 2 ngay).
#define APT_RND_CROSS_M1_BARS 2880

// Thoi gian (PHUT, so thuc) tu luc gia CAT QUA moc lam tron `lvl` lan gan nhat den gio.
//   Gia hien tai (bid) dang o phia nao cua moc -> quet lui nen M1 tim nen GAN NHAT nam o phia nguoc lai:
//     bid >= lvl -> nen co Low  < lvl | bid < lvl -> nen co High >= lvl.
//   Thoi diem cat = gio dong cua nen do (open + 60s) -> phut = (TimeCurrent - thoi diem cat) / 60, khong am.
//   Nen M1 dang chay (shift 0) o phia nguoc lai -> 0.00. Khong tim thay trong APT_RND_CROSS_M1_BARS nen -> false.
bool AptRndCrossMinutes(const double lvl, const double bid, double &outMin)
{
   static MqlRates s_m1[];
   static datetime s_m1T = 0;
   static int      s_m1N = 0;
   outMin = 0.0;
   if(lvl <= 0.0 || bid <= 0.0)
      return false;
   datetime t0 = iTime(_Symbol, PERIOD_M1, 0);
   if(t0 <= 0)
      return false;
   if(s_m1T != t0)   // chi doc lai nen M1 da dong khi sang nen M1 moi
   {
      ArraySetAsSeries(s_m1, true);
      int got = CopyRates(_Symbol, PERIOD_M1, 1, APT_RND_CROSS_M1_BARS, s_m1);
      if(got <= 0)
      {
         s_m1N = 0;
         return false;
      }
      s_m1N = got;
      s_m1T = t0;
   }
   bool   above = (bid >= lvl);
   double nowT  = (double)TimeCurrent();
   // nen M1 dang chay (shift 0): da o phia nguoc lai trong phut nay -> vua cat xong
   double lo0 = iLow (_Symbol, PERIOD_M1, 0);
   double hi0 = iHigh(_Symbol, PERIOD_M1, 0);
   if(lo0 > 0.0 && hi0 > 0.0 && (above ? (lo0 < lvl) : (hi0 >= lvl)))
      return true;
   for(int b = 0; b < s_m1N; b++)
   {
      bool opp = above ? (s_m1[b].low < lvl) : (s_m1[b].high >= lvl);
      if(!opp)
         continue;
      double m = (nowT - ((double)s_m1[b].time + 60.0)) / 60.0;
      outMin = (m > 0.0) ? m : 0.0;
      return true;
   }
   return false;
}

// So nen M1 DA DONG toi da quet lui de do chuoi nen nam trong vung alarm (APT_RND_REACT_M1_BARS nen).
#define APT_RND_REACT_M1_BARS 500

// TI LE PHAN UNG cua gia voi moc lam tron `lvl` = Batlai / (Batlai + Xuyen), trong [0, 1].
//   N KHONG co dinh: N = so nen M1 LIEN TIEP (tinh tu nen dang chay lui ve truoc) co khoang High-Low cham vung alarm [lvl - dist, lvl + dist]
//   (cung vung |Bid - moc| <= InpRndAlertDist cua AptRndAlertCheck()). Nen dang chay luon tinh vao chuoi vi Bid dang nam trong vung.
//   Phia tiep can: Close cua nen ngay truoc chuoi (nen do khong cham vung nen nam han mot phia) >= lvl -> gia di xuong tu tren (fromAbove), nguoc lai di len tu duoi.
//   Xuyen  : fromAbove -> max(0, lvl - LowThapNhat cua N nen) | fromBelow -> max(0, HighCaoNhat cua N nen - lvl).
//   Bat lai: tinh TU nen co diem sau nhat (nen day / dinh) tro ve nay: fromAbove -> max(0, max(Close nen sau nhat, High cac nen moi hon) - lvl) | fromBelow doi xung.
//            (nen sau nhat dung Close vi trong nen do khong biet High hay Low xay ra truoc; Close nen dang chay = Bid.)
//   Batlai + Xuyen = 0 (gia dung dung tai moc, chua di dau) -> false (nhan hien "-"). ATR khong can vi bi triet tieu khi chia.
bool AptRndReactRatio(const double lvl, const double dist, const double bid, double &outRatio, int &outN)
{
   static MqlRates s_rr[];
   static datetime s_rrT = 0;
   static int      s_rrN = 0;
   outRatio = 0.0;
   outN     = 0;
   if(lvl <= 0.0 || bid <= 0.0)
      return false;
   datetime t0 = iTime(_Symbol, PERIOD_M1, 0);
   if(t0 <= 0)
      return false;
   if(s_rrT != t0)   // chi doc lai nen M1 da dong khi sang nen M1 moi
   {
      ArraySetAsSeries(s_rr, true);
      int got = CopyRates(_Symbol, PERIOD_M1, 1, APT_RND_REACT_M1_BARS, s_rr);
      if(got <= 0)
      {
         s_rrN = 0;
         return false;
      }
      s_rrN = got;
      s_rrT = t0;
   }
   double tol = _Point * 0.5;
   double hiZ = lvl + dist + tol;
   double loZ = lvl - dist - tol;
   double hi0 = iHigh(_Symbol, PERIOD_M1, 0);
   double lo0 = iLow (_Symbol, PERIOD_M1, 0);
   if(hi0 <= 0.0 || lo0 <= 0.0)
      return false;
   // nen shift 0 = nen dang chay (Close = Bid); nen shift s >= 1 = s_rr[s - 1]
   int n = 1;
   while(n - 1 < s_rrN && s_rr[n - 1].low <= hiZ && s_rr[n - 1].high >= loZ)
      n++;
   outN = n;

   double ref;   // gia tham chieu de biet gia tiep can moc tu phia nao
   if(n - 1 < s_rrN)
      ref = s_rr[n - 1].close;                                  // nen ngay truoc chuoi (khong cham vung)
   else
      ref = (n - 1 == 0) ? iOpen(_Symbol, PERIOD_M1, 0) : s_rr[n - 2].open;   // het du lieu -> Open nen cu nhat trong chuoi
   bool fromAbove = (ref >= lvl);

   // diem sau nhat: fromAbove -> Low thap nhat | fromBelow -> High cao nhat. Quet tu nen MOI -> cu, chi doi khi cuc tri HON han -> hoa nhau giu nen moi hon.
   int    jd  = 0;
   double ext = fromAbove ? lo0 : hi0;
   for(int s = 1; s <= n - 1; s++)
   {
      double e = fromAbove ? s_rr[s - 1].low : s_rr[s - 1].high;
      if(fromAbove ? (e < ext - 1e-9) : (e > ext + 1e-9))
      {
         ext = e;
         jd  = s;
      }
   }

   double pen = fromAbove ? (lvl - ext) : (ext - lvl);
   if(pen < 0.0)
      pen = 0.0;

   double cd   = (jd == 0) ? bid : s_rr[jd - 1].close;
   double back = fromAbove ? (cd - lvl) : (lvl - cd);
   for(int s = 0; s < jd; s++)
   {
      double e = (s == 0) ? (fromAbove ? hi0 : lo0) : (fromAbove ? s_rr[s - 1].high : s_rr[s - 1].low);
      double b = fromAbove ? (e - lvl) : (lvl - e);
      if(b > back)
         back = b;
   }
   if(back < 0.0)
      back = 0.0;

   double den = back + pen;
   if(den <= 1e-9)
      return false;
   outRatio = back / den;
   return true;
}

// So nen gan nhat (tinh ca nen dang chay, shift 0..N-1) cua moi khung dung de dem dinh/day nam gon trong vung alarm cua moc lam tron.
#define APT_RND_HL_BARS 10

// DINH / DAY NEN NAM GON TRONG VUNG ALARM cua moc lam tron `lvl`: vung = [lvl - dist, lvl + dist] (cung vung |Bid - moc| <= InpRndAlertDist cua AptRndAlertCheck()).
//   Voi moi khung trong g_tfList[] (1m..1nm), xet APT_RND_HL_BARS nen gan nhat (shift 0..N-1, gom nen dang chay):
//     <so dinh> = so nen co High nam trong vung, <so day> = so nen co Low nam trong vung.
//   Tra chuoi "<khung><so dinh>/<so day>" cua cac khung co tong > 0, cach nhau 1 dau cach, theo thu tu 1m -> 1nm, vd "5m1/3 1h0/1".
//   Khung thieu du lieu (CopyHigh / CopyLow loi) -> bo qua khung do, khong doan. Khong khung nao co dinh/day trong vung -> "". Chi doc gia, khong tao object.
string AptRndHLCountStr(const double lvl, const double dist)
{
   if(lvl <= 0.0)
      return "";
   double tol = _Point * 0.5;
   double loZ = lvl - dist - tol;
   double hiZ = lvl + dist + tol;
   string res = "";
   for(int i = 0; i < 14; i++)
   {
      double hb[], lb[];
      ArraySetAsSeries(hb, true);
      ArraySetAsSeries(lb, true);
      int gH = CopyHigh(_Symbol, g_tfList[i], 0, APT_RND_HL_BARS, hb);
      int gL = CopyLow (_Symbol, g_tfList[i], 0, APT_RND_HL_BARS, lb);
      int g  = MathMin(gH, gL);
      if(g <= 0)
         continue;
      int nH = 0, nL = 0;
      for(int s = 0; s < g; s++)
      {
         if(hb[s] > 0.0 && hb[s] >= loZ && hb[s] <= hiZ)
            nH++;
         if(lb[s] > 0.0 && lb[s] >= loZ && lb[s] <= hiZ)
            nL++;
      }
      if(nH + nL <= 0)
         continue;
      res += ((res != "") ? " " : "") + g_tfLabel[i] + IntegerToString(nH) + "/" + IntegerToString(nL);
   }
   return res;
}

// OWTRON cua cac khung 1m, 5m, 15m, 30m (g_tfList[0..3]) so voi nhan lam tron co gia `lvl`: <Owtron> = (OW cua khung - lvl)/spread, 1 so le.
//   OW = EMA(Open) chu ky n = g_aptBrkDBars (AptOpenLwma(), cung nguon <diffpv3> / <Owtron> tren nhan Pivot, n kep 2..500).
//   Tra chuoi "<khung><Owtron>" cach nhau 1 dau cach, theo thu tu 1m -> 30m, vd "1m-1.5 5m2.3 15m0.4 30m-3.1".
//   Khung thieu OW -> bo qua khung do (khong doan). Thieu spread / lvl <= 0 / khong khung nao tinh duoc -> "". Chi doc gia, khong tao object.
#define APT_RND_OWTRON_TF_N   4   // so khung dau cua g_tfList (1m, 5m, 15m, 30m)
#define APT_RND_OWTRON_DIGITS 1   // so le (= M1_ELP_LBL_DIF1_DIGITS; hang do khai bao sau ham nay)
string AptRndOwTronStr(const double lvl)
{
   double spread = (double)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * _Point;
   if(lvl <= 0.0 || spread <= 0.0)
      return "";
   int nOw = g_aptBrkDBars;
   if(nOw < 2)   nOw = 2;
   if(nOw > 500) nOw = 500;
   string res = "";
   for(int i = 0; i < APT_RND_OWTRON_TF_N; i++)
   {
      double ow = 0.0;
      if(!AptOpenLwma(g_tfList[i], nOw, ow) || !(ow > 0.0))
         continue;
      res += ((res != "") ? " " : "") + g_tfLabel[i] + DoubleToString((ow - lvl) / spread, APT_RND_OWTRON_DIGITS);
   }
   return res;
}

// Dinh dang ti le [0, 1]: toi da 2 so thap phan, bo so 0 thua cuoi ("1", "0.5", "0.67", "0").
string AptRatioStr(const double r)
{
   string t = DoubleToString(r, 2);
   if(StringFind(t, ".") >= 0)
   {
      int len = StringLen(t);
      while(len > 0 && StringGetCharacter(t, len - 1) == '0')
         len--;
      if(len > 0 && StringGetCharacter(t, len - 1) == '.')
         len--;
      t = StringSubstr(t, 0, len);
   }
   return t;
}

// ALERT GIA GAN MOC LAM TRON: OW KHUNG 1m (AptOpenLwma(PERIOD_M1, n = g_aptBrkDBars), cach tinh theo OW MODE UI) o trong vung |OW 1m - moc| <= InpRndAlertDist
//   cua BAT KY moc nao (nhan mau trang do AptRndMarksDraw() dung) thi (truoc day dieu kien la |Bid - moc| <= InpRndAlertDist; OW 1m doi theo nen 1m DA DONG nen
//   alert chu yeu phat luc sang nen 1m moi hoac khi bo moc doi; khong tinh duoc OW 1m -> khong xet, giu nguyen trang thai):
//   - AM THANH (InpRndAlertSound): phat lap lai MOI InpRndAlertRepeatSec GIAY chung nao Bid con trong vung. Khoang cach toi thieu giua 2 lan phat tinh tu
//     lan phat truoc (g_rndAlLastSnd), ke ca khi Bid ra roi vao lai vung nhanh -> khong bao gio phat day hon InpRndAlertRepeatSec giay / lan.
//   - LOG Experts / PUSH: chi bao 1 LAN moi khi OW 1m VAO vung cua 1 moc (g_rndAlHot[] = cac moc DANG trong vung); roi vung roi vao lai thi bao tiep.
//     Nhieu moc cung vao vung trong 1 nhip -> gop thanh 1 thong bao.
//   OW 1m dang o trong vung ngay khi nap EA / doi khung -> bao (khong con bo qua lan dau).
double   g_rndAlHot[];
datetime g_rndAlLastSnd = 0;

void AptRndAlertNotify(const string msg)
{
   string full = _Symbol + " | MOC LAM TRON: " + msg;
   Print("[APT] ", full);
   if(InpRndAlertPush)
   {
      // Push toi da 255 ky tu / thong bao (gioi han cua MT5); noi dung: "<symbol> | MOC LAM TRON: OW1m <gia> gan moc <gia moc> [<ten khung>...] <OW1m - moc> | ..."
      if(StringLen(full) > 255)
         full = StringSubstr(full, 0, 255);
      if(!SendNotification(full))
         Print("[APT] SendNotification loi ", GetLastError(), " - bat Tools > Options > Notifications va dien MetaQuotes ID cua app MT5 tren dien thoai");
   }
}

void AptRndAlertCheck(const double &px[], const string &nm[], const int n)
{
   if(!InpRndAlertOn || n <= 0)
   {
      if(ArraySize(g_rndAlHot) > 0)
         ArrayResize(g_rndAlHot, 0);
      return;
   }
   // Gia tham chieu = OW khung 1m (khong con la Bid): cung cach tinh voi <Owtron> (AptOpenLwma(), n = g_aptBrkDBars kep 2..500).
   int nOw = g_aptBrkDBars;
   if(nOw < 2)   nOw = 2;
   if(nOw > 500) nOw = 500;
   double bid = 0.0;   // (giu ten bien) = OW 1m
   if(!AptOpenLwma(PERIOD_M1, nOw, bid) || bid <= 0.0)
      return;

   double dist = (InpRndAlertDist < 0.0) ? 0.0 : InpRndAlertDist;
   double tol  = _Point * 0.5;

   double newHot[];
   ArrayResize(newHot, 0);
   string msg  = "";
   int    nNew = 0;
   for(int k = 0; k < n; k++)
   {
      if(MathAbs(bid - px[k]) > dist)
         continue;
      int h = ArraySize(newHot);
      ArrayResize(newHot, h + 1);
      newHot[h] = px[k];

      bool wasHot = false;
      for(int j = 0; j < ArraySize(g_rndAlHot); j++)
         if(MathAbs(g_rndAlHot[j] - px[k]) <= tol)
         {
            wasHot = true;
            break;
         }
      if(wasHot)
         continue;

      string lb = nm[k];
      StringTrimLeft(lb);
      msg += (nNew > 0 ? " | " : "") + DoubleToString(px[k], _Digits) + " [" + lb + "] " + StringFormat("%+.2f", bid - px[k]);
      nNew++;
   }

   int nIn = ArraySize(newHot);
   ArrayResize(g_rndAlHot, nIn);
   for(int c = 0; c < nIn; c++)
      g_rndAlHot[c] = newHot[c];

   if(nNew > 0)
      AptRndAlertNotify("OW1m " + DoubleToString(bid, _Digits) + " gan moc " + msg);

   // am thanh: con trong vung cua it nhat 1 moc -> lap lai moi InpRndAlertRepeatSec giay
   if(nIn > 0 && StringLen(InpRndAlertSound) > 0)
   {
      int      gap = (InpRndAlertRepeatSec < 1) ? 1 : InpRndAlertRepeatSec;
      datetime now = TimeLocal();
      if(g_rndAlLastSnd == 0 || (long)(now - g_rndAlLastSnd) >= (long)gap)
      {
         PlaySound(InpRndAlertSound);
         g_rndAlLastSnd = now;
      }
   }
}

// TO MAU NEN 1M CHAM / XUYEN QUA NHAN LAM TRON (nhan mau trang do AptRndMarksDraw() ve). Dung plot DRAW_COLOR_BARS (to nen kieu BAR CHART OHLC; 5 buffer: O, H, L, C, mau - cung bo buffer voi DRAW_COLOR_CANDLES, khong doi code ghi) de
//   phu mau len dung nen cua chart - KHONG tao them object / duong nao. Chi chay khi chart dang la khung M1 (nen chart = nen 1m); khung khac -> khong to.
//   Moc xet = TOAN BO gia nhan lam tron dang hien tren chart (g_aptRndLvl[0..g_aptRndLvlN-1], AptRndMarksDraw() cap nhat moi lan ve nhan).
//   MAU VANG : nen cham hoac xuyen qua moc roi bi bat LEN tren moc   -> Low  <= moc VA Close > moc.
//   MAU TRANG: nen cham hoac xuyen qua moc roi bi bat XUONG duoi moc -> High >= moc VA Close < moc.
//   Nen thoa ca hai (cat nhieu moc) -> lay moc gan Close nhat (bang nhau -> vang). Nen khong thoa -> khong ve (giu nguyen mau nen cua chart).
//   Quet toi da APT_RND_CNDL_BARS nen M1 gan nhat. Nen da dong chi tinh lai khi bo moc doi / co nen moi; nen dang chay tinh lai moi lan goi.
#define APT_RND_CNDL_BARS 5000
double g_aptRndLvl[56];       // gia cac nhan lam tron dang hien (cung px[] cua AptRndMarksDraw())
int    g_aptRndLvlN = 0;      // so moc hop le trong g_aptRndLvl[]
double g_rcO[];               // buffer 0: Open  nen duoc to mau (EMPTY_VALUE = khong to)
double g_rcH[];               // buffer 1: High
double g_rcL[];               // buffer 2: Low
double g_rcC[];               // buffer 3: Close
double g_rcClr[];             // buffer 4: chi so mau (0 = vang, 1 = trang)

// 1 = vang (bat len tren moc), -1 = trang (bat xuong duoi moc), 0 = khong thoa moc nao
int AptRndCandleDir(const double hi, const double lo, const double cl)
{
   double tol    = _Point * 0.5;
   double bestUp = DBL_MAX;   // Close - moc nho nhat trong cac moc bi bat len
   double bestDn = DBL_MAX;   // moc - Close nho nhat trong cac moc bi bat xuong
   for(int k = 0; k < g_aptRndLvlN; k++)
   {
      double lv = g_aptRndLvl[k];
      if(lv <= 0.0)
         continue;
      if(lo <= lv + tol && cl > lv + tol)
      {
         if(cl - lv < bestUp)
            bestUp = cl - lv;
      }
      else if(hi >= lv - tol && cl < lv - tol)
      {
         if(lv - cl < bestDn)
            bestDn = lv - cl;
      }
   }
   if(bestUp == DBL_MAX && bestDn == DBL_MAX)
      return 0;
   return (bestUp <= bestDn) ? 1 : -1;
}

// Ghi 1 nen (shift s) vao buffer: thoa -> O/H/L/C that + chi so mau; khong thoa -> EMPTY_VALUE (khong ve).
void AptRndCandleSet(const int s, const MqlRates &r)
{
   int d = AptRndCandleDir(r.high, r.low, r.close);
   if(d == 0)
   {
      g_rcO[s]   = EMPTY_VALUE;
      g_rcH[s]   = EMPTY_VALUE;
      g_rcL[s]   = EMPTY_VALUE;
      g_rcC[s]   = EMPTY_VALUE;
      g_rcClr[s] = 0.0;
      return;
   }
   g_rcO[s]   = r.open;
   g_rcH[s]   = r.high;
   g_rcL[s]   = r.low;
   g_rcC[s]   = r.close;
   g_rcClr[s] = (d > 0) ? 0.0 : 1.0;
}

void AptRndCandlePaint()
{
   int sz = MathMin(MathMin(ArraySize(g_rcO), ArraySize(g_rcH)), MathMin(ArraySize(g_rcL), MathMin(ArraySize(g_rcC), ArraySize(g_rcClr))));
   if(sz <= 0)
      return;   // terminal chua cap buffer (truoc OnCalculate dau tien)

   int nLv = (_Period == PERIOD_M1) ? g_aptRndLvlN : 0;
   if(nLv > 56)
      nLv = 56;
   datetime t0  = iTime(_Symbol, PERIOD_M1, 0);
   double   sig = (double)nLv;
   for(int k = 0; k < nLv; k++)
      sig += g_aptRndLvl[k] * (double)(k + 1);

   static double   s_sig = -1.0;   // chu ky bo moc da to lan truoc
   static datetime s_t0  = 0;      // nen M1 0 luc to lan truoc
   static int      s_sz  = 0;      // so phan tu buffer luc to lan truoc

   MqlRates r[];
   ArraySetAsSeries(r, true);

   if(sig != s_sig || t0 != s_t0 || sz != s_sz)
   {
      // bo moc doi / nen moi / lich su dai ra -> to lai ca cum nen gan nhat, xoa phan con lai
      int cnt = (nLv > 0) ? MathMin(sz, APT_RND_CNDL_BARS) : 0;
      int got = 0;
      if(cnt > 0)
      {
         got = CopyRates(_Symbol, PERIOD_M1, 0, cnt, r);
         if(got < 0)
            got = 0;
      }
      for(int s = 0; s < sz; s++)
      {
         if(s < got)
            AptRndCandleSet(s, r[s]);
         else
         {
            g_rcO[s]   = EMPTY_VALUE;
            g_rcH[s]   = EMPTY_VALUE;
            g_rcL[s]   = EMPTY_VALUE;
            g_rcC[s]   = EMPTY_VALUE;
            g_rcClr[s] = 0.0;
         }
      }
      if(cnt == 0 || got > 0)
      {
         s_sig = sig;
         s_t0  = t0;
         s_sz  = sz;
      }
      else
         s_sig = -1.0;   // chua doc duoc nen M1 (dang tai lich su) -> lan sau thu lai
      return;
   }

   // khong doi gi ngoai nen dang chay (shift 0): chi tinh lai 1 nen
   if(nLv > 0 && CopyRates(_Symbol, PERIOD_M1, 0, 1, r) == 1)
      AptRndCandleSet(0, r[0]);
}

//==================================================================
//  AptQuickReadStr: DOC NHANH tu 3 truong <FVG> <LVN> <IMB> cua 14 khung trong cot Pattern (g_patFvgStr / g_patLvnStr / g_patImbStr), DIEM LIEN TUC.
//  Moi khung cho DIEM s thuoc [-1, +1] (+ = ky vong gia len, - = xuong), cong 3 thanh phan roi kep [-1, +1] (xung dot nguoc dau tu triet tieu):
//    - FVG  (dao chieu): FVG tang (pct = vi tri Bid trong vung, 0 = mep duoi) -> +pct/100 (cham mep tren = lan cham dau, manh nhat; di sau vao vung -> yeu dan);
//                        FVG giam -> -(1 - pct/100) (cham mep duoi manh nhat).
//    - IMB  (t = |pct| / InpQrImbBigPct): t < 1 -> hoi ve gia tri (dao chieu): -dau * (1 - t) (sat bien VA manh nhat, yeu dan den nguong); t >= 1 -> tiep dien (xuyen): +dau * min(1, t - 1) (manh dan den 2 lan nguong).
//    - LVN  (huong = Bid so voi Open nen dang chay cua khung; pct = vi tri Bid trong vung): con DUONG CHAY: len -> +(1 - pct/100), xuong -> -pct/100 (vua vao vung manh nhat, sap ra khoi vung -> yeu). Bid = Open -> 0.
//  Tong hop: S = sum(w * s) / sum(w), w = log2(chu ky khung tinh bang phut) + 1 (1m = 1, 1h ~ 6.9, 1d ~ 11.5, 1nm ~ 15.4) - khung lon nang hon.
//  Ma: |S| < InpQrBand -> TL (trung lap); nguoc lai nhom DAO CHIEU (FVG + IMB nho) lon hon hoac bang nhom XUYEN (IMB lon + LVN) tinh theo |sum(w * nhom)| -> ĐCT (S > 0) / ĐCG (S < 0); con lai -> XT (S > 0) / XG (S < 0).
//  Ket qua "<ma> <S> <tang>/<giam>/<trung lap> [F<tang>/<giam>] [L<len>/<xuong>]", vd "ĐCT +0.42 7/2/5 F5/0 L0/9": S co dau, 2 so le; <tang>/<giam>/<trung lap> = so KHUNG co s > 0.1 / s < -0.1 / con lai; F = so khung co FVG tang / giam; L = so khung trong LVN dang chay len / xuong.
//  Khong khung nao co FVG / LVN / IMB -> "". LUU Y: cac ham dang diem (vi tri trong vung, trong so khung, nguong 0.1) la gia thuyet chua duoc backtest.
//==================================================================
string AptQuickReadStr()
  {
   double sumW = 0.0, sumS = 0.0, sumR = 0.0, sumB = 0.0;
   int    nUp = 0, nDn = 0, fvUp = 0, fvDn = 0, lvN = 0, lvUp = 0, lvDn = 0;
   bool   any = false;
   double bidQ = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   for(int i = 0; i < 14; i++)
     {
      double w  = MathLog((double)PeriodSeconds(g_tfList[i]) / 60.0) / MathLog(2.0) + 1.0;
      double fvS = 0.0, imR = 0.0, imB = 0.0, lvS = 0.0;
      string fs = g_patFvgStr[i];
      if(fs != "")
        {
         any = true;
         bool   bear = (StringGetCharacter(fs, 0) == '-');
         double p    = MathMin(100.0, (double)StringToInteger(bear ? StringSubstr(fs, 1) : fs)) / 100.0;
         if(bear) { fvS = -(1.0 - p); fvDn++; }
         else     { fvS = p;          fvUp++; }
        }
      string im = g_patImbStr[i];
      if(StringLen(im) >= 2)
        {
         ushort c0 = StringGetCharacter(im, 0);
         if(c0 == '+' || c0 == '-')
           {
            any = true;
            int    sg = (c0 == '+') ? 1 : -1;
            double t  = (double)StringToInteger(StringSubstr(im, 1)) / MathMax(InpQrImbBigPct, 0.0001);
            if(t < 1.0) imR = -sg * (1.0 - t);
            else        imB =  sg * MathMin(1.0, t - 1.0);
           }
        }
      string ls = g_patLvnStr[i];
      if(ls != "")
        {
         any = true;
         lvN++;
         double opQ = iOpen(_Symbol, g_tfList[i], 0);
         double p   = MathMin(100.0, (double)StringToInteger(ls)) / 100.0;
         if(bidQ > 0.0 && opQ > 0.0)
           {
            if(bidQ > opQ)      { lvS = 1.0 - p; lvUp++; }
            else if(bidQ < opQ) { lvS = -p;      lvDn++; }
           }
        }
      double r  = fvS + imR;
      double b  = imB + lvS;
      double st = MathMax(-1.0, MathMin(1.0, r + b));
      sumW += w;
      sumS += w * st;
      sumR += w * r;
      sumB += w * b;
      if(st > 0.1)       nUp++;
      else if(st < -0.1) nDn++;
     }
   if(!any || sumW <= 0.0)
      return("");

   double S = sumS / sumW;
   string code;
   if(MathAbs(S) < InpQrBand)
      code = "TL";
   else
      if(MathAbs(sumR) >= MathAbs(sumB))
         code = (S > 0.0) ? "ĐCT" : "ĐCG";
      else
         code = (S > 0.0) ? "XT" : "XG";
   return(code + " " + (S > 0.0 ? "+" : "") + DoubleToString(S, 2) + " " + IntegerToString(nUp) + "/" + IntegerToString(nDn) + "/" + IntegerToString(14 - nUp - nDn) +
          ((fvUp + fvDn > 0) ? (" F" + IntegerToString(fvUp) + "/" + IntegerToString(fvDn)) : "") + ((lvN > 0) ? (" L" + IntegerToString(lvUp) + "/" + IntegerToString(lvDn)) : ""));
  }

void AptRndMarksDraw()
{
   // So nhan toi da 56 (14 khung x 4 loai moc: R/S, HH, LL, OW)
   double px[56];
   string nm[56];
   int    n = 0;

   // HH / LL cua kenh brkD tung khung tu 5m tro len -> <lamtron> (HH: cach tinh R; LL: cach tinh S).
   //   HH / LL chi doi khi khung sang nen moi hoac doi so nen kenh (nut B<n>) -> cache theo (thoi gian nen 0, N).
   //   Thieu du lieu (Bars < N + 2, iHighest / iLowest loi, gia <= 0) -> khong co moc; khong cache de lan sau thu lai.
   static datetime s_hlBarT[14];
   static int      s_hlN   [14];
   static double   s_hlHH  [14];
   static double   s_hlLL  [14];
   int bn = g_aptBrkDBars;
   if(bn < 2)   bn = 2;
   if(bn > 500) bn = 500;
   for(int hi = 0; hi < 14; hi++)
   {
      g_aptRndHPx[hi] = 0.0;
      g_aptRndLPx[hi] = 0.0;
      ENUM_TIMEFRAMES tfh = g_tfList[hi];
      if(PeriodSeconds(tfh) < 300)   // chi tu 5m tro len (giong moc R / S: bo 1m)
         continue;
      datetime tb = iTime(_Symbol, tfh, 0);
      if(tb <= 0)
         continue;
      if(s_hlBarT[hi] != tb || s_hlN[hi] != bn)
      {
         s_hlBarT[hi] = 0;
         s_hlHH[hi]   = 0.0;
         s_hlLL[hi]   = 0.0;
         if(Bars(_Symbol, tfh) >= bn + 2)
         {
            int ihh = iHighest(_Symbol, tfh, MODE_HIGH, bn, 1);
            int ill = iLowest (_Symbol, tfh, MODE_LOW , bn, 1);
            if(ihh >= 0 && ill >= 0)
            {
               double hhv = iHigh(_Symbol, tfh, ihh);
               double llv = iLow (_Symbol, tfh, ill);
               if(hhv > 0.0 && llv > 0.0)
               {
                  s_hlHH[hi]   = hhv;
                  s_hlLL[hi]   = llv;
                  s_hlN[hi]    = bn;
                  s_hlBarT[hi] = tb;
               }
            }
         }
      }
      if(s_hlHH[hi] > 0.0 && s_hlLL[hi] > 0.0)
      {
         // Dung lai AptRoundNearStr(): "R1" = cach tinh R (boi so nho nhat >= gia, cach <= W), "S1" = cach tinh S (boi so lon nhat < gia, cach <= W).
         string rH = AptRoundNearStr("R1", s_hlHH[hi]);
         string rL = AptRoundNearStr("S1", s_hlLL[hi]);
         if(rH != "") g_aptRndHPx[hi] = StringToDouble(rH);
         if(rL != "") g_aptRndLPx[hi] = StringToDouble(rL);
      }
   }

   // OW (EMA(Open) chu ky bn) cua tung khung tu 5m tro len -> <lamtron>. Cache theo (thoi gian nen 0, bn).
   //   Thieu du lieu -> khong co moc. Huong lam tron: RV1 >= OW (len) / nguoc lai (xuong) - xem khai bao g_aptRndOwPx.
   static datetime s_owBarT[14];
   static int      s_owN   [14];
   static double   s_owV   [14];
   for(int oi = 0; oi < 14; oi++)
   {
      g_aptRndOwPx[oi] = 0.0;
      ENUM_TIMEFRAMES tfo = g_tfList[oi];
      if(PeriodSeconds(tfo) < 300)   // chi tu 5m tro len
         continue;
      datetime tbo = iTime(_Symbol, tfo, 0);
      if(tbo <= 0)
         continue;
      // [GIU NGUYEN - KHONG XOA] if(s_owBarT[oi] != tbo || s_owN[oi] != bn)
      if(s_owBarT[oi] != tbo || s_owN[oi] != AptOwModeKey(bn))
      {
         double owv = 0.0;
         s_owV[oi]    = AptOpenLwma(tfo, bn, owv) ? owv : 0.0;
         // [GIU NGUYEN - KHONG XOA] s_owN[oi]    = bn;
         s_owN[oi]    = AptOwModeKey(bn);
         s_owBarT[oi] = (s_owV[oi] > 0.0) ? tbo : 0;   // that bai -> khong cache, lan sau thu lai
      }
      // RV1 (cua khung do) >= OW -> lam tron LEN ("R1"), nguoc lai -> lam tron XUONG ("S1")
      double rv1o = g_rv1ValCache[oi];
      if(s_owV[oi] > 0.0 && rv1o > 0.0)
      {
         string rO = AptRoundNearStr((rv1o >= s_owV[oi]) ? "R1" : "S1", s_owV[oi]);
         if(rO != "") g_aptRndOwPx[oi] = StringToDouble(rO);
      }
   }

   // Gop moc theo 4 loai: kd = 0 -> R/S (g_aptRndPx, nhan "<khung>"), kd = 1 -> HH ("<khung>H"), kd = 2 -> LL ("<khung>L"), kd = 3 -> OW (g_aptRndOwPx, "<khung>OW").
   for(int i = 0; i < 14; i++)
   {
       for(int kd = 0; kd < 4; kd++)
      {
         double v = (kd == 0) ? g_aptRndPx[i] : ((kd == 1) ? g_aptRndHPx[i] : ((kd == 2) ? g_aptRndLPx[i] : g_aptRndOwPx[i]));
         if(v <= 0.0)
            continue;
         if(!AptRndGapKeep(v))   // nut "KC": bo cac muc chan xen giua
            continue;
         string lb = g_tfLabel[i] + ((kd == 1) ? "H" : ((kd == 2) ? "L" : ((kd == 3) ? "OW" : "")));
         int f = -1;
         for(int j = 0; j < n; j++)
            if(px[j] == v) { f = j; break; }
         if(f >= 0)
            nm[f] = nm[f] + " " + lb;
         else
         {
            px[n] = v;
            nm[n] = lb;
            n++;
         }
      }
   }

   AptRndAlertCheck(px, nm, n);   // alert khi Bid den gan moc (+/- InpRndAlertDist), doc lap voi viec ve nhan ben duoi

   // Luu bo gia nhan lam tron dang hien de to mau nen 1m cham/xuyen qua nhan (xem AptRndCandlePaint()).
   g_aptRndLvlN = n;
   for(int lk = 0; lk < n; lk++)
      g_aptRndLvl[lk] = px[lk];
   AptRndCandlePaint();

   int psec = PeriodSeconds(_Period);
   datetime t0 = iTime(_Symbol, _Period, 0);
   if(n > 0 && (psec <= 0 || t0 <= 0))
      n = 0;
   datetime tR = 0;
   if(n > 0)
   {
      // thoi gian cua cot nen NGOAI CUNG BEN PHAI dang hien tren chart (sat thang gia)
      int rs = (int)ChartGetInteger(0, CHART_FIRST_VISIBLE_BAR) - (int)ChartGetInteger(0, CHART_VISIBLE_BARS) + 1;
      tR = (rs >= 0) ? iTime(_Symbol, _Period, rs) : (datetime)((long)t0 + (long)(-rs) * (long)psec);
      if(tR <= 0)
         n = 0;
   }

   // Nhan "gia moi vuot qua" = moc co thoi gian tu luc gia cat qua NHO NHAT (hoa nhau -> moc gan gia hon).
   // [GIU NGUYEN - KHONG XOA] //   Chi nhan nay duoc them tien to "<phut>s " va dau " - " truoc gia, vd "1.50s 5mH - 4160".
   // [GIU NGUYEN - KHONG XOA] //   Chi nhan nay duoc them tien to "<phut>s ", vd "1.50s 5mH" (gia moc chi con hien tren the gia ben phai).
   //   Chi nhan nay hien "<phut>s", vd "1.50s" (khong in <ten moc>; gia moc chi con hien tren the gia ben phai).
   int    crossK   = -1;
   double crossMin = 0.0;
   if(n > 0)
   {
      double bidX = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      if(bidX > 0.0)
         for(int ck = 0; ck < n; ck++)
         {
            double mk = 0.0;
            if(!AptRndCrossMinutes(px[ck], bidX, mk))
               continue;
            if(crossK < 0 || mk < crossMin - 1e-9
               || (MathAbs(mk - crossMin) <= 1e-9 && MathAbs(bidX - px[ck]) < MathAbs(bidX - px[crossK])))
            {
               crossK   = ck;
               crossMin = mk;
            }
         }
   }

   // Nhan LAM TRON GAN BID NHAT trong cac moc dang trong vung alarm (|Bid - moc| <= InpRndAlertDist, nhu AptRndAlertCheck()) them "<ti le phan ung>"
   //   cuoi nhan, vd "0.75s 1" hoac "1" ("-" khi chua tinh duoc). Ti le = Batlai / (Batlai + Xuyen), N = so nen M1 trong vung alarm (AptRndReactRatio()).
   //   Tat alert (InpRndAlertOn = false) -> khong them.
   //   (Truoc day nhan nay con them "<khung><so dinh>/<so day>" - AptRndHLCountStr() - da thay bang <Owtron> cac khung 1m..30m o nhan GAN GIA GIUA NHAT, xem midK ben duoi.)
   int    actK     = -1;
   string actRatio = "";
   if(InpRndAlertOn && n > 0)
   {
      double bidA  = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double distA = (InpRndAlertDist < 0.0) ? 0.0 : InpRndAlertDist;
      if(bidA > 0.0)
      {
         for(int ak = 0; ak < n; ak++)
         {
            double da = MathAbs(bidA - px[ak]);
            if(da > distA)
               continue;
            if(actK < 0 || da < MathAbs(bidA - px[actK]))
               actK = ak;
         }
         if(actK >= 0)
         {
            double rr = 0.0;
            int    rn = 0;
            actRatio = AptRndReactRatio(px[actK], distA, bidA, rr, rn) ? AptRatioStr(rr) : "-";
         }
      }
   }

   // Nhan LAM TRON GAN GIA GIUA (Bid + Ask)/2 NHAT (khong gioi han khoang cach, hoa nhau -> chi so nho hon; cung cach chon voi AptRndNearestMidLvl()) them
   //   ket qua DOC NHANH rut gon tu <IMB> <LVN> <FVG> cua cac khung trong cot Pattern (AptQuickReadStr()), vd "ĐCT 3/1/10" / "XG 1/4/9 L2" / "TL 2/2/10".
   int    midK  = -1;
   string midQr = "";
   if(n > 0)
   {
      double bidM = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double askM = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      if(bidM > 0.0 && askM > 0.0)
      {
         double midM = (bidM + askM) / 2.0;
         for(int mk2 = 0; mk2 < n; mk2++)
            if(midK < 0 || MathAbs(midM - px[mk2]) < MathAbs(midM - px[midK]))
               midK = mk2;
         if(midK >= 0)
            midQr = AptQuickReadStr();
      }
   }

   // 56 object cap (14 khung x 4 loai moc)
   for(int k = 0; k < 56; k++)
   {
      string nmA = g_rndMkPrefix + "A" + IntegerToString(k);
      string nmT = g_rndMkPrefix + "T" + IntegerToString(k);
      if(k >= n)
      {
         ObjectDelete(0, nmA);
         ObjectDelete(0, nmT);
         continue;
      }
      if(ObjectFind(0, nmA) < 0)
         ObjectCreate(0, nmA, OBJ_ARROW_RIGHT_PRICE, 0, tR, px[k]);
      ObjectMove(0, nmA, 0, tR, px[k]);
      ObjectSetInteger(0, nmA, OBJPROP_COLOR,      clrWhite);
      ObjectSetInteger(0, nmA, OBJPROP_WIDTH,      1);
      ObjectSetInteger(0, nmA, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, nmA, OBJPROP_HIDDEN,     true);
      ObjectSetInteger(0, nmA, OBJPROP_BACK,       false);

      if(ObjectFind(0, nmT) < 0)
         ObjectCreate(0, nmT, OBJ_TEXT, 0, tR, px[k]);
      ObjectMove(0, nmT, 0, tR, px[k]);
      // [GIU NGUYEN - KHONG XOA] // Nhan ghi theo format "<khung> <khung> ... <gia lam tron>", vd "1h 2h 4h 8h 12h 4100". Gia = px[k] lam tron ra so nguyen.
      // [GIU NGUYEN - KHONG XOA] //   Rieng nhan gia MOI VUOT QUA (crossK): "<phut>s <khung> ... - <gia lam tron>", vd "1.50s 5mH - 4160" (phut = AptRndCrossMinutes()).
      // [GIU NGUYEN - KHONG XOA] //   Nhan moc dang trong vung alarm gan Bid nhat (actK) them " <ti le phan ung>" o cuoi, vd "0.75s 5mOW - 81700 1".
      // [GIU NGUYEN - KHONG XOA] // Nhan ghi theo format "<khung> <khung> ...", vd "1h 2h 4h 8h 12h". Gia moc chi hien tren the gia (OBJ_ARROW_RIGHT_PRICE) ben phai, khong lap lai trong chu.
      // [GIU NGUYEN - KHONG XOA] //   Rieng nhan gia MOI VUOT QUA (crossK): "<phut>s <khung> ...", vd "1.50s 5mH" (phut = AptRndCrossMinutes()).
      // [GIU NGUYEN - KHONG XOA] //   Nhan moc dang trong vung alarm gan Bid nhat (actK) them " <ti le phan ung>" o cuoi, vd "0.75s 5mOW 1".
      // Chu nhan KHONG in <ten moc> (ten khung + H/L/OW) va khong in gia (gia moc chi hien tren the gia OBJ_ARROW_RIGHT_PRICE ben phai).
      //   Nhan gia MOI VUOT QUA (crossK): "<phut>s", vd "1.50s" (phut = AptRndCrossMinutes()).
      //   Nhan moc dang trong vung alarm gan Bid nhat (actK): them "<ti le phan ung>" o cuoi, vd "0.75s 1" hoac "1".
      //   Cac moc khac: chu rong (ghi 1 dau cach de MT5 khong hien chu mac dinh), chi con the gia.
      string rtx = (k == actK && actRatio != "") ? (" " + actRatio) : "";
      // [GIU NGUYEN - KHONG XOA] if(k == crossK)
      // [GIU NGUYEN - KHONG XOA]    ObjectSetString (0, nmT, OBJPROP_TEXT,    StringFormat("%.2f", crossMin) + "s " + nm[k] + " - " + IntegerToString((long)MathRound(px[k])) + rtx);
      // [GIU NGUYEN - KHONG XOA] else
      // [GIU NGUYEN - KHONG XOA]    ObjectSetString (0, nmT, OBJPROP_TEXT,    nm[k] + " " + IntegerToString((long)MathRound(px[k])) + rtx);
      // [GIU NGUYEN - KHONG XOA] if(k == crossK)
      // [GIU NGUYEN - KHONG XOA]    ObjectSetString (0, nmT, OBJPROP_TEXT,    StringFormat("%.2f", crossMin) + "s " + nm[k] + rtx);
      // [GIU NGUYEN - KHONG XOA] else
      // [GIU NGUYEN - KHONG XOA]    ObjectSetString (0, nmT, OBJPROP_TEXT,    nm[k] + rtx);
      // [GIU NGUYEN - KHONG XOA] string mkTxt = ((k == crossK) ? (StringFormat("%.2f", crossMin) + "s") : "") + rtx;
      string mkTxt = ((k == crossK) ? (StringFormat("%.2f", crossMin) + "s") : "") + rtx + ((k == midK && midQr != "") ? (" " + midQr) : "");
      StringTrimLeft(mkTxt);
      if(mkTxt == "")
         mkTxt = " ";
      ObjectSetString (0, nmT, OBJPROP_TEXT,    mkTxt);
      ObjectSetString (0, nmT, OBJPROP_FONT,       InpFontName);
      ObjectSetInteger(0, nmT, OBJPROP_FONTSIZE,   InpFontSize);
      ObjectSetInteger(0, nmT, OBJPROP_COLOR,      clrWhite);
      ObjectSetInteger(0, nmT, OBJPROP_ANCHOR,     ANCHOR_RIGHT);   // chu ket thuc ngay truoc the gia
      ObjectSetInteger(0, nmT, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, nmT, OBJPROP_HIDDEN,     true);
      ObjectSetInteger(0, nmT, OBJPROP_BACK,       false);
   }
}

string AptRoundNearStr(const string tenMuc, const double lvlPx)
{
   if(StringLen(tenMuc) != 2 || lvlPx <= 0.0)
      return "";
   ushort c0 = StringGetCharacter(tenMuc, 0);
   ushort c1 = StringGetCharacter(tenMuc, 1);
   if(c1 < '1' || c1 > '9')   // R1..R9 / S1..S9
      return "";
   int    ridx = (g_aptRndIdx < 0 || g_aptRndIdx > 3) ? 1 : g_aptRndIdx;
   double step = (double)g_aptRndVals[ridx];
   double off  = (double)g_aptRndOff[ridx];       // nut x5: gia tri = n*10 + 5 (4195, 4205...); cac nut con lai off = 0
   double rng  = (g_aptRndRange < 0.0) ? 0.0 : g_aptRndRange;
   double q    = MathCeil((lvlPx - off) / step - 1e-9);   // boi so nho nhat (n*buoc + do lech) >= lvlPx
   double v;
   if(c0 == 'R')
     {
      v = q * step + off;
      if(v - lvlPx > rng)
         return "";
     }
   else if(c0 == 'S')
     {
      v = (q - 1.0) * step + off;                 // boi so lon nhat < lvlPx
      if(lvlPx - v > rng)
         return "";
     }
   else
      return "";
   return IntegerToString((long)MathRound(v));
}

// Cache CHUOI (streak) cua brkD tren hang BREAK STATS, cho 14 khung cua g_tfList (cung chi so i voi vong lap DrawBreakStats).
//   <streak> (AptBrkStreakCount): brkD >= 50 -> so nen lien tiep co brkD > 90; brkD < 50 -> so nen lien tiep co brkD < 10 (gom ca nen hien tai).
//   CACHE: phan chuoi cua cac nen da dong (k >= 1) chi doi khi khung sang nen moi -> tinh lai 1 lan / nen (khoa theo iTime(tf,0));
//     nen shift 0 (doi theo tick) duoc ghep vao luc doc.
#define APT_BRK_STREAK_TF_COUNT 14   // = so phan tu g_tfList (1m..1nm)
#define APT_BRK_STREAK_MAX      60   // tran so nen quet lui (an toan hieu nang)

// So nen cua KENH dung lam mau so cho brkD - xem input InpBrkDBars (ben duoi).

input group             "=== 14. KENH brkD (hang BREAK STATS) ==="
// So nen N cua KENH dung lam mau so cho brkD:
//   brkD = (Close[0] - LowestLow(1..N)) / (HighestHigh(1..N) - LowestLow(1..N)) * 100
//   Kenh lay tu nen shift 1 den shift N, KHONG gom nen shift 0 -> brkD co the > 100 (pha dinh kenh) hoac < 0 (thung day kenh).
//   N nho (3..5) = bam sat, nhay, streak ngan | N vua (8..12) = can bang | N lon (20+) = it cat moc 50, streak dai.
//   Gia tri duoc KEP trong [2, 500] trong AptBrkDAt(). Doi gia tri nay -> MT5 goi lai OnInit -> cache streak (g_aptBrkStrkHi/Lo/Side/BarT) tinh lai tu dau.
//   Gia tri khoi tao cua g_aptBrkDBars (nut B<n>).
input int               InpBrkDBars       = 10;   // So nen cua kenh brkD (2..500) - hang BREAK STATS

int      g_aptBrkStrkSide[APT_BRK_STREAK_TF_COUNT];  // co "cache hop le": 1 = hop le, 0 = chua hop le
datetime g_aptBrkStrkBarT[APT_BRK_STREAK_TF_COUNT];  // open time nen shift 0 luc dung cache
// <streak>: brkD >= 50 -> dem nen lien tiep co brkD > 90; brkD < 50 -> dem nen lien tiep co brkD < 10.
//   Hai bo dem nen DA DONG (tinh tu k = 1).
int      g_aptBrkStrkHi  [APT_BRK_STREAK_TF_COUNT];  // so nen DA DONG lien tiep co brkD > 90, tinh tu k = 1
int      g_aptBrkStrkLo  [APT_BRK_STREAK_TF_COUNT];  // so nen DA DONG lien tiep co brkD < 10, tinh tu k = 1

//==================================================================
//  HELPER - lay 1 gia tri buffer
//==================================================================
double BufVal(const int handle,const int shift)
  {
   if(handle==INVALID_HANDLE)
      return(0.0);
   double b[];
   if(CopyBuffer(handle,0,shift,1,b)<1)
      return(0.0);
   return(b[0]);
  }

//==================================================================
//  HELPER - lam tron lot theo dac ta symbol
//==================================================================
double NormalizeLots(double lots)
  {
   double vmin  = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   double vmax  = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
   double vstep = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   if(vstep<=0.0)
      vstep=0.01;
   lots = MathFloor(lots/vstep)*vstep;
   if(lots<vmin)
      lots=vmin;
   if(vmax>0.0 && lots>vmax)
      lots=vmax;
   return(NormalizeDouble(lots,2));
  }

//==================================================================
//  HELPER - tien lo/lai cho 1 lot tren 1 khoang gia
//==================================================================
double MoneyPerLot(const double priceDistance)
  {
   double tickVal = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
   double tickSz  = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   if(tickSz<=0.0 || tickVal<=0.0)
     {
      double contract = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_CONTRACT_SIZE);
      if(contract<=0.0)
         contract=1.0;
      return(priceDistance*contract);
     }
   return(priceDistance/tickSz*tickVal);
  }

//==================================================================
//  HELPER - tim swing (fractal) gan nhat tu startIdx tro ve qua khu
//==================================================================
bool FindSwing(const bool isHigh,const int startIdx,const int depth,
               const int lookback,int &idx,double &price)
  {
   int total = Bars(_Symbol,_Period);
   int maxi  = MathMin(lookback,total-depth-2);
   int begin = MathMax(startIdx,depth);
   for(int i=begin; i<=maxi; i++)
     {
      double v = isHigh ? iHigh(_Symbol,_Period,i) : iLow(_Symbol,_Period,i);
      bool ok  = true;
      for(int k=1; k<=depth && ok; k++)
        {
         double a = isHigh ? iHigh(_Symbol,_Period,i+k) : iLow(_Symbol,_Period,i+k);
         double b = isHigh ? iHigh(_Symbol,_Period,i-k) : iLow(_Symbol,_Period,i-k);
         if(isHigh)
           {
            if(a>v || b>v)
               ok=false;
           }
         else
           {
            if(a<v || b<v)
               ok=false;
           }
        }
      if(ok)
        {
         idx   = i;
         price = v;
         return(true);
        }
     }
   return(false);
  }

//==================================================================
//  HELPER - tim swing ke tiep vuot qua nguong ref (dung cho TP_STRUCT)
//==================================================================
bool FindTargetSwing(const bool isHigh,const double ref,const int depth,
                     const int lookback,double &price)
  {
   int    idx   = 0;
   double p     = 0.0;
   int    start = depth;
   for(int guard=0; guard<80; guard++)
     {
      if(!FindSwing(isHigh,start,depth,lookback,idx,p))
         return(false);
      if(isHigh && p>ref)
        {
         price=p;
         return(true);
        }
      if(!isHigh && p<ref)
        {
         price=p;
         return(true);
        }
      start = idx+1;
     }
   return(false);
  }

//==================================================================
//  HELPER (noi bo bias) - so nen M1 tuong ung 1 chu ky TF
//  Sao chep y het GetRV2NBars cua RollingVWAP2_MultiTF.mq5
//==================================================================
int AptGetNBars(const ENUM_TIMEFRAMES tf)
  {
   int nB = (int)(PeriodSeconds(tf) / 60);
   if(nB < 1)
      nB = 1;
   return nB;
  }

//==================================================================
//  HELPER (noi bo bias) - tim index M1 (series, 0=moi nhat) co open
//  time <= atTime, gan nhat hien tai. Sao chep y het FindM1Shift cua
//  RollingVWAP2_MultiTF.mq5
//==================================================================
int AptFindM1Shift(const datetime &tm[], const int got, const datetime atTime)
  {
   if(got <= 0)
      return -1;
   if(atTime >= tm[0])
      return 0;
   if(atTime < tm[got - 1])
      return -1;
   int lo = 0, hi = got - 1;
   while(lo < hi)
     {
      int mid = (lo + hi) / 2;
      if(tm[mid] > atTime)
         lo = mid + 1;
      else
         hi = mid;
     }
   return lo;
  }

bool AptRvQCalc(const double &series[], const int avail, const double rangeRS,
                const int qBarsInp, double &outQ)
  {
   outQ = 0.0;
   if(avail < 2)
      return false;
   if(rangeRS <= 0.0)
      return false;
   if(series[0] <= 0.0 || series[1] <= 0.0)
      return false;

   double slope = (series[0] - series[1]) / rangeRS;
   if(slope >  1.0) slope =  1.0;
   if(slope < -1.0) slope = -1.0;

   int n = qBarsInp;
   if(n < 2)  n = 2;
   if(n > 20) n = 20;
   if(n > avail) n = avail;
   if(n < 2)
      return false;

   double path = 0.0;
   for(int i = 0; i < n - 1; i++)
     {
      double a = series[i];
      double b = series[i + 1];
      if(a <= 0.0 || b <= 0.0)
         return false;
      path += MathAbs(a - b);
     }
   if(path <= 0.0)
      return false;

   double net = MathAbs(series[0] - series[n - 1]);
   double er  = net / path;
   if(er > 1.0)
      er = 1.0;

   outQ = er * slope;
   return true;
  }

//==================================================================
//  HELPER (noi bo bias) - lay RV1[0]-RV1[1] va Q1 cua 1 khung TF
//  Cong thuc SAO CHEP y het RollingVWAP2_MultiTF.mq5:
//    RV1 = VWAP (tp=(H+L+C)/3, weight=tick volume) cua nB nen M1
//          ket thuc tai moc nen TF (shift 0 = TimeCurrent, shift>0 =
//          open time nen TF).
//  Tra them outRv0 = rv[0] (RV1 hien tai cua khung tf) de ben ngoai tinh diffrv1 = Bid - RV1.
//==================================================================
bool AptRv1DiffAndQ1(const ENUM_TIMEFRAMES tf, double &outDiff, double &outQ1, double &outRv0)
  {
   outDiff = 0.0;
   outQ1   = 0.0;
   outRv0  = 0.0;

   int nB = AptGetNBars(tf);
   if(nB < 1)
      return false;

   // so mau RV1 can: 10 (Q) + 2 an toan
   const int qBars = 10;
   int needTF = qBars + 2;
   if(needTF < 4)
      needTF = 4;

   long needL = (long)needTF * (long)nB + (long)nB;
   if(needL < 2)
      return false;
   if(needL > 200000)
      needL = 200000;
   int need = (int)needL;

   double   hi[], lo[], cl[];
   long     tv[];
   datetime tm[];
   ArraySetAsSeries(hi, true);
   ArraySetAsSeries(lo, true);
   ArraySetAsSeries(cl, true);
   ArraySetAsSeries(tv, true);
   ArraySetAsSeries(tm, true);

   int cpH = CopyHigh      (_Symbol, PERIOD_M1, 0, need, hi);
   int cpL = CopyLow       (_Symbol, PERIOD_M1, 0, need, lo);
   int cpC = CopyClose     (_Symbol, PERIOD_M1, 0, need, cl);
   int cpV = CopyTickVolume(_Symbol, PERIOD_M1, 0, need, tv);
   int cpT = CopyTime      (_Symbol, PERIOD_M1, 0, need, tm);
   int got = MathMin(MathMin(MathMin(cpH, cpL), MathMin(cpC, cpV)), cpT);
   if(got < 2)
      return false;

   // prefix-sum de tinh VWAP cua cua so nB nhanh
   double cumTPV[], cumVol[];
   ArrayResize(cumTPV, got + 1);
   ArrayResize(cumVol, got + 1);
   cumTPV[got] = 0.0;
   cumVol[got] = 0.0;
   for(int s = got - 1; s >= 0; s--)
     {
      double tp = (hi[s] + lo[s] + cl[s]) / 3.0;
      double v  = (double)tv[s];
      cumTPV[s] = cumTPV[s + 1] + tp * v;
      cumVol[s] = cumVol[s + 1] + v;
     }

   datetime tmTF[];
   ArraySetAsSeries(tmTF, true);
   int gotTF = CopyTime(_Symbol, tf, 0, needTF, tmTF);
   if(gotTF < 2)
      return false;

   double rv[];
   ArrayResize(rv, gotTF);
   int avail = 0;
   for(int k = 0; k < gotTF; k++)
     {
      // Nen lich su (k>0) neo tai GIO DONG (tmTF[k]+PeriodSeconds(tf)-1), cung cach RvwapAtBarTime() cua WPR_rVWAP_Osc.mq5; xem Wpr9BuildRv1Series
      datetime atTime = (k == 0) ? TimeCurrent() : (tmTF[k] + (datetime)PeriodSeconds(tf) - 1);
      int m1sh = AptFindM1Shift(tm, got, atTime);
      if(m1sh < 0 || m1sh + nB >= got)
         break;

      double wVol = cumVol[m1sh] - cumVol[m1sh + nB];
      double v    = (wVol > 0.0) ? (cumTPV[m1sh] - cumTPV[m1sh + nB]) / wVol : 0.0;
      if(v <= 0.0)
         break;

      rv[k] = v;
      avail = k + 1;
     }
   if(avail < 2)
      return false;

   outDiff = rv[0] - rv[1];
   outRv0  = rv[0];

   // R1 - S1 cua bar TF lien truoc (shift 1) - Woodie
   double hB = iHigh (_Symbol, tf, 1);
   double lB = iLow  (_Symbol, tf, 1);
   double cB = iClose(_Symbol, tf, 1);
   if(hB <= 0.0 || lB <= 0.0 || cB <= 0.0 || hB < lB)
      return false;

   double pp = (hB + lB + 2.0 * cB) / 4.0;   // PP = (H+L+2*C)/4
   double r1 = 2.0 * pp - lB;                 // R1 = 2*PP - L
   double s1 = 2.0 * pp - hB;                 // S1 = 2*PP - H
   double rangeRS = r1 - s1;
   if(rangeRS <= 0.0)
      return false;

   if(!AptRvQCalc(rv, avail, rangeRS, qBars, outQ1))
      return false;

   return true;
  }

//==================================================================
//  HELPER - ATR dung cho quet S1 (cung cach BuildSetup() tinh).
//==================================================================
double AptScanATR()
  {
   double atr = BufVal(g_hATR,1);
   if(atr<=0.0)
      atr = (iHigh(_Symbol,_Period,1)-iLow(_Symbol,_Period,1));
   if(atr<=0.0)
      atr = 10*_Point;
   return(atr);
  }

//==================================================================
//  KHAI BAO TRUOC cho AptScanRangeQ (than ham nam o duoi):
//    - AptRvFindSwing : tim fractal tren mot day so bat ky
//    - AptS1EmaSeries : day EMA(S1) theo tung nen TF
//==================================================================
bool AptRvFindSwing(const double &rv[],const int avail,const int depth,
                    const bool findHigh,int &outIdx,double &outVal);
int  AptS1EmaSeries(const ENUM_TIMEFRAMES tf,double &outS1[],const int wantPoints);

//==================================================================
//  QUET SWING DINH/DAY CUA DUONG S1; du phong: PHAN VI RANGE
//    Chinh: hiP / loP = gia tri duong S1 tai dinh / day swing gan nhat cua chinh no.
//    Du phong (thieu du lieu S1): lay bien do (High-Low) cua N bar gan nhat, sap xep tang dan,
//    lay phan vi Q lam do rong vung neo: hiP = Close[0] + rngQ/2 ; loP = Close[0] - rngQ/2.
//  Khong co tin hieu chieu rieng -> nhuong cho bias.
//==================================================================
bool AptScanRangeQ(double &hiP,double &loP,int &dirHint,int &fbDir,string &note)
  {
   //  QUET SWING DINH/DAY CUA DUONG S1:
   //      hiP = gia tri duong S1 (EMA(APT_S1_EMA_PERIOD) cua muc S1, AptS1EmaSeries()) tai DINH swing gan nhat
   //      loP = gia tri duong S1 tai DAY swing gan nhat
   //  Fractal tim bang AptRvFindSwing() do sau InpSwingDepth, quet S1LOOK nen TF.
   //  Chieu: dirHint = 0 (nhuong bias); fbDir = +1 neu swing moi hon la DAY, -1 neu la DINH.
   //  Thieu du lieu / khong bat duoc ca dinh lan day -> roi xuong phan vi range ben duoi.
   const int S1LOOK = 120;                        // so nen TF lui ve quet S1

   int s1Depth = InpSwingDepth;
   if(s1Depth < 1)
      s1Depth = 1;

   int s1Want = S1LOOK;
   if(s1Want < 2*s1Depth + 2)
      s1Want = 2*s1Depth + 2;

   double s1Ser[];
   int s1Avail = AptS1EmaSeries(_Period,s1Ser,s1Want);
   if(s1Avail >= 2*s1Depth + 1)
     {
      int    s1HiIdx = -1, s1LoIdx = -1;
      double s1HiVal = 0.0, s1LoVal = 0.0;
      bool okS1H = AptRvFindSwing(s1Ser,s1Avail,s1Depth,true ,s1HiIdx,s1HiVal);
      bool okS1L = AptRvFindSwing(s1Ser,s1Avail,s1Depth,false,s1LoIdx,s1LoVal);
      if(okS1H && okS1L && s1HiVal > s1LoVal)
        {
         hiP     = s1HiVal;
         loP     = s1LoVal;
         dirHint = 0;                             // de bias quyet dinh
         fbDir   = (s1LoIdx < s1HiIdx) ? 1 : -1;  // swing S1 moi nhat la day -> LONG
         note    = StringFormat("S1 swing hi#%d lo#%d  rong %.0f pts",
                                s1HiIdx,s1LoIdx,(s1HiVal-s1LoVal)/_Point);
         return(true);
        }
     }

   //  DU PHONG - PHAN VI RANGE
   const int    N = 200;      // so bar lay mau
   const double Q = 0.85;     // phan vi (85%)

   int total = Bars(_Symbol,_Period);
   int n     = MathMin(N,total-2);
   if(n<20)
     {
      note = "Thieu bar de tinh phan vi range";
      return(false);
     }

   double r[];
   ArrayResize(r,n);
   for(int i=1; i<=n; i++)
     {
      double h = iHigh(_Symbol,_Period,i);
      double l = iLow (_Symbol,_Period,i);
      r[i-1] = (h>l) ? (h-l) : 0.0;
     }
   ArraySort(r);                                  // tang dan

   int qi = (int)MathFloor(Q*(n-1));
   if(qi<0)
      qi=0;
   if(qi>n-1)
      qi=n-1;
   double rng = r[qi];
   if(rng<=0.0)
      rng = AptScanATR();
   if(rng<=0.0)
     {
      note = "Range phan vi = 0";
      return(false);
     }

   double c = iClose(_Symbol,_Period,0);
   if(c<=0.0)
      c = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   hiP = c + rng*0.5;
   loP = c - rng*0.5;
   if(hiP<=loP)
     {
      note = "Vung phan vi khong hop le";
      return(false);
     }

   dirHint = 0;

   //--- chieu du phong: so Close[0] voi trung diem cua (dinh cao nhat,
   //    day thap nhat) trong cung cua so N bar
   int    ih = iHighest(_Symbol,_Period,MODE_HIGH,n,1);
   int    il = iLowest (_Symbol,_Period,MODE_LOW ,n,1);
   double hh = (ih>=0) ? iHigh(_Symbol,_Period,ih) : hiP;
   double ll = (il>=0) ? iLow (_Symbol,_Period,il) : loP;
   fbDir = (c >= (hh+ll)*0.5) ? 1 : -1;

   note = StringFormat("Range P%.0f = %.0f pts",Q*100.0,rng/_Point);
   return(true);
  }

//==================================================================
//  HELPER - DAY SO RV1 THEO TUNG NEN TF
//  Co che nhu AptRv1DiffAndQ1(): RV1 tai moc nen TF thu k = VWAP cua nB nen M1 ket thuc tai moc do
//  (tp=(H+L+C)/3, trong so = tick volume). Tra ra ca day (outRv[0]=nen hien tai, outRv[k]=nen TF thu k lui ve)
//  de quet dinh/day fractal tren chinh duong RV1.
//  Tra ve: so phan tu RV1 lay duoc (0 = that bai). Chi doc gia.
//==================================================================
int AptRvSeries(const ENUM_TIMEFRAMES tf,double &outRv[],const int wantTF)
  {
   ArrayResize(outRv,0);

   int nB = AptGetNBars(tf);
   if(nB < 1)
      return(0);

   int needTF = wantTF + 2;
   if(needTF < 4)
      needTF = 4;

   long needL = (long)needTF * (long)nB + (long)nB;
   if(needL < 2)
      return(0);
   if(needL > 200000)
      needL = 200000;
   int need = (int)needL;

   double   hi[], lo[], cl[];
   long     tv[];
   datetime tm[];
   ArraySetAsSeries(hi, true);
   ArraySetAsSeries(lo, true);
   ArraySetAsSeries(cl, true);
   ArraySetAsSeries(tv, true);
   ArraySetAsSeries(tm, true);

   int cpH = CopyHigh      (_Symbol, PERIOD_M1, 0, need, hi);
   int cpL = CopyLow       (_Symbol, PERIOD_M1, 0, need, lo);
   int cpC = CopyClose     (_Symbol, PERIOD_M1, 0, need, cl);
   int cpV = CopyTickVolume(_Symbol, PERIOD_M1, 0, need, tv);
   int cpT = CopyTime      (_Symbol, PERIOD_M1, 0, need, tm);
   int got = MathMin(MathMin(MathMin(cpH, cpL), MathMin(cpC, cpV)), cpT);
   if(got < 2)
      return(0);

   double cumTPV[], cumVol[];
   ArrayResize(cumTPV, got + 1);
   ArrayResize(cumVol, got + 1);
   cumTPV[got] = 0.0;
   cumVol[got] = 0.0;
   for(int s = got - 1; s >= 0; s--)
     {
      double tp = (hi[s] + lo[s] + cl[s]) / 3.0;
      double v  = (double)tv[s];
      cumTPV[s] = cumTPV[s + 1] + tp * v;
      cumVol[s] = cumVol[s + 1] + v;
     }

   datetime tmTF[];
   ArraySetAsSeries(tmTF, true);
   int gotTF = CopyTime(_Symbol, tf, 0, needTF, tmTF);
   if(gotTF < 2)
      return(0);

   ArrayResize(outRv, gotTF);
   int avail = 0;
   for(int k = 0; k < gotTF; k++)
     {
      // Nen lich su (k>0) neo tai GIO DONG (tmTF[k]+PeriodSeconds(tf)-1), cung cach RvwapAtBarTime() cua WPR_rVWAP_Osc.mq5; xem Wpr9BuildRv1Series
      datetime atTime = (k == 0) ? TimeCurrent() : (tmTF[k] + (datetime)PeriodSeconds(tf) - 1);
      int m1sh = AptFindM1Shift(tm, got, atTime);
      if(m1sh < 0 || m1sh + nB >= got)
         break;

      double wVol = cumVol[m1sh] - cumVol[m1sh + nB];
      double v    = (wVol > 0.0) ? (cumTPV[m1sh] - cumTPV[m1sh + nB]) / wVol : 0.0;
      if(v <= 0.0)
         break;

      outRv[k] = v;
      avail    = k + 1;
     }

   if(avail < 2)
     {
      ArrayResize(outRv,0);
      return(0);
     }

   ArrayResize(outRv, avail);
   return(avail);
  }

//==================================================================
// HELPER - TIM FRACTAL TREN DAY SO RV1
//  Chi so theo kieu series: 0 = nen TF hien tai, k lon = lui ve qua khu.
//  Diem k la DINH RV1 khi:  rv[k] >= rv[k-j] (phia moi hon) VA
//                           rv[k] >  rv[k+j] (phia cu hon), j = 1..depth
//  Diem k la DAY RV1 khi:   rv[k] <= rv[k-j] VA rv[k] < rv[k+j]
// Cach bat dang thuc lech nhau nay giong FindSwing(): doan RV1 di ngang khong bao gio nhan ca cum bang nhau.
//  Quet tu k = depth tang dan nen luon lay DINH/DAY GAN HIEN TAI NHAT.
//  Tra ve outIdx = chi so nen TF, outVal = gia tri RV1 tai do.
//==================================================================
bool AptRvFindSwing(const double &rv[],const int avail,const int depth,
                    const bool findHigh,int &outIdx,double &outVal)
  {
   outIdx = -1;
   outVal = 0.0;

   int d = depth;
   if(d < 1)
      d = 1;
   if(avail < 2*d + 1)
      return(false);

   for(int k = d; k + d < avail; k++)
     {
      bool ok = true;
      for(int j = 1; j <= d && ok; j++)
        {
         if(findHigh)
           {
            if(rv[k] <  rv[k-j])
               ok = false;
            if(ok && rv[k] <= rv[k+j])
               ok = false;
           }
         else
           {
            if(rv[k] >  rv[k-j])
               ok = false;
            if(ok && rv[k] >= rv[k+j])
               ok = false;
           }
        }
      if(ok)
        {
         outIdx = k;
         outVal = rv[k];
         return(true);
        }
     }
   return(false);
  }

//==================================================================
//  QUET VUNG NEO - quet swing dinh/day cua duong S1 (AptScanRangeQ)
//  Tra ve vung neo [loP , hiP], goi y chieu (dirHint, co the = 0) va chieu du phong (fbDir, luon khac 0).
//==================================================================
bool AptScanLevels(double &hiP,double &loP,
                   int &dirHint,int &fbDir,string &note)
  {
   hiP     = 0.0;
   loP     = 0.0;
   dirHint = 0;
   fbDir   = 1;
   note    = "";

   if(!AptScanRangeQ(hiP,loP,dirHint,fbDir,note))
      return(false);
   if(hiP<=loP)
     {
      note = "Vung neo khong hop le";
      return(false);
     }
   if(fbDir==0)
      fbDir = 1;
   return(true);
  }

//==================================================================
//  BIAS DA KHUNG - Weighted Candle Break (H12 -> M30)
//  8 khung: H12 H8 H6 H4 H3 H2 H1 M30. Khung lon trong so cao hon.
//  Trong so: H12=8, H8=7, H6=6, H4=5, H3=4, H2=3, H1=2, M30=1.
//  Neu khong pha dinh/day nen truoc -> xet RV1[0]-RV1[1] va Q1
//  (cong thuc lay tu RollingVWAP2_MultiTF.mq5):
//    RV1[0]-RV1[1] > 0  VA  Q1 > 0  -> cong diem scoreLong
//    RV1[0]-RV1[1] < 0  VA  Q1 < 0  -> cong diem scoreShort
//    con lai                         -> khung do khong tinh diem
//==================================================================
int CalcMultiTFBias()
  {
   // 8 khung H12 -> M30; tong trong so = 36
   ENUM_TIMEFRAMES tfs[8] = {PERIOD_H12, PERIOD_H8, PERIOD_H6, PERIOD_H4,
                             PERIOD_H3, PERIOD_H2, PERIOD_H1, PERIOD_M30};
   int             w[8]   = {8, 7, 6, 5, 4, 3, 2, 1};

   int scoreLong  = 0;
   int scoreShort = 0;

   for(int i=0; i<8; i++)
     {
      if(Bars(_Symbol, tfs[i]) < 3)
         continue;

      double prevHigh = iHigh(_Symbol, tfs[i], 1);
      double prevLow  = iLow (_Symbol, tfs[i], 1);
      double curClose = iClose(_Symbol, tfs[i], 0);

      if(curClose > prevHigh)
         scoreLong  += w[i];
      else
         if(curClose < prevLow)
            scoreShort += w[i];
         else
           {
            // Khong pha dinh/day -> xet RV1[0]-RV1[1] va Q1
            double rvDiff = 0.0;
            double q1     = 0.0;
            double rv0Dummy = 0.0;
            if(AptRv1DiffAndQ1(tfs[i], rvDiff, q1, rv0Dummy))
              {
               if(rvDiff > 0.0 && q1 > 0.0)
                  scoreLong  += w[i];
               else
                  if(rvDiff < 0.0 && q1 < 0.0)
                     scoreShort += w[i];
              }
            // thieu du lieu RV1/Q1 hoac khong cung dau -> khung nay khong tinh diem
           }
     }

   if(scoreLong > scoreShort)
      return 1;
   if(scoreShort > scoreLong)
      return -1;

   return 0;
  }

//==================================================================
//  AptBrkDAt: gia tri brkD cua nen shift tren khung tf.
//        brkD = (Close[shift] - LL) / (HH - LL) * 100
//    HH = High cao nhat, LL = Low thap nhat cua N nen lien truoc nen shift (shift+1 .. shift+N), KHONG gom chinh nen shift;
//    N = g_aptBrkDBars (nut "B<n>"), kep [2, 500].
//  brkD > 100 = Close pha DINH kenh N nen; brkD < 0 = Close thung DAY kenh N nen.
//  Thieu du lieu (it hon shift+N+2 nen, iHighest/iLowest loi, HH<=LL, Close<=0) -> tra false.
//  Chi doc gia: khong tao object.
//==================================================================
bool AptBrkDAt(const ENUM_TIMEFRAMES tf, const int shift, int &outBrkD)
  {
   outBrkD = 0;
   if(shift < 0)
      return false;

   // Do dai kenh = g_aptBrkDBars (doi bang nut "B<n>"), kep [2, 500]: duoi 2 kenh khong con la kenh, tren 500 ton lich su vo ich.
   int n = g_aptBrkDBars;
   if(n < 2)
      n = 2;
   if(n > 500)
      n = 500;
   if(Bars(_Symbol, tf) < shift + n + 2)
      return false;

   int ih = iHighest(_Symbol, tf, MODE_HIGH, n, shift + 1);
   int il = iLowest (_Symbol, tf, MODE_LOW , n, shift + 1);
   if(ih < 0 || il < 0)
      return false;

   double hh = iHigh(_Symbol, tf, ih);
   double ll = iLow (_Symbol, tf, il);
   double den = hh - ll;
   if(den <= 0.0)
      return false;

   double cS = iClose(_Symbol, tf, shift);
   if(cS <= 0.0)
      return false;

   outBrkD = (int)MathRound((cS - ll) / den * 100.0);
   return true;
  }

//==================================================================
//  AptBrkWAt: William %R (W%) cua nen shift tren khung tf, dung chinh kenh HH/LL cua brkD:
//        W% = (HH - Close[shift]) / (HH - LL) * -100        (mien thuong gap -100..0)
//    HH/LL = High cao nhat / Low thap nhat cua g_aptBrkDBars nen (kep 2..500) lien truoc nen shift (shift+1 .. shift+N), giong het AptBrkDAt().
//    Thieu du lieu (giong AptBrkDAt) -> tra false, noi goi bo W%.
//  Chi doc gia: khong tao object.
//==================================================================
bool AptBrkWAt(const ENUM_TIMEFRAMES tf, const int shift, int &outW)
  {
   outW = 0;
   if(shift < 0)
      return false;

   int n = g_aptBrkDBars;
   if(n < 2)
      n = 2;
   if(n > 500)
      n = 500;
   if(Bars(_Symbol, tf) < shift + n + 2)
      return false;

   int ih = iHighest(_Symbol, tf, MODE_HIGH, n, shift + 1);
   int il = iLowest (_Symbol, tf, MODE_LOW , n, shift + 1);
   if(ih < 0 || il < 0)
      return false;

   double hh = iHigh(_Symbol, tf, ih);
   double ll = iLow (_Symbol, tf, il);
   double den = hh - ll;
   if(den <= 0.0)
      return false;

   double cS = iClose(_Symbol, tf, shift);
   if(cS <= 0.0)
      return false;

   outW = (int)MathRound((hh - cS) / den * -100.0);
   return true;
  }

//==================================================================
//  AptHHLLStrengthStr: suc manh CHUOI 5 kenh HH/LL tren khung tf. Chi tra "<T>" (vd "+0.8").
//    Chu ky kenh P = g_aptBrkDBars (nut B<n>, cung chu ky brkD). Chuoi = K = 5 kenh TRUOT tung nen, k = 0 moi nhat:
//      HH[k] = High cao nhat, LL[k] = Low thap nhat cua P nen shift 1+k .. P+k (nen DA DONG; k=0 chinh la kenh cua AptBrkDAt(tf,0)).
//      W[k]  = HH[k] - LL[k];  Wavg = trung binh 5 W[k].
//    T = [(HH[0]-HH[4]) + (LL[0]-LL[4])] / (2 * Wavg)   -> dich chuyen diem giua kenh trong 4 nen, tinh bang so lan chieu cao kenh TB.
//        Duong = kenh dang di len, am = di xuong.
//    Dinh dang: T co dau (+/-), 1 so thap phan. Thieu du lieu -> tra false, noi goi in "-".
//  Chi doc gia: khong tao object.
//==================================================================
bool AptHHLLStrengthStr(const ENUM_TIMEFRAMES tf, string &outStr)
  {
   outStr = "";
   int P = g_aptBrkDBars;
   if(P < 2)   P = 2;
   if(P > 500) P = 500;
   const int K = 5;
   const int need = P + K - 1;
   if(Bars(_Symbol, tf) < need + 2)
      return false;

   double hi[], lo[];
   ArraySetAsSeries(hi, true);
   ArraySetAsSeries(lo, true);
   if(CopyHigh(_Symbol, tf, 1, need, hi) != need)
      return false;
   if(CopyLow (_Symbol, tf, 1, need, lo) != need)
      return false;

   double hh[5], ll[5], wSum = 0.0;
   for(int k = 0; k < K; k++)
     {
      double h = hi[k], l = lo[k];
      for(int j = k + 1; j < k + P; j++)
        {
         if(hi[j] > h) h = hi[j];
         if(lo[j] < l) l = lo[j];
        }
      hh[k] = h;
      ll[k] = l;
      wSum += h - l;
     }
   double wAvg = wSum / K;
   if(wAvg <= 0.0)
      return false;

   double t = ((hh[0] - hh[K-1]) + (ll[0] - ll[K-1])) / (2.0 * wAvg);

   t = MathRound(t * 10.0) / 10.0 + 0.0;   // "+ 0.0" doi -0.0 thanh 0.0
   outStr = ((t >= 0.0) ? "+" : "") + DoubleToString(t, 1);
   return true;
  }

//==================================================================
//  AptRsiEmaLast / AptErhErlStr: <erh>/<erl> cho nhan cot Pattern.
//    HH, LL = chuoi HH/LL cua kenh brkD (HH[k] = High cao nhat, LL[k] = Low thap nhat cua P nen shift 1+k .. P+k, P = g_aptBrkDBars = nut B<n>).
//    erh = EMA( RSI( HH, P ), P )   |   erl = EMA( RSI( LL, P ), P )      (period RSI va EMA deu = P).
//    RSI = Wilder (trung binh don P buoc dau lam hat giong, sau do lam min Wilder). EMA: hat giong = SMA P gia tri RSI dau, he so 2/(P+1).
//    Chuoi HH/LL dai M = 4P+1 gia tri (hoac it hon neu lich su ngan, toi thieu 2P) tinh bang cua so truot, chi dung nen DA DONG.
//    erhdiff = erh(nen hien tai) - erh(nen truoc 1 nen), erldiff tuong tu; deu lam tron SO NGUYEN, co dau "+" khi duong.
//    Dinh dang: "<erh>/<erhdiff> <erl>/<erldiff>" (vd "62/+3 48/-2"). Thieu du lieu -> false, noi goi in "-/- -/-".
//    Cache theo (khung, nen moi nhat, P) vi chi doc nen da dong. Chi doc gia: khong tao object.
//==================================================================
bool AptRsiEmaLast(const double &src[], const int m, const int p, double &outV, double &outPrev)
  {
   outV = 0.0;
   outPrev = 0.0;
   if(p < 2 || m < 2 * p + 1)
      return false;

   double ag = 0.0, al = 0.0;
   for(int t = 1; t <= p; t++)
     {
      double d0 = src[t] - src[t - 1];
      if(d0 > 0.0)
         ag += d0;
      else
         al -= d0;
     }
   ag /= p;
   al /= p;

   const double alpha = 2.0 / (p + 1.0);
   double ema = 0.0, prevEma = 0.0, rsiSum = 0.0;
   int rsiCnt = 0;
   for(int t = p; t < m; t++)
     {
      if(t > p)
        {
         double d = src[t] - src[t - 1];
         double g = (d > 0.0) ? d : 0.0;
         double l = (d < 0.0) ? -d : 0.0;
         ag = (ag * (p - 1) + g) / p;
         al = (al * (p - 1) + l) / p;
        }
      double rsi;
      if(al <= 0.0)
         rsi = (ag > 0.0) ? 100.0 : 50.0;
      else
         rsi = 100.0 - 100.0 / (1.0 + ag / al);

      rsiCnt++;
      if(rsiCnt <= p)
        {
         rsiSum += rsi;
         if(rsiCnt == p)
            ema = rsiSum / p;
        }
      else
        {
         prevEma = ema;   // EMA cua nen truoc (de tinh diff)
         ema = ema + alpha * (rsi - ema);
        }
     }
   outV = ema;
   outPrev = prevEma;
   return true;
  }

//==================================================================
//  AptRsiEmaSeries: nhu AptRsiEmaLast() nhung tra CA CHUOI EMA(RSI(src,p),p) (ser[t], t = 0 cu nhat ... m-1 moi nhat;
//    gia tri chua xac dinh (chua du lich su khoi dong) = -1). Dung de tim thoi diem dieu kien "erh [>|<] gia tri" bat dau dung.
//==================================================================
bool AptRsiEmaSeries(const double &src[], const int m, const int p, double &ser[])
  {
   ArrayResize(ser, m);
   for(int t = 0; t < m; t++)
      ser[t] = -1.0;
   if(p < 2 || m < 2 * p + 1)
      return false;

   double ag = 0.0, al = 0.0;
   for(int t = 1; t <= p; t++)
     {
      double d0 = src[t] - src[t - 1];
      if(d0 > 0.0)
         ag += d0;
      else
         al -= d0;
     }
   ag /= p;
   al /= p;

   const double alpha = 2.0 / (p + 1.0);
   double ema = 0.0, rsiSum = 0.0;
   int rsiCnt = 0;
   for(int t = p; t < m; t++)
     {
      if(t > p)
        {
         double d = src[t] - src[t - 1];
         double g = (d > 0.0) ? d : 0.0;
         double l = (d < 0.0) ? -d : 0.0;
         ag = (ag * (p - 1) + g) / p;
         al = (al * (p - 1) + l) / p;
        }
      double rsi;
      if(al <= 0.0)
         rsi = (ag > 0.0) ? 100.0 : 50.0;
      else
         rsi = 100.0 - 100.0 / (1.0 + ag / al);

      rsiCnt++;
      if(rsiCnt <= p)
        {
         rsiSum += rsi;
         if(rsiCnt == p)
           {
            ema = rsiSum / p;
            ser[t] = ema;
           }
        }
      else
        {
         ema = ema + alpha * (rsi - ema);
         ser[t] = ema;
        }
     }
   return true;
  }

ENUM_TIMEFRAMES g_aptErCacheTf[32];
datetime        g_aptErCacheT0[32];
int             g_aptErCacheP [32];
string          g_aptErCacheStr[32];
int             g_aptErCacheCnt = 0;

bool AptErhErlStr(const ENUM_TIMEFRAMES tf, string &outStr)
  {
   outStr = "";
   int p = g_aptBrkDBars;
   if(p < 2)   p = 2;
   if(p > 500) p = 500;

   datetime t0 = iTime(_Symbol, tf, 0);
   int slot = -1;
   for(int c = 0; c < g_aptErCacheCnt; c++)
     {
      if(g_aptErCacheTf[c] == tf)
        {
         slot = c;
         break;
        }
     }
   if(slot >= 0 && t0 > 0 && g_aptErCacheT0[slot] == t0 && g_aptErCacheP[slot] == p)
     {
      outStr = g_aptErCacheStr[slot];
      return (outStr != "");
     }

   int bars = Bars(_Symbol, tf);
   int m = 4 * p + 1;
   if(m > bars - p - 1)
      m = bars - p - 1;

   bool ok = false;
   string res = "";
   if(m >= 2 * p + 1)
     {
      int cnt = p + m - 1;
      double   hi[], lo[];
      ArraySetAsSeries(hi, false);
      ArraySetAsSeries(lo, false);
        if(CopyHigh(_Symbol, tf, 1, cnt, hi) == cnt && CopyLow(_Symbol, tf, 1, cnt, lo) == cnt)
        {
         double hhS[], llS[];
         int    dqH[], dqL[];
         ArrayResize(hhS, m);
         ArrayResize(llS, m);
         ArrayResize(dqH, cnt);
         ArrayResize(dqL, cnt);
         int hH = 0, tH = 0, hL = 0, tL = 0;
         for(int j = 0; j < cnt; j++)
           {
            while(tH > hH && hi[dqH[tH - 1]] <= hi[j])
               tH--;
            dqH[tH++] = j;
            while(dqH[hH] <= j - p)
               hH++;
            while(tL > hL && lo[dqL[tL - 1]] >= lo[j])
               tL--;
            dqL[tL++] = j;
            while(dqL[hL] <= j - p)
               hL++;
            if(j >= p - 1)
              {
               hhS[j - p + 1] = hi[dqH[hH]];
               llS[j - p + 1] = lo[dqL[hL]];
              }
           }
         double erh = 0.0, erl = 0.0, erhP = 0.0, erlP = 0.0;
         double erhS[];
         bool okH = AptRsiEmaSeries(hhS, m, p, erhS);
         if(okH)
           {
            erh  = erhS[m - 1];
            erhP = erhS[m - 2];
           }
         if(okH && AptRsiEmaLast(llS, m, p, erl, erlP))
           {
            long dh = (long)MathRound(erh - erhP);
            long dl = (long)MathRound(erl - erlP);
            res = IntegerToString((long)MathRound(erh)) + "/" + ((dh > 0) ? "+" : "") + IntegerToString(dh) + " "
                + IntegerToString((long)MathRound(erl)) + "/" + ((dl > 0) ? "+" : "") + IntegerToString(dl);
            ok = true;
           }
        }
     }

   if(t0 > 0)
     {
      if(slot < 0 && g_aptErCacheCnt < 32)
         slot = g_aptErCacheCnt++;
      if(slot >= 0)
        {
         g_aptErCacheTf[slot]  = tf;
         g_aptErCacheT0[slot]  = t0;
         g_aptErCacheP [slot]  = p;
         g_aptErCacheStr[slot] = ok ? res : "";
        }
     }
   outStr = ok ? res : "";
   return ok;
  }

//==================================================================
//  AptBrkStreakClosedBuild: tinh (va cache) cho MOT khung tf hai bo dem cac nen DA DONG lien tiep (k = 1, 2, ...) tinh lui ve qua khu:
//    g_aptBrkStrkHi[idx] = so nen lien tiep co brkD > 90;  g_aptBrkStrkLo[idx] = so nen lien tiep co brkD < 10  (brkD = AptBrkDAt(tf,k)).
//  - idx: chi so cua tf trong g_tfList (0..13) - noi goi truyen thang bien dem cua vong lap.
//  - Thieu du lieu kenh (AptBrkDAt that bai) -> dung vong tai do, lay phan da dem duoc. Toi da APT_BRK_STREAK_MAX nen.
//  - Khoa cache: g_aptBrkStrkBarT[idx] = iTime(tf,0) (moi nen tinh 1 lan); g_aptBrkStrkSide[idx] = 1 la co "cache hop le" (0 = chua hop le).
//  Chi doc gia: khong tao object.
//==================================================================
void AptBrkStreakClosedBuild(const int idx, const ENUM_TIMEFRAMES tf)
  {
   if(idx < 0 || idx >= APT_BRK_STREAK_TF_COUNT)
      return;

   datetime t0 = iTime(_Symbol, tf, 0);
   if(t0 <= 0)
     {
      g_aptBrkStrkSide[idx] = 0;
      g_aptBrkStrkHi  [idx] = 0;
      g_aptBrkStrkLo  [idx] = 0;
      return;
     }

   //--- cache con hieu luc: van dang o trong CUNG mot nen cua khung tf
   if(g_aptBrkStrkBarT[idx] == t0 && g_aptBrkStrkSide[idx] != 0)
      return;

   // Dem 2 chuoi nen DA DONG (k = 1, 2, ...) cung luc: nen co brkD > 90 va nen co brkD < 10.
   //   Moi chuoi dung ngay khi gap nen khong thoa. Thieu du lieu kenh -> dung vong (khong doan).
   int hiCnt = 0, loCnt = 0;
   bool hiAlive = true, loAlive = true;
   for(int k = 1; k <= APT_BRK_STREAK_MAX; k++)
     {
      int brkK2 = 0;
      if(!AptBrkDAt(tf, k, brkK2))
         break;
      if(hiAlive)
        {
         if(brkK2 > 90) hiCnt++;
         else           hiAlive = false;
        }
      if(loAlive)
        {
         if(brkK2 < 10) loCnt++;
         else           loAlive = false;
        }
      if(!hiAlive && !loAlive)
         break;
     }
   g_aptBrkStrkHi  [idx] = hiCnt;
   g_aptBrkStrkLo  [idx] = loCnt;
   g_aptBrkStrkSide[idx] = 1;   // co "cache hop le"
   g_aptBrkStrkBarT[idx] = t0;
  }

//==================================================================
//  AptBrkStreakCount: <streak> trong ngoac cua nhan brkD = so nen LIEN TIEP (gom ca nen hien tai, shift 0) co brkD o vung cuc tri:
//    brkNow >= 50 -> so nen lien tiep co brkD > 90 ; brkNow < 50 -> so nen lien tiep co brkD < 10. Nen hien tai khong thoa nguong -> 0. Toi da APT_BRK_STREAK_MAX.
//  brkNow = chinh con so brkD dang in tren nhan - truyen vao de KHONG tinh lai, bao dam so trong ngoac luon khop voi so ben ngoai.
//  hoac thieu du lieu lich su -> tra 1.
//==================================================================
int AptBrkStreakCount(const int idx, const ENUM_TIMEFRAMES tf, const int brkNow)
  {
   if(idx < 0 || idx >= APT_BRK_STREAK_TF_COUNT)
      return 1;

   AptBrkStreakClosedBuild(idx, tf);

   int tot = 0;
   if(brkNow >= 50)
     {
      if(brkNow > 90)
         tot = g_aptBrkStrkHi[idx] + 1;
     }
   else
     {
      if(brkNow < 10)
         tot = g_aptBrkStrkLo[idx] + 1;
     }
   if(tot > APT_BRK_STREAK_MAX)
      tot = APT_BRK_STREAK_MAX;
   return tot;
  }

//==================================================================
//  AptChanHL / AptChanDir: helper cho AptChanStackCount().
//    AptChanHL  : HH / LL cua kenh thu k = P nen LIEN KE khong chong nhau, shift k*P .. (k+1)*P-1 (k = 0 gom ca nen dang chay).
//    AptChanDir : so sanh kenh MOI (hhN, llN) voi kenh CU (hhO, llO): +1 = kenh moi cao hon CA dinh LAN day, -1 = thap hon ca hai, 0 = khong chong.
//==================================================================
bool AptChanHL(const ENUM_TIMEFRAMES tf, const int k, const int P, double &hh, double &ll)
  {
   hh = 0.0;
   ll = 0.0;
   int ih = iHighest(_Symbol, tf, MODE_HIGH, P, k * P);
   int il = iLowest (_Symbol, tf, MODE_LOW , P, k * P);
   if(ih < 0 || il < 0)
      return false;
   hh = iHigh(_Symbol, tf, ih);
   ll = iLow (_Symbol, tf, il);
   return (hh > ll && ll > 0.0);
  }

int AptChanDir(const double hhN, const double llN, const double hhO, const double llO)
  {
   if(hhN > hhO && llN > llO)
      return 1;
   if(hhN < hhO && llN < llO)
      return -1;
   return 0;
  }

//==================================================================
//  AptChanStackCount: chuoi KENH CHONG KENH lien tiep GAN NHAT, ket thuc o kenh cuoi (kenh moi nhat) co chua nen hien tai.
//    Kenh k (k = 0 moi nhat) = P nen LIEN KE khong chong nhau: shift k*P .. (k+1)*P-1, P = g_aptBrkDBars (nut B<n>, kep 2..500).
//    Kenh 0 GOM nen dang chay (shift 0) -> HH/LL kenh cuoi doi theo tung tick; kenh k >= 1 chi gom nen DA DONG.
//    Tang chong tang: HH[k] > HH[k+1] VA LL[k] > LL[k+1]. Giam chong giam: HH[k] < HH[k+1] VA LL[k] < LL[k+1].
//    outCnt = so KENH trong chuoi (>= 2), duong = tang, am = giam; 0 = kenh cuoi khong chong len / xuong kenh truoc.
//    Khong gioi han so kenh: di lui den khi dut dieu kien hoac het lich su. Chi tim chuoi gan nhat (neo o kenh 0), khong tim chuoi cu.
//    Kenh k >= 1 chi doi khi sang nen moi -> cache theo (khung idx, open time nen shift 0, P); moi tick chi tinh lai kenh 0.
//    Thieu du lieu (< 2P nen, iHighest/iLowest loi) -> false, noi goi bo qua.
//  Chi doc gia: khong tao object.
//==================================================================
bool AptChanStackCount(const int idx, const ENUM_TIMEFRAMES tf, int &outCnt)
  {
   outCnt = 0;
   if(idx < 0 || idx >= APT_BRK_STREAK_TF_COUNT)
      return false;

   const int P = (g_aptBrkDBars < 2) ? 2 : ((g_aptBrkDBars > 500) ? 500 : g_aptBrkDBars);
   const int bars = Bars(_Symbol, tf);
   if(bars < 2 * P)
      return false;

   datetime t0 = iTime(_Symbol, tf, 0);
   if(t0 <= 0)
      return false;

   static datetime s_cBar [APT_BRK_STREAK_TF_COUNT];
   static int      s_cP   [APT_BRK_STREAK_TF_COUNT];
   static double   s_cHH1 [APT_BRK_STREAK_TF_COUNT];   // HH kenh 1
   static double   s_cLL1 [APT_BRK_STREAK_TF_COUNT];   // LL kenh 1
   static int      s_cDir1[APT_BRK_STREAK_TF_COUNT];   // chieu cua cap (kenh 1, kenh 2): +1 / -1 / 0
   static int      s_cRun1[APT_BRK_STREAK_TF_COUNT];   // so cap lien tiep CUNG chieu, bat dau tu cap (kenh 1, kenh 2)

   if(s_cBar[idx] != t0 || s_cP[idx] != P)
     {
      s_cBar[idx] = 0;   // tinh that bai -> khong cache, lan sau thu lai
      double hhA, llA, hhB, llB;
      if(!AptChanHL(tf, 1, P, hhA, llA))
         return false;
      s_cHH1[idx] = hhA;
      s_cLL1[idx] = llA;

      int dir1 = 0, run1 = 0;
      if(bars >= 3 * P && AptChanHL(tf, 2, P, hhB, llB))
        {
         dir1 = AptChanDir(hhA, llA, hhB, llB);
         if(dir1 != 0)
           {
            run1 = 1;
            for(int k = 2; bars >= (k + 2) * P; k++)   // con du nen cho kenh k+1
              {
               hhA = hhB;
               llA = llB;
               if(!AptChanHL(tf, k + 1, P, hhB, llB))
                  break;
               if(AptChanDir(hhA, llA, hhB, llB) != dir1)
                  break;
               run1++;
              }
           }
        }
      s_cDir1[idx] = dir1;
      s_cRun1[idx] = run1;
      s_cP   [idx] = P;
      s_cBar [idx] = t0;
     }

   double hh0, ll0;
   if(!AptChanHL(tf, 0, P, hh0, ll0))
      return false;
   int dir0 = AptChanDir(hh0, ll0, s_cHH1[idx], s_cLL1[idx]);
   if(dir0 == 0)
      return true;

   outCnt = dir0 * ((dir0 == s_cDir1[idx]) ? (2 + s_cRun1[idx]) : 2);
   return true;
  }

//==================================================================
//  AptBrkAccSecToStr: in so giay cong don cua bo dem Up / Dn cho gon:
//    secs <  60  -> "<so giay>s"            (30  -> "30s")
//    secs >= 60  -> "<so phut>.<giay le>s"  (90  -> "1.30s", 605 -> "10.05s")
//  Phan giay le luon 2 chu so de cac nhan thang hang. Ham thuan tuy doi so -> chuoi.
//==================================================================
string AptBrkAccSecToStr(long secs)
  {
   if(secs < 0)
      secs = 0;
   if(secs < 60)
      return(IntegerToString((int)secs) + "s");

   long _m = secs / 60;
   long _s = secs % 60;
   return(IntegerToString((int)_m) + "." + StringFormat("%02d",(int)_s) + "s");
  }

//==================================================================
//  AptFindTfIndex: chi so cua tf trong g_tfList (-1 neu khong co).
//==================================================================
int AptFindTfIndex(const ENUM_TIMEFRAMES tf)
  {
   for(int k=0; k<14; k++)
      if(g_tfList[k] == tf)
         return(k);
   return(-1);
  }

//==================================================================
//  HELPER - format thoi gian con lai den nen moi
//  5m: van hien thi giay
//  15m tro len: chi gio + phut (ngan gon)
//==================================================================
string FormatRemain(const ENUM_TIMEFRAMES tf)
  {
   datetime barTime = iTime(_Symbol, tf, 0);
   if(barTime <= 0)
      return("--");

   int periodSec = PeriodSeconds(tf);
   datetime nextBar = barTime + periodSec;
   int remain = (int)(nextBar - TimeCurrent());
   if(remain < 0)
      remain = 0;

   // 15m tro len: chi hien gio + phut
   if(periodSec >= 900)   // 15m = 900s
     {
      int h = remain / 3600;
      int m = (remain % 3600) / 60;
      if(h > 0)
         return StringFormat("%dh%02dm", h, m);
      else
         return StringFormat("%dm", m);
     }

   // 5m: van hien thi giay
   if(remain >= 60)
     {
      int m = remain / 60;
      int s = remain % 60;
      return StringFormat("%d.%ds", m, s);
     }
   else
     {
      return StringFormat("%ds", remain);
     }
  }

//==================================================================
//  AptRv2BuildAll14: tinh RV2 (shift 0) cua 14 khung g_tfList vao g_aptRv2All[] (+ co Ok).
//    RV1(tf)[k] = VWAP (gia dien hinh (H+L+C)/3, trong so tick volume) cua nB nen M1 ket thuc tai moc nen tf thu k:
//                 k=0 -> TimeCurrent(); k>0 -> GIO DONG nen tf thu k (iTime(tf,k)+PeriodSeconds(tf)-1), cung RvwapAtBarTime() cua WPR_rVWAP_Osc.mq5
//                 (xem Wpr9BuildRv1Series).
//    RV2(tf)    = EMA(g_aptRv2EmaPeriod) tren chuoi RV1 do, seed = SMA cac mau cu nhat, warmup = emaP*4.
//  Dung hai helper AptGetNBars() va AptFindM1Shift(). Doc toi da 200000 nen M1; RV2 can avail >= warm + 2.
//  Khung nao thieu du lieu M1 (thuong 1w, 1nm) -> Ok = false, noi goi bo qua (nhan hien "-").
//  Ham chi doc gia va ghi hai mang toan cuc noi tren: khong tao object.
//==================================================================
void AptRv2BuildAll14()
  {
   for(int z=0; z<14; z++)
     {
      g_aptRv2All[z]   = 0.0;
      g_aptRv2AllOk[z] = false;
     }

   // Chu ky EMA ra RV2 lay tu RV2 EMA UI
   int emaP = g_aptRv2EmaPeriod;
   if(emaP < 1)
      emaP = 1;
   int warm = emaP*4;
   if(warm < emaP + 2)
      warm = emaP + 2;
   int pts = warm + 2;      // chi can ema[0] nen khong lay du thua diem

   //--- so nen M1 can lay = gia tri LON NHAT trong 14 khung, kep bang tran
   int need = 0;
   for(int i=0; i<14; i++)
     {
      int nBi = AptGetNBars(g_tfList[i]);
      int rq  = (pts + warm + 1)*nBi;
      if(rq > need)
         need = rq;
     }
   if(need > 200000)
      need = 200000;
   if(need < 2)
      return;

   //--- doc du lieu M1 MOT LAN cho ca 14 khung
   double   hi[], lo[], cl[];
   long     tv[];
   datetime tm[];
   ArraySetAsSeries(hi, true);
   ArraySetAsSeries(lo, true);
   ArraySetAsSeries(cl, true);
   ArraySetAsSeries(tv, true);
   ArraySetAsSeries(tm, true);

   int cpH = CopyHigh      (_Symbol, PERIOD_M1, 0, need, hi);
   int cpL = CopyLow       (_Symbol, PERIOD_M1, 0, need, lo);
   int cpC = CopyClose     (_Symbol, PERIOD_M1, 0, need, cl);
   int cpV = CopyTickVolume(_Symbol, PERIOD_M1, 0, need, tv);
   int cpT = CopyTime      (_Symbol, PERIOD_M1, 0, need, tm);
   int got = MathMin(MathMin(MathMin(cpH, cpL), MathMin(cpC, cpV)), cpT);
   if(got < 2)
      return;

   //--- prefix-sum tren du lieu M1
   double cumTPV[], cumVol[];
   ArrayResize(cumTPV, got + 1);
   ArrayResize(cumVol, got + 1);
   cumTPV[got] = 0.0;
   cumVol[got] = 0.0;
   for(int s = got - 1; s >= 0; s--)
     {
      double tp = (hi[s] + lo[s] + cl[s]) / 3.0;
      double v  = (double)tv[s];
      cumTPV[s] = cumTPV[s + 1] + tp * v;
      cumVol[s] = cumVol[s + 1] + v;
     }

   for(int i=0; i<14; i++)
     {
      ENUM_TIMEFRAMES tf = g_tfList[i];
      int nB = AptGetNBars(tf);

      datetime tmTF[];
      ArraySetAsSeries(tmTF, true);
      int gotTF = CopyTime(_Symbol, tf, 0, pts + warm, tmTF);
      if(gotTF < 2)
         continue;

      double rv[];
      ArrayResize(rv, gotTF);
      int avail = 0;
      for(int k=0; k<gotTF; k++)
        {
         // neo nen lich su (k>0) tai GIO DONG (tmTF[k]+PeriodSeconds(tf)-1) thay vi GIO MO - dung Y HET RvwapAtBarTime() cua WPR_rVWAP_Osc.mq5; giai thich day du tai chu thich Wpr9BuildRv1Series().
         datetime atTime = (k == 0) ? TimeCurrent() : (tmTF[k] + (datetime)PeriodSeconds(tf) - 1);
         int m1sh = AptFindM1Shift(tm, got, atTime);
         if(m1sh < 0 || m1sh + nB >= got)
            break;

         double wVol = cumVol[m1sh] - cumVol[m1sh + nB];
         double v    = (wVol > 0.0) ? (cumTPV[m1sh] - cumTPV[m1sh + nB]) / wVol : 0.0;
         if(v <= 0.0)
            break;

         rv[k] = v;
         avail = k + 1;
        }

      //--- RV2 = EMA(emaP) cua rv[], seed = SMA(emaP) cac mau cu nhat
      if(avail < warm + 2)
         continue;

      double ema[];
      ArrayResize(ema, avail);
      double alpha   = 2.0 / (emaP + 1.0);
      double seedSum = 0.0;
      for(int s = avail - 1; s >= avail - emaP; s--)
         seedSum += rv[s];
      double emaVal = seedSum / (double)emaP;
      for(int s = avail - 1; s >= avail - emaP; s--)
         ema[s] = 0.0;   // khong dung (pham vi seed)
      for(int s = avail - emaP - 1; s >= 0; s--)
        {
         emaVal = alpha * rv[s] + (1.0 - alpha) * emaVal;
         ema[s] = emaVal;
        }

      if(ema[0] <= 0.0)
         continue;

      g_aptRv2All[i]   = ema[0];
      g_aptRv2AllOk[i] = true;
     }
  }

//==================================================================
//  AptTickPressure: TSF + LAM tren cua so nB nen M1 ket thuc tai m1sh0. Dung lai cl[] / tv[] da copy.
//  TSF = dong tick co dau, chuan hoa [-1,+1]. LAM = log2(lambda_gan / lambda_cua_so).
//  Doc cl[s+1] nen can m1sh0 + nB < got.
//==================================================================
bool AptTickPressure(const int nB, const int m1sh0, const int got,
                     const double &cl[], const long &tv[],
                     double &outTsf, double &outLam)
  {
   outTsf = 0.0;
   outLam = 0.0;
   if(nB < 5 || m1sh0 + nB >= got)
      return(false);

   int kRec = nB/8;
   if(kRec < 3)
      kRec = 3;
   if(kRec > 15)
      kRec = 15;

   double num=0.0, den=0.0;
   double pathW=0.0, volW=0.0;
   double pathR=0.0, volR=0.0;

   for(int s = m1sh0; s < m1sh0 + nB; s++)
     {
      double v  = (double)tv[s];
      double dP = cl[s] - cl[s+1];
      if(v <= 0.0)
         continue;

      if(dP > 0.0)
         num += v;
      else
         if(dP < 0.0)
            num -= v;
      den += v;

      double ad = MathAbs(dP);
      pathW += ad;
      volW  += v;
      if(s < m1sh0 + kRec)
        {
         pathR += ad;
         volR  += v;
        }
     }

   if(den <= 0.0 || volW <= 0.0 || volR <= 0.0)
      return(false);
   outTsf = num/den;

   double lamW = pathW/volW;
   double lamR = pathR/volR;
   if(lamW <= 0.0 || lamR <= 0.0)
      return(false);

   outLam = MathLog(lamR/lamW) / MathLog(2.0);
   return(true);
  }

//==================================================================
//  AptTickPressureCalcSlow: TSF+LAM rieng cho W1/MN1, tinh tren dung cua so nen cua khung do (AptGetNBars(tf)),
//  chi tinh lai khi co nen MOI cua chinh khung do (theo iTime(_Symbol,tf,0)) thay vi moi lan OnTimer.
//  Chua du lich su M1 (CopyX tra ve thieu) -> khong chot cache, lan goi ke tiep thu lai.
//==================================================================
datetime g_aptLamSlowBarT[2] = {0, 0};     // 0=W1, 1=MN1 - thoi diem nen dang cache
double   g_aptLamSlowTsf[2]  = {0.0, 0.0};
double   g_aptLamSlowLam[2]  = {0.0, 0.0};
bool     g_aptLamSlowOk[2]   = {false, false};

bool AptTickPressureCalcSlow(const ENUM_TIMEFRAMES tf, double &outTsf, double &outLam)
  {
   outTsf = 0.0;
   outLam = 0.0;

   int idx = (tf == PERIOD_W1) ? 0 : (tf == PERIOD_MN1 ? 1 : -1);
   if(idx < 0)
      return false;

   datetime curBarT = iTime(_Symbol, tf, 0);
   if(curBarT != 0 && curBarT == g_aptLamSlowBarT[idx] && g_aptLamSlowOk[idx])
     {
      outTsf = g_aptLamSlowTsf[idx];
      outLam = g_aptLamSlowLam[idx];
      return true;
     }

   int nB = AptGetNBars(tf);
   if(nB < 5)
      nB = 5;

   double cl[];
   long   tv[];
   ArraySetAsSeries(cl, true);
   ArraySetAsSeries(tv, true);
   int need = nB + 2;
   int cpC  = CopyClose     (_Symbol, PERIOD_M1, 0, need, cl);
   int cpV  = CopyTickVolume(_Symbol, PERIOD_M1, 0, need, tv);
   int got  = MathMin(cpC, cpV);

   double tsfTmp = 0.0, lamTmp = 0.0;
   if(!AptTickPressure(nB, 0, got, cl, tv, tsfTmp, lamTmp))
      return false;

   g_aptLamSlowBarT[idx] = curBarT;
   g_aptLamSlowTsf[idx]  = tsfTmp;
   g_aptLamSlowLam[idx]  = lamTmp;
   g_aptLamSlowOk[idx]   = true;

   outTsf = tsfTmp;
   outLam = lamTmp;
   return true;
  }

bool AptTickPressureCalc(double &outTsf, double &outLam)
  {
   outTsf = 0.0;
   outLam = 0.0;

   // scanTF la W1/MN1: dung cua so that + cache theo nen cua khung (AptTickPressureCalcSlow).
   if(_Period == PERIOD_W1 || _Period == PERIOD_MN1)
      return(AptTickPressureCalcSlow(_Period, outTsf, outLam));

   // Toi day _Period khong phai W1/MN1 nen nB toi da la cua D1 = 1440 nen M1 - nhe, khong can cache.
   int nB = AptGetNBars(_Period);
   if(nB < 5)
      nB = AptGetNBars(_Period);
   if(nB < 5)
      nB = 5;

   double cl[];
   long   tv[];
   ArraySetAsSeries(cl, true);
   ArraySetAsSeries(tv, true);
   int need = nB + 2;
   int cpC  = CopyClose     (_Symbol, PERIOD_M1, 0, need, cl);
   int cpV  = CopyTickVolume(_Symbol, PERIOD_M1, 0, need, tv);
   int got  = MathMin(cpC, cpV);

   return(AptTickPressure(nB, 0, got, cl, tv, outTsf, outLam));
  }

//==================================================================
//  CMF (C) va VPIN (V) cho hang T/L (SYS3), tinh tren cung cua so nen M1 voi AptTickPressureCalc()
//  (nB = AptGetNBars(_Period); W1/MN1 dung cua so that cua khung va cache theo nen khung, giong AptTickPressureCalcSlow()).
//  - CMF (Chaikin Money Flow) = SUM(CLV_k * V_k) / SUM(V_k), mien [-1,+1]
//      CLV_k = ((C-L) - (H-C)) / (H-L) cua nen M1 k (H==L -> CLV = 0).
//  - VPIN (Bulk Volume Classification tren nen M1):
//      sigma  = do lech chuan cua dP = C[k]-C[k+1] tren cua so
//      ty le mua cua nen k = Phi(dP/sigma)  (Phi = phan phoi chuan tich luy)
//      chia tong tick volume cua so thanh APT_VPIN_BUCKETS gio CUNG volume (it nen hon so gio -> so gio = so nen),
//      rai volume tung nen (cu -> moi) vao cac gio, VPIN = SUM|Vmua - Vban| cac gio / tong volume, mien [0,1].
//      Chieu = dau cua SUM(Vmua - Vban): >0 "▲", <0 "▼", =0 " ".
//  Hang so noi bo. Khong tao/xoa object.
//==================================================================
#define APT_VPIN_BUCKETS 50

double AptNormCdf(const double x)
  {
   // Xap xi Abramowitz-Stegun 7.1.26 cho erf (sai so < 1.5e-7)
   double z = MathAbs(x) / MathSqrt(2.0);
   double t = 1.0 / (1.0 + 0.3275911 * z);
   double y = 1.0 - (((((1.061405429 * t - 1.453152027) * t) + 1.421413741) * t - 0.284496736) * t + 0.254829592) * t * MathExp(-z * z);
   return((x >= 0.0) ? 0.5 * (1.0 + y) : 0.5 * (1.0 - y));
  }

bool AptCmfVpinCore(const int nB, const int got,
                    const double &hi[], const double &lo[], const double &cl[], const long &tv[],
                    double &outCmf, bool &outCmfOk,
                    double &outVpin, bool &outVpinOk, int &outDir)
  {
   outCmf    = 0.0;
   outCmfOk  = false;
   outVpin   = 0.0;
   outVpinOk = false;
   outDir    = 0;
   if(nB < 5 || nB >= got)
      return(false);
   if(ArraySize(hi) < nB || ArraySize(lo) < nB)
      return(false);

   //--- CMF
   double num = 0.0, den = 0.0;
   for(int s = 0; s < nB; s++)
     {
      double v = (double)tv[s];
      if(v <= 0.0)
         continue;
      double rg  = hi[s] - lo[s];
      double clv = (rg > 0.0) ? ((cl[s] - lo[s]) - (hi[s] - cl[s])) / rg : 0.0;
      num += clv * v;
      den += v;
     }
   if(den <= 0.0)
      return(false);
   outCmf   = num / den;
   outCmfOk = true;

   //--- sigma cua dP tren cua so
   double sum = 0.0, sum2 = 0.0;
   int    cnt = 0;
   for(int s = 0; s < nB; s++)
     {
      double dP = cl[s] - cl[s+1];
      sum  += dP;
      sum2 += dP * dP;
      cnt++;
     }
   if(cnt < 2)
      return(true);
   double mean = sum / (double)cnt;
   double var  = sum2 / (double)cnt - mean * mean;
   if(var <= 0.0)
      return(true);
   double sig = MathSqrt(var);

   //--- VPIN: rai volume (cu -> moi) vao cac gio cung volume
   int nBk = APT_VPIN_BUCKETS;
   if(nBk > nB)
      nBk = nB;
   double vb     = den / (double)nBk;
   double eps    = vb * 1e-9;
   double bBuy   = 0.0, bSell = 0.0, bFill = 0.0;
   double sumAbs = 0.0, totDelta = 0.0;
   for(int s = nB - 1; s >= 0; s--)
     {
      double v = (double)tv[s];
      if(v <= 0.0)
         continue;
      double fb  = AptNormCdf((cl[s] - cl[s+1]) / sig);
      double rem = v;
      while(rem > 0.0)
        {
         double room = vb - bFill;
         double take = MathMin(rem, room);
         if(take > 0.0)
           {
            bBuy  += take * fb;
            bSell += take * (1.0 - fb);
            bFill += take;
            rem   -= take;
           }
         if(vb - bFill <= eps)
           {
            sumAbs   += MathAbs(bBuy - bSell);
            totDelta += (bBuy - bSell);
            bBuy  = 0.0;
            bSell = 0.0;
            bFill = 0.0;
           }
        }
     }
   if(bFill > 0.0)
     {
      sumAbs   += MathAbs(bBuy - bSell);
      totDelta += (bBuy - bSell);
     }

   outVpin   = sumAbs / den;
   outVpinOk = true;
   outDir    = (totDelta > 0.0) ? 1 : ((totDelta < 0.0) ? -1 : 0);
   return(true);
  }

datetime g_aptCvSlowBarT[2] = {0, 0};      // 0=W1, 1=MN1 - thoi diem nen dang cache
double   g_aptCvSlowCmf[2]  = {0.0, 0.0};
bool     g_aptCvSlowCmfOk[2]  = {false, false};
double   g_aptCvSlowVpin[2] = {0.0, 0.0};
bool     g_aptCvSlowVpinOk[2] = {false, false};
int      g_aptCvSlowDir[2]  = {0, 0};

void AptCmfVpinCalc(double &outCmf, bool &outCmfOk, double &outVpin, bool &outVpinOk, int &outDir)
  {
   outCmf    = 0.0;
   outCmfOk  = false;
   outVpin   = 0.0;
   outVpinOk = false;
   outDir    = 0;

   int slowIdx = (_Period == PERIOD_W1) ? 0 : (_Period == PERIOD_MN1 ? 1 : -1);
   datetime curBarT = 0;
   int nB = 0;
   if(slowIdx >= 0)
     {
      curBarT = iTime(_Symbol, _Period, 0);
      if(curBarT != 0 && curBarT == g_aptCvSlowBarT[slowIdx] && g_aptCvSlowCmfOk[slowIdx])
        {
         outCmf    = g_aptCvSlowCmf[slowIdx];
         outCmfOk  = g_aptCvSlowCmfOk[slowIdx];
         outVpin   = g_aptCvSlowVpin[slowIdx];
         outVpinOk = g_aptCvSlowVpinOk[slowIdx];
         outDir    = g_aptCvSlowDir[slowIdx];
         return;
        }
      nB = AptGetNBars(_Period);
      if(nB < 5)
         nB = 5;
     }
   else
     {
      nB = AptGetNBars(_Period);
      if(nB < 5)
         nB = AptGetNBars(_Period);
      if(nB < 5)
         nB = 5;
     }

   double hi[], lo[], cl[];
   long   tv[];
   ArraySetAsSeries(hi, true);
   ArraySetAsSeries(lo, true);
   ArraySetAsSeries(cl, true);
   ArraySetAsSeries(tv, true);
   int need = nB + 2;
   int cpH  = CopyHigh      (_Symbol, PERIOD_M1, 0, need, hi);
   int cpL  = CopyLow       (_Symbol, PERIOD_M1, 0, need, lo);
   int cpC  = CopyClose     (_Symbol, PERIOD_M1, 0, need, cl);
   int cpV  = CopyTickVolume(_Symbol, PERIOD_M1, 0, need, tv);
   int got  = MathMin(MathMin(cpH, cpL), MathMin(cpC, cpV));

   AptCmfVpinCore(nB, got, hi, lo, cl, tv, outCmf, outCmfOk, outVpin, outVpinOk, outDir);

   if(slowIdx >= 0 && outCmfOk)
     {
      g_aptCvSlowBarT[slowIdx]   = curBarT;
      g_aptCvSlowCmf[slowIdx]    = outCmf;
      g_aptCvSlowCmfOk[slowIdx]  = outCmfOk;
      g_aptCvSlowVpin[slowIdx]   = outVpin;
      g_aptCvSlowVpinOk[slowIdx] = outVpinOk;
      g_aptCvSlowDir[slowIdx]    = outDir;
     }
  }

//==================================================================
//  TINH LOT / TIEN / R:R / ETA cho setup hien tai
//==================================================================
void RecalcMoney(SSetup &s)
  {
   SSpmScopeTimer __spmTimer("RecalcMoney");
   if(!s.valid)
      return;

   double slDist = MathAbs(s.entry - s.sl);
   double tpDist = MathAbs(s.tp    - s.entry);
   if(slDist<=0.0)
     {
      s.valid = false;
      s.note  = "SL trung Entry";
      return;
     }

   s.slPts = slDist/_Point;
   s.tpPts = tpDist/_Point;
   s.rr    = tpDist/slDist;

   double lossPerLot = MoneyPerLot(slDist);
   double want = InpUseFixedMoney ? InpFixedRisk
                 : AccountInfoDouble(ACCOUNT_BALANCE)*InpRiskPercent/100.0;
   if(want<=0.0)
      want = 100.0;

   double lots = (lossPerLot>0.0) ? want/lossPerLot : 0.0;
   s.lots        = NormalizeLots(lots);
   s.riskMoney   = s.lots*lossPerLot;
   s.rewardMoney = s.lots*MoneyPerLot(tpDist);

   double atr = (s.atr>0.0) ? s.atr : BufVal(g_hATR,1);
   double spd = MathMax(atr*InpSpeedFactor,_Point);
   int eta = (int)MathCeil(tpDist/spd);
   if(eta<1)
      eta=1;
   if(eta>1000)
      eta=1000;
   s.etaBars = eta;
   s.etaTime = iTime(_Symbol,_Period,0) + (datetime)((long)PeriodSeconds(_Period)*eta);
  }

//==================================================================
//  QUET CAU TRUC -> DUNG SETUP
//==================================================================
void BuildSetup()
  {
   SSetup s;
   s.valid=false;
   s.dir=0;
   s.entry=0;
   s.sl=0;
   s.tp=0;
   s.slPts=0;
   s.tpPts=0;
   s.rr=0;
   s.lots=0;
   s.riskMoney=0;
   s.rewardMoney=0;
   s.etaBars=0;
   s.etaTime=0;
   s.atr=0;
   s.note="";

   double atr = BufVal(g_hATR,1);
   if(atr<=0.0)
      atr = (iHigh(_Symbol,_Period,1)-iLow(_Symbol,_Period,1));
   if(atr<=0.0)
      atr = 10*_Point;
   s.atr = atr;

   // Vung neo (hiP / loP) do AptScanLevels() (quet swing dinh/day cua duong S1) tra ve.
   double hiP=0.0, loP=0.0;
   int    dirHint=0, fbDir=1;
   string scanNote="";
   if(!AptScanLevels(hiP,loP,dirHint,fbDir,scanNote))
     {
      s.note = scanNote;
      g_s = s;
      return;
     }

   //--- xac dinh chieu (Bias da khung co trong so)
   // Thu tu quyet dinh chieu: tin hieu chieu rieng cua quet (dirHint) duoc uu tien truoc bias.
   int dir = dirHint;
   if(dir==0 && InpUseBias)
      dir = CalcMultiTFBias();
   if(dir==0)
      dir = fbDir;

   if(InpMode==APT_AUTO_LONG)
      dir = 1;
   if(InpMode==APT_AUTO_SHORT)
      dir = -1;
   s.dir = dir;

   double leg = hiP - loP;
   double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   if(ask<=0.0)
      ask = iClose(_Symbol,_Period,0);
   if(bid<=0.0)
      bid = iClose(_Symbol,_Period,0);

   double entry=0.0, sl=0.0, tp=0.0;

   if(dir>0)
     {
      switch(InpEntryMode)
        {
         case ENTRY_MARKET:
            entry = ask;
            break;
         case ENTRY_PULLBACK:
            entry = hiP - leg*InpFiboEntry;
            break;
         case ENTRY_BREAKOUT:
            entry = hiP + atr*InpBreakBufATR;
            break;
        }
      sl = loP - atr*InpSLatrMult;
      if(entry<=sl)
         entry = sl + atr*0.5;

      switch(InpTPMode)
        {
         case TP_RR:
            tp = entry + (entry-sl)*InpRR;
            break;
         case TP_FIBOEXT:
            tp = loP + leg*InpFiboExt;
            break;
         case TP_STRUCT:
            if(!FindTargetSwing(true,entry+atr*0.5,InpSwingDepth,InpLookback,tp))
               tp = entry + (entry-sl)*InpRR;
            break;
        }
      if(tp<=entry)
         tp = entry + (entry-sl)*InpRR;
     }
   else
     {
      switch(InpEntryMode)
        {
         case ENTRY_MARKET:
            entry = bid;
            break;
         case ENTRY_PULLBACK:
            entry = loP + leg*InpFiboEntry;
            break;
         case ENTRY_BREAKOUT:
            entry = loP - atr*InpBreakBufATR;
            break;
        }
      sl = hiP + atr*InpSLatrMult;
      if(entry>=sl)
         entry = sl - atr*0.5;

      switch(InpTPMode)
        {
         case TP_RR:
            tp = entry - (sl-entry)*InpRR;
            break;
         case TP_FIBOEXT:
            tp = hiP - leg*InpFiboExt;
            break;
         case TP_STRUCT:
            if(!FindTargetSwing(false,entry-atr*0.5,InpSwingDepth,InpLookback,tp))
               tp = entry - (sl-entry)*InpRR;
            break;
        }
      if(tp>=entry)
         tp = entry - (sl-entry)*InpRR;
     }

   s.entry = NormalizeDouble(entry,_Digits);
   s.sl    = NormalizeDouble(sl,_Digits);
   s.tp    = NormalizeDouble(tp,_Digits);
   s.valid = true;
   s.note  = "OK";

   RecalcMoney(s);
   g_s = s;
   g_touchedE = false;
  }

//==================================================================
//  KHOI TAO SETUP MAC DINH CHO CHE DO MANUAL
//==================================================================
void BuildManualDefault()
  {
   double atr = BufVal(g_hATR,1);
   if(atr<=0.0)
      atr = 10*_Point;
   double px = iClose(_Symbol,_Period,0);
   g_s.valid = true;
   g_s.dir   = 1;
   g_s.atr   = atr;
   g_s.entry = NormalizeDouble(px,_Digits);
   g_s.sl    = NormalizeDouble(px-atr*1.5,_Digits);
   g_s.tp    = NormalizeDouble(px+atr*1.5*InpRR,_Digits);
   g_s.note  = "Manual";
   RecalcMoney(g_s);
  }

//==================================================================
//  OBJECT HELPERS
//==================================================================
void MakeTrend(const string name,const datetime t1,const double p1,
               const datetime t2,const double p2,const color clr,
               const int style,const int width)
  {
   if(ObjectFind(0,name)<0)
     {
      ObjectCreate(0,name,OBJ_TREND,0,t1,p1,t2,p2);
      ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
     }
   ObjectSetInteger(0,name,OBJPROP_TIME,0,t1);
   ObjectSetDouble(0,name,OBJPROP_PRICE,0,p1);
   ObjectSetInteger(0,name,OBJPROP_TIME,1,t2);
   ObjectSetDouble(0,name,OBJPROP_PRICE,1,p2);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(0,name,OBJPROP_STYLE,style);
   ObjectSetInteger(0,name,OBJPROP_WIDTH,width);
   ObjectSetInteger(0,name,OBJPROP_RAY_RIGHT,false);
   ObjectSetInteger(0,name,OBJPROP_BACK,false);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
  }

void MakeText(const string name,const datetime t,const double p,
              const string txt,const color clr,const int anchor)
  {
   if(ObjectFind(0,name)<0)
     {
      ObjectCreate(0,name,OBJ_TEXT,0,t,p);
      ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
     }
   ObjectSetInteger(0,name,OBJPROP_TIME,0,t);
   ObjectSetDouble(0,name,OBJPROP_PRICE,0,p);
   ObjectSetString(0,name,OBJPROP_TEXT,txt);
   ObjectSetString(0,name,OBJPROP_FONT,InpFontName);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,InpFontSize);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(0,name,OBJPROP_ANCHOR,anchor);
   ObjectSetInteger(0,name,OBJPROP_BACK,false);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
  }

void MakeLabel(const string name,const int x,const int y,
               const string txt,const color clr)
  {
   if(ObjectFind(0,name)<0)
     {
      ObjectCreate(0,name,OBJ_LABEL,0,0,0);
      ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
     }
   int anchor = (InpCorner==CORNER_RIGHT_UPPER || InpCorner==CORNER_RIGHT_LOWER)
                ? ANCHOR_RIGHT_UPPER : ANCHOR_LEFT_UPPER;
   ObjectSetInteger(0,name,OBJPROP_CORNER,InpCorner);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetString(0,name,OBJPROP_TEXT,txt);
   ObjectSetString(0,name,OBJPROP_FONT,InpFontName);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,InpFontSize);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(0,name,OBJPROP_ANCHOR,anchor);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_BACK,false);
  }

void MakePanelBG(const int x,const int y,const int w,const int h)
  {
   string name = PFX"PN_BG";
   if(ObjectFind(0,name)<0)
     {
      ObjectCreate(0,name,OBJ_RECTANGLE_LABEL,0,0,0);
      ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
     }
   ObjectSetInteger(0,name,OBJPROP_CORNER,InpCorner);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,w);
   ObjectSetInteger(0,name,OBJPROP_YSIZE,h);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,InpPanelBG);
   ObjectSetInteger(0,name,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,name,OBJPROP_COLOR,InpPanelBorder);
   ObjectSetInteger(0,name,OBJPROP_BACK,false);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
  }

//==================================================================
//  MAU THEO CHIEU: TANG = gold/orange, GIAM = trang
//==================================================================
color ColByDir(const bool up)
  {
   return(up ? InpColUp : InpColDown);
  }

//==================================================================
//  TRANG THAI SETUP
//==================================================================
string StatusText()
  {
   if(!g_s.valid)
      return("KHONG CO SETUP");
   double px = iClose(_Symbol,_Period,0);
   if(g_s.dir>0)
     {
      if(px>=g_s.tp)
         return("DA CHAM TP");
      if(px<=g_s.sl)
         return("DA CHAM SL");
      if(px<=g_s.entry)
         return("TRONG VUNG ENTRY");
      return("CHO GIA HOI VE ENTRY");
     }
   else
     {
      if(px<=g_s.tp)
         return("DA CHAM TP");
      if(px>=g_s.sl)
         return("DA CHAM SL");
      if(px>=g_s.entry)
         return("TRONG VUNG ENTRY");
      return("CHO GIA HOI LEN ENTRY");
     }
  }

//==================================================================
//  DrawBreakStats: khong ve nhan nao. Moi nhip nuoi du lieu dung chung:
//    g_rv1ValCache / g_aptRv2All ...
//    va cac bo dem giay g_aptBrkAccUp/Dn, UpA/DnA, UpB/DnB, UpC/DnC (14 khung g_tfList).
//  Dieu kien dem moi bo dem (moi khung, nen shift 0; khong du du lieu -> khong cong ben nao):
//    Up/Dn   : Up: diffavg2 > 0.1 | Dn: diffavg2 < -0.1   (diffavg2 = diffavg hien tai - diffavg giay truoc, xem DrawMidPriceLabel())
//    UpA/DnA : UpA: dRV1W%, dRV2W%, dPivotW% deu > 0.1 | DnA: ca ba < -0.1 (van can RV2 / WPR2 / tick / spread)
//    UpB/DnB : UpB: (<TenMuc> thuoc {PP, R1..R9} va <brkddiff> > 1 va <bodiff> > 0.1) hoac <brkD> >= 100 | DnB: (<TenMuc> thuoc {PP, S1..S9} va <brkddiff> < -1 va <bodiff> < -0.1) hoac <brkD> <= 0
//    UpC/DnC : UpC: <Pivotdiff> > 0.1 VA <Pivotdiff2> > 0.1 | DnC: ca hai < -0.1
//  Moc reset: xem _aptAccResetTf trong ham.
//==================================================================
bool AptWoodieDisplayLvlForTF(ENUM_TIMEFRAMES tf, int &outLvl);   // khai bao truoc: than ham nam o duoi (UpE/DnE trong DrawBreakStats() can <TenMuc>)

void DrawBreakStats()
  {
   if(!g_s.valid)
      return;


   double bidNow = SymbolInfoDouble(_Symbol,SYMBOL_BID);

   // dt (giay) cho cac bo dem Up/Dn/UpA/DnA/UpB/DnB/UpC/DnC/UpE/DnE: tinh MOT lan, dung chung cho 14 khung trong nhip nay.
   //   Lan goi dau tien (g_aptBrkAccLast con 0), doc gio that bai, hoac khoang cach >= 3600 giay (chart vua mo lai / may vua thuc giac)
   //   -> dt = 0: khong cong nhip nay, chi dat lai moc. Nhip cong don la nhip ve lai bang (DrawPanel -> DrawBreakStats, throttle 200 ms trong OnCalculate).
   datetime _aptAccNow = TimeCurrent();
   long     _aptAccDt  = 0;
   if(_aptAccNow > 0)
     {
      long _aptAccDtL = (long)_aptAccNow - (long)g_aptBrkAccLast;
      if(g_aptBrkAccLast > 0 && _aptAccDtL > 0 && _aptAccDtL < 3600)
         _aptAccDt = _aptAccDtL;
      g_aptBrkAccLast = _aptAccNow;
     }

   // Nuoi RV2 cho CA 14 khung truoc vong lap (doc M1 mot lan cho ca 14, xem AptRv2BuildAll14); ket qua o g_aptRv2All[]/g_aptRv2AllOk[], vong lap chi doc lai.
   AptRv2BuildAll14();
   for(int i=0; i<14; i++)
     {
      double rvDiff = 0.0;
      double q1     = 0.0;
      double rv0    = 0.0;
      AptRv1DiffAndQ1(g_tfList[i], rvDiff, q1, rv0);   // chi lay rv0 (RV1 that) de ghi g_rv1ValCache[] ben duoi
      // Cache RV1 that (rv0) cho khoi cong don ben duoi. AptRv1DiffAndQ1() that bai -> rv0 = 0.0 -> cache 0 -> khung nay bo qua cac dieu kien can RV1 > 0.
      g_rv1ValCache[i] = rv0;
     }

   double   _aptUcWpr1M1c[];
   int      _aptUcWpr1AvailM1c = Wpr8BuildRv1M1Series(Wpr8NeedM1Bars(), _aptUcWpr1M1c);
   datetime _aptUcWpr1TmM1c[];
   double   _aptUcWpr1CumTPVc[], _aptUcWpr1CumVolc[];
   int      _aptUcWpr1GotM1c     = Wpr9BuildM1Cache(_aptUcWpr1TmM1c, _aptUcWpr1CumTPVc, _aptUcWpr1CumVolc);
   int      _aptUcWpr1NeedTfBars = Wpr9NeedTfBars();

   // RV2(1m) = EMA(g_aptRv2EmaPeriod) ap len chuoi RV1(1m) doc o tren (_aptUcWpr1M1c/_aptUcWpr1AvailM1c) qua Wpr8BuildRv2M1Series().
   // RV2 cua 13 khung con lai (5m..1nm) duoc dung trong vong lap tu Wpr9BuildRv1Series + cache M1 dung chung o tren (xem khoi UpA/DnA).
   double   _aptUaWpr2M1c[];
   int      _aptUaWpr2AvailM1c = Wpr8BuildRv2M1Series(_aptUcWpr1M1c, _aptUcWpr1AvailM1c, g_aptRv2EmaPeriod, _aptUaWpr2M1c);

   for(int i=0; i<14; i++)
     {
      // Moc RESET (_aptAccResetTf) cua ca nam cap bo dem (Up/Dn, UpA/DnA, UpB/DnB, UpC/DnC):
      //   - Khung co chu ky < PERIOD_M15 (1m, 5m): reset theo nen cua chinh khung do.
      //   - Khung co chu ky >= PERIOD_M15: reset dong loat moi khi co NEN M5 MOI.
      //   Nguong so sanh dung PeriodSeconds() chu khong dung chi so vong lap i.
      //   Sang nen moi -> reset ca nam cap ve 0 va bo qua nhip giao nen.
      ENUM_TIMEFRAMES _aptAccResetTf =
         (PeriodSeconds(g_tfList[i]) < PeriodSeconds(PERIOD_M15))
         ? g_tfList[i] : PERIOD_M5;
      datetime _aptAccBt = iTime(_Symbol,_aptAccResetTf,0);
      if(_aptAccBt > 0)
        {
         if(g_aptBrkAccBarT[i] != _aptAccBt)
           {
            g_aptBrkAccBarT[i] = _aptAccBt;
            g_aptBrkAccUp[i]   = 0;
            g_aptBrkAccDn[i]   = 0;
            g_aptBrkAccUpA[i]  = 0;
            g_aptBrkAccDnA[i]  = 0;
            g_aptBrkAccUpB[i]  = 0;
            g_aptBrkAccDnB[i]  = 0;
            g_aptBrkAccUpC[i]  = 0;
            g_aptBrkAccDnC[i]  = 0;
            g_aptBrkAccUpE[i]  = 0;
            g_aptBrkAccDnE[i]  = 0;
           }
         else
            if(_aptAccDt > 0)
              {
               double _aptNSpread = (double)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * _Point;
                // Dieu kien dem Up/Dn (khung g_tfList[i]): <diffavg2> = diffavg hien tai - diffavg o giay truoc (g_aptDiffAvg2V[i], DrawMidPriceLabel() ghi; cung gia tri in o hang khung cua nhan gia giua):
                //   - Up: <diffavg2> >  0.1
                //   - Dn: <diffavg2> < -0.1
                //   Thieu <diffavg2> (thieu RV1 / RV2 / Pivot / OW / spread) -> khong cong ben nao. (InpUpWUp/InpUpBrkUp/InpDnWDn/InpDnBrkDn khong con dung cho Up/Dn.)
               if(g_aptDiffAvg2Ok[i])
                 {
                  if(g_aptDiffAvg2V[i] > 0.1)
                     g_aptBrkAccUp[i] += _aptAccDt;
                  else
                     if(g_aptDiffAvg2V[i] < -0.1)
                        g_aptBrkAccDn[i] += _aptAccDt;
                 }

                // Dieu kien dem UpA/DnA: SpR2 = lam tron (Bid - RV2)/spread (so nguyen, cung <SpR2> tren cot Pattern); WPR2 = William %R tren RV2(tf).
                //   WPR2 tinh ngay cho khung i: khung 1m (i==0) dung _aptUaWpr2M1c/_aptUaWpr2AvailM1c tinh truoc vong lap;
                //   13 khung con lai dung chuoi RV1(tf) tu Wpr9BuildRv1Series (cung cache M1 _aptUcWpr1TmM1c/_aptUcWpr1CumTPVc/_aptUcWpr1CumVolc/
                //   _aptUcWpr1GotM1c/_aptUcWpr1NeedTfBars) roi Wpr8BuildRv2M1Series() ra RV2(tf).
                //   WPR2 khong tinh duoc (EMPTY_VALUE - thieu lich su) -> dieu kien false -> khong cong ben nao.
               double _aptRv2A = g_aptRv2All[i];
               double _aptUaWpr2Now = EMPTY_VALUE;
               if(i == 0)
                 {
                  if(_aptUaWpr2AvailM1c > 0)
                     _aptUaWpr2Now = Wpr8WilliamsRAt(_aptUaWpr2M1c, _aptUaWpr2AvailM1c, 0, InpWpr8Period);
                 }
               else
                 {
                  if(_aptUcWpr1GotM1c > 0)
                    {
                     double _aptUaWpr1Tfc[];
                     int _aptUaWpr1AvailTfc = Wpr9BuildRv1Series(g_tfList[i], _aptUcWpr1NeedTfBars, _aptUcWpr1CumTPVc, _aptUcWpr1CumVolc, _aptUcWpr1TmM1c, _aptUcWpr1GotM1c, _aptUaWpr1Tfc);
                     if(_aptUaWpr1AvailTfc > 0)
                       {
                        double _aptUaWpr2Tfc[];
                        int _aptUaWpr2AvailTfc = Wpr8BuildRv2M1Series(_aptUaWpr1Tfc, _aptUaWpr1AvailTfc, g_aptRv2EmaPeriod, _aptUaWpr2Tfc);
                        if(_aptUaWpr2AvailTfc > 0)
                           _aptUaWpr2Now = Wpr8WilliamsRAt(_aptUaWpr2Tfc, _aptUaWpr2AvailTfc, 0, InpWpr8Period);
                       }
                    }
                 }
                // Dieu kien dem UpA/DnA: <dRV1W%> <dRV2W%> <dPivotW%> = thay doi theo GIAY cua <RV1W%> <RV2W%> <PivotW%> (g_aptWChgV[i*4 + 1..3]; <dOWW%> khong tham gia, DrawMidPriceLabel() / AptWChgStr() ghi; cung gia tri in o hang khung cua nhan gia giua).
                //   - UpA: CA BA gia tri >  0.1
                //   - DnA: CA BA gia tri < -0.1
                //   Thieu RV2 / WPR2 (khong du lich su) / tick / spread, hoac thieu BAT KY gia tri nao trong ba gia tri tren -> khong cong ben nao.
               if(g_aptRv2AllOk[i] && _aptRv2A > 0.0 && _aptUaWpr2Now != EMPTY_VALUE && bidNow > 0.0 && _aptNSpread > 0.0 &&
                  g_aptWChgOk[i*4 + 1] && g_aptWChgOk[i*4 + 2] && g_aptWChgOk[i*4 + 3])
                 {
                  if(g_aptWChgV[i*4 + 1] > 0.1 && g_aptWChgV[i*4 + 2] > 0.1 && g_aptWChgV[i*4 + 3] > 0.1)
                     g_aptBrkAccUpA[i] += _aptAccDt;
                  else
                     if(g_aptWChgV[i*4 + 1] < -0.1 && g_aptWChgV[i*4 + 2] < -0.1 && g_aptWChgV[i*4 + 3] < -0.1)
                        g_aptBrkAccDnA[i] += _aptAccDt;
                 }

                // Dieu kien dem UpE/DnE: <TenMuc> = muc Woodie gan Bid nhat cua khung (AptWoodieDisplayLvlForTF(): 0 = PP, 1..9 = R1..R9, 10..18 = S1..S9);
                //   <brkddiff> / <bodiff> = g_aptBrkDDiffV[i] / g_aptBoDiffV[i] (DrawMidPriceLabel() ghi; cung gia tri in o hang khung cua nhan gia giua).
                //   - UpE: <TenMuc> thuoc {PP, R1..R9}  VA  <brkD> >= 80  VA  <brkddiff> > 0.1  VA  <bodiff> > 0.1
                //   - DnE: <TenMuc> thuoc {PP, S1..S9}  VA  <brkD> <= 20  VA  <brkddiff> < -0.1  VA  <bodiff> < -0.1
                //   <brkD> = g_aptBrkDV[i]. Thieu <TenMuc> / <brkD> / <brkddiff> / <bodiff> -> khong cong ben nao.
               int    _aptELvl  = -1;
               if(g_aptBrkDOk[i] && g_aptBrkDDiffOk[i] && g_aptBoDiffOk[i] && AptWoodieDisplayLvlForTF(g_tfList[i], _aptELvl) && _aptELvl >= 0)
                 {
                  if(_aptELvl <= 9 && g_aptBrkDV[i] >= 80.0 && g_aptBrkDDiffV[i] > 0.1 && g_aptBoDiffV[i] > 0.1)
                     g_aptBrkAccUpE[i] += _aptAccDt;
                  else
                     if((_aptELvl == 0 || _aptELvl >= 10) && g_aptBrkDV[i] <= 20.0 && g_aptBrkDDiffV[i] < -0.1 && g_aptBoDiffV[i] < -0.1)
                        g_aptBrkAccDnE[i] += _aptAccDt;
                 }

                // Dieu kien dem UpB/DnB:
                //   <brkddiff> = g_aptBrkDDiffV[i], <bodiff> = g_aptBoDiffV[i], <brkD> = g_aptBrkDV[i] (DrawMidPriceLabel() ghi, cung gia tri in o hang khung cua nhan gia giua;
                //   brkddiff = brkD nen hien tai - brkD nen da dong truoc).
                //   - UpB: (<TenMuc> thuoc {PP, R1..R9}  VA  <brkddiff> >  1  VA  <bodiff> >  0.1)  HOAC  <brkD> >= 100   (VA uu tien hon HOAC: <brkD> khong can <TenMuc>)
                //   - DnB: (<TenMuc> thuoc {PP, S1..S9}  VA  <brkddiff> < -1  VA  <bodiff> < -0.1)  HOAC  <brkD> <= 0
                //   Moi ve cua dieu kien HOAC chi xet khi gia tri cua no co (thieu <TenMuc> / <brkddiff> / <bodiff> van xet <brkD> va nguoc lai); thieu tat ca -> khong cong ben nao.
                //   UpB uu tien truoc DnB (khong cong ca hai cung nhip).
               int  _aptBLvl   = -1;
               bool _aptBLvlOk = (AptWoodieDisplayLvlForTF(g_tfList[i], _aptBLvl) && _aptBLvl >= 0);
               bool _aptBUp = (_aptBLvlOk && _aptBLvl <= 9 && g_aptBrkDDiffOk[i] && g_aptBoDiffOk[i] && g_aptBrkDDiffV[i] > 1.0  && g_aptBoDiffV[i] > 0.1)  || (g_aptBrkDOk[i] && g_aptBrkDV[i] >= 100.0);
               bool _aptBDn = (_aptBLvlOk && (_aptBLvl == 0 || _aptBLvl >= 10) && g_aptBrkDDiffOk[i] && g_aptBoDiffOk[i] && g_aptBrkDDiffV[i] < -1.0 && g_aptBoDiffV[i] < -0.1) || (g_aptBrkDOk[i] && g_aptBrkDV[i] <= 0.0);
               if(_aptBUp)
                  g_aptBrkAccUpB[i] += _aptAccDt;
               else
                  if(_aptBDn)
                     g_aptBrkAccDnB[i] += _aptAccDt;

                // Dieu kien dem UpC/DnC (khung g_tfList[i]): <Pivotdiff> = g_pivotEmaDiffStr[i], <Pivotdiff2> = g_pivotEmaDiff2Str[i] (cung gia tri in tren nhan PIVOT):
                //   - UpC: <Pivotdiff> >  0.1  VA  <Pivotdiff2> >  0.1
                //   - DnC: <Pivotdiff> < -0.1  VA  <Pivotdiff2> < -0.1
                //   Gia tri 0 (hoac trong [-0.1, 0.1]) coi la khong duong khong am -> khong cong ben nao. Thieu BAT KY chuoi nao ("" hoac "-") -> khong cong ben nao.
               if(g_pivotEmaDiffStr[i] != "" && g_pivotEmaDiffStr[i] != "-" &&
                  g_pivotEmaDiff2Str[i] != "" && g_pivotEmaDiff2Str[i] != "-")
                 {
                  double _aptUcPd1 = StringToDouble(g_pivotEmaDiffStr[i]);
                  double _aptUcPd2 = StringToDouble(g_pivotEmaDiff2Str[i]);
                  if(_aptUcPd1 > 0.1 && _aptUcPd2 > 0.1)
                     g_aptBrkAccUpC[i] += _aptAccDt;
                  else
                     if(_aptUcPd1 < -0.1 && _aptUcPd2 < -0.1)
                        g_aptBrkAccDnC[i] += _aptAccDt;
                 }
              }
        }
     }
  }

//==================================================================
//  AptCheckSoundAlerts: phat am thanh canh bao (chi doc gia co san + PlaySound; in nhan Topday/Baseday...).
//
//  NHOM 1 - TOPDAY.WAV / BASEDAY.WAV: so Bid voi dinh/day cua nen ngay D1 hien tai (shift 0) va nen truoc do (shift 1):
//      (highD0 - Bid) < InpDayEdgeThresholdUSD  VA  highD0 > highD1  -> PlaySound("Topday.wav")
//      (Bid - lowD0)  < InpDayEdgeThresholdUSD  VA  lowD0  < lowD1   -> PlaySound("Baseday.wav")
//    Moi ngay chi phat MOT LAN (luu iTime(D1,0) vao g_aptSndTopDayT/g_aptSndBaseDayT).
//  NHOM 2 / 3: cung cong thuc cho nen tuan W1 ("Topweek"/"Baseweek") va nen thang MN1 ("TopMonth"/"BaseMonth"), cung nguong InpDayEdgeThresholdUSD.
//==================================================================
void AptPeriodExtremeAlertCheck();   // khai bao truoc: than ham nam o duoi (sau AptPeriodExtremeMarksDraw)

void AptCheckSoundAlerts()
  {
   //----- Moc thoi gian NEO NHAN cho cac khung Ngay/Tuan/Thang: nen hien tai cua chart (_Period, shift 0) de nhan hien gan gia hien tai;
   //   chi anh huong vi tri hien thi, khong anh huong cong thuc dieu kien.
   datetime tSndAnchor = iTime(_Symbol,_Period,0);
   //   Khoang cach GIA giua cac tang nhan xep chong (tang 0 = Ngay, 1 = Tuan, 2 = Thang) de nhan khong de len nhau.
   const double APT_SND_LBL_STACK = 150.0*_Point;

   //----- NHOM 1: Topday.wav / Baseday.wav (dinh/day NEN NGAY vs Bid) -----
   if(Bars(_Symbol,PERIOD_D1) >= 2)
     {
      double highD0 = iHigh(_Symbol,PERIOD_D1,0);
      double lowD0  = iLow (_Symbol,PERIOD_D1,0);
      double highD1 = iHigh(_Symbol,PERIOD_D1,1);
      double lowD1  = iLow (_Symbol,PERIOD_D1,1);
      double bid    = SymbolInfoDouble(_Symbol,SYMBOL_BID);

      if(highD0>0.0 && lowD0>0.0 && highD1>0.0 && lowD1>0.0 && bid>0.0)
        {
         datetime tD0 = iTime(_Symbol,PERIOD_D1,0);

         if((highD0 - bid) < InpDayEdgeThresholdUSD && highD0 > highD1)
           {
            if(g_aptSndTopDayT != tD0)
              {
               PlaySound("Topday.wav");
                // In nhan "Topday" tai dinh nen Ngay.
               MakeText(PFX"SND_TOPDAY",tSndAnchor,highD0,"Topday",InpColUp,ANCHOR_LOWER);
               g_aptSndTopDayT = tD0;
              }
           }

         if((bid - lowD0) < InpDayEdgeThresholdUSD && lowD0 < lowD1)
           {
            if(g_aptSndBaseDayT != tD0)
              {
               PlaySound("Baseday.wav");
                // In nhan "Baseday" tai day nen Ngay.
               MakeText(PFX"SND_BASEDAY",tSndAnchor,lowD0,"Baseday",InpColDown,ANCHOR_UPPER);
               g_aptSndBaseDayT = tD0;
              }
           }
        }
     }

   //----- NHOM 2: Topday.wav / Baseday.wav cho nen TUAN (W1), nhan "Topweek"/"Baseweek"; cung cong thuc va nguong InpDayEdgeThresholdUSD nhu NHOM 1.
   if(Bars(_Symbol,PERIOD_W1) >= 2)
     {
      double highW0 = iHigh(_Symbol,PERIOD_W1,0);
      double lowW0  = iLow (_Symbol,PERIOD_W1,0);
      double highW1 = iHigh(_Symbol,PERIOD_W1,1);
      double lowW1  = iLow (_Symbol,PERIOD_W1,1);
      double bidW   = SymbolInfoDouble(_Symbol,SYMBOL_BID);

      if(highW0>0.0 && lowW0>0.0 && highW1>0.0 && lowW1>0.0 && bidW>0.0)
        {
         datetime tW0 = iTime(_Symbol,PERIOD_W1,0);

         if((highW0 - bidW) < InpDayEdgeThresholdUSD && highW0 > highW1)
           {
            if(g_aptSndTopWeekT != tW0)
              {
               PlaySound("Topday.wav");
                // In nhan "Topweek" tai dinh nen Tuan, xep tang 1 (cao hon tang Ngay).
               MakeText(PFX"SND_TOPWEEK",tSndAnchor,highW0+APT_SND_LBL_STACK,"Topweek",InpColUp,ANCHOR_LOWER);
               g_aptSndTopWeekT = tW0;
              }
           }

         if((bidW - lowW0) < InpDayEdgeThresholdUSD && lowW0 < lowW1)
           {
            if(g_aptSndBaseWeekT != tW0)
              {
               PlaySound("Baseday.wav");
                // In nhan "Baseweek" tai day nen Tuan, xep tang 1 (thap hon tang Ngay).
               MakeText(PFX"SND_BASEWEEK",tSndAnchor,lowW0-APT_SND_LBL_STACK,"Baseweek",InpColDown,ANCHOR_UPPER);
               g_aptSndBaseWeekT = tW0;
              }
           }
        }
     }

   //----- NHOM 3: Topday.wav / Baseday.wav cho nen THANG (MN1), nhan "TopMonth"/"BaseMonth"; cung cong thuc va nguong nhu NHOM 1.
   if(Bars(_Symbol,PERIOD_MN1) >= 2)
     {
      double highMN0 = iHigh(_Symbol,PERIOD_MN1,0);
      double lowMN0  = iLow (_Symbol,PERIOD_MN1,0);
      double highMN1 = iHigh(_Symbol,PERIOD_MN1,1);
      double lowMN1  = iLow (_Symbol,PERIOD_MN1,1);
      double bidMN   = SymbolInfoDouble(_Symbol,SYMBOL_BID);

      if(highMN0>0.0 && lowMN0>0.0 && highMN1>0.0 && lowMN1>0.0 && bidMN>0.0)
        {
         datetime tMN0 = iTime(_Symbol,PERIOD_MN1,0);

         if((highMN0 - bidMN) < InpDayEdgeThresholdUSD && highMN0 > highMN1)
           {
            if(g_aptSndTopMonthT != tMN0)
              {
               PlaySound("Topday.wav");
                // In nhan "TopMonth" tai dinh nen Thang, xep tang 2.
               MakeText(PFX"SND_TOPMONTH",tSndAnchor,highMN0+APT_SND_LBL_STACK*2.0,"TopMonth",InpColUp,ANCHOR_LOWER);
               g_aptSndTopMonthT = tMN0;
              }
           }

         if((bidMN - lowMN0) < InpDayEdgeThresholdUSD && lowMN0 < lowMN1)
           {
            if(g_aptSndBaseMonthT != tMN0)
              {
               PlaySound("Baseday.wav");
                // In nhan "BaseMonth" tai day nen Thang, xep tang 2.
               MakeText(PFX"SND_BASEMONTH",tSndAnchor,lowMN0-APT_SND_LBL_STACK*2.0,"BaseMonth",InpColDown,ANCHOR_UPPER);
               g_aptSndBaseMonthT = tMN0;
              }
           }
        }
     }
  }

//==================================================================
//  TRUONG <S1>: cong thuc Pivot Woodie + RSI cua muc Pivot (port tu RollingVWAP2_MultiTF.mq5: WoodieLevelValue / CalcRSI / S1RsiTextForTF,
//  doi ten co tien to Apt). Input cua RollingVWAP2 duoc thay bang hang so:
//      InpHistPoints           = 480  -> APT_S1_HIST_POINTS
//      InpWoodiePivotEmaPeriod = 5    -> APT_S1_EMA_PERIOD
//      InpTFStatS1DiffDigits   = 0    -> APT_S1_DIFF_DIGITS
//      InpTFStatS1RsiDigits    = 0    -> APT_S1_RSI_DIGITS
//      WOODIE_RSI_PERIOD       = 5    -> APT_S1_RSI_PERIOD (bien, doi bang Pe UI)
//  Cac ham o day chi doc gia: khong tao object.
//==================================================================
#define APT_S1_LVL_COUNT 19

//--- ten 19 muc, thu tu: 0 = PP, 1..9 = R1..R9, 10..18 = S1..S9
string g_aptLvlName[APT_S1_LVL_COUNT] = { "PP", "R1", "R2", "R3", "R4",
                                           "R5", "R6", "R7", "R8", "R9",
                                           "S1", "S2", "S3", "S4", "S5",
                                           "S6", "S7", "S8", "S9" };

// APT_S1_RSI_PERIOD la bien (khong phai hang so): Pe UI (bang nut chon chu ky RSI, xem CreateRsiPePanel()) gan gia tri khi nguoi dung bam; khoi tao = 5.
int APT_S1_RSI_PERIOD  = 5;           // chu ky RSI cua muc Pivot (doi bang Pe UI)
const int APT_S1_HIST_POINTS = 480;   // = InpHistPoints (mac dinh)
const int APT_S1_EMA_PERIOD  = 5;     // = InpWoodiePivotEmaPeriod (mac dinh)
const int APT_S1_DIFF_DIGITS = 0;     // = InpTFStatS1DiffDigits (mac dinh)
const int APT_S1_RSI_DIGITS  = 0;     // = InpTFStatS1RsiDigits (mac dinh)

//==================================================================
//  AptWoodieLevelValue - gia tri muc Pivot Woodie lvl (0 = PP, 1..9 = R1..R9, 10..18 = S1..S9) tu H/L/C cua bar lien truoc:
//      PP = (H + L + 2*C)/4 ; rng = H - L
//      R1 = 2*PP - L                  S1 = 2*PP - H
//      R2 = PP + rng                  S2 = PP - rng
//      Rn = H + (n-1)*(PP - L)        Sn = L - (n-1)*(H - PP)  (n>=3)
//  PP/R1/S1 trung khit voi khoi rangeRS cua AptRv1DiffAndQ1().
//==================================================================
double AptWoodieLevelValue(const int lvl, const double hB, const double lB, const double cB)
  {
   double pp    = (hB + lB + 2.0 * cB) / 4.0;   // PP = (H+L+2*C)/4
   double rng   = hB - lB;                      // bien do bar lien truoc
   double dRise = pp - lB;                      // PP - L
   double dFall = hB - pp;                      // H - PP

   switch(lvl)
     {
      case 0:  return pp;                       // PP
      case 1:  return 2.0 * pp - lB;            // R1 = 2*PP - L
      case 2:  return pp + rng;                 // R2 = PP + (H-L)
      case 3:  return hB + 2.0 * dRise;         // R3 = H + 2*(PP-L)
      case 4:  return hB + 3.0 * dRise;         // R4 = H + 3*(PP-L)
      case 5:  return hB + 4.0 * dRise;         // R5 = H + 4*(PP-L)
      case 6:  return hB + 5.0 * dRise;         // R6 = H + 5*(PP-L)
      case 7:  return hB + 6.0 * dRise;         // R7 = H + 6*(PP-L)
      case 8:  return hB + 7.0 * dRise;         // R8 = H + 7*(PP-L)
      case 9:  return hB + 8.0 * dRise;         // R9 = H + 8*(PP-L)
      case 10: return 2.0 * pp - hB;            // S1 = 2*PP - H
      case 11: return pp - rng;                 // S2 = PP - (H-L)
      case 12: return lB - 2.0 * dFall;         // S3 = L - 2*(H-PP)
      case 13: return lB - 3.0 * dFall;         // S4 = L - 3*(H-PP)
      case 14: return lB - 4.0 * dFall;         // S5 = L - 4*(H-PP)
      case 15: return lB - 5.0 * dFall;         // S6 = L - 5*(H-PP)
      case 16: return lB - 6.0 * dFall;         // S7 = L - 6*(H-PP)
      case 17: return lB - 7.0 * dFall;         // S8 = L - 7*(H-PP)
      case 18: return lB - 8.0 * dFall;         // S9 = L - 8*(H-PP)
     }
   return 2.0 * pp - hB;                        // du phong: S1 (mac dinh cu)
  }

//==================================================================
//  AptS1EmaSeries - day so cua duong S1:
//      S1[s] = AptWoodieLevelValue(APT_S1_SWING_LVL, H, L, C cua bar (s+1) cua khung tf)   -> S1 = 2*PP - H
//      -> EMA(APT_S1_EMA_PERIOD) tren chuoi do (cung cach seed EMA tu phan tu CU NHAT nhu AptS1RsiTextForTF),
//  nhung tra ra CA DAY thay vi chi ema[0], va chi lam rieng muc S1.
//  Chi so theo kieu series: outS1[0] = nen TF hien tai, tang dan la lui ve qua khu (cung chieu AptRvFindSwing()).
//  Tra ve: so phan tu lay duoc (0 = that bai). Chi doc gia.
//==================================================================
const int APT_S1_SWING_LVL = 10;   // chi so muc S1 trong AptWoodieLevelValue

int AptS1EmaSeries(const ENUM_TIMEFRAMES tf,double &outS1[],const int wantPoints)
  {
   ArrayResize(outS1,0);

   int want = wantPoints;
   if(want < 3)                   want = 3;
   if(want > APT_S1_HIST_POINTS)  want = APT_S1_HIST_POINTS;

   int need = want + 1;           // +1 vi moi diem s can bar lien truoc (s+1)

   double hi[], lo[], cl[];
   ArraySetAsSeries(hi, true);
   ArraySetAsSeries(lo, true);
   ArraySetAsSeries(cl, true);

   int cpH = CopyHigh (_Symbol, tf, 0, need, hi);
   int cpL = CopyLow  (_Symbol, tf, 0, need, lo);
   int cpC = CopyClose(_Symbol, tf, 0, need, cl);
   int got = MathMin(MathMin(cpH, cpL), cpC);
   if(got < 2)
      return(0);

   int points = got - 1;
   if(points > want)
      points = want;
   if(points < 3)
      return(0);

    // Chuoi S1 tho, s = 0 la MOI NHAT (bar s+1)
   double s1Arr[];
   ArrayResize(s1Arr, points);
   for(int s = 0; s < points; s++)
     {
      double hB = hi[s + 1];
      double lB = lo[s + 1];
      double cB = cl[s + 1];
      s1Arr[s] = AptWoodieLevelValue(APT_S1_SWING_LVL, hB, lB, cB);
     }

    // EMA(APT_S1_EMA_PERIOD) tren chuoi S1 (seed tu phan tu CU NHAT roi chay ve hien tai)
   ArrayResize(outS1, points);
   int    pEma = MathMax(1, APT_S1_EMA_PERIOD);
   double aEma = 2.0 / (pEma + 1.0);
   double e      = 0.0;
   bool   seeded = false;
   for(int s = points - 1; s >= 0; s--)
     {
      if(!seeded)
        {
         e = s1Arr[s];
         seeded = true;
        }
      else
        {
         e = aEma * s1Arr[s] + (1.0 - aEma) * e;
        }
      outS1[s] = e;
     }

   return(points);
  }

//==================================================================
//  AptCalcRSI - RSI(period) tren mot chuoi gia tri "series" (s = cu nhat -> moi nhat, cung chieu mang EMA), Wilder smoothing chuan.
//  Ket qua ghi vao rsiOut[] cung chieu dai voi series/points. Cac vi tri qua cu (khong du du lieu de seed) gan bang RSI seed dau tien.
//==================================================================
void AptCalcRSI(const double &series[], const int points, const int period, double &rsiOut[])
  {
   ArrayResize(rsiOut, points);
   for(int i = 0; i < points; i++)
      rsiOut[i] = 50.0;
   if(points < period + 1)
      return;

   double gainSum = 0.0, lossSum = 0.0;
   for(int k = 0; k < period; k++)
     {
      int s = points - 2 - k;
      double diff = series[s] - series[s + 1];
      if(diff > 0)
         gainSum += diff;
      else
         lossSum += -diff;
     }
   double avgGain = gainSum / period;
   double avgLoss = lossSum / period;
   int    seedIndex = points - 1 - period;
   double rs     = (avgLoss == 0.0) ? 0.0 : avgGain / avgLoss;
   double rsiVal = (avgLoss == 0.0) ? 100.0 : 100.0 - 100.0 / (1.0 + rs);
   rsiOut[seedIndex] = rsiVal;

   for(int s = seedIndex - 1; s >= 0; s--)
     {
      double diff = series[s] - series[s + 1];
      double gain = (diff > 0) ? diff : 0.0;
      double loss = (diff < 0) ? -diff : 0.0;
      avgGain = (avgGain * (period - 1) + gain) / period;
      avgLoss = (avgLoss * (period - 1) + loss) / period;
      rs = (avgLoss == 0.0) ? 0.0 : avgGain / avgLoss;
      rsiOut[s] = (avgLoss == 0.0) ? 100.0 : 100.0 - 100.0 / (1.0 + rs);
     }
   for(int s = seedIndex + 1; s < points; s++)
      rsiOut[s] = rsiVal;
  }

//==================================================================
//  AptS1RsiTextForTF: chuoi <S1> = "<ten muc> <RSI5>/<do lech>" (vd "R1 48/+10") cua muc Pivot GAN BID NHAT cua khung tf.
//  Chuoi cua ca 19 muc chi dung bar DA DONG nen cache theo tung khung, chi tinh lai khi iTime(tf,0) doi.
//  Buoc CHON MUC chay moi lan goi vi phu thuoc BID hien tai.
//==================================================================
bool AptS1RsiTextForTF(ENUM_TIMEFRAMES tf, string &outText)
  {
   static int      s_s1Key[32];
   static datetime s_s1BarT[32];
   static string   s_s1Txt[32][APT_S1_LVL_COUNT];
   static double   s_s1Val[32][APT_S1_LVL_COUNT];
   static bool     s_s1Ok [32][APT_S1_LVL_COUNT];
   static int      s_s1Cnt = 0;

   outText = "-";

   datetime _s1T0 = iTime(_Symbol, tf, 0);
   if(_s1T0 <= 0)
      return(false);

   // --- tim (hoac cap phat) o nho cho khung tf ---
   int _s1Slot = -1;
   for(int _s1k = 0; _s1k < s_s1Cnt; _s1k++)
      if(s_s1Key[_s1k] == (int)tf)
        {
         _s1Slot = _s1k;
         break;
        }
   if(_s1Slot < 0 && s_s1Cnt < 32)
     {
      _s1Slot = s_s1Cnt;
      s_s1Key[s_s1Cnt]  = (int)tf;
      s_s1BarT[s_s1Cnt] = 0;
      for(int _s1z = 0; _s1z < APT_S1_LVL_COUNT; _s1z++)
        {
         s_s1Txt[s_s1Cnt][_s1z] = "";
         s_s1Val[s_s1Cnt][_s1z] = 0.0;
         s_s1Ok [s_s1Cnt][_s1z] = false;
        }
      s_s1Cnt++;
     }
   if(_s1Slot < 0)
      return(false);

   // Chi TINH LAI khi khung sang nen moi.
   if(s_s1BarT[_s1Slot] != _s1T0)
     {
      int need = APT_S1_HIST_POINTS + 1;   // +1 vi moi diem s can bar lien truoc (s+1)
      double hi[], lo[], cl[];
      ArraySetAsSeries(hi, true);
      ArraySetAsSeries(lo, true);
      ArraySetAsSeries(cl, true);

      int cpH = CopyHigh (_Symbol, tf, 0, need, hi);
      int cpL = CopyLow  (_Symbol, tf, 0, need, lo);
      int cpC = CopyClose(_Symbol, tf, 0, need, cl);
      int got = MathMin(MathMin(cpH, cpL), cpC);
      if(got < 2)
         return(false);

      int points = got - 1;
      if(points > APT_S1_HIST_POINTS)  points = APT_S1_HIST_POINTS;
      if(points <= APT_S1_RSI_PERIOD)  return(false);

      int dg = APT_S1_DIFF_DIGITS;
      if(dg < 0) dg = 0;
      if(dg > 2) dg = 2;

      int dgR = APT_S1_RSI_DIGITS;
      if(dgR < 0) dgR = 0;
      if(dgR > 2) dgR = 2;

      for(int lvl = 0; lvl < APT_S1_LVL_COUNT; lvl++)
        {
         s_s1Ok [_s1Slot][lvl] = false;
         s_s1Txt[_s1Slot][lvl] = "";
         s_s1Val[_s1Slot][lvl] = 0.0;

          // Chuoi muc tho, s = cu nhat -> moi nhat (bar s+1)
         double s1Arr[];
         ArrayResize(s1Arr, points);
         for(int s = 0; s < points; s++)
           {
            double hB = hi[s + 1];
            double lB = lo[s + 1];
            double cB = cl[s + 1];
            s1Arr[s] = AptWoodieLevelValue(lvl, hB, lB, cB);
           }

          // EMA(APT_S1_EMA_PERIOD) tren chuoi muc (nhu DrawEmaSeries)
         double ema[];
         ArrayResize(ema, points);
         int    pEma = MathMax(1, APT_S1_EMA_PERIOD);
         double aEma = 2.0 / (pEma + 1.0);
         double e      = 0.0;
         bool   seeded = false;
         for(int s = points - 1; s >= 0; s--)
           {
            if(!seeded)
              {
               e = s1Arr[s];
               seeded = true;
              }
            else
              {
               e = aEma * s1Arr[s] + (1.0 - aEma) * e;
              }
            ema[s] = e;
           }

         double rsiArr[];
         AptCalcRSI(ema, points, APT_S1_RSI_PERIOD, rsiArr);
         double rsiNow  = rsiArr[0];
         double rsiPrev = (points > 1) ? rsiArr[1] : rsiNow;
         double rsiDiff = rsiNow - rsiPrev;

         // txt co dang "<RSI5>/<do lech>", vi du "48/+10".
         string txt = DoubleToString(rsiNow, dgR) + "/" +
                      ((rsiDiff >= 0) ? "+" : "") + DoubleToString(rsiDiff, dg);

         s_s1Txt[_s1Slot][lvl] = txt;
         s_s1Val[_s1Slot][lvl] = ema[0];   // gia tri duong muc lvl tai diem moi nhat
         s_s1Ok [_s1Slot][lvl] = true;
        }

      s_s1BarT[_s1Slot] = _s1T0;
     }

   // CHON MUC GAN BID NHAT cua chinh khung tf (chay moi lan goi, khong cache).
   MqlTick _s1Tk;
   if(!SymbolInfoTick(_Symbol, _s1Tk))
      return(false);
   double _s1Px = _s1Tk.bid;
   if(_s1Px <= 0.0)
      return(false);

   int    _s1Best = -1;
   double _s1Dist = 0.0;
   for(int lvl = 0; lvl < APT_S1_LVL_COUNT; lvl++)
     {
      if(!s_s1Ok[_s1Slot][lvl])
         continue;
      double dAbs = MathAbs(_s1Px - s_s1Val[_s1Slot][lvl]);
      if(_s1Best < 0 || dAbs < _s1Dist)
        {
         _s1Best = lvl;
         _s1Dist = dAbs;
        }
     }
   if(_s1Best < 0)
      return(false);

   // <S1> = "<ten muc> <RSI5>/<do lech>", vi du "R1 48/+10".
   outText = g_aptLvlName[_s1Best] + " " + s_s1Txt[_s1Slot][_s1Best];
   return(true);
  }

//==================================================================
//  AptWoodieDisplayLvlForTF: chi so muc Pivot (0 = PP, 1..9 = R1..R9, 10..18 = S1..S9) GAN BID NHAT cua khung tf (cung cach chon voi AptS1RsiTextForTF()).
//  Chuoi EMA muc cache theo khung (chi tinh lai khi khung sang nen moi); buoc chon muc chay moi lan goi. Gia tri muc ghi vao g_aptWdLastVal.
//==================================================================
bool AptWoodieDisplayLvlForTF(ENUM_TIMEFRAMES tf, int &outLvl)
  {
   static int      s_wdKey[32];
   static datetime s_wdBarT[32];
   static double   s_wdVal[32][APT_S1_LVL_COUNT];
   static bool     s_wdOk [32][APT_S1_LVL_COUNT];
   static int      s_wdCnt = 0;

   outLvl = -1;

   datetime _wdT0 = iTime(_Symbol, tf, 0);
   if(_wdT0 <= 0)
      return(false);

   int _wdSlot = -1;
   for(int _wdk = 0; _wdk < s_wdCnt; _wdk++)
      if(s_wdKey[_wdk] == (int)tf)
        {
         _wdSlot = _wdk;
         break;
        }
   if(_wdSlot < 0 && s_wdCnt < 32)
     {
      _wdSlot = s_wdCnt;
      s_wdKey[s_wdCnt]  = (int)tf;
      s_wdBarT[s_wdCnt] = 0;
      for(int _wdz = 0; _wdz < APT_S1_LVL_COUNT; _wdz++)
        {
         s_wdVal[s_wdCnt][_wdz] = 0.0;
         s_wdOk [s_wdCnt][_wdz] = false;
        }
      s_wdCnt++;
     }
   if(_wdSlot < 0)
      return(false);

    // Chi TINH LAI khi khung sang nen moi (cung nhip cache voi AptS1RsiTextForTF()).
   if(s_wdBarT[_wdSlot] != _wdT0)
     {
      int need = APT_S1_HIST_POINTS + 1;   // +1 vi moi diem s can bar lien truoc (s+1)
      double hi[], lo[], cl[];
      ArraySetAsSeries(hi, true);
      ArraySetAsSeries(lo, true);
      ArraySetAsSeries(cl, true);

      int cpH = CopyHigh (_Symbol, tf, 0, need, hi);
      int cpL = CopyLow  (_Symbol, tf, 0, need, lo);
      int cpC = CopyClose(_Symbol, tf, 0, need, cl);
      int got = MathMin(MathMin(cpH, cpL), cpC);
      if(got < 2)
         return(false);

      int points = got - 1;
      if(points > APT_S1_HIST_POINTS) points = APT_S1_HIST_POINTS;
      if(points < 1) return(false);

      for(int lvl = 0; lvl < APT_S1_LVL_COUNT; lvl++)
        {
         s_wdOk [_wdSlot][lvl] = false;
         s_wdVal[_wdSlot][lvl] = 0.0;

          // Chuoi muc tho, s = cu nhat -> moi nhat (bar s+1)
         double lvlArr[];
         ArrayResize(lvlArr, points);
         for(int s = 0; s < points; s++)
           {
            double hB = hi[s + 1];
            double lB = lo[s + 1];
            double cB = cl[s + 1];
            lvlArr[s] = AptWoodieLevelValue(lvl, hB, lB, cB);
           }

          // EMA(APT_S1_EMA_PERIOD) tren chuoi muc (nhu AptS1RsiTextForTF())
         double ema[];
         ArrayResize(ema, points);
         int    pEma = MathMax(1, APT_S1_EMA_PERIOD);
         double aEma = 2.0 / (pEma + 1.0);
         double e      = 0.0;
         bool   seeded = false;
         for(int s = points - 1; s >= 0; s--)
           {
            if(!seeded)
              {
               e = lvlArr[s];
               seeded = true;
              }
            else
              {
               e = aEma * lvlArr[s] + (1.0 - aEma) * e;
              }
            ema[s] = e;
           }

         s_wdVal[_wdSlot][lvl] = ema[0];   // gia tri duong muc lvl tai diem moi nhat
         s_wdOk [_wdSlot][lvl] = true;
        }

      s_wdBarT[_wdSlot] = _wdT0;
     }

    // CHON MUC GAN BID NHAT cua chinh khung tf (chay moi lan goi, khong cache).
   MqlTick _wdTk;
   if(!SymbolInfoTick(_Symbol, _wdTk))
      return(false);
   double _wdPx = _wdTk.bid;
   if(_wdPx <= 0.0)
      return(false);

   int    _wdBest = -1;
   double _wdDist = 0.0;
   for(int lvl = 0; lvl < APT_S1_LVL_COUNT; lvl++)
     {
      if(!s_wdOk[_wdSlot][lvl])
         continue;
      double dAbs = MathAbs(_wdPx - s_wdVal[_wdSlot][lvl]);
      if(_wdBest < 0 || dAbs < _wdDist)
        {
         _wdBest = lvl;
         _wdDist = dAbs;
        }
     }
   if(_wdBest < 0)
      return(false);

   outLvl = _wdBest;
   g_aptWdLastVal = s_wdVal[_wdSlot][_wdBest];   // gia muc <TenMuc> cho AptRoundNearStr()
   return(true);
  }

//==================================================================
//  AptWoodieDisplayLvlForSym: nhu AptWoodieDisplayLvlForTF() nhung tinh tren symbol sym (dung cho DXY):
//    chi so muc Pivot (0 = PP, 1..9 = R1..R9, 10..18 = S1..S9) GAN GIA NHAT cua khung tf cua symbol sym.
//    Muc = EMA(APT_S1_EMA_PERIOD) tren chuoi muc Woodie (H/L/C bar lien truoc) cua sym; gia so sanh = Bid cua sym (Bid <= 0 -> Close nen 0 cua sym tren khung tf).
//    Chuoi EMA cache theo khung (chi tinh lai khi khung cua sym sang nen moi); doi symbol -> xoa cache. Buoc chon muc chay moi lan goi.
//    KHONG ghi g_aptWdLastVal (bien do chi danh cho symbol cua chart). Thieu du lieu / symbol khong ton tai -> false. Chi doc gia, khong tao object.
//==================================================================
bool AptWoodieDisplayLvlForSym(const string sym, ENUM_TIMEFRAMES tf, int &outLvl)
  {
   static string   s_dxCurSym = "";
   static int      s_dxKey[32];
   static datetime s_dxBarT[32];
   static double   s_dxVal[32][APT_S1_LVL_COUNT];
   static bool     s_dxOk [32][APT_S1_LVL_COUNT];
   static int      s_dxCnt = 0;

   outLvl = -1;
   if(StringLen(sym) < 1)
      return(false);

   if(sym != s_dxCurSym)   // doi symbol -> bo toan bo cache cu
     {
      s_dxCurSym = sym;
      s_dxCnt    = 0;
     }

   datetime _dxT0 = iTime(sym, tf, 0);
   if(_dxT0 <= 0)
      return(false);

   int _dxSlot = -1;
   for(int _dxk = 0; _dxk < s_dxCnt; _dxk++)
      if(s_dxKey[_dxk] == (int)tf)
        {
         _dxSlot = _dxk;
         break;
        }
   if(_dxSlot < 0 && s_dxCnt < 32)
     {
      _dxSlot = s_dxCnt;
      s_dxKey[s_dxCnt]  = (int)tf;
      s_dxBarT[s_dxCnt] = 0;
      for(int _dxz = 0; _dxz < APT_S1_LVL_COUNT; _dxz++)
        {
         s_dxVal[s_dxCnt][_dxz] = 0.0;
         s_dxOk [s_dxCnt][_dxz] = false;
        }
      s_dxCnt++;
     }
   if(_dxSlot < 0)
      return(false);

   // Chi TINH LAI khi khung cua sym sang nen moi.
   if(s_dxBarT[_dxSlot] != _dxT0)
     {
      int need = APT_S1_HIST_POINTS + 1;   // +1 vi moi diem s can bar lien truoc (s+1)
      double hi[], lo[], cl[];
      ArraySetAsSeries(hi, true);
      ArraySetAsSeries(lo, true);
      ArraySetAsSeries(cl, true);

      int cpH = CopyHigh (sym, tf, 0, need, hi);
      int cpL = CopyLow  (sym, tf, 0, need, lo);
      int cpC = CopyClose(sym, tf, 0, need, cl);
      int got = MathMin(MathMin(cpH, cpL), cpC);
      if(got < 2)
         return(false);

      int points = got - 1;
      if(points > APT_S1_HIST_POINTS) points = APT_S1_HIST_POINTS;
      if(points < 1) return(false);

      for(int lvl = 0; lvl < APT_S1_LVL_COUNT; lvl++)
        {
         s_dxOk [_dxSlot][lvl] = false;
         s_dxVal[_dxSlot][lvl] = 0.0;

         // Chuoi muc tho, s = cu nhat -> moi nhat (bar s+1)
         double lvlArr[];
         ArrayResize(lvlArr, points);
         for(int s = 0; s < points; s++)
           {
            double hB = hi[s + 1];
            double lB = lo[s + 1];
            double cB = cl[s + 1];
            lvlArr[s] = AptWoodieLevelValue(lvl, hB, lB, cB);
           }

         // EMA(APT_S1_EMA_PERIOD) tren chuoi muc (nhu AptWoodieDisplayLvlForTF())
         int    pEma = MathMax(1, APT_S1_EMA_PERIOD);
         double aEma = 2.0 / (pEma + 1.0);
         double e      = 0.0;
         bool   seeded = false;
         for(int s = points - 1; s >= 0; s--)
           {
            if(!seeded)
              {
               e = lvlArr[s];
               seeded = true;
              }
            else
              {
               e = aEma * lvlArr[s] + (1.0 - aEma) * e;
              }
           }

         s_dxVal[_dxSlot][lvl] = e;   // gia tri duong muc lvl tai diem moi nhat
         s_dxOk [_dxSlot][lvl] = true;
        }

      s_dxBarT[_dxSlot] = _dxT0;
     }

   // CHON MUC GAN GIA DXY NHAT cua chinh khung tf (chay moi lan goi, khong cache).
   double _dxPx = 0.0;
   MqlTick _dxTk;
   if(SymbolInfoTick(sym, _dxTk))
      _dxPx = _dxTk.bid;
   if(_dxPx <= 0.0)
      _dxPx = iClose(sym, tf, 0);
   if(_dxPx <= 0.0)
      return(false);

   int    _dxBest = -1;
   double _dxDist = 0.0;
   for(int lvl = 0; lvl < APT_S1_LVL_COUNT; lvl++)
     {
      if(!s_dxOk[_dxSlot][lvl])
         continue;
      double dAbs = MathAbs(_dxPx - s_dxVal[_dxSlot][lvl]);
      if(_dxBest < 0 || dAbs < _dxDist)
        {
         _dxBest = lvl;
         _dxDist = dAbs;
        }
     }
   if(_dxBest < 0)
      return(false);

   outLvl = _dxBest;
   return(true);
  }

//==================================================================
//  AptDxyLvlTag: chuoi {<DxyTenMuc>} chen ngay sau <TF> tren nhan cot Pattern, vd "{R2}" / "{S1}" / "{PP}".
//    Symbol = g_dxySym. Thieu du lieu / symbol khong ton tai -> "{-}". Chi doc gia, khong tao object.
//==================================================================
string AptDxyLvlTag(const ENUM_TIMEFRAMES tf)
  {
   int _dxLv = -1;
   if(AptWoodieDisplayLvlForSym(g_dxySym, tf, _dxLv) && _dxLv >= 0 && _dxLv < APT_S1_LVL_COUNT)
      return("{" + g_aptLvlName[_dxLv] + "}");
   return("{-}");
  }

//==================================================================
//  QUET MAU HINH DANG TAO (port logic Pine Chart Pattern Scanner - Forming).
//  Quet doc lap tren tung khung g_tfList[0..13], khong dong den Entry/SL/TP.
//  Cot nhan: prefix PFX"PATL" - 14 hang, khung nho nhat o DUOI CUNG.
//  Duong mau PFX"PAT_L1/L2/L3" ve mau hinh cua khung dang chon o bang nut than nen lon (g_barTF).
//==================================================================
#define APT_PAT_PIVCAP   12
#define APT_PAT_LOOK     120

struct SAptPat
  {
   bool     valid;
   string   bias;
   double   conf;
   int      mode;
   datetime t1;
   datetime t2;
   datetime t3;
   datetime t4;
   double   p1;
   double   p2;
   double   p3;
   double   p4;
  };

SAptPat         g_aptPat[14];
bool            g_patAnchorOk = false;
int             g_patAnchorX  = 0;
int             g_patAnchorY  = 0;
bool            g_patPosOk[14];
datetime        g_patPosT[14];
double          g_patPosP[14];

// Cache pivot/ATR theo tung khung (idx 0..13, chi so g_tfList). AptPatScanTF() chi chay lai AptPatCollect
//   (vong lap nang nhat - quet toi APT_PAT_LOOK nen) khi khung tf sang nen moi.
double          g_patCHiP[14][APT_PAT_PIVCAP];
int             g_patCHiS[14][APT_PAT_PIVCAP];
int             g_patCNH[14];
double          g_patCLoP[14][APT_PAT_PIVCAP];
int             g_patCLoS[14][APT_PAT_PIVCAP];
int             g_patCNL[14];
double          g_patCAtr[14];
datetime        g_patCBarT[14];
bool            g_patCReady[14];

double AptPatAtrTF(const ENUM_TIMEFRAMES tf,const int period)
  {
   int n = MathMax(2,period);
   double s = 0.0;
   int cnt = 0;
   for(int i=1; i<=n; i++)
     {
      double h = iHigh(_Symbol,tf,i);
      double l = iLow(_Symbol,tf,i);
      double pc = iClose(_Symbol,tf,i+1);
      if(h<=0.0 || l<=0.0)
         continue;
      double tr = h-l;
      if(pc>0.0)
        {
         double a = MathAbs(h-pc);
         double b = MathAbs(l-pc);
         if(a>tr) tr=a;
         if(b>tr) tr=b;
        }
      s += tr;
      cnt++;
     }
   if(cnt<=0)
      return(_Point);
   return(s/(double)cnt);
  }

//+------------------------------------------------------------------+
//  VUNG MAT CAN BANG (Imbalance) theo tung khung (hien trong cot Pattern qua AptImbalanceForTF()).
//  - Vung phan phoi can bang (Value Area) cua khung tf = vung gia gom APT_IMB_VA_PCT % tong tick volume, mo rong tu POC,
//    dung Volume Profile cua APT_IMB_VA_BARS nen DA DONG gan nhat (shift 1..N), chia APT_IMB_BINS muc gia.
//    Chi tinh lai khi khung tf sang nen moi. Profile dung tu nen con cua khung nguon AptImbSourceTF(tf).
//  - Bid > VAH hoac Bid < VAL -> dang o vung MAT CAN BANG.
//      muc do % = khoang cach Bid ra ngoai VA / do rong VA * 100
//                 (dau "+" = tren VAH, dau "-" = duoi VAL)
//      thoi gian = so giay tu khi Bid roi ra ngoai VA (cung phia).
//  - Trong VA / thieu du lieu -> tra ve chuoi rong "".
//+------------------------------------------------------------------+
#define APT_IMB_VA_BARS   20
#define APT_IMB_BINS      50
#define APT_IMB_VA_PCT    70.0
#define APT_IMB_BACK_M1   1440

double          g_imbVah[14];
double          g_imbVal[14];
bool            g_imbVaOk[14];
datetime        g_imbVaBarT[14];
int             g_imbDir[14];
datetime        g_imbStartT[14];
bool            g_imbInit[14];

// Khung NGUON dung de dung Volume Profile cho khung tf: nen con hep hon nhieu so voi nen cua tf, so nen can copy van nho (toi da ~1200 nen / khung):
//     1m..1h  -> M1     2h..4h -> M5     6h..12h -> M15
//     1d      -> M30    1w     -> H4     1nm     -> D1
ENUM_TIMEFRAMES AptImbSourceTF(const ENUM_TIMEFRAMES tf)
  {
   int sec = PeriodSeconds(tf);
   if(sec<=PeriodSeconds(PERIOD_H1))
      return(PERIOD_M1);
   if(sec<=PeriodSeconds(PERIOD_H4))
      return(PERIOD_M5);
   if(sec<=PeriodSeconds(PERIOD_H12))
      return(PERIOD_M15);
   if(sec<=PeriodSeconds(PERIOD_D1))
      return(PERIOD_M30);
   if(sec<=PeriodSeconds(PERIOD_W1))
      return(PERIOD_H4);
   return(PERIOD_D1);
  }

// Tinh Value Area (VAH/VAL) tu mang nen rates[0..cnt-1]: chia vung High-Low chung thanh APT_IMB_BINS muc gia,
//   rai tick volume cua moi nen deu len cac muc gia nam trong nen do, tim POC roi mo rong toi khi gom du APT_IMB_VA_PCT % tong volume.
bool AptImbValueAreaFromRates(const MqlRates &rates[],const int cnt,double &vah,double &val)
  {
   vah = 0.0;
   val = 0.0;
   if(cnt<3)
      return(false);

   double hi = -DBL_MAX;
   double lo =  DBL_MAX;
   for(int k=0; k<cnt; k++)
     {
      if(rates[k].high<=0.0 || rates[k].low<=0.0)
         return(false);
      if(rates[k].high>hi) hi = rates[k].high;
      if(rates[k].low <lo) lo = rates[k].low;
     }
   if(hi<=lo)
      return(false);

   double bs = (hi-lo)/(double)APT_IMB_BINS;
   if(bs<=0.0)
      return(false);

   double vol[];
   ArrayResize(vol,APT_IMB_BINS);
   ArrayInitialize(vol,0.0);
   double tot = 0.0;
   for(int k=0; k<cnt; k++)
     {
      double h = rates[k].high;
      double l = rates[k].low;
      double v = (double)rates[k].tick_volume;
      if(v<=0.0)
         v = 1.0;
      int b0 = (int)MathFloor((l-lo)/bs);
      int b1 = (int)MathFloor((h-lo)/bs);
      if(b0<0) b0 = 0;
      if(b1>APT_IMB_BINS-1) b1 = APT_IMB_BINS-1;
      if(b0>APT_IMB_BINS-1) b0 = APT_IMB_BINS-1;
      if(b1<b0) b1 = b0;
      double share = v/(double)(b1-b0+1);
      for(int b=b0; b<=b1; b++)
         vol[b] += share;
      tot += v;
     }
   if(tot<=0.0)
      return(false);

   int poc = 0;
   for(int b=1; b<APT_IMB_BINS; b++)
      if(vol[b]>vol[poc])
         poc = b;

   int    up  = poc;
   int    dn  = poc;
   double acc = vol[poc];
   double tgt = tot*APT_IMB_VA_PCT/100.0;
   while(acc<tgt && (up<APT_IMB_BINS-1 || dn>0))
     {
      double vUp = (up<APT_IMB_BINS-1) ? vol[up+1] : -1.0;
      double vDn = (dn>0)              ? vol[dn-1] : -1.0;
      if(vUp>=vDn)
        {
         up++;
         acc += vol[up];
        }
      else
        {
         dn--;
         acc += vol[dn];
        }
     }

   vah = lo+(double)(up+1)*bs;
   val = lo+(double)dn*bs;
   return(vah>val);
  }

// Value Area cua khung tf tren cua so APT_IMB_VA_BARS nen DA DONG gan nhat cua tf (tu open nen shift N den truoc open nen dang chay),
//   dung tu nen cua khung NGUON AptImbSourceTF(tf). Khung nguon thieu lich su (khong phu kin cua so) hoac copy that bai ->
//   dung truc tiep N nen cua chinh tf, va tra fine = false de noi goi THU LAI o nhip sau.
bool AptImbCalcValueArea(const ENUM_TIMEFRAMES tf,double &vah,double &val,bool &fine)
  {
   vah  = 0.0;
   val  = 0.0;
   fine = false;
   int bars = iBars(_Symbol,tf);
   int n    = MathMin(APT_IMB_VA_BARS,bars-1);
   if(n<3)
      return(false);

   datetime tStart = iTime(_Symbol,tf,n);
   datetime tEnd   = iTime(_Symbol,tf,0);
   if(tStart<=0 || tEnd<=tStart)
      return(false);

   MqlRates rates[];
   ENUM_TIMEFRAMES srcTf = AptImbSourceTF(tf);
   if(srcTf!=tf && PeriodSeconds(srcTf)<PeriodSeconds(tf))
     {
      int got = CopyRates(_Symbol,srcTf,tStart,tEnd-1,rates);
      if(got>=3 && rates[0].time<tStart+PeriodSeconds(tf))
        {
         fine = true;
         return(AptImbValueAreaFromRates(rates,got,vah,val));
        }
     }
   else
      fine = true;

   int got2 = CopyRates(_Symbol,tf,1,n,rates);
   if(got2<3)
      return(false);
   return(AptImbValueAreaFromRates(rates,got2,vah,val));
  }

string AptImbalanceForTF(const int idx,const ENUM_TIMEFRAMES tf)
  {
   datetime tBarNow = iTime(_Symbol,tf,0);
   if(tBarNow<=0)
      return("");
   if(g_imbVaBarT[idx]!=tBarNow)
     {
      double _vah,_val;
      bool   _fine = false;
      g_imbVaOk[idx]   = AptImbCalcValueArea(tf,_vah,_val,_fine);
      g_imbVah[idx]    = _vah;
      g_imbVal[idx]    = _val;
      // Chi chot cache theo nen khi da dung duoc tu khung nguon; neu phai dung nen cua chinh tf thi de nhip sau tinh lai.
      if(_fine)
         g_imbVaBarT[idx] = tBarNow;
     }
   if(!g_imbVaOk[idx])
      return("");

   double vah   = g_imbVah[idx];
   double val   = g_imbVal[idx];
   double width = vah-val;
   double bid   = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   if(bid<=0.0 || width<=0.0)
      return("");

   int dir = 0;
   if(bid>vah)      dir =  1;
   else if(bid<val) dir = -1;

   datetime now = TimeCurrent();
   if(!g_imbInit[idx])
     {
      g_imbInit[idx]   = true;
      g_imbDir[idx]    = dir;
      g_imbStartT[idx] = now;
      if(dir!=0)
        {
         // Lan dau: do nguoc tren M1 xem Bid da o ngoai VA (cung phia) tu luc nao
         int mx = MathMin(APT_IMB_BACK_M1,iBars(_Symbol,PERIOD_M1)-1);
         for(int sh=1; sh<=mx; sh++)
           {
            double c = iClose(_Symbol,PERIOD_M1,sh);
            if(c<=0.0)
               break;
            bool outSide = (dir>0) ? (c>vah) : (c<val);
            if(!outSide)
               break;
            datetime tm = iTime(_Symbol,PERIOD_M1,sh);
            if(tm>0)
               g_imbStartT[idx] = tm;
           }
        }
     }
   else if(dir!=g_imbDir[idx])
     {
      g_imbDir[idx]    = dir;
      g_imbStartT[idx] = now;
     }

   if(dir==0)
      return("");

   double pct = (dir>0) ? (bid-vah)/width*100.0 : (val-bid)/width*100.0;
   long   sec = (long)(now-g_imbStartT[idx]);
   if(sec<0)
      sec = 0;
   string sPct = (dir>0 ? "+" : "-") + IntegerToString((int)MathRound(pct)) + "%";
   // Thoi gian doi sang <ngay>.<gio>.<phut>.<giay>s, bo cac don vi lon bang 0 o dau, don vi phia sau luon 2 chu so:
   //     105 giay -> "1.45s"   2h05m30s -> "2.05.30s"   1d03h04m05s -> "1.03.04.05s"   9 giay -> "0.09s"
   long   dd   = sec/86400;
   long   hh   = (sec%86400)/3600;
   long   mm   = (sec%3600)/60;
   long   ss   = sec%60;
   string sSS  = (ss<10 ? "0" : "") + IntegerToString(ss);
   string sMM  = (mm<10 ? "0" : "") + IntegerToString(mm);
   string sHH  = (hh<10 ? "0" : "") + IntegerToString(hh);
   string sDur;
   if(dd>0)
      sDur = IntegerToString(dd) + "." + sHH + "." + sMM + "." + sSS + "s";
   else if(hh>0)
      sDur = IntegerToString(hh) + "." + sMM + "." + sSS + "s";
   else
      sDur = IntegerToString(mm) + "." + sSS + "s";
   return("(" + sPct + " " + sDur + ")");
  }

//==================================================================
//  AptLvnPushStr: <LVN> = vi tri Bid trong vung LVN (Low Volume Node) cua khung tf, in trong cot Pattern (giua <FVG> va <IMB>).
//  Dung CHUNG Volume Profile voi <IMB> (AptImbSourceTF / APT_IMB_VA_BARS nen DA DONG / APT_IMB_BINS muc gia, tick volume rai deu len cac muc nen cham).
//  Muc LVN = muc co volume < APT_LVN_PCT % volume cua POC (muc volume lon nhat). Cac muc LVN LIEN TIEP gop thanh 1 vung; vung ngan hon APT_LVN_MIN_BINS muc bi bo.
//  Bid nam TRONG mot vung LVN -> "<pct>L" (vd "45L"), pct = (Bid - mep duoi) / (mep tren - mep duoi) * 100, 0 = mep duoi, 100 = mep tren, lam tron so nguyen.
//  Cac vung LVN khong chong nhau nen Bid chi nam trong toi da 1 vung. Bid ngoai moi vung / thieu du lieu -> chuoi rong "".
//  Danh sach vung chi phu thuoc cac nen DA DONG nen cache theo nen cua khung tf; Bid kiem tra lai moi lan goi. Chi doc gia, khong tao object.
//==================================================================
#define APT_LVN_PCT       30.0
#define APT_LVN_MIN_BINS  2
#define APT_LVN_MAX       25     // = APT_IMB_BINS / 2: so vung LVN toi da (moi vung >= 2 muc, giua 2 vung co it nhat 1 muc khong thap)

datetime g_aptLvnBarT[14];
int      g_aptLvnCnt[14];
double   g_aptLvnLo[14][APT_LVN_MAX];
double   g_aptLvnHi[14][APT_LVN_MAX];

// Dung profile tu rates[0..cnt-1] (cung cach chia muc / rai volume nhu AptImbValueAreaFromRates), tim cac vung LVN, ghi vao hang idx cua g_aptLvnLo/Hi.
// Tra ve so vung (0 = khong co), -1 neu thieu du lieu.
int AptLvnZonesFromRates(const int idx,const MqlRates &rates[],const int cnt)
  {
   if(cnt<3)
      return(-1);

   double hi = -DBL_MAX;
   double lo =  DBL_MAX;
   for(int k=0; k<cnt; k++)
     {
      if(rates[k].high<=0.0 || rates[k].low<=0.0)
         return(-1);
      if(rates[k].high>hi) hi = rates[k].high;
      if(rates[k].low <lo) lo = rates[k].low;
     }
   if(hi<=lo)
      return(-1);

   double bs = (hi-lo)/(double)APT_IMB_BINS;
   if(bs<=0.0)
      return(-1);

   double vol[];
   ArrayResize(vol,APT_IMB_BINS);
   ArrayInitialize(vol,0.0);
   for(int k=0; k<cnt; k++)
     {
      double h = rates[k].high;
      double l = rates[k].low;
      double v = (double)rates[k].tick_volume;
      if(v<=0.0)
         v = 1.0;
      int b0 = (int)MathFloor((l-lo)/bs);
      int b1 = (int)MathFloor((h-lo)/bs);
      if(b0<0) b0 = 0;
      if(b1>APT_IMB_BINS-1) b1 = APT_IMB_BINS-1;
      if(b0>APT_IMB_BINS-1) b0 = APT_IMB_BINS-1;
      if(b1<b0) b1 = b0;
      double share = v/(double)(b1-b0+1);
      for(int b=b0; b<=b1; b++)
         vol[b] += share;
     }

   double vPoc = 0.0;
   for(int b=0; b<APT_IMB_BINS; b++)
      if(vol[b]>vPoc)
         vPoc = vol[b];
   if(vPoc<=0.0)
      return(-1);

   double thr      = vPoc*APT_LVN_PCT/100.0;
   int    n        = 0;
   int    runStart = -1;
   for(int b=0; b<=APT_IMB_BINS; b++)
     {
      bool low = (b<APT_IMB_BINS && vol[b]<thr);
      if(low)
        {
         if(runStart<0)
            runStart = b;
         continue;
        }
      if(runStart>=0)
        {
         if(b-runStart>=APT_LVN_MIN_BINS && n<APT_LVN_MAX)
           {
            g_aptLvnLo[idx][n] = lo+(double)runStart*bs;
            g_aptLvnHi[idx][n] = lo+(double)b*bs;
            n++;
           }
         runStart = -1;
        }
     }
   return(n);
  }

// Lay nen cho profile nhu AptImbCalcValueArea() (nen cua khung NGUON, thieu lich su -> nen cua chinh tf va fine = false de noi goi thu lai o nhip sau).
int AptLvnCalcZones(const int idx,const ENUM_TIMEFRAMES tf,bool &fine)
  {
   fine = false;
   int bars = iBars(_Symbol,tf);
   int n    = MathMin(APT_IMB_VA_BARS,bars-1);
   if(n<3)
      return(-1);

   datetime tStart = iTime(_Symbol,tf,n);
   datetime tEnd   = iTime(_Symbol,tf,0);
   if(tStart<=0 || tEnd<=tStart)
      return(-1);

   MqlRates rates[];
   ENUM_TIMEFRAMES srcTf = AptImbSourceTF(tf);
   if(srcTf!=tf && PeriodSeconds(srcTf)<PeriodSeconds(tf))
     {
      int got = CopyRates(_Symbol,srcTf,tStart,tEnd-1,rates);
      if(got>=3 && rates[0].time<tStart+PeriodSeconds(tf))
        {
         fine = true;
         return(AptLvnZonesFromRates(idx,rates,got));
        }
     }
   else
      fine = true;

   int got2 = CopyRates(_Symbol,tf,1,n,rates);
   if(got2<3)
      return(-1);
   return(AptLvnZonesFromRates(idx,rates,got2));
  }

string AptLvnPushStr(const int idx,const ENUM_TIMEFRAMES tf)
  {
   if(idx<0 || idx>=14)
      return("");
   datetime tBarNow = iTime(_Symbol,tf,0);
   if(tBarNow<=0)
      return("");

   if(g_aptLvnBarT[idx]!=tBarNow)
     {
      bool fine = false;
      int  n    = AptLvnCalcZones(idx,tf,fine);
      if(n<0)
         g_aptLvnCnt[idx] = 0;            // thieu du lieu -> nhip sau thu lai
      else
        {
         g_aptLvnCnt[idx] = n;
         if(fine)
            g_aptLvnBarT[idx] = tBarNow;
        }
     }
   if(g_aptLvnCnt[idx]<=0)
      return("");

   double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   if(bid<=0.0)
      return("");

   for(int j=0; j<g_aptLvnCnt[idx]; j++)
     {
      double lo = g_aptLvnLo[idx][j];
      double hi = g_aptLvnHi[idx][j];
      if(bid<lo || bid>hi)
         continue;
      double width = hi-lo;
      if(width<=0.0)
         continue;
      int pct = (int)MathRound((bid-lo)/width*100.0);
      return(IntegerToString(pct)+"L");
     }
   return("");
  }

//==================================================================
//  AptFvgPushStr: ky hieu FVG theo tung khung, in trong cot Pattern (ngay truoc gia tri imbalance).
//  Don vi $ (don vi gia, vd $/oz voi XAUUSD), khong doi ra point, lam tron so nguyen.
//  Nhan G chi hien khi Bid DANG NAM TRONG mot vung FVG cua khung tf; ngoai vung -> khong in gi.
//  Vung FVG cua khung tf: bo 3 nen A(i+2) - B(i+1) - C(i) lui toi da 120 nen,
//  loc nhieu chieu cao >= ATR x 0.10 (ATR = trung binh High-Low 14 nen DA DONG cua chinh khung tf, vi AptScanATR() chi phuc vu khung chart):
//    high(A) < low(C) -> FVG TANG [high(A) , low(C)]
//    low(A) > high(C) -> FVG GIAM [high(C) , low(A)]
//  Vung CON HIEU LUC khi CHUA co nen DA DONG nao (tu i-1 ve 1) dong cua vuot qua mep BEN KIA (FVG tang: Close < mep duoi; FVG giam: Close > mep tren).
//  Gia cham / lot vao trong vung khong lam mat hieu luc.
//  Bid nam trong vung con hieu luc (lay vung GAN NHAT neu nhieu vung chong nhau) -> vi tri Bid trong vung theo %,
//  cung mot cong thuc cho ca hai chieu (0 = mep duoi, 100 = mep tren), lam tron so nguyen:
//    pct = (Bid - mep duoi) / (mep tren - mep duoi) * 100
//    FVG tang -> "<pct>G"   (vd "87G")
//    FVG giam -> "-<pct>G"  (vd "-87G")
//  Danh sach vung chi phu thuoc cac nen DA DONG nen cache theo nen cua khung tf; Bid kiem tra lai moi lan goi.
//==================================================================
#define APT_FVGG_MAX 20

datetime g_fvgGBarT[14];
int      g_fvgGCnt[14];
int      g_fvgGDir[14][APT_FVGG_MAX];
double   g_fvgGLo[14][APT_FVGG_MAX];
double   g_fvgGHi[14][APT_FVGG_MAX];

// Tra ve so vung con hieu luc cua khung tf (luu vao hang idx), -1 neu thieu
// lich su (noi goi KHONG chot cache de nhip sau thu lai).
int AptFvgListTF(const int idx,const ENUM_TIMEFRAMES tf)
  {
   const int    LB     = 120;    // so bar lui ve quet
   const double MINATR = 0.10;   // loc nhieu
   const int    ATRN   = 14;     // so nen tinh trung binh High-Low

   int total = Bars(_Symbol,tf);
   int maxi  = MathMin(LB,total-4);
   if(maxi<3)
      return(-1);

   double atr = 0.0;
   int    atrCnt = 0;
   for(int a=1; a<=ATRN && a<total; a++)
     {
      double ha = iHigh(_Symbol,tf,a);
      double la = iLow (_Symbol,tf,a);
      if(ha<=0.0 || la<=0.0)
         continue;
      atr += (ha-la);
      atrCnt++;
     }
   if(atrCnt>0)
      atr /= (double)atrCnt;

   int cnt = 0;
   for(int i=1; i<=maxi && cnt<APT_FVGG_MAX; i++)
     {
      double hA = iHigh(_Symbol,tf,i+2);
      double lA = iLow (_Symbol,tf,i+2);
      double hC = iHigh(_Symbol,tf,i);
      double lC = iLow (_Symbol,tf,i);
      if(hA<=0.0 || lA<=0.0 || hC<=0.0 || lC<=0.0)
         continue;

      double gLo=0.0, gHi=0.0;
      int    d=0;
      if(hA < lC)
        {
         gLo = hA;
         gHi = lC;
         d   = 1;                                 // FVG tang
        }
      else
         if(lA > hC)
           {
            gLo = hC;
            gHi = lA;
            d   = -1;                             // FVG giam
           }
         else
            continue;

      if(gHi-gLo < MathMax(atr*MINATR,_Point))
         continue;

      //--- vung bi PHA: co nen DA DONG tu i-1 ve 1 dong cua vuot mep ben kia
      bool broken = false;
      for(int k=i-1; k>=1 && !broken; k--)
        {
         double ck = iClose(_Symbol,tf,k);
         if(ck<=0.0)
            continue;
         if(d>0 ? (ck < gLo) : (ck > gHi))
            broken = true;
        }
      if(broken)
         continue;

      g_fvgGDir[idx][cnt] = d;
      g_fvgGLo[idx][cnt]  = gLo;
      g_fvgGHi[idx][cnt]  = gHi;
      cnt++;
     }
   return(cnt);
  }

string AptFvgPushStr(const int idx,const ENUM_TIMEFRAMES tf)
  {
   if(idx<0 || idx>=14)
      return("");
   datetime tBarNow = iTime(_Symbol,tf,0);
   if(tBarNow<=0)
      return("");

   if(g_fvgGBarT[idx]!=tBarNow)
     {
      int n = AptFvgListTF(idx,tf);
      if(n<0)
         g_fvgGCnt[idx] = 0;             // thieu lich su -> nhip sau thu lai
      else
        {
         g_fvgGCnt[idx]  = n;
         g_fvgGBarT[idx] = tBarNow;
        }
     }
   if(g_fvgGCnt[idx]<=0)
      return("");

   double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   if(bid<=0.0)
      return("");

   for(int j=0; j<g_fvgGCnt[idx]; j++)
     {
      double lo = g_fvgGLo[idx][j];
      double hi = g_fvgGHi[idx][j];
      if(bid<lo || bid>hi)
         continue;
      int    dir   = g_fvgGDir[idx][j];
      double width = hi-lo;
      if(width<=0.0)
         continue;
      // % vi tri Bid trong vung (0..100)
      int    pct   = (int)MathRound((bid-lo)/width*100.0);
      return((dir>0 ? "" : "-") + IntegerToString(pct) + "G");
     }
   return("");
  }

bool AptPatNearEq(const double a,const double b,const double atr,const double tolPct)
  {
   double den = MathMax(MathAbs(a),MathMax(MathAbs(b),_Point));
   double pct = 100.0*MathAbs(a-b)/den;
   // Hai muc gan bang nhau khi THOA CA HAI dieu kien: lech % <= tolPct (InpPatEqTolPct) VA lech gia <= atr*0.35.
   return(pct<=tolPct && MathAbs(a-b)<=atr*0.35);
  }

bool AptPatInWin(const int bars,const int mn,const int mx)
  {
   return(bars>=mn && bars<=mx);
  }

double AptPatPctDiff(const double a,const double b)
  {
   double den = MathMax(MathAbs(a),MathMax(MathAbs(b),_Point));
   return(100.0*MathAbs(a-b)/den);
  }

double AptPatSlope(const double y1,const int x1,const double y2,const int x2)
  {
   int dx = x2-x1;
   if(dx<0) dx=-dx;
   if(dx<1) dx=1;
   return((y2-y1)/(double)dx);
  }

bool AptPatSwingAt(const ENUM_TIMEFRAMES tf,const int shift,const int leftB,const int rightB,const bool isHigh)
  {
   // shift<=rightB bi loai: moi pivot duoc cong nhan chi dung cac nen DA DONG (shift-rightB>=1), khong phu thuoc nen 0 (tranh pivot nhap nhay theo tick).
   if(shift<=rightB)
      return(false);
   double v = isHigh ? iHigh(_Symbol,tf,shift) : iLow(_Symbol,tf,shift);
   if(v<=0.0)
      return(false);
   for(int k=1; k<=leftB; k++)
     {
      double older = isHigh ? iHigh(_Symbol,tf,shift+k) : iLow(_Symbol,tf,shift+k);
      if(isHigh) { if(older>v) return(false); }
      else       { if(older<v && older>0.0) return(false); }
     }
   for(int k=1; k<=rightB; k++)
     {
      double newer = isHigh ? iHigh(_Symbol,tf,shift-k) : iLow(_Symbol,tf,shift-k);
      if(isHigh) { if(newer>v) return(false); }
      else       { if(newer<v && newer>0.0) return(false); }
     }
   return(true);
  }

void AptPatCollect(const ENUM_TIMEFRAMES tf,const int leftB,const int rightB,const int look,
                   double &hiP[],int &hiS[],int &nH,
                   double &loP[],int &loS[],int &nL)
  {
   nH=0; nL=0;
   int total=Bars(_Symbol,tf);
   int maxi=MathMin(look,total-leftB-2);
   if(maxi<rightB+1)
      return;
   for(int i=rightB; i<=maxi; i++)
     {
      if(AptPatSwingAt(tf,i,leftB,rightB,true) && nH<APT_PAT_PIVCAP)
        {
         // i chay tu nho (moi) den lon (cu) -> append giu 0 = newest
         hiP[nH]=iHigh(_Symbol,tf,i);
         hiS[nH]=i;
         nH++;
        }
      if(AptPatSwingAt(tf,i,leftB,rightB,false) && nL<APT_PAT_PIVCAP)
        {
         loP[nL]=iLow(_Symbol,tf,i);
         loS[nL]=i;
         nL++;
        }
      // Ca hai mang hiP/loP da day APT_PAT_PIVCAP -> dung vong lap som.
      if(nH>=APT_PAT_PIVCAP && nL>=APT_PAT_PIVCAP)
         break;
     }
  }

void AptPatClear(SAptPat &p)
  {
   p.valid=false;
   p.bias="BOTH";
   p.conf=0.0;
   p.mode=0;
   p.t1=0; p.t2=0; p.t3=0; p.t4=0;
   p.p1=0.0; p.p2=0.0; p.p3=0.0; p.p4=0.0;
  }

void AptPatKeep(SAptPat &best,const string bias,const double conf,
                const int mode,
                const datetime t1,const double p1,
                const datetime t2,const double p2,
                const datetime t3,const double p3,
                const datetime t4,const double p4)
  {
   if(conf+0.0001<best.conf)
      return;
   best.valid=true;
   best.bias=bias;
   best.conf=conf;
   best.mode=mode;
   best.t1=t1; best.p1=p1;
   best.t2=t2; best.p2=p2;
   best.t3=t3; best.p3=p3;
   best.t4=t4; best.p4=p4;
  }

// Quy doi so nen pivot/khoang cach swing theo TY LE thoi gian thuc cua tung khung so voi M1: cac gia tri InpPat* la "chuan tai M1"
//   (khung M1 co scale=1.0), khung lon duoc quy doi theo PeriodSeconds(tf)/PeriodSeconds(PERIOD_M1).
int AptPatTfBars(const int baseBars,const ENUM_TIMEFRAMES tf,const int minVal)
  {
   int baseSec = PeriodSeconds(PERIOD_M1);
   int tfSec   = PeriodSeconds(tf);
   if(baseSec<=0) baseSec=60;
   if(tfSec<=0)   tfSec=baseSec;
   double scale = MathSqrt((double)baseSec/(double)tfSec);
   int v = (int)MathRound((double)baseBars*scale);
   if(v<minVal) v=minVal;
   return(v);
  }

void AptPatScanTF(const ENUM_TIMEFRAMES tf,const int idx,SAptPat &out)
  {
   AptPatClear(out);
   int leftB  = AptPatTfBars(InpPatLeftBars,tf,2);
   int rightB = AptPatTfBars(InpPatRightBars,tf,1);
   int mn     = AptPatTfBars(InpPatMinBars,tf,3);
   int mx     = MathMax(mn+1,AptPatTfBars(InpPatMaxBars,tf,mn+1));
   double tol = InpPatEqTolPct;

   // Chi chay lai AptPatCollect (vong lap nang nhat - quet toi APT_PAT_LOOK nen) khi khung tf sang nen moi (so datetime nen 0);
   //   con lai dung pivot/ATR da cache trong g_patC*[idx].
   datetime tBarNow = iTime(_Symbol,tf,0);
   if(!g_patCReady[idx] || g_patCBarT[idx]!=tBarNow)
     {
      double hiP0[APT_PAT_PIVCAP];
      int    hiS0[APT_PAT_PIVCAP];
      double loP0[APT_PAT_PIVCAP];
      int    loS0[APT_PAT_PIVCAP];
      int nH0=0,nL0=0;
      AptPatCollect(tf,leftB,rightB,APT_PAT_LOOK,hiP0,hiS0,nH0,loP0,loS0,nL0);
      for(int q=0;q<nH0;q++) { g_patCHiP[idx][q]=hiP0[q]; g_patCHiS[idx][q]=hiS0[q]; }
      for(int q=0;q<nL0;q++) { g_patCLoP[idx][q]=loP0[q]; g_patCLoS[idx][q]=loS0[q]; }
      g_patCNH[idx]  = nH0;
      g_patCNL[idx]  = nL0;
      g_patCAtr[idx] = AptPatAtrTF(tf,MathMax(5,InpPatAtrLen));
      g_patCBarT[idx]= tBarNow;
      g_patCReady[idx]=true;
     }
   double atr = g_patCAtr[idx];
   if(atr<=0.0) atr=_Point;

   double hiP[APT_PAT_PIVCAP];
   int    hiS[APT_PAT_PIVCAP];
   double loP[APT_PAT_PIVCAP];
   int    loS[APT_PAT_PIVCAP];
   int nH=g_patCNH[idx],nL=g_patCNL[idx];
   for(int q=0;q<nH;q++) { hiP[q]=g_patCHiP[idx][q]; hiS[q]=g_patCHiS[idx][q]; }
   for(int q=0;q<nL;q++) { loP[q]=g_patCLoP[idx][q]; loS[q]=g_patCLoS[idx][q]; }

   double h0=iHigh(_Symbol,tf,0);
   double l0=iLow(_Symbol,tf,0);
   double c0=iClose(_Symbol,tf,0);
   datetime t0=iTime(_Symbol,tf,0);
   if(h0<=0.0 || t0<=0)
      return;

   bool candHigh=true, candLow=true;
   for(int k=1;k<=leftB;k++)
     {
      if(iHigh(_Symbol,tf,k)>h0) candHigh=false;
      double lk=iLow(_Symbol,tf,k);
      if(lk>0.0 && lk<l0) candLow=false;
     }

   int wspan;
   double mid;
   datetime ta,tb;

   // 1) Double Top / Bottom (forming + confirmed neckline)
   if(InpPatEnDT)
     {
      if(nH>=1 && candHigh)
        {
         wspan=hiS[0];
         if(AptPatInWin(wspan,mn,mx) && AptPatNearEq(h0,hiP[0],atr,tol) && h0<=hiP[0]+atr*0.15)
           {
            mid=iLow(_Symbol,tf,iLowest(_Symbol,tf,MODE_LOW,MathMax(1,wspan),0));
            if(hiP[0]-mid>=atr*0.8)
               AptPatKeep(out,"BEAR",70.0,2,
                          iTime(_Symbol,tf,hiS[0]),hiP[0],t0,h0,
                          iTime(_Symbol,tf,hiS[0]),mid,t0,mid);
           }
        }
      if(nL>=1 && candLow)
        {
         wspan=loS[0];
         if(AptPatInWin(wspan,mn,mx) && AptPatNearEq(l0,loP[0],atr,tol) && l0>=loP[0]-atr*0.15)
           {
            mid=iHigh(_Symbol,tf,iHighest(_Symbol,tf,MODE_HIGH,MathMax(1,wspan),0));
            if(mid-loP[0]>=atr*0.8)
               AptPatKeep(out,"BULL",70.0,2,
                          iTime(_Symbol,tf,loS[0]),loP[0],t0,l0,
                          iTime(_Symbol,tf,loS[0]),mid,t0,mid);
           }
        }
      if(nH>=2)
        {
         if(AptPatInWin(hiS[1]-hiS[0],mn,mx) && AptPatNearEq(hiP[1],hiP[0],atr,tol))
           {
            mid=iLow(_Symbol,tf,iLowest(_Symbol,tf,MODE_LOW,MathMax(1,hiS[1]),0));
            if(c0<=mid+atr*0.6 && c0<MathMin(hiP[0],hiP[1]))
               AptPatKeep(out,"BEAR",80.0,2,
                          iTime(_Symbol,tf,hiS[1]),hiP[1],iTime(_Symbol,tf,hiS[0]),hiP[0],
                          iTime(_Symbol,tf,hiS[1]),mid,t0,mid);
           }
        }
      if(nL>=2)
        {
         if(AptPatInWin(loS[1]-loS[0],mn,mx) && AptPatNearEq(loP[1],loP[0],atr,tol))
           {
            mid=iHigh(_Symbol,tf,iHighest(_Symbol,tf,MODE_HIGH,MathMax(1,loS[1]),0));
            if(c0>=mid-atr*0.6 && c0>MathMax(loP[0],loP[1]))
               AptPatKeep(out,"BULL",80.0,2,
                          iTime(_Symbol,tf,loS[1]),loP[1],iTime(_Symbol,tf,loS[0]),loP[0],
                          iTime(_Symbol,tf,loS[1]),mid,t0,mid);
           }
        }
     }

   // 2) Triple Top / Bottom
   if(InpPatEnTT)
     {
      if(nH>=2 && candHigh)
        {
         if(AptPatInWin(hiS[1]-hiS[0],mn,mx) && AptPatInWin(hiS[0],mn,mx)
            && AptPatNearEq(hiP[1],hiP[0],atr,tol) && AptPatNearEq(hiP[0],h0,atr,tol))
            AptPatKeep(out,"BEAR",68.0,3,
                       iTime(_Symbol,tf,hiS[1]),hiP[1],iTime(_Symbol,tf,hiS[0]),hiP[0],t0,h0,0,0.0);
        }
      if(nL>=2 && candLow)
        {
         if(AptPatInWin(loS[1]-loS[0],mn,mx) && AptPatInWin(loS[0],mn,mx)
            && AptPatNearEq(loP[1],loP[0],atr,tol) && AptPatNearEq(loP[0],l0,atr,tol))
            AptPatKeep(out,"BULL",68.0,3,
                       iTime(_Symbol,tf,loS[1]),loP[1],iTime(_Symbol,tf,loS[0]),loP[0],t0,l0,0,0.0);
        }
      if(nH>=3 && AptPatNearEq(hiP[2],hiP[1],atr,tol) && AptPatNearEq(hiP[1],hiP[0],atr,tol))
         AptPatKeep(out,"BEAR",75.0,3,
                    iTime(_Symbol,tf,hiS[2]),hiP[2],iTime(_Symbol,tf,hiS[1]),hiP[1],
                    iTime(_Symbol,tf,hiS[0]),hiP[0],0,0.0);
      if(nL>=3 && AptPatNearEq(loP[2],loP[1],atr,tol) && AptPatNearEq(loP[1],loP[0],atr,tol))
         AptPatKeep(out,"BULL",75.0,3,
                    iTime(_Symbol,tf,loS[2]),loP[2],iTime(_Symbol,tf,loS[1]),loP[1],
                    iTime(_Symbol,tf,loS[0]),loP[0],0,0.0);
     }

   // 3) Head & Shoulders / Inverse
   if(InpPatEnHS)
     {
      double headMin=atr*InpPatHsHeadMin;
      if(nH>=2 && nL>=1 && candHigh)
        {
         if(hiS[0]>hiS[1] && hiP[0]>hiP[1]+headMin && hiP[0]>h0+headMin
            && AptPatPctDiff(hiP[1],h0)<=InpPatHsSym
            && AptPatInWin(hiS[0]-hiS[1],mn,mx) && AptPatInWin(hiS[0],mn,mx))
            AptPatKeep(out,"BEAR",72.0,3,
                       iTime(_Symbol,tf,hiS[1]),hiP[1],iTime(_Symbol,tf,hiS[0]),hiP[0],t0,h0,0,0.0);
        }
      if(nL>=2 && nH>=1 && candLow)
        {
         if(loS[0]>loS[1] && loP[0]<loP[1]-headMin && loP[0]<l0-headMin
            && AptPatPctDiff(loP[1],l0)<=InpPatHsSym
            && AptPatInWin(loS[0]-loS[1],mn,mx) && AptPatInWin(loS[0],mn,mx))
            AptPatKeep(out,"BULL",72.0,3,
                       iTime(_Symbol,tf,loS[1]),loP[1],iTime(_Symbol,tf,loS[0]),loP[0],t0,l0,0,0.0);
        }
       // Nhanh 3 swing cua VDV / VDV nguoc chi bao khi:
       //   (1) khoang cach giua cac swing nam trong cua so [mn,mx] (cung quy uoc cac mau hinh khac);
       //   (2) co duong co (muc thap nhat / cao nhat cua swing nguoc chieu nam GIUA ba swing);
       //   (3) gia dong cua c0 CHUA chay qua duong co hon 0.5*ATR theo chieu bao tin hieu
       //       (VDV nguoc: c0 <= co + 0.5*ATR ; VDV: c0 >= co - 0.5*ATR).
      if(nH>=3)
        {
         bool   _hsNeckOk = false;
         double _hsNeck   = 0.0;
         if(AptPatInWin(hiS[1]-hiS[0],mn,mx) && AptPatInWin(hiS[2]-hiS[1],mn,mx))
            for(int _q=0; _q<nL; _q++)
               if(loS[_q]>hiS[0] && loS[_q]<hiS[2])
                 {
                  if(!_hsNeckOk || loP[_q]<_hsNeck) _hsNeck=loP[_q];
                  _hsNeckOk=true;
                 }
         if(_hsNeckOk && c0>=_hsNeck-0.5*atr &&
            hiP[1]>hiP[2]+headMin && hiP[1]>hiP[0]+headMin && AptPatPctDiff(hiP[2],hiP[0])<=InpPatHsSym)
            AptPatKeep(out,"BEAR",82.0,3,
                       iTime(_Symbol,tf,hiS[2]),hiP[2],iTime(_Symbol,tf,hiS[1]),hiP[1],
                       iTime(_Symbol,tf,hiS[0]),hiP[0],0,0.0);
        }
      if(nL>=3)
        {
         bool   _hsNeckOk2 = false;
         double _hsNeck2   = 0.0;
         if(AptPatInWin(loS[1]-loS[0],mn,mx) && AptPatInWin(loS[2]-loS[1],mn,mx))
            for(int _q=0; _q<nH; _q++)
               if(hiS[_q]>loS[0] && hiS[_q]<loS[2])
                 {
                  if(!_hsNeckOk2 || hiP[_q]>_hsNeck2) _hsNeck2=hiP[_q];
                  _hsNeckOk2=true;
                 }
         if(_hsNeckOk2 && c0<=_hsNeck2+0.5*atr &&
            loP[1]<loP[2]-headMin && loP[1]<loP[0]-headMin && AptPatPctDiff(loP[2],loP[0])<=InpPatHsSym)
            AptPatKeep(out,"BULL",82.0,3,
                       iTime(_Symbol,tf,loS[2]),loP[2],iTime(_Symbol,tf,loS[1]),loP[1],
                       iTime(_Symbol,tf,loS[0]),loP[0],0,0.0);
        }
     }

   // 4) Rounding Top / Bottom
   if(InpPatEnRound)
     {
      int w=MathMin(40,MathMax(16,leftB*5));
      if(Bars(_Symbol,tf)>w+5)
        {
         double hiW=iHigh(_Symbol,tf,iHighest(_Symbol,tf,MODE_HIGH,w,0));
         double loW=iLow(_Symbol,tf,iLowest(_Symbol,tf,MODE_LOW,w,0));
         double o0=iOpen(_Symbol,tf,0);
         int midFrom=w/3;
         int midTo=2*w/3;
         int hiAt=iHighest(_Symbol,tf,MODE_HIGH,w,0);
         bool midPeak=(hiAt>=midFrom && hiAt<=midTo);
          // Luu 3 moc: vai trai cua so -> dinh (hiW) -> vai phai (nen 0).
          //   mode=3 dung 2 doan PAT_L1/L2; p4=hiW de ve them PAT_L3 nam ngang tai noc.
         if(midPeak && hiW-c0>=atr*0.7 && c0<o0 && h0<hiW)
           {
            datetime tL=iTime(_Symbol,tf,w);
            datetime tPk=iTime(_Symbol,tf,hiAt);
            double   pL=iHigh(_Symbol,tf,w);
            if(tL<=0) tL=t0;
            if(tPk<=0) tPk=t0;
            if(pL<=0.0) pL=hiW;
            AptPatKeep(out,"BEAR",58.0,3,
                       tL,pL,tPk,hiW,t0,h0,tL,hiW);
           }
         if(c0-loW>=atr*0.7 && c0>o0 && l0>loW)
           {
            int loAt=iLowest(_Symbol,tf,MODE_LOW,w,0);
            datetime tL=iTime(_Symbol,tf,w);
            datetime tPk=iTime(_Symbol,tf,loAt);
            double   pL=iLow(_Symbol,tf,w);
            if(tL<=0) tL=t0;
            if(tPk<=0) tPk=t0;
            if(pL<=0.0) pL=loW;
            AptPatKeep(out,"BULL",58.0,3,
                       tL,pL,tPk,loW,t0,l0,tL,loW);
           }
        }
     }

   // 5) Diamond
   if(InpPatEnDiamond && nH>=3 && nL>=3)
     {
      double r2=hiP[2]-loP[2];
      double r1=hiP[1]-loP[1];
      double r0=hiP[0]-loP[0];
      if(r1>r2*1.15 && r0<r1*0.85 && r1>atr*1.2)
        {
         if(c0<(hiP[0]+loP[0])*0.5)
            AptPatKeep(out,"BEAR",60.0,2,
                       iTime(_Symbol,tf,hiS[1]),hiP[1],iTime(_Symbol,tf,hiS[0]),hiP[0],
                       iTime(_Symbol,tf,loS[1]),loP[1],iTime(_Symbol,tf,loS[0]),loP[0]);
         else
            AptPatKeep(out,"BULL",60.0,2,
                       iTime(_Symbol,tf,hiS[1]),hiP[1],iTime(_Symbol,tf,hiS[0]),hiP[0],
                       iTime(_Symbol,tf,loS[1]),loP[1],iTime(_Symbol,tf,loS[0]),loP[0]);
        }
     }

   // 6) Triangle
   if(InpPatEnTri && nH>=2 && nL>=2)
     {
      double sh=AptPatSlope(hiP[1],hiS[1],hiP[0],hiS[0]);
      double sl=AptPatSlope(loP[1],loS[1],loP[0],loS[0]);
      double startGap=MathAbs(hiP[1]-loP[1]);
      double endGap  =MathAbs(hiP[0]-loP[0]);
      bool squeeze=(endGap<startGap*0.85 && startGap>atr*0.8);
      bool flatH=(MathAbs(sh)<atr*0.02);
      bool flatL=(MathAbs(sl)<atr*0.02);
      double projH=hiP[0]+sh*(0-hiS[0]);
      double projL=loP[0]+sl*(0-loS[0]);
      bool inside=(c0<MathMax(projH,hiP[0])+atr*0.15 && c0>MathMin(projL,loP[0])-atr*0.15);
      int span=MathMax(hiS[0],loS[0])-MathMin(hiS[1],loS[1]);
      if(squeeze && inside && AptPatInWin(span,mn,mx))
        {
         ta=iTime(_Symbol,tf,hiS[1]); tb=iTime(_Symbol,tf,loS[1]);
         if(flatH && sl>0.0)
            AptPatKeep(out,"BULL",74.0,2,
                       ta,hiP[1],t0,projH,tb,loP[1],t0,projL);
         else if(flatL && sh<0.0)
            AptPatKeep(out,"BEAR",74.0,2,
                       ta,hiP[1],t0,projH,tb,loP[1],t0,projL);
         else if(sh<0.0 && sl>0.0)
            AptPatKeep(out,"BOTH",72.0,2,
                       ta,hiP[1],t0,projH,tb,loP[1],t0,projL);
        }
     }

   // 7) Wedge
   if(InpPatEnWedge && nH>=2 && nL>=2)
     {
      double sh=AptPatSlope(hiP[1],hiS[1],hiP[0],hiS[0]);
      double sl=AptPatSlope(loP[1],loS[1],loP[0],loS[0]);
      double startGap=MathAbs(hiP[1]-loP[1]);
      double endGap  =MathAbs(hiP[0]-loP[0]);
      bool squeeze=(endGap<startGap*0.8);
      double projH=hiP[0]+sh*(0-hiS[0]);
      double projL=loP[0]+sl*(0-loS[0]);
      bool inside=(c0<=MathMax(projH,hiP[0])+atr*0.2 && c0>=MathMin(projL,loP[0])-atr*0.2);
      if(squeeze && inside)
        {
         ta=iTime(_Symbol,tf,hiS[1]); tb=iTime(_Symbol,tf,loS[1]);
         if(sh>0.0 && sl>0.0)
            AptPatKeep(out,"BEAR",66.0,2,
                       ta,hiP[1],t0,projH,tb,loP[1],t0,projL);
         else if(sh<0.0 && sl<0.0)
            AptPatKeep(out,"BULL",66.0,2,
                       ta,hiP[1],t0,projH,tb,loP[1],t0,projL);
        }
     }

   // 8) Rectangle
   if(InpPatEnRect && nH>=2 && nL>=2)
     {
      bool okH=AptPatNearEq(hiP[0],hiP[1],atr,tol);
      bool okL=AptPatNearEq(loP[0],loP[1],atr,tol);
      if(nH>=3) okH=okH && (AptPatNearEq(hiP[0],hiP[2],atr,tol) || AptPatPctDiff(hiP[0],hiP[2])<tol*1.6);
      if(nL>=3) okL=okL && (AptPatNearEq(loP[0],loP[2],atr,tol) || AptPatPctDiff(loP[0],loP[2])<tol*1.6);
      double height=(hiP[0]+hiP[1])*0.5-(loP[0]+loP[1])*0.5;
      bool inside=(c0<=MathMax(hiP[0],hiP[1])+atr*0.15 && c0>=MathMin(loP[0],loP[1])-atr*0.15);
      int span=MathMin(hiS[1],loS[1]);
      if(okH && okL && height>atr*0.7 && inside && span>=mn)
         AptPatKeep(out,"BOTH",70.0,2,
                    iTime(_Symbol,tf,hiS[1]),hiP[1],t0,hiP[0],
                    iTime(_Symbol,tf,loS[1]),loP[1],t0,loP[0]);
     }

   // 9) Flag / Pennant
    // Dieu kien co: "pole" (xung):
    //     - chieu cao pole = High-Low CUA SO pole
    //     - huong pole = thu tu thoi gian cua dinh/day (day CU + dinh MOI = xung LEN; nguoc lai = xung XUONG)
    //     - gia hien tai phai CON nam dung nua pole, CHUA phu toan bo xung va CHUA pha moc bat dau pole
    //       (neu pha roi thi la dao chieu / trend moi, khong con la co).
   if(InpPatEnFlag)
     {
      int poleLook=MathMax(8,InpPatPoleLook);
      if(Bars(_Symbol,tf)>poleLook+5 && nH>=2 && nL>=2)
        {
         int poleTo  =MathMax(3,poleLook/3);          // het pole / dau co
         int poleLen =poleLook-poleTo+1;
         int ihPole  =iHighest(_Symbol,tf,MODE_HIGH,poleLen,poleTo);
         int ilPole  =iLowest (_Symbol,tf,MODE_LOW ,poleLen,poleTo);
         double poleHi=(ihPole>=0) ? iHigh(_Symbol,tf,ihPole) : 0.0;
         double poleLo=(ilPole>=0) ? iLow (_Symbol,tf,ilPole) : 0.0;
         double poleH =poleHi-poleLo;
         int consN=MathMax(5,poleLook/3);
         double rngCons=iHigh(_Symbol,tf,iHighest(_Symbol,tf,MODE_HIGH,consN,0))
                       -iLow (_Symbol,tf,iLowest (_Symbol,tf,MODE_LOW ,consN,0));
         // Co phai la hoi nong sau xung, khong phai chinh cai trend.
         bool compact=(rngCons<atr*2.2 && poleH>0.0 && rngCons<poleH*0.72);
         double sh=AptPatSlope(hiP[1],hiS[1],hiP[0],hiS[0]);
         double sl=AptPatSlope(loP[1],loS[1],loP[0],loS[0]);
         double midPole=(poleHi+poleLo)*0.5;
         // shift lon = cu hon. Xung LEN: day xuat hien TRUOC dinh.
         bool impulseUp  =(poleH>atr*InpPatPoleAtr && ilPole>ihPole && ihPole>=0 && poleHi>0.0);
         bool impulseDn  =(poleH>atr*InpPatPoleAtr && ihPole>ilPole && ilPole>=0 && poleLo>0.0);
         // Chua pha moc bat dau pole + van dung nua dung huong.
         bool holdBull   =(c0>midPole && l0>poleLo-atr*0.15 && hiP[0]<=poleHi+atr*0.20);
         bool holdBear   =(c0<midPole && h0<poleHi+atr*0.15 && loP[0]>=poleLo-atr*0.20);
         if(impulseUp && compact && holdBull)
           {
            if(sh<=0.0 && sl<=0.0)
               AptPatKeep(out,"BULL",69.0,2,
                          iTime(_Symbol,tf,hiS[1]),hiP[1],iTime(_Symbol,tf,hiS[0]),hiP[0],
                          iTime(_Symbol,tf,loS[1]),loP[1],iTime(_Symbol,tf,loS[0]),loP[0]);
            else if(sh<0.0 && sl>0.0)
               AptPatKeep(out,"BULL",69.0,2,
                          iTime(_Symbol,tf,hiS[1]),hiP[1],iTime(_Symbol,tf,hiS[0]),hiP[0],
                          iTime(_Symbol,tf,loS[1]),loP[1],iTime(_Symbol,tf,loS[0]),loP[0]);
           }
         if(impulseDn && compact && holdBear)
           {
            if(sh>=0.0 && sl>=0.0)
               AptPatKeep(out,"BEAR",69.0,2,
                          iTime(_Symbol,tf,hiS[1]),hiP[1],iTime(_Symbol,tf,hiS[0]),hiP[0],
                          iTime(_Symbol,tf,loS[1]),loP[1],iTime(_Symbol,tf,loS[0]),loP[0]);
            else if(sh<0.0 && sl>0.0)
               AptPatKeep(out,"BEAR",69.0,2,
                          iTime(_Symbol,tf,hiS[1]),hiP[1],iTime(_Symbol,tf,hiS[0]),hiP[0],
                          iTime(_Symbol,tf,loS[1]),loP[1],iTime(_Symbol,tf,loS[0]),loP[0]);
           }
        }
     }

   // 10) Cup and Handle
   if(InpPatEnCup && nH>=2 && nL>=1)
     {
      int width=hiS[1]-hiS[0];
      if(width<0) width=-width;
      double cupLow=iLow(_Symbol,tf,iLowest(_Symbol,tf,MODE_LOW,MathMax(1,hiS[1]),0));
      double depth=(hiP[1]+hiP[0])*0.5-cupLow;
      bool depthOk=(depth>=atr*1.4 && depth/MathMax(hiP[1],_Point)<=0.45);
      bool rimsOk=AptPatNearEq(hiP[1],hiP[0],atr,tol) || AptPatPctDiff(hiP[1],hiP[0])<=tol*1.8;
      int lowAt=iLowest(_Symbol,tf,MODE_LOW,MathMax(1,hiS[1]),0);
      bool rounded=(lowAt>width*0.15 && lowAt<width*0.85);
      bool handleNow=(c0<hiP[0] && c0>cupLow+depth*0.5 && c0<hiP[0]-depth*0.08);
      if(width>=InpPatCupMin && width<=InpPatCupMax && depthOk && rimsOk && rounded && handleNow)
         AptPatKeep(out,"BULL",71.0,2,
                    iTime(_Symbol,tf,hiS[1]),hiP[1],iTime(_Symbol,tf,hiS[0]),hiP[0],
                    iTime(_Symbol,tf,hiS[1]),cupLow,iTime(_Symbol,tf,hiS[0]),cupLow+depth*0.15);
      if(nL>=2 && nH>=1)
        {
         int w2=loS[1]-loS[0];
         if(w2<0) w2=-w2;
         double cupHi=iHigh(_Symbol,tf,iHighest(_Symbol,tf,MODE_HIGH,MathMax(1,loS[1]),0));
         double dep2=cupHi-(loP[1]+loP[0])*0.5;
         if(w2>=InpPatCupMin && w2<=InpPatCupMax && AptPatNearEq(loP[1],loP[0],atr,tol) && dep2>=atr*1.4)
           {
            if(c0>loP[0] && c0<cupHi-dep2*0.5)
               AptPatKeep(out,"BEAR",64.0,2,
                          iTime(_Symbol,tf,loS[1]),loP[1],iTime(_Symbol,tf,loS[0]),loP[0],
                          iTime(_Symbol,tf,loS[1]),cupHi,iTime(_Symbol,tf,loS[0]),cupHi-dep2*0.15);
           }
        }
     }

   if(!out.valid)
     {
     }
  }

//==================================================================
//  Gia tren 1 doan duong hinh mau tai moc atT: noi suy / keo dai tuyen tinh theo 2 moc (t1,p1)-(t2,p2) ma
//  DrawAptSelectedPattern() ve (MakeTrend PFX"PAT_L*"). Tra 0.0 neu doan khong hop le.
//==================================================================
double AptPatLinePriceAt(const datetime t1,const double p1,
                         const datetime t2,const double p2,
                         const datetime atT)
  {
   if(t1<=0 || t2<=0 || p1<=0.0 || p2<=0.0)
      return(0.0);
   long dt=(long)t2-(long)t1;
   if(dt==0)
      return(p2);
   double k=(double)((long)atT-(long)t1)/(double)dt;
   double px=p1+(p2-p1)*k;
   if(px<=0.0)
      return(0.0);
   return(px);
  }

//+------------------------------------------------------------------+

color AptPatColor(const SAptPat &p)
  {
   if(!p.valid)
      return(clrSilver);
   if(p.bias=="BULL")
      return(clrLime);
   if(p.bias=="BEAR")
      return(clrOrange);
   return(clrGold);
  }

void AptPatDelSeg(const string name)
  {
   // Xoa 1 doan PAT_L* cung nhan khung di kem (name + "_TF").
   ObjectDelete(0,name);
   ObjectDelete(0,name+"_TF");
  }

void AptPatDrawPatternOf(const SAptPat &p,const string tfTxt)
  {
   // Ve toi da 3 doan PAT_L1 / PAT_L2 / PAT_L3 cua mau hinh p:
   //   mode 2 (day doi...) : L1 = 2 day, L2 = neckline;  mode 3 (noc/day tron): L1, L2 = 2 doan dau, L3 = doan ngang tai noc/day (p4).
   // tfTxt = nhan khung (vd "4H") ghi o CUOI moi doan de phan biet dang ve khung nao.
   if(!p.valid || p.mode<=0 || p.t1<=0 || p.t2<=0)
     {
      AptPatDelSeg(PFX"PAT_L1");
      AptPatDelSeg(PFX"PAT_L2");
      AptPatDelSeg(PFX"PAT_L3");
      return;
     }
   color col=AptPatColor(p);
   AptPatDrawOneSeg(PFX"PAT_L1",p.t1,p.p1,p.t2,p.p2,col,tfTxt);
   if(p.mode==2 && p.t3>0 && p.t4>0)
     {
      AptPatDrawOneSeg(PFX"PAT_L2",p.t3,p.p3,p.t4,p.p4,col,tfTxt);
      AptPatDelSeg(PFX"PAT_L3");
     }
   else if(p.mode==3 && p.t3>0)
     {
      AptPatDrawOneSeg(PFX"PAT_L2",p.t2,p.p2,p.t3,p.p3,col,tfTxt);
      if(p.p4>0.0 && p.t1>0 && p.t3>0)
         AptPatDrawOneSeg(PFX"PAT_L3",p.t1,p.p4,p.t3,p.p4,col,tfTxt);
      else
         AptPatDelSeg(PFX"PAT_L3");
     }
   else
     {
      AptPatDelSeg(PFX"PAT_L2");
      AptPatDelSeg(PFX"PAT_L3");
     }
  }

void AptPatDrawOneSeg(const string name,const datetime t1,const double p1,
                      const datetime t2,const double p2,const color col,const string tfTxt)
  {
   // Ve 1 doan PAT_L* bang MakeTrend. Keo moc 2 toi TimeCurrent() theo dung do doc (t1,p1)-(t2,p2)
   //   de duong di toi cho Bid dang chay, trung voi AptPatLinePriceAt().
   // Ghi nhan khung (OBJ_TEXT name+"_TF", cung mau duong, neo trai) tai diem cuoi (tB,pB).
   if(t1<=0 || t2<=0 || p1<=0.0 || p2<=0.0)
     {
      AptPatDelSeg(name);
      return;
     }
   datetime tB=t2;
   double   pB=p2;
   datetime nowT=TimeCurrent();
   if(nowT>t2)
     {
      double px=AptPatLinePriceAt(t1,p1,t2,p2,nowT);
      if(px>0.0)
        {
         tB=nowT;
         pB=px;
        }
     }
   MakeTrend(name,t1,p1,tB,pB,col,STYLE_SOLID,2);
   MakeText(name+"_TF",tB,pB," "+tfTxt,col,ANCHOR_LEFT);
  }

string AptPatTfText(const ENUM_TIMEFRAMES tf)
  {
   // Nhan khung ghi cuoi duong pattern: 1M 5M 15M 30M 1H 2H 3H 4H 6H 8H 12H 1D 1W 1MN.
   // Khong dung g_tfName[] vi mang do khai bao SAU ham nay (MQL5 can khai bao bien toan cuc truoc khi dung).
   switch(tf)
     {
      case PERIOD_M1:  return("1M");
      case PERIOD_M5:  return("5M");
      case PERIOD_M15: return("15M");
      case PERIOD_M30: return("30M");
      case PERIOD_H1:  return("1H");
      case PERIOD_H2:  return("2H");
      case PERIOD_H3:  return("3H");
      case PERIOD_H4:  return("4H");
      case PERIOD_H6:  return("6H");
      case PERIOD_H8:  return("8H");
      case PERIOD_H12: return("12H");
      case PERIOD_D1:  return("1D");
      case PERIOD_W1:  return("1W");
      case PERIOD_MN1: return("1MN");
     }
   return("");
  }

void DrawAptSelectedPattern()
  {
   // Ve pattern cua khung dang chon o bang nut chon khung than nen lon (CreateTFPanels / g_btnBcPrefix / g_barTF);
   ENUM_TIMEFRAMES tf=g_barTF;
   if(tf==PERIOD_CURRENT)
      tf=_Period;

   int idx=-1;
   for(int i=0;i<14;i++)
      if(g_tfList[i]==tf)
        { idx=i; break; }
   if(idx<0)
     {
      AptPatDelSeg(PFX"PAT_L1");
      AptPatDelSeg(PFX"PAT_L2");
      AptPatDelSeg(PFX"PAT_L3");
      return;
     }
   AptPatDrawPatternOf(g_aptPat[idx],AptPatTfText(tf));
  }

// Khai bao truoc DrawAptLvlColumn() (than ham nam sau GetRV2Color(), vi dung g_color[]): cot nhan <TenMuc> lich su tren dinh nen 1m.
void DrawAptLvlColumn();
void DrawAptRndDiffColumn();   // khai bao truoc: than ham nam o duoi (cot v0..v4 duoi day nen 1m)

// Khai bao truoc AptPivotRowColor() (than ham nam o duoi, sau DrawAptPatternColumn): cot Pattern goi no de to mau theo cot nhan Pivot.
color AptPivotRowColor(const ENUM_TIMEFRAMES tf);

// Khai bao truoc 2 ham dung trong DrawAptPatternColumn(): than ham nam o duoi (gan DrawBrkDHHLL()).
string AptRv1MdStr(const ENUM_TIMEFRAMES tf);
string AptOwStr(const ENUM_TIMEFRAMES tf, string &outCnt);
void   DrawOwLine();   // dinh nghia sau SpmUpsertTrendSeg()
void   DrawOwLabelsAll();   // dinh nghia ngay sau DrawBrkDHHLL()
void DrawAptPatternColumn()
  {
   // Quet 14 khung (AptPatScanTF -> g_aptPat[]) + ve cot nhan Pattern: neo mep TRAI tai g_rv1M1LblT (moc nhan RV1 1m),
   // gia = RV1(1m) + InpPatAboveRv1Pts point (du phong: dinh nen M1 + InpPatAbovePts); khung 1m o DUOI CUNG.
   for(int i=0;i<14;i++)
     {
      AptPatScanTF(g_tfList[i],i,g_aptPat[i]);
     }

   // Ve duong pattern ngay sau khi quet, truoc moi nhanh return cua cot nhan (neo that bai / thieu nen M1).
   DrawAptSelectedPattern();

   // Cot nhan <TenMuc> lich su tren dinh cac nen 1m gan nhat (input nhom "16."); doc lap voi cot Pattern nen goi truoc moi nhanh return ben duoi.
   DrawAptLvlColumn();

   // [GIU NGUYEN - KHONG XOA] // Cot v0..v4 (chenh lech so voi muc lam tron gan nhat) duoi day nen 1m hien tai; doc lap voi cot Pattern nen cung goi truoc moi nhanh return ben duoi.
   // [GIU NGUYEN - KHONG XOA] DrawAptRndDiffColumn();
   // Da bo cot v0..v4 duoi day nen 1m: khong goi DrawAptRndDiffColumn() nua (ham con trong file); xoa object cot con sot lai (PFX"RDC_0".."RDC_4").
   for(int _rdcK = 0; _rdcK < 5; _rdcK++)
      ObjectDelete(0, PFX"RDC_" + IntegerToString(_rdcK));

   datetime tM1=iTime(_Symbol,PERIOD_M1,0);
   double   highM1=iHigh(_Symbol,PERIOD_M1,0);
   if(tM1<=0 || highM1<=0.0)
      return;

   int lineH=InpFontSize+7;
   // Neo cot Pattern theo nhan RV1 khung 1m:
   //   - Truc THOI GIAN: g_rv1M1LblT (mep trai khu vuc nhan RV1 1m). Chua co (0) -> du phong tM1.
   //   - Truc GIA: gia RV1 1m (g_rv1ValCache[chi so khung 1m]) + InpPatAboveRv1Pts point. Chua co RV1 1m -> du phong dinh nen M1 + InpPatAbovePts point.
   datetime tAnc=(g_rv1M1LblT>0) ? g_rv1M1LblT : tM1;
   double   rv1M1P=0.0;
   int      rv1M1Idx=AptFindTfIndex(PERIOD_M1);
   if(rv1M1Idx>=0 && rv1M1Idx<14)
      rv1M1P=g_rv1ValCache[rv1M1Idx];
   double highLbl=(rv1M1P>0.0) ? rv1M1P+InpPatAboveRv1Pts*_Point : highM1+InpPatAbovePts*_Point;
   int xC=0,yC=0;
   if(ChartTimePriceToXY(0,0,tAnc,highLbl,xC,yC))
     {
      g_patAnchorOk=true;
      g_patAnchorX=xC;
      g_patAnchorY=yC;
     }
   else
     {
      if(!g_patAnchorOk)
         return;
      xC=g_patAnchorX;
      yC=g_patAnchorY;
     }

   // Nhan neo mep TRAI (ANCHOR_LEFT_LOWER) tai g_rv1M1LblT: x = xC.
   int xLeft=xC;

   for(int i=0;i<14;i++)
     {
      // i=0 (1m) o DUOI CUNG: yPix = yC  (gia ~ highLbl)
      // khung lon hon xep LEN TREN: yPix giam (man hinh)
      int xPix=xLeft;
      int yPix=yC-lineH*i;
      int subWin=0;
      datetime tItem=tAnc;
      double   pItem=highLbl;
      if(ChartXYToTimePrice(0,xPix,yPix,subWin,tItem,pItem))
        {
         g_patPosOk[i]=true;
         g_patPosT[i]=tItem;
         g_patPosP[i]=pItem;
        }
      else
        {
         if(!g_patPosOk[i])
            continue;
         tItem=g_patPosT[i];
         pItem=g_patPosP[i];
        }
      // Truc THOI GIAN co dinh = moc nhan RV1 1m (chi lay GIA tu pixel).
      tItem=tAnc;
      AptImbalanceForTF(i,g_tfList[i]);
      // Cot Pattern: <TF>{<DxyTenMuc>} <UpE>/<DnE> <UpB>/<DnB> <Up>/<Dn> <UpC>/<DnC> <UpA>/<DnA> <FVG><LVN><IMB> (g_patCdlStr[]; chua co -> chi <TF>{<DxyTenMuc>})
      string txt=(g_patCdlStr[i]!="") ? g_patCdlStr[i] : (g_tfLabel[i] + AptDxyLvlTag(g_tfList[i]));
      // Mau nhan cot Pattern DOI THEO mau nhan cot Pivot cua CHINH khung nay: dung AptPivotRowColor(tf) -
      //   CUNG ham to mau nhan Pivot (lvlLblClr trong DrawWoodiePivotEma())
      color  clr=AptPivotRowColor(g_tfList[i]);
      // Neo mep TRAI-DUOI (cung mep trai voi nhan RV1 1m)
      MakeText(PFX"PATL_"+IntegerToString(i),tItem,pItem,txt,clr,ANCHOR_LEFT_LOWER);
     }
  }

//==================================================================
//  DrawBrkDHHLL: danh dau HH, LL va MD cua KENH brkD tren khung g_tfList[g_aptBrkDTfIdx].
//    Kenh = g_aptBrkDBars nen ngay TRUOC nen dang chay cua khung do (shift 1..N) - chinh kenh AptBrkDAt() dung (cung kep 2..500).
//    HH = High cao nhat, LL = Low thap nhat cua kenh. Moi nhan la 1 OBJ_TEXT tai GIA HH/LL, THOI GIAN = than nen lon dang ve,
//    nam ngay tren than nen lon: "HH<khung>" (neo phia tren) va "LL<khung>" (neo phia duoi), vd "HH1m", "LL1m"; them PFX"BKMD" (MD).
//    Object text: PFX"BKHH" / PFX"BKLL" / PFX"BKMD" (OnDeinit don bang ObjectsDeleteAll(0,PFX)).
//    idx = -1 (tat) hoac thieu du lieu -> xoa nhan, khong doan.
//==================================================================
datetime BarChartMidTime(const int s, const datetime barOpen, const long secPerBar);   // khai bao truoc: than ham nam o duoi

//==================================================================
//  OW tinh tren khung tf, chu ky n (n = g_aptBrkDBars, nut B<n>), chi dung cac nen DA DONG (shift >= 1). Cach tinh theo OW MODE UI (g_aptOwMode):
//    LWMA      : OW = LWMA(Open, n), trong so n..1 (nen moi nhat trong so n).
//    EMA       : OW = EMA(Open, n), alpha = 2/(n+1), hat giong = SMA(Open) cua n nen CU NHAT trong cua so.
//    EMA(LWMA) : OW = EMA(n) ap len chuoi LWMA(Open, n) (hat giong = SMA cua n gia tri LWMA cu nhat).
//  AptOpenEmaSeries (giu ten ham): CHUOI OW, outOw[s] = OW tinh den het nen DA DONG shift s+1 (outOw[0] = gia tri OW dung cho nen dang chay = OW tai nen shift 1).
//    Cua so: LWMA = want + n - 1 nen; EMA = want + APT_OW_EMA_WARM_MULT*n nen; EMA(LWMA) = want + n - 1 + APT_OW_EMA_WARM_MULT*n nen (khoi dong EMA);
//    kep theo so nen co san - lich su ngan hon -> it nen khoi dong hon.
//    want = so diem toi da can lay. Tra ve so diem (0 = thieu du lieu: it hon n+1 nen da dong, CopyOpen loi, gia <= 0). Chi doc gia, khong tao object.
//==================================================================
#define APT_OW_EMA_WARM_MULT 10

// [GIU NGUYEN - KHONG XOA] int AptOpenEmaSeries(const ENUM_TIMEFRAMES tf, const int n, const int want, double &outOw[])
// [GIU NGUYEN - KHONG XOA]   {
// [GIU NGUYEN - KHONG XOA]    ArrayResize(outOw, 0);
// [GIU NGUYEN - KHONG XOA]    if(n < 2 || want < 1)
// [GIU NGUYEN - KHONG XOA]       return 0;
// [GIU NGUYEN - KHONG XOA]    int avail = Bars(_Symbol, tf) - 1;      // so nen DA DONG kha dung (shift >= 1)
// [GIU NGUYEN - KHONG XOA]    if(avail < n + 1)
// [GIU NGUYEN - KHONG XOA]       return 0;
// [GIU NGUYEN - KHONG XOA]    int need = want + APT_OW_EMA_WARM_MULT * n;
// [GIU NGUYEN - KHONG XOA]    if(need > avail)
// [GIU NGUYEN - KHONG XOA]       need = avail;
// [GIU NGUYEN - KHONG XOA] 
// [GIU NGUYEN - KHONG XOA]    double op[];
// [GIU NGUYEN - KHONG XOA]    ArraySetAsSeries(op, false);             // op[0] = nen CU NHAT, op[got-1] = nen shift 1 (moi nhat)
// [GIU NGUYEN - KHONG XOA]    int got = CopyOpen(_Symbol, tf, 1, need, op);
// [GIU NGUYEN - KHONG XOA]    if(got < n + 1)
// [GIU NGUYEN - KHONG XOA]       return 0;
// [GIU NGUYEN - KHONG XOA]    for(int c = 0; c < got; c++)
// [GIU NGUYEN - KHONG XOA]       if(!(op[c] > 0.0))
// [GIU NGUYEN - KHONG XOA]          return 0;
// [GIU NGUYEN - KHONG XOA] 
// [GIU NGUYEN - KHONG XOA]    int points = got - n + 1;                // EMA co gia tri tu c = n-1 (hat giong) den c = got-1
// [GIU NGUYEN - KHONG XOA]    if(points > want)
// [GIU NGUYEN - KHONG XOA]       points = want;
// [GIU NGUYEN - KHONG XOA]    ArrayResize(outOw, points);
// [GIU NGUYEN - KHONG XOA] 
// [GIU NGUYEN - KHONG XOA]    double alpha = 2.0 / (n + 1.0);
// [GIU NGUYEN - KHONG XOA]    double ema   = 0.0;
// [GIU NGUYEN - KHONG XOA]    for(int c = 0; c < n; c++)
// [GIU NGUYEN - KHONG XOA]       ema += op[c];
// [GIU NGUYEN - KHONG XOA]    ema /= (double)n;                        // hat giong SMA tai c = n-1
// [GIU NGUYEN - KHONG XOA]    for(int c = n - 1; c < got; c++)
// [GIU NGUYEN - KHONG XOA]      {
// [GIU NGUYEN - KHONG XOA]       if(c > n - 1)
// [GIU NGUYEN - KHONG XOA]          ema = alpha * op[c] + (1.0 - alpha) * ema;
// [GIU NGUYEN - KHONG XOA]       int s = got - 1 - c;                  // chi so series: s = 0 la nen shift 1
// [GIU NGUYEN - KHONG XOA]       if(s < points)
// [GIU NGUYEN - KHONG XOA]          outOw[s] = ema;
// [GIU NGUYEN - KHONG XOA]      }
// [GIU NGUYEN - KHONG XOA]    if(!(outOw[0] > 0.0))
// [GIU NGUYEN - KHONG XOA]      {
// [GIU NGUYEN - KHONG XOA]       ArrayResize(outOw, 0);
// [GIU NGUYEN - KHONG XOA]       return 0;
// [GIU NGUYEN - KHONG XOA]      }
// [GIU NGUYEN - KHONG XOA]    return points;
// [GIU NGUYEN - KHONG XOA]   }
int AptOpenEmaSeries(const ENUM_TIMEFRAMES tf, const int n, const int want, double &outOw[])
  {
   ArrayResize(outOw, 0);
   if(n < 2 || want < 1)
      return 0;
   int avail = Bars(_Symbol, tf) - 1;      // so nen DA DONG kha dung (shift >= 1)
   if(avail < n + 1)
      return 0;
   int mode = g_aptOwMode;
   if(mode < 0 || mode >= APT_OW_MODE_COUNT)
      mode = APT_OW_MODE_EMA;

   int need = want + APT_OW_EMA_WARM_MULT * n;               // EMA
   if(mode == APT_OW_MODE_LWMA)
      need = want + n - 1;
   else if(mode == APT_OW_MODE_EMA_LWMA)
      need = want + n - 1 + APT_OW_EMA_WARM_MULT * n;
   if(need > avail)
      need = avail;

   double op[];
   ArraySetAsSeries(op, false);             // op[0] = nen CU NHAT, op[got-1] = nen shift 1 (moi nhat)
   int got = CopyOpen(_Symbol, tf, 1, need, op);
   // LWMA can dung n nen (want = 1 -> need = n); EMA / EMA(LWMA) can it nhat n + 1 nen. Truoc day luon doi n + 1 -> LWMA voi want = 1 (AptOpenLwma()) luon that bai
   //   -> <Owtron>, [<diffpv3>], <diffavg>, <RV1OW>, moc lam tron <khung>OW deu thanh "-" khi chon che do LWMA o OW MODE UI.
   int minGot = (mode == APT_OW_MODE_LWMA) ? n : n + 1;
   if(got < minGot)
      return 0;
   for(int c = 0; c < got; c++)
      if(!(op[c] > 0.0))
         return 0;

   // Buoc 1: chuoi nguon src[] theo thu tu thoi gian (src[L-1] = gia tri tai nen shift 1): EMA -> Open; LWMA / EMA(LWMA) -> LWMA(Open, n).
   double src[];
   int    L = 0;
   if(mode == APT_OW_MODE_EMA)
     {
      L = got;
      ArrayResize(src, L);
      for(int c = 0; c < L; c++)
         src[c] = op[c];
     }
   else
     {
      L = got - n + 1;                      // LWMA co gia tri tai nen op[c + n - 1], c = 0..L-1
      ArrayResize(src, L);
      double sw = (double)n * (double)(n + 1) / 2.0;
      for(int c = 0; c < L; c++)
        {
         double sv = 0.0;
         for(int j = 0; j < n; j++)
            sv += (double)(j + 1) * op[c + j];   // nen moi nhat (j = n-1) trong so n
         src[c] = sv / sw;
        }
     }

   // LWMA: tra thang chuoi LWMA
   if(mode == APT_OW_MODE_LWMA)
     {
      int pts = (L < want) ? L : want;
      if(pts < 1)
         return 0;
      ArrayResize(outOw, pts);
      for(int s = 0; s < pts; s++)
         outOw[s] = src[L - 1 - s];
      if(!(outOw[0] > 0.0))
        {
         ArrayResize(outOw, 0);
         return 0;
        }
      return pts;
     }

   // Buoc 2 (EMA / EMA(LWMA)): EMA(n) tren src[], hat giong = SMA cua n gia tri CU NHAT
   if(L < n)
      return 0;
   int points = L - n + 1;                  // EMA co gia tri tu c = n-1 (hat giong) den c = L-1
   if(points > want)
      points = want;
   ArrayResize(outOw, points);

   double alpha = 2.0 / (n + 1.0);
   double ema   = 0.0;
   for(int c = 0; c < n; c++)
      ema += src[c];
   ema /= (double)n;                        // hat giong SMA tai c = n-1
   for(int c = n - 1; c < L; c++)
     {
      if(c > n - 1)
         ema = alpha * src[c] + (1.0 - alpha) * ema;
      int s = L - 1 - c;                    // chi so series: s = 0 la nen shift 1
      if(s < points)
         outOw[s] = ema;
     }
   if(!(outOw[0] > 0.0))
     {
      ArrayResize(outOw, 0);
      return 0;
     }
   return points;
  }

//==================================================================
//  AptOpenLwma: (giu ten ham cu) tra OW (cach tinh theo OW MODE UI: LWMA / EMA / EMA(LWMA)) chu ky n tren khung tf, tinh tren cac nen DA DONG (gia tri tai nen shift 1 - AptOpenEmaSeries()[0]).
//    n = g_aptBrkDBars (nut B<n>). Truoc day la LWMA(Open) (trong so n..1, giu nguyen than ham cu ben duoi dang [GIU NGUYEN - KHONG XOA]).
//    Thieu du lieu (it hon n + 1 nen da dong, CopyOpen loi, gia <= 0) -> false, noi goi xoa nhan, khong doan. Chi doc gia, khong tao object.
//==================================================================
// [GIU NGUYEN - KHONG XOA] bool AptOpenLwma(const ENUM_TIMEFRAMES tf, const int n, double &outLwma)
// [GIU NGUYEN - KHONG XOA]   {
// [GIU NGUYEN - KHONG XOA]    outLwma = 0.0;
// [GIU NGUYEN - KHONG XOA]    if(n < 2)
// [GIU NGUYEN - KHONG XOA]       return false;
// [GIU NGUYEN - KHONG XOA]    int avail = Bars(_Symbol, tf) - 1;      // so nen DA DONG kha dung (shift >= 1)
// [GIU NGUYEN - KHONG XOA]    if(avail < n + 1)
// [GIU NGUYEN - KHONG XOA]       return false;
// [GIU NGUYEN - KHONG XOA] 
// [GIU NGUYEN - KHONG XOA]    double op[];
// [GIU NGUYEN - KHONG XOA]    ArraySetAsSeries(op, true);              // op[0] = Open nen shift 1 (moi nhat)
// [GIU NGUYEN - KHONG XOA]    if(CopyOpen(_Symbol, tf, 1, n, op) != n)
// [GIU NGUYEN - KHONG XOA]       return false;
// [GIU NGUYEN - KHONG XOA] 
// [GIU NGUYEN - KHONG XOA]    // LWMA: n nen moi nhat, trong so n..1
// [GIU NGUYEN - KHONG XOA]    double sw = 0.0, sv = 0.0;
// [GIU NGUYEN - KHONG XOA]    for(int i = 0; i < n; i++)
// [GIU NGUYEN - KHONG XOA]      {
// [GIU NGUYEN - KHONG XOA]       double w = (double)(n - i);
// [GIU NGUYEN - KHONG XOA]       sw += w;
// [GIU NGUYEN - KHONG XOA]       sv += w * op[i];
// [GIU NGUYEN - KHONG XOA]      }
// [GIU NGUYEN - KHONG XOA]    if(sw <= 0.0)
// [GIU NGUYEN - KHONG XOA]       return false;
// [GIU NGUYEN - KHONG XOA]    outLwma = sv / sw;
// [GIU NGUYEN - KHONG XOA]    return(outLwma > 0.0);
// [GIU NGUYEN - KHONG XOA]   }
bool AptOpenLwma(const ENUM_TIMEFRAMES tf, const int n, double &outLwma)
  {
   outLwma = 0.0;
   double ow[];
   if(AptOpenEmaSeries(tf, n, 1, ow) < 1)
      return false;
   outLwma = ow[0];
   return(outLwma > 0.0);
  }

//==================================================================
//  AptOwSeries: CHUOI OW = EMA(Open) chu ky n cua khung tf, DUNG CACH DrawOwLine() ve duong OW tren chart:
//    outOw[k] = EMA(Open) tinh den het nen DA DONG shift k+1 (AptOpenEmaSeries()); outOw[0] = nen dang chay = gia tri nhan OW (= AptOpenLwma()).
//    want = so diem toi da can lay. Tra ve so diem (0 = thieu du lieu / CopyOpen loi -> noi goi in "-"). Chi doc gia, khong tao object.
//==================================================================
int AptOwSeries(const ENUM_TIMEFRAMES tf, const int n, const int want, double &outOw[])
  {
   // [GIU NGUYEN - KHONG XOA] ArrayResize(outOw, 0);
   // [GIU NGUYEN - KHONG XOA] if(n < 2 || want < 1)
   // [GIU NGUYEN - KHONG XOA]    return 0;
   // [GIU NGUYEN - KHONG XOA] double op[];
   // [GIU NGUYEN - KHONG XOA] ArraySetAsSeries(op, true);              // op[i] = Open nen shift i+1
   // [GIU NGUYEN - KHONG XOA] int got = CopyOpen(_Symbol, tf, 1, want + n, op);
   // [GIU NGUYEN - KHONG XOA] if(got < n + 1)
   // [GIU NGUYEN - KHONG XOA]    return 0;
   // [GIU NGUYEN - KHONG XOA] int points = got - n + 1;                // diem s can op[s .. s+n-1]
   // [GIU NGUYEN - KHONG XOA] if(points > want)
   // [GIU NGUYEN - KHONG XOA]    points = want;
   // [GIU NGUYEN - KHONG XOA] if(points < 1)
   // [GIU NGUYEN - KHONG XOA]    return 0;
   // [GIU NGUYEN - KHONG XOA] double sw = 0.0;
   // [GIU NGUYEN - KHONG XOA] for(int i = 0; i < n; i++)
   // [GIU NGUYEN - KHONG XOA]    sw += (double)(n - i);
   // [GIU NGUYEN - KHONG XOA] if(sw <= 0.0)
   // [GIU NGUYEN - KHONG XOA]    return 0;
   // [GIU NGUYEN - KHONG XOA] ArrayResize(outOw, points);
   // [GIU NGUYEN - KHONG XOA] for(int s = 0; s < points; s++)
   // [GIU NGUYEN - KHONG XOA]   {
   // [GIU NGUYEN - KHONG XOA]    double sv = 0.0;
   // [GIU NGUYEN - KHONG XOA]    for(int j = 0; j < n; j++)
   // [GIU NGUYEN - KHONG XOA]       sv += (double)(n - j) * op[s + j];
   // [GIU NGUYEN - KHONG XOA]    outOw[s] = sv / sw;
   // [GIU NGUYEN - KHONG XOA]   }
   // [GIU NGUYEN - KHONG XOA] return points;
   return AptOpenEmaSeries(tf, n, want, outOw);
  }

//==================================================================
//  AptRv1LwmaCrossCnt: SO NEN TF tu khi MOT duong cat duong EMA(Open) (= OW) cua CHINH khung tf. Co 2 loai duong (tham so kind):
//    kind = 0 : RV1 (chuoi AptRvSeries(); rv[0] = nen dang chay = rvNow = g_rv1ValCache[idx]; rv[k] = RV1 luc dong nen TF thu k).
//               Dung cho nhan OW<khung> (chu "OW1m -5").
//    kind = 1 : gia tri PIVOT cua muc dang chon o bang Pivot UI (g_pivotLevelIdx, mac dinh PP) = EMA(InpWoodiePivotEmaPeriod) tren chuoi muc Woodie
//               cua khung tf - CHINH chuoi duong EMA Pivot ve tren chart (AptPivotUiEmaSeries(); [0] = nen dang chay, [k] = nen shift k).
//               Gia tri hien tai (nen dang chay) ham TU tinh moi lan goi tu H/L/C hien tai (rvNow bi bo qua). Dung cho <so nen> cua nhan RV1 va <pls>.
//    LWMA = (ten bien giu nguyen) OW = EMA(Open) chu ky n = g_aptBrkDBars tren cac nen DA DONG (AptOpenEmaSeries()).
//           Gia tri tai nen k (k >= 1) = EMA(Open) tinh den het nen shift k; k = 0 (nen dang chay) dung gia tri tai nen shift 1.
//    Phia cua moi nen = dau cua (duong - LWMA). outCnt = (phia hien tai) * (so nen LIEN TIEP tu nen dang chay k = 0 lui ve qua khu co CUNG phia; nen cat = nen cu nhat cua day, tinh la 1).
//    DUONG = duong tren LWMA (vuot LEN), AM = duong duoi LWMA (vuot XUONG), 0 = hai duong bang nhau. Chua gap cat trong cua so -> tra so nen toi da cua cua so.
//    Phan nen DA DONG (k >= 1) chi doi khi khung sang nen moi / doi n (nut B<n>) / (kind 1) doi muc Pivot UI nen duoc nho theo (khung, kind); chi so sanh gia tri hien tai voi LWMA moi lan goi.
//    Thieu du lieu (kind 0: rvNow <= 0; thieu nen, AptRvSeries/AptPivotUiEmaSeries/CopyOpen loi) -> false, noi goi in "-". Chi doc gia, khong tao object.
//==================================================================
// Khai bao truoc (than ham nam sau cac bien Pivot UI / WoodieLevelValue, xem khoi "AptPivotUiEmaSeries" ngay duoi WoodieLevelValue):
double WoodieLevelValue(const int lvl, const double hB, const double lB, const double cB);
int    AptPivotUiLevelIdx();
int    AptPivotEmaPeriod();
int    AptPivotUiEmaSeries(const ENUM_TIMEFRAMES tf, const int want, double &outEma[]);

#define APT_RVX_SLOTS 32
ENUM_TIMEFRAMES g_aptRvXTf   [APT_RVX_SLOTS];   // khung cua o nho (PERIOD_CURRENT = 0 = o trong)
int             g_aptRvXKind [APT_RVX_SLOTS];   // loai duong cua o nho: 0 = RV1, 1 = Pivot UI
datetime        g_aptRvXBar  [APT_RVX_SLOTS];   // iTime(tf,0) luc dung o nho
int             g_aptRvXN    [APT_RVX_SLOTS];   // n luc dung o nho
int             g_aptRvXLvl  [APT_RVX_SLOTS];   // kind 1: muc Pivot UI luc dung o nho (-1 = kind 0 / chua co)
double          g_aptRvXLw0  [APT_RVX_SLOTS];   // EMA(Open) hien tai (shift 1..n)
double          g_aptRvXPvE1 [APT_RVX_SLOTS];   // kind 1: EMA Pivot tai nen TF shift 1 (de tinh EMA hien tai moi tick)
int             g_aptRvXSide1[APT_RVX_SLOTS];   // phia (duong - LWMA) tai nen TF shift 1
int             g_aptRvXRun1 [APT_RVX_SLOTS];   // so nen LIEN TIEP tu shift 1 lui ve co CUNG phia voi shift 1
ulong           g_aptRvXFail [APT_RVX_SLOTS];   // moc GetTickCount64() lan dung o nho that bai gan nhat (0 = khong loi) - gian cach thu lai 5 giay
bool            g_aptRvXFound[APT_RVX_SLOTS];   // true = tim thay NEN CAT (nen cu nhat cua day cung phia voi shift 1) trong cua so lich su
double          g_aptRvXCutPx[APT_RVX_SLOTS];   // gia tri duong luc dong nen cat (khi g_aptRvXFound)
datetime        g_aptRvXCutT [APT_RVX_SLOTS];   // thoi diem dong nen cat (= gio mo nen ke sau) (khi g_aptRvXFound)
datetime        g_aptRvXC0Bar [APT_RVX_SLOTS];  // iTime(tf,0) luc ghi nhan duong vua cat sang phia moi NGAY TRONG nen dang chay (0 = khong co)
int             g_aptRvXC0Side[APT_RVX_SLOTS];  // huong cat cua diem cat trong nen dang chay (+1 len / -1 xuong)
datetime        g_aptRvXC0T  [APT_RVX_SLOTS];   // TimeCurrent() o lan DAU thay duong o phia moi cua LWMA trong nen dang chay
double          g_aptRvXC0Px [APT_RVX_SLOTS];   // gia tri duong tai thoi diem do

bool AptRv1LwmaCrossBuild(const ENUM_TIMEFRAMES tf, const int n, const int kind, double &outLw0, int &outSide1, int &outRun1, bool &outFound, double &outCutPx, datetime &outCutT, double &outE1)
  {
   outLw0   = 0.0;
   outSide1 = 0;
   outRun1  = 0;
   outFound = false;
   outCutPx = 0.0;
   outCutT  = 0;
   outE1    = 0.0;
   int availBars = Bars(_Symbol, tf) - 1;      // so nen DA DONG kha dung (shift >= 1)
   if(availBars < n + 1)
      return false;

   double rvS[];
   int av = (kind == 1) ? AptPivotUiEmaSeries(tf, 3 * n + 200, rvS)   // rvS[0] = nen dang chay, rvS[k] = EMA Pivot nen TF shift k
                        : AptRvSeries(tf, rvS, 3 * n + 200);          // rvS[0] = nen dang chay, rvS[k] = RV1 luc dong nen TF thu k
   if(av < 3)
      return false;
   outE1 = rvS[1];

   // [GIU NGUYEN - KHONG XOA] int kMax   = av - 1;                         // k = 1..kMax
   // [GIU NGUYEN - KHONG XOA] int needOp = (kMax - 1) + n;                 // LWMA tai k dung op[k-1 .. k-1+n-1]
   // [GIU NGUYEN - KHONG XOA] if(needOp > availBars)
   // [GIU NGUYEN - KHONG XOA]   {
   // [GIU NGUYEN - KHONG XOA]    needOp = availBars;
   // [GIU NGUYEN - KHONG XOA]    kMax   = needOp - n + 1;
   // [GIU NGUYEN - KHONG XOA]   }
   // [GIU NGUYEN - KHONG XOA] if(kMax < 1)
   // [GIU NGUYEN - KHONG XOA]    return false;
   // [GIU NGUYEN - KHONG XOA] 
   // [GIU NGUYEN - KHONG XOA] double op[];
   // [GIU NGUYEN - KHONG XOA] ArraySetAsSeries(op, true);                  // op[0] = Open nen shift 1 (moi nhat)
   // [GIU NGUYEN - KHONG XOA] if(CopyOpen(_Symbol, tf, 1, needOp, op) != needOp)
   // [GIU NGUYEN - KHONG XOA]    return false;
   // [GIU NGUYEN - KHONG XOA] 
   // [GIU NGUYEN - KHONG XOA] double sw  = (double)n * (double)(n + 1) / 2.0;
   // [GIU NGUYEN - KHONG XOA] int    run = 0;
   // [GIU NGUYEN - KHONG XOA] for(int k = 1; k <= kMax; k++)
   // [GIU NGUYEN - KHONG XOA]   {
   // [GIU NGUYEN - KHONG XOA]    int    i = k - 1;
   // [GIU NGUYEN - KHONG XOA]    double v = 0.0;
   // [GIU NGUYEN - KHONG XOA]    for(int j = 0; j < n; j++)
   // [GIU NGUYEN - KHONG XOA]       v += (double)(n - j) * op[i + j];
   // [GIU NGUYEN - KHONG XOA]    double lw = v / sw;
   int kMax   = av - 1;                         // k = 1..kMax
   double owS[];
   int owN = AptOpenEmaSeries(tf, n, kMax, owS);   // owS[k-1] = OW = EMA(Open) tinh den het nen DA DONG shift k
   if(owN < kMax)
      kMax = owN;
   if(kMax < 1)
      return false;

   int    run = 0;
   for(int k = 1; k <= kMax; k++)
     {
      double lw = owS[k - 1];
      if(!(lw > 0.0))
         return false;
      int side = (rvS[k] > lw) ? 1 : ((rvS[k] < lw) ? -1 : 0);
      if(k == 1)
        {
         outLw0   = lw;
         outSide1 = side;
         run      = 1;
        }
      else
        {
         if(side != outSide1)
           {
            outFound = true;
            break;
           }
         run++;
        }
     }
   outRun1 = run;
   // Diem cat = nen cu nhat cua day cung phia voi shift 1 (nen thu "run"): gia tri duong luc dong nen do + thoi diem dong nen do (= gio mo nen shift run-1).
   if(outFound && outSide1 != 0 && run >= 1)
     {
      outCutPx = rvS[run];
      outCutT  = iTime(_Symbol, tf, run - 1);
      if(!(outCutPx > 0.0) || outCutT <= 0)
         outFound = false;
     }
   else
      outFound = false;
   return true;
  }

bool AptRv1LwmaCrossCnt(const ENUM_TIMEFRAMES tf, const int n, const double rvNow, int &outCnt, const int kind = 0)
  {
   outCnt = 0;
   if(n < 2)
      return false;
   if(kind == 0 && !(rvNow > 0.0))
      return false;
   datetime bar0 = iTime(_Symbol, tf, 0);
   if(bar0 <= 0)
      return false;
   int lvlNow = (kind == 1) ? AptPivotUiLevelIdx() : -1;

   int slot = -1, freeSlot = -1;
   for(int s = 0; s < APT_RVX_SLOTS; s++)
     {
      if(g_aptRvXTf[s] == tf && g_aptRvXKind[s] == kind)
        {
         slot = s;
         break;
        }
      if(freeSlot < 0 && g_aptRvXTf[s] == PERIOD_CURRENT)
         freeSlot = s;
     }
   if(slot < 0)
     {
      slot = (freeSlot >= 0) ? freeSlot : 0;
      g_aptRvXTf[slot]    = tf;
      g_aptRvXKind[slot]  = kind;
      g_aptRvXBar[slot]   = 0;
      g_aptRvXN[slot]     = 0;
      g_aptRvXLvl[slot]   = -1;
      g_aptRvXFail[slot]  = 0;
      g_aptRvXFound[slot] = false;
      g_aptRvXC0Bar[slot] = 0;
     }

   // [GIU NGUYEN - KHONG XOA] if(g_aptRvXBar[slot] != bar0 || g_aptRvXN[slot] != n || g_aptRvXLvl[slot] != lvlNow)
   if(g_aptRvXBar[slot] != bar0 || g_aptRvXN[slot] != AptOwModeKey(n) || g_aptRvXLvl[slot] != lvlNow)
     {
      ulong nowMs = GetTickCount64();
      if(g_aptRvXFail[slot] != 0 && (nowMs - g_aptRvXFail[slot]) < 5000)
         return false;
      double lw0 = 0.0;
      int    s1 = 0, r1 = 0;
      bool     fnd = false;
      double   cpx = 0.0;
      datetime ct  = 0;
      double   e1  = 0.0;
      if(!AptRv1LwmaCrossBuild(tf, n, kind, lw0, s1, r1, fnd, cpx, ct, e1))
        {
         g_aptRvXFail[slot] = nowMs + 1;
         g_aptRvXBar[slot]  = 0;
         return false;
        }
      // [GIU NGUYEN - KHONG XOA] if(g_aptRvXN[slot] != n || g_aptRvXLvl[slot] != lvlNow)
      if(g_aptRvXN[slot] != AptOwModeKey(n) || g_aptRvXLvl[slot] != lvlNow)
         g_aptRvXC0Bar[slot] = 0;   // doi n / doi che do OW / doi muc Pivot UI -> bo diem cat trong nen dang chay da ghi
      g_aptRvXFail[slot]  = 0;
      g_aptRvXBar[slot]   = bar0;
      // [GIU NGUYEN - KHONG XOA] g_aptRvXN[slot]     = n;
      g_aptRvXN[slot]     = AptOwModeKey(n);   // n + che do OW
      g_aptRvXLvl[slot]   = lvlNow;
      g_aptRvXLw0[slot]   = lw0;
      g_aptRvXPvE1[slot]  = e1;
      g_aptRvXSide1[slot] = s1;
      g_aptRvXRun1[slot]  = r1;
      g_aptRvXFound[slot] = fnd;
      g_aptRvXCutPx[slot] = cpx;
      g_aptRvXCutT[slot]  = ct;
     }

   // Gia tri hien tai cua duong: kind 0 = rvNow do noi goi dua vao; kind 1 = EMA Pivot nen dang chay = a*muc(H,L,C hien tai) + (1-a)*EMA shift 1.
   double curV = rvNow;
   if(kind == 1)
     {
      double hh = iHigh(_Symbol, tf, 0);
      double ll = iLow(_Symbol, tf, 0);
      double cc = iClose(_Symbol, tf, 0);
      if(!(hh > 0.0) || !(ll > 0.0) || !(cc > 0.0))
         return false;
      double aE = 2.0 / (MathMax(1, AptPivotEmaPeriod()) + 1.0);
      curV = aE * WoodieLevelValue(lvlNow, hh, ll, cc) + (1.0 - aE) * g_aptRvXPvE1[slot];
      if(!(curV > 0.0))
         return false;
     }

   double lwNow   = g_aptRvXLw0[slot];
   int    sideNow = (curV > lwNow) ? 1 : ((curV < lwNow) ? -1 : 0);
   if(sideNow == 0)
     {
      g_aptRvXC0Bar[slot] = 0;
      outCnt = 0;
      return true;
     }
   int cnt = 1;                                  // nen dang chay (k = 0)
   if(sideNow == g_aptRvXSide1[slot])
     {
      cnt += g_aptRvXRun1[slot];
      g_aptRvXC0Bar[slot] = 0;
     }
   else if(g_aptRvXC0Bar[slot] != bar0 || g_aptRvXC0Side[slot] != sideNow)
     {
      // Duong vua cat sang phia moi NGAY TRONG nen dang chay: ghi nhan thoi diem + gia tri o lan DAU thay (dung cho <pls>, xem AptPivotCutPoint()).
      g_aptRvXC0Bar[slot]  = bar0;
      g_aptRvXC0Side[slot] = sideNow;
      g_aptRvXC0T[slot]    = TimeCurrent();
      g_aptRvXC0Px[slot]   = curV;
     }
   outCnt = sideNow * cnt;
   return true;
  }

//==================================================================
//  AptPivotCutPoint: DIEM Pivot cat duong EMA(Open) (= OW) cua CHINH khung tf, theo dung dinh nghia "nen cat" cua AptRv1LwmaCrossCnt() (kind 1):
//    Pivot = EMA(InpWoodiePivotEmaPeriod) cua muc dang chon o bang Pivot UI (g_pivotLevelIdx, mac dinh PP) - AptPivotUiEmaSeries().
//    - Pivot dang TREN LWMA -> dir = +1 (cat LEN); Pivot dang DUOI LWMA -> dir = -1 (cat XUONG); Pivot = LWMA / thieu du lieu -> false.
//    - Diem cat = nen CU NHAT cua day nen LIEN TIEP cung phia hien tai cua Pivot (nen dem la "1" cua <so nen> tren nhan RV1):
//        + nen cat la nen DA DONG (k >= 1): outPx = Pivot luc dong nen do, outT = thoi diem dong nen do (g_aptRvXCutPx/g_aptRvXCutT, do AptRv1LwmaCrossBuild() ghi).
//        + nen cat la nen DANG CHAY (k = 0, tuc vua cat ngay trong nen nay): outPx = Pivot, outT = TimeCurrent() tai LAN DAU AptRv1LwmaCrossCnt() thay Pivot o phia moi
//          (g_aptRvXC0Px/g_aptRvXC0T). Neu indicator moi nap giua nen (hoac vua doi muc Pivot UI / doi n) thi thoi diem la luc do.
//    - Day nen cung phia dai het cua so lich su (khong tim thay nen cat) -> false (noi goi in "-").
//    Chi doc gia, khong tao object.
//==================================================================
bool AptPivotCutPoint(const ENUM_TIMEFRAMES tf, const int n, int &outDir, double &outPx, datetime &outT)
  {
   outDir = 0;
   outPx  = 0.0;
   outT   = 0;
   int cnt = 0;
   if(!AptRv1LwmaCrossCnt(tf, n, 0.0, cnt, 1) || cnt == 0)
      return false;
   int slot = -1;
   for(int s = 0; s < APT_RVX_SLOTS; s++)
     {
      if(g_aptRvXTf[s] == tf && g_aptRvXKind[s] == 1)
        {
         slot = s;
         break;
        }
     }
   if(slot < 0)
      return false;
   int dir = (cnt > 0) ? 1 : -1;
   if(cnt == dir)
     {
      // so nen = +-1: Pivot vua sang phia moi ngay trong nen dang chay
      datetime bar0 = iTime(_Symbol, tf, 0);
      if(bar0 <= 0 || g_aptRvXC0Bar[slot] != bar0 || g_aptRvXC0Side[slot] != dir)
         return false;
      outPx = g_aptRvXC0Px[slot];
      outT  = g_aptRvXC0T[slot];
     }
   else
     {
      if(!g_aptRvXFound[slot])
         return false;
      outPx = g_aptRvXCutPx[slot];
      outT  = g_aptRvXCutT[slot];
     }
   if(!(outPx > 0.0) || outT <= 0)
      return false;
   outDir = dir;
   return true;
  }

//==================================================================
//  AptPlsStr: pls = dau * |Bid - gia nhan LAM TRON GAN BID NHAT| / so giay ke tu luc Bid cat LEN / cat XUONG gia do.
//    Nhan lam tron = cac nhan mau trang AptRndMarksDraw() ve (g_aptRndLvl[0..g_aptRndLvlN-1], dung chung cho moi khung). Chi xet nhan nam trong KHU VUC ALARM:
//    |Bid - nhan| <= InpRndAlertDist (mac dinh 2.0 = +/-2) va InpRndAlertOn = true; nhieu nhan cung nam trong khu vuc -> lay nhan gan Bid nhat.
//    Thoi diem cat = AptRndCrossMinutes() (gio dong cua nen M1 gan nhat nam o phia nguoc lai, do chinh xac theo nen M1; nen M1 dang chay da o phia nguoc lai -> 0 -> tinh 1 giay).
//    Bid >= nhan (da cat LEN) -> DUONG (dau "+"); Bid < nhan (da cat XUONG) -> AM (dau "-"). Khong co nhan trong khu vuc / khong tim thay lan cat / alert tat -> tra false (noi goi in "-").
//    Gia tri khong phu thuoc khung tf (cung 1 so tren ca 14 nhan RV1 trong cung 1 nhip). Dinh dang: dau +/-, (_Digits+1) so thap phan. So giay toi thieu 1. Chi doc gia: khong tao object.
//==================================================================
bool AptPlsStr(const ENUM_TIMEFRAMES tf, string &outStr)
  {
   outStr = "";
   if(!InpRndAlertOn || g_aptRndLvlN <= 0)
      return false;
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(bid <= 0.0)
      return false;
   double dist = (InpRndAlertDist < 0.0) ? 0.0 : InpRndAlertDist;
   int    nK   = -1;
   double nD   = 0.0;
   for(int k = 0; k < g_aptRndLvlN && k < 56; k++)
     {
      double d = MathAbs(bid - g_aptRndLvl[k]);
      if(d > dist)
         continue;
      if(nK < 0 || d < nD)
        {
         nK = k;
         nD = d;
        }
     }
   if(nK < 0)
      return false;
   double lvl = g_aptRndLvl[nK];
   double crossMin = 0.0;
   if(!AptRndCrossMinutes(lvl, bid, crossMin))
      return false;
   double secs = crossMin * 60.0;
   if(secs < 1.0)
      secs = 1.0;
   double mag = nD / secs;
   outStr = ((bid >= lvl) ? "+" : "-") + DoubleToString(mag, _Digits + 1);
   return true;
  }

//==================================================================
//  AptRndNearestMidLvl: GIA cua nhan lam tron GAN GIA GIUA (Bid + Ask)/2 NHAT = nhan mau trang (g_aptRndLvl[0..g_aptRndLvlN-1], AptRndMarksDraw()).
//    KHONG gioi han khoang cach (khong phu thuoc InpRndAlertOn / InpRndAlertDist). Hoa nhau -> lay nhan co chi so nho hon.
//    Chua co nhan nao (g_aptRndLvlN = 0) / thieu Bid hoac Ask -> false. Chi doc gia.
//==================================================================
bool AptRndNearestMidLvl(double &outLvl)
  {
   outLvl = 0.0;
   if(g_aptRndLvlN <= 0)
      return false;
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   if(bid <= 0.0 || ask <= 0.0)
      return false;
   double mid = (bid + ask) / 2.0;
   int    nK  = -1;
   double nD  = 0.0;
   for(int k = 0; k < g_aptRndLvlN && k < 56; k++)
     {
      double d = MathAbs(mid - g_aptRndLvl[k]);
      if(nK < 0 || d < nD)
        {
         nK = k;
         nD = d;
        }
     }
   if(nK < 0)
      return false;
   outLvl = g_aptRndLvl[nK];
   return true;
  }

//==================================================================
//  AptOwStr: tra "<RV1OW>" = (Bid - OW)/spread lam tron SO NGUYEN (MathRound, cung kieu <SpR1>/<SpR2>), OW = EMA(Open) chu ky n = g_aptBrkDBars (nhan OW<khung>);
//    outCnt = <so nen> = so nen TF tu khi gia tri PIVOT cua muc dang chon o bang Pivot UI (mac dinh PP; EMA Pivot, xem AptPivotUiEmaSeries()) cat OW
//             (AptRv1LwmaCrossCnt(..., kind = 1); duong = Pivot tren LWMA, am = Pivot duoi LWMA).
//    Goi AptOpenLwma() MOT lan. Truong nao thieu du lieu (spread <= 0, OW / Pivot khong tinh duoc) -> "-" (khong doan).
//    Chi doc gia, khong tao object.
//==================================================================
string AptOwStr(const ENUM_TIMEFRAMES tf, string &outCnt)
  {
   int n = g_aptBrkDBars;
   if(n < 2)   n = 2;
   if(n > 500) n = 500;
   double ow = 0.0;
   bool   ok = AptOpenLwma(tf, n, ow);
   // <so nen> = so nen tu khi gia tri Pivot (muc chon o bang Pivot UI) cat EMA(Open) (AptRv1LwmaCrossCnt(), kind 1). Thieu du lieu -> "-".
   string sCnt = "-";
   int    pvCross = 0;
   if(AptRv1LwmaCrossCnt(tf, n, 0.0, pvCross, 1))
      sCnt = IntegerToString(pvCross);
   string sOw  = "-";
   // <RV1OW> = (Bid - OW)/spread (Bid = SYMBOL_BID hien tai).
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double spread = (double)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * _Point;
   if(ok && bid > 0.0 && spread > 0.0)
     {
      sOw = IntegerToString((int)MathRound((bid - ow) / spread));
     }
   // <so nen> tra qua outCnt; <RV1MD> do noi goi dat truoc
   outCnt = sCnt;
   return sOw;
  }

//==================================================================
//  AptRv1MdStr: <RV1MD> = (Bid - MD)/spread cua khung tf (cung don vi/so le voi <diffpv>), lam tron SO NGUYEN.
//    MD  = trung binh Open cua DUNG n = g_aptBrkDBars nen DA DONG gan nhat (shift 1..n, kep 2..500) cua khung tf - chinh gia tri nhan MD (DrawBrkDHHLL) ve.
//    Duong: Bid tren MD; am: Bid duoi MD. Thieu n gia Open / spread <= 0 -> "-" (khong doan). Chi doc gia, khong tao object.
//==================================================================
string AptRv1MdStr(const ENUM_TIMEFRAMES tf)
  {
   // <RV1MD> = (Bid - MD)/spread (Bid = SYMBOL_BID hien tai). Tham so tf la khung can tinh.
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(bid <= 0.0)
      return "-";
   double spread = (double)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * _Point;
   if(spread <= 0.0)
      return "-";
   int n = g_aptBrkDBars;
   if(n < 2)   n = 2;
   if(n > 500) n = 500;
   double op[];
   ArraySetAsSeries(op, true);
   if(CopyOpen(_Symbol, tf, 1, n, op) != n)
      return "-";
   double sum = 0.0;
   for(int k = 0; k < n; k++)
      sum += op[k];
   double md = sum / (double)n;
   if(md <= 0.0)
      return "-";
   // Lam tron SO NGUYEN (MathRound, cung cach <SpR1>/<SpR2>)
   return IntegerToString((int)MathRound((bid - md) / spread));
  }

void DrawBrkDHHLL()
  {
   DrawOwLine();   // duong OW (EMA(Open)) theo khung chon o nut UI; co cache, khong ve lai moi tick
   DrawOwLabelsAll();   // nhan OW cua 14 khung, khong phu thuoc nut chon khung
   string nmH = PFX"BKHH";
   string nmL = PFX"BKLL";
    // Nhan MD = TRUNG BINH Open cua cac nen trong day tinh HH/LL (cung khung, cung g_aptBrkDBars nen, shift 1..N).
   string nmM = PFX"BKMD";
   if(g_aptBrkDTfIdx < 0 || g_aptBrkDTfIdx >= APT_BRKDTF_COUNT)
     {
      ObjectDelete(0,nmH);
      ObjectDelete(0,nmL);
      ObjectDelete(0,nmM);
      return;
     }
   ENUM_TIMEFRAMES tf = g_tfList[g_aptBrkDTfIdx];
   int n = g_aptBrkDBars;
   if(n < 2)   n = 2;
   if(n > 500) n = 500;
   if(Bars(_Symbol,tf) < n + 2)
     {
      ObjectDelete(0,nmH);
      ObjectDelete(0,nmL);
      ObjectDelete(0,nmM);
      return;
     }
   int ih = iHighest(_Symbol,tf,MODE_HIGH,n,1);
   int il = iLowest (_Symbol,tf,MODE_LOW ,n,1);
   if(ih < 0 || il < 0)
     {
      ObjectDelete(0,nmH);
      ObjectDelete(0,nmL);
      ObjectDelete(0,nmM);
      return;
     }
   datetime tH = iTime(_Symbol,tf,ih);
   datetime tL = iTime(_Symbol,tf,il);
   double   hh = iHigh(_Symbol,tf,ih);
   double   ll = iLow (_Symbol,tf,il);
   if(tH <= 0 || tL <= 0 || hh <= 0.0 || ll <= 0.0)
     {
      ObjectDelete(0,nmH);
      ObjectDelete(0,nmL);
      ObjectDelete(0,nmM);
      return;
     }
    // Truc THOI GIAN cua nhan = THAN NEN LON dang ve (nen s = 0 cua bar chart khung g_barTF / InpBarChartTF), de nhan nam ngay tren than nen lon:
    //   BarChartMidTime(0, rt[0].time, secPerBar). Gia (truc doc) la gia HH/LL that cua kenh.
    //   Khong doc duoc nen lon -> du phong dung thoi gian nen HH/LL
   datetime tHb = tH;
   datetime tLb = tL;
   ENUM_TIMEFRAMES _bhTf = InpBarChartTF;
   if(g_barTF != InpBarChartTF) _bhTf = g_barTF;
   long _bhSec = PeriodSeconds(_bhTf);
   MqlRates _bhRt[];
   ArraySetAsSeries(_bhRt,true);
   if(_bhSec > 0 && CopyRates(_Symbol,_bhTf,0,1,_bhRt) >= 1)
     {
      datetime _bhMid = BarChartMidTime(0,_bhRt[0].time,_bhSec);
      if(_bhMid > 0)
        {
         tHb = _bhMid;
         tLb = _bhMid;
        }
     }
   string lbl = g_tfLabel[g_aptBrkDTfIdx];
   MakeText(nmH,tHb,hh,"HH"+lbl,clrTomato,ANCHOR_LOWER);
   MakeText(nmL,tLb,ll,"LL"+lbl,clrDeepSkyBlue,ANCHOR_UPPER);
    // MD = trung binh Open cua dung n nen da dung tinh HH/LL (iHighest/iLowest(n, start = 1) -> shift 1..n cua khung tf).
    //   Dat tren cung truc thoi gian voi HH/LL (tHb = giua than nen lon), tai gia MD. Doc khong du n gia Open -> xoa nhan MD, khong doan.
   double mdOpen[];
   ArraySetAsSeries(mdOpen,true);
   if(CopyOpen(_Symbol,tf,1,n,mdOpen) == n)
     {
      double mdSum = 0.0;
      for(int mdI = 0; mdI < n; mdI++)
         mdSum += mdOpen[mdI];
      double md = mdSum / (double)n;
      if(md > 0.0)
          // Neo GIUA (ANCHOR_CENTER) de chu MD nam tren cung truc thoi gian (than nen lon) voi HH/LL.
         MakeText(nmM,tHb,md,"MD"+lbl,clrGold,ANCHOR_CENTER);
      else
         ObjectDelete(0,nmM);
     }
   else
      ObjectDelete(0,nmM);
  }

//==================================================================
//  DrawOwLabelsAll: ve nhan OW (EMA(Open) chu ky n = g_aptBrkDBars, nut B<n>) cho 14 khung g_tfList, khong phu thuoc nut chon khung.
//    Object PFX"BKOW_"+<chi so khung>, chu "OW<khung> <so nen>" (vd "OW1m -5", "OW4h 3": so nen gia tri Pivot (EMA Pivot muc chon o bang Pivot UI, mac dinh PP) cat OW, xem AptRv1LwmaCrossCnt kind 1),
//    mau clrMagenta, neo GIUA, cung truc thoi gian (giua than nen lon) voi HH/LL/MD, tai gia OW cua khung do.
//    Cac khung co gia OW gan nhau se de len nhau. Khung thieu du lieu (Bars < n + 2, CopyOpen loi) -> xoa nhan do, khong doan.
//    OW chi doi khi khung sang nen moi / doi n -> cache theo khung (bar0, n, gia); chi MakeText khi chu / gia / truc thoi gian doi hoac object mat.
//==================================================================
void DrawOwLabelsAll()
  {
   static datetime s_bar0[14];
   static int      s_n[14];
   static double   s_val[14];
   static datetime s_tHb[14];
   static string   s_txt[14];   // chu nhan lan ve truoc (OW<khung> <so nen>)
   static double   s_px [14];   // gia lan ve truoc
   static bool     s_init = false;
   if(!s_init)
     {
      for(int k = 0; k < 14; k++) { s_bar0[k] = 0; s_n[k] = 0; s_val[k] = 0.0; s_tHb[k] = 0; s_txt[k] = ""; s_px[k] = 0.0; }
      s_init = true;
     }

   int n = g_aptBrkDBars;
   if(n < 2)   n = 2;
   if(n > 500) n = 500;

   // Truc THOI GIAN = giua than nen lon (cung cach HH/LL/MD); khong doc duoc -> nen hien tai cua chart
   datetime tHb = iTime(_Symbol, _Period, 0);
   ENUM_TIMEFRAMES _owTf = InpBarChartTF;
   if(g_barTF != InpBarChartTF) _owTf = g_barTF;
   long _owSec = PeriodSeconds(_owTf);
   MqlRates _owRt[];
   ArraySetAsSeries(_owRt, true);
   if(_owSec > 0 && CopyRates(_Symbol, _owTf, 0, 1, _owRt) >= 1)
     {
      datetime _owMid = BarChartMidTime(0, _owRt[0].time, _owSec);
      if(_owMid > 0)
         tHb = _owMid;
     }
   if(tHb <= 0)
      return;

   for(int i = 0; i < 14; i++)
     {
      string nm = PFX"BKOW_" + IntegerToString(i);
      ENUM_TIMEFRAMES tf = g_tfList[i];
      datetime bar0 = iTime(_Symbol, tf, 0);
      if(bar0 <= 0)
        {
         ObjectDelete(0, nm);
         s_val[i] = 0.0;
         continue;
        }
      // [GIU NGUYEN - KHONG XOA] if(bar0 != s_bar0[i] || n != s_n[i])
      if(bar0 != s_bar0[i] || AptOwModeKey(n) != s_n[i])
        {
         double ow = 0.0;
         s_val[i]  = AptOpenLwma(tf, n, ow) ? ow : 0.0;
         s_bar0[i] = bar0;
         // [GIU NGUYEN - KHONG XOA] s_n[i]    = n;
         s_n[i]    = AptOwModeKey(n);
        }
      if(s_val[i] <= 0.0)
        {
         ObjectDelete(0, nm);
         s_tHb[i] = 0;
         continue;
        }
      // [GIU NGUYEN - KHONG XOA] // Them SO NEN tu khi RV1 cat OW cua chinh khung: "OW<khung> <so nen>", vd "OW1m -5" / "OW5m 5".
      // [GIU NGUYEN - KHONG XOA] //   So nen = AptRv1LwmaCrossCnt(): duong = RV1 dang TREN OW (cat LEN), am = RV1 dang DUOI OW (cat XUONG);
      // [GIU NGUYEN - KHONG XOA] //   nen cat = nen cu nhat cua day, tinh la 1; 0 = RV1 bang OW. RV1 = g_rv1ValCache[i]. Thieu RV1 / du lieu -> "-".
      // [GIU NGUYEN - KHONG XOA] //   RV1 doi theo tick -> chu nhan tinh lai moi lan goi (ham dem da cache theo khung/nen).
      // [GIU NGUYEN - KHONG XOA] string cntTxt = "-";
      // [GIU NGUYEN - KHONG XOA] int    owCross = 0;
      // [GIU NGUYEN - KHONG XOA] if(AptRv1LwmaCrossCnt(tf, n, g_rv1ValCache[i], owCross))
      // [GIU NGUYEN - KHONG XOA]    cntTxt = IntegerToString(owCross);
      // Them SO NEN tu khi gia tri PIVOT (EMA Pivot cua muc chon o bang Pivot UI, mac dinh PP - AptPivotUiEmaSeries()) cat OW cua chinh khung:
      //   "OW<khung> <so nen>", vd "OW1m -5" / "OW5m 5".
      //   So nen = AptRv1LwmaCrossCnt(..., kind = 1): duong = Pivot dang TREN OW (cat LEN), am = Pivot dang DUOI OW (cat XUONG);
      //   nen cat = nen cu nhat cua day, tinh la 1; 0 = Pivot bang OW. Gia tri Pivot hien tai ham tu tinh tu H/L/C nen dang chay. Thieu du lieu -> "-".
      //   Pivot doi theo tick -> chu nhan tinh lai moi lan goi (ham dem da cache theo khung/nen/muc Pivot UI).
      string cntTxt = "-";
      int    owCross = 0;
      if(AptRv1LwmaCrossCnt(tf, n, 0.0, owCross, 1))
         cntTxt = IntegerToString(owCross);
      string owTxt = "OW" + g_tfLabel[i] + " " + cntTxt;
      if(s_tHb[i] == tHb && s_txt[i] == owTxt && s_px[i] == s_val[i] && ObjectFind(0, nm) >= 0)
         continue;
      // [GIU NGUYEN - KHONG XOA] MakeText(nm, tHb, s_val[i], owTxt, clrLimeGreen, ANCHOR_CENTER);
      MakeText(nm, tHb, s_val[i], owTxt, clrMagenta, ANCHOR_CENTER);
      s_tHb[i] = tHb;
      s_txt[i] = owTxt;
      s_px[i]  = s_val[i];
     }
  }

//==================================================================
//  PANEL
//==================================================================
void DrawPanel()
  {
   SSpmScopeTimer __spmTimer("DrawPanel");
   DrawBreakStats();
   AptCheckSoundAlerts();
   AptPeriodExtremeAlertCheck();   // alert am thanh RIENG + push cho cao/thap tuan, thang, qui, nam
   DrawAptPatternColumn();
   DrawBrkDHHLL();   // nhan HH/LL/MD cua kenh brkD tren khung da chon

   if(!InpShowPanel)
     {
      ObjectsDeleteAll(0,PFX"PN");
      return;
     }

   int lineH = InpFontSize + 7;
   int rows  = 15;
   int w     = (int)(InpFontSize*5.6) + 250;
   int h     = rows*lineH + 14;
   // Bang thong tin bat dau tai InpPanelY.
   int panelYInfo   = InpPanelY;
   MakePanelBG(InpPanelX,panelYInfo,w,h);

   int x = InpPanelX + 10;
   int y = panelYInfo + 8;
   if(InpCorner==CORNER_RIGHT_UPPER || InpCorner==CORNER_RIGHT_LOWER)
      x = InpPanelX + w - 10;

   bool   up    = (g_s.dir>0);
   color  cDir  = ColByDir(up);
   color  cNeu  = clrSilver;
   string sDir  = !g_s.valid ? "N/A" : (up ? "LONG" : "SHORT");
   double px    = iClose(_Symbol,_Period,0);
   double dEnt  = g_s.valid ? MathAbs(px-g_s.entry)/_Point : 0.0;
   double bal   = AccountInfoDouble(ACCOUNT_BALANCE);
   double rPct  = (bal>0.0) ? g_s.riskMoney/bal*100.0 : 0.0;

   string modeTxt = "AUTO";
   if(InpMode==APT_MANUAL)
      modeTxt="MANUAL";

   int r=0;
   MakeLabel(PFX"PN_0",x,y+lineH*(r++),"AUTO POSITION TOOL   ["+modeTxt+"]",clrGold);
   MakeLabel(PFX"PN_1",x,y+lineH*(r++),
             StringFormat("%-9s %s  Quet:%s","Symbol:",_Symbol,EnumToString(_Period)),cNeu);
   MakeLabel(PFX"PN_2",x,y+lineH*(r++),
             StringFormat("%-9s %s","Chieu:",sDir),cDir);
   MakeLabel(PFX"PN_3",x,y+lineH*(r++),
             StringFormat("%-9s %s","Gia:",DoubleToString(px,_Digits)),cNeu);
   MakeLabel(PFX"PN_4",x,y+lineH*(r++),"----------------------------------",cNeu);

   if(!g_s.valid)
     {
      MakeLabel(PFX"PN_5",x,y+lineH*(r++),"Khong co setup: "+g_s.note,clrTomato);
      for(int i=6; i<rows; i++)
         MakeLabel(PFX"PN_"+IntegerToString(i),x,y+lineH*(r++)," ",cNeu);
      return;
     }

   MakeLabel(PFX"PN_5",x,y+lineH*(r++),
             StringFormat("%-9s %s","Entry:",DoubleToString(g_s.entry,_Digits)),InpColEntry);
   MakeLabel(PFX"PN_6",x,y+lineH*(r++),
             StringFormat("%-9s %s  (%.0f pts)","SL:",DoubleToString(g_s.sl,_Digits),g_s.slPts),
             ColByDir(!up));
   MakeLabel(PFX"PN_7",x,y+lineH*(r++),
             StringFormat("%-9s %s  (%.0f pts)","TP:",DoubleToString(g_s.tp,_Digits),g_s.tpPts),
             ColByDir(up));
   MakeLabel(PFX"PN_8",x,y+lineH*(r++),
             StringFormat("%-9s %.2f","R:R",g_s.rr),
             (g_s.rr>=InpRR ? clrGold : clrSilver));
   MakeLabel(PFX"PN_9",x,y+lineH*(r++),"----------------------------------",cNeu);
   MakeLabel(PFX"PN_10",x,y+lineH*(r++),
             StringFormat("%-9s %.2f lot","Volume:",g_s.lots),clrGold);
   MakeLabel(PFX"PN_11",x,y+lineH*(r++),
             StringFormat("%-9s -%.2f  (%.2f%% bal)","Rui ro:",g_s.riskMoney,rPct),ColByDir(false));
   MakeLabel(PFX"PN_12",x,y+lineH*(r++),
             StringFormat("%-9s +%.2f","Loi nhuan:",g_s.rewardMoney),ColByDir(true));
   MakeLabel(PFX"PN_13",x,y+lineH*(r++),
             StringFormat("%-9s ~%d bar  (%s)","Forecast:",g_s.etaBars,
                          TimeToString(g_s.etaTime,TIME_DATE|TIME_MINUTES)),cNeu);
   MakeLabel(PFX"PN_14",x,y+lineH*(r++),
             StringFormat("%s | cach Entry %.0f pts",StatusText(),dEnt),clrGold);
  }

//==================================================================
//  CANH BAO
//==================================================================
void DoAlert(const string msg)
  {
   Alert(_Symbol+" "+EnumToString((ENUM_TIMEFRAMES)_Period)+": "+msg);
   if(InpPushAlert)
      SendNotification(_Symbol+": "+msg);
  }

void CheckAlerts()
  {
   SSpmScopeTimer __spmTimer("CheckAlerts");
   if(!g_s.valid)
      return;

   if(InpAlertNewSetup &&
      (g_s.dir!=g_prevDir || MathAbs(g_s.entry-g_prevEntry)>_Point))
     {
      if(g_prevDir!=0)
         DoAlert(StringFormat("Setup moi %s  Entry %s | SL %s | TP %s | R:R %.2f",
                              (g_s.dir>0?"LONG":"SHORT"),
                              DoubleToString(g_s.entry,_Digits),
                              DoubleToString(g_s.sl,_Digits),
                              DoubleToString(g_s.tp,_Digits),g_s.rr));
      g_prevDir   = g_s.dir;
      g_prevEntry = g_s.entry;
     }

   if(InpAlertTouch)
     {
      double px = iClose(_Symbol,_Period,0);
      bool inZone = (g_s.dir>0) ? (px<=g_s.entry) : (px>=g_s.entry);
      if(inZone && !g_touchedE)
        {
         g_touchedE = true;
         DoAlert("Gia cham vung ENTRY "+DoubleToString(g_s.entry,_Digits));
        }
     }
  }

//==================================================================
//  KHOI TU RollingVWAP2_MultiTF.mq5: duong/nhan Rolling VWAP (RV1), RV2 = EMA(RV1), Woodie Pivot EMA, bang nut chon khung,
//  Bar Chart (than nen lon) va cac cot nhan RV1 / RV2 / Pivot.
//    RV1 = VWAP truot tren cua so N nen M1 ket thuc tai moc neo (N = so phut cua khung TF); neo = GIO DONG cua tung nen TF
//    (nen dang chay: TimeCurrent). RV2 = EMA(g_aptRv2EmaPeriod) ap len chuoi RV1 lay mau theo tung nen cua khung TF
//    (seed = SMA cac mau cu nhat roi EMA tien ve hien tai). Chi copy du lieu M1 + tinh prefix-sum 1 lan cho moi lan ve.
//  Mang g_tfList cua khoi nay la g_rvTfList (cung noi dung voi g_tfList cua APT).
//  InpTFPanelX / InpTFPanelY mac dinh 380 / 330 de cum bang nut khong de len bang thong tin cua APT
//  (bang thong tin y 10..264; font mac dinh InpFontSize = 9).
//  Cot nhan RV1 / RV2 / Pivot neo LEFT tai moc thoi gian nam ben PHAI nen hien tai (InpS1LabelFutureBars va cac buoc dich cot);
//  cot nhan dinh nen cua APT neo RIGHT_LOWER tai chinh nen hien tai nen keo sang TRAI: hai he thong nhan nam hai phia cua nen hien tai.
//==================================================================

input group "=== Tham số tính toán ==="
input int  InpEmaPeriod   = 5;    // Chu kỳ EMA áp lên chuỗi RV1 (ra RV2), dùng chung cho mọi khung
input int  InpHistPoints  = 480;  // Số nến TF lịch sử tối đa vẽ mỗi đường (mỗi điểm = 1 nến của khung TF đó)
input int  InpMaxSegments = 160;  // Số segment tối đa mỗi đường (bước gộp điểm, chống nặng chart)

input group "=== Màu đường (mặc định: TF ngắn = lạnh, TF dài = nóng) ==="
input color InpColor_M1  = clrYellowGreen;
input color InpColor_M5  = clrDodgerBlue;
input color InpColor_M15 = clrYellow;
input color InpColor_M30 = clrRed;
input color InpColor_H1  = clrOrange;
input color InpColor_H2  = clrOrangeRed;
// InpColor_H3 / InpColor_H6: mau rieng cua H3 / H6 trong g_color[] (gan trong OnInit), khac cac mau con lai.
input color InpColor_H3  = clrTomato;
input color InpColor_H4  = clrMagenta;
input color InpColor_H6  = clrDeepPink;
input color InpColor_H8  = clrPurple;
input color InpColor_H12 = clrDarkViolet;
input color InpColor_D1  = clrWhite;
input color InpColor_W1  = clrGold;
input color InpColor_MN1 = clrLime;

// --- Bar Chart: vẽ thân nến (candle) khung thời gian tùy chọn, độc lập với các đường RV2 ---
input group "=== Bar Chart (thân nến khung thời gian tùy chọn) ==="
input bool             InpShowBarChart    = true;         // Bật/tắt vẽ thân nến khung tùy chọn
input ENUM_TIMEFRAMES  InpBarChartTF      = PERIOD_H2;    // Khung thời gian vẽ nến (mặc định H2)
input int              InpBarChartCount   = 16;           // Số nến tối đa vẽ (lùi từ nến hiện tại về quá khứ)
input color            InpBarUpColor      = clrLimeGreen; // Màu thân nến tăng (Close >= Open)
input color            InpBarDownColor    = clrRed;       // Màu thân nến giảm (Close < Open)
input int              InpBarBodyWidthPct = 70;           // Độ rộng thân nến (% so với 1 chu kỳ của khung đã chọn)

// --- Nhan tai VACH CLOSE cua than nen Bar Chart:
//--   (1) % bien do nen so voi Close cua CHINH nen do: (High-Low)/Close*100, mang dau
//--       "-" khi nen giam (Close < Open) - cong thuc giu nguyen 100%.
//--   (2) elapsedSec: thoi gian da qua cua nen HIEN TAI = TimeCurrent() - open time.
//--   (3) Dmax/Dmin: % bien do LON NHAT cua nhom nen TANG va AM SAU NHAT cua nhom nen
//--       GIAM, quet trong cua so thong ke cua khung InpBarChartTF (<=H4: tu 00:00 hom
//--       nay; <=H12: tu dau tuan; <=D1: tu dau thang; W1/MN1: khong co -> "-").
//--   Ba gia tri chi ghi bang OBJ_TEXT tai diem cuoi vach Close, KHONG ve them duong.
input group "=== Bar Chart: nhan tai vach Close (port tu MiniBarChart) ==="
input bool  InpBarLblShow        = true;      // Bat/tat toan bo nhan tai vach Close
input bool  InpBarLblShowPct     = true;      // Hien % bien do nen so voi Close cua chinh nen do
input int   InpBarLblPctCount    = 30;        // So nen gan nhat co nhan % (0 = tat ca nen dang ve)
input bool  InpBarLblShowElapsed = true;      // Hien elapsedSec cua nen hien tai (nen s = 0)
input bool  InpBarLblShowMaxMin  = true;      // Hien Dmax/Dmin cua khung InpBarChartTF (nen s = 0)
input int   InpBarLblFontSize    = 8;         // Co chu nhan
input color InpBarLblColorCur    = clrWhite;  // Mau cum nhan cua nen hien tai (s = 0)
input int   InpBarLblRefreshMs   = 500;       // Nhip cap nhat nhan (ms); 0 = khong dung timer

// --- CANH BAO HET GIO tai cum nhan cua nen hien tai --------------
//--   Quet cac khung tu LON NHAT (1MN) xuong 5M (khong xet 1M). Khung nao co
//--   thoi gian DEM LUI den luc dong nen < InpBarLblCdSec giay thi ghi them
//--   "<TenTF>:<so giay>s" vao CUOI cum nhan, vi du:
//--       -0.35% | 02:41:09 | Max +0.62% -0.48% 4H:45s
//--   Nhieu khung cung sap dong -> liet ke lien tiep theo thu tu khung lon
//--   truoc (vd "1D:12s 4H:12s"), gioi han so muc bang InpBarLblCdMaxItems.
//--   Chi noi them chuoi vao OBJ_TEXT san co: KHONG tao object moi, KHONG ve duong.
input bool  InpBarLblShowCountdown = true;    // Bat/tat canh bao het gio (dem lui < nguong)
input int   InpBarLblCdSec         = 60;      // Nguong canh bao (giay); 60 = duoi 1 phut
input int   InpBarLblCdMaxItems    = 0;       // So khung toi da hien (0 = tat ca, 1 = chi khung lon nhat)

// --- Do dai vach Open/Close (va diem gan nhan): khi InpBarTickFixedLen bat, KHONG scale theo InpBarChartTF ma lay theo MOT khung tham chieu
//--   co dinh (mac dinh M5) nen vach cua moi khung deu ngan bang nhau. Tat -> dung cong thuc goc (secPerBar * bodyFrac / 2).
input bool            InpBarTickFixedLen  = true;       // Vach Open/Close dai BANG NHAU o moi khung (false = dung do dai goc theo secPerBar)
input int             InpBarTickChartBars = 3;          // Do dai vach = bao nhieu NEN CUA CHART dang mo (_Period) -> be rong pixel co dinh
input ENUM_TIMEFRAMES InpBarTickRefTF     = PERIOD_M5;  // Chi dung khi InpBarTickChartBars <= 0: lay do dai theo khung nay

// --- Vi tri ve THAN NEN HIEN TAI (nen dang chay, s = 0) ----------
//--   Cong thuc goc dat than nen tai GIUA chu ky (time + secPerBar/2); voi nen dang chay thi diem do nam o TUONG LAI.
//--   Cho phep chon moc dat; cac nen DA DONG (s > 0) luon dung cong thuc goc.
enum ENUM_BARCUR_POS
{
   BARCUR_M1   = 0,   // Nen M1 hien tai (mac dinh)
   BARCUR_OPEN = 1,   // Thoi diem MO cua chinh nen hien tai
   BARCUR_TF   = 2,   // Nen hien tai cua khung tuy chon InpBarCurPosTF
   BARCUR_ORIG = 3    // Cong thuc goc: giua chu ky (time + secPerBar/2)
};
input ENUM_BARCUR_POS InpBarCurPosMode = BARCUR_M1;    // Vi tri ve than nen hien tai
input ENUM_TIMEFRAMES InpBarCurPosTF   = PERIOD_M5;    // Khung dung khi chon BARCUR_TF

// --- So NEN VE TUONG LAI (theo khung cua CHART hien tai) ma THAN NEN
//--   cua nen DANG CHAY (s = 0) duoc dich sang PHAI so voi moc do
//--   InpBarCurPosMode tra ve (moc mac dinh BARCUR_M1 -> iTime(M1, 0), cong them BARCUR_FUTURE_BARS nen). Do dich ap dung cho CA than
//--   nen (duong dung Low->High, vach Open, vach Close) va cum nhan tai vach Close, vi ca hai lay moc tu BarChartMidTime().
//--   Cac nen DA DONG (s > 0) khong bi anh huong.
const int BARCUR_FUTURE_BARS = 1;

// --- Bang nut UI chon khung ve than nen lon Bar Chart (khoi tao = InpBarChartTF) --------
//--   Bam nut thi ve lai ngay khoi tuong ung; nut dang chon to nen mau khac. Chi tao OBJ_BUTTON.
input group "=== UI chon khung thoi gian (bang nut) ==="
input bool             InpShowTFPanels  = true;              // Hien cac bang nut chon khung
input ENUM_BASE_CORNER InpTFPanelCorner = CORNER_LEFT_UPPER; // Goc neo cac bang nut
// Mac dinh 380 de cum cac bang nut khong de len bang thong tin cua APT (xem so do bo tri o dau khoi).
input int              InpTFPanelX      = 380;               // Le X cua bang nut chon khung tinh tu goc neo (px)
// Mac dinh 330 de cum cac bang nut nam han duoi bang thong tin cua APT (bang do ket thuc o y = 316 voi font mac dinh InpFontSize = 9).
input int              InpTFPanelY      = 330;               // Le Y cua cac bang nut tinh tu goc neo (px)
input int              InpTFPanelGapX   = 24;                // Khoang cach ngang giua cac bang nut (px)
input int              InpTFBtnW        = 44;                // Rong moi nut (px)
input int              InpTFBtnH        = 22;                // Cao moi nut (px)
input int              InpTFBtnGap      = 3;                 // Khe ho giua cac nut (px)
input color            InpTFBtnBg       = clrDimGray;        // Mau nen nut thuong
input color            InpTFBtnBgSel    = clrGreen;          // Mau nen nut DANG CHON
input color            InpTFBtnTextCol  = clrWhite;          // Mau chu tren nut
input int              InpTFBtnFontSize = 8;                 // Co chu tren nut

// --- brk: muc do PHA BIEN DO nen LIEN TRUOC cua CHINH khung do (BrkTextForTF; cong thuc WrvBuildBrkStr cua NewCandle.mq5):
//--       price = Close[shift] cua khung do
//--       _pH = High[shift+1], _pL = Low[shift+1], _rg = _pH - _pL
//--       price > _pH -> (price - _pL) / _rg * 100     (duong, luon >= 100)
//--       price < _pL -> (price - _pH) / _rg * 100     (am,   luon <= -100)
//--       con lai -> chuoi rong -> in dau "-"
//--   Ket qua in dang phan tram, khong kem dau "%" (vd "105", "-118"). Ham chi doc gia.
input int    InpTFStatBrkShift    = 0;          // Nen dung lam "nen hien tai" khi tinh brk (0 = nen dang chay)
input int    InpTFStatBrkDigits   = 0;          // So chu so thap phan cua brk (0 = "105", 1 = "105.4")
// --- Woodie Pivot EMA: 19 duong EMA(PP)/EMA(R1..R9)/EMA(S1..S9) ---
input group "=== Woodie Pivot EMA (PP / R1-R9 / S1-S9) ==="
input bool            InpShowWoodiePivotEma   = true;            // Ve cac duong EMA(PP)/EMA(R1..R9)/EMA(S1..S9)
input int             InpWoodiePivotEmaPeriod = 5;               // Chu ky EMA ap dung cho PP/R1-R9/S1-S9
input color           InpEmaPPColor           = clrWhite;       // Mau duong EMA(PP)
input color           InpEmaR1Color           = clrLime;         // Mau duong EMA(R1)
input color           InpEmaR2Color           = clrLime;        // Mau duong EMA(R2)
input color           InpEmaR3Color           = clrLime;  // Mau duong EMA(R3)
input color           InpEmaR4Color           = clrLime;    // Mau duong EMA(R4)
input color           InpEmaR5Color           = clrLime;    // Mau duong EMA(R5)
input color           InpEmaR6Color           = clrLime;    // Mau duong EMA(R6)
input color           InpEmaR7Color           = clrLime;    // Mau duong EMA(R7)
input color           InpEmaR8Color           = clrLime;    // Mau duong EMA(R8)
input color           InpEmaR9Color           = clrLime;    // Mau duong EMA(R9)
input color           InpEmaS1Color           = clrOrange;               // Mau duong EMA(S1)
input color           InpEmaS2Color           = clrYellowGreen;       // Mau duong EMA(S2)
input color           InpEmaS3Color           = clrYellowGreen;    // Mau duong EMA(S3)
input color           InpEmaS4Color           = clrYellowGreen;       // Mau duong EMA(S4)
input color           InpEmaS5Color           = clrYellowGreen;       // Mau duong EMA(S5)
input color           InpEmaS6Color           = clrYellowGreen;       // Mau duong EMA(S6)
input color           InpEmaS7Color           = clrYellowGreen;       // Mau duong EMA(S7)
input color           InpEmaS8Color           = clrYellowGreen;       // Mau duong EMA(S8)
input color           InpEmaS9Color           = clrYellowGreen;       // Mau duong EMA(S9)
// --- Tuy chon hien thi duong / nhan S1 theo khung thoi gian ---
input bool            InpS1LineM1Only         = true;  // Chi ve DUONG S1 cho khung chon o nut UI (1m..1nm); khung khac chi hien NHAN
input int             InpS1LabelFutureBars    = 3;     // Nhan S1 cua khung >= 5m dat cach nen hien tai bao nhieu NEN VE TUONG LAI (0 = dung tai nen hien tai)
input bool            InpAutoChartShift       = true;  // Tu bat Chart shift (le phai) de nhan dat o tuong lai hien thi duoc
// Khung ve duong RV1/RV2/Pivot/OW (khung phu) lay tu nut chon khung (hang nut 1m..1nm duoi hang B<n>, g_aptBrkDTfIdx) - xem AptExtraLineTf().

// --- UI CHON MUC PIVOT (PP / R1-R9 / S1-S9) -------------------
//--   Bang 19 nut (PP, R1..R9, S1..S9) dat NGAY TRUOC va BEN TRAI bang nut chon khung ve than nen lon (Bar Chart). Bam nut nao -> ca 14 duong/nhan
//--   cua PHAN 1 cua DrawWoodiePivotEma() chuyen sang muc do, dung prefix object / nhan / mau cua chinh muc do o nhom "Woodie Pivot EMA" phia tren.
enum ENUM_WOODIE_LVL
{
   WLVL_PP = 0,    // PP
   WLVL_R1 = 1,    // R1
   WLVL_R2 = 2,    // R2
   WLVL_R3 = 3,    // R3
   WLVL_R4 = 4,    // R4
   WLVL_R5 = 5,    // R5
   WLVL_R6 = 6,    // R6
   WLVL_R7 = 7,    // R7
   WLVL_R8 = 8,    // R8
   WLVL_R9 = 9,    // R9
   WLVL_S1 = 10,   // S1 (mac dinh)
   WLVL_S2 = 11,   // S2
   WLVL_S3 = 12,   // S3
   WLVL_S4 = 13,   // S4
   WLVL_S5 = 14,   // S5
   WLVL_S6 = 15,   // S6
   WLVL_S7 = 16,   // S7
   WLVL_S8 = 17,   // S8
   WLVL_S9 = 18    // S9
};
input group "=== UI chon muc Pivot (PP / R1-R9 / S1-S9) ==="
input bool            InpShowLevelPanel     = true;          // Hien bang nut chon muc Pivot (ben TRAI bang nut khung)
input ENUM_WOODIE_LVL InpWoodieLevelDefault = WLVL_PP;       // Muc Pivot chon san khi nap indicator
input int             InpLvlBtnW            = 30;            // Rong moi nut cua bang muc (px)
input int             InpLvlPanelGapX       = 24;            // Khoang cach tu bang muc sang bang nut khung (px)
input color           InpLvlBtnBgSel        = clrDarkOrange; // Mau nen nut muc DANG CHON

// --- COT NHAN CUA RV2 (Rolling VWAP #2) THEO 14 KHUNG -----
//--   Moi khung trong g_rvTfList (1m..1MN) duoc ghi MOT OBJ_TEXT dat DUNG tai muc gia RV2 khung do (diem RV2 moi nhat); noi dung xem DrawRv2RsiLabels()
//--   (RV2 = EMA(g_aptRv2EmaPeriod) tren cac mau RV1 lay theo tung nen cua khung do; RSI dung chu ky WOODIE_RSI_PERIOD va CalcRSI (Wilder)).
//--   Cot nay dat ben PHAI cot nhan Pivot, lech them InpRv2LblExtraBars nen CHART so voi cot do (cot Pivot cua khung >= 5m von da lech
//--   InpS1LabelFutureBars nen).
//--   Khung nao thieu lich su M1 de dung du chuoi RV2 thi bo qua khung do (khong ve nhan), khong doan gia tri.
//--   Chi tao OBJ_TEXT (prefix rieng g_rv2RsiLblPrefix).
input group "=== Cot nhan RSI cua RV2 (Rolling VWAP #2) ==="
input bool  InpShowRv2RsiLbl    = true;    // Hien cot nhan "RSI(RV2,5)/diff TF"
// --- Khoang cach toi cot nhan Pivot do bang PIXEL (mac dinh) thay vi bang SO NEN: do bang so nen thi khi chart phong to cot nhan bi day di
//--   rat xa, thu nho lai thi de len nhau. Do bang pixel roi quy doi ra so nen theo be rong nen THUC TE cua chart thi khoang cach luon on dinh.
//--   Tat InpRv2LblAutoGap -> dung InpRv2LblExtraBars.
input bool  InpRv2LblAutoGap    = true;    // Do khoang cach toi cot Pivot bang PIXEL (tat = dung so nen ben duoi)
input int   InpRv2LblGapPx      = 95;      // Khoang cach toi cot nhan Pivot (px) khi bat InpRv2LblAutoGap
input int   InpRv2LblExtraBars  = 6;       // Khoang cach tinh bang NEN CHART (chi dung khi TAT InpRv2LblAutoGap)
input int   InpRv2LblPoints     = 30;      // So diem RV2 dung de tinh RSI (lon hon = can nhieu lich su M1 hon)
input int   InpRv2LblMaxM1      = 100000;  // Tran so nen M1 doc 1 lan cho cot nhan nay
input int   InpRv2LblRsiDigits  = 0;       // So chu so thap phan phan RSI (0 = "56", 1 = "56.4")
input int   InpRv2LblDiffDigits = 0;       // So chu so thap phan phan diff (0 = "1", 1 = "1.0")
input int   InpRv2LblFontSize   = 9;       // Co chu cua cot nhan
// --- COT NHAN CUA RV1 (Rolling VWAP #1) THEO 14 KHUNG -----
//--   Dat ngay BEN PHAI cot RV2; nhan dat tai muc gia RV1 moi nhat cua khung do (chuoi rv[] da tinh san cho cot RV2, khong copy them du lieu).
//--   Cac tham so dinh dang (so chu so thap phan, co chu, che do do khoang cach) dung CHUNG voi cot RV2.
//--   Chi tao OBJ_TEXT (prefix rieng g_rv1RsiLblPrefix).
input bool  InpShowRv1RsiLbl    = true;    // Hien cot nhan "RSI(RV1,5)/diff TF" (ben phai cot RV2)
input int   InpRv1LblGapPx      = 80;      // Khoang cach tu cot RV2 sang cot RV1 (px) khi bat InpRv2LblAutoGap
input int   InpRv1LblExtraBars  = 6;       // Khoang cach tinh bang NEN CHART (chi dung khi TAT InpRv2LblAutoGap)
// --- TU DONG GIAN CACH CAC COT NHAN THEO DO PHAN GIAI MAN HINH --
//--   InpRv2LblGapPx / InpRv1LblGapPx la so PIXEL co dinh; khi DPI man hinh khac thi chu to/nho hon va cac cot nhan (Pivot | RV2 | RV1) co the ghi de len nhau.
//--   Bat InpLblAutoFitCols: khoang cach cua tung cot = BE RONG THUC TE cua chuoi DAI NHAT o cot ben trai (TextGetSize voi dung co chu va DPI)
//--   + khe ho InpLblAutoPadPx (nhan theo DPI). Do theo chuoi dai nhat co the xuat hien de cot dung yen khi do dai chuoi doi.
//--   Tat InpLblAutoFitCols -> dung InpRv2LblGapPx / InpRv1LblGapPx. Chi co hieu luc khi InpRv2LblAutoGap dang BAT (che do do bang pixel).
input bool  InpLblAutoFitCols   = true;    // Tu dong gian cach 3 cot nhan theo do phan giai/DPI man hinh
input int   InpLblAutoPadPx     = 14;      // Khe ho giua 2 cot khi bat che do tu dong (px, chuan 96 DPI)
// Khe ho CONG THEM giua cac cot nhan: _pad = (InpLblAutoPadPx + InpLblColExtraPadPx) * LblDpiScale() dung chung cho Pivot->RV1, RV1->RV2, RV2->diem het cot (xem DrawRv2RsiLabels).
input int   InpLblColExtraPadPx = 70;      // Khe ho CONG THEM giua Pivot/RV1/RV2/RV1-1m (px, chuan 96 DPI)
// So nen M1 lam khe ho chinh giua cot nhan Pivot va nhan RV1-1m (dong tinh _rv1m1FinalT trong DrawRv2RsiLabels).
input int   InpRv1M1GapM1Bars   = 32;       // Khe ho cot Pivot -> nhan RV1-1m (so nen M1)
// Cot RV2 neo tai nen lich su thu N cua khung M1 (dem tu nen M1 hien tai lui ve qua khu; xem DrawRv2RsiLabels). N <= 0 hoac lon hon so nen M1 doc duoc -> ep ve gia tri hop le gan nhat.
input int   InpRv1Rv2LeftM1BarIdx = 12;     // Cot RV2: neo tai nen lich su thu N cua khung M1
// Cot RV1 (khung >=5m) neo DOC LAP voi cot RV2: cach nen M1 dang chay hien tai N nen M1 ve TUONG LAI (N = InpRv1LeftM1FutureBars).
input int   InpRv1LeftM1FutureBars = 34;    // Cot RV1(>=5m) - neo DOC LAP: cach nen M1 hien tai N nen M1 ve TUONG LAI
input int   InpCsmaFutureBars      = 38;    // Nhan Close Simple (SMA) - cach nhan RV1 1m hien tai N nen CUA CHART ve TUONG LAI
// So diem Pivot lich su toi da va so segment toi da dung InpHistPoints / InpMaxSegments o nhom "Tham so tinh toan" phia tren (mac dinh 480 / 160).

//--- So khung ho tro: g_rvTfList va g_tfName cung noi dung va thu tu voi g_tfList (14 phan tu) ---
#define RV2_TF_COUNT 14

//--- Bang khung thoi gian / ten hien thi ---
ENUM_TIMEFRAMES g_rvTfList[RV2_TF_COUNT] = { PERIOD_M1, PERIOD_M5, PERIOD_M15, PERIOD_M30,
                                            PERIOD_H1, PERIOD_H2, PERIOD_H3, PERIOD_H4, PERIOD_H6,
                                            PERIOD_H8, PERIOD_H12, PERIOD_D1, PERIOD_W1, PERIOD_MN1 };
// So nen M1 can cho moi khung duoc tinh runtime qua GetRV2NBars(tf).
string g_tfName[RV2_TF_COUNT] = { "1m", "5m", "15m", "30m", "1h", "2h", "3h", "4h", "6h",
                                   "8h", "12h", "1D", "1W", "1MN" };

//--- Cache mau theo tung khung trong danh sach RV2_TF_COUNT, gom 1 lan trong OnInit (tra mau qua GetRV2Color) ---
color g_color[RV2_TF_COUNT];

//--- Prefix object OBJ_TREND cua duong RV2 va duong RV1 (Rolling VWAP truoc khi qua EMA) cua KHUNG CHON o nut UI (xem DrawRvLinesSelTF()).
//    Hai prefix khong la tien to cua nhau nen ObjectsDeleteAll cua duong nay khong xoa nham duong kia.
string g_rv2LinePrefix = "RV2_LINE_";
string g_rv1LinePrefix = "RV1_LINE_";

//--- Prefix cot nhan RV2 (OBJ_TEXT). Ten day du = prefix + ten khung (vd "RV2_RSILBL_15m"), khong trung ten voi duong RV2 (g_rv2LinePrefix). ---
string g_rv2RsiLblPrefix = "RV2_RSILBL_";

//--- Prefix cot nhan RV1 (OBJ_TEXT). Ten day du = prefix + ten khung (vd "RV1_RSILBL_15m"), khong trung ten voi duong RV1 (g_rv1LinePrefix). ---
string g_rv1RsiLblPrefix = "RV1_RSILBL_";

//--- Cache PHAN GOC ("<RSI5> / <+/-do lech> <TF>") cua nhan cot Pivot (DrawEmaSeries ghi), theo tung khung trong g_rvTfList
//    (chi so i = 0..RV2_TF_COUNT-1, cung chi so DrawRv2RsiLabels() dung cho _olTf[]). DrawRv2RsiLabels() doc lai de ghep chuoi
//    ghi len nhan Pivot. Rong "" = chua co nhan Pivot hop le cho khung do (tat InpShowWoodiePivotEma, thieu du lieu...).
string g_pivotLblBaseText[RV2_TF_COUNT];

// g_pivotLvlUsedIdx[i]: muc Pivot DA DUNG cho khung i (che do "TenMuc": moi khung tu chon muc gan Bid nhat cua chinh no, nen ten object
//   nhan/duong khac nhau theo khung - qua WoodieLevelLblPrefix()/WoodieLevelLinePrefix()). Gan trong vong lap PHAN 1 cua
//   DrawWoodiePivotEma(); DrawRv2RsiLabels() va PivotLabelsRelayout() chi doc.
int    g_pivotLvlUsedIdx[RV2_TF_COUNT];

//--- g_rv1M1Row2Txt: chuoi hang 2 cua nhan RV1 khung 1m ("TC <RV1up>/<RV1dn> <cmf> <tsf>/<dau> V<vpin><chieu>L<lam>"); DrawRv2RsiLabels() ghi vao g_bcTopTxt[1].
string g_rv1M1Row2Txt  = "";
//--- Cache W% cho cot <TF><RV1W%>/<RV2W%> <PivotW%> ... cua DrawMidPriceLabel() (hang 2.. duoi nhan RV1 1m). Chi so = chi so khung trong g_tfList (0..13).
//    DrawRv2RsiLabels() ghi moi nhip ve (reset ve "-" dau ham); thieu du lieu -> "-". Dinh dang giong cu: William %R SO NGUYEN, khong kep (AptRvChanW()).
string g_midRv1WStr[14];   // <RV1W%> cua khung
string g_midRv2WStr[14];   // <RV2W%> cua khung
string g_midPvWStr[14];    // <PivotW%> cua khung
string g_midTmStr[14];     // <TenMuc> (PP / R1..R9 / S1..S9, AptWoodieDisplayLvlForTF()) cua khung - in ngay sau <PivotW%>+kenh, truoc [<brkD>...]; "" = chua xac dinh
string g_midRsiStr[14];    // <RSI> ("<RSI>/<+-dRSI>" cua muc <TenMuc>, phan sau dau cach cua AptS1RsiTextForTF()) cua khung - in sau <TenMuc> trong cum brkD; "" = chua tinh
string g_midRowTailStr[14];   // cum sau <TF> cua nhan RV2: <SigBrk><brkD>/<brkddiff><TenMuc> <bodiff>/<(Bid-Open)/spread> <SpR2>/<SpR1> <diffavg>/<diffavg2>); DrawMidPriceLabel() tinh va ghi moi lan ve (khong con ve hang khung rieng), DrawRv2RsiLabels() doc; "" = chua co

datetime g_rv2ColEndTime = 0;

//--- Prefix object rieng cho Bar Chart ---
string g_barPrefix = "RV2_BARTF_";

//--- Prefix rieng cho nhan OBJ_TEXT tai vach Close (tach khoi OBJ_TREND cua than nen de ObjectsDeleteAll cua tung loai khong dam vao nhau) ---
string g_barLblPrefix = "RV2_BARTF_TXT_";

//--- So chu so thap phan RIENG cho truong (gia - RV1) cua cot nhan: 1 chu so sau dau phay (vd "-7.5"). ---
const int M1_ELP_LBL_DIF1_DIGITS = 1; // so chu so thap phan cua rieng truong (gia - RV1)

//--- Danh sach khung cho 2 bang nut UI (13 khung, xep 4 cot) ---
#define RV2_UI_TF_COUNT 13
#define RV2_UI_COLS      4
ENUM_TIMEFRAMES g_uiTFList[RV2_UI_TF_COUNT] = { PERIOD_M1, PERIOD_M5, PERIOD_M15, PERIOD_M30,
                                                PERIOD_H1, PERIOD_H2, PERIOD_H4, PERIOD_H6,
                                                PERIOD_H8, PERIOD_H12, PERIOD_D1, PERIOD_W1,
                                                PERIOD_MN1 };
string g_uiTFName[RV2_UI_TF_COUNT] = { "M1", "M5", "M15", "M30",
                                        "H1", "H2", "H4", "H6",
                                        "H8", "H12", "D1", "W1",
                                        "MN1" };

//--- Prefix nut + khung dang chon cua tung bang ---
string g_btnBcPrefix = "RV2_TFBTN_BC_";   // bang 2: than nen lon (Bar Chart)
ENUM_TIMEFRAMES g_barTF   = PERIOD_H4;        // khoi tao trong OnInit = InpBarChartTF

// Bang tra cuu 19 muc Pivot + muc dang chon. Chi so: 0 = PP, 1..9 = R1..R9, 10..18 = S1..S9 (khop thu tu enum ENUM_WOODIE_LVL). Bang nut xep 5 cot.
#define RV2_LVL_COUNT 19
#define RV2_LVL_COLS   5
#define RV2_LVL_S1    10   // chi so cua muc S1
string g_lvlName[RV2_LVL_COUNT] = { "PP", "R1", "R2", "R3", "R4",
                                     "R5", "R6", "R7", "R8", "R9",
                                     "S1", "S2", "S3", "S4", "S5",
                                     "S6", "S7", "S8", "S9" };
string g_btnLvPrefix   = "RV2_LVBTN_";        // prefix nut cua bang chon muc

//--- Bang check box chon KHUNG duoc HIEN HANG trong nhan Pivot / RV1 / RV2 (dat NGAY TREN bang chon muc Pivot, xem CreateRowTfPanel()).
//    g_tfRowShow[i] (i = chi so g_rvTfList = g_tfList: 1m..1nm): true = hien hang cua khung i, false = an. Mac dinh true ca 14 (OnInit).
//    Chi AN CHU NHAN: duong EMA/RV, cache gia, bo dem va mau van tinh du 14 khung nhu cu.
#define RV2_ROWTF_COLS 4
string g_btnRowTfPrefix = "RV2_ROWTFBTN_";
bool   g_tfRowShow[RV2_TF_COUNT];
datetime g_pivotM1LblTime = 0;   // moc thoi gian nhan Pivot 1m (DrawWoodiePivotEma ghi) - SlLabelTime() dung khi nhan 1m bi an

int    g_pivotLevelIdx = RV2_LVL_S1;          // khoi tao trong OnInit = InpWoodieLevelDefault

//--- Bang 2 nut chon nguon MUC Pivot dung de VE nhan/duong EMA Pivot cua TUNG khung trong DrawWoodiePivotEma():
//    nut "TenMuc" = moi khung tu chon muc gan Bid nhat cua chinh no (AptWoodieDisplayLvlForTF()); nut "BangUI" = dung CHUNG muc
//    g_pivotLevelIdx (bang chon muc Pivot 19 nut) cho ca 14 khung. Dat ngay duoi bang chon muc Pivot, cung toa do X va be rong
//    (xem CreatePivotModePanel()).
string g_btnPvModePrefix       = "RV2_PVMODEBTN_";
// g_pivotFollowDisplayedLvl: khoi tao true = "BangUI" (mac dinh); bam nut "TenMuc"/"BangUI" tren UI de doi (xem OnChartEvent()).
bool   g_pivotFollowDisplayedLvl = true;      // true = "BangUI" (Mode 2, mac dinh, g_pivotLevelIdx), false = "TenMuc" (Mode 1)

long     g_rvOrdRv1Up = 0;
long     g_rvOrdRv1Dn = 0;
datetime g_rvOrdBarT  = 0;
datetime g_rvOrdLast  = 0;

//--- Bo dem GIAY cong don cho hang UPDDND cua cum nhan duoi than nen lon (TpAccumUpdate()):
//      g_upD = tong giay W%(M1) > InpUpdWUp VA brkD(M1) > InpUpdBrkUp;  g_dnD = tong giay W% < InpUpdWDn VA brkD < InpUpdBrkDn
//    Cung khung moc / nhip cong don voi g_rvOrdRv1Up/Dn (khung than nen lon g_barTF; dt = TimeCurrent() - moc lan truoc, 0 < dt < 3600;
//    reset ve 0 khi than nen lon sang nen moi).
//      g_tpAccBarT = open time nen lon dang dem (doi -> reset ca hai)
//      g_tpAccLast = moc TimeCurrent() cua lan cap nhat truoc
long     g_upD        = 0;
long     g_dnD        = 0;

//--- Nguong dieu kien dem UpD/DnD (hang UPDDND, khung M1): UpD +1 giay khi W% > InpUpdWUp VA brkD > InpUpdBrkUp;  DnD +1 giay khi W% < InpUpdWDn VA brkD < InpUpdBrkDn.
input group "=== Dieu kien dem UpD/DnD (hang UPDDND, khung M1) ==="
input double InpUpdWUp   = -20.0;  // UpD: W% phai LON HON gia tri nay
input double InpUpdBrkUp = 80.0;   // UpD: brkD phai LON HON gia tri nay
input double InpUpdWDn   = -80.0;  // DnD: W% phai NHO HON gia tri nay
input double InpUpdBrkDn = 20.0;   // DnD: brkD phai NHO HON gia tri nay
datetime g_tpAccBarT  = 0;
datetime g_tpAccLast  = 0;

//--- Danh sach khung cho CANH BAO HET GIO, xep tu KHUNG LON NHAT xuong 5M (khong co 1M). Ten hien thi kieu "4H" / "30M" / "1MN". ---
#define RV2_CD_TF_COUNT 13
ENUM_TIMEFRAMES g_cdTFList[RV2_CD_TF_COUNT] = { PERIOD_MN1, PERIOD_W1, PERIOD_D1, PERIOD_H12,
                                                PERIOD_H8, PERIOD_H6, PERIOD_H4, PERIOD_H3,
                                                PERIOD_H2, PERIOD_H1, PERIOD_M30, PERIOD_M15,
                                                PERIOD_M5 };
string g_cdTFName[RV2_CD_TF_COUNT] = { "1MN", "1W", "1D", "12H",
                                        "8H", "6H", "4H", "3H",
                                        "2H", "1H", "30M", "15M",
                                        "5M" };

//--- Object prefix cho 9 duong Woodie Pivot EMA ---
const string PP_EMA_PP_PREFIX = "RVWAP_PP_EMA_PP_";   // prefix cho duong EMA(PP)
const string PP_EMA_R1_PREFIX = "RVWAP_PP_EMA_R1_";   // prefix cho duong EMA(R1)
const string PP_EMA_R2_PREFIX = "RVWAP_PP_EMA_R2_";   // prefix cho duong EMA(R2)
const string PP_EMA_R3_PREFIX = "RVWAP_PP_EMA_R3_";   // prefix cho duong EMA(R3)
const string PP_EMA_R4_PREFIX = "RVWAP_PP_EMA_R4_";   // prefix cho duong EMA(R4)
const string PP_EMA_R5_PREFIX = "RVWAP_PP_EMA_R5_";   // prefix cho duong EMA(R5)
const string PP_EMA_R6_PREFIX = "RVWAP_PP_EMA_R6_";   // prefix cho duong EMA(R6)
const string PP_EMA_R7_PREFIX = "RVWAP_PP_EMA_R7_";   // prefix cho duong EMA(R7)
const string PP_EMA_R8_PREFIX = "RVWAP_PP_EMA_R8_";   // prefix cho duong EMA(R8)
const string PP_EMA_R9_PREFIX = "RVWAP_PP_EMA_R9_";   // prefix cho duong EMA(R9)
const string PP_EMA_S1_PREFIX = "RVWAP_PP_EMA_S1_";   // prefix cho duong EMA(S1)
const string PP_EMA_S2_PREFIX = "RVWAP_PP_EMA_S2_";   // prefix cho duong EMA(S2)
const string PP_EMA_S3_PREFIX = "RVWAP_PP_EMA_S3_";   // prefix cho duong EMA(S3)
const string PP_EMA_S4_PREFIX = "RVWAP_PP_EMA_S4_";   // prefix cho duong EMA(S4)
const string PP_EMA_S5_PREFIX = "RVWAP_PP_EMA_S5_";   // prefix cho duong EMA(S5)
const string PP_EMA_S6_PREFIX = "RVWAP_PP_EMA_S6_";   // prefix cho duong EMA(S6)
const string PP_EMA_S7_PREFIX = "RVWAP_PP_EMA_S7_";   // prefix cho duong EMA(S7)
const string PP_EMA_S8_PREFIX = "RVWAP_PP_EMA_S8_";   // prefix cho duong EMA(S8)
const string PP_EMA_S9_PREFIX = "RVWAP_PP_EMA_S9_";   // prefix cho duong EMA(S9)

//--- Object prefix cho nhan RSI(5) o diem cuoi moi duong (OBJ_TEXT, khong phai duong ve) ---
const string PP_EMA_PP_LBL_PREFIX = "RVWAP_PP_EMA_PP_LBL_";   // nhan RSI5 cho EMA(PP)
const string PP_EMA_R1_LBL_PREFIX = "RVWAP_PP_EMA_R1_LBL_";   // nhan RSI5 cho EMA(R1)
const string PP_EMA_R2_LBL_PREFIX = "RVWAP_PP_EMA_R2_LBL_";   // nhan RSI5 cho EMA(R2)
const string PP_EMA_R3_LBL_PREFIX = "RVWAP_PP_EMA_R3_LBL_";   // nhan RSI5 cho EMA(R3)
const string PP_EMA_R4_LBL_PREFIX = "RVWAP_PP_EMA_R4_LBL_";   // nhan RSI5 cho EMA(R4)
const string PP_EMA_R5_LBL_PREFIX = "RVWAP_PP_EMA_R5_LBL_";   // nhan RSI5 cho EMA(R5)
const string PP_EMA_R6_LBL_PREFIX = "RVWAP_PP_EMA_R6_LBL_";   // nhan RSI5 cho EMA(R6)
const string PP_EMA_R7_LBL_PREFIX = "RVWAP_PP_EMA_R7_LBL_";   // nhan RSI5 cho EMA(R7)
const string PP_EMA_R8_LBL_PREFIX = "RVWAP_PP_EMA_R8_LBL_";   // nhan RSI5 cho EMA(R8)
const string PP_EMA_R9_LBL_PREFIX = "RVWAP_PP_EMA_R9_LBL_";   // nhan RSI5 cho EMA(R9)
const string PP_EMA_S1_LBL_PREFIX = "RVWAP_PP_EMA_S1_LBL_";   // nhan RSI5 cho EMA(S1)
const string PP_EMA_S2_LBL_PREFIX = "RVWAP_PP_EMA_S2_LBL_";   // nhan RSI5 cho EMA(S2)
const string PP_EMA_S3_LBL_PREFIX = "RVWAP_PP_EMA_S3_LBL_";   // nhan RSI5 cho EMA(S3)
const string PP_EMA_S4_LBL_PREFIX = "RVWAP_PP_EMA_S4_LBL_";   // nhan RSI5 cho EMA(S4)
const string PP_EMA_S5_LBL_PREFIX = "RVWAP_PP_EMA_S5_LBL_";   // nhan RSI5 cho EMA(S5)
const string PP_EMA_S6_LBL_PREFIX = "RVWAP_PP_EMA_S6_LBL_";   // nhan RSI5 cho EMA(S6)
const string PP_EMA_S7_LBL_PREFIX = "RVWAP_PP_EMA_S7_LBL_";   // nhan RSI5 cho EMA(S7)
const string PP_EMA_S8_LBL_PREFIX = "RVWAP_PP_EMA_S8_LBL_";   // nhan RSI5 cho EMA(S8)
const string PP_EMA_S9_LBL_PREFIX = "RVWAP_PP_EMA_S9_LBL_";   // nhan RSI5 cho EMA(S9)

// WOODIE_RSI_PERIOD la bien: Pe UI (bang nut chon chu ky RSI, xem CreateRsiPePanel()) gan gia tri khi nguoi dung bam; cung gia tri voi APT_S1_RSI_PERIOD
//   (dong bo boi Pe UI, xem xu ly click trong OnChartEvent()). Khoi tao = 5.
int WOODIE_RSI_PERIOD = 5;

//--- So NEN VE TUONG LAI (theo khung cua CHART hien tai) ma cot nhan Pivot cua khung M1 duoc dich sang PHAI so voi nen hien tai (nen hien tai + 1).
//    Gia tri nay cung duoc cong them cho cac cot nhan nam ben phai cot do (cot Pivot cua khung >= 5m, cot RV2, cot RV1).
const int PIVOT_M1_LBL_FUTURE_BARS = 1;

//+------------------------------------------------------------------+
//| Cac ham TRA CUU cho MUC Pivot dang chon o bang nut chon muc       |
//| (PP / R1..R9 / S1..S9). Chi so lvl chay 0..18 theo thu tu mang    |
//| g_lvlName: 0 = PP, 1..9 = R1..R9, 10..18 = S1..S9.                 |
//| Cong thuc gia tri (giong AptWoodieLevelValue; lvl = 10 la S1):     |
//|    PP = (H + L + 2*C)/4 ; rng = H - L                             |
//|    R1 = 2*PP - L                  S1 = 2*PP - H                   |
//|    R2 = PP + rng                  S2 = PP - rng                   |
//|    Rn = H + (n-1)*(PP - L)        Sn = L - (n-1)*(H - PP)  (n>=3) |
//| Prefix / nhan / mau tra ve dung cac hang so va input cua chinh muc do. |
//| Chi tra cuu: khong tao object, khong ve duong.                     |
//+------------------------------------------------------------------+
double WoodieLevelValue(const int lvl, const double hB, const double lB, const double cB)
{
   double pp    = (hB + lB + 2.0 * cB) / 4.0;   // PP = (H+L+2*C)/4
   double rng   = hB - lB;                      // bien do bar lien truoc
   double dRise = pp - lB;                      // PP - L
   double dFall = hB - pp;                      // H - PP

   switch(lvl)
   {
      case 0:  return pp;                       // PP
      case 1:  return 2.0 * pp - lB;            // R1 = 2*PP - L
      case 2:  return pp + rng;                 // R2 = PP + (H-L)
      case 3:  return hB + 2.0 * dRise;         // R3 = H + 2*(PP-L)
      case 4:  return hB + 3.0 * dRise;         // R4 = H + 3*(PP-L)
      case 5:  return hB + 4.0 * dRise;         // R5 = H + 4*(PP-L)
      case 6:  return hB + 5.0 * dRise;         // R6 = H + 5*(PP-L)
      case 7:  return hB + 6.0 * dRise;         // R7 = H + 6*(PP-L)
      case 8:  return hB + 7.0 * dRise;         // R8 = H + 7*(PP-L)
      case 9:  return hB + 8.0 * dRise;         // R9 = H + 8*(PP-L)
      case 10: return 2.0 * pp - hB;            // S1 = 2*PP - H
      case 11: return pp - rng;                 // S2 = PP - (H-L)
      case 12: return lB - 2.0 * dFall;         // S3 = L - 2*(H-PP)
      case 13: return lB - 3.0 * dFall;         // S4 = L - 3*(H-PP)
      case 14: return lB - 4.0 * dFall;         // S5 = L - 4*(H-PP)
      case 15: return lB - 5.0 * dFall;         // S6 = L - 5*(H-PP)
      case 16: return lB - 6.0 * dFall;         // S7 = L - 6*(H-PP)
      case 17: return lB - 7.0 * dFall;         // S8 = L - 7*(H-PP)
      case 18: return lB - 8.0 * dFall;         // S9 = L - 8*(H-PP)
   }
   return 2.0 * pp - hB;                        // du phong: S1 (mac dinh cu)
}

//+------------------------------------------------------------------+
//| AptPivotUiLevelIdx / AptPivotEmaPeriod: doc muc Pivot dang chon o bang Pivot UI (g_pivotLevelIdx, mac dinh InpWoodieLevelDefault = PP) va chu ky   |
//|   EMA Pivot (InpWoodiePivotEmaPeriod). Dung de AptRv1LwmaCrossCnt() (khai bao truoc o tren) doc duoc cac bien nay.                          |
//+------------------------------------------------------------------+
int AptPivotUiLevelIdx()
{
   return g_pivotLevelIdx;
}

int AptPivotEmaPeriod()
{
   return InpWoodiePivotEmaPeriod;
}

//+------------------------------------------------------------------+
//| AptPivotEmaSeriesLvl: chuoi EMA Pivot cua muc lvl (0..18; AptPivotUiEmaSeries() truyen vao muc dang chon o bang Pivot UI g_pivotLevelIdx) cua khung tf, DUNG CACH DrawWoodiePivotEma() + DrawEmaSeries() |
//|   tinh duong EMA Pivot ve tren chart (cung WoodieLevelValue(), cung chu ky EMA, cung cach lay H/L/C: s = 0 dung bar 0, s >= 1 dung bar s + 1;       |
//|   seed tai diem CU NHAT). Khac DrawWoodiePivotEma(): LUON dung muc chon o bang Pivot UI (khong theo che do "TenMuc").                                 |
//|   outEma[0] = EMA nen dang chay, outEma[k] = EMA nen TF shift k. want = so diem toi da. Tra ve so diem (0 = that bai). Chi doc gia.                  |
//+------------------------------------------------------------------+
int AptPivotEmaSeriesLvl(const ENUM_TIMEFRAMES tf, const int want, const int lvl, double &outEma[])
{
   ArrayResize(outEma, 0);

   int w = (want < 3) ? 3 : want;
   int need = w + 1;                // +1 vi moi diem s can bar lien truoc (s + 1)

   double hi[], lo[], cl[];
   ArraySetAsSeries(hi, true);
   ArraySetAsSeries(lo, true);
   ArraySetAsSeries(cl, true);

   int cpH = CopyHigh (_Symbol, tf, 0, need, hi);
   int cpL = CopyLow  (_Symbol, tf, 0, need, lo);
   int cpC = CopyClose(_Symbol, tf, 0, need, cl);
   int got = MathMin(MathMin(cpH, cpL), cpC);
   if(got < 2)
      return(0);

   int points = got - 1;
   if(points > w)
      points = w;
   if(points < 3)
      return(0);

   ArrayResize(outEma, points);
   int    pEma = MathMax(1, InpWoodiePivotEmaPeriod);
   double aEma = 2.0 / (pEma + 1.0);
   double e      = 0.0;
   bool   seeded = false;
   for(int s = points - 1; s >= 0; s--)
   {
      double hB = (s == 0) ? hi[0] : hi[s + 1];
      double lB = (s == 0) ? lo[0] : lo[s + 1];
      double cB = (s == 0) ? cl[0] : cl[s + 1];
      double rawV = WoodieLevelValue(lvl, hB, lB, cB);
      if(!seeded)
      {
         e = rawV;
         seeded = true;
      }
      else
      {
         e = aEma * rawV + (1.0 - aEma) * e;
      }
      outEma[s] = e;
   }
   return(points);
}

//+------------------------------------------------------------------+
//| AptPivotUiEmaSeries: nhu AptPivotEmaSeriesLvl() nhung LUON dung muc dang chon o bang Pivot UI (g_pivotLevelIdx). |
//+------------------------------------------------------------------+
int AptPivotUiEmaSeries(const ENUM_TIMEFRAMES tf, const int want, double &outEma[])
{
   return AptPivotEmaSeriesLvl(tf, want, g_pivotLevelIdx, outEma);
}

//==================================================================
//  AptOwWCalc: <OW W%> cua khung tf.
//    OW = chuoi AptOpenEmaSeries() (cach tinh theo OW MODE UI, chu ky P = g_aptBrkDBars): ow[0] = OW dung cho nen dang chay (= OW tai nen shift 1), ow[k] = OW tai nen shift k+1.
//    outW = William %R cua ow[0] trong kenh HH/LL cua ow[1..P] (AptRvChanW(), cung cach <PivotW%>): (HH - ow[0]) / (HH - LL) * -100, SO NGUYEN, khong kep.
//    OW chi tinh tren nen DA DONG nen ket qua chi doi khi sang nen moi / doi P / doi OW MODE -> cache theo (khung idx, open time nen shift 0, P, khoa OW MODE).
//    Thieu du lieu (< P + 1 diem OW) -> false, noi goi in "-". Chi doc gia: khong tao object.
//==================================================================
bool AptRvChanW(const double &rv[], const int validCount, int &outW);   // khai bao truoc: than ham nam o khoi "KENH HH/LL TINH TREN CHUOI RV1 / RV2" phia sau

bool AptOwWCalc(const int idx, const ENUM_TIMEFRAMES tf, string &outW)
  {
   outW = "";
   if(idx < 0 || idx >= APT_BRK_STREAK_TF_COUNT)
      return false;

   const int P = (g_aptBrkDBars < 2) ? 2 : ((g_aptBrkDBars > 500) ? 500 : g_aptBrkDBars);
   datetime t0 = iTime(_Symbol, tf, 0);
   if(t0 <= 0)
      return false;
   const int key = AptOwModeKey(P);

   static datetime s_oBar[APT_BRK_STREAK_TF_COUNT];
   static int      s_oP  [APT_BRK_STREAK_TF_COUNT];
   static int      s_oKey[APT_BRK_STREAK_TF_COUNT];
   static string   s_oW  [APT_BRK_STREAK_TF_COUNT];

   if(s_oBar[idx] != t0 || s_oP[idx] != P || s_oKey[idx] != key)
     {
      s_oBar[idx] = 0;   // tinh that bai -> khong cache, lan sau thu lai
      s_oW[idx]   = "";
      double ow[];
      int av = AptOpenEmaSeries(tf, P, P + 2, ow);
      if(av < P + 1)
         return false;
      int w = 0;
      s_oW[idx] = AptRvChanW(ow, av, w) ? IntegerToString(w) : "";
      s_oP  [idx] = P;
      s_oKey[idx] = key;
      s_oBar[idx] = t0;
     }

   outW = s_oW[idx];
   return (outW != "");
  }

//+------------------------------------------------------------------+
//| WoodieLevelLinePrefix: prefix object duong EMA cua muc Pivot lvl (0..18). |
//+------------------------------------------------------------------+
string WoodieLevelLinePrefix(const int lvl)
{
   switch(lvl)
   {
      case 0:  return PP_EMA_PP_PREFIX;
      case 1:  return PP_EMA_R1_PREFIX;
      case 2:  return PP_EMA_R2_PREFIX;
      case 3:  return PP_EMA_R3_PREFIX;
      case 4:  return PP_EMA_R4_PREFIX;
      case 5:  return PP_EMA_R5_PREFIX;
      case 6:  return PP_EMA_R6_PREFIX;
      case 7:  return PP_EMA_R7_PREFIX;
      case 8:  return PP_EMA_R8_PREFIX;
      case 9:  return PP_EMA_R9_PREFIX;
      case 10: return PP_EMA_S1_PREFIX;
      case 11: return PP_EMA_S2_PREFIX;
      case 12: return PP_EMA_S3_PREFIX;
      case 13: return PP_EMA_S4_PREFIX;
      case 14: return PP_EMA_S5_PREFIX;
      case 15: return PP_EMA_S6_PREFIX;
      case 16: return PP_EMA_S7_PREFIX;
      case 17: return PP_EMA_S8_PREFIX;
      case 18: return PP_EMA_S9_PREFIX;
   }
   return PP_EMA_S1_PREFIX;                     // du phong: S1
}

//+------------------------------------------------------------------+
//| WoodieLevelLblPrefix: prefix object nhan RSI5 cua muc Pivot lvl (0..18). |
//+------------------------------------------------------------------+
string WoodieLevelLblPrefix(const int lvl)
{
   switch(lvl)
   {
      case 0:  return PP_EMA_PP_LBL_PREFIX;
      case 1:  return PP_EMA_R1_LBL_PREFIX;
      case 2:  return PP_EMA_R2_LBL_PREFIX;
      case 3:  return PP_EMA_R3_LBL_PREFIX;
      case 4:  return PP_EMA_R4_LBL_PREFIX;
      case 5:  return PP_EMA_R5_LBL_PREFIX;
      case 6:  return PP_EMA_R6_LBL_PREFIX;
      case 7:  return PP_EMA_R7_LBL_PREFIX;
      case 8:  return PP_EMA_R8_LBL_PREFIX;
      case 9:  return PP_EMA_R9_LBL_PREFIX;
      case 10: return PP_EMA_S1_LBL_PREFIX;
      case 11: return PP_EMA_S2_LBL_PREFIX;
      case 12: return PP_EMA_S3_LBL_PREFIX;
      case 13: return PP_EMA_S4_LBL_PREFIX;
      case 14: return PP_EMA_S5_LBL_PREFIX;
      case 15: return PP_EMA_S6_LBL_PREFIX;
      case 16: return PP_EMA_S7_LBL_PREFIX;
      case 17: return PP_EMA_S8_LBL_PREFIX;
      case 18: return PP_EMA_S9_LBL_PREFIX;
   }
   return PP_EMA_S1_LBL_PREFIX;                 // du phong: S1
}

//+------------------------------------------------------------------+
//| WoodieLevelColor: mau duong/nhan cua muc Pivot lvl (input InpEma*Color). |
//+------------------------------------------------------------------+
color WoodieLevelColor(const int lvl)
{
   switch(lvl)
   {
      case 0:  return InpEmaPPColor;
      case 1:  return InpEmaR1Color;
      case 2:  return InpEmaR2Color;
      case 3:  return InpEmaR3Color;
      case 4:  return InpEmaR4Color;
      case 5:  return InpEmaR5Color;
      case 6:  return InpEmaR6Color;
      case 7:  return InpEmaR7Color;
      case 8:  return InpEmaR8Color;
      case 9:  return InpEmaR9Color;
      case 10: return InpEmaS1Color;
      case 11: return InpEmaS2Color;
      case 12: return InpEmaS3Color;
      case 13: return InpEmaS4Color;
      case 14: return InpEmaS5Color;
      case 15: return InpEmaS6Color;
      case 16: return InpEmaS7Color;
      case 17: return InpEmaS8Color;
      case 18: return InpEmaS9Color;
   }
   return InpEmaS1Color;                        // du phong: S1
}

//+------------------------------------------------------------------+
//| CalcRSI: tinh RSI(period) cho 1 chuoi gia tri "series"            |
//| (s = cu nhat -> moi nhat, cung thu tu voi mang EMA), Wilder        |
//| smoothing chuan (giong RSI mac dinh cua MT5). Ket qua ghi vao      |
//| rsiOut[] cung chieu dai voi series/points. Cac vi tri qua cu       |
//| (khong du du lieu de seed) duoc gan bang gia tri RSI seed dau tien. |
//+------------------------------------------------------------------+
void CalcRSI(const double &series[], const int points, const int period, double &rsiOut[])
{
   ArrayResize(rsiOut, points);
   for(int i = 0; i < points; i++) rsiOut[i] = 50.0;
   if(points < period + 1) return;

   double gainSum = 0.0, lossSum = 0.0;
   for(int k = 0; k < period; k++)
   {
      int s = points - 2 - k;
      double diff = series[s] - series[s + 1];
      if(diff > 0) gainSum += diff; else lossSum += -diff;
   }
   double avgGain = gainSum / period;
   double avgLoss = lossSum / period;
   int    seedIndex = points - 1 - period;
   double rs     = (avgLoss == 0.0) ? 0.0 : avgGain / avgLoss;
   double rsiVal = (avgLoss == 0.0) ? 100.0 : 100.0 - 100.0 / (1.0 + rs);
   rsiOut[seedIndex] = rsiVal;

   for(int s = seedIndex - 1; s >= 0; s--)
   {
      double diff = series[s] - series[s + 1];
      double gain = (diff > 0) ? diff : 0.0;
      double loss = (diff < 0) ? -diff : 0.0;
      avgGain = (avgGain * (period - 1) + gain) / period;
      avgLoss = (avgLoss * (period - 1) + loss) / period;
      rs = (avgLoss == 0.0) ? 0.0 : avgGain / avgLoss;
      rsiOut[s] = (avgLoss == 0.0) ? 100.0 : 100.0 - 100.0 / (1.0 + rs);
   }
   for(int s = seedIndex + 1; s < points; s++) rsiOut[s] = rsiVal;
}

//+------------------------------------------------------------------+
//| CalcRsiTrendBars: dem so nen LIEN TIEP RSI (rsiArr[], as-series,  |
//| tra ve tu CalcRSI()) dang cung chieu (tang hoac giam), tinh tu     |
//| diem moi nhat (index 0) lui ve qua khu. Chi dung cho DrawEmaSeries() |
//| (nhan RSI5/xu huong cua cot Pivot).                                |
//|                                                                    |
//| Vao:  rsiArr[]  - mang RSI as-series (index 0 = moi nhat), lay thang tu CalcRSI() |
//|       rsiPoints - so phan tu HOP LE trong rsiArr[]                 |
//| Ra:   int - so nen RSI da LIEN TUC cung chieu; dau + neu dang TANG |
//|       (rsi[0] > rsi[1]), dau - neu dang GIAM (rsi[0] < rsi[1]).     |
//|       rsi[0] == rsi[1] hoac rsiPoints < 2 -> 0.                    |
//|                                                                    |
//| Cach dem: so sanh tung cap (rsi[k], rsi[k+1]) tu k=0; chieu cua cap |
//| giong cap dau thi dem tiep; gap chieu nguoc lai hoac bang nhau thi dung. |
//+------------------------------------------------------------------+
int CalcRsiTrendBars(const double &rsiArr[], const int rsiPoints)
{
   if(rsiPoints < 2)
      return(0);

   double d0 = rsiArr[0] - rsiArr[1];
   if(d0 == 0.0)
      return(0);

   int dir = (d0 > 0.0) ? 1 : -1;
   int cnt = 1;

   for(int k = 1; k + 1 < rsiPoints; k++)
   {
      double dk = rsiArr[k] - rsiArr[k + 1];
      if(dk == 0.0)
         break;
      int dirk = (dk > 0.0) ? 1 : -1;
      if(dirk != dir)
         break;
      cnt++;
   }

   return(dir * cnt);
}

//+------------------------------------------------------------------+
// Tai su dung object OBJ_TREND/OBJ_TEXT cua DrawEmaSeries() (goi tu vong lap PHAN 1 cua DrawWoodiePivotEma(),
//   moi khung g_rvTfList[i] la MOT "cho" rieng, slotId = i) thay vi xoa-het-roi-tao-lai moi lan goi.
//   g_emaSlotPrefix[]/g_emaSlotLabel[]/g_emaSlotSegCount[] nho theo tung cho: prefix duong + ten nhan + so doan OBJ_TREND da ve o lan goi truoc.
//   Hai truong hop can don dep:
//     (1) Doi muc Pivot dang chon (bam nut khac, hoac che do "TenMuc" tu doi muc theo Bid) -> prefix cho nay doi hoan toan
//         (vd "PP_EMA_S1_1m_" -> "PP_EMA_R3_1m_") -> SpmEmaSlotBegin() xoa sach doan + EXT + nhan cua PREFIX CU truoc khi ve muc moi.
//     (2) Cung prefix nhung lan nay can it doan hon lan truoc -> SpmEmaSlotEnd() xoa phan du (chi so >= so doan lan nay).
//   Ngoai hai truong hop tren, khong xoa gi - object cu duoc SpmUpsertTrendSeg() ObjectMove() sang vi tri moi.
int    g_emaSlotSegCount[RV2_TF_COUNT];
string g_emaSlotPrefix  [RV2_TF_COUNT];
string g_emaSlotLabel   [RV2_TF_COUNT];

// Don sach TOAN BO object (doan 0..oldSegCount-1 + "EXT" + nhan rieng) cua MOT prefix cu - dung khi doi muc Pivot.
void SpmEmaSlotWipe(const string oldPrefix, const string oldLabel, const int oldSegCount)
{
   for(int k = 0; k < oldSegCount; k++)
      ObjectDelete(0, oldPrefix + IntegerToString(k));
   ObjectDelete(0, oldPrefix + "EXT");
   if(oldLabel != "")
      ObjectDelete(0, oldLabel);
}

// Goi o DAU DrawEmaSeries(): dam bao cho slotId dang dung DUNG prefix/nhan cua lan goi nay - khac lan truoc (doi muc Pivot) thi don sach
//   prefix CU (SpmEmaSlotWipe) va tra ve 0. Tra ve SO DOAN da ve o lan goi truoc (cung prefix) de don phan du sau khi ve xong (xem SpmEmaSlotEnd).
int SpmEmaSlotBegin(const int slotId, const string prefix, const string label)
{
   if(slotId < 0 || slotId >= RV2_TF_COUNT)
      return 0;
   if(g_emaSlotPrefix[slotId] != "" && g_emaSlotPrefix[slotId] != prefix)
   {
      SpmEmaSlotWipe(g_emaSlotPrefix[slotId], g_emaSlotLabel[slotId], g_emaSlotSegCount[slotId]);
      g_emaSlotSegCount[slotId] = 0;
   }
   g_emaSlotPrefix[slotId] = prefix;
   g_emaSlotLabel [slotId] = label;
   return g_emaSlotSegCount[slotId];
}

// Goi o CUOI DrawEmaSeries(): ghi lai SO DOAN vua ve xong cho slotId, don PHAN DU neu lan nay ve it doan hon lan truoc.
void SpmEmaSlotEnd(const int slotId, const int newSegCount)
{
   if(slotId < 0 || slotId >= RV2_TF_COUNT)
      return;
   int oldSegCount = g_emaSlotSegCount[slotId];
   for(int k = newSegCount; k < oldSegCount; k++)
      ObjectDelete(0, g_emaSlotPrefix[slotId] + IntegerToString(k));
   g_emaSlotSegCount[slotId] = newSegCount;
}

// Tao moi (chua co) hoac doi cho (da co - chi ObjectMove hai dau mut) 1 doan OBJ_TREND cua DrawEmaSeries(), giu nguyen moi thuoc tinh hien thi.
void SpmUpsertTrendSeg(const string name, const datetime t1, const double p1,
                        const datetime t2, const double p2,
                        const color clr, const int width, const ENUM_LINE_STYLE style = STYLE_DOT)
{
   if(ObjectFind(0, name) >= 0)
   {
      ObjectMove(0, name, 0, t1, p1);
      ObjectMove(0, name, 1, t2, p2);
   }
   else
   {
      if(!ObjectCreate(0, name, OBJ_TREND, 0, t1, p1, t2, p2))
         return;
      ObjectSetInteger(0, name, OBJPROP_STYLE,      STYLE_DOT);
      ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT,  false);
      ObjectSetInteger(0, name, OBJPROP_RAY_LEFT,   false);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN,     true);
      ObjectSetInteger(0, name, OBJPROP_BACK,       true);
   }
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style);   // set moi lan
}

//==================================================================
//  DrawOwLine: VE DUONG OW = EMA(Open) chu ky n (n = g_aptBrkDBars, nut B<n>) theo KHUNG chon o NUT UI
//    (hang nut 1m..1nm, g_aptBrkDTfIdx - xem AptExtraLineTf(); bam lai nut dang sang = TAT -> don duong).
//    Gia tri tai nen k cua khung = EMA(Open) tinh den het nen DA DONG shift k+1 (AptOpenEmaSeries()) - nen diem k = 0 TRUNG gia tri nhan OW
//    (AptOpenLwma()). Moi diem = 1 nen cua khung do, toi da InpHistPoints diem, gop buoc theo InpMaxSegments (cung cach cac duong RV1/RV2/Pivot).
//    Noi them doan NGANG tu nen moi nhat cua khung toi nen hien tai cua CHART. Mau clrLimeGreen (cung nhan OW), net 1, kieu DASH (cung nhom duong khung phu).
//    Gia tri chi doi khi khung chon sang nen moi / doi n / doi khung -> CACHE theo khoa (g_owLineKey), khong tinh lai moi tick. Thieu du lieu -> don duong, KHONG doan.
//    Goi tu DrawBrkDHHLL() (da duoc goi khi doi khung / doi nut B<n> / moi lan ve). Object: g_owLinePrefix + so thu tu | "EXT". Ham khong them input.
//==================================================================
string g_owLinePrefix = PFX"OWLN_";
int    g_owLineSegCnt = 0;
string g_owLineKey    = "";

void DrawOwLineClear()
  {
   for(int k = 0; k < g_owLineSegCnt; k++)
      ObjectDelete(0, g_owLinePrefix + IntegerToString(k));
   ObjectDelete(0, g_owLinePrefix + "EXT");
   g_owLineSegCnt = 0;
   g_owLineKey    = "";
  }

void DrawOwLine()
  {
   ENUM_TIMEFRAMES tf = PERIOD_CURRENT;
   if(!AptExtraLineTf(tf))
     {
      if(g_owLineSegCnt > 0 || g_owLineKey != "")
         DrawOwLineClear();
      return;
     }
   int n = g_aptBrkDBars;
   if(n < 2)   n = 2;
   if(n > 500) n = 500;

   datetime tBar0  = iTime(_Symbol, tf, 0);
   datetime tChart = iTime(_Symbol, _Period, 0);
   if(tBar0 <= 0)
      return;
   string key = IntegerToString((int)tf) + "|" + IntegerToString(n) + "|" + IntegerToString((long)tBar0) + "|" + IntegerToString((long)tChart)
                + "|" + IntegerToString(InpHistPoints) + "|" + IntegerToString(InpMaxSegments)
                + "|" + IntegerToString(g_aptOwMode);   // doi che do OW -> ve lai duong
   if(key == g_owLineKey && (g_owLineSegCnt == 0 || ObjectFind(0, g_owLinePrefix + "0") >= 0))
      return;

   int points = (InpHistPoints < 2) ? 2 : InpHistPoints;
   // [GIU NGUYEN - KHONG XOA] double   op[];
   // [GIU NGUYEN - KHONG XOA] datetime tm[];
   // [GIU NGUYEN - KHONG XOA] ArraySetAsSeries(op, true);              // op[i] = Open nen shift i+1
   // [GIU NGUYEN - KHONG XOA] ArraySetAsSeries(tm, true);              // tm[k] = thoi gian MO nen shift k (k = 0 = nen dang chay)
   // [GIU NGUYEN - KHONG XOA] int gotO = CopyOpen(_Symbol, tf, 1, points + n, op);
   // [GIU NGUYEN - KHONG XOA] int gotT = CopyTime(_Symbol, tf, 0, points, tm);
   // [GIU NGUYEN - KHONG XOA] if(gotO < n + 2 || gotT < 2)
   // [GIU NGUYEN - KHONG XOA]   {
   // [GIU NGUYEN - KHONG XOA]    DrawOwLineClear();
   // [GIU NGUYEN - KHONG XOA]    return;
   // [GIU NGUYEN - KHONG XOA]   }
   // [GIU NGUYEN - KHONG XOA] if(points > gotO - n) points = gotO - n;
   // [GIU NGUYEN - KHONG XOA] if(points > gotT)     points = gotT;
   // [GIU NGUYEN - KHONG XOA] if(points < 2)
   // [GIU NGUYEN - KHONG XOA]   {
   // [GIU NGUYEN - KHONG XOA]    DrawOwLineClear();
   // [GIU NGUYEN - KHONG XOA]    return;
   // [GIU NGUYEN - KHONG XOA]   }
   // [GIU NGUYEN - KHONG XOA] 
   // [GIU NGUYEN - KHONG XOA] double sw = 0.0;
   // [GIU NGUYEN - KHONG XOA] for(int i = 0; i < n; i++)
   // [GIU NGUYEN - KHONG XOA]    sw += (double)(n - i);
   double   owS[];
   datetime tm[];
   ArraySetAsSeries(tm, true);              // tm[k] = thoi gian MO nen shift k (k = 0 = nen dang chay)
   int gotO = AptOpenEmaSeries(tf, n, points, owS);   // owS[s] = OW = EMA(Open) tinh den het nen DA DONG shift s+1
   int gotT = CopyTime(_Symbol, tf, 0, points, tm);
   if(gotO < 2 || gotT < 2)
     {
      DrawOwLineClear();
      return;
     }
   if(points > gotO) points = gotO;
   if(points > gotT) points = gotT;
   if(points < 2)
     {
      DrawOwLineClear();
      return;
     }

   int      step  = MathMax(1, points / MathMax(1, InpMaxSegments));
   datetime prevT = 0;
   double   prevV = 0.0;
   int      seg   = 0;
   double   lastV = 0.0;
   for(int s = points - 1; s >= 0; )
     {
      // [GIU NGUYEN - KHONG XOA] double v = 0.0;
      // [GIU NGUYEN - KHONG XOA] for(int j = 0; j < n; j++)
      // [GIU NGUYEN - KHONG XOA]    v += (double)(n - j) * op[s + j];
      // [GIU NGUYEN - KHONG XOA] v /= sw;
      double v = owS[s];
      if(v > 0.0)
        {
         if(prevT > 0)
            SpmUpsertTrendSeg(g_owLinePrefix + IntegerToString(seg++), prevT, prevV, tm[s], v, clrLimeGreen, 1, STYLE_DASH);
         prevT = tm[s];
         prevV = v;
         if(s == 0) lastV = v;
        }
      if(s == 0) break;
      s -= step;
      if(s < 0) s = 0;   // dam bao diem cuoi (nen moi nhat) luon co mat
     }

   // Noi dai NGANG tu nen moi nhat cua khung toi nen hien tai cua CHART
   if(lastV > 0.0 && tChart > tm[0])
      SpmUpsertTrendSeg(g_owLinePrefix + "EXT", tm[0], lastV, tChart, lastV, clrLimeGreen, 1, STYLE_DASH);
   else
      ObjectDelete(0, g_owLinePrefix + "EXT");

   for(int k = seg; k < g_owLineSegCnt; k++)
      ObjectDelete(0, g_owLinePrefix + IntegerToString(k));
   g_owLineSegCnt = seg;
   g_owLineKey    = key;
  }

void DrawEmaSeries(const int slotId, const string prefix, const color lineColor,
                    const double &raw[], const int points,
                    const datetime &tmP[], const int step,
                    const string lblPrefix,
                    const string tfSuffix = "",
                    const bool drawLine = true, const int lblFutureBars = 0,
                    const datetime lblTimeAbs = 0,
                    const color lblColorOverride = CLR_NONE,
                    const int lineWidth = 1,
                    const ENUM_LINE_STYLE lineStyle = STYLE_DOT)
{
   SpmEmaSlotBegin(slotId, prefix, lblPrefix);
   double ema[];
   ArrayResize(ema, points);
   int    pEma = MathMax(1, InpWoodiePivotEmaPeriod);
   double aEma = 2.0 / (pEma + 1.0);
   double e = 0.0;
   bool   seeded = false;
   for(int s = points - 1; s >= 0; s--)
   {
      if(!seeded)
      {
         e = raw[s];
         seeded = true;
      }
      else
      {
         e = aEma * raw[s] + (1.0 - aEma) * e;
      }
      ema[s] = e;
   }
   g_dsEmaOk = (points >= 2 && ema[0] > 0.0 && ema[1] > 0.0);
   if(g_dsEmaOk)
     {
      g_dsEma0 = ema[0];
      g_dsEma1 = ema[1];
     }

   datetime tChartNow = iTime(_Symbol, _Period, 0);
   datetime tEnd      = (points > 0) ? tmP[0] : 0;
   if(points > 0 && tChartNow > tmP[0]) tEnd = tChartNow;

   if(drawLine)
   {
      datetime prevT = 0;
      double   prevV = 0.0;
      int      seg   = 0;

      for(int s = points - 1; s >= 0; s -= step)
      {
         double v = ema[s];
         if(v > 0.0)
         {
            if(prevT > 0)
            {
               string nm = prefix + IntegerToString(seg++);
               SpmUpsertTrendSeg(nm, prevT, prevV, tmP[s], v, lineColor, lineWidth, lineStyle);
            }
            prevT = tmP[s];
            prevV = v;
         }
      }

      // Dam bao diem cuoi (s=0) luon co mat
      if(((points - 1) % step) != 0)
      {
         double val0 = ema[0];
         if(val0 > 0.0 && prevT > 0)
         {
            string nm0 = prefix + IntegerToString(seg++);
            SpmUpsertTrendSeg(nm0, prevT, prevV, tmP[0], val0, lineColor, lineWidth, lineStyle);
         }
      }

      if(points > 0 && tEnd > tmP[0] && ema[0] > 0.0)
         SpmUpsertTrendSeg(prefix + "EXT", tmP[0], ema[0], tEnd, ema[0], lineColor, lineWidth, lineStyle);
      else
         ObjectDelete(0, prefix + "EXT");   // doan noi dai lan truoc (neu co) khong con dieu kien -> don, tranh sot doan "chet"

      SpmEmaSlotEnd(slotId, seg);
   }
   else
   {
      SpmEmaSlotEnd(slotId, 0);
      ObjectDelete(0, prefix + "EXT");
   }

   datetime tLbl = tEnd;
   if(lblTimeAbs > 0)
   {
      tLbl = lblTimeAbs;
   }
   else
      if(lblFutureBars > 0)
      {
         int _psec = PeriodSeconds(_Period);
         if(_psec > 0) tLbl = tEnd + (datetime)((long)lblFutureBars * (long)_psec);
      }

   // --- RSI(WOODIE_RSI_PERIOD) tren chinh chuoi EMA vua ve, ghi nhan gia tri cuoi cung ---
   if(points > WOODIE_RSI_PERIOD)
   {
      double rsiArr[];
      CalcRSI(ema, points, WOODIE_RSI_PERIOD, rsiArr);
      double rsiNow  = rsiArr[0];
      double rsiDiff = (double)CalcRsiTrendBars(rsiArr, points);
      string _rsiExtDiffTxt = (rsiDiff >= 0 ? "+" : "") + DoubleToString(rsiDiff, 0);
      // [LUU Y FORMAT] Chuoi nay ("<TF> <RSI5> / <+-diffRSI>") CHI la chuoi GOC, luu vao g_pivotLblBaseText[]. Chu HIEN TREN CHART cua nhan Pivot
      //   duoc DrawRv2RsiLabels() GHI DE sau do - xem "BANG FORMAT NHAN HIEN TAI" o dau file.
      string txt = DoubleToString(rsiNow, 0) + " / " + _rsiExtDiffTxt;
      if(tfSuffix != "") txt = tfSuffix + " " + txt;

      color _lblClr = (lblColorOverride != CLR_NONE) ? lblColorOverride : lineColor;
      if(ObjectFind(0, lblPrefix) < 0)
      {
         ObjectCreate(0, lblPrefix, OBJ_TEXT, 0, tLbl, ema[0]);
         ObjectSetInteger(0, lblPrefix, OBJPROP_ANCHOR,     ANCHOR_LEFT);
         ObjectSetInteger(0, lblPrefix, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, lblPrefix, OBJPROP_HIDDEN,     true);
         ObjectSetInteger(0, lblPrefix, OBJPROP_BACK,       false);
      }
      else
      {
         ObjectMove(0, lblPrefix, 0, tLbl, ema[0]);
      }
      ObjectSetString (0, lblPrefix, OBJPROP_TEXT,     txt);
      ObjectSetInteger(0, lblPrefix, OBJPROP_COLOR,    _lblClr);
      ObjectSetInteger(0, lblPrefix, OBJPROP_FONTSIZE, 8);
   }
   else if(ObjectFind(0, lblPrefix) >= 0)
   {
      ObjectDelete(0, lblPrefix);
   }
}

//+------------------------------------------------------------------+
//| AptPivotRowColor: mau cua MOT hang nhan (Pivot / RV1 / RV2 / Pattern) cua khung tf.                          |
//|  Chieu: rvUp = RV1(tf) >= RV2(tf), rvDn = RV1(tf) < RV2(tf) (doc g_rv1ValCache / g_aptRv2All).                |
//|  Bo dem giay cua khung: Up/Dn, UpA/DnA, UpB/DnB, UpC/DnC (g_aptBrkAcc*). brk = round((Close-prevLow)/(prevHigh-prevLow)*100). |
//|  TANG: Magenta (UpB,UpC,UpA,Up > 0 va Dn* == 0, brk > 110, RSI5 >= 50) > Orange (4 cap) > Gold (B,C,A) > Yellow (B,C) > Lime (B).|
//|  GIAM: White (4 cap Dn, brk < -10, RSI5 < 50) > LightGray (4 cap) > Silver (B,C,A) > LightSteelBlue (B,C) > LightBlue (B).  |
//|  Khong khop bac / thieu RV1-RV2 -> Aqua. Chi doc cache + gia, khong tao/sua/xoa object.                         |
//+------------------------------------------------------------------+
color AptPivotRowColor(const ENUM_TIMEFRAMES tf)
{
   // RV1/RV2 doc tu cache (g_rv1ValCache / g_aptRv2All). Thieu RV1/RV2 hoac khong khop bac nao -> aqua.
   color clr = clrAqua;

   datetime tC     = iTime(_Symbol,_Period,0);
   int      barIdx = iBarShift(_Symbol,tf,tC,false);

   double rv1 = 0.0, rv2 = 0.0;
   int    _pvTfIdx = AptFindTfIndex(tf);
   if(_pvTfIdx >= 0)
     {
      rv1 = g_rv1ValCache[_pvTfIdx];
      if(g_aptRv2AllOk[_pvTfIdx])
         rv2 = g_aptRv2All[_pvTfIdx];
     }
   bool rvUp = (rv1 > 0.0 && rv2 > 0.0 && rv1 >= rv2);
   bool rvDn = (rv1 > 0.0 && rv2 > 0.0 && rv1 <  rv2);

   // Bon cap bo dem giay tich luy cua chinh khung tf (g_aptBrkAccUp/Dn, UpA/DnA, UpB/DnB, UpC/DnC; danh chi so theo g_tfList, nhu rv1/rv2).
   // Chi so khong hop le (_pvTfIdx < 0) -> tam gia tri giu 0 (rvUp/rvDn cung false) nen roi vao nhanh Aqua.
   long _pvUp  = 0, _pvDn  = 0;
   long _pvUpA = 0, _pvDnA = 0;
   long _pvUpB = 0, _pvDnB = 0;
   long _pvUpC = 0, _pvDnC = 0;
   if(_pvTfIdx >= 0)
     {
      _pvUp  = g_aptBrkAccUp[_pvTfIdx];
      _pvDn  = g_aptBrkAccDn[_pvTfIdx];
      _pvUpA = g_aptBrkAccUpA[_pvTfIdx];
      _pvDnA = g_aptBrkAccDnA[_pvTfIdx];
      _pvUpB = g_aptBrkAccUpB[_pvTfIdx];
      _pvDnB = g_aptBrkAccDnB[_pvTfIdx];
      _pvUpC = g_aptBrkAccUpC[_pvTfIdx];
      _pvDnC = g_aptBrkAccDnC[_pvTfIdx];
     }

   // <RSI5> cua chinh khung tf: tach tu chuoi AptS1RsiTextForTF() ("<TenMuc> <RSI5>/<do lech>", phan truoc dau "/", sau dau cach dau tien)
   //   de lam dieu kien phu cho bac Magenta/White. That bai -> _pvRsi5Ok = false -> hai bac do khong khop (roi xuong bac ke tiep).
   bool   _pvRsi5Ok = false;
   double _pvRsi5   = 0.0;
   string _pvS1Text = "-";
   if(AptS1RsiTextForTF(tf, _pvS1Text) && _pvS1Text != "-")
     {
      int _pvSpacePos = StringFind(_pvS1Text, " ");
      if(_pvSpacePos > 0)
        {
         string _pvBody     = StringSubstr(_pvS1Text, _pvSpacePos + 1);
         int    _pvSlashPos = StringFind(_pvBody, "/");
         if(_pvSlashPos > 0)
           {
            _pvRsi5   = StringToDouble(StringSubstr(_pvBody, 0, _pvSlashPos));
            _pvRsi5Ok = true;
           }
        }
     }

   if(barIdx>=0)
     {
      double prevHighTf = iHigh(_Symbol,tf,barIdx+1);
      double prevLowTf  = iLow (_Symbol,tf,barIdx+1);
      double rangeDenom = prevHighTf - prevLowTf;
      if(rangeDenom>0.0)
        {
         double curCloseTf = iClose(_Symbol,tf,barIdx);
         if(curCloseTf<=0.0)
            curCloseTf = iClose(_Symbol,_Period,0);
         double rangeVal = (curCloseTf - prevLowTf)/rangeDenom;
         int    rangeInt = (int)MathRound(rangeVal*100);
         double brkVal   = (double)rangeInt;

         // Magenta them dieu kien RSI5 >= 50; White them dieu kien RSI5 < 50; cac bac con lai khong xet RSI5.
         if(rvUp && _pvUpB>0 && _pvDnB==0 && _pvUpC>0 && _pvDnC==0 && _pvUpA>0 && _pvDnA==0 && _pvUp>0 && _pvDn==0 && brkVal > 110.0 && _pvRsi5Ok && _pvRsi5 >= 50.0)
            clr = clrMagenta;
         else if(rvUp && _pvUpB>0 && _pvDnB==0 && _pvUpC>0 && _pvDnC==0 && _pvUpA>0 && _pvDnA==0 && _pvUp>0 && _pvDn==0)
            clr = clrOrange;
         else if(rvUp && _pvUpB>0 && _pvDnB==0 && _pvUpC>0 && _pvDnC==0 && _pvUpA>0 && _pvDnA==0)
            clr = clrGold;
         else if(rvUp && _pvUpB>0 && _pvDnB==0 && _pvUpC>0 && _pvDnC==0)
            clr = clrYellow;
         else if(rvUp && _pvUpB>0 && _pvDnB==0)
            clr = clrLime;
         else if(rvDn && _pvUpB==0 && _pvDnB>0 && _pvUpC==0 && _pvDnC>0 && _pvUpA==0 && _pvDnA>0 && _pvUp==0 && _pvDn>0 && brkVal < -10.0 && _pvRsi5Ok && _pvRsi5 < 50.0)
            clr = clrWhite;
         else if(rvDn && _pvUpB==0 && _pvDnB>0 && _pvUpC==0 && _pvDnC>0 && _pvUpA==0 && _pvDnA>0 && _pvUp==0 && _pvDn>0)
            clr = clrLightGray;
         else if(rvDn && _pvUpB==0 && _pvDnB>0 && _pvUpC==0 && _pvDnC>0 && _pvUpA==0 && _pvDnA>0)
            clr = clrSilver;
         else if(rvDn && _pvUpB==0 && _pvDnB>0 && _pvUpC==0 && _pvDnC>0)
            clr = clrLightSteelBlue;
         else if(rvDn && _pvUpB==0 && _pvDnB>0)
            clr = clrLightBlue;
         else
            clr = clrAqua;
        }
     }
   return clr;
}

//+------------------------------------------------------------------+
//| AptRv2RowColor: mau nhan RV1 / RV2 cua khung tf (thay AptPivotRowColor cho hai nhan nay; nhan Pivot / cot Pattern van dung AptPivotRowColor). |
//|  Gia tri (moi gia tri co g_apt*Ok[]; thieu -> dieu kien dung gia tri do khong thoa, roi xuong bac ke tiep):                                |
//|   bo = (Bid-Open)/spread (g_aptBoValV), bd = bodiff (g_aptBoDiffV), kd = brkddiff (g_aptBrkDDiffV), brkD (g_aptBrkDV),                      |
//|   <TenMuc> = AptWoodieDisplayLvlForTF(): 1..9 = R1..R9, 10..18 = S1..S9 (PP = 0 khong thuoc ca hai tap).                                  |
//|  TANG : Magenta bo>1,bd>0.1,kd>1,brkD>=80,R1..R9 > Orange bo>1,bd>0.1,kd>1,brkD>=80 > Gold bo>1,bd>0.1,kd>1 > Yellow bo>1,bd>0.1 > Lime bo>1. |
//|  GIAM : White bo<-1,bd<-0.1,kd<-1,brkD<=20,S1..S9 > LightGray (bo,bd,kd,brkD) > Silver (bo,bd,kd) > LightSteelBlue (bo,bd) > LightBlue bo<-1. |
//|  Con lai -> Aqua. Chi doc cache, khong tao/sua/xoa object.                                                                                |
//+------------------------------------------------------------------+
color AptRv2RowColor(const ENUM_TIMEFRAMES tf)
{
   int idx = AptFindTfIndex(tf);
   if(idx < 0 || idx >= 14)
      return clrAqua;
   bool boOk = g_aptBoValOk[idx];
   bool bdOk = g_aptBoDiffOk[idx];
   bool kdOk = g_aptBrkDDiffOk[idx];
   bool bkOk = g_aptBrkDOk[idx];
   double bo = g_aptBoValV[idx];
   double bd = g_aptBoDiffV[idx];
   double kd = g_aptBrkDDiffV[idx];
   double bk = g_aptBrkDV[idx];
   int    lvl = -1;
   bool   lvlOk = (AptWoodieDisplayLvlForTF(tf, lvl) && lvl >= 0);
   bool   isR = (lvlOk && lvl >= 1 && lvl <= 9);
   bool   isS = (lvlOk && lvl >= 10 && lvl <= 18);

   if(boOk && bo > 1.0)
     {
      bool c2 = (bdOk && bd > 0.1);
      bool c3 = (c2 && kdOk && kd > 1.0);
      bool c4 = (c3 && bkOk && bk >= 80.0);
      if(c4 && isR) return clrMagenta;
      if(c4)        return clrOrange;
      if(c3)        return clrGold;
      if(c2)        return clrYellow;
      return clrLime;
     }
   if(boOk && bo < -1.0)
     {
      bool c2 = (bdOk && bd < -0.1);
      bool c3 = (c2 && kdOk && kd < -1.0);
      bool c4 = (c3 && bkOk && bk <= 20.0);
      if(c4 && isS) return clrWhite;
      if(c4)        return clrLightGray;
      if(c3)        return clrSilver;
      if(c2)        return clrLightSteelBlue;
      return clrLightBlue;
     }
   return clrAqua;
}

//+------------------------------------------------------------------+
//| Khai bao truoc BarChartMidTime (than ham o duoi, canh DrawBarChart); S1LblFutureBarsFromEnd can goi. |
//+------------------------------------------------------------------+
datetime BarChartMidTime(const int s, const datetime barOpen, const long secPerBar);

//+------------------------------------------------------------------+
//| Khai bao truoc LblDpiScale (than ham o duoi, canh LblTextWidthPx / LblColMeasure); S1LblFutureBarsFromEnd can goi de quy doi khe ho InpLblAutoPadPx theo DPI. |
//+------------------------------------------------------------------+
double LblDpiScale();

// Khai bao truoc LblRowGapPx() (than ham o duoi, canh LblDpiScale); DrawWoodiePivotEma/PivotLabelsRelayout/DrawRv2RsiLabels can goi de lay khoang cach hang (pixel) theo co chu that + DPI.
int    LblRowGapPx(const int fs);

//+------------------------------------------------------------------+
//| S1LblFutureBarsFromEnd: tra ve so NEN CUA CHART (_Period) can dich sang PHAI ke tu moc tEnd de roi vao MEP PHAI cua THAN NEN LON dang chay. |
//|   DrawEmaSeries dat nhan tai tLbl = tEnd + lblFutureBars * PeriodSeconds(_Period); tEnd cua tung khung khac nhau (max(tmP[0], iTime(_Period,0)))  |
//|   nen ham nhan tEnd lam tham so, de moi khung deu roi dung mot moc (mot truc thoi gian).                                                       |
//|   MEP PHAI than nen lon (cung cach DrawBarChart / BarChartMoveCurBar):                                                                         |
//|       tMid   = BarChartMidTime(0, rt[0].time, secPerBar)                                                                                      |
//|       tickLen= do dai vach Open/Close (theo InpBarTickFixedLen / InpBarTickChartBars / InpBarTickRefTF / InpBarBodyWidthPct)                    |
//|       tRight = tMid + tickLen        <- mep phai vach Close                                                                                    |
//|   Khung ve than nen lay theo bang nut (g_barTF).                                                                                               |
//|   Tra ve -1 khi KHONG tinh duoc (tat InpShowBarChart, doc rates that bai, PeriodSeconds <= 0...) -> noi goi dung cach tinh du phong.             |
//|   Ham chi tinh mot con so: khong tao object.                                                                                                  |
//+------------------------------------------------------------------+
int S1LblFutureBarsFromEnd(const datetime tEnd)
{
   if(!InpShowBarChart) return(-1);
   if(tEnd <= 0)        return(-1);

   long secChart = PeriodSeconds(_Period);
   if(secChart <= 0) return(-1);

   ENUM_TIMEFRAMES _s1Tf = InpBarChartTF;
   if(g_barTF != InpBarChartTF) _s1Tf = g_barTF;

   long secPerBar = PeriodSeconds(_s1Tf);
   if(secPerBar <= 0) return(-1);

   MqlRates _s1Rt[];
   ArraySetAsSeries(_s1Rt, true);
   if(CopyRates(_Symbol, _s1Tf, 0, 1, _s1Rt) < 1) return(-1);

   double   _s1BodyFrac = MathMax(5, MathMin(95, InpBarBodyWidthPct)) / 100.0;
   datetime _s1TickLen  = (datetime)((secPerBar * _s1BodyFrac) / 2.0);
   if(InpBarTickFixedLen)
   {
      if(InpBarTickChartBars > 0)
      {
         _s1TickLen = (datetime)((long)InpBarTickChartBars * secChart);
      }
      else
      {
         long _s1SecTickRef = PeriodSeconds(InpBarTickRefTF);
         if(_s1SecTickRef > 0) _s1TickLen = (datetime)((_s1SecTickRef * _s1BodyFrac) / 2.0);
      }
   }
   if(_s1TickLen < 1) _s1TickLen = 1;

   datetime _s1Mid   = BarChartMidTime(0, _s1Rt[0].time, secPerBar);
   datetime _s1Right = _s1Mid + _s1TickLen;

   long _s1Delta = (long)_s1Right - (long)tEnd;
   if(_s1Delta < 0) _s1Delta = 0;

   //--- lam tron LEN de nhan luon nam BEN PHAI mep, khong de len than nen
   int _s1N = (int)((_s1Delta + secChart - 1) / secChart);

   if(InpLblAutoFitCols)
   {
      long _s1WPx = ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
      long _s1VBr = ChartGetInteger(0, CHART_VISIBLE_BARS);
      if(_s1WPx > 0 && _s1VBr > 0)
      {
         double _s1BarPx = (double)_s1WPx / (double)_s1VBr;
         if(_s1BarPx > 0.0)
         {
            int _s1Pad = (InpLblAutoPadPx < 0) ? 0 : InpLblAutoPadPx;
            _s1Pad = (int)MathCeil((double)_s1Pad * LblDpiScale());
            int _s1PadBars = (int)MathCeil((double)_s1Pad / _s1BarPx);
            if(_s1PadBars < 1) _s1PadBars = 1;
            _s1N += _s1PadBars;
         }
      }
   }

   if(_s1N < 0)   _s1N = 0;
   if(_s1N > 500) _s1N = 500;   // tran an toan
   return(_s1N);
}

//+------------------------------------------------------------------+
//| PivotLabelsRelayout: dan lai vi tri DOC cua cac nhan Pivot de khong chong len nhau (khoi "UU TIEN VI TRI NHAN PIVOT THEO THU TU KHUNG" tach ra khoi |
//|   DrawWoodiePivotEma()); goi lai o OnTimer va khi doi thang gia (CHARTEVENT_CHART_CHANGE). Chi ObjectMove nhan Pivot da co: khong tao/xoa object, |
//|   khong doi chuoi/mau/co chu/ANCHOR.                                                                                         |
//+------------------------------------------------------------------+
void PivotLabelsRelayout()
{
      int      _pvOvN = 0;
      string   _pvOvName [RV2_TF_COUNT];
      double   _pvOvPrice[RV2_TF_COUNT];
      datetime _pvOvTime [RV2_TF_COUNT];
      int      _pvOvIsM1 [RV2_TF_COUNT];

      for(int _po = 0; _po < RV2_TF_COUNT; _po++)
      {
         string _poName = WoodieLevelLblPrefix(g_pivotLvlUsedIdx[_po]) + g_tfName[_po];
         if(ObjectFind(0, _poName) < 0) continue;
         _pvOvName [_pvOvN] = _poName;
         double _pvTrueP = 0.0;
         int    _pvTrueI = AptFindTfIndex(g_rvTfList[_po]);
         if(_pvTrueI >= 0 && _pvTrueI < 14)
            _pvTrueP = g_pivotLvlValCache[_pvTrueI];
         _pvOvPrice[_pvOvN] = (_pvTrueP > 0.0) ? _pvTrueP : ObjectGetDouble (0, _poName, OBJPROP_PRICE);
         _pvOvTime [_pvOvN] = (datetime)ObjectGetInteger(0, _poName, OBJPROP_TIME);
         _pvOvIsM1 [_pvOvN] = (g_rvTfList[_po] == PERIOD_M1) ? 1 : 0;
         _pvOvN++;
      }

      if(_pvOvN > 1)
      {
         double _pMinPv = 0.0, _pMaxPv = 0.0;
         long   _hcPxPv = 0;
         ChartGetDouble (0, CHART_PRICE_MIN,        0, _pMinPv);
         ChartGetDouble (0, CHART_PRICE_MAX,        0, _pMaxPv);
         ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS,  0, _hcPxPv);
         double _pxPrPv = (_hcPxPv > 0 && _pMaxPv > _pMinPv)
                           ? (_pMaxPv - _pMinPv) / (double)_hcPxPv : _Point;
         if(_pxPrPv <= 0.0) _pxPrPv = _Point;
         double _pvGap = (double)LblRowGapPx(8) * _pxPrPv;
         if(_pvGap <= 0.0) _pvGap = _Point;

         double _pvSettled[RV2_TF_COUNT];
         int    _pvSettledN = 0;

         for(int _i = 0; _i < _pvOvN; _i++)
         {
            double _pvPlaced = _pvOvPrice[_i];   // mac dinh: dung DUNG vi tri gia that

            if(_pvOvIsM1[_i] != 1)
            {
               for(int _guard = 0; _guard < _pvOvN; _guard++)
               {
                  bool _hit = false;
                  for(int _k = 0; _k < _pvSettledN; _k++)
                  {
                     if(MathAbs(_pvPlaced - _pvSettled[_k]) < _pvGap)
                     {
                        int    _dirVsK = (_pvOvPrice[_i] >= _pvOvPrice[_k]) ? +1 : -1;
                        double _cand   = _pvSettled[_k] + (double)_dirVsK * _pvGap;
                        if((_dirVsK > 0 && _cand > _pvPlaced) ||
                           (_dirVsK < 0 && _cand < _pvPlaced))
                        {
                           _pvPlaced = _cand;
                           _hit = true;
                        }
                     }
                  }
                  if(!_hit) break;
               }
            }
            // M1 (_pvOvIsM1[_i] == 1): giu nguyen _pvPlaced = gia that,
            //   khong bao gio bi day - dung y "uu tien vi tri nhan Pivot
            //   cua khung 1m".

            if(_pvPlaced != _pvOvPrice[_i])
               ObjectMove(0, _pvOvName[_i], 0, _pvOvTime[_i], _pvPlaced);

            _pvSettled[_pvSettledN++] = _pvPlaced;
         }
      }
}

//+------------------------------------------------------------------+
//| S1LblTimeAtBarRight: moc thoi gian neo cot nhan Pivot = truc (tam) than nen lon (BarChartMidTime(0, ...)) cong khe ho chuan |
//|   InpLblAutoPadPx (quy ra giay, khi InpLblAutoFitCols), de bon cot nhan co khe ho deu nhau.                                  |
//|   Tra ve 0 khi khong tinh duoc -> noi goi dung nhanh du phong S1LblFutureBarsFromEnd (mep phai vach Close).                   |
//+------------------------------------------------------------------+
datetime S1LblTimeAtBarRight()
{
   if(!InpShowBarChart) return(0);

   long secChart = PeriodSeconds(_Period);
   if(secChart <= 0) return(0);

   ENUM_TIMEFRAMES _saTf = InpBarChartTF;
   if(g_barTF != InpBarChartTF) _saTf = g_barTF;

   long secPerBar = PeriodSeconds(_saTf);
   if(secPerBar <= 0) return(0);

   MqlRates _saRt[];
   ArraySetAsSeries(_saRt, true);
   if(CopyRates(_Symbol, _saTf, 0, 1, _saRt) < 1) return(0);

   // Neo cot nhan Pivot vao truc thoi gian (tam) cua than nen lon, khong neo sau mep phai vach Close (vach Close dai InpBarTickChartBars nen cua chart
   //   se day cot Pivot ra xa khi chart phong to). Truc than nen = BarChartMidTime(0, ...) - cung ham DrawBarChart va BarChartMoveCurBar dung.
   datetime _saMid   = BarChartMidTime(0, _saRt[0].time, secPerBar);
   datetime _saRight = _saMid;

   //--- khe ho chuan giua hai cot, quy tu PIXEL ra GIAY
   if(InpLblAutoFitCols)
   {
      long _saWPx = ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
      long _saVBr = ChartGetInteger(0, CHART_VISIBLE_BARS);
      if(_saWPx > 0 && _saVBr > 0)
      {
         double _saBarPx = (double)_saWPx / (double)_saVBr;
         if(_saBarPx > 0.0)
         {
            int _saPad = (InpLblAutoPadPx < 0) ? 0 : InpLblAutoPadPx;
            _saPad = (int)MathCeil((double)_saPad * LblDpiScale());
            long _saPadSec = (long)MathCeil((double)_saPad / _saBarPx * (double)secChart);
            if(_saPadSec < 1) _saPadSec = 1;
            _saRight = _saRight + (datetime)_saPadSec;
         }
      }
   }

   return(_saRight);
}

void DrawWoodiePivotEma()
{
   SSpmScopeTimer __spmTimer("DrawWoodiePivotEma");

   for(int _pvI = 0; _pvI < RV2_TF_COUNT; _pvI++)
      g_pivotLblBaseText[_pvI] = "";
   for(int _pvJ = 0; _pvJ < 14; _pvJ++)
     {
      g_pivotLvlValCache[_pvJ] = 0.0;
      g_pivotEmaDiffStr[_pvJ]  = "";
      g_pivotEmaDiff2Str[_pvJ] = "";
     }
   for(int _pvK = 0; _pvK < RV2_TF_COUNT; _pvK++)
      g_pivotLvlUsedIdx[_pvK] = g_pivotLevelIdx;

   if(!InpShowWoodiePivotEma)
      return;

   for(int i = 0; i < RV2_TF_COUNT; i++)
   {
      ENUM_TIMEFRAMES tf = g_rvTfList[i];


      int need = InpHistPoints + 1;   // +1 vi moi diem i can bar lien truoc (i+1)
      double   hi[], lo[], cl[];
      datetime tmP[];
      ArraySetAsSeries(hi,  true);
      ArraySetAsSeries(lo,  true);
      ArraySetAsSeries(cl,  true);
      ArraySetAsSeries(tmP, true);

      int cpH = CopyHigh (_Symbol, tf, 0, need, hi);
      int cpL = CopyLow  (_Symbol, tf, 0, need, lo);
      int cpC = CopyClose(_Symbol, tf, 0, need, cl);
      int cpT = CopyTime (_Symbol, tf, 0, need, tmP);
      int got = MathMin(MathMin(cpH, cpL), MathMin(cpC, cpT));
      if(got < 2) continue;

      int points = got - 1;   // so diem Pivot tinh duoc (moi diem dung bar[i] va bar[i+1])
      if(points > InpHistPoints) points = InpHistPoints;
      if(points < 1) continue;

      int _pvLvlForTf = g_pivotLevelIdx;
      int  _pvDispLvl = -1;
      bool _pvDispOk  = AptWoodieDisplayLvlForTF(tf, _pvDispLvl);
      if(!g_pivotFollowDisplayedLvl)
      {
         if(_pvDispOk)
            _pvLvlForTf = _pvDispLvl;
      }

      double s1Arr[];
      ArrayResize(s1Arr, points);
      for(int s = 0; s < points; s++)
      {
         double hB = (s == 0) ? hi[0] : hi[s + 1];
         double lB = (s == 0) ? lo[0] : lo[s + 1];
         double cB = (s == 0) ? cl[0] : cl[s + 1];
         s1Arr[s] = WoodieLevelValue(_pvLvlForTf, hB, lB, cB);
      }

      int step = MathMax(1, points / InpMaxSegments);

      ENUM_TIMEFRAMES _xTf   = PERIOD_CURRENT;
      bool            _xTfOk = AptExtraLineTf(_xTf);
      bool            _isXTf = (_xTfOk && tf == _xTf);
      bool s1DrawLine = true;
      if(InpS1LineM1Only && !_isXTf)
         s1DrawLine = false;

      int s1LblFuture = PIVOT_M1_LBL_FUTURE_BARS;
      if(PeriodSeconds(tf) > PeriodSeconds(PERIOD_M1))
         s1LblFuture = InpS1LabelFutureBars + PIVOT_M1_LBL_FUTURE_BARS;

      datetime _s1EndTf = tmP[0];
      datetime _s1NowCh = iTime(_Symbol, _Period, 0);
      if(_s1NowCh > _s1EndTf) _s1EndTf = _s1NowCh;
      int _s1AtRight = S1LblFutureBarsFromEnd(_s1EndTf);
      if(_s1AtRight >= 0) s1LblFuture = _s1AtRight;

      datetime _s1TimeAbs = S1LblTimeAtBarRight();

      string lvlPfx = WoodieLevelLinePrefix(_pvLvlForTf);
      string lvlLbl = WoodieLevelLblPrefix(_pvLvlForTf);
      color  lvlClr = WoodieLevelColor(_pvLvlForTf);
      g_pivotLvlUsedIdx[i] = _pvLvlForTf;
      color lvlLblClr = AptPivotRowColor(tf);
      int _pvLineWidth = 1;
      ENUM_LINE_STYLE _pvLineStyle = _isXTf ? STYLE_DASH : STYLE_DOT;
      DrawEmaSeries(i, lvlPfx + g_tfName[i] + "_", lvlClr, s1Arr, points, tmP, step,
                    lvlLbl + g_tfName[i], g_tfName[i],
                    s1DrawLine, s1LblFuture, _s1TimeAbs, lvlLblClr, _pvLineWidth, _pvLineStyle);

      string _pvLblName = lvlLbl + g_tfName[i];
      if(ObjectFind(0, _pvLblName) >= 0)
        {
         g_pivotLblBaseText[i] = ObjectGetString(0, _pvLblName, OBJPROP_TEXT);
         int _pvValIdx = AptFindTfIndex(tf);
         if(_pvValIdx >= 0)
           {
            g_pivotLvlValCache[_pvValIdx] = ObjectGetDouble(0, _pvLblName, OBJPROP_PRICE);
            double _pvdSp = (double)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * _Point;
            g_pivotEmaDiffStr[_pvValIdx] = (g_dsEmaOk && _pvdSp > 0.0)
                                           ? DoubleToString((g_dsEma0 - g_dsEma1) / _pvdSp, M1_ELP_LBL_DIF1_DIGITS) : "-";
           }
         if(i == 0)
            g_pivotM1LblTime = (datetime)ObjectGetInteger(0, _pvLblName, OBJPROP_TIME);

         // Khung bi bo tick o bang check box: chi go CHU NHAN Pivot (cache gia / diff / chuoi goc o tren da ghi xong; duong EMA giu nguyen).
         if(!g_tfRowShow[i])
            ObjectDelete(0, _pvLblName);
        }

      {
         int _pd2Idx = AptFindTfIndex(tf);
         if(_pd2Idx >= 0 && _pd2Idx < 14)
           {
            double _pd2Sp   = (double)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * _Point;
            string _pd2Str  = "-";
            if(_pvDispOk && _pd2Sp > 0.0)
              {
               double _pd2E0 = 0.0, _pd2E1 = 0.0;
               bool   _pd2Ok = false;
               if(_pvDispLvl == _pvLvlForTf)
                 {
                  if(g_dsEmaOk)
                    {
                     _pd2E0 = g_dsEma0;
                     _pd2E1 = g_dsEma1;
                     _pd2Ok = true;
                    }
                 }
               else
                 {
                  if(points >= 2)
                    {
                     int    _pd2P = MathMax(1, InpWoodiePivotEmaPeriod);
                     double _pd2A = 2.0 / (_pd2P + 1.0);
                     double _pd2E = 0.0;
                     bool   _pd2Seeded = false;
                     double _pd2Ema0 = 0.0, _pd2Ema1 = 0.0;
                     for(int _pd2S = points - 1; _pd2S >= 0; _pd2S--)
                       {
                        double _pd2H = (_pd2S == 0) ? hi[0] : hi[_pd2S + 1];
                        double _pd2L = (_pd2S == 0) ? lo[0] : lo[_pd2S + 1];
                        double _pd2C = (_pd2S == 0) ? cl[0] : cl[_pd2S + 1];
                        double _pd2V = WoodieLevelValue(_pvDispLvl, _pd2H, _pd2L, _pd2C);
                        if(!_pd2Seeded)
                          {
                           _pd2E = _pd2V;
                           _pd2Seeded = true;
                          }
                        else
                           _pd2E = _pd2A * _pd2V + (1.0 - _pd2A) * _pd2E;
                        if(_pd2S == 1) _pd2Ema1 = _pd2E;
                        if(_pd2S == 0) _pd2Ema0 = _pd2E;
                       }
                     if(_pd2Ema0 > 0.0 && _pd2Ema1 > 0.0)
                       {
                        _pd2E0 = _pd2Ema0;
                        _pd2E1 = _pd2Ema1;
                        _pd2Ok = true;
                       }
                    }
                 }
               if(_pd2Ok)
                  _pd2Str = DoubleToString((_pd2E0 - _pd2E1) / _pd2Sp, M1_ELP_LBL_DIF1_DIGITS);
              }
            g_pivotEmaDiff2Str[_pd2Idx] = _pd2Str;
           }
      }
   }

   // =================================================================
   PivotLabelsRelayout();

   // =================================================================
}

//+------------------------------------------------------------------+
//| Ba ham duoi day duoc copy y het tu MiniBarChart.mq5 de tinh:      |
//|   - % bien do cua 1 nen (MbcBarRangePctAtShift)                   |
//|   - moc bat dau cua so thong ke theo do lon khung                 |
//|     (MbcRangeStatWinStart)                                        |
//|   - Dmax/Dmin trong cua so do, co cache theo tung khung           |
//|     (MbcRangeStatCurrent)                                         |
//| Logic giong ban trong MiniBarChart.mq5.                            |
//+------------------------------------------------------------------+
#define MBC_RG_SCAN_CAP 3000
//+------------------------------------------------------------------+
//| MbcBarRangePctAtShift: % bien do cua MOT nen: pct = (High - Low)/Close*100, DUONG khi |
//|   nen TANG (Close >= Open), AM khi nen GIAM (Close < Open).       |

//+------------------------------------------------------------------+
bool MbcBarRangePctAtShift(ENUM_TIMEFRAMES tf, int shift, double &outPct)
{
   outPct = 0.0;
   if(shift < 0) return false;
   double _bpO = iOpen (_Symbol, tf, shift);
   double _bpH = iHigh (_Symbol, tf, shift);
   double _bpL = iLow  (_Symbol, tf, shift);
   double _bpC = iClose(_Symbol, tf, shift);
   if(_bpO <= 0.0 || _bpH <= 0.0 || _bpL <= 0.0 || _bpC <= 0.0) return false;
   if(_bpH < _bpL) return false;
   double _bpPct = ((_bpH - _bpL) / _bpC) * 100.0;
   if(_bpC < _bpO) _bpPct = -_bpPct;
   outPct = _bpPct;
   return true;
}
//+------------------------------------------------------------------+
//|   Moc bat dau CUA SO THONG KE theo do lon khung:                  |
//|     tf <= H4   -> tu 00:00 HOM NAY                                |
//|     tf <= H12  -> tu dau TUAN                                     |
//|     tf <= D1   -> tu dau THANG                                    |
//|     W1 / MN1   -> KHONG co cua so -> tra false (noi goi in "-").  |
//+------------------------------------------------------------------+
bool MbcRangeStatWinStart(ENUM_TIMEFRAMES tf, datetime &outStart)
{
   outStart = 0;
   int _rgSec = PeriodSeconds(tf);
   if(_rgSec <= 0) return false;
   datetime _rgNow = TimeCurrent();
   if(_rgNow <= 0) return false;
   MqlDateTime _rgSt;
   if(!TimeToStruct(_rgNow, _rgSt)) return false;
   int _rgDow = _rgSt.day_of_week;
   if(_rgDow < 0) _rgDow = 0;
   if(_rgDow > 6) _rgDow = 6;
   _rgSt.hour = 0;
   _rgSt.min  = 0;
   _rgSt.sec  = 0;
   datetime _rgDay0 = StructToTime(_rgSt);
   if(_rgDay0 <= 0) return false;
   if(_rgSec <= PeriodSeconds(PERIOD_H4))
   {
      outStart = _rgDay0;
      return true;
   }
   if(_rgSec <= PeriodSeconds(PERIOD_H12))
   {
      outStart = _rgDay0 - (datetime)((long)_rgDow * 86400);
      return true;
   }
   if(_rgSec <= PeriodSeconds(PERIOD_D1))
   {
      _rgSt.day = 1;
      datetime _rgMon0 = StructToTime(_rgSt);
      if(_rgMon0 <= 0) return false;
      outStart = _rgMon0;
      return true;
   }
   return false;
}
//+------------------------------------------------------------------+
//| PivRangeStatCurrent (port tu NewCandle.mq5)                       |
//|   outMaxUp = pct LON NHAT trong nhom nen TANG  (hasUp = tim thay) |
//|   outMaxDn = pct AM SAU NHAT trong nhom nen GIAM (hasDn = tim thay)|
//|                                                                   |
//|  [CACHE] Cac nen DA DONG (shift >= 1) chi quet MOT LAN roi giu     |
//|  trong bo dem theo TUNG khung; moi nhip ve sau do chi quet cac nen |
//|  vua dong them. Nen dang hinh thanh (shift 0) duoc gop vao BAN SAO |
//|  cuc tri o buoc cuoi nen van doi theo tung tick ma khong lam hong  |
//|  cache. Sang ngay / tuan / thang moi -> moc cua so doi -> reset    |
//|  cache, quet lai tu dau. Bo dem tra cuu theo (int)tf.              |
//|                                                                   |
//|  Tra ve false khi khung KHONG co cua so thong ke (W1 / MN1).       |
//|  Ham chi doc gia, khong tao object / buffer nao.                   |
//+------------------------------------------------------------------+
bool MbcRangeStatCurrent(ENUM_TIMEFRAMES tf, bool &hasUp, double &outMaxUp,
                         bool &hasDn, double &outMaxDn)
{
   static int      s_rgKey[32];
   static datetime s_rgWinStart[32];
   static datetime s_rgDoneT[32];
   static double   s_rgMaxUp[32];
   static double   s_rgMaxDn[32];
   static bool     s_rgHasUp[32];
   static bool     s_rgHasDn[32];
   static int      s_rgCnt = 0;

   hasUp    = false;
   hasDn    = false;
   outMaxUp = 0.0;
   outMaxDn = 0.0;

   datetime _rgWs = 0;
   if(!MbcRangeStatWinStart(tf, _rgWs)) return false;
   if(_rgWs <= 0) return false;

   // --- tim (hoac cap phat) o nho cho khung tf ---
   int _rgSlot = -1;
   for(int _rgk = 0; _rgk < s_rgCnt; _rgk++)
      if(s_rgKey[_rgk] == (int)tf) { _rgSlot = _rgk; break; }
   if(_rgSlot < 0 && s_rgCnt < 32)
   {
      _rgSlot = s_rgCnt;
      s_rgKey[s_rgCnt]      = (int)tf;
      s_rgWinStart[s_rgCnt] = 0;
      s_rgDoneT[s_rgCnt]    = 0;
      s_rgMaxUp[s_rgCnt]    = 0.0;
      s_rgMaxDn[s_rgCnt]    = 0.0;
      s_rgHasUp[s_rgCnt]    = false;
      s_rgHasDn[s_rgCnt]    = false;
      s_rgCnt++;
   }
   if(_rgSlot < 0) return false;   // het o nho (khong the xay ra voi 13 khung)

   if(s_rgWinStart[_rgSlot] != _rgWs)
   {
      s_rgWinStart[_rgSlot] = _rgWs;
      s_rgDoneT[_rgSlot]    = 0;
      s_rgMaxUp[_rgSlot]    = 0.0;
      s_rgMaxDn[_rgSlot]    = 0.0;
      s_rgHasUp[_rgSlot]    = false;
      s_rgHasDn[_rgSlot]    = false;
   }

   datetime _rgDone    = s_rgDoneT[_rgSlot];
   datetime _rgNewDone = _rgDone;
   for(int _rgSh = 1; _rgSh <= MBC_RG_SCAN_CAP; _rgSh++)
   {
      datetime _rgBt = iTime(_Symbol, tf, _rgSh);
      if(_rgBt <= 0) break;
      if(_rgBt < _rgWs) break;
      if(_rgBt <= _rgDone) break;
      double _rgPc = 0.0;
      if(MbcBarRangePctAtShift(tf, _rgSh, _rgPc))
      {
         if(_rgPc >= 0.0)
         {
            if(!s_rgHasUp[_rgSlot] || _rgPc > s_rgMaxUp[_rgSlot])
            {
               s_rgMaxUp[_rgSlot] = _rgPc;
               s_rgHasUp[_rgSlot] = true;
            }
         }
         else
         {
            if(!s_rgHasDn[_rgSlot] || _rgPc < s_rgMaxDn[_rgSlot])
            {
               s_rgMaxDn[_rgSlot] = _rgPc;
               s_rgHasDn[_rgSlot] = true;
            }
         }
      }
      if(_rgBt > _rgNewDone) _rgNewDone = _rgBt;
   }
   s_rgDoneT[_rgSlot] = _rgNewDone;

   bool   _rgHu = s_rgHasUp[_rgSlot];
   bool   _rgHd = s_rgHasDn[_rgSlot];
   double _rgMu = s_rgMaxUp[_rgSlot];
   double _rgMd = s_rgMaxDn[_rgSlot];
   datetime _rgBt0 = iTime(_Symbol, tf, 0);
   if(_rgBt0 > 0 && _rgBt0 >= _rgWs)
   {
      double _rgPc0 = 0.0;
      if(MbcBarRangePctAtShift(tf, 0, _rgPc0))
      {
         if(_rgPc0 >= 0.0)
         {
            if(!_rgHu || _rgPc0 > _rgMu)
            {
               _rgMu = _rgPc0;
               _rgHu = true;
            }
         }
         else
         {
            if(!_rgHd || _rgPc0 < _rgMd)
            {
               _rgMd = _rgPc0;
               _rgHd = true;
            }
         }
      }
   }
   hasUp    = _rgHu;
   hasDn    = _rgHd;
   outMaxUp = _rgHu ? _rgMu : 0.0;
   outMaxDn = _rgHd ? _rgMd : 0.0;
   return true;
}
//+------------------------------------------------------------------+
//| Đổi số giây đã trôi qua thành chuỗi ngắn gọn: |
//|   < 1 giờ   -> "mm:ss"                                            |
//|   < 1 ngày  -> "hh:mm:ss"                                         |
//|   >= 1 ngày -> "Nd hh:mm"   (dùng cho khung D1/W1/MN1)            |
//+------------------------------------------------------------------+
string ElapsedToStr(long secs)
{
   if(secs < 0) secs = 0;
   long d = secs / 86400;
   long h = (secs % 86400) / 3600;
   long m = (secs % 3600) / 60;
   long s = secs % 60;
   if(d > 0) return StringFormat("%dd %02d:%02d", (int)d, (int)h, (int)m);
   if(h > 0) return StringFormat("%02d:%02d:%02d", (int)h, (int)m, (int)s);
   return StringFormat("%02d:%02d", (int)m, (int)s);
}
//+------------------------------------------------------------------+
//| BarRemainSec: so giay CON LAI cho den khi nen hien tai |
//|   cua khung tf dong lai.                                          |
//|     tEnd = iTime(tf,0) + PeriodSeconds(tf); rieng MN1 lay dung     |
//|     moc 00:00 ngay 1 THANG KE TIEP (do dai thang khong co dinh).   |
//|     remain = tEnd - TimeCurrent().                                 |
//|   Tra false khi: khung khong hop le, chua co du lieu, hoac moc     |
//|   dong nen DA TROI QUA ma nen chua doi (vd phien nghi cuoi tuan    |
//|   voi D1/W1) - de tranh bao "0s" treo lien tuc.                   |
//|   Ham CHI DOC thoi gian: khong tao object, khong ve duong.         |
//+------------------------------------------------------------------+
bool BarRemainSec(ENUM_TIMEFRAMES tf, long &outRemain)
{
   outRemain = 0;
   long secTf = (long)PeriodSeconds(tf);
   if(secTf <= 0) return false;
   datetime t0 = iTime(_Symbol, tf, 0);
   if(t0 <= 0) return false;
   datetime tNow = TimeCurrent();
   if(tNow <= 0) return false;

   datetime tEnd = t0 + (datetime)secTf;
   if(tf == PERIOD_MN1)
   {
      MqlDateTime _cdSt;
      if(TimeToStruct(t0, _cdSt))
      {
         _cdSt.day  = 1;
         _cdSt.hour = 0;
         _cdSt.min  = 0;
         _cdSt.sec  = 0;
         _cdSt.mon  = _cdSt.mon + 1;
         if(_cdSt.mon > 12)
         {
            _cdSt.mon  = 1;
            _cdSt.year = _cdSt.year + 1;
         }
         datetime tNext = StructToTime(_cdSt);
         if(tNext > t0) tEnd = tNext;
      }
   }

   long rem = (long)(tEnd - tNow);
   if(rem <= 0)     return false;   // moc dong nen da qua (phien nghi) -> bo qua
   if(rem > secTf)  return false;   // du lieu le -> bo qua
   outRemain = rem;
   return true;
}
//+------------------------------------------------------------------+
//| BuildCountdownWarn: chuoi canh bao HET GIO. |
//|   Duyet g_cdTFList tu KHUNG LON NHAT (1MN) xuong 5M; khung nao co |
//|   remain < InpBarLblCdSec thi noi them "<TenTF>:<remain>s".       |
//|   Nhieu khung thoa -> noi cach nhau bang 1 dau cach, khung lon     |
//|   dung truoc; so muc toi da = InpBarLblCdMaxItems (0 = khong gioi  |
//|   han). Khong co khung nao thoa -> tra chuoi rong.                 |
//+------------------------------------------------------------------+
string BuildCountdownWarn()
{
   if(!InpBarLblShowCountdown) return("");

   long thr = (long)((InpBarLblCdSec <= 0) ? 60 : InpBarLblCdSec);
   int  lim = (InpBarLblCdMaxItems <= 0) ? RV2_CD_TF_COUNT : InpBarLblCdMaxItems;
   if(lim > RV2_CD_TF_COUNT) lim = RV2_CD_TF_COUNT;

   string res = "";
   int    n   = 0;
   for(int i = 0; i < RV2_CD_TF_COUNT; i++)
   {
      if(n >= lim) break;
      long rem = 0;
      if(!BarRemainSec(g_cdTFList[i], rem)) continue;
      if(rem >= thr) continue;
      string one = g_cdTFName[i] + ":" + IntegerToString((int)rem) + "s";
      res = (res == "") ? one : (res + " " + one);
      n++;
   }
   return(res);
}
//+------------------------------------------------------------------+
//| BarChartMidTime: moc thoi gian dat than nen Bar Chart. |
//|   - Nen DA DONG (s > 0): luon tra ve dung cong thuc goc            |
//|     time + secPerBar/2 (giua chu ky) - khong doi gi.               |
//|   - Nen HIEN TAI (s = 0): tra ve moc theo InpBarCurPosMode.        |
//|     Thieu du lieu -> tu dong roi ve cong thuc goc.                 |
//|   Dung CHUNG cho DrawBarChart va DrawBarChartLabels de than nen va |
//|   nhan luon dung mot moc.                                          |
//+------------------------------------------------------------------+
datetime BarChartMidTime(const int s, const datetime barOpen, const long secPerBar)
{
   datetime tOrig = barOpen + (datetime)(secPerBar / 2);
   if(s != 0) return(tOrig);

   datetime tShift  = 0;
   long     secChrt = PeriodSeconds(_Period);
   if(secChrt > 0 && BARCUR_FUTURE_BARS > 0)
      tShift = (datetime)((long)BARCUR_FUTURE_BARS * secChrt);

   if(InpBarCurPosMode == BARCUR_M1)
   {
      datetime tM1 = iTime(_Symbol, PERIOD_M1, 0);
      if(tM1 > 0) return(tM1 + tShift);
      return(tOrig + tShift);
   }
   if(InpBarCurPosMode == BARCUR_OPEN)
      return(barOpen + tShift);
   if(InpBarCurPosMode == BARCUR_TF)
   {
      datetime tTf = iTime(_Symbol, InpBarCurPosTF, 0);
      if(tTf > 0) return(tTf + tShift);
      return(tOrig + tShift);
   }
   return(tOrig + tShift);
}


//+------------------------------------------------------------------+
//| HANG 5..12 CUA NHAN DUOI THAN NEN LON: CAO NHAT / THAP NHAT cua TUAN, THANG, QUI, NAM, 2 / 3 / 4 / 5 NAM (moc lam tron ben ngoai dinh / day) + SO LAN CHAM quanh khu vuc do. |
//|   Format moi hang: "<ten> cao <gia> (<n> lan) thap <gia> (<m> lan)", vd "tuan cao 4155 (2 lan) thap 3955 (1 lan)" (ten: tuan / thang / qui / nam / 2..5 nam, co dau). |
//|   Cao nhat / thap nhat = High cao nhat / Low thap nhat cua cac nen H1 tu DAU ky den hien tai (gom nen dang chay); lam tron = moc lam tron BEN NGOAI (cao -> len, thap -> xuong) theo nut dang chon.   |
//|   Dau ky: tuan = iTime(W1,0); thang = ngay 1 cua thang hien tai; qui = ngay 1 cua thang dau qui (1/4/7/10); nam = 1/1; N nam = 1/1 cua nam (hien tai - (N-1)) (gio may chu, 00:00). |
//|   So lan cham: 1 LAN CHAM = 1 doan nen H1 LIEN TIEP co khoang [Low, High] giao voi khu vuc [lam tron - W, lam tron + W]; W = PHAM VI cua o nhap trong    |
//|   bang LAM TRON UI (g_aptRndRange, mac dinh 50). Cac nen lien tiep trong khu vuc chi tinh 1 lan; nen chua tung chua dinh/day luon duoc tinh >= 1 lan.     |
//|   Cache: tinh lai toi da 1 lan / giay hoac khi doi W; nen H1 (5 nam ~ 31000 nen) copy 1 lan / nen H1 moi, dung chung cho 8 ky (AptPeriodExtremeUpdate()). |
//+------------------------------------------------------------------+
// [GIU NGUYEN - KHONG XOA] #define APT_PEX_COUNT 4
// [GIU NGUYEN - KHONG XOA] string   g_pexTxt[APT_PEX_COUNT];            // chuoi 4 hang (0 = tuan, 1 = thang, 2 = qui, 3 = nam); rong = chua tinh
// [GIU NGUYEN - KHONG XOA] string   g_pexName[APT_PEX_COUNT] = {"tuần", "tháng", "quí", "năm"};   // ten ky (co dau)
#define APT_PEX_COUNT 8
#define APT_PEX_HIST_TOL 604800              // 7 ngay: nen H1 dau tien da copy tre hon dau ky qua muc nay -> thieu lich su, ky do in "-"
string   g_pexTxt[APT_PEX_COUNT];            // chuoi 8 hang (0 = tuan, 1 = thang, 2 = qui, 3 = nam, 4..7 = 2 / 3 / 4 / 5 nam); rong = chua tinh
string   g_pexName[APT_PEX_COUNT] = {"tuần", "tháng", "quí", "năm", "2 năm", "3 năm", "4 năm", "5 năm"};   // ten ky (co dau)
bool     g_pexOk [APT_PEX_COUNT];            // true = co du lieu (cac mang duoi day hop le)
double   g_pexHiR[APT_PEX_COUNT];            // gia CAO NHAT cua ky, moc lam tron ben ngoai (>= dinh)
double   g_pexLoR[APT_PEX_COUNT];            // gia THAP NHAT cua ky, moc lam tron ben ngoai (<= day)
int      g_pexNH [APT_PEX_COUNT];            // so lan cham quanh khu vuc gia cao nhat
int      g_pexNL [APT_PEX_COUNT];            // so lan cham quanh khu vuc gia thap nhat
datetime g_pexLastSec = 0;                   // giay (TimeLocal) cua lan tinh gan nhat
double   g_pexLastW   = -1.0;                // W cua lan tinh gan nhat

datetime AptPeriodStartTime(const int k)
  {
   if(k == 0)
      return(iTime(_Symbol, PERIOD_W1, 0));
   MqlDateTime d;
   TimeToStruct(TimeCurrent(), d);
   d.hour = 0;
   d.min  = 0;
   d.sec  = 0;
   d.day  = 1;
   if(k == 2)
      d.mon = ((d.mon - 1) / 3) * 3 + 1;     // thang dau cua qui
   else if(k == 3)
      d.mon = 1;                             // ngay dau nam
   else if(k >= 4)
     {
      d.mon  = 1;                            // N nam (k = 4..7 -> N = 2..5): 1/1 cua nam (hien tai - (N - 1)), tuc nam nay + N-1 nam lich truoc
      d.year = d.year - (k - 3);
     }
   return(StructToTime(d));
  }

// (AptPeriodExtremeStr() con trong file nhung khong con duoc goi: AptPeriodExtremeUpdate() dung AptPeriodExtremeFromRates() tren mang H1 dung chung.)
string AptPeriodExtremeStr(const int k, const string name, const datetime tStart, const double w)
  {
   g_pexOk[k] = false;
   MqlRates r[];
   ArraySetAsSeries(r, false);
   int got = (tStart > 0) ? CopyRates(_Symbol, PERIOD_H1, tStart, TimeCurrent(), r) : -1;
   if(got <= 0)
      return(name + " cao - thấp -");

   double hi = r[0].high;
   double lo = r[0].low;
   for(int i = 1; i < got; i++)
     {
      if(r[i].high > hi) hi = r[i].high;
      if(r[i].low  < lo) lo = r[i].low;
     }
   if(hi <= 0.0 || lo <= 0.0)
      return(name + " cao - thấp -");

   // [GIU NGUYEN - KHONG XOA] double hiR = MathRound(hi / 10.0) * 10.0;   // lam tron hang chuc
   // [GIU NGUYEN - KHONG XOA] double loR = MathRound(lo / 10.0) * 10.0;
   // [GIU NGUYEN - KHONG XOA] double hiR = MathRound((hi - 5.0) / 10.0) * 10.0 + 5.0;   // lam tron ve muc x5 GAN NHAT (..4145, 4155, 4165..)
   // [GIU NGUYEN - KHONG XOA] double loR = MathRound((lo - 5.0) / 10.0) * 10.0 + 5.0;
   double hiR = AptRndOutsideHigh(hi);   // moc lam tron BEN NGOAI dinh (>= dinh) theo luoi nut dang chon
   double loR = AptRndOutsideLow(lo);    // moc lam tron BEN NGOAI day (<= day) theo luoi nut dang chon

   int  nH = 0, nL = 0;
   bool inH = false, inL = false;
   for(int i = 0; i < got; i++)
     {
      bool tH = (r[i].high >= hiR - w && r[i].low <= hiR + w);
      bool tL = (r[i].high >= loR - w && r[i].low <= loR + w);
      if(tH && !inH) nH++;
      if(tL && !inL) nL++;
      inH = tH;
      inL = tL;
     }
   if(nH < 1) nH = 1;     // nen chua dinh / day luon cham khu vuc cua chinh no
   if(nL < 1) nL = 1;

   g_pexOk [k] = true;
   g_pexHiR[k] = hiR;
   g_pexLoR[k] = loR;
   g_pexNH [k] = nH;
   g_pexNL [k] = nL;
   return(name + " cao " + IntegerToString((long)hiR) + " (" + IntegerToString(nH) + " lần) thấp " +
          IntegerToString((long)loR) + " (" + IntegerToString(nL) + " lần)");
  }

// [GIU NGUYEN - KHONG XOA] // Cap nhat g_pexTxt[0..3] (tuan, thang, qui, nam). Throttle: toi da 1 lan / giay hoac khi doi pham vi W.
// [GIU NGUYEN - KHONG XOA] void AptPeriodExtremeUpdate()
// [GIU NGUYEN - KHONG XOA]   {
// [GIU NGUYEN - KHONG XOA]    double   w   = (g_aptRndRange < 0.0) ? 0.0 : g_aptRndRange;
// [GIU NGUYEN - KHONG XOA]    datetime now = TimeLocal();
// [GIU NGUYEN - KHONG XOA]    if(g_pexTxt[0] != "" && g_pexLastSec == now && g_pexLastW == w)
// [GIU NGUYEN - KHONG XOA]       return;
// [GIU NGUYEN - KHONG XOA]    g_pexLastSec = now;
// [GIU NGUYEN - KHONG XOA]    g_pexLastW   = w;
// [GIU NGUYEN - KHONG XOA]    for(int k = 0; k < APT_PEX_COUNT; k++)
// [GIU NGUYEN - KHONG XOA]       g_pexTxt[k] = AptPeriodExtremeStr(k, g_pexName[k], AptPeriodStartTime(k), w);
// [GIU NGUYEN - KHONG XOA]   }

// Nhu AptPeriodExtremeStr() (cung cong thuc cao/thap, lam tron x5, dem lan cham) nhung tinh tren mang nen H1 DUNG CHUNG r[from..got-1] (r[] tang dan theo thoi gian).
string AptPeriodExtremeFromRates(const int k, const string name, const MqlRates &r[], const int from, const int got, const double w)
  {
   g_pexOk[k] = false;
   if(from < 0 || from >= got)
      return(name + " cao - thấp -");

   double hi = r[from].high;
   double lo = r[from].low;
   for(int i = from + 1; i < got; i++)
     {
      if(r[i].high > hi) hi = r[i].high;
      if(r[i].low  < lo) lo = r[i].low;
     }
   if(hi <= 0.0 || lo <= 0.0)
      return(name + " cao - thấp -");

   // [GIU NGUYEN - KHONG XOA] double hiR = MathRound((hi - 5.0) / 10.0) * 10.0 + 5.0;   // lam tron ve muc x5 GAN NHAT (..4145, 4155, 4165..)
   // [GIU NGUYEN - KHONG XOA] double loR = MathRound((lo - 5.0) / 10.0) * 10.0 + 5.0;
   double hiR = AptRndOutsideHigh(hi);   // moc lam tron BEN NGOAI dinh (>= dinh) theo luoi nut dang chon
   double loR = AptRndOutsideLow(lo);    // moc lam tron BEN NGOAI day (<= day) theo luoi nut dang chon

   int  nH = 0, nL = 0;
   bool inH = false, inL = false;
   for(int i = from; i < got; i++)
     {
      bool tH = (r[i].high >= hiR - w && r[i].low <= hiR + w);
      bool tL = (r[i].high >= loR - w && r[i].low <= loR + w);
      if(tH && !inH) nH++;
      if(tL && !inL) nL++;
      inH = tH;
      inL = tL;
     }
   if(nH < 1) nH = 1;     // nen chua dinh / day luon cham khu vuc cua chinh no
   if(nL < 1) nL = 1;

   g_pexOk [k] = true;
   g_pexHiR[k] = hiR;
   g_pexLoR[k] = loR;
   g_pexNH [k] = nH;
   g_pexNL [k] = nL;
   return(name + " cao " + IntegerToString((long)hiR) + " (" + IntegerToString(nH) + " lần) thấp " +
          IntegerToString((long)loR) + " (" + IntegerToString(nL) + " lần)");
  }

// Cap nhat g_pexTxt[0..7] (tuan, thang, qui, nam, 2 / 3 / 4 / 5 nam). Throttle: toi da 1 lan / giay hoac khi doi pham vi W.
//   Nen H1 copy MOT LAN tu dau ky SOM NHAT (5 nam ~ 31000 nen) va dung chung cho ca 8 ky; chi copy lai khi sang nen H1 moi / doi dau ky,
//   giua hai lan do chi cap nhat nen H1 dang chay. Lich su H1 cua terminal ngan hon dau ky (nen dau tien tre hon dau ky > APT_PEX_HIST_TOL) -> ky do in "-",
//   va cu 60 giay thu copy lai (terminal co the dang tai them lich su).
void AptPeriodExtremeUpdate()
  {
   static MqlRates s_pexR[];
   static int      s_pexGot   = 0;
   static datetime s_pexFrom  = 0;    // dau ky som nhat luc copy
   static datetime s_pexH1T   = 0;    // iTime(H1, 0) luc copy
   static bool     s_pexShort = false; // lich su H1 khong phu toi dau ky som nhat
   static datetime s_pexTry   = 0;    // TimeLocal lan copy gan nhat

   double   w   = (g_aptRndRange < 0.0) ? 0.0 : g_aptRndRange;
   datetime now = TimeLocal();
   if(g_pexTxt[0] != "" && g_pexLastSec == now && g_pexLastW == w)
      return;
   g_pexLastSec = now;
   g_pexLastW   = w;

   datetime st[APT_PEX_COUNT];
   datetime tMin = 0;
   for(int k = 0; k < APT_PEX_COUNT; k++)
     {
      st[k] = AptPeriodStartTime(k);
      if(st[k] > 0 && (tMin == 0 || st[k] < tMin))
         tMin = st[k];
     }

   datetime h1T = iTime(_Symbol, PERIOD_H1, 0);
   bool reload = (tMin > 0) && (s_pexGot <= 0 || s_pexFrom != tMin || s_pexH1T != h1T ||
                                (s_pexShort && (long)(now - s_pexTry) >= 60));
   if(reload)
     {
      ArraySetAsSeries(s_pexR, false);
      int g = CopyRates(_Symbol, PERIOD_H1, tMin, TimeCurrent(), s_pexR);
      s_pexTry   = now;
      s_pexGot   = (g > 0) ? g : 0;
      s_pexFrom  = (g > 0) ? tMin : 0;
      s_pexH1T   = (g > 0) ? h1T  : 0;
      s_pexShort = (g > 0) && ((long)s_pexR[0].time > (long)tMin + APT_PEX_HIST_TOL);
     }
   else if(s_pexGot > 0)
     {
      MqlRates c[];
      if(CopyRates(_Symbol, PERIOD_H1, 0, 1, c) == 1 && c[0].time == s_pexR[s_pexGot - 1].time)
         s_pexR[s_pexGot - 1] = c[0];      // chi cap nhat nen H1 dang chay
     }

   for(int k = 0; k < APT_PEX_COUNT; k++)
     {
      g_pexOk[k] = false;
      if(st[k] <= 0 || s_pexGot <= 0 || (long)s_pexR[0].time > (long)st[k] + APT_PEX_HIST_TOL)
        {
         g_pexTxt[k] = g_pexName[k] + " cao - thấp -";   // thieu du lieu / lich su H1 khong phu toi dau ky
         continue;
        }
      int lo = 0, hi = s_pexGot;                   // nen dau tien co time >= dau ky
      while(lo < hi)
        {
         int mid = (lo + hi) / 2;
         if(s_pexR[mid].time < st[k]) lo = mid + 1;
         else                         hi = mid;
        }
      g_pexTxt[k] = AptPeriodExtremeFromRates(k, g_pexName[k], s_pexR, lo, s_pexGot, w);
     }
  }

// Danh dau CAO NHAT / THAP NHAT (moc lam tron ben ngoai dinh / day) cua tuan, thang, qui, nam, 2 / 3 / 4 / 5 nam + so lan cham len TRUC THOI GIAN noi THAN NEN LON dang ve (tAt = tMid cua nen s = 0 trong DrawBarChartLabels):
//   moi moc 1 nhan OBJ_TEXT tai (tAt, gia moc), neo trai: "◆ <gia> <ky> cao (<n> lan)" / "◆ <gia> <ky> thap (<m> lan)". Cac moc TRUNG GIA gop 1 nhan, noi bang " | ".
//   Mau: moc CAO = InpBarUpColor, moc THAP = InpBarDownColor. Khong ve duong; object ten g_barLblPrefix + "PX" + chi so (DrawBarChartLabels da xoa het OBJ_TEXT prefix nay truoc moi lan ve).
void AptPeriodExtremeMarksDraw(const datetime tAt, const int fs)
  {
   AptPeriodExtremeUpdate();
   double px[2 * APT_PEX_COUNT];
   string tx[2 * APT_PEX_COUNT];
   color  cl[2 * APT_PEX_COUNT];
   int    n = 0;
   for(int k = 0; k < APT_PEX_COUNT; k++)
     {
      if(!g_pexOk[k])
         continue;
      for(int side = 0; side < 2; side++)
        {
         double p   = (side == 0) ? g_pexHiR[k] : g_pexLoR[k];
         int    cnt = (side == 0) ? g_pexNH[k]  : g_pexNL[k];
         if(p <= 0.0)
            continue;
         string t = g_pexName[k] + ((side == 0) ? " cao" : " thấp") + " (" + IntegerToString(cnt) + " lần)";
         int f = -1;
         for(int j = 0; j < n; j++)
            if(px[j] == p) { f = j; break; }
         if(f >= 0)
            tx[f] = tx[f] + " | " + t;
         else
           {
            px[n] = p;
            tx[n] = t;
            cl[n] = (side == 0) ? InpBarUpColor : InpBarDownColor;
            n++;
           }
        }
     }
   for(int j = 0; j < n; j++)
     {
      string nmX = g_barLblPrefix + "PX" + IntegerToString(j);
      if(ObjectCreate(0, nmX, OBJ_TEXT, 0, tAt, px[j]))
        {
         ObjectSetString (0, nmX, OBJPROP_TEXT,       "◆ " + IntegerToString((long)MathRound(px[j])) + " " + tx[j]);
         ObjectSetString (0, nmX, OBJPROP_FONT,       InpFontName);
         ObjectSetInteger(0, nmX, OBJPROP_COLOR,      cl[j]);
         ObjectSetInteger(0, nmX, OBJPROP_FONTSIZE,   fs);
         ObjectSetInteger(0, nmX, OBJPROP_ANCHOR,     ANCHOR_LEFT);
         ObjectSetInteger(0, nmX, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, nmX, OBJPROP_HIDDEN,     true);
         ObjectSetInteger(0, nmX, OBJPROP_BACK,       false);
        }
     }
  }

//+------------------------------------------------------------------+
//| ALERT RIENG CAO NHAT / THAP NHAT cua TUAN, THANG, QUI, NAM (AptPeriodExtremeAlertCheck): 8 moc = 4 ky x (cao, thap), moi moc 1 file am thanh rieng (InpPexSnd*).   |
//|   Moc lay tu AptPeriodExtremeUpdate() (g_pexHiR / g_pexLoR / g_pexNH / g_pexNL), cung gia lam tron ben ngoai voi nhan hang 5..12 va dau moc tren chart; 2..5 nam dung chung am thanh NAM.            |
//|   Moc CAO "nong" khi Bid >= moc - InpPexAlertDist ; moc THAP "nong" khi Bid <= moc + InpPexAlertDist. Moi lan 1 moc tu khong nong -> nong (hoac sang ky moi):    |
//|     - phat am thanh rieng cua moc (them: lap lai moi InpPexAlertRepeatSec giay khi con nong, 0 = khong lap);                                                     |
//|     - ghi log Experts; gom TAT CA moc moi nong trong 1 nhip thanh 1 PUSH (SendNotification, toi da 255 ky tu), moi moc cach nhau it nhat InpPexPushMinSec giay.   |
//|   Push gui toi app MT5 co MetaQuotes ID khai bao trong Tools > Options > Notifications.                                                                          |
//+------------------------------------------------------------------+
bool     g_pexAlHot    [2 * APT_PEX_COUNT];   // moc (k * 2 + side; side 0 = cao, 1 = thap) dang "nong"
datetime g_pexAlLastSnd[2 * APT_PEX_COUNT];   // TimeLocal lan phat am thanh gan nhat cua moc
datetime g_pexAlLastPush[2 * APT_PEX_COUNT];  // TimeLocal lan gui push gan nhat cua moc
datetime g_pexAlPeriod [APT_PEX_COUNT];       // dau ky luc kiem tra truoc (doi ky -> moc moi, bao lai tu dau)

string AptPexSoundFor(const int k, const int side)
  {
   if(k == 0)
      return(side == 0 ? InpPexSndWeekHigh : InpPexSndWeekLow);
   if(k == 1)
      return(side == 0 ? InpPexSndMonthHigh : InpPexSndMonthLow);
   if(k == 2)
      return(side == 0 ? InpPexSndQuarterHigh : InpPexSndQuarterLow);
   return(side == 0 ? InpPexSndYearHigh : InpPexSndYearLow);
  }

void AptPeriodExtremeAlertCheck()
  {
   if(!InpPexAlertOn)
     {
      for(int z = 0; z < 2 * APT_PEX_COUNT; z++)
         g_pexAlHot[z] = false;
      return;
     }
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(bid <= 0.0)
      return;

   AptPeriodExtremeUpdate();
   double   dist = (InpPexAlertDist < 0.0) ? 0.0 : InpPexAlertDist;
   datetime now  = TimeLocal();
   string   pushMsg = "";
   int      nPush = 0;

   for(int k = 0; k < APT_PEX_COUNT; k++)
     {
      datetime per = AptPeriodStartTime(k);
      if(g_pexAlPeriod[k] != per)
        {
         g_pexAlPeriod[k] = per;                  // sang ky moi: moc moi -> bao lai tu dau
         g_pexAlHot[k * 2]     = false;
         g_pexAlHot[k * 2 + 1] = false;
        }
      for(int side = 0; side < 2; side++)
        {
         int    idx = k * 2 + side;
         double lvl = 0.0;
         int    cnt = 0;
         bool   hot = false;
         if(g_pexOk[k])
           {
            lvl = (side == 0) ? g_pexHiR[k] : g_pexLoR[k];
            cnt = (side == 0) ? g_pexNH[k]  : g_pexNL[k];
            if(lvl > 0.0 && !AptRndGapHides(lvl))   // nut "KC": moc trung nhan lam tron dang bi an -> khong bao (am thanh + push)
               hot = (side == 0) ? (bid >= lvl - dist) : (bid <= lvl + dist);
           }
         if(!hot)
           {
            g_pexAlHot[idx] = false;
            continue;
           }

         bool   isNew = !g_pexAlHot[idx];
         g_pexAlHot[idx] = true;
         string what = g_pexName[k] + ((side == 0) ? " cao " : " thấp ") + IntegerToString((long)MathRound(lvl)) + " (" + IntegerToString(cnt) + " lần)";

         // am thanh RIENG cua moc
         string snd = AptPexSoundFor(k, side);
         if(StringLen(snd) > 0)
           {
            bool again = (InpPexAlertRepeatSec > 0 && g_pexAlLastSnd[idx] != 0 && (long)(now - g_pexAlLastSnd[idx]) >= (long)InpPexAlertRepeatSec);
            if(isNew || again)
              {
               PlaySound(snd);
               g_pexAlLastSnd[idx] = now;
              }
           }

         if(!isNew)
            continue;
         Print("[APT] ", _Symbol, " | MOC ", what, " | Bid ", DoubleToString(bid, _Digits), " (", StringFormat("%+.2f", bid - lvl), ")");

         // push: gom cac moc moi nong trong 1 nhip thanh 1 thong bao
         if(InpPexPushOn)
           {
            int minGap = (InpPexPushMinSec < 0) ? 0 : InpPexPushMinSec;
            if(g_pexAlLastPush[idx] == 0 || (long)(now - g_pexAlLastPush[idx]) >= (long)minGap)
              {
               g_pexAlLastPush[idx] = now;
               pushMsg += (nPush > 0 ? " | " : "") + what;
               nPush++;
              }
           }
        }
     }

   if(nPush > 0)
     {
      string full = _Symbol + ": " + pushMsg + " | Bid " + DoubleToString(bid, _Digits);
      if(StringLen(full) > 255)
         full = StringSubstr(full, 0, 255);
      if(!SendNotification(full))
         Print("[APT] SendNotification loi ", GetLastError(), " - bat Tools > Options > Notifications va dien MetaQuotes ID cua app MT5 tren dien thoai");
     }
  }

//+------------------------------------------------------------------+
//| ATR "NEN MANH" (AptAtrHi): trung binh TR cua APT_ATRHI_PICK (14) nen DA DONG GAN NHAT co TR > TRUNG VI TR cua APT_ATRHI_BASE (50) nen da dong gan nhat. |
//|   TR = max(High, Close truoc) - min(Low, Close truoc). Quet lui toi da APT_ATRHI_SCAN (300) nen; lich su ngan hon thi dung so nen co san.                   |
//|   Khong du 14 nen manh -> false (in "-"). Chi doc nen da dong nen cache theo iTime(tf, 0). Dung cho hang 1 cum nhan duoi than nen lon: artday artweek artmonth. |
//+------------------------------------------------------------------+
#define APT_ATRHI_PICK 14
#define APT_ATRHI_BASE 50
#define APT_ATRHI_SCAN 300

bool AptAtrHi(const ENUM_TIMEFRAMES tf, double &outAtr)
  {
   outAtr = 0.0;
   int avail = Bars(_Symbol, tf) - 2;                       // nen da dong co nen lien truoc
   int need  = MathMin(MathMax(APT_ATRHI_BASE, APT_ATRHI_SCAN), avail);
   if(need < APT_ATRHI_PICK + 1)
      return false;
   double h[], l[], c[];
   ArraySetAsSeries(h, true);
   ArraySetAsSeries(l, true);
   ArraySetAsSeries(c, true);
   if(CopyHigh (_Symbol, tf, 1, need + 1, h) < need + 1 ||
      CopyLow  (_Symbol, tf, 1, need + 1, l) < need + 1 ||
      CopyClose(_Symbol, tf, 1, need + 1, c) < need + 1)
      return false;

   double tr[];
   ArrayResize(tr, need);
   for(int i = 0; i < need; i++)                            // tr[i] = TR cua nen shift i+1
      tr[i] = MathMax(h[i], c[i + 1]) - MathMin(l[i], c[i + 1]);

   int    mB = MathMin(APT_ATRHI_BASE, need);
   double base[];
   ArrayResize(base, mB);
   for(int i = 0; i < mB; i++)
      base[i] = tr[i];
   ArraySort(base);
   double med = (mB % 2 == 1) ? base[mB / 2] : 0.5 * (base[mB / 2 - 1] + base[mB / 2]);

   double sum = 0.0;
   int    got = 0;
   for(int i = 0; i < need && got < APT_ATRHI_PICK; i++)
      if(tr[i] > med)
        {
         sum += tr[i];
         got++;
        }
   if(got < APT_ATRHI_PICK)
      return false;                                         // khong du nen manh -> khong doan
   outAtr = sum / got;
   return true;
  }

// Chuoi so nguyen ($) cua AptAtrHi() cho khung tf, cache theo nen tf. Thieu du lieu -> "-" (thu lai o lan goi sau).
string AptAtrHiStr(const ENUM_TIMEFRAMES tf)
  {
   static ENUM_TIMEFRAMES s_tf[3]  = {PERIOD_D1, PERIOD_W1, PERIOD_MN1};
   static datetime        s_bar[3] = {0, 0, 0};
   static string          s_txt[3] = {"-", "-", "-"};
   int k = -1;
   for(int j = 0; j < 3; j++)
      if(s_tf[j] == tf) { k = j; break; }
   datetime b0 = iTime(_Symbol, tf, 0);
   if(k >= 0 && b0 > 0 && s_bar[k] == b0)
      return s_txt[k];
   double a = 0.0;
   string r = AptAtrHi(tf, a) ? IntegerToString((long)MathRound(a)) : "-";
   if(k >= 0)
     {
      s_txt[k] = r;
      s_bar[k] = (r != "-") ? b0 : 0;
     }
   return r;
  }

//+------------------------------------------------------------------+
//| BuildBarCurLblRows: dung cac hang nhan cua cum duoi than nen lon (% bien do, Dmax/Dmin, elapsed, hang 5..12 tuan/thang/qui/nam/2..5 nam, canh bao het gio, 3 hang g_bcTopTxt[] (hien khong ghi)); tra ve so hang, mau tung hang o g_bcRowClr[]. |
//+------------------------------------------------------------------+
int BuildBarCurLblRows(string &rows[])
{
   ArrayResize(rows, 0);

   if(!InpBarLblShow)   return(0);
   if(!InpShowBarChart) return(0);   // than nen tat thi cum cung tat theo

   //--- Khung: y het DrawBarChartLabels (setting truoc, bang nut 2 de len) ---
   ENUM_TIMEFRAMES _bcTf = InpBarChartTF;
   if(g_barTF != InpBarChartTF) _bcTf = g_barTF;

   MqlRates _bcRt[];
   ArraySetAsSeries(_bcRt, true);
   if(CopyRates(_Symbol, _bcTf, 0, 1, _bcRt) <= 0) return(0);

   bool _bcUp = (_bcRt[0].close >= _bcRt[0].open);

   //--- (1) % bien do nen so voi Close cua chinh nen do ---
   if(InpBarLblShowPct && _bcRt[0].close != 0.0)
   {
      // Nen dang chay (s = 0) luon nam trong pham vi InpBarLblPctCount nen khong can kiem tra lai.
      double _bcHlc = (_bcRt[0].high - _bcRt[0].low) / _bcRt[0].close * 100.0;
      if(!_bcUp) _bcHlc = -_bcHlc;
      int _n0 = ArraySize(rows);
      ArrayResize(rows, _n0 + 1);
      // [GIU NGUYEN - KHONG XOA] // Format hang: <x.xx>% x.x$  (x.xx% = (High-Low)/Close*100 co dau theo chieu nen; x.x$ = |High-Low| tuyet doi, 1 so le, tinh bang don vi gia)
      // [GIU NGUYEN - KHONG XOA] rows[_n0] = DoubleToString(_bcHlc, 2) + "% " + DoubleToString(MathAbs(_bcRt[0].high - _bcRt[0].low), 1) + "$";
      // Format hang: <x.xx>% x.x$ <artday> <artweek> <artmonth>  (art* = ATR nen manh khung D1 / W1 / MN1, AptAtrHi(), so nguyen don vi gia; thieu -> "-")
      rows[_n0] = DoubleToString(_bcHlc, 2) + "% " + DoubleToString(MathAbs(_bcRt[0].high - _bcRt[0].low), 1) + "$ " +
                  AptAtrHiStr(PERIOD_D1) + " " + AptAtrHiStr(PERIOD_W1) + " " + AptAtrHiStr(PERIOD_MN1);
   }

   //--- (2) Dmax / Dmin cua khung do - MOT lan doc, hai hang rieng ---
   if(InpBarLblShowMaxMin)
   {
      bool   _bcHu = false, _bcHd = false;
      double _bcMu = 0.0,   _bcMd = 0.0;
      bool   _bcOk = MbcRangeStatCurrent(InpBarChartTF, _bcHu, _bcMu, _bcHd, _bcMd);
      if(g_barTF != InpBarChartTF)
         _bcOk = MbcRangeStatCurrent(g_barTF, _bcHu, _bcMu, _bcHd, _bcMd);

      string _bcUpS = "-";
      string _bcDnS = "-";
      if(_bcOk)
      {
         if(_bcHu) _bcUpS = "+" + DoubleToString(_bcMu, 2) + "%";
         if(_bcHd) _bcDnS = DoubleToString(_bcMd, 2) + "%";
      }

      int _n1 = ArraySize(rows);
      ArrayResize(rows, _n1 + 1);
      rows[_n1] = _bcUpS;                 // <Dmax>

      int _n2 = ArraySize(rows);
      ArrayResize(rows, _n2 + 1);
      rows[_n2] = _bcDnS;                 // <Dmin>
   }

   //--- (3) elapsed cua nen hien tai ---
   if(InpBarLblShowElapsed)
   {
      long _bcEl = (long)(TimeCurrent() - _bcRt[0].time);
      if(_bcEl < 0) _bcEl = 0;
      int _n3 = ArraySize(rows);
      ArrayResize(rows, _n3 + 1);
      rows[_n3] = ElapsedToStr(_bcEl);
   }

   //--- (3b) hang 5..12: cao nhat / thap nhat TUAN, THANG, QUI, NAM, 2 / 3 / 4 / 5 NAM + so lan cham (xem AptPeriodExtremeUpdate) ---
   {
      int _pxN0 = ArraySize(rows);
      if(_pxN0 < 4)                       // dem cho du 4 hang truoc de tuan / thang / qui / nam luon la hang 5 / 6 / 7 / 8
        {
         ArrayResize(rows, 4);
         for(int _pxK = _pxN0; _pxK < 4; _pxK++) rows[_pxK] = " ";
        }
      AptPeriodExtremeUpdate();
      for(int _pxJ = 0; _pxJ < APT_PEX_COUNT; _pxJ++)
        {
         int _pxN = ArraySize(rows);
         ArrayResize(rows, _pxN + 1);
         rows[_pxN] = g_pexTxt[_pxJ];
        }
   }

   //--- (4) canh bao HET GIO (nay nam SAU hang nam, chi hien khi sap het gio) ---
   if(InpBarLblShowCountdown)
   {
      string _bcCd = BuildCountdownWarn();
      if(_bcCd != "")
      {
         int _n4 = ArraySize(rows);
         ArrayResize(rows, _n4 + 1);
         rows[_n4] = _bcCd;
      }
   }


   int _bcTopIdx[3] = {-1, -1, -1};   // 3 hang
   bool _bcHasTop = false;
   for(int _bcTk = 0; _bcTk < 3; _bcTk++)
      if(StringLen(g_bcTopTxt[_bcTk]) > 0) { _bcHasTop = true; break; }
   if(_bcHasTop)
   {
      int _tpN0 = ArraySize(rows);
      if(_tpN0 < 5)
      {
         ArrayResize(rows, 5);
         for(int _tpK = _tpN0; _tpK < 5; _tpK++) rows[_tpK] = " ";
      }
   }
   for(int _bcTk = 0; _bcTk < 3; _bcTk++)
   {
      if(StringLen(g_bcTopTxt[_bcTk]) < 1) continue;
      int _tpN = ArraySize(rows);
      ArrayResize(rows, _tpN + 1);
      rows[_tpN] = g_bcTopTxt[_bcTk];
      _bcTopIdx[_bcTk] = _tpN;
   }

   ArrayResize(g_bcRowClr, ArraySize(rows));
   for(int _bcCk = 0; _bcCk < ArraySize(rows); _bcCk++)
      g_bcRowClr[_bcCk] = InpBarLblColorCur;
   for(int _bcTk = 0; _bcTk < 3; _bcTk++)
      if(_bcTopIdx[_bcTk] >= 0)
         g_bcRowClr[_bcTopIdx[_bcTk]] = g_bcTopClr[_bcTk];

   return(ArraySize(rows));
}

//+------------------------------------------------------------------+
//| Khai bao TRUOC RvOrderAccumUpdate(): than ham nam o duoi trong file |
//|   (ngay sau BrkAccumUpdate); DrawBarChartLabels ngay ben duoi can goi. |
//+------------------------------------------------------------------+
void   RvOrderAccumUpdate();
// Khai bao TRUOC TpAccumUpdate(): than ham nam o duoi trong file (ngay sau RvOrderAccumUpdate());
//   DrawBarChartLabels ngay ben duoi can goi.
void   TpAccumUpdate();

//+------------------------------------------------------------------+
//| DrawBarChartLabels: ghi nhan tai DIEM CUOI cua VACH |
//|   CLOSE (ben phai) cua tung than nen Bar Chart dang ve theo khung |
//|   InpBarChartTF trong setting.                                    |
//|     - Nen s > 0 (da dong): chi ghi % bien do cua chinh nen do,    |
//|       mau theo chieu nen (InpBarUpColor / InpBarDownColor).       |
//| - Nen s = 0 (dang chay): cum gop duoc ghi tai DAY |
//|       (Low) cua than nen lon, moc thoi gian tMid (tam cot than nen)|
//|       va ANCHOR_UPPER nen chu nam NGAY DUOI day nen, can giua cot. |
//|       Chuoi cum van do BuildBarCurLblStr() go.                     |
void DrawBarChartLabels()
{
   RvOrderAccumUpdate();

   TpAccumUpdate();

   ObjectsDeleteAll(0, g_barLblPrefix, -1, OBJ_TEXT);

   if(!InpBarLblShow)   return;
   if(!InpShowBarChart) return;   // than nen tat thi nhan cung tat theo

   int cnt = InpBarChartCount;
   if(cnt < 1) return;

   MqlRates rt[];
   ArraySetAsSeries(rt, true);
   int _bcProbeN = (g_barTF != InpBarChartTF) ? 1 : cnt;
   int got = CopyRates(_Symbol, InpBarChartTF, 0, _bcProbeN, rt);
   if(got <= 0) return;

   long secPerBar = PeriodSeconds(InpBarChartTF);
   if(secPerBar <= 0) return;

   if(g_barTF != InpBarChartTF)
   {
      got = CopyRates(_Symbol, g_barTF, 0, cnt, rt);
      if(got <= 0) return;
      secPerBar = PeriodSeconds(g_barTF);
      if(secPerBar <= 0) return;
   }

   // Diem cuoi vach Close: tam nen + nua do rong than nen (y het DrawBarChart)
   double   bodyFrac = MathMax(5, MathMin(95, InpBarBodyWidthPct)) / 100.0;
   datetime tickLen  = (datetime)((secPerBar * bodyFrac) / 2.0);
   if(InpBarTickFixedLen)
   {
      // Uu tien neo theo SO NEN CUA CHART dang mo: be rong vach ra pixel luon co dinh,
      // khong phu thuoc InpBarChartTF, nen khung lon hay nho deu co vach ngan bang nhau.
      if(InpBarTickChartBars > 0)
      {
         long secChart = PeriodSeconds(_Period);
         if(secChart > 0) tickLen = (datetime)((long)InpBarTickChartBars * secChart);
      }
      else
      {
         long secTickRef = PeriodSeconds(InpBarTickRefTF);
         if(secTickRef > 0) tickLen = (datetime)((secTickRef * bodyFrac) / 2.0);
      }
   }
   if(tickLen < 1) tickLen = 1;

   int fs = (InpBarLblFontSize < 6) ? 6 : InpBarLblFontSize;

   double _curPMin = 0.0, _curPMax = 0.0;
   long   _curHcPx = 0;
   ChartGetDouble (0, CHART_PRICE_MIN,        0, _curPMin);
   ChartGetDouble (0, CHART_PRICE_MAX,        0, _curPMax);
   ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS, 0, _curHcPx);
   double _curPxStep = (_curHcPx > 0 && _curPMax > _curPMin)
                        ? (_curPMax - _curPMin) / (double)_curHcPx : _Point;
   if(_curPxStep <= 0.0) _curPxStep = _Point;

   for(int s = 0; s < got; s++)
   {
      bool  up  = (rt[s].close >= rt[s].open);
      color clr = up ? InpBarUpColor : InpBarDownColor;

      datetime tMid = rt[s].time + (datetime)(secPerBar / 2);
      tMid = BarChartMidTime(s, rt[s].time, secPerBar);
      datetime tEnd = tMid + tickLen;          // dung diem cuoi vach Close

      // --- (1) % bien do nen so voi Close cua chinh nen do ---
      string pctStr = "";
      if(InpBarLblShowPct && rt[s].close != 0.0)
      {
         bool inRange = (InpBarLblPctCount <= 0) || (s < InpBarLblPctCount);
         if(inRange)
         {
            double hlcPct = (rt[s].high - rt[s].low) / rt[s].close * 100.0;
            if(!up) hlcPct = -hlcPct;
            pctStr = DoubleToString(hlcPct, 2) + "%";
         }
      }

      if(s > 0)
      {
         // Nen da dong: chi ghi cum %, mau theo chieu nen
         if(pctStr == "") continue;
         string nmP = g_barLblPrefix + "P" + IntegerToString(s);
         if(ObjectCreate(0, nmP, OBJ_TEXT, 0, tEnd, rt[s].close))
         {
            ObjectSetString (0, nmP, OBJPROP_TEXT,       pctStr);
            ObjectSetInteger(0, nmP, OBJPROP_COLOR,      clr);
            ObjectSetInteger(0, nmP, OBJPROP_FONTSIZE,   fs);
            ObjectSetInteger(0, nmP, OBJPROP_ANCHOR,     ANCHOR_LEFT);
            ObjectSetInteger(0, nmP, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, nmP, OBJPROP_HIDDEN,     true);
            ObjectSetInteger(0, nmP, OBJPROP_BACK,       false);
         }
         continue;
      }

      AptPeriodExtremeMarksDraw(tMid, fs);   // dau moc cao nhat / thap nhat tuan, thang, qui, nam + so lan cham, tai truc thoi gian cua than nen lon

      string curRows[];
      int    curRowCnt = BuildBarCurLblRows(curRows);
      if(curRowCnt <= 0) continue;

      for(int r = 0; r < curRowCnt; r++)
      {
         string   nmCB  = g_barLblPrefix + "CUR" + IntegerToString(r);
         double   pRow  = rt[0].low - _curPxStep * (double)(fs + 7) * (double)r;
         if(ObjectCreate(0, nmCB, OBJ_TEXT, 0, tMid, pRow))
         {
            ObjectSetString (0, nmCB, OBJPROP_TEXT,       curRows[r]);
            ObjectSetInteger(0, nmCB, OBJPROP_COLOR,      (r < ArraySize(g_bcRowClr)) ? g_bcRowClr[r] : InpBarLblColorCur);
            ObjectSetInteger(0, nmCB, OBJPROP_FONTSIZE,   fs);
            ObjectSetInteger(0, nmCB, OBJPROP_ANCHOR,     ANCHOR_RIGHT_UPPER);
            ObjectSetInteger(0, nmCB, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, nmCB, OBJPROP_HIDDEN,     true);
            ObjectSetInteger(0, nmCB, OBJPROP_BACK,       false);
         }
      }


   }
}

//+------------------------------------------------------------------+
//| MakeTFButton: tao 1 nut OBJ_BUTTON co dinh theo pixel. |
//+------------------------------------------------------------------+
void MakeTFButton(const string name, const string text,
                  const int x, const int y, const int w, const int h,
                  const bool selected)
{
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER,     InpTFPanelCorner);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE,  x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE,  y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE,      w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE,      h);
   ObjectSetString (0, name, OBJPROP_TEXT,       text);
   ObjectSetString (0, name, OBJPROP_FONT,       "Arial");
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE,   (InpTFBtnFontSize < 6) ? 6 : InpTFBtnFontSize);
   ObjectSetInteger(0, name, OBJPROP_COLOR,      InpTFBtnTextCol);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR,    selected ? InpTFBtnBgSel : InpTFBtnBg);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, clrSilver);
   ObjectSetInteger(0, name, OBJPROP_STATE,      false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN,     true);
   ObjectSetInteger(0, name, OBJPROP_BACK,       false);
}

//+------------------------------------------------------------------+
//| TFPanelWidth: be rong 1 bang = 4 cot nut + khe ho. |
//+------------------------------------------------------------------+
int TFPanelWidth()
{
   int w = (InpTFBtnW < 16) ? 16 : InpTFBtnW;
   int g = (InpTFBtnGap < 0) ? 0 : InpTFBtnGap;
   return(RV2_UI_COLS * w + (RV2_UI_COLS - 1) * g);
}

//+------------------------------------------------------------------+
//| MakeLevelButton: tao 1 nut cua BANG CHON MUC Pivot. |
//|   Giong het MakeTFButton, chi khac mau nen khi nut DANG CHON dung |
//|   InpLvlBtnBgSel (de phan biet voi bang nut khung). Khong dung     |
//|   den bat ky setting nao cua bang nut khung.                       |
//+------------------------------------------------------------------+
void MakeLevelButton(const string name, const string text,
                     const int x, const int y, const int w, const int h,
                     const bool selected)
{
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER,     InpTFPanelCorner);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE,  x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE,  y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE,      w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE,      h);
   ObjectSetString (0, name, OBJPROP_TEXT,       text);
   ObjectSetString (0, name, OBJPROP_FONT,       "Arial");
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE,   (InpTFBtnFontSize < 6) ? 6 : InpTFBtnFontSize);
   ObjectSetInteger(0, name, OBJPROP_COLOR,      InpTFBtnTextCol);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR,    selected ? InpLvlBtnBgSel : InpTFBtnBg);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, clrSilver);
   ObjectSetInteger(0, name, OBJPROP_STATE,      false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN,     true);
   ObjectSetInteger(0, name, OBJPROP_BACK,       false);
}

//+------------------------------------------------------------------+
//| LevelPanelWidth: be rong bang chon muc = 5 cot nut. |
//+------------------------------------------------------------------+
int LevelPanelWidth()
{
   int w = (InpLvlBtnW < 16) ? 16 : InpLvlBtnW;
   int g = (InpTFBtnGap < 0) ? 0 : InpTFBtnGap;
   return(RV2_LVL_COLS * w + (RV2_LVL_COLS - 1) * g);
}

//+------------------------------------------------------------------+
//| RV2_PanelBaseLeftX: MEP TRAI cua ca cum bang.                      |
//|   - Con bat bang chon MUC Pivot -> mep trai cum = mep trai bang do|
//|         xL = x2 - InpLvlPanelGapX - LevelPanelWidth()             |
//|   - Tat bang chon MUC Pivot   -> mep trai cum = mep trai bang nut |
//|         x2 = InpTFPanelX + TFPanelWidth() + InpTFPanelGapX        |
//|   Cong thuc giong LevelPanelX(), viet lai o day de khong goi vong lai |
//|   LevelPanelX() (tranh de quy). Ham chi tinh so px.               |
//+------------------------------------------------------------------+
int RV2_PanelBaseLeftX()
{
   int gapP = (InpTFPanelGapX  < 0) ? 0 : InpTFPanelGapX;
   int gapL = (InpLvlPanelGapX < 0) ? 0 : InpLvlPanelGapX;
   int x2   = InpTFPanelX + TFPanelWidth() + gapP;

   if(!InpShowLevelPanel) return (x2 < 0) ? 0 : x2;

   int xL = x2 - gapL - LevelPanelWidth();
   if(xL < 0) xL = 0;
   return xL;
}

//+------------------------------------------------------------------+
//| RV2_PanelShiftX: DO DICH NGANG dung chung cho CA CUM bang nut     |
//|   (bang chon MUC Pivot + bang chon KHUNG thoi gian + cac bang khac): |
//|   lui ca cum sang SAT CANH TRAI cua chart, tuc dua MEP TRAI cua cum ve x = 0: |
//|       shift = -RV2_PanelBaseLeftX()   (so AM = dich sang trai)    |
//|   Cac bang cong CUNG mot so px nen khoang cach tuong doi giua chung |
//|   (InpLvlPanelGapX, InpTFPanelGapX) khong doi.                     |
//|   Ham CHI TINH so px: KHONG tao object, KHONG ve them duong nao.  |
//+------------------------------------------------------------------+
int RV2_PanelShiftX()
{
   return -RV2_PanelBaseLeftX();
}

//+------------------------------------------------------------------+
//| RV2_ApplyPanelShiftX: cong do dich vao MOT toa do X. |
//|   Goc neo TRAI (CORNER_LEFT_UPPER / CORNER_LEFT_LOWER): XDISTANCE |
//|     do tu MEP TRAI  -> dich sang trai = CONG shift (shift am).    |
//|   Goc neo PHAI (CORNER_RIGHT_UPPER / CORNER_RIGHT_LOWER):         |
//|     XDISTANCE do tu MEP PHAI -> dich sang trai = TRU shift, tuc   |
//|     tang khoang cach so voi mep phai.                             |
//|   Kep >= 0 de bang khong bi day han ra ngoai mep chart.           |
//+------------------------------------------------------------------+
int RV2_ApplyPanelShiftX(const int x)
{
   int  sft        = RV2_PanelShiftX();
   bool leftCorner = (InpTFPanelCorner == CORNER_LEFT_UPPER ||
                      InpTFPanelCorner == CORNER_LEFT_LOWER);
   int  r          = leftCorner ? (x + sft) : (x - sft);
   if(r < 0) r = 0;
   return r;
}

//+------------------------------------------------------------------+
//| LevelPanelX: goc TRAI cua bang chon muc.                          |
//|   Bang chon muc dat NGAY TRUOC (ben trai) bang nut chon khung:    |
//|      x2 = InpTFPanelX + TFPanelWidth() + InpTFPanelGapX  (bang nut khung)|
//|      xL = x2 - InpLvlPanelGapX - LevelPanelWidth()                |
//|   Chart qua hep / InpTFPanelX qua nho -> kep ve 0 de bang khong bi|
//|   day ra ngoai mep trai.                                          |
//+------------------------------------------------------------------+
int LevelPanelX()
{
   int gapP = (InpTFPanelGapX  < 0) ? 0 : InpTFPanelGapX;
   int gapL = (InpLvlPanelGapX < 0) ? 0 : InpLvlPanelGapX;
   int x2   = InpTFPanelX + TFPanelWidth() + gapP;
   int xL   = x2 - gapL - LevelPanelWidth();
   if(xL < 0) xL = 0;

   return RV2_ApplyPanelShiftX(xL);
}

//+------------------------------------------------------------------+
//| CreateLevelPanel: dung bang nut chon MUC Pivot |
//|   19 nut xep 5 cot: PP R1 R2 R3 R4 / R5 R6 R7 R8 R9 /             |
//|   S1 S2 S3 S4 S5 / S6 S7 S8 S9. Chieu cao nut / khe ho / mau chu  |
//|   dung chung setting cua bang nut khung de hai bang thang hang.   |
//+------------------------------------------------------------------+
void CreateLevelPanel()
{
   if(!InpShowTFPanels)   return;
   if(!InpShowLevelPanel) return;

   int w  = (InpLvlBtnW  < 16) ? 16 : InpLvlBtnW;
   int h  = (InpTFBtnH   < 12) ? 12 : InpTFBtnH;
   int g  = (InpTFBtnGap <  0) ?  0 : InpTFBtnGap;
   int xL = LevelPanelX();

   for(int i = 0; i < RV2_LVL_COUNT; i++)
   {
      int col = i % RV2_LVL_COLS;
      int row = i / RV2_LVL_COLS;
      int dx  = col * (w + g);
      int dy  = row * (h + g);

      MakeLevelButton(g_btnLvPrefix + IntegerToString(i), g_lvlName[i],
                      xL + dx, InpTFPanelY + dy, w, h,
                      (i == g_pivotLevelIdx));
   }
}

//+------------------------------------------------------------------+
//| UpdateLevelPanelStates: to lai nen nut theo muc chon. |
//+------------------------------------------------------------------+
void UpdateLevelPanelStates()
{
   if(!InpShowTFPanels)   return;
   if(!InpShowLevelPanel) return;
   for(int i = 0; i < RV2_LVL_COUNT; i++)
   {
      string nmL = g_btnLvPrefix + IntegerToString(i);
      if(ObjectFind(0, nmL) >= 0)
      {
         ObjectSetInteger(0, nmL, OBJPROP_BGCOLOR,
                          (i == g_pivotLevelIdx) ? InpLvlBtnBgSel : InpTFBtnBg);
         ObjectSetInteger(0, nmL, OBJPROP_STATE, false);
      }
   }
}

//+------------------------------------------------------------------+
//| RowTfPanelY: dong dau cua bang check box khung = NGAY TREN bang chon muc Pivot:                      |
//|   yTop = InpTFPanelY - so hang * (h+g) (hang cuoi cach bang chon muc dung 1 khe ho g). Kep >= 0.    |
//+------------------------------------------------------------------+
int RowTfPanelY()
{
   int h  = (InpTFBtnH   < 12) ? 12 : InpTFBtnH;
   int g  = (InpTFBtnGap <  0) ?  0 : InpTFBtnGap;
   int rows = (RV2_TF_COUNT + RV2_ROWTF_COLS - 1) / RV2_ROWTF_COLS;
   int y = InpTFPanelY - rows * (h + g);
   return (y < 0) ? 0 : y;
}

//+------------------------------------------------------------------+
//| OW MODE UI: 3 nut "LWMA" / "EMA" / "EMA(LWMA)" chon cach tinh OW (g_aptOwMode, xem AptOpenEmaSeries()).                 |
//|   Dat NGAY TREN bang check box khung (CreateRowTfPanel()): yOw = RowTfPanelY() - (h + g), kep >= 0.                   |
//|   Dung chung xL = LevelPanelX() va be rong LevelPanelWidth(); 2 nut dau moi nut 30%, nut "EMA(LWMA)" lay phan con lai  |
//|   (chu dai hon). Dung MakeLevelButton(); nut DANG CHON to nen InpLvlBtnBgSel. Chi hien khi InpShowTFPanels va           |
//|   InpShowLevelPanel deu bat. Chi tao OBJ_BUTTON (prefix g_btnOwModePrefix).                                           |
//+------------------------------------------------------------------+
int OwModePanelY()
{
   int h = (InpTFBtnH   < 12) ? 12 : InpTFBtnH;
   int g = (InpTFBtnGap <  0) ?  0 : InpTFBtnGap;
   int y = RowTfPanelY() - (h + g);
   return (y < 0) ? 0 : y;
}

void CreateOwModePanel()
{
   if(!InpShowTFPanels)   return;
   if(!InpShowLevelPanel) return;

   int h  = (InpTFBtnH   < 12) ? 12 : InpTFBtnH;
   int g  = (InpTFBtnGap <  0) ?  0 : InpTFBtnGap;
   int xL = LevelPanelX();
   int yO = OwModePanelY();

   int fullW = LevelPanelWidth();
   int wA    = (int)((fullW - 2 * g) * 0.3);
   if(wA < 16) wA = 16;
   int wC    = fullW - 2 * g - 2 * wA;
   if(wC < 16) wC = 16;

   int xPos = xL;
   for(int i = 0; i < APT_OW_MODE_COUNT; i++)
   {
      int w = (i == APT_OW_MODE_COUNT - 1) ? wC : wA;
      string nmO = g_btnOwModePrefix + IntegerToString(i);
      MakeLevelButton(nmO, g_aptOwModeLbl[i], xPos, yO, w, h, (i == g_aptOwMode));
      ObjectSetString(0, nmO, OBJPROP_TOOLTIP, "Cach tinh OW: " + g_aptOwModeLbl[i] + "(Open, B<n>)");
      xPos += w + g;
   }
}

//+------------------------------------------------------------------+
//| UpdateOwModePanelStates: to lai nen 3 nut OW MODE UI theo che do dang chon. Chi doi PROPERTY, khong tao/xoa object. |
//+------------------------------------------------------------------+
void UpdateOwModePanelStates()
{
   if(!InpShowTFPanels)   return;
   if(!InpShowLevelPanel) return;

   for(int i = 0; i < APT_OW_MODE_COUNT; i++)
   {
      string nmO = g_btnOwModePrefix + IntegerToString(i);
      if(ObjectFind(0, nmO) >= 0)
      {
         ObjectSetInteger(0, nmO, OBJPROP_BGCOLOR, (i == g_aptOwMode) ? InpLvlBtnBgSel : InpTFBtnBg);
         ObjectSetInteger(0, nmO, OBJPROP_STATE, false);
      }
   }
}

//+------------------------------------------------------------------+
//| CreateRowTfPanel: bang CHECK BOX chon khung hien hang trong nhan Pivot / RV1 / RV2.                   |
//|   14 nut (1m..1nm) xep 4 cot, cung xL = LevelPanelX() va be rong LevelPanelWidth() voi bang muc Pivot.|
//|   "[x]" + nen InpLvlBtnBgSel = dang HIEN, "[ ]" + nen thuong = dang AN. Chi tao OBJ_BUTTON (prefix     |
//|   g_btnRowTfPrefix). Chi hien khi InpShowTFPanels va InpShowLevelPanel deu bat.                      |
//+------------------------------------------------------------------+
void CreateRowTfPanel()
{
   if(!InpShowTFPanels)   return;
   if(!InpShowLevelPanel) return;

   int h  = (InpTFBtnH   < 12) ? 12 : InpTFBtnH;
   int g  = (InpTFBtnGap <  0) ?  0 : InpTFBtnGap;
   int xL = LevelPanelX();
   int yT = RowTfPanelY();

   int fullW = LevelPanelWidth();
   int wC    = (fullW - (RV2_ROWTF_COLS - 1) * g) / RV2_ROWTF_COLS;
   if(wC < 16) wC = 16;

   for(int i = 0; i < RV2_TF_COUNT; i++)
   {
      int col = i % RV2_ROWTF_COLS;
      int row = i / RV2_ROWTF_COLS;

      MakeLevelButton(g_btnRowTfPrefix + IntegerToString(i),
                      (g_tfRowShow[i] ? "[x]" : "[ ]") + g_tfLabel[i],
                      xL + col * (wC + g), yT + row * (h + g), wC, h,
                      g_tfRowShow[i]);
   }
}

//+------------------------------------------------------------------+
//| UpdateRowTfPanelStates: doi chu "[x]"/"[ ]" va nen nut theo g_tfRowShow[]. Chi doi PROPERTY, khong tao/xoa object. |
//+------------------------------------------------------------------+
void UpdateRowTfPanelStates()
{
   if(!InpShowTFPanels)   return;
   if(!InpShowLevelPanel) return;

   for(int i = 0; i < RV2_TF_COUNT; i++)
   {
      string nmR = g_btnRowTfPrefix + IntegerToString(i);
      if(ObjectFind(0, nmR) >= 0)
      {
         ObjectSetString (0, nmR, OBJPROP_TEXT, (g_tfRowShow[i] ? "[x]" : "[ ]") + g_tfLabel[i]);
         ObjectSetInteger(0, nmR, OBJPROP_BGCOLOR, g_tfRowShow[i] ? InpLvlBtnBgSel : InpTFBtnBg);
         ObjectSetInteger(0, nmR, OBJPROP_STATE, false);
      }
   }
}

//+------------------------------------------------------------------+
//| CreatePivotModePanel: bang 2 nut "TenMuc" / "BangUI" chon nguon MUC Pivot dung de VE nhan/duong EMA Pivot cua tung khung trong |
//|   DrawWoodiePivotEma() - xem bien g_pivotFollowDisplayedLvl khai bao canh g_pivotLevelIdx. Dat NGAY SAT DUOI bang chon muc Pivot (19 nut, |
//|   CreateLevelPanel()): dung chung xL = LevelPanelX() va be rong LevelPanelWidth() (chia doi cho 2 nut); dong dau (yMode) = lvlRows*(h+g) |
//|   voi lvlRows = ceil(RV2_LVL_COUNT / RV2_LVL_COLS). Dung MakeLevelButton() nen mau/co chu/vien giong 19 nut kia; nut dang CHON to nen InpLvlBtnBgSel. |
//|   Chi hien khi InpShowTFPanels va InpShowLevelPanel deu bat (cung dieu kien CreateLevelPanel()). Chi tao 2 OBJ_BUTTON (prefix g_btnPvModePrefix). |
//+------------------------------------------------------------------+
void CreatePivotModePanel()
{
   if(!InpShowTFPanels)   return;
   if(!InpShowLevelPanel) return;

   int h  = (InpTFBtnH   < 12) ? 12 : InpTFBtnH;
   int g  = (InpTFBtnGap <  0) ?  0 : InpTFBtnGap;
   int xL = LevelPanelX();

   // So hang THAT SU cua bang 19 nut Pivot (CreateLevelPanel()), lam tron len:
   //   (19 + 5 - 1) / 5 = 4 hang (dung DUNG so hang ma vong lap i/RV2_LVL_COLS
   //   cua CreateLevelPanel() dang tao ra, khong hard-code so 4).
   int lvlRows = (RV2_LVL_COUNT + RV2_LVL_COLS - 1) / RV2_LVL_COLS;
   int yMode   = InpTFPanelY + lvlRows * (h + g);

   int fullW = LevelPanelWidth();
   int wMode = (fullW - g) / 2;
   if(wMode < 16) wMode = 16;

   MakeLevelButton(g_btnPvModePrefix + "0", "TenMuc",
                   xL,             yMode, wMode, h,
                   !g_pivotFollowDisplayedLvl);
   MakeLevelButton(g_btnPvModePrefix + "1", "BangUI",
                   xL + wMode + g, yMode, wMode, h,
                   g_pivotFollowDisplayedLvl);
}

//+------------------------------------------------------------------+
//| UpdatePivotModePanelStates: to lai|
//|   nen 2 nut "TenMuc"/"BangUI" theo che do dang chon. CHI doi       |
//|   PROPERTY cua object da ton tai: khong tao/khong xoa object nao,  |
//|   dung Y HET khuon mau UpdateLevelPanelStates().|
//+------------------------------------------------------------------+
void UpdatePivotModePanelStates()
{
   if(!InpShowTFPanels)   return;
   if(!InpShowLevelPanel) return;

   string nmMode0 = g_btnPvModePrefix + "0";
   if(ObjectFind(0, nmMode0) >= 0)
   {
      ObjectSetInteger(0, nmMode0, OBJPROP_BGCOLOR,
                       (!g_pivotFollowDisplayedLvl) ? InpLvlBtnBgSel : InpTFBtnBg);
      ObjectSetInteger(0, nmMode0, OBJPROP_STATE, false);
   }

   string nmMode1 = g_btnPvModePrefix + "1";
   if(ObjectFind(0, nmMode1) >= 0)
   {
      ObjectSetInteger(0, nmMode1, OBJPROP_BGCOLOR,
                       g_pivotFollowDisplayedLvl ? InpLvlBtnBgSel : InpTFBtnBg);
      ObjectSetInteger(0, nmMode1, OBJPROP_STATE, false);
   }
}

//+------------------------------------------------------------------+
//| Pe UI: bang nut chon CHU KY RSI (Pe), dat NGAY DUOI bang nut     |
//|   "TenMuc"/"BangUI" (CreatePivotModePanel()). Mot Pe UI gan cung   |
//|   mot gia tri cho CA HAI bien APT_S1_RSI_PERIOD va                 |
//|   WOODIE_RSI_PERIOD khi nguoi dung bam chon (xem OnChartEvent()).  |
//|   8 nut gia tri: 5/9/14/21/30/35/40/50, mac dinh 5 (nut dau tien,  |
//|   g_aptRsiPeIdx khoi tao = 0).                                     |
//|   Dung chung xL = LevelPanelX() va be rong LevelPanelWidth() voi   |
//|   bang chon MUC Pivot/bang "TenMuc"/"BangUI" (chia deu cho 4 cot); |
//|   dong dau (yPe) ngay duoi bang "TenMuc"/"BangUI". Dung MakeLevelButton(). |
//|   Chi hien khi InpShowTFPanels va InpShowLevelPanel deu bat (cung dieu |
//|   kien CreatePivotModePanel()). Chi tao OBJ_BUTTON (prefix g_btnRsiPePrefix). |
//+------------------------------------------------------------------+
#define APT_RSI_PE_COUNT 8
#define APT_RSI_PE_COLS  4
int    g_aptRsiPeVals[APT_RSI_PE_COUNT] = {5,9,14,21,30,35,40,50};
string g_btnRsiPePrefix = "RV2_RSIPEBTN_";
int    g_aptRsiPeIdx    = 0;   // chi so dang chon trong g_aptRsiPeVals[], mac dinh 0 (Pe=5)

//+------------------------------------------------------------------+
//| RsiPePanelY: dong dau cua Pe UI, ngay duoi bang "TenMuc"/"BangUI": |
//|   cong thuc yMode cua CreatePivotModePanel() cong them mot hang    |
//|   (h+g), viet lai o day de khong goi vong lai CreatePivotModePanel() |
//|   (ham do chi VE, khong TRA VE toa do).                            |
//+------------------------------------------------------------------+
int RsiPePanelY()
{
   int h  = (InpTFBtnH   < 12) ? 12 : InpTFBtnH;
   int g  = (InpTFBtnGap <  0) ?  0 : InpTFBtnGap;

   int lvlRows = (RV2_LVL_COUNT + RV2_LVL_COLS - 1) / RV2_LVL_COLS;
   int yMode   = InpTFPanelY + lvlRows * (h + g);
   return(yMode + h + g);
}

//+------------------------------------------------------------------+
//| CreateRsiPePanel: dung bang nut chon |
//|   Pe (chu ky RSI) - 8 nut xep 4 cot: 5 9 14 21 / 30 35 40 50.      |
//+------------------------------------------------------------------+
void CreateRsiPePanel()
{
   if(!InpShowTFPanels)   return;
   if(!InpShowLevelPanel) return;

   int h  = (InpTFBtnH   < 12) ? 12 : InpTFBtnH;
   int g  = (InpTFBtnGap <  0) ?  0 : InpTFBtnGap;
   int xL = LevelPanelX();
   int yP = RsiPePanelY();

   int fullW = LevelPanelWidth();
   int wPe   = (fullW - (APT_RSI_PE_COLS - 1) * g) / APT_RSI_PE_COLS;
   if(wPe < 16) wPe = 16;

   for(int i = 0; i < APT_RSI_PE_COUNT; i++)
   {
      int col = i % APT_RSI_PE_COLS;
      int row = i / APT_RSI_PE_COLS;
      int dx  = col * (wPe + g);
      int dy  = row * (h + g);

      MakeLevelButton(g_btnRsiPePrefix + IntegerToString(i), IntegerToString(g_aptRsiPeVals[i]),
                      xL + dx, yP + dy, wPe, h,
                      (i == g_aptRsiPeIdx));
   }
}

//+------------------------------------------------------------------+
//| UpdateRsiPePanelStates: to lai nen |
//|   cac nut Pe theo chu ky dang chon. CHI doi PROPERTY cua object da |
//|   ton tai: khong tao/khong xoa object nao.                         |
//+------------------------------------------------------------------+
void UpdateRsiPePanelStates()
{
   if(!InpShowTFPanels)   return;
   if(!InpShowLevelPanel) return;

   for(int i = 0; i < APT_RSI_PE_COUNT; i++)
   {
      string nmP = g_btnRsiPePrefix + IntegerToString(i);
      if(ObjectFind(0, nmP) >= 0)
      {
         ObjectSetInteger(0, nmP, OBJPROP_BGCOLOR,
                          (i == g_aptRsiPeIdx) ? InpLvlBtnBgSel : InpTFBtnBg);
         ObjectSetInteger(0, nmP, OBJPROP_STATE, false);
      }
   }
}

//+------------------------------------------------------------------+
//| RV2 EMA UI: bang nut chon CHU KY EMA |
//|   ra RV2 (RV2 = EMA(chu ky) ap len chuoi RV1) - 5 nut 5/10/20/50/200   |
//|   xep MOT HANG, dat NGAY SAT DUOI Pe UI (bang nut chon chu ky RSI).|
//|   Rv2EmaPanelY: dong dau = RsiPePanelY() + so hang THAT SU cua Pe  |
//|   UI (ceil(APT_RSI_PE_COUNT / APT_RSI_PE_COLS) hang) nhan (h+g).   |
//|   Dung CHUNG xL = LevelPanelX() va be rong LevelPanelWidth() voi   |
//|   cac bang tren, 4 cot chia deu. Dung LAI MakeLevelButton() (KHONG |
//|   doi). Bang nay CHI hien khi InpShowTFPanels va InpShowLevelPanel |
//|   deu bat - dung dieu kien cua Pe UI. CHI tao OBJ_BUTTON (prefix   |
//|   rieng g_btnRv2EmaPrefix): KHONG ve them duong line nao, KHONG    |
//|   doi setting/input nao da co.                                      |
//+------------------------------------------------------------------+
int Rv2EmaPanelY()
{
   int h  = (InpTFBtnH   < 12) ? 12 : InpTFBtnH;
   int g  = (InpTFBtnGap <  0) ?  0 : InpTFBtnGap;

   int peRows = (APT_RSI_PE_COUNT + APT_RSI_PE_COLS - 1) / APT_RSI_PE_COLS;
   return(RsiPePanelY() + peRows * (h + g));
}

void CreateRv2EmaPanel()
{
   if(!InpShowTFPanels)   return;
   if(!InpShowLevelPanel) return;

   int h  = (InpTFBtnH   < 12) ? 12 : InpTFBtnH;
   int g  = (InpTFBtnGap <  0) ?  0 : InpTFBtnGap;
   int xL = LevelPanelX();
   int yP = Rv2EmaPanelY();

   int fullW = LevelPanelWidth();
   int wE    = (fullW - (APT_RV2EMA_COLS - 1) * g) / APT_RV2EMA_COLS;
   if(wE < 16) wE = 16;

   for(int i = 0; i < APT_RV2EMA_COUNT; i++)
   {
      int col = i % APT_RV2EMA_COLS;
      int row = i / APT_RV2EMA_COLS;
      int dx  = col * (wE + g);
      int dy  = row * (h + g);

      MakeLevelButton(g_btnRv2EmaPrefix + IntegerToString(i), IntegerToString(g_aptRv2EmaVals[i]),
                      xL + dx, yP + dy, wE, h,
                      (i == g_aptRv2EmaIdx));
   }

   int yB = Rv2BrkDPanelY();
   for(int j = 0; j < APT_BRKDUI_COUNT; j++)
   {
      int dxj = (j % APT_RV2EMA_COLS) * (wE + g);
      MakeLevelButton(g_btnBrkDPrefix + IntegerToString(j), "B" + IntegerToString(g_aptBrkDBarsVals[j]),
                      xL + dxj, yB, wE, h, (j == g_aptBrkDBarsIdx));
   }
   int yT = Rv2BrkDTfPanelY();
   for(int t = 0; t < APT_BRKDTF_COUNT; t++)
      MakeLevelButton(g_btnBrkDTfPrefix + IntegerToString(t), g_tfLabel[t],
                      xL + (t % APT_RV2EMA_COLS) * (wE + g), yT + (t / APT_RV2EMA_COLS) * (h + g), wE, h, (t == g_aptBrkDTfIdx));
}

//+------------------------------------------------------------------+
//| UpdateRv2EmaPanelStates: to lai nen |
//|   cac nut RV2 EMA theo chu ky dang chon. CHI doi PROPERTY cua      |
//|   object da ton tai: khong tao/khong xoa object nao.               |
//+------------------------------------------------------------------+
void UpdateRv2EmaPanelStates()
{
   if(!InpShowTFPanels)   return;
   if(!InpShowLevelPanel) return;

   for(int i = 0; i < APT_RV2EMA_COUNT; i++)
   {
      string nmE = g_btnRv2EmaPrefix + IntegerToString(i);
      if(ObjectFind(0, nmE) >= 0)
      {
         ObjectSetInteger(0, nmE, OBJPROP_BGCOLOR,
                          (i == g_aptRv2EmaIdx) ? InpLvlBtnBgSel : InpTFBtnBg);
         ObjectSetInteger(0, nmE, OBJPROP_STATE, false);
      }
   }

   for(int j = 0; j < APT_BRKDUI_COUNT; j++)
   {
      string nmB = g_btnBrkDPrefix + IntegerToString(j);
      if(ObjectFind(0, nmB) >= 0)
      {
         ObjectSetInteger(0, nmB, OBJPROP_BGCOLOR, (j == g_aptBrkDBarsIdx) ? InpLvlBtnBgSel : InpTFBtnBg);
         ObjectSetInteger(0, nmB, OBJPROP_STATE, false);
      }
   }
   for(int j = 0; j < APT_BRKDTF_COUNT; j++)
   {
      string nmT = g_btnBrkDTfPrefix + IntegerToString(j);   // hang chon khung HH/LL
      if(ObjectFind(0, nmT) >= 0)
      {
         ObjectSetInteger(0, nmT, OBJPROP_BGCOLOR, (j == g_aptBrkDTfIdx) ? InpLvlBtnBgSel : InpTFBtnBg);
         ObjectSetInteger(0, nmT, OBJPROP_STATE, false);
      }
   }
}

//+------------------------------------------------------------------+
//| Close Simple UI: bang nut chon PERIOD |
//|   Close Simple (5/10/20/50/200, mac dinh 200), dat NGAY SAT DUOI    |
//|   RV2 EMA UI. CsmaPanelY: dong dau = Rv2EmaPanelY() + so hang THAT  |
//|   SU cua RV2 EMA UI nhan (h+g). Dung CHUNG xL = LevelPanelX() va    |
//|   be rong LevelPanelWidth(), dung LAI MakeLevelButton() (KHONG doi).|
//|   Hien khi InpShowTFPanels va InpShowLevelPanel deu bat (cung dieu  |
//|   kien RV2 EMA UI). CHI tao OBJ_BUTTON (prefix rieng               |
//|   g_btnCsmaPrefix): KHONG ve them duong line nao, KHONG doi         |
//|   setting/input nao da co.                                          |
//+------------------------------------------------------------------+
// Hang nut brkD ("B<n>") nam NGAY DUOI hang nut RV2 EMA; hang nut RSI cua brkD ("R<n>") nam duoi hang brkD.
int Rv2BrkDPanelY()
{
   int h  = (InpTFBtnH   < 12) ? 12 : InpTFBtnH;
   int g  = (InpTFBtnGap <  0) ?  0 : InpTFBtnGap;
   int emaRows = (APT_RV2EMA_COUNT + APT_RV2EMA_COLS - 1) / APT_RV2EMA_COLS;
   return(Rv2EmaPanelY() + emaRows * (h + g));
}

int Rv2BrkDTfPanelY()
{
   int h  = (InpTFBtnH   < 12) ? 12 : InpTFBtnH;
   int g  = (InpTFBtnGap <  0) ?  0 : InpTFBtnGap;
   return(Rv2BrkDPanelY() + (h + g));
}

int CsmaPanelY()
{
   int h  = (InpTFBtnH   < 12) ? 12 : InpTFBtnH;
   int g  = (InpTFBtnGap <  0) ?  0 : InpTFBtnGap;

   int brkTfRows = (APT_BRKDTF_COUNT + APT_RV2EMA_COLS - 1) / APT_RV2EMA_COLS;
   return(Rv2BrkDTfPanelY() + brkTfRows * (h + g));
}

void CreateCsmaPanel()
{
   if(!InpShowTFPanels)   return;
   if(!InpShowLevelPanel) return;

   int h  = (InpTFBtnH   < 12) ? 12 : InpTFBtnH;
   int g  = (InpTFBtnGap <  0) ?  0 : InpTFBtnGap;
   int xL = LevelPanelX();
   int yP = CsmaPanelY();

   int fullW = LevelPanelWidth();
   int wE    = (fullW - (APT_CSMA_COLS - 1) * g) / APT_CSMA_COLS;
   if(wE < 16) wE = 16;

   for(int i = 0; i < APT_CSMA_COUNT; i++)
   {
      int col = i % APT_CSMA_COLS;
      int row = i / APT_CSMA_COLS;
      int dx  = col * (wE + g);
      int dy  = row * (h + g);

      MakeLevelButton(g_btnCsmaPrefix + IntegerToString(i), IntegerToString(g_aptCsmaVals[i]),
                      xL + dx, yP + dy, wE, h,
                      (i == g_aptCsmaIdx));
   }
}

//+------------------------------------------------------------------+
//| UpdateCsmaPanelStates: to lai nen cac |
//|   nut Close Simple UI theo period dang chon. CHI doi PROPERTY cua   |
//|   object da ton tai: khong tao/khong xoa object nao.                |
//+------------------------------------------------------------------+
void UpdateCsmaPanelStates()
{
   if(!InpShowTFPanels)   return;
   if(!InpShowLevelPanel) return;

   for(int i = 0; i < APT_CSMA_COUNT; i++)
   {
      string nmC = g_btnCsmaPrefix + IntegerToString(i);
      if(ObjectFind(0, nmC) >= 0)
      {
         ObjectSetInteger(0, nmC, OBJPROP_BGCOLOR,
                          (i == g_aptCsmaIdx) ? InpLvlBtnBgSel : InpTFBtnBg);
         ObjectSetInteger(0, nmC, OBJPROP_STATE, false);
      }
   }
}

//+------------------------------------------------------------------+
//| LAM TRON UI: hang 1 = 3 nut chon muc |
//|   lam tron (1000 / 100 / 10), hang 2 = o nhap PHAM VI tim kiem (mac   |
//|   dinh 50). Dat NGAY SAT DUOI Close Simple UI (cung xL va be rong |
//|   LevelPanelWidth()). Dung cho <lamtron> tren nhan Pivot (xem         |
//|   AptRoundNearStr()). CHI tao 3 OBJ_BUTTON + 1 OBJ_EDIT (prefix        |
//|   rieng): KHONG ve line, KHONG doi setting/input nao da co.           |
//+------------------------------------------------------------------+
void CreateRndPanel()
{
   if(!InpShowTFPanels)   return;
   if(!InpShowLevelPanel) return;

   int h  = (InpTFBtnH   < 12) ? 12 : InpTFBtnH;
   int g  = (InpTFBtnGap <  0) ?  0 : InpTFBtnGap;
   int xL = LevelPanelX();
   int yP = CsmaPanelY() + (h + g);   // ngay duoi Close Simple UI

   int fullW = LevelPanelWidth();
   // [GIU NGUYEN - KHONG XOA] int wB    = (fullW - 3 * g) / 4;
   int wB    = (fullW - 4 * g) / 5;   // 4 nut muc lam tron + nut "KC"
   if(wB < 16) wB = 16;

   for(int i = 0; i < 4; i++)
   {
      string nmB = g_btnRndPrefix + IntegerToString(i);
      MakeLevelButton(nmB, g_aptRndLbl[i], xL + i * (wB + g), yP, wB, h, (i == g_aptRndIdx));
      ObjectSetString(0, nmB, OBJPROP_TOOLTIP, (i == 3) ? "Lam tron theo hang don vi la 5 (4195, 4205, 4215...) cho <lamtron> tren nhan Pivot (R2-R9 / S2-S9)"
                                                         : "Muc lam tron cho <lamtron> tren nhan Pivot (R2-R9 / S2-S9)");
   }
   MakeLevelButton(g_btnRndGapName, "KC", xL + 4 * (wB + g), yP, wB, h, g_aptRndGap);
   ObjectSetString(0, g_btnRndGapName, OBJPROP_TOOLTIP, "Khoang cach: bat -> nhan lam tron chi ve muc le cua buoc (vd buoc 10: 4170, 4190, bo 4180)");

   string nmE = g_edtRndPrefix + "VAL";
   if(ObjectFind(0, nmE) < 0)
      ObjectCreate(0, nmE, OBJ_EDIT, 0, 0, 0);
   ObjectSetInteger(0, nmE, OBJPROP_CORNER,       InpTFPanelCorner);
   ObjectSetInteger(0, nmE, OBJPROP_XDISTANCE,    xL);
   ObjectSetInteger(0, nmE, OBJPROP_YDISTANCE,    yP + (h + g));
   ObjectSetInteger(0, nmE, OBJPROP_XSIZE,        fullW);
   ObjectSetInteger(0, nmE, OBJPROP_YSIZE,        h);
   ObjectSetString (0, nmE, OBJPROP_TEXT,         g_aptRndRangeTxt);
   ObjectSetString (0, nmE, OBJPROP_TOOLTIP,      "Pham vi tim kiem gia tri lam tron (don vi gia)");
   ObjectSetString (0, nmE, OBJPROP_FONT,         "Arial");
   ObjectSetInteger(0, nmE, OBJPROP_FONTSIZE,     (InpTFBtnFontSize < 6) ? 6 : InpTFBtnFontSize);
   ObjectSetInteger(0, nmE, OBJPROP_COLOR,        InpTFBtnTextCol);
   ObjectSetInteger(0, nmE, OBJPROP_BGCOLOR,      InpTFBtnBg);
   ObjectSetInteger(0, nmE, OBJPROP_BORDER_COLOR, clrSilver);
   ObjectSetInteger(0, nmE, OBJPROP_ALIGN,        ALIGN_CENTER);
   ObjectSetInteger(0, nmE, OBJPROP_READONLY,     false);
   ObjectSetInteger(0, nmE, OBJPROP_SELECTABLE,   false);
   ObjectSetInteger(0, nmE, OBJPROP_HIDDEN,       true);
   ObjectSetInteger(0, nmE, OBJPROP_BACK,         false);
}

void UpdateRndPanelStates()
{
   if(!InpShowTFPanels)   return;
   if(!InpShowLevelPanel) return;

   for(int i = 0; i < 4; i++)
   {
      string nmB = g_btnRndPrefix + IntegerToString(i);
      if(ObjectFind(0, nmB) >= 0)
      {
         ObjectSetInteger(0, nmB, OBJPROP_BGCOLOR, (i == g_aptRndIdx) ? InpLvlBtnBgSel : InpTFBtnBg);
         ObjectSetInteger(0, nmB, OBJPROP_STATE,   false);
      }
   }
   if(ObjectFind(0, g_btnRndGapName) >= 0)
   {
      ObjectSetInteger(0, g_btnRndGapName, OBJPROP_BGCOLOR, g_aptRndGap ? InpLvlBtnBgSel : InpTFBtnBg);
      ObjectSetInteger(0, g_btnRndGapName, OBJPROP_STATE,   false);
   }
}

//+------------------------------------------------------------------+
//| CreateDxyPanel: o nhap SYMBOL DXY (OBJ_EDIT, ten g_edtDxyPrefix + "SYM"), dat NGAY DUOI o nhap pham vi cua LAM TRON UI,         |
//|   cung xL = LevelPanelX() va be rong LevelPanelWidth(). Nhap ten symbol roi Enter -> g_dxySym doi, cot Pattern ve lai.         |
//|   Hien khi InpShowTFPanels va InpShowLevelPanel deu bat (cung dieu kien LAM TRON UI). Chi tao 1 OBJ_EDIT, khong ve line.       |
//+------------------------------------------------------------------+
void CreateDxyPanel()
{
   if(!InpShowTFPanels)   return;
   if(!InpShowLevelPanel) return;

   int h  = (InpTFBtnH   < 12) ? 12 : InpTFBtnH;
   int g  = (InpTFBtnGap <  0) ?  0 : InpTFBtnGap;
   int xL = LevelPanelX();
   int yP = CsmaPanelY() + (h + g);   // hang nut LAM TRON (cung cong thuc CreateRndPanel())
   int yD = yP + 2 * (h + g);         // ngay duoi o nhap pham vi LAM TRON

   int fullW = LevelPanelWidth();

   string nmD = g_edtDxyPrefix + "SYM";
   if(ObjectFind(0, nmD) < 0)
      ObjectCreate(0, nmD, OBJ_EDIT, 0, 0, 0);
   ObjectSetInteger(0, nmD, OBJPROP_CORNER,       InpTFPanelCorner);
   ObjectSetInteger(0, nmD, OBJPROP_XDISTANCE,    xL);
   ObjectSetInteger(0, nmD, OBJPROP_YDISTANCE,    yD);
   ObjectSetInteger(0, nmD, OBJPROP_XSIZE,        fullW);
   ObjectSetInteger(0, nmD, OBJPROP_YSIZE,        h);
   ObjectSetString (0, nmD, OBJPROP_TEXT,         g_dxySym);
   ObjectSetString (0, nmD, OBJPROP_TOOLTIP,      "Symbol DXY (ten dung nhu Market Watch) - <TenMuc> DXY hien sau <TF> o cot Pattern");
   ObjectSetString (0, nmD, OBJPROP_FONT,         "Arial");
   ObjectSetInteger(0, nmD, OBJPROP_FONTSIZE,     (InpTFBtnFontSize < 6) ? 6 : InpTFBtnFontSize);
   ObjectSetInteger(0, nmD, OBJPROP_COLOR,        InpTFBtnTextCol);
   ObjectSetInteger(0, nmD, OBJPROP_BGCOLOR,      InpTFBtnBg);
   ObjectSetInteger(0, nmD, OBJPROP_BORDER_COLOR, clrSilver);
   ObjectSetInteger(0, nmD, OBJPROP_ALIGN,        ALIGN_CENTER);
   ObjectSetInteger(0, nmD, OBJPROP_READONLY,     false);
   ObjectSetInteger(0, nmD, OBJPROP_SELECTABLE,   false);
   ObjectSetInteger(0, nmD, OBJPROP_HIDDEN,       true);
   ObjectSetInteger(0, nmD, OBJPROP_BACK,         false);
}

//--- Du lieu OW / chieu cho NHAN GIA GIUA (MidOwRefresh()), lam moi toi da 1 lan / giay (OW doi theo nen DA DONG, khong can tinh moi tick):
//      KHUNG = khung dang sang o bang nut chon khung 1m..1nm (g_aptBrkDTfIdx, AptExtraLineTf()); bang tat (idx = -1) -> khong co du lieu.
//      g_midOwVal = OW khung do (AptOpenLwma()); g_midOwDir = +1 khi Pivot ema (muc chon o bang Pivot UI, khung do) >= OW, -1 khi < OW, 0 = thieu du lieu.
double   g_midOwVal  = 0.0;   // OW khung dang sang (0 = chua co)
int      g_midOwDir  = 0;     // +1 = Pivot ema >= OW (tam giac tang), -1 = Pivot < OW (tam giac giam), 0 = thieu du lieu / bang khung dang tat
datetime g_midOwLast = 0;     // TimeCurrent() cua lan lam moi truoc
int      g_midOwKey  = -1;    // khoa (khung UI, muc Pivot UI, chu ky + che do OW): doi -> lam moi ngay

//+------------------------------------------------------------------+
//| MidOwRefresh: cap nhat g_midOwVal / g_midOwDir theo khung dang sang o bang nut 1m..1nm.                  |
//|   Thieu Pivot / OW / bang khung tat -> g_midOwVal = 0, g_midOwDir = 0. Chi doc gia.                         |
//+------------------------------------------------------------------+
void MidOwRefresh()
{
   ENUM_TIMEFRAMES tf = PERIOD_CURRENT;
   if(!AptExtraLineTf(tf))
   {
      g_midOwVal = 0.0;
      g_midOwDir = 0;
      g_midOwKey = -1;
      return;
   }

   int nOw = g_aptBrkDBars;
   if(nOw < 2)   nOw = 2;
   if(nOw > 500) nOw = 500;
   int      key = (g_aptBrkDTfIdx * 100 + g_pivotLevelIdx) * 10000 + AptOwModeKey(nOw);
   datetime now = TimeCurrent();
   if(key == g_midOwKey && now == g_midOwLast)
      return;
   g_midOwKey  = key;
   g_midOwLast = now;

   double pvSer[];
   double pv = 0.0;
   if(AptPivotUiEmaSeries(tf, 3, pvSer) > 0)
      pv = pvSer[0];
   double ow = 0.0;
   if(!AptOpenLwma(tf, nOw, ow) || !(ow > 0.0))
   {
      g_midOwVal = 0.0;
      g_midOwDir = 0;
      return;
   }
   g_midOwVal = ow;
   g_midOwDir = (pv > 0.0) ? ((pv >= ow) ? 1 : -1) : 0;
}

//+------------------------------------------------------------------+
//| MidLblPut: tao / cap nhat 1 OBJ_TEXT (neo ANCHOR_LEFT) cua nhan gia giua. Chi doi thuoc tinh khi gia tri thuc su khac.   |
//+------------------------------------------------------------------+
void MidLblPut(const string nm, const datetime t, const double px, const string txt, const color clr, const int fs, const string tip)
{
   if(ObjectFind(0, nm) < 0)
     {
      ObjectCreate(0, nm, OBJ_TEXT, 0, t, px);
      ObjectSetString (0, nm, OBJPROP_FONT,       InpFontName);
      ObjectSetInteger(0, nm, OBJPROP_FONTSIZE,   fs);
      ObjectSetInteger(0, nm, OBJPROP_COLOR,      clr);
      ObjectSetInteger(0, nm, OBJPROP_ANCHOR,     ANCHOR_LEFT);
      ObjectSetInteger(0, nm, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, nm, OBJPROP_HIDDEN,     true);
      ObjectSetInteger(0, nm, OBJPROP_BACK,       false);
      ObjectSetString (0, nm, OBJPROP_TOOLTIP,    tip);
      ObjectSetString (0, nm, OBJPROP_TEXT,       txt);
      return;
     }
   if((datetime)ObjectGetInteger(0, nm, OBJPROP_TIME) != t || ObjectGetDouble(0, nm, OBJPROP_PRICE) != px)
      ObjectMove(0, nm, 0, t, px);
   if(ObjectGetString(0, nm, OBJPROP_TEXT) != txt)
      ObjectSetString(0, nm, OBJPROP_TEXT, txt);
   if((int)ObjectGetInteger(0, nm, OBJPROP_FONTSIZE) != fs)
      ObjectSetInteger(0, nm, OBJPROP_FONTSIZE, fs);
}

//+------------------------------------------------------------------+
//| DrawMidPriceLabel: NHAN GIA GIUA (Bid + Ask)/2 (hang 1, tai gia giua) + COT <TF> <RV1W%>/<RV2W%> <PivotW%> [<brkD>(<streak>)<SigBrk>] <(Bid - Open)/spread> <SpR2>/<SpR1> <diffavg> (hang 2..15) xep xuong duoi NHAN RV1 KHUNG 1m (cung moc thoi gian g_rv1M1LblT,  |
//|   cung co chu, cach nhau (co chu RV1 1m + 7) pixel; hang 2 ngay duoi nhan RV1 1m). Chua co nhan RV1 1m -> khong ve cot. Cac dong mo ta ben duoi ghi "hang 2..14 xep xuong duoi hang 1" la ban cu (nay hang 2..15, 14 khung).  |
//|   - Truc GIA hang 1: dung tai gia giua (Bid + Ask)/2.                                                                                              |
//|   - Truc THOI GIAN: iTime(M1, 0) + InpMidLblFutureM1Bars nen M1 (60 giay / nen) ve phia tuong lai; ca 7 hang cung moc thoi gian, neo ANCHOR_LEFT.    |
//|   - Font InpFontName, co chu InpMidLblFontSize. Hang 1 mau clrMagenta; hang 2..15 mau duong cua khung (g_color[]), tooltip "<khung> (Bid - Open)/spread". |
//|   HANG 1 : "<gia><chieu><Owtron>/<diffavg>", vd "4123.4<tam giac tang>-1.5/4.1".                                                                   |
//|     (CAP NHAT: hang 1 chi con "<gia>", vd "4123.4"; <chieu>, <Owtron>, <diffavg> khong con in. Cac dong <chieu> / <Owtron> / <diffavg> ben duoi chi la mo ta cu.) |
//|     <gia> = (Bid + Ask)/2, 1 so le.                                                                                                                  |
//|     <chieu>: tang = Pivot ema >= OW, giam = Pivot < OW (khung dang sang o bang nut 1m..1nm; thieu du lieu -> khong in).                              |
//|     <Owtron> = (OW khung dang sang - gia nhan lam tron GAN GIA GIUA NHAT)/spread, 1 so le (AptRndNearestMidLvl()); thieu -> "-".                     |
//|     <diffavg> = (diffpv + diffpv2 + diffpv3)/3 cua khung dang sang (cung cach tinh nhan Pivot): diffpv = (RV1 - Pivot)/spread, diffpv2 = (RV2 - Pivot)/spread,|
//|       diffpv3 = (Pivot - OW)/spread, 1 so le; thieu 1 trong RV1 / RV2 / Pivot / OW / spread / bang khung tat -> "-".                                  |
//|   HANG 2..15 : "<TF> <RV1W%>/<RV2W%> <PivotW%> [<brkD>(<streak>)<SigBrk>] <(Bid - Open nen DANG CHAY)/spread> <SpR2>/<SpR1> <diffavg>" (TF = g_tfName[], vd "5m -62/-48 -35 [112(3)<tam giac tang>] -0.8 -3/-5 4.1"), 1 so le, lan luot 14 khung 1m, 5m, 15m, 30m, 1h, 2h, 3h, 4h, 6h, 8h, 12h, 1d, 1w, 1nm; thieu Open / spread -> "-". |
//|     (CAP NHAT: hang 2..15 hien dang "<TF> [<SigBrk><brkD>/<brkddiff><TenMuc> <bodiff>/<(Bid-Open)/spread> <SpR2>/<SpR1> <diffavg>/<diffavg2> <RSI>/<dRSI>]"; <dOWW%> <dRV1W%>/<dRV2W%> <dPivotW%> khong con in. |
//|     <SpR2>/<SpR1> (cung cach tinh nhan RV1) va <diffavg> (cung cach tinh nhan Pivot / hang 1) tinh cho CHINH khung cua hang do (thieu -> "-/-" va "-").   |
//|   - Thieu Bid / Ask / thoi gian nen M1 -> xoa ca 7 hang, khong doan. Chua doc duoc thang gia chart -> chi giu hang 1, xoa hang 2..15.                |
//|   Doi tuong OBJ_TEXT: PFX"MIDLBL" (hang 1), PFX"MIDLBL_1".."MIDLBL_14" (hang 2..15); OnDeinit don bang ObjectsDeleteAll(0,PFX).                         |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| AptWChgStr: thay doi THEO GIAY cua mot gia tri W% (so nguyen dang chuoi) cua khung ix, de in o hang khung cua nhan gia giua.            |
//|   fld: 0 = OW W%, 1 = RV1 W%, 2 = RV2 W%, 3 = Pivot W%. cur = chuoi W% hien tai ("-" / "" = thieu).                                      |
//|   Tra "<W% hien tai - W% cuoi cung cua giay truoc>" (so nguyen, khong dau "+"; 0 neu chua co moc truoc / vua sang nen moi cua khung tf); |
//|   thieu cur -> "-" va xoa cache. Cung co che voi <bodiff> / <diffavg2> trong DrawMidPriceLabel().                                         |
//+------------------------------------------------------------------+
string AptWChgStr(const int ix, const int fld, const string cur, const ENUM_TIMEFRAMES tf)
{
   static datetime s_wSec[56];
   static datetime s_wBar[56];
   static long     s_wCur[56];
   static long     s_wPrev[56];
   int k = ix * 4 + fld;
   if(ix < 0 || ix >= 14 || fld < 0 || fld > 3)
      return "-";
   if(cur == "" || cur == "-")
     {
      s_wSec[k] = 0;
      g_aptWChgOk[k] = false;
      return "-";
     }
   long     v    = StringToInteger(cur);
   datetime secN = TimeLocal();
   datetime barN = iTime(_Symbol, tf, 0);
   if(s_wSec[k] == 0 || s_wBar[k] != barN)
     {
      s_wPrev[k] = v;   // chua co moc truoc / nen moi -> thay doi = 0
      s_wCur[k]  = v;
      s_wSec[k]  = secN;
      s_wBar[k]  = barN;
     }
   else
      if(s_wSec[k] != secN)
        {
         s_wPrev[k] = s_wCur[k];   // giay moi: gia tri cuoi cung cua giay vua qua
         s_wCur[k]  = v;
         s_wSec[k]  = secN;
        }
      else
         s_wCur[k] = v;
   g_aptWChgV[k]  = (double)(v - s_wPrev[k]);
   g_aptWChgOk[k] = true;
   return IntegerToString(v - s_wPrev[k]);
}

#define APT_MID_ROWS 15   // so hang cua nhan gia giua (1 hang gia + 14 hang khung: 1m 5m 15m 30m 1h 2h 3h 4h 6h 8h 12h 1d 1w 1nm, theo thu tu g_tfList)

void DrawMidPriceLabel()
{
   MidOwRefresh();   // OW + chieu theo khung dang sang o bang nut 1m..1nm (toi da 1 lan / giay)
   string   nm  = PFX"MIDLBL";
   double   bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double   ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   datetime tM1 = iTime(_Symbol, PERIOD_M1, 0);
   if(bid <= 0.0 || ask <= 0.0 || tM1 <= 0)
     {
      for(int d = 0; d < APT_MID_ROWS; d++)
        {
         string nmD = (d == 0) ? nm : (nm + "_" + IntegerToString(d));
         if(ObjectFind(0, nmD) >= 0)
            ObjectDelete(0, nmD);
        }
      ArrayInitialize(g_aptBrkDDiffOk, false);   // thieu gia -> UpE/DnE khong cong
      ArrayInitialize(g_aptBoDiffOk, false);
      ArrayInitialize(g_aptBoValOk, false);
      ArrayInitialize(g_aptDiffAvg2Ok, false);
      ArrayInitialize(g_aptBrkDOk, false);
      ArrayInitialize(g_aptWChgOk, false);
      for(int _tl = 0; _tl < 14; _tl++)
         g_midRowTailStr[_tl] = "";   // thieu gia -> nhan RV2 chi con <TF>
      return;
     }

   double   mid  = (bid + ask) / 2.0;
   int      nFut = (InpMidLblFutureM1Bars < 0) ? 0 : InpMidLblFutureM1Bars;
   datetime tLbl = tM1 + (datetime)((long)nFut * (long)PeriodSeconds(PERIOD_M1));
   int      fs   = (InpMidLblFontSize < 6) ? 6 : InpMidLblFontSize;

   string   txt[APT_MID_ROWS];
   string   tip[APT_MID_ROWS];
   color    clr[APT_MID_ROWS];
   double   spread = (double)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * _Point;

   // HANG 1: chi con <gia> = (Bid + Ask)/2, lam tron 1 so le (<chieu>, <Owtron>, <diffavg> da bo khoi nhan).
   txt[0] = DoubleToString(mid, 1);
   tip[0] = "<gia>";
   clr[0] = clrMagenta;

   // HANG 2..15: "<TF> <RV1W%>/<RV2W%> <PivotW%> [<brkD>(<streak>)<SigBrk>] <(Bid - Open nen dang chay)/spread> <SpR2>/<SpR1> <diffavg>" cua 14 khung = g_tfList[0..13] (gom ca 3h = g_tfList[6])
   //   <SpR2>/<SpR1> cua CHINH khung hang do (cung cach tinh nhan RV1): SpR2 = round((Bid - RV2)/spread), SpR1 = round((Bid - RV1)/spread), so nguyen; thieu -> "-".
   //   <diffavg> = (diffpv + diffpv2 + diffpv3)/3 (cung cach tinh nhan Pivot)
   //   voi diffpv = (RV1 - Pivot)/spread, diffpv2 = (RV2 - Pivot)/spread, diffpv3 = (Pivot - OW)/spread (Pivot = g_pivotLvlValCache[], RV1 = g_rv1ValCache[], RV2 = g_aptRv2All[]). Thieu du lieu -> "-".
   //   OW cua tung khung chi doi khi khung sang nen moi / doi chu ky / doi che do OW -> cache theo khung (khong CopyOpen moi tick).
   static datetime s_rowOwBar[14];
   static int      s_rowOwKey[14];
   static double   s_rowOwVal[14];
   int nOwR = g_aptBrkDBars;
   if(nOwR < 2)   nOwR = 2;
   if(nOwR > 500) nOwR = 500;
   int tfIdx[APT_MID_ROWS - 1] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13};
   for(int r = 1; r < APT_MID_ROWS; r++)
     {
      int             ix  = tfIdx[r - 1];
      ENUM_TIMEFRAMES tfR = g_tfList[ix];
      double opR = iOpen(_Symbol, tfR, 0);
      // <brkD>(<streak>)<SigBrk> (chuyen tu nhan RV1, KHONG ngoac vuong, dinh lien <(Bid-Open)/spread>): brkD = (Close - LL)/(HH - LL)*100 cua kenh brkD GIA (AptBrkDAt()); <streak> = AptBrkStreakCount();
      //   <SigBrk> = tam giac tang khi brkD >= 110, tam giac giam khi brkD <= -10, con lai khong in. Thieu du lieu kenh -> "-".
      string rowBrk = "-";       // phan DAU trong [ ]: <SigBrk><brkD>/<brkddiff><TenMuc>
      string rowBrkTail = "";    // phan DUOI trong [ ]: <RSI5>/<lech>
      int    rowBrkD = 0;
      g_aptBrkDDiffOk[ix] = false;   // <brkddiff> / <bodiff> cho UpE/DnE (DrawBreakStats()): chi hop le khi tinh duoc trong lan ve nay
      g_aptBoDiffOk[ix]   = false;
      g_aptBoValOk[ix]    = false;
      g_aptDiffAvg2Ok[ix] = false;   // <diffavg2> cho Up/Dn (DrawBreakStats())
      g_aptBrkDOk[ix]     = false;   // <brkD> cho UpB/DnB (DrawBreakStats())
      if(AptBrkDAt(tfR, 0, rowBrkD))
        {
         g_aptBrkDV[ix]  = (double)rowBrkD;
         g_aptBrkDOk[ix] = true;
         string rowSig = (rowBrkD >= 110) ? ShortToString(0x25B2) : ((rowBrkD <= -10) ? ShortToString(0x25BC) : "");
         // <brkddiff> = brkD nen hien tai - brkD nen DA DONG ngay truoc (AptBrkDAt shift 1), co dau (+5 / -3 / 0); thieu nen truoc -> "-"
         int    rowBrkPrev = 0;
         string rowBrkDiff = "-";
         if(AptBrkDAt(tfR, 1, rowBrkPrev))
           {
            int rowBrkDf = rowBrkD - rowBrkPrev;
            rowBrkDiff = ((rowBrkDf > 0) ? "+" : "") + IntegerToString(rowBrkDf);
            g_aptBrkDDiffV[ix]  = (double)rowBrkDf;
            g_aptBrkDDiffOk[ix] = true;
           }
         rowBrk     = rowSig + IntegerToString(rowBrkD) + "/" + rowBrkDiff + g_midTmStr[ix];   // <SigBrk><brkD>/<brkddiff><TenMuc>, dung ngay sau "["
         rowBrkTail = g_midRsiStr[ix];   // <RSI5>/<lech>, cuoi hang truoc "]"
        }
      // <RV1W%>/<RV2W%> <PivotW%>: William %R (so nguyen) cua RV1, RV2, Pivot - do DrawRv2RsiLabels() tinh va cache o g_midRv1WStr[] / g_midRv2WStr[] / g_midPvWStr[]; thieu -> "-".
      // <bodiff>/<(Bid-Open)/spread>: bodiff = (Bid-Open)/spread HIEN TAI - gia tri CUOI CUNG cua (Bid-Open)/spread o GIAY TRUOC (TimeLocal), 1 so le, KHONG dau "+" (0.1 / -0.1).
      //   Moi khung giu 3 o nho: s_boCur = gia tri moi nhat trong giay hien tai, s_boPrev = gia tri cuoi cung cua giay truoc, s_boSec = giay dang ghi.
      //   Sang giay moi -> s_boPrev = s_boCur. Sang nen moi cua khung (Open doi, gia tri nhay) hoac chua co giay truoc -> bodiff = 0.0. Thieu Open / spread -> "-" (xoa cache).
      static datetime s_boSec[14];
      static datetime s_boBar[14];
      static double   s_boCur[14];
      static double   s_boPrev[14];
      string rowBO = "-";
      if(spread > 0.0 && opR > 0.0)
        {
         double   boNow  = (bid - opR) / spread;
         datetime boSecN = TimeLocal();
         datetime boBarN = iTime(_Symbol, tfR, 0);
         if(s_boSec[ix] == 0 || s_boBar[ix] != boBarN)
           {
            s_boPrev[ix] = boNow;   // chua co moc truoc / nen moi -> diff = 0
            s_boCur[ix]  = boNow;
            s_boSec[ix]  = boSecN;
            s_boBar[ix]  = boBarN;
           }
         else
            if(s_boSec[ix] != boSecN)
              {
               s_boPrev[ix] = s_boCur[ix];   // giay moi: gia tri cuoi cung cua giay vua qua
               s_boCur[ix]  = boNow;
               s_boSec[ix]  = boSecN;
              }
            else
               s_boCur[ix] = boNow;
         double boDf = NormalizeDouble(boNow - s_boPrev[ix], M1_ELP_LBL_DIF1_DIGITS);
         if(boDf == 0.0)
            boDf = 0.0;   // tranh "-0.0"
         g_aptBoDiffV[ix]  = boDf;
         g_aptBoDiffOk[ix] = true;
         g_aptBoValV[ix]   = NormalizeDouble(boNow, M1_ELP_LBL_DIF1_DIGITS);
         g_aptBoValOk[ix]  = true;
         rowBO = DoubleToString(boDf, M1_ELP_LBL_DIF1_DIGITS) + "/" + DoubleToString(boNow, M1_ELP_LBL_DIF1_DIGITS);   // <bodiff>/<(Bid-Open)/spread>
        }
      else
         s_boSec[ix] = 0;
      // <dRV1W%> <dRV2W%> <dPivotW%> KHONG con in tren hang khung, nhung VAN phai tinh moi lan ve: AptWChgStr() ghi g_aptWChgV[] / g_aptWChgOk[] cho dem UpA/DnA (xem DrawBreakStats()).
      //   (<dOWW%> da bo han khoi hang khung va khoi dieu kien dem.)
      string rowWChgKeep = AptWChgStr(ix, 1, g_midRv1WStr[ix], tfR) + AptWChgStr(ix, 2, g_midRv2WStr[ix], tfR) + AptWChgStr(ix, 3, g_midPvWStr[ix], tfR);
      // (Hang khung rieng cua nhan gia giua da bo: cum <SigBrk><brkD>/... duoc ghi vao g_midRowTailStr[ix] de nhan RV2 hien.)

      datetime bar0R = iTime(_Symbol, tfR, 0);
      int      keyR  = AptOwModeKey(nOwR);
      if(bar0R > 0 && (s_rowOwBar[ix] != bar0R || s_rowOwKey[ix] != keyR))
        {
         double owNew = 0.0;
         s_rowOwVal[ix] = AptOpenLwma(tfR, nOwR, owNew) ? owNew : 0.0;
         s_rowOwKey[ix] = keyR;
         s_rowOwBar[ix] = (s_rowOwVal[ix] > 0.0) ? bar0R : 0;   // that bai -> khong cache, lan sau thu lai
        }
      double owR = (bar0R > 0) ? s_rowOwVal[ix] : 0.0;
      string rowSpR2    = "-";
      string rowSpR1    = "-";
      string rowDiffAvg = "-";
      if(spread > 0.0 && bid > 0.0)
        {
         if(g_aptRv2AllOk[ix] && g_aptRv2All[ix] > 0.0)
            rowSpR2 = IntegerToString((int)MathRound((bid - g_aptRv2All[ix]) / spread));
         if(g_rv1ValCache[ix] > 0.0)
            rowSpR1 = IntegerToString((int)MathRound((bid - g_rv1ValCache[ix]) / spread));
        }
      // <diffavg>/<diffavg2>: diffavg2 = diffavg HIEN TAI - gia tri CUOI CUNG cua diffavg o GIAY TRUOC (TimeLocal), 1 so le, KHONG dau "+" (cung co che voi <bodiff>).
      //   Sang giay moi -> s_daPrev = s_daCur. Sang nen moi cua khung hoac chua co giay truoc -> diffavg2 = 0.0. Thieu diffavg -> "-" (xoa cache).
      static datetime s_daSec[14];
      static datetime s_daBar[14];
      static double   s_daCur[14];
      static double   s_daPrev[14];
      bool daOk = false;
      if(spread > 0.0 && owR > 0.0)
        {
         if(g_rv1ValCache[ix] > 0.0 && g_aptRv2AllOk[ix] && g_aptRv2All[ix] > 0.0 && g_pivotLvlValCache[ix] > 0.0)
           {
            double rPv1 = g_rv1ValCache[ix] - g_pivotLvlValCache[ix];
            double rPv2 = g_aptRv2All[ix]   - g_pivotLvlValCache[ix];
            double rPv3 = g_pivotLvlValCache[ix] - owR;
            double daNow  = (rPv1 + rPv2 + rPv3) / (3.0 * spread);
            datetime daSecN = TimeLocal();
            if(s_daSec[ix] == 0 || s_daBar[ix] != bar0R)
              {
               s_daPrev[ix] = daNow;   // chua co moc truoc / nen moi -> diffavg2 = 0
               s_daCur[ix]  = daNow;
               s_daSec[ix]  = daSecN;
               s_daBar[ix]  = bar0R;
              }
            else
               if(s_daSec[ix] != daSecN)
                 {
                  s_daPrev[ix] = s_daCur[ix];   // giay moi: gia tri cuoi cung cua giay vua qua
                  s_daCur[ix]  = daNow;
                  s_daSec[ix]  = daSecN;
                 }
               else
                  s_daCur[ix] = daNow;
            double daDf = NormalizeDouble(daNow - s_daPrev[ix], M1_ELP_LBL_DIF1_DIGITS);
            if(daDf == 0.0)
               daDf = 0.0;   // tranh "-0.0"
            rowDiffAvg = DoubleToString(daNow, M1_ELP_LBL_DIF1_DIGITS) + "/" + DoubleToString(daDf, M1_ELP_LBL_DIF1_DIGITS);   // <diffavg>/<diffavg2>
            g_aptDiffAvg2V[ix]  = daDf;
            g_aptDiffAvg2Ok[ix] = true;
            daOk = true;
           }
        }
      if(!daOk)
         s_daSec[ix] = 0;
      g_midRowTailStr[ix] = " { " + rowBrk + " " + rowBO + " } " + rowSpR2 + "/" + rowSpR1 + " " + rowDiffAvg + ")";   // { <SigBrk><brkD>/<brkddiff><TenMuc> <bodiff>/<(Bid-Open)/spread> } <SpR2>/<SpR1> <diffavg>/<diffavg2>)  (")" dong ngoac "(" mo o nhan RV2; <RSI>/<dRSI> khong con o cuoi nhan)
     }

   // Quy doi pixel -> gia de xep hang 2..15 xuong duoi hang 1 (khong phu thuoc ChartTimePriceToXY: moc thoi gian nam o tuong lai)
   double pMax = ChartGetDouble(0, CHART_PRICE_MAX, 0);
   double pMin = ChartGetDouble(0, CHART_PRICE_MIN, 0);
   long   hPx  = ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS, 0);
   double perPx = (hPx > 0 && pMax > pMin) ? (pMax - pMin) / (double)hPx : 0.0;
   // Hang 2..14 (cot <TF> <(Bid - Open)/spread>) = hang thu 2, 3, ... duoi nhan RV1 khung 1m: cung moc thoi gian (g_rv1M1LblT), cung co chu, hang 2 ngay duoi nhan RV1 1m.
   //   Chua co nhan RV1 1m (g_rv1M1LblT / g_rv1M1LblPx = 0) hoac chua doc duoc thang gia -> xoa cot, khong doan.
   int    fsC   = (g_rv1M1LblFs < 6) ? fs : g_rv1M1LblFs;
   int    lineH = fsC + 7;

   for(int r = 0; r < APT_MID_ROWS; r++)
     {
      string nmR = (r == 0) ? nm : (nm + "_" + IntegerToString(r));
      if(r == 0)
        {
         MidLblPut(nmR, tLbl, mid, txt[r], clr[r], fs, tip[r]);
         continue;
        }
      // Hang 2..15 (cot <TF> [...] duoi nhan RV1 1m) da bo: cum noi dung chuyen sang nhan RV2 (g_midRowTailStr[]); xoa object cu neu con.
      if(ObjectFind(0, nmR) >= 0)
         ObjectDelete(0, nmR);
     }
}

//+------------------------------------------------------------------+
//| DrawCloseSimpleLabels: ve nhan danh dau vi tri Close Simple =       |
//|   SMA(Close, g_aptCsmaPeriod) cua TUNG khung trong g_tfList[] (14   |
//|   khung), period lay tu Close Simple UI.                            |
//|   - Truc GIA: SMA cua g_aptCsmaPeriod gia dong cua gan nhat cua      |
//|     chinh khung do (gom nen dang chay). Khung chua du g_aptCsmaPeriod|
//|     nen lich su -> khong ve nhan khung do (xoa nhan cu), khong doan. |
//|   - Truc THOI GIAN: g_rv1M1LblT (moc nhan RV1 1m, do DrawRv2RsiLabels|
//|     ghi) + InpCsmaFutureBars nen cua chart dang mo ve phia tuong lai.|
//|     Chua co moc (0) -> du phong nen 0.                               |
//|   - Mau lay theo g_color[i] cua khung (cung thu tu g_tfList).        |
//|   Chi tao/di chuyen OBJ_TEXT (prefix g_csmaLblPrefix).               |
//+------------------------------------------------------------------+
void DrawCloseSimpleLabels()
{
   int per = (g_aptCsmaPeriod < 1) ? 1 : g_aptCsmaPeriod;

   datetime tBase = (g_rv1M1LblT > 0) ? g_rv1M1LblT : iTime(_Symbol, _Period, 0);
   int      psec  = PeriodSeconds(_Period);
   if(tBase <= 0 || psec <= 0)
     {
      ObjectsDeleteAll(0, g_csmaLblPrefix, -1, OBJ_TEXT);
      return;
     }
   datetime tLbl = tBase + (datetime)((long)MathMax(0, InpCsmaFutureBars) * (long)psec);
   int      fs   = (InpRv2LblFontSize < 6) ? 6 : InpRv2LblFontSize;

   for(int i = 0; i < 14; i++)
     {
      string nm = g_csmaLblPrefix + g_tfLabel[i];

      double cl[];
      int got = CopyClose(_Symbol, g_tfList[i], 0, per, cl);
      if(got < per)
        {
         if(ObjectFind(0, nm) >= 0)
            ObjectDelete(0, nm);
         continue;
        }

      double sum = 0.0;
      for(int k = 0; k < per; k++)
         sum += cl[k];
      double sma = sum / (double)per;
      if(sma <= 0.0)
        {
         if(ObjectFind(0, nm) >= 0)
            ObjectDelete(0, nm);
         continue;
        }

      if(ObjectFind(0, nm) < 0)
         ObjectCreate(0, nm, OBJ_TEXT, 0, tLbl, sma);
      ObjectMove(0, nm, 0, tLbl, sma);
      ObjectSetString (0, nm, OBJPROP_TEXT,       "< " + g_tfLabel[i] + " SMA" + IntegerToString(per));
      ObjectSetString (0, nm, OBJPROP_FONT,       InpFontName);
      ObjectSetInteger(0, nm, OBJPROP_COLOR,      g_color[i]);
      ObjectSetInteger(0, nm, OBJPROP_FONTSIZE,   fs);
      ObjectSetInteger(0, nm, OBJPROP_ANCHOR,     ANCHOR_LEFT);
      ObjectSetInteger(0, nm, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, nm, OBJPROP_HIDDEN,     true);
      ObjectSetInteger(0, nm, OBJPROP_BACK,       false);
     }
}

//+------------------------------------------------------------------+
//|   Bang nut chon khung ve than nen lon Bar Chart (g_barTF):        |
//|   13 nut / bang, xep 4 cot: M1 M5 M15 M30 / H1 H2 H4 H6 /         |
//|   H8 H12 D1 W1 / MN1. Vi tri x2 = InpTFPanelX + TFPanelWidth() + gap. |
//+------------------------------------------------------------------+
void CreateTFPanels()
{
   if(!InpShowTFPanels) return;

   int w  = (InpTFBtnW < 16) ? 16 : InpTFBtnW;
   int h  = (InpTFBtnH < 12) ? 12 : InpTFBtnH;
   int g  = (InpTFBtnGap < 0) ? 0 : InpTFBtnGap;
   int x2 = InpTFPanelX + TFPanelWidth() + ((InpTFPanelGapX < 0) ? 0 : InpTFPanelGapX);

   x2 = RV2_ApplyPanelShiftX(x2);

   for(int i = 0; i < RV2_UI_TF_COUNT; i++)
   {
      int col = i % RV2_UI_COLS;
      int row = i / RV2_UI_COLS;
      int dx  = col * (w + g);
      int dy  = row * (h + g);

      MakeTFButton(g_btnBcPrefix + IntegerToString(i), g_uiTFName[i],
                   x2 + dx, InpTFPanelY + dy, w, h,
                   (g_uiTFList[i] == g_barTF));
   }

   CreateLevelPanel();

   CreatePivotModePanel();

   CreateRowTfPanel();

   CreateOwModePanel();

   CreateRsiPePanel();

   CreateRv2EmaPanel();

   CreateCsmaPanel();

   CreateRndPanel();

   CreateDxyPanel();
}

//+------------------------------------------------------------------+
//|   Bang nut chon khung than nen lon (Bar Chart).                   |
//+------------------------------------------------------------------+
void UpdateTFPanelStates()
{
   if(!InpShowTFPanels) return;
   for(int i = 0; i < RV2_UI_TF_COUNT; i++)
   {
      string nmB = g_btnBcPrefix + IntegerToString(i);
      if(ObjectFind(0, nmB) >= 0)
      {
         ObjectSetInteger(0, nmB, OBJPROP_BGCOLOR,
                          (g_uiTFList[i] == g_barTF) ? InpTFBtnBgSel : InpTFBtnBg);
         ObjectSetInteger(0, nmB, OBJPROP_STATE, false);
      }
   }

   UpdateLevelPanelStates();

   UpdatePivotModePanelStates();

   UpdateRowTfPanelStates();

   UpdateOwModePanelStates();

   UpdateRsiPePanelStates();

   UpdateRv2EmaPanelStates();

   UpdateCsmaPanelStates();
   UpdateRndPanelStates();
}

//+------------------------------------------------------------------+
//| DeleteTFPanels: don toan bo nut cua cac bang nut. |
//+------------------------------------------------------------------+
void DeleteTFPanels()
{
   ObjectsDeleteAll(0, g_btnBcPrefix, -1, OBJ_BUTTON);
   ObjectsDeleteAll(0, g_btnLvPrefix, -1, OBJ_BUTTON);
   ObjectsDeleteAll(0, g_btnPvModePrefix, -1, OBJ_BUTTON);
   ObjectsDeleteAll(0, g_btnRowTfPrefix, -1, OBJ_BUTTON);
   ObjectsDeleteAll(0, g_btnOwModePrefix, -1, OBJ_BUTTON);
   ObjectsDeleteAll(0, g_btnRsiPePrefix, -1, OBJ_BUTTON);
   ObjectsDeleteAll(0, g_btnRv2EmaPrefix, -1, OBJ_BUTTON);
   ObjectsDeleteAll(0, g_btnBrkDPrefix, -1, OBJ_BUTTON);
   ObjectsDeleteAll(0, g_btnBrkDTfPrefix, -1, OBJ_BUTTON);
   ObjectsDeleteAll(0, g_btnCsmaPrefix, -1, OBJ_BUTTON);
   ObjectsDeleteAll(0, g_btnRndPrefix, -1, OBJ_BUTTON);
   ObjectDelete(0, g_btnRndGapName);
   ObjectsDeleteAll(0, g_edtRndPrefix, -1, OBJ_EDIT);
   ObjectsDeleteAll(0, g_edtDxyPrefix, -1, OBJ_EDIT);
}

//+------------------------------------------------------------------+
//| WrvBuildBrkStr - PORT NGUYEN VEN tu NewCandle.mq5. |
//|  Cum {brk}: muc do pha vo bien do nen LIEN TRUOC cua MOT khung.   |
//|  Gia dung de so sanh: Close[shift] cua CHINH khung do.            |
//|  Nen lien truoc = nen [shift+1]: _pH = High[1], _pL = Low[1] (chi |
//|  so [0]/[1] tinh tren mang da copy tu vi tri shift).              |
//|                                                                   |
//|  QUY TAC:                                                         |
//|    price > High[1]  -> brk = (price - Low[1] ) / (High[1]-Low[1])  |
//|    price < Low[1]   -> brk = (price - High[1]) / (High[1]-Low[1])  |
//|    con lai (nam trong bien do nen truoc) -> tra ve CHUOI RONG      |
//|                                                                   |
//|  Ket qua in duoi dang PHAN TRAM, KHONG kem dau '%' (vd "105",     |
//|  "-12"). Thieu du lieu (khung chua du 2 nen, range = 0, gia <= 0,  |
//|  shift < 0) -> chuoi RONG, KHONG doan gia tri.                     |
//|                                                                   |
//|  Tham so digits (mac dinh 0) chi doi so chu so thap phan luc IN, khong dung vao phep tinh nao.                                       |
//|                                                                   |
//|  KHONG tao object / duong line / plot / buffer nao trong ham nay.  |
//+------------------------------------------------------------------+
string WrvBuildBrkStr(ENUM_TIMEFRAMES tf, int shift = 0, int digits = 0)
{
   if(shift < 0) return "";

   double _brkH[], _brkL[], _brkC[];

   ArraySetAsSeries(_brkH, true);
   ArraySetAsSeries(_brkL, true);
   ArraySetAsSeries(_brkC, true);

   // Vi tri bat dau = shift: _brkC[0] la Close cua nen shift, con _brkH[1] /
   //   _brkL[1] la nen LIEN TRUOC no. Y nghia cac chi so [0] / [1] KHONG doi.
   if(CopyHigh (_Symbol, tf, shift, 2, _brkH) < 2) return "";
   if(CopyLow  (_Symbol, tf, shift, 2, _brkL) < 2) return "";
   if(CopyClose(_Symbol, tf, shift, 2, _brkC) < 2) return "";

   double _price = _brkC[0];
   if(_price <= 0.0) return "";

   double _pH = _brkH[1];
   double _pL = _brkL[1];
   double _rg = _pH - _pL;
   if(_rg <= 0.0) return "";

   int _dg = digits;
   if(_dg < 0) _dg = 0;
   if(_dg > 3) _dg = 3;

   return DoubleToString((_price - _pL) / _rg * 100.0, _dg);
}

//+------------------------------------------------------------------+
//| BrkTextForTF: boc WrvBuildBrkStr cho o bang thong ke. |
//|   Chuoi RONG (gia con nam trong bien do nen truoc, hoac thieu du   |
//|   lieu) -> outText giu dau "-" giong cac o khac cua bang.          |
//|   KHONG cache: brk phu thuoc gia HIEN TAI (Close cua nen dang chay)|
//|   nen phai tinh lai moi lan lam moi bang. Moi lan goi chi doc 2 nen|
//|   cua khung do -> tai rat nhe.                                     |
//|   Ham CHI DOC gia: khong tao object, khong ve duong.               |
//+------------------------------------------------------------------+
bool BrkTextForTF(ENUM_TIMEFRAMES tf, string &outText)
{
   outText = "-";

   int _bkSh = (InpTFStatBrkShift < 0) ? 0 : InpTFStatBrkShift;
   int _bkDg = InpTFStatBrkDigits;
   if(_bkDg < 0) _bkDg = 0;
   if(_bkDg > 3) _bkDg = 3;

   string _bkStr = WrvBuildBrkStr(tf, _bkSh, _bkDg);
   if(_bkStr == "") return false;

   outText = _bkStr;
   return true;
}

//+------------------------------------------------------------------+
//| BrkAccSecToStr: in so giay cong don cho gon. |
//|   secs <  60  -> "<so giay>s"          (vd 30  -> "30s")          |
//|   secs >= 60  -> "<so phut>.<giay le>s" (vd 90  -> "1.30s",       |
//|                                              605 -> "10.05s")     |
//|   Phan giay le luon 2 chu so de cac o thang hang.                 |
//|   Ham THUAN TUY doi so -> chuoi: khong doc gia, khong tao object.  |
//+------------------------------------------------------------------+
string BrkAccSecToStr(long secs)
{
   if(secs < 0) secs = 0;
   if(secs < 60) return IntegerToString((int)secs) + "s";

   long _m = secs / 60;
   long _s = secs % 60;
   return IntegerToString((int)_m) + "." + StringFormat("%02d", (int)_s) + "s";
}

// --- Nguong CMF/VPIN cho dieu kien dem <RV1up>/<RV1dn> (g_rvOrdRv1Up/g_rvOrdRv1Dn, xem RvOrderAccumUpdate() ngay duoi).
input group             "=== DEM RV1up/RV1dn - NGUONG CMF / VPIN ==="
input double            InpRvOrdCmfTh     = 0.20;   // RV1up: CMF > +nguong ; RV1dn: CMF < -nguong (tuy chon)

//+------------------------------------------------------------------+
//| RvOrderAccumUpdate: nuoi bo dem giay g_rvOrdRv1Up/g_rvOrdRv1Dn (CMF > +InpRvOrdCmfTh / < -InpRvOrdCmfTh), reset khi sang nen M5 moi. |
//+------------------------------------------------------------------+
void RvOrderAccumUpdate()
{
   datetime _roBt = iTime(_Symbol, PERIOD_M5, 0);
   if(_roBt <= 0) return;

   datetime _roNow = TimeCurrent();
   if(_roNow <= 0) return;

   long _roDtL = (long)_roNow - (long)g_rvOrdLast;
   int  _roDt  = 0;
   if(g_rvOrdLast > 0 && _roDtL > 0 && _roDtL < 3600) _roDt = (int)_roDtL;
   g_rvOrdLast = _roNow;

   //--- Sang NEN M5 MOI -> reset ca hai bo dem, bo qua nhip giao nen ---
   if(g_rvOrdBarT != _roBt)
   {
      g_rvOrdBarT  = _roBt;
      g_rvOrdRv1Up = 0;
      g_rvOrdRv1Dn = 0;
      return;
   }

   if(_roDt <= 0) return;

   {
      double _roCmf = 0.0, _roVpin = 0.0;
      bool   _roCmfOk = false, _roVpinOk = false;
      int    _roVpinDir = 0;
      AptCmfVpinCalc(_roCmf, _roCmfOk, _roVpin, _roVpinOk, _roVpinDir);
      if(_roCmfOk)
      {
         if(_roCmf > InpRvOrdCmfTh)
            g_rvOrdRv1Up += (long)_roDt;
         else if(_roCmf < -InpRvOrdCmfTh)
            g_rvOrdRv1Dn += (long)_roDt;
      }
   }



}

//+------------------------------------------------------------------+
//| TpAccumUpdate: nuoi bo dem giay cong don g_upD / g_dnD cho hang UPDDND |
//|   cua cum nhan duoi than nen lon.                                  |
//|                                                                    |
//|   KHUNG MOC: khung cua THAN NEN LON (InpBarChartTF, bang nut g_barTF |
//|   de len), cung cach RvOrderAccumUpdate(). Bam nut doi khung than nen |
//|   thi bo dem dem lai theo nen cua khung moi.                        |
//|   CUA SO DEM: tu luc than nen lon sang NEN MOI. Khi iTime(khung,0) doi -> |
//|   reset ca hai bo dem ve 0 va bo qua nhip do.                        |
//|   NHIP CONG DON: dt = TimeCurrent() - moc lan truoc, chi cong khi    |
//|   0 < dt < 3600.                                                    |
//|   DIEU KIEN CONG (khung M1, nen shift 0):                           |
//|     g_upD += dt khi W% > InpUpdWUp VA brkD > InpUpdBrkUp             |
//|     g_dnD += dt khi W% < InpUpdWDn VA brkD < InpUpdBrkDn             |
//|   Thieu du lieu (AptBrkWAt / AptBrkDAt that bai) -> khong cong ben nao.|
//|   Ham chi doc gia + cong bien dem.                                  |
//+------------------------------------------------------------------+
void TpAccumUpdate()
{
   //--- Khung than nen lon: y het RvOrderAccumUpdate() ---
   ENUM_TIMEFRAMES _tdTf = InpBarChartTF;
   if(g_barTF != InpBarChartTF) _tdTf = g_barTF;

   datetime _tdBt = iTime(_Symbol, _tdTf, 0);
   if(_tdBt <= 0) return;

   datetime _tdNow = TimeCurrent();
   if(_tdNow <= 0) return;

   long _tdDtL = (long)_tdNow - (long)g_tpAccLast;
   int  _tdDt  = 0;
   if(g_tpAccLast > 0 && _tdDtL > 0 && _tdDtL < 3600) _tdDt = (int)_tdDtL;
   g_tpAccLast = _tdNow;

   //--- Than nen lon sang NEN MOI -> reset ca hai, bo qua nhip giao nen ---
   if(g_tpAccBarT != _tdBt)
   {
      g_tpAccBarT = _tdBt;
      g_upD       = 0;
      g_dnD       = 0;
      return;
   }

   if(_tdDt <= 0) return;

   int  _tdWv   = 0;
   int  _tdBrkv = 0;
   bool _tdWOk   = AptBrkWAt (PERIOD_M1, 0, _tdWv);
   bool _tdBrkOk = AptBrkDAt (PERIOD_M1, 0, _tdBrkv);
   if(_tdWOk && _tdBrkOk)
   {
      if((double)_tdWv > InpUpdWUp && (double)_tdBrkv > InpUpdBrkUp)
         g_upD += (long)_tdDt;
      else
         if((double)_tdWv < InpUpdWDn && (double)_tdBrkv < InpUpdBrkDn)
            g_dnD += (long)_tdDt;
   }

}

//+------------------------------------------------------------------+
//| GetRV2NBars: so nen M1 cho 1 khung TF bat ky.                      |
//+------------------------------------------------------------------+
int GetRV2NBars(ENUM_TIMEFRAMES tf)
{
   int nB = (int)(PeriodSeconds(tf) / 60);
   if(nB < 1) nB = 1;
   return nB;
}

//+------------------------------------------------------------------+
//| g_rvTfList nay da co DU 14 |
//|   khung (them H3/H6, xem dinh nghia canh RV2_TF_COUNT), moi khung |
//|   deu co input mau rieng (InpColor_H3/InpColor_H6 moi, xem canh   |
//|   InpColor_H2/InpColor_H4) nen vong lap ben duoi LUON tim thay -  |
//|   nhanh return InpColor_H4 cuoi ham GIU LAI (khong xoa) chi con   |
//|   dung cho khung THAT SU nam ngoai danh sach 14 khung nay.        |
//+------------------------------------------------------------------+
color GetRV2Color(ENUM_TIMEFRAMES tf)
{
   for(int i = 0; i < RV2_TF_COUNT; i++)
      if(g_rvTfList[i] == tf) return g_color[i];
   return InpColor_H4;
}

//==================================================================
//  COT NHAN <TenMuc> LICH SU TREN DINH NEN 1M  (DrawAptLvlColumn)
//  Moi nen 1m trong InpLvlColBars nen gan nhat (shift 0..N-1) co 1 cot 14 nhan ngay tren dinh nen: moi nhan = <TenMuc> (PP / R1..R9 / S1..S9)
//  cua 1 khung trong g_tfList (1m o duoi cung). Nen dang chay: theo BID hien tai. Nen lich su: <TenMuc> TAI THOI DIEM nen do (xem BANG FORMAT muc 5).
//  Chuoi EMA muc Woodie cua tung khung duoc tinh 1 lan roi cache, chi tinh lai khi khung sang nen moi / doi so nen N.
//  Cau truc hien tai: hang 1..6 = <TenMuc> khung 1m..2h; hang 7..12 = (<diffpv>+<diffpv2>+<diffpv3>)/3 khung 1m..2h; hang 13..14 trong (xem BANG FORMAT muc 5).
//  Object: PFX"LVC_"+<nen>+"_"+<khung> (OnDeinit don bang ObjectsDeleteAll(0,PFX)). Khong ve them duong nao, khong doi setting cu.
//==================================================================
#define APT_LVC_TF       14     // so khung (= g_tfList)
#define APT_LVC_MAXBARS  100    // tran so nen 1m co cot nhan (InpLvlColBars duoc kep 1..100)
#define APT_LVC_KCAP     101    // so shift khung toi da luu trong cache (k <= shift nen 1m <= APT_LVC_MAXBARS - 1)
#define APT_LVC_NAMETF   6      // so hang dau = <TenMuc> khung g_tfList[0..5] (1m..2h); cac hang sau (7 tro len) = (diffpv+diffpv2+diffpv3)/3 cua cung 6 khung
#define APT_LVC_VALTF    6      // so hang gia tri (diffpv+diffpv2+diffpv3)/3 (khung g_tfList[0..5] = 1m..2h)
#define APT_LVC_EXTRA_PTS 50    // khoang cach CONG THEM (point) giua dinh nen 1m va nhan hang 1, cong voi InpLvlColAbovePts (tranh nhan sat dinh nen)

double   g_lvcEma     [APT_LVC_TF][APT_S1_LVL_COUNT][APT_LVC_KCAP]; // EMA(APT_S1_EMA_PERIOD) cua muc lvl tai nen khung shift k
datetime g_lvcTfBar0  [APT_LVC_TF];                                 // iTime(tf,0) luc tinh cache cua khung i
int      g_lvcKNeed   [APT_LVC_TF];                                 // shift lon nhat da YEU CAU luc tinh cache (de biet khi nao can tinh lai)
int      g_lvcKAvail  [APT_LVC_TF];                                 // shift lon nhat THUC SU co du lieu trong cache (k > nay -> "-")
bool     g_lvcOk      [APT_LVC_TF];                                 // cache cua khung i hop le
string   g_lvcSig     [APT_LVC_MAXBARS * APT_LVC_TF];               // chu ky lan ve truoc cua tung nhan (bo qua neu khong doi)
bool     g_lvcWasOn = false;                                        // lan goi truoc co dang bat cot nhan khong (de don object 1 lan khi tat)
datetime g_lvcHT      [APT_LVC_MAXBARS];                            // thoi gian mo nen 1m cua o lich su (o = (thoi gian/60) % APT_LVC_MAXBARS); 0 = trong
string   g_lvcHS      [APT_LVC_MAXBARS][APT_LVC_VALTF];             // (diffpv+diffpv2+diffpv3)/3 gan nhat da ghi nhan cua khung j tai nen 1m o do ("-" = thieu)

//--- Tinh (hoac dung lai) cache EMA muc Woodie cua khung g_tfList[i] cho shift k = 0..kNeed. Cung cong thuc AptWoodieDisplayLvlForTF():
//    chuoi muc tho s = cu nhat -> moi nhat (nen khung shift s+1), EMA(APT_S1_EMA_PERIOD) seed tu phan tu cu nhat; ema[s] = gia tri muc tai nen khung shift s.
bool AptLvcBuildTF(const int i, const int kNeed)
  {
   ENUM_TIMEFRAMES tf = g_tfList[i];
   datetime t0 = iTime(_Symbol, tf, 0);
   if(t0 <= 0)
     {
      g_lvcOk[i] = false;
      return(false);
     }
   if(g_lvcOk[i] && g_lvcTfBar0[i] == t0 && g_lvcKNeed[i] >= kNeed)
      return(true);

   int need = kNeed + APT_S1_HIST_POINTS + 1;   // +1 vi moi diem s can nen lien truoc (s+1)
   double hi[], lo[], cl[];
   ArraySetAsSeries(hi, true);
   ArraySetAsSeries(lo, true);
   ArraySetAsSeries(cl, true);
   int cpH = CopyHigh (_Symbol, tf, 0, need, hi);
   int cpL = CopyLow  (_Symbol, tf, 0, need, lo);
   int cpC = CopyClose(_Symbol, tf, 0, need, cl);
   int got = MathMin(MathMin(cpH, cpL), cpC);
   if(got < 2)
     {
      g_lvcOk[i] = false;
      return(false);
     }

   int points = got - 1;
   if(points > kNeed + APT_S1_HIST_POINTS)
      points = kNeed + APT_S1_HIST_POINTS;
   if(points < 1)
     {
      g_lvcOk[i] = false;
      return(false);
     }

   int kMax = kNeed;
   if(kMax > points - 1)
      kMax = points - 1;
   if(kMax > APT_LVC_KCAP - 1)
      kMax = APT_LVC_KCAP - 1;

   int    pEma = MathMax(1, APT_S1_EMA_PERIOD);
   double aEma = 2.0 / (pEma + 1.0);
   for(int lvl = 0; lvl < APT_S1_LVL_COUNT; lvl++)
     {
      double e      = 0.0;
      bool   seeded = false;
      for(int s = points - 1; s >= 0; s--)
        {
         double v = AptWoodieLevelValue(lvl, hi[s + 1], lo[s + 1], cl[s + 1]);
         if(!seeded)
           {
            e = v;
            seeded = true;
           }
         else
           {
            e = aEma * v + (1.0 - aEma) * e;
           }
         if(s <= kMax)
            g_lvcEma[i][lvl][s] = e;
        }
     }

   g_lvcTfBar0[i] = t0;
   g_lvcKNeed [i] = kNeed;
   g_lvcKAvail[i] = kMax;
   g_lvcOk    [i] = true;
   return(true);
  }

void DrawAptLvlColumn()
  {
   if(!InpLvlColShow)
     {
      if(g_lvcWasOn)
        {
         ObjectsDeleteAll(0, PFX"LVC_");
         for(int z = 0; z < APT_LVC_MAXBARS * APT_LVC_TF; z++)
            g_lvcSig[z] = "";
         g_lvcWasOn = false;
        }
      return;
     }
   g_lvcWasOn = true;

   int nBars = InpLvlColBars;
   if(nBars < 1)
      nBars = 1;
   if(nBars > APT_LVC_MAXBARS)
      nBars = APT_LVC_MAXBARS;
   int nUse = MathMin(nBars, Bars(_Symbol, PERIOD_M1));
   if(nUse < 1)
      return;

   // --- Thong so nen 1m trong pham vi: thoi gian mo, dinh, Close (Close nen 1m dong = Bid cuoi cung cua nen) ---
   datetime tM[APT_LVC_MAXBARS];
   double   hM[APT_LVC_MAXBARS];
   double   cM[APT_LVC_MAXBARS];
   bool     mOk[APT_LVC_MAXBARS];
   for(int m = 0; m < nUse; m++)
     {
      tM[m] = iTime (_Symbol, PERIOD_M1, m);
      hM[m] = iHigh (_Symbol, PERIOD_M1, m);
      cM[m] = iClose(_Symbol, PERIOD_M1, m);
      mOk[m] = (tM[m] > 0 && hM[m] > 0.0);
     }
   // Nen dang chay: dung BID hien tai (cung nguon voi AptWoodieDisplayLvlForTF()).
   double bidNow = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(bidNow > 0.0)
      cM[0] = bidNow;

   int lineH = InpFontSize + 7;

   // --- (<diffpv>+<diffpv2>+<diffpv3>)/3 cua khung g_tfList[0..APT_LVC_VALTF-1] (1m..2h): ghi gia tri tuc thoi vao o lich su cua nen 1m dang chay;
   //     nen da dong giu gia tri cuoi cung ghi nhan duoc. <diffpv> = (RV1 - Pivot)/spread, <diffpv2> = (RV2 - Pivot)/spread, <diffpv3> = (Pivot - OW)/spread (OW = EMA(Open) chu ky n = g_aptBrkDBars, AptOpenLwma()). Thieu du lieu -> khong ghi de (giu gia tri truoc, mac dinh "-").
   if(mOk[0])
     {
      double vSp  = (double)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * _Point;
      int    hs0  = (int)(((long)tM[0] / 60) % APT_LVC_MAXBARS);
      if(g_lvcHT[hs0] != tM[0])
        {
         g_lvcHT[hs0] = tM[0];
         for(int j = 0; j < APT_LVC_VALTF; j++)
            g_lvcHS[hs0][j] = "-";
        }
      int nOw = g_aptBrkDBars;   // OW = EMA(Open) chu ky n = g_aptBrkDBars (cung nguon <diffpv3> tren nhan Pivot)
      if(nOw < 2)   nOw = 2;
      if(nOw > 500) nOw = 500;
      for(int j = 0; j < APT_LVC_VALTF; j++)
        {
         double owJ = 0.0;
         if(vSp > 0.0 && g_rv1ValCache[j] > 0.0 && g_aptRv2AllOk[j] && g_aptRv2All[j] > 0.0 && g_pivotLvlValCache[j] > 0.0
            && AptOpenLwma(g_tfList[j], nOw, owJ) && owJ > 0.0)
           {
            double dPv1 = (g_rv1ValCache[j] - g_pivotLvlValCache[j]) / vSp;
            double dPv2 = (g_aptRv2All[j]   - g_pivotLvlValCache[j]) / vSp;
            double dPv3 = (g_pivotLvlValCache[j] - owJ) / vSp;
            g_lvcHS[hs0][j] = IntegerToString((int)MathRound((dPv1 + dPv2 + dPv3) / 3.0));
           }
        }
     }

   for(int i = 0; i < APT_LVC_TF; i++)
     {
      ENUM_TIMEFRAMES tf = g_tfList[i];
      bool isVal = (i >= APT_LVC_NAMETF);       // hang 7 tro len = gia tri (diffpv+diffpv2+diffpv3)/3, khong phai <TenMuc>
      int  valJ  = i - APT_LVC_NAMETF;          // khung g_tfList[valJ] cua hang gia tri (0..7); >= APT_LVC_VALTF -> hang trong

      // shift cua nen khung tf CHUA tung nen 1m (iBarShift, exact = false); kNeed = shift lon nhat can cache.
      int kOf[APT_LVC_MAXBARS];
      int kNeed = 0;
      for(int m = 0; m < nUse; m++)
        {
         kOf[m] = -1;
         if(!mOk[m])
            continue;
         int k = isVal ? -1 : iBarShift(_Symbol, tf, tM[m], false);   // hang gia tri khong can shift khung / cache muc Woodie
         if(k < 0 || k > APT_LVC_KCAP - 1)
            continue;
         kOf[m] = k;
         if(k > kNeed)
            kNeed = k;
        }
      bool cacheOk = (!isVal) && AptLvcBuildTF(i, kNeed);

      color clr = isVal ? g_color[(valJ < APT_LVC_VALTF) ? valJ : i] : g_color[i];

      for(int m = 0; m < nUse; m++)
        {
         string nm = PFX"LVC_" + IntegerToString(m) + "_" + IntegerToString(i);
         if(!mOk[m])
           {
            ObjectDelete(0, nm);
            continue;
           }

         // --- <TenMuc> cua khung tf tai thoi diem nen 1m thu m: muc EMA gan nhat voi gia (Bid / Close nen 1m) ---
         string lvlTxt = "-";
         if(isVal)
           {
            if(valJ >= APT_LVC_VALTF)       // hang 13, 14: khong ve
              {
               ObjectDelete(0, nm);
               continue;
              }
            int hsM = (int)(((long)tM[m] / 60) % APT_LVC_MAXBARS);
            if(g_lvcHT[hsM] == tM[m])
               lvlTxt = g_lvcHS[hsM][valJ];
           }
         if(!isVal && cacheOk && kOf[m] >= 0 && kOf[m] <= g_lvcKAvail[i] && cM[m] > 0.0)
           {
            int    best = -1;
            double bestD = 0.0;
            for(int lvl = 0; lvl < APT_S1_LVL_COUNT; lvl++)
              {
               double dAbs = MathAbs(cM[m] - g_lvcEma[i][lvl][kOf[m]]);
               if(best < 0 || dAbs < bestD)
                 {
                  best = lvl;
                  bestD = dAbs;
                 }
              }
            if(best >= 0)
               lvlTxt = g_aptLvlName[best];
           }

         // --- Vi tri: ngay tren dinh nen 1m, nhan thu i xep len tren i * lineH pixel (1m o duoi cung) ---
         double basePx = hM[m] + (InpLvlColAbovePts + APT_LVC_EXTRA_PTS) * _Point;
         int xC = 0, yC = 0;
         if(!ChartTimePriceToXY(0, 0, tM[m], basePx, xC, yC))
           {
            ObjectDelete(0, nm);
            continue;
           }
         int      subWin = 0;
         datetime tIt = tM[m];
         double   pIt = basePx;
         if(!ChartXYToTimePrice(0, xC, yC - lineH * i, subWin, tIt, pIt))
           {
            ObjectDelete(0, nm);
            continue;
           }

         // Khong doi so voi lan ve truoc (va object con ton tai) -> bo qua, do ton CPU.
         string sig = lvlTxt + "|" + IntegerToString((long)tM[m]) + "|" + DoubleToString(pIt, _Digits) + "|" + IntegerToString((long)clr);
         int    sgi = m * APT_LVC_TF + i;
         if(g_lvcSig[sgi] == sig && ObjectFind(0, nm) >= 0)
            continue;

         MakeText(nm, tM[m], pIt, lvlTxt, clr, ANCHOR_LOWER);
         ObjectSetString(0, nm, OBJPROP_TOOLTIP, isVal ? (g_tfName[valJ] + " (diffpv+diffpv2+diffpv3)/3 " + lvlTxt) : (g_tfName[i] + " " + lvlTxt));
         g_lvcSig[sgi] = sig;
        }
     }
  }


//==================================================================
//  DrawAptRndDiffColumn: COT 5 GIA TRI chenh lech so voi muc LAM TRON GAN NHAT, khung 1m, nam DUOI DAY nen 1m hien tai, xep doc tu tren xuong v0 -> v4.
//    Muc lam tron = boi so GAN NHAT cua B (nut LAM TRON UI: 1000/100/10; nut x5 = buoc 10 lech 5) - GAN NHAT thuc su (khong gioi han o pham vi W, khong phan biet R / S):
//      lamtron(X) = MathRound((X - off) / B) * B + off.        v = (X - lamtron(X)) / spread, lam tron SO NGUYEN (am = X duoi moc, duong = X tren moc).
//    X: v0 = Bid | v1 = RV1 cua khung 1m (g_rv1ValCache) | v2 = RV2 cua khung 1m (g_aptRv2All) | v3 = gia tri Pivot (EMA Pivot cua muc chon o bang Pivot UI, AptPivotUiEmaSeries()[0])
//       | v4 = OW cua khung 1m (EMA(Open) chu ky n = g_aptBrkDBars, AptOpenLwma()). Thieu du lieu / spread <= 0 -> "-" (khong doan).
//    Object text PFX"RDC_"+j (j = 0..4): neo ANCHOR_UPPER ngay duoi Low nen 1m dang chay, cach nhau (InpFontSize+7) pixel. Chi doc gia, OnDeinit don bang ObjectsDeleteAll(0,PFX).
//==================================================================
void DrawAptRndDiffColumn()
  {
   datetime tM1  = iTime(_Symbol, PERIOD_M1, 0);
   double   loM1 = iLow (_Symbol, PERIOD_M1, 0);
   if(tM1 <= 0 || loM1 <= 0.0)
      return;

   double spread = (double)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * _Point;
   int    ridx   = (g_aptRndIdx < 0 || g_aptRndIdx > 3) ? 1 : g_aptRndIdx;   // cung cach AptRoundNearStr()
   double step   = (double)g_aptRndVals[ridx];
   double off    = (double)g_aptRndOff[ridx];

   int mi = AptFindTfIndex(PERIOD_M1);
   if(mi < 0 || mi >= 14)
      mi = 0;

   double xv[5];
   xv[0] = SymbolInfoDouble(_Symbol, SYMBOL_BID);                       // v0: Bid
   xv[1] = g_rv1ValCache[mi];                                           // v1: RV1 1m
   xv[2] = g_aptRv2AllOk[mi] ? g_aptRv2All[mi] : 0.0;                   // v2: RV2 1m
   xv[3] = 0.0;                                                         // v3: Pivot (muc chon o bang Pivot UI)
   double pvSer[];
   if(AptPivotUiEmaSeries(PERIOD_M1, 3, pvSer) > 0)
      xv[3] = pvSer[0];
   xv[4] = 0.0;                                                         // v4: OW 1m
   int nOw = g_aptBrkDBars;
   if(nOw < 2)   nOw = 2;
   if(nOw > 500) nOw = 500;
   double ow = 0.0;
   if(AptOpenLwma(PERIOD_M1, nOw, ow))
      xv[4] = ow;

   string txt[5];
   for(int j = 0; j < 5; j++)
     {
      txt[j] = "-";
      if(spread > 0.0 && step > 0.0 && xv[j] > 0.0)
        {
         double nr = MathRound((xv[j] - off) / step) * step + off;      // muc lam tron gan nhat
         txt[j] = IntegerToString((int)MathRound((xv[j] - nr) / spread));
        }
     }

   int xC = 0, yC = 0;
   if(!ChartTimePriceToXY(0, 0, tM1, loM1, xC, yC))
      return;   // khong doi duoc toa do -> giu nguyen nhan cu
   int lineH = InpFontSize + 7;

   static string s_rdcSig[5];
   string tip[5] = {"v0 = (Bid - lamtron)/spread", "v1 = (RV1 - lamtron)/spread", "v2 = (RV2 - lamtron)/spread",
                    "v3 = (Pivot - lamtron)/spread", "v4 = (OW - lamtron)/spread"};
   for(int j = 0; j < 5; j++)
     {
      string   nm     = PFX"RDC_" + IntegerToString(j);
      int      subWin = 0;
      datetime tIt    = tM1;
      double   pIt    = loM1;
      if(!ChartXYToTimePrice(0, xC, yC + 4 + lineH * j, subWin, tIt, pIt))
         continue;

      // Khong doi so voi lan ve truoc (va object con ton tai) -> bo qua, do ton CPU.
      string sig = txt[j] + "|" + IntegerToString((long)tM1) + "|" + DoubleToString(pIt, _Digits);
      if(s_rdcSig[j] == sig && ObjectFind(0, nm) >= 0)
         continue;

      MakeText(nm, tM1, pIt, txt[j], g_color[0], ANCHOR_UPPER);
      ObjectSetString(0, nm, OBJPROP_TOOLTIP, tip[j]);
      s_rdcSig[j] = sig;
     }
  }

//+------------------------------------------------------------------+
//| FindM1Shift: tim index M1 (series, 0=moi nhat) co open time <=    |
//| atTime, gan nhat hien tai — soi guong iBarShift(M1, atTime).      |
//+------------------------------------------------------------------+
int FindM1Shift(const datetime &tm[], int got, datetime atTime)
{
   if(got <= 0) return -1;
   if(atTime >= tm[0]) return 0;
   if(atTime < tm[got - 1]) return -1;
   int lo = 0, hi = got - 1;
   while(lo < hi)
   {
      int mid = (lo + hi) / 2;
      if(tm[mid] > atTime) lo = mid + 1;
      else                 hi = mid;
   }
   return lo;   // tm[lo] <= atTime, moi nhat trong cac bar thoa
}

//+------------------------------------------------------------------+
//| DrawRvLinesSelTF: ve duong RV2 (prefix g_rv2LinePrefix) va duong RV1 (prefix RIENG g_rv1LinePrefix) cua khung chon o nut UI    |
//|   (AptExtraLineTf()). Chuoi rv[]/tSample[]/points/step la RV1 tai moi nen cua khung do (tinh truoc khi EMA ra RV2).            |
//|   RV2: mau GetRV2Color(tf); RV1: mau clrMagenta; ca hai net dash, do day 1 (OBJ_TREND, nhieu doan).                            |
//+------------------------------------------------------------------+
void DrawRvLinesSelTF()
{
   SSpmScopeTimer __spmTimer("DrawRvLinesSelTF");
   ENUM_TIMEFRAMES tf = PERIOD_CURRENT;
   if(!AptExtraLineTf(tf))
   {
      ObjectsDeleteAll(0, g_rv2LinePrefix, -1, OBJ_TREND);
      ObjectsDeleteAll(0, g_rv1LinePrefix, -1, OBJ_TREND);
      return;
   }

   int emaP = MathMax(1, g_aptRv2EmaPeriod);
   int warm = emaP * 4;
   if(warm < emaP + 2) warm = emaP + 2;
   int dispBarsTF = InpHistPoints;
   if(dispBarsTF < 2) dispBarsTF = 2;

   //--- So nen M1 can = (dispBarsTF + warm) * nBars[tf] + nBars[tf] ---
   int nB   = GetRV2NBars(tf);
   int need = (dispBarsTF + warm) * nB + nB;
   if(need > 100000) need = 100000;

   double   hi[], lo[], cl[];
   long     tv[];
   datetime tm[];
   ArraySetAsSeries(hi, true);
   ArraySetAsSeries(lo, true);
   ArraySetAsSeries(cl, true);
   ArraySetAsSeries(tv, true);
   ArraySetAsSeries(tm, true);

   int cpH = CopyHigh      (_Symbol, PERIOD_M1, 0, need, hi);
   int cpL = CopyLow       (_Symbol, PERIOD_M1, 0, need, lo);
   int cpC = CopyClose     (_Symbol, PERIOD_M1, 0, need, cl);
   int cpV = CopyTickVolume(_Symbol, PERIOD_M1, 0, need, tv);
   int cpT = CopyTime      (_Symbol, PERIOD_M1, 0, need, tm);
   int got = MathMin(MathMin(MathMin(cpH, cpL), MathMin(cpC, cpV)), cpT);
   if(got <= nB)
   {
      ObjectsDeleteAll(0, g_rv2LinePrefix, -1, OBJ_TREND);
      ObjectsDeleteAll(0, g_rv1LinePrefix, -1, OBJ_TREND);
      return; // khong du du lieu M1
   }

   //--- Prefix-sum ---
   double cumTPV[], cumVol[];
   ArrayResize(cumTPV, got + 1);
   ArrayResize(cumVol, got + 1);
   cumTPV[got] = 0.0;
   cumVol[got] = 0.0;
   for(int s = got - 1; s >= 0; s--)
   {
      double tp = (hi[s] + lo[s] + cl[s]) / 3.0;
      double v  = (double)tv[s];
      cumTPV[s] = cumTPV[s + 1] + tp * v;
      cumVol[s] = cumVol[s + 1] + v;
   }

   ObjectsDeleteAll(0, g_rv2LinePrefix, -1, OBJ_TREND);
   ObjectsDeleteAll(0, g_rv1LinePrefix, -1, OBJ_TREND);

   int needTF = dispBarsTF + warm;   // du warmup + doan hien thi

   //--- Lay thoi gian tung nen cua khung TF (series: 0 = moi nhat) ---
   datetime tmTF[];
   ArraySetAsSeries(tmTF, true);
   int gotTF = CopyTime(_Symbol, tf, 0, needTF, tmTF);
   if(gotTF < warm + 1)
      return;

   //--- RV1 tai moi nen TF: VWAP N nen M1 ket thuc tai thoi diem neo - dung
   //    lam gia tri trung gian de EMA ra RV2, KHONG ve duong RV1 nao ---
   double   rv[];
   datetime tSample[];
   ArrayResize(rv,      gotTF);
   ArrayResize(tSample, gotTF);
   int avail = 0;
   for(int k = 0; k < gotTF; k++)
   {
      datetime atTime = (k == 0) ? TimeCurrent() : (tmTF[k] + (datetime)PeriodSeconds(tf) - 1);
      int m1sh = FindM1Shift(tm, got, atTime);
      if(m1sh < 0 || m1sh + nB >= got)
         break;   // het du lieu M1 cho cua so rolling

      double wVol = cumVol[m1sh] - cumVol[m1sh + nB];
      double v    = (wVol > 0.0) ? (cumTPV[m1sh] - cumTPV[m1sh + nB]) / wVol : 0.0;
      if(v <= 0.0) break;

      rv[k]      = v;
      tSample[k] = tmTF[k];
      avail      = k + 1;
   }
   if(avail < warm + 1)
      return;

   //--- So diem hien thi thuc te (cat phan warmup) ---
   int points = avail - warm;
   if(points > dispBarsTF) points = dispBarsTF;
   if(points < 1)
      return;

   //--- EMA(emaP) cua rv[], tinh tu cu nhat (avail-1) -> moi nhat (0) ---
   double ema[];
   ArrayResize(ema, avail);
   double alpha   = 2.0 / (emaP + 1.0);
   double seedSum = 0.0;
   for(int s = avail - 1; s >= avail - emaP; s--)
      seedSum += rv[s];
   double emaVal = seedSum / (double)emaP;
   for(int s = avail - 1; s >= avail - emaP; s--)
      ema[s] = 0.0;
   for(int s = avail - emaP - 1; s >= 0; s--)
   {
      emaVal = alpha * rv[s] + (1.0 - alpha) * emaVal;
      ema[s] = emaVal;
   }

   color lineColor = GetRV2Color(tf);

   //--- Ve polyline RV2(5m) tren cac nen 5m (moi diem = 1 nen 5m) ---
   int      step  = MathMax(1, points / InpMaxSegments);
   datetime prevT = 0;
   double   prevV = 0.0;
   int      seg   = 0;

   for(int s = points - 1; s >= 0; s -= step)
   {
      double val = ema[s];
      if(val > 0.0)
      {
         if(prevT > 0)
         {
            string nm = g_rv2LinePrefix + IntegerToString(seg++);
            if(ObjectCreate(0, nm, OBJ_TREND, 0, prevT, prevV, tSample[s], val))
            {
               ObjectSetInteger(0, nm, OBJPROP_COLOR,      lineColor);
               ObjectSetInteger(0, nm, OBJPROP_WIDTH,      1);
               ObjectSetInteger(0, nm, OBJPROP_STYLE,      STYLE_DASH);   // STYLE_DASH chi hien khi WIDTH = 1
               ObjectSetInteger(0, nm, OBJPROP_RAY_RIGHT,  false);
               ObjectSetInteger(0, nm, OBJPROP_RAY_LEFT,   false);
               ObjectSetInteger(0, nm, OBJPROP_SELECTABLE, false);
               ObjectSetInteger(0, nm, OBJPROP_HIDDEN,     true);
               ObjectSetInteger(0, nm, OBJPROP_BACK,       true);
            }
         }
         prevT = tSample[s];
         prevV = val;
      }
   }

   //--- Dam bao diem cuoi (s=0, RV2(5m) moi nhat) luon co mat ---
   if(((points - 1) % step) != 0)
   {
      double val0 = ema[0];
      if(val0 > 0.0 && prevT > 0)
      {
         string nm0 = g_rv2LinePrefix + IntegerToString(seg++);
         if(ObjectCreate(0, nm0, OBJ_TREND, 0, prevT, prevV, tSample[0], val0))
         {
            ObjectSetInteger(0, nm0, OBJPROP_COLOR,      lineColor);
            ObjectSetInteger(0, nm0, OBJPROP_WIDTH,      1);
            ObjectSetInteger(0, nm0, OBJPROP_STYLE,      STYLE_DASH);   // STYLE_DASH chi hien khi WIDTH = 1
            ObjectSetInteger(0, nm0, OBJPROP_RAY_RIGHT,  false);
            ObjectSetInteger(0, nm0, OBJPROP_RAY_LEFT,   false);
            ObjectSetInteger(0, nm0, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, nm0, OBJPROP_HIDDEN,     true);
            ObjectSetInteger(0, nm0, OBJPROP_BACK,       true);
         }
      }
   }

   color rv1Color5m = clrMagenta;
   datetime prevT1m5 = 0;
   double   prevV1m5 = 0.0;
   int      seg1m5   = 0;

   for(int s = points - 1; s >= 0; s -= step)
   {
      double val1 = rv[s];
      if(val1 > 0.0)
      {
         if(prevT1m5 > 0)
         {
            string nm1 = g_rv1LinePrefix + IntegerToString(seg1m5++);
            if(ObjectCreate(0, nm1, OBJ_TREND, 0, prevT1m5, prevV1m5, tSample[s], val1))
            {
               ObjectSetInteger(0, nm1, OBJPROP_COLOR,      rv1Color5m);
               ObjectSetInteger(0, nm1, OBJPROP_WIDTH,      1);
               ObjectSetInteger(0, nm1, OBJPROP_STYLE,      STYLE_DASH);   // STYLE_DASH chi hien khi WIDTH = 1
               ObjectSetInteger(0, nm1, OBJPROP_RAY_RIGHT,  false);
               ObjectSetInteger(0, nm1, OBJPROP_RAY_LEFT,   false);
               ObjectSetInteger(0, nm1, OBJPROP_SELECTABLE, false);
               ObjectSetInteger(0, nm1, OBJPROP_HIDDEN,     true);
               ObjectSetInteger(0, nm1, OBJPROP_BACK,       true);
            }
         }
         prevT1m5 = tSample[s];
         prevV1m5 = val1;
      }
   }

   //--- Dam bao diem cuoi (s=0, RV1(5m) moi nhat) luon co mat ---
   if(((points - 1) % step) != 0)
   {
      double val10 = rv[0];
      if(val10 > 0.0 && prevT1m5 > 0)
      {
         string nm10 = g_rv1LinePrefix + IntegerToString(seg1m5++);
         if(ObjectCreate(0, nm10, OBJ_TREND, 0, prevT1m5, prevV1m5, tSample[0], val10))
         {
            ObjectSetInteger(0, nm10, OBJPROP_COLOR,      rv1Color5m);
            ObjectSetInteger(0, nm10, OBJPROP_WIDTH,      1);
            ObjectSetInteger(0, nm10, OBJPROP_STYLE,      STYLE_DASH);   // STYLE_DASH chi hien khi WIDTH = 1
            ObjectSetInteger(0, nm10, OBJPROP_RAY_RIGHT,  false);
            ObjectSetInteger(0, nm10, OBJPROP_RAY_LEFT,   false);
            ObjectSetInteger(0, nm10, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, nm10, OBJPROP_HIDDEN,     true);
            ObjectSetInteger(0, nm10, OBJPROP_BACK,       true);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| LblDpiScale: he so quy doi pixel theo DPI man hinh |
//|   dang chay (96 DPI = 1.0). Dung de nhan khe ho InpLblAutoPadPx    |
//|   -> khe ho NHIN THAY bang nhau tren man hinh thuong va man hinh   |
//|   do phan giai cao. Doc that bai -> tra 1.0 (khong doan bua).      |
//+------------------------------------------------------------------+
double LblDpiScale()
{
   long dpi = TerminalInfoInteger(TERMINAL_SCREEN_DPI);
   if(dpi <= 0) return 1.0;
   double sc = (double)dpi / 96.0;
   if(sc < 0.5) sc = 0.5;
   if(sc > 4.0) sc = 4.0;
   return sc;
}

//+------------------------------------------------------------------+
//| LblRowGapPx: khoang cach DOC (pixel) toi thieu giua hai hang nhan lien tiep (Pivot / RV1 / RV2) cho co chu fs, |
//|   lay LON NHAT cua ba gia tri:                                                                                    |
//|     1) fs + 5                                                                                                    |
//|     2) chieu cao chu do bang TextGetSize("Wg") voi font Arial co chu am (-fs*10 = theo DPI) + 3 pixel             |
//|     3) (fs + 5) * LblDpiScale()       (quy doi theo DPI man hinh)                                                |
//|   Do chu that bai -> chi con gia tri 1) va 3).                                                                    |
//+------------------------------------------------------------------+
int LblRowGapPx(const int fs)
{
   int f    = (fs < 1) ? 1 : fs;
   int gOld = f + 5;
   int gDpi = (int)MathCeil((double)gOld * LblDpiScale());
   int gTxt = 0;
   uint tw = 0, th = 0;
   if(TextSetFont("Arial", -f * 10) && TextGetSize("Wg", tw, th) && th > 0)
      gTxt = (int)th + 3;
   int g = gOld;
   if(gDpi > g) g = gDpi;
   if(gTxt > g) g = gTxt;
   return g;
}

//+------------------------------------------------------------------+
//| LblTextWidthPx: do BE RONG THUC TE (pixel) cua mot chuoi khi duoc ve  |
//|   bang font mac dinh cua OBJ_TEXT ("Arial") voi co chu fs (diem).      |
//|   Truyen co chu AM (-fs*10 = don vi 1/10 diem) cho TextSetFont de MT5  |
//|   tu nhan theo DPI man hinh, khop cach OBJPROP_FONTSIZE duoc render.   |
//|   Do that bai -> tra 0 de ben goi quay ve gia tri input.               |
//+------------------------------------------------------------------+
int LblTextWidthPx(const string txt, const int fs)
{
   if(txt == "") return 0;
   int f = (fs < 1) ? 1 : fs;
   if(!TextSetFont("Arial", -f * 10)) return 0;

   uint w = 0, h = 0;
   if(!TextGetSize(txt, w, h)) return 0;
   return (int)w;
}

//+------------------------------------------------------------------+
//| LblWidestSample: dung chuoi DAI NHAT co the xuat hien |
//|   o mot cot nhan, theo dung dinh dang dang dung:                   |
//|     cot Pivot  : "-100.0 / -100.0 <ten khung dai nhat>"            |
//|     cot RV2/RV1: "-100.0/-100.0 <ten khung dai nhat>"              |
//|   (so chu so thap phan truyen vao qua dgR/dgD, dau cach quanh ky   |
//|   tu '/' bat/tat qua spaced). RSI nam trong 0..100 va do lech nam  |
//|   trong -100..100 nen day la truong hop dai nhat co the xay ra.    |
//+------------------------------------------------------------------+
string LblWidestSample(const int dgR, const int dgD, const bool spaced)
{
   string tfW = g_tfName[0];
   for(int i = 1; i < RV2_TF_COUNT; i++)
      if(StringLen(g_tfName[i]) > StringLen(tfW)) tfW = g_tfName[i];

   string sep = spaced ? " / " : "/";
   return "-" + DoubleToString(100.0, dgR) + sep +
          "-" + DoubleToString(100.0, dgD) + " " + tfW;
}

//+------------------------------------------------------------------+
//| LblColMeasure: do BE RONG PIXEL THAT cua chuoi DAI NHAT dang thuc su  |
//|   hien tren chart cua mot cot nhan, va lay luon MOC THOI GIAN THAT ma  |
//|   cot do dang neo.                                                    |
//|   Cach lam: quet cac object OBJ_TEXT co ten bat dau bang prefix, doc   |
//|   OBJPROP_TEXT va OBJPROP_FONTSIZE cua tung object roi do bang        |
//|   LblTextWidthPx; cot ben phai dat sat mep phai cot ben trai.          |
//|   outTime = moc thoi gian LON NHAT trong nhom (cac nhan cua mot cot    |
//|   chung mot moc nen day chinh la moc cua cot).                        |
//|   Khong tim thay object nao / do that bai -> tra 0 va outTime = 0.     |
//|   Ham chi doc object.                                                  |
//+------------------------------------------------------------------+
int LblColMeasure(const string prefix, datetime &outTime)
{
   outTime = 0;
   int pLen = StringLen(prefix);
   if(pLen < 1) return 0;

   int wMax = 0;
   int tot  = ObjectsTotal(0, -1, OBJ_TEXT);
   for(int k = 0; k < tot; k++)
   {
      string nm = ObjectName(0, k, -1, OBJ_TEXT);
      if(StringLen(nm) < pLen)                continue;
      if(StringSubstr(nm, 0, pLen) != prefix) continue;

      string txt = ObjectGetString(0, nm, OBJPROP_TEXT);
      if(txt == "") continue;

      int fs = (int)ObjectGetInteger(0, nm, OBJPROP_FONTSIZE);
      if(fs < 1) fs = 6;

      int w = LblTextWidthPx(txt, fs);
      if(w > wMax) wMax = w;

      datetime t = (datetime)ObjectGetInteger(0, nm, OBJPROP_TIME, 0);
      if(t > outTime) outTime = t;
   }
   return wMax;
}

//==================================================================
//  Wpr8* : William %R + MA tren RV1(1m) / RV2(1m) (cong thuc WPR_rVWAP_Osc.mq5: WprOnSeries + SignalMA), cho cac nhan RV1.
//  AutoPositionTool_UI.mq5 la indicator 0 buffer/0 plot nen phai tu dung lai chuoi RV1(1m)/RV2(1m) lui ve qua khu (Copy M1 rieng) roi tinh William %R + MA mot lan.
//  RV1(1m) tai shift k (k=0 la nen M1 dang chay, k>0 la nen M1 dong cach k nen) = hlc3 = (H+L+C)/3 cua chinh nen M1 do (VWAP cua N=1 nen M1, khop dinh nghia RV1 trong file).
//  RV2(1m) = EMA(g_aptRv2EmaPeriod) ap len chuoi RV1(1m) o tren, seed = SMA cac mau CU NHAT roi lam muot dan ve shift 0.
//  Tham so: cac input Wpr8* va Ma8* (nhom "10.").
//==================================================================

//+------------------------------------------------------------------+
//| Wpr8NeedM1Bars: so nen M1 can Copy de ca hai bo ba (RV1 va RV2)   |
//|   co du du lieu tinh William %R + MA (seed warmup EMA/SMMA =      |
//|   period*4, toi thieu period+2 - CUNG cong thuc warm da dung khap |
//|   period*4, toi thieu period+2). Ban RV2 can cong THEM g_aptRv2EmaPeriod vi   |
//|   chinh no da la EMA cua RV1.                                    |
//+------------------------------------------------------------------+
int Wpr8NeedM1Bars()
{
   int needWpr1 = MathMax(InpMa8Period1 * 4, InpMa8Period1 + 2);
   int needWpr2 = MathMax(InpMa8Period  * 4, InpMa8Period  + 2);
   int total1   = needWpr1 + InpWpr8Period1;
   int total2   = g_aptRv2EmaPeriod + needWpr2 + InpWpr8Period;
   int need     = MathMax(total1, total2) + 5;
   if(need < 10) need = 10;
   return need;
}

//+------------------------------------------------------------------+
//| Wpr8BuildRv1M1Series: mang RV1(1m) lui ve qua khu, index 0 = nen  |
//|   M1 dang chay (hlc3 cua no), index k>0 = nen M1 dong cach k nen. |
//|   Tra ve so phan tu THUC SU lay duoc (co the < need neu thieu     |
//|   lich su M1) - KHONG lam tron/doan bua phan thieu.               |
//+------------------------------------------------------------------+
int Wpr8BuildRv1M1Series(int need, double &outRv1[])
{
   if(need < 1) need = 1;
   double hi[], lo[], cl[];
   ArraySetAsSeries(hi, true);
   ArraySetAsSeries(lo, true);
   ArraySetAsSeries(cl, true);

   int got = CopyHigh (_Symbol, PERIOD_M1, 0, need, hi);
   int gL  = CopyLow  (_Symbol, PERIOD_M1, 0, need, lo);
   int gC  = CopyClose(_Symbol, PERIOD_M1, 0, need, cl);
   if(gL < got) got = gL;
   if(gC < got) got = gC;
   if(got <= 0)
   {
      ArrayResize(outRv1, 0);
      return 0;
   }

   ArrayResize(outRv1, got);
   for(int k = 0; k < got; k++)
      outRv1[k] = (hi[k] + lo[k] + cl[k]) / 3.0;
   return got;
}

//+------------------------------------------------------------------+
//| Wpr8BuildRv2M1Series: mang RV2 = EMA(emaPeriod) ap len chuoi RV1 (rv1[] dau vao), |
//|   seed = SMA(emaPeriod) cac mau CU NHAT, lam muot dan ve shift 0. Tra ve so phan tu |
//|   HOP LE cua outRv2 (vung seed dau khong dung duoc, danh dau bang 0.0).        |
//+------------------------------------------------------------------+
int Wpr8BuildRv2M1Series(const double &rv1[], int avail, int emaPeriod, double &outRv2[])
{
   if(emaPeriod < 1) emaPeriod = 1;
   ArrayResize(outRv2, avail);
   if(avail < emaPeriod + 1)
   {
      ArrayResize(outRv2, 0);
      return 0;
   }

   double alpha   = 2.0 / (emaPeriod + 1.0);
   double seedSum = 0.0;
   for(int s = avail - 1; s >= avail - emaPeriod; s--)
      seedSum += rv1[s];
   double emaVal = seedSum / (double)emaPeriod;
   for(int s = avail - 1; s >= avail - emaPeriod; s--)
      outRv2[s] = 0.0;
   for(int s = avail - emaPeriod - 1; s >= 0; s--)
   {
      emaVal    = alpha * rv1[s] + (1.0 - alpha) * emaVal;
      outRv2[s] = emaVal;
   }
   return avail - emaPeriod;   // so phan tu [0 .. avail-emaPeriod-1] dung duoc
}

//+------------------------------------------------------------------+
//| Wpr8WilliamsRAt: William %R tai shift s cua chuoi src[] (index 0 |
//|   = moi nhat), nhin lui dung "period" phan tu [s .. s+period-1]. |
//|   Cong thuc y het WprOnSeries() cua WPR_rVWAP_Osc.mq5. Thieu du   |
//|   lieu (s+period > validCount) -> tra EMPTY_VALUE.                |
//+------------------------------------------------------------------+
double Wpr8WilliamsRAt(const double &src[], int validCount, int s, int period)
{
   if(period < 1) period = 1;
   if(s < 0 || s + period > validCount) return EMPTY_VALUE;

   double hh = -DBL_MAX, ll = DBL_MAX;
   for(int j = 0; j < period; j++)
   {
      double v = src[s + j];
      if(v > hh) hh = v;
      if(v < ll) ll = v;
   }
   double cur = src[s];
   if(hh == ll) return 0.0;
   return -100.0 * (hh - cur) / (hh - ll);
}

//+------------------------------------------------------------------+
//| Wpr8UnclampedAt: William |
//|   %R KHONG ke 0..-100 cho <WPR1>/<WPR2>. Cung cong thuc nhung hh/ll|
//|   lay tren "period" phan tu TRUOC [s+1 .. s+period] (KHONG gom    |
//|   phan tu hien tai src[s]) nen src[s] co the vuot hh (>0) hoac    |
//|   thung ll (<-100). Thieu du lieu (s+1+period > validCount) ->    |
//|   EMPTY_VALUE. Wpr8WilliamsRAt() la ban co kep 0..-100.             |
//+------------------------------------------------------------------+
double Wpr8UnclampedAt(const double &src[], int validCount, int s, int period)
{
   if(period < 1) period = 1;
   if(s < 0 || s + 1 + period > validCount) return EMPTY_VALUE;

   double hh = -DBL_MAX, ll = DBL_MAX;
   for(int j = 1; j <= period; j++)
   {
      double v = src[s + j];
      if(v > hh) hh = v;
      if(v < ll) ll = v;
   }
   double cur = src[s];
   if(hh == ll) return 0.0;
   return -100.0 * (hh - cur) / (hh - ll);
}

//+------------------------------------------------------------------+
//| Wpr8ComputeMa: MA (SMA/EMA/SMMA/LWMA) cua chuoi William %R tai    |
//|   shift 0, dung mang wpr[] da tinh san o "period" shift lien tiep   |
//|   [0..period-1] (validWpr = so shift wpr[] hop le). EMA/SMMA: seed  |
//|   = SMA(period) cac mau CU NHAT roi lam muot dan ve shift 0 (khong co |
//|   bo dem qua tung tick nen tinh mot phat); SMA/LWMA tinh truc tiep  |
//|   tren "period" shift dau. Thieu du lieu -> tra EMPTY_VALUE.          |
//+------------------------------------------------------------------+
double Wpr8ComputeMa(const double &wpr[], int validWpr, int period, ENUM_MA_METHOD method)
{
   if(period <= 1)
      return (validWpr >= 1) ? wpr[0] : EMPTY_VALUE;
   if(validWpr < period)
      return EMPTY_VALUE;

   switch(method)
   {
      case MODE_LWMA:
      {
         double sw = 0.0, sww = 0.0;
         for(int j = 0; j < period; j++)
         {
            double w = (double)(period - j);
            sw  += wpr[j] * w;
            sww += w;
         }
         return (sww > 0.0) ? sw / sww : EMPTY_VALUE;
      }
      case MODE_EMA:
      case MODE_SMMA:
      {
         if(validWpr < period + 1) return EMPTY_VALUE;
         double seed = 0.0;
         for(int s = validWpr - 1; s >= validWpr - period; s--)
            seed += wpr[s];
         double val   = seed / (double)period;
         double alpha = 2.0 / (period + 1.0);
         for(int s = validWpr - period - 1; s >= 0; s--)
         {
            if(method == MODE_EMA)
               val = alpha * wpr[s] + (1.0 - alpha) * val;
            else // MODE_SMMA
               val = (val * (period - 1) + wpr[s]) / period;
         }
         return val;
      }
      default: // MODE_SMA
      {
         double s = 0.0;
         for(int j = 0; j < period; j++)
            s += wpr[j];
         return s / period;
      }
   }
}

//+------------------------------------------------------------------+
//| Wpr8BuildTripleStr: go chuoi "{dWPR}/{WPR}/{MA}" tu MOT chuoi RV  |
//|   (rv1(1m) hoac rv2(1m)) - CUNG quy uoc voi WPR_rVWAP_Osc.mq5:    |
//|   thieu shift 1 (khong tinh duoc dWPR) -> BO qua ca dau "/" cua   |
//|   no (chi con "{WPR}/{MA}" hoac "{WPR}" neu MA cung thieu); MA    |
//|   thieu -> bo qua dau "/" cua rieng no. So NGUYEN, lam tron 0     |
//|   chu so thap phan (DoubleToString(...,0)) y het WPR_rVWAP_Osc.   |
//+------------------------------------------------------------------+
string Wpr8BuildTripleStr(const double &rv[], int validCount, int wprPeriod, int maPeriod, ENUM_MA_METHOD maMethod)
{
   double wpr0 = Wpr8UnclampedAt(rv, validCount, 0, wprPeriod);
   if(wpr0 == EMPTY_VALUE)
      return "";

   string txt = DoubleToString(wpr0, 0);

   double wpr1 = Wpr8UnclampedAt(rv, validCount, 1, wprPeriod);
   if(wpr1 != EMPTY_VALUE)
      txt = DoubleToString(wpr0 - wpr1, 0) + "/" + txt;

   //--- mang wpr[] cho Wpr8ComputeMa: shift j can Wpr8WilliamsRAt(rv,validCount,j,wprPeriod)
   int needWpr = maPeriod * 4;
   if(needWpr < maPeriod + 2) needWpr = maPeriod + 2;
   double wprArr[];
   ArrayResize(wprArr, needWpr);
   int validWpr = 0;
   for(int j = 0; j < needWpr; j++)
   {
      double v = Wpr8UnclampedAt(rv, validCount, j, wprPeriod);
      if(v == EMPTY_VALUE) break;
      wprArr[j] = v;
      validWpr  = j + 1;
   }

   double ma = Wpr8ComputeMa(wprArr, validWpr, maPeriod, maMethod);
   if(ma != EMPTY_VALUE)
      txt = txt + "/" + DoubleToString(ma, 0);

   return txt;
}

//+------------------------------------------------------------------+
//| Wpr8BuildMaStr: CHI tra phan |
//|   <MA> (so nguyen, lam tron 0 chu so) cua Wpr8BuildTripleStr()   |
//|   - CUNG cach lay mau wpr[] va CUNG Wpr8ComputeMa(). Thieu du     |
//|   lieu (khong tinh duoc WPR hoac MA) -> tra "" . KHONG sua        |
//|   Wpr8BuildTripleStr().                                          |
//+------------------------------------------------------------------+
string Wpr8BuildMaStr(const double &rv[], int validCount, int wprPeriod, int maPeriod, ENUM_MA_METHOD maMethod)
{
   double wpr0 = Wpr8UnclampedAt(rv, validCount, 0, wprPeriod);
   if(wpr0 == EMPTY_VALUE)
      return "";

   int needWpr = maPeriod * 4;
   if(needWpr < maPeriod + 2) needWpr = maPeriod + 2;
   double wprArr[];
   ArrayResize(wprArr, needWpr);
   int validWpr = 0;
   for(int j = 0; j < needWpr; j++)
   {
      double v = Wpr8UnclampedAt(rv, validCount, j, wprPeriod);
      if(v == EMPTY_VALUE) break;
      wprArr[j] = v;
      validWpr  = j + 1;
   }

   double ma = Wpr8ComputeMa(wprArr, validWpr, maPeriod, maMethod);
   if(ma == EMPTY_VALUE)
      return "";
   return DoubleToString(ma, 0);
}

//==================================================================
  //  KENH HH/LL TINH TREN CHUOI RV1 / RV2 (cung cach AptBrkDAt()/AptBrkWAt()/AptErhErlStr()):
  //    Chu ky kenh P = g_aptBrkDBars (nut B<n>, kep 2..500). Chuoi rv[] index 0 = moi nhat (RV1 hoac RV2 cua khung).
  //    HH[k] = max rv[1+k .. P+k], LL[k] = min rv[1+k .. P+k]  (k = 0 la kenh P gia tri DA DONG ngay truoc rv[0], khong gom rv[0]).
  //    W%  = (HH[0] - rv[0]) / (HH[0] - LL[0]) * -100, so nguyen, khong kep (rv[0] pha kenh -> >0 hoac < -100).
  //    erh = EMA(RSI(HH,P),P), erl = EMA(RSI(LL,P),P) tren chuoi HH/LL cua RV: "<erh>/<erhdiff> <erl>/<erldiff>" (diff = so voi gia tri truoc, so nguyen, "+" khi duong).
  //    Thieu du lieu -> false (noi goi in "-" / "-/- -/-"). Ham chi doc mang rv[].
//==================================================================
int AptRvChanP()
{
   int p = g_aptBrkDBars;
   if(p < 2)   p = 2;
   if(p > 500) p = 500;
   return p;
}

// So gia tri RV can co: P (kenh) + 4P+1 (chuoi HH/LL cho erh/erl) + canh an toan; RV2 can cong them chu ky EMA cua RV2.
int AptRvChanNeed()
{
   return g_aptRv2EmaPeriod + 5 * AptRvChanP() + 5;
}

bool AptRvChanW(const double &rv[], const int validCount, int &outW)
{
   outW = 0;
   const int p = AptRvChanP();
   if(validCount < p + 1)
      return false;
   double cur = rv[0];
   if(cur <= 0.0)
      return false;
   double hh = -DBL_MAX, ll = DBL_MAX;
   for(int j = 1; j <= p; j++)
   {
      double v = rv[j];
      if(v <= 0.0)
         return false;
      if(v > hh) hh = v;
      if(v < ll) ll = v;
   }
   double den = hh - ll;
   if(den <= 0.0)
      return false;
   outW = (int)MathRound((hh - cur) / den * -100.0);
   return true;
}

bool AptRvChanErStr(const double &rv[], const int validCount, string &outStr)
{
   outStr = "";
   const int p = AptRvChanP();
   int m = 4 * p + 1;
   if(m > validCount - p)
      m = validCount - p;
   if(m < 2 * p + 1)
      return false;

   const int cnt = p + m - 1;            // dung rv[1 .. cnt]
   double val[];
   ArrayResize(val, cnt);
   for(int j = 0; j < cnt; j++)          // chrono: j = 0 cu nhat (rv[cnt]) ... j = cnt-1 moi nhat (rv[1])
   {
      double v = rv[cnt - j];
      if(v <= 0.0)
         return false;
      val[j] = v;
   }

   double hhS[], llS[];
   int    dqH[], dqL[];
   ArrayResize(hhS, m);
   ArrayResize(llS, m);
   ArrayResize(dqH, cnt);
   ArrayResize(dqL, cnt);
   int hH = 0, tH = 0, hL = 0, tL = 0;
   for(int j = 0; j < cnt; j++)
   {
      while(tH > hH && val[dqH[tH - 1]] <= val[j])
         tH--;
      dqH[tH++] = j;
      while(dqH[hH] <= j - p)
         hH++;
      while(tL > hL && val[dqL[tL - 1]] >= val[j])
         tL--;
      dqL[tL++] = j;
      while(dqL[hL] <= j - p)
         hL++;
      if(j >= p - 1)
      {
         hhS[j - p + 1] = val[dqH[hH]];
         llS[j - p + 1] = val[dqL[hL]];
      }
   }

   double erhS[];
   if(!AptRsiEmaSeries(hhS, m, p, erhS))
      return false;
   double erh = erhS[m - 1], erhP = erhS[m - 2];
   double erl = 0.0, erlP = 0.0;
   if(!AptRsiEmaLast(llS, m, p, erl, erlP))
      return false;

   long dh = (long)MathRound(erh - erhP);
   long dl = (long)MathRound(erl - erlP);
   outStr = IntegerToString((long)MathRound(erh)) + "/" + ((dh > 0) ? "+" : "") + IntegerToString(dh) + " "
          + IntegerToString((long)MathRound(erl)) + "/" + ((dl > 0) ? "+" : "") + IntegerToString(dl);
   return true;
}

//==================================================================
//  Wpr9* : mo rong cong thuc Wpr8* (Wpr8WilliamsRAt / Wpr8ComputeMa / Wpr8BuildTripleStr) sang 13 khung 5m..1nm
//  cua g_tfList/g_tfLabel. Tu 5m tro len nB (so nen M1 cho 1 nen cua khung) > 1 nen RV1(tf) la VWAP THAT (hlc3 x tick volume) cua nB nen M1,
//  nB = GetRV2NBars(tf). Bo may Wpr9*: Wpr9FindShift / Wpr9Rv1AtAnchor / Wpr9BuildM1Cache / Wpr9BuildRv1Series.
//  Mang M1 (gio + tick volume) Copy MOT LAN (Wpr9BuildM1Cache) roi dung chung cho ca 13 khung.
//
//  GIOI HAN: William %R(30) + MA(5, warmup ~20) tren RV1(tf) can khoang 50-55 mau lien tiep cua chinh khung tf (xem Wpr9NeedTfBars):
//  D1 ~ 79,200 nen M1; W1 ~ 396,000; MN1 ~ 2,376,000 - qua lon de Copy moi tick. InpWpr9MaxM1Bars (mac dinh 50,000) la tran an toan
//  chung cho ca 13 khung: 5m..D1 du du lieu, rieng W1/MN1 thuong khong du -> hang cua hai khung do tu AN (Wpr8BuildTripleStr tra chuoi rong
//  khi thieu du lieu). Co the tang InpWpr9MaxM1Bars neu broker co du lich su M1 va chap nhan hieu nang cao hon.
//==================================================================

//+------------------------------------------------------------------+
//| Wpr9FindShift: tim chi so k NHO NHAT sao cho tm[k] <= atTime,     |
//|   trong mang tm[] da sap xep GIAM DAN (series, index 0 = moi      |
//|   nhat). Nhi phan, y het FindM1Shift() cua WPR_rVWAP_Osc.mq5.     |
//+------------------------------------------------------------------+
int Wpr9FindShift(const datetime &tm[], int n, datetime atTime)
{
   if(n <= 0) return -1;
   if(atTime >= tm[0]) return 0;
   if(atTime < tm[n - 1]) return -1;
   int lo = 0, hi = n - 1;
   while(lo < hi)
   {
      int mid = (lo + hi) / 2;
      if(tm[mid] > atTime) lo = mid + 1;
      else                 hi = mid;
   }
   return lo;
}

//+------------------------------------------------------------------+
//| Wpr9Rv1AtAnchor: RV1 (Rolling VWAP) cua nB nen M1 GAN NHAT ket    |
//|   thuc tai/truoc atTime - dung mang M1 DUNG CHUNG (cumTPV/cumVol  |
//|   la suffix-sum tick-volume-weighted hlc3, tmM1 la thoi gian tung |
//|   nen M1) do Wpr9BuildM1Cache() dung MOT LAN cho ca 13 khung.     |
//+------------------------------------------------------------------+
bool Wpr9Rv1AtAnchor(int nB, datetime atTime,
                      const double &cumTPV[], const double &cumVol[],
                      const datetime &tmM1[], int gotM1, double &outVal)
{
   int m1sh = Wpr9FindShift(tmM1, gotM1, atTime);
   if(m1sh < 0 || m1sh + nB >= gotM1) return false;
   double wVol = cumVol[m1sh] - cumVol[m1sh + nB];
   if(wVol <= 0.0) return false;
   outVal = (cumTPV[m1sh] - cumTPV[m1sh + nB]) / wVol;
   return true;
}

//+------------------------------------------------------------------+
//| Wpr9NeedTfBars: so mau (shift) LIEN TIEP cua CHINH khung tf can   |
//|   de William %R(period) + MA(maPeriod, warmup period*4) hoi tu -  |
//|   DUNG CHUNG cong thuc voi hang 8 (Wpr8NeedM1Bars), lay gia tri   |
//|   LON HON giua yeu cau cua ban RV1 va ban RV2 (ban RV2 can cong    |
//|   them InpEmaPeriod vi no la EMA cua RV1).                        |
//+------------------------------------------------------------------+
int Wpr9NeedTfBars()
{
   int needWpr1 = MathMax(InpMa8Period1 * 4, InpMa8Period1 + 2);
   int needWpr2 = MathMax(InpMa8Period  * 4, InpMa8Period  + 2);
   int total1   = needWpr1 + InpWpr8Period1;
   int total2   = g_aptRv2EmaPeriod + needWpr2 + InpWpr8Period;
   int need     = MathMax(total1, total2) + 5;
   if(need < 10) need = 10;
   return need;
}

//+------------------------------------------------------------------+
//| Wpr9BuildM1Cache: Copy M1 (gio + tick volume) MOT LAN DUY NHAT    |
//|   cho CA 13 khung 5m..1nm, roi dung suffix-sum cumTPV/cumVol -    |
//|   CUNG cong thuc RV1 (VWAP hlc3 x tick volume) da dung khap file. |
//|   So nen M1 xin = InpWpr9MaxM1Bars (tran an toan hieu nang - xem  |
//|   chu thich dai o dau cum ham nay). Tra ve so nen M1 THUC SU lay  |
//|   duoc (co the < InpWpr9MaxM1Bars neu lich su M1 chua du).        |
//+------------------------------------------------------------------+
int Wpr9BuildM1Cache(datetime &outTm[], double &outCumTPV[], double &outCumVol[])
{
   int need = InpWpr9MaxM1Bars;
   if(need < 100) need = 100;

   double hi[], lo[], cl[];
   long   tv[];
   ArraySetAsSeries(outTm, true);
   ArraySetAsSeries(hi, true);
   ArraySetAsSeries(lo, true);
   ArraySetAsSeries(cl, true);
   ArraySetAsSeries(tv, true);

   int got = CopyTime      (_Symbol, PERIOD_M1, 0, need, outTm);
   int gH  = CopyHigh      (_Symbol, PERIOD_M1, 0, need, hi);
   int gL  = CopyLow       (_Symbol, PERIOD_M1, 0, need, lo);
   int gC  = CopyClose     (_Symbol, PERIOD_M1, 0, need, cl);
   int gV  = CopyTickVolume(_Symbol, PERIOD_M1, 0, need, tv);
   if(gH < got) got = gH;
   if(gL < got) got = gL;
   if(gC < got) got = gC;
   if(gV < got) got = gV;
   if(got <= 0)
   {
      ArrayResize(outTm,     0);
      ArrayResize(outCumTPV, 0);
      ArrayResize(outCumVol, 0);
      return 0;
   }

   ArrayResize(outCumTPV, got);
   ArrayResize(outCumVol, got);
   outCumTPV[got - 1] = ((hi[got - 1] + lo[got - 1] + cl[got - 1]) / 3.0) * (double)tv[got - 1];
   outCumVol[got - 1] = (double)tv[got - 1];
   for(int k = got - 2; k >= 0; k--)
   {
      double tp = (hi[k] + lo[k] + cl[k]) / 3.0;
      outCumTPV[k] = outCumTPV[k + 1] + tp * (double)tv[k];
      outCumVol[k] = outCumVol[k + 1] + (double)tv[k];
   }
   return got;
}

//+------------------------------------------------------------------+
//| Wpr9BuildRv1Series: chuoi RV1(tf) lay mau THEO TUNG NEN CUA KHUNG |
//|   tf, dung mang M1 dung chung tu Wpr9BuildM1Cache(). Tra ve so    |
//|   phan tu THUC SU lay duoc (avail, co the < need neu thieu lich   |
//|   su M1/tf).                                                      |
//|                                                                    |
//|   Moc neo: nen lich su (k>0) neo tai GIO DONG cua chinh no         |
//|   (tmTF[k] + PeriodSeconds(tf) - 1), cung RvwapAtBarTime() cua      |
//|   WPR_rVWAP_Osc.mq5 (cua so nB nen M1 ket thuc tai gio dong). Nen   |
//|   k=0 (dang chay) neo TimeCurrent(). RV2 = EMA cua chuoi RV1 nay     |
//|   (Wpr8BuildRv2M1Series). VWAP = hlc3 x tick volume (Wpr9Rv1AtAnchor()).|
int Wpr9BuildRv1Series(ENUM_TIMEFRAMES tf, int need,
                        const double &cumTPV[], const double &cumVol[],
                        const datetime &tmM1[], int gotM1, double &outRv1[])
{
   int nB = GetRV2NBars(tf);
   datetime tmTF[];
   ArraySetAsSeries(tmTF, true);
   int gotTF = CopyTime(_Symbol, tf, 0, need, tmTF);
   if(gotTF <= 0)
   {
      ArrayResize(outRv1, 0);
      return 0;
   }

   ArrayResize(outRv1, gotTF);
   int avail = 0;
   for(int k = 0; k < gotTF; k++)
   {
      datetime atTime = (k == 0) ? TimeCurrent() : (tmTF[k] + (datetime)PeriodSeconds(tf) - 1);
      double   v = 0.0;
      if(!Wpr9Rv1AtAnchor(nB, atTime, cumTPV, cumVol, tmM1, gotM1, v))
         break;
      outRv1[k] = v;
      avail = k + 1;
   }
   if(avail < gotTF)
      ArrayResize(outRv1, avail);
   return avail;
}

//+------------------------------------------------------------------+
//| LblWidestSampleRv1: chuoi mau DAI NHAT dung de do be rong cot RV1:  |
//|   LblWidestSample(dgR, dgD, false) + " 31d 23:59" (phan " 31d 23:59" |
//|   la khoang du du phong, dang <N>d hh:mm cua ElapsedToStr - dang rong |
//|   nhat). Chi dung de do be rong: khong tao object, khong doc gia.     |
//+------------------------------------------------------------------+
string LblWidestSampleRv1(const int dgR, const int dgD)
{
   return LblWidestSample(dgR, dgD, false) + " " + "31d 23:59";
}

//+------------------------------------------------------------------+
//| LblAutoGapPx: khoang cach (px) du de cot ben PHAI khong ghi de len |
//|   cot ben TRAI = be rong chuoi dai nhat cua cot ben trai + khe ho   |
//|   InpLblAutoPadPx (da nhan theo DPI). Tat InpLblAutoFitCols, hoac   |
//|   do be rong that bai -> tra gia tri input fallbackPx.              |
//+------------------------------------------------------------------+
int LblAutoGapPx(const int fallbackPx, const string sampleTxt, const int fs)
{
   int fb = (fallbackPx < 0) ? 0 : fallbackPx;
   if(!InpLblAutoFitCols) return fb;

   int w = LblTextWidthPx(sampleTxt, fs);
   if(w <= 0) return fb;

   int pad = (InpLblAutoPadPx < 0) ? 0 : InpLblAutoPadPx;
   int g   = w + (int)MathCeil((double)pad * LblDpiScale());
   if(g < 1) g = 1;
   return g;
}

//+------------------------------------------------------------------+
//  DrawRv2RsiLabels: tinh va ghi cac nhan theo 14 khung (g_rvTfList = g_tfList), moi nhip ve:
//    - nhan RV1 (g_rv1RsiLblPrefix+TF, cot RV1, tai gia RV1): noi dung = txt1 = "<TF> (<rawdiffV1V2>/<diffV1V2>)" (xem "FORMAT NHAN" o dau file);
//    - nhan RV2 (g_rv2RsiLblPrefix+TF, cot RV2, tai gia RV2): chi con "<TF>";
//    - nhan Pivot (WoodieLevelLblPrefix+TF): ghi de bang _swapPvTxt ("<TF> <Pivotdiff> <Pivotdiff2> <RSI5>/<xu huong>"; xem "FORMAT NHAN PIVOT" ben duoi);
//    - nhan RV1 khung 1m (hang 1 cua cum) + 3 hang duoi than nen lon (g_bcTopTxt[0..2]) + hang SYS3;
//    - cache cho cot Pattern: g_patCdlStr, g_rv1ValCache, g_aptRndPx.
//  Cot nhan chi bi xoa khi cot do dang TAT (InpShowRv2RsiLbl / InpShowRv1RsiLbl); khi BAT, object cu duoc ObjectMove/ObjectSetString sang gia tri moi.
//  Giai thich tung truong cua nhan: BANG FORMAT o dau file.
//+------------------------------------------------------------------+
void DrawRv2RsiLabels()
{
   SSpmScopeTimer __spmTimer("DrawRv2RsiLabels");
   // Reset moc thoi gian nhan RV1-1m va cache cac hang nhan duoi than nen lon
   g_rv1M1LblT = 0;   // reset moc thoi gian nhan RV1-1m (xem khai bao)
   g_rv1M1LblPx = 0.0;
   g_rv1M1LblFs = 0;
   for(int _bcTk = 0; _bcTk < 3; _bcTk++)
     {
      g_bcTopTxt[_bcTk] = "";
      g_bcTopClr[_bcTk] = clrSilver;
     }
   for(int _ptk = 0; _ptk < 14; _ptk++)
     {
      g_patCdlStr[_ptk]    = "";
      g_patFvgStr[_ptk]    = "";
      g_patLvnStr[_ptk]    = "";
      g_patImbStr[_ptk]    = "";
      g_midRv1WStr[_ptk]   = "-";
      g_midRv2WStr[_ptk]   = "-";
      g_midPvWStr[_ptk]    = "-";
      g_midTmStr[_ptk]     = "";
      g_midRsiStr[_ptk]    = "";
     }
   // Cot nhan RV2 / RV1 chi bi xoa khi cot do dang TAT (input co dinh trong vong doi indicator; OnDeinit da quet prefix khi go).
   if(!InpShowRv2RsiLbl)
      ObjectsDeleteAll(0, g_rv2RsiLblPrefix, -1, OBJ_TEXT);
   if(!InpShowRv1RsiLbl)
      ObjectsDeleteAll(0, g_rv1RsiLblPrefix, -1, OBJ_TEXT);

   // Khung bi bo tick o bang check box (g_tfRowShow[]): go nhan RV1 / RV2 cua khung do. Tinh toan ben duoi van chay du 14 khung
   //   (cache, mau, bo dem khong doi); nhan RV1 1m van tinh moc g_rv1M1LblT, chi khong ve chu.
   for(int _hk = 0; _hk < RV2_TF_COUNT; _hk++)
      if(!g_tfRowShow[_hk])
        {
         ObjectDelete(0, g_rv2RsiLblPrefix + g_tfName[_hk]);
         ObjectDelete(0, g_rv1RsiLblPrefix + g_tfName[_hk]);
        }

   g_rv2ColEndTime = 0;


   if(!InpShowRv2RsiLbl && !InpShowRv1RsiLbl) { ObjectsDeleteAll(0, g_rndMkPrefix); g_aptRndLvlN = 0; AptRndCandlePaint(); return; }   // tat nhan -> go luon danh dau lam tron (va bo to mau nen)

   int emaP = MathMax(1, g_aptRv2EmaPeriod);
   int warm = emaP * 4;                       // warmup EMA
   if(warm < emaP + 2) warm = emaP + 2;

   int pts = InpRv2LblPoints;                 // so diem RV2 muon co de tinh RSI
   if(pts < WOODIE_RSI_PERIOD + 2) pts = WOODIE_RSI_PERIOD + 2;

    //--- So nen M1 can lay = gia tri LON NHAT trong 14 khung, kep bang tran ---
   int need = 0;
   for(int i = 0; i < RV2_TF_COUNT; i++)
   {

      int nBi = GetRV2NBars(g_rvTfList[i]);
      int rq  = (pts + warm + 1) * nBi;
      if(rq > need) need = rq;
   }
   int capM1 = InpRv2LblMaxM1;
   if(capM1 < 1000) capM1 = 1000;
   if(need > capM1) need = capM1;
   if(need < 2)     return;

    //--- Copy du lieu M1 MOT LAN cho ca 14 khung ---
   double   hi[], lo[], cl[];
   long     tv[];
   datetime tm[];
   ArraySetAsSeries(hi, true);
   ArraySetAsSeries(lo, true);
   ArraySetAsSeries(cl, true);
   ArraySetAsSeries(tv, true);
   ArraySetAsSeries(tm, true);

   int cpH = CopyHigh      (_Symbol, PERIOD_M1, 0, need, hi);
   int cpL = CopyLow       (_Symbol, PERIOD_M1, 0, need, lo);
   int cpC = CopyClose     (_Symbol, PERIOD_M1, 0, need, cl);
   int cpV = CopyTickVolume(_Symbol, PERIOD_M1, 0, need, tv);
   int cpT = CopyTime      (_Symbol, PERIOD_M1, 0, need, tm);
   int got = MathMin(MathMin(MathMin(cpH, cpL), MathMin(cpC, cpV)), cpT);
   if(got < 2) return;

    //--- Prefix-sum tren du lieu M1 ---
   double cumTPV[], cumVol[];
   ArrayResize(cumTPV, got + 1);
   ArrayResize(cumVol, got + 1);
   cumTPV[got] = 0.0;
   cumVol[got] = 0.0;
   for(int s = got - 1; s >= 0; s--)
   {
      double tp = (hi[s] + lo[s] + cl[s]) / 3.0;
      double v  = (double)tv[s];
      cumTPV[s] = cumTPV[s + 1] + tp * v;
      cumVol[s] = cumVol[s + 1] + v;
   }

   //--- Moc thoi gian goc = nen dang chay cua CHART (giong cot nhan Pivot) ---
   datetime tBase = iTime(_Symbol, _Period, 0);
   int      psec  = PeriodSeconds(_Period);
   if(tBase <= 0) return;

   int dgR = InpRv2LblRsiDigits;
   if(dgR < 0) dgR = 0;
   if(dgR > 2) dgR = 2;
   int dgD = InpRv2LblDiffDigits;
   if(dgD < 0) dgD = 0;
   if(dgD > 2) dgD = 2;
   int fsz = InpRv2LblFontSize;
   if(fsz < 6) fsz = 6;

   g_rv1M1Row2Txt   = "";

   // --- DANH SACH THU THAP NHAN de xu li TRUNG VI TRI ---
   // Moi nhan duoc day vao mot danh sach phang, den cuoi ham moi gom cum va dat vi tri MOT LUOT.
   // Suc chua = RV2_TF_COUNT * 2: moi khung sinh toi da HAI nhan (RV1 tai tLbl, RV2 tai tLbl1).
   // _olHead = moc thoi gian cua tung nhan (hai cot khac moc nen tu tach thanh hai cum rieng).
   int      _olCnt = 0;
   string   _olName  [RV2_TF_COUNT * 2];
   int      _olTf    [RV2_TF_COUNT * 2];   // chi so khung (0..13) - dung de sap xep trong cum
   double   _olPrice [RV2_TF_COUNT * 2];   // gia goc (RV1 hoac RV2 that) cua tung nhan
   datetime _olHead  [RV2_TF_COUNT * 2];   // moc thoi gian (x) cua tung nhan
   string   _olText  [RV2_TF_COUNT * 2];
   color    _olClr   [RV2_TF_COUNT * 2];
   int      _olFs    [RV2_TF_COUNT * 2];
   // _olCol: nhan thuoc COT nao: 0 = cot RV1, 1 = cot RV2. Khoi tinh khoang cach ben duoi ghi de _olHead theo cot nay.
   int      _olCol   [RV2_TF_COUNT * 2];
   bool     _olHide  [RV2_TF_COUNT * 2];   // true = khung bi bo tick o bang check box: khong ve chu, khong tham gia do be rong / xep hang

   // Hai moc thoi gian do vong lap tinh ra (tLbl / tLbl1); dung lam gia tri du phong khi khong do duoc be rong that cua cot ben trai.
   datetime _colT0 = 0;   // moc cot RV1 (cach cu)
   datetime _colT1 = 0;   // moc cot RV2 (cach cu)

   // --- BUOC GIA ung voi 1 PIXEL (_pxPr). Doc that bai -> lui ve _Point de khoi gom cum ben duoi van chay duoc. ---
   double _pMin = 0.0, _pMax = 0.0;
   long   _hcPx = 0;
   ChartGetDouble (0, CHART_PRICE_MIN,        0, _pMin);
   ChartGetDouble (0, CHART_PRICE_MAX,        0, _pMax);
   ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS, 0, _hcPx);
   double _pxPr = (_hcPx > 0 && _pMax > _pMin) ? (_pMax - _pMin) / (double)_hcPx : _Point;
   if(_pxPr <= 0.0) _pxPr = _Point;

   double   _rv2LblRv1M1c[];
   int      _rv2LblAvailRv1M1c = Wpr8BuildRv1M1Series(MathMax(Wpr8NeedM1Bars(), AptRvChanNeed()), _rv2LblRv1M1c);   // du lich su cho kenh RV
   datetime _rv2LblTmM1c[];
   double   _rv2LblCumTPVc[], _rv2LblCumVolc[];
   int      _rv2LblGotM1c     = Wpr9BuildM1Cache(_rv2LblTmM1c, _rv2LblCumTPVc, _rv2LblCumVolc);
   int      _rv2LblNeedTfBars = MathMax(Wpr9NeedTfBars(), AptRvChanNeed());   // du lich su cho kenh RV

   for(int i = 0; i < RV2_TF_COUNT; i++)
   {
      // Vong lap chay qua DU 14 khung cua g_rvTfList; khung nao du lich su M1 la co nhan RV1 va RV2.

      ENUM_TIMEFRAMES tf = g_rvTfList[i];
      int nB = GetRV2NBars(tf);

      // Mau CHUNG cua nhan RV1/RV2 (_lblClr) = AptRv2RowColor(tf) (KHONG con la AptPivotRowColor); xem AptRv2RowColor. Ghi chu cu: AptPivotRowColor(tf) - cung cong thuc to mau nhan Pivot (chieu RV1(tf) vs RV2(tf) ket hop cac bo dem giay UpA/DnA, UpB/DnB, UpC/DnC, Up/Dn cua khung tf).
      color  _lblClr   = AptRv2RowColor(tf);   // mau nhan RV1 / RV2: logic (Bid-Open)/spread, bodiff, brkddiff, brkD, <TenMuc> (xem AptRv2RowColor)

      //--- Thoi gian tung nen cua khung TF (series: 0 = moi nhat) ---
      datetime tmTF[];
      ArraySetAsSeries(tmTF, true);
      int gotTF = CopyTime(_Symbol, tf, 0, pts + warm, tmTF);
      if(gotTF < warm + 2) continue;

      //--- Chuoi RV1 lay mau theo tung nen TF ---
      double rv[];
      ArrayResize(rv, gotTF);
      int avail = 0;
      for(int k = 0; k < gotTF; k++)
      {
         datetime atTime = (k == 0) ? TimeCurrent() : (tmTF[k] + (datetime)PeriodSeconds(tf) - 1);
         int m1sh = FindM1Shift(tm, got, atTime);
         if(m1sh < 0 || m1sh + nB >= got) break;   // het du lieu M1 cho cua so rolling

         double wVol = cumVol[m1sh] - cumVol[m1sh + nB];
         double v    = (wVol > 0.0) ? (cumTPV[m1sh] - cumTPV[m1sh + nB]) / wVol : 0.0;
         if(v <= 0.0) break;

         rv[k] = v;
         avail = k + 1;
      }
      if(avail < warm + 2) continue;

      //--- RV2 = EMA(emaP) cua rv[], seed = SMA(emaP) cac mau cu nhat ---
      double ema[];
      ArrayResize(ema, avail);
      double alpha   = 2.0 / (emaP + 1.0);
      double seedSum = 0.0;
      for(int s = avail - 1; s >= avail - emaP; s--)
         seedSum += rv[s];
      double emaVal = seedSum / (double)emaP;
      for(int s = avail - 1; s >= avail - emaP; s--)
         ema[s] = 0.0;   // khong dung (pham vi seed)
      for(int s = avail - emaP - 1; s >= 0; s--)
      {
         emaVal = alpha * rv[s] + (1.0 - alpha) * emaVal;
         ema[s] = emaVal;
      }

      //--- Cat phan warmup roi tinh RSI(5) tren chinh chuoi RV2 ---
      int pOK = avail - warm;
      if(pOK <= WOODIE_RSI_PERIOD) continue;
      if(ema[0] <= 0.0)            continue;

      // Bo dem va cac chuoi phu cua nhan: <UpE>/<DnE>, <UpB>/<DnB>, <UpA>/<DnA>, <Up>/<Dn> doc tu g_aptBrkAcc*[] qua chi so _rv2LblUdIdx = AptFindTfIndex(tf)
      // (chi so theo g_tfList). Khong tim thay chi so / cache rong -> "-" hoac "" (khong doan).

      int    _rv2LblUdIdx    = AptFindTfIndex(tf);
      string _rv2LblBrkStr   = "-";
      bool   _rv2LblBrkOk    = BrkTextForTF(tf, _rv2LblBrkStr);
      int    _rv2LblBrkDInt  = 0;
      if(AptBrkDAt(tf, 0, _rv2LblBrkDInt))
        {
         _rv2LblBrkStr = IntegerToString(_rv2LblBrkDInt)
                         + "(" + IntegerToString(AptBrkStreakCount(_rv2LblUdIdx, tf, _rv2LblBrkDInt)) + ")";
         _rv2LblBrkOk  = true;
        }
      string _rv2LblSigBrk = " ";
      if(_rv2LblBrkOk && _rv2LblBrkStr != "" && _rv2LblBrkStr != "-")
        {
         double _rv2LblBrkVal = StringToDouble(_rv2LblBrkStr);
         if(_rv2LblBrkVal >= 110.0)
            _rv2LblSigBrk = "▲";
         else if(_rv2LblBrkVal <= -10.0)
            _rv2LblSigBrk = "▼";
        }
      // <diffpv> = (RV1 - gia muc Pivot)/spread; spread = SYMBOL_SPREAD * _Point (spread <= 0 -> "-"), so le M1_ELP_LBL_DIF1_DIGITS.
      double _dpvSpread = (double)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * _Point;
      string _rv2LblDiffPvStr = "-";
      if(_rv2LblUdIdx >= 0 && g_pivotLvlValCache[_rv2LblUdIdx] > 0.0 && _dpvSpread > 0.0)
         _rv2LblDiffPvStr = DoubleToString((g_rv1ValCache[_rv2LblUdIdx] - g_pivotLvlValCache[_rv2LblUdIdx]) / _dpvSpread, M1_ELP_LBL_DIF1_DIGITS);
      // <diffpv2> = (RV2 - gia muc Pivot dang dung cua khung tf)/spread (RV2 lay tu g_aptRv2All[]). Thieu RV2 hoac muc Pivot -> "-".
      string _rv2LblDiffPv2Str = "-";
      if(_rv2LblUdIdx >= 0 && g_aptRv2AllOk[_rv2LblUdIdx] && g_aptRv2All[_rv2LblUdIdx] > 0.0 && g_pivotLvlValCache[_rv2LblUdIdx] > 0.0 && _dpvSpread > 0.0)
         _rv2LblDiffPv2Str = DoubleToString((g_aptRv2All[_rv2LblUdIdx] - g_pivotLvlValCache[_rv2LblUdIdx]) / _dpvSpread, M1_ELP_LBL_DIF1_DIGITS);
      // <diffpv3> = (gia muc Pivot - OW)/spread; OW = EMA(Open) chu ky n = g_aptBrkDBars (AptOpenLwma(), cung nguon nhan OW<khung>). Thieu OW / muc Pivot / spread -> "-".
      string _rv2LblDiffPv3Str = "-";
      // <diffavg> = (diffpv + diffpv2 + diffpv3)/3 (tinh tu gia tri CHUA lam tron cua ca 3), so le M1_ELP_LBL_DIF1_DIGITS: chuoi hien tren nhan Pivot thay cho [<diffpv>] [<diffpv2>][<diffpv3>].
      //   Thieu 1 trong RV1 / RV2 / muc Pivot / OW / spread -> "-" (khong doan).
      string _rv2LblDiffAvgStr = "-";
      // <Owtron> = (OW - gia nhan lam tron GAN GIA GIUA NHAT)/spread, 1 so le M1_ELP_LBL_DIF1_DIGITS. OW = OW cua khung tf (cung nguon <diffpv3>); nhan = AptRndNearestMidLvl()
      //   (nhan lam tron mau trang gan (Bid + Ask)/2 nhat, khong gioi han khoang cach). Khong co nhan lam tron / thieu OW / spread -> "-".
      string _rv2LblOwTronStr = "-";
        {
         int _dpv3N = g_aptBrkDBars;
         if(_dpv3N < 2)   _dpv3N = 2;
         if(_dpv3N > 500) _dpv3N = 500;
         double _dpv3Ow = 0.0;
         double _owTronLvl = 0.0;
         if(_rv2LblUdIdx >= 0 && _dpvSpread > 0.0 && AptOpenLwma(tf, _dpv3N, _dpv3Ow) && _dpv3Ow > 0.0 && AptRndNearestMidLvl(_owTronLvl))
            _rv2LblOwTronStr = DoubleToString((_dpv3Ow - _owTronLvl) / _dpvSpread, M1_ELP_LBL_DIF1_DIGITS);
         _dpv3Ow = 0.0;
         if(_rv2LblUdIdx >= 0 && g_pivotLvlValCache[_rv2LblUdIdx] > 0.0 && _dpvSpread > 0.0 && AptOpenLwma(tf, _dpv3N, _dpv3Ow) && _dpv3Ow > 0.0)
           {
            _rv2LblDiffPv3Str = DoubleToString((g_pivotLvlValCache[_rv2LblUdIdx] - _dpv3Ow) / _dpvSpread, M1_ELP_LBL_DIF1_DIGITS);
            if(g_rv1ValCache[_rv2LblUdIdx] > 0.0 && g_aptRv2AllOk[_rv2LblUdIdx] && g_aptRv2All[_rv2LblUdIdx] > 0.0)
              {
               double _dAvg1 = (g_rv1ValCache[_rv2LblUdIdx] - g_pivotLvlValCache[_rv2LblUdIdx]) / _dpvSpread;
               double _dAvg2 = (g_aptRv2All[_rv2LblUdIdx]   - g_pivotLvlValCache[_rv2LblUdIdx]) / _dpvSpread;
               double _dAvg3 = (g_pivotLvlValCache[_rv2LblUdIdx] - _dpv3Ow) / _dpvSpread;
               _rv2LblDiffAvgStr = DoubleToString((_dAvg1 + _dAvg2 + _dAvg3) / 3.0, M1_ELP_LBL_DIF1_DIGITS);
              }
           }
        }

      // Nhan RV2 chi con "<TF>" (xem BANG FORMAT o dau file); <MA1> /<MA2> [<W1>] [<W2>] ghep vao nhan PIVOT, diffpv/diffpv2 ghep vao nhan PIVOT; SpR/rawdiff ghep vao nhan RV1.
      string _rv2LblWpr1Str     = "";
      string _rv2LblMa1Str      = "";   // <MA> cua WPR tren RV1 (cho nhan RV2)
      string _rv2LblMa2Str      = "";   // <MA> cua WPR tren RV2 (cho nhan RV2)
      string _rv2LblDiffV1V2Str = "-";
      string _rv2LblW1Str  = "-";
      string _rv2LblW2Str  = "-";
      if(tf == PERIOD_M1)
        {
         if(_rv2LblAvailRv1M1c > 0)
           {
            _rv2LblWpr1Str = Wpr8BuildTripleStr(_rv2LblRv1M1c, _rv2LblAvailRv1M1c, InpWpr8Period1, InpMa8Period1, InpMa8Method1);
            { int _cw; if(AptRvChanW(_rv2LblRv1M1c, _rv2LblAvailRv1M1c, _cw)) _rv2LblW1Str = IntegerToString(_cw); }
            _rv2LblMa1Str  = Wpr8BuildMaStr(_rv2LblRv1M1c, _rv2LblAvailRv1M1c, AptRvChanP(), InpMa8Period1, InpMa8Method1);
            double _rv2LblRv2M1c[];
            int _rv2LblAvailRv2M1c = Wpr8BuildRv2M1Series(_rv2LblRv1M1c, _rv2LblAvailRv1M1c, g_aptRv2EmaPeriod, _rv2LblRv2M1c);
            if(_rv2LblAvailRv2M1c > 0)
              {
               { int _cw; if(AptRvChanW(_rv2LblRv2M1c, _rv2LblAvailRv2M1c, _cw)) _rv2LblW2Str = IntegerToString(_cw); }
               _rv2LblMa2Str  = Wpr8BuildMaStr(_rv2LblRv2M1c, _rv2LblAvailRv2M1c, AptRvChanP(), InpMa8Period, InpMa8Method);
               int _rv2LblDiffV1V2N = MathMin(_rv2LblAvailRv1M1c, _rv2LblAvailRv2M1c);
               if(_rv2LblDiffV1V2N > 0 && _rv2LblRv1M1c[0] > 0.0 && _rv2LblRv2M1c[0] > 0.0)
                 {
                  bool _rv2LblDiffV1V2Up  = (_rv2LblRv1M1c[0] >= _rv2LblRv2M1c[0]);
                  int  _rv2LblDiffV1V2Cnt = 0;
                  for(int _rv2LblDiffV1V2S = 0; _rv2LblDiffV1V2S < _rv2LblDiffV1V2N; _rv2LblDiffV1V2S++)
                    {
                     if(_rv2LblRv1M1c[_rv2LblDiffV1V2S] <= 0.0 || _rv2LblRv2M1c[_rv2LblDiffV1V2S] <= 0.0) break;
                     if((_rv2LblRv1M1c[_rv2LblDiffV1V2S] >= _rv2LblRv2M1c[_rv2LblDiffV1V2S]) != _rv2LblDiffV1V2Up) break;
                     _rv2LblDiffV1V2Cnt++;
                    }
                  _rv2LblDiffV1V2Str = IntegerToString(_rv2LblDiffV1V2Up ? _rv2LblDiffV1V2Cnt : -_rv2LblDiffV1V2Cnt);
                 }
              }
           }
        }
      else
        {
         if(_rv2LblGotM1c > 0)
           {
            double _rv2LblRv1Tfc[];
            int _rv2LblAvailRv1Tfc = Wpr9BuildRv1Series(tf, _rv2LblNeedTfBars, _rv2LblCumTPVc, _rv2LblCumVolc, _rv2LblTmM1c, _rv2LblGotM1c, _rv2LblRv1Tfc);
            if(_rv2LblAvailRv1Tfc > 0)
              {
               _rv2LblWpr1Str = Wpr8BuildTripleStr(_rv2LblRv1Tfc, _rv2LblAvailRv1Tfc, InpWpr8Period1, InpMa8Period1, InpMa8Method1);
               { int _cw; if(AptRvChanW(_rv2LblRv1Tfc, _rv2LblAvailRv1Tfc, _cw)) _rv2LblW1Str = IntegerToString(_cw); }
               _rv2LblMa1Str  = Wpr8BuildMaStr(_rv2LblRv1Tfc, _rv2LblAvailRv1Tfc, AptRvChanP(), InpMa8Period1, InpMa8Method1);
               double _rv2LblRv2Tfc[];
               int _rv2LblAvailRv2Tfc = Wpr8BuildRv2M1Series(_rv2LblRv1Tfc, _rv2LblAvailRv1Tfc, g_aptRv2EmaPeriod, _rv2LblRv2Tfc);
               if(_rv2LblAvailRv2Tfc > 0)
                 {
                  { int _cw; if(AptRvChanW(_rv2LblRv2Tfc, _rv2LblAvailRv2Tfc, _cw)) _rv2LblW2Str = IntegerToString(_cw); }
                  _rv2LblMa2Str  = Wpr8BuildMaStr(_rv2LblRv2Tfc, _rv2LblAvailRv2Tfc, AptRvChanP(), InpMa8Period, InpMa8Method);
                  int _rv2LblDiffV1V2N = MathMin(_rv2LblAvailRv1Tfc, _rv2LblAvailRv2Tfc);
                  if(_rv2LblDiffV1V2N > 0 && _rv2LblRv1Tfc[0] > 0.0 && _rv2LblRv2Tfc[0] > 0.0)
                    {
                     bool _rv2LblDiffV1V2Up  = (_rv2LblRv1Tfc[0] >= _rv2LblRv2Tfc[0]);
                     int  _rv2LblDiffV1V2Cnt = 0;
                     for(int _rv2LblDiffV1V2S = 0; _rv2LblDiffV1V2S < _rv2LblDiffV1V2N; _rv2LblDiffV1V2S++)
                       {
                        if(_rv2LblRv1Tfc[_rv2LblDiffV1V2S] <= 0.0 || _rv2LblRv2Tfc[_rv2LblDiffV1V2S] <= 0.0) break;
                        if((_rv2LblRv1Tfc[_rv2LblDiffV1V2S] >= _rv2LblRv2Tfc[_rv2LblDiffV1V2S]) != _rv2LblDiffV1V2Up) break;
                        _rv2LblDiffV1V2Cnt++;
                       }
                     _rv2LblDiffV1V2Str = IntegerToString(_rv2LblDiffV1V2Up ? _rv2LblDiffV1V2Cnt : -_rv2LblDiffV1V2Cnt);
                    }
                 }
              }
           }
        }
      if(_rv2LblUdIdx >= 0 && _rv2LblUdIdx < 14)
        {
         g_midRv1WStr[_rv2LblUdIdx] = _rv2LblW1Str;   // -> cot hang 2.. duoi nhan RV1 1m (DrawMidPriceLabel())
         g_midRv2WStr[_rv2LblUdIdx] = _rv2LblW2Str;
        }
      string txt = g_tfName[i];
      string _swapPvTxt   = "";   // chuoi hien tren nhan Pivot (= chuoi cu cua RV2)
      string _rv2NewRsiFull = "-";
      AptS1RsiTextForTF(tf, _rv2NewRsiFull);
      string _rv2NewRsi = _rv2NewRsiFull;
      int    _rv2NewRsiSp = StringFind(_rv2NewRsiFull, " ");
      if(_rv2NewRsiSp > 0)
         _rv2NewRsi = StringSubstr(_rv2NewRsiFull, _rv2NewRsiSp + 1);
      if(StringLen(_rv2NewRsi) < 1) _rv2NewRsi = "-";
      string _rv2NewRsi5 = "";
      {
         string _rv2PvBase = g_pivotLblBaseText[i];
         int    _rv2PvSp   = StringFind(_rv2PvBase, " ");
         if(_rv2PvSp > 0)
           {
            _rv2NewRsi5 = StringSubstr(_rv2PvBase, _rv2PvSp + 1);
            StringReplace(_rv2NewRsi5, " / ", "/");
            StringReplace(_rv2NewRsi5, " /", "/");
            StringTrimLeft(_rv2NewRsi5);
            StringTrimRight(_rv2NewRsi5);
           }
         if(StringLen(_rv2NewRsi5) < 1) _rv2NewRsi5 = "-";
      }
      if(_rv2LblUdIdx >= 0 && _rv2LblUdIdx < 14)
         AptImbalanceForTF(_rv2LblUdIdx, tf);   // cap nhat trang thai/cache Imbalance cua khung (ket qua khong dung)
      int _rv2NewTmLvl = -1;
      string _rv2NewTmName = "";
      string _rv2NewRnd = "";   // <lamtron> (rong neu khong thoa)
      if(AptWoodieDisplayLvlForTF(tf, _rv2NewTmLvl) && _rv2NewTmLvl >= 0 && _rv2NewTmLvl < APT_S1_LVL_COUNT)
        {
         _rv2NewTmName = g_aptLvlName[_rv2NewTmLvl];
         if(PeriodSeconds(tf) >= 300)
            _rv2NewRnd = AptRoundNearStr(_rv2NewTmName, g_aptWdLastVal);
        }
      if(_rv2LblUdIdx >= 0 && _rv2LblUdIdx < 14)
         { g_aptRndPx[_rv2LblUdIdx] = (_rv2NewRnd != "") ? StringToDouble(_rv2NewRnd) : 0.0; g_midTmStr[_rv2LblUdIdx] = _rv2NewTmName; g_midRsiStr[_rv2LblUdIdx] = _rv2NewRsi; }   // de danh dau len thang gia
      // Nhan RV2: <TF> <SigBrk><brkD>/<brkddiff><TenMuc> <bodiff>/<(Bid-Open)/spread> <SpR2>/<SpR1> <diffavg>/<diffavg2> <RSI>/<dRSI>
      //   Phan sau <TF> = g_midRowTailStr[idx] (chuyen tu hang khung cua nhan gia giua; DrawMidPriceLabel() tinh va ghi moi lan ve, gom cac gia tri co trang thai nhu bodiff / diffavg2). Chua co / thieu -> chi <TF>.
      //   (<MA1> /<MA2> da chuyen sang nhan PIVOT.)
      // Nhan RV2: <TF> <Owtron>(<RSI>/<dRSI> <RSI5>/<xu huong> <Pivotdiff2> <Pivotdiff> { <SigBrk><brkD>/<brkddiff><TenMuc> <bodiff>/<(Bid-Open)/spread> } <SpR2>/<SpR1> <diffavg>/<diffavg2>)
      //   <Owtron> = _rv2LblOwTronStr (thieu -> "-"). <RSI>/<dRSI> = _rv2NewRsi; <RSI5>/<xu huong> = _rv2NewRsi5 (cung chuoi nhan Pivot); <Pivotdiff2> = g_pivotEmaDiff2Str[]; <Pivotdiff> = g_pivotEmaDiffStr[]; thieu -> "-".
      //   Ngoac "(" mo ngay sau <Owtron> (dinh lien) va chua: <RSI>/<dRSI> <RSI5>/<xu huong> <Pivotdiff2> <Pivotdiff> + 1 dau cach + { <SigBrk>...<(Bid-Open)/spread> } (ngoac nhon, co 1 dau cach trong moi dau ngoac) + 1 dau cach + <SpR2>/<SpR1> <diffavg>/<diffavg2> + ")"; phan tu "[" tro di = g_midRowTailStr[idx] (da gom ")" dong ngoac); Sau ")" khong con gi. Chua co cum -> nhan dong ngoac ngay sau <Pivotdiff>. <PivotW%> khong con tren nhan RV2.
      string _rv2TxtPd1 = "-", _rv2TxtPd2 = "-";   // <Pivotdiff> / <Pivotdiff2> (g_pivotEmaDiffStr[] / g_pivotEmaDiff2Str[], do DrawWoodiePivotEma() ghi); chua co -> "-"
      if(_rv2LblUdIdx >= 0 && _rv2LblUdIdx < 14)
        {
         if(g_pivotEmaDiffStr[_rv2LblUdIdx]  != "") _rv2TxtPd1 = g_pivotEmaDiffStr[_rv2LblUdIdx];
         if(g_pivotEmaDiff2Str[_rv2LblUdIdx] != "") _rv2TxtPd2 = g_pivotEmaDiff2Str[_rv2LblUdIdx];
        }
      txt = g_tfName[i] + " " + _rv2LblOwTronStr + "(" + _rv2NewRsi + " " + _rv2NewRsi5 + " " + _rv2TxtPd2 + " " + _rv2TxtPd1;   // ngoac "(" mo o day, dong o cuoi cum g_midRowTailStr[] (hoac ngay duoi neu chua co cum)
      if(_rv2LblUdIdx >= 0 && _rv2LblUdIdx < 14 && g_midRowTailStr[_rv2LblUdIdx] != "")
         txt += g_midRowTailStr[_rv2LblUdIdx];
      else
         txt += ")";

      //--- Moc dat nhan: lech phai so voi cot nhan Pivot cua CHINH khung do.
      //    Cot Pivot: khung > 1m lech InpS1LabelFutureBars nen, khung 1m lech 0.
      //    Cot nay cong them mot khoang -> nam sat canh ben phai cot do.
      // Bat InpRv2LblAutoGap -> khoang cach do bang PIXEL:
      //    be rong 1 nen (px) = CHART_WIDTH_IN_PIXELS / CHART_VISIBLE_BARS
      //    so nen can lech      = ceil(InpRv2LblGapPx / be rong 1 nen)
      //   Doc that bai (tra ve 0) -> tu dong quay ve InpRv2LblExtraBars,
      //   khong doan bua gia tri.
      int offs = InpRv2LblExtraBars;
      if(InpRv2LblAutoGap)
      {
         long wPx = ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
         long vBr = ChartGetInteger(0, CHART_VISIBLE_BARS);
         if(wPx > 0 && vBr > 0)
         {
            double barPx = (double)wPx / (double)vBr;
            int    gapPx = LblAutoGapPx(InpRv2LblGapPx, LblWidestSample(1, 1, true), 8);
            if(barPx > 0.0)
            {
               offs = (int)MathCeil((double)gapPx / barPx);
               if(offs < 1) offs = 1;
            }
         }
      }
      offs += InpS1LabelFutureBars + PIVOT_M1_LBL_FUTURE_BARS;
      if(offs < 0) offs = 0;

      int offs1 = InpRv1LblExtraBars;
      if(InpRv2LblAutoGap)
      {
         long wPx1 = ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
         long vBr1 = ChartGetInteger(0, CHART_VISIBLE_BARS);
         if(wPx1 > 0 && vBr1 > 0)
         {
            double barPx1 = (double)wPx1 / (double)vBr1;
            int    gapPx1 = LblAutoGapPx(InpRv1LblGapPx, LblWidestSampleRv1(dgR, dgD), fsz);
            if(barPx1 > 0.0)
            {
               offs1 = (int)MathCeil((double)gapPx1 / barPx1);
               if(offs1 < 1) offs1 = 1;
            }
         }
      }
      offs1 += offs;   // moc cua cot GAN + khoang cach -> sat canh ben phai
      if(offs1 < 0) offs1 = 0;

      datetime tLbl = tBase;
      if(psec > 0 && offs > 0)
         tLbl = tBase + (datetime)((long)offs * (long)psec);

      datetime tLbl1 = tBase;
      if(psec > 0 && offs1 > 0)
         tLbl1 = tBase + (datetime)((long)offs1 * (long)psec);

      _colT0 = tLbl;
      _colT1 = tLbl1;

      {
         string   _endSample = InpShowRv2RsiLbl ? LblWidestSample(dgR, dgD, false)
                                                : LblWidestSampleRv1(dgR, dgD);
         datetime _endBase   = InpShowRv2RsiLbl ? tLbl1 : tLbl;
         int      _endPx     = LblAutoGapPx(InpRv1LblGapPx, _endSample, fsz);
         int      _endOffs   = 0;

         long _endWPx = ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
         long _endVBr = ChartGetInteger(0, CHART_VISIBLE_BARS);
         if(_endWPx > 0 && _endVBr > 0)
         {
            double _endBarPx = (double)_endWPx / (double)_endVBr;
            if(_endBarPx > 0.0) _endOffs = (int)MathCeil((double)_endPx / _endBarPx);
         }
         if(_endOffs < 1) _endOffs = 1;

         g_rv2ColEndTime = (psec > 0)
                           ? (_endBase + (datetime)((long)_endOffs * (long)psec))
                           : _endBase;
      }

      string nmL = g_rv2RsiLblPrefix + g_tfName[i];
      if(InpShowRv2RsiLbl && g_tfRowShow[i] && _olCnt < RV2_TF_COUNT * 2)
      {
         _olName [_olCnt] = nmL;
         _olTf   [_olCnt] = i;
         _olPrice[_olCnt] = ema[0];        // gia RV2 that cua khung nay
         _olHead [_olCnt] = tLbl1;         // cot XA (ngoai cung ben phai)
         _olText [_olCnt] = txt;
         _olClr  [_olCnt] = _lblClr;
         _olFs   [_olCnt] = fsz;
         _olCol  [_olCnt] = 1;   // thuoc cot RV2
         _olHide [_olCnt] = false;
         _olCnt++;
      }

      if(InpShowRv1RsiLbl && rv[0] > 0.0)
      {

         int    _rv1UdIdx = AptFindTfIndex(tf);
         string _rv1UpStr = (_rv1UdIdx >= 0) ? AptBrkAccSecToStr(g_aptBrkAccUp[_rv1UdIdx]) : "-";
         string _rv1DnStr = (_rv1UdIdx >= 0) ? AptBrkAccSecToStr(g_aptBrkAccDn[_rv1UdIdx]) : "-";
         string _rv1UpCStr = (_rv1UdIdx >= 0) ? AptBrkAccSecToStr(g_aptBrkAccUpC[_rv1UdIdx]) : "-";
         string _rv1DnCStr = (_rv1UdIdx >= 0) ? AptBrkAccSecToStr(g_aptBrkAccDnC[_rv1UdIdx]) : "-";
         string _rv1UpAStr = (_rv1UdIdx >= 0) ? AptBrkAccSecToStr(g_aptBrkAccUpA[_rv1UdIdx]) : "-";
         string _rv1DnAStr = (_rv1UdIdx >= 0) ? AptBrkAccSecToStr(g_aptBrkAccDnA[_rv1UdIdx]) : "-";
         string _rv1UpEStr = (_rv1UdIdx >= 0) ? AptBrkAccSecToStr(g_aptBrkAccUpE[_rv1UdIdx]) : "-";
         string _rv1DnEStr = (_rv1UdIdx >= 0) ? AptBrkAccSecToStr(g_aptBrkAccDnE[_rv1UdIdx]) : "-";
         string _rv1UpBStr = (_rv1UdIdx >= 0) ? AptBrkAccSecToStr(g_aptBrkAccUpB[_rv1UdIdx]) : "-";
         string _rv1DnBStr = (_rv1UdIdx >= 0) ? AptBrkAccSecToStr(g_aptBrkAccDnB[_rv1UdIdx]) : "-";

         string _rv1UpAStrNoS = _rv1UpAStr; StringReplace(_rv1UpAStrNoS, "s", "");
         string _rv1DnAStrNoS = _rv1DnAStr; StringReplace(_rv1DnAStrNoS, "s", "");
         string _rv1UpStrNoS  = _rv1UpStr;  StringReplace(_rv1UpStrNoS,  "s", "");
         string _rv1DnStrNoS  = _rv1DnStr;  StringReplace(_rv1DnStrNoS,  "s", "");
         string _rv1UpBStrNoS = _rv1UpBStr; StringReplace(_rv1UpBStrNoS, "s", "");
         string _rv1DnBStrNoS = _rv1DnBStr; StringReplace(_rv1DnBStrNoS, "s", "");
         string _rv1UpEStrNoS = _rv1UpEStr; StringReplace(_rv1UpEStrNoS, "s", "");
         string _rv1DnEStrNoS = _rv1DnEStr; StringReplace(_rv1DnEStrNoS, "s", "");
         string _rv1UpCStrNoS = _rv1UpCStr; StringReplace(_rv1UpCStrNoS, "s", "");
         string _rv1DnCStrNoS = _rv1DnCStr; StringReplace(_rv1DnCStrNoS, "s", "");
         int _rv1TenMucLvl = g_pivotLvlUsedIdx[i];
         if(_rv1TenMucLvl < 0 || _rv1TenMucLvl > RV2_LVL_COUNT - 1)
            _rv1TenMucLvl = g_pivotLevelIdx;
         double _rqS1Ema   = 0.0;
         bool   _rqS1EmaOk = false;
         {
            double _rqS1EmaSer[];
            int _rqS1EmaWant = MathMax(3, APT_S1_EMA_PERIOD * 8);
            int _rqS1EmaAv   = AptS1EmaSeries(tf, _rqS1EmaSer, _rqS1EmaWant);
            if(_rqS1EmaAv > 0 && _rqS1EmaSer[0] > 0.0)
              {
               _rqS1Ema   = _rqS1EmaSer[0];
               _rqS1EmaOk = true;
              }
         }
         double _rv1PrevDayClose = iClose(_Symbol, PERIOD_D1, 1);
         string _rv1CdlS1Str = "-";
         if(_rqS1EmaOk && _rv1PrevDayClose > 0.0)
            _rv1CdlS1Str = DoubleToString(_rqS1Ema - _rv1PrevDayClose, M1_ELP_LBL_DIF1_DIGITS);
         string txt1Base = g_tfName[i] + " " + _rv2LblWpr1Str;



         string txt1 = txt1Base;

         if(g_rvTfList[i] == PERIOD_M1)
           {
            double _r1Tsf = 0.0, _r1Lam = 0.0;
            bool   _r1TpOk = AptTickPressureCalc(_r1Tsf, _r1Lam);
            double _r1Cmf = 0.0, _r1Vpin = 0.0;
            bool   _r1CmfOk = false, _r1VpinOk = false;
            int    _r1VpinDir = 0;
            AptCmfVpinCalc(_r1Cmf, _r1CmfOk, _r1Vpin, _r1VpinOk, _r1VpinDir);
            string _r1CmfStr  = _r1CmfOk ? StringFormat("%+.2f", _r1Cmf) : "-";
            string _r1TsfStr  = _r1TpOk ? StringFormat("%+.2f/%d", _r1Tsf, (_r1Tsf >= 0.0) ? 1 : -1) : "-";
            string _r1VpinStr = _r1VpinOk ? StringFormat("V%.2f", _r1Vpin) + ((_r1VpinDir > 0) ? "▲" : ((_r1VpinDir < 0) ? "▼" : " ")) : "V-";
            string _r1LamStr = _r1TpOk ? StringFormat("L%+.2f", _r1Lam) : "L-";
            g_rv1M1Row2Txt = "TC " + BrkAccSecToStr(g_rvOrdRv1Up) + "/" + BrkAccSecToStr(g_rvOrdRv1Dn) + " " +
                             _r1CmfStr + " " + _r1TsfStr + " " + _r1VpinStr + _r1LamStr;
           }



         {
            string _rv1NewImb = (_rv1UdIdx >= 0 && _rv1UdIdx < 14) ? AptImbalanceForTF(_rv1UdIdx, tf) : "";
            StringReplace(_rv1NewImb, "(", "");
            StringReplace(_rv1NewImb, ")", "");
            // Cot Pattern: <TF>{<DxyTenMuc>} <UpE>/<DnE> <UpB>/<DnB> <Up>/<Dn> <UpC>/<DnC> <UpA>/<DnA> <FVG><LVN><IMB> - <IMB> chuyen tu nhan RV1; <FVG> = AptFvgPushStr() (rong khi Bid ngoai vung FVG); <LVN> = AptLvnPushStr() (rong khi Bid ngoai vung LVN).
            string _rv1NewFvg = (_rv1UdIdx >= 0 && _rv1UdIdx < 14) ? AptFvgPushStr(_rv1UdIdx, tf) : "";
            string _rv1NewLvn = (_rv1UdIdx >= 0 && _rv1UdIdx < 14) ? AptLvnPushStr(_rv1UdIdx, tf) : "";
            if(_rv1UdIdx >= 0 && _rv1UdIdx < 14)
               g_patCdlStr[_rv1UdIdx] = g_tfName[i] + AptDxyLvlTag(g_rvTfList[i]) + " " +
                                       _rv1UpEStrNoS + "/" + _rv1DnEStrNoS + " " +
                                       _rv1UpBStrNoS + "/" + _rv1DnBStrNoS + " " +
                                       _rv1UpStrNoS  + "/" + _rv1DnStrNoS  + " " +
                                       _rv1UpCStrNoS + "/" + _rv1DnCStrNoS + " " +
                                       _rv1UpAStrNoS + "/" + _rv1DnAStrNoS + " " +
                                       _rv1NewFvg + _rv1NewLvn + _rv1NewImb;
            if(_rv1UdIdx >= 0 && _rv1UdIdx < 14)
              {
               g_patFvgStr[_rv1UdIdx] = _rv1NewFvg;
               g_patLvnStr[_rv1UdIdx] = _rv1NewLvn;
               g_patImbStr[_rv1UdIdx] = _rv1NewImb;
              }
            // Nhan PIVOT: <TF> <Pivotdiff> <Pivotdiff2> <RSI5>/<xu huong>
            //   <MA1> /<MA2> = _rv2LblMa1Str / _rv2LblMa2Str (tinh o khoi RV1/RV2 phia tren); thieu -> "-". _rv2LblW1Str / _rv2LblW2Str / _pvWStr (<RV1W%> / <RV2W%> / <PivotW%>) khong in tren nhan nay, cache o g_midRv1WStr[] / g_midRv2WStr[] / g_midPvWStr[] cho DrawMidPriceLabel().
            //   <Pivotdiff> = g_pivotEmaDiffStr[], <Pivotdiff2> = g_pivotEmaDiff2Str[] (do DrawWoodiePivotEma() ghi); chua co -> "-".
            string _pvDiff1Txt = (_rv1UdIdx >= 0 && _rv1UdIdx < 14 && g_pivotEmaDiffStr[_rv1UdIdx]  != "") ? g_pivotEmaDiffStr[_rv1UdIdx]  : "-";
            string _pvDiff2Txt = (_rv1UdIdx >= 0 && _rv1UdIdx < 14 && g_pivotEmaDiff2Str[_rv1UdIdx] != "") ? g_pivotEmaDiff2Str[_rv1UdIdx] : "-";
            // <PivotW%> (cot hang 2.. duoi nhan RV1 1m) = William %R cua gia tri Pivot (EMA Pivot cua muc chon o bang Pivot UI, mac dinh PP - AptPivotUiEmaSeries()) trong KENH HH/LL tinh tren
            //   CHINH chuoi Pivot cua khung tf (chu ky P = nut B<n>): (HH-Pivot)/(HH-LL)*-100, KHONG kep, SO NGUYEN (AptRvChanW()); thieu -> "-".
            string _pvWStr = "-";
            {
               double _pvWSer[];
               int    _pvWAv  = AptPivotUiEmaSeries(tf, 3 * AptRvChanP() + 200, _pvWSer);   // _pvWSer[0] = nen dang chay, [k] = nen shift k
               int    _pvWVal = 0;
               if(_pvWAv > 0 && AptRvChanW(_pvWSer, _pvWAv, _pvWVal))
                  _pvWStr = IntegerToString(_pvWVal);
            }
            if(_rv1UdIdx >= 0 && _rv1UdIdx < 14)
               g_midPvWStr[_rv1UdIdx] = _pvWStr;   // -> cot hang 2.. duoi nhan RV1 1m (DrawMidPriceLabel())
            // Nhan Pivot: <TF> <Pivotdiff> <Pivotdiff2> <RSI5>/<xu huong>   (<MA1> /<MA2> da bo khoi nhan; _rv2LblMa1Str / _rv2LblMa2Str van duoc tinh o khoi tren)
            _swapPvTxt = g_tfName[i] + " " + _pvDiff1Txt + " " + _pvDiff2Txt + " " + _rv2NewRsi5;
            // Nhan RV1: <TF> (<rawdiffV1V2>/<diffV1V2>)   (<SpR2>/<SpR1> va <brkD>(<streak>)<SigBrk> da chuyen sang cot hang 2.. duoi nhan RV1 1m - DrawMidPriceLabel())
            //   <rawdiffV1V2> = (RV1 - RV2)/spread (RV1 = g_rv1ValCache[], RV2 = g_aptRv2All[]);
            //   <diffV1V2> = _rv2LblDiffV1V2Str. Thieu RV1/RV2/spread -> "-".
            double _rv1TlSp   = (double)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * _Point;
            string _rv1TlRaw  = "-";
            if(_rv1UdIdx >= 0 && _rv1UdIdx < 14 && _rv1TlSp > 0.0 && g_aptRv2AllOk[_rv1UdIdx] && g_aptRv2All[_rv1UdIdx] > 0.0)
              {
               if(g_rv1ValCache[_rv1UdIdx] > 0.0)
                  _rv1TlRaw = DoubleToString((g_rv1ValCache[_rv1UdIdx] - g_aptRv2All[_rv1UdIdx]) / _rv1TlSp, M1_ELP_LBL_DIF1_DIGITS);
              }
            txt1 = g_tfName[i] + " (" + _rv1TlRaw + "/" + _rv2LblDiffV1V2Str + ")";
         }

         if(g_pivotLblBaseText[i] != "")
         {
            string _pvTargetName = WoodieLevelLblPrefix(_rv1TenMucLvl) + g_tfName[i];
            // FORMAT NHAN PIVOT (chuoi _swapPvTxt ghi bang ObjectSetString ngay duoi):
            //   <TF> <Pivotdiff> <Pivotdiff2> <RSI5>/<xu huong>
            //   <PivotW%> khong con tren nhan PIVOT: chuyen sang cot hang 2.. duoi nhan RV1 1m (g_midPvWStr[]); <Pivotdiff2> cach <RSI5>/<xu huong> 1 dau cach.
            //   <RSI5>/<xu huong> = phan sau dau cach DAU TIEN cua g_pivotLblBaseText[i] ("<TF> <RSI5> / <+-diffRSI>" do DrawEmaSeries ghi), bo khoang trang quanh "/" -> dang "48/+2"; rong -> "-".
            //   Chuoi "<TF>{<DxyTenMuc>} <UpE>/<DnE> <UpB>/<DnB> <Up>/<Dn> ... <FVG><LVN><IMB>" hien o COT PATTERN (g_patCdlStr[]).
            if(ObjectFind(0, _pvTargetName) >= 0)
               ObjectSetString(0, _pvTargetName, OBJPROP_TEXT,
                               _swapPvTxt);
         }

         string nmL1 = g_rv1RsiLblPrefix + g_tfName[i];

         if(_olCnt < RV2_TF_COUNT * 2)
         {
            _olName [_olCnt] = nmL1;
            _olTf   [_olCnt] = i;
            _olPrice[_olCnt] = rv[0];      // gia RV1 that cua khung nay
            _olHead [_olCnt] = tLbl;       // cot GAN (sat canh phai cot Pivot)
            _olText [_olCnt] = txt1;
            _olClr  [_olCnt] = _lblClr;
            _olFs   [_olCnt] = fsz;
            _olCol  [_olCnt] = 0;   // thuoc cot RV1
            _olHide [_olCnt] = !g_tfRowShow[i];
            _olCnt++;
         }
      }
   }

   int _rv1M1Idx = -1;
   for(int _e = 0; _e < _olCnt; _e++)
      if(_olCol[_e] == 0 && _olTf[_e] == 0) { _rv1M1Idx = _e; break; }

   {
      datetime _tPiv  = 0;
      int      _wPiv  = LblColMeasure("RVWAP_PP_EMA_", _tPiv);
      if(_wPiv > 0)
         _wPiv = (int)MathCeil((double)_wPiv * 1.20) + 6;

      int _wRv1 = 0, _wRv2 = 0;
      for(int _e = 0; _e < _olCnt; _e++)
      {
         if(_olHide[_e]) continue;
         int _w = LblTextWidthPx(_olText[_e], _olFs[_e]);
         if(_olCol[_e] == 0)
         {
            if(_e == _rv1M1Idx) continue;   // nhan RV1 cua 1m: khong thuoc cot nay nua
            if(_w > _wRv1) _wRv1 = _w;
         }
         else                { if(_w > _wRv2) _wRv2 = _w; }
      }

      double _barPx = 0.0;
      long   _wPxC  = ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
      long   _vBrC  = ChartGetInteger(0, CHART_VISIBLE_BARS);
      if(_wPxC > 0 && _vBrC > 0) _barPx = (double)_wPxC / (double)_vBrC;

      int _pad = (InpLblAutoPadPx < 0) ? 0 : InpLblAutoPadPx;
      int _padX = (InpLblColExtraPadPx < 0) ? 0 : InpLblColExtraPadPx;
      _pad = (int)MathCeil((double)(_pad + _padX) * LblDpiScale());

      datetime _tCol0 = _colT0;   // mac dinh = cach cu
      datetime _tCol1 = _colT1;

      // Vi tri nhan RV1 khung 1m (moc goc de cot RV1(>=5m)/RV2 ben duoi dua
      //   vao, KHONG bi cac cot do "keo theo"): mep trai dat cach mep PHAI
      //   chu THAT cua cot Pivot (_tPiv + _sPivOnly, KHONG cong _pad) dung
      bool     _rv1m1Ok     = false;
      datetime _rv1m1FinalT = 0;     // vi tri THAT su se ve nhan RV1-1m (mep trai, ANCHOR_LEFT)
      if(_rv1M1Idx >= 0 && InpLblAutoFitCols && _barPx > 0.0 && psec > 0 && _wPiv > 0 && _tPiv > 0)
      {
         long _sPivOnly = (long)MathCeil((double)_wPiv / _barPx * (double)psec);
         if(_sPivOnly < 1) _sPivOnly = 1;
         long _sOneM1Bar = (long)PeriodSeconds(PERIOD_M1);
         if(_sOneM1Bar < 1) _sOneM1Bar = 60;
         _rv1m1FinalT = _tPiv + (datetime)_sPivOnly + (datetime)(_sOneM1Bar * InpRv1M1GapM1Bars);   // 5 -> input InpRv1M1GapM1Bars

         _olHead[_rv1M1Idx]  = _rv1m1FinalT;
         _rv1m1Ok            = true;
      }

      // Khoang cach giua cac cot (Pivot->RV1->RV2->moc het cot) quy THANG ra
      //   GIAY roi cong thang vao datetime, KHONG lam tron ve so nen nguyen
      //   cua chart truoc - tranh cong don sai so lam tron nhieu lan thanh
      //   khoang trong lon giua cac cot.
      if(InpLblAutoFitCols && _barPx > 0.0 && psec > 0)
      {
         if(got > 1)
         {
            int _leftIdx = InpRv1Rv2LeftM1BarIdx;
            if(_leftIdx < 1)     _leftIdx = 1;
            if(_leftIdx > got-1) _leftIdx = got - 1;
            _tCol0 = tm[_leftIdx];
         }

         // Ban du phong cua _tCol1 (cung se bi ghi de o cuoi ham): dat cach
         //   _tCol0 mot khoang bang 3 lan be rong THAT hien tai cua chinh cot
         //   RV2 (_wRv2, do o dau ham).
         if(_wRv2 > 0)
         {
            long _sRv1 = (long)MathCeil((double)(3 * _wRv2) / _barPx * (double)psec);
            if(_sRv1 < 1) _sRv1 = 1;
            _tCol1 = _tCol0 + (datetime)_sRv1;
         }

         // Moc "het cot" ngoai cung (g_rv2ColEndTime): cot ngoai cung la RV2
         //   khi InpShowRv2RsiLbl bat, la RV1 khi tat rieng RV2. Gia tri nay
         //   con bi khoi "FIX - Chart Shift" o duoi keo lui neu vuot mep
         //   phai vung nhin thay - la gia tri CUOI CUNG cua g_rv2ColEndTime
         //   (khong bi ghi de them lan nao nua sau do).
         int      _wOut = InpShowRv2RsiLbl ? _wRv2  : _wRv1;
         datetime _tOut = InpShowRv2RsiLbl ? _tCol1 : _tCol0;
         if(_wOut > 0 && _tOut > 0)
         {
            long _sOut = (long)MathCeil((double)(_wOut + _pad) / _barPx * (double)psec);
            if(_sOut < 1) _sOut = 1;
            g_rv2ColEndTime = _tOut + (datetime)_sOut;
         }
      }

      // Rut ngan (khong bao gio keo gian them) khoang cach _tCol0->_tCol1 ve
      //   dung muc "sat mep": be rong THAT cua chu cot RV1 (_wRv1) cong khe
      //   ho chuan InpLblAutoPadPx (qua LblDpiScale()). Chi hoat dong khi
      //   khoang cach hien co (_curGap) LON HON muc sat mep nay; phan chenh
      //   lech la _rv1ToRv2Shift, cong vao _tCol0. Ket qua _tCol0 sau dong
      //   nay van chi la mot buoc trung gian - bi ghi de lan cuoi bang cong
      //   thuc "sat mep cot RV2" o gan cuoi ham (xem khoi "_tCol0 = _tCol1 -
      //   ..." o duoi). _tCol1/g_rv2ColEndTime KHONG bi dong toi o day.
      long _rv1ToRv2Shift = 0;
      if(InpLblAutoFitCols && _barPx > 0.0 && psec > 0 && _wRv1 > 0 && _tCol1 > _tCol0)
      {
         double _satMepPadPx = (double)((InpLblAutoPadPx < 0) ? 0 : InpLblAutoPadPx) * LblDpiScale();
         long   _sSatMep = (long)MathCeil(((double)_wRv1 + _satMepPadPx) / _barPx * (double)psec);
         if(_sSatMep < 1) _sSatMep = 1;
         long _curGap = (long)(_tCol1 - _tCol0);
         if(_curGap > _sSatMep)
            _rv1ToRv2Shift = _curGap - _sSatMep;
      }
      _tCol0 = _tCol0 + (datetime)_rv1ToRv2Shift;

      // Neu Chart Shift dang BAT: quy be rong vung "future space" ben phai
      //   (CHART_SHIFT_SIZE) ra giay, roi neu diem XA NHAT trong ba moc
      //   (_tCol0/_tCol1/g_rv2ColEndTime) vuot qua vung do thi keo lui CA BA
      //   mot khoang bang nhau (giu nguyen khoang cach tuong doi giua chung)
      //   de mep ngoai cung khop mep phai vung nhin thay - tranh nhan bi day
      //   ra khoi man hinh. Chart Shift TAT hoac khong doc duoc thiet lap ->
      //   giu nguyen cac moc da tinh. Luu y: _tCol0/_tCol1 bi keo lui o day
      //   se bi hai khoi ghi de "sat mep" ngay ben duoi tinh lai tu dau, chi
      //   con g_rv2ColEndTime la gia tri song sot tu buoc nay.
      if(InpLblAutoFitCols && _barPx > 0.0 && psec > 0)
      {
         long   _fixShiftOnL = 0;
         double _fixShiftPct = 0.0;
         if(ChartGetInteger(0, CHART_SHIFT, 0, _fixShiftOnL) && _fixShiftOnL != 0 &&
            ChartGetDouble (0, CHART_SHIFT_SIZE, 0, _fixShiftPct) && _fixShiftPct > 0.0)
         {
            long _fixWPx = ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
            if(_fixWPx > 0)
            {
               double _fixShiftPx = (double)_fixWPx * (_fixShiftPct / 100.0);
               long   _fixMaxSec  = (long)((_fixShiftPx / _barPx) * (double)psec);
               if(_fixMaxSec > 0)
               {
                  datetime _fixMaxT = tBase + (datetime)_fixMaxSec;
                  datetime _fixFar  = g_rv2ColEndTime;
                  if(_tCol1 > _fixFar) _fixFar = _tCol1;
                  if(_tCol0 > _fixFar) _fixFar = _tCol0;
                  if(_fixFar > _fixMaxT)
                  {
                     datetime _fixPullBack = _fixFar - _fixMaxT;
                     _tCol0          = _tCol0          - _fixPullBack;
                     _tCol1          = _tCol1          - _fixPullBack;
                     g_rv2ColEndTime = g_rv2ColEndTime - _fixPullBack;
                  }
               }
            }
         }
      }

      // GIA TRI CUOI CUNG cua _tCol1 (moc x hien thi that su cua cot RV2, doc
      //   boi vong for "Ghi de moc thoi gian..." ngay duoi): nen M1 dang chay
      //   hien tai + N nen M1 ve tuong lai (N = InpRv1Rv2LeftM1BarIdx). Dat o
      //   day, sau toan bo cac khoi tinh/ghi de _tCol1 phia tren, de khong bi
      //   khoi nao o tren ghi de lai nua.
      _tCol1 = iTime(_Symbol, PERIOD_M1, 0) + (datetime)(InpRv1Rv2LeftM1BarIdx * 60);

      _tCol0 = iTime(_Symbol, PERIOD_M1, 0) + (datetime)(InpRv1LeftM1FutureBars * 60);

      // Ghi de moc thoi gian cua tung nhan theo dung cot cua no.
      for(int _e = 0; _e < _olCnt; _e++)
         _olHead[_e] = (_olCol[_e] == 0) ? _tCol0 : _tCol1;

      // Vong for tren da ghi de _olHead[_rv1M1Idx] bang _tCol0 (cung cot voi cac nhan RV1 con lai) - gan lai _rv1m1FinalT (tinh o tren)
      //   de nhan RV1 khung 1m giu dung vi tri sat Pivot cua no.
      if(_rv1m1Ok) _olHead[_rv1M1Idx] = _rv1m1FinalT;

   }

   {
      for(int _c = 0; _c <= 1; _c++)       // 0 = cot RV1, 1 = cot RV2
      {
         int _lpIdx[RV2_TF_COUNT * 2];
         int _lpN = 0;
         for(int _e = 0; _e < _olCnt; _e++)
            if(_olCol[_e] == _c && _e != _rv1M1Idx && !_olHide[_e]) _lpIdx[_lpN++] = _e;
         if(_lpN < 1) continue;


         // Buoc gia mot hang theo font LON nhat cua cot (tranh de chong khi font lech nhau).
         int _lpMaxFs = 0;
         for(int _i = 0; _i < _lpN; _i++)
            if(_olFs[_lpIdx[_i]] > _lpMaxFs) _lpMaxFs = _olFs[_lpIdx[_i]];
         double _lpGap = (double)LblRowGapPx(_lpMaxFs) * _pxPr;
         if(_lpGap <= 0.0) _lpGap = _Point;

         double _lpSettled[RV2_TF_COUNT * 2];
         int    _lpSettledN = 0;

         for(int _i = 0; _i < _lpN; _i++)
         {
            int    _e     = _lpIdx[_i];
            double _rowPr = _olPrice[_e];   // mac dinh: dung DUNG vi tri gia that

            for(int _guard = 0; _guard < _lpN; _guard++)
            {
               bool _hit = false;
               for(int _k = 0; _k < _lpSettledN; _k++)
               {
                  if(MathAbs(_rowPr - _lpSettled[_k]) < _lpGap)
                  {
                     int    _dirVsK = (_olPrice[_e] >= _olPrice[_lpIdx[_k]]) ? +1 : -1;
                     double _cand   = _lpSettled[_k] + (double)_dirVsK * _lpGap;
                     if((_dirVsK > 0 && _cand > _rowPr) ||
                        (_dirVsK < 0 && _cand < _rowPr))
                     {
                        _rowPr = _cand;
                        _hit = true;
                     }
                  }
               }
               if(!_hit) break;
            }
            _lpSettled[_lpSettledN++] = _rowPr;

            if(ObjectFind(0, _olName[_e]) < 0)
               ObjectCreate(0, _olName[_e], OBJ_TEXT, 0, _olHead[_e], _rowPr);
            ObjectMove(0, _olName[_e], 0, _olHead[_e], _rowPr);
            ObjectSetString (0, _olName[_e], OBJPROP_TEXT,       _olText[_e]);
            ObjectSetInteger(0, _olName[_e], OBJPROP_COLOR,      _olClr[_e]);
            ObjectSetInteger(0, _olName[_e], OBJPROP_FONTSIZE,   _olFs[_e]);
            ObjectSetInteger(0, _olName[_e], OBJPROP_ANCHOR,     ANCHOR_LEFT);
            ObjectSetInteger(0, _olName[_e], OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, _olName[_e], OBJPROP_HIDDEN,     true);
            ObjectSetInteger(0, _olName[_e], OBJPROP_BACK,       false);
         }
      }

      if(_rv1M1Idx >= 0)
      {
         int    _mE     = _rv1M1Idx;
         double _mRowPr = _olPrice[_mE];

         long     _mOneM1  = (long)PeriodSeconds(PERIOD_M1);
         if(_mOneM1 < 1) _mOneM1 = 60;
         datetime _mShiftT = _olHead[_mE] - (datetime)_mOneM1;
         g_rv1M1LblT = _mShiftT;   // chia se moc thoi gian cho nhan lenh gia lap / nhan nhoi
         g_rv1M1LblPx = _mRowPr;   // chia se vi tri gia + co chu cho cot <TF> <(Bid - Open)/spread> (hang 2.. cua nhan RV1 1m, xem DrawMidPriceLabel())
         g_rv1M1LblFs = _olFs[_mE];

         if(_olHide[_mE])
            ObjectDelete(0, _olName[_mE]);   // 1m bi bo tick: moc g_rv1M1LblT o tren van duoc giu, chi go chu nhan
         else
         {
            if(ObjectFind(0, _olName[_mE]) < 0)
               ObjectCreate(0, _olName[_mE], OBJ_TEXT, 0, _mShiftT, _mRowPr);
            ObjectMove(0, _olName[_mE], 0, _mShiftT, _mRowPr);
            ObjectSetString (0, _olName[_mE], OBJPROP_TEXT,       _olText[_mE]);
            ObjectSetInteger(0, _olName[_mE], OBJPROP_COLOR,      _olClr[_mE]);
            ObjectSetInteger(0, _olName[_mE], OBJPROP_FONTSIZE,   _olFs[_mE]);
            ObjectSetInteger(0, _olName[_mE], OBJPROP_ANCHOR,     ANCHOR_LEFT);
            ObjectSetInteger(0, _olName[_mE], OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, _olName[_mE], OBJPROP_HIDDEN,     true);
            ObjectSetInteger(0, _olName[_mE], OBJPROP_BACK,       false);
         }

         // Da bo 3 hang cuoi cua cum nhan duoi than nen lon (brkD/pvD, TC, UPDDND): khong ghi g_bcTopTxt[0..2] nua -> BuildBarCurLblRows() khong chen hang nao.
      }
   }
   AptRndMarksDraw();   // danh dau cac muc lam tron da tinh duoc len thang gia (nhan trang + ten khung)
}

//+------------------------------------------------------------------+
//| DrawBarChart: ve than nen lon (khung g_barTF, toi da InpBarChartCount nen) bang OBJ_TREND: duong dung Low->High + vach Open (trai) + vach Close (phai). |
//+------------------------------------------------------------------+
void DrawBarChart()
{
   // Xóa toàn bộ object nến cũ trước, vẽ lại từ đầu (đồng bộ cách làm với các đường RV2)
   ObjectsDeleteAll(0, g_barPrefix, -1, OBJ_TREND);

   if(!InpShowBarChart) return;

   int cnt = InpBarChartCount;
   if(cnt < 1) return;

   MqlRates rt[];
   ArraySetAsSeries(rt, true);
   int _bcProbeN = (g_barTF != InpBarChartTF) ? 1 : cnt;
   int got = CopyRates(_Symbol, InpBarChartTF, 0, _bcProbeN, rt);
   if(got <= 0) return;

   long secPerBar = PeriodSeconds(InpBarChartTF);
   if(secPerBar <= 0) return;

   if(g_barTF != InpBarChartTF)
   {
      got = CopyRates(_Symbol, g_barTF, 0, cnt, rt);
      if(got <= 0) return;
      secPerBar = PeriodSeconds(g_barTF);
      if(secPerBar <= 0) return;
   }

   double   bodyFrac = MathMax(5, MathMin(95, InpBarBodyWidthPct)) / 100.0;
   datetime tickLen  = (datetime)((secPerBar * bodyFrac) / 2.0); // độ dài mỗi vạch open/close, tính từ tâm nến
   if(InpBarTickFixedLen)
   {
      // Uu tien neo theo SO NEN CUA CHART dang mo: be rong vach ra pixel luon co dinh,
      // khong phu thuoc InpBarChartTF, nen khung lon hay nho deu co vach ngan bang nhau.
      if(InpBarTickChartBars > 0)
      {
         long secChart = PeriodSeconds(_Period);
         if(secChart > 0) tickLen = (datetime)((long)InpBarTickChartBars * secChart);
      }
      else
      {
         long secTickRef = PeriodSeconds(InpBarTickRefTF);
         if(secTickRef > 0) tickLen = (datetime)((secTickRef * bodyFrac) / 2.0);
      }
   }
   if(tickLen < 1) tickLen = 1;

   for(int s = 0; s < got; s++)
   {
      bool  up  = (rt[s].close >= rt[s].open);
      color clr = up ? InpBarUpColor : InpBarDownColor;

      if(s == 0)
      {
         clr = clrAqua;
         int    _cClrIdx     = AptFindTfIndex(_Period);
         int    _cClrLvl     = -1;
         bool   _cClrLvlOk   = AptWoodieDisplayLvlForTF(_Period, _cClrLvl);
         string _cClrTenMuc  = (_cClrLvlOk && _cClrLvl >= 0) ? g_aptLvlName[_cClrLvl] : "";
         bool   _cClrDiffOk  = false;
         double _cClrDiffRv1 = 0.0;
         long   _cClrUpB     = 0;
         long   _cClrDnB     = 0;
         if(_cClrIdx >= 0)
           {
            double _cClrBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            double _cClrRv1 = g_rv1ValCache[_cClrIdx];
            if(_cClrBid > 0.0 && _cClrRv1 > 0.0)
              {
               _cClrDiffRv1 = _cClrBid - _cClrRv1;
               _cClrDiffOk  = true;
              }
            _cClrUpB  = g_aptBrkAccUpB[_cClrIdx];
            _cClrDnB  = g_aptBrkAccDnB[_cClrIdx];
           }
         if((_cClrTenMuc == "R4" || _cClrTenMuc == "R5" || _cClrTenMuc == "R6") && _cClrDiffOk && _cClrDiffRv1 > 0.0 && _cClrUpB > 0 && _cClrDnB == 0)
            clr = clrMagenta;
         else
            if(_cClrTenMuc == "R3" && _cClrDiffOk && _cClrDiffRv1 > 0.0 && _cClrUpB > 0 && _cClrDnB == 0)
               clr = clrOrange;
            else
               if(_cClrTenMuc == "R2" && _cClrDiffOk && _cClrDiffRv1 > 0.0 && _cClrUpB > 0 && _cClrDnB == 0)
                  clr = clrGold;
               else
                  if(_cClrTenMuc == "R1" && _cClrDiffOk && _cClrDiffRv1 > 0.0 && _cClrUpB > 0 && _cClrDnB == 0)
                     clr = clrYellow;
                  else
                     if((_cClrTenMuc == "R1" || _cClrTenMuc == "R2" || _cClrTenMuc == "R3" || _cClrTenMuc == "R4" || _cClrTenMuc == "R5") && _cClrUpB > 0 && _cClrDnB == 0)
                        clr = clrLime;
                     else
                        if((_cClrTenMuc == "S4" || _cClrTenMuc == "S5" || _cClrTenMuc == "S6") && _cClrDiffOk && _cClrDiffRv1 < 0.0 && _cClrDnB > 0 && _cClrUpB == 0)
                           clr = clrWhite;
                        else
                           if(_cClrTenMuc == "S3" && _cClrDiffOk && _cClrDiffRv1 < 0.0 && _cClrDnB > 0 && _cClrUpB == 0)
                              clr = clrLightGray;
                           else
                              if(_cClrTenMuc == "S2" && _cClrDiffOk && _cClrDiffRv1 < 0.0 && _cClrDnB > 0 && _cClrUpB == 0)
                                 clr = clrSilver;
                              else
                                 if(_cClrTenMuc == "S1" && _cClrDiffOk && _cClrDiffRv1 < 0.0 && _cClrDnB > 0 && _cClrUpB == 0)
                                    clr = clrLightSteelBlue;
                                 else
                                    if((_cClrTenMuc == "S1" || _cClrTenMuc == "S2" || _cClrTenMuc == "S3" || _cClrTenMuc == "S4" || _cClrTenMuc == "S5") && _cClrDnB > 0 && _cClrUpB == 0)
                                       clr = clrLightBlue;
      }

      //--- Kiểu "bar chart" cổ điển: 1 đường thẳng đứng tại giữa chu kỳ nến (Low->High)
      //    + 1 vạch ngang bên trái tại Open + 1 vạch ngang bên phải tại Close.
      //    Độ dài vạch Open/Close = bodyFrac * 1 chu kỳ nến (theo InpBarBodyWidthPct) ---
      datetime tMid = rt[s].time + (datetime)(secPerBar / 2);
      tMid = BarChartMidTime(s, rt[s].time, secPerBar);

      //--- Đường thẳng đứng: Low -> High ---
      string vertNm = g_barPrefix + "V" + IntegerToString(s);
      if(ObjectCreate(0, vertNm, OBJ_TREND, 0, tMid, rt[s].low, tMid, rt[s].high))
      {
         ObjectSetInteger(0, vertNm, OBJPROP_COLOR,      clr);
         ObjectSetInteger(0, vertNm, OBJPROP_WIDTH,      2);   // day them 1 co (duong thang dung Low->High)
         ObjectSetInteger(0, vertNm, OBJPROP_STYLE,      STYLE_SOLID);
         ObjectSetInteger(0, vertNm, OBJPROP_RAY_RIGHT,  false);
         ObjectSetInteger(0, vertNm, OBJPROP_RAY_LEFT,   false);
         ObjectSetInteger(0, vertNm, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, vertNm, OBJPROP_HIDDEN,     true);
         ObjectSetInteger(0, vertNm, OBJPROP_BACK,       true);
      }

      //--- Vạch Open: nằm bên trái đường thẳng đứng ---
      string openNm = g_barPrefix + "O" + IntegerToString(s);
      if(ObjectCreate(0, openNm, OBJ_TREND, 0, tMid - tickLen, rt[s].open, tMid, rt[s].open))
      {
         ObjectSetInteger(0, openNm, OBJPROP_COLOR,      clr);
         ObjectSetInteger(0, openNm, OBJPROP_WIDTH,      2);   // day them 1 co (vach Open)
         ObjectSetInteger(0, openNm, OBJPROP_STYLE,      STYLE_SOLID);
         ObjectSetInteger(0, openNm, OBJPROP_RAY_RIGHT,  false);
         ObjectSetInteger(0, openNm, OBJPROP_RAY_LEFT,   false);
         ObjectSetInteger(0, openNm, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, openNm, OBJPROP_HIDDEN,     true);
         ObjectSetInteger(0, openNm, OBJPROP_BACK,       true);
      }

      //--- Vạch Close: nằm bên phải đường thẳng đứng ---
      string closeNm = g_barPrefix + "C" + IntegerToString(s);
      if(ObjectCreate(0, closeNm, OBJ_TREND, 0, tMid, rt[s].close, tMid + tickLen, rt[s].close))
      {
         ObjectSetInteger(0, closeNm, OBJPROP_COLOR,      clr);
         ObjectSetInteger(0, closeNm, OBJPROP_WIDTH,      2);   // day them 1 co (vach Close)
         ObjectSetInteger(0, closeNm, OBJPROP_STYLE,      STYLE_SOLID);
         ObjectSetInteger(0, closeNm, OBJPROP_RAY_RIGHT,  false);
         ObjectSetInteger(0, closeNm, OBJPROP_RAY_LEFT,   false);
         ObjectSetInteger(0, closeNm, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, closeNm, OBJPROP_HIDDEN,     true);
         ObjectSetInteger(0, closeNm, OBJPROP_BACK,       true);
      }
   }
}

//+------------------------------------------------------------------+
//| BarChartMoveCurBar: keo BA object cua NEN DANG CHAY (s = 0) bam theo gia thoi gian thuc:|
//|       g_barPrefix + "V0"  = duong thang dung Low -> High           |
//|       g_barPrefix + "O0"  = vach Open  (ben trai)                  |
//|       g_barPrefix + "C0"  = vach Close (ben phai)                  |
//|                                                                    |
//|   DrawBarChart() chi chay khi CHART sinh nen moi (newBarOrFirst    |
//|   trong OnCalculate) hoac khi bam nut chon khung, nen rt[0].close/ |
//|   high/low da chup lai luc do; ham nay chay moi nhip OnTimer de    |
//|   dong bo lai.                                                     |
//|     - Chi dung ObjectMove tren object DA TON TAI (ObjectFind < 0 thi |
//|       bo qua; viec tao object do DrawBarChart() dam nhiem).        |
//|     - Chi dung toi nen s = 0; nen da dong (s >= 1) khong bi dung.  |
//|     - Moc thoi gian tMid va do dai vach tickLen tinh nhu DrawBarChart |
//|       (BarChartMidTime, InpBarTickFixedLen / InpBarTickChartBars /  |
//|       InpBarTickRefTF / InpBarBodyWidthPct).                        |
//|     - Mau cap nhat theo quy tac DrawBarChart (close >= open ->      |
//|       InpBarUpColor, con lai InpBarDownColor); cac thuoc tinh khac  |
//|       (WIDTH / STYLE / BACK...) giu nhu luc tao.                    |
//|     - Tat than nen (InpShowBarChart = false) -> thoat ngay.         |
//+------------------------------------------------------------------+
void BarChartMoveCurBar()
{
   if(!InpShowBarChart) return;

   // --- Khung ve than nen: bang nut 2 (g_barTF) neu khac input goc ---
   ENUM_TIMEFRAMES _cbTf = InpBarChartTF;
   if(g_barTF != InpBarChartTF) _cbTf = g_barTF;

   long _cbSecPerBar = PeriodSeconds(_cbTf);
   if(_cbSecPerBar <= 0) return;

   // --- Doc DUY NHAT nen dang chay cua khung do (tai rat nhe) ---
   MqlRates _cbRt[];
   ArraySetAsSeries(_cbRt, true);
   if(CopyRates(_Symbol, _cbTf, 0, 1, _cbRt) < 1) return;

   // --- Do dai vach Open/Close: SAO CHEP y het khoi trong DrawBarChart ---
   double   _cbBodyFrac = MathMax(5, MathMin(95, InpBarBodyWidthPct)) / 100.0;
   datetime _cbTickLen  = (datetime)((_cbSecPerBar * _cbBodyFrac) / 2.0);
   if(InpBarTickFixedLen)
   {
      if(InpBarTickChartBars > 0)
      {
         long _cbSecChart = PeriodSeconds(_Period);
         if(_cbSecChart > 0) _cbTickLen = (datetime)((long)InpBarTickChartBars * _cbSecChart);
      }
      else
      {
         long _cbSecTickRef = PeriodSeconds(InpBarTickRefTF);
         if(_cbSecTickRef > 0) _cbTickLen = (datetime)((_cbSecTickRef * _cbBodyFrac) / 2.0);
      }
   }
   if(_cbTickLen < 1) _cbTickLen = 1;

   // --- Tam nen: DUNG ham chung voi DrawBarChart / DrawBarChartLabels ---
   datetime _cbMid = BarChartMidTime(0, _cbRt[0].time, _cbSecPerBar);

   bool  _cbUp  = (_cbRt[0].close >= _cbRt[0].open);
   color _cbClr = _cbUp ? InpBarUpColor : InpBarDownColor;

   _cbClr = clrAqua;
   int    _cbClr2Idx    = AptFindTfIndex(_Period);
   int    _cbClr2Lvl    = -1;
   bool   _cbClr2LvlOk  = AptWoodieDisplayLvlForTF(_Period, _cbClr2Lvl);
   string _cbClr2TenMuc = (_cbClr2LvlOk && _cbClr2Lvl >= 0) ? g_aptLvlName[_cbClr2Lvl] : "";
   bool   _cbClr2DiffOk = false;
   double _cbClr2Diff   = 0.0;
   long   _cbClr2UpB    = 0;
   long   _cbClr2DnB    = 0;
   if(_cbClr2Idx >= 0)
     {
      double _cbClr2Bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double _cbClr2Rv1 = g_rv1ValCache[_cbClr2Idx];
      if(_cbClr2Bid > 0.0 && _cbClr2Rv1 > 0.0)
        {
         _cbClr2Diff   = _cbClr2Bid - _cbClr2Rv1;
         _cbClr2DiffOk = true;
        }
      _cbClr2UpB  = g_aptBrkAccUpB[_cbClr2Idx];
      _cbClr2DnB  = g_aptBrkAccDnB[_cbClr2Idx];
     }
   if((_cbClr2TenMuc == "R4" || _cbClr2TenMuc == "R5" || _cbClr2TenMuc == "R6") && _cbClr2DiffOk && _cbClr2Diff > 0.0 && _cbClr2UpB > 0 && _cbClr2DnB == 0)
      _cbClr = clrMagenta;
   else
      if(_cbClr2TenMuc == "R3" && _cbClr2DiffOk && _cbClr2Diff > 0.0 && _cbClr2UpB > 0 && _cbClr2DnB == 0)
         _cbClr = clrOrange;
      else
         if(_cbClr2TenMuc == "R2" && _cbClr2DiffOk && _cbClr2Diff > 0.0 && _cbClr2UpB > 0 && _cbClr2DnB == 0)
            _cbClr = clrGold;
         else
            if(_cbClr2TenMuc == "R1" && _cbClr2DiffOk && _cbClr2Diff > 0.0 && _cbClr2UpB > 0 && _cbClr2DnB == 0)
               _cbClr = clrYellow;
            else
               if((_cbClr2TenMuc == "R1" || _cbClr2TenMuc == "R2" || _cbClr2TenMuc == "R3" || _cbClr2TenMuc == "R4" || _cbClr2TenMuc == "R5") && _cbClr2UpB > 0 && _cbClr2DnB == 0)
                  _cbClr = clrLime;
               else
                  if((_cbClr2TenMuc == "S4" || _cbClr2TenMuc == "S5" || _cbClr2TenMuc == "S6") && _cbClr2DiffOk && _cbClr2Diff < 0.0 && _cbClr2DnB > 0 && _cbClr2UpB == 0)
                     _cbClr = clrWhite;
                  else
                     if(_cbClr2TenMuc == "S3" && _cbClr2DiffOk && _cbClr2Diff < 0.0 && _cbClr2DnB > 0 && _cbClr2UpB == 0)
                        _cbClr = clrLightGray;
                     else
                        if(_cbClr2TenMuc == "S2" && _cbClr2DiffOk && _cbClr2Diff < 0.0 && _cbClr2DnB > 0 && _cbClr2UpB == 0)
                           _cbClr = clrSilver;
                        else
                           if(_cbClr2TenMuc == "S1" && _cbClr2DiffOk && _cbClr2Diff < 0.0 && _cbClr2DnB > 0 && _cbClr2UpB == 0)
                              _cbClr = clrLightSteelBlue;
                           else
                              if((_cbClr2TenMuc == "S1" || _cbClr2TenMuc == "S2" || _cbClr2TenMuc == "S3" || _cbClr2TenMuc == "S4" || _cbClr2TenMuc == "S5") && _cbClr2DnB > 0 && _cbClr2UpB == 0)
                                 _cbClr = clrLightBlue;

   string _cbV = g_barPrefix + "V0";
   string _cbO = g_barPrefix + "O0";
   string _cbC = g_barPrefix + "C0";

   // --- (1) Duong thang dung Low -> High ---
   if(ObjectFind(0, _cbV) >= 0)
   {
      ObjectMove(0, _cbV, 0, _cbMid, _cbRt[0].low);
      ObjectMove(0, _cbV, 1, _cbMid, _cbRt[0].high);
      ObjectSetInteger(0, _cbV, OBJPROP_COLOR, _cbClr);
   }

   // --- (2) Vach Open (ben trai tam nen) ---
   if(ObjectFind(0, _cbO) >= 0)
   {
      ObjectMove(0, _cbO, 0, _cbMid - _cbTickLen, _cbRt[0].open);
      ObjectMove(0, _cbO, 1, _cbMid,              _cbRt[0].open);
      ObjectSetInteger(0, _cbO, OBJPROP_COLOR, _cbClr);
   }

   // --- (3) Vach Close (ben phai tam nen) ---
   if(ObjectFind(0, _cbC) >= 0)
   {
      ObjectMove(0, _cbC, 0, _cbMid,              _cbRt[0].close);
      ObjectMove(0, _cbC, 1, _cbMid + _cbTickLen, _cbRt[0].close);
      ObjectSetInteger(0, _cbC, OBJPROP_COLOR, _cbClr);
   }
}

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//==================================================================
//  MODULE MO PHONG QUAN LY LENH (port tu SimPositionManager_1.mq5)
//  (KHONG gui lenh that): nut BUY/SELL/DONG LENH CUOI/DONG TAT CA, duong DASHDOTDOT danh dau vi tri vao lenh, dem giay trong lai/trong lo,
//  danh gia huong vao lenh cua lenh goc + goi y vi tri nhoi lenh, canh bao khi co tinh nhoi them luc lenh goc dang lo,
//  cot nhan tin hieu RV1 da khung thoi gian.
//  Cac ham diem vao OnInit/OnDeinit/OnTick/OnTimer/OnChartEvent cua module duoc dat ten SpmOnInit/SpmOnDeinit/SpmOnTick/SpmOnTimer/SpmOnChartEvent
//  va duoc GOI TU BEN TRONG cac ham OnInit/OnDeinit/OnCalculate/OnTimer/OnChartEvent cua AutoPositionTool_UI, de hai bo tinh nang dung CHUNG
//  mot timer va mot vong OnCalculate/OnChartEvent thay vi chay thanh hai chuong trinh rieng tren cung 1 chart (nguyen nhan gay treo chart).
//==================================================================

//==================================================================
// 1. ENUM
//==================================================================
enum ENUM_STEP_MODE
  {
   STEP_POINTS = 0,  // Buoc co dinh theo diem
   STEP_ATR    = 1   // Buoc theo ATR
  };

//==================================================================
// 2. INPUT
//==================================================================
input group "=== 1. MO PHONG ==="
input double         InpLots             = 0.01;          // Khoi luong moi lenh (mo phong)
input bool           InpAllowOpposite    = false;         // Cho phep mo lenh nguoc huong lenh goc
// true = BUY va SELL la 2 ro DOC LAP:
//   moi chieu co LENH GOC rieng + dem nhoi rieng, bam BUY/SELL deu duoc bat
//   ke chieu kia dang co lenh. false = hanh vi cu (chieu nguoc bi chan/
//   hoac mo dang NGUOC HUONG theo InpAllowOpposite).
input bool           InpIndependentSides = true;          // BUY va SELL doc lap (moi chieu 1 lenh goc rieng)

input group "=== 2. NHOI LENH ==="
input int            InpMaxAdds          = 5;             // So lan nhoi toi da (moi lan 1 lenh)
// Mac dinh doi sang STEP_ATR
input ENUM_STEP_MODE InpStepMode         = STEP_ATR;      // Cach tinh buoc nhoi
input int            InpStepPoints       = 300;           // Buoc nhoi co dinh (diem)
input int            InpSpmATRPeriod        = 14;            // Chu ky ATR
input double         InpATRMult          = 0.5;           // He so ATR cho buoc nhoi

input group "=== 3. DIEU KIEN DUNG HUONG ==="
input int            InpMinHoldSeconds   = 60;            // Thoi gian giu lenh goc toi thieu (giay)
input int            InpMinProfitPoints  = 150;           // Lai toi thieu cua lenh goc (diem)
input double         InpMinTimeInProfit  = 60.0;          // % thoi gian nam trong lai toi thieu
input double         InpMaxAdverseRatio  = 40.0;          // MAE toi da so voi MFE (%) - do on dinh
input double         InpMinPeakRetain    = 60.0;          // Lai hien tai / dinh MFE toi thieu (%)

input group "=== 4. CANH BAO ==="
input bool           InpBlockAddWhenLoss = false;         // Chan han viec nhoi khi lenh goc dang lo
input int            InpConfirmSeconds   = 6;             // Thoi gian xac nhan nhoi khi lo (giay)
input bool           InpPopupAlert       = true;          // Bat Alert popup

input group "=== 5. HIEN THI ==="
input ENUM_BASE_CORNER InpSpmCorner         = CORNER_RIGHT_UPPER; // Goc neo hang nut
input int            InpX                = 8;             // Khoang cach X tinh tu goc
input int            InpY                = 20;            // Khoang cach Y tinh tu goc
input string         InpSpmFontName         = "Consolas";    // Font panel
input int            InpSpmFontSize         = 9;             // Co chu panel
input color          InpColBuy           = clrGold;       // Mau BUY (chieu tang)
input color          InpColSell          = clrWhiteSmoke; // Mau SELL (chieu giam)
input color          InpColAdd           = clrAqua;       // Mau muc nhoi goi y

//==================================================================
// 3. HANG SO / BIEN TOAN CUC
//==================================================================
#define SPM_PFX        "SPM_"
// tang gioi han ky tu cua nhan tren chart de cho vua
//   them phut:giay con lai cua nen, phut:giay tu luc lenh goc den luc nhoi
//   duoc lenh 1/2, va toc do lai/lo quy doi 60 giay o hang NHOI #1/#2 ma
//   khong bi Cut() cat mat phan moi them. Chi la hang so dinh dang hien
//   thi, khong phai input/setting giao dich nao cua code goc.
#define LBLCH      140    // so ky tu toi da cua nhan tren chart

// So luong doi tuong ve (object) TOI DA tren toan
//   chart (ObjectsTotal(0) - dem CA object cua indicator/EA KHAC, khong
//   rieng cua file nay) truoc khi bi coi la "qua nhieu, co the lam cham
//   redraw/ve nen". Nguong mang tinh tham khao (MT5 khong cong bo con so
//   chinh thuc), chon o muc de bat cac truong hop ro rang bat thuong.
#define SPM_OBJCOUNT_WARN     500
// Khoang cach toi thieu (giay) giua hai lan Print
//   canh bao "qua nhieu object" lien tiep, tranh spam Experts log moi giay
//   khi chart van tiep tuc co nhieu object (do SpmOnTimer() chay moi 1 giay).
#define SPM_OBJCOUNT_COOLDOWN 300
// Khoang cach (diem gia, tinh theo _Point) giua
//   2 hang nhan chu tin hieu RV1 xep thanh COT DOC (xem Rv1SignalDraw()).
//   Chi la hang so canh chinh HIEN THI, khong phai input/setting giao dich
//   nao cua code goc.
#define RV1SIG_STEP_PTS       150

string BTN_BUY       = SPM_PFX + "BTN_BUY";
string BTN_SELL      = SPM_PFX + "BTN_SELL";
string BTN_CLOSELAST = SPM_PFX + "BTN_CLOSELAST";
string BTN_CLOSEALL  = SPM_PFX + "BTN_CLOSEALL";

struct SimPos
  {
   int      id;            // so thu tu lenh mo phong
   int      type;          // 0 = BUY, 1 = SELL
   double   price;         // gia vao lenh
   double   lots;          // khoi luong
   datetime tOpen;         // thoi gian server (de neo duong ve)
   double   mfePts;        // dinh lai (diem, >=0)
   double   maePts;        // day lo  (diem, <=0)
   int      secProfit;     // so giay nam trong LAI
   int      secLoss;       // so giay nam trong LO
   int      secFlat;       // so giay hoa von
   double   pts;           // lai/lo hien tai (diem)
   double   pl;            // lai/lo hien tai (tien)
   string   tag;           // nhan: LENH GOC / NHOI #n / NHOI KHI LO / NGUOC HUONG
  };

SimPos   g_pos[];
int      g_nextId       = 1;
datetime g_lastCalc     = 0;

// Lich su lenh DA DONG (de thong ke) + bo cong don cua bang thong ke. Xem muc 10B.
struct SimHist
  {
   int      type;        // 0 = BUY, 1 = SELL
   double   lots;
   double   pl;          // lai/lo luc dong (tien)
   int      secProfit;   // so giay nam trong LAI
   int      secLoss;     // so giay nam trong LO
   int      holdSec;     // thoi gian giu lenh (giay)
   datetime tOpenGmt;    // gio mo lenh theo GMT
   string   tag;
  };
SimHist g_hist[];

// Chi tiet gia vao tung lenh de bang thong ke liet ke "<gia vao><TenMuc 1m>" cua lenh thang / thua (xem StDetRows()).
struct SStDet
  {
   int      type;     // 0 = BUY, 1 = SELL
   double   pl;       // lai/lo (tien): > 0 thang, < 0 thua
   double   price;    // gia vao lenh
   datetime tGmt;     // gio mo lenh theo GMT (cung quy uoc g_hist[].tOpenGmt)
  };
SStDet g_hpx[];       // lenh mo phong DA DONG: nap tu file SPM_<symbol>_hpx.csv (file phu cua _hist.csv, 1 dong / lenh dong)

struct SStat
  {
   int    nB, nS;
   double lotB, lotS;
   double prof, loss;
   int    nWin, nLose;
   long   secP, secL;
   double lotWin, lotLose;
   long   holdWin, holdLose;
   double sessP[3], sessL[3];
   int    sessN[3];
   double hourP[24], hourL[24];
  };
SStat g_st;

void HistAdd(const SimPos &p);
void SpmStatsDraw();
void SlRecord(const int id, const int type);   // chot gia chan lo luc vao lenh (muc 7A)
void SlDrop(const int id);                    // xoa gia chan lo + vach khi dong lenh (muc 7A)

//--- thong ke ro lenh
int      g_bSecProfit   = 0;
int      g_bSecLoss     = 0;
int      g_bSecFlat     = 0;

//--- thong ke da dong
double   g_realized     = 0.0;
int      g_closedCount  = 0;

//--- THEO DOI NGUONG NHOI HIEN TAI NHU MOT LENH AO (chi de thong ke)
//    Khong mo lenh that, khong tao them bat ky duong ve nao: van dung
//    dung 1 duong ADD da co san trong code goc, chi bo sung so lieu
//    lai/lo va thoi gian cong don vao nhan cua duong do.
// moi bien la mang [2] theo CHIEU
//   ([0] = BUY, [1] = SELL) de ve + thong ke RIENG duong nhoi cua tung chieu.
int      g_addKey[2]       = {-1, -1}; // moc nhan dien nguong (theo chieu)
double   g_addPts[2];                  // lai/lo ao cua nguong (diem)
double   g_addPl[2];                   // lai/lo ao cua nguong (tien)
int      g_addSecProfit[2];            // thoi gian cong don nguong nam trong LAI (giay)
int      g_addSecLoss[2];              // thoi gian cong don nguong nam trong LO  (giay)
int      g_addSecFlat[2];              // thoi gian cong don nguong hoa von (giay)

//--- xac nhan nhoi khi dang lo
int      g_confirmType  = -1;
datetime g_confirmTime  = 0;

//--- ATR
int      g_atr          = INVALID_HANDLE;

//--- chi ve lai chart khi that su co gi thay doi
bool     g_needRedraw   = false;

// moc thoi gian Print canh bao "qua nhieu object
//   tren chart" gan nhat - dung voi SPM_OBJCOUNT_COOLDOWN de khong spam
//   Experts log (xem WarnIfManyChartObjects()).
datetime g_lastObjWarn  = 0;

//==================================================================
// 4. TIEN ICH CHUNG
//==================================================================
double AskP() { return SymbolInfoDouble(_Symbol, SYMBOL_ASK); }
double BidP() { return SymbolInfoDouble(_Symbol, SYMBOL_BID); }

//--- gia dung de DONG mot lenh (mo phong)
double ClosePriceFor(int type) { return (type == 0) ? BidP() : AskP(); }
//--- gia dung de MO mot lenh (mo phong)
double OpenPriceFor(int type)  { return (type == 0) ? AskP() : BidP(); }

string SideName(int type) { return (type == 0) ? "BUY" : "SELL"; }
color  SideColor(int type){ return (type == 0) ? InpColBuy : InpColSell; }

string AccCur() { return AccountInfoString(ACCOUNT_CURRENCY); }

string PriceStr(double p) { return DoubleToString(p, _Digits); }

//--- cat bot chuoi qua dai
string Cut(string s, int mx)
  {
   if(StringLen(s) > mx)
      s = StringSubstr(s, 0, mx - 1) + "~";
   return s;
  }

void SpmDoAlert(string m)
  {
   Print("[SPM] ", m);
   if(InpPopupAlert)
      Alert(_Symbol + " | " + m);
  }

//--- khong con panel: thong bao chi ra Experts log
void SetWarn(string m)
  {
   Print("[SPM] ", m);
  }

//--- lai/lo bang tien cua 1 lenh mo phong
double PosProfit(const SimPos &p)
  {
   double res = 0.0;
   ENUM_ORDER_TYPE t = (p.type == 0) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   if(!OrderCalcProfit(t, _Symbol, p.lots, p.price, ClosePriceFor(p.type), res))
     {
      double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
      double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      if(tickSize > 0.0)
        {
         double dir = (p.type == 0) ? 1.0 : -1.0;
         res = (ClosePriceFor(p.type) - p.price) * dir / tickSize * tickValue * p.lots;
        }
      else
         res = 0.0;
     }
   return res;
  }

double BasketPL()
  {
   double s = 0.0;
   for(int i = 0; i < ArraySize(g_pos); i++)
      s += g_pos[i].pl;
   return s;
  }

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//--- buoc nhoi hien tai (diem)
int StepPointsNow()
  {
   if(InpStepMode == STEP_POINTS)
      return InpStepPoints;

   double buf[];
   if(g_atr != INVALID_HANDLE && CopyBuffer(g_atr, 0, 0, 1, buf) == 1 && buf[0] > 0.0)
     {
      int p = (int)MathRound(buf[0] * InpATRMult / _Point);
      if(p < 10)
         p = 10;
      return p;
     }
   return InpStepPoints;
  }

// --- vi tri LENH GOC cua 1 chieu (lenh dau tien cung
//    chieu type). type < 0 = lenh goc chung g_pos[0] nhu code cu. -1 = khong co.
int BaseIdx(int type = -1)
  {
   int n = ArraySize(g_pos);
   if(n == 0)
      return -1;
   if(type < 0)
      return 0;
   for(int i = 0; i < n; i++)
      if(g_pos[i].type == type)
         return i;
   return -1;
  }

//--- so lan da nhoi (khong tinh lenh goc, khong tinh lenh nguoc huong)
int AddsDone(int type = -1)
  {
   int n  = ArraySize(g_pos);
   int bi = BaseIdx(type);
   if(bi < 0)
      return 0;
   int base = g_pos[bi].type;
   int c = 0;
   for(int i = bi + 1; i < n; i++)
      if(g_pos[i].type == base)
         c++;
   return c;
  }

//--- gia goi y cho lan nhoi ke tiep = gia lenh cung huong gan nhat + 1 buoc
double NextAddPrice(int type = -1)
  {
   int n  = ArraySize(g_pos);
   int bi = BaseIdx(type);
   if(bi < 0)
      return 0.0;
   int base = g_pos[bi].type;
   double last = g_pos[bi].price;
   for(int i = bi + 1; i < n; i++)
      if(g_pos[i].type == base)
         last = g_pos[i].price;

   double step = StepPointsNow() * _Point;
   return (base == 0) ? (last + step) : (last - step);
  }

//==================================================================
// 5. DANH GIA HUONG VAO LENH CUA LENH GOC
//    0 = SAI HUONG (dang lo) | 1 = CHUA DU DIEU KIEN | 2 = DUNG HUONG
//==================================================================
int EvaluateFirst(string &detail, int type = -1)
  {
   detail = "";
   int bi = BaseIdx(type);
   if(bi < 0)
      return 1;

   SimPos p   = g_pos[bi];
   int    hold = p.secProfit + p.secLoss + p.secFlat;
   double ratio = (hold > 0) ? (100.0 * p.secProfit / hold) : 0.0;
   double mfe = p.mfePts;
   double mae = -p.maePts;                    // doi ve so duong

   bool cHold    = (hold >= InpMinHoldSeconds);
   bool cProfit  = (p.pts >= InpMinProfitPoints);
   bool cTime    = (ratio >= InpMinTimeInProfit);
   bool cAdverse = (mfe > 0.0) ? (mae <= mfe * InpMaxAdverseRatio / 100.0) : false;
   bool cRetain  = (mfe > 0.0) ? (p.pts >= mfe * InpMinPeakRetain / 100.0) : false;

   detail = StringFormat("%sgiu %d/%d  %slai %.0f/%d  %s%%lai %.0f/%.0f  %sMAE/MFE %.0f/%.0f  %sdinh %.0f/%.0f",
                         cHold    ? "[v]" : "[x]", hold, InpMinHoldSeconds,
                         cProfit  ? "[v]" : "[x]", p.pts, InpMinProfitPoints,
                         cTime    ? "[v]" : "[x]", ratio, InpMinTimeInProfit,
                         cAdverse ? "[v]" : "[x]", (mfe > 0.0 ? 100.0 * mae / mfe : 999.0), InpMaxAdverseRatio,
                         cRetain  ? "[v]" : "[x]", (mfe > 0.0 ? 100.0 * p.pts / mfe : 0.0), InpMinPeakRetain);

   if(p.pts < 0.0)
      return 0;
   if(cHold && cProfit && cTime && cAdverse && cRetain)
      return 2;
   return 1;
  }

//==================================================================
// 6. MO / DONG LENH MO PHONG
//==================================================================
void OpenSim(int type, string tag)
  {
   int n = ArraySize(g_pos);
   ArrayResize(g_pos, n + 1);

   g_pos[n].id         = g_nextId++;
   g_pos[n].type       = type;
   g_pos[n].price      = OpenPriceFor(type);
   g_pos[n].lots       = InpLots;
   g_pos[n].tOpen      = TimeCurrent();
   g_pos[n].mfePts     = 0.0;
   g_pos[n].maePts     = 0.0;
   g_pos[n].secProfit  = 0;
   g_pos[n].secLoss    = 0;
   g_pos[n].secFlat    = 0;
   g_pos[n].pts        = 0.0;
   g_pos[n].pl         = 0.0;
   g_pos[n].tag        = tag;

   Print(StringFormat("[SPM] MO PHONG mo lenh #%d %s %.2f @ %s (%s)",
                      g_pos[n].id, SideName(type), g_pos[n].lots, PriceStr(g_pos[n].price), tag));
   SlRecord(g_pos[n].id, type);   // chot gia chan lo (-----STB / -----STS) theo Pivot 1m luc vao lenh
   SaveState();
  }

void DeletePosObjects(int id)
  {
   ObjectDelete(0, SPM_PFX + "L"  + (string)id);
   ObjectDelete(0, SPM_PFX + "LT" + (string)id);
   SlDrop(id);   // vach chan lo + gia chan lo da luu cua lenh nay
  }

void RemoveAt(int idx)
  {
   int n = ArraySize(g_pos);
   if(idx < 0 || idx >= n)
      return;

   g_realized += g_pos[idx].pl;
   g_closedCount++;
   HistAdd(g_pos[idx]);   // luu lenh vua dong de thong ke
   Print(StringFormat("[SPM] MO PHONG dong lenh #%d %s @ %s | PL %.2f %s | lai %ds / lo %ds",
                      g_pos[idx].id, SideName(g_pos[idx].type), PriceStr(ClosePriceFor(g_pos[idx].type)),
                      g_pos[idx].pl, AccCur(), g_pos[idx].secProfit, g_pos[idx].secLoss));
   DeletePosObjects(g_pos[idx].id);

   for(int i = idx; i < n - 1; i++)
      g_pos[i] = g_pos[i + 1];
   ArrayResize(g_pos, n - 1);
  }

void CloseLast()
  {
   int n = ArraySize(g_pos);
   if(n == 0)
     {
      SetWarn("Khong co lenh mo phong nao de dong.");
      return;
     }
   RemoveAt(n - 1);
   if(ArraySize(g_pos) == 0)
      ResetBasketStats();
   SetWarn("Da dong lenh cuoi (mo phong).");
   SaveState();
  }

void CloseAll()
  {
   int n = ArraySize(g_pos);
   if(n == 0)
     {
      SetWarn("Khong co lenh mo phong nao de dong.");
      return;
     }
   while(ArraySize(g_pos) > 0)
      RemoveAt(ArraySize(g_pos) - 1);

   ResetBasketStats();
   DeleteAddObjects();
   SetWarn("Da dong TAT CA lenh mo phong.");
   SaveState();
  }

//--- xoa bo dem cua NGUONG NHOI ao (goi khi moc nguong doi hoac dong ro)
//    side = 0/1: chi xoa chieu do; side < 0: xoa ca 2 chieu.
void ResetAddStats(int side = -1)
  {
   for(int k = 0; k < 2; k++)
     {
      if(side >= 0 && k != side)
         continue;
      g_addSecProfit[k] = 0;
      g_addSecLoss[k]   = 0;
      g_addSecFlat[k]   = 0;
      g_addPts[k]       = 0.0;
      g_addPl[k]        = 0.0;
     }
  }

// --- chieu s (0 BUY / 1 SELL) co duong nhoi can theo
//    doi khong; argOut = tham so chieu truyen cho AddsDone/NextAddPrice/
//    EvaluateFirst (-1 = lenh goc chung g_pos[0] nhu code cu).
bool AddSideActive(int s, int &argOut)
  {
   int n = ArraySize(g_pos);
   bool active;
   if(InpIndependentSides)
     {
      argOut = s;
      active = (BaseIdx(s) >= 0);
     }
   else
     {
      argOut = -1;
      active = (n > 0 && g_pos[0].type == s);
     }
   return active && AddsDone(argOut) < InpMaxAdds;
  }

string AddLineName(int s) { return SPM_PFX + "ADD"  + (s == 0 ? "B" : "S"); }
string AddTextName(int s) { return SPM_PFX + "ADDT" + (s == 0 ? "B" : "S"); }

void DeleteAddObjects()
  {
   for(int k = 0; k < 2; k++)
     {
      ObjectDelete(0, AddLineName(k));
      ObjectDelete(0, AddTextName(k));
     }
  }

void ResetBasketStats()
  {
   g_bSecProfit = 0;
   g_bSecLoss   = 0;
   g_bSecFlat   = 0;
   g_confirmType = -1;
   g_confirmTime = 0;
   //--- BO SUNG: xoa luon bo dem lai/lo + thoi gian cong don cua nguong nhoi
   ResetAddStats();
   g_addKey[0]   = -1;
   g_addKey[1]   = -1;
  }

//------------------------------------------------------------------
// Xu ly bam nut BUY / SELL
//------------------------------------------------------------------
void TryOpen(int type)
  {
   int n = ArraySize(g_pos);

   //--- 1) chua co lenh nao -> mo lenh goc
   if(n == 0)
     {
      OpenSim(type, "LENH GOC");
      SetWarn("Da mo LENH GOC " + SideName(type) + " (mo phong). Theo doi %time trong lai truoc khi nhoi.");
      return;
     }

   int bi = 0;
   if(InpIndependentSides)
     {
      bi = BaseIdx(type);
      if(bi < 0)
        {
         OpenSim(type, "LENH GOC");
         SetWarn("Da mo LENH GOC " + SideName(type) + " (mo phong, doc lap voi chieu con lai).");
         return;
        }
     }

   int base = g_pos[bi].type;
   int sideArg = InpIndependentSides ? type : -1;

   //--- 2) nguoc huong lenh goc
   if(type != base)
     {
      if(!InpAllowOpposite)
        {
         string m = "CHAN: lenh " + SideName(type) + " NGUOC HUONG lenh goc " + SideName(base) +
                    ". Dong ro truoc, hoac bat InpAllowOpposite.";
         SetWarn(m);
         SpmDoAlert(m);
         return;
        }
      OpenSim(type, "NGUOC HUONG");
      SetWarn("Da mo lenh NGUOC HUONG lenh goc - day KHONG phai nhoi lenh, danh gia huong van tinh theo lenh goc.");
      return;
     }

   //--- 3) cung huong -> day la mot lan NHOI
   int adds = AddsDone(sideArg);
   if(adds >= InpMaxAdds)
     {
      string m = StringFormat("CHAN: da nhoi du %d/%d lan. Khong nhoi them.", adds, InpMaxAdds);
      SetWarn(m);
      SpmDoAlert(m);
      return;
     }

   double p0pts = g_pos[bi].pts;
   double p0pl  = g_pos[bi].pl;

   //--- 3a) LENH GOC DANG LO -> CANH BAO
   if(p0pts < 0.0)
     {
      string m = StringFormat("CANH BAO NHOI NGUOC KY VONG: lenh goc %s dang LO %.0f diem (%.2f %s) - %d giay nam trong lo. Nhoi them cung huong luc nay la trung binh gia xuong, rui ro tang theo cap so.",
                              SideName(base), -p0pts, p0pl, AccCur(), g_pos[bi].secLoss);

      if(InpBlockAddWhenLoss)
        {
         SetWarn(m + " [DA CHAN theo cai dat]");
         SpmDoAlert(m);
         return;
        }

      if(g_confirmType != type || (int)(TimeLocal() - g_confirmTime) > InpConfirmSeconds)
        {
         g_confirmType = type;
         g_confirmTime = TimeLocal();
         SetWarn(m + StringFormat(" -> Bam %s them lan nua trong %ds de XAC NHAN.", SideName(type), InpConfirmSeconds));
         SpmDoAlert(m);
         return;
        }

      g_confirmType = -1;
      OpenSim(type, "NHOI KHI DANG LO");
      SetWarn("DA NHOI TRONG TRANG THAI LO (co xac nhan) - theo doi chat, khong nen nhoi tiep.");
      SpmDoAlert("Da nhoi them 1 lenh trong khi lenh goc dang lo.");
      return;
     }

   //--- 3b) lenh goc dang lai -> kiem tra do "dung huong"
   string detail = "";
   int score = EvaluateFirst(detail, sideArg);

   double addPrice = NextAddPrice(sideArg);
   double cur      = OpenPriceFor(type);
   bool   reached  = (base == 0) ? (cur >= addPrice) : (cur <= addPrice);

   string note = "";
   if(score < 2)
      note += "Lenh goc CHUA du dieu kien dung huong. ";
   if(!reached)
      note += StringFormat("Gia chua dat muc nhoi goi y %s. ", PriceStr(addPrice));

   OpenSim(type, StringFormat("NHOI #%d", adds + 1));

   if(StringLen(note) > 0)
     {
      SetWarn("LUU Y: " + note + "Da nhoi theo lenh thu cong (mo phong).");
      SpmDoAlert(note);
     }
   else
      SetWarn(StringFormat("Da nhoi lan %d/%d dung muc goi y, thuan huong lenh goc.", adds + 1, InpMaxAdds));
  }

//==================================================================
// 7. VE DUONG DANH DAU VI TRI VAO LENH (DASHDOTDOT)
//==================================================================
datetime RightAnchor()
  {
   datetime t0 = iTime(_Symbol, _Period, 0);
   if(t0 == 0)
      t0 = TimeCurrent();
   return t0;                 // dung o nen hien tai, nhan moc nguoc sang TRAI
  }

// --- dinh dang so giay thanh chuoi "phut:giay"
//--- (giay luon 2 chu so), dung chung cho ca 3 gia tri moi bo sung o duoi.
string FmtMinSec(int totalSec)
  {
   if(totalSec < 0)
      totalSec = 0;
   int m = totalSec / 60;
   int s = totalSec % 60;
   return StringFormat("%d:%02d", m, s);
  }

//+------------------------------------------------------------------+

// --- toc do lai/lo cua 1 lenh mo phong tinh THEO GIAY
//--- ($/giay) - lai/lo hien tai (p.pl) chia cho tong so giay da giu lenh
//--- (p.secProfit + p.secLoss + p.secFlat). KHONG nhan 60 nua (ban truoc
//--- quy doi ra "moi 60 giay" - theo yeu cau doi lai thanh gia tri thuan
//--- tren 1 giay). Dung cho hang hien toc do o duoi khoi MACRO.
double RatePerSec(const SimPos &p)
  {
   int hold = p.secProfit + p.secLoss + p.secFlat;
   if(hold <= 0)
      return 0.0;
   return p.pl / hold;
  }

//--- chi ghi thuoc tinh khi gia tri thuc su khac -> khong lam nghen chart
void SetStr(string nm, ENUM_OBJECT_PROPERTY_STRING prop, string v)
  {
   if(ObjectGetString(0, nm, prop) != v)
     {
      ObjectSetString(0, nm, prop, v);
      g_needRedraw = true;
     }
  }

void SetInt(string nm, ENUM_OBJECT_PROPERTY_INTEGER prop, long v, int mod = 0)
  {
   if(ObjectGetInteger(0, nm, prop, mod) != v)
     {
      ObjectSetInteger(0, nm, prop, mod, v);
      g_needRedraw = true;
     }
  }

void SetDbl(string nm, ENUM_OBJECT_PROPERTY_DOUBLE prop, double v, int mod = 0)
  {
   if(ObjectGetDouble(0, nm, prop, mod) != v)
     {
      ObjectSetDouble(0, nm, prop, mod, v);
      g_needRedraw = true;
     }
  }

void DrawOneLine(string name, datetime t1, double p1, datetime t2, double p2, color c, int width, string txt, string tname)
  {
   if(ObjectFind(0, name) < 0)
     {
      ObjectCreate(0, name, OBJ_TREND, 0, t1, p1, t2, p2);
      ObjectSetInteger(0, name, OBJPROP_STYLE,     STYLE_DASHDOTDOT);
      ObjectSetInteger(0, name, OBJPROP_RAY_LEFT,  false);
      ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
      ObjectSetInteger(0, name, OBJPROP_BACK,      false);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN,    true);
     }
   SetInt(name, OBJPROP_TIME,  (long)t1, 0);
   SetDbl(name, OBJPROP_PRICE, p1, 0);
   SetInt(name, OBJPROP_TIME,  (long)t2, 1);
   SetDbl(name, OBJPROP_PRICE, p2, 1);
   SetInt(name, OBJPROP_COLOR, (long)c);
   SetInt(name, OBJPROP_WIDTH, width);

   if(ObjectFind(0, tname) < 0)
     {
      ObjectCreate(0, tname, OBJ_TEXT, 0, t2, p2);
      ObjectSetInteger(0, tname, OBJPROP_ANCHOR,     ANCHOR_RIGHT_LOWER);
      ObjectSetString (0, tname, OBJPROP_FONT,       InpSpmFontName);
      ObjectSetInteger(0, tname, OBJPROP_FONTSIZE,   InpSpmFontSize);
      ObjectSetInteger(0, tname, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, tname, OBJPROP_HIDDEN,     true);
     }
   datetime tLbl = (g_rv1M1LblT > 0) ? g_rv1M1LblT : t2;
   SetInt(tname, OBJPROP_TIME,   (long)tLbl);
   SetInt(tname, OBJPROP_ANCHOR, (g_rv1M1LblT > 0) ? ANCHOR_LEFT_LOWER : ANCHOR_RIGHT_LOWER);
   SetDbl(tname, OBJPROP_PRICE, p2);
   SetInt(tname, OBJPROP_COLOR, (long)c);
   SetStr(tname, OBJPROP_TEXT,  txt);
  }

void DrawLines()
  {
   datetime tR = RightAnchor();
   int n = ArraySize(g_pos);

   for(int i = 0; i < n; i++)
     {
      string nm  = SPM_PFX + "L"  + (string)g_pos[i].id;
      string tnm = SPM_PFX + "LT" + (string)g_pos[i].id;

      string tip = "";
      int  sideArg = InpIndependentSides ? g_pos[i].type : -1;
      int  bIdx    = BaseIdx(sideArg);
      bool isBase  = (i == bIdx);
      if(isBase)
        {
         string dd = "";
         int    s0 = EvaluateFirst(dd, sideArg);

         string hd = (s0 == 2) ? "DU DIEU KIEN NHOI"
                     : ((s0 == 0) ? "DANG LO - KHONG NEN NHOI" : "CHUA DU DIEU KIEN - NEN CHO");
         StringReplace(dd, "  ", "\n");
         tip = "DANH GIA LENH GOC: " + hd + "\n" + dd;
        }
      //--- 1 hang: #<id> <BUY|SELL> <lot> <+-lai/lo> $/s <+-lai/lo tren 1 giay>$
      string txtBase = StringFormat("#%d %s %.2f %+.2f $/s %+.4f$",
                                    g_pos[i].id, SideName(g_pos[i].type), g_pos[i].lots,
                                    g_pos[i].pl, RatePerSec(g_pos[i]));

      if(g_pos[i].tag == "NHOI #2")
        {
         int sinceBase2 = (int)(g_pos[i].tOpen - g_pos[bIdx < 0 ? 0 : bIdx].tOpen);
         txtBase += StringFormat(" | nhoi2 sau %s", FmtMinSec(sinceBase2));
        }

      string txt = Cut(txtBase, LBLCH);

      //--- keo dai net ve VE TRAI toi thieu 25 nen tinh tu nen hien tai
      //--- (dung y het do dai duong goi y nhoi lenh o duoi), tranh truong
      //--- hop lenh vua moi mo (tOpen ~ tR) khien duong gan nhu khong co do
      //--- dai, rat kho thay tren chart. Lenh da mo lau (tOpen xa hon 25 nen)
      //--- van neo DUNG thoi diem vao lenh that, khong doi.
      datetime tLineStart = g_pos[i].tOpen;
      datetime tMinStart  = (datetime)(tR - (long)PeriodSeconds() * 25);
      if(tLineStart > tMinStart)
         tLineStart = tMinStart;

      DrawOneLine(nm, tLineStart, g_pos[i].price, tR, g_pos[i].price,
                  SideColor(g_pos[i].type), (isBase ? 2 : 1), txt, tnm);

      if(isBase)
        {
         SetStr(nm,  OBJPROP_TOOLTIP, tip);
         SetStr(tnm, OBJPROP_TOOLTIP, tip);
        }
     }

   //--- duong goi y vi tri nhoi
   // ve RIENG 1 duong nhoi cho BUY (SPM_ADDB/ADDTB) va 1 cho SELL (SPM_ADDS/ADDTS), moi duong tinh theo lenh goc cung chieu.
   for(int s = 0; s < 2; s++)
     {
      string an = AddLineName(s), at = AddTextName(s);
      int    arg = -1;
      if(!AddSideActive(s, arg))
        {
         ObjectDelete(0, an);
         ObjectDelete(0, at);
         continue;
        }

      double ap = NextAddPrice(arg);
      datetime tL = (datetime)(RightAnchor() - (long)PeriodSeconds() * 25);
      string   d  = "";
      int      sc = EvaluateFirst(d, arg);
      int      aHold = g_addSecProfit[s] + g_addSecLoss[s] + g_addSecFlat[s];
      string   tx = Cut(StringFormat("NHOI %s #%d %+.2f$",
                                     SideName(s), AddsDone(arg) + 1, g_addPl[s]), LBLCH);
      color    cc = (sc == 2) ? InpColAdd : ((sc == 0) ? clrRed : clrOrange);
      DrawOneLine(an, tL, ap, RightAnchor(), ap, cc, 1, tx, at);

      string dtip = d;
      StringReplace(dtip, "  ", "\n");
      double aRatio = (aHold > 0) ? (100.0 * g_addSecProfit[s] / aHold) : 0.0;
      dtip = StringFormat("MUC NHOI %s #%d @ %s (buoc %d pt)\n" +
                          "Lai/lo neu vao tai muc nay: %+.0f diem (%+.2f %s)\n" +
                          "Thoi gian theo doi: %ds | trong LAI %ds | trong LO %ds | hoa von %ds\n" +
                          "%% thoi gian nam trong lai: %.0f%%\n" +
                          "DIEU KIEN LENH GOC %s:\n%s",
                          SideName(s), AddsDone(arg) + 1, PriceStr(ap), StepPointsNow(),
                          g_addPts[s], g_addPl[s], AccCur(),
                          aHold, g_addSecProfit[s], g_addSecLoss[s], g_addSecFlat[s],
                          aRatio, SideName(s), dtip);
      SetStr(an, OBJPROP_TOOLTIP, dtip);
      SetStr(at, OBJPROP_TOOLTIP, dtip);
     }
  }

//==================================================================
// 7A. VACH CHAN LO "-----STB" / "-----STS" (lenh gia lap)
//
//  MOI lenh gia lap co 1 vach chan lo trang: BUY -> "-----STB" tai muc S cua Pivot khung 1m, SELL -> "-----STS" tai muc R cua Pivot khung 1m.
//  GIA CHAN LO DUOC CHOT 1 LAN LUC VAO LENH (SlRecord() goi tu OpenSim()) va KHONG dich chuyen theo Pivot/S/R sau do; chi truc THOI GIAN bam theo nhan Pivot 1m.
//  Muc = muc dang chon o bang Pivot UI (g_pivotLevelIdx) TAI LUC VAO LENH: BUY lay muc S (chon Rn thi doi sang Sn), SELL lay muc R (chon Sn thi doi sang Rn);
//  PP giu nguyen PP. Gia = EMA Pivot khung 1m cua muc do luc do (cung gia tri duong/nhan Pivot 1m, AptPivotEmaSeriesLvl()).
//  CHAN LO THAT SU: CheckStopLosses() (UpdateAll, moi tick) dong lenh mo phong khi Bid cham/vuot vach (BUY: Bid <= vach; SELL: Bid >= vach). Vach nam sai phia so voi gia vao
//  (gia da vuot muc S/R luc vao lenh) chi co hieu luc sau khi Bid tung quay lai phia an toan (g_slArm[]), de lenh khong bi dong ngay.
//  Gia chan lo luu file SPM_<symbol>_stop.csv (id lenh;gia) de giu nguyen khi doi khung / tat mo EA; lenh dong -> xoa vach + dong luu.
//  Lenh dang mo ma chua co gia chan lo (vd mo bang ban cu) -> chot gia tai lan ve dau tien.
//  Truc THOI GIAN = thoi gian cua nhan Pivot khung 1m (OBJPROP_TIME cua object nhan), ANCHOR_RIGHT: vach nam sat ben trai nhan Pivot, khong de len chu nhan.
//  Object SPM_SLOSS_B<id> / SPM_SLOSS_S<id> (don boi ObjectsDeleteAll(SPM_PFX) o SpmOnInit/SpmOnDeinit, va boi DeletePosObjects() khi dong lenh).
//==================================================================
int    g_slId[];   // id lenh gia lap
double g_slPx[];   // gia chan lo da chot cua lenh do
bool   g_slArm[];  // true = vach da "len dan": Bid da tung o phia AN TOAN cua vach (hoac vach nam dung phia so voi gia vao) -> tu luc do Bid cham/vuot vach moi dong lenh (CheckStopLosses())

//--- phia an toan: BUY = Bid tren vach, SELL = Bid duoi vach
bool SlBidSafe(const int type, const double sl, const double bid)
  {
   return (type == 0) ? (bid > sl) : (bid < sl);
  }

double SlEntryPx(const int id)
  {
   for(int i = 0; i < ArraySize(g_pos); i++)
      if(g_pos[i].id == id)
         return g_pos[i].price;
   return 0.0;
  }

//--- vach co hieu luc ngay neu da nam dung phia so voi gia vao (BUY: duoi gia vao; SELL: tren gia vao) hoac Bid dang o phia an toan.
//    Vach nam sai phia luc vao lenh (gia da vuot muc S/R) thi cho Bid quay lai phia an toan roi moi tinh, tranh dong lenh ngay tuc khac.
bool SlInitArmed(const int type, const double entry, const double sl)
  {
   bool rightSide = (type == 0) ? (sl < entry) : (sl > entry);
   return rightSide || SlBidSafe(type, sl, BidP());
  }

string SlFile() { return SPM_PFX + _Symbol + "_stop.csv"; }

string SlObjName(const int id, const int type) { return SPM_PFX + "SLOSS_" + (type == 0 ? "B" : "S") + (string)id; }

int SlFind(const int id)
  {
   for(int i = 0; i < ArraySize(g_slId); i++)
      if(g_slId[i] == id)
         return i;
   return -1;
  }

void SlSave()
  {
   int h = FileOpen(SlFile(), FILE_WRITE | FILE_CSV | FILE_ANSI, ';');
   if(h == INVALID_HANDLE)
      return;
   for(int i = 0; i < ArraySize(g_slId); i++)
      FileWrite(h, g_slId[i], DoubleToString(g_slPx[i], _Digits));
   FileClose(h);
  }

//--- nap lai sau LoadState(): chi giu dong cua lenh DANG MO
void SlLoad()
  {
   ArrayResize(g_slId, 0);
   ArrayResize(g_slPx, 0);
   ArrayResize(g_slArm, 0);
   if(!FileIsExist(SlFile()))
      return;

   int h = FileOpen(SlFile(), FILE_READ | FILE_CSV | FILE_ANSI, ';');
   if(h == INVALID_HANDLE)
      return;
   while(!FileIsEnding(h))
     {
      string s = FileReadString(h);
      if(StringLen(s) == 0)
         break;
      int    id = (int)StringToInteger(s);
      double px = StringToDouble(FileReadString(h));

      int pi = -1;
      for(int i = 0; i < ArraySize(g_pos); i++)
         if(g_pos[i].id == id)
           {
            pi = i;
            break;
           }
      if(pi < 0 || px <= 0.0 || SlFind(id) >= 0)
         continue;

      int k = ArraySize(g_slId);
      ArrayResize(g_slId, k + 1);
      ArrayResize(g_slPx, k + 1);
      ArrayResize(g_slArm, k + 1);
      g_slId[k]  = id;
      g_slPx[k]  = px;
      g_slArm[k] = SlInitArmed(g_pos[pi].type, g_pos[pi].price, px);
     }
   FileClose(h);
   SlSave();
  }

//--- xoa gia chan lo + vach cua 1 lenh (lenh da dong)
void SlDrop(const int id)
  {
   ObjectDelete(0, SlObjName(id, 0));
   ObjectDelete(0, SlObjName(id, 1));
   int idx = SlFind(id);
   if(idx < 0)
      return;
   int n = ArraySize(g_slId);
   for(int i = idx; i < n - 1; i++)
     {
      g_slId[i]  = g_slId[i + 1];
      g_slPx[i]  = g_slPx[i + 1];
      g_slArm[i] = g_slArm[i + 1];
     }
   ArrayResize(g_slId, n - 1);
   ArrayResize(g_slPx, n - 1);
   ArrayResize(g_slArm, n - 1);
   SlSave();
  }

int StopLossLvlIdx(const int side)   // side: 0 = BUY (muc S), 1 = SELL (muc R)
  {
   int sel = g_pivotLevelIdx;
   if(sel < 0 || sel >= RV2_LVL_COUNT)
      sel = 0;
   if(sel == 0)
      return 0;                                  // PP
   bool selIsR = (sel <= 9);                     // 1..9 = R1..R9, 10..18 = S1..S9
   if(side == 0)
      return selIsR ? sel + 9 : sel;             // BUY: Rn -> Sn
   return selIsR ? sel : sel - 9;                // SELL: Sn -> Rn
  }

//--- chot gia chan lo cua lenh id theo Pivot 1m HIEN TAI (chi ghi neu lenh chua co gia)
void SlRecord(const int id, const int type)
  {
   if(SlFind(id) >= 0)
      return;
   double ema[];
   if(AptPivotEmaSeriesLvl(PERIOD_M1, InpHistPoints, StopLossLvlIdx(type), ema) < 1 || ema[0] <= 0.0)
      return;                                    // thieu du lieu nen 1m -> khong doan gia, thu lai o lan ve sau
   int k = ArraySize(g_slId);
   ArrayResize(g_slId, k + 1);
   ArrayResize(g_slPx, k + 1);
   ArrayResize(g_slArm, k + 1);
   g_slId[k]  = id;
   g_slPx[k]  = ema[0];
   g_slArm[k] = SlInitArmed(type, SlEntryPx(id), ema[0]);
   SlSave();
  }

//--- truc thoi gian cua nhan Pivot khung 1m
datetime SlLabelTime()
  {
   datetime t = 0;
   string   pvLbl = WoodieLevelLblPrefix(g_pivotLvlUsedIdx[0]) + g_tfName[0];   // g_rvTfList[0] = M1
   if(ObjectFind(0, pvLbl) >= 0)
      t = (datetime)ObjectGetInteger(0, pvLbl, OBJPROP_TIME);
   if(t <= 0)
      t = g_pivotM1LblTime;   // nhan Pivot 1m bi an o bang check box khung: dung moc da luu
   if(t <= 0)
      t = S1LblTimeAtBarRight();
   if(t <= 0)
      t = iTime(_Symbol, _Period, 0);
   return t;
  }

void DrawStopLossMarks()
  {
   datetime t = SlLabelTime();
   if(t <= 0)
      return;

   int n = ArraySize(g_pos);
   for(int i = 0; i < n; i++)
     {
      int    id   = g_pos[i].id;
      int    type = g_pos[i].type;
      string nm   = SlObjName(id, type);

      int idx = SlFind(id);
      if(idx < 0)
        {
         SlRecord(id, type);
         idx = SlFind(id);
        }
      if(idx < 0)
        {
         ObjectDelete(0, nm);
         continue;
        }
      double px = g_slPx[idx];

      if(ObjectFind(0, nm) < 0)
        {
         ObjectCreate(0, nm, OBJ_TEXT, 0, t, px);
         ObjectSetInteger(0, nm, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, nm, OBJPROP_HIDDEN,     true);
         ObjectSetInteger(0, nm, OBJPROP_BACK,       false);
         ObjectSetInteger(0, nm, OBJPROP_FONTSIZE,   8);
         g_needRedraw = true;
        }
      SetInt(nm, OBJPROP_TIME,   (long)t);
      SetDbl(nm, OBJPROP_PRICE,  px);
      SetInt(nm, OBJPROP_ANCHOR, ANCHOR_RIGHT);
      SetInt(nm, OBJPROP_COLOR,  (long)clrWhite);
      SetStr(nm, OBJPROP_TEXT,   type == 0 ? "-----STB" : "-----STS");
      SetStr(nm, OBJPROP_TOOLTIP, StringFormat("Chan lo lenh #%d %s (gia lap): %s - chot luc vao lenh",
                                               id, SideName(type), PriceStr(px)));
     }
  }

//--- CHAN LO THAT SU: Bid cham/vuot vach -----STB (BUY: Bid <= vach) / -----STS (SELL: Bid >= vach) -> dong lenh mo phong do (gia dong = ClosePriceFor(), nhu cac lenh dong khac).
//    Goi tu UpdateAll() MOI TICK (sau khi lai/lo da cap nhat). Lenh chua co gia chan lo thi bo qua (DrawStopLossMarks() se chot).
void CheckStopLosses()
  {
   double bid = BidP();
   if(bid <= 0.0)
      return;

   bool closedAny = false;
   for(int i = ArraySize(g_pos) - 1; i >= 0; i--)
     {
      int idx = SlFind(g_pos[i].id);
      if(idx < 0)
         continue;

      int    type = g_pos[i].type;
      double sl   = g_slPx[idx];

      if(SlBidSafe(type, sl, bid))
        {
         g_slArm[idx] = true;                    // Bid o phia an toan -> tu gio vach co hieu luc
         continue;
        }
      if(!g_slArm[idx])
         continue;                               // vach sai phia luc vao lenh, Bid chua tung quay lai phia an toan

      int    id = g_pos[i].id;
      double pl = g_pos[i].pl;
      SpmDoAlert(StringFormat("CHAN LO lenh #%d %s: Bid %s cham vach %s -> dong lenh (mo phong), PL %.2f %s",
                              id, SideName(type), PriceStr(bid), PriceStr(sl), pl, AccCur()));
      RemoveAt(i);                               // luu lich su + xoa vach/gia chan lo (DeletePosObjects -> SlDrop)
      closedAny = true;
     }

   if(closedAny)
     {
      if(ArraySize(g_pos) == 0)
         ResetBasketStats();
      SaveState();
      g_needRedraw = true;
     }
  }

//==================================================================
// 7B. COT NHAN TIN HIEU RV1 (Rolling VWAP #1) DA KHUNG THOI GIAN
//
//  Voi tung khung tf <= khung chart hien tai (_Period), tinh RV1(tf) HIEN TAI (mau moi nhat) va so voi VACH DAT LENH
//  (gia vao cua LENH GOC, g_pos[0].price):
//   - LENH GOC la BUY  : RV1(tf) > gia vao LENH GOC  VA  (Bid - RV1(tf)) >= 2 lan spread  ->  hien chu HOA (A=1m,B=5m,... theo g_rv1TfList[]).
//   - LENH GOC la SELL : RV1(tf) < gia vao LENH GOC  VA  (RV1(tf) - Ask) >= 2 lan spread ->  hien "-" + chu (-A=1m,...).
//  Chua co lenh nao dang mo (g_pos rong) -> an het cot nhan. spread = Ask - Bid (gia thuc te, khong quy doi ra point).
//
//  CONG THUC RV1(tf): VWAP cua nB nen M1 GAN NHAT (nB = PeriodSeconds(tf)/60), gia dien hinh (H+L+C)/3, trong so tick volume -
//  cung cong thuc RV1(tf)[k=0] (neo tai TimeCurrent()) cua AptRv2BuildAll14(). Doc du lieu M1 MOT LAN cho ca 14 khung (prefix-sum).
//
//  Danh sach 14 khung + chu cai A..N: theo g_tfList[14] (1m,5m,15m,30m,1h,2h,3h,4h,6h,8h,12h,1d,1w,1nm); vi du chart o M30 thi chi 4 khung
//  dau (1m,5m,15m,30m = A,B,C,D) thoa dieu kien "<= khung chart hien tai".
//
//  Vi tri nhan: 1 COT DOC (moi khung thoa dieu kien 1 object OBJ_TEXT) neo tai (thoi gian nen hien tai, gia Ask) - hang dau nam DUNG tai gia Ask,
//  cac hang sau lui xuong RV1SIG_STEP_PTS diem/hang (ANCHOR_LEFT_LOWER). Khung khong thoa dieu kien -> xoa object hang do.
//==================================================================

//--- 14 khung dung cho cot nhan RV1 - THEO DUNG thu tu/gia tri g_tfList[]
//--- cua AutoPositionTool_UI.mq5, khong tu doi thu tu (chu cai A..N tinh
//--- theo chi so mang, xem Rv1SignalDraw()).
ENUM_TIMEFRAMES g_rv1TfList[14] =
  {
   PERIOD_M1, PERIOD_M5, PERIOD_M15, PERIOD_M30,
   PERIOD_H1, PERIOD_H2, PERIOD_H3, PERIOD_H4,
   PERIOD_H6, PERIOD_H8, PERIOD_H12,
   PERIOD_D1, PERIOD_W1, PERIOD_MN1
  };

//--- RV1(tf) HIEN TAI tu prefix-sum M1 da doc san (cumTPV[k]/cumVol[k] =
//--- tong tich luy cua k nen M1 GAN NHAT, s=0..k-1). Tra ve false neu
//--- khong du du lieu M1 cho khung tf (KHONG doan bua gia tri).
bool Rv1Now(const double &cumTPV[], const double &cumVol[], const int got,
            const ENUM_TIMEFRAMES tf, double &out)
  {
   int nB = (int)(PeriodSeconds(tf) / 60);
   if(nB < 1)
      nB = 1;
   if(nB > got)
      return false;

   double vol = cumVol[nB];
   if(vol <= 0.0)
      return false;

   out = cumTPV[nB] / vol;
   return true;
  }

void Rv1SignalDraw()
  {
   string prefix = SPM_PFX + "RV1SIG";

   int n = ArraySize(g_pos);
   if(n == 0)
     {
      for(int i = 0; i < 14; i++)
         ObjectDelete(0, prefix + (string)i);
      return;
     }

   int    baseType  = g_pos[0].type;    // 0 = BUY, 1 = SELL - huong lenh goc
   double basePrice = g_pos[0].price;   // VACH DAT LENH: gia vao cua LENH GOC
   double bid = BidP(), ask = AskP();
   double spread = ask - bid;

   //--- so nen M1 toi da can doc = nB lon nhat trong cac khung <= chart
   //--- hien tai (khung lon hon chart khong duoc tinh, bo qua tu day)
   int maxNb = 0;
   for(int i = 0; i < 14; i++)
     {
      if(PeriodSeconds(g_rv1TfList[i]) > PeriodSeconds(_Period))
         continue;
      int nb = (int)(PeriodSeconds(g_rv1TfList[i]) / 60);
      if(nb > maxNb)
         maxNb = nb;
     }
   if(maxNb < 1)
     {
      for(int i = 0; i < 14; i++)
         ObjectDelete(0, prefix + (string)i);
      return;
     }
   if(maxNb > 200000)
      maxNb = 200000;

   double   hi[], lo[], cl[];
   long     tv[];
   ArraySetAsSeries(hi, true);
   ArraySetAsSeries(lo, true);
   ArraySetAsSeries(cl, true);
   ArraySetAsSeries(tv, true);

   int cpH = CopyHigh      (_Symbol, PERIOD_M1, 0, maxNb, hi);
   int cpL = CopyLow       (_Symbol, PERIOD_M1, 0, maxNb, lo);
   int cpC = CopyClose     (_Symbol, PERIOD_M1, 0, maxNb, cl);
   int cpV = CopyTickVolume(_Symbol, PERIOD_M1, 0, maxNb, tv);
   int got = MathMin(MathMin(cpH, cpL), MathMin(cpC, cpV));
   if(got < 1)
     {
      for(int i = 0; i < 14; i++)
         ObjectDelete(0, prefix + (string)i);
      return;
     }

   //--- prefix-sum tu nen M1 moi nhat (s=0) tro ve: cumTPV[k]/cumVol[k] =
   //--- tong tich luy cua k nen M1 dau tien (gan nhat)
   double cumTPV[], cumVol[];
   ArrayResize(cumTPV, got + 1);
   ArrayResize(cumVol, got + 1);
   cumTPV[0] = 0.0;
   cumVol[0] = 0.0;
   for(int s = 0; s < got; s++)
     {
      double tp = (hi[s] + lo[s] + cl[s]) / 3.0;
      double v  = (double)tv[s];
      cumTPV[s + 1] = cumTPV[s] + tp * v;
      cumVol[s + 1] = cumVol[s] + v;
     }

   int row = 0;
   for(int i = 0; i < 14; i++)
     {
      string nm = prefix + (string)i;
      ENUM_TIMEFRAMES tf = g_rv1TfList[i];

      if(PeriodSeconds(tf) > PeriodSeconds(_Period))
        {
         ObjectDelete(0, nm);
         continue;
        }

      double rv1;
      if(!Rv1Now(cumTPV, cumVol, got, tf, rv1))
        {
         ObjectDelete(0, nm);
         continue;
        }

      bool   ok  = false;
      string lbl = "";
      if(baseType == 0)   // LENH GOC la BUY
        {
         if(rv1 > basePrice && (bid - rv1) >= 2.0 * spread)
           {
            ok  = true;
            lbl = CharToString((uchar)('A' + i));
           }
        }
      else                 // LENH GOC la SELL
        {
         if(rv1 < basePrice && (rv1 - ask) >= 2.0 * spread)
           {
            ok  = true;
            lbl = "-" + CharToString((uchar)('A' + i));
           }
        }

      if(!ok)
        {
         ObjectDelete(0, nm);
         continue;
        }

      datetime tAnchor = RightAnchor();
      double   pAnchor = ask - row * RV1SIG_STEP_PTS * _Point;

      if(ObjectFind(0, nm) < 0)
        {
         ObjectCreate(0, nm, OBJ_TEXT, 0, tAnchor, pAnchor);
         ObjectSetInteger(0, nm, OBJPROP_ANCHOR,     ANCHOR_LEFT_LOWER);
         ObjectSetString (0, nm, OBJPROP_FONT,       InpSpmFontName);
         ObjectSetInteger(0, nm, OBJPROP_FONTSIZE,   InpSpmFontSize);
         ObjectSetInteger(0, nm, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, nm, OBJPROP_HIDDEN,     true);
        }
      SetInt(nm, OBJPROP_TIME,  (long)tAnchor);
      SetDbl(nm, OBJPROP_PRICE, pAnchor);
      SetInt(nm, OBJPROP_COLOR, (long)(baseType == 0 ? InpColBuy : InpColSell));
      SetStr(nm, OBJPROP_TEXT,  lbl);

      row++;
     }
  }

//==================================================================
// 8. PANEL
//==================================================================
void CreateButton(string name, int x, int y, int w, int h, string txt, color bg, color fg)
  {
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER,      InpSpmCorner);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE,   x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE,   y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE,       w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE,       h);
   ObjectSetString (0, name, OBJPROP_TEXT,        txt);
   ObjectSetString (0, name, OBJPROP_FONT,        InpSpmFontName);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE,    InpSpmFontSize);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR,     bg);
   ObjectSetInteger(0, name, OBJPROP_COLOR,       fg);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR,clrDimGray);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE,  false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN,      true);
   ObjectSetInteger(0, name, OBJPROP_STATE,       false);
  }

void CreatePanel()
  {
   int by  = InpY;
   int gap = 4;
   int x   = InpX;
   bool right = (InpSpmCorner == CORNER_RIGHT_UPPER || InpSpmCorner == CORNER_RIGHT_LOWER);

   if(right)
     {
      //--- goc phai: MT5 dat CANH TRAI cua nut cach mep phai XDISTANCE,
      //--- nen phai cong them be rong nut de nut khong tran ra ngoai chart.
      CreateButton(BTN_CLOSEALL,  x + 110, by, 110, 20, "DONG TAT CA", C'55,25,25', clrTomato);
      x += 110 + gap;
      CreateButton(BTN_CLOSELAST, x + 110, by, 110, 20, "DONG CUOI",   C'45,30,30', clrLightSalmon);
      x += 110 + gap;
      CreateButton(BTN_SELL,      x + 78,  by, 78,  20, "SELL",        C'40,40,45', InpColSell);
      x += 78 + gap;
      CreateButton(BTN_BUY,       x + 78,  by, 78,  20, "BUY",         C'40,40,20', InpColBuy);
     }
   else
     {
      CreateButton(BTN_BUY,       x, by, 78,  20, "BUY",         C'40,40,20', InpColBuy);
      x += 78 + gap;
      CreateButton(BTN_SELL,      x, by, 78,  20, "SELL",        C'40,40,45', InpColSell);
      x += 78 + gap;
      CreateButton(BTN_CLOSELAST, x, by, 110, 20, "DONG CUOI",   C'45,30,30', clrLightSalmon);
      x += 110 + gap;
      CreateButton(BTN_CLOSEALL,  x, by, 110, 20, "DONG TAT CA", C'55,25,25', clrTomato);
     }
  }

// Do THOI GIAN THUC THI cua mot ham tu luc vao ham
//   den luc ra - bao gom moi nhanh return co san - bang ky thuat RAII: khai
//   bao MOT bien cuc bo kieu struct nay lam dong DAU TIEN trong than ham can
//   do (constructor ghi lai GetTickCount()); bien nay tu dong bi huy (goi
//   destructor) khi ham ket thuc theo BAT KY return nao (MQL5 huy bien cuc bo
//   dung luc ra khoi pham vi, giong C++), nen KHONG can them/sua bat ky dong
//   thoi gian troi qua >= SPM_SLOW_CALL_MS, in CANH BAO ra Experts log kem
//   ten ham va so mili-giay - day chinh la cach bat dung LENH GOI BI CHAN
//   (vi du dong bo lich su tu server) thay vi chi dem so luong object.
#define SPM_SLOW_CALL_MS       80
#define SPM_SLOW_CALL_COOLDOWN 10

string   g_spmSlowCallName[40];
datetime g_spmSlowCallLast[40];
int      g_spmSlowCallCount = 0;

// Gioi han tan suat CANH BAO CHAM rieng cho TUNG
//   ten ham (khong dung chung 1 cooldown cho ca 6 ham do o duoi), de ham nao
//   cham lien tuc van duoc bao lai sau moi SPM_SLOW_CALL_COOLDOWN giay, ma
//   khong bi ham khac (dang trong cooldown cua no) che mat.
bool SpmSlowCallCooldownOk(string tag)
  {
   datetime nw = TimeLocal();
   for(int i = 0; i < g_spmSlowCallCount; i++)
      if(g_spmSlowCallName[i] == tag)
        {
         if((int)(nw - g_spmSlowCallLast[i]) < SPM_SLOW_CALL_COOLDOWN)
            return false;
         g_spmSlowCallLast[i] = nw;
         return true;
        }
   if(g_spmSlowCallCount < 40)
     {
      g_spmSlowCallName[g_spmSlowCallCount] = tag;
      g_spmSlowCallLast[g_spmSlowCallCount] = nw;
      g_spmSlowCallCount++;
     }
   return true;
  }

struct SSpmScopeTimer
  {
   string tag;
   uint   t0;
   SSpmScopeTimer(string tg) { tag = tg; t0 = GetTickCount(); }
   ~SSpmScopeTimer()
     {
      uint dt = GetTickCount() - t0;
      if(dt >= SPM_SLOW_CALL_MS && SpmSlowCallCooldownOk(tag))
         Print(StringFormat(
            "[SPM] CANH BAO CHAM: ham %s vua chay mat %u ms (nguong %d ms) - " +
            "day rat co the la nguyen nhan lam treo/giat chart (lenh goi bi chan, " +
            "vi du dong bo lich su tu server, hoac qua nhieu viec trong 1 chu ky).",
            tag, dt, SPM_SLOW_CALL_MS));
     }
  };

// CANH BAO NGUYEN NHAN CO THE GAY TREO CHART /
//   CHAN VE NEN MOI KHI GAN CUNG INDICATOR KHAC TREN 1 CHART: dem TOAN BO
//   object dang co tren chart (ObjectsTotal(0) - dem CA object cua indicator
//   /EA KHAC, khong rieng cua file nay). MT5 phai duyet/dat lai vi tri toan
//   bo object nay moi lan chart can ve lai (doi khung nhin, tick moi, nen
//   moi...) tren CUNG mot luong giao dien; qua nhieu object (thuong do
//   NHIEU indicator cung ve duong/nhan tren 1 chart cong lai) lam tang chi
//   phi moi lan ve, bieu hien thanh chart giat/treo hoac nen moi ve tre.
//   CHI Print canh bao (co gioi han tan suat qua SPM_OBJCOUNT_COOLDOWN de
//   khong spam Experts log moi giay) - KHONG xoa/dong cham object nao,
//   KHONG anh huong logic mo phong lenh.
void WarnIfManyChartObjects()
  {
   int total = ObjectsTotal(0);
   if(total < SPM_OBJCOUNT_WARN)
      return;

   datetime nw = TimeLocal();
   if(g_lastObjWarn != 0 && (int)(nw - g_lastObjWarn) < SPM_OBJCOUNT_COOLDOWN)
      return;
   g_lastObjWarn = nw;

   Print(StringFormat(
      "[SPM] CANH BAO: chart dang co %d object ve (dem ca object cua indicator/EA khac, nguong %d) - " +
      "so luong lon co the lam CHAM REDRAW / CHAM VE NEN khi nhieu indicator cung ve len 1 chart. " +
      "Neu thay chart giat/treo, thu tat bot indicator khac tren CUNG chart nay de doi chieu.",
      total, SPM_OBJCOUNT_WARN));
  }

//==================================================================
// 9. CAP NHAT CHINH
//==================================================================
void UpdateAll(bool draw)
  {
   datetime now = TimeLocal();
   int dt = (int)(now - g_lastCalc);
   if(dt < 0)
      dt = 0;
   g_lastCalc = now;

   int n = ArraySize(g_pos);
   for(int i = 0; i < n; i++)
     {
      double cur = ClosePriceFor(g_pos[i].type);
      double dir = (g_pos[i].type == 0) ? 1.0 : -1.0;

      g_pos[i].pts = (cur - g_pos[i].price) * dir / _Point;
      g_pos[i].pl  = PosProfit(g_pos[i]);

      if(g_pos[i].pts > g_pos[i].mfePts)
         g_pos[i].mfePts = g_pos[i].pts;
      if(g_pos[i].pts < g_pos[i].maePts)
         g_pos[i].maePts = g_pos[i].pts;

      if(dt > 0)
        {
         if(g_pos[i].pl > 0.0)      g_pos[i].secProfit += dt;
         else if(g_pos[i].pl < 0.0) g_pos[i].secLoss   += dt;
         else                       g_pos[i].secFlat   += dt;
        }
     }

   if(dt > 0 && n > 0)
     {
      double tot = BasketPL();
      if(tot > 0.0)      g_bSecProfit += dt;
      else if(tot < 0.0) g_bSecLoss   += dt;
      else               g_bSecFlat   += dt;
     }

   CheckStopLosses();   // Bid cham vach -----STB / -----STS -> dong lenh mo phong (moi tick)

   //--- BO SUNG: dem lai/lo + thoi gian cong don cua NGUONG NHOI ke tiep
   //    Coi nguong nhoi nhu mot lenh AO cung khoi luong, cung huong lenh
   //    goc, vao lenh dung tai muc gia goi y. Nho do biet duoc muc nhoi
   //    do "song" bao lau trong lai va bao lau trong lo - giong cach dang
   //    do cho hang lenh goc. KHONG mo lenh, KHONG ve them duong moi.
   // chay RIENG cho tung chieu co duong nhoi.
   for(int s = 0; s < 2; s++)
     {
      int arg = -1;
      if(!AddSideActive(s, arg))
        {
         //--- khong con muc nhoi nao de theo doi -> xoa bo dem
         if(g_addKey[s] != -1)
           {
            ResetAddStats(s);
            g_addKey[s] = -1;
           }
         continue;
        }

      int    aType  = s;
      double aPrice = NextAddPrice(arg);

      //--- moc nguong doi khi lenh goc chieu nay doi hoac so lan nhoi doi
      //--- -> bo dem bat dau lai tu 0 cho dung muc nhoi moi
      int bi   = BaseIdx(arg);
      int aKey = g_pos[bi].id * 1000 + AddsDone(arg) * 10 + aType;
      if(aKey != g_addKey[s])
        {
         ResetAddStats(s);
         g_addKey[s] = aKey;
        }

      double aCur = ClosePriceFor(aType);
      double aDir = (aType == 0) ? 1.0 : -1.0;
      g_addPts[s] = (aCur - aPrice) * aDir / _Point;

      SimPos vp;
      vp.id         = 0;
      vp.type       = aType;
      vp.price      = aPrice;
      vp.lots       = InpLots;
      vp.tOpen      = 0;
      vp.mfePts     = 0.0;
      vp.maePts     = 0.0;
      vp.secProfit  = 0;
      vp.secLoss    = 0;
      vp.secFlat    = 0;
      vp.pts        = 0.0;
      vp.pl         = 0.0;
      vp.tag        = "AO";
      g_addPl[s] = PosProfit(vp);

      if(dt > 0)
        {
         if(g_addPl[s] > 0.0)      g_addSecProfit[s] += dt;
         else if(g_addPl[s] < 0.0) g_addSecLoss[s]   += dt;
         else                      g_addSecFlat[s]   += dt;
        }
     }

   //--- moi tick chi tinh so; viec ve object don ve nhip 1 giay cua SpmOnTimer
   if(!draw)
      return;

   g_needRedraw = false;
   CreatePanel();
   DrawLines();
   DrawStopLossMarks();   // vach chan lo -----STB / -----STS (gia chot luc vao lenh)
   Rv1SignalDraw();
   SpmStatsDraw();
   WarnIfManyChartObjects();

   //--- Khong ep ChartRedraw() dinh ky: gia tri object duoc cap nhat moi giay qua ObjectSet*, MT5 tu ve lai theo tick; ChartRedraw() chi goi ngay sau khi
   //--- nguoi dung bam nut (xem SpmOnChartEvent) de tranh chiem thread giao dien khi chay cung cac indicator khac.
  }

//==================================================================
// 10. LUU / NAP TRANG THAI (giu nguyen khi doi khung thoi gian)
//==================================================================
string StateFile()
  {
   return SPM_PFX + _Symbol + ".csv";
  }

void SaveState()
  {
   int h = FileOpen(StateFile(), FILE_WRITE | FILE_CSV | FILE_ANSI, ';');
   if(h == INVALID_HANDLE)
      return;

   FileWrite(h, g_nextId, DoubleToString(g_realized, 2), g_closedCount, g_bSecProfit, g_bSecLoss, g_bSecFlat);
   for(int i = 0; i < ArraySize(g_pos); i++)
      FileWrite(h,
                g_pos[i].id,
                g_pos[i].type,
                DoubleToString(g_pos[i].price, _Digits),
                DoubleToString(g_pos[i].lots, 2),
                (long)g_pos[i].tOpen,
                DoubleToString(g_pos[i].mfePts, 1),
                DoubleToString(g_pos[i].maePts, 1),
                g_pos[i].secProfit,
                g_pos[i].secLoss,
                g_pos[i].secFlat,
                g_pos[i].tag);
   FileClose(h);
  }

void LoadState()
  {
   if(!FileIsExist(StateFile()))
      return;

   int h = FileOpen(StateFile(), FILE_READ | FILE_CSV | FILE_ANSI, ';');
   if(h == INVALID_HANDLE)
      return;

   g_nextId      = (int)StringToInteger(FileReadString(h));
   g_realized    = StringToDouble(FileReadString(h));
   g_closedCount = (int)StringToInteger(FileReadString(h));
   g_bSecProfit  = (int)StringToInteger(FileReadString(h));
   g_bSecLoss    = (int)StringToInteger(FileReadString(h));
   g_bSecFlat    = (int)StringToInteger(FileReadString(h));

   ArrayResize(g_pos, 0);
   while(!FileIsEnding(h))
     {
      string s = FileReadString(h);
      if(StringLen(s) == 0)
         break;

      int k = ArraySize(g_pos);
      ArrayResize(g_pos, k + 1);
      g_pos[k].id         = (int)StringToInteger(s);
      g_pos[k].type       = (int)StringToInteger(FileReadString(h));
      g_pos[k].price      = StringToDouble(FileReadString(h));
      g_pos[k].lots       = StringToDouble(FileReadString(h));
      g_pos[k].tOpen      = (datetime)StringToInteger(FileReadString(h));
      g_pos[k].mfePts     = StringToDouble(FileReadString(h));
      g_pos[k].maePts     = StringToDouble(FileReadString(h));
      g_pos[k].secProfit  = (int)StringToInteger(FileReadString(h));
      g_pos[k].secLoss    = (int)StringToInteger(FileReadString(h));
      g_pos[k].secFlat    = (int)StringToInteger(FileReadString(h));
      g_pos[k].tag        = FileReadString(h);
      g_pos[k].pts        = 0.0;
      g_pos[k].pl         = 0.0;
     }
   FileClose(h);

   if(ArraySize(g_pos) > 0)
      Print(StringFormat("[SPM] Da nap lai %d lenh mo phong tu %s", ArraySize(g_pos), StateFile()));
  }

//==================================================================
// 10B. LICH SU LENH DONG + BANG THONG KE
//   - HistAdd(): moi lenh mo phong KHI DONG duoc ghi them 1 dong vao file SPM_<symbol>_hist.csv
//     (nap lai khi khoi dong, nen thong ke con nguyen sau khi doi khung / tat mo EA).
//   - SpmStatsDraw(): ve bang thong ke nho (nhieu hang ngan) NGAY DUOI hang nut Close Simple UI (5/10/20/50/200).
//     Thong ke tinh tren lenh DA DONG (tu file lich su) + lenh DANG MO (lai/lo hien tai).
//     Gio/phien tinh theo GIO VIET NAM (GMT+7): A = 05h-14h, Au = 14h-20h, My = 20h-05h.
//   Chi tao OBJ_LABEL + 1 OBJ_RECTANGLE_LABEL nen (prefix SPM_ST_): KHONG ve line, KHONG doi input/setting nao.
//==================================================================
string HistFile() { return SPM_PFX + _Symbol + "_hist.csv"; }
string HpxFile()  { return SPM_PFX + _Symbol + "_hpx.csv"; }   // file phu: tOpenGmt;type;gia vao;lai/lo

void HistAdd(const SimPos &p)
  {
   long off  = (long)(TimeCurrent() - TimeGMT());
   int  k    = ArraySize(g_hist);
   ArrayResize(g_hist, k + 1);
   g_hist[k].type      = p.type;
   g_hist[k].lots      = p.lots;
   g_hist[k].pl        = p.pl;
   g_hist[k].secProfit = p.secProfit;
   g_hist[k].secLoss   = p.secLoss;
   long hold = (long)(TimeCurrent() - p.tOpen);
   if(hold < 0) hold = 0;
   g_hist[k].holdSec   = (int)hold;
   g_hist[k].tOpenGmt  = (datetime)((long)p.tOpen - off);
   g_hist[k].tag       = p.tag;

   // Gia vao lenh (file phu _hpx.csv) de bang thong ke liet ke <gia vao><TenMuc 1m> tung lenh thang / thua.
   int kx = ArraySize(g_hpx);
   ArrayResize(g_hpx, kx + 1);
   g_hpx[kx].type  = p.type;
   g_hpx[kx].pl    = p.pl;
   g_hpx[kx].price = p.price;
   g_hpx[kx].tGmt  = g_hist[k].tOpenGmt;
   int hx = FileOpen(HpxFile(), FILE_READ | FILE_WRITE | FILE_CSV | FILE_ANSI, ';');
   if(hx != INVALID_HANDLE)
     {
      FileSeek(hx, 0, SEEK_END);
      FileWrite(hx, (long)g_hpx[kx].tGmt, p.type, DoubleToString(p.price, _Digits), DoubleToString(p.pl, 2));
      FileClose(hx);
     }

   int h = FileOpen(HistFile(), FILE_READ | FILE_WRITE | FILE_CSV | FILE_ANSI, ';');
   if(h == INVALID_HANDLE)
      return;
   FileSeek(h, 0, SEEK_END);
   FileWrite(h, p.id, p.type, DoubleToString(p.lots, 2), DoubleToString(p.pl, 2),
             p.secProfit, p.secLoss, g_hist[k].holdSec, (long)g_hist[k].tOpenGmt, p.tag);
   FileClose(h);
  }

void HistLoad()
  {
   ArrayResize(g_hist, 0);
   if(!FileIsExist(HistFile()))
      return;
   int h = FileOpen(HistFile(), FILE_READ | FILE_CSV | FILE_ANSI, ';');
   if(h == INVALID_HANDLE)
      return;
   while(!FileIsEnding(h))
     {
      string s = FileReadString(h);   // id
      if(StringLen(s) == 0)
         break;
      int k = ArraySize(g_hist);
      ArrayResize(g_hist, k + 1);
      g_hist[k].type      = (int)StringToInteger(FileReadString(h));
      g_hist[k].lots      = StringToDouble(FileReadString(h));
      g_hist[k].pl        = StringToDouble(FileReadString(h));
      g_hist[k].secProfit = (int)StringToInteger(FileReadString(h));
      g_hist[k].secLoss   = (int)StringToInteger(FileReadString(h));
      g_hist[k].holdSec   = (int)StringToInteger(FileReadString(h));
      g_hist[k].tOpenGmt  = (datetime)StringToInteger(FileReadString(h));
      g_hist[k].tag       = FileReadString(h);
     }
   FileClose(h);
  }

void HpxLoad()
  {
   ArrayResize(g_hpx, 0);
   if(!FileIsExist(HpxFile()))
      return;
   int h = FileOpen(HpxFile(), FILE_READ | FILE_CSV | FILE_ANSI, ';');
   if(h == INVALID_HANDLE)
      return;
   while(!FileIsEnding(h))
     {
      string s = FileReadString(h);   // tOpenGmt
      if(StringLen(s) == 0)
         break;
      int k = ArraySize(g_hpx);
      ArrayResize(g_hpx, k + 1);
      g_hpx[k].tGmt  = (datetime)StringToInteger(s);
      g_hpx[k].type  = (int)StringToInteger(FileReadString(h));
      g_hpx[k].price = StringToDouble(FileReadString(h));
      g_hpx[k].pl    = StringToDouble(FileReadString(h));
     }
   FileClose(h);
  }

int StSessOf(const int hr)
  {
   if(hr >= 14 && hr < 20) return 1;   // Au
   if(hr >= 20 || hr < 5)  return 2;   // My
   return 0;                           // A (05-14h)
  }

void StAdd(const int type, const double lots, const double pl, const long sp, const long sl,
           const long hold, const datetime tGmt)
  {
   if(type == 0) { g_st.nB++; g_st.lotB += lots; }
   else          { g_st.nS++; g_st.lotS += lots; }
   g_st.secP += sp;
   g_st.secL += sl;
   MqlDateTime dt;
   TimeToStruct(tGmt + 7 * 3600, dt);   // tGmt (luu trong file) + 7h = gio Viet Nam
   int hr = dt.hour;
   int ss = StSessOf(hr);
   g_st.sessN[ss]++;
   if(pl > 0.0)
     {
      g_st.prof += pl; g_st.nWin++; g_st.lotWin += lots; g_st.holdWin += hold;
      g_st.sessP[ss] += pl; g_st.hourP[hr] += pl;
     }
   else if(pl < 0.0)
     {
      g_st.loss += pl; g_st.nLose++; g_st.lotLose += lots; g_st.holdLose += hold;
      g_st.sessL[ss] += pl; g_st.hourL[hr] += pl;
     }
  }

string StSign(const double v, const int dg = 2)
  {
   return ((v >= 0.0) ? "+" : "") + DoubleToString(v, dg);
  }

string StDur(const double sec)
  {
   if(sec < 60.0)   return IntegerToString((int)MathRound(sec)) + "s";
   if(sec < 3600.0) return IntegerToString((int)MathRound(sec / 60.0)) + "m";
   return DoubleToString(sec / 3600.0, 1) + "h";
  }

#define SPM_ST_ROWS 16            // so hang thong ke co dinh
#define SPM_ST_MAXROWS 40         // so hang toi da cua bang (16 hang co dinh + phan chi tiet lenh thang / thua)
#define SPM_DET_MAXITEMS 12       // so lenh GAN NHAT toi da liet ke moi nhom (Mua thang / Mua thua / Ban thang / Ban thua)
#define SPM_DET_PERROW   4        // so lenh moi hang
string g_stTxt[SPM_ST_MAXROWS];
color  g_stClr[SPM_ST_MAXROWS];
int    g_stRowsUsed = SPM_ST_ROWS;   // so hang bang GIA LAP dang dung (StBuild ghi)
int    g_rtRowsUsed = SPM_ST_ROWS;   // so hang bang LENH THAT dang dung (RtBuild ghi)

//--- <TenMuc> cua khung 1m TAI THOI DIEM tSrv (gio server) voi gia price: muc Woodie (PP/R1..R9/S1..S9) gan price nhat.
//    Cung cong thuc AptWoodieDisplayLvlForTF(): muc tho tu H/L/C nen 1m lien truoc, EMA(APT_S1_EMA_PERIOD) seed tu nen cu nhat; chi doc EMA tai nen 1m chua tSrv.
//    Ket qua cache theo (tSrv, price). Thieu du lieu nen 1m -> "-" (khong cache de lan sau thu lai).
datetime g_lvnT[256];
double   g_lvnP[256];
string   g_lvnS[256];
int      g_lvnN = 0;
int      g_lvnW = 0;

string AptLvlNameM1At(const datetime tSrv, const double price)
  {
   for(int i = 0; i < g_lvnN; i++)
      if(g_lvnT[i] == tSrv && g_lvnP[i] == price)
         return(g_lvnS[i]);

   if(tSrv <= 0 || price <= 0.0)
      return("-");
   int k = iBarShift(_Symbol, PERIOD_M1, tSrv, false);
   if(k < 0)
      return("-");

   int need = APT_S1_HIST_POINTS + 2;   // bar j (shift k+j) can bar lien truoc j+1
   double hi[], lo[], cl[];
   ArraySetAsSeries(hi, true);
   ArraySetAsSeries(lo, true);
   ArraySetAsSeries(cl, true);
   int cpH = CopyHigh (_Symbol, PERIOD_M1, k, need, hi);
   int cpL = CopyLow  (_Symbol, PERIOD_M1, k, need, lo);
   int cpC = CopyClose(_Symbol, PERIOD_M1, k, need, cl);
   int got = MathMin(MathMin(cpH, cpL), cpC);
   if(got < 2)
      return("-");
   int points = got - 1;
   if(points > APT_S1_HIST_POINTS + 1)
      points = APT_S1_HIST_POINTS + 1;

   int    pEma = MathMax(1, APT_S1_EMA_PERIOD);
   double aEma = 2.0 / (pEma + 1.0);
   int    best = -1;
   double bestD = 0.0;
   for(int lvl = 0; lvl < APT_S1_LVL_COUNT; lvl++)
     {
      double e      = 0.0;
      bool   seeded = false;
      for(int j = points - 1; j >= 0; j--)
        {
         double v = AptWoodieLevelValue(lvl, hi[j + 1], lo[j + 1], cl[j + 1]);
         if(!seeded)
           {
            e = v;
            seeded = true;
           }
         else
           {
            e = aEma * v + (1.0 - aEma) * e;
           }
        }
      double dAbs = MathAbs(price - e);   // e = EMA muc lvl tai nen 1m chua tSrv (j = 0)
      if(best < 0 || dAbs < bestD)
        {
         best = lvl;
         bestD = dAbs;
        }
     }
   if(best < 0)
      return("-");

   string nm = g_aptLvlName[best];
   int w = 0;
   if(g_lvnN < 256)
      w = g_lvnN++;
   else
     {
      w = g_lvnW;
      g_lvnW = (g_lvnW + 1) % 256;
     }
   g_lvnT[w] = tSrv;
   g_lvnP[w] = price;
   g_lvnS[w] = nm;
   return(nm);
  }

void StDetPush(SStDet &det[], const int type, const double pl, const double price, const datetime tGmt)
  {
   int k = ArraySize(det);
   ArrayResize(det, k + 1);
   det[k].type  = type;
   det[k].pl    = pl;
   det[k].price = price;
   det[k].tGmt  = tGmt;
  }

//--- Them phan chi tiet "<gia vao><TenMuc 1m>" cua tung lenh thang / thua vao r[] / c[] tu hang base; tra ve so hang bang dang dung.
//    Hang tu base tro di luon duoc xoa truoc (bang LENH THAT ve lai moi 5 giay). Xem BANG FORMAT muc 6.
int StDetRows(SStDet &det[], string &r[], color &c[], const int base)
  {
   color cTxt = C'200,200,200', cUp = C'80,220,120', cDn = C'255,110,110';
   for(int z = base; z < SPM_ST_MAXROWS; z++)
     {
      r[z] = "";
      c[z] = cTxt;
     }
   int n = ArraySize(det);
   if(n <= 0 || base >= SPM_ST_MAXROWS)
      return(base);

   long off = (long)(TimeCurrent() - TimeGMT());
   int  row = base;
   r[row] = "Gia vao + TenMuc 1m:";
   c[row] = clrWhite;
   row++;

   for(int grp = 0; grp < 4; grp++)
     {
      int  ty  = (grp < 2) ? 0 : 1;      // 0 = mua, 1 = ban
      bool win = (grp % 2 == 0);          // grp 0,2 = thang; 1,3 = thua
      int  cnt = 0;
      for(int i = 0; i < n; i++)
        {
         if(det[i].type != ty)
            continue;
         if(win ? (det[i].pl > 0.0) : (det[i].pl < 0.0))
            cnt++;
        }
      if(cnt == 0)
         continue;
      if(row >= SPM_ST_MAXROWS)
         break;

      color cc = win ? cUp : cDn;
      r[row] = ((ty == 0) ? "Mua " : "Ban ") + (win ? "thang" : "thua") + " (" + IntegerToString(cnt) + "):";
      c[row] = cc;
      row++;

      int    skip   = (cnt > SPM_DET_MAXITEMS) ? cnt - SPM_DET_MAXITEMS : 0;   // chi giu cac lenh GAN NHAT
      int    seen   = 0;
      int    inLine = 0;
      string line   = "";
      for(int i = 0; i < n; i++)
        {
         if(det[i].type != ty)
            continue;
         if(!(win ? (det[i].pl > 0.0) : (det[i].pl < 0.0)))
            continue;
         if(seen < skip)
           {
            seen++;
            continue;
           }
         seen++;

         string px = (det[i].price >= 100.0) ? DoubleToString(det[i].price, 0) : DoubleToString(det[i].price, _Digits);
         string it = px + AptLvlNameM1At((datetime)((long)det[i].tGmt + off), det[i].price);
         line = line + ((inLine > 0) ? " " : "") + it;
         inLine++;
         if(inLine >= SPM_DET_PERROW)
           {
            if(row < SPM_ST_MAXROWS)
              {
               r[row] = line;
               c[row] = cc;
               row++;
              }
            line = "";
            inLine = 0;
           }
        }
      if(inLine > 0 && row < SPM_ST_MAXROWS)
        {
         r[row] = line;
         c[row] = cc;
         row++;
        }
     }
   return(row);
  }

void StFormat(string &r[], color &c[], const bool real, const int nClosed);

void StBuild(string &r[], color &c[])
  {
   ZeroMemory(g_st);
   int nHist = ArraySize(g_hist);
   int nClosed = 0;
   long off = (long)(TimeCurrent() - TimeGMT());
   datetime _stNow = TimeCurrent();
   datetime _stD0  = _stNow - (_stNow % 86400);
   for(int i = 0; i < nHist; i++)
     {
      if((long)g_hist[i].tOpenGmt + off < (long)_stD0)
         continue;
      nClosed++;
      StAdd(g_hist[i].type, g_hist[i].lots, g_hist[i].pl, g_hist[i].secProfit, g_hist[i].secLoss,
            g_hist[i].holdSec, g_hist[i].tOpenGmt);
     }
   int nOpen = ArraySize(g_pos);
   for(int i = 0; i < nOpen; i++)
     {
      long hd = (long)(TimeCurrent() - g_pos[i].tOpen);
      if(hd < 0) hd = 0;
      StAdd(g_pos[i].type, g_pos[i].lots, g_pos[i].pl, g_pos[i].secProfit, g_pos[i].secLoss,
            hd, (datetime)((long)g_pos[i].tOpen - off));
     }

   // Chi tiet gia vao tung lenh hom nay (da dong tu file phu _hpx + dang mo) de liet ke <gia vao><TenMuc 1m>.
   SStDet det[];
   for(int i = 0; i < ArraySize(g_hpx); i++)
     {
      if((long)g_hpx[i].tGmt + off < (long)_stD0)
         continue;
      StDetPush(det, g_hpx[i].type, g_hpx[i].pl, g_hpx[i].price, g_hpx[i].tGmt);
     }
   for(int i = 0; i < nOpen; i++)
      StDetPush(det, g_pos[i].type, g_pos[i].pl, g_pos[i].price, (datetime)((long)g_pos[i].tOpen - off));

   StFormat(r, c, false, nClosed);
   g_stRowsUsed = StDetRows(det, r, c, SPM_ST_ROWS);
  }

// Dinh dang chung cho CA HAI bang (gia lap / that) tu bo cong don g_st.
//   real = true: bang LENH THAT trong ngay (khong theo doi tung giay lai/lo -> "1s" tinh theo thoi gian GIU lenh,
//   "ty le thang" thay cho "% thoi gian nam lai").
void StFormat(string &r[], color &c[], const bool real, const int nClosed)
  {
   color cTxt = C'200,200,200', cUp = C'80,220,120', cDn = C'255,110,110', cMid = C'240,200,90';
   for(int i = 0; i < SPM_ST_ROWS; i++) { r[i] = ""; c[i] = cTxt; }

   int nAll = g_st.nB + g_st.nS;
   if(real)
      r[0] = "TK THAT HOM NAY: " + IntegerToString(nAll) + " lenh";
   else
      r[0] = "TK GIA LAP HOM NAY: " + IntegerToString(nAll) + " lenh (" + IntegerToString(nClosed) + " dong)";
   c[0] = clrWhite;
   if(nAll == 0)
     {
      r[1] = "Chua co lenh nao";
      return;
     }

   r[1] = "Mua " + IntegerToString(g_st.nB) + " | Ban " + IntegerToString(g_st.nS);
   r[2] = "Lot TB: mua " + ((g_st.nB > 0) ? DoubleToString(g_st.lotB / g_st.nB, 2) : "-") +
          " ban " + ((g_st.nS > 0) ? DoubleToString(g_st.lotS / g_st.nS, 2) : "-");
   r[3] = "Lai " + StSign(g_st.prof) + " | Lo " + StSign(g_st.loss);

   double rateP = (g_st.secP > 0) ? g_st.prof / (double)g_st.secP : 0.0;
   double rateL = (g_st.secL > 0) ? g_st.loss / (double)g_st.secL : 0.0;   // am
   r[4] = "1s: lai " + StSign(rateP, 3) + " lo " + StSign(rateL, 3);

   double net = g_st.prof + g_st.loss;
   string pfS = (g_st.loss < 0.0) ? DoubleToString(g_st.prof / (-g_st.loss), 2) : "khong lo";
   if(net > 0.0)      { r[5] = "TT THUAN LOI (lai/lo " + pfS + ")"; c[5] = cUp; }
   else if(net < 0.0) { r[5] = "TT BAT LOI (lai/lo " + pfS + ")";   c[5] = cDn; }
   else               { r[5] = "TT TRUNG TINH";                      c[5] = cMid; }

   double avgHW = (g_st.nWin  > 0) ? (double)g_st.holdWin  / g_st.nWin  : 0.0;
   double avgHL = (g_st.nLose > 0) ? (double)g_st.holdLose / g_st.nLose : 0.0;
   r[6] = "Giu TB: lai " + ((g_st.nWin > 0) ? StDur(avgHW) : "-") + " | lo " + ((g_st.nLose > 0) ? StDur(avgHL) : "-");
   if(g_st.nWin > 0 && g_st.nLose > 0)
     {
      if(avgHL > avgHW * 1.3)      { r[7] = "=> GONG LO, cat lo cham";       c[7] = cDn; }
      else if(avgHW > avgHL * 1.3) { r[7] = "=> CAT LO SOM, de lai chay";    c[7] = cUp; }
      else                         { r[7] = "=> giu lai/lo can bang";        c[7] = cMid; }
     }
   else
      r[7] = "=> chua du lenh lai+lo";

   double pctP = (g_st.secP + g_st.secL > 0) ? 100.0 * (double)g_st.secP / (double)(g_st.secP + g_st.secL) : 0.0;
   if(real)
      pctP = (g_st.nWin + g_st.nLose > 0) ? 100.0 * (double)g_st.nWin / (double)(g_st.nWin + g_st.nLose) : 0.0;
   double aLW  = (g_st.nWin  > 0) ? g_st.lotWin  / g_st.nWin  : 0.0;
   double aLL  = (g_st.nLose > 0) ? g_st.lotLose / g_st.nLose : 0.0;
   if(real)
      r[8] = "Ty le thang " + DoubleToString(pctP, 0) + "% (" + IntegerToString(g_st.nWin) + "/" + IntegerToString(g_st.nWin + g_st.nLose) + ")";
   else
      r[8] = "Nam lai " + DoubleToString(pctP, 0) + "% thoi gian";
   r[9] = "Lot TB: lai " + ((g_st.nWin > 0) ? DoubleToString(aLW, 2) : "-") + " | lo " + ((g_st.nLose > 0) ? DoubleToString(aLL, 2) : "-");

   bool lotBias = (g_st.nWin > 0 && g_st.nLose > 0 && aLL > aLW * 1.25);
   bool vaoSai  = (g_st.secP + g_st.secL > 0 && pctP < 50.0) ||
                  (g_st.secP > 0 && g_st.secL > 0 && MathAbs(rateL) > rateP * 1.3);
   if(net < 0.0)
     {
      c[10] = cDn;
      if(vaoSai && lotBias) r[10] = "LO: VAO SAI + LOT lon";
      else if(vaoSai)       r[10] = "LO: do VAO SAI (toc do lo)";
      else if(lotBias)      r[10] = "LO: do LOT lon luc thua";
      else                  r[10] = "LO: nhe, chua ro nguyen nhan";
     }
   else
     {
      c[10] = cUp;
      if(g_st.nWin > 0 && g_st.nLose > 0 && aLW > aLL * 1.25) r[10] = "LAI: nho LOT lon khi thang";
      else if(!vaoSai)                                         r[10] = "LAI: nho VAO DUNG";
      else                                                     { r[10] = "LAI: mong, toc do lo cao"; c[10] = cMid; }
     }

   string sn[3] = {"A  05-14", "Au 14-20", "My 20-05"};
   for(int s = 0; s < 3; s++)
      r[11 + s] = sn[s] + ": " + StSign(g_st.sessP[s], 1) + "/" + StSign(g_st.sessL[s], 1) + " (" + IntegerToString(g_st.sessN[s]) + ")";

   int bs = -1, ws = -1, bh = -1, wh = -1;
   double bsv = 0.0, wsv = 0.0, bhv = 0.0, whv = 0.0;
   for(int s = 0; s < 3; s++)
     {
      if(g_st.sessP[s] > bsv) { bsv = g_st.sessP[s]; bs = s; }
      if(g_st.sessL[s] < wsv) { wsv = g_st.sessL[s]; ws = s; }
     }
   for(int hr = 0; hr < 24; hr++)
     {
      if(g_st.hourP[hr] > bhv) { bhv = g_st.hourP[hr]; bh = hr; }
      if(g_st.hourL[hr] < whv) { whv = g_st.hourL[hr]; wh = hr; }
     }
   string snm[3] = {"A", "Au", "My"};
   r[14] = "Lai nhieu: " + ((bs >= 0) ? snm[bs] + " " + IntegerToString(bh) + "h" : "-") + " (VN)";
   r[15] = "Lo nhieu: "  + ((ws >= 0) ? snm[ws] + " " + IntegerToString(wh) + "h" : "-") + " (VN)";
   c[14] = cUp;
   c[15] = cDn;
  }

// Bang thong ke LENH THAT cua tai khoan trong NGAY (tat ca ma, tinh theo ngay server).
//   Moi VI THE (position) da dong hom nay tinh 1 lenh: chieu/lot/mo-luc lay tu deal vao, lai/lo = tong profit+swap+commission+fee
//   cua cac deal cua vi the do, dong luc = deal ra cuoi cung. Chi DOC lich su tai khoan (HistorySelect...), KHONG gui/sua/dong lenh.
//   Lich su duoc doc lai toi da moi 5 giay; ket qua luu g_rtRows/g_rtCols.
string   g_rtRows[SPM_ST_MAXROWS];
color    g_rtCols[SPM_ST_MAXROWS];
string   g_rtTxt [SPM_ST_MAXROWS];
color    g_rtClr [SPM_ST_MAXROWS];
datetime g_rtLast = 0;

void RtBuild()
  {
   ZeroMemory(g_st);
   datetime now = TimeCurrent();
   datetime d0  = now - (now % 86400);   // 00:00 ngay server
   long off = (long)(now - TimeGMT());
   int nClosed = 0;
   SStDet det[];   // chi tiet gia vao tung lenh that hom nay (xem StDetRows())

   if(HistorySelect(d0, now + 60))
     {
      int nd = HistoryDealsTotal();
      ulong posIds[];
      int   np = 0;
      for(int i = 0; i < nd; i++)
        {
         ulong tk = HistoryDealGetTicket(i);
         if(tk == 0) continue;
         long en = HistoryDealGetInteger(tk, DEAL_ENTRY);
         if(en != DEAL_ENTRY_OUT && en != DEAL_ENTRY_OUT_BY && en != DEAL_ENTRY_INOUT) continue;
         long dtp = HistoryDealGetInteger(tk, DEAL_TYPE);
         if(dtp != DEAL_TYPE_BUY && dtp != DEAL_TYPE_SELL) continue;
         ulong pid = (ulong)HistoryDealGetInteger(tk, DEAL_POSITION_ID);
         bool dup = false;
         for(int j = 0; j < np; j++)
            if(posIds[j] == pid) { dup = true; break; }
         if(dup) continue;
         ArrayResize(posIds, np + 1);
         posIds[np++] = pid;
        }

      for(int k = 0; k < np; k++)
        {
         if(!HistorySelectByPosition(posIds[k])) continue;
         int    n2 = HistoryDealsTotal();
         double pl = 0.0, lots = 0.0;
         datetime tIn = 0, tOut = 0;
         double pxIn = 0.0;   // gia deal vao dau tien cua vi the
         int    type = -1;
         for(int j = 0; j < n2; j++)
           {
            ulong t2 = HistoryDealGetTicket(j);
            if(t2 == 0) continue;
            long dt2 = HistoryDealGetInteger(t2, DEAL_TYPE);
            if(dt2 != DEAL_TYPE_BUY && dt2 != DEAL_TYPE_SELL) continue;
            long en2 = HistoryDealGetInteger(t2, DEAL_ENTRY);
            datetime tm = (datetime)HistoryDealGetInteger(t2, DEAL_TIME);
            pl += HistoryDealGetDouble(t2, DEAL_PROFIT) + HistoryDealGetDouble(t2, DEAL_SWAP)
                + HistoryDealGetDouble(t2, DEAL_COMMISSION) + HistoryDealGetDouble(t2, DEAL_FEE);
            if(en2 == DEAL_ENTRY_IN)
              {
               lots += HistoryDealGetDouble(t2, DEAL_VOLUME);
               if(tIn == 0 || tm < tIn)
                 {
                  tIn  = tm;
                  pxIn = HistoryDealGetDouble(t2, DEAL_PRICE);
                  type = (dt2 == DEAL_TYPE_BUY) ? 0 : 1;
                 }
              }
            else if(tm > tOut)
               tOut = tm;
           }
         if(type < 0 || tIn == 0 || tOut == 0) continue;   // vi the mo tu truoc lich su doc duoc -> bo qua, khong doan
         if(tOut < d0) continue;                            // dong truoc hom nay
         long hold = (long)(tOut - tIn);
         if(hold < 0) hold = 0;
         StAdd(type, lots, pl, (pl > 0.0) ? hold : 0, (pl < 0.0) ? hold : 0, hold, (datetime)((long)tIn - off));
         StDetPush(det, type, pl, pxIn, (datetime)((long)tIn - off));
         nClosed++;
        }
     }

   StFormat(g_rtRows, g_rtCols, true, nClosed);
   if(g_st.nB + g_st.nS == 0)
      g_rtRows[1] = "Chua co lenh that hom nay";
   g_rtRowsUsed = StDetRows(det, g_rtRows, g_rtCols, SPM_ST_ROWS);
  }

void SpmStatsDelete()
  {
   string pf[2] = {"ST_", "RT_"};
   for(int p = 0; p < 2; p++)
     {
      ObjectDelete(0, SPM_PFX + pf[p] + "BG");
      for(int i = 0; i < SPM_ST_MAXROWS; i++)
         ObjectDelete(0, SPM_PFX + pf[p] + IntegerToString(i));
     }
  }

//--- ve 1 bang (nen + 16 nhan) tai X = x, hang dau tai Y = y0. pf = tien to ten object.
void StPaint(const string pf, const int x, const int y0, string &rows[], color &cols[], string &txtC[], color &clrC[], const int nRows)
  {
   int rh = 13;
   int w  = LevelPanelWidth();
   bool right = (InpTFPanelCorner == CORNER_RIGHT_UPPER || InpTFPanelCorner == CORNER_RIGHT_LOWER);

   string bg = SPM_PFX + pf + "BG";
   if(ObjectFind(0, bg) < 0)
     {
      ObjectCreate(0, bg, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, bg, OBJPROP_BGCOLOR,     C'28,28,28');
      ObjectSetInteger(0, bg, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, bg, OBJPROP_COLOR,       clrDimGray);
      ObjectSetInteger(0, bg, OBJPROP_SELECTABLE,  false);
      ObjectSetInteger(0, bg, OBJPROP_HIDDEN,      true);
      ObjectSetInteger(0, bg, OBJPROP_BACK,        false);
      for(int i = 0; i < SPM_ST_MAXROWS; i++)
         ObjectDelete(0, SPM_PFX + pf + IntegerToString(i));   // tao lai nhan SAU nen de nam tren
     }
   ObjectSetInteger(0, bg, OBJPROP_CORNER,    InpTFPanelCorner);
   ObjectSetInteger(0, bg, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, bg, OBJPROP_YDISTANCE, y0);
   ObjectSetInteger(0, bg, OBJPROP_XSIZE,     w);
   ObjectSetInteger(0, bg, OBJPROP_YSIZE,     nRows * rh + 6);

   for(int i = 0; i < SPM_ST_MAXROWS; i++)
     {
      string nm = SPM_PFX + pf + IntegerToString(i);
      if(i >= nRows)
        {
         // hang ngoai pham vi dang dung (vd lenh dong het -> phan chi tiet ngan lai): xoa nhan
         if(ObjectFind(0, nm) >= 0)
            ObjectDelete(0, nm);
         txtC[i] = "";
         continue;
        }
      bool fresh = false;
      if(ObjectFind(0, nm) < 0)
        {
         ObjectCreate(0, nm, OBJ_LABEL, 0, 0, 0);
         ObjectSetString (0, nm, OBJPROP_FONT,      "Arial");
         ObjectSetInteger(0, nm, OBJPROP_FONTSIZE,  8);
         ObjectSetInteger(0, nm, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, nm, OBJPROP_HIDDEN,     true);
         ObjectSetInteger(0, nm, OBJPROP_BACK,       false);
         txtC[i] = "#init#";   // ep ghi lai text
         fresh = true;
        }
      ObjectSetInteger(0, nm, OBJPROP_CORNER,    InpTFPanelCorner);
      ObjectSetInteger(0, nm, OBJPROP_ANCHOR,    right ? ANCHOR_RIGHT_UPPER : ANCHOR_LEFT_UPPER);
      ObjectSetInteger(0, nm, OBJPROP_XDISTANCE, x + 4);
      ObjectSetInteger(0, nm, OBJPROP_YDISTANCE, y0 + 3 + i * rh);
      if(txtC[i] != rows[i])
        {
         ObjectSetString(0, nm, OBJPROP_TEXT, rows[i]);
         txtC[i] = rows[i];
        }
      if(fresh || clrC[i] != cols[i])
        {
         ObjectSetInteger(0, nm, OBJPROP_COLOR, cols[i]);
         clrC[i] = cols[i];
        }
     }
  }

void SpmStatsDraw()
  {
   if(!InpShowTFPanels || !InpShowLevelPanel)
     {
      SpmStatsDelete();
      return;
     }

   string rows[SPM_ST_MAXROWS];
   color  cols[SPM_ST_MAXROWS];
   StBuild(rows, cols);

   int h = (InpTFBtnH   < 12) ? 12 : InpTFBtnH;
   int g = (InpTFBtnGap <  0) ?  0 : InpTFBtnGap;
   int tfRows = (RV2_UI_TF_COUNT + RV2_UI_COLS - 1) / RV2_UI_COLS;
   int x   = RV2_ApplyPanelShiftX(InpTFPanelX + TFPanelWidth() + ((InpTFPanelGapX < 0) ? 0 : InpTFPanelGapX));
   int y0  = InpTFPanelY + tfRows * (h + g) + 4;
   int w   = LevelPanelWidth();
   bool right = (InpTFPanelCorner == CORNER_RIGHT_UPPER || InpTFPanelCorner == CORNER_RIGHT_LOWER);

   // bang 1 (GIA LAP) ngay duoi bang nut khung M1..MN1
   StPaint("ST_", x, y0, rows, cols, g_stTxt, g_stClr, g_stRowsUsed);

   if(g_rtLast == 0 || TimeLocal() - g_rtLast >= 5)
     {
      RtBuild();
      g_rtLast = TimeLocal();
     }
   int x2 = right ? x - (w + 6) : x + w + 6;
   if(x2 < 0) x2 = 0;
   StPaint("RT_", x2, y0, g_rtRows, g_rtCols, g_rtTxt, g_rtClr, g_rtRowsUsed);
  }

//==================================================================
// 11. SU KIEN
//==================================================================
void SpmOnInit()
  {
   if(InpStepMode == STEP_ATR)
     {
      g_atr = iATR(_Symbol, _Period, InpSpmATRPeriod);
      if(g_atr == INVALID_HANDLE)
         Print("[SPM] Khong tao duoc ATR handle, se dung buoc co dinh.");
     }

   ObjectsDeleteAll(0, SPM_PFX);
   LoadState();
   SlLoad();     // nap gia chan lo (-----STB / -----STS) da chot cua cac lenh dang mo
   HistLoad();   // nap lich su lenh dong de thong ke
   HpxLoad();    // nap gia vao tung lenh dong (file phu) de liet ke <gia vao><TenMuc 1m>
   CreatePanel();

   g_lastCalc = TimeLocal();
   SetWarn("EA MO PHONG - khong gui lenh that. Bam BUY/SELL de mo lenh gia lap.");

   Print("[SPM] LUU Y nguyen nhan co the gay treo chart / cham ve nen khi gan cung indicator khac tren 1 chart:");
   Print("[SPM]  (1) Nhieu indicator/EA CUNG ve nhieu duong/nhan (object) tren 1 chart lam tang chi phi moi lan chart can ve lai - EA se Print canh bao rieng khi tong so object tren chart vuot nguong (xem WarnIfManyChartObjects()).");
   Print("[SPM]  (2) Nhieu EA/indicator CUNG dung EventSetTimer() tren 1 chart: cac ham SpmOnTimer() xep hang chay TUAN TU tren CUNG mot luong - neu MOT ham cham se lam TRE ca cac ham SpmOnTimer khac cua indicator/EA con lai, ke ca viec chart tu ve nen moi. EA nay da bo ChartRedraw() dinh ky (xem chu thich trong UpdateAll()) de giam bot phan tranh chap phia minh, nhung khong khu duoc nguyen nhan (1)/(2) neu no den tu indicator/EA khac.");

   UpdateAll(true);
  }

void SpmOnDeinit()
  {
   SaveState();
   ObjectsDeleteAll(0, SPM_PFX);
   if(g_atr != INVALID_HANDLE)
      IndicatorRelease(g_atr);
  }

void SpmOnTick()
  {
   SSpmScopeTimer __spmTimer("SpmOnTick");
   UpdateAll(false);   // chi cap nhat lai/lo va bo dem giay
  }

void SpmOnTimer()
  {
   SSpmScopeTimer __spmTimer("SpmOnTimer");
   UpdateAll(true);    // 1 giay/lan moi cham vao object cua chart
  }

void SpmOnChartEvent(const int id, const string &sparam)
  {
   SSpmScopeTimer __spmTimer("SpmOnChartEvent");
   //--- doi kich thuoc chart -> flush cac thay doi hien thi con cho (g_needRedraw)
   if(id == CHARTEVENT_CHART_CHANGE)
     {
      PivotLabelsRelayout();   // doi thang gia/kich thuoc chart -> dan lai ngay
      DrawRv2RsiLabels();
      DrawCloseSimpleLabels();   // nhan Close Simple (period tu Close Simple UI)
      ChartRedraw();
      if(g_needRedraw)
        {
         ChartRedraw();
         g_needRedraw = false;
        }
      return;
     }

   if(id != CHARTEVENT_OBJECT_CLICK)
      return;
   if(StringFind(sparam, SPM_PFX) != 0)
      return;

   ObjectSetInteger(0, sparam, OBJPROP_STATE, false);

   if(sparam == BTN_BUY)            TryOpen(0);
   else if(sparam == BTN_SELL)      TryOpen(1);
   else if(sparam == BTN_CLOSELAST) CloseLast();
   else if(sparam == BTN_CLOSEALL)  CloseAll();
   else return;

   UpdateAll(true);
   ChartRedraw();   // bam nut can phan hoi tuc thi, day la truong hop hiem gap nen khong gay treo
  }
//+------------------------------------------------------------------+
//==================================================================
//  OnInit
//==================================================================
int OnInit()
  {
   g_aptRv2EmaPeriod = MathMax(1, InpEmaPeriod);
   g_aptRv2EmaIdx    = -1;
   for(int _rv2eI = 0; _rv2eI < APT_RV2EMA_COUNT; _rv2eI++)
      if(g_aptRv2EmaVals[_rv2eI] == g_aptRv2EmaPeriod)
         g_aptRv2EmaIdx = _rv2eI;
   g_aptBrkDBars   = InpBrkDBars;
   g_aptBrkDBarsIdx = -1;
   for(int _bdI = 0; _bdI < APT_BRKDUI_COUNT; _bdI++)
     {
      if(g_aptBrkDBarsVals[_bdI] == g_aptBrkDBars)  g_aptBrkDBarsIdx = _bdI;
     }
   IndicatorSetString(INDICATOR_SHORTNAME,"AutoPositionTool");

   // Plot to mau nen 1m cham/xuyen nhan lam tron (AptRndCandlePaint()): 4 buffer OHLC + 1 buffer chi so mau (0 = vang, 1 = trang).
   SetIndexBuffer(0, g_rcO,   INDICATOR_DATA);
   SetIndexBuffer(1, g_rcH,   INDICATOR_DATA);
   SetIndexBuffer(2, g_rcL,   INDICATOR_DATA);
   SetIndexBuffer(3, g_rcC,   INDICATOR_DATA);
   SetIndexBuffer(4, g_rcClr, INDICATOR_COLOR_INDEX);
   ArraySetAsSeries(g_rcO,   true);
   ArraySetAsSeries(g_rcH,   true);
   ArraySetAsSeries(g_rcL,   true);
   ArraySetAsSeries(g_rcC,   true);
   ArraySetAsSeries(g_rcClr, true);
   PlotIndexSetDouble (0, PLOT_EMPTY_VALUE,  EMPTY_VALUE);
   PlotIndexSetInteger(0, PLOT_COLOR_INDEXES, 2);
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, 0, clrYellow);
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, 1, clrWhite);
   g_aptRndLvlN = 0;

   g_hATR = iATR(_Symbol,_Period,MathMax(2,InpATRPeriod));
   if(g_hATR==INVALID_HANDLE)
     {
      Print("Loi tao handle ATR");
      return(INIT_FAILED);
     }

   g_lastBar   = 0;
   g_lastBarTF = 0;
   g_started   = false;
   g_prevDir   = 0;
   g_prevEntry = 0.0;
   g_touchedE  = false;

   g_patAnchorOk = false;
   ArrayInitialize(g_patPosOk,false);
   ArrayInitialize(g_patCReady,false);
   for(int _imbI=0; _imbI<14; _imbI++)
     {
      g_imbVah[_imbI]    = 0.0;
      g_imbVal[_imbI]    = 0.0;
      g_imbVaOk[_imbI]   = false;
      g_imbVaBarT[_imbI] = 0;
      g_imbDir[_imbI]    = 0;
      g_imbStartT[_imbI] = 0;
      g_imbInit[_imbI]   = false;
     }

   ArrayInitialize(g_aptBrkAccUp,0);
   ArrayInitialize(g_aptBrkAccDn,0);
   ArrayInitialize(g_aptBrkAccUpA,0);
   ArrayInitialize(g_aptBrkAccDnA,0);
   ArrayInitialize(g_aptBrkAccUpE,0);
   ArrayInitialize(g_aptBrkAccDnE,0);
   ArrayInitialize(g_aptBrkAccBarT,0);
   g_aptBrkAccLast = 0;

   //==================================================================
   g_color[0]  = InpColor_M1;
   g_color[1]  = InpColor_M5;
   g_color[2]  = InpColor_M15;
   g_color[3]  = InpColor_M30;
   g_color[4]  = InpColor_H1;
   g_color[5]  = InpColor_H2;
   g_color[6]  = InpColor_H3;
   g_color[7]  = InpColor_H4;
   g_color[8]  = InpColor_H6;
   g_color[9]  = InpColor_H8;
   g_color[10] = InpColor_H12;
   g_color[11] = InpColor_D1;
   g_color[12] = InpColor_W1;
   g_color[13] = InpColor_MN1;

   ENUM_TIMEFRAMES tfRV2Init = _Period;
   int emaPInit = MathMax(1, g_aptRv2EmaPeriod);
   int warmInit = emaPInit * 4;
   if(warmInit < emaPInit + 2)
      warmInit = emaPInit + 2;
   int dispBarsTF = (InpHistPoints < 2) ? 2 : InpHistPoints;
   int nBRV2Init  = GetRV2NBars(tfRV2Init);
   int needRV2    = (dispBarsTF + warmInit) * nBRV2Init + nBRV2Init;
   if(needRV2 > 100000)
      needRV2 = 100000;
   if(needRV2 > 0 && SeriesInfoInteger(_Symbol, PERIOD_M1, SERIES_BARS_COUNT) < needRV2)
      Print("RollingVWAP2_MultiTF: Can them lich su M1 (can ~", needRV2, " nen). Dang tai...");

   if(InpS1LabelFutureBars > 0)
     {
      bool shiftOn = (bool)ChartGetInteger(0, CHART_SHIFT);
      if(!shiftOn)
        {
         if(InpAutoChartShift)
           {
            ChartSetInteger(0, CHART_SHIFT, true);
            Print("WoodiePivotEMA: da bat Chart shift de hien nhan S1 dat truoc ",
                  InpS1LabelFutureBars, " nen.");
           }
         else
           {
            Print("WoodiePivotEMA: Chart shift dang TAT nen nhan S1 dat truoc ",
                  InpS1LabelFutureBars,
                  " nen se khong dich duoc. Bat Chart shift hoac dat InpAutoChartShift = true.");
           }
        }
     }

   ENUM_TIMEFRAMES tfWoodie   = _Period;
   int             needWoodie = InpHistPoints + 1;
   if(SeriesInfoInteger(_Symbol, tfWoodie, SERIES_BARS_COUNT) < needWoodie)
      Print("WoodiePivotEMA: Can them lich su. Dang tai...");

   if(InpBarLblShow && InpBarLblRefreshMs > 0)
      EventSetMillisecondTimer((InpBarLblRefreshMs < 50) ? 50 : InpBarLblRefreshMs);

   g_barTF   = InpBarChartTF;

   for(int _rtI = 0; _rtI < RV2_TF_COUNT; _rtI++)
      g_tfRowShow[_rtI] = true;   // mac dinh hien hang ca 14 khung
   g_pivotM1LblTime = 0;

   g_pivotLevelIdx = (int)InpWoodieLevelDefault;
   if(g_pivotLevelIdx < 0)
      g_pivotLevelIdx = RV2_LVL_S1;
   if(g_pivotLevelIdx > RV2_LVL_COUNT - 1)
      g_pivotLevelIdx = RV2_LVL_S1;

   g_dxySym = InpDxySymbol;
   StringTrimLeft(g_dxySym);
   StringTrimRight(g_dxySym);
   if(StringLen(g_dxySym) > 0 && !SymbolSelect(g_dxySym, true))
      Print("DXY: khong tim thay symbol \"", g_dxySym, "\" trong Market Watch - cot Pattern hien {-}. Nhap lai ten dung vao o DXY.");

   CreateTFPanels();

   ChartSetInteger(0, CHART_SHIFT, true);
   ChartSetDouble(0, CHART_SHIFT_SIZE, 50.0);

   ChartSetInteger(0,CHART_EVENT_OBJECT_DELETE,true);


   SpmOnInit();   // khoi tao module mo phong quan ly lenh (panel BUY/SELL/DONG LENH, nap trang thai da luu).
   return(INIT_SUCCEEDED);
  }

//==================================================================
//  OnDeinit
//==================================================================
void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(0,PFX);
   if(g_hATR!=INVALID_HANDLE)
      IndicatorRelease(g_hATR);

   //==================================================================
   //==================================================================
   ObjectsDeleteAll(0, g_rv2LinePrefix, -1, OBJ_TREND);
   ObjectsDeleteAll(0, g_rv1LinePrefix, -1, OBJ_TREND);
   ObjectsDeleteAll(0, g_owLinePrefix, -1, OBJ_TREND);   // duong OW
   ObjectsDeleteAll(0, g_barPrefix, -1, OBJ_TREND);
   ObjectsDeleteAll(0, PP_EMA_PP_PREFIX, -1, OBJ_TREND);
   ObjectsDeleteAll(0, PP_EMA_R1_PREFIX, -1, OBJ_TREND);
   ObjectsDeleteAll(0, PP_EMA_R2_PREFIX, -1, OBJ_TREND);
   ObjectsDeleteAll(0, PP_EMA_R3_PREFIX, -1, OBJ_TREND);
   ObjectsDeleteAll(0, PP_EMA_R4_PREFIX, -1, OBJ_TREND);
   ObjectsDeleteAll(0, PP_EMA_R5_PREFIX, -1, OBJ_TREND);
   ObjectsDeleteAll(0, PP_EMA_R6_PREFIX, -1, OBJ_TREND);
   ObjectsDeleteAll(0, PP_EMA_R7_PREFIX, -1, OBJ_TREND);
   ObjectsDeleteAll(0, PP_EMA_R8_PREFIX, -1, OBJ_TREND);
   ObjectsDeleteAll(0, PP_EMA_R9_PREFIX, -1, OBJ_TREND);
   ObjectsDeleteAll(0, PP_EMA_S1_PREFIX, -1, OBJ_TREND);
   ObjectsDeleteAll(0, PP_EMA_S2_PREFIX, -1, OBJ_TREND);
   ObjectsDeleteAll(0, PP_EMA_S3_PREFIX, -1, OBJ_TREND);
   ObjectsDeleteAll(0, PP_EMA_S4_PREFIX, -1, OBJ_TREND);
   ObjectsDeleteAll(0, PP_EMA_S5_PREFIX, -1, OBJ_TREND);
   ObjectsDeleteAll(0, PP_EMA_S6_PREFIX, -1, OBJ_TREND);
   ObjectsDeleteAll(0, PP_EMA_S7_PREFIX, -1, OBJ_TREND);
   ObjectsDeleteAll(0, PP_EMA_S8_PREFIX, -1, OBJ_TREND);
   ObjectsDeleteAll(0, PP_EMA_S9_PREFIX, -1, OBJ_TREND);
   ObjectsDeleteAll(0, PP_EMA_PP_LBL_PREFIX, -1, OBJ_TEXT);
   ObjectsDeleteAll(0, PP_EMA_R1_LBL_PREFIX, -1, OBJ_TEXT);
   ObjectsDeleteAll(0, PP_EMA_R2_LBL_PREFIX, -1, OBJ_TEXT);
   ObjectsDeleteAll(0, PP_EMA_R3_LBL_PREFIX, -1, OBJ_TEXT);
   ObjectsDeleteAll(0, PP_EMA_R4_LBL_PREFIX, -1, OBJ_TEXT);
   ObjectsDeleteAll(0, PP_EMA_R5_LBL_PREFIX, -1, OBJ_TEXT);
   ObjectsDeleteAll(0, PP_EMA_R6_LBL_PREFIX, -1, OBJ_TEXT);
   ObjectsDeleteAll(0, PP_EMA_R7_LBL_PREFIX, -1, OBJ_TEXT);
   ObjectsDeleteAll(0, PP_EMA_R8_LBL_PREFIX, -1, OBJ_TEXT);
   ObjectsDeleteAll(0, PP_EMA_R9_LBL_PREFIX, -1, OBJ_TEXT);
   ObjectsDeleteAll(0, PP_EMA_S1_LBL_PREFIX, -1, OBJ_TEXT);
   ObjectsDeleteAll(0, PP_EMA_S2_LBL_PREFIX, -1, OBJ_TEXT);
   ObjectsDeleteAll(0, PP_EMA_S3_LBL_PREFIX, -1, OBJ_TEXT);
   ObjectsDeleteAll(0, PP_EMA_S4_LBL_PREFIX, -1, OBJ_TEXT);
   ObjectsDeleteAll(0, PP_EMA_S5_LBL_PREFIX, -1, OBJ_TEXT);
   ObjectsDeleteAll(0, PP_EMA_S6_LBL_PREFIX, -1, OBJ_TEXT);
   ObjectsDeleteAll(0, PP_EMA_S7_LBL_PREFIX, -1, OBJ_TEXT);
   ObjectsDeleteAll(0, PP_EMA_S8_LBL_PREFIX, -1, OBJ_TEXT);
   ObjectsDeleteAll(0, PP_EMA_S9_LBL_PREFIX, -1, OBJ_TEXT);
   ObjectsDeleteAll(0, g_rv2RsiLblPrefix, -1, OBJ_TEXT);
   ObjectsDeleteAll(0, g_rv1RsiLblPrefix, -1, OBJ_TEXT);
   ObjectsDeleteAll(0, g_csmaLblPrefix, -1, OBJ_TEXT);   // nhan Close Simple
   ObjectsDeleteAll(0, g_barLblPrefix, -1, OBJ_TEXT);
   ObjectsDeleteAll(0, g_rndMkPrefix);   // danh dau muc lam tron tren thang gia
   DeleteTFPanels();
   EventKillTimer();

   SpmOnDeinit();   // don doi tuong/luu trang thai cua module mo phong truoc khi APT ve lai chart lan cuoi.
   ChartRedraw();
  }

//==================================================================
//  OnCalculate
//==================================================================
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   SSpmScopeTimer __spmTimer("OnCalculate");
   SpmOnTick();   // cap nhat lai/lo + bo dem giay cua module mo phong, chay tren moi tick.
   DrawMidPriceLabel();   // nhan gia giua (Bid + Ask)/2 - cap nhat moi tick
   AptRndCandlePaint();   // to mau nen 1m cham/xuyen nhan lam tron (vang = bat len, trang = bat xuong); nen moi / nen dang chay cap nhat o day
   if(rates_total < InpSwingDepth*3 + 20)
      return(rates_total);

   datetime t0 = iTime(_Symbol,_Period,0);
   bool newBar = (t0!=g_lastBar);
   if(newBar)
      g_lastBar = t0;

   datetime tTF = iTime(_Symbol,_Period,0);
   bool newBarTF = (tTF!=g_lastBarTF);
   if(newBarTF)
      g_lastBarTF = tTF;

   if(!g_started)
     {
      if(InpMode==APT_MANUAL)
         BuildManualDefault();
      else
         BuildSetup();
      g_started = true;
     }
   else
     {
      if(InpMode!=APT_MANUAL && newBarTF && InpRescanNewBar)
         BuildSetup();
     }

   uint now = GetTickCount();
   if(newBar || now-g_lastDraw>400)
     {
      g_lastDraw = now;
      RecalcMoney(g_s);
      DrawPanel();
      CheckAlerts();
      // Duong RV1/RV2 cua khung chon o nut UI: ve lai theo tick, cung nhip throttle 200ms voi cac ham ve o tren.
      DrawRvLinesSelTF();
      DrawWoodiePivotEma();
      DrawRv2RsiLabels();
      DrawCloseSimpleLabels();   // nhan Close Simple (period tu Close Simple UI)
      ChartRedraw();
     }

   //==================================================================
   //==================================================================
   bool rvPortNewBarOrFirst = !(prev_calculated > 0 && rates_total == prev_calculated);
   if(rvPortNewBarOrFirst && rates_total > 0)
     {
      DrawWoodiePivotEma();
      DrawBarChart();
      DrawBarChartLabels();
      DrawRv2RsiLabels();
      DrawCloseSimpleLabels();   // nhan Close Simple (period tu Close Simple UI)
      ChartRedraw();
     }

   return(rates_total);
  }

//==================================================================
//  OnTimer cua APT: timer duoc bat trong OnInit theo dieu kien (InpBarLblShow && InpBarLblRefreshMs > 0) va tat trong OnDeinit.
//  Nhip lam moi THOI GIAN THUC cua cum nhan than nen lon (BarChartMoveCurBar, DrawBarChartLabels), cac nhan RV1/RV2/Close Simple/Pivot/Pattern
//  va module mo phong (SpmOnTimer) - thieu no thi dong ho tren nhan chi nhay moi khi co nen moi.
//==================================================================
void OnTimer()
  {
   SSpmScopeTimer __spmTimer("OnTimer");
   BarChartMoveCurBar();
   DrawBarChartLabels();
   DrawRv2RsiLabels();
   DrawCloseSimpleLabels();   // nhan Close Simple (period tu Close Simple UI)
   DrawMidPriceLabel();   // nhan gia giua (Bid + Ask)/2 - giu dung vi tri khi sang nen M1 moi ma chua co tick
   PivotLabelsRelayout();   // dan lai hang nhan Pivot theo thang gia hien tai (khong doi tick)
   DrawAptPatternColumn();
   SpmOnTimer();   // cap nhat + ve lai cac doi tuong cua module mo phong, dung CHUNG timer nay voi APT.
   ChartRedraw();
  }

//==================================================================
//  OnChartEvent - keo duong / phim tat
//==================================================================
void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
  {
   SSpmScopeTimer __spmTimer("OnChartEvent");
   if(id==CHARTEVENT_OBJECT_ENDEDIT && sparam==g_edtDxyPrefix+"SYM")
     {
      string _dx=ObjectGetString(0,sparam,OBJPROP_TEXT);
      StringTrimLeft(_dx);
      StringTrimRight(_dx);
      if(StringLen(_dx)>0)
        {
         if(!SymbolSelect(_dx,true))
            Print("DXY: khong tim thay symbol \"",_dx,"\" trong Market Watch - cot Pattern hien {-}.");
         g_dxySym=_dx;
        }
      ObjectSetString(0,sparam,OBJPROP_TEXT,g_dxySym);
      DrawRv2RsiLabels();
      DrawAptPatternColumn();
      ChartRedraw();
      return;
     }
   if(id==CHARTEVENT_OBJECT_ENDEDIT && sparam==g_edtRndPrefix+"VAL")
     {
      string _rx=ObjectGetString(0,sparam,OBJPROP_TEXT);
      StringTrimLeft(_rx);
      StringTrimRight(_rx);
      StringReplace(_rx,",",".");
      bool _rHasDig=false, _rBad=false;
      for(int _rc=0;_rc<StringLen(_rx);_rc++)
        {
         ushort _rch=StringGetCharacter(_rx,_rc);
         if(_rch>='0' && _rch<='9')
           { _rHasDig=true; continue; }
         if(_rch=='.')
            continue;
         _rBad=true;
         break;
        }
      if(_rHasDig && !_rBad)
        {
         g_aptRndRange=StringToDouble(_rx);
         g_aptRndRangeTxt=_rx;
        }
      ObjectSetString(0,sparam,OBJPROP_TEXT,g_aptRndRangeTxt);
      DrawRv2RsiLabels();
      ChartRedraw();
      return;
     }
   if(id==CHARTEVENT_OBJECT_CLICK && sparam==g_btnRndGapName)
     {
      g_aptRndGap=!g_aptRndGap;
      UpdateRndPanelStates();
      DrawRv2RsiLabels();   // ve lai nhan lam tron (AptRndMarksDraw)
      ChartRedraw();
      ObjectSetInteger(0,sparam,OBJPROP_STATE,false);
      return;
     }
   if(id==CHARTEVENT_OBJECT_CLICK && StringFind(sparam,g_btnRndPrefix)==0)
     {
      int _ri=(int)StringToInteger(StringSubstr(sparam,StringLen(g_btnRndPrefix)));
      if(_ri>=0 && _ri<4)
        {
         g_aptRndIdx=_ri;
         UpdateRndPanelStates();
         DrawRv2RsiLabels();
         ChartRedraw();
        }
      ObjectSetInteger(0,sparam,OBJPROP_STATE,false);
      return;
     }
   SpmOnChartEvent(id, sparam);   // xu ly rieng cac object cua module mo phong (prefix SPM_PFX); rieng logic goc APT o duoi khong doi.

   if(id==CHARTEVENT_OBJECT_CLICK)
     {
      //==================================================================
      //==================================================================
      if(InpShowTFPanels)
        {
         if(InpShowLevelPanel)
           {
            for(int om = 0; om < APT_OW_MODE_COUNT; om++)
              {
               if(sparam == g_btnOwModePrefix + IntegerToString(om))
                 {
                  g_aptOwMode = om;   // doi cach tinh OW: LWMA / EMA / EMA(LWMA)
                  UpdateTFPanelStates();
                  DrawBrkDHHLL();       // duong OW + nhan OW<khung>
                  DrawRv2RsiLabels();   // [<diffpv3>] tren nhan Pivot + moc lam tron <khung>OW
                  ChartRedraw();
                  return;
                 }
              }

            for(int rt = 0; rt < RV2_TF_COUNT; rt++)
              {
               if(sparam == g_btnRowTfPrefix + IntegerToString(rt))
                 {
                  g_tfRowShow[rt] = !g_tfRowShow[rt];   // tick/bo tick hang cua khung rt trong nhan Pivot / RV1 / RV2
                  UpdateTFPanelStates();
                  DrawWoodiePivotEma();
                  DrawRv2RsiLabels();
                  ChartRedraw();
                  return;
                 }
              }

            for(int k = 0; k < RV2_LVL_COUNT; k++)
              {
               if(sparam == g_btnLvPrefix + IntegerToString(k))
                 {
                  g_pivotLevelIdx = k;
                  UpdateTFPanelStates();
                  DrawWoodiePivotEma();
                  ChartRedraw();
                  return;
                 }
              }

            if(sparam == g_btnPvModePrefix + "0")
              {
               g_pivotFollowDisplayedLvl = false;
               UpdateTFPanelStates();
               DrawWoodiePivotEma();
               ChartRedraw();
               return;
              }
            if(sparam == g_btnPvModePrefix + "1")
              {
               g_pivotFollowDisplayedLvl = true;
               UpdateTFPanelStates();
               DrawWoodiePivotEma();
               ChartRedraw();
               return;
              }

            for(int p = 0; p < APT_RSI_PE_COUNT; p++)
              {
               if(sparam == g_btnRsiPePrefix + IntegerToString(p))
                 {
                  g_aptRsiPeIdx      = p;
                  APT_S1_RSI_PERIOD  = g_aptRsiPeVals[p];
                  WOODIE_RSI_PERIOD  = g_aptRsiPeVals[p];
                  UpdateTFPanelStates();
                  DrawWoodiePivotEma();
                  ChartRedraw();
                  return;
                 }
              }

            for(int pe = 0; pe < APT_RV2EMA_COUNT; pe++)
              {
               if(sparam == g_btnRv2EmaPrefix + IntegerToString(pe))
                 {
                  g_aptRv2EmaIdx    = pe;
                  g_aptRv2EmaPeriod = g_aptRv2EmaVals[pe];
                  UpdateTFPanelStates();
                  DrawRvLinesSelTF();
                  DrawWoodiePivotEma();
                  DrawRv2RsiLabels();
                  DrawCloseSimpleLabels();   // nhan Close Simple theo moc nhan 1m moi
                  ChartRedraw();
                  return;
                 }
              }

            for(int bk = 0; bk < APT_BRKDUI_COUNT; bk++)
              {
               if(sparam != g_btnBrkDPrefix + IntegerToString(bk))
                  continue;
               g_aptBrkDBarsIdx = bk;
               g_aptBrkDBars    = g_aptBrkDBarsVals[bk];
               for(int _ci = 0; _ci < APT_BRK_STREAK_TF_COUNT; _ci++)
                 {
                  g_aptBrkStrkSide[_ci] = 0;   // 0 = cache streak chua hop le -> AptBrkStreakClosedBuild() tinh lai
                  g_aptBrkStrkBarT[_ci] = 0;
                 }
               UpdateTFPanelStates();
               DrawRv2RsiLabels();
               DrawAptPatternColumn();
               DrawBrkDHHLL();   // doi so nen kenh -> HH/LL doi theo
               ChartRedraw();
               return;
              }

            for(int tk = 0; tk < APT_BRKDTF_COUNT; tk++)
              {
               if(sparam == g_btnBrkDTfPrefix + IntegerToString(tk))
                 {
                  g_aptBrkDTfIdx = (g_aptBrkDTfIdx == tk) ? -1 : tk;
                  UpdateTFPanelStates();
                  DrawRvLinesSelTF();    // doi khung -> ve lai duong RV1/RV2 theo khung moi (hoac don neu TAT)
                  DrawWoodiePivotEma();   // doi khung -> duong Pivot doi theo
                  DrawBrkDHHLL();
                  ChartRedraw();
                  return;
                 }
              }

            for(int cs = 0; cs < APT_CSMA_COUNT; cs++)
              {
               if(sparam == g_btnCsmaPrefix + IntegerToString(cs))
                 {
                  g_aptCsmaIdx    = cs;
                  g_aptCsmaPeriod = g_aptCsmaVals[cs];
                  UpdateTFPanelStates();
                  DrawCloseSimpleLabels();
                  ChartRedraw();
                  return;
                 }
              }
           }

         for(int i = 0; i < RV2_UI_TF_COUNT; i++)
           {
            if(sparam == g_btnBcPrefix + IntegerToString(i))
              {
               g_barTF = g_uiTFList[i];
               UpdateTFPanelStates();
               DrawBarChart();
               DrawBarChartLabels();
               DrawAptPatternColumn();
               ChartRedraw();
               return;
              }
           }
        }
      return;
     }

   if(id==CHARTEVENT_KEYDOWN)
     {
      //--- phim R = quet lai ngay
      if(lparam==82)
        {
         if(InpMode==APT_MANUAL)
            BuildManualDefault();
         else
            BuildSetup();
         DrawPanel();
         ChartRedraw();
        }
      return;
     }

   if(id==CHARTEVENT_OBJECT_DELETE)
     {
      if(StringFind(sparam,PFX)==0
         && StringFind(sparam,PFX"PAT")!=0)
        {
         DrawPanel();
         ChartRedraw();
        }
      return;
     }
  }
//+------------------------------------------------------------------+
