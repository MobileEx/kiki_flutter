import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kiki_wifi/app/globals.dart';
import 'package:kiki_wifi/service/cloudFuncs/stripeSubscriptionFunc.dart';
import 'package:kiki_wifi/ui/widget/appWidgets.dart';
import 'package:kiki_wifi/util/logger.dart';
import 'package:stripe_payment/stripe_payment.dart';

class DevCreditCardScreen extends StatefulWidget {
  DevCreditCardScreen({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _DevCreditCardScreenState createState() => _DevCreditCardScreenState();
}

class _DevCreditCardScreenState extends State<DevCreditCardScreen> {
  bool _loaded = false;
  AppWidgets _appWidgets;
  StripeSubscriptionFunc _subscriptionFunc;

  UserRef _userRef = UserRef();

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  PaymentMethod _paymentMethod;
  String _error;

  @override
  initState() {
    super.initState();
    StripePayment.setOptions(
      StripeOptions(
        publishableKey:
            'pk_test_51HgC0eKe4BM2E8Ini22asgHj76JCDaUmNuIlEs4IUDjWKMCO3qhegaSNjKget0HKNiSlaJdcNRm1n8G8dXXlfcHT00iU4H0ect',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _appWidgets = AppWidgets(context);
    _subscriptionFunc = StripeSubscriptionFunc();

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

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        logoWidget,
        _appWidgets.goBackButton(),
        Text('CC# Input Here'),
        // _ccInput1(),
        _ccInput2(),
      ],
    );
  }

  final CreditCard testCard = CreditCard(
      // number: '4000002760003184',
      number: '4242424242424242',
      expMonth: 12,
      expYear: 25,
      cvc: '321');

  Widget _ccInput1() {
    return RaisedButton(
      child: Text("Create Payment Method with Card"),
      onPressed: () {
        dbg.i('onPressed: ${testCard.toString()}');

        StripePayment.createPaymentMethod(
          PaymentMethodRequest(
            card: testCard,
          ),
        ).then((paymentMethod) async {
          dbg.i(
              'callback for : createPaymentMethod, paymentMethod.id: ${paymentMethod.id}');
          dbg.i(
              'callback for : createPaymentMethod, paymentMethod.toString(): ${paymentMethod.toString()}');
          dbg.i(
              'callback for : createPaymentMethod, paymentMethod: $paymentMethod');

          await _subscriptionFunc.createSubscription(
            _userRef.mUser.uid,
            paymentMethod.id,
          );

          dbg.i('Subscription Created');

          // _scaffoldKey.currentState
          //     .showSnackBar(SnackBar(content: Text('Subscription Created')));
        }).catchError(setError);
      },
    );
  }

  Widget _ccInput2() {
    return RaisedButton(
      child: Text("Create Token with Card Form"),
      onPressed: () {
        StripePayment.paymentRequestWithCardForm(CardFormPaymentRequest())
            .then((paymentMethod) async {
          dbg.i(
              'callback for : paymentRequestWithCardForm, paymentMethod.id: ${paymentMethod.id}');
          dbg.i(
              'callback for : paymentRequestWithCardForm, paymentMethod.toString(): ${paymentMethod.toString()}');
          dbg.i(
              'callback for : paymentRequestWithCardForm, paymentMethod: $paymentMethod');

          var result = await _subscriptionFunc.createSubscription(
            _userRef.mUser.uid,
            paymentMethod.id,
          );

          dbg.i('Subscription Created, result: $result');
        }).catchError(setError);
      },
    );
  }

  void setError(dynamic error) {
    dbg.i('setError: $error.toString()');
    setState(() {
      _error = error.toString();
    });
  }
}

/*
    _scaffoldKey.currentState
        .showSnackBar(SnackBar(content: Text(error.toString())));

          // _scaffoldKey.currentState.showSnackBar(SnackBar(
          //     content: Text('callback for : paymentRequestWithCardForm')));

              _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text('Received ${paymentMethod.id}')));
              setState(() {
                _paymentMethod = paymentMethod;
              });

//          _scaffoldKey.currentState.showSnackBar(
//              SnackBar(content: Text('Received ${paymentMethod.id}')));
//          setState(() {
//            _paymentMethod = paymentMethod;
//          });
*/
