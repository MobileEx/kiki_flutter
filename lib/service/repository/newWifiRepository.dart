import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kiki_wifi/app/globals.dart';

class NewWifiRepository {
  Future<List<dynamic>> loadCompleteWifiCollections() async {
    List<Map<String, String>> wifiList = [];

    try {
      var allDataFromServer =
          await FirebaseFirestore.instance.collection(Collctn.PASSWORDS).get();

      for (int i = 0; i < allDataFromServer.docs.length; i++) {
        QueryDocumentSnapshot itemDocSnapshot = allDataFromServer.docs[i];
        String referenceId = itemDocSnapshot.reference.id;
        String ssid = itemDocSnapshot.get(Field.SSID);
        String password = itemDocSnapshot.get(Field.PASSWORD);

        wifiList.add({
          'referenceId': referenceId,
          'ssid': ssid,
          'password': password,
        });
      }
    } on FirebaseException catch (e) {
      print(e.message);
    }

    return wifiList;
  }
}
