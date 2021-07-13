import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kiki_wifi/app/globals.dart';
import 'package:kiki_wifi/service/cloudFuncs/stripeSubscriptionFunc.dart';
import 'package:kiki_wifi/service/payment/subscriptionPaymentService.dart';
import 'package:kiki_wifi/ui/_nav/appRoutes.dart';
import 'package:kiki_wifi/ui/widget/appDialogs.dart';
import 'package:kiki_wifi/ui/widget/appWidgets.dart';
import 'package:kiki_wifi/ui/widget/creditCard/appCreditCardForm.dart';
import 'package:kiki_wifi/util/logger.dart';
// import 'package:kiki_wifi/model/ui/paymentCard.dart';

class BuyerAccountStatusScreen extends StatefulWidget {
  BuyerAccountStatusScreen({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _BuyerAccountStatusScreenState createState() =>
      _BuyerAccountStatusScreenState();
}

class _BuyerAccountStatusScreenState extends State<BuyerAccountStatusScreen> {
  UserRef _userRef = UserRef();
  AppWidgets _appWidgets;
  NavCtrlWidgets _navCtrlWidgets;

  AppDialogs _appDialogs;
  StripeSubscriptionFunc _subscriptionFunc;
  SubscriptionPaymentService _paymentService;
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  List<Widget> _mainColWidgets;

  @override
  void initState() {
    super.initState();
    Function callerSetState = () {
      setState(() {});
    };

    _paymentService = SubscriptionPaymentService(callerSetState);
  }

  @override
  Widget build(BuildContext context) {
    _appWidgets = AppWidgets(context);
    _navCtrlWidgets = NavCtrlWidgets(context);
    _appDialogs = AppDialogs(context);
    _subscriptionFunc = StripeSubscriptionFunc();

    dbg.enter(
        '_BuyerAccountStatusScreenState, userRef.isEmailVerified(): ${_userRef.isEmailVerified()}');

    Widget logoWidget = _appWidgets.headerLogoWidget(onBackButton: () async {
      await _userRef.reloadUser();
      setState(() {});
    });

    _loadStatus();

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: logoWidget,
            centerTitle: true,
          ),
          body: _mainLayout()),
    );
  }

  _loadStatus() async {
    await _subscriptionFunc.getSubscription(
      _userRef.mUser.uid,
    );
  }

  Widget _mainLayout() {
    bool isSubscriptionValid = _userRef.isSubscriptionValid();
    String status = isSubscriptionValid ? 'ACTIVE' : 'EXPIRED';

    _mainColWidgets = [
      _appWidgets.goBackButton(),
      Text('Subscription Status: $status'),
    ];

    if (isSubscriptionValid) {
      _setValidSubscriptionLayout();
    } else {
      _setUnpaidLayout();
    }

    return _appWidgets.appScreenContainer(SingleChildScrollView(
        child: Container(
            padding: EdgeInsets.all(30),
            // color: Colors.amber,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: _mainColWidgets))));
  }

  _setValidSubscriptionLayout() {
    String renewDate = _userRef.get(Field.SUBSCRIPTION_EXPIRES);

    _mainColWidgets.add(Container(height: 20));
    _mainColWidgets.add(Text('Renewal Date: $renewDate'));
    _mainColWidgets.add(Container(height: 20));
    _mainColWidgets.add(_appWidgets.appNavLink('Cancel Subscription', () {
      dbg.i('cloudFunc: Cancel Sbcrptn');
      _appWidgets.showToastTopShort('Pending');
    }));
    _mainColWidgets.add(Container(height: 20));
  }

  _setUnpaidLayout() {
    _mainColWidgets.add(_appWidgets.appNavLink('Start Subscription', () async {
      // await showSubscriptionPaymentDialog();
      Navigator.pushNamed(context, AppRoute.SubscriptionPayment)
          .then((_) async {
        await _userRef.reloadUser();
        setState(() {});
      });
    }));
  }

  showSubscriptionPaymentDialog() async {
    Column cardCol = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[

      ],
    );

    if (_paymentService.errMsg.length > 0) {
      cardCol.children.add(Text('${_paymentService.errMsg}'));
    }

    if (_paymentService.isPaymentSuccessful) {
      cardCol.children.add(Text('Payment Successful'));
    }
    else {

      Widget creditCardForm = Container(
        child: AppCreditCardForm(
          _scaffoldKey,
          (paymentCard) {
            dbg.callback('_onCreditCardSubmit() handler');

            _paymentService.submitPayment(paymentCard);
          },
        ),
      );

      cardCol.children.add(creditCardForm);
    }

    if (_paymentService.isPaymentProcessing) {
      cardCol.children.add(CircularProgressIndicator());
    }

    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10.0))),
            title: Center(child: Text("Subscribe to Kiki \$30/mo. ")),
            content: cardCol,
          );
        });
  }
}
//            actions: [
//              FlatButton(
//                child: Text("Pay Now"),
//                onPressed: () {
//                  // Go
//                },
//              ),
//            ],

/*


      Widget creditCardForm = AppCre ditCardForm(
        _scaffoldKey,
        onCreditCardSubmit: () {
          _paymentService.submitPayment(CreditCardActiveRef.paymentCard);
        },
      );

      creditCardForm = _navCtrlWidgets.clearFocusHandler(
        Expanded(child: creditCardForm),
      );

      _mainColWidgets.add(Container(height: 500, child: creditCardForm));

//  Navigator.pushNamed(context, AppRoute.SubscriptionPayment)
//      .then((_) async {
//    await _userRef.reloadUser();
//    setState(() {});
//  });


*/
