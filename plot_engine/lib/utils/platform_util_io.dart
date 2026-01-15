import 'dart:io' show Platform;

/// Native platform implementation
bool getPlatformIsWindows() => Platform.isWindows;
bool getPlatformIsLinux() => Platform.isLinux;
bool getPlatformIsMacOS() => Platform.isMacOS;
