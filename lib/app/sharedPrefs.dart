import 'package:kiki_wifi/util/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';


class AppData {
  static final String isFirebaseDelUserOn = 'isFirebaseDelUserOn';
  static final String appName = 'appName';

  // Dev Fields
  static final String buyerEmail = 'buyerEmail';
  static final String sellerEmail = 'sellerEmail';

  static Map<String, dynamic> _appDataMap = {};

  static dynamic get(String key) {
    return _appDataMap[key];
  }

  /*
  Saves to SharedPrefs on call/update
   */
  static set(String key, dynamic value) {
    _appDataMap[key] = value;

    SharedPrefs.saveAppDataMap(_appDataMap);
  }
}

class SharedPrefs {
  static const String KEY_LAST_KNOWN_TEXT = 'LastKnownText';
  static final String KEY_APP_DATA_MAP = 'AppDataMap';

  static String lastKnownText;

  static saveAppDataMap(Map appDataMap) async {
    dbg.enter('saveAppDataMap');

    // serialize
    String appDataStr = json.encode(appDataMap);

    final prefs = await SharedPreferences.getInstance();
    prefs.setString(KEY_APP_DATA_MAP, appDataStr);
  }

  static setLastKnownText(String updateValue) async {
    dbg.enter('setAppName');
    lastKnownText = updateValue;

    final prefs = await SharedPreferences.getInstance();
    prefs.setString(KEY_LAST_KNOWN_TEXT, updateValue);
  }

  static loadSharedPrefsData() async {
    final prefs = await SharedPreferences.getInstance();

    SharedPrefs.lastKnownText = prefs.getString(KEY_LAST_KNOWN_TEXT) ?? '';
  }
}
