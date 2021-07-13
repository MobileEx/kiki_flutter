import AbstractView from "./AbstractView.js";

export default class extends AbstractView {
    constructor(params) {
        super(params);
        this.setTitle("Settings");
    }

    async getHtml() {
        return `
            <h1>Settings</h1>
            <p>Manage your privacy and configuration.</p>
        `;
    }
}

/*
// Add this in to clear out Firestore collctns
            firebase
                .firestore()
                .collection('users')
                // .where('email', '==', 'genebcontact2@gmail.com')
                .where('email', '==', 'sjcgo1a@gmail.com')
                .onSnapshot((snapshot) => {

                    snapshot.forEach((snap) => snap.ref.delete());
                });
*/

