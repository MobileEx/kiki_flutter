import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:internet_speed_test/internet_speed_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:kiki_wifi/app/globals.dart';
import 'package:kiki_wifi/ui/screen/sign_up/sellerEnroll.dart';
import 'package:kiki_wifi/ui/widget/appWidgets.dart';

/*
For: "I have WiFi"
 */
class SellerSignUpScreen extends StatefulWidget {
  SellerSignUpScreen({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _SellerSignUpScreenState createState() => _SellerSignUpScreenState();
}

class _SellerSignUpScreenState extends State<SellerSignUpScreen> {

  AppWidgets _appWidgets;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _appWidgets = AppWidgets(context);

    Widget logoWidget = _appWidgets.headerLogoWidget();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: logoWidget,
        centerTitle: true,
      ),
      body: ListView(
        children: <Widget>[
          Container(),
          Container(
            width: MediaQuery.of(context).size.width,
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
              children: <Widget>[
                Text(
                  "🏘",
                  style: TextStyle(fontSize: 48),
                ),
                Text(
                    "${Const.APP_NAME} enables you to earn money off your existing WiFi by sharing it with your neighbors, securely and anonymously."),
              ],
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width,
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
              children: <Widget>[
                Text(
                  "💸",
                  style: TextStyle(fontSize: 48),
                ),
                Text(
                    "Once you sign up we'll notify you if anyone near you wants to do a 3 day trial. After that, if you approve, we'll send you \$25 every month. It's that easy."),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              QuestionButton(
                title: "Will this slow my WiFi down?",
                emoji: "🚤",
                description:
                    "While it is true that your WiFi speed can be determined by usage based on bandwidth it's unlikely that you'd find any significant slow downs as a result of sharing your WiFi. Think of it like this: does your WiFi slow down when you buy a new laptop? The answer is yes, when it's in use, but not by much.",
              ),
              QuestionButton(
                title: "Will anyone steal my data?",
                emoji: "💻",
                description:
                    "We generally advise that you should revise your network and sharing settings before starting your share, but so long as you know what the rules on your network are you're totally safe.",
              ),
            ],
          ),
          RaisedButton(
            child: Container(
              width: MediaQuery.of(context).size.width,
              child: Text(
                "Get Started",
                textAlign: TextAlign.center,
              ),
            ),
            onPressed: () async {

              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => SellerEnrollScreen(
                            speed: 50,
                            ssid: null,
                          )));
            },
          ),
          _appWidgets.goBackButton(),
        ],
      ),
    );
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

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  int _page = 0;
  double _speeds = 0.0;
  bool _done = false;
  double _percent = 0.00;
  String ssid = "";

  @override
  void initState() {
    super.initState();
    _getSpeeds();
  }

  void _getSpeeds() async {
    // get wifi

    // get speeds
    final internetSpeedTest = InternetSpeedTest();

    internetSpeedTest.startDownloadTesting(
      onDone: (double transferRate, var unit) async {
        setState(() {
          _speeds = transferRate;
          _done = true;
          _percent = 1.00;
        });

        String _wifiInfo = await WiFiForIoTPlugin.getSSID();
        showCupertinoDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text("Great!"),
                content: Text(
                    "Your internet speed is fast enough to share WiFi on our platform. We'll need to take some details and then we can get started."),
                actions: [
                  FlatButton(
                    child: Text("Okay!"),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SellerEnrollScreen(
                                    speed: _speeds,
                                    ssid: _wifiInfo,
                                  )));
                    },
                  ),
                ],
              );
            });
      },
      onProgress: (double percent, double transferRate, var unit) {
        setState(() {
          _percent = percent;
          _speeds = transferRate;
        });
      },
      onError: (String errorMessage, String speedTestError) async {
        setState(() {
          _speeds = 25.0;
          _done = true;
          _percent = 1.00;
        });

        String _wifiInfo = await WiFiForIoTPlugin.getSSID();

        print(_wifiInfo);
        _wifiInfo = await WiFiForIoTPlugin.getWiFiAPSSID();
        showCupertinoDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text("Hmm..."),
                content: Text(
                    "We weren't able to verify your internet speed, but you're still able to use WiFi share. We'll need to take some details and then we can get started."),
                actions: [
                  FlatButton(
                    child: Text("Okay!"),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SellerEnrollScreen(
                                    speed: _speeds,
                                    ssid: _wifiInfo,
                                  )));
                    },
                  ),
                ],
              );
            });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height / 2,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        child: Center(
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _speeds < 10
                            ? Colors.red
                            : _speeds < 30
                                ? Colors.yellow
                                : Colors.green,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey[300],
                            blurRadius: 16,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _speeds.toStringAsFixed(2) + "mbps",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      "Testing your speed",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Center(
                child: Container(
                  width: 212,
                  height: 212,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _speeds < 10
                          ? Colors.red
                          : _speeds < 30
                              ? Colors.yellow
                              : Colors.green,
                    ),
                    value: _percent / 100,
                    strokeWidth: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



//              showCupertinoDialog(
//                  context: context,
//                  builder: (BuildContext context) {
//                    return AlertDialog(
//                      title: Text("Get Started"),
//                      content: Text("Before we take your details we'd like to run a quick speed test to display to your potential sharers. This'll only take a minute!"),
//                      actions: [
//                        FlatButton(
//                          child: Text("Okay!"),
//                          onPressed: () {
//                            Navigator.pop(context);
//                            showCupertinoModalPopup(
//                                context: context,
//                                builder: (BuildContext context) {
//                                  return SignupScreen();
//                                });
//                          },
//                        ),
//                      ],
//                    );
//                  });