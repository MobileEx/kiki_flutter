import 'package:flutter/material.dart';
import 'package:kiki_wifi/ui/style/appScale.dart';

class AppStyle {
  BuildContext _ctxt;
  AppScale _scale;

  AppStyle(this._ctxt) {
    _scale = AppScale(_ctxt);
  }

  TextStyle appNavLink({double fontSize}) {
    fontSize ??= _scale.detailsRowTextFontSize;
    return TextStyle(
      fontSize: fontSize,
      fontStyle: FontStyle.normal,
      // fontWeight: FontWeight.w600,
      color: Colors.blue[700],
    );
  }

}
