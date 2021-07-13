import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kiki_wifi/app/globals.dart';
import 'package:kiki_wifi/ui/_nav/appRoutes.dart';
import 'package:kiki_wifi/ui/widget/appWidgets.dart';
import 'package:kiki_wifi/util/logger.dart';
import 'package:share/share.dart';

class SellerDashboardScreen extends StatefulWidget {
  @override
  _SellerDashboardState createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboardScreen> {
  AppWidgets _appWidgets;
  UserRef _userRef = UserRef();

  @override
  void initState() {
    super.initState();
    _checkUser();
  }

  void _checkUser() async {
    if (userSnapshot == null) {
      // Navigator.push(context, MaterialPageRoute(builder: (context) => AppStartScreen()));
      Navigator.pushNamed(context, AppRoute.AppHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    dbg.enter('SellerDashboardScreen');

    _appWidgets = AppWidgets(context);

    return _mainLayout();
  }

  String verifyEmailMsg = 'You have not verified your email address yet.  '
      'Please check your email.';

  Widget _mainLayout() {
    dbg.i('SellerDashboardScreen, user.emailVerified: ${fireAuthUser.emailVerified}');

    List<Widget> mainWidgets = [_welcomeUserBlock()];

    if (!_userRef.isEmailVerified()) {
      Widget verifyEmailBlock = _appWidgets.verifyEmailBlock(() {
        setState(() {});
      });
      mainWidgets.add(verifyEmailBlock);
    } else {
      mainWidgets.add(_networkUsersBlock());
      mainWidgets.add(_cheaperWifiBlock());
    }

    // leave this available for user to signout, etc
    mainWidgets.add(_updateAccountBlock());

    return ListView(children: mainWidgets);
  }

  Widget _welcomeUserBlock() {
    // Here is where we tell the user they need to click the verifcation link
    return _appWidgets.appBoxShadowContainer(
      _appWidgets.sectionHeader2(
        "Hello, ${userSnapshot.get('name')}!",
      ),
    );
  }

  Widget _networkUsersBlock() {
    int wifiUserCount = sellerWiFiDetails.get('users').length;
    int wifiPayout = wifiUserCount * 25;

    return _appWidgets.columnWrapper(
      [
        _appWidgets.headerIcon1(Icons.people),
        Text(
            "There are $wifiUserCount people signed up and using your network. "
            "\n\n"
            "That's a total payout of \$$wifiPayout coming your way at the end of the month!")
      ],
    );
  }

  Widget _cheaperWifiBlock() {
    return GestureDetector(
      onTap: () {
        Share.share(
            "Want cheaper WiFi? Check out ${Const.APP_NAME} and start WiFi sharing today!");
      },
      child: _appWidgets.columnWrapper([
        _appWidgets.headerIcon1(Icons.share),
        Text(
            "Want to boost that number? Tap here to share ${Const.APP_NAME} with your neighbours!"),
      ]),
    );
  }

  Widget _updateAccountBlock() {
    return _appWidgets.columnWrapper([
      _appWidgets.headerIcon1(Icons.security),
      Text("Need to change anything on your account? Let us know here."),
      FlatButton(
          child: Text("Sign-out"),
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            // Navigator.push(context, MaterialPageRoute(builder: (context) => AppStartScreen()));
            Navigator.pushNamed(context, AppRoute.AppHome);
          }),
      FlatButton(
          child: Text("WiFi Password Changed"),
          onPressed: () {
            _onClickWifiPasswordChanged();
          }),
      FlatButton(
        child: Text("Delete my account"),
        onPressed: () {
          _showAccountDeleteConfirmDialog();
        },
      ),
    ]);
  }

  _onClickWifiPasswordChanged() async {
    final passwordController = TextEditingController();

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Enter new WiFi password"),
            content: TextFormField(
              controller: passwordController,
            ),
            actions: [
              FlatButton(
                child: Text("Update"),
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('passwords')
                      .doc(userSnapshot.get('network'))
                      .update({
                    "password": passwordController.text,
                  });
                },
              ),
            ],
          );
        });
    await FirebaseAuth.instance.signOut();
    // Navigator.push(context, MaterialPageRoute(builder: (context) => AppStartScreen()));
    Navigator.pushNamed(context, AppRoute.AppHome);
  }

  _showAccountDeleteConfirmDialog() {
    showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Are you sure?"),
            content: Text(
                "Deleting your account will remove ALL data we keep on you, and you won't be eligible for this month's payout. We'll inform all active connections that your account has been deleted, but you'll still remain anonymous. Note that this won't disconnect active connections: you'll need to change your WiFi password for that."),
            actions: [
              FlatButton(
                child: Text("Yes, I'm sure."),
                onPressed: () async {
                  showCupertinoDialog(
                      context: context,
                      builder: (BuildContext context) {
                        final _emailController = TextEditingController();
                        final _passwordController = TextEditingController();
                        return AlertDialog(
                          title: Text("Please login again to confirm"),
                          content: Container(
                            height: 200,
                            width: 200,
                            child: ListView(
                              shrinkWrap: true,
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
                              child: Text("Delete Account"),
                              onPressed: () async {
                                await _userRef.deleteAccount();

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
                      });
                  await _userRef.deleteAccount();
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
        });
  }
}
