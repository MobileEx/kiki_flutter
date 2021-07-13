'use strict';

const {Logging} = require('@google-cloud/logging');
const logging   = new Logging({
    projectId : process.env.GCLOUD_PROJECT,
});

const appConfig = require('../appConfig');
const appData   = appConfig.appData;
const mathUtil  = require('../util/mathUtil');

let mSellerLat;
let mSellerLon;


let rangeKmKey = appData.Key.feet60;

exports.setSellerLatLng = function (sellerLatLonArr) {

    console.log(`ENTER: setSellerLatLng(), sellerLatLonArr: ${JSON.stringify(sellerLatLonArr)}`);

    mSellerLat = sellerLatLonArr[0];
    mSellerLon = sellerLatLonArr[1];
    console.log('mSellerLat: ' + mSellerLat + ', mSellerLon: ' + mSellerLon);
};

exports.isWifiInRangeOfBuyer = function (latLonArr) {

    let buyerLat = latLonArr[0];
    let buyerLon = latLonArr[1];

    console.log(`buyerLat: ${buyerLat}, buyerLon: ${buyerLon}`);

    let maxRangeKm = appData.MAX_RANGE_KM[rangeKmKey];

    let distanceKm =
            mathUtil.getHaversineKm(buyerLat, buyerLon, mSellerLat, mSellerLon);
    console.log(`rangeKmKey: ${rangeKmKey}, distanceKm: ${distanceKm}, maxRangeKm: ${maxRangeKm}`);

    let isWifiInRangeOfBuyer = (distanceKm <= maxRangeKm);

    return isWifiInRangeOfBuyer;
};
