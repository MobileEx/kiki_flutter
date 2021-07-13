import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kiki_wifi/ui/widget/creditCard/ccInputFormatter.dart';
import 'package:kiki_wifi/model/ui/paymentCard.dart';
import 'package:kiki_wifi/ui/widget/appWidgets.dart';
import 'package:kiki_wifi/util/logger.dart';

class AppCreditCardForm extends StatefulWidget {
  final _scaffoldKey;

  final Function _onCreditCardSubmit;

  AppCreditCardForm(this._scaffoldKey, this._onCreditCardSubmit, {Key key}) : super(key: key);

  @override
  _AppCreditCardFormState createState() =>
      new _AppCreditCardFormState(_scaffoldKey, _onCreditCardSubmit);
}

class _AppCreditCardFormState extends State<AppCreditCardForm> {
  var _scaffoldKey;
  Function _onCreditCardSubmit;

  NavCtrlWidgets _navCtrlWidgets;
  var _formKey = GlobalKey<FormState>();
  var numberController = TextEditingController();
  var _paymentCard = PaymentCard();
  var _autoValidate = false;

  var _card = PaymentCard();

  final FocusNode cardNumberFocus = FocusNode();
  final FocusNode cvvFocus = FocusNode();
  final FocusNode expiryDateFocus = FocusNode();

  Color themeColor;


  _AppCreditCardFormState(this._scaffoldKey, this._onCreditCardSubmit);

  @override
  void initState() {
    super.initState();
    _paymentCard.type = CardType.Others;
    numberController.addListener(_getCardTypeFrmNumber);
  }

  @override
  void didChangeDependencies() {
    themeColor = Theme.of(context).primaryColor;
    super.didChangeDependencies();
  }

//              SizedBox(
//                height: 20.0,
//              ),
//              _cardNameInput(),

  double CARD_NUM_WIDTH = 220;
  double CVV_WIDTH = 95;
  double EXPIRES_WIDTH = 95;

  @override
  Widget build(BuildContext context) {
    _navCtrlWidgets = NavCtrlWidgets(context);

    return Theme(
      data: ThemeData(
        primaryColor: themeColor.withOpacity(0.8),
        primaryColorDark: themeColor,
      ),
      child: Form(
          key: _formKey,
          autovalidate: _autoValidate,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
//              SizedBox(
//                height: 30.0,
//              ),
              _cardNumberInput(),
              SizedBox(
                height: 30.0,
              ),
              Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _cvvInput(),
                    SizedBox(
                      width: 30.0,
                    ),
                    _expiresInput(),
                  ]
              ),
              SizedBox(
                height: 50.0,
              ),
              Image.asset(
                'assets/images/stripeBadgeWhite.png',
                //    width: imgWidth,
                // height: 40,
                fit: BoxFit.cover,
              ),
              SizedBox(
                height: 50.0,
              ),
              Container(
                alignment: Alignment.center,
                child: _getPayButton(),
              )
            ],
          )),
    );
  }


  void _validateInputs() {
    final FormState form = _formKey.currentState;
    if (!form.validate()) {
      setState(() {
        _autoValidate = true; // Start validating on every change.
      });
      // _showInSnackBar('Please fix the errors in red before submitting.');
    } else {
      form.save();
      // Encrypt and send send payment details to payment gateway
      // _showInSnackBar('Payment card is valid');

      // CreditCardActiveRef.paymentCard = _paymentCard;
      _onCreditCardSubmit(_paymentCard);
    }
  }

  _cardNumberInput() {

    Widget cardNumberInput = TextFormField(
      keyboardType: TextInputType.number,
      inputFormatters: [
        WhitelistingTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(19),
        CardNumberInputFormatter()
      ],
      controller: numberController,
      focusNode: cardNumberFocus,
      decoration: InputDecoration(
        border: const UnderlineInputBorder(),
        filled: true,
        // icon: CardUtils.getCardIcon(_paymentCard.type),
        // icon: Icon(Icons.credit_card, size: 40),
        hintText: 'XXXX XXXX XXXX XXXX',
        labelText: 'Card Number',
      ),
      onSaved: (String cardNumber) {
        print('onSaved, cardNumber: $cardNumber');
        print('Num controller has = ${numberController.text}');
        _paymentCard.number = CardUtils.getCleanedNumber(cardNumber);
      },
      onChanged: (cardNumberText) {
        print('onChanged, cardNumber: $cardNumberText');
        String trimmedCardNumber =
        CardUtils.getCleanedNumber(cardNumberText);

        dbg.i('onChanged(), trimmedCardNumber: $trimmedCardNumber');
        if (trimmedCardNumber.length == 16) {
          cardNumberFocus.unfocus();
          FocusScope.of(context).requestFocus(cvvFocus);
        }
      },
      validator: CardUtils.validateCardNum,
    );

    cardNumberInput = Container(
        width: CARD_NUM_WIDTH,
        child: cardNumberInput
    );

    return cardNumberInput;
  }

  _cardNameInput() {

    return TextFormField(
      decoration: const InputDecoration(
        border: const UnderlineInputBorder(),
        filled: true,
//                  icon: const Icon(
//                    Icons.person,
//                    size: 40.0,
//                  ),
        hintText: 'What name is written on card?',
        labelText: 'Card Name',
      ),
      onSaved: (String value) {
        _card.name = value;
      },
      keyboardType: TextInputType.text,
      validator: (String value) =>
      value.isEmpty ? Strings.fieldReq : null,
    );
  }

  _cvvInput() {

    Widget cvvInput = TextFormField(
      inputFormatters: [
        WhitelistingTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      focusNode: cvvFocus,
      decoration: InputDecoration(
        border: const UnderlineInputBorder(),
        filled: true,
//        icon: Image.asset(
//          'assets/images/card_cvv.png',
//          width: 40.0,
//          color: Colors.grey[600],
//        ),
        hintText: 'XXX',
        labelText: 'CVV',
      ),
      validator: CardUtils.validateCVV,
      keyboardType: TextInputType.number,
      onSaved: (value) {
        _paymentCard.cvv = int.parse(value);
      },
      onChanged: (cvvText) {
        print('onChanged, cvvText: $cvvText');
        if (cvvText.length == 3) {
          cvvFocus.unfocus();
          FocusScope.of(context).requestFocus(expiryDateFocus);
        }
      },
    );

    cvvInput = Container(
        width: CVV_WIDTH,
        child: cvvInput
    );

    return cvvInput;
  }

  _expiresInput() {

    Widget expiresInput = TextFormField(
      inputFormatters: [
        WhitelistingTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
        CardMonthInputFormatter()
      ],
      focusNode: expiryDateFocus,
      decoration: InputDecoration(
        border: const UnderlineInputBorder(),
        filled: true,
//        icon: Image.asset(
//          'assets/images/calender.png',
//          width: 40.0,
//          color: Colors.grey[600],
//        ),
        hintText: 'MM/YY',
        labelText: 'Expires',
      ),
      validator: CardUtils.validateDate,
      keyboardType: TextInputType.number,
      onSaved: (expiryDateStr) {
        List<int> expiryDate = CardUtils.getExpiryDate(expiryDateStr);
        _paymentCard.month = expiryDate[0];
        _paymentCard.year = expiryDate[1];
      },
      onChanged: (expiryDateStr) {
        /*
                          focusNode.unfocus();
                          if (nextFocusNode != null) {
                            FocusScope.of(_ctxt).requestFocus(nextFocusNode);
                          }
                       */
        dbg.i('onChanged(), expiryDateStr: $expiryDateStr');
        List<int> expiryDate = CardUtils.getExpiryDate(expiryDateStr);
        int month = expiryDate[0];
        int year = expiryDate[1];
        dbg.i('month: $month, year: $year');

        if (year > 9) {
          // next focus - last input
          // dbg.i('expiryDateStr, send to next focus');

          _navCtrlWidgets.dismissKeyboard();
        }
      },
    );

    expiresInput = Container(
        width: EXPIRES_WIDTH,
        child: expiresInput
    );

    return expiresInput;
  }

  @override
  void dispose() {
    // Clean up the controller when the Widget is removed from the Widget tree
    numberController.removeListener(_getCardTypeFrmNumber);
    numberController.dispose();
    super.dispose();
  }

  void _getCardTypeFrmNumber() {
    String input = CardUtils.getCleanedNumber(numberController.text);
    CardType cardType = CardUtils.getCardTypeFrmNumber(input);
    setState(() {
      this._paymentCard.type = cardType;
    });
  }

  Widget _getPayButton() {
    if (Platform.isIOS) {
      return CupertinoButton(
        onPressed: _validateInputs,
        color: CupertinoColors.activeBlue,
        child: const Text(
          'Pay',
          style: const TextStyle(fontSize: 17.0),
        ),
      );
    } else {
      return RaisedButton(
        onPressed: _validateInputs,
        color: Colors.deepOrangeAccent,
        splashColor: Colors.deepPurple,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(const Radius.circular(100.0)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 80.0),
        textColor: Colors.white,
        child: Text(
          'PAY',
          style: const TextStyle(fontSize: 17.0),
        ),
      );
    }
  }

  void _showInSnackBar(String value) {
    dbg.i('_showInSnackBar msg: $value');

    // _scaffoldKey.currentState.showSnackBar(SnackBar(
    //   content: Text(value),
    //   duration: Duration(seconds: 3),
    // ));
  }
}
