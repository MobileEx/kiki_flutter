import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:connectivity/connectivity.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kiki_wifi/app/globals.dart';
import 'package:kiki_wifi/app/sharedPrefs.dart';
import 'package:kiki_wifi/service/cloudFuncs/sendGlobalFcmMessageFunc.dart';
import 'package:kiki_wifi/service/cloudFuncs/sendUserFcmMessageFunc.dart';
import 'package:kiki_wifi/service/cloudFuncs/deleteTestUsers1Func.dart';
import 'package:kiki_wifi/service/messaging/pushNotificationManager.dart';
import 'package:kiki_wifi/ui/_nav/appRoutes.dart';
import 'package:kiki_wifi/ui/style/appScale.dart';
import 'package:kiki_wifi/ui/widget/appDialogs.dart';
import 'package:kiki_wifi/ui/widget/appWidgets.dart';
import 'package:kiki_wifi/util/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wifi_connect/wifi_connect.dart';

/*
TODO:
Add a button to set expiresDate back 4 days, to force subscribe screen

 */
class DevScreen extends StatefulWidget {
  @override
  DevScreenState createState() => DevScreenState();
}

class DevScreenState extends State<DevScreen> {
  static const String KEY_SSID = 'SSID';
  static const String KEY_PASSWORD = 'Password';

  AppWidgets _appWidgets;
  AppScale _scale;
  AppDialogs _dialogs;
  UserRef _userRef = UserRef();
  String _connectionStatus = 'Unknown';
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult> _connectivitySubscription;

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  @override
  void initState() {
    super.initState();
    _readNetworkDataFromPrefs();
    _initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void dispose() {
    if (_connectivitySubscription != null) {
      _connectivitySubscription.cancel();
    }
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    _appWidgets = AppWidgets(context);
    _scale = AppScale(context);
    _dialogs = AppDialogs(context);

    Widget bodyMain = _mainLayout(context);

    Scaffold scaffold = Scaffold(
      appBar: AppBar(title: Text('Dev Screen')),
      body: bodyMain,
    );

    return scaffold;
  }

  // final HttpsCallable sendMailCallable = CloudFunctions.instance.getHttpsCallable(functionName: 'sendMail')
  //   ..timeout = const Duration(seconds: 30);

  final _buyerEmailController = TextEditingController();
  final _sellerEmailController = TextEditingController();
  final _cardNumberController = TextEditingController();

  String defaultBuyer = '';
  String defaultSeller = '';

  TextEditingController ssidController = TextEditingController(text: 'WheatNet');
  TextEditingController passwordController = TextEditingController(text: 'SuperPWD123');
  bool _isConnected = false;
  String _networkName = '';

  Widget _mainLayout(BuildContext context) {
    // SharedPrefs.lastKnownText = null;

    _buyerEmailController.text = AppData.get(AppData.buyerEmail) ?? defaultBuyer;
    _sellerEmailController.text = AppData.get(AppData.sellerEmail) ?? defaultSeller;
    _cardNumberController.text = '4242 4242 4242 4242';

    return _appWidgets.appScreenContainer(SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: TextFormField(
                    // initialValue: SharedPrefs.lastKnownText ?? '',
                    controller: _buyerEmailController..text,
                    decoration: InputDecoration(
                      labelText: 'Buyer Email Address',
                    ),
                  )),
              _appWidgets.appNavLink('Copy', () {
                String email = _buyerEmailController.text;
                AppData.set(AppData.buyerEmail, email);
                Clipboard.setData(new ClipboardData(text: email));
                _appWidgets
                    .showToastTopShort('Saved & Copied to Clipboard:\n$email');
              })
            ],
          ),
          Container(height: 20),
          Row(
            children: [
              Expanded(
                  child: TextFormField(
                    // initialValue: SharedPrefs.lastKnownText ?? '',
                    controller: _sellerEmailController..text,
                    decoration: InputDecoration(
                      labelText: 'Seller Email Address',
                    ),
                  )),
              _appWidgets.appNavLink('Copy', () {
                String email = _sellerEmailController.text;
                AppData.set(AppData.sellerEmail, email);
                Clipboard.setData(new ClipboardData(text: email));
                _appWidgets
                    .showToastTopShort('Saved & Copied to Clipboard:\n$email');
              })
            ],
          ),          Container(height: 20),
          Row(
            children: [
              Expanded(
                  child: TextFormField(
                    // initialValue: SharedPrefs.lastKnownText ?? '',
                    controller: _cardNumberController..text,
                    decoration: InputDecoration(
                      labelText: 'Test CC# Number',
                    ),
                  )),
              _appWidgets.appNavLink('Copy', () {
                String cardNumber = _cardNumberController.text;
                Clipboard.setData(new ClipboardData(text: cardNumber));
                _appWidgets
                    .showToastTopShort('Copied to Clipboard:\n$cardNumber');
              })
            ],
          ),

          // Text('[For use during coding]'),
          // Container(height: 15),

          Container(height: 20),
          _appWidgets.appNavLink('Expire Trial', () async {

            DateTime expireTrialDate = _userRef.get(Field.CREATED).toDate().subtract(Duration(days: 10));

            _userRef.updateUser({
              Field.CREATED : expireTrialDate,
              Field.TRIAL : false
            }).then((_) {

              _appWidgets.showToastTopShort('Account Expired');
            }).catchError((err) {

              _appWidgets.showToastTopShort('err: $err');
              dbg.i('err: $err');
            });
          }),

          Container(height: 20),
          _appWidgets.appNavLink('Delete Firestore Subscription', () async {

            _userRef.updateUser({
              Field.SUBSCRIPTION_EXPIRES :null
            }).then((_) {

              _appWidgets.showToastTopShort('Deleted Firestore Subscription');
            }).catchError((err) {

              _appWidgets.showToastTopShort('err: $err');
              dbg.i('err: $err');
            });
          }),

          Container(height: 20),
          _appWidgets.appNavLink('Firestore Reload User', () async {
            _userRef.reloadUser();
          }),

          Container(height: 20),
          _appWidgets.appNavLink('Full Screen CC# Form', () async {
            Navigator.pushNamed(context, AppRoute.DevCreditCard);
          }),

          Container(height: 20),
          _appWidgets.appNavLink('Delete Test User Group 1', () async {
            String message = 'For Sean test users ';
            // message += _userRef.mUser.email;
            message += '\n\n';
            message += 'Cannot be undone';

            _dialogs.showConfirmationDialog('Delete Test User Group 1', message,
                    () async {
                  DeleteTestUsers1Func deleteTest1UsersFunc = DeleteTestUsers1Func();

                  // await fireAuthUser.delete();
                  await deleteTest1UsersFunc.run();

                  Navigator.pop(context);
                  Navigator.pop(context);
                });
          }),

          Container(height: 20),
          Text('(Use this carefully)'),
          Container(
            padding: EdgeInsets.all(10),
            color: Colors.orangeAccent[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning),
                Icon(Icons.warning),
                // Text('Caution: '),
                _appWidgets.appNavLink('Clear Firestore', () async {
                  _dialogs.showConfirmationDialog(
                      'Delete All Firestore Data', 'Cannot be undone',
                      () async {
                    await Collctn().clearAllCollections();
                    _appWidgets.showToastTopShort('Firestore Cleared');
                  });
                })
              ],
            ),
          ),
          _setFcmToken(),

          _sendUserFcmMessage(),

          _sendGlobalFcmMessage(),

          buildWifiConnectWidget(context)
        ],
      ),
    ));
  }

  _setFcmToken() {

    PushNotificationManager pushNtfcnMgr = PushNotificationManager();

    return Column(
      children: [
        Container(height: 20),
        _appWidgets.appNavLink('Call setFcmToken();', () async {

          pushNtfcnMgr.setFcmToken();
        }),

      ],
    );

  }

  _sendGlobalFcmMessage() {

    SendGlobalFcmMessageFunc _sendGlobalMsg = SendGlobalFcmMessageFunc();

    return Column(
      children: [
        Container(height: 20),
        _appWidgets.appNavLink('Send Global Ntfcn', () async {

          _sendGlobalMsg.run("Here's a Global Ntfcn");
        }),

      ],
    );

  }

  _sendUserFcmMessage() {

    SendUserFcmMessageFunc _sendUserMsg = SendUserFcmMessageFunc();

    return Column(
      children: [
        Container(height: 20),
        _appWidgets.appNavLink('Send User Ntfcn', () async {

          _sendUserMsg.run("Here's a User Ntfcn just for ${_userRef.get('email')}");
        }),

      ],
    );

  }

//  _sendEmail(String recipientEmail) async {
//    dbg.i('recipientEmail: $recipientEmail');
//    SharedPrefs.setLastKnownText(recipientEmail);
//
//    SendEmailFunc(context).send BuyerInterestedWelcome(recipientEmail);
//
//    // _appWidgets.showToastTopShort('Email has been sent');
//  }

  Widget _toggleFirebaseDelUserEnabled() {
    bool isFirebaseDelUserOn =
        AppData.get(AppData.isFirebaseDelUserOn) ?? false;
    dbg.i('isFirebaseDelUserOn: $isFirebaseDelUserOn');

    String stateText = isFirebaseDelUserOn ? 'ON' : 'OFF';
    Row row = new Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          //this goes in as one of the children in our column
          Expanded(
              child: Text('Delete Firebase User',
                  style: TextStyle(
                      fontSize: _scale.toggleLabel, color: Colors.green))),

          Container(
              margin: EdgeInsets.only(left: 15),
              child: Text(stateText,
                  style: TextStyle(
                      fontSize: 25,
                      color: Colors.green,
                      fontWeight: FontWeight.w600))),
          Switch(
            value: isFirebaseDelUserOn,
            onChanged: (value) {
              bool updateState = !isFirebaseDelUserOn;
              setState(() {
                isFirebaseDelUserOn = updateState;

                AppData.set(AppData.isFirebaseDelUserOn, isFirebaseDelUserOn);
              });
            },
            activeTrackColor: Colors.lightGreenAccent,
            activeColor: Colors.green,
          ),
        ]);

    return Padding(
      // child: const Icon(Icons.arrow_forward)))
        padding: EdgeInsets.all(10.0),
        child: row);
  }

  Widget buildWifiConnectWidget(BuildContext context) {
    if (_isConnected) {
      return Center(
        child: Column(children: [
          Text('You are connected to $_networkName', style: TextStyle(fontSize: 18.0),),
          MaterialButton(
              child: Text('DISCONNECT'),
              onPressed: () {
                _disconnectNetwork(ssidController.text).then((void value) => (void value) {
                  setState(() {
                    _networkName = "";
                    _isConnected = false;
                  });
                });
              })
        ]),
      );
    } else {
      return Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          TextField(controller: ssidController, decoration: InputDecoration(hintText: 'SSID')),
          TextField(controller: passwordController, decoration: InputDecoration(hintText: 'Password')),
          Text('Connection status:  $_connectionStatus'),
          MaterialButton(
              child: Text('CONNECT'),
              onPressed: () {
                _connectNetwork(ssidController.text, passwordController.text);
              }),
          MaterialButton(
              child: Text("DISCONNECT"),
              onPressed: () {
                _disconnectNetwork(ssidController.text).then((void value) => (void value) {
                      setState(() {
                        _networkName = "";
                        _isConnected = false;
                      });
                    });
              })
        ],
      )); // This trailing comma makes auto-formatting nicer for build methods.
    }
  }

  Future<void> _connectNetwork(String ssid, String password) async {
    print('Connecting network');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(KEY_SSID, ssid);
    prefs.setString(KEY_PASSWORD, password);
    WifiConnect.connect(context, ssid: ssidController.text, password: passwordController.text).then((value) async {
      ConnectivityResult result;
      try {
        result = await _connectivity.checkConnectivity();
      } on PlatformException catch (e) {
        print(e.toString());
      }
      _updateConnectionStatus(result);
    });
  }

  Future<void> _disconnectNetwork(String ssid) async {
    WifiConnect.disconnect(ssid);
  }

  Future<void> _readNetworkDataFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String ssid = prefs.getString(KEY_SSID);
    String password = prefs.getString(KEY_PASSWORD);
    if ((ssid != null && ssid.isNotEmpty) && (password != null && password.isNotEmpty)) {
      setState(() {
        ssidController.text = ssid;
        passwordController.text = password;
      });
    }
  }

  Future<void> _initConnectivity() async {
    ConnectivityResult result;
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      print(e.toString());
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) {
      return Future.value(null);
    }

    return _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    switch (result) {
      case ConnectivityResult.wifi:
        WifiConnect.getConnectedSSID(context).then((network) {
          setState(() {
            _networkName = network;
            _isConnected = true;
            _connectionStatus = "Connected to wifi";
          });
        });
        break;
      case ConnectivityResult.mobile:
        setState(() {
          _networkName = "";
          _isConnected = false;
          _connectionStatus = "Connected via mobile network";
        });
        break;
      case ConnectivityResult.none:
        setState(() {
          _networkName = "";
          _isConnected = false;
          _connectionStatus = "Not connected";
        });
        break;
      default:
        setState(() {
          _networkName = "";
          _isConnected = false;
          _connectionStatus = 'Failed to get connectivity info.';
        });
        break;
    }
  }
}
