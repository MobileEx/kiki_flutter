const appConfig = require('../../platform/appConfig');

// we will use this to provide links
const appData = appConfig.appData;
// ${appData.AppUrl.welcomeVerification}

exports.EmailHasBeenVerified = `
        <body>
        <p style='font-size: 16px;'>Thank you for signing up, your email has been verified</p>
        <p style='font-size: 12px;'>If you are on a mobile device, click the link below to access the app</p>
        <a href='#' onclick='alert("Pending")' style='font-size: 12px;'>Go to Buyer Sign Up</a>
        <p style='font-size: 12px;'>-Kiki Support Team</p>
        </body>
      `;


exports.VerificationDocMissing = `
        <body>
        <p style='font-size: 16px;'>Your request is invalid.  Please contact our support</p>
        </body>
      `;

