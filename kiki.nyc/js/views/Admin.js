import AbstractView from "./AbstractView.js";

export default class extends AbstractView {
    constructor(params) {
        super(params);
        this.setTitle("Admin");
    }

    setupListeners() {
        let currentUser = firebase.auth().currentUser;

        firebase
        .firestore()
        .collection('users')
        .doc(currentUser.uid)
        .onSnapshot(async (snapshot) => {
            let user = snapshot.data();
            if (user && user.role === 'admin') {
                document.getElementById('loader').style.display = 'block';
                
                await getVendorList();

                document.getElementById('loader').style.display = 'none';
            
            } else {
                document.getElementById('error-message').innerHTML = 'You are not authorized to view this page';
            }
        });

        async function getVendorList() {
            const getVendors = firebase.functions().httpsCallable('getVendorList');
            const vendors = await getVendors();

            document.getElementById('vendors-list').innerHTML = `<tr>
            <th>Firebase UID</th>
            <th>Stripe account Id</th>
            <th>Details submitted</th>
            <th></th>
            </tr>`;
            Object.keys(vendors.data).forEach(key => {
                let trElement = document.createElement('tr');
                trElement.id = `vendor-${key}`;
                let content = `<td>${key}</td>
                <td>${vendors.data[key].account_id}</td>
                <td>${vendors.data[key].details_submitted ? 'Yes' : 'No'}</td>
                <td><button id="delete-${key}" type="button">Delete</button></td>
                `;

                trElement.innerHTML = content;

                document.getElementById('vendors-list').appendChild(trElement);
            })
        }

        document.querySelector('#vendors-list').addEventListener('click', async (e) => {
            e.stopPropagation();

            if (e.target.type === 'button') {
                document
                .querySelectorAll('button')
                .forEach((button) => (button.disabled = true));

                const deleteVendor = firebase.functions().httpsCallable('deleteVendor');
 
                try {
                    const res = await deleteVendor({
                        userId: e.target.id.split('-')[1]
                    });

                    console.log(res)

                    await getVendorList();
                } catch (err) {
                    console.error(err)
                    document.getElementById('error-message').innerHTML = err.message
                }

                document
                .querySelectorAll('button')
                .forEach((button) => (button.disabled = false));
            }
        });
    }

    async getHtml() {
        return `
            <h1>Manage vendors</h1>
            <div id="error-message"></div>
            <table id="vendors-list"></table>
        `;
    }
}