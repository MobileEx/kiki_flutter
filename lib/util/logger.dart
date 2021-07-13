import 'package:kiki_wifi/app/globals.dart';
import 'package:kiki_wifi/util/dataUtil.dart';

class Dbg {
  List<String> _muteTags = ['tts1'];

  String _tag;

  Dbg(this._tag);

  bool _isOn() {
    return !_muteTags.contains(_tag);
  }

  String _tagM(String msg) {
    return '$_tag :: $msg';
  }

  enter(String msg) {
    if (_isOn()) dbg.enter(_tagM(msg));
  }

  returns(String msg) {
    if (_isOn()) dbg.returns(_tagM(msg));
  }

  calling(String msg) {
    if (_isOn()) dbg.calling(_tagM(msg));
  }

  i(String msg) {
    if (_isOn()) dbg.i(_tagM(msg));
  }
}

class dbg {

  static enter(String msg) {
    printS('\n\n\n');
    printS('===========================');
    printS('================');
    printS('Enter $msg');
  }

  static returns(String msg) {
    printS('RETURNS: $msg');
  }

  static calling(String msg) {
    printS('Calling $msg');
  }

  static callback(String msg) {
    printS('then().callback : $msg :: ${DateUtil.getNowMillisTimestamp()} ');
  }

  static i(String msg) {
    printS('info: $msg');
  }

  static printS(String msg) {
    print('$msg');
  }
}
