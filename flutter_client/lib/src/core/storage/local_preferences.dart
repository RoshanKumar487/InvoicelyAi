import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalPreferences {
  LocalPreferences({required this.scope});

  final String scope;

  String _key(String name) => 'invoicely.$scope.$name';

  Future<Map<String, Object?>> readMap(String name) async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(_key(name));
    if (value == null) return <String, Object?>{};
    final decoded = jsonDecode(value);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Saved local settings are invalid.');
    }
    return Map<String, Object?>.from(decoded);
  }

  Future<void> writeMap(String name, Map<String, Object?> value) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(_key(name), jsonEncode(value));
    if (!saved) {
      throw StateError('Could not persist local settings.');
    }
  }

  Future<String?> readString(String name) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_key(name));
  }

  Future<void> writeString(String name, String value) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(_key(name), value);
    if (!saved) throw StateError('Could not persist local settings.');
  }

  Future<void> remove(String name) async {
    final preferences = await SharedPreferences.getInstance();
    final removed = await preferences.remove(_key(name));
    if (!removed) throw StateError('Could not remove saved local settings.');
  }
}
