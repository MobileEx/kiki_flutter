import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kiki_wifi/app/globals.dart';
import 'package:kiki_wifi/service/cloudFuncs/resendVerificationEmailFunc.dart';
import 'package:kiki_wifi/ui/_nav/appRoutes.dart';
import 'package:kiki_wifi/ui/style/appStyle.dart';
import 'package:kiki_wifi/util/logger.dart';

class NavCtrlWidgets {
  BuildContext _ctxt;

  NavCtrlWidgets(this._ctxt);

  dismissKeyboard() {
    FocusScope.of(_ctxt).requestFocus(FocusNode()); // dismiss the keyboard
  }

  Widget clearFocusHandler(Widget screenWidget) {
    // to support touch listener , eg click outside of textfield to lose/take focus
    GestureDetector clearFocusGestureDetector = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          // print('GestureDetector.onTap()');
          FocusScope.of(_ctxt).requestFocus(FocusNode());
        },
        child: screenWidget);

    return clearFocusGestureDetector;
  }

  WillPopScope doubleBackClickPopScope(Scaffold scaffold) {
    WillPopScope willPopScope = WillPopScope(
        onWillPop: () {
          dbg.i('onWillPop() called, for doubleBackClickPopScope()');

          Navigator.pop(_ctxt, false);
          Navigator.pop(_ctxt, false);

          //we need to return a future
          return Future.value(false);
        },
        child: scaffold);

    return willPopScope;
  }
}

class AppWidgets {
  BuildContext _ctxt;
  AppStyle _style;
  UserRef userRef = UserRef();

  AppWidgets(this._ctxt) {
    _style = AppStyle(_ctxt);
  }

  Widget appScreenContainer(Widget mainScreenWidget) {
    // return SafeArea(
    return Container(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: mainScreenWidget,
      ),
    );
  }

  Widget goBackButton() {
    return FlatButton(
        onPressed: () {
          Navigator.pop(_ctxt);
        },
        child: Text(
          "Go back",
          style: TextStyle(),
        ));
  }

  Widget appNavLink(
    String text,
    Function onClick, {
    double fontSize,
    Color fontColor,
    Color buttonColor,
    bool isRoundedCorners,
    double borderRadius = 0,
    EdgeInsetsGeometry padding,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: padding ?? EdgeInsets.all(5),
        child: Text(text,
            style: (fontSize == null && fontColor == null)
                ? _style.appNavLink()
                : _style
                    .appNavLink()
                    .copyWith(fontSize: fontSize, color: fontColor)),
      ),
      onTap: () {
        onClick();
      },
    );
  }

  Widget headerLogoWidget(
      {double logoHeight = 52, double logoWidth, Function onBackButton}) {
    Widget logoWidget = Image.asset(
      'assets/logo.jpg',
      height: logoHeight,
      width: logoWidth,
    );

    if (App.isDebugMode()) {
      logoWidget = GestureDetector(
        child: logoWidget,
        onLongPress: () {
          dbg.i('onLongPress');
          Navigator.pushNamed(_ctxt, AppRoute.Dev).then((_) {
            dbg.callback('AppRoute.Dev');
            if (onBackButton != null) {
              onBackButton();
            }
          });
        },
      );
    }

    return logoWidget;
  }

  Widget sectionHeader1(String textStr,
      {double fontSize = 36, FontWeight fontWeight = FontWeight.w800}) {
    return Text(
      textStr,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
    );
  }

  Widget sectionHeader2(String textStr,
      {double fontSize = 24, FontWeight fontWeight = FontWeight.w800}) {
    return Text(
      textStr,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget centerText1(String textStr, {Color color, FontWeight fontWeight}) {
    return Text(
      textStr ?? '[Uh-oh, Data Missing]',
      style: TextStyle(
        fontSize: 18,
        color: color,
        fontWeight: fontWeight,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget headerIcon1(IconData icon) {
    return Icon(icon, size: 36);
  }

  String verifyEmailMsg = 'You have not verified your email address yet.  '
      'Please check your email.';

  /*
  @param stateObject to be able to call .setState()
   */
  Widget verifyEmailBlock(
    Function onReload, {
    EdgeInsetsGeometry margin,
    Color buttonColor,
    double borderRadius,
    double fontSize,
    Color fontButtonColor,
    EdgeInsetsGeometry padding,
    bool hasButtonBar = false,
    Color color,
    BoxShadow boxShadow,
    Color messageTextColor,
  }) {
    ResendVerificationEmailFunc resendVerificationEmailFunc =
        ResendVerificationEmailFunc();

    List<Widget> columnWidgets = [
      Text(
        verifyEmailMsg +
            ' If email has not arrived, you can choose to resend verification link',
        style: TextStyle(color: messageTextColor),
      ),
      Container(height: 10),
      if (!hasButtonBar)
        appNavLink(
          'REFRESH',
          () async {
            dbg.i('CLICK-ON: I already clicked');
            showToastTopShort('Ok, checking the server now ...');

            await userRef.setUser();

            // await getUser().then((_) => user.reload());
            // looks like this works
            await fireAuthUser.reload();

            // but this doesnt
            await userRef.mUser.reload().then((_) async {
              dbg.callback('await userRef.mUser.reload()');
              dbg.i('userRef.mUser: ${userRef.mUser}');
              dbg.i('global user: $fireAuthUser');
              // onReload(); // FIXME - readd this if it works, and rm rest of block

              await userRef.setUser();

              onReload();
            }); // in reference to global user
          },
          buttonColor: buttonColor,
          borderRadius: borderRadius,
          fontColor: fontButtonColor,
          fontSize: fontSize,
          padding: padding,
        ),
      if (!hasButtonBar) Container(height: 10),
      if (!hasButtonBar)
        appNavLink(
          'RESEND',
          () async {
            dbg.i('clicked: Resend Verification Link');

            // await fireAuthUser.sendEmailVerification();
            await resendVerificationEmailFunc.run();
            showToastTopShort('Verification link has been sent to your email');
          },
          buttonColor: buttonColor,
          borderRadius: borderRadius,
          fontColor: fontButtonColor,
          fontSize: fontSize,
          padding: padding,
        ),
      if (hasButtonBar)
        ButtonBar(
          alignment: MainAxisAlignment.spaceAround,
          children: [
            appNavLink(
              'REFRESH',
              () async {
                dbg.i('CLICK-ON: I already clicked');
                showToastTopShort('Ok, checking the server now ...');

                await userRef.setUser();

                // await getUser().then((_) => user.reload());
                // looks like this works
                await fireAuthUser.reload();

                // but this doesnt
                await userRef.mUser.reload().then((_) async {
                  dbg.callback('await userRef.mUser.reload()');
                  dbg.i('userRef.mUser: ${userRef.mUser}');
                  dbg.i('global user: $fireAuthUser');
                  // onReload(); // FIXME - readd this if it works, and rm rest of block

                  await userRef.setUser();

                  onReload();
                }); // in reference to global user
              },
              buttonColor: buttonColor,
              borderRadius: borderRadius,
              fontColor: fontButtonColor,
              fontSize: fontSize,
              padding: padding,
            ),
            appNavLink(
              'RESEND',
              () async {
                dbg.i('clicked: Resend Verification Link');

                // await fireAuthUser.sendEmailVerification();
                await resendVerificationEmailFunc.run();
                showToastTopShort(
                    'Verification link has been sent to your email');
              },
              buttonColor: buttonColor,
              borderRadius: borderRadius,
              fontColor: fontButtonColor,
              fontSize: fontSize,
              padding: padding,
            ),
          ],
        ),
    ];

    Widget verifyEmailBlock = columnWrapper(columnWidgets,
        margin: margin, color: color, boxShadow: boxShadow);

    return verifyEmailBlock;
  }

  showToastTopShort(String msgText) {
    Fluttertoast.showToast(
      msg: msgText,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.lightGreen[600],
      textColor: Colors.white,
      fontSize: 25.0,
    );
  }

  Widget columnWrapper(List<Widget> columnWidgets,
      {BoxShadow boxShadow,
      EdgeInsetsGeometry padding,
      EdgeInsetsGeometry margin,
      Color color}) {
    Widget mainWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: columnWidgets,
    );

    return appBoxShadowContainer(mainWidget,
        boxShadow: boxShadow, padding: padding, margin: margin, color: color);
  }

  Widget appBoxShadowContainer(
    Widget mainWidget, {
    BoxShadow boxShadow,
    EdgeInsetsGeometry padding,
    EdgeInsetsGeometry margin,
    Color color,
  }) {
    return Container(
      padding: padding ?? EdgeInsets.all(20),
      margin: margin ?? EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        boxShadow: [
          boxShadow ??
              BoxShadow(
                color: Colors.grey[200],
                blurRadius: 16,
              ),
        ],
        borderRadius: BorderRadius.circular(20),
      ),
      child: mainWidget,
    );
  }

  // =================
  // == Buttons

  navRaisedButton(String label, String routeName) {
    return raisedButtonCentered(label, () async {
      return await Navigator.pushNamed(_ctxt, routeName).then((result) {
        dbg.callback('from route: $routeName');
      }).catchError((e) {
        print(e.toString());
      });
    });
  }

  Widget navFlatButton(String label, String routeName,
      {Color color, ShapeBorder shape, double height, Color textColor}) {
    return flatButtonCentered(
      label,
      () async {
        return await Navigator.pushNamed(_ctxt, routeName).then((result) {
          dbg.callback('from route: $routeName');
        }).catchError((e) {
          print(e.toString());
        });
      },
      color: color,
      shape: shape,
      height: height,
    );
  }

  Widget raisedButtonCentered(String label, Function onPress,
      {Color color,
      ShapeBorder shape,
      double elevation,
      double height,
      Color textColor}) {
    return RaisedButton(
      onPressed: onPress,
      child: Container(
        alignment: Alignment.center,
        width: MediaQuery.of(_ctxt).size.width,
        height: height,
        child: Text(
          label,
          textAlign: TextAlign.center,
        ),
      ),
      elevation: elevation,
      color: color,
      shape: shape,
      textColor: textColor,
    );
  }

  flatButtonCentered(String label, Function onPress,
      {Color color, ShapeBorder shape, double height}) {
    return FlatButton(
      color: (color == null) ? Theme.of(_ctxt).primaryColor : color,
      onPressed: onPress,
      shape: shape,
      child: Container(
        width: MediaQuery.of(_ctxt).size.width,
        height: height,
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
