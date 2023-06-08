import 'dart:convert';

import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:locus/App.dart';
import 'package:locus/api/get-locations.dart';
import 'package:locus/constants/notifications.dart';
import 'package:locus/services/location_alarm_service.dart';
import 'package:locus/services/location_point_service.dart';
import 'package:locus/services/task_service.dart';
import 'package:locus/services/view_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/log.dart';
import 'log_service.dart';

Future<void> updateLocation() async {
  final taskService = await TaskService.restore();
  final logService = await LogService.restore();

  await taskService.checkup(logService);
  final runningTasks = await taskService.getRunningTasks().toList();

  if (runningTasks.isEmpty) {
    return;
  }

  final locationData = await LocationPointService.createUsingCurrentLocation();

  for (final task in runningTasks) {
    await task.publishCurrentLocationNow(locationData.copyWithDifferentId());
  }

  await logService.addLog(
    Log.updateLocation(
      initiator: LogInitiator.system,
      latitude: locationData.latitude,
      longitude: locationData.longitude,
      accuracy: locationData.accuracy,
      tasks: List<UpdatedTaskData>.from(
        runningTasks.map(
          (task) => UpdatedTaskData(
            id: task.id,
            name: task.name,
          ),
        ),
      ),
    ),
  );
}

Future<void> checkViewAlarms({
  required final AppLocalizations l10n,
  required final Iterable<TaskView> views,
}) async {
  for (final view in views) {
    await view.checkAlarm(
      onTrigger: (alarm, location, __) async {
        if (alarm is RadiusBasedRegionLocationAlarm) {
          final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

          flutterLocalNotificationsPlugin.show(
            location.createdAt.millisecondsSinceEpoch,
            l10n.locationAlarm_radiusBasedRegion_notificationTitle_whenEnter(
              view.name,
              "test",
            ),
            l10n.locationAlarm_notification_description,
            NotificationDetails(
              android: AndroidNotificationDetails(
                AndroidChannelIDs.locationAlarms.name,
                l10n.androidNotificationChannel_locationAlarms_name,
                channelDescription: l10n.androidNotificationChannel_locationAlarms_description,
                importance: Importance.max,
                priority: Priority.max,
              ),
            ),
            payload: jsonEncode({
              "type": NotificationActionType.openTaskView.index,
              "taskViewID": view.id,
            }),
          );
        }
      },
      onMaybeTrigger: (alarm, _, __) {},
    );
  }
}

Future<void> _checkViewAlarms() async {
  final viewService = await ViewService.restore();
  final alarmsViews = viewService.viewsWithAlarms;
  final locale = Locale("en");
  final l10n = await AppLocalizations.delegate.load(locale);

  if (alarmsViews.isEmpty) {
    return;
  }

  checkViewAlarms(
    l10n: l10n,
    views: alarmsViews,
  );
}

@pragma('vm:entry-point')
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  String taskId = task.taskId;
  bool isTimeout = task.timeout;

  if (isTimeout) {
    BackgroundFetch.finish(taskId);
    return;
  }

  await updateLocation();

  BackgroundFetch.finish(taskId);
}

void configureBackgroundFetch() {
  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);

  BackgroundFetch.configure(
    BackgroundFetchConfig(
      minimumFetchInterval: 15,
      requiresCharging: false,
      enableHeadless: true,
      requiredNetworkType: NetworkType.ANY,
      requiresBatteryNotLow: false,
      requiresDeviceIdle: false,
      requiresStorageNotLow: false,
      startOnBoot: true,
      stopOnTerminate: false,
    ),
    (taskId) async {
      // We only use one taskId to update the location for all tasks,
      // so we don't need to check the taskId.
      await updateLocation();

      BackgroundFetch.finish(taskId);
    },
    (taskId) {
      // Timeout, we need to finish immediately.
      BackgroundFetch.finish(taskId);
    },
  );
}
