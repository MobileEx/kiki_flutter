import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:kiki_wifi/main.dart';
import 'package:kiki_wifi/util/dataUtil.dart';
import 'package:kiki_wifi/util/logger.dart';

DocumentSnapshot userSnapshot;
DocumentSnapshot sellerWiFiDetails;
DocumentSnapshot sellerWiFiSpeed;
User fireAuthUser;

class App {
  static String deviceFcmToken;

  static bool isDebugMode() {
    return RunMode.IS_DEBUG_ON;
  }

  static bool isProductionMode() {
    bool isProductionMode = !isDebugMode();
    return isProductionMode;
  }
}

class AppStripeCfg {
  // static const String PUBLISHABLE_KEY =
  //     'pk_test_51HgC0eKe4BM2E8Ini22asgHj76JCDaUmNuIlEs4IUDjWKMCO3qhegaSNjKget0HKNiSlaJdcNRm1n8G8dXXlfcHT00iU4H0ect';
  static const String PUBLISHABLE_KEY =
      'pk_live_51HgC0eKe4BM2E8InGxvJe1fBCFlQMJlkw8qDjPpuwliClupMkOd9vvPcCm7j6qjGDd70shbGrpo6bLfwCU1oiURl00xTI4JWo2';
}

class Const {
  static const String APP_NAME = 'Kiki Wifi';
}

class Field {
  static const String SSID = 'ssid';
  static const String TRIAL = 'trial';
  static const String CREATED = 'created';
  static const String PASSWORD = 'password';
  static const String OWNER = 'owner';
  static const String EMAIL = 'email';
  static const String MESSAGE = 'message';
  static const String DEVICE_TYPE = 'deviceType';
  static const String POS = 'pos'; // geocodePosition
  static const String SUBSCRIPTION_EXPIRES = 'subscriptionExpires';
  static const String FCM_TOKEN = 'fcmToken';
  static const String DEVICE_FCM_TOKENS = 'deviceFcmTokens';
}

class Collctn {
  static const String NETWORKS = 'networks';
  static const String PASSWORDS = 'passwords';
  static const String MAILING_LIST = 'mailing-list';
  static const String USERS = 'users';

  Future<String> clearAllCollections() async {
    String result = '';
    result += await clearFirestore(NETWORKS);
    result += await clearFirestore(PASSWORDS);
    result += await clearFirestore(MAILING_LIST);
    result += await clearFirestore(USERS);

    dbg.i('\n\n\n\n allToStdout '
        '$result'
        '\n\n\n\n  END  allToStdout \n\n\n\n ');

    return result;
  }

  allToStdout() async {
    dbg.i('\n\n\n\n allToStdout ');
    CollectionReference collctnRef;
    toStdout(NETWORKS);
    toStdout(PASSWORDS);
    toStdout(MAILING_LIST);
    toStdout(USERS);
    dbg.i('\n\n\n\n  END  allToStdout \n\n\n\n ');
  }

  Future<String> clearFirestore(String collctnName) async {
    String result = '\n\n\n';
    result += '============================';
    result += '\n clearFirstore: $collctnName:';

    QuerySnapshot collctnRef =
        await FirebaseFirestore.instance.collection(collctnName).get();
    for (int i = 0; i < collctnRef.docs.length; i++) {
      result += '\n\n';
      QueryDocumentSnapshot docQDS = collctnRef.docs[i];
      await docQDS.reference.delete();
    }
    result += '\n\n\n\n';

    return result.trim();
  }

  toStdout(String collctnName) async {
    String result = '\n\n\n';
    result += '============================';
    result += '\n $collctnName:';

    QuerySnapshot collctnRef =
        await FirebaseFirestore.instance.collection(collctnName).get();
    for (int i = 0; i < collctnRef.docs.length; i++) {
      result += '\n\n';
      QueryDocumentSnapshot docQDS = collctnRef.docs[i];
      String doc = docQDS.data().toString();
      result += doc.toString();
      result += '\n\n';

      FirebaseFirestore.instance
          .collection('zBak')
          .doc('${collctnName}_${docQDS.id}')
          .set(docQDS.data());
    }
    result += '\n\n\n\n';

    dbg.i(result);
  }
}

class UserRef {
  static User _mUser;
  static DocumentSnapshot _mUserSnapshot;
  static Map<String, dynamic> _userDataMap = {};

  User get mUser => _mUser;

  DocumentSnapshot get mUserSnapshot => _mUserSnapshot;

  reloadUser() async {
    await fireAuthUser.reload();

    await setUser();
  }

  updateUser(Map<String, dynamic> updateFields) async {
    dbg.enter('updateUser, updateFields: $updateFields');

    await FirebaseFirestore.instance
        .collection(Collctn.USERS)
        .doc(mUser.uid)
        .update(updateFields);
  }

  deleteAccount() async {
    await userSnapshot.reference.delete();
    await sellerWiFiDetails.reference.delete();
    await sellerWiFiSpeed.reference.delete();
    await fireAuthUser.delete();
  }

  dynamic get(String fieldName) {
    dynamic value = _userDataMap[fieldName];
    return value;
  }

  bool hasField(String fieldName) {
    dynamic value = get(fieldName);
    bool hasField = (value != null);
    return hasField;
  }

  bool _isTrialActive() {
    bool isTrialActive = !hasTrialExpired();

    return isTrialActive;
  }

  /*
      int remainingTrialDays = userSnapshot
        .get('created')
   */

  bool isEmailVerified() {
    bool isEmailVerified = _mUser.emailVerified;

    // uncomment for testing
    // isEmailVerified = true;

    return isEmailVerified;
  }

  bool isWifiAccessValid() {
    bool isWifiAccessValid = (_isTrialActive() || isSubscriptionValid());

    return isWifiAccessValid;
  }

  bool isSubscriptionValid() {
    bool isSubscriptionValid;

    String expiresTimeStr = get(Field.SUBSCRIPTION_EXPIRES);
    dbg.i('expiresTimeStr: $expiresTimeStr');

    if (expiresTimeStr != null) {
      //   static final dateFormat6 = new DateFormat('M/d/yyyy, h:mm a');
      DateFormat format = new DateFormat("M/d/yyyy h:mm:ss a");
      expiresTimeStr =
          expiresTimeStr.replaceFirst(' pm', ' PM').replaceFirst(' am', ' AM');

      DateTime expiresTime = format.parse(expiresTimeStr);

      isSubscriptionValid = DateUtil.isInFuture(expiresTime);
    }

    return isSubscriptionValid ?? false;
  }

  bool hasTrialExpired() {
    int remainingTrialDays = getRemainingTrialDays();

    bool hasTrialEnded = remainingTrialDays < 0;

    return hasTrialEnded;
  }

  int getRemainingTrialDays() {
    Timestamp createdStr = get('created');
    int remainingTrialDays = createdStr
        .toDate()
        .add(Duration(days: 3))
        .difference(DateTime.now())
        .inDays;

    remainingTrialDays += 1;

    return remainingTrialDays;
  }

  // {bool isSeller = true}
  Future<void> setUser() async {
    dbg.enter('setUser()');

    _mUser = await FirebaseAuth.instance.currentUser;
    fireAuthUser = _mUser;

    _mUserSnapshot = await FirebaseFirestore.instance
        .collection(Collctn.USERS)
        .doc(fireAuthUser.uid)
        .get();

    userSnapshot = _mUserSnapshot;

    _userDataMap = _mUserSnapshot.data();

    dbg.i('getUser(), fireAuthUser: $fireAuthUser');
    dbg.i('_userDataMap: $_userDataMap');

    _verifyDeviceFcmTokenIsSetForUser();

    bool isSeller = this.hasField('network');
    // isSeller &&
    // if (this.hasField('network')) {
    if (isSeller) {
      await _setSellerWiFi();
    }

    return;
  }

  _verifyDeviceFcmTokenIsSetForUser() async {
    List userDeviceFcmTokens = get(Field.DEVICE_FCM_TOKENS);

    bool isTokenUserSet =
        (userDeviceFcmTokens?.contains(App.deviceFcmToken) ?? false);

    if (!isTokenUserSet) {
      await FirebaseFirestore.instance
          .collection(Collctn.USERS)
          .doc(fireAuthUser.uid)
          .set(
        {
          Field.DEVICE_FCM_TOKENS: [App.deviceFcmToken]
        },
        SetOptions(merge: true),
      );
    }
  }

  _setSellerWiFi() async {
    // passwords: this is a PROVIDER user: ssid, pwd, users list
    QuerySnapshot sellerPasswordQS = await FirebaseFirestore.instance
        .collection('passwords')
        .where('owner', isEqualTo: fireAuthUser.uid)
        .get();

    sellerWiFiDetails = sellerPasswordQS.docs.first;

    // networks: geocode, users list
    QuerySnapshot sellerNetworkQS = await FirebaseFirestore.instance
        .collection('networks')
        .where('owner', isEqualTo: fireAuthUser.uid)
        .get();

    sellerWiFiSpeed = sellerNetworkQS.docs.first;
  }
}
