import 'dart:io';
import 'package:intl/intl.dart';
import 'package:device_info/device_info.dart';

class DeviceUtil {

  Future<String> getDeviceId() async {
    var deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) { // import 'dart:io'
      var iosDeviceInfo = await deviceInfo.iosInfo;
      return iosDeviceInfo.identifierForVendor; // unique ID on iOS
    } else {
      var androidDeviceInfo = await deviceInfo.androidInfo;
      return androidDeviceInfo.androidId; // unique ID on Android
    }
  }
}

class ListUtil {
  List getListStartingAtIndex(int startIdx, List inputList) {
    List resultList = [];

    if (startIdx >= inputList.length) {
      startIdx = 0;
    }

    for (int i = startIdx; i < inputList.length; i++) {
      dynamic value = inputList[i];
      resultList.add(value);
    }

    for (int i = 0; i < startIdx; i++) {
      dynamic value = inputList[i];
      resultList.add(value);
    }

    return resultList;
  }
}

class StringUtil {
  static String getWithLineBreaks(String text) {
    String result = text.replaceAll('\\n', '\n');
    return result;
  }

  static String getSingleOrPlural(int count, String text) {
    String result = '$text';
    if (count > 1) {
      result += 's';
    }

    return result;
  }
}

class DateUtil {
  static final dateFormat1 = new DateFormat('yyyy-MM-dd hh:mm');
  static final dateFormat2 = new DateFormat('hh:mm a, MM/dd/yyyy');
  static final dateFormat6 = new DateFormat('M/d/yyyy, h:mm a');
  static final dateFormat_MDY_HMA = new DateFormat('M/d/yyyy, h:mm a');
  static final dateFormat_MDY = new DateFormat('MM/dd/yyyy');
  static final dateFormat_HMA = new DateFormat('h:mm a');

  static bool isInFuture(DateTime dateTime) {

    int nowMillis = DateUtil.getNowMillisTimestamp();
    int timeMillis = dateTime.millisecondsSinceEpoch;

    bool isInFuture = (nowMillis < timeMillis);

    return isInFuture;
  }

  static int getNowMillisTimestamp() {
    int millisSinceEpoch = new DateTime.now().millisecondsSinceEpoch;

    return millisSinceEpoch;
  }

  static DateTime readableTimestampToDateTime(readableTimestamp) {
    DateTime parsedDate = DateTime.parse(readableTimestamp);

    return parsedDate;
  }

  static String getNowReadableTimestamp() {
    int nowMillisSinceEpoch = DateUtil.getNowMillisTimestamp();

    return getReadableTimestamp(nowMillisSinceEpoch);
  }

  static String getReadableTimestamp(int millisSinceEpoch) {
    DateTime dateTime =
        new DateTime.fromMillisecondsSinceEpoch(millisSinceEpoch);

    String readableTimestamp = dateFormat_MDY_HMA.format(dateTime);

    return readableTimestamp;
  }

  static String getReadableTimestamp_HMA(int millisSinceEpoch) {
    DateTime dateTime =
        new DateTime.fromMillisecondsSinceEpoch(millisSinceEpoch);

    String readableTimestamp = dateFormat_HMA.format(dateTime);

    if (readableTimestamp[0] == '0') {
      readableTimestamp = readableTimestamp.substring(1);
    }

    return readableTimestamp;
  }

  static String getReadableTimestamp_MDY(int millisSinceEpoch) {
    DateTime dateTime =
        new DateTime.fromMillisecondsSinceEpoch(millisSinceEpoch);

    String readableTimestamp = dateFormat_MDY.format(dateTime);

    if (readableTimestamp[0] == '0') {
      readableTimestamp = readableTimestamp.substring(1);
    }

    return readableTimestamp;
  }
}
