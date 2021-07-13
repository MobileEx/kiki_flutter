const objectUtil = require('./objectUtil');

// HOUR : 60*60*1000,
// DAY : exports.HOUR * 24,
// MONTH : exports.DAY * 31,

exports.getServerNowDate = function () {

    let serverNowDate = new Date();

    return serverNowDate;
};

// let timestampL = new Date(readableTimeStamp).getTime();
exports.add1MonthToTimestamp = function (readableTimeStamp) {
    let timestampDate = new Date(readableTimeStamp);
    timestampDate.setMonth(timestampDate.getMonth() + 1);

    let readableTime = exports.getReadableTimestamp(timestampDate);
    return readableTime;
};

exports.getReadableTimestampAsDate = function (readableTimeStamp) {
    let timestampDate = new Date(readableTimeStamp);
    return timestampDate;
};

exports.getNowReadableTimestamp = function () {
    // let timestamp = (new Date()).toUTCString();
    let now = exports.getServerNowDate();
    return exports.getReadableTimestamp(now);
};

// let timestamp = (new Date()).toUTCString();
exports.getNowReadableTimestampPST = function () {

    let now = exports.getServerNowDate();
    return exports.getReadableTimestamp(now) + ' PST';
};

exports.getReadableTimestamp = function (dateObject) {

    if (objectUtil.isMissing(dateObject) === true) {

        dateObject = exports.getServerNowDate();
    }

    // let timestamp = (now).toDateString();
    let timestamp =
            (dateObject.getMonth() + 1)
            + '/' + dateObject.getDate()
            + '/' + dateObject.getFullYear();

    let hours = dateObject.getHours();
    let amPm  = (hours < 12) ? 'am' : 'pm';

    hours = ((hours + 11) % 12 + 1);

    timestamp += ' ' + hours;
    let minutes = dateObject.getMinutes();
    if (minutes < 10) {
        minutes = '0' + minutes;
    }
    timestamp += ':' + minutes;

    let seconds = dateObject.getSeconds();
    if (seconds < 10) {
        seconds = '0' + seconds;
    }

    timestamp += ':' + seconds;
    timestamp += ' ' + amPm;

    return timestamp;
};

exports.getNowNumericTimestamp = function () {
    return new Date().getTime();
};

exports.getTodayMDYHM = function () {

    let fullDate = exports.getServerNowDate(); // Thu May 19 2011 17:25:38 GMT+1000 {}

    let todayMDY = exports.getDateAsStringMDYHM(fullDate);

    return todayMDY;
};

let DATE_DELIM = '_';
exports.getDateAsStringMDYHM = function (lookupDate, dateDelimiter) {

    if (objectUtil.isMissing(dateDelimiter)) {
        dateDelimiter = DATE_DELIM;
    }

    // month starts at 0 in date object
    let month = lookupDate.getMonth() + 1;

    //convert month to 2 digits
    let twoDigitMonth = (month >= 10) ? month
        : '0' + month;

    let todayMDY = twoDigitMonth
        + dateDelimiter + lookupDate.getDate()
        + dateDelimiter + lookupDate.getFullYear()
        + dateDelimiter + lookupDate.getHours()
        + dateDelimiter + lookupDate.getMinutes();

    return todayMDY;
};

/*

 */