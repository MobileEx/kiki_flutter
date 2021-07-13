import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kiki_wifi/app/globals.dart';
import 'package:kiki_wifi/service/cloudFuncs/registerBuyerInterestFunc.dart';
import 'package:kiki_wifi/service/repository/newWifiRepository.dart';
import 'package:kiki_wifi/ui/_nav/appRoutes.dart';
import 'package:kiki_wifi/ui/widget/appDialogs.dart';
import 'package:kiki_wifi/ui/widget/appWidgets.dart';
import 'package:kiki_wifi/util/logger.dart';
import 'package:wifi_iot/wifi_iot.dart';

import 'package:wifi/wifi.dart';

class BuyerSignUpScreen extends StatefulWidget {
  BuyerSignUpScreen({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _BuyerSignUpScreenState createState() => _BuyerSignUpScreenState();
}

class _BuyerSignUpScreenState extends State<BuyerSignUpScreen> {
  AppDialogs _appDialogs;
  AppWidgets _appWidgets;
  NewWifiRepository firebaseRepository = NewWifiRepository();
  List<WifiResult> aroundWifiList = [];
  List<dynamic> ssidList = [];
  var loadingData = false;

  @override
  void initState() {
    super.initState();

    initData();
  }

  @override
  Widget build(BuildContext context) {
    _appDialogs ??= AppDialogs(context);
    _appWidgets = AppWidgets(context);

    Widget logoWidget = _appWidgets.headerLogoWidget();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: logoWidget,
        centerTitle: true,
      ),
      body: Container(
        child: loadingData ? _buildLoadingBar() : _buildBody(),
      ),
    );
  }

  Widget _buildLoadingBar() {
    return Container(
      margin: EdgeInsets.only(top: 100),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              Padding(padding: EdgeInsets.only(left: 10)),
              Text("Searching..."),
            ],
          ),
          Padding(padding: EdgeInsets.all(10)),
          Text('Looking up networks...'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Container(
      child: Column(
        children: (ssidList.length == 0
            ? _badNewsBlockWidgets()
            : _greatNewsBlockWidgets()),
      ),
    );
  }

  List<Widget> _badNewsBlockWidgets() {
    return [
      Expanded(
        child: Container(
          height: 300,
          child: _buildAvaliableWifiList(),
        ),
      ),
      Text(
        "😭",
        style: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.w800,
        ),
      ),
      Text(
        "Bad news!",
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      Text(
          "None of your neighbors are sharing their WiFi in ${Const.APP_NAME}.\nSign up here and we'll let you know if that changes."),
      Padding(
        padding: EdgeInsets.all(20),
        child: TextFormField(
          controller: _appDialogs.emailController..text,
          decoration: InputDecoration(
            labelText: "Email Address",
          ),
        ),
      ),
      RaisedButton(
          child: Text("Register Interest"),
          onPressed: () async {
            _firebaseRegisterInterest();
          }),
      Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          "By registering your interest we'll log your approximate location. If anyone within a 100 meter range of you starts offering their WiFi for sharing we'll send you an email.",
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey,
          ),
        ),
      ),
      _appWidgets.goBackButton(),
    ];
  }

  List<Widget> _greatNewsBlockWidgets() {
    return [
      Text(
        "📲",
        style: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.w800,
        ),
      ),
      Text(
        "Great news!",
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          "We have a network available for you with speeds up to 5mbps"
          "upload and 50mbps download.",
          textAlign: TextAlign.center,
        ),
      ),
      RaisedButton(
          child: Text("Get started with your free 3 day trial"),
          onPressed: () {
            _appDialogs.showBuyerTrialDialog(
                onCreateBuyerAccount: _firebaseCreateBuyerAccount);
          }),
      _appWidgets.goBackButton(),
    ];
  }

  initData() async {
    loadingData = true;
    setState(() {});
    List<dynamic> savedList =
        await firebaseRepository.loadCompleteWifiCollections();
    loadingData = false;
    setState(() {});

    if (savedList.length > 0) {
      loadData(savedList);
    }
  }

  Widget _buildAvaliableWifiList() {
    return ListView.builder(
        padding: EdgeInsets.all(8.0),
        itemCount: aroundWifiList.length,
        itemBuilder: (BuildContext context, int index) {
          return Text(
            "Name: " +
                aroundWifiList[index].ssid +
                " + Signal: " +
                aroundWifiList[index].level.toString(),
            style: TextStyle(
              color: Colors.black87,
              fontSize: 16.0,
            ),
          );
        });
  }

  void loadData(List<dynamic> savedList) async {
    log(savedList.toString());
    Wifi.list('').then((aroundList) {
      aroundWifiList = aroundList;
      this.setState(() {});

      if (aroundList.length > 0) {
        aroundList.sort((x, y) => y.level.compareTo(x.level));
        List<dynamic> wifiListAvailable = [];

        for (int i = 0; i < aroundList.length; i++) {
          var existedWifiList = [];

          for (int j = 0; j < savedList.length; j++) {
            if (savedList[j]['ssid'] == aroundList[i].ssid) {
              existedWifiList.add({
                'referenceId': savedList[j]['referenceId'],
                "ssid": savedList[j]['ssid'],
                "password": savedList[j]['password'],
                "signal_level": aroundList[i].level,
              });
            }
          }

          wifiListAvailable.addAll(existedWifiList);
        }

        List<dynamic> newList = [];
        for (int i = 0; i < wifiListAvailable.length; i++) {
          var isExistItem = false;
          for (int j = 0; j < newList.length; j++) {
            if (wifiListAvailable[i]['ssid'] == newList[j]['ssid'] &&
                wifiListAvailable[i]['password'] == newList[j]['password']) {
              isExistItem = true;
            }
          }

          if (!isExistItem) {
            newList.add(wifiListAvailable[i]);
          }
        }

        ssidList = newList;
        setState(() {});
      }
    });
  }

  _firebaseRegisterInterest() async {
    String recipientEmail = _appDialogs.email;

    Position _pos = await getCurrentPosition();

    await RegisterBuyerInterestFunc().run(
      recipientEmail,
      [
        _pos.latitude,
        _pos.longitude,
      ],
    );

    _appDialogs.showInterestRegistered();
  }

  _firebaseCreateBuyerAccount() async {
    var docObj = {
      'email': _appDialogs.email,
      'trial': true,
      'role': 'buyer',
      'created': Timestamp.now(),
      'connected': ssidList[0]['referenceId'],
    };

    try {
      UserCredential ar = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: _appDialogs.email, password: _appDialogs.password);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(ar.user.uid)
          .set(docObj);

      await UserRef().setUser();

      String ssid = ssidList[0]['ssid'];
      String pwd = ssidList[0]['password'];

      await WiFiForIoTPlugin.findAndConnect(ssid, password: pwd);

      // close dialog
      Navigator.pop(context);

      // close signUp screen, goes back to start screen
      Navigator.pop(context);

      //
      Navigator.pushNamed(context, AppRoute.BuyerDashboard);
      //
    } catch (e) {
      Navigator.pop(context);
      _appDialogs.showCupertinoError(e);
    }
  }
}
