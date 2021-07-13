import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kiki_wifi/app/globals.dart';

class WifiRepository {
  /*
  In buyerSignUp.dart, we want to look up SSID
  Existing code has it check in networks, but it is in pwds,
  so have to build around that
   */
  Map<String, String> _networkToPwdSsidMap = {};

  QuerySnapshot _networksQS;
  QuerySnapshot _passwordsQS;

  QuerySnapshot get networksQS => _networksQS;

  QuerySnapshot get passwordsQS => _passwordsQS;

  String getNetworkSsid(String networkKey) {
    return _networkToPwdSsidMap[networkKey];
  }

  /*
  Current code loads all Networks
  Here:
  1. Get all networks
  2. Extract ownerId for each one
  3. Use that result set as criteria for which pwd docs to get
  4. Use the returned pwd docs to set netwokr->ssid paris 
   */
  loadCompleteWifiCollections() async {
    log('--- getting list from firestore ---');

    _networksQS = await collectionAll(Collctn.NETWORKS);

    log(_networksQS.toString());

    List<String> networkOwners = [];

    for (int i = 0; i < _networksQS.docs.length; i++) {
      String owner = _networksQS.docs[i].get(Field.OWNER);
      networkOwners.add(owner);
    }
    log(networkOwners.toString());

    // FIXME/TODO: Add a cloud function to get only the actual data we need
    //   for when data set is large, and also better security
    _passwordsQS = await FirebaseFirestore.instance
        .collection(Collctn.PASSWORDS)
        // .where(Field.OWNER, arrayContainsAny: networkOwners)
        .get();

    print('_passwordsQS.docs.length: ${_passwordsQS.docs.length}');

    for (int i = 0; i < _passwordsQS.docs.length; i++) {
      QueryDocumentSnapshot passwordDocSnapshot = _passwordsQS.docs[i];
      String networkKey =
          passwordDocSnapshot.id; // network and pwd have parallel keys
      String ssid = passwordDocSnapshot.get(Field.SSID);
      _networkToPwdSsidMap[networkKey] = ssid;
    }
  }

  collectionAll(String collectionName) async {
    return await FirebaseFirestore.instance.collection(collectionName).get();
  }
}
