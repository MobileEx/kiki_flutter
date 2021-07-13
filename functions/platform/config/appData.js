let Key = exports.Key = {

    uid    : 'uid',
    feet30 : 'feet30',
    feet50 : 'feet50',
    feet60 : 'feet60',

    // placeholder for string replace
    urlDocId : '[doc]',
}

exports.MAX_RANGE_KM = {

    [Key.feet30] : 0.009144,
    [Key.feet50] : 0.015,
    [Key.feet60] : 0.018,
};

let Deployment = exports.Deployment = {

    hostUrl       : 'https://wifi-share-c1423.web.app',
    cloudFuncsUrl : 'https://us-central1-wifi-share-c1423.cloudfunctions.net',
};

exports.AppUrl = {

    welcomeVerification : `${Deployment.cloudFuncsUrl}/welcomeVerification?id=${Key.urlDocId}`,
};

exports.Role = {

    buyer  : 'buyer',
    seller : 'seller'
};

exports.Collctn = {

    appLog                     : '_appLog',
    networks                   : 'networks',
    users                      : 'users',
    vendors                    : 'vendors',
    deviceFcmToken             : 'deviceFcmToken',
    stripeCustomers            : 'stripeCustomers',
    stripeFailedPayments       : 'stripeFailedPayments',
    mailingList                : 'mailing-list',
    stripeDeletedSubscriptions : 'stripeDeletedSubscriptions',
};

// [Key.feet50]               : 0.015,
// [Key.feet60]               : 0.018,

exports.Field = {

    created : '_created',
    message : 'message',

    deviceId        : 'deviceId',
    deviceType      : 'deviceType',
    messagesSent    : 'messagesSent',
    firstHourNtfcn  : 'firstHourNtfcn',
    deviceFcmTokens : 'deviceFcmTokens',

    role  : 'role',
    owner : 'owner',
    uid   : 'uid',
    trial : 'trial',
    pos   : 'pos',
    email : 'email',

    connected   : 'connected',
    customer_id : 'customer_id',

    verifiedOn          : 'verifiedOn',
    subscriptionExpires : 'subscriptionExpires',
};

exports.MessagesSent = {

    firstHourNtfcn : `${exports.Field.messagesSent}.${exports.Field.firstHourNtfcn}`,
};
