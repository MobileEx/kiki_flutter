import Dashboard from "./views/Dashboard.js";
import Settings from "./views/Settings.js";
import BecomeVendor from "./views/BecomeVendor.js";
import SingleSubscription from "./views/SingleSubscription.js";
import PublicSubscription from "./views/PublicSubscription.js";
import Admin from "./views/Admin.js";

const pathToRegex = path => new RegExp("^" + path.replace(/\//g, "\\/").replace(/:\w+/g, "(.+)") + "$");

const getParams = match => {
    const values = match.result.slice(1);
    const keys = Array.from(match.route.path.matchAll(/:(\w+)/g)).map(result => result[1]);

    return Object.fromEntries(keys.map((key, i) => {
        return [key, values[i]];
    }));
};

const navigateTo = url => {
    history.pushState(null, null, url);
    router();
};

const router = async () => {
    const routes = [
        { path: "/", view: Dashboard },
        { path: "/become-vendor", view: BecomeVendor },
        { path: "/settings", view: Settings },
        { path: "/single-subscription", view: SingleSubscription },
        { path: "/app_subscribe", view: PublicSubscription },
        { path: "/admin", view: Admin },
    ];

    // Test each route for potential match
    const potentialMatches = routes.map(route => {
        return {
            route: route,
            result: location.pathname.match(pathToRegex(route.path))
        };
    });

    let match = potentialMatches.find(potentialMatch => potentialMatch.result !== null);

    if (!match) {
        match = {
            route: routes[0],
            result: [location.pathname]
        };
    }

    const view = new match.route.view(getParams(match));
    
    let currentUser = firebase.auth().currentUser;
    if (currentUser) {
        document.querySelector("#content").innerHTML = await view.getHtml();

        if (typeof view.setupListeners === 'function') view.setupListeners();
    }
    

};

window.addEventListener("popstate", router);

document.addEventListener("DOMContentLoaded", () => {
    document.body.addEventListener("click", e => {
        if (e.target.matches("[data-link]")) {
            e.preventDefault();
            navigateTo(e.target.href);
        }
    });

    router();

       /**
     * Firebase auth configuration
     */
    window.firebaseUI = new firebaseui.auth.AuthUI(firebase.auth());
    const firebaseUiConfig = {
    callbacks: {
        signInSuccessWithAuthResult: function (authResult, redirectUrl) {
        // User successfully signed in.
        // Return type determines whether we continue the redirect automatically
        // or whether we leave that to developer to handle.
        return true;
        },
        uiShown: () => {
        document.getElementById('loader').style.display = 'none';
        },
    },
    signInFlow: 'popup',
    signInSuccessUrl: '/',
    signInOptions: [
        firebase.auth.GoogleAuthProvider.PROVIDER_ID,
        firebase.auth.EmailAuthProvider.PROVIDER_ID,
    ],
    credentialHelper: window.firebaseui.auth.CredentialHelper.NONE,
    // Your terms of service url.
    tosUrl: 'https://example.com/terms',
    // Your privacy policy url.
    privacyPolicyUrl: 'https://example.com/privacy',
    };
    firebase.auth().onAuthStateChanged(async (firebaseUser) => {
    if (firebaseUser) {

        router();

        document
        .getElementById('userSignedIn').style.display = 'block';
        document.getElementById('loader').style.display = 'none';
        document.getElementById('content').style.display = 'block';

        await getDbUser(firebaseUser.uid);
    } else {
        document.getElementById('content').style.display = 'none';
        window.firebaseUI.start('#firebaseui-auth-container', firebaseUiConfig);
        document
        .getElementById('userSignedIn').style.display = 'none';
    }
    });

    // Signout button
    document
    .getElementById('signout')
    .addEventListener('click', () => firebase.auth().signOut());

    async function getDbUser(uid) {
        const user = await firebase.firestore().collection('users').doc(uid).get();
        if (user.data() && user.data().role === 'admin') {
            document
            .querySelectorAll('.admin-navlink')
            .forEach((link) => (link.style.display = 'block'));
        }
    }

});