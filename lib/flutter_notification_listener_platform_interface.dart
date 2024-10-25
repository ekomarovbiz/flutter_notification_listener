import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_notification_listener_method_channel.dart';

abstract class FlutterNotificationListenerPlatform extends PlatformInterface {
  /// Constructs a FlutterNotificationListenerPlatform.
  FlutterNotificationListenerPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterNotificationListenerPlatform _instance = MethodChannelFlutterNotificationListener();

  /// The default instance of [FlutterNotificationListenerPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterNotificationListener].
  static FlutterNotificationListenerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterNotificationListenerPlatform] when
  /// they register themselves.
  static set instance(FlutterNotificationListenerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
