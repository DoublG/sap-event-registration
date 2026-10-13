<script setup>
import { useRoute, useRouter } from 'vue-router'
import { t, state, useLanguage } from './i18n.js'
import { session, signInAs } from './api.js'

const route = useRoute()
const router = useRouter()
useLanguage(state.lang)

const pages = [
  { name: 'sessions', icon: 'appointment-2', label: 'navSessions' },
  { name: 'dojos', icon: 'map', label: 'navDojos' },
  { name: 'family', icon: 'family-care', label: 'navFamily' },
]
const navigate = e => router.push({ name: e.detail.selectedItems[0].dataset.page })
const changeLanguage = e => useLanguage(e.detail.selectedOption.value)
// Development only: CAP's mocked users. Production signs in through IAS.
const changeUser = e => signInAs(e.detail.selectedOption.value)
</script>

<template>
  <a class="skip-link" href="#content">{{ t('skip') }}</a>
  <ui5-shellbar>
    <ui5-shellbar-branding slot="branding">{{ t('appTitle') }}</ui5-shellbar-branding>
  </ui5-shellbar>
  <main id="content" tabindex="-1">
    <!-- Development only: language and CAP's mocked users. -->
    <div class="toolbar">
      <ui5-select :accessible-name="t('language')" @change="changeLanguage">
        <ui5-option value="nl" :selected="state.lang === 'nl'">Nederlands</ui5-option>
        <ui5-option value="fr" :selected="state.lang === 'fr'">Français</ui5-option>
        <ui5-option value="en" :selected="state.lang === 'en'">English</ui5-option>
      </ui5-select>
      <ui5-select :accessible-name="t('signedInAs')" @change="changeUser">
        <ui5-option value="" :selected="!session.user">{{ t('notSignedIn') }}</ui5-option>
        <ui5-option value="parent" :selected="session.user === 'parent'">parent</ui5-option>
        <ui5-option value="other-parent" :selected="session.user === 'other-parent'">other-parent</ui5-option>
      </ui5-select>
    </div>
    <nav class="toolbar" :aria-label="t('appTitle')">
      <ui5-segmented-button @selection-change="navigate">
        <ui5-segmented-button-item v-for="p in pages" :key="p.name" :data-page="p.name" :icon="p.icon"
          :selected="route.name === p.name">{{ t(p.label) }}</ui5-segmented-button-item>
      </ui5-segmented-button>
    </nav>
    <!-- Remount on language or user change, so every view reloads its data. -->
    <router-view :key="state.lang + session.user" />
  </main>
</template>
