// the daily reminder. A LOCAL notification: our app asks the phone
// "show this text every day at 8:00", and from then on the phone does it by itself,
// even if the app is closed or killed. No server involved (that would be a PUSH notification).
//
// Another repository: the providers call schedule/cancel, only this class knows the plugin.

import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // flutter pub add flutter_local_notifications
import 'package:flutter_timezone/flutter_timezone.dart'; // the phone's time zone ("Europe/Rome")
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz; // dates "at 8:00 in Rome", that stay right when the clock changes

class ReminderService {
  static const _dailyId = 1; // each notification has a number: the same number replaces or cancels it
  static const _confirmId = 2;
  static const hour = 8; // the time of the reminder

  final _plugin = FlutterLocalNotificationsPlugin();

  // the plugin is started once, the first time we need it (not in main: most users never turn the reminder on)
  Future<void>? _ready;
  Future<void> _start() => _ready ??= _setUp();

  Future<void> _setUp() async {
    tz_data.initializeTimeZones();
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'), // the small icon: our app icon
        // we ask for the permission ourselves, when the user turns the switch on (see requestPermission)
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }

  /// Asks the user (only the first time: then the system remembers the answer).
  /// true = we may show notifications.
  Future<bool> requestPermission() async {
    await _start();
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission() ??
        await ios?.requestPermissions(alert: true, sound: true);
    return granted ?? false;
  }

  // how the notification looks. On Android it belongs to a "channel", which the user can turn off in the settings
  static const _details = NotificationDetails(
    android: AndroidNotificationDetails('daily_reminder', 'Daily reminder'),
    iOS: DarwinNotificationDetails(),
  );

  /// Every day at 8:00, from the next 8:00 on. The texts are fixed now, in the language of now.
  Future<void> scheduleDaily({required String title, required String body}) async {
    await _start();
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1)); // 8:00 already passed: tomorrow
    await _plugin.zonedSchedule(
      id: _dailyId,
      scheduledDate: next,
      notificationDetails: _details,
      // inexact: Android may move it by a few minutes to save battery. Fine for a reminder, and no extra permission
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: title,
      body: body,
      matchDateTimeComponents: DateTimeComponents.time, // repeat every day at the same time
    );
  }

  /// One notification right now: "the reminder is on". It also shows that notifications work.
  Future<void> showNow({required String title, required String body}) async {
    await _start();
    await _plugin.show(id: _confirmId, title: title, body: body, notificationDetails: _details);
  }

  Future<void> cancel() async {
    await _start();
    await _plugin.cancel(id: _dailyId);
  }
}
