// The CAP OData services. Development signs in with CAP's mocked users
// (package.json, cds.requires.auth) over basic auth; in production the SAP
// Application Router holds the IAS session and no header is needed.
//
// The row types are the CAP model's own (cds-typer, @cds-models): a change to
// an entity in db/ or srv/ shows up here as a type error.
import { reactive } from 'vue'
import type { Dojo, Event } from '#cds-models/PublicService'
import type { MyNinja, MyRegistration } from '#cds-models/FamilyService'
import { state as i18n } from './i18n'

/** An OData row: the model's entity with the selected fields filled in. */
type Row<T, K extends keyof T> = { [P in K]-?: NonNullable<T[P]> }

export type DojoRow = Row<Dojo, 'ID' | 'name'> & Partial<Pick<Dojo, 'tagline' | 'minAge' | 'maxAge' | 'address'>>
export type SessionRow = Row<Event, 'ID' | 'name' | 'startTime' | 'places'> &
  Partial<Pick<Event, 'dojoName' | 'endTime' | 'venueName' | 'minAge' | 'maxAge'>>
export type ChildRow = Row<MyNinja, 'ID' | 'name'> & Partial<Pick<MyNinja, 'familyName' | 'dateOfBirth'>>
export type RegistrationRow = Row<MyRegistration, 'ID' | 'ninja_ID' | 'waitingList' | 'position'> & {
  event?: { name: string; startTime: string } | null
}

export const session = reactive({ user: sessionGet('user') ?? '' })

export function signInAs(user: string): void {
  session.user = user
  try { sessionStorage.setItem('user', user) } catch { /* private mode */ }
}

function sessionGet(key: string): string | null {
  try { return sessionStorage.getItem(key) } catch { return null }
}

type Method = 'GET' | 'POST'

async function request<T>(path: string, { method = 'GET', body }: { method?: Method; body?: unknown } = {}): Promise<T> {
  const headers: Record<string, string> = { 'Accept-Language': i18n.lang, Accept: 'application/json' }
  if (session.user) headers.Authorization = 'Basic ' + btoa(session.user + ':')
  if (body !== undefined) headers['Content-Type'] = 'application/json'
  const res = await fetch(path, { method, headers, body: body === undefined ? undefined : JSON.stringify(body) })
  const data = res.status === 204 ? null : await res.json().catch(() => null)
  if (!res.ok) throw new Error((data as { error?: { message?: string } } | null)?.error?.message || res.statusText)
  return data as T
}

const list = async <T>(path: string): Promise<T[]> => (await request<{ value: T[] }>(path)).value

export const api = {
  dojos: (search: string) => list<DojoRow>(`/public/Dojos?$select=ID,name,tagline,minAge,maxAge,address&$orderby=name` +
    (search ? `&$search=${encodeURIComponent(search)}` : '')),
  sessions: () => list<SessionRow>('/public/Events?$select=ID,name,dojoName,startTime,endTime,places,venueName,minAge,maxAge&$orderby=startTime'),
  myNinjas: () => list<ChildRow>('/family/MyNinjas?$select=ID,name,familyName,dateOfBirth&$orderby=name'),
  myRegistrations: () => list<RegistrationRow>('/family/MyRegistrations?$select=ID,ninja_ID,waitingList,position&$expand=event($select=name,startTime)'),
  signUp: (event: string, ninjas: string[]) =>
    request<{ value: RegistrationRow[] }>('/family/signUp', { method: 'POST', body: { event, ninjas } }).then(d => d.value),
  cancel: (registration: string) => request<{ value: boolean }>('/family/cancel', { method: 'POST', body: { registration } }),
}
