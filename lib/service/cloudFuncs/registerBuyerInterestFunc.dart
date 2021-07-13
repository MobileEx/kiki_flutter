import 'package:cloud_functions/cloud_functions.dart';
import 'package:kiki_wifi/app/globals.dart';
import 'package:kiki_wifi/app/sharedPrefs.dart';
import 'package:kiki_wifi/util/logger.dart';

/*
Expects:
    {
    "email": recipientEmail,
    "pos": [
    _pos.latitude,
    _pos.longitude,
    ],
    }
    
 */
class RegisterBuyerInterestFunc {
  final HttpsCallable _registerInterestCallable = CloudFunctions.instance
      .getHttpsCallable(functionName: 'registerBuyerInterest')
        ..timeout = const Duration(seconds: 30);

  Future<bool> run(String recipientEmail, latLonArr) async {
    dbg.i('recipientEmail: $recipientEmail');
    SharedPrefs.setLastKnownText(recipientEmail);

    String msg;

    try {
      final HttpsCallableResult result = await _registerInterestCallable.call(
        <String, dynamic>{
          Field.EMAIL: recipientEmail,
          Field.POS: [
            latLonArr.latitude,
            latLonArr.longitude,
          ],
        },
      );
      print('callable result.data: ${result.data}');
      msg = 'Email was sent to: $recipientEmail';
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
    return await _registerBuyerInterest(BUYER_SIGNUP_WELCOME, recipientEmail);
  }

  sendSellerSignUpWelcome(String recipientEmail) async {
    return await _registerBuyerInterest(SELLER_SIGNUP_WELCOME, recipientEmail);
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
//            _registerBuyerInterest();
//          }),
//        ],
//      ),
//    ));
//  }
