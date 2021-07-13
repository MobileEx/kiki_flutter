import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kiki_wifi/app/globals.dart';
import 'package:kiki_wifi/ui/style/appScale.dart';
import 'package:kiki_wifi/ui/widget/appWidgets.dart';
import 'package:kiki_wifi/util/logger.dart';

class AppDialogs {
  BuildContext _ctxt;
  AppWidgets _appWidgets;
  AppScale _scale;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String get email => _emailController.text;

  String get password => _passwordController.text;

  TextEditingController get emailController => _emailController;

  AppDialogs(this._ctxt) {
    _appWidgets = AppWidgets(_ctxt);
    _scale = AppScale(this._ctxt);
  }

  showConfirmationDialog(String title, String message, Function onConfirm) {
    Widget cancelButton = getDialogActionButton(
      "Cancel",
          () {
        Navigator.of(_ctxt).pop();
      },
    );

    Widget continueButton = getDialogActionButton(
      "Continue",
          () {
        dbg.i('ACTION Confirmed');
        Navigator.of(_ctxt).pop();
        onConfirm();
      },
    );

    showAppDialog(
        title, getDialogTextWidget(message), [cancelButton, continueButton]);
  }

  Widget getDialogTextWidget(String contentText) {
    return Text(contentText,
        style: TextStyle(
          fontSize: _scale.dialogActionButton,
          fontStyle: FontStyle.normal,
        ));
  }


  Widget getDialogActionButton(String buttonText, Function onClick) {
    Widget dialogActionButton = FlatButton(
      child: Text(
        buttonText,
        style: TextStyle(
          // height: MediaQuery.of(_sCtxt).size.height / 2,
          // fontSize: 20.0,
          fontSize: _scale.dialogActionButton,
          // fontWeight: FontWeight.w900,
          fontStyle: FontStyle.normal,
          // fontFamily: 'DancingScript',
          color: Color(0xFF2A67A6),
        ),
      ),
      onPressed: () {
        onClick();
      },
    );

    return dialogActionButton;
  }
  showAppDialog(
      String title, Widget dialogContent, List<Widget> actionButtonWidgets,
      {bool outsideDismissible = true}) {
    AlertDialog appDialog =
    getAlertDialogWidget(title, dialogContent, actionButtonWidgets);

    showDialog(
        context: _ctxt,
        barrierDismissible: outsideDismissible,
        builder: (BuildContext context) {
          return appDialog;
        });
  }

  static Widget getDialogTitle(String title) {
    Widget dialogTitle = Text(title,
        style: TextStyle(
          // height: MediaQuery.of(_sCtxt).size.height / 2,
          // fontFamily: 'DancingScript',
            fontSize: 30.0,
            fontStyle: FontStyle.normal,
            color: Color(0xFF557D31)));

    return dialogTitle;
  }

  AlertDialog getAlertDialogWidget(
      String title, Widget dialogContent, List<Widget> actionButtonWidgets) {
    AlertDialog appDialog = AlertDialog(
      title: getDialogTitle(title),
      shape:
      RoundedRectangleBorder(borderRadius: new BorderRadius.circular(15)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          dialogContent,
        ],
      ),
      actions: actionButtonWidgets,
    );

    return appDialog;
  }
  // ===============
  // === Dashboard Dialogs

  /**
   * TODO:
   *  Set custom text for Trial or "Subscription Expired"
   */
  showTrialEnded() {
    showDialog(
        context: _ctxt,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Your trial has ended"),
            content: Text("In order to reconnect, please subscribe."),
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

  showSubscriptionCreated() {
    showDialog(
        context: _ctxt,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Subscription Created"),
            content: Text("Your payment has been process.  Click Okay to go back"),
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

  showReportNetwork({Function onConfirmReport}) {
    showCupertinoDialog(
        context: _ctxt,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Oh no!"),
            content: Text(
              "We're sorry that you're having issues with this provider. "
                  "As far as we are aware the network is up and running and if that isn't the case then confirm your report and we'll investigate.",
            ),
            actions: [
              FlatButton(
                child: Text("Confirm Report"),
                onPressed: () async {
                  await onConfirmReport();

                  showReportNetworkConfirmation();
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

  showReportNetworkConfirmation() {
    showCupertinoDialog(
        context: _ctxt,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Thank You"),
            content: Text(
              "We'll investigate this network and try to find a resolution. If we are unable to reach the provider we will stop their payouts and return your money. "
                  "Thank you for helping make ${Const.APP_NAME} a better place.",
            ),
            actions: [
              FlatButton(
                child: Text("Okay"),
                onPressed: () async {
                  Navigator.pop(context);
                },
              ),
            ],
          );
        });
  }

  // ===============
  // === Sign Up Dialogs

  showInterestRegistered() async {
    showDialog<void>(
      context: _ctxt,
      barrierDismissible: true,
      // false = user must tap button, true = tap outside dialog
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Interest registered!'),
          content: Container(
            child: _appWidgets.columnWrapper([
              Text('Please check your email for a welcome message.'),
              Container(height: 10),
              // Text('When we find a seller in your area will send you an email.'),
              Text(
                  "We'll let you know when a neighbour sets up their network!"),
            ]),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Okay'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Dismiss alert dialog
                Navigator.pop(_ctxt); // Dismiss alert dialog
              },
            ),
          ],
        );
      },
    );
  }

  showCupertinoError(err) {
    showCupertinoDialog(
        context: _ctxt,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Woops!"),
            content: Text(err.message.toString()),
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

  showError2(err) async {
    showCupertinoDialog(
      context: _ctxt,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Something isn't right..."),
          content: Text(err.message),
          actions: [
            FlatButton(
              child: Text('Okay'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );

  }

  Future showError(err) async {
    return showDialog(
        context: _ctxt,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Woops!"),
            content: Text(err.toString()),
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

  /*
   */
  showCheckingDetailsDialog() async {

    showCupertinoDialog(
        context: _ctxt,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Checking details..."),
            content: Container(
              width: 32,
              height: 32,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        });
  }

  /*
   */
  showSellerCreateAccountDialog({Function onCreateSellerAccount}) async {

    showCupertinoDialog(
      context: _ctxt,
      // FIXME: bring this back for production
      // barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Details verified!"),
          content: Text(
              "Your WiFi details have been verified. Press the button below to continue registration."),
          actions: [
            FlatButton(
              child: Text("Cancel"),
              onPressed: () {
                // 1) close current dialog
                // 2) cancel CircularProgressIndicator
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
            FlatButton(
              child: Text("Create Account"),
              onPressed: () async {
                showCupertinoDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text("Creating account..."),
                        content: Container(
                          width: 32,
                          height: 32,
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      );
                    });

                await onCreateSellerAccount();
              },
            ),
          ],
        );
      },
    ).then((v) async {});
  }

  /*
  Clicking through this goes to a 2nd info dialog with spinner
   */
  showBuyerTrialDialog({Function onCreateBuyerAccount}) {
    showCupertinoDialog(
        context: _ctxt,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Your free 3 day trial"),
            content: _trialDialogContent(),
            actions: [
              FlatButton(
                child: Text("Cancel"),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              FlatButton(
                child: Text("Create Account"),
                onPressed: () async {
                  _showCreatingAccountInfoDialog();

                  await onCreateBuyerAccount();
                },
              ),
            ],
          );
        });
  }

  _trialDialogContent() {
    Widget dialogContent = Container(
      height: 200,
      width: 200,
      child: ListView(
        children: [
          Text(
              "Register with us and we'll instantly connect you to this WiFi network FREE for 3 days!"),
          TextFormField(
            controller: _emailController..text,
            decoration: InputDecoration(
              labelText: "Email Address",
            ),
          ),
          TextFormField(
            controller: _passwordController..text,
            decoration: InputDecoration(
              labelText: "Password",
            ),
            obscureText: true,
          ),
        ],
      ),
    );
    return dialogContent;
  }


  _showCreatingAccountInfoDialog() async {
    showCupertinoDialog(
        context: _ctxt,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Creating account..."),
            content: Container(
              width: 32,
              height: 32,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        });
  }
}
