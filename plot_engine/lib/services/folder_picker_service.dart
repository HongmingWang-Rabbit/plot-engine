import 'dart:io';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';

/// Centralized folder picking service with platform-specific handling
class FolderPickerService {
  static const platform = MethodChannel('com.plotengine.folder_picker');

  /// Pick a directory with platform-specific implementation
  static Future<String?> pickDirectory({String? dialogTitle}) async {
    if (Platform.isMacOS) {
      // macOS uses native picker for better sandboxing support
      try {
        final String? result = await platform.invokeMethod('pickDirectory');
        return result;
      } on PlatformException catch (e) {
        print("Failed to pick directory: '${e.message}'.");
        return null;
      }
    } else {
      // Other platforms use file_picker
      return await FilePicker.platform.getDirectoryPath(
        dialogTitle: dialogTitle ?? 'Select Directory',
      );
    }
  }
}
