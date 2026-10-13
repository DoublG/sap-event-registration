// The CAP OData services. Development signs in with CAP's mocked users
// (package.json, cds.requires.auth) over basic auth; in production the SAP
// Application Router holds the IAS session and no header is needed.
import { reactive } from 'vue'
import { state as i18n } from './i18n.js'

export const session = reactive({ user: sessionGet('user') || '' })

export function signInAs(user) {
  session.user = user
  try { sessionStorage.setItem('user', user) } catch { /* private mode */ }
}

function sessionGet(key) { try { return sessionStorage.getItem(key) } catch { return null } }

async function request(path, { method = 'GET', body } = {}) {
  const headers = { 'Accept-Language': i18n.lang, Accept: 'application/json' }
  if (session.user) headers.Authorization = 'Basic ' + btoa(session.user + ':')
  if (body) headers['Content-Type'] = 'application/json'
  const res = await fetch(path, { method, headers, body: body && JSON.stringify(body) })
  const data = res.status === 204 ? null : await res.json().catch(() => null)
  if (!res.ok) throw new Error(data?.error?.message || res.statusText)
  return data
}

const list = async path => (await request(path)).value

export const api = {
  dojos: search => list(`/public/Dojos?$select=ID,name,tagline,minAge,maxAge,address&$orderby=name` +
    (search ? `&$search=${encodeURIComponent(search)}` : '')),
  sessions: () => list('/public/Events?$select=ID,name,dojoName,startTime,endTime,places,venueName,minAge,maxAge&$orderby=startTime'),
  myNinjas: () => list('/family/MyNinjas?$select=ID,name,familyName,dateOfBirth&$orderby=name'),
  myRegistrations: () => list('/family/MyRegistrations?$select=ID,ninja_ID,waitingList,position&$expand=event($select=name,startTime)'),
  signUp: (event, ninjas) => request('/family/signUp', { method: 'POST', body: { event, ninjas } }).then(d => d.value),
  cancel: registration => request('/family/cancel', { method: 'POST', body: { registration } }),
}
