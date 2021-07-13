import 'package:flutter/material.dart';

class AppScale {
  BuildContext _ctxt;

  AppScale(this._ctxt);

  // ==================
  // General
  double get drawerWidth => scaledWidth(.7);

  double get rightColumnMaxWidth => scaledWidth(.45);

  double get toggleLabel => scaledHeight(.035);

  // ==================
  // Icons
  double get iconActionButton => scaledHeight(.05);
  double get dropdownSelectListButton => scaledHeight(.03);

  // ==================
  // Fonts
  double get detailsHeaderTextFontSize => scaledHeight(.04);
  double get listSubHeaderTextFontSize => scaledHeight(.035);
  double get detailsRowTextFontSize => scaledHeight(.03);
  double get textFieldFontSize => scaledHeight(.03);
  double get textFieldCounterFontSize => scaledHeight(.03);
  double get verificationBlockButtonFontSize => scaledHeight(.02);
  double get remainingTrialBlockDaysFontSize => scaledHeight(0.05);
  double get remainingTrialBlockMessageFontSize => scaledHeight(0.028);
  double get accountStatusButtonFontSize => scaledHeight(0.027);
  double get accountStatusBlockMessageFontSize => scaledHeight(0.02);
  double get reconnectBlockMessageFontSize => scaledHeight(0.03);

  // Dialogs
  double get dialogActionButton => scaledHeight(.025);

  double get dialogText => scaledHeight(.03);

  double get dialogMainMsg => scaledHeight(.035);

  double scaledWidth(double widthScale) {
    return MediaQuery.of(_ctxt).size.width * widthScale;
  }

  double scaledHeight(double heightScale) {
    return MediaQuery.of(_ctxt).size.height * heightScale;
  }
}
