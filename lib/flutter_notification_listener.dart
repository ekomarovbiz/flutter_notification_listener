
import 'flutter_notification_listener_platform_interface.dart';

class FlutterNotificationListener {
  Future<String?> getPlatformVersion() {
    return FlutterNotificationListenerPlatform.instance.getPlatformVersion();
  }
}
