
// let pin = numberUtil.getFixedLenRandomNumber(5);
exports.getFixedLenRandomNumber = function (numDigits) {

    if (numDigits < 2) {

        throw new Error('Bad Error, getFixedLenRandomNumber is missing param input');
    }

    let exponent = numDigits - 1;

    // let plusValue  = 10 * numDigits; // eg, 10000
    let plusValue  = Math.pow(10, exponent); // eg, 10000
    let multiplier = plusValue * 9; // eg, 90000

    let fixedLenRandomNumber = Math
        .floor(Math.random() * multiplier)
        + plusValue;

    return fixedLenRandomNumber;
};

    // Logr.debug('plusValue: ' + plusValue);
    // Logr.debug('multiplier: ' + multiplier);


