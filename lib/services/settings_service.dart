import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';

class SettingsService extends ChangeNotifier {
  static const String _keyDbfPath = 'dbf_path';
  static const String _keyAccessDbPath = 'access_db_path';
  static const String _keyDbfEncoding = 'dbf_encoding';
  static const String _keyItemsPerPage = 'items_per_page';

  AppSettings _settings = const AppSettings(
    dbfPath: '',
    accessDbPath: '',
  );

  AppSettings get settings => _settings;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    String dbfPath = prefs.getString(_keyDbfPath) ?? '';
    String accessPath = prefs.getString(_keyAccessDbPath) ?? '';
    final encoding = prefs.getString(_keyDbfEncoding) ?? 'CP1252';
    final itemsPerPage = prefs.getInt(_keyItemsPerPage) ?? 25;

    // Check default sample paths if empty
    if (dbfPath.isEmpty) {
      final sampleDbf = File(r'd:\DEV\maj_ged\sample_ged.dbf');
      if (sampleDbf.existsSync()) {
        dbfPath = sampleDbf.path;
      }
    }

    if (accessPath.isEmpty) {
      final sampleAccess = File(r'd:\DEV\maj_ged\test_access.accdb');
      if (sampleAccess.existsSync()) {
        accessPath = sampleAccess.path;
      }
    }

    _settings = AppSettings(
      dbfPath: dbfPath,
      accessDbPath: accessPath,
      dbfEncoding: encoding,
      itemsPerPage: itemsPerPage,
    );
    notifyListeners();
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDbfPath, newSettings.dbfPath);
    await prefs.setString(_keyAccessDbPath, newSettings.accessDbPath);
    await prefs.setString(_keyDbfEncoding, newSettings.dbfEncoding);
    await prefs.setInt(_keyItemsPerPage, newSettings.itemsPerPage);
    notifyListeners();
  }

  Future<void> setDbfPath(String path) async {
    await updateSettings(_settings.copyWith(dbfPath: path));
  }

  Future<void> setAccessDbPath(String path) async {
    await updateSettings(_settings.copyWith(accessDbPath: path));
  }
}
