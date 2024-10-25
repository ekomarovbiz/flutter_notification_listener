import 'dart:isolate';
import 'dart:ui';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import './event.dart';

typedef EventCallbackFunc = void Function(NotificationEvent evt);

/// NotificationsListener
class NotificationsListener {
  static String channelId = "flutter_notification_listener";
  static String sendPortName = "notifications_send_port";
  static final MethodChannel _methodChannel =
      MethodChannel('{$channelId/method');
  static final MethodChannel _bgMethodChannel =
      MethodChannel('$channelId/bg_method');
  static MethodChannel get bgMethodChannel => _bgMethodChannel;
  static ReceivePort? _receivePort;

  /// Get a defualt receivePort
  static ReceivePort? get receivePort {
    if (_receivePort == null) {
      _receivePort = ReceivePort();
      // remove the old one at first.
      IsolateNameServer.removePortNameMapping(sendPortName);
      IsolateNameServer.registerPortWithName(
          _receivePort!.sendPort, sendPortName);
    }
    return _receivePort;
  }

  /// Check have permission or not
  static Future<bool?> get hasPermission async {
    return await _methodChannel.invokeMethod('plugin.hasPermission');
  }

  /// Open the settings activity
  static Future<void> openPermissionSettings() async {
    return await _methodChannel.invokeMethod('plugin.openPermissionSettings');
  }

  /// Initialize the plugin and request relevant permissions from the user.
  static Future<void> initialize({
    EventCallbackFunc callbackHandle = _defaultCallbackHandle,
  }) async {
    final CallbackHandle callbackDispatch =
        PluginUtilities.getCallbackHandle(callbackDispatcher)!;
    await _methodChannel.invokeMethod(
        'plugin.initialize', callbackDispatch.toRawHandle());

    // call this call back in the current engine
    // this is important to use ui flutter engine access `service.channel`
    callbackDispatcher(inited: false);

    // register event handler
    // register the default event handler
    await registerEventHandle(callbackHandle);
  }

  /// Register a new event handler
  static Future<void> registerEventHandle(EventCallbackFunc callback) async {
    final CallbackHandle callback0 =
        PluginUtilities.getCallbackHandle(callback)!;
    await _methodChannel.invokeMethod(
        'plugin.registerEventHandle', callback0.toRawHandle());
  }

  /// check the service running or not
  static Future<bool?> get isRunning async {
    return await _methodChannel.invokeMethod('plugin.isServiceRunning');
  }

  /// start the service
  static Future<bool?> startService({
    bool foreground = true,
    String subTitle = "",
    bool showWhen = false,
    String title = "Notification Listener",
    String description = "Service is running",
  }) async {
    var data = {};
    data["foreground"] = foreground;
    data["subTitle"] = subTitle;
    data["showWhen"] = showWhen;
    data["title"] = title;
    data["description"] = description;

    var res = await _methodChannel.invokeMethod('plugin.startService', data);

    return res;
  }

  /// stop the service
  static Future<bool?> stopService() async {
    return await _methodChannel.invokeMethod('plugin.stopService');
  }

  /// promote the service to foreground
  static Future<void> promoteToForeground(
    String title, {
    String subTitle = "",
    bool showWhen = false,
    String description = "Service is running",
  }) async {
    var data = {};
    data["foreground"] = true;
    data["subTitle"] = subTitle;
    data["showWhen"] = showWhen;
    data["title"] = title;
    data["description"] = description;

    return await _bgMethodChannel.invokeMethod(
        'service.promoteToForeground', data);
  }

  /// demote the service to background
  static Future<void> demoteToBackground() async =>
      await _bgMethodChannel.invokeMethod('service.demoteToBackground');

  /// tap the notification
  static Future<bool> tapNotification(String uid) async {
    return await _bgMethodChannel.invokeMethod<bool>('service.tap', [uid]) ??
        false;
  }

  /// tap the notification action
  /// use the index to locate the action
  static Future<bool> tapNotificationAction(String uid, int actionId) async {
    return await _bgMethodChannel
            .invokeMethod<bool>('service.tap_action', [uid, actionId]) ??
        false;
  }

  /// set content for action's input
  /// this is useful while auto reply by notification
  static Future<bool> postActionInputs(
      String uid, int actionId, Map<String, dynamic> map) async {
    return await _bgMethodChannel
            .invokeMethod<bool>("service.send_input", [uid, actionId, map]) ??
        false;
  }

  /// get the full notification from android
  /// with the unqiue id
  static Future<dynamic> getFullNotification(String uid) async {
    return await _bgMethodChannel
        .invokeMethod<dynamic>("service.get_full_notification", [uid]);
  }

  static void _defaultCallbackHandle(NotificationEvent evt) {
    final SendPort? send = IsolateNameServer.lookupPortByName(sendPortName);
    if (kDebugMode) {
      print("[default callback handler] [send isolate nameserver]");
    }
    if (send == null) {
      if (kDebugMode) {
        print("IsolateNameServer: can not find send $sendPortName");
      }
    }
    send?.send(evt);
  }
}

/// callbackDispatcher use to install background channel
void callbackDispatcher({inited = true}) {
  WidgetsFlutterBinding.ensureInitialized();

  NotificationsListener._bgMethodChannel
      .setMethodCallHandler((MethodCall call) async {
    try {
      switch (call.method) {
        case "sink_event":
          {
            final List<dynamic> args = call.arguments;
            final evt = NotificationEvent.fromMap(args[1]);

            final Function? callback = PluginUtilities.getCallbackFromHandle(
                CallbackHandle.fromRawHandle(args[0]));

            if (callback == null) {
              if (kDebugMode) {
                print("callback is not register: ${args[0]}");
              }
              return;
            }

            callback(evt);
          }
          break;
        default:
          {
            if (kDebugMode) {
              print("unknown bg_method: ${call.method}");
            }
          }
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  });

  // if start the ui first, this will cause method not found error
  if (inited) {
    NotificationsListener._bgMethodChannel.invokeMethod('service.initialized');
  }
}