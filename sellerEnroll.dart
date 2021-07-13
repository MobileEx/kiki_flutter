import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kiki_wifi/app/globals.dart';
import 'package:kiki_wifi/service/cloudFuncs/registerBuyerInterestFunc.dart';
import 'package:kiki_wifi/ui/screen/dashboard/buyerDashboard.dart';
import 'package:kiki_wifi/ui/widget/appDialogs.dart';
import 'package:kiki_wifi/ui/widget/appWidgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:wifi/wifi.dart';

class SellerEnrollScreen extends StatefulWidget {
  SellerEnrollScreen({Key key, this.speed, this.ssid}) : super(key: key);

  final double speed;
  final String ssid;

  @override
  _SellerEnrollScreenState createState() => _SellerEnrollScreenState();
}

class _SellerEnrollScreenState extends State<SellerEnrollScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _wifiPasswordController = TextEditingController();
  final _ssidController = TextEditingController();

  AppWidgets _appWidgets;
  AppDialogs _appDialogs;

  List<WifiNameModel> wifiList = [];
  int selectedWifiIndex = -1;

  @override
  void initState() {
    _ssidController.text = widget.ssid;
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
      body: SafeArea(
        child: ListView(
          children: <Widget>[
            _appWidgets.columnWrapper(
              [
                Text(
                  "📲",
                  style: TextStyle(fontSize: 48),
                ),
                Text(
                    "We need to take some information so that we can get an account setup, tracking your WiFi details and payouts."),
              ],
            ),
            _appWidgets.columnWrapper(_sellerRegisterFormInputs()),
            RaisedButton(
              child: Container(
                width: MediaQuery.of(context).size.width,
                child: Text(
                  "Create Account",
                  textAlign: TextAlign.center,
                ),
              ),
              onPressed: () async {
                _appDialogs.showCheckingDetailsDialog();

                try {
                  await WiFiForIoTPlugin.removeWifiNetwork(
                      _ssidController.text);
                  await WiFiForIoTPlugin.disconnect();
                } catch (e) {
                  print("An error curred when trying to disconnect.");
                }
                print("attempting to connect");

                bool _connected = await WiFiForIoTPlugin.findAndConnect(
                    _ssidController.text,
                    password: _wifiPasswordController.text);

                _appDialogs.showSellerCreateAccountDialog(
                    onCreateSellerAccount: _firebaseCreateSellerAccount);
              },
            ),
            _appWidgets.goBackButton(),
          ],
        ),
      ),
    );
  }

  List<Widget> _sellerRegisterFormInputs() {
    return [
      Padding(
        padding: EdgeInsets.all(10),
        child: Text(
          "Account Information",
          style: TextStyle(fontSize: 22),
        ),
      ),
      Padding(
        padding: EdgeInsets.all(10),
        child: TextFormField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: "Name",
            border: OutlineInputBorder(),
          ),
        ),
      ),
      Padding(
        padding: EdgeInsets.all(10),
        child: TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: "Email Address",
            border: OutlineInputBorder(),
          ),
        ),
      ),
      Padding(
        padding: EdgeInsets.all(10),
        child: TextFormField(
          keyboardType: TextInputType.numberWithOptions(),
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: "Phone Number",
            border: OutlineInputBorder(),
          ),
        ),
      ),
      Padding(
        padding: EdgeInsets.all(10),
        child: TextFormField(
          controller: _passwordController,
          decoration: InputDecoration(
            labelText: "Password",
            border: OutlineInputBorder(),
          ),
          obscureText: true,
        ),
      ),
      Padding(
        padding: EdgeInsets.all(10),
        child: TextFormField(
          controller: _confirmPasswordController,
          decoration: InputDecoration(
            labelText: "Confirm Password",
            border: OutlineInputBorder(),
          ),
          obscureText: true,
        ),
      ),
      Padding(
        padding: EdgeInsets.all(10),
        child: Text(
          "Wifi Information",
          style: TextStyle(fontSize: 22),
        ),
      ),
      Padding(
        padding: EdgeInsets.all(10),
        child: ButtonTheme(
          minWidth: double.infinity,
          height: 60,
          child: OutlineButton(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                selectedWifiIndex == -1
                    ? "WiFi Name"
                    : wifiList[selectedWifiIndex]._value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.normal,
                  fontSize: 16,
                ),
              ),
            ),
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Wifi Name'),
                      content: showWifiListDialog(),
                    );
                  });
            },
            borderSide: BorderSide(
              color: Colors.grey[500],
              style: BorderStyle.solid,
            ),
          ),
        ),
      ),
      Padding(
        padding: EdgeInsets.all(10),
        child: TextFormField(
          controller: _wifiPasswordController,
          decoration: InputDecoration(
            labelText: "WiFi Password",
            border: OutlineInputBorder(),
          ),
        ),
      ),
    ];
  }

  Widget showWifiListDialog() {
    return Container(
      height: 350.0, // Change as per your requirement
      width: 300.0, // Change as per your requirement
      child: ListView(
        children: wifiList
            .map((wifiItem) => RadioListTile(
                  groupValue: selectedWifiIndex,
                  title: Text(wifiItem._value),
                  value: wifiItem._key,
                  onChanged: (val) {
                    selectedWifiIndex = val;
                    _ssidController.text = wifiList[val]._value;
                    setState(() {});
                    Navigator.pop(context);
                  },
                ))
            .toList(),
      ),
    );
  }

  initData() {
    Wifi.list('').then((aroundList) {
      List<WifiResult> filteredLists = [];
      for (int i = 0; i < aroundList.length; i++) {
        var isExistItem = false;
        for (int j = 0; j < filteredLists.length; j++) {
          if (aroundList[i].ssid == filteredLists[j].ssid) {
            isExistItem = true;
          }
        }

        if (!isExistItem) {
          filteredLists.add(aroundList[i]);
        }
      }

      for (int i = 0; i < filteredLists.length; i++) {
        if (filteredLists[i].ssid.isNotEmpty) {
          wifiList.add(WifiNameModel(i, filteredLists[i].ssid));
        }
      }
    });
  }

  _firebaseCreateSellerAccount() async {
    try {
      String bssid = Random().nextInt(99999).toString();

      Position _pos = await getCurrentPosition();
      UserCredential ar = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: _emailController.text, password: _passwordController.text);

      await FirebaseFirestore.instance.collection('networks').doc(bssid).set({
        'speed': {
          'up': '${(widget.speed / 10).toStringAsFixed(0)}mbps',
          'down': '${widget.speed.toStringAsFixed(0)}mbps'
        },
        'owner': ar.user.uid,
        'pos': [_pos.latitude, _pos.longitude],
      });

      await FirebaseFirestore.instance.collection('passwords').doc(bssid).set({
        'ssid': _ssidController.text,
        'password': _wifiPasswordController.text,
        'users': [],
        'owner': ar.user.uid,
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(ar.user.uid)
          .set({
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'role': 'seller',
        'network': bssid,
        'created': Timestamp.now(),
      });

      // TODO: This will now be handled by cloud funcs: auth().onCreate
      //  try {
      //    await ar.user.sendEmailVerification();
      //    String recipientEmail = ar.user.email;
      //    await SendEmailFunc(context).sendSellerSignUpWelcome(recipientEmail);
      //  } catch (e) {
      //    print(
      //        'An error occured while trying to send email        verification');
      //    print(e.message);
      //  }

      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Registration complete!'),
            content: Text(
                // 'All set! We've got what we need and will notify you when any of your neighbors starts a 3 day trial.'),
                'Thanks for signing up.  We have sent an verification link to your email.  Please click that to get started.'),
            actions: [
              FlatButton(
                child: Text('Dashboard'),
                onPressed: () async {
                  await UserRef().setUser();
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => BuyerDashboardScreen()));
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      Navigator.pop(context);
      _appDialogs.showError(e);
    }
  }
}

class QuestionButton extends StatelessWidget {
  QuestionButton({this.title, this.emoji, this.description});

  final String title;
  final String emoji;
  final String description;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Container(
      width: 128,
      height: 128,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: RawMaterialButton(
          onPressed: () {
            showCupertinoDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text(title),
                    content: Text(description),
                    actions: [
                      FlatButton(
                        child: Text("Okay"),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  );
                });
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey[200],
                  blurRadius: 16,
                ),
              ],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  emoji,
                  style: TextStyle(fontSize: 48),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WifiNameModel {
  final int _key;
  final String _value;

  WifiNameModel(
    this._key,
    this._value,
  );
}
// =======================
// =======================
// =======================
// =======================
// =======================
// =======================

/*if (_connected == false) {
                Navigator.pop(context);
                showCupertinoDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text("Something isn't right..."),
                      content: Text("We weren't able to connect to that WiFi network. Is the password correct?\n\nConnected: $_connected"),
                      actions: [
                        FlatButton(
                          child: Text("Okay"),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    );
                  },
                );
              } else {*/
//  }

/*


            Container(
              padding: EdgeInsets.all(20),
              margin: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey[200],
                    blurRadius: 16,
                  ),
                ],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: <Widget>

            Container(
              padding: EdgeInsets.all(20),
              margin: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey[200],
                    blurRadius: 16,
                  ),
                ],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: _sellerRegisterFormInputs(),
              ),
            ),
*/
