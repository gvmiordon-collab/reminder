import 'package:flutter/foundation.dart';

/// 撳咗 notification 之後想強制跳去邊個 tab(0 = list, 1 = calendar)。
/// MainScreen 會 listen 呢個 notifier,一有新值就切 tab。
final ValueNotifier<int> requestedTabIndex = ValueNotifier<int>(0);