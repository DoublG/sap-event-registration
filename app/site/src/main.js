import { createApp } from 'vue'
import { createRouter, createWebHashHistory } from 'vue-router'

// The UI5 Web Components this app uses (each import registers one custom element).
import '@ui5/webcomponents/dist/Assets.js'        // translations and themes for the components
import '@ui5/webcomponents-fiori/dist/Assets.js'
import '@ui5/webcomponents/dist/Bar.js'
import '@ui5/webcomponents/dist/BusyIndicator.js'
import '@ui5/webcomponents/dist/Button.js'
import '@ui5/webcomponents/dist/Card.js'
import '@ui5/webcomponents/dist/CardHeader.js'
import '@ui5/webcomponents/dist/CheckBox.js'
import '@ui5/webcomponents/dist/Dialog.js'
import '@ui5/webcomponents/dist/Input.js'
import '@ui5/webcomponents/dist/Label.js'
import '@ui5/webcomponents/dist/List.js'
import '@ui5/webcomponents/dist/ListItemStandard.js'
import '@ui5/webcomponents/dist/MessageStrip.js'
import '@ui5/webcomponents/dist/Option.js'
import '@ui5/webcomponents/dist/SegmentedButton.js'
import '@ui5/webcomponents/dist/SegmentedButtonItem.js'
import '@ui5/webcomponents/dist/Select.js'
import '@ui5/webcomponents/dist/Tag.js'
import '@ui5/webcomponents/dist/Text.js'
import '@ui5/webcomponents/dist/Title.js'
import '@ui5/webcomponents-fiori/dist/ShellBar.js'
import '@ui5/webcomponents-fiori/dist/ShellBarBranding.js'
import '@ui5/webcomponents-icons/dist/map.js'
import '@ui5/webcomponents-icons/dist/appointment-2.js'
import '@ui5/webcomponents-icons/dist/family-care.js'

import App from './App.vue'
import DojoFinder from './views/DojoFinder.vue'
import Sessions from './views/Sessions.vue'
import MyFamily from './views/MyFamily.vue'
import './fonts.css'
import './style.css'

const router = createRouter({
  history: createWebHashHistory(),
  routes: [
    { path: '/', redirect: '/sessions' },
    { path: '/dojos', component: DojoFinder, name: 'dojos' },
    { path: '/sessions', component: Sessions, name: 'sessions' },
    { path: '/family', component: MyFamily, name: 'family' },
  ],
})

createApp(App).use(router).mount('#app')
