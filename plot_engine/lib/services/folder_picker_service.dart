import 'package:flutter/services.dart';

class FolderPickerService {
  static const platform = MethodChannel('com.plotengine.folder_picker');

  static Future<String?> pickDirectory() async {
    try {
      final String? result = await platform.invokeMethod('pickDirectory');
      return result;
    } on PlatformException catch (e) {
      print("Failed to pick directory: '${e.message}'.");
      return null;
    }
  }
}
