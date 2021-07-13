exports.isDefined = function (val) {

    // must be &&
    return (val !== null && typeof val !== 'undefined');
};

exports.isMissing = function (val) {

    let isMissing = (
        exports.isDefined(val) !== true
        || exports.isObjectEmpty(val) === true);

    return isMissing;
};

exports.isObjectEmpty = function (dataObject) {

    let keys          = Object.keys(dataObject);
    let isObjectEmpty = (keys.length === 0);

    return isObjectEmpty;
};
