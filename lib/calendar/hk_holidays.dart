/// 香港公眾假期(資料嚟源:政府憲報 gov.hk/en/about/abouthk/holiday)。
/// 呢個 app 冇後台/API,呢個清單淨係本機靜態資料。
///
/// ⚠️ 維護提示:每年到咗(建議每年 5-6 月政府公佈新一年假期表嗰陣),
/// 要嚟呢個 file 加多一年嘅日期,再跟返你而家嘅流程出新版 APK。
/// 一次過睇晒未來幾年:https://www.gov.hk/en/about/abouthk/holiday/index.htm
library;

final Set<DateTime> hkHolidays = <DateTime>{
  // ===== 2026 =====
  DateTime(2026, 1, 1),   // 元旦
  DateTime(2026, 2, 17),  // 農曆年初一
  DateTime(2026, 2, 18),  // 農曆年初二
  DateTime(2026, 2, 19),  // 農曆年初三
  DateTime(2026, 4, 3),   // 耶穌受難節
  DateTime(2026, 4, 4),   // 耶穌受難節翌日
  DateTime(2026, 4, 6),   // 清明節翌日
  DateTime(2026, 4, 7),   // 復活節後翌日
  DateTime(2026, 5, 1),   // 勞動節
  DateTime(2026, 5, 25),  // 佛誕翌日
  DateTime(2026, 6, 19),  // 端午節
  DateTime(2026, 7, 1),   // 香港特別行政區成立紀念日
  DateTime(2026, 9, 26),  // 中秋節翌日
  DateTime(2026, 10, 1),  // 國慶日
  DateTime(2026, 10, 19), // 重陽節翌日
  DateTime(2026, 12, 25), // 聖誕節
  DateTime(2026, 12, 26), // 聖誕節後第一個周日

  // ===== 2027 =====
  DateTime(2027, 1, 1),   // 元旦
  DateTime(2027, 2, 6),   // 農曆年初一
  DateTime(2027, 2, 8),   // 農曆年初三(初二啱啱好係星期日,政府補咗初四)
  DateTime(2027, 2, 9),   // 農曆年初四
  DateTime(2027, 3, 26),  // 耶穌受難節
  DateTime(2027, 3, 27),  // 耶穌受難節翌日
  DateTime(2027, 3, 29),  // 復活節星期一
  DateTime(2027, 4, 5),   // 清明節
  DateTime(2027, 5, 1),   // 勞動節
  DateTime(2027, 5, 13),  // 佛誕
  DateTime(2027, 6, 9),   // 端午節
  DateTime(2027, 7, 1),   // 香港特別行政區成立紀念日
  DateTime(2027, 9, 16),  // 中秋節翌日
  DateTime(2027, 10, 1),  // 國慶日
  DateTime(2027, 10, 8),  // 重陽節
  DateTime(2027, 12, 25), // 聖誕節
  DateTime(2027, 12, 27), // 聖誕節後第一個周一
};