import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kiki_wifi/app/globals.dart';
import 'package:kiki_wifi/app/sharedPrefs.dart';
import 'package:kiki_wifi/service/messaging/pushNotificationManager.dart';
import 'package:kiki_wifi/ui/_nav/appRoutes.dart';
import 'package:kiki_wifi/ui/screen/appStart.dart';

class RunMode {
  static const bool IS_DEBUG_ON = true;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  PushNotificationManager().init();

  SharedPrefs.loadSharedPrefsData();

  runApp(KikiWifiApp());
}

class KikiWifiApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    ErrorWidget.builder = getErrorWidget;
    return MaterialApp(
      title: 'Kiki Wifi',
      debugShowCheckedModeBanner: App.isDebugMode(),
      initialRoute: AppRoute.initialRoute(),
      routes: AppRoute.getRouteMap(),
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // FIXME: ONLY COMMENTED OUT ON MACBOOK 2011
        // visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AppStartScreen(title: 'Flutter Demo Home Page'),
    );
  }
}

Widget getErrorWidget(FlutterErrorDetails error) {
  return Center(
    child: Text(
      "Error appeared. ${error.stack.toString()}",
      style: TextStyle(
          fontSize: 10, color: Colors.red, fontWeight: FontWeight.normal),
    ),
  );
}
