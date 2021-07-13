import 'package:cloud_functions/cloud_functions.dart';
import 'package:kiki_wifi/util/logger.dart';

class StripeSubscriptionFunc {
  // Subscription Price ID from Stripe Account: Kiki WiFi
  // static final String SUBSCRIPTION_PRICE_ID = 'price_1HhISBKe4BM2E8In2xsFXGUD';
  static final String SUBSCRIPTION_PRICE_ID = 'price_1HvnfeKe4BM2E8InQo55Iuww';

  dynamic _funcErr;

  final HttpsCallable _createSubscriptionCallable = CloudFunctions.instance
      .getHttpsCallable(functionName: 'createSubscription')
        ..timeout = const Duration(seconds: 30);

  final HttpsCallable _listSubscriptionsCallable = CloudFunctions.instance
      .getHttpsCallable(functionName: 'listSubscriptions')
        ..timeout = const Duration(seconds: 30);

  String getFuncErrMsg() {
    String funcErrMsg = _funcErr.toString();

    if (_funcErr is CloudFunctionsException) {
      _funcErr += 'ErrCode: ${_funcErr.code} ';
      _funcErr += ', \n';
      _funcErr += ', \n';
      _funcErr += _funcErr.message;
      _funcErr += ', \n';
      _funcErr += ', \n';
      _funcErr += 'DETAILS: ';
      _funcErr += _funcErr.details;
    }
    return funcErrMsg;
  }

  /*
  From Web UI:
            const createSubscription = firebase.functions().httpsCallable('createSubscription');
            const result = await createSubscription({
                userId: currentUser.uid,
                plan: PRICE_ID,
                payment_method: paymentMethod.id
            });

   */
  Future<bool> createSubscription(String userId, String paymentMethodId) async {
    dbg.enter('createSubscription');

    String toastMsg;

    Map<String, dynamic> funcParams = <String, dynamic>{
      'userId': userId,
      'plan': SUBSCRIPTION_PRICE_ID,
      'payment_method': paymentMethodId,
    };

    dbg.i('funcParams: $funcParams');

    try {
      final HttpsCallableResult result =
          await _createSubscriptionCallable.call(funcParams
              // <String, dynamic>{
              //   'userId': userId,
              //   'plan': SUBSCRIPTION_PRICE_ID,
              //   'payment_method': paymentMethodId,
              // },
              );
      print('callable result.data: ${result.data}');
      toastMsg = 'Subscription Created';
    } on CloudFunctionsException catch (e) {
      _funcErr = e;
      print('caught firebase functions exception');
      print(e.code);
      print(e.message);
      print(e.details);
    } catch (e) {
      _funcErr = e;
      print('caught generic exception');
      print(e);
      toastMsg = 'Error on createSubscription :( ';
    }

    // No toast for now, just showing confirmation dialog
    // _appWidgets.showToastTopShort(toastMsg);

    dbg.i('$toastMsg');

    bool isSuccessful = (_funcErr == null);

    // to chain async calls, must return a value from them
    return isSuccessful;
  }

  Future<bool> getSubscription(String userId) async {
    dbg.enter('getSubscription');

    String toastMsg;

    Map<String, dynamic> funcParams = <String, dynamic>{
      'userId': userId,
    };

    dbg.i('funcParams: $funcParams');

    try {
      final HttpsCallableResult result =
          await _listSubscriptionsCallable.call(funcParams);
      print('getSubscription callable result.data: ${result.data}');
    } on CloudFunctionsException catch (e) {
      print('caught firebase functions exception');
      print(e.code);
      print(e.message);
      print(e.details);
    } catch (e) {
      print('caught generic exception');
      print(e);
      toastMsg = 'Error on createSubscription :( ';
    }

    // No toast for now, just showing confirmation dialog
    // _appWidgets.showToastTopShort(toastMsg);

    dbg.i('$toastMsg');

    // to chain async calls, must return a value from them
    return true;
  }
}
