import 'package:cloud_functions/cloud_functions.dart';
import 'package:kiki_wifi/app/globals.dart';
import 'package:kiki_wifi/app/sharedPrefs.dart';
import 'package:kiki_wifi/util/logger.dart';
import 'dart:io';

class DeleteTestUsers1Func {
  final HttpsCallable _deleteTestUsers1Callable = CloudFunctions.instance
      .getHttpsCallable(functionName: 'deleteSeanUsers')
        ..timeout = const Duration(seconds: 30);

  Future<bool> run() async {
    dbg.enter('DeleteTestUsers1Func.run()');

    String msg;

    // 'token': fcmToken,
    var requestData = <String, dynamic>{};

    dbg.i('requestData: ${requestData.toString()}');

    try {
      final HttpsCallableResult result =
          await _deleteTestUsers1Callable.call(requestData);

      print('callable result.data: ${result.data}');
    } on CloudFunctionsException catch (e) {
      print('caught firebase functions exception');
      print(e.code);
      print(e.message);
      print(e.details);
    } catch (e) {
      print('caught generic exception');
      print(e);
      msg = 'Error on deleteTestUsers1() :( ';
    }

    dbg.i('$msg');

    // to chain async calls, must return a value from them
    return true;
  }
}
