import AppComponent from "sap/fe/core/AppComponent";

/**
 * The app's root component: Fiori elements builds every page from
 * manifest.json and the service's annotations (../annotations.cds).
 * @namespace coderdojo.volunteerapplications
 */
export default class Component extends AppComponent {
    public static metadata = {
        manifest: "json"
    };
}
