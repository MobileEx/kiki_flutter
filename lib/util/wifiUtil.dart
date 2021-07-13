import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kiki_wifi/app/globals.dart';
import 'package:wifi_connect/wifi_connect.dart';
import 'package:wifi_iot/wifi_iot.dart';

class WifiUtil {
  BuildContext _ctxt;

  WifiUtil(this._ctxt);

  /*
  This method does:
  1. Get  userSnapshot.get('connected'), the firestore document ID for Seller network profile
  2. Use result docId to lookup the Seller's network SSID & pwd

  This means when we are search for networks available to Buyer,
  must verify an in-range network is not already in use.
   */
  connect() async {
    DocumentSnapshot _password = await FirebaseFirestore.instance
        .collection('passwords')
        .doc(userSnapshot.get('connected'))
        .get();

    // await WiFiForIoTPlugin.findAndConnect(_password['ssid'], password: _password['password'],);
    await WifiConnect.connect(_ctxt,
        ssid: _password.get('ssid'), password: _password.get('password'));
  }

  removeUserTrialAccess() async {
    DocumentSnapshot _network = await FirebaseFirestore.instance
        .collection('passwords')
        .doc(userSnapshot.get('connected'))
        .get();
    // verify use case of missing ssid
    var ssid = get(_network, 'ssid');
    if (ssid == null) {
      return;
    }
    WiFiForIoTPlugin.removeWifiNetwork(ssid);
    WiFiForIoTPlugin.disconnect();
  }

  // move to separate utility if required
  dynamic get(DocumentSnapshot snapshot, String key) {
    try {
      return snapshot.get(key);
    } catch (e) {
      print(e);
    }
    return null;
  }
}
