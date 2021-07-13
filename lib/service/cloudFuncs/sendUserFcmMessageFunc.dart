import 'package:cloud_functions/cloud_functions.dart';
import 'package:kiki_wifi/app/globals.dart';
import 'package:kiki_wifi/app/sharedPrefs.dart';
import 'package:kiki_wifi/util/logger.dart';
import 'dart:io';

class SendUserFcmMessageFunc {
  final HttpsCallable _sendUserFcmMessageCallable = CloudFunctions.instance
      .getHttpsCallable(functionName: 'sendUserFcmMessage')
        ..timeout = const Duration(seconds: 30);

  Future<bool> run(String message) async {
    dbg.enter('SendUserFcmMessageFunc.run()');

    dbg.i('message: $message');

    String msg;

    // 'token': fcmToken,
    var requestData = <String, dynamic>{
      Field.MESSAGE: message,
    };

    dbg.i('requestData: ${requestData.toString()}');

    try {
      final HttpsCallableResult result =
          await _sendUserFcmMessageCallable.call(requestData);

      print('callable result.data: ${result.data}');
    } on CloudFunctionsException catch (e) {
      print('caught firebase functions exception');
      print(e.code);
      print(e.message);
      print(e.details);
    } catch (e) {
      print('caught generic exception');
      print(e);
      msg = 'Error on sendUserFcmMessage() :( ';
    }

    dbg.i('$msg');

    // to chain async calls, must return a value from them
    return true;
  }
}
