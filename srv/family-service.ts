// events/registrations.py, ported: sign_up and cancel.
//
// Django locks the session's row (SELECT ... FOR UPDATE) so two families
// can't take the last place or the same waiting-list position. CAP does the
// same with SELECT.forUpdate() inside the request's transaction; on SQLite
// (development) the whole database is locked per write transaction anyway.
//
// The entity and action types come from cds-typer (@cds-models, generated
// from the CDS model by `npm run typer`, and on every `cds watch`).
import cds from '@sap/cds'
import { Events, Registrations, RegistrationCancellations, EventPathways } from '#cds-models/coderdojo/events'
import { Ninjas, Guardianships, type Ninja } from '#cds-models/coderdojo/accounts'
import { Dojos } from '#cds-models/coderdojo/dojos'
import { MyRegistrations, signUp, cancel } from '#cds-models/FamilyService'

/** Today as a CDS Date (YYYY-MM-DD). */
const today = () => new Date().toISOString().slice(0, 10) as NonNullable<Ninja['memberSince']>

export default class FamilyService extends cds.ApplicationService {
  override init() {
    /** The account behind the logged-in user (the IdP passes it as an attribute). */
    const accountOf = (req: cds.Request): string => {
      const account = req.user.attr?.account as string | undefined
      if (!account) return req.reject(403, 'NO_ACCOUNT')
      return account
    }

    // Ninja.objects.signable_by(user): only your own children (404, like Django).
    const assertOwnChildren = async (req: cds.Request, ninjaIDs: string[]): Promise<void> => {
      const own = await SELECT.from(Guardianships).columns('ninja_ID')
        .where({ guardian_ID: accountOf(req), ninja_ID: ninjaIDs })
      if (own.length !== new Set(ninjaIDs).size) req.reject(404, 'NINJA_NOT_FOUND')
    }

    const count = async (where: object): Promise<number> =>
      ((await SELECT.one.from(Registrations).columns('count(1) as n').where(where)) as unknown as { n: number }).n

    this.on(signUp, async req => {
      const { event: eventID, ninjas: ninjaIDs = [] } = req.data
      if (!eventID || !ninjaIDs.length) return req.reject(400, 'NO_CHILDREN_SELECTED')
      await assertOwnChildren(req, ninjaIDs)

      // _lock(): read everything we decide on after taking the lock.
      const event = await SELECT.one.from(Events, eventID).forUpdate()
      if (!event) return req.reject(404, 'EVENT_NOT_FOUND')
      if (event.status !== 'open') return req.reject(409, 'Registrations for this session are closed.')

      const already = new Set((await SELECT.from(Registrations).columns('ninja_ID')
        .where({ event_ID: eventID, ninja_ID: ninjaIDs })).map(r => r.ninja_ID))
      const newChildren = ninjaIDs.filter(id => !already.has(id))
      if (!newChildren.length)
        return req.reject(409, 'The child(ren) you selected are already signed up for this session.')

      const { max } = (await SELECT.one.from(Registrations).columns('max(position) as max')
        .where({ event_ID: eventID })) as unknown as { max: number | null }
      let position = max ?? 0
      let confirmed = await count({ event_ID: eventID, waitingList: false })
      const pathways = await SELECT.from(EventPathways).columns('pathway_ID').where({ event_ID: eventID })
      const dojo = await SELECT.one.from(Dojos, event.dojo_ID!).columns('ID', 'kind')

      const created: string[] = []
      for (const ninjaID of newChildren) {
        position += 1
        const waitingList = confirmed >= (event.places ?? 0)
        const ID = cds.utils.uuid()
        await INSERT.into(Registrations).entries({
          ID, event_ID: eventID, ninja_ID: ninjaID, waitingList, position,
          pathways: pathways.map(p => ({ pathway_ID: p.pathway_ID })), // registration.pathways.set(...)
        })
        // accounts.home_dojo.assign_on_signup: the first sign-up sets the home dojo.
        if (dojo?.kind === 'dojo')
          await UPDATE(Ninjas, ninjaID).set({ homeDojo_ID: dojo.ID, memberSince: today() }).where({ homeDojo_ID: null })
        if (!waitingList) confirmed += 1
        created.push(ID)
        await this.emit('booked', { registration: ID, waitingList })
      }
      return SELECT.from(MyRegistrations).where({ ID: created }).orderBy('position')
    })

    this.on(cancel, async req => {
      const account = accountOf(req)
      if (!req.data.registration) return false
      const registration = await SELECT.one.from(Registrations, req.data.registration)
      if (!registration) return false // cancelled already (a second click)
      await assertOwnChildren(req, [registration.ninja_ID!])

      const event = await SELECT.one.from(Events, registration.event_ID!).forUpdate()
      const current = await SELECT.one.from(Registrations, registration.ID!)
      if (!event || !current) return false

      await INSERT.into(RegistrationCancellations).entries({
        ninja_ID: current.ninja_ID, event_ID: event.ID, wasWaitlisted: current.waitingList,
        signedUpAt: current.createdAt, cancelledBy_ID: account,
      })
      await DELETE.from(Registrations, current.ID!)
      if (current.waitingList) return true

      if (await count({ event_ID: event.ID, waitingList: false }) >= (event.places ?? 0)) return true
      const promoted = await SELECT.one.from(Registrations)
        .where({ event_ID: event.ID, waitingList: true }).orderBy('position')
      if (promoted) {
        await UPDATE(Registrations, promoted.ID!).set({ waitingList: false })
        await this.emit('waitlistPromoted', { registration: promoted.ID })
      }
      return true
    })

    return super.init()
  }
}
