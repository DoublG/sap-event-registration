<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { api, session, type ChildRow, type RegistrationRow } from '../api'
import { t, state } from '../i18n'

const children = ref<ChildRow[]>([])
const registrations = ref<RegistrationRow[]>([])
const loading = ref(true)
const error = ref('')
const notice = ref('')

const placesOf = (id: string) => registrations.value.filter(r => r.ninja_ID === id)
const when = (d: string) => new Intl.DateTimeFormat(state.lang, { dateStyle: 'medium', timeStyle: 'short' }).format(new Date(d))
const signedIn = computed(() => !!session.user)

async function load() {
  if (!signedIn.value) { loading.value = false; return }
  try {
    ;[children.value, registrations.value] = await Promise.all([api.myNinjas(), api.myRegistrations()])
  } catch (e) { error.value = (e as Error).message }
  loading.value = false
}

async function cancel(r: RegistrationRow) {
  try { await api.cancel(r.ID); notice.value = t('cancelled'); await load() } catch (e) { error.value = (e as Error).message }
}
onMounted(load)
</script>

<template>
  <section>
    <ui5-title level="H1" size="H3">{{ t('myChildren') }}</ui5-title>
    <ui5-message-strip v-if="!signedIn" design="Information" hide-close-button>{{ t('signInToSignUp') }}</ui5-message-strip>
    <ui5-message-strip v-if="notice" design="Positive" @close="notice = ''">{{ notice }}</ui5-message-strip>
    <ui5-message-strip v-if="error" design="Negative">{{ t('error', { message: error }) }}</ui5-message-strip>
    <ui5-busy-indicator v-if="loading" active size="L" style="width: 100%"></ui5-busy-indicator>
    <template v-else-if="signedIn">
      <p v-if="!loading && !children.length">{{ t('noChildren') }}</p>
      <div class="grid">
        <ui5-card v-for="c in children" :key="c.ID">
          <ui5-card-header slot="header" :title-text="c.name" :subtitle-text="c.familyName"></ui5-card-header>
          <div class="card-body">
            <ui5-label>{{ t('myPlaces') }}</ui5-label>
            <ui5-text v-if="!placesOf(c.ID).length">{{ t('noPlaces') }}</ui5-text>
            <div v-for="r in placesOf(c.ID)" :key="r.ID" class="row">
              <ui5-text>{{ r.event?.name }} · {{ r.event ? when(r.event.startTime) : '' }}</ui5-text>
              <ui5-tag :design="r.waitingList ? 'Critical' : 'Positive'">{{ r.waitingList ? t('waitingList') : t('confirmed') }}</ui5-tag>
              <ui5-button design="Transparent" @click="cancel(r)">{{ t('cancelPlace') }}</ui5-button>
            </div>
          </div>
        </ui5-card>
      </div>
    </template>
  </section>
</template>
