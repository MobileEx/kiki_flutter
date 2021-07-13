import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kiki_wifi/app/globals.dart';
import 'package:kiki_wifi/service/payment/subscriptionPaymentService.dart';
import 'package:kiki_wifi/ui/_nav/appRoutes.dart';
import 'package:kiki_wifi/ui/screen/dashboard/sellerDashboard.dart';
import 'package:kiki_wifi/ui/style/appScale.dart';
import 'package:kiki_wifi/ui/widget/appDialogs.dart';
import 'package:kiki_wifi/ui/widget/appWidgets.dart';
import 'package:kiki_wifi/ui/widget/creditCard/appCreditCardForm.dart';
import 'package:kiki_wifi/util/dataUtil.dart';
import 'package:kiki_wifi/util/logger.dart';
import 'package:kiki_wifi/util/wifiUtil.dart';
import 'package:wifi_connect/wifi_connect.dart';

class BuyerDashboardScreen extends StatefulWidget {
  BuyerDashboardScreen({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _BuyerDashboardScreenState createState() => _BuyerDashboardScreenState();
}

class _BuyerDashboardScreenState extends State<BuyerDashboardScreen> {
  bool _connecting = false;
  UserRef _userRef = UserRef();
  AppWidgets _appWidgets;
  AppDialogs _appDialogs;
  WifiUtil _wifiUtil;
  SubscriptionPaymentService _paymentService;

  bool _isTrialChecked = false;

  var _scaffoldKey = new GlobalKey<ScaffoldState>();

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
    _appDialogs = AppDialogs(context);
    _wifiUtil = WifiUtil(context);

    if (!_isTrialChecked) {
      _isTrialChecked = true;
      _checkTrialAndSubscription();
    }

    dbg.enter(
        '_BuyerDashboardScreenState, userRef.isEmailVerified(): ${_userRef.isEmailVerified()}');

    Widget logoWidget = _appWidgets.headerLogoWidget(
      onBackButton: () async {
        await _userRef.reloadUser();
        setState(() {});
      },
      logoWidth: MediaQuery.of(context).size.width / 2,
      logoHeight: null,
    );

    // _connecting = false;
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: logoWidget,
            centerTitle: true,
            elevation: 0,
            toolbarHeight: 100,
          ),
          backgroundColor: Colors.white,
          body: _userRef.hasField('network')
              ? SellerDashboardScreen()
              : _mainLayout()),
    );
  }

  _checkTrialAndSubscription() async {
    if (_userRef.isWifiAccessValid()) {
      return;
    }

    // TODO: Show button, Redirect to subscribe view
    await _wifiUtil.removeUserTrialAccess();

    _appDialogs.showTrialEnded();
  }

  _reconnectWifi() async {
    try {
      setState(() {
        _connecting = true;
      });

      await _wifiUtil.connect();
    } catch (err) {
      String errMsg = (err is WifiConnectException)
          ? err.status.toString()
          : err.toString();

      _appDialogs.showError(errMsg);
    }

    _connecting = false;
    setState(() {});
  }

  Widget _mainLayout() {
    List<Widget> block1Widgets = [];

    block1Widgets.add(_appWidgets.sectionHeader2(
      'Logged in as:',
      fontSize: null,
      fontWeight: null,
    ));

    String userName = _userRef.get('name');
    if (userName != null) {
      block1Widgets.add(_appWidgets.centerText1(
        userName,
        color: Colors.blue[700],
        fontWeight: FontWeight.w600,
      ));
    }

    block1Widgets.add(_appWidgets.centerText1(
      _userRef.mUser.email,
      color: Colors.blue[700],
      fontWeight: FontWeight.w600,
    ));

    if (!_userRef.isEmailVerified()) {
      //TODO
      Widget verifyEmailBlock = _appWidgets.verifyEmailBlock(
        () {
          setState(() {});
        },
        margin: EdgeInsets.symmetric(horizontal: 60, vertical: 10),
        buttonColor: Colors.blue[700],
        borderRadius: 10,
        fontSize: AppScale(context).verificationBlockButtonFontSize,
        fontButtonColor: Colors.white,
        padding: EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 12,
        ),
        hasButtonBar: true,
        color: Colors.yellow[100],
        boxShadow: BoxShadow(color: Colors.black45, spreadRadius: 1),
        messageTextColor: Colors.black87,
      );
      block1Widgets.add(verifyEmailBlock);
    } else {
      Widget reconnectButton = _connecting
          ? Center(child: CircularProgressIndicator())
          : _reconnectButtonWrapper(
              RaisedButton(
                child: Text(
                  "Reconnect".toUpperCase(),
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () async {
                  _reconnectWifi();
                },
                color: Colors.blue,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 32),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );

      block1Widgets.add(reconnectButton);
    }

    List<Widget> mainColWidgets = [];

    if (_userRef.isWifiAccessValid()) {
      mainColWidgets.add(_appWidgets.columnWrapper(block1Widgets,
          boxShadow: BoxShadow(
            color: Colors.white10,
          ),
          padding: EdgeInsets.zero,
          margin: EdgeInsets.zero));

      if (_userRef.get(Field.TRIAL) == true) {
        // mainColWidgets.add(_remainingTrialDaysBlock());
        mainColWidgets.add(_remainingTrialDaysBlock(isIconOn: false));
      }
    } else {
      mainColWidgets.add(_resubscribeBlockWrapper(_resubscribeBlock()));
    }

    mainColWidgets.add(_pictureWrapper(_accountChangesBlock()));

    return ListView(
      children: mainColWidgets,
    );
  }

  /*
    return ListView(
      children: [
        // TBD: do we let them know they are in trial mode?
        _userRef.isTrialActive()
            ? _appWidgets.columnWrapper(block1Widgets)
            : Container(),
        _userRef.hasTrialExpired()
            ? _resubscribeBlock()
            : _userRef.hasField('trial')
                ? _remainingTrialDaysBlock()
                : _userRef.get('created') == null
                    ? Container()
                    : _remainingTrialDaysBlock(isIconOn: true),
        _accountChangesBlock(),
      ],
    );
*/

  Widget _remainingTrialDaysBlock({isIconOn = false}) {
    int remainingTrialDays = _userRef.getRemainingTrialDays();
    String remainingDaysMsg =
        StringUtil.getSingleOrPlural(remainingTrialDays, 'day');

    remainingDaysMsg += ' left';
    String remainingDaysMsg2 = 'free trial';

    List<Widget> remainingTrialDaysWidgets = [
      _appWidgets.sectionHeader1(remainingTrialDays.toString(),
          fontSize: AppScale(context).remainingTrialBlockDaysFontSize,
          fontWeight: FontWeight.bold),
      Text(
        remainingDaysMsg,
        textAlign: TextAlign.center,
        style: TextStyle(
            fontSize: AppScale(context).remainingTrialBlockMessageFontSize,
            fontWeight: FontWeight.w500),
      ),
      Text(remainingDaysMsg2),
    ];

    if (isIconOn) {
      remainingTrialDaysWidgets.insert(
          0, _appWidgets.headerIcon1(Icons.calendar_today));
    }

    return _appWidgets.columnWrapper(remainingTrialDaysWidgets,
        boxShadow: BoxShadow(color: Colors.black45, spreadRadius: 1),
        color: Colors.amber[200],
        margin: EdgeInsets.symmetric(horizontal: 60, vertical: 10),
        padding: EdgeInsets.fromLTRB(20, 15, 20, 15));
  }

  Widget _resubscribeBlock({
    double labelFontSize = 36,

    ///This is the separation between phrase and button
    double inlineSeparation = 0,
    BoxShadow boxShadow,
    Color color,
    EdgeInsetsGeometry margin,
    EdgeInsetsGeometry padding,
    String buttonLabel = "Subscribe Now",
    EdgeInsetsGeometry buttonPadding,
    Color buttonColor,
    ShapeBorder buttonShape,
    Color buttonTextColor,
    double buttonElevation,
  }) {
    return _appWidgets.columnWrapper(
      [
        _appWidgets.centerText1(_userRef.mUser.email),
        _appWidgets.sectionHeader1('Trial Ended', fontSize: labelFontSize),
        SizedBox(height: inlineSeparation),
        RaisedButton(
          child: Text(buttonLabel),
          onPressed: () {
            dbg.i('Load CC# input screen');
            Navigator.pushNamed(context, AppRoute.SubscriptionPayment)
                .then((_) async {
              await _userRef.reloadUser();
              setState(() {});
            });
          },
          padding: buttonPadding,
          color: buttonColor,
          shape: buttonShape,
          textColor: buttonTextColor,
          elevation: buttonElevation,
        ),
      ],
      boxShadow: boxShadow,
      color: color,
      margin: margin,
      padding: padding,
    );
  }

  showSubscriptionPayment() {
    Widget cardCol = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          child: AppCreditCardForm(_scaffoldKey, () {
            _appWidgets.showToastTopShort('FIX ME');
          }),
        )
      ],
    );

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10.0))),
            title: Center(child: Text("Subscribe to Kiki \$30/mo. ")),
            content: cardCol,
//            actions: [
//              FlatButton(
//                child: Text("Pay Now"),
//                onPressed: () {
//                  // Go
//                },
//              ),
//            ],
          );
        });
  }

  Widget _accountChangesBlock() {
    Widget accountChangesBlock = Column(
      children: [
        _appWidgets.appNavLink('Account Status', () async {
          Navigator.pushNamed(context, AppRoute.BuyerAccountStatus)
              .then((_) async {
            await _userRef.reloadUser();
            setState(() {});
          });
        },
            fontColor: Colors.black,
            fontSize: AppScale(context).accountStatusButtonFontSize),
        // _appWidgets.headerIcon1(Icons.security),
        SizedBox(height: 10),
        Text(
          "Need to change anything on your account?",
          style: TextStyle(
              color: Colors.grey[600],
              fontSize: AppScale(context).accountStatusBlockMessageFontSize),
        ),
        ButtonBar(
          buttonTextTheme: ButtonTextTheme.normal,
          mainAxisSize: MainAxisSize.min,
          alignment: MainAxisAlignment.spaceBetween,
          children: [
            (_userRef.isEmailVerified())
                ? _reportNetworkButton(
                    AppScale(context).accountStatusBlockMessageFontSize,
                    EdgeInsets.zero)
                : Container(),
            _signOutButton(AppScale(context).accountStatusBlockMessageFontSize,
                EdgeInsets.zero),
          ],
        ),
      ],
    );
    accountChangesBlock = _appWidgets.appBoxShadowContainer(accountChangesBlock,
        color: Colors.indigo[100],
        margin: EdgeInsets.only(left: 60, right: 60, top: 10),
        padding: EdgeInsets.fromLTRB(20, 20, 20, 0));

    return accountChangesBlock;
  }

  Widget _signOutButton([
    double fontSize,
    EdgeInsetsGeometry padding,
  ]) {
    return FlatButton(
        child: Text("Sign-out", style: TextStyle(fontSize: fontSize)),
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
          // Navigator.push(context, MaterialPageRoute(builder: (context) => AppStartScreen()));
          Navigator.pop(
              context); // this line added by Gene, so that Dashboard is not in the stack
          Navigator.pushNamed(context, AppRoute.AppHome);
        });
  }

  Widget _reportNetworkButton([double fontSize, EdgeInsetsGeometry padding]) {
    return FlatButton(
        child: Text("Report network", style: TextStyle(fontSize: fontSize)),
        onPressed: () async {
          _appDialogs.showReportNetwork(onConfirmReport: () async {
            await FirebaseFirestore.instance.collection('reports').add({
              "reporter": _userRef.get('email'),
              "network": _userRef.get('connected'),
              "reviewed": false,
              "created": Timestamp.now(),
            });
            Navigator.pop(context);
          });
        });
  }

  Widget _pictureWrapper(Widget child) {
    String getPicture() {
      var time = _userRef.getRemainingTrialDays();
      if (time == 3) {
        return 'assets/illustrations/full_service.png';
      } else if (time == 2) {
        return 'assets/illustrations/active_service.png';
      } else if (time == 1) {
        return 'assets/illustrations/almost_no_service.png';
      }
      return null;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 130),
      child: Column(
        children: [
          child,
          if (getPicture() != null)
            Image.asset(
              getPicture(),
              width: MediaQuery.of(context).size.width,
            ),
        ],
      ),
    );
  }

  Widget _resubscribeBlockWrapper(Widget resubscribeBlock) {
    return _resubscribeBlock(
      labelFontSize: 26,
      inlineSeparation: 10,
      boxShadow: BoxShadow(color: Colors.black45, spreadRadius: 1),
      color: Colors.deepOrange[200],
      margin: EdgeInsets.symmetric(horizontal: 60, vertical: 10),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 15),
      buttonLabel: 'Subscribe'.toUpperCase(),
      buttonPadding: EdgeInsets.symmetric(horizontal: 40),
      buttonShape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      buttonColor: Colors.blue,
      buttonTextColor: Colors.white,
      buttonElevation: 0,
    );
  }

  Widget _reconnectButtonWrapper(RaisedButton reconnectButton) {
    Widget button = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.green[200],
      ),
      margin: EdgeInsets.symmetric(horizontal: 60, vertical: 10),
      padding: EdgeInsets.all(10),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Paused',
                style: TextStyle(
                    fontSize: AppScale(context).reconnectBlockMessageFontSize),
              ),
            ),
            reconnectButton,
          ],
        ),
      ),
    );

    return button;
  }
}
