import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kiki_wifi/app/globals.dart';
import 'package:kiki_wifi/service/payment/subscriptionPaymentService.dart';
import 'package:kiki_wifi/ui/widget/appDialogs.dart';
import 'package:kiki_wifi/ui/widget/appWidgets.dart';
import 'package:kiki_wifi/ui/widget/creditCard/appCreditCardForm.dart';
import 'package:stripe_payment/stripe_payment.dart';

class SubscriptionPaymentScreen extends StatefulWidget {
  SubscriptionPaymentScreen({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _SubscriptionPaymentScreenState createState() =>
      _SubscriptionPaymentScreenState();
}

class _SubscriptionPaymentScreenState extends State<SubscriptionPaymentScreen> {
  AppWidgets _appWidgets;
  NavCtrlWidgets _navCtrlWidgets;
  SubscriptionPaymentService _paymentService;

  AppDialogs _appDialogs;

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  @override
  initState() {
    super.initState();
    StripePayment.setOptions(
      StripeOptions(publishableKey: AppStripeCfg.PUBLISHABLE_KEY),
    );

    Function callerSetState = () {
      setState(() {});
    };

    _paymentService = SubscriptionPaymentService(callerSetState);
  }

  @override
  Widget build(BuildContext context) {
    _appWidgets = AppWidgets(context);
    _appDialogs = AppDialogs(context);
    _navCtrlWidgets = NavCtrlWidgets(context);

    return Scaffold(
      body: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            color: Colors.white,
          ),
          child: _mainLayout()),
    );
  }

  Widget _mainLayout() {
    Widget logoWidget = _appWidgets.headerLogoWidget(logoHeight: 100);

    // view header
    List<Widget> mainColWidgets = [
      logoWidget,
      Text('Kiki WiFi Subscribe', style: TextStyle(fontSize: 20)),
      _appWidgets.goBackButton(),
    ];

    if (_paymentService.errMsg.length > 0) {
      mainColWidgets.add(Text('${_paymentService.errMsg}'));
    }

    if (_paymentService.isPaymentProcessing) {
      mainColWidgets.add(CircularProgressIndicator());
    }

    if (_paymentService.isPaymentSuccessful) {
      mainColWidgets.add(_paymentSuccessBlock());
    }
    //
    else {
      Widget creditCardForm = AppCreditCardForm(
        _scaffoldKey,
        (paymentCard) {
          _paymentService.submitPayment(paymentCard);
        },
      );

      creditCardForm = _navCtrlWidgets.clearFocusHandler(
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [Expanded(child: creditCardForm)],
        ),
      );

      mainColWidgets.add(Container(height: 500, child: creditCardForm));
    }

    return _appWidgets.appScreenContainer(
      SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: mainColWidgets,
        ),
      ),
    );
  }

  _paymentSuccessBlock() {
    return Column(children: [
      Text("Subscription Created"),
      Container(height: 10),
      Text("Your payment has been process."),
      Container(height: 10),
      Text("Click Okay to go back."),
      Container(height: 20),
      FlatButton(
          child: Text("Okay"),
          onPressed: () {
            Navigator.pop(context);
          }),
    ]);
  }
}

/*
  void setError(dynamic error) {
    dbg.i('setError: $error.toString()');
    setState(() {
      _displayMsg = 'ERR:\n';
      _displayMsg += error.toString();
    });
  }
  _submitPayment() {
    dbg.enter('_submitPayment()');

    bool isFormInputValid = (CreditCardActiveRef.paymentCard != null);
    dbg.enter('isFormInputValid: $isFormInputValid');
    if (!isFormInputValid) {
      _appWidgets.showToastTopShort('Please fix errors');
      return;
    }

    dbg.i('CC# input good, submitting to stripe');
    _createSubscription();

    _isPaymentProcessing = true;
    setState(() {});
  }

  _createSubscription() async {
    dbg.enter('_createSubscription()');

    int expMo = CreditCardActiveRef.paymentCard.month;
    int expYr = CreditCardActiveRef.paymentCard.year;

    dbg.i('expMo: $expMo');
    dbg.i('expYr: $expYr');

    CreditCard userCard = CreditCard(
        number: CreditCardActiveRef.paymentCard.number,
        expMonth: expMo,
        expYear: expYr,
        cvc: CreditCardActiveRef.paymentCard.cvv.toString());

    dbg.i('userCard: ${userCard.toString()}');

    StripePayment.createPaymentMethod(
      PaymentMethodRequest(
        card: userCard,
      ),
    ).then((paymentMethod) async {
      dbg.callback(
          'createPaymentMethod, paymentMethod.id: ${paymentMethod.id}');
      dbg.callback(
          'createPaymentMethod, paymentMethod.toString(): ${paymentMethod.toString()}');
      dbg.callback('createPaymentMethod, paymentMethod: $paymentMethod');

      bool isSuccessful = await _subscriptionFunc.createSubscription(
        _userRef.mUser.uid,
        paymentMethod.id,
      );

      if (isSuccessful) {
        dbg.i('Subscription Created');

        _userRef.reloadUser();

        _appWidgets.showToastTopShort('Subscription Created');

        _isPaymentProcessing = false;
        _isPaymentSuccessful = true;

        setState(() {});

        return;
      }

      setState(() {
        _displayMsg = _subscriptionFunc.getFuncErrMsg();
      });
    }).catchError(setError);
  }
*/

//UserRef _userRef = UserRef();
//String _displayMsg = '';

// mainColWidgets.add(
//   _appWidgets.flatButtonCentered('Submit', () {
//     dbg.i('pressed Submit');
//     NavCtrlWidgets(context).dismissKeyboard();
//     _submitPayment();
//   }),
// );
