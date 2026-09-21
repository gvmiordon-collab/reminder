import 'package:flutter/material.dart';
import 'notification_service.dart';

/// MainScreen 開嗰陣 call 一次:先問 Android 13+ 嘅 POST_NOTIFICATIONS
/// (有 system dialog),再睇吓 exact alarm 開咗未,冇嘅話彈個 dialog
/// 解釋一下先帶用戶去 Settings(呢個冇 in-app system dialog)。
///
/// 撳「遲啲先」之後會記低,之後開 app 唔會再彈。撳「去開」就唔記,
/// 如果返嚟之後權限仲未開,下次開 app 會再問一次。
/// 一旦權限已開,會清走「已經問過」記錄,將來如果權限被收返會再問。
Future<void> runNotificationPermissionGate(BuildContext context) async {
  final service = NotificationService.instance;

  await service.requestPermissions();

  if (!context.mounted) return;
  final needsExactAlarm = await service.needsExactAlarmSettingsPrompt();

  if (!needsExactAlarm) {
    await service.setExactAlarmPromptDismissed(false);
    return;
  }
  if (await service.isExactAlarmPromptDismissed()) return;
  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('準時提醒要開多一個權限'),
      content: const Text(
        '為咗保證提醒可以準時彈出,尤其係就快到期嗰陣嘅密集提醒,'
            '需要喺系統設定入面開返「鬧鐘與提醒」呢個權限。而家去開？',
      ),
      actions: [
        TextButton(
          onPressed: () {
            service.setExactAlarmPromptDismissed(true);
            Navigator.pop(context);
          },
          child: const Text('遲啲先'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            service.openExactAlarmSettings();
          },
          child: const Text('去開'),
        ),
      ],
    ),
  );
}