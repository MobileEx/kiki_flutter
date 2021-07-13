
exports.removeSpecialChars = function (inputString) {

    let filteredString = inputString.replace(/[^A-Z0-9]/ig, '_');
    return filteredString;
};

exports.contains = function (needle, haystack) {

    let isNeedleInHaystack = haystack.includes(needle);
    return isNeedleInHaystack;
};

exports.ts = function (object) {

    return exports.toStr(object);
};

exports.toStr = function (object) {

    // prior version was just one line:
    // return JSON.stringify(object, null, '\t');

    let seen  = [];
    let value = JSON.stringify(
        object,
        (key, val) => {
            if (val !== null && typeof val === 'object') {
                if (seen.indexOf(val) >= 0) {
                    return;
                }
                seen.push(val);
            }
            return val;
        },
        '\t');

    return value;
};

exports.replaceAllOccurrences = function (inputString, oldStr, newStr) {

    console.debug('enter: replaceAllOccurrences gets inputString = ' + inputString);

    console.debug('oldStr = ' + oldStr);
    console.debug('newStr = ' + newStr);

    let i = 0;

    while (inputString.indexOf(oldStr) >= 0) {
        inputString = inputString.replace(oldStr, newStr);
        i++;
    }

    return inputString;
};

exports.formatPhoneNumber1 = function(phoneNumberString) {
    let cleaned = (String(phoneNumberString)).replace(/\D/g, '');
    let match = cleaned.match(/^(\d{3})(\d{3})(\d{4})$/);
    if (match) {
        return '(' + match[1] + ') ' + match[2] + '-' + match[3]
    }
    return null;
};
exports.capitalizeFirstLetter = function (str) {
    return str.charAt(0).toUpperCase() + str.slice(1);
};

exports.singleQuote = function (str) {

    return '\'' + str + '\'';
};

exports.isEmpty = function (arg) {
    let opposite = (!isNonEmpty(arg));

    return opposite;
};

exports.isNonEmpty = function (arg) {

    return isNonEmpty(arg);
};

exports.getEmailName = function (email) {

    let emailName = email;

    let atIdx = email.indexOf('@');
    if (atIdx > -1) {
        emailName = email.substr(0, atIdx);
    }

    return emailName;
};

exports.hash64 = function(str) {

    let hash = 0, i = 0, len = str.length;

    while ( i < len ) {
        hash  = ((hash << 5) - hash + str.charCodeAt(i++)) << 0;
    }

    return hash;
};

exports.removeNonDigits = function (thestring) {

    let thenum = thestring.replace(/\D/g,'');

    return thenum;
};


function isNonEmpty(arg) {
    // must be &&
    if (typeof arg !== 'undefined'
        && arg && arg.length > 0) {
        return true;
    }

    return false;
}

//
//exports.setSearchQuery = function (qb, queryText)
//{
//	// FIXME where clause needs to be only for employer's jobs
//	// 	There's a better clause for id=X , find it
//	
//	// In this case, probably will not be empty or we have to have error handling
//	// In Google's case, they just wont submit the form unless there's input 
//	// - and they don't show any error message 
//	if ( typeof queryText !== 'undefined' && queryText && queryText.length > 0)
//	{
//		console.log('Adding Where clause because queryText = ' + queryText);
//		qb.where('title', 'LIKE', '%' + queryText + '%');
//	}
//	else
//	{
//		qb.where('title', 'LIKE', 'THIS WILL RETURN NO RESULTS');
//	}
//};

/*
		// collection : collection,
	// userJsonData = collection;
	// console.log(userJsonData);
	// res.json({error: false, data: userJsonData});

    console.log(' >> queryText');
    console.log(queryText);
    // TODO - determine columns for location look up 
    console.log(' >> queryLocation');
    console.log(queryLocation);

	// right now employer_ctrlr.js handles this route
	// FIXME this should be the public user path
	// for employer_ctrlr.js, /employer/jobs/search
*/