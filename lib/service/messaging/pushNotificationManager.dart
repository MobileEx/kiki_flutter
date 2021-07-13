
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:kiki_wifi/app/globals.dart';
import 'package:kiki_wifi/service/cloudFuncs/storeFcmTokenFunc.dart';
import 'package:kiki_wifi/util/logger.dart';

class PushNotificationManager {

  StoreFcmTokenFunc _storeFcmTokenFunc;

  PushNotificationManager._() {

    _storeFcmTokenFunc = StoreFcmTokenFunc();
  }

  factory PushNotificationManager() => _instance;

  static final PushNotificationManager _instance = PushNotificationManager._();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  bool _initialized = false;

  Future<void> init() async {

    dbg.enter('PushNotificationManager.init()');

    if (!_initialized) {
      // For iOS request permission first.
      setFcmToken();
    }
  }

  /*
    public for testing
   */
  setFcmToken() async{

    _firebaseMessaging.requestNotificationPermissions();
    _firebaseMessaging.configure();

    // For testing purposes print the Firebase Messaging fcmToken
    App.deviceFcmToken = await _firebaseMessaging.getToken();
    print("FirebaseMessaging fcmToken: $App.deviceFcmToken");

    _initialized = true;

    _storeFcmTokenFunc.run(App.deviceFcmToken);
  }
}