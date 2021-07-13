import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kiki_wifi/app/globals.dart';
import 'package:kiki_wifi/ui/_nav/appRoutes.dart';
import 'package:kiki_wifi/ui/screen/dashboard/buyerDashboard.dart';
import 'package:kiki_wifi/ui/widget/appWidgets.dart';

class AppStartScreen extends StatefulWidget {
  AppStartScreen({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _AppStartScreenState createState() => _AppStartScreenState();
}

class _AppStartScreenState extends State<AppStartScreen> {
  bool _loaded = false;
  AppWidgets _appWidgets;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  /*
  Sends user to Dashboard if already logged in
   */
  void _checkLogin() async {
    try {
      try {
        await UserRef().setUser();
      } catch (e) {
        fireAuthUser = null;
        print(e);
      }
      if (fireAuthUser == null) {
        setState(() {
          _loaded = true;
        });
      } else {
        // User is logged in, send them to DashboardPage
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => BuyerDashboardScreen()));
      }
    } catch (e) {
      setState(() {
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _appWidgets = AppWidgets(context);

    return Scaffold(
      body: SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            color: Colors.white,
          ),
          child: _loaded
              ? _mainLayout()
              : Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }

  Widget _mainLayout() {
    Widget logoWidget = _appWidgets.headerLogoWidget(
        logoHeight: null, logoWidth: MediaQuery.of(context).size.width / 2);

    var size = MediaQuery.of(context).size;

    return Column(
      // Changed to spaceBetween from SpaceEvenly
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Spacer(),
        logoWidget,
        _shareWiFiBlock(),
        Spacer(),
        _haveAndSeekingWifiButtons(),
        Stack(
          children: [
            Image.asset(
              'assets/illustrations/loginScreenIllustration.jpg',
              height: size.height / 3,
              width: size.width,
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
            ),
            Positioned(
              bottom: 5,
              width: size.width,
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(
                      'assets/illustrations/login_text_button_background.png',
                    ),
                  ),
                ),
                child: _loginTextButton(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _shareWiFiBlock() {
    return Text(
      "Share WiFi with your neighbors",
      style: TextStyle(
        fontStyle: FontStyle.italic,
        color: Colors.blue[900],
      ),
    );
  }

  Widget _haveAndSeekingWifiButtons() {

    Color getInternet = Color(0xff55c89e);
    Color offerInternet = Color(0xff1B98CE);


    return Container(
      width: MediaQuery.of(context).size.width,
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: _appWidgets.navFlatButton(
              "GET INTERNET",
              AppRoute.BuyerSignUp,
              color: getInternet,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              height: MediaQuery.of(context).size.width / 7,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: _appWidgets.raisedButtonCentered(
              "OFFER MY INTERNET",
                  () async {
                return await Navigator.pushNamed(
                    context, AppRoute.SellerSignUp);
              },
              color: offerInternet,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              height: MediaQuery.of(context).size.width / 7,
              elevation: 0,
              textColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _loginTextButton() {
    return FlatButton(
      onPressed: () {
        showCupertinoDialog(
            context: context,
            builder: (BuildContext context) {
              return _loginDialog();
            });
      },
      child: Text(
        "Have an account? Tap here to login",
        style: TextStyle(
          color: Colors.grey,
        ),
      ),
    );
  }

  _loginDialog() {
    final _emailController = TextEditingController();
    final _passwordController = TextEditingController();

    return AlertDialog(
      title: Text("Login"),
      content: Container(
        height: 135,
        width: 200,
        child: Column(
          children: [
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "Email Address",
              ),
            ),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: "Password",
              ),
              obscureText: true,
            ),
          ],
        ),
      ),
      actions: [
        FlatButton(
          child: Text("Login"),
          onPressed: () async {
            try {
              await FirebaseAuth.instance.signInWithEmailAndPassword(
                  email: _emailController.text,
                  password: _passwordController.text);
              await UserRef().setUser();
            } catch (e) {
              await showCupertinoDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text("Woops!"),
                      content: Text(e.toString()),
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
            }
            // TBD if we need this: Not sure why this is here
            // Navigator.push(context, MaterialPageRoute(builder: (context) => AppStartScreen()));
            Navigator.pushNamed(context, AppRoute.AppHome);
          },
        ),
        FlatButton(
          child: Text("Cancel"),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}

/*

//              Navigator.push(
//                  context,
//                  MaterialPageRoute(
//                      builder: (context) => SellerSignUpScreen()));

            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BuyerSignUpScreen()),
              ).then((result) {
                dbg.callback('AppStartScreen => BuyerSignUpScreen');
              }).catchError((e) {
                print(e.toString());
              });
            },
          ),

 */
