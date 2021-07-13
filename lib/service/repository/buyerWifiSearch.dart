import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kiki_wifi/service/repository/wifiRepository.dart';
import 'package:kiki_wifi/util/distanceCalcUtil.dart';
import 'package:kiki_wifi/util/logger.dart';
import 'package:geolocator/geolocator.dart';

class BuyerWifiSearch {
  // Public fields
  bool isLoaded = false;
  bool isFound = false;
  String status = 'Looking up networks...';
  DocumentSnapshot foundDS;

  WifiRepository _wifiRepository = WifiRepository();
  DistanceCalcUtil _distanceCalcUtil = DistanceCalcUtil();

  var _buyerLat;
  var _buyerLon;
  QuerySnapshot _networksQS;

  _initBuyerSearch() async {
    dbg.enter('initBuyerSearch()');
    await _wifiRepository.loadCompleteWifiCollections();

    _networksQS = _wifiRepository.networksQS;

    Position buyerGeoPosition = await getCurrentPosition();

    _buyerLat = buyerGeoPosition.latitude;
    _buyerLon = buyerGeoPosition.longitude;

    dbg.i('buyerLat: $_buyerLat, buyerLon: $_buyerLon');
  }

  processFirstAvailableWifiCheck({Function onStatusUpdate}) async {
    dbg.enter('processFirstAvailableWifiCheck, Checking for wifi...');

    await _initBuyerSearch();

    for (int i = 0; i < _networksQS.docs.length; i++) {
      QueryDocumentSnapshot networkDocSnapshot = _networksQS.docs[i];

      var networkLat = networkDocSnapshot.get('pos')[0];
      var networkLon = networkDocSnapshot.get('pos')[1];

      double calcdDistance = _distanceCalcUtil.calculateDistance(
          _buyerLat, _buyerLon, networkLat, networkLon);

      dbg.i('Checking networkLat: $networkLat, networkLon: $networkLon');

      String networkKey = networkDocSnapshot.id;
      String curSsid = _wifiRepository.getNetworkSsid(networkKey);
      dbg.i('Checking curSsid: $curSsid, calcdDistance: $calcdDistance');
      status += '\nChecking $curSsid';

      if (calcdDistance < 0.15) {
        dbg.i('network found, calcdDistance < 0.15 == true');
        isLoaded = true;
        foundDS = networkDocSnapshot;
        isFound = true;
        break;
      }

      status += ' (not found)';
      onStatusUpdate(); // eg, setState(() {});
    }

    dbg.i('status log: \n$status');
  }
}
