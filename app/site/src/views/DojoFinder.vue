<script setup>
import { ref, onMounted } from 'vue'
import { api } from '../api.js'
import { t } from '../i18n.js'

const dojos = ref([])
const search = ref('')
const loading = ref(true)
const error = ref('')

async function load() {
  loading.value = true
  try { dojos.value = await api.dojos(search.value) } catch (e) { error.value = e.message }
  loading.value = false
}
let timer
const onInput = e => { search.value = e.target.value; clearTimeout(timer); timer = setTimeout(load, 300) }
onMounted(load)
</script>

<template>
  <section>
    <ui5-title level="H1" size="H3">{{ t('findDojo') }}</ui5-title>
    <div class="toolbar">
      <ui5-input :placeholder="t('searchPlaceholder')" :accessible-name="t('findDojo')" @input="onInput"></ui5-input>
    </div>
    <ui5-message-strip v-if="error" design="Negative" hide-close-button>{{ t('error', { message: error }) }}</ui5-message-strip>
    <ui5-busy-indicator v-if="loading" active size="L" style="width: 100%"></ui5-busy-indicator>
    <template v-else>
      <ui5-list :no-data-text="t('noDojos')">
        <ui5-li v-for="d in dojos" :key="d.ID" :description="d.tagline || d.address"
          :additional-text="d.minAge ? t('ages', { min: d.minAge, max: d.maxAge }) : ''">{{ d.name }}</ui5-li>
      </ui5-list>
    </template>
  </section>
</template>
