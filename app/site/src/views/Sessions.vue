<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { api, session, type SessionRow, type ChildRow } from '../api'
import { t, state } from '../i18n'

const sessions = ref<SessionRow[]>([])
const children = ref<ChildRow[]>([])
const loading = ref(true)
const error = ref('')
type Result = { design: 'Positive' | 'Critical'; text: string }
const results = ref<Result[]>([])                // what the last sign-up gave each child
const dialog = ref<SessionRow | null>(null)      // the session being signed up for
const picked = ref(new Set<string>())

const when = (s: SessionRow) => new Intl.DateTimeFormat(state.lang, { dateStyle: 'full', timeStyle: 'short' }).format(new Date(s.startTime))

onMounted(async () => {
  try {
    sessions.value = await api.sessions()
    if (session.user) children.value = await api.myNinjas()
  } catch (e) { error.value = (e as Error).message }
  loading.value = false
})

function open(s: SessionRow) { dialog.value = s; picked.value = new Set(); results.value = [] }
function toggle(id: string, checked: boolean) { checked ? picked.value.add(id) : picked.value.delete(id) }

async function confirm() {
  if (!dialog.value) return
  error.value = ''
  try {
    const regs = await api.signUp(dialog.value.ID, [...picked.value])
    const name = (id: string) => children.value.find(c => c.ID === id)?.name ?? ''
    results.value = regs.map(r => r.waitingList
      ? { design: 'Critical' as const, text: t('onWaitingList', { name: name(r.ninja_ID), position: r.position }) }
      : { design: 'Positive', text: t('gotPlace', { name: name(r.ninja_ID) }) } satisfies Result)
  } catch (e) { error.value = (e as Error).message }
  dialog.value = null
}
</script>

<template>
  <section>
    <ui5-title level="H1" size="H3">{{ t('upcoming') }}</ui5-title>
    <ui5-message-strip v-for="r in results" :key="r.text" :design="r.design">{{ r.text }}</ui5-message-strip>
    <ui5-message-strip v-if="error" design="Negative">{{ t('error', { message: error }) }}</ui5-message-strip>
    <ui5-message-strip v-if="!session.user" design="Information" hide-close-button>{{ t('signInToSignUp') }}</ui5-message-strip>
    <ui5-busy-indicator v-if="loading" active size="L" style="width: 100%"></ui5-busy-indicator>
    <template v-else>
      <div class="grid">
        <ui5-card v-for="s in sessions" :key="s.ID">
          <ui5-card-header slot="header" :title-text="s.name" :subtitle-text="s.dojoName"></ui5-card-header>
          <div class="card-body">
            <ui5-text>{{ when(s) }}</ui5-text>
            <ui5-text v-if="s.venueName">{{ s.venueName }}</ui5-text>
            <div class="row">
              <ui5-tag design="Information" hide-state-icon>{{ s.places === 1 ? t('placesOne') : t('places', { n: s.places }) }}</ui5-tag>
              <ui5-button v-if="session.user && children.length" design="Emphasized" @click="open(s)">{{ t('signUp') }}</ui5-button>
            </div>
          </div>
        </ui5-card>
      </div>
    </template>

    <ui5-dialog :open="!!dialog" :header-text="dialog ? t('whoComes', { name: dialog.name }) : ''" @close="dialog = null">
      <div class="card-body">
        <ui5-checkbox v-for="c in children" :key="c.ID" :text="c.name"
          @change="(e: Event) => toggle(c.ID, (e.target as HTMLInputElement).checked)"></ui5-checkbox>
      </div>
      <ui5-bar slot="footer" design="Footer">
        <ui5-button slot="endContent" design="Emphasized" :disabled="!picked.size" @click="confirm">{{ t('confirm') }}</ui5-button>
        <ui5-button slot="endContent" design="Transparent" @click="dialog = null">{{ t('cancel') }}</ui5-button>
      </ui5-bar>
    </ui5-dialog>
  </section>
</template>
