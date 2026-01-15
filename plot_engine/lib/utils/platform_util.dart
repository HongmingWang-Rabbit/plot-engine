import 'platform_util_stub.dart'
    if (dart.library.io) 'platform_util_io.dart';

/// Platform detection utilities that work on both web and native
class PlatformUtil {
  static bool get isWindows => getPlatformIsWindows();
  static bool get isLinux => getPlatformIsLinux();
  static bool get isMacOS => getPlatformIsMacOS();
}
