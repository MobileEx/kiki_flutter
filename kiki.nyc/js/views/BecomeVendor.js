import AbstractView from "./AbstractView.js";

export default class extends AbstractView {
    constructor(params) {
        super(params);
        this.setTitle("Become vendor");
    }

    setupListeners() {
        /** start firebase logic */
        const STRIPE_PUBLISHABLE_KEY = 'pk_test_HfpZGsxEimfoYTnkb0m762bo';
        let currentUser = {};
        let customerData = {};

        /**
         * Firebase auth configuration
         */
        if (!window.firebaseUI) window.firebaseUI = new firebaseui.auth.AuthUI(firebase.auth());
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
        firebase.auth().onAuthStateChanged((firebaseUser) => {
            setViewNav(firebaseUser);

            if (firebaseUser) {
            currentUser = firebaseUser;
            firebase
            .firestore()
            .collection('stripeCustomers')
            .doc(currentUser.uid)
            .onSnapshot((snapshot) => {
                if (snapshot.data()) {
                customerData = snapshot.data();

                document.getElementById('loader').style.display = 'none';
                document.getElementById('content').style.display = 'block';
                } else {
                console.warn(
                    `No Stripe customer found in Firestore for user: ${currentUser.uid}`
                );
                }
            });

            getVendorInfo();
        } else {
            document.getElementById('content').style.display = 'none';
            window.firebaseUI.start('#firebaseui-auth-container', firebaseUiConfig);
        }
        });

        // Signout button
        document
        .getElementById('signout')
        .addEventListener('click', () => firebase.auth().signOut());

        // Become a vendor button
        document.querySelector('#become_vendor').addEventListener('click', async (e) => {
            e.stopPropagation();

            document
            .querySelectorAll('button')
            .forEach((button) => (button.disabled = true));

            const onboardVendor = firebase.functions().httpsCallable('onboardVendor');
            let currentUser = firebase.auth().currentUser;
            const stripeLinks = await onboardVendor({
                userId: currentUser.uid
            });

            console.log(stripeLinks, stripeLinks.data);
            // redirect user to complete stripe connected onboarding
            if (stripeLinks.data.url) {
                window.location.href = stripeLinks.data.url;
            }

            document
            .querySelectorAll('button')
            .forEach((button) => (button.disabled = false));
        });

        async function getVendorInfo() {
            const getVendor = firebase.functions().httpsCallable('getVendor');
            let currentUser = firebase.auth().currentUser;
            const vendorInfo = await getVendor({
                userId: currentUser.uid
            });
            console.log(vendorInfo)
            if (vendorInfo.data.details_submitted) {
                document.querySelector('#vendor_details').innerText = 'You are already registered as a vendor';
            } else {
                document.querySelector('#onboarding').style.display = 'block';
            }
        }

    }

    async getHtml() {
        return `
            <section id="firebaseui-auth-container"></section>
            <div id="loader">Loading &hellip;</div>
            <section id="content" style="display: block;">
                <button type="button" id="signout">
                    Sign out
                </button>
            <h1>Become vendor</h1>
            <div id="onboarding" style="display: none;">
                <button
                    id="become_vendor"
                >
                    Click to become vendor
                </button>
            </div>
            <div id="vendor_details"></div>
 
        </section>
        `;
    }
}