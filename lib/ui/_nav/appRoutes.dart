import 'package:kiki_wifi/ui/screen/_dev/devScreen.dart';
import 'package:kiki_wifi/ui/screen/_dev/devCreditCard.dart';
import 'package:kiki_wifi/ui/screen/dashboard/sellerDashboard.dart';
import 'package:kiki_wifi/ui/screen/dashboard/buyerDashboard.dart';
import 'package:kiki_wifi/ui/screen/dashboard/buyerAccountStatus.dart';
import 'package:kiki_wifi/ui/screen/sign_up/sellerSignUp.dart';
import 'package:kiki_wifi/ui/screen/sign_up/sellerEnroll.dart';
import 'package:kiki_wifi/ui/screen/sign_up/buyerSignUp.dart';
import 'package:kiki_wifi/ui/screen/appStart.dart';
import 'package:kiki_wifi/ui/screen/payment/subscriptionPaymentScreen.dart';

class AppRoute {
  static const String Dev = 'Dev';
  static const String DevCreditCard = 'DevCreditCard';

  static const String AppHome = 'AppHome';

  static const String BuyerSignUp = 'BuyerSignUp';
  static const String BuyerDashboard = 'BuyerDashboard';
  static const String BuyerAccountStatus = 'BuyerAccountStatus';
  static const String SubscriptionPayment = 'SubscriptionPayment';
  
  static const String SellerSignUp = 'SellerSignUp';
  static const String SellerEnroll = 'SellerEnroll';
  static const String SellerDashboard = 'SellerDashboard';

  static String initialRoute() {
    return AppHome;
  }

  static getRouteMap() {
    return {
      AppRoute.Dev: (context) => DevScreen(),
      AppRoute.DevCreditCard: (context) => DevCreditCardScreen(),
      //
      AppRoute.AppHome: (context) => AppStartScreen(),
      //
      AppRoute.SellerSignUp: (context) => SellerSignUpScreen(),
      AppRoute.SellerEnroll: (context) => SellerEnrollScreen(),
      AppRoute.SellerDashboard: (context) => SellerDashboardScreen(),
      //
      AppRoute.BuyerSignUp: (context) => BuyerSignUpScreen(),
      AppRoute.BuyerDashboard: (context) => BuyerDashboardScreen(),
      AppRoute.BuyerAccountStatus: (context) => BuyerAccountStatusScreen(),
      AppRoute.SubscriptionPayment: (context) => SubscriptionPaymentScreen(),
    };
  }
}
