// web_storage.dart
import 'dart:html' as html;

void saveToLocalStorage(String key, String value) {
  html.window.localStorage[key] = value;
}

String? getFromLocalStorage(String key) {
  return html.window.localStorage[key];
}

void clearLocalStorage() {
  html.window.localStorage.clear();
}