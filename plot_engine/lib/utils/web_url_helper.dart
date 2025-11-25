// Web implementation
import 'dart:html' as html;

Uri? getCurrentUrl() {
  try {
    return Uri.parse(html.window.location.href);
  } catch (e) {
    return null;
  }
}

void reloadPage() {
  html.window.location.href = '/';
}
