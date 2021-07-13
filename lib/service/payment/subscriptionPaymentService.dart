import 'package:kiki_wifi/app/globals.dart';
import 'package:kiki_wifi/model/ui/paymentCard.dart';
import 'package:kiki_wifi/service/cloudFuncs/stripeSubscriptionFunc.dart';
import 'package:kiki_wifi/util/logger.dart';
import 'package:stripe_payment/stripe_payment.dart';

class SubscriptionPaymentService {
  StripeSubscriptionFunc _subscriptionFunc;

  PaymentCard _paymentCard;

  String _errMsg = '';

  UserRef _userRef = UserRef();

  bool _isPaymentProcessing = false;
  bool _isPaymentSuccessful = false;

  Function _callerSetState; // for setState(() {}); from caller
  SubscriptionPaymentService(this._callerSetState) {
    _subscriptionFunc = StripeSubscriptionFunc();
  }

  bool get isPaymentProcessing => _isPaymentProcessing;

  bool get isPaymentSuccessful => _isPaymentSuccessful;

  String get errMsg => _errMsg;

  submitPayment(PaymentCard paymentCard) {
    _paymentCard = paymentCard;

    dbg.enter('_submitPayment()');

    bool isFormInputValid = (_paymentCard != null);
    dbg.enter('isFormInputValid: $isFormInputValid');
    if (!isFormInputValid) {
      // do nothing for setState(..) because UI already updated
      return;
    }

    _isPaymentProcessing = true;

    dbg.i('CC# input good, submitting to stripe');
    _createSubscription();

    // we need to call this in order to show Progress Spinner
    _callerSetState(); // setState(() {});
  }

  _createSubscription() async {
    dbg.enter('_createSubscription()');

    int expMo = _paymentCard.month;
    int expYr = _paymentCard.year;

    dbg.i('expMo: $expMo');
    dbg.i('expYr: $expYr');

    CreditCard userCard = CreditCard(
        number: _paymentCard.number,
        expMonth: expMo,
        expYear: expYr,
        cvc: _paymentCard.cvv.toString());

    dbg.i('userCard: ${userCard.toString()}');

    return StripePayment.createPaymentMethod(
      PaymentMethodRequest(
        card: userCard,
      ),
    ).then((paymentMethod) async {
      dbg.callback('createPaymentMethod())');
      dbg.i('paymentMethod.id: ${paymentMethod.id}');
      dbg.i('paymentMethod.toString(): ${paymentMethod.toString()}');
      dbg.i('paymentMethod: $paymentMethod');

      bool isSuccessful = await _subscriptionFunc.createSubscription(
        _userRef.mUser.uid,
        paymentMethod.id,
      );

      if (isSuccessful != true) {
        _errMsg = _subscriptionFunc.getFuncErrMsg();
      } else {
        dbg.i('Subscription Created');

        _userRef.reloadUser();
        _isPaymentSuccessful = true;
      }
      _isPaymentProcessing = false;
      _callerSetState();
    }).catchError((e) {
      setError(e);
    });
  }

  void setError(dynamic error) {
    dbg.i('setError: $error.toString()');
    _errMsg = 'ERR:\n';
    _errMsg += error.toString();
    _isPaymentProcessing = false;
    _isPaymentSuccessful = false;
    _callerSetState(); // setState(() {});
  }
}
