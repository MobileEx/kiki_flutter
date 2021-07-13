import 'package:cloud_functions/cloud_functions.dart';
import 'package:kiki_wifi/util/logger.dart';

class ResendVerificationEmailFunc {
  final HttpsCallable _registerInterestCallable = CloudFunctions.instance
      .getHttpsCallable(functionName: 'resendVerificationEmail')
        ..timeout = const Duration(seconds: 30);

  Future<bool> run() async {
    dbg.enter('ResendVerificationEmailFunc().run()');

    String msg;

    try {
      final HttpsCallableResult result = await _registerInterestCallable.call(
        <String, dynamic>{},
      );

      print('callable result.data: ${result.data}');
    } on CloudFunctionsException catch (e) {
      print('caught firebase functions exception');
      print(e.code);
      print(e.message);
      print(e.details);
    } catch (e) {
      print('caught generic exception');
      print(e);
      msg = 'Error sending email :( ';
    }

    dbg.i('$msg');

    // to chain async calls, must return a value from them
    return true;
  }
}

/*

  // No toast for now, just showing confirmation dialog
  // _appWidgets.showToastTopShort(toastMsg);

//  AppWidgets _appWidgets;
//  static final int BUYER_SIGNUP_WELCOME = 1;
//  static final int SELLER_SIGNUP_WELCOME = 2;
//    _appWidgets = AppWidgets(_ctxt);

  sendBuyerSignUpWelcome(String recipientEmail) async {
    return await _resendVerificationEmail(BUYER_SIGNUP_WELCOME, recipientEmail);
  }

  sendSellerSignUpWelcome(String recipientEmail) async {
    return await _resendVerificationEmail(SELLER_SIGNUP_WELCOME, recipientEmail);
  }
*/
//  @override
//  Widget build(BuildContext context) {
//    _appWidgets = AppWidgets(context);
//
//    Widget bodyMain = _mainLayout();
//
//    Scaffold scaffold = Scaffold(
//      appBar: AppBar(title: Text('SendEmailCloudFunc Screen')),
//      body: bodyMain,
//    );
//
//    return scaffold;
//  }
//  Widget _mainLayout() {
//    return _appWidgets.appScreenContainer(SingleChildScrollView(
//      child: Column(
//        children: [
//          TextFormField(
//            initialValue: SharedPrefs.lastKnownText,
//            controller: _emailController,
//            decoration: InputDecoration(
//              labelText: "Email Address",
//            ),
//          ),
//          _appWidgets.appNavLink('Call sendEmail cloudFunc', () {
//            _resendVerificationEmail();
//          }),
//        ],
//      ),
//    ));
//  }
