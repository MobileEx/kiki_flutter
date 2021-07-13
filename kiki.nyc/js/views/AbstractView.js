export default class {

    STRIPE_PUBLISHABLE_KEY = 'pk_test_51HgC0eKe4BM2E8Ini22asgHj76JCDaUmNuIlEs4IUDjWKMCO3qhegaSNjKget0HKNiSlaJdcNRm1n8G8dXXlfcHT00iU4H0ect';

    SUBSCRIPTION_PRICE_ID = 'price_1HhISBKe4BM2E8In2xsFXGUD';

    constructor(params) {
        this.params = params;
        console.log(`STRIPE_PUBLISHABLE_KEY: ${this.STRIPE_PUBLISHABLE_KEY}`);
        console.log(`SUBSCRIPTION_PRICE_ID: ${this.SUBSCRIPTION_PRICE_ID}`);
    }

    setTitle(title) {
        document.title = title;
    }

    async getHtml() {
        return "";
    }

    setUserInfo() {
        let currentUser = firebase.auth().currentUser;

        if (currentUser !== null && typeof currentUser !== 'undefined') {

            console.log(`currentUser.uid: ${currentUser.uid}`);
            console.log(`currentUser.email: ${currentUser.email}`);

            document.getElementById('user_id').innerHTML = currentUser.uid;
            document.getElementById('user_email').innerHTML = currentUser.email;
        }

    }
}